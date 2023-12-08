package App::IBIS::Controller::Circos;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use App::IBIS::Circos;

BEGIN {
    extends 'Catalyst::Controller';
    with    'App::IBIS::Role::Markup';
}

=head1 NAME

App::IBIS::Controller::Circos - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 ci2

circos plot

=cut

sub ci2 :Local {
    my ($self, $c) = @_;

    # get some input. innnnnnn putttttt
    my $req = $c->req;
    my $ns  = $self->ns;
    my $bs  = $req->base;
    my $q   = $req->query_parameters;
    my $ref = $q->{subject};
    # i knew that would bite me in the ass

    my $deg = $q->{degrees} || 360;
    my $rot = $q->{rotate}  || 0;

    # other handy things
    my $lab = $self->labels;
    my $inv = $self->inverse;
    my $m   = $c->rdf_cache;

    # first we obtain the subject either from the query string or from
    # the referrer

    my %lit;
    if ($ref) {
        $ref = [$ref] unless ref $ref;
        for my $s (map { URI->new_abs($_, $bs) } @$ref) {
            if (my ($uuid) = ($s->path =~ $self->UUID_RE)) {
                my $sub  = iri('urn:uuid:' . lc $uuid);
                my $suri = $c->uri_for($uuid);
                $lit{$suri} = $sub;
            }
        }
    }

    # types
    my @t  = map { $ns->ibis->uri($_) } qw(Issue Argument Position);

    # "forward" relations, i.e. those visible on the chart
    my @fp = map { $ns->ibis->uri($_) } qw(generalizes replaces questions
                                           suggests responds-to supports
                                           opposes);
    my %fp = map { $_->uri_value => $_ } @fp;
    # "reverse" relations, i.e. those which are flipped into forward
    my %rp = map { my $x = $ns->ibis->uri($_); $x->uri_value => $x }
        qw(specializes replaced-by questioned-by suggested-by response
           supported-by opposed-by);

    my (%nodes, @edges, @queue);

    # here we execute a riff on a spanning tree
    if (%lit) {
        # start the queue with the context node if present
        push @queue, values %lit;
    }
    else {
        # otherwise get a list of all the "top" nodes
        my $i = $ns->ibis;
        my $t = $ns->rdf->type;
        my @pairs = (
            [$i->generalizes, $i->specializes],
            [$i->questions, $i->uri('questioned-by')],
            [$i->uri('suggested-by'), $i->suggests],
        );
        for my $node (map { $m->subjects($t, $_) } @t) {
            my $skip;
            for my $p (@pairs) {
                $skip = $m->count_statements
                    (undef, $p->[0], $node) and last;
                $skip = $m->count_statements
                    ($node, $p->[1], undef) and last;
            }
            next if $skip;

            #next if my @x = $m->subjects($i->generalizes, $node);
            #next if    @x = $m->objects($node, $i->specializes);

            push @queue, $node;
        }
    }

    while (my $s = shift @queue) {
        next unless $s->is_resource;

        my $uu = URI->new($s->uri_value);
        # XXX warn this maybe?
        next unless $uu->isa('URI::urn::uuid');

        my $su = URI->new_abs($uu->uuid, $bs);
        next if $nodes{$su};

        my $n = $nodes{$su} ||= {};

        my $ns = $self->ns;

        # first we get

        if (my @types = $m->objects($s, $ns->rdf->type)) {
            my %t = map +($_->uri_value => $_), @t;
            @types = grep { $_->is_resource && $t{$_->uri_value} } @types;
            $n->{type} = URI->new($types[0]->uri_value) if @types;
        }
        if (my ($created) = $m->objects($s, $ns->dct->created)) {
            $n->{date} = $created->literal_value;
        }
        if (my ($value) = $m->objects($s, $ns->rdf->value)) {
            $n->{label} = $value->literal_value;
        }

        # first we accumulate all the "neighbours" of the node under
        # inspection, then we select which edges we want to display,
        # then we select which of these neighbours we add to the
        # queue.

        # cache of "neighbours"
        my %nbrs;

        for my $p (values %fp, values %rp) {
            # we want to unconditionally add the neighbour, then we
            # want to flip the semantic relation where applicable
            my $pv = $p->uri_value;

            for my $o ($m->objects($s, $p)) {
                next unless $o->is_resource;

                my $ov = $o->uri_value;
                next unless $ov =~ $self->UUID_URN;

                my $x = $nbrs{$pv} ||= {};
                $x->{$ov} = $o;
            }

            # skip if there is no inverse (there always should be)
            my $ip = $inv->{$pv}[0] or do {
                warn "no inverse for $pv";
                next;
            };
            my $iv = $ip->uri_value;

            for my $o ($m->subjects($p, $s)) {
                next unless $o->is_resource;

                my $ov = $o->uri_value;
                next unless $ov =~ $self->UUID_URN;

                my $x = $nbrs{$iv} ||= {};
                $x->{$ov} = $o;
            }
        }

        # now we add only the "forward" edges for this node to the
        # list. 1) subsequent nodes will have their own "forward"
        # edges added; 2) we don't care if these edges will actually
        # be shown because the circos module takes care of that.
        for my $pv (keys %nbrs) {
            my $nodes = $nbrs{$pv};
            my $isfwd = !!$fp{$pv};

            # XXX note this line obviates most of the code in this block
            #next unless $isfwd;

            # reverse node
            unless ($isfwd) {
                $pv = $inv->{$pv}[0] or next;
                $pv = $pv->uri_value;
            }

            my $pu = URI->new($pv);
            my $pl = $lab->{$pv}[1];

            for my $ov (keys %$nodes) {
                my $ou = URI->new($ov);
                $ou = URI->new_abs($ou->uuid, $bs);

                push @edges, {
                    source => $isfwd ? $su : $ou,
                    target => $isfwd ? $ou : $su,
                    type   => $pu,
                    label  => $pl,
                };
            }
        }

        # now we prune out the neighbours that we don't want to display
        my %nope = map {
            my $x = $ns->ibis->uri($_)->uri_value;
            my $y = delete $nbrs{$x};
            $y ? ($x => $y) : ()
        } qw(generalizes questions questioned-by suggests suggested-by);

        # we also flatten out the remaining nodes
        my %ok = map +(%{$_}), values %nbrs;

        # add nodes to queue
        push @queue, values %ok;
        if (grep { $s->equal($_) } values %lit) {
            # add recurse down (?s ibis:generalizes ?o, ?o
            # ibis:specializes ?s) to queue
            %nope = map +(%$_), values %nope;
            push @queue, values %nope;
        }
        else {
            # add downward hierarchy to "stubs"
            my (%stubs, %rstubs);
            for my $pv (keys %nope) {
                my $x = $nope{$pv};
                my $y;
                if ($fp{$pv}) {
                    $y = $stubs{$pv} ||= {};
                }
                else {
                    my $p = $inv->{$pv}[0] or next;
                    $pv = $p->uri_value;
                    $y  = $rstubs{$pv} ||= {};
                }

                #next unless $fp{$pv};
                #$stubs{$pv} ||= {};
                for my $ov (keys %$x) {
                    my $ou = URI->new($ov);
                    $ou = URI->new_abs($ou->uuid, $bs);
                    $y->{$ou} = $ou;
                    #$stubs{$pv}{$ou} = $ou;
                }
            }
            $nodes{$su}{stubs}  = { %{$nodes{$su}{stubs}  ||= {}}, %stubs  };
            $nodes{$su}{rstubs} = { %{$nodes{$su}{rstubs} ||= {}}, %rstubs };
        }
    }

    # now generate the graphic
    my $circos = App::IBIS::Circos->new(
        start     => 0,    # initial degree offset
        end       => $deg, # terminal degree offset
        rotate    => $rot, # offset to previous two values
        gap       => 2,    # units of whitespace between arc slices
        thickness => 50,   # thickness of arc slices
        margin    => 20,   # gap between outer edge and viewbox
        size      => 200,  # overall width/height of the viewbox
        radius    => 270,
        base      => $bs,
        css       => $c->uri_for('/asset/circos.css'),
        ns        => $self->uns,
        node_seq  => [map { $_->uri_value} @t],
        edge_seq  => [map { $_->uri_value} @fp],
        collator  => $c->collator,
    );

    #warn Data::Dumper::Dumper(\%nodes, \@edges);

    my $doc = $circos->plot(
        nodes  => \%nodes,
        edges  => \@edges,
        active => \%lit,
    );

    $c->res->content_type('image/svg+xml');
    $c->res->body($doc);
    # okay so we have approximately 3400 scalar refs going missing.
    # this is almost certainly the xml thinger
    #$c->log->debug(Devel::Gladiator::arena_table());
    # my $all = Devel::Gladiator::walk_arena();
    # # #$c->log->debug(Data::Dumper::Dumper($all->[0]));
    # my %wtf;
    # for my $sv (@$all) {
    #     #next unless ref $sv eq 'SCALAR';
    #     next unless ref($sv) =~ /rdf/i;
    #     #my $x = Data::Dumper::Dumper($sv);
    #     my $x = ref $sv;
    #     $wtf{$x} ||= 0;
    #     $wtf{$x}++;
    #     #$c->log->debug(Data::Dumper::Dumper($sv));
    #     #warn Data::Dumper::Dumper($sv);
    #     #$c->log->debug($sv);
    #     #warn Devel::FindRef::track($sv)
    #     #    if defined $$sv and !ref $$sv and $$sv eq '1';
    #     #warn Devel::FindRef::track($sv) unless defined $$sv;
    # }
    # undef $all;

    # for my $k (sort { $wtf{$b} <=> $wtf{$a} } keys %wtf) {
    #     #next if $wtf{$k} < 500;
    #     warn "$wtf{$k} => $k";
    # }

    # $c->log->debug(sprintf 'node %d statement %d stream %d',
    #                scalar keys %_p_librdf_node_s::OWNER,
    #                scalar keys %_p_librdf_statement_s::OWNER,
    #                scalar keys %_p_librdf_stream_s::OWNER);

    # for my $k (keys %_p_librdf_node_s::OWNER) {
    #     warn sprintf "%s => %s", $k, $_p_librdf_node_s::OWNER{$k};
    # }

    # my %ftw;
    # while (my ($k, $v) = each %wtf) {
    #     my $x = $ftw{$v} ||= [];
    #     push @$x, $k;
    # }

    # for my $n (sort { $b <=> $a } keys %ftw) {
    #     warn ($n, ' ', @{$ftw{$n}});
    # }
}

