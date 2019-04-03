package App::IBIS::Controller::Root;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

BEGIN {
#    extends 'App::IBIS::Base::Controller';
    extends 'Catalyst::Controller';
    with    'App::IBIS::Role::Schema';
    with    'Role::Markup::XML';
#    require Devel::Gladiator;
#    require Devel::FindRef;
#    $RDF::Redland::Debug = 1;
}

# constants
use RDF::Trine qw(iri blank literal);
use RDF::Trine::Namespace qw(RDF);
use constant IBIS => RDF::Trine::Namespace->new
    ('https://privatealpha.com/ontology/ibis/1#');

use RDF::KV;
use DateTime;
use DateTime::Format::W3CDTF;

use Scalar::Util ();
use List::MoreUtils qw(any);

#use App::IBIS::HivePlot;
use App::IBIS::Circos;

my $UUID_RE  = qr/([0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){4}[0-9A-Fa-f]{8})/;
my $UUID_URN = qr/^urn:uuid:([0-9a-f]{8}(?:-[0-9a-f]{4}){4}[0-9a-f]{8})$/i;

my %FORMBP = (
    -name            => 'form',
    method           => 'POST',
    action           => '',
    'accept-charset' => 'utf-8',
);

my %FOOTER = (
    -name => 'footer', -content => {
        -name => 'nav', -content => {
            -name => 'ul', -content => [
                { -name => 'li', -content => { href => '/',
                                               -content => 'Overview' } },
                { -name => 'li', -content => {
                    href => '/we-have-issues',
                    -content => 'What is this thing?' } },
            ] } },
);

has _dispatch => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $ns = $self->ns;
        my $ibis = $ns->ibis;
        my $skos = $ns->skos;
        return {
            $ibis->Issue->value      => '_get_ibis',
            $ibis->Position->value   => '_get_ibis',
            $ibis->Argument->value   => '_get_ibis',
            $skos->Concept->value    => '_get_concept',
            $skos->Collection->value => '_get_collection',
        };
    },
);

use constant TOGGLE => {
    -name => 'form', id => 'toggle-which',
    -content => { -name => 'fieldset', -content => [
        { -name => 'label', -content => [
            { -name => 'input', type => 'radio',
              name => 'new-item', value => '' },
            ' Connect existing' ] },
        { -name => 'label', -content => [
            { -name => 'input', type => 'radio',
              name => 'new-item', value => 1, checked => 'checked' },
            ' Create new' ] } ] }
};

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

