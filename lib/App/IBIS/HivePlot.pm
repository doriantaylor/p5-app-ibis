package App::IBIS::HivePlot;

use Moose;
use namespace::autoclean;

# data schleppin'
use RDF::Trine qw(iri);
use XML::LibXML::LazyBuilder qw(DOM E F P);

# actual workin'

# iso 8601 can be lexically sorted if it's all the same time zone
#use DateTime;
use Math::Trig;
use List::Util qw(sum min max);

with 'App::IBIS::Role::Schema';

# our data source
has model => (
    is       => 'ro',
    isa      => 'RDF::Trine::Model|App::IBIS::Model::RDF',
    required => 1,
);

# uri changr 
has callback => (
    is       => 'ro',
    isa      => 'CodeRef',
    lazy     => 1,
    default  => sub { sub { shift } }, # yodawgyodawgyo
);

has collections => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

# # which RDF types we're interested in
# has types => (
#     is      => 'ro',
#     isa     => 'ArrayRef',
#     lazy    => 1,
#     default => sub { [map { $NS->ibis->uri($_) } qw(Issue Position Argument)] },
# );

# offset from centre
has offset => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    default => 30,
);

# splay (in degrees) for self-referential types
has splay => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    default => 40,
);

# padding between cells
has padding => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    default => 1,
);

# factor to multiply sizes by so there's a bigger target to click on
has factor => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    default => 3,
);

# subject map
has _s => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { { } },
);

# type map
has _t => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { { } },
);

# predicate-object map
has _po => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { { } },
);

# predicate-subject map
has _ps => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { { } },
);

# self-referential map
has _sr => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { { } },
);

# time-sequence map
has _ts => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { { } },
);


sub BUILD {
    my $self = shift;

    # Initial scan of graph
    my $iter = $self->model->get_statements(undef, undef, undef);
    while (my $stmt = $iter->next) {
        my ($s, $p, $o) = $stmt->nodes;

        # skip if uninteresting
        next unless $s->is_resource;

        # hash keys are strings
        my $sv = $s->uri_value;

        # really uninteresting
        next unless $sv =~ /^urn:uuid:/i;

        # subject
        my $ss = $self->_s->{$sv} ||= {};

        my $pv = $p->uri_value;
        if ($pv =~ $self->re) {
            # if (my $inv = $PREFER{$pv}) {
            #     $p = $inv;
            #     ($s, $o) = ($o, $s);

            #     # overwite this so we don't screw up
            #     $sv = $s->value;
            # }

            my $pp = $self->_po->{$pv} ||= {};
            my $oo = $pp->{$sv}        ||= {};
            $oo->{$o->value} = 1;
        }
        else {
            # getting all this so far?
            $ss->{$pv} = $o;

            if ($p->equal($self->ns->rdf->uri('type'))) {
                my $ov = $o->value;
                my $tt = $self->_t->{$ov} ||= {};
                $tt->{$sv} = $ss;
            }
        }
    }

    # Now we get reverse and self-referential values
    for my $p (keys %{$self->_po}) {
        my $po = $self->_po->{$p};
        my $ps = $self->_ps->{$p} ||= {};

        for my $s (keys %$po) {
            my $so = $po->{$s};
            for my $o (keys %$so) {

                my $ss = $self->_s;
                if ($ss->{$o}) {
                    # cache A <-> A self-reference test
                    my $tt = $self->_t;
                    for my $t (keys %$tt) {
                        if ($tt->{$t}{$s} && $tt->{$t}{$o}) {
                            $self->_sr->{$t} = 1;
                            next;
                        }
                    }

                    # got all this?
                    $ps->{$o} ||= {};
                    $ps->{$o}{$s} = $ss->{$o};
                    $po->{$s}{$o} = $ss->{$s};
                }
            }
        }
    }

    # now we lay out the subjects by creation date
    my $c = $self->ns->dct->created->value;
    for my $t ($self->types) {
        my $x = $t->value;

        my $tt = $self->_t->{$x};
        my $po = $self->_po;
        my $ps = $self->_ps;

        my @out;
        for my $s (sort { $tt->{$a}{$c}->value cmp
                              $tt->{$b}{$c}->value } keys %$tt) {
            my %tmp;
            for my $p ($po, $ps) {
                for my $k (keys %$p) {
                    next unless $p->{$k}{$s};
                    for my $o (keys %{$p->{$k}{$s}}) {
                        my $ot = $p->{$k}{$s}{$o}{$self->ns->rdf->type->value};
                        $tmp{$ot}++;
                    }
                }
            }
            # get the max degree
            my $degree = keys %tmp ? (sort { $b <=> $a } values %tmp)[0] : 0;
            push @out, [$s, $degree];
        }

        $self->_ts->{$x} = \@out;
    }

    # that should be it for setting this bastard up.
}

