package App::IBIS::Circos;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use App::IBIS::Types qw(Angle URIObject);
use MooseX::Types::Moose qw(Maybe Defined Str Num HashRef ArrayRef);

use MooseX::Params::Validate;

with 'Role::Markup::XML';

use List::Util;
use Math::Trig;
use POSIX qw(fmod);

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

sub _make_doc {
    my ($self, $paths, $lines) = @_;

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
                  { -name => 'g', id => 'edges', -content => $lines },
                  { -name => 'g', id => 'nodes', -content => $paths } ] } ] };

    unshift @spec, { -pi => 'xml-stylesheet', type => 'text/css',
                  href => $self->css->as_string } if $self->css;

    $self->_XML(doc => $doc, spec => \@spec);

    $doc;
}

# generate path points

sub _directed_points {
    my ($self, %p) = @_;

    my $dlen = $p{length} || 1;
    my $w    = $dlen * ($p{weight} || 1);
    my $r    = $p{radius} || 1;
    my $soff = $p{start}  || 0;
    my $eoff = $p{end}    || $p{start} + $w;


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
    my $th = 0;                 #$self->thickness;
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

    sprintf(
        $pf,                                # format string
        $x1, $y1,                           # moveto
        $x2, $y2, $x3, $y3,                 # q-curve over
        $x4, $y4, $x5, $y5,                 # arrowhead
        $x6, $y6, $x7, $y7,                 # q-curve back
        ($r + $th) x 2, $ddeg, $x1, $y1,    # arc
    );
}

sub _symmetric_points {
    my ($self, %p) = @_;

    my $dlen = $p{length} || 1;
    my $w    = $dlen * ($p{weight} || 1);
    my $r    = $p{radius} || 1;
    my $soff = $p{start}  || 0;
    my $eoff = $p{end}    || $w;

    my $sx = cos($soff);
    my $sy = sin($soff);

    my $tx = cos($eoff);
    my $ty = sin($eoff);

    my $pf = join(' ',
                  'M%g,%g',               # moveto
                  'Q%g,%g %g,%g',         # q-curve over
                  'A%g,%g, %g 0,0 %g,%g', # arc 1
                  'Q%g,%g %g,%g',         # q-curve back
                  'A%g,%g, %g 0,0 %g,%g', # arc 2
                  'z'                     # close path
              );

    my $ddeg   = -rad2deg($w);

    # first point
    my $th = 0;                 #$self->thickness;
    my $x1 = $sx * ($r + $th);
    my $y1 = $sy * ($r + $th);

    # central point 1
    my $cp = ($eoff - $soff)/2;
    my $x2 = cos($soff + $cp) * $w;
    my $y2 = sin($soff + $cp) * $w;

    # q-curve stop 1
    my $x3 = $tx * $r;
    my $y3 = $ty * $r;

    # arc 1
    my $x4 = cos($eoff-$w) * $r;
    my $y4 = sin($eoff-$w) * $r;

    # central point 2
    my $x5 = cos($eoff - $cp) * $dlen;
    my $y5 = sin($eoff - $cp) * $dlen;

    # q-curve stop 2
    my $x6 = cos($soff + $w) * ($r + $th);
    my $y6 = sin($soff + $w) * ($r + $th);

    sprintf(
        $pf,                          # format string
        $x1, $y1,                     # moveto
        $x2, $y2, $x3, $y3,           # q-curve over
        ($r + $th) x 2, 0, $x4, $y4,  # arc 1
        $x5, $y5, $x6, $y6,           # q-curve back
        ($r + $th) x 2,  0, $x1, $y1, # arc 2
    );
}

sub _stub_points {
    my ($self, %p) = @_;

    my $dlen = $p{length} || 1;
    my $w    = $dlen * ($p{weight} || 1);
    my $r    = $p{radius} || 1;
    my $soff = $p{start}  || $p{end} - $w;

    my $pf = join(' ',
                  'M%g,%g',               # moveto
                  'A%g,%g, %g 0,0 %g,%g', # arc 1
                  'A%g,%g, %g 0,0 %g,%g', # arc 2
                  'z'                     # close path
              );

    my $sx = cos($soff);
    my $sy = sin($soff);

    my $tx = cos($soff + $w);
    my $ty = sin($soff + $w);

    #my $ddeg   = -rad2deg($w);

    # first point
    my $th = 0;                 #$self->thickness;
    my $x1 = $sx * ($r + $th);
    my $y1 = $sy * ($r + $th);

    # second point
    my $x2 = $tx * ($r + $th);
    my $y2 = $ty * ($r + $th);

    # degrees

    sprintf(
        $pf,
        $x1, $y1,                         # moveto
        ($w) x 2, 0, $x2, $y2,       # arc 1
        ($r + $th) x 2, 0, $x1, $y1, # arc 2
    );
}

