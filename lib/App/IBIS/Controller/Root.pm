package App::IBIS::Controller::Root;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

BEGIN {
#    extends 'App::IBIS::Base::Controller';
    extends 'Catalyst::Controller';
    with    'App::IBIS::Role::Markup';
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
use List::MoreUtils qw(any);

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
        return {
            $ibis->Network->value       => '_get_concept_scheme',
            $ibis->Issue->value         => '_get_generic', #'ibis/get_ibis',
            $ibis->Position->value      => '_get_generic', # 'ibis/get_ibis',
            $ibis->Argument->value      => '_get_generic', # 'ibis/get_ibis',
            $skos->Concept->value       => '_get_generic', # 'skos/get_concept',
            $skos->Collection->value    => 'skos/get_collection',
            $skos->ConceptScheme->value => '_get_concept_scheme',
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

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    if ($req->method eq 'DELETE') {
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
                        -content => { href => $uuid->uuid, -content => $c } };
        }
    }

    my $new ||= $self->uuid4;

    my $doc = $c->stub(
        uri => $req->base,
        title => 'Welcome to App::IBIS: We Have Issues.',
        attr => { typeof => 'ibis:Network' },
        content => [
            { -name => 'main', -content => [
                { -name => 'figure', id => 'force' },
            { -name => 'section', class => 'index ibis',
              -content => [
                  { -name => 'h1', -content => 'Issue Network' },
                  # { -name => 'figure',
                  #   -content => { -name => 'object',
                  #                 type => 'image/svg+xml', data => 'ci2' } },
                  $self->_do_404($new), # not really a 404 but whatev
              ] },
            { -name => 'section', class => 'index skos',
              -content => [
                  { -name => 'h1', -content => 'Concept Scheme' },
                  # { -name => 'figure',
                  #   -content => { -name => 'object',
                  #                 type => 'image/svg+xml',
                  #                 data => 'concepts?rotate=180' } },
                  { %{$self->FORMBP}, action => $new,
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
                            # XXX WTF \xa0 MAKES THIS TURN TO LATIN1 ???? WTFFF
                            href => './', -content => "\x{200b}" } }, # empty overview
                        { -name => 'li', -content => {
                            href => 'we-have-issues',
                            -content => 'What is this thing?' } },
                    ] } } }
        ]);

    $resp->body($doc);
}


