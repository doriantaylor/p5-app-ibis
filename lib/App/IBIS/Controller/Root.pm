package App::IBIS::Controller::Root;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

BEGIN {
    extends 'App::IBIS::Base::Controller';
    with 'App::IBIS::Role::Schema';
}



# constants
use RDF::Trine qw(iri blank literal);
use RDF::Trine::Namespace qw(RDF);
use constant IBIS => RDF::Trine::Namespace->new
    ('http://privatealpha.com/ontology/ibis/1#');

use XML::LibXML::LazyBuilder qw(DOM E DTD F);
use RDF::KV;
use DateTime;

use App::IBIS::HivePlot;

my $UUID_RE = qr/([0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){4}[0-9A-Fa-f]{8})/;

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
    $resp->body($self->_doc('Welcome to App::IBIS: We Have Issues.',
                            $req->base, undef, {},
                            $self->_do_index($c))->toString(1));
}

sub hp :Local {
    my ($self, $c) = @_;

    my $req = $c->req;
    my $b   = $req->base;
    my $q   = $req->query_parameters;
    my $ref = $q->{referrer} || $q->{referer} || $req->referer;
    my $col = $q->{collection} || [];
    $col = ref $col ? $col : [$col];

    # glean subject from referrer
    my $s;
    if ($ref) {
        $ref = $ref->[0] if ref $ref eq 'ARRAY'; # lol got all that?
        $ref = URI->new_abs($ref, $b);

        if (my ($uuid) = ($ref->path =~ $UUID_RE)) {
            $s = iri('urn:uuid:' . lc $uuid);
        }
    }

    my $hp = App::IBIS::HivePlot->new(
        model       => $c->model('RDF'),
        callback    => sub { _from_urn(shift, $b) },
        collections => $col,
    );
    $c->res->content_type('image/svg+xml');
    $c->res->body($hp->plot($s)->toString(1));
}

sub uuid :Regexp('^([0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){4}[0-9A-Fa-f]{8})') {
    my ($self, $c) = @_;

    my $req  = $c->req;
    my $resp = $c->res;

    my $uuid = $c->req->captures->[0];

    my $path = '/' . lc $uuid;
    $uuid = RDF::Trine::Node::Resource->new('urn:uuid:' . lc $uuid);

    # check request method
    my $method = $req->method;
    if ($method eq 'POST') {
        # check for input
        $self->_post_uuid($c, $uuid, $req->body_parameters);
        $resp->redirect($path);
    }
    elsif ($method eq 'GET' or $method eq 'HEAD') {
        # do this for now until we can handle html properly
        $resp->content_type('application/xhtml+xml');
        # check model for subject
        my $m = $c->model('RDF');
        if (my @o = $m->objects($uuid, $self->ns->rdf->type, undef)) {
            # GHETTO FRESNEL
            my $d = $self->_dispatch;
            my ($handler) = map { $d->{$_->value} } grep { $d->{$_->value} } @o;
            #warn $handler;
            $resp->status(200);
            $c->forward($handler, [$uuid]);
            #$resp->body($self->_get_uuid($c, $req->uri, $uuid));
        }
        else {
            # 404
            my $new = $uuid->uri_value;
            $new =~ s!urn:uuid:!/!;
            $resp->status(404);
            $resp->body($self->_doc('Nothing here. Make something?',
                                    $req->base, undef, {},
                                    $self->_do_404($new))->toString(1));
        }
    }
    else {
        $resp->status('405');
        $resp->content_type('text/plain');
        # XXX something wittier perhaps
        $resp->body('Method not allowed.');
    }
}

sub dump :Local {
    my ($self, $c) = @_;
    my $resp = $c->res;

    $resp->status(200);
    $resp->content_type('text/plain');
    my $serializer = RDF::Trine::Serializer->new
        ('turtle', namespaces => $self->ns);
    $resp->body($serializer->serialize_model_to_string($c->model('RDF')));
}