sub _plot_arcs {
    my ($self, $subject, $start, $angle, $srctype, $trgtype) = @_;

    my $map = $self->predicate_map;

    my $a1 = ($start % 360) * pi/180;
    my $a2 = (($start + $angle) % 360) * pi/180;

    # these are our yardsticks
    my @src = @{$self->_ts->{$srctype->uri_value} || []};
    my @trg = @{$self->_ts->{$trgtype->uri_value} || []};
    return unless scalar @src && scalar @trg;

    # get all viable predicates
    my @preds = map { $_->[0] }
        @{$map->{$srctype->uri_value}{$trgtype->uri_value} || [] };

    # hits
    my (%hs, %ht);
    for my $p (@preds) {
        if (my $po = $self->_po->{$p->uri_value}) {
            for my $i (0..$#src) {
                my $s = $src[$i][0];
                $hs{$s} = $i if grep { $po->{$s}{$_->[0]} } @trg;
            }
        }

        if (my $ps = $self->_ps->{$p->uri_value}) {
            for my $i (0..$#trg) {
                my $o = $trg[$i][0];
                $ht{$o} = $i if grep { $ps->{$o}{$_->[0]} } @src;
            }
        }
    }

    #require Data::Dumper;
    #warn Data::Dumper::Dumper(\%hs, \%ht);

    my ($off, $fac, $pad) = ($self->offset, $self->factor, $self->padding);

    my %tloff;
    my @arcs;
    for my $i (sort { $a <=> $b } values %hs) {
        my $s = $src[$i][0];
        #warn "$s $sdeg";

        my $soff = $off + $pad;
        if ($i > 0) {
            $soff += sum(map { $_->[1] * $fac + ($pad * 2) } @src[0..$i-1]);
        }
        #warn $soff;


        my @pgrp;
        for my $p (@preds) {
            next unless my $po = $self->_po->{$p->uri_value};

            #warn $p;

            my @j = sort { $a <=> $b }
                grep { defined $_ } map { $ht{$_} } keys %{$po->{$s}};
            for my $j (@j) {
                my ($o, $odeg) = @{$trg[$j]}; # = $trg[$j][0];

                $tloff{$o} ||= 0;

                # count down from the back
                my $toff = $off + ($tloff{$o} * $fac) - $pad;

                $toff += sum(map {
                    $_->[1] * $fac + ($pad * 2) } @trg[0..$j]);
                #warn $toff;

                #warn "$s $p $o";

                my $x1 = cos($a1) * ($soff + $fac/2);
                my $y1 = sin($a1) * ($soff + $fac/2);

                # control points will be some arbitrary offset 90
                # degrees from the axis, translated by the endpoints
                my $n = $angle < 0 ? -90 : 90;

                my $ca1 = ($start + $n) % 360 * pi/180;
                my $ca2 = ($start + $angle - $n) % 360 * pi/180;

                my $cx1 = cos($ca1) * $off + $x1;
                my $cy1 = sin($ca1) * $off + $y1;

                my $x2 = cos($a2) * ($toff - $fac/2);
                my $y2 = sin($a2) * ($toff - $fac/2);

                my $cx2 = cos($ca2) * $off + $x2;
                my $cy2 = sin($ca2) * $off + $y2;

                #
                my $path = sprintf 'M%f,%f C%f,%f %f,%f, %f,%f',
                    $x1, $y1, $cx1, $cy1, $cx2, $cy2, $x2, $y2;

                my $class = 'arc';
                if ($subject) {
                    my $sv = $subject->uri_value;
                    $class .= ' subject' if $sv eq $s or $sv eq $o;
                }

                push @pgrp,
                    (E path => { class => $class,
                                 about => $s,
                                 rel => $self->ns->abbreviate($p),
                                 resource => $o,
                                 title => $self->labels->{$p->uri_value}[1],
                                 d => $path });
                    # (E line => { class => 'arc',
                    #              about => $s,
                    #              rel => $NS->abbreviate($p),
                    #              resource => $o,
                    #              x1 => $x1, y1 => $y1,
                    #              x2 => $x2, y2 => $y2 });
                $soff += $fac;
                $tloff{$o}--; # -= $fac;
            }

        }
        push @arcs, (E g => {}, @pgrp) if @pgrp;
    }

    @arcs;
}

