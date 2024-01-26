package App::IBIS::Controller::Root;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

BEGIN {
#    extends 'App::IBIS::Base::Controller';
    extends 'Catalyst::Controller';
    with    'App::IBIS::Role::Schema';
#    require Devel::Gladiator;
#    require Devel::FindRef;
#    $RDF::Redland::Debug = 1;
}

# constants
use RDF::Trine qw(iri blank literal statement);
use RDF::Trine::Namespace qw(RDF);
use constant IBIS => RDF::Trine::Namespace->new
    ('https://vocab.methodandstructure.com/ibis#');

use RDF::KV;
use DateTime;
use DateTime::Format::W3CDTF;

use Scalar::Util ();

# negotiate yo
use HTTP::Negotiate ();

has _dispatch => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $ns = $self->ns;
        my $ibis = $ns->ibis;
        my $skos = $ns->skos;
        my $cgto = $ns->cgto;
        return {
            $ibis->Network->value       => '_get_concept_scheme',
            $ibis->Issue->value         => '_get_generic', #'ibis/get_ibis',
            $ibis->Position->value      => '_get_generic', # 'ibis/get_ibis',
            $ibis->Argument->value      => '_get_generic', # 'ibis/get_ibis',
            $skos->Concept->value       => '_get_generic', # 'skos/get_concept',
            $skos->Collection->value    => '_get_generic',
            $skos->ConceptScheme->value => '_get_concept_scheme',
            $cgto->Space->value         => '_get_generic',
            $cgto->View->value          => '_get_generic',
            $cgto->Error->value         => '_get_generic',
        };
    },
);

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm

__PACKAGE__->config(namespace => '');

=head1 NAME

App::IBIS::Controller::Root - Root Controller for App::IBIS

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 begin

Runs every time this controller gets run.

=cut

sub begin :Private {
    my ($self, $c) = @_;

    # we use the main guy rather than the cache for this
    my $m  = $c->model('RDF');
    my $g  = $c->graph;
    my $ns = $c->ns;

    # test for the existence of the cgto:Space

    my @spaces = $c->spaces;

    my $req = $c->req;

    my $get = $req->method =~ /^(?:GET|HEAD)$/;
    if ($get and (not @spaces or @spaces > 1)) {
        $c->forward('maybe_bootstrap');
        return;
    }

    if ($c->req->method eq 'POST') {
        # i don't remember what i was going to do here lol
    }

    # there should be exactly one space; if there isn't, complain (409)

    # if there is a space then there should be a focus (again 409 if not)

    # if there is no focus then we should demand to set one (this can
    # be done client-side)

    # if there are no candidates (skos:ConceptScheme or ibis:Network)
    # then we should demand to mint one (again, client-side)
}

=head2 maybe_bootstrap

Initializes the cgto:Space bootstrapping process.

=cut

my @EXEMPT = qw(default all_classes all_properties dump bulk);

sub maybe_bootstrap :Private {
    my ($self, $c) = @_;

    my $arg = $c->req->args->[0] // '';

    # $c->log->debug('does arg match? ' . $arg =~ $self->UUID_RE);

    # XXX note the operand order; string overload in play here
    if ($arg !~ $self->UUID_RE && grep { $_ eq $c->action } @EXEMPT) {
        $c->log->debug('Skipping action from bootstrap screen: ' . $c->action);
    }
    else {
        $c->log->debug('Trapping action for bootstrap: ' . $c->action);
        $c->forward('generic_error', [409]);
    }

    return;
}

=head2 index

The root page (/)

=cut


sub index :Path :Args(0) :HEAD :GET {
    my ( $self, $c ) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    my $ns = $self->ns;
    my $m  = $c->rdf_cache;

    my @spaces = $c->spaces;

    unless (@spaces == 1) {
        $resp->status(500);
        my $err = @spaces ?
            'Multiple spaces selected: ' . join(', ', @spaces) :
                'No spaces; this should have been intercepted.';
        $c->log->error($err);
        $resp->body($err);

        return;
    }

    $c->forward(uuid => [$spaces[0]]);
}

=head2 uuid

Handle UUID-denominated graph entities.

=cut