sub _get_collection :Private {
    my ($self, $c, $subject) = @_;

    # XXX COPY THIS SHIT FROM THE OTHER ONE

    my $uri = $c->req->uri;

    my $m = $c->model('RDF');

    #warn $subject;
    my $rns = $self->ns;

    # XXX THIS CAN GET AWAY ON US
    my ($type)  = $m->objects($subject, $rns->rdf->type);
    my ($title) = $m->objects($subject, $rns->skos->prefLabel);
    my ($desc)  = $m->objects($subject, $rns->skos->description);

    my %attrs;
    $attrs{typeof} = $rns->abbreviate($type) if $type;

    my $maybetitle = $title ? $title->value : '';

    my $body = $self->_doc($maybetitle || $subject->value,
                           $uri, undef, \%attrs,
                           (E form => { method => 'post',
                                        action => $uri,
                                        'accept-encoding' => 'utf-8' },
                            (E h1 => {},
                             E input => {
                                 name => '= skos:prefLabel',
                                 value => $maybetitle }),
                            (E p => {},
                             (E textarea => { name => '= skos:description' },
                              $desc ? $desc->value : ''))),
                           $self->_do_index($c, $subject),
            )->toString(1);

    # XXX forward this maybe?
    $c->res->body($body);
}

sub _get_ibis :Private {
    my ($self, $c, $subject) = @_;

    my $uri = $c->req->uri;

    my $m = $c->model('RDF');

    #warn $subject;
    my $rns = $self->ns;

    # XXX THIS CAN GET AWAY ON US
    my ($type)  = $m->objects($subject, $rns->rdf->type);
    my ($title) = $m->objects($subject, $rns->rdf->value);

    my %attrs;

    # XXX DERIVE THIS BETTER
    my $label;
    if ($type) {
        $attrs{typeof} = $rns->abbreviate($type);
        ($label) = ($attrs{typeof} =~ /:(.*)/);
        $label .= ': ';
    }

    my $body = $self->_doc(
        $label . ($title ? $title->value : ''), $uri, undef, \%attrs,
        (E div => { class => 'aside' },
         (E object => { class => 'hiveplot',
                        data => '/hp',
                        type => 'image/svg+xml' }, "(Hive Plot)")),
        (E div => { class => 'main' },
         $self->_do_content($c, $subject),
         (E div => {},
          $self->_do_connect_form($c, $subject, $type),
          $self->_do_create_form($c, $uri, $type)),
         $self->_do_toggle),
    )->toString(1);

    # XXX forward this maybe?
    $c->res->body($body);
}

sub _to_urn {
    my $path = shift;
    #warn "lols $path";
    if (my ($uuid) = ($path =~ $UUID_RE)) {
        return URI->new("urn:uuid:$uuid");
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
        ibis => 'http://privatealpha.com/ontology/ibis/1#',
        skos => 'http://www.w3.org/2004/02/skos/core#',
        dct  => 'http://purl.org/dc/terms/',
    });

    my $rns = $self->ns;

    my $kv = RDF::KV->new(
        #subject    => 'http://deuce:5000/' . $uuid->uuid,
        subject    => $c->req->base . $uuid->uuid,
        namespaces => $ns,
        callback   => \&_to_urn,
   );

    my $patch = $kv->process($content);
    #warn Data::Dumper::Dumper($patch);
    my $m = $c->model('RDF');
    $c->log->debug("Size: " .$m->size);
    # add a timestamp
    unless ($m->count_statements($subject, undef, undef)) {
        my $now = literal(DateTime->now . 'Z', undef, $rns->xsd->dateTime);
        $patch->add_this($subject, $rns->dct->created, $now);
    }

    $patch->apply($m);

    $m->_store->_model->sync;
    $c->log->debug("Size: " .$m->size);

}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c, @p) = @_;
    $c->log->debug(@p);
    $c->res->status(404);
    my $doc = $self->_doc('Nothing here. Make something?',
                $c->req->base, undef, {}, $self->_do_404);
    $c->res->body($doc->toString(1));
}