sub _plot_axis {
    my ($self, $subject, $type, $angle) = @_;
    #warn "derp $angle";
    $angle %= 360;

    my $t = $type->uri_value;

    my ($off, $fac, $pad) = ($self->offset, $self->factor, $self->padding);

    my @rects;
    for my $pair (@{$self->_ts->{$t} || []}) {
        my ($s, $degree) = @$pair;

        # lol @ this
        my $title = $self->_s->{$s}{$self->ns->rdf->value->value}->value;

        my $href = $self->callback->($s);

        my $class = '';
        if ($subject) {
            my $sv = $subject->uri_value;
            $class .= 'subject' if $sv eq $s;
        }

        push @rects, (E a => { 'xlink:target' => '_top', target => '_top',
                               'xlink:href' => $href },
                      (E rect => {
                          # XXX CONSTANTS line thickness
                          class => $class,
                          about => $s, typeof => $self->ns->abbreviate($type),
                          x => $off, y => -($fac/2),
                          width => $degree * $fac + ($pad * 2), height => $fac,
                          title => $title}));
        $off += $degree * $fac + ($pad * 2);
    }
    return (E g => { transform => "rotate($angle)" }, @rects);
}

sub plot {
    my ($self, $subject) = @_;

    #warn "lol $subject" if $subject;

    my @arcs;

    #warn Data::Dumper::Dumper($self->_sr);

    my @types = $self->types;
    for my $i (0..$#types) {
        my $type = $types[$i];
        my $next = $types[($i + 1) % @types];

        my $angle  = 360/@types;
        my $offset = $i*$angle;

        my $tv = $type->uri_value;

        if ($self->_sr->{$tv}) {
            #warn "wtf $tv";

            my $splay = $self->splay/2;
            push @arcs, $self->_plot_arcs
                ($subject, $splay,  $splay * -2, ($type) x 2);
            push @arcs, $self->_plot_arcs
                ($subject, -$splay, $splay * 2,  ($type) x 2);

            $offset += $splay;
            $angle  -= $splay;
        }
        elsif ($self->_sr->{$next->uri_value}) {
            # shave half the splay off the angle
            $angle -= $self->splay/2;
        }
        else {
            # noop
        }

        #warn "$type $next";
        push @arcs, $self->_plot_arcs
            ($subject, $offset + $angle, -$angle, $next, $type);
        push @arcs, $self->_plot_arcs
            ($subject, $offset, $angle, $type, $next);


        #$self->_plot_arcs(20, -40, ($NS->ibis->Issue) x 2),
        #$self->_plot_arcs(-20, 40, ($NS->ibis->Issue) x 2),
    }

    my @axes;
    for my $i (0..$#types) {
        my $type = $types[$i];

        my $angle  = 360/@types;
        my $offset = $i*$angle;

        my $tv = $type->uri_value;

        if ($self->_sr->{$tv}) {
            my $splay = $self->splay/2;
            push @axes, $self->_plot_axis($subject, $type, $offset - $splay);
            $offset += $splay;
        }
        else {
            # noop
        }

        push @axes, $self->_plot_axis($subject, $type, $offset);
    }

    # lol one more time for the bounding box
    my ($xmin, $ymin, $xmax, $ymax) = ((0) x 4);
    for my $i (0..$#types) {
        my $type = $types[$i];

        my $angle = 360/@types;
        my $offset = $i*$angle;

        my $tv = $type->uri_value;
        if ($self->_sr->{$tv}) {
            my $splay = $self->splay/2;
            my ($x, $y) = $self->_tangent_for($type, $offset - $splay);

            $xmin = $x if $xmin > $x;
            $ymin = $y if $ymin > $y;
            $xmax = $x if $xmax < $x;
            $ymax = $y if $ymax < $y;

            #warn "$x $y";
            $offset += $splay;
        }
        my ($x, $y) = $self->_tangent_for($type, $offset);
        $xmin = $x if $xmin > $x;
        $ymin = $y if $ymin > $y;
        $xmax = $x if $xmax < $x;
        $ymax = $y if $ymax < $y;
    }

    my $w = $xmax - $xmin;
    my $h = $ymax - $ymin;

    return DOM F(
        (P 'xml-stylesheet', { type => 'text/css', href => '/asset/svg.css' }),
        (E svg => {
        xmlns => 'http://www.w3.org/2000/svg',
#        viewBox => "$xmin $ymin $xmax $ymax",
        viewBox => "0 0 $w $h",
        preserveAspectRatio => 'xMidYMid meet', %{$self->xmlns} },
            #(map { ("xmlns:$_" => $self->xmlns->{$_}) } keys %{$self->xmlns}) },
         (E title => {}, 'All Issues, Positions, Arguments'),
         #(E style => { type => 'text/css' }, $CSS),
         #(E rect => {
         #    width => '100%', height => '100%', fill => '#333' }),
         (E g => {
             transform => sprintf('translate(%f, %f)',
                                  -$xmin, -$ymin) }, @arcs, @axes)));

}