sub uuid :Private {
    my ($self, $c, $uuid) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    my $path = lc $uuid;
    $uuid = RDF::Trine::Node::Resource->new('urn:uuid:' . lc $uuid);

    # check request method
    my $method = $req->method;
    if ($method eq 'POST') {
        # check for input
        my $newsub;
        eval {
            $c->log->debug('gonna post it lol');
            $newsub = $self->_post_uuid($c, $uuid, $req->body_parameters);
            $c->log->debug('welp posted it lol');
        };
        if ($@) {
            $c->log->debug($@);
            $resp->status(409);
            $resp->content_type('text/plain');
            $resp->body('wtf');
            # $resp->body(sprintf 'wat %s', $@ // '');
        }
        else {
            my $newuri = _from_urn($newsub, $req->base);
            $c->log->debug("see other: $newuri");
            $resp->redirect($newuri, 303);
        }
        return;
    }
    elsif ($method eq 'GET' or $method eq 'HEAD') {
        # do this for now until we can handle html properly
        $resp->content_type('application/xhtml+xml');
        # check model for subject
        # my $m = $c->model('RDF');
        # my $g = $c->graph;
        my $m = $c->rdf_cache;
        if (my @o = $m->objects($uuid, $self->ns->rdf->type)) {
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

sub bulk :Local {
    my ($self, $c) = @_;

    my $req = $c->req;
    my $rm  = $req->method;

    if ($rm eq 'GET' or $rm eq 'HEAD') {

        my $doc = $c->stub(
            title => 'Load a (Turtle) data file',
            uri   => $req->uri,
            content => {
                %{$self->FORMBP}, enctype => 'multipart/form-data', -content => [
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

        $c->res->redirect($c->req->base);
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


sub _to_urn {
    my $path = shift;
    #warn "lols $path";
    if (my ($uuid) = ($path =~ $App::IBIS::Role::Markup::UUID_RE)) {
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
    URI->new_abs($uuid->uuid, $base);
}

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

# XXX we repeat because we can't do inferences in perl
my %RIDER = (
    'ibis:Issue'         => [@DEFAULT_RIDER],
    'ibis:Position'      => [@DEFAULT_RIDER],
    'ibis:Argument'      => [@DEFAULT_RIDER],
    'ibis:Network'       => [@DEFAULT_RIDER],
    'skos:Concept'       => [@DEFAULT_RIDER],
    'skos:ConceptScheme' => [@DEFAULT_RIDER],
    'skos:Collection'    => [@DEFAULT_RIDER],
);

sub _post_uuid {
    my ($self, $c, $subject, $content) = @_;
    my $uuid = URI->new($subject->uri_value);

    # XXX lame; i forgot why i'm doing this again
    my $ns = URI::NamespaceMap->new({
        rdf  => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        ibis => 'https://vocab.methodandstructure.com/ibis#',
        skos => 'http://www.w3.org/2004/02/skos/core#',
        dct  => 'http://purl.org/dc/terms/',
        xsd  => 'http://www.w3.org/2001/XMLSchema#',
    });

    my $rns = $self->ns;
    my $m = $c->model('RDF'); # this actually needs the writable one
    my $g = $c->graph;

    my $kv = RDF::KV->new(
        #subject    => 'http://deuce:5000/' . $uuid->uuid,
        subject    => _from_urn($uuid, $c->req->base),
        namespaces => $ns,
        graph      => $g->value,
        callback   => \&_to_urn,
   );

    my $patch = $kv->process($content);

    my $newsub = $kv->subject;
    $c->log->debug("new(?) subject: $newsub");
    #$c->log->debug(Data::Dumper::Dumper($patch));

    # $c->log->debug('got here 0');

    my @bad = grep { !$g->equal($_) } $patch->affected_graphs;
    if (@bad) {
        $c->log->error(sprintf 'Modification of graph(s) %s not allowed (%s)',
                       join(', ', map { $_ // '' } @bad), $g);
        return;
    }

    # $c->log->debug('got here 1');

    # ensure that all the statements in the patch match the graph
    # grep { $_->graph->value } map { $patch->$_ } qw(to_add to_remove);

    $c->log->debug("Initial size: " . $m->size);

    # apply the patch

    $m->begin_bulk_ops;
    eval { $patch->apply($m) };
    if ($@) {
        $c->log->error("cannot apply patch: $@");
        return;
    }
    # $c->log->debug('got here 2');

    eval {
        # now we add a rider
        for my $pair ($patch->affected_subjects(1)) {
            # $c->log->debug('got here 3');

            my $ag = $pair->[0];         # affected graph
            for my $as (@{$pair->[1]}) { # affected subjects
                $c->log->debug("trying to add riders to $ag / $as");
                # get the type for the subject
                my @t = $m->objects($as, $rns->rdf->type, $ag);
                my @r = map { @{$RIDER{$rns->abbreviate($_)} || []} } @t;
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
        $c->log->debug($@);
        return;
    };

    $m->end_bulk_ops;
    # clear the cache
    eval { $c->rdf_cache(1) };
    if ($@) {
        $c->log->error("wtf cache: $@");
    }
    $c->log->debug("New size: " . $m->size);

    $newsub;
}

=head2 default

Standard 404 error page

=cut

sub default :Path :Does('+CatalystX::Action::Negotiate') {
    my ( $self, $c, @p) = @_;

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

sub _get_generic :Private {
    my ($self, $c, $subject) = @_;
    my $doc = $c->render_simple($subject);
    $c->res->body($doc);
}

sub _do_404 {
    my ($self, $new) = @_;
    $new ||= $self->uuid4;

    # new thing types
    my @types = map +["ibis:$_" => $_ ], qw(Issue Position Argument);
    #push @types, ['skos:Concept' => 'Concept'];

    return { %{$self->FORMBP}, class => "new-ibis", action => $new,
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

sub _is_xml_node {
    my $body = shift;
    ref $body and Scalar::Util::blessed($body)
        and $body->isa('XML::LibXML::Node');
}

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

    my $type = $resp->content_type;

    # XXX we should really turn this into a standalone view

    if ($type =~ m!/(?:[^/]*(?:ht|x)ml)$!i or _is_xml_node($c->res->body)) {
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