sub _reverse_stub_points {
    my ($self, %p) = @_;

    my $dlen = $p{length} || 1;
    my $w    = $dlen * ($p{weight} || 1);
    my $r    = $p{radius} || 1;
    my $soff = $p{start}  || $p{end} - $w;
    my $eoff = $p{end}    || $p{start} + $w;

    my $pf = join(' ',
                  'M%g,%g',               # moveto
                  'L%g,%g %g,%g',         # arrowhead
                  'A%g,%g, %g 0,1 %g,%g', # arc
                  'z'                     # close path
              );

    my $sx = cos($soff);
    my $sy = sin($soff);

    my $tx = cos($eoff);
    my $ty = sin($eoff);

    my $shortr = $r-$w*sin(pi/4)*$r; # 45 degree arrowhead

    # first point
    my $th = 0;                 #$self->thickness;
    my $x1 = $sx * $shortr;
    my $y1 = $sy * $shortr;

    # arrowhead point
    my $x2 = cos($eoff - $w/2) * ($r + $th);
    my $y2 = sin($eoff - $w/2) * ($r + $th);

    # third point
    my $x3 = $tx * $shortr;
    my $y3 = $ty * $shortr;

    sprintf(
        $pf,
        $x1, $y1,              # moveto
        $x2, $y2, $x3, $y3,    # arrowhead
        ($w) x 2, 0, $x1, $y1, # arc
    );
}

