package App::IBIS::Circos;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use MooseX::Types -declare => [qw(Angle URIObject)];
use MooseX::Types::Moose qw(Maybe Defined Str Num HashRef ArrayRef);

use MooseX::Params::Validate;

with 'Role::Markup::XML';

use List::Util;
use Math::Trig;
use POSIX                    qw(fmod);

class_type URIObject, { class => 'URI' };
coerce URIObject, from Str, via { URI->new($_) };

subtype Angle, as Num,   where { $_ >= 0 && $_ <= 360 };
coerce  Angle, from Num, via { fmod($_, 360) };

coerce HashRef, from Maybe[Str|URIObject],
    via { defined $_[0] ? {$_[0] => $_[0]} : {} };
coerce HashRef, from ArrayRef, via { { map ($_ => $_), @{$_[0]} } };

has title => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => 'Circos Plot',
);

has ns => (
    is      => 'ro',
    isa     => 'URI::NamespaceMap',
    lazy    => 1,
    default => sub {
        URI::NamespaceMap->new({
            rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        })
      },
);

has base => (
    is     => 'ro',
    isa    => URIObject,
    lazy   => 0,
    coerce => 1,
);

has css => (
    is     => 'ro',
    isa    => URIObject,
    lazy   => 0,
    coerce => 1,
);

has start => (
    is      => 'ro',
    isa     => Angle,
    lazy    => 1,
    coerce  => 1,
    default => 0,
);

has end => (
    is      => 'ro',
    isa     => Angle,
    lazy    => 1,
    coerce  => 1,
    default => 0,
);

has rotate => (
    is      => 'ro',
    isa     => Angle,
    lazy    => 1,
    coerce  => 1,
    default => 0,
);

has pad => (
    is      => 'ro',
    isa     => Num,
    lazy    => 1,
    default => 1,
);

has gap => (
    is      => 'ro',
    isa     => Num,
    lazy    => 1,
    default => 1,
);

has thickness => (
    is      => 'ro',
    isa     => Num,
    lazy    => 1,
    default => 0,
);

has margin => (
    is      => 'ro',
    isa     => Num,
    lazy    => 1,
    default => 10,
);

has size => (
    is      => 'ro',
    isa     => Num,
    lazy    => 1,
    default => 100,
);

has radius => (
    is      => 'ro',
    isa     => Num,
    lazy    => 1,
    default => 30,
);

has node_seq => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

has edge_seq => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

#sub BUILD {
    # yo do we need to do anything here?
#}

=head2 plot %PARAMS

=cut