sub _tangent_for {
    my ($self, $type, $angle) = @_;
    $angle %= 360;
    my $a1 = $angle * pi/180;

    my ($off, $fac, $pad) = ($self->offset, $self->factor, $self->padding);

    my $len = $off +
        (sum(map { $_->[1] * $fac + ($pad * 2) } @{$self->_ts->{$type->value}}) || 0);

    my $x  = cos($a1) * $len;
    my $y  = sin($a1) * $len;

    my $t1 = ($angle + 90) % 360 * pi/180;
    my $t2 = ($angle - 90) % 360 * pi/180;

    # XXX remember $off is what we're using as a tangent for the arc
    # control points.
    my $tx1 = cos($t1) * $off + $x;
    my $ty1 = sin($t1) * $off + $y;

    my $tx2 = cos($t2) * $off + $x;
    my $ty2 = sin($t2) * $off + $y;

    return _compare_bbox($angle, [$x, $tx1, $tx2], [$y, $ty1, $ty2]);
}

sub _compare_bbox {
    my ($angle, $xs, $ys) = @_;

    $angle %= 360;

    if ($angle <= 90) {
        # max x max y
        return (max(@$xs), max(@$ys));
    }
    elsif ($angle <= 180) {
        # min x max y
        return (min(@$xs), max(@$ys));
    }
    elsif ($angle <= 270) {
        # min x min y
        return (min(@$xs), min(@$ys));
    }
    else {
        # max x min y
        return (max(@$xs), min(@$ys));
    }
}

__PACKAGE__->meta->make_immutable;

1;
