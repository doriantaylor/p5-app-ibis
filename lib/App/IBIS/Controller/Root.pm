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
        model    => $c->model('RDF'),
        callback => sub { _from_urn(shift, $b) },
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
        # check model for subject
        my $m = $c->model('RDF');
        if ($m->count_statements($uuid, undef, undef)) {
            $resp->status(200);
            $resp->body($self->_get_uuid($c, $req->uri, $uuid));
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


sub _get_uuid {
    my ($self, $c, $uri, $subject) = @_;

    my $m = $c->model('RDF');

    #warn $subject;
    my $rns = $self->ns;

    # XXX THIS CAN GET AWAY ON US
    my ($type)  = $m->objects($subject, $rns->rdf->type);
    my ($title) = $m->objects($subject, $rns->rdf->value);

    my %attrs;
    $attrs{typeof} = $rns->abbreviate($type) if $type;

    $self->_doc($title ? $title->value : '', $uri, undef, \%attrs,
                (E div => { class => 'aside' },
                 (E object => { class => 'hiveplot',
                                data => '/hp',
                                type => 'image/svg+xml' }, "\xa0")),
                 (E div => { class => 'main' },
                  $self->_do_content($c, $subject),
                  (E div => {},
                   $self->_do_connect_form($c, $subject, $type),
                   $self->_do_create_form($c, $uri, $type)),
                  $self->_do_toggle),
            )->toString(1);
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
    warn $m->size;
    # add a timestamp
    unless ($m->count_statements($subject, undef, undef)) {
        my $now = literal(DateTime->now . 'Z', undef, $rns->xsd->dateTime);
        $patch->add_this($subject, $rns->dct->created, $now);
    }

    $patch->apply($m);

    $m->_store->_model->sync;
    warn $m->size;
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
        $attr{disabled} = 'disabled' unless @checkbox;

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
                        checked => 'checked' }), ' Connect existing'),
         (E label => {},
          (E input => { type => 'radio', value => 1,
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
                         action => '' }, (E div => {}, @buttons)),
                             @dl ? (E dl => {
                                 class => 'predicates' }, @dl) : ();

}

sub _do_index {
    my ($self, $c) = @_;
    my $m = $c->model('RDF');
    my $ns = $self->ns;


    my @labels = qw(Issue Position Argument);
    my @types  = map { $self->ns->ibis->uri($_) } @labels;

    my @out;
    for my $i (0..$#labels) {
        my @s = $m->subjects($ns->rdf->type, $types[$i]);
        my %d = map {
            my ($x) = $m->objects($_, $ns->dct->created);
            $_->value => defined $x ? $x->value : undef } @s;

        my @x;
        for my $s (sort { $d{$b->value} cmp $d{$a->value} } @s) {
            my ($v) = $m->objects($s, $ns->rdf->value);
            my $uu = URI->new($s->value);
            push @x, (E li => {}, (E a => { href => '/'. $uu->uuid },
                                   $v->value || $s->value));
            #push @x, $self->_do_content($c, $s, 2);
        }
        @x = E ul => {}, @x if @x;
        push @out, (E div => {}, (E h1 => {}, $labels[$i] . 's'), @x);
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
                method => 'POST', 'accept-charset' => 'utf-8', action => '' },
        (E fieldset => {}, $self->_menu($c, $type),
         (E fieldset => { class => 'interaction' },
          $self->_select($c, $subject), (E button => {}, 'Connect')));
}

sub _do_create_form {
    my ($self, $c, $subject, $type) = @_;

    my $new = '/' . $self->uuid4;

    E form => { id => 'create-new',
                method => 'POST', 'accept-charset' => 'utf-8', action => $new },
        (E fieldset => {},
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
