package App::IBIS::Role::Markup;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use namespace::autoclean;

use Data::UUID::NCName ();

use RDF::Trine qw(iri blank literal statement);
use RDF::Trine::Namespace qw(RDF);
use constant IBIS => RDF::Trine::Namespace->new
    ('https://vocab.methodandstructure.com/ibis#');

with qw(App::IBIS::Role::Schema Role::Markup::XML);

our $UUID_RE  = qr/([0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){4}[0-9A-Fa-f]{8})/;
our $UUID_URN = qr/^urn:uuid:([0-9a-f]{8}(?:-[0-9a-f]{4}){4}[0-9a-f]{8})$/i;

my %FIGURE = (
    -name => 'figure',
    id    => 'force',
    class => 'aside',
);

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
                { -name => 'li', -content => { href => './',
                                               -content => 'Overview' } },
                { -name => 'li', -content => {
                    href => 'we-have-issues',
                    -content => 'What is this thing?' } },
            ] } },
);

my %TOGGLE = (
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
);

# XXX TIL these only return scalar context

has FORMBP => (
    is      => 'ro',
    default => sub { wantarray ? %FORMBP : {%FORMBP} },
);

has FOOTER => (
    is      => 'ro',
    default => sub { wantarray ? %FOOTER : {%FOOTER} },
);

has TOGGLE => (
    is      => 'ro',
    default => sub { wantarray ? %TOGGLE : {%TOGGLE} },
);

has UUID_RE => (
    is      => 'ro',
    default => sub { $UUID_RE },
);

has UUID_URN => (
    is      => 'ro',
    default => sub { $UUID_URN },
);