App::IBIS::Controller::Root - Root Controller for App::IBIS

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    if ($req->method == 'DELETE') {
        $c->forward('truncate');
        return;
    }

    my $ns = $self->ns;
    my $m  = $c->rdf_cache;

    my %concepts;
    for my $s ($m->subjects($ns->rdf->type, $ns->skos->Concept)) {
        next unless $s->is_resource;
        next unless $s->uri_value =~ /^urn:uuid:/i;
        my $uri     = URI->new($s->uri_value);
        my ($label) = $m->objects($s, $ns->skos->prefLabel);
        next unless $label && $label->is_literal;
        my $x = $concepts{$label->literal_value} ||= {};
        $x->{$uri} = $uri;
    }

    my @li;
    for my $c ($c->collator->sort(keys %concepts)) {
        for my $uuid (sort values %{$concepts{$c}}) {
            push @li, { -name => 'li',
                        -content => {
                            href => '/' . $uuid->uuid, -content => $c } };
        }
    }

    my $new ||= '/' . $self->uuid4;

    my $doc = $c->stub(
        uri => $req->base,
        title => 'Welcome to App::IBIS: We Have Issues.',
        content => [
            { -name => 'main', -content => [
            { -name => 'section', class => 'index ibis',
              -content => [
                  { -name => 'h1', -content => 'Argumentation Structure' },
                  { -name => 'figure',
                    -content => { -name => 'object',
                                  type => 'image/svg+xml', data => '/ci2' } },
                  $self->_do_404($new), # not really a 404 but whatev
              ] },
            { -name => 'section', class => 'index skos',
              -content => [
                  { -name => 'h1', -content => 'Concept Scheme' },
                  { -name => 'figure',
                    -content => { -name => 'object',
                                  type => 'image/svg+xml',
                                  data => '/concepts?rotate=180' } },
                  { %FORMBP, action => $new,
                    -content => { -name => 'fieldset', -content => [
                        { -name => 'legend',
                          -content => 'Start a new Concept' },
                        { -name => 'input', type => 'text',
                          name => '= skos:prefLabel' },
                        { -name => 'button', name => '= rdf:type :',
                          value => 'skos:Concept', -content => 'Go' } ] } },
              ] },
            { -name => 'section', class => 'index list',
              -content => [$self->_do_index($c),
                           { -name => 'section', -content => [
                               { -name => 'h2', -content => 'Concepts' },
                               { -name => 'ul', -content => \@li } ] },
                       ] },
        ]},
            { -name => 'footer', -content => {
                -name => 'nav', -content => {
                    -name => 'ul', -content => [
                        { -name => 'li', -content => {
                            href => '/', -content => "\xa0" } }, # empty overview
                        { -name => 'li', -content => {
                            href => '/we-have-issues',
                            -content => 'What is this thing?' } },
                    ] } } }
        ]);

    $resp->body($doc);
}

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
            if (my ($uuid) = ($s->path =~ $UUID_RE)) {
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
                next unless $ov =~ $UUID_URN;

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
                next unless $ov =~ $UUID_URN;

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
            next unless $uu =~ $UUID_RE;
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
                next unless $ov =~ $UUID_URN;

                my $x = $nbrs{$pv} ||= {};
                $x->{$ov} = $o;
            }

            # now we do the reverse thing again
            my $ip = $inv->{$pv}[0] or next;
            my $iv = $ip->uri_value;

            for my $o ($m->subjects($p, $s)) {
                next unless $o->is_resource;

                my $ov = $o->uri_value;
                next unless $ov =~ $UUID_URN;

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


sub uuid :Private {
    my ($self, $c, $uuid) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    my $path = '/' . lc $uuid;
    $uuid = RDF::Trine::Node::Resource->new('urn:uuid:' . lc $uuid);

    # check request method
    my $method = $req->method;
    if ($method eq 'POST') {
        # check for input
        eval {
            $self->_post_uuid($c, $uuid, $req->body_parameters);
        };
        if ($@) {
            $c->res->body("wat $@");
        }
        else {
            $resp->redirect($path);
        }
    }
    elsif ($method eq 'GET' or $method eq 'HEAD') {
        # do this for now until we can handle html properly
        $resp->content_type('application/xhtml+xml');
        # check model for subject
        my $m = $c->model('RDF');
        my $g = $c->graph;
        if (my @o = $m->objects($uuid, $self->ns->rdf->type, $g)) {
            # GHETTO FRESNEL
            my $d = $self->_dispatch;
            if (my ($handler) = map { $d->{$_->value} }
                    grep { $d->{$_->value} } @o) {
                $resp->status(200);
                $c->forward($handler, [$uuid]);
            }
            else {
                $c->log->debug('no handler for type(s) ' . join ' ', @o);
                $resp->status(501);

                my $msg = $c->stub(content => 'sorry boss');
                $resp->body($msg);
            }
        }
        else {
            # 404
            my $new = $uuid->uri_value;
            $c->log->debug("failed to identify $new");
            $new =~ s!urn:uuid:!/!;
            $resp->status(404);
            my $msg = $c->stub(
                uri => $req->base,
                title => 'Nothing here. Make something?',
                content => $self->_do_404($new));
            $resp->body($msg);
        }
    }
    elsif ($method eq 'DELETE') {
        $c->forward('_delete_uuid', [$uuid]);
    }
    else {
        $resp->status('405');
        $resp->content_type('text/plain');
        # XXX something wittier perhaps
        $resp->body('Method not allowed.');
    }
}

sub _delete_uuid :Private {
    my ($self, $c, $uuid) = @_;
    my $m = $c->model('RDF');
    my $g = $c->graph;

    $c->log->debug($g);

    $c->log->debug(sprintf 'Model size: %d', $m->size);

    $m->begin_bulk_ops;
    $m->remove_statements($uuid, undef, undef, $g);
    $m->remove_statements(undef, undef, $uuid, $g);
    $m->end_bulk_ops;

    $c->log->debug(sprintf 'New size: %d', $m->size);

    my $resp = $c->response;
    $resp->status('204');
    $resp->content_type('text/plain');
    $resp->body('');
    return;
}

sub truncate :Private {
    my ($self, $c) = @_;

    my $m = $c->model('RDF');
    my $g = $c->graph;

    $c->log->debug(sprintf 'Model size: %d', $m->size);

    $m->begin_bulk_ops;
    $m->remove_statements(undef, undef, undef, $g);
    $m->end_bulk_ops;

    $c->log->debug(sprintf 'New size: %d', $m->size);

    my $resp = $c->response;
    $resp->status('204');
    $resp->content_type('text/plain');
    $resp->body('');
    return;
}

sub dump :Local {
    my ($self, $c) = @_;
    my $resp = $c->res;

    $resp->status(200);
    $resp->content_type('text/plain');
    my $serializer = RDF::Trine::Serializer->new
        ('turtle', namespaces => $self->ns);
    $resp->body($serializer->serialize_model_to_string($c->rdf_cache));
}

sub bulk :Local {
    my ($self, $c) = @_;

    my $req = $c->req;
    my $rm  = $req->method;

    if ($rm eq 'GET' or $rm eq 'HEAD') {

        my $doc = $c->stub(
            title => 'Load a (Turtle) data file',
            uri   => $req->uri,
            content => {
                %FORMBP, enctype => 'multipart/form-data', -content => [
                    { -name => 'input', type => 'file', name => 'data' },
                    { -name => 'button', -content => 'Upload' },
                ] },
        );

        $c->res->body($doc);
        return;
    }
    elsif ($rm eq 'POST') {
        my $up = $req->upload('data');

        my $m = $c->model('RDF');
        my $g = $c->graph;
        #my $fh = $up->decoded_fh(':raw');
        #$c->log->debug($up->charset);
        #$fh->binmode(':raw');

        # RDF::Trine 1.019 apparently no longer fucks up utf8
        my $p = RDF::Trine::Parser->new('turtle');

        $p->parse(undef, $up->decoded_slurp(':utf8'),
                  sub { $m->add_statement(shift, $g) });

        $c->res->redirect('/');
        return;
    }
    else {
        $c->res->status(405);
        $c->res->body('Method not allowed');
    }
}

sub _date_seq {
    my @literals = grep { $_->is_literal && $_->has_datatype
                              && $_->literal_datatype =~ /date(Time)?$/ } @_;
    my $dtf = DateTime::Format::W3CDTF->new;
    my @out;
    for my $literal (@literals) {
        my $dt = eval { $dtf->parse_datetime($literal->literal_value) };
        next if $@;
        push @out, $dt;
    }
    @out = sort { DateTime->compare($a, $b) } @out;

    wantarray ? @out : \@out;
}

sub feed :Local {
    my ($self, $c) = @_;

    my $ns = $self->ns;
    my $m  = $c->rdf_cache;

    # specify relevant types
    my @t  = map { $ns->ibis->uri($_) } qw(Issue Position Argument);

    # get unique subjects
    my %s = map { $_->uri_value => { id => $_ } }
        grep { $_->is_resource }
            map { $m->subjects($ns->rdf->type, $_) } @t;

    # this is dumb because it does all the work before sending the
    # cache response but whatever

    for my $v (values %s) {
        my $s = $v->{id};
        ($v->{title})   = $m->objects($s, $ns->rdf->value);
        ($v->{author})  = $m->objects($s, $ns->dct->creator);
        ($v->{created}) = _date_seq($m->objects($s, $ns->dct->created));
        $v->{modified}  = _date_seq($m->objects($s, $ns->dct->modified));
    }

    # look for if-modified-since header
    my @entries;
    if (my $ims = $c->req->headers->if_modified_since) {
        $ims = DateTime->from_epoch(epoch => $ims);
        $c->log->debug("Found If-Modified-Since: $ims");

        for my $k (keys %s) {
            # mtime is either latest mtime or ctime
            my $mtime = @{$s{$k}{modified}}
                ? $s{$k}{modified}[-1] : $s{$k}{created};
            delete $s{$k} if $mtime and $ims >= $mtime;
        }
    }
    @entries = sort { DateTime->compare(
        (@{$a->{modified}} ? $a->{modified}[-1] : $a->{created}),
        (@{$b->{modified}} ? $b->{modified}[-1] : $b->{created})) } values %s;

    my $resp = $c->res;

    if (@entries) {
        require Data::Dumper;
        $resp->status(200);
        $resp->content_type('application/xml');
        my $lm = @{$entries[-1]{modified}} ?
            $entries[-1]{modified}[-1] : $entries[-1]{created};
        $resp->headers->last_modified($lm->epoch);

        my $dtf = DateTime::Format::W3CDTF->new;

        my @out;
        for my $entry (@entries) {
            my $published = $entry->{created};
            my $updated   = @{$entry->{modified}} ?
                $entry->{modified}[-1] : $published;
            my $uuid = URI->new($entry->{id}->uri_value);
            my $link = $c->req->base . $uuid->uuid;
            push @out, {
                -name => 'entry',
                -content => [
                    { -name => 'title',
                      -content => $entry->{title}->literal_value },
                    { -name => 'link', rel => 'alternate',
                      type => 'text/html', href => $link },
                    { -name => 'id', -content => $uuid->as_string },
                    { -name => 'updated',
                      -content => $dtf->format_datetime($updated) },
                    { -name => 'published',
                      -content => $dtf->format_datetime($published) },
                ]
            };
        }

        my $doc = $c->stub;
        $self->_XML(
            doc => $doc,
            spec => {
                -name => 'feed', xmlns => 'http://www.w3.org/2005/Atom',
                -content => [
                    { -name => 'title',
                      -content => 'New Issues, Positions and Arguments' },
                    { -name => 'updated',
                      -content => $dtf->format_datetime($lm) }, @out ] } );

        $resp->body($doc);
    }
    else {
        $resp->status(304);
    }
}

sub _get_concept :Private {
    my ($self, $c, $subject) = @_;

    my $m  = $c->rdf_cache;
    my $ns = $self->ns;

    my ($label) = $m->objects($subject, $ns->skos->prefLabel);
    my ($desc)  = $m->objects($subject, $ns->skos->description);
    $desc = $desc ? $desc->literal_value : '';

    my $uu = URI->new($subject->uri_value);

    my %t = map { my $x = $ns->ibis->uri($_);
                  $x->uri_value => $x } qw(Issue Position Argument);
    my @ibis;
    for my $ib ($m->subjects($ns->dct->references, $subject)) {
        next unless $ib->is_resource;
        my $iu = URI->new($ib->uri_value);
        next unless $iu->isa('URI::urn::uuid');
        my @types = $m->objects($ib, $ns->rdf->type);
        next unless grep { $t{$_->value} } @types;

        push @ibis, $iu->uuid;
    }

    my $doc = $c->stub(
        uri   => $c->req->uri,
        title => $label->value,
        attr  => { typeof => 'skos:Concept' },
        content => [
            { -name => 'main', -content => [
                { -name => 'figure', class => 'aside', -content => [
                    { -name => 'object', class => 'baby hiveplot',
                      type => 'image/svg+xml',
                      data => $c->uri_for('ci2',
                                          { subject => \@ibis, degrees => 240,
                                            rotate => 60 }) },
                    { -name => 'object', class => 'hiveplot',
                      type => 'image/svg+xml',
                      data => $c->uri_for(concepts => {
                          subject => $uu->uuid,
                          degrees => 240, rotate => 60 }) },
                ] },
                { -name => 'article', -content => [
                    { -name => 'section', class => 'self', -content => [
                        { -name => 'h1', -content => { %FORMBP, -content => [
                            { -name => 'input', type => 'text',
                              name => '= skos:prefLabel',
                              value => $label->literal_value },
                            { -name => 'button', class => 'fa fa-repeat',
                              -content => '', } ] } },
                        { %FORMBP, -content => [
                            { -name => 'textarea', class => 'description',
                              name => '= skos:description', -content => $desc },
                            { -name => 'button', class => 'update fa fa-repeat',
                              -content => '' } ] },
                        $self->_do_link_form($c, $subject),
                        $self->_do_link_form($c, $subject, 1),
                    ] },
                    $self->_do_concept_neighbours($c, $subject),
                    { -name => 'section', class => 'edit', -content => [
                        TOGGLE,
                        $self->_do_concept_create_form($c, $subject),
                        $self->_do_concept_connect_form($c, $subject),
                    ] },
                ] },
            ] }, \%FOOTER,
        ],
    );

    $c->res->body($doc);
}

# the order we would like the neighbours to show up in
my @SKOS_SEQ = (
    ['Has Narrower'  => ['', 'narrower'],
     # ['Transitive', 'narrowerTransitive'],
     ['Narrow Match', 'narrowMatch']],
    ['Has Related' => ['', 'related'],
     ['Close Match', 'closeMatch'], ['Exact Match', 'exactMatch']],
    ['Has Broader' => ['', 'broader'],
     # ['Transitive', 'broaderTransitive'],
     ['Broad Match', 'broadMatch']],
);

sub _do_concept_neighbours {
    my ($self, $c, $subject) = @_;

    my $bs  = $c->req->base;
    my $m   = $c->rdf_cache;
    my $ns  = $self->ns;
    my $inv = $self->inverse;
    my $sv  = $subject->uri_value;

    my @out;

    for my $col (@SKOS_SEQ) {
        my ($label, @row) = @$col;

        my @subs;
        for my $pair (@row) {
            my ($sh, $p) = @$pair;
            $p = $ns->skos->uri($p);

            # collect forward and reverse versions of a given relation
            my (@li, %seen);
            for my $o ($m->objects($subject, $p),
                       $m->subjects($inv->{$p->uri_value}[0], $subject)) {
                next unless $o->is_resource;
                next if $o->equal($subject);

                # do not duplicate for redundantly asserted relations
                my $ov = $o->uri_value;
                next if $seen{$ov};
                $seen{$ov} = $o;

                # double-check this is a concept
                next unless $m->count_statements
                    ($o, $ns->rdf->type, $ns->skos->Concept);
                next unless $o->uri_value =~ $UUID_URN;

                # now convert to http uri
                my $ou = URI->new($ov);
                $ou = URI->new_abs($ou->uuid, $bs);

                # get label
                my ($lab) = $m->objects($o, $ns->skos->prefLabel);

                # generate rdf-kv form keys
                my $fp = sprintf '- %s :', $ns->abbreviate($p);
                my $rp = sprintf '-! %s :',
                    $ns->abbreviate($inv->{$p->uri_value}[0]);

                # label may be undef
                my $cnt = $lab ? $lab->literal_value : '';

                # now make the list item
                push @li, { -name => 'li', -content => { %FORMBP, -content => [
                    { -name => 'input', type => 'hidden', name => $rp,
                      value => $ov },
                    { -name => 'button', class => 'disconnect fa fa-unlink',
                      name => $fp, value => $ov },
                    { href => $ou, -content => $cnt } ] } };
            }

            # now sort the bugger
            @li = sort { $a->{-content}{-content}[-1]{-content}
                             cmp $b->{-content}{-content}[-1]{-content} } @li;
            if (@li) {
                my @x = ({ -name => 'ul', -content => \@li });
                unshift @x, { -name => 'h4', -content => $sh } if $sh;
                push @subs, { -name => 'section', -content => \@x };
            }
        }

        push @out, { -name => 'aside', class => 'predicate', -content => [
            { -name => 'h3', -content => $label }, @subs ] } if @subs;
    }

    return { -name => 'section', class => 'relations', -content => \@out };
}

sub _concept_menu {
    my ($self, $c, $flag) = @_;

    my $ns = $self->ns;

    my @out;

    # i suppose it doesn't make sense for the ui to permit multiple
    # semantic relations at once, so let's just make the entire damn
    # thing radio buttons


    for my $col (@SKOS_SEQ) {
        my ($lab, @row) = @$col;

        my ($leg, @li);

        my $xp;

        for my $i (0..$#row) {
            my ($sh, $p) = @{$row[$i]};
            $p = $ns->skos->uri($p);

            my %radio = (
                -name => 'input', type => 'radio', name => '$ predicate',
                value => $ns->abbreviate($p),
            );
            $radio{checked} = 'checked' if $p->equal($ns->skos->related);

            if ($i) {
                push @li, { -name => 'li', -content => {
                    -name => 'label', -content => [\%radio, " $sh"] } };
            }
            else {
                $xp = $ns->abbreviate($p);
                $leg = { -name => 'h4', -content => {
                    -name => 'label', -content => [\%radio, " $lab"] } };
            }
        }

        @li = { -name => 'ul', -content => [@li] } if @li;

        push @out, { -name => 'fieldset', rel => $xp,
                     class => "skos relation", -content => [$leg, @li] };
    }

    wantarray ? @out : \@out;
}

sub _do_concept_create_form {
    my ($self, $c, $subject) = @_;

    my $new = '/' .$self->uuid4;


    return { %FORMBP, id => 'create-new', action => $new, -content => [
        { -name => 'input', type => 'hidden', name => 'rdf:type :',
          value => 'skos:Concept' },
        { -name => 'input', type => 'hidden', name => '! $predicate :',
          value => $subject->uri_value },
        { -name => 'fieldset', class => 'edit-group', -content => [
            $self->_concept_menu($c, 1),
            { -name => 'div', class => 'interaction', -content => [
                { -name => 'input', type => 'text', class => 'new-value',
                  name => 'skos:prefLabel' },
                { -name => 'button', class => 'fa fa-plus', -content => '' }
            ] } ] } ]};
}

sub _do_concept_connect_form {
    my ($self, $c, $subject) = @_;
    my $ns = $self->ns;
    my $m  = $c->rdf_cache;

    my %c;
    for my $c ($m->subjects($ns->rdf->type, $ns->skos->Concept)) {
        next unless $c->is_resource;
        my $cv = $c->uri_value;
        next unless $cv =~ $UUID_URN;

        my ($lab) = $m->objects($c, $ns->skos->prefLabel);
        $c{$cv} = $lab ? $lab->value : '';
    }

    my @opt = map +{ -name => 'option', value => $_, -content => $c{$_} },
        sort { $c{$a} cmp $c{$b} } keys %c;

    return { %FORMBP, id => 'connect-existing', action => '',
             -content => {
                 -name => 'fieldset', class => 'edit-group', -content => [
                     $self->_concept_menu($c, 1),
                     { -name => 'div', class => 'interaction', -content => [
                         { -name => 'select', class=> 'target',
                           name => '$predicate :', -content => \@opt },
                         { -name => 'button', class => 'fa fa-link',
                           -content => '' } ] } ] } };
}

sub _get_collection :Private {
    my ($self, $c, $subject) = @_;

    # XXX COPY THIS SHIT FROM THE OTHER ONE

    my $uri = $c->req->uri;

    my $m = $c->rdf_cache;

    #warn $subject;
    my $rns = $self->ns;

    # XXX THIS CAN GET AWAY ON US
    my ($type)  = $m->objects($subject, $rns->rdf->type);
    my ($title) = $m->objects($subject, $rns->skos->prefLabel);
    my ($desc)  = $m->objects($subject, $rns->skos->description);

    my %attrs;
    $attrs{typeof} = $rns->abbreviate($type) if $type;

    my $maybetitle = $title ? $title->value : '';

    my $doc = $c->stub(
        uri   => $uri,
        title => $maybetitle || $subject->value,
        attr  => \%attrs,
        content => { %FORMBP, action => $uri, -content => [
            { -name => 'h1', -content => {
                -name => 'input', name => '= skos:prefLabel',
                value => $maybetitle } },
            { -name => 'p', -content => {
                -name => 'textarea', name => '= skos:description',
                -content => $desc ? $desc->value : '' }},
            $self->_do_index($c, $subject) ] },
    );

    # XXX forward this maybe?
    $c->res->body($doc);
}

sub _get_ibis :Private {
    my ($self, $c, $subject) = @_;

    my $uri = $c->req->uri;
    my $uu  = URI->new($subject->uri_value);
    my $su  = URI->new_abs($uu->uuid, $uri);

    my $m = $c->rdf_cache;

    #warn $subject;
    my $rns = $self->ns;
    my $ns = $rns;

    # XXX THIS CAN GET AWAY ON US
    my ($type)  = $m->objects($subject, $rns->rdf->type);
    my ($title) = $m->objects($subject, $rns->rdf->value);

    $c->log->debug($title->value);

    my %attrs;

    # XXX DERIVE THIS BETTER
    my $label;
    if ($type) {
        $attrs{typeof} = $rns->abbreviate($type);
        ($label) = ($attrs{typeof} =~ /:(.*)/);
        $label .= ': ';
    }

    my @concepts;
    for my $co ($m->objects($subject, $ns->dct->references)) {
        next unless $co->is_resource;
        my $cu = URI->new($co->uri_value);
        next unless $cu->isa('URI::urn::uuid');
        next unless $m->count_statements
            ($co, $ns->rdf->type, $ns->skos->Concept);

        push @concepts, $cu->uuid;
    }

    my $ci2 = $c->uri_for('ci2', { subject => $uu->uuid,
                                   degrees => 240, rotate => 60, });

    my $css = $c->config->{css} || '/asset/main.css';

    my (undef, $doc) = $self->_XHTML(
        ns    => $self->uns,
        uri   => $uri,
        title => $label . $title ? $title->value : '',
        link  => [
            { rel => 'stylesheet', type => 'text/css', href => $css },
            { rel => 'alternate', type => 'application/atom+xml',
              href => '/feed' } ],
        head  => [
            map +{ -name => 'script', type => 'text/javascript', src => $_ },
            qw(/asset/jquery.js /asset/main.js) ],
        attr  => \%attrs,
        content => [ { -name => 'main', -content => [
            { -name => 'figure', class => 'aside', -content => [
                { -name => 'object', class => 'other baby hiveplot',
                  type => 'image/svg+xml',
                  data => $c->uri_for('concepts',
                                      { subject => \@concepts,
                                        degrees => 240, rotate => 60, }) },
                { -name => 'object', class => 'hiveplot', data => $ci2,
                  type => 'image/svg+xml', -content => '(Circos Plot)' }
            ]},
            { -name => 'article', -content => [
                $self->_do_content($c, $subject),
                #{ -name => 'hr', class => 'separator' },
                { -name => 'section', class => 'edit', -content => [
                    TOGGLE,
                    $self->_do_connect_form($c, $subject, $type),
                    $self->_do_create_form($c, $uri, $type) ] },
            ] } ] },
                     \%FOOTER,
        ],
    );

    # XXX forward this maybe?
    $c->res->body($doc);
}

sub _to_urn {
    my $path = shift;
    #warn "lols $path";
    if (my ($uuid) = ($path =~ $UUID_RE)) {
        #warn $uuid;
        my $out = URI->new("urn:uuid:$uuid");
        return $out;
    }
    return $path;
}

sub _from_urn {
    my ($uuid, $base) = @_;
    $uuid = URI->new($uuid) unless ref $uuid;
    $uuid = URI->new($uuid->uri_value) if $uuid->isa('RDF::Trine::Node');
    URI->new_abs($uuid->uuid, $base);
}

sub _post_uuid {
    my ($self, $c, $subject, $content) = @_;
    my $uuid = URI->new($subject->uri_value);

    # XXX lame
    my $ns = URI::NamespaceMap->new({
        rdf  => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        ibis => 'https://privatealpha.com/ontology/ibis/1#',
        skos => 'http://www.w3.org/2004/02/skos/core#',
        dct  => 'http://purl.org/dc/terms/',
    });

    my $rns = $self->ns;
    my $m = $c->model('RDF'); # this actually needs the writable one
    my $g = $c->graph;

    my $kv = RDF::KV->new(
        #subject    => 'http://deuce:5000/' . $uuid->uuid,
        subject    => $c->req->base . $uuid->uuid,
        namespaces => $ns,
        graph      => $g->value,
        callback   => \&_to_urn,
   );

    my $patch = $kv->process($content);
    #warn Data::Dumper::Dumper($patch);

    $c->log->debug("Initial size: " .$m->size);
    # add a timestamp
    # eval { $m->count_statements($subject, undef, undef) };
    # if ($@) {
    #     $c->log->debug($@);
    #     return;
    # }

    # XXX HACK this should really apply to all subjects (resources?)
    # in the graph but RDF::KV has no way of spitting them all out
    unless ($m->count_statements($subject, $rns->dct->created, undef, $g)) {
        my $now = literal(DateTime->now . 'Z', undef, $rns->xsd->dateTime);
        $patch->add_this($subject, $rns->dct->created, $now, $g);
    }

    $m->begin_bulk_ops;
    eval { $patch->apply($m) };
    if ($@) {
        $c->log->error("cannot apply patch: $@");
    }
    else {
        $m->end_bulk_ops;
        $c->log->debug("New size: " .$m->size);
    }

    #$m->_store->_model->sync;
}

=head2 default

Standard 404 error page

=cut

sub default :Path :Does('+CatalystX::Action::Negotiate') {
    my ( $self, $c, @p) = @_;

    if ($p[0] and $p[0] =~ $UUID_RE) {
        $c->forward(uuid => [lc $p[0]]);
        return;
    }
}


sub _naive_typeof {
    my ($self, $c, @types) = @_;
    my $m = $c->rdf_cache;
    my %out;
    for my $t (@types) {
        my $v = $t->value;
        $out{$v} ||= {};
        for my $s ($m->subjects($self->ns->rdf->type, $t)) {
            $out{$v}{$s->value} = 1;
        }
    }
    \%out;
}

# XXX make a resource that returns logged-in status and user info (if
# logged in of course)

# XXX make a resource containing all objects of type X then just turn
# it into a select.

sub _select {
    my ($self, $c, $subject) = @_;
    my @labels = qw(Issue Position Argument);
    my @types  = map { $self->ns->ibis->uri($_) } @labels;
    my $map    = $self->_naive_typeof($c, @types);
    my $model  = $c->rdf_cache;
    my @opts;
    for my $i (0..$#labels) {
        my $l = $labels[$i];
        my $t = $types[$i];
        my $v = $t->value;

        # XXX this will crash
        my $coll = $c->collator;
        my $rdfv = $self->ns->rdf->value;
        my @pairs = sort {
            $coll->cmp(($a->[1] ? $a->[1]->value : ''),
                       ($b->[1] ? $b->[1]->value : ''))
        } map {
            my $s = iri($_); [$s, $model->objects($s, $rdfv)]
        } keys %{$map->{$v} || {}};

        my @o;
        # XXX this might be a blank node but not on my watch
        for my $pair (@pairs) {
            my ($s, $val) = @$pair;
            next if $subject->equal($s);

            my $text = $val ? $val->value : $s->value;
            my $ss   = $s->value;
            push @o, { -name => 'option',
                       about => $ss, value => $ss, -content => $text };
        }

        push @opts, { -name => 'optgroup', about => $v, label => $l,
                      rev => 'rdf:type', -content => \@o } if @o;
    }

    return { -name => 'select', class => 'target',
             name => '$ obj', -content => \@opts };
}

sub _menu {
    my ($self, $c, $type, $flag) = @_;
    my $ns  = $self->ns;

    my @labels = qw(Issue Position Argument);
    my @types  = map { $ns->ibis->uri($_) } @labels;

    my @out;

    my $map = $self->predicate_map;

    # XXX TEMPORARY
    my @rep = map { $ns->ibis->uri($_) } qw(replaces replaced-by);

    my @cls;

    for my $i (0..$#labels) {
        my $v = $type->uri_value;

        # my @radio;
        # for my $item (@{$map->{$v}{$types[$i]->uri_value} || []}) {
        #     # XXX TEMPORARY
        #     next if grep { $_->equal($item->[0]) } @rep;

        #     my $curie = $ns->abbreviate($item->[0]);

        #     my $name = '$pred :';
        #     $name = '! ' . $name if $flag;

        #     push @radio, {
        #         -name => 'li', about => $curie, -content => {
        #             -name => 'label', -content => [
        #                 { -name => 'input', type => 'radio',
        #                   name => $name, value => $curie },
        #                 ' ' . $item->[1] ] } };
        # }

        my @checkbox;
        for my $item (@{$map->{$v}{$types[$i]->uri_value} || []}) {
            # XXX TEMPORARY
            next if grep { $_->equal($item->[0]) } @rep;

            my $curie = $ns->abbreviate($item->[0]);
            my $name  = $curie . ' : $';
            $name = '! ' . $name if $flag;
            push @checkbox, {
                -name => 'li', about => $curie, -content => {
                    -name => 'label', -content => [
                        { -name => 'input', type => 'checkbox',
                          name => $name, value => '$obj' },
                        ' ' . $item->[1] ] } };
        }

        my $type = $ns->abbreviate($types[$i]);

        my %attr = (
            class => 'type-toggle',
            type  => 'radio',
            name  => $flag ? 'rdf:type :' : 'rdf-type',
            #value => $flag ? $ns->abbreviate($types[$i]) : '',
            value => $type,
        );
        $attr{checked}  = 'checked' if $i == 0;
        #$attr{disabled} = 'disabled' unless @checkbox;

        my $class = 'relation ' . lc $labels[$i];
        $class .= ' selected' unless $i;

        push @cls, { -name => 'label', -content => [
            { -name => 'input', %attr }, " $labels[$i]" ] };

        push @out, { -name => 'fieldset', about => $type,
                     class => $class, -content => [ !!@checkbox ? {
                         -name => 'ul', -content => \@checkbox } : () ] };
    }

    push @out, { -name => 'fieldset', class => 'types',
                 -content => { -name => 'ul', -content => [
                     map +( { -name => 'li', -content => $_}), @cls] } };
    @out;
}

sub _coerce_datetime {
    my $d = shift;
    return unless $d and Scalar::Util::blessed($d) and
        $d->isa('RDF::Trine::Node::Literal') and $d->has_datatype and
        $d->literal_datatype =~
        qr!^http://www.w3.org/2001/XMLSchema#date(?:Time)?$!;

    DateTime::Format::W3CDTF->parse_datetime($d->literal_value);
}

sub _do_index {
    my ($self, $c, @collections) = @_;
    my $m  = $c->rdf_cache;
    my $ns = $self->ns;


    my @labels = qw(Issue Position Argument);
    my @types  = map { $self->ns->ibis->uri($_) } @labels;

    my %set;
    if (@collections) {
        for my $col (@collections) {
            for my $o ($m->objects($col, $ns->skos->member)) {
                my ($t) = $m->objects($o, $ns->rdf->type);
                my ($d) = $m->objects($o, $ns->dct->created);
                my ($v) = $m->objects($o, $ns->rdf->value);
                my $x = $set{$t->value} ||= [];

                push @$x, [$o, $v || $o, _coerce_datetime($d)];
            }
        }
    }
    else {
        for my $t (@types) {
            for my $o ($m->subjects($ns->rdf->type, $t)) {
                my ($t) = $m->objects($o, $ns->rdf->type);
                my ($d) = $m->objects($o, $ns->dct->created);
                my ($v) = $m->objects($o, $ns->rdf->value);
                my $x = $set{$t->value} ||= [];
                push @$x, [$o, $v || $o, _coerce_datetime($d)];
            }
        }
    }

    my $cl = $c->collator;

    # janky comparison function that does reverse chrono
    my $cmp = sub {
        my $x = int (defined $_[0][2] && defined $_[1][2] &&
                         $_[1][2] <=> $_[0][2]);
        $x || $cl->cmp($_[0][1]->value, $_[1][1]->value);
    };

    my @out;
    for my $i (0..$#labels) {
        my @triads = @{$set{$types[$i]->value} || []};

        my @x;
        for my $x (sort { $cmp->($a, $b) } @triads) {
            my ($s, $v) = @{$x}[0,1];
            my $uu = URI->new($s->value);
            push @x, {
                -name => 'li',
                -content => { href => '/' . $uu->uuid,
                              -content => $v ? $v->value : $s->value } };
        }

        @x = { -name => 'ul', -content => [@x] } if @x;
        push @out, { -name => 'section', -content => [
            { -name => 'h2', -content => $labels[$i] . 's' }, @x ] };
    }

    wantarray ? @out : \@out;
}

sub _do_content {
    my ($self, $c, $subject, $demote) = @_;
    my (%in, %res, %lit, $iter);

    my $m = $c->rdf_cache;

    my $ns      = $self->ns;
    my $inverse = $self->inverse;
    my $labels  = $self->labels;

    $iter = $m->get_statements(undef, undef, $subject);
    while (my $stmt = $iter->next) {
        #my $p = $NS->abbreviate($stmt->predicate) || $stmt->predicate->value;
        my $p = $stmt->predicate->value;
        my $s = $stmt->subject;
        if (my $inv = $inverse->{$p}) {
            $p = $inv->[0]->value;
            $res{$p} ||= {};
            $res{$p}{$s->value} ||= $s;
            #push @{$res{$p}}, $s;
        }
        else {
            $in{$p} ||= {};
            $in{$p}{$s->value} ||= $s;
            #push @{$in{$p}}, $s;
        }
    }

    $iter = $m->get_statements($subject, undef, undef);
    while (my $stmt = $iter->next) {
        #my $p = $NS->abbreviate($stmt->predicate) || $stmt->predicate->value;
        my $p = $stmt->predicate->value;
        my $o = $stmt->object;
        if ($o->is_literal) {
            $lit{$p} ||= [];
            push @{$lit{$p}}, $o;
        }
        else {
            $res{$p} ||= {};
            $res{$p}{$o->value} ||= $o;
            #push @{$res{$p}}, $o;
        }
    }

    my @asides;
    my %p = map { $_ => 1 } (keys %in, keys %res);


    for my $k ($self->predicate_seq) {

        my $pred = $ns->abbreviate($k);
        $k       = $k->uri_value; # we don't need this as an iri obj anymore
        my $inv  = $inverse->{$k} ? $ns->abbreviate($inverse->{$k}[0]) : undef;

        my %li;
        for my $o (values %{$res{$k} || {}}) {
            my ($type) = $m->objects($o, $ns->rdf->type);
            my ($text) = $m->objects($o, $ns->rdf->value);
            # replicate the uuid if text is missing
            $text = $o unless $text;

            my $uri = '/' . URI->new($o->value)->uuid;

            my @baleet = { -name => 'button',
                           class => 'disconnect fa fa-unlink',
                           name => "- $pred :", value => $uri };
            unshift @baleet, { -name => 'input', type => 'hidden',
                               name => "-! $inv :", value => $uri } if $inv;

            my $tv = $text ? $text->value : $uri;

            $li{$tv . $uri} = {
                -name => 'li', about => $o->value,
                typeof => $ns->abbreviate($type),
                -content => { %FORMBP, -content => [
                    @baleet, { about => $o->value, href => $uri,
                               property => 'rdf:value', -content => $tv } ] }
                # -content => { %FORMBP, -content => {
                #     -name => 'div', -content => [
                #         @baleet,
                #         { about => $o->value, href => $uri,
                #           property => 'rdf:value', -content => $tv } ] } }
            };
        }

        my @li = @li{$c->collator->sort(keys %li)};

        if ($res{$k} && @li) {
            my $abbrk = $ns->abbreviate($k);
            # XXX wtf is this even for anyway?
            my $first = $li[0]{-content}{-content}[-1]{href};
            push @asides, {
                -name => 'aside', class => 'predicate', rel => $abbrk,
                resource => $first, -content => [
                    { -name => 'h3', about => $k, property => 'rdfs:label',
                      -content => $labels->{$k}[1] },
                    { -name => 'ul', about => '', rel => $abbrk,
                      -content => \@li } ] };
        }

    }

    my %c = (
        Issue    => 'fa-exclamation-triangle',
        Position => 'fa-gavel',
        Argument => 'fa-comments',
    );

    # XXX 
    my @buttons = map {
        my $t = "ibis:$_";
        my %attrs = (
            -name => 'button',
            class => "set-type fa $c{$_}", title => $_,
            name => '= rdf:type :', value => $t);
        $attrs{disabled} = 'disabled' if grep { $ns->uri($t)->equal($_) }
            values %{$res{$ns->rdf->type->value} || {}};
        \%attrs;
    } (qw(Issue Position Argument));

    my $rank = $demote || 1;

    my $v = $ns->rdf->value->value;
    my $text = $lit{$v} ? $lit{$v}[0]->value : '';

    my $dtf = DateTime::Format::W3CDTF->new;
    my ($date) = $m->objects($subject, $ns->dct->created);
    if ($date and $date->is_literal
            and $date->literal_datatype eq $ns->xsd->dateTime->uri_value) {
        $date = $dtf->parse_datetime($date->literal_value);
    }
    else {
        undef $date;
    }

    my $meta = { -name => 'span', class => 'date', property => 'dct:created',
                 content => $dtf->format_datetime($date),
                 -content => 'Created ' . $date->ymd } if $date;

    return (
        { -name => 'section', class => 'self', -content => [
            { -name => "h$rank", class => 'heading', -content => [
                { %FORMBP, class => 'types', -content => \@buttons },
                { %FORMBP, class => 'description', -content => [
                    { -name => 'textarea', class => 'heading',
                      name => '= rdf:value', -content => $text },
                    { -name => 'button', class => 'fa fa-repeat',
                      -content => '' } ] } ] },
            $meta,
            $self->_do_concept_form($c, $subject),
            $self->_do_link_form($c, $subject),
        ] },
        { -name => 'section', class => 'relations', -content => \@asides },
    );
}

sub _do_link_form {
    my ($self, $c, $subject, $reverse, $name) = @_;

    my $m  = $c->rdf_cache;
    my $ns = $self->ns;
    my $bs  = $c->req->base;

    $name ||= 'aside';

    my @in = $reverse ? $m->subjects($ns->dct->references, $subject) :
        $m->objects($subject, $ns->dct->references);

    my @li;
    for my $link (@in) {
        next unless $link->is_resource;
        my $uri = URI->new($link->uri_value);
        if ($uri->isa('URI::urn::uuid')) {
            # skip concepts
            next if $m->count_statements
                ($link, $ns->rdf->type, $ns->skos->Concept);
            $uri = URI->new_abs($uri->uuid, $bs);
        }

        # XXX do labels here
        my $label = $c->label_for($link);

        my $pred = sprintf '-%s dct:references :', $reverse ? '!' : '';

        push @li, { -name => 'li', -content => { %FORMBP, -content => [
            { href => $uri, -content => $label->value },
            { -name => 'button', name => $pred, value => $uri,
              class => 'disconnect fa fa-unlink', -content => '' } ] } };
    }

    # conveniently we can sort this list after we construct it
    @li = sort {
        $a->{-content}{-content}[0]{-content}
            cmp $b->{-content}{-content}[0]{-content} } @li;

    # default list item to add a new link
    push @li, { -name => 'li', -content => { %FORMBP, -content => [
        { -name => 'input', type => 'text', name => 'dct:references :' },
        { -name => 'button', class=> 'fa fa-plus', -content => '' } ] } };

    my $lab = 'Links';
    $lab = 'Inbound ' . $lab if $reverse;

    return { -name => $name, class => 'predicate link', -content => [
        { -name => 'h3', class => 'label', -content => $lab },
        { -name => 'ul', -content => \@li } ] };
}

sub _do_concept_form {
    my ($self, $c, $subject, $name) = @_;

    my $m  = $c->rdf_cache;
    my $ns = $self->ns;
    my $bs = $c->req->base;

    $name ||= 'aside';

    my (%li, %opt, @li, @opt);

    for my $concept ($m->objects($subject, $ns->dct->references)) {
        next unless $concept->is_resource;
        next unless $concept->uri_value =~ $UUID_URN;
        next unless $m->count_statements
            ($concept, $ns->rdf->type, $ns->skos->Concept);

        # cache this to prune from select options
        $li{$concept->uri_value} = $concept;

        my $label = $c->label_for($concept);

        #my ($label) = $m->objects($concept, $ns->skos->prefLabel);

        my $uri = URI->new($concept->uri_value);
        $uri = URI->new_abs($uri->uuid, $bs);

        push @li, { -name => 'li', -content => { %FORMBP, -content => [
            { href => $uri, -content => $label->value },
            { -name => 'input', type => 'hidden',
              name => '-! dct:isReferencedBy :',
              value => $concept->uri_value },
            { -name => 'button', class => 'disconnect fa fa-unlink',
              name => '- dct:references :', value => $concept->uri_value },
        ] } };
    }

    @li = sort { $a->{-content}{-content}[0]{-content}
                     cmp $b->{-content}{-content}[0]{-content} } @li;

    for my $concept ($m->subjects($ns->rdf->type, $ns->skos->Concept)) {
        # remove self links
        next if $subject and $concept->equal($subject);

        # remove bnodes
        next unless $concept->is_resource;

        # and now prune
        next if $li{$concept->uri_value};

        # XXX REDO LABELS
        my ($label) = $m->objects($concept, $ns->skos->prefLabel);

        push @opt, { -name => 'option', value => $concept->uri_value,
                     -content => $label->value };
    }

    my $cl = $c->collator;
    @opt = sort { $cl->cmp($a->{-content}, $b->{-content}) } @opt;

    push @li, { -name => 'li', -content => { %FORMBP, -content => [
        { -name => 'select', name => 'dct:references :',
          -content => [{ -name => 'option', -content => '' }, @opt] },
        { -name => 'button', class => 'fa fa-link', -content => '' }]}} if @opt;
    push @li, { -name => 'li', -content => { %FORMBP, -content => [
        { -name => 'input', type => 'hidden',
          name => '$ concept $', value => '$NEW_UUID_URN' },
        { -name => 'input', type => 'hidden',
          name => 'dct:references : $', value => '$concept' },
        { -name => 'input', type => 'hidden',
          name => '= $concept rdf:type :', value => 'skos:Concept' },
        { -name => 'input', type => 'text',
          name => '= $concept skos:prefLabel' },
        { -name => 'button', class=> 'fa fa-plus', -content => '' },
    ]}};

    return { -name => $name, class => 'predicate concept', -content => [
        { -name => 'h3', class => 'label', -content => 'Concepts' },
        { -name => 'ul', -content => \@li } ] };
}

sub _do_collection_form {
    my ($self, $c, $subject) = @_;

    my $m = $c->rdf_cache;
    my $ns = $self->ns;

    my @has = $m->subjects($ns->skos->member, $subject);
    my %map = map { $_->value => 1 } @has;

    my @out;
    # get the list of collections and their labels
    my @s = $m->subjects($ns->rdf->type, $ns->skos->Collection);
    if (@s) {
        for my $i (0..$#s) {
            my $s = $s[$i];
            my ($label) = $m->objects($s, $ns->skos->prefLabel);
            $s[$i] = [$s, $label ? $label->value : ''];
        }

        # make a bullet list
        my @li;
        for my $pair (sort { $a->[1] cmp $b->[1] } @s) {
            my ($s, $label) = @$pair;
            #warn $s;
            next unless $map{$s->value};

            my $uu = URI->new($s->value);

            push @li, {
                -name => 'li', -content => [
                    { href => '/' . $uu->uuid, -content => $label },
                    { -name => 'button', name => '-! skos:member :',
                      value => "$uu" }, 'Remove' ]
            };
        }

        push @out, { %FORMBP,
                     -content => { -name => 'ul', -content => \@li } } if @li;

        if (my @which = grep { ! $map{$_->[0]->value} } @s) {
            # generate a sorted list of option elements
            my @opts = map +{ -name => 'option', value => $_->[0]->value,
                              -content => $_->[1] },
                                  sort { $a->[1] cmp $b->[1] } @which;

            push @out, { %FORMBP, -content => [
                { -name => 'select', name => '! skos:member :',
                  -content => \@opts },
                { -name => 'button', class => 'fa fa-link', -content => '' } ]
            }; # attach
        }
    }

    # XXX THERE IS NOW A PROTOCOL MACRO FOR THIS
    my $newuuid = $self->uuid4urn;

    push @out, { %FORMBP, -content => {
        -name => 'div', -content => [
            { -name => 'input', type => 'hidden',
              name => "= $newuuid rdf:type :",
              value => $ns->skos->Collection->value },
            { -name => 'input', type => 'hidden',
              name => '! skos:member :', value => $newuuid },
            { -name => 'div', -content => [
                { -name => 'button', class => 'fa fa-plus', -content => '' },
                { -name => 'input', type => 'text',
                  name => "= $newuuid skos:prefLabel" }
            ] } ] } }; # Create & Attach

    return { -name => 'aside', class => 'collection', -content => \@out };
}

sub _do_404 {
    my ($self, $new) = @_;
    $new ||= '/' . $self->uuid4;

    # new thing types
    my @types = map +["ibis:$_" => $_ ], qw(Issue Position Argument);
    #push @types, ['skos:Concept' => 'Concept'];

    return { %FORMBP, class => "new-ibis", action => $new,
             -content => {
                 -name => 'fieldset', -content => [
                     { -name => 'legend', -content => [
                         { -name => 'span', -content => 'Start a new ' },
                         { -name => 'select', name => 'rdf:type :',
                           -content => [map +{
                               -name => 'option', value => $_->[0],
                               -content => $_->[1] }, @types] } ] },
                     { -name => 'input', class => 'new-value',
                       type => 'text', name => '= rdf:value' },
                     { -name => 'button', -content => 'Go' } ] } };
}

sub _do_connect_form {
    my ($self, $c, $subject, $type) = @_;

    return { %FORMBP, id => 'connect-existing', -content => {
        -name => 'fieldset', class => 'edit-group', -content => [
            $self->_menu($c, $type),
            # XXX fieldset can't do flex
            { -name => 'div', class => 'interaction',
              -content => [
                  $self->_select($c, $subject),
                  { -name => 'button', class => 'fa fa-link', -content => '' }]
          } ] } };
}

sub _do_create_form {
    my ($self, $c, $subject, $type) = @_;

    my $m  = $c->rdf_cache;
    my $ns = $self->ns;

    my $s = $subject->isa('RDF::Trine::Node') ? $subject : iri("$subject");
    if ($subject->isa('URI::http')) {
        my $path = $subject->path;
        if (my ($uuid) = $path =~ $UUID_RE) {
            $s = iri("urn:uuid:$uuid");
        }
    }

    my @has = $m->subjects($ns->skos->member, $s);
    @has = map +{ -name => 'input', type => 'hidden',
                  name => '! skos:member :', value => $_->value }, @has;

    my $new = '/' . $self->uuid4;

    return { %FORMBP, id => 'create-new', action => $new, -content => {
        -name => 'fieldset', class => 'edit-group', -content => [
            @has,
            { -name => 'input', type => 'hidden',
              name => '$ obj', value => $subject },
            $self->_menu($c, $type, 1),
            # XXX fieldset can't do flex
            { -name => 'div', class => 'interaction', -content => [
                { -name => 'input', class => 'new-value',
                  type => 'text', name => '= rdf:value' },
                { -name => 'button', class => 'fa fa-plus', -content => '' } ]
          } ] } };
}


=head2 config

=cut

sub conf :Local {
    my ($self, $c) = @_;
    my $resp = $c->res;

    require Config::General;

    $resp->content_type('text/plain');
    $resp->body(Config::General->new->save_string($c->config));
}

=head2 palette

=cut

sub palette :Local {
    my ($self, $c) = @_;

    # 

}

=head2 end

Fiddle with serialization, content type/length, etc.

=cut

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;

    my $resp = $c->res;
    my $body = $resp->body;

    if ($resp->status == 404) {
        my $doc = $c->stub(
        title => 'Nothing here. Make something?',
        uri => $c->req->base, content => $self->_do_404);

        $c->res->body($doc);
    }

    if (ref $body and Scalar::Util::blessed($body)
            and $body->isa('XML::LibXML::Document')) {
        # fix it ya goof
        unless ($body->documentElement) {
            $resp->status(501);
            $resp->content_type('text/plain');
            $resp->body("Missing document element!");
            return;
        }

        my $doc = $body;
        my $ct;
        if ($body->documentElement->localName eq 'html') {
            $ct = 'application/xhtml+xml';
        }
        else {
            $ct = 'application/xml';
        }

        $resp->content_type($ct) unless $resp->content_type;

        $body = $body->toString(1);
        $resp->content_length(length $body);
        utf8::decode($body) if lc $doc->actualEncoding eq 'utf-8';
        $resp->body($body);
    }
}

=head1 AUTHOR

dorian,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