sub uuid :Private {
    my ($self, $c, $uuid) = @_;

    my $req  = $c->req;
    my $resp = $c->res;


    unless (ref $uuid and Scalar::Util::blessed($uuid)
            and $uuid->isa('RDF::Trine::Node::Resource')) {
        my ($tmp) = ("$uuid" =~ $self->UUID_RE);

        unless ($tmp) {
            $resp->status(500);
            my $err = "$uuid is not a UUID";
            $c->log->error($err);
            $resp->body($err);
            return;
        }

        $uuid = RDF::Trine::Node::Resource->new('urn:uuid:' . lc $tmp);
    }

    # check request method
    my $method = $req->method;
    if ($method eq 'GET' or $method eq 'HEAD') {
        # do this for now until we can handle html properly
        $resp->content_type('application/xhtml+xml');
        # check model for subject
        # my $m = $c->model('RDF');
        # my $g = $c->graph;
        my $m = $c->rdf_cache;
        if (my @o = $m->objects($uuid, $c->ns->rdf->type)) {
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
        $c->forward('delete_uuid', [$uuid]);
    }
    else {
        $resp->status('405');
        $resp->content_type('text/plain');
        # XXX something wittier perhaps
        $resp->body('Method not allowed.');
    }
}

=head2 delete_uuid

Handle DELETE on UUIDs.

=cut

sub delete_uuid :Private {
    my ($self, $c, $uuid) = @_;
    my $m = $c->model('RDF');
    my $g = $c->graph;

    $c->log->debug(sprintf 'Graph %s; Model size: %d', $g->value, $m->size);

    $m->begin_bulk_ops;
    $m->remove_statements($uuid, undef, undef, $g);
    $m->remove_statements(undef, undef, $uuid, $g);
    $m->end_bulk_ops;

    # reset the graph cache
    $c->rdf_cache(1);

    $c->log->debug(sprintf 'New size: %d', $m->size);

    my $resp = $c->response;
    $resp->status('204');
    $resp->content_type('text/plain');
    $resp->body('');
    return;
}

=head2 truncate

Run DELETE on the root, which empties out the whole graph.

=cut

sub truncate :Path('/') :DELETE {
    my ($self, $c, @p) = @_;

    # ABSOLUTELY FUCK THIS SHIT THIS COST ME AN HOUR OF WORK AND A STREAM
    if ($p[0] and $p[0] =~ $self->UUID_RE) {
        my $uuid = iri('urn:uuid:' . lc $p[0]);
        $c->forward(delete_uuid => [$uuid]);
        return;
    }

    my $m = $c->model('RDF');
    my $g = $c->graph;

    $c->log->debug(sprintf 'Model size: %d', $m->size);

    $m->begin_bulk_ops;
    $m->remove_statements(undef, undef, undef, $g);
    $m->end_bulk_ops;

    $c->log->debug(sprintf 'New size: %d', $m->size);

    # blow away the cache
    $c->rdf_cache(1);

    my $resp = $c->response;
    $resp->status('204');
    $resp->content_type('text/plain');
    $resp->body('');
    return;
}

=head2 dump

Dump the whole graph to a serialized representation.

=cut

my %DUMP = (
    turtle   => 'text/turtle',
    rdfxml   => 'application/rdf+xml',
    ntriples => 'application/n-triples',
);

sub dump :Local {
    my ($self, $c) = @_;
    my $req  = $c->req;
    my $resp = $c->res;

    # get the variant or fail
    my $chosen = HTTP::Negotiate::choose([
        ['turtle',   1,    'text/turtle'],
        ['turtle',   0.99, 'text/plain'],
        ['rdfxml',   0.7,  'application/rdf+xml'],
        ['rdfxml',   0.5,  'application/xml'],
        ['ntriples', 0.5,  'application/n-triples'],
    ], $req->headers) or do {
        $resp->status(406);
        $resp->content_type('text/plain');
        $resp->body(q[lol fail can't pick a mime type]);
        return;
    };

    # do this so the damn thing actually checks lol
    $resp->header('Cache-Control', 'max-age=10');

    my $ns = $self->ns;
    my $m  = $c->rdf_cache;

    # suck up all the dates
    # my @dates = _date_seq(
    #     $m->objects(undef, $ns->dct->created),
    #     $m->objects(undef, $ns->dct->modified));

    # XXX JUST DO THIS FOR NOW
    my @dates;
    push @dates, $c->global_mtime;

    # $c->log->debug(Data::Dumper::Dumper(\@dates));

    # if there are any (which there should be...)
    if (@dates) {
        if (my $ims = $req->headers->if_modified_since) {
            $ims = DateTime->from_epoch(epoch => $ims);

            # return 304 if nothing is new
            if ($ims >= $dates[-1]) {
                $resp->status(304);
                return;
            }
        }

        # otherwise include LM header
        $resp->headers->last_modified($dates[-1]->epoch);
    }

    # override unless turtle is actually in the header
    my $type = $DUMP{$chosen};
    $type = 'text/plain' if $chosen eq 'turtle' and
        ($req->header('Accept') // '') !~ m!\btext/turtle\b!i;

    $c->log->debug('in: ' . ( $req->header('Accept') // ''));
    $c->log->debug('out: ' . $type);
    $c->log->debug('chosen: ' . $chosen);

    $resp->status(200);
    $resp->content_type($type);
    my $s = RDF::Trine::Serializer->new($chosen, namespaces => $self->ns);
    $c->stash->{skip_rewrite} = 1;
    my $out = $s->serialize_model_to_string($c->rdf_cache);
    $resp->body($out);
    # $c->log->debug($resp->body);
}

=head2 bulk

Bulk-upload serialized graph data.

=cut

sub bulk :Local {
    my ($self, $c) = @_;

    my $req = $c->req;
    my $rm  = $req->method;

    if ($rm eq 'GET' or $rm eq 'HEAD') {

        my $doc = $c->stub(
            title => 'Load a (Turtle) data file',
            uri   => $req->uri,
            content => {
                -name => 'form', method => 'POST',
                action => '', 'accept-charset' => 'utf-8',
                enctype => 'multipart/form-data', -content => [
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

        $p->parse(undef, $up->decoded_slurp(':utf8'), sub {
                      $m->add_statement(shift, $g);
                  });
        $c->rdf_cache(1);
        $c->res->redirect($c->req->base, 303);
        return;
    }
    else {
        $c->res->status(405);
        $c->res->body('Method not allowed');
    }
}

=head2 feed

Get IBIS entities as an Atom feed.

=cut

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

        my $doc = $self->_DOC;
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

=head2 rdf_kv_post

Handle POST requests that conform to the RDF-KV protocol.

=cut

# POST RIDERS SHOULD BE IDEMPOTENT IN CASE THEY GET RUN MORE THAN ONCE

my @DEFAULT_RIDER = (
    sub {
        my ($self, $c, $p) = @_;
        my ($m, $g, $s, $n) = @{$p}{qw(model graph subject ns)};

        # $c->log->debug("running dct:created rider on g: $g s: $s");

        unless ($m->count_statements($s, $n->dct->created, undef, $g)) {
            my $now = literal(DateTime->now . 'Z', undef, $n->xsd->dateTime);
            my $st  = statement($s, $n->dct->created, $now, $g);
            $m->add_statement($st);
        }
    },
    sub {
        my ($self, $c, $p) = @_;
        my ($m, $g, $s, $n) = @{$p}{qw(model graph subject ns)};

        # $c->log->debug("running dct:creator rider on g: $g s: $s");

        if (my $me = $c->whoami and not
            $m->count_statements($s, $n->dct->creator, undef, $g)) {
            my $st = statement($s, $n->dct->creator, $me, $g);
            $m->add_statement($st);
        }
    },
);

# XXX we repeat because we can't do inferences in RDF::Trine
my %RIDER = (
    'ibis:Issue'         => [],
    'ibis:Position'      => [],
    'ibis:Argument'      => [],
    'ibis:Network'       => [],
    'skos:Concept'       => [],
    'skos:ConceptScheme' => [],
    'skos:Collection'    => [],
    'cgto:Space'         => [],
);

sub rdf_kv_post :Path('/') :POST {
    my ($self, $c, @args) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    my $m = $c->model('RDF');
    my $g = $c->graph;

    my $kv = RDF::KV->new(
        subject    => $req->uri->canonical,
        namespaces => $c->uns,
        graph      => $g->value,
        callback   => sub { $c->internal_uri_for(shift) },
    );

    my $patch = eval { $kv->process($req->body_parameters) };
    if ($@) {
        $resp->status(409);
        $resp->body($@);
        return;
    }

    # my $newsub = _from_urn($kv->subject, $req->base);
    my $newsub = $c->uri_for($kv->subject);

    $c->log->debug("RDF-KV: new(?) subject $newsub");

    unless (lc $newsub->authority eq lc $c->req->base->authority) {
        $resp->status(409);
        $resp->body("RDF-KV: Neutralized attempt to redirect offsite: $newsub");
        return;
    }

    my @bad = grep { !$g->equal($_) } $patch->affected_graphs;
    if (@bad) {
        my $bad = join(', ', map { $_ // '' } @bad);
        my $err = sprintf
            'RDF-KV: Modification of graph(s) %s not allowed (%s)', $bad, $g;

        $c->log->error($err);
        $resp->status(409);
        $resp->body($err);

        return;
    }

    $c->log->debug("RDF-KV: Initial size: " . $m->size);

    # XXX this might actually not completely work
    my $space = ($c->spaces)[0] if 1 == $c->spaces;

    $m->begin_bulk_ops;
    eval {
        # we have to override the patch application stuff to rewrite
        # the graph identifier if there is one to rewrite
        $patch->apply(
            sub { # remove
                # we do this little rigmarole for RDF::Trine's quad semantics
                my @n = @_[0..3];
                pop @n unless defined $n[3];

                if ($space) {
                    $n[0] = $space if $n[0]->equal($c->graph);
                    $n[2] = $space if $n[2] and $n[2]->equal($c->graph)
                        and !$n[1]->equal($c->ns->ci->canonical);
                }

                $m->remove_statements(@n);
            },
            sub { # add
                my $stmt = defined $_[3] ?
                    RDF::Trine::Statement::Quad->new(@_)
                      : RDF::Trine::Statement->new(@_[0..2]);

                if ($space) {
                    $stmt->subject($space) if $stmt->subject->equal($c->graph);

                    $stmt->object($space) if $stmt->object->equal($c->graph)
                        and !$c->predicate->equal($c->ns->ci->canonical);
                }

                $m->add_statement($stmt);
            },
        ) };
    if ($@) {
        # XXX WOULD LOVE A ROLLBACK HERE

        my $err = "RDF-KV: Can't apply patch: $@";
        $c->log->error($err);
        $resp->status(409);
        $resp->body($err);

        return;
    }

    # gotta love having two incompatible classes for namespace maps
    my $rns = $c->ns;

    $c->log->debug('RDF-KV: Running post-POST riders');
    eval {
        # now we add a rider
        for my $pair ($patch->affected_subjects(1)) {

            my $ag = $pair->[0];         # affected graph
            for my $as (@{$pair->[1]}) { # affected subjects
                $c->log->debug("trying to add riders to $ag / $as");
                # get the type for the subject
                my @t = $m->objects($as, $rns->rdf->type, $ag);
                my @r = (@DEFAULT_RIDER,
                         map { @{$RIDER{$rns->abbreviate($_)} || []} } @t);
                # run each of the riders
                for my $rider (@r) {
                    my %p = (model => $m, graph => $ag,
                             ns => $rns, subject => $as);
                    $rider->($self, $c, \%p);
                }
            }
        }
    };
    if ($@) {
        # XXX ROLLBACK HERE TOO LOL

        my $err = "RDF-KV: rider function failed: $@";
        $c->log->error($err);
        $resp->status(409);
        $c->
        return;
    };

    # uhh commit transactions? lol
    $m->end_bulk_ops;
    # clear the cache
    $c->rdf_cache(1);

    $c->log->debug('RDF-KV: New size: ' . $m->size);

    $resp->redirect($newsub, 303);
}

sub _to_urn {
    my $path = shift;
    #warn "lols $path";
    if (my ($uuid) = ($path =~ $App::IBIS::Role::Schema::UUID_RE)) {
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
    Carp::croak("wtf $uuid, @{[join ' ', caller]}") unless $uuid->isa('URI');
    return $uuid unless $uuid->isa('URI::urn::uuid');
    URI->new_abs($uuid->uuid, $base);
}

=head2 default

Standard 404 error page

=cut

sub default :Path :Does('+CatalystX::ActionRole::Negotiate') :GET :HEAD {
    my ( $self, $c, @p) = @_;

    $c->log->debug('Default: ' . join '/', @p);

    if ($p[0] and $p[0] =~ $self->UUID_RE) {
        $c->forward(uuid => [lc $p[0]]);
        return;
    }
}

# XXX make a resource that returns logged-in status and user info (if
# logged in of course)

# XXX make a resource containing all objects of type X then just turn
# it into a select.

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
                -content => { href => $uu->uuid,
                              -content => $v ? $v->value : $s->value } };
        }

        @x = { -name => 'ul', -content => [@x] } if @x;
        push @out, { -name => 'section', -content => [
            { -name => 'h2', -content => $labels[$i] . 's' }, @x ] };
    }

    wantarray ? @out : \@out;
}

=head2 _get_generic

Retrieve a generic representation (this was grafted on after
jettisoning the type-specific renderers).

=cut

sub _get_generic :Private {
    my ($self, $c, $subject) = @_;

    my $doc = $c->render_simple($subject);

    $c->res->body($doc);
}

=head2 _get_concept_scheme

Variant of above for concept schemes.

=cut

sub _get_concept_scheme :Private {
    my ($self, $c, $subject) = @_;

    my $ns  = $c->ns;
    my $doc = $c->render_simple(
        $subject, rev => [$ns->skos->inScheme, $ns->skos->topConceptOf]);

    $c->res->body($doc);
}

=head2 generic_error

This is the "error" associated with a graph missing its C<cgto:Space>.

=cut

sub generic_error :Private {
    my ($self, $c, $status, $path) = @_;

    my $resp = $c->res;

    my $uri = $c->uri_for($path || $c->config->{error} || 'generic-error');
    my (undef, @path) = split m!/+!, $uri->path;
    #$c->req->path($uri->path);
    $c->stash->{status_override} = $status || 404;
    $c->action('default');

    $c->stash->{negotiate_use_args} = 1;

    $c->forward('default', \@path);
    # $c->forward('_wtf', [$status]);
    # $c->detach;
}

sub _wtf :Does('+CatalystX::ActionRole::Negotiate') {
    my ($self, $c, $status) = @_;
    $c->res->status($status || 404);
    $c->log->debug("wtf: " . $c->req->uri);
}

sub _do_404 {
    my ($self, $new) = @_;
    $new ||= $self->uuid4;

    # new thing types
    my @types = map +["ibis:$_" => $_ ], qw(Issue Position Argument);
    push @types, ['skos:Concept' => 'Concept'];

    return { method => 'POST', 'accept-charset' => 'utf-8', action => $new,
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

### XXX much of these next several things can probably get smushed
### into considerably less code

=head2 all_classes

Summary representation for all RDF classes.

=cut

sub all_classes :Path('all-classes') :Args(0) {
    my ($self, $c) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    my $mtime = $c->global_mtime;
    if (my $ims = $req->headers->if_modified_since) {
        $ims = DateTime->from_epoch(epoch => $ims);
        if ($ims >= $mtime) {
            $resp->status(304);
            return;
        }
    }
    $resp->headers->last_modified($mtime->epoch);

    my $m  = $c->rdf_cache;
    my $ns = $c->ns;

    my @types = $m->objects(undef, $ns->rdf->type, undef, type => 'resource');

    # note the single quotes
    my %tr;
    for my $type (@types) {
        next unless my $curie = $ns->abbreviate($type);

        my $cs = $m->count_statements(undef, $ns->rdf->type, $type);

        $tr{$curie} = {
            -name => 'tr', id => 'o.$o', about => '#o.$o',
            typeof => 'qb:Observation', -content => [
                { -name => 'th', -content => { rel => 'cgto:class',
                href => $type->value, -content => $curie } },
            { -name => 'td', -content => {
                rel => 'cgto:subjects', href => $c->uri_for('has-type', $curie),
                -content => {
                    about => '#o.$o', property => 'cgto:subject-count',
                    datatype => 'xsd:nonNegativeInteger', -content => $cs }
            } } ] };

    }

    my @tr = @tr{sort { $a cmp $b } keys %tr};
    # lol we do this because the sort messes it up
    for my $i (1..@tr) {
        my $tr = $tr[$i-1];
        $tr->{about} =~ s/(?<=\.)\$o\b/$i/g;
        $tr->{id} =~ s/(?<=\.)\$o\b/$i/g;
        $tr->{-content}[-1]{-content}{-content}{about} =~ s/(?<=\.)\$o\b/$i/g;
    }

    my $doc = $c->stub(
        title => ['Resources by Class', 'dct:title'],
        attr  => { typeof => 'cgto:Summary' },
        content => { -name => 'table', -content => [
            { -name => 'caption', about => 'cgto:resources-by-class',
              property => 'rdfs:comment',
              -content => 'This structure describes a data set that ' .
              ' tabulates subject resources of a certain rdf:type.' },
            { -name => 'thead', rel => 'qb:structure',
              resource => 'cgto:resources-by-class',
              typeof => 'qb:DataStructureDefinition', -content => {
                -name => 'tr', rel => 'qb:component', -content => [
                    { -name => 'th', about => '_:c1', rel => 'qb:dimension',
                      typeof => 'qb:ComponentSpecification',
                      resource => 'cgto:class', -content => 'Class' },
                    { -name => 'th', -content => [
                        { about => '_:c2', typeof => 'qb:ComponentSpecification',
                          rel => 'qb:attribute', resource => 'cgto:subjects',
                          -content => 'Subjects' },
                        { about => '_:c3', typeof => 'qb:ComponentSpecification',
                          rel => 'qb:measure', resource => 'cgto:subject-count' }
                    ] } ] } },
            { -name => 'tbody', rev => 'qb:dataSet', -content => \@tr } ] }
    );

    $resp->body($doc);
}

=head2 all_properties

Summary representation for all RDF properties.

=cut

sub all_properties :Path('all-properties') :Args(0) {
    my ($self, $c) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    my $mtime = $c->global_mtime;
    if (my $ims = $req->headers->if_modified_since) {
        $ims = DateTime->from_epoch(epoch => $ims);
        if ($ims >= $mtime) {
            $resp->status(304);
            return;
        }
    }

    $resp->headers->last_modified($mtime->epoch);

    my $m  = $c->rdf_cache;
    my $ns = $c->ns;

    my @props = $m->predicates(undef, undef);

    my %tr;
    for my $prop (@props) {
        next unless my $curie = $ns->abbreviate($prop);

        # collect nodes on either end
        my (%s, %o);
        my $iter = $m->get_statements(undef, $prop, undef);
        while (my $stmt = $iter->next) {
            my ($s, $o) = ($stmt->subject, $stmt->object);
            $s{$s->uri_value} = $s if $s->is_resource;
            $o{$o->uri_value} = $o if $o->is_resource;
        }

        # this will give us counts
        my $cs = keys %s;
        my $co = keys %o;

        $tr{$curie} = {
            -name => 'tr', id => 'o.$o', about => '#o.$o',
            typeof => 'qb:Observation', -content => [
                { -name => 'th', -content => {
                    rel => 'cgto:property', href => $prop->value,
                    -content => $curie } },
                { -name => 'td', -content => {
                    rel => 'cgto:subjects',
                    href => $c->uri_for('subjects-of', $curie),
                    -content => {
                        about => '#o.$o', property => 'cgto:subject-count',
                        datatype => 'xsd:nonNegativeInteger', -content => $cs }
                } },
                { -name => 'td', -content => {
                    rel => 'cgto:objects',
                    href => $c->uri_for('objects-of', $curie),
                    -content => {
                        about => '#o.$o', property => 'cgto:object-count',
                        datatype => 'xsd:nonNegativeInteger', -content => $co }
                } },
        ] };
    }

    # same business here rewriting the fragments
    my @tr = @tr{sort { $a cmp $b } keys %tr};
    for my $i (1..@tr) {
        my $tr = $tr[$i-1];
        $tr->{about} =~ s/(?<=\.)\$o\b/$i/g;
        $tr->{id} =~ s/(?<=\.)\$o\b/$i/g;
        $tr->{-content}[-1]{-content}{-content}{about} =~ s/(?<=\.)\$o\b/$i/g;
        $tr->{-content}[-2]{-content}{-content}{about} =~ s/(?<=\.)\$o\b/$i/g;
    }

    # note this is almost completely static save for the tbody rows
    my $doc = $c->stub(
        title => ['Resources by Property', 'dct:title'],
        attr  => { typeof => 'cgto:Summary' },
        content => { -name => 'table', -content => [
            { -name => 'caption', about => 'cgto:resources-by-property',
              property => 'rdfs:comment',
              -content => 'This structure describes a data set that tabulates' .
              ' both subject and object resources by property (predicate).' },
            { -name => 'thead', rel => 'qb:structure',
              resource => 'cgto:resources-by-property',
              typeof => 'qb:DataStructureDefinition', -content => {
                  -name => 'tr', rel => 'qb:component', -content => [
                      { -name => 'th', about => '_:p1', rel => 'qb:dimension',
                        typeof => 'cgto:ComponentSpecification',
                        resource => 'cgto:property', -content => 'Property' },
                      { -name => 'th', -content => [
                          { about => '_:p2', rel => 'qb:attribute',
                            resource => 'qb:subjects', -content => 'Subjects',
                            typeof => 'qb:ComponentSpecification' },
                          { about => '_:p3', rel => 'qb:measure',
                            resource => 'qb:subject-count',
                            typeof => 'qb:ComponentSpecification' },
                      ] },
                      { -name => 'th', -content => [
                          { about => '_:p4', rel => 'qb:attribute',
                            resource => 'qb:objects', -content => 'Objects',
                            typeof => 'qb:ComponentSpecification' },
                          { about => '_:p5', rel => 'qb:measure',
                            resource => 'qb:object-count',
                            typeof => 'qb:ComponentSpecification' },
                      ] },
                  ] } },
            { -name => 'tbody', rev => 'qb:dataSet', -content => \@tr } ] }
    );

    $resp->body($doc);
}

=head2 has_type

List of subjects that have asserted a certain C<rdf:type>.

=cut

sub has_type :Path('has-type') :Args(1) {
    my ($self, $c, $type) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    # redirect to /all-classes unless type is defined
    unless (defined $type and $type ne '') {
        $resp->redirect('/all-classes', 303);
        return;
    }

    my $mtime = $c->global_mtime;
    if (my $ims = $req->headers->if_modified_since) {
        $ims = DateTime->from_epoch(epoch => $ims);
        if ($ims >= $mtime) {
            $resp->status(304);
            return;
        }
    }

    $resp->headers->last_modified($mtime->epoch);

    my $ns = $c->ns;

    # blow up if we can't resolve the type
    my $term = $ns->uri($type);
    unless ($term) {
        $resp->status(409);
        $resp->body("Can't resolve CURIE: $type");
        return;
    }

    my $base = $req->base;

    my $m = $c->rdf_cache;

    my @nodes = grep { $_->is_resource } $m->subjects($ns->rdf->type, $term);

    my @li;
    for my $s (@nodes) {
        my ($lo, $lp) = $c->label_for($s);
        my $uri = _from_urn($s, $base);
        my $c = $lp ? { property => $lp->uri_value, -content => $lo->value } :
            $lo->value;
        push @li, [$lo->value, { -name => 'li', -content => {
            href => $uri, typeof => $type, -content => $c } }];
    }

    # $c->log->debug(Data::Dumper::Dumper(\@li));

    @li = map { $_->[1] } sort { $a->[0] cmp $b->[0] } @li;

    my $doc = $c->stub(
        title => ["Subjects of $type", 'dct:title'],
        attr  => { typeof => 'cgto:Inventory' },
        content => { -name => 'ul', rel => 'dct:hasPart', -content => \@li });

    $resp->body($doc);
}

=head2 subjects_of

List of subject resources of a certain RDF predicate.

=cut

sub subjects_of :Path('subjects-of') :Args(1) {
    my ($self, $c, $property) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    # redirect to /all-properties unless property is defined
    unless (defined $property and $property ne '') {
        $resp->redirect('/all-properties', 303);
        return;
    }

    my $mtime = $c->global_mtime;
    if (my $ims = $req->headers->if_modified_since) {
        $ims = DateTime->from_epoch(epoch => $ims);
        if ($ims >= $mtime) {
            $resp->status(304);
            return;
        }
    }

    $resp->headers->last_modified($mtime->epoch);

    my $ns = $c->ns;

    # blow up if we can't resolve the property
    my $term = $ns->uri($property);
    unless ($term) {
        $c->res->status(409);
        $c->res->body("Can't resolve CURIE: $property");
        return;
    }

    my $m = $c->rdf_cache;

    my @nodes = grep { $_->is_resource } $m->subjects($term, undef);

    my $base = $req->base;

    # $c->log->debug(Data::Dumper::Dumper(\@nodes));

    my @li;
    for my $s (@nodes) {
        my ($lo, $lp) = $c->label_for($s);
        my $uri = _from_urn($s, $base);
        my $ct = $lp ? { property => $lp->uri_value, -content => $lo->value } :
            $lo->value;
        my @types = sort map { $ns->abbreviate($_) } $c->types_for($s);
        push @li, [ $lo->value, { -name => 'li', -content => {
            href => $uri, typeof => \@types, -content => $ct } } ];
    }

    @li = map { $_->[1] } sort { $a->[0] cmp $b->[0] } @li;

    my $doc = $c->stub(
        title => ["Subjects of $property", 'dct:title'],
        attr  => { typeof => 'cgto:Inventory' },
        content => { -name => 'ul', rel => 'dct:hasPart', -content => \@li });

    $resp->body($doc);
}

=head2 objects_of

List of object resources of a certain RDF predicate.

=cut

sub objects_of :Path('objects-of') :Args(1) {
    my ($self, $c, $property) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    # redirect to /all-properties unless property is defined
    unless (defined $property and $property ne '') {
        $resp->redirect('/all-properties', 303);
        return;
    }

    my $ns = $c->ns;

    # blow up if we can't resolve the property
    my $term = $ns->uri($property);
    unless ($term) {
        $c->res->status(409);
        $c->res->body("Can't resolve CURIE: $property");
        return;
    }

    my $m = $c->rdf_cache;

    my @nodes = $m->objects(undef, $term, undef, type => 'resource');

    my $base = $req->base;

    my @li;
    for my $s (@nodes) {
        $c->log->debug(Data::Dumper::Dumper($s));
        my ($lo, $lp) = $c->label_for($s);
        my $uri = _from_urn($s, $base);
        my $ct = $lp ? { property => $lp->uri_value, -content => $lo->value } :
            $lo->value;
        my @types = sort map { $ns->abbreviate($_) } $c->types_for($s);
        push @li, [$lo->value, { -name => 'li', -content => {
            href => $uri, typeof => \@types, -content => $ct } } ];
    }

    @li = map { $_->[1]  }sort { $a->[0] cmp $b->[0] } @li;

    my $doc = $c->stub(
        title => ["Objects of $property", 'dct:title'],
        attr  => { typeof => 'cgto:Inventory' },
        content => { -name => 'ul', rel => 'dct:hasPart', -content => \@li });

    $resp->body($doc);
}

=head2 config

Dump the configuration file (XXX MIGHT WANNA ACL THIS).

=cut

sub conf :Local {
    my ($self, $c) = @_;
    my $resp = $c->res;

    require Config::General;

    $resp->content_type('text/plain');
    $resp->body(Config::General->new->save_string($c->config));
}

=head2 palette

One day this will spit out a configurable palette.

=cut

sub palette :Local {
    my ($self, $c) = @_;

    # ??? what precisely was i planning to do here
 }

=head2 end

Fiddle with serialization, content type/length, etc.

=cut

sub _is_xml_node {
    my $body = shift;
    ref $body and Scalar::Util::blessed($body)
        and $body->isa('XML::LibXML::Node');
}

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;

    my $resp = $c->res;
    my $body = $resp->body;

    # $c->log->debug(Data::Dumper::Dumper($resp->status));
    if ($c->stash->{status_override}) {
        $resp->status($c->stash->{status_override});
    }
    elsif ($resp->status == 404) {
        my $doc = $c->stub(
        title => 'Nothing here. Make something?',
        uri => $c->req->base, content => $self->_do_404);

        $c->res->body($doc);
    }

    my $type = $resp->content_type;

    # XXX we should really turn this into a standalone view

    if ($type =~ m!/(?:[^/]*(?:ht|x)ml)$!i or _is_xml_node($c->res->body)) {
        # lol this does not work
        # $c->stash->{current_view} = 'XML::Finish';
        # $c->log->debug($c->view);
        $c->forward('View::XML::Finish');
    }

    # XXX this too

    # elsif ($type =~ m!text/(?:x-)?vnd\.sass(?:\.scss)?!i
    #        and not $c->stash->{is_subreq}) {
    #     $c->log->debug('invoking Sass handler for ' . $c->req->uri);
    #     $c->forward('View::Sass');
    # }
}

=head1 AUTHOR

dorian,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