sub edit_menu {
    my ($self, $c, $type, @rest) = @_;

    my (%p, $flag);

    if (@rest && @rest % 2) {
        $flag = $rest[0];
    }
    else {
        %p = @rest;
        $flag = $p{flag};
    }

    my $ns  = $self->ns;

    my @labels = qw(Issue Position Argument);
    my @types  = map { $ns->ibis->uri($_) } @labels;

    # XXX
    if (0) {
        push @labels, 'Concept';
        push @types, $ns->skos->Concept;
    }

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

sub do_relations {
    my ($self, $c, $res, $predicates, $labelp) = @_;

    my $m = $c->rdf_cache;

    my $ns      = $self->ns;
    my $inverse = $self->inverse;
    my $labels  = $self->labels;

    my @asides;

    #
    for my $k (@$predicates) {

        my $pred = $ns->abbreviate($k);
        $k       = $k->uri_value; # we don't need this as an iri obj anymore
        my $inv  = $inverse->{$k} ? $ns->abbreviate($inverse->{$k}[0]) : undef;

        my %li;
        for my $o (values %{$res->{$k} || {}}) {
            my ($type) = $m->objects($o, $ns->rdf->type);
            my ($text) = $m->objects($o, $labelp);
            # replicate the uuid if text is missing
            $text = $o unless $text;

            my $uri = URI->new($o->value)->uuid;

            my @baleet = { -name => 'button',
                           class => 'disconnect fa fa-unlink',
                           name => "- $pred :", value => $uri };
            unshift @baleet, { -name => 'input', type => 'hidden',
                               name => "-! $inv :", value => $uri } if $inv;

            my $tv = $text ? $text->value : $uri;

            $li{$tv . $uri} = {
                -name => 'li', about => $o->value,
                typeof => $ns->abbreviate($type) || $type,
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

        if ($res->{$k} && @li) {
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

    wantarray ? @asides : \@asides;
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

sub type_select {
    my ($self, $c, $subject, %p) = @_;

    my $ns = $self->ns;
    my $m  = $c->rdf_cache;

    my @types = @{$p{types} || []};
    @types = grep { $_->is_resource } $m->objects($subject, $ns->rdf->type)
        unless @types;

    my @labels = map { $self->labels->{$_} } @types;

    my $map = $self->_naive_typeof($c, @types);
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
            my $s = iri($_); [$s, $m->objects($s, $rdfv)]
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


=head2 do_boilerplate $C, $SUBJECT, %PARAMS

=over 4

=item self

=item relations

=item edit

=item figure

=back

=cut

sub do_boilerplate {
    my ($self, $c, $subject, %p) = @_;

    my $m  = $c->rdf_cache;
    my $ns = $self->ns;

    my $types = join ' ', sort { $a cmp $b } map { $ns->abbreviate($_) } grep {
        $_->is_resource } ($m->objects($subject, $ns->rdf->type));

    my %attrs = (typeof => $types, %{$p{attrs} || {}});

    $p{figure} ||= \%FIGURE;

    $c->stub(
        ns      => $self->uns,
        uri     => $c->req->uri,
        attr    => \%attrs,
        content => [
            { -name => 'main', -content => [
                { -name => 'article',
                  -content => [@p{qw(self relations edit)}] },
                $p{figure}, ] },\%FOOTER ],
    );
}

sub do_link_form {
    my ($self, $c, $subject, $reverse, $tag) = @_;

    my $m  = $c->rdf_cache;
    my $ns = $self->ns;
    my $bs = $c->req->base;

    my %p;
    if (ref $reverse eq 'HASH') {
        %p = (%p, %$reverse);
        $p{tag} ||= $tag if $tag;
        $reverse = $p{reverse};
    }
    $p{predicate} ||= $ns->dct->references;
    $p{class} ||= 'link';

    $tag ||= 'aside';

    my $pred = $ns->abbreviate($p{predicate});

    my @in = $reverse ? $m->subjects($p{predicate}, $subject) :
        $m->objects($subject, $p{predicate});

    my @li;
    for my $link (@in) {
        my ($elem, $minus);

        my $value;
        if ($link->is_resource) {
            my $uri = URI->new($link->uri_value);
            if ($uri->isa('URI::urn::uuid')) {
                # skip concepts
                next if $m->count_statements
                    ($link, $ns->rdf->type, $ns->skos->Concept);
                $uri = URI->new_abs($uri->uuid, $bs);
            }

            # XXX do labels here
            my $label = $c->label_for($link);

            $elem = { href => $uri, -content => $label->value };

            $minus = sprintf '-%s %s :', $reverse ? '!' : '', $pred;
            $value = "$uri";
        }
        elsif ($link->is_literal) {
            $minus = "- $pred";
            $value = $link->literal_value;

            $elem = { -content => $link->value };
            if ($link->has_language) {
                my $lang = $link->literal_value_language;
                $elem->{'xml:lang'} = $lang;
                $minus = sprintf '%s @%s', $minus, $lang;
            }
            elsif ($link->has_datatype) {
                my $dt = $link->literal_datatype;
                $dt = $ns->abbreviate($dt) || $dt;
                $elem->{datatype} = $dt;
                $minus = sprintf '%s ^%s', $minus, $dt;
            }
        }
        else {
            next;
        }

        push @li, { -name => 'li', -content => { %FORMBP, -content => [
            $elem,
            { -name => 'button', name => $minus, value => $value,
              class => 'disconnect fa fa-unlink', -content => '' } ] } };
    }

    # conveniently we can sort this list after we construct it
    @li = sort {
        $a->{-content}{-content}[0]{-content}
            cmp $b->{-content}{-content}[0]{-content} } @li;

    my $designator = do {
        if ($p{literal}) {
            Scalar::Util::blessed($p{literal}) ?
                  sprintf(' ^%s', $ns->abbreviate($p{literal})) :
                  $p{literal} =~ /^[A-Za-z-]+$/ ? " \@$p{literal}" : '';
        }
        else {
            ' :';
        }
    };

    my $plus = sprintf '%s%s', $pred, $designator;
    $plus = "! $plus" if $reverse;

    # default list item to add a new link
    push @li, { -name => 'li', -content => { %FORMBP, -content => [
        { -name => 'input', type => 'text', name => $plus },
        { -name => 'button', class=> 'fa fa-plus', -content => '' } ] } };

    my $lab = $p{label} || ($reverse ? 'Inbound Links' : 'Links');

    return { -name => $tag, class => sprintf('predicate %s', $p{class}),
             -content => [
                 { -name => 'h3', class => 'label', -content => $lab },
                 { -name => 'ul', -content => \@li } ] };
}

1;