sub _node_cmp_func {
    my ($self, $nodes) = @_;
    my $nseq = $self->node_seq;
    my %tseq = map +($nseq->[$_] => $_), (0..$#$nseq);

    return sub {
        my ($l, $r) = @{$nodes}{@_[0,1]};
        my $lt = defined $l->{type} ? $l->{type} : '';
        my $rt = defined $r->{type} ? $r->{type} : '';
        return (($tseq{$lt} || 0) <=> ($tseq{$rt} || 0))
            || (($l->{date} || '') cmp ($r->{date} || ''))
                || ($l->{label} cmp $r->{label});
    };
}

sub _make_node_seq {
    my ($self, $nodes) = @_;

    my $cmp = $self->_node_cmp_func($nodes);

    sort { $cmp->($a, $b) } keys %$nodes;
}

sub _nested_hash_get {
    my ($hash, @stack) = @_;
    return unless defined $hash;
    Carp::croak("$hash not a HASH") unless ref $hash eq 'HASH';
    Carp::croak('need at least one element in the stack') unless @stack;

    my $k = shift @stack;
    my $x = $hash->{$k};

    return unless defined $x;
    return $x unless @stack;

    _nested_hash_get($x, @stack);
}

sub _nested_hash_put {
    my ($hash, @stack) = @_;
    return unless defined $hash;
    Carp::croak("$hash not a HASH") unless ref $hash eq 'HASH';
    Carp::croak('need at least two elements in the stack') unless @stack > 1;

    my ($k, $v) = splice @stack, 0, 2;
    return $hash->{$k} = $v unless @stack;

    my $x = $hash->{$k} ||= {};
    _nested_hash_put($x, $v, @stack);
}

sub plot {
    my ($self, %p) = MooseX::Params::Validate::validated_hash(
        \@_,
        nodes  => { isa => HashRef  },
        edges  => { isa => ArrayRef },
        active => { isa => HashRef, coerce => 1, optional => 1 },
    );

    # generate intermediate data structures

    my (%nodes, %edges, %ostubs, %istubs, %oedges, %iedges);

    # start with the nodes
    while (my ($k, $v) = each %{$p{nodes}}) {
        # copy
        my $x = $nodes{$k} = {%$v};

        # duplicate the key into the structure if it isn't already there
        $x->{id} = $k unless defined $x->{id};

        # add a degree element
        $x->{degree} ||= 0;
    }

    # then proceed to the edges
    for my $edge (@{$p{edges}}) {
        my ($s, $o) = @{$edge}{qw(source target)};

        # skip over self-references
        next if $s eq $o;

        # edge (predicate) type (not to be confused with node type)
        my $p = $edge->{type};
        $p = '' unless defined $p;

        # duplicate the edge with unit weight
        my %e = (weight => 1, %$edge);

        if ($nodes{$s}) {
            if (my $ops = _nested_hash_get(\%oedges, $o, $p, $s)) {
                my @x = ref $ops eq 'ARRAY' ? @$ops : ($ops);

                # declare these symmetric if they aren't already
                map { $_->{symmetric} ||= 1 } @x;
                next;
            }

            my $oe = $oedges{$s} ||= {};
            $oe = $oe->{$p}      ||= {};
            unless ($oe->{$o}) {
                $oe->{$o} = \%e;

                # increment the degree(-ish measure as it is weighted)
                $nodes{$s}{degree} += $e{weight};

                # tally up a set of outbound counts
                my $oc = $nodes{$s}{ocounts} ||= {};
                $oc->{$p}++;

                # do the same for the other side if present
                if ($nodes{$o}) {
                    my $ie = $iedges{$o} ||= {};
                    $ie = $ie->{$p}      ||= {};

                    unless ($ie->{$s}) {
                        $ie->{$s} = \%e;
                        $nodes{$o}{degree} += $e{weight};
                        my $ic = $nodes{$o}{icounts} ||= {};
                        $ic->{$p}++;
                    }
                }
            }
        }
        elsif ($nodes{$o}) {
            if (my $spo = _nested_hash_get(\%iedges, $s, $p, $o)) {
                my @x = ref $spo eq 'ARRAY' ? @$spo : ($spo);

                # declare these symmetric if they aren't already
                map { $_->{symmetric} ||= 1 } @x;
                next;
            }

            my $ie = $iedges{$o} ||= {};
            $ie = $ie->{$p}      ||= {};
            unless ($ie->{$s}) {
                $ie->{$s} = \%e;

                # increment the degree(-ish measure as it is weighted)
                $nodes{$o}{degree} += $e{weight};

                # tally up a set of inbound counts
                my $ic = $nodes{$o}{icounts} ||= {};
                $ic->{$p}++;
            }
        }
        else {
            # noop; no nodes exist for this edge
        }
    }

    # now we create the node sequence

    my @seq = $self->_make_node_seq(\%nodes);

    # now we do some math

    # (graph) degree sum and node count
    my $dsum  = List::Util::sum(0, map { $nodes{$_}{degree} || 0 } @seq);
    my $nodes = scalar @seq;
    my $r     = $self->radius;
    my $gap   = 2*asin($self->gap/(2*$r)); # chord -> angle in radians
    my $gaps  = $nodes * $gap;             # total angle of all gaps

    # OK we have to figure out how many degrees (of arc) is one degree
    # (of graph).

    # start with the arc length in degrees
    my $arcd = fmod($self->end - $self->start, 360) || 360;
    my $arcr = $arcd * pi/180; # arc length in radians
    my $dlen = $gap; # set degree length to gap initally
    my $plen = $gap; # set padding length too

    my $dsumr = $dsum * $dlen; # degree sum expressed in gap angle radians
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

    # now we generate the svg for the nodes
    my @nodes = $self->_make_nodes(
        nodes    => \%nodes,
        edges    => \%oedges, # $p{edges},
        oedges   => \%oedges,
        iedges   => \%iedges,
        istubs   => \%istubs,
        ostubs   => \%ostubs,
        active   => $p{active},
        sequence => \@seq,
        dlen     => $dlen,
        plen     => $plen,
        gap      => $gap,
    );

    # now we generate the svg for the edges
    my @edges = $self->_make_edges(
        nodes    => \%nodes,
        edges    => \%oedges,
        oedges   => \%oedges,
        iedges   => \%iedges,
        istubs   => \%istubs,
        ostubs   => \%ostubs,
        active   => $p{active},
        sequence => \@seq,
        dlen     => $dlen,
    );

    # now we punt out the document
    $self->_make_doc(\@nodes, \@edges);
}

sub _edge_sort_func {
    my ($self, $edges, $es) = @_;

    my %es = $es ? %$es :
        map { $self->edge_seq->[$_] => $_ } (0..$#{$self->edge_seq});

    return sub {
        my ($l, $r) = @_;
        my $lk = keys %{$edges->{$l}};
        my $rk = keys %{$edges->{$r}};
        return ($rk <=> $lk) ||  ($es{$l} <=> $es{$r});
    };
}

sub _edge_sort_func2 {
    my ($self, $seq) = @_;

    my %seq = map { $seq->[$_] => $_ } (0..$#$seq);

    return sub {
        my ($l, $r) = @_;
        my $dl = defined $seq{$l};
        my $dr = defined $seq{$r};
        return $seq{$r} <=> $seq{$l} if $dl && $dr;
        return -1 if $dl;
        return  1 if $dr;
        return  0;
    };
}

sub _make_nodes {
    my ($self, %p) = @_;
    $p{active} ||= {};

    my $r     = $self->radius;
    my @seq   = @{$p{sequence} || []};
    my $large = int(@seq == 1);
    my $angle = fmod($self->start + $self->rotate, 360); # angle in DEGREES
    my %es    = map { $self->edge_seq->[$_] => $_ } (0..$#{$self->edge_seq});
    my $esort = $self->_edge_sort_func2(\@seq);

    my @nodes;
    for my $s (@seq) {
        my $rec = $p{nodes}{$s};
        # XXX the degree-age here should be the total sweep from the params
        my $deg = ($rec->{degree} ||= 0) * $p{dlen};

        # set this so we can come back to it
        $rec->{angle} = $angle;

        my $arad = deg2rad($angle);
        my $hgap = $p{gap}  / 2;
        my $hpad = $p{plen} / 2;

        my $start = $arad + $hgap;
        $rec->{soff} = $start + $hpad;

        my $x1 = cos($start);
        my $y1 = sin($start);

        my $end = $start + $deg + $p{plen};
        $rec->{eoff} = $rec->{soff} + $deg;

        my $x2 = cos($end);
        my $y2 = sin($end);

        my $r2 = $r + $self->thickness;

        my $points = sprintf(
            'M%g,%g A%g,%g %g %d,1 %g,%g L %g,%g A%g,%g, %g %d,0 %g,%g z',
            $x1*$r, $y1*$r, $r, $r, $angle, $large, $x2*$r, $y2*$r,
            $x2*$r2, $y2*$r2, $r2, $r2, $angle + $deg, $large, $x1*$r2, $y1*$r2,
        );

        # calculate offsets for edges
        my $neighbour;
        if (my $oe = $p{oedges}{$s}) {
            my $sub = $self->_edge_sort_func($oe, \%es);
            my $pos = 0;

            for my $p (sort { $sub->($a, $b) } keys %$oe) {
                my $oep = $oe->{$p};

                # this one goes forwards
                for my $o (sort { $esort->($a, $b) } keys %$oep) {
                    my $edge = $oep->{$o};
                    $edge->{soff} = $pos;
                    $pos += $edge->{weight} || 1;

                    # $s is a neighbour if this guy is active
                    $neighbour = 1 if $p{active}{$o};
                }
            }
        }

        # aaand the same thing in reverse
        if (my $ie = $p{iedges}{$s}) {
            my $sub = $self->_edge_sort_func($ie, \%es);
            my $pos = 0;

            for my $p (sort { $sub->($a, $b) } keys %$ie) {
                my $iep = $ie->{$p};

                # this one goes backwards
                for my $o (sort { $esort->($b, $a) } keys %$iep) {
                    my $edge = $iep->{$o};
                    $edge->{eoff} = $pos;
                    $pos -= $edge->{weight} || 1;

                    # $s is a neighbour if this guy is active
                    $neighbour = 1 if $p{active}{$o};
                }
            }
        }

        # add css hooks for highlighting
        my @css = qw(node);
        if ($p{active}{$s}) {
            push @css, 'subject';
        }
        elsif ($neighbour) {
            push @css, 'neighbour';
        }
        else {
            # noop
        }

        #warn $points;

        push @nodes, {
            -name          => 'a',
            'target'       => '_parent',
            'xlink:target' => '_parent',
            'xlink:href'   => $s,
            'xlink:title'  => $rec->{label} || '',
            -content => {
                -name => 'path',
                d => $points,
                class => join(' ', @css),
                #stroke => 'none',
                #fill   => sprintf('#%02x%02x%02x', ($i * 3) x 3),
                about  => $s,
                typeof => $self->ns->abbreviate($rec->{type}) || $rec->{type},
            }
        };

        # increment the angle (in degrees) by padding and gap
        $angle += rad2deg($deg + $p{plen} + $p{gap});
    }

    @nodes;
}

sub _make_edges {
    my ($self, %p) = @_;
    $p{active} ||= {};

    my $r   = $self->radius;
    my @seq = @{$p{sequence} || []};
    my %seq = map { $seq[$_] => $_ } (0..$#seq);
    my %es  = map { $self->edge_seq->[$_] => $_ } (0..$#{$self->edge_seq});

    my $dlen  = $p{dlen};
    my $esort = $self->_edge_sort_func2(\@seq);

    my @edges;
    for my $s (@seq) {
        my $src = $p{nodes}{$s};

        # do outbound edges
        if (my $oe = $p{oedges}{$s}) {
            my $sub = $self->_edge_sort_func($oe, \%es);
            for my $p (sort { $sub->($a, $b) } keys %$oe) {
                my $oep = $oe->{$p};

                my @g;

                # this one goes forwards
                for my $o (sort { $esort->($a, $b) } keys %$oep) {
                    my $edge = $oep->{$o};

                    my $soff = $dlen * $edge->{soff} + $src->{soff};

                    my $points;

                    if (my $trg = $p{nodes}{$o}) {
                        # full arc
                        my $eoff = $dlen * $edge->{eoff} + $trg->{eoff};

                        if ($edge->{symmetric}) {
                            $points = $self->_symmetric_points(
                                length => $dlen,
                                weight => $edge->{weight} || 1,
                                radius => $r,
                                start  => $soff,
                                end    => $eoff,
                            );
                        }
                        else {
                            $points = $self->_directed_points(
                                length => $dlen,
                                weight => $edge->{weight} || 1,
                                radius => $r,
                                start  => $soff,
                                end    => $eoff,
                            );
                        }
                    }
                    elsif ($edge->{symmetric}) {
                        # symmetric stub
                        $points = $self->_stub_points(
                            length => $dlen,
                            weight => $edge->{weight} || 1,
                            radius => $r,
                            start  => $soff,
                        );
                    }
                    else {
                        # asymmetric stub
                        $points = $self->_stub_points(
                            length => $dlen,
                            weight => $edge->{weight} || 1,
                            radius => $r,
                            start  => $soff,
                        );
                    }

                    my %elem = (
                        -name    => 'path',
                        d        => $points,
                        about    => $s,
                        resource => $o,
                    );

                    if (my $rel = $self->ns->abbreviate($p)) {
                        $elem{rel} = $rel;
                    }
                    else {
                        #warn $pred;
                    }

                    my @css;
                    push @css, 'subject' if ($p{active}{$s} or $p{active}{$o});
                    $elem{class} = join ' ', @css if @css;
                    $elem{title} = $elem{'xlink:title'} = $edge->{label}
                        if defined $edge->{label};

                    push @g, \%elem;

                }

                push @edges, { -name => 'g', -content => \@g } if @g;
            }
        }

        # do inbound edges (rather, stubs)
        if (my $ie = $p{iedges}{$s}) {
            my $sub = $self->_edge_sort_func($ie, \%es);
            for my $p (sort { $sub->($a, $b) } keys %$ie) {
                my $iep = $ie->{$p};

                my @g;

                # this one goes backwards
                for my $o (sort { $esort->($b, $a) } keys %$iep) {
                    # we only do stubs here
                    next if $p{nodes}{$o};

                    my $edge = $iep->{$o};
                    my $eoff = $edge->{eoff} * $dlen + $src->{eoff};

                    my $points;

                    if ($edge->{symmetric}) {
                        # symmetric stub
                        $points = $self->_stub_points(
                            length => $dlen,
                            weight => $edge->{weight} || 1,
                            radius => $r,
                            end    => $eoff,
                        );
                    }
                    else {
                        # asymmetric stub
                        $points = $self->_reverse_stub_points(
                            length => $dlen,
                            weight => $edge->{weight} || 1,
                            radius => $r,
                            end    => $eoff,
                        );
                    }

                    my %elem = (
                        -name    => 'path',
                        d        => $points,
                        about    => $s,
                        resource => $o,
                    );

                    if (my $rel = $self->ns->abbreviate($p)) {
                        $elem{rel} = $rel;
                    }
                    else {
                        #warn $pred;
                    }

                    my @css;
                    push @css, 'subject' if $p{active}{$s};
                    $elem{class} = join ' ', @css if @css;
                    $elem{title} = $elem{'xlink:title'} = $edge->{label}
                        if defined $edge->{label};

                    push @g, \%elem;

                }

                push @edges, { -name => 'g', -content => \@g } if @g;
            }
        }
    }

    @edges;
}

__PACKAGE__->meta->make_immutable;

1;