sub _naive_typeof {
    my ($self, $c, @types) = @_;
    my $m = $c->model('RDF');
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
    my $model  = $c->model('RDF');
    my @opts;
    for my $i (0..$#labels) {
        my $l = $labels[$i];
        my $t = $types[$i];
        my $v = $t->value;

        # XXX this will crash
        my $rdfv = $self->ns->rdf->value;
        my @pairs = sort { $a->[1]->value cmp $b->[1]->value } map {
            my $s = iri($_); [$s, $model->objects($s, $rdfv)]
        } keys %{$map->{$v} || {}};

        my @o;
        # XXX this might be a blank node but not on my watch
        #for my $pair  (map { iri($_) } keys %{$map->{$v} || {}}) {
        for my $pair (@pairs) {
            my ($s, $val) = @$pair;
            next if $subject->equal($s);

            #my ($val) = $model->objects($s, RDF->value);
            my $text = $val ? $val->value : $s->value;
            my $ss   = $s->value;
            push @o, (E option => { about => $ss, value => $ss }, $text);
        }

        push @opts, (E optgroup => {
            about => $v, label => $l, rev => 'rdf:type' }, @o) if @o;
    }

    E select => { class => 'target', name => '$ obj' }, @opts;
}

sub _menu {
    my ($self, $c, $type, $flag) = @_;
    my $ns  = $self->ns;

    my @labels = qw(Issue Position Argument);
    my @types  = map { $ns->ibis->uri($_) } @labels;

    #warn Data::Dumper::Dumper(\@types);

    my @out;

    my $map = $self->predicate_map;

    for my $i (0..$#labels) {
        my $v = $type->uri_value;
        my @checkbox;
        for my $item (@{$map->{$v}{$types[$i]->uri_value} || []}) {
            my $name = $ns->abbreviate($item->[0]) . ' : $';
            $name = '! ' . $name if $flag;
            push @checkbox, (E li => {},
                             (E label => {},
                              (E input => {
                                  type  => 'checkbox',
                                  name  => $name,
                                  value => '$obj',
                              }), ' ' . $item->[1]));
        }

        my %attr = (
            class => 'type-toggle',
            type  => 'radio',
            name  => $flag ? 'rdf:type :' : 'rdf-type',
            #value => $flag ? $ns->abbreviate($types[$i]) : '',
            value => $ns->abbreviate($types[$i]),
        );
        $attr{checked}  = 'checked' if $i == 0;
        #$attr{disabled} = 'disabled' unless @checkbox;

        my $class = 'relation ' . lc $labels[$i];

        push @out, (E fieldset => { class => $class },
                    (E legend => {},
                     (E label => {}, (E input => \%attr), " $labels[$i]")),
                    scalar(@checkbox) ? (E ul => {}, @checkbox) : ());
    }

    @out;
}

sub _do_toggle {
    E form => { id => 'toggle-which' },
        (E fieldset => {},
         (E label => {},
          (E input => { type => 'radio', name => 'new-item', value => '',
                        }), ' Connect existing'),
         (E label => {},
          (E input => { type => 'radio', value => 1, checked => 'checked',
                        name => 'new-item'}), ' Create new'));
}

sub _do_dl {
    my ($self, $c, $authed) = @_;
}

