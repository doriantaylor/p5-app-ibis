package App::IBIS::Controller::IBIS;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use RDF::Trine qw(iri blank literal statement);
use RDF::Trine::Namespace qw(RDF);
use constant IBIS => RDF::Trine::Namespace->new
    ('https://vocab.methodandstructure.com/ibis#');


BEGIN {
    extends 'Catalyst::Controller';
    with    'App::IBIS::Role::Markup';
}

=head1 NAME

App::IBIS::Controller::IBIS - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub _do_connect_form {
    my ($self, $c, $subject, $type) = @_;

    my $ns = $self->ns;

    # XXX this should be part of the configuration
    my @types = ($ns->ibis->Issue, $ns->ibis->Position,
                 $ns->ibis->Argument, $ns->skos->Concept);

    return { %{$self->FORMBP}, id => 'connect-existing', -content => {
        -name => 'fieldset', class => 'edit-group', -content => [
            $self->edit_menu($c, $type, types => \@types),
            # XXX fieldset can't do flex
            { -name => 'div', class => 'interaction',
              -content => [
                  $self->type_select($c, $subject, types => \@types),
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
        if (my ($uuid) = $path =~ $self->UUID_RE) {
            $s = iri("urn:uuid:$uuid");
        }
    }

    my @types = ($ns->ibis->Issue, $ns->ibis->Position,
                 $ns->ibis->Argument, $ns->skos->Concept);

    my @has = $m->subjects($ns->skos->member, $s);
    @has = map +{ -name => 'input', type => 'hidden',
                  name => '! skos:member :', value => $_->value }, @has;

    my $new = $self->uuid4;

    return { %{$self->FORMBP}, id => 'create-new', action => $new, -content => {
        -name => 'fieldset', class => 'edit-group', -content => [
            @has,
            { -name => 'input', type => 'hidden',
              name => '$ obj', value => $subject },
            $self->edit_menu($c, $type, types => \@types, flag => 1),
            # XXX fieldset can't do flex
            { -name => 'div', class => 'interaction', -content => [
                { -name => 'input', class => 'new-value',
                  type => 'text', name => '= rdf:value' },
                { -name => 'button', class => 'fa fa-plus', -content => '' } ]
          } ] } };
}

sub _do_content {
    my ($self, $c, $subject, $demote) = @_;
    my (%in, %res, %lit, $iter);

    my $m = $c->rdf_cache;

    my $ns      = $self->ns;
    my $inverse = $self->inverse;
    my $labels  = $self->labels;

    # XXX PALLIATIVE SURGERY LOL
    my ($resources, $literals) = $c->neighbour_structs($subject);
    %res = %$resources;
    %lit = %$literals;

    my @asides = $self->do_relations(
        $c, \%res, [$self->predicate_seq], $ns->rdf->value);

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
                { %{$self->FORMBP}, class => 'types', -content => \@buttons },
                { %{$self->FORMBP}, class => 'description', -content => [
                    { -name => 'textarea', class => 'heading',
                      name => '= rdf:value', -content => $text },
                    { -name => 'button', class => 'fa fa-sync',
                      -content => '' } ] } ] },
            $meta,
            $self->_do_concept_form($c, $subject),
            $self->do_link_form($c, $subject),
        ] },
        { -name => 'section', class => 'relations', -content => \@asides },
    );
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
        next unless $concept->uri_value =~ $self->UUID_URN;
        next unless $m->count_statements
            ($concept, $ns->rdf->type, $ns->skos->Concept);

        # cache this to prune from select options
        $li{$concept->uri_value} = $concept;

        my $label = $c->label_for($concept);

        #my ($label) = $m->objects($concept, $ns->skos->prefLabel);

        my $uri = URI->new($concept->uri_value);
        $uri = URI->new_abs($uri->uuid, $bs);

        push @li, { -name => 'li', -content => { %{$self->FORMBP}, -content => [
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
        my ($label) = ($m->objects($concept, $ns->skos->prefLabel),
                       $m->objects($concept, $ns->rdfs->label));

        push @opt, { -name => 'option', value => $concept->uri_value,
                     -content => $label ? $label->value : $concept->uri_value };
    }

    my $cl = $c->collator;
    @opt = sort { $cl->cmp($a->{-content}, $b->{-content}) } @opt;

    push @li, { -name => 'li', -content => { %{$self->FORMBP}, -content => [
        { -name => 'select', name => 'dct:references :',
          -content => [{ -name => 'option', -content => '' }, @opt] },
        { -name => 'button', class => 'fa fa-link', -content => '' }]}} if @opt;
    push @li, { -name => 'li', -content => { %{$self->FORMBP}, -content => [
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

sub get_ibis :Private {
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

    # my $ci2 = $c->uri_for('ci2', { subject => $uu->uuid,
    #                                degrees => 240, rotate => 240, });


    my $doc = $c->stub(
        ns    => $self->uns,
        uri   => $uri,
        title => $label . $title ? $title->value : '',
        attr  => \%attrs,
        content => [ { -name => 'main', -content => [
            { -name => 'article', -content => [
                $self->_do_content($c, $subject),
                #{ -name => 'hr', class => 'separator' },
                { -name => 'section', class => 'edit', -content => [
                    $self->TOGGLE,
                    $self->_do_connect_form($c, $subject, $type),
                    $self->_do_create_form($c, $uri, $type) ] },
            ] },
            { -name => 'figure', id => 'force', class => 'aside', # [
                # { -name => 'object', class => 'other baby hiveplot',
                #   type => 'image/svg+xml',
                #   data => $c->uri_for('concepts',
                #                       { subject => \@concepts,
                #                         degrees => 240, rotate => 240, }) },
                # { -name => 'object', class => 'hiveplot', data => $ci2,
                #   type => 'image/svg+xml', -content => '(Circos Plot)' }
            # ]
          } ] }, $self->FOOTER ],
    );

    # XXX forward this maybe?
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