# sub _wtfsort {
#     my ($obj, $l, $r) = @_;
#     return ($obj->{$r} || 0) <=> ($obj->{$l} || 0);
# }

sub concepts :Local {
    my ($self, $c) = @_;

    # get some input. innnnnnn putttttt
    my $req = $c->req;
    my $ns  = $self->ns;
    my $b   = $req->base;
    my $q   = $req->query_parameters;
    my $ref = $q->{subject};
    # ditto

    my $deg = $q->{degrees} || 360;
    my $rot = $q->{rotate}  || 0;

    # other handy things
    my $lab = $self->labels;
    my $inv = $self->inverse;
    my $m   = $c->rdf_cache;

    # these are the nodes we want lit up; we get them from QS or Referer
    my %lit;
    if ($ref) {
        # lol @ this
        $ref = [$ref] unless ref $ref;
        for my $uu (@$ref) {
            next unless $uu =~ $self->UUID_RE;
            $uu = iri("urn:uuid:$1");
            my $su = URI->new($uu->uri_value);
            $su = URI->new_abs($su->uuid, $b);
            $lit{$su} = $uu;
        }
    }

    # generate semantic relations

    my @fp = map { $ns->skos->uri($_) } qw(narrower narrowerTransitive
                                           narrowMatch related closeMatch
                                           exactMatch);
    my %fp = map { $_->uri_value => $_ } @fp;
    my %rp = map { my $x = $ns->skos->uri($_); $x->uri_value => $x }
        qw(broader broaderTransitive broadMatch related closeMatch exactMatch);

    # note the symmetric properties are in both groups.

    # for the concepts we just want to get them all and sort them
    # alphabetically.

    my (%nodes, @edges);

    for my $s ($m->subjects($ns->rdf->type, $ns->skos->Concept)) {
        next unless $s->is_resource;
        my $uu = URI->new($s->uri_value);
        next unless $uu->isa('URI::urn::uuid');

        my $su = URI->new_abs($uu->uuid, $b);
        next if $nodes{$su};

        my $n = $nodes{$su} ||= {};

        my ($label) = $m->objects($s, $ns->skos->prefLabel);

        $n->{label} = $label ? $label->literal_value : '';
        $n->{type}  = 'skos:Concept';

        # do the neighbour thing again
        my %nbrs;

        for my $p (values %fp, values %rp) {
            my $pv = $p->uri_value;

            for my $o ($m->objects($s, $p)) {
                next unless $o->is_resource;
                my $ov = $o->uri_value;
                next unless $ov =~ $self->UUID_URN;

                my $x = $nbrs{$pv} ||= {};
                $x->{$ov} = $o;
            }

            # now we do the reverse thing again
            my $ip = $inv->{$pv}[0] or next;
            my $iv = $ip->uri_value;

            for my $o ($m->subjects($p, $s)) {
                next unless $o->is_resource;

                my $ov = $o->uri_value;
                next unless $ov =~ $self->UUID_URN;

                my $x = $nbrs{$iv} ||= {};
                $x->{$ov} = $o;
            }
        }

        # now we do this again
        for my $pv (keys %nbrs) {
            next unless $fp{$pv};
            my $pu = URI->new($pv);
            my $pl = $lab->{$pv}[1];
            for my $ov (keys %{$nbrs{$pv}}) {
                my $ou = URI->new($ov);
                $ou = URI->new_abs($ou->uuid, $b);
                push @edges, {
                    source    => $su,
                    target    => $ou,
                    type      => $pu,
                    label     => $pl,
                    symmetric => $inv->{$pv}[0]->uri_value eq $pv,
                };
            }
        }

    }

    my $circos = App::IBIS::Circos->new(
        start     => 0,    # initial degree offset
        end       => $deg, # terminal degree offset
        rotate    => $rot, # offset to previous two values
        gap       => 2,    # units of whitespace between arc slices
        thickness => 50,   # thickness of arc slices
        margin    => 20,   # gap between outer edge and viewbox
        size      => 200,  # overall width/height of the viewbox
        radius    => 270,
        base      => $b,
        css       => $c->uri_for('/asset/circos.css'),
        ns        => $self->uns,
        node_seq  => [$ns->skos->Concept->uri_value],
        edge_seq  => [map { $_->uri_value } @fp],
        collator  => $c->collator,
    );

    #warn Data::Dumper::Dumper(\%nodes, \@edges);
    #warn Data::Dumper::Dumper(\%lit);


    my $doc = $circos->plot(
        nodes  => \%nodes,
        edges  => \@edges,
        active => \%lit,
    );

    $c->res->content_type('image/svg+xml');
    $c->res->body($doc);

}

=encoding utf8

=head1 AUTHOR

dorian,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