sub _do_content {
    my ($self, $c, $subject, $demote) = @_;
    my (%in, %res, %lit, $iter);

    my $m = $c->model('RDF');
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
            $res{$p} ||= [];
            push @{$res{$p}}, $s;
        }
        else {
            $in{$p} ||= [];
            push @{$in{$p}}, $s;
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
            $res{$p} ||= [];
            push @{$res{$p}}, $o;
        }
    }

    my @dl;
    my %p = map { $_ => 1 } (keys %in, keys %res);


    for my $k ($self->predicate_seq) {
        push @dl, (E dt => { about => $k, property => 'rdfs:label'},
                   $labels->{$k}[1]) if $res{$k};

        my $pred = $ns->abbreviate(iri($k));
        my $inv  = $inverse->{$k} ? $ns->abbreviate($inverse->{$k}[0]) : undef;

        for my $o (@{$res{$k} || []}) {
            my ($type) = $m->objects($o, $ns->rdf->type);
            my ($text) = $m->objects($o, $ns->rdf->value);
            #warn $text;
            my $uri = '/' . URI->new($o->value)->uuid;

            my @baleet = (E button => {
                class => 'disconnect',
                name => "- $pred :", value => $uri }, 'Disconnect');
            if ($inv) {
                unshift @baleet, (E input => { type => 'hidden',
                                               name => "-! $inv :",
                                               value => $uri });
            }

            push @dl, (E dd => {},
                       (E form => { method => 'POST', action => '',
                                    'accept-charset' => 'utf-8' },
                        (E div => {}, @baleet,
                         (E a => { href => $uri }, $text->value))));
        }
    }

    # XXX 
    my @buttons = map {
        my $t = "ibis:$_";
        my %attrs = (class => 'set-type', name => '= rdf:type :', value => $t);
        $attrs{disabled} = 'disabled' if grep { $ns->uri($t)->equal($_) }
            @{$res{$ns->rdf->type->value} ||[]};
        (E button => \%attrs, $_)
    } (qw(Issue Position Argument));

    my $rank = $demote || 1;

    my $v = $ns->rdf->value->value;
    E div => {},
        (E "h$rank" => {}, $lit{$v} ? $lit{$v}[0]->value : $subject->value),
            (E form => { class => 'set-type',
                         method => 'POST', 'accept-charset' => 'utf-8',
                         action => '' },
             (E div => {}, @buttons,
              $self->_do_collection_form($c, $subject))),
                  @dl ? (E dl => {
                      class => 'predicates' }, @dl) : ();

}

sub _do_collection_form {
    my ($self, $c, $subject) = @_;

    my $m = $c->model('RDF');
    my $ns = $self->ns;

    my @has = $m->subjects($ns->skos->member, $subject);
    my %map = map { $_->value => 1 } @has;

    my %boilerplate = (
        method => 'post',
        action => '',
        'accept-encoding' => 'utf-8'
    );

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

            my $a = E a => { href => '/' . $uu->uuid }, $label;
            my $li = E li => {}, $a,
                     (E button => {
                         name => '-! skos:member :', value => "$uu" },
                 'Remove');
            push @li, $li;
        }

        push @out, (E form => \%boilerplate, (E ul => {}, @li)) if @li;

        if (my @which = grep { ! $map{$_->[0]->value} } @s) {
            # generate a sorted list of option elements
            my @opts = map {
                (E option => { value => $_->[0]->value }, $_->[1]) }
                sort { $a->[1] cmp $b->[1] } @which;

            push @out, (E form => \%boilerplate,
                        (E select => { name => '! skos:member :' }, @opts),
                        (E button => {}, 'Attach'));
        }
    }

    # XXX THERE IS NOW A PROTOCOL MACRO FOR THIS
    my $newuuid = $self->uuid4urn;

    push @out,
        (E form => \%boilerplate,
         (E div => {},
          (E input => { type  => 'hidden',
                        name  => "= $newuuid rdf:type :",
                        value => $ns->skos->Collection->value }),
          (E input => { type => 'hidden',
                        name => '! skos:member :',
                       value => $newuuid }),
          (E div => {},
           (E input => {
               name => "= $newuuid skos:prefLabel" }),
           (E button => {}, 'Create & Attach'))));

    (E div => {}, @out);
}

