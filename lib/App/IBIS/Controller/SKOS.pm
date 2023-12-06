package App::IBIS::Controller::SKOS;
use Moose;
use namespace::autoclean;

BEGIN {
    extends 'Catalyst::Controller';
    with    'App::IBIS::Role::Markup';
}

=head1 NAME

App::IBIS::Controller::SKOS - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for SKOS entities.

=head1 METHODS

=cut

sub do_concept_self {
    my ($self, $c, $subject) = @_;

    my $m  = $c->rdf_cache;
    my $ns = $self->ns;

    my ($label) = $m->objects($subject, $ns->skos->prefLabel);
    my ($desc)  = $m->objects($subject, $ns->skos->definition);
    $desc = $desc ? $desc->literal_value : '';

    return { -name => 'section', class => 'self', -content => [
        { -name => 'h1', -content => { %{$self->FORMBP}, -content => [
            { -name => 'input', type => 'text',
              name => '= skos:prefLabel',
              value => $label->literal_value },
            { -name => 'button', class => 'fa fa-sync',
              -content => '', } ] } },
        { %{$self->FORMBP}, -content => [
            { -name => 'textarea', class => 'description',
              name => '= skos:definition', -content => $desc },
            { -name => 'button', class => 'update fa fa-sync',
              -content => '' } ] },
        $self->do_link_form($c, $subject, {
            predicate => $ns->skos->altLabel, literal => 1,
            class => 'label', label => 'Alternative Labels' }),
        $self->do_link_form($c, $subject, {
            predicate => $ns->skos->hiddenLabel, literal => 1,
            class => 'label hidden', label => 'Hidden Labels' }),
        $self->do_link_form($c, $subject),
        $self->do_link_form($c, $subject, 1),
    ] };
}

# the order we would like the neighbours to show up in
my @SKOS_SEQ = (
    ['Has Narrower'  => ['', 'narrower'],
     # ['Transitive', 'narrowerTransitive'],
     # ['Narrow Match', 'narrowMatch']
 ],
    ['Has Related' => ['', 'related'],
     # ['Close Match', 'closeMatch'], ['Exact Match', 'exactMatch']
 ],
    ['Has Broader' => ['', 'broader'],
     # ['Transitive', 'broaderTransitive'],
     # ['Broad Match', 'broadMatch']
 ],
);

sub do_concept_neighbours {
    my ($self, $c, $subject) = @_;

    my ($resources) = $self->neighbour_structs($c, $subject);

    my $ns  = $self->ns;

    # XXX PALLIATIVE SURGERY LOL
    my @skosp = map {
        $ns->skos->uri($_)
    } qw(narrower narrowMatch related closeMatch exactMatch broader broadMatch);

    my @out = $self->do_relations($c, $resources, \@skosp, $ns->skos->prefLabel);

    return { -name => 'section', class => 'relations', -content => \@out };
}

sub do_concept_menu {
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

sub do_concept_create_form {
    my ($self, $c, $subject) = @_;

    my $new = $self->uuid4;

    return {
        %{$self->FORMBP},
        id => 'create-new', action => $new, about => 'skos:Concept',
        -content => [
            { -name => 'input', type => 'hidden', name => 'rdf:type :',
              value => 'skos:Concept' },
            { -name => 'input', type => 'hidden', name => '! $predicate :',
              value => $subject->uri_value },
            { -name => 'fieldset', class => 'edit-group', -content => [
                $self->do_concept_menu($c, 1),
                { -name => 'div', class => 'interaction', -content => [
                    { -name => 'input', type => 'text',
                      class => 'new-value', name => 'skos:prefLabel' },
                    { -name => 'button', class => 'fa fa-plus',
                      -content => '' }
                ] } ] } ]};
}

sub do_concept_connect_form {
    my ($self, $c, $subject) = @_;

    my $ns = $self->ns;
    my $m  = $c->rdf_cache;

    my %c;
    for my $c ($m->subjects($ns->rdf->type, $ns->skos->Concept)) {
        next unless $c->is_resource;
        my $cv = $c->uri_value;
        next unless $cv =~ $self->UUID_URN;

        my ($lab) = $m->objects($c, $ns->skos->prefLabel);
        $c{$cv} = $lab ? $lab->value : '';
    }

    my @opt = map +{ -name => 'option', value => $_, -content => $c{$_} },
        sort { $c{$a} cmp $c{$b} } keys %c;

    return {
        %{$self->FORMBP}, id => 'connect-existing', action => '',
        about => 'skos:Concept', -content => {
            -name => 'fieldset', class => 'edit-group', -content => [
                $self->do_concept_menu($c, 1),
                { -name => 'div', class => 'interaction', -content => [
                    { -name => 'select', class=> 'target',
                      name => '$predicate :', -content => \@opt },
                    { -name => 'button', class => 'fa fa-link',
                      -content => '' } ] } ] } };
}

sub do_collection_form {
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
                    { href => $uu->uuid, -content => $label },
                    { -name => 'button', name => '-! skos:member :',
                      value => "$uu" }, 'Remove' ]
            };
        }

        push @out, { %{$self->FORMBP},
                     -content => { -name => 'ul', -content => \@li } } if @li;

        if (my @which = grep { ! $map{$_->[0]->value} } @s) {
            # generate a sorted list of option elements
            my @opts = map +{ -name => 'option', value => $_->[0]->value,
                              -content => $_->[1] },
                                  sort { $a->[1] cmp $b->[1] } @which;

            push @out, { %{$self->FORMBP}, -content => [
                { -name => 'select', name => '! skos:member :',
                  -content => \@opts },
                { -name => 'button', class => 'fa fa-link', -content => '' } ]
            }; # attach
        }
    }

    # XXX THERE IS NOW A PROTOCOL MACRO FOR THIS
    my $newuuid = $self->uuid4urn;

    push @out, { %{$self->FORMBP}, -content => {
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

sub get_concept :Private {
    my ($self, $c, $subject) = @_;

    my $doc = $self->do_boilerplate(
        $c, $subject,
        self => $self->do_concept_self($c, $subject),
        relations => $self->do_concept_neighbours($c, $subject),
        edit => { -name => 'section', class => 'edit', -content => [
            $self->TOGGLE,
            $self->do_concept_create_form($c, $subject),
            $self->do_concept_connect_form($c, $subject),
        ] },
    );

    $c->res->body($doc);
}

sub get_collection :Private {
    my ($self, $c, $subject) = @_;

    # XXX COPY THIS SHIT FROM THE OTHER ONE

    my $uri = $c->req->uri;

    my $m = $c->rdf_cache;

    #warn $subject;
    my $rns = $self->ns;

    # XXX THIS CAN GET AWAY ON US
    my ($type)  = $m->objects($subject, $rns->rdf->type);
    my ($title) = $m->objects($subject, $rns->skos->prefLabel);
    my ($desc)  = $m->objects($subject, $rns->skos->definition);

    my %attrs;
    $attrs{typeof} = $rns->abbreviate($type) if $type;

    my $maybetitle = $title ? $title->value : '';

    my $doc = $c->stub(
        uri   => $uri,
        title => $maybetitle || $subject->value,
        attr  => \%attrs,
        content => { %{$self->FORMBP}, action => $uri, -content => [
            { -name => 'h1', -content => {
                -name => 'input', name => '= skos:prefLabel',
                value => $maybetitle } },
            { -name => 'p', -content => {
                -name => 'textarea', name => '= skos:definition',
                -content => $desc ? $desc->value : '' }},
            $self->do_index($c, $subject) ] },
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