sub plot {
    my ($self, %p) = MooseX::Params::Validate::validated_hash(
        \@_,
        nodes  => { isa => HashRef  },
        edges  => { isa => ArrayRef },
        active => { isa => HashRef, coerce => 1, optional => 1 },
    );

    # derive global geometric properties

    # derive inner radius from size/2 - margin - stack depth

    # stack depth is some function or other applied to the maximum
    # amount of stuff sandwiched between the inner and outer radii.

    # you know what? it would be totally sexy just to declare a side
    # length and a margin and derive the rest, but that's a lot more
    # work than just defining a radius and letting some poor schmuck
    # (i.e. me) figure out the side length.

    # once we know the scheme by which things 

    # First we figure out what this thing looks like as a rectangle:
    # how long and how thick it is. How do we do that? Measure the
    # weighted degree of each node. How do we do that? Find each edge
    # where the node is either a source or a target and sum up the
    # weights.

    # OK well we aren't going to do weights for the moment.

    # Neither should we do multiple topological sorting criteria
    # because we have no idea how it will look.

    # Resolution: *show* the topological sorting criteria but don't
    # try to sort by it yet (besides we don't even have any data for
    # dct:subject->skos:Concept relations yet).

    # Sort by: type, then date. If the dates are equal (which they
    # almost certainly won't be), sort by label. If the labels are
    # identical or one is missing, sort by URL. If the URLs are
    # identical or one is missing, sort by ID, which are required to
    # be both defined and unique (just not necessarily meaningful).

    # this is a way to do it
    my %edges;
    for my $edge (@{$p{edges}}) {
        my ($s, $o) = @{$edge}{qw(source target)};

        # skip over self-refs
        next if $s eq $o;
        # skip over danglers
        next unless $p{nodes}{$s} and $p{nodes}{$o};

        my $t = $edge->{type};
        $t = '' unless defined $t;

        next if $edge->{symmetric} and $edges{$o} and $edges{$o}{$t}
            and $edges{$o}{$t}{$s};

        my $x = $edges{$s} ||= {};
        my $y = $x->{$t}   ||= {};
        my $z = $y->{$o}   ||= [];
        push @$z, $edge;

        my $weight = $edge->{weight} || 1;
        $p{nodes}{$s}{degree} += $weight;
        $p{nodes}{$o}{degree} += $weight;

        # remove any stubs for which we actually have the edge
        my $stubs = $p{nodes}{$s}{stubs};
        # warn Data::Dumper::Dumper($stubs);
        if ($stubs and $stubs->{$t}) {
            delete $stubs->{$t}{$o};
        }
        my $rstubs = $p{nodes}{$o}{rstubs};
        # warn Data::Dumper::Dumper($rstubs);
        if ($rstubs and $rstubs->{$t}) {
            delete $rstubs->{$t}{$s};
        }
    }

    # fix degrees for stubs
    for my $node (values %{$p{nodes}}) {
        my %stubs  = (%{$node->{stubs} || {}});
        my %rstubs = (%{$node->{rstubs} || {}});
        my $weight = List::Util::sum(0, map { scalar keys %$_ } values %stubs);
        $weight += List::Util::sum(0, map { scalar keys %$_ } values %rstubs);
        $node->{degree} += $weight;
    }

    # XXX make this a sort parameter
    # my @order = qw(Issue Argument Position);
    # my %type = map {
    #     'http://privatealpha.com/ontology/ibis/1#' . $order[$_] => $_
    # } (0..$#order);

    my %type = map { $self->node_seq->[$_] => $_ } (0..$#{$self->node_seq});

    # skip everything if keys %{$p{nodes}} == 0

    my @seq = sort {
        my ($x, $y) = ($p{nodes}{$a}, $p{nodes}{$b});
        ($type{$x->{type}} || 0) <=> ($type{$y->{type}} || 0)
            || ($x->{date} || '') cmp ($y->{date} || '')
                || $x->{label} cmp $y->{label}
    } keys %{$p{nodes}};

    # skip all this crap if @seq == 0

    #warn Data::Dumper::Dumper(
    #[map { $p{nodes}{$_}{type} . ' ' . $p{nodes}{$_}{date} } @seq]);

    # degree sum
    my $dsum  = List::Util::sum
        (0, map { $_ ? $p{nodes}{$_}{degree} || 0 : 0 } @seq);
    # node count
    my $nodes = scalar @seq;

    my $r     = $self->radius;
    my $gap   = 2*asin($self->gap/(2*$r)); # chord -> angle in radians
    # warn $gap * $r;
    my $gaps  = $nodes * $gap;

    # OK we have to figure out how many degrees (of arc) is one degree
    # (of graph).

    my $arcd = fmod($self->end - $self->start, 360); # arc length in degrees
    my $arcr = $arcd * pi/180; # arc length in radians
    #warn sprintf("%f -%f = %f (%f)\n", $self->end, $self->start, $arcd, $arcr);
    #warn $arcr / $gap;
    #warn $gap * ($dsum+$nodes) * 180 / pi;
    #warn 2 * pi / $gap;

    my $dlen = $gap; # set degree length to gap initally
    my $plen = $gap; # set padding length too

    my $dsumr = $dsum * $dlen; # degree sum expressed in gap radians
    if ($dsumr > $arcr) {
        # the degree sum * gap length is longer than the arc length,
        # so do away with the idea of padding and gaps entirely.
        $gap  = 0;
        $plen = 0;
        $dlen = $arcr / $dsum;
    }
    else {
        # otherwise there is padding and gaps, but how big are they?

        my $glen = $nodes * $gap;
        my $rest = $arcr - $dsumr;

        if (!$nodes) {
            # noop to eliminate division by zero
        }
        elsif ($rest > 2 * $glen) {
            # the pad length is the same as degree length
            $dlen = $plen = ($arcr - $glen) / ($nodes + $dsum);

            my $thick = $self->thickness / $r;
            if ($dlen > $thick) {
                $dlen = $thick;
                $plen = ($arcr - $glen - ($dlen * $dsum)) / $nodes;
            }
        }
        else {
            # split the remaining length between padding and gap
            $gap = $plen = $rest / (2 * $nodes);
        }
    }

    #warn "degree = $dlen; pad = $plen; gap = $gap";

    # get neighbours
    my %neighbours;
    if ($p{active}) {
        for my $edge (@{$p{edges}}) {
            $neighbours{$edge->{source}} = 1 if $p{active}{$edge->{target}};
            $neighbours{$edge->{target}} = 1 if $p{active}{$edge->{source}};
        }
    }

    #require Data::Dumper;
    #warn Data::Dumper::Dumper(\%targets);

    my @paths;
    my $angle = fmod($self->start + $self->rotate, 360); # angle in DEGREES
    for my $i (0..$#seq) {
        my $id = $seq[$i];
        my $rec = $p{nodes}{$id};
        # XXX the degree-age here should be the total sweep from the params
        my $deg = ($rec->{degree} ||= 0) * $dlen;

        # set this so we can come back to it
        $rec->{angle} = $angle;

        my $arad = deg2rad($angle);
        my $hgap = $gap  / 2;
        my $hpad = $plen / 2;

        my $start = $arad + $hgap;
        $rec->{soff} = $start + $hpad;

        my $x1 = cos($start);
        my $y1 = sin($start);

        my $end = $start + $deg + $plen;
        $rec->{eoff} = $rec->{soff} + $deg;

        my $x2 = cos($end);
        my $y2 = sin($end);

        my $r2 = $r + $self->thickness;

        my $large = int(@seq == 1);

        my $points = sprintf(
            'M%g,%g A%g,%g %g %d,1 %g,%g L %g,%g A%g,%g, %g %d,0 %g,%g z',
            $x1*$r, $y1*$r, $r, $r, $angle, $large, $x2*$r, $y2*$r,
            $x2*$r2, $y2*$r2, $r2, $r2, $angle + $deg, $large, $x1*$r2, $y1*$r2,
        );

        # add css hooks for highlighting
        my @css = qw(node);
        if ($p{active} and $p{active}{$id}) {
            push @css, 'subject';
        }
        elsif ($neighbours{$id}) {
            push @css, 'neighbour';
        }
        else {
            # noop
        }

        #warn $points;

        push @paths, {
            -name => 'a',
            'target'       => '_parent',
            'xlink:target' => '_parent',
            'xlink:href'   => $id,
            'xlink:title'  => $rec->{label} || '',
            -content => {
                -name => 'path',
                d => $points,
                class => join(' ', @css),
                #stroke => 'none',
                #fill   => sprintf('#%02x%02x%02x', ($i * 3) x 3),
                about  => $id,
                typeof => $self->ns->abbreviate($rec->{type}) || $rec->{type},
            }
        };

        $angle += rad2deg($deg + $plen + $gap);
    }

    # sort edges by type and then by source/target position

    my %es = map { $self->edge_seq->[$_] => $_ } (0..$#{$self->edge_seq});
    my @lines;
    for my $s (@seq) {
        my $x = $edges{$s};
        next unless defined $x;

        #warn $s;

        # sort types by source clustering
        my %t;
        for my $t (keys %$x) {
            my $y = $x->{$t};
            for my $o (keys %$y) {
                $t{$t} += scalar @{$y->{$o}};
            }
        }


        for my $type (sort {$t{$b} <=> $t{$a}
                                or $es{$a} <=> $es{$b} } keys %t) {
            my @g;
            my $y = $x->{$type};
            # XXX sort this more intelligently
            for my $o (grep { $y->{$_} } reverse @seq) {
                for my $edge (@{$y->{$o}}) {
                    my $src = $p{nodes}{$s};
                    my $trg = $p{nodes}{$o};

                    my $w = $dlen * ($edge->{weight} || 1);

                    my $soff = $src->{soff}; #+ $dlen/2;
                    my $eoff = $trg->{eoff}; #- $dlen/2;

                    my $sx = cos($soff);
                    my $sy = sin($soff);

                    my $tx = cos($eoff);
                    my $ty = sin($eoff);

                    my $pf = join(' ',
                                  'M%g,%g',               # moveto
                                  'Q%g,%g %g,%g',         # q-curve over
                                  'L%g,%g %g,%g',         # arrowhead
                                  'Q%g,%g %g,%g',         # q-curve back
                                  'A%g,%g, %g 0,0 %g,%g', # arc
                                  'z'                     # close path
                              );

                    my $shortr = $r-$w*sin(pi/4)*$r; # 45 degree arrowhead
                    my $ddeg   = -rad2deg($w);
                    # first point
                    my $th = 0; #$self->thickness;
                    my $x1 = $sx*($r + $th);
                    my $y1 = $sy*($r + $th);

                    # central point 1
                    my $cp = ($eoff - $soff)/2;
                    my $x2 = cos($soff + $cp) * $w;
                    my $y2 = sin($soff + $cp) * $w;

                    # q-curve stop 1
                    my $x3 = $tx * $shortr;
                    my $y3 = $ty * $shortr;

                    # arrowhead
                    my $x4 = cos($eoff-$w/2) * $r;
                    my $y4 = sin($eoff-$w/2) * $r;
                    my $x5 = cos($eoff-$w) * $shortr;
                    my $y5 = sin($eoff-$w) * $shortr;

                    # central point 2
                    my $x6 = cos($eoff - $cp) * $dlen;
                    my $y6 = sin($eoff - $cp) * $dlen;

                    # q-curve stop 2
                    my $x7 = cos($soff + $w) * ($r + $th);
                    my $y7 = sin($soff + $w) * ($r + $th);

                    my $points = sprintf
                        ($pf,                     # format string
                         $x1, $y1,                # moveto
                         $x2, $y2, $x3, $y3,      # q-curve over
                         $x4, $y4, $x5, $y5,      # arrowhead
                         $x6, $y6, $x7, $y7,      # q-curve back
                         ($r + $th) x 2, $ddeg, $x1, $y1, # arc
                     );

                    my @css;
                    push @css, 'subject' if $p{active}
                        and ($p{active}{$s} or $p{active}{$o});

                    my %p = (
                        -name    => 'path',
                        d        => $points,
                        #fill     => 'black',
                        #stroke   => 'none',
                        #opacity  => '0.5',
                        #class    => join(' ', @css),
                        about    => $s,
                        resource => $o,
                    );

                    if (my $rel = $self->ns->abbreviate($type)) {
                        $p{rel} = $rel;
                    }
                    else {
                        #warn $type;
                    }

                    $p{class} = join ' ', @css if @css;
                    $p{title} = $p{'xlink:title'} = $edge->{label}
                        if defined $edge->{label};

                    push @g, \%p;

                    $src->{soff} += $w;
                    $trg->{eoff} -= $w;

                    # if ($src->{stubs} and $src->{stubs}{$type}
                    #         and keys %{$src->{stubs}{$type}}) {
                    #     warn "fwd $type";
                    #     warn Data::Dumper::Dumper($src->{stubs}{$type});
                    # }
                    # if ($trg->{rstubs} and $trg->{rstubs}{$type}
                    #         and keys %{$trg->{rstubs}{$type}}) {
                    #     warn "rev $type";
                    #     warn Data::Dumper::Dumper($trg->{rstubs}{$type});
                    # }
                }
            }

            # now we do stubs
            my $node = $p{nodes}{$s};
            if ($node->{stubs} and $node->{stubs}{$type}
                    and keys %{$node->{stubs}{$type}}) {
                #warn "fwd stub $s $type";
                #warn Data::Dumper::Dumper($node->{stubs}{$type});
            }
            if ($node->{rstubs} and $node->{rstubs}{$type}
                    and keys %{$node->{rstubs}{$type}}) {
                #warn "rev stub $s $type";
                #warn Data::Dumper::Dumper($node->{rstubs}{$type});
            }

            push @lines, { -name => 'g', -content => \@g };
        }
    }

    # something in here causes a syntax error
    my %ns = (map {
        ("xmlns:$_" => $self->ns->namespace_uri($_)->as_string)
    } ($self->ns->list_prefixes));
    $ns{'xml:base'} = $self->base->as_string if $self->base;

    my $xl = $self->radius + $self->thickness + $self->margin;

    my $doc = $self->_DOC;
    my @spec = {
        -name => 'svg', %ns,
        xmlns         => 'http://www.w3.org/2000/svg',
        'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
        viewBox => sprintf("0 0 %g %g", ($xl * 2) x 2),
        preserveAspectRatio => 'xMinYMid meet',
        -content => [
            { -name => 'title', -content => $self->title },
            { -name => 'g',
              transform => sprintf('translate(%g, %g)', ($xl) x 2),
              -content => [
                  { -name => 'g', id => 'edges', -content => \@lines },
                  { -name => 'g', id => 'nodes', -content => \@paths } ] } ] };

    unshift @spec, { -pi => 'xml-stylesheet', type => 'text/css',
                  href => $self->css->as_string } if $self->css;

    $self->_XML(doc => $doc, spec => \@spec);

    $doc;
}

__PACKAGE__->meta->make_immutable;

1;