sub _do_index {
    my ($self, $c, @collections) = @_;
    my $m = $c->model('RDF');
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
                push @$x, [$o, $v, $d];
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
                push @$x, [$o, $v, $d];
            }
        }
    }

    my @out;
    for my $i (0..$#labels) {
        my @triads = @{$set{$types[$i]->value} || []};

        my %d = map {
            $_->[0]->value => defined $_->[2] ? $_->[2]->value : undef
        } @triads;

        my @x;
        for my $x (sort { $d{$b->[0]->value} cmp $d{$a->[0]->value} } @triads) {
            my ($s, $v) = @{$x}[0,1];
            my $uu = URI->new($s->value);
            push @x, (E li => {}, (E a => { href => '/'. $uu->uuid },
                                   $v ? $v->value : $s->value));
            #push @x, $self->_do_content($c, $s, 2);
        }
        @x = (E ul => {}, @x) if @x;
        push @out, (E div => {}, (E h2 => {}, $labels[$i] . 's'), @x);
    }

    @out;
}

sub _do_404 {
    my ($self, $new) = @_;
    $new ||= '/' . $self->uuid4;
    E form => { method => 'POST', 'accept-charset' => 'utf-8', action => $new },
        (E fieldset => {},
         (E legend => {},
          (E span => {}, 'Start a new '),
          (E select => { name => 'rdf:type :' },
           (map { (E option => { value => "ibis:$_" }, $_) }
                qw(Issue Position Argument)))),
         (E input => { class => 'new-value',
                       type => 'text', name => '= rdf:value' }),
         (E button => {}, 'Go'));
}

sub _do_connect_form {
    my ($self, $c, $subject, $type) = @_;

    E form => { id => 'connect-existing',
                method => 'post', 'accept-charset' => 'utf-8', action => '' },
        (E fieldset => {}, $self->_menu($c, $type),
         (E fieldset => { class => 'interaction' },
          $self->_select($c, $subject), (E button => {}, 'Connect')));
}

sub _do_create_form {
    my ($self, $c, $subject, $type) = @_;

    my $m = $c->model('RDF');
    my $ns = $self->ns;

    # XXX WHY IS THIS A URI OBJECT AGAIN?
    my $s = $subject->isa('RDF::Trine::Node') ? $subject : iri("$subject");
    if ($subject->isa('URI::http')) {
        my $path = $subject->path;
        if (my ($uuid) = $path =~ $UUID_RE) {
            $s = iri("urn:uuid:$uuid");
        }
    }


    my @has = $m->subjects($ns->skos->member, $s);

    @has = map { E input => { type => 'hidden',
                              name => '! skos:member :',
                              value => $_->value  } } @has;

    my $new = '/' . $self->uuid4;

    E form => { id => 'create-new',
                method => 'post', 'accept-charset' => 'utf-8', action => $new },
                    (E fieldset => {}, @has,
         (E input => { type => 'hidden', name => '$ obj', value => $subject }),
         $self->_menu($c, $type, 1),
         (E fieldset => { class => 'interaction' },
          (E input => { class => 'new-value',
                        type => 'text', name => '= rdf:value' }),
           (E button => {}, 'Create')));
}

sub _doc {
    my ($self, $title, $base, $ns, $attrs, @body) = @_;

    $attrs ||= {};
    $ns    ||= $self->xmlns;

    DOM F(
        (DTD 'html'),
        (E html => { version => 'XHTML+RDFa 1.0',
                     xmlns => 'http://www.w3.org/1999/xhtml', %$ns },
         (E head => {},
          (E title => {}, $title),
          (E base => { href => $base }),
          (E link => { rel => 'stylesheet',
                       type => 'text/css', href => '/asset/main.css' }),
          (E script => { type => 'text/javascript', src => '/asset/jquery.js' }, '//'),
          (E script => { type => 'text/javascript', src => '/asset/main.js' }, '//'),
          (map { E link => $_ } @{$self->links || []}),
          (map { E meta => $_ } @{$self->metas || []}),
          ),#(E style => { type => 'text/css' }, $CSS)),
         (E body => $attrs, @body)));
}


=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

dorian,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
