package App::IBIS::Role::Schema;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use namespace::autoclean;

use URI;
use URI::NamespaceMap;
use RDF::Trine::NamespaceMap;

#use RDF::Trine qw(iri blank literal);

use Data::GUID::Any    ();
use Data::UUID::NCName ();

# if i hadn't already mentioned, the angry fruit salad takes care of
# all this crap.

my %XMLNS = (
    rdf   => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    rdfs  => 'http://www.w3.org/2000/01/rdf-schema#',
    cgto  => 'https://vocab.methodandstructure.com/graph-tool#',
    ci    => 'https://vocab.methodandstructure.com/content-inventory#',
    dct   => 'http://purl.org/dc/terms/',
    bibo  => 'http://purl.org/ontology/bibo/',
    foaf  => 'http://xmlns.com/foaf/0.1/',
    ibis  => 'https://vocab.methodandstructure.com/ibis#',
    org   => 'http://www.w3.org/ns/org#',
    pav   => 'http://purl.org/pav/',
    pm    => 'https://vocab.methodandstructure.com/process-model#',
    prov  => 'http://www.w3.org/ns/prov#',
    qb    => 'http://purl.org/linked-data/cube#',
    sioc  => 'http://rdfs.org/sioc/ns#',
    sioct => 'http://rdfs.org/sioc/types#',
    skos  => 'http://www.w3.org/2004/02/skos/core#',
    xhv   => 'http://www.w3.org/1999/xhtml/vocab#',
    xlink => 'http://www.w3.org/1999/xlink',
    xsd   => 'http://www.w3.org/2001/XMLSchema#',
);

my $NS = RDF::Trine::NamespaceMap->new(\%XMLNS);

my $IBIS_RE = do { my $x = $NS->ibis->uri->value; qr/^$x/; };

sub _expand {
    my $x = $_[0] // $_;
    # this will give us ibis objects
    my %y = map { $_ => ucfirst($_) } qw(issue position argument);
    $x =~ /:/ ? $NS->uri($x) : $NS->ibis->uri($y{$x} // $x);
}

my %LABELS = map {
    my $x = _expand($_->[0]);
    $x->uri_value => [$x, $_->[1]] } (
        # IBIS
        ['Issue',         'Issue'],
        ['Position',      'Position'],
        ['Argument',      'Argument'],
        ['concerns',      'Concerns'],
        ['concern-of',    'Concern of'],
        ['endorses',      'Endorses'],
        ['endorsed-by',   'Endorsed By'],
        ['generalizes',   'Generalizes'],
        ['specializes',   'Specializes'],
        ['replaces',      'Replaces'],
        ['replaced-by',   'Replaced By'],
        ['questions',     'Questions'],
        ['questioned-by', 'Questioned By'],
        ['suggests',      'Suggests'],
        ['suggested-by',  'Suggested By'],
        ['response',      'Has Response'],
        ['responds-to',   'Responds to'],
        ['supports',      'Supports'],
        ['supported-by',  'Supported By'],
        ['opposes',       'Opposes'],
        ['opposed-by',    'Opposed By'],
        # SKOS
        ['skos:Concept',            'Concept'],
        ['skos:ConceptScheme',      'Concept Scheme'],
        ['skos:Collection',         'Collection'],
        ['skos:OrderedCollection',  'Ordered Collection'],
        ['skos:related',            'Related to'],
        ['skos:narrower',           'Has Narrower'],
        ['skos:broader',            'Has Broader'],
        ['skos:narrowerTransitive', 'Has Narrower (Transitive)'],
        ['skos:broaderTransitive',  'Has Broader (Transitive)'],
        ['skos:narrowMatch',        'Has Narrower Match'],
        ['skos:broadMatch',         'Has Broader Match'],
        ['skos:closeMatch',         'Has Close Match'],
        ['skos:exactMatch',         'Has Exact Match'],
        # FOAF
        # ORG
        # SIOC
);

my @DEFAULT_LABELS = map {
    _expand($_) } qw(skos:prefLabel skos:altLabel rdfs:label dct:title);
my @ALT_LABELS     = map {
    _expand($_) } qw(skos:altLabel bibo:shortTitle dct:alternative);
my $RDFV = $NS->rdf->value;

my %LPROPS = map {
    my $x = _expand($_->[0]);
    my @y = @{$_->[1]};
    my @z = @{$_->[2]};
    $x->uri_value => [\@y, \@z];
} (
    ['Issue',                   [$RDFV, @DEFAULT_LABELS], \@ALT_LABELS],
    ['Position',                [$RDFV, @DEFAULT_LABELS], \@ALT_LABELS],
    ['Argument',                [$RDFV, @DEFAULT_LABELS], \@ALT_LABELS],
#    ['skos:Concept',           \@DEFAULT_LABELS, \@ALT_LABELS],
#    ['skos:ConceptScheme',     \@DEFAULT_LABELS, \@ALT_LABELS],
#    ['skos:Collection',        \@DEFAULT_LABELS, \@ALT_LABELS],
#    ['skos:OrderedCollection', \@DEFAULT_LABELS, \@ALT_LABELS],
);

my %INVERSE = map {
    my ($x, $y) = map(_expand, @$_);
    my @out = ($x->uri_value => $LABELS{$y->uri_value});
    $x->equal($y) ? @out : (@out, $y->uri_value => $LABELS{$x->uri_value});
} (
        [qw(concerns concern-of)],
        [qw(endorses endorsed-by)],
        [qw(generalizes specializes)],
        [qw(replaces replaced-by)],
        [qw(questions questioned-by)],
        [qw(suggests suggested-by)],
        [qw(response responds-to)],
        [qw(supports supported-by)],
        [qw(opposes opposed-by)],
        # SKOS
        [qw(skos:related skos:related)],
        [qw(skos:narrower skos:broader)],
        [qw(skos:narrowerTransitive skos:broaderTransitive)],
        [qw(skos:narrowMatch skos:broadMatch)],
        [qw(skos:closeMatch skos:closeMatch)],
        [qw(skos:exactMatch skos:exactMatch)],
        [qw(skos:relatedMatch skos:relatedMatch)],
        [qw(skos:hasTopConcept skos:topConceptOf)],
        # DCT
        [qw(dct:hasFormat  dct:isFormatOf)],
        [qw(dct:hasPart    dct:isPartOf)],
        [qw(dct:hasVersion dct:isVersionOf)],
        [qw(dct:references dct:isReferencedBy)],
        [qw(dct:replaces   dct:isReplacedBy)],
        [qw(dct:requires   dct:isRequiredBy)],
        # ORG
        [qw(org:memberOf org:hasMember)],
        [qw(org:hasSubOrganization org:isSubOrganizationOf)],
        [qw(org:hasUnit org:isUnitOf)],
        # SIOC
        [qw(sioc:space_of sioc:has_space)],
        [qw(sioc:container_of sioc:has_container)],
        [qw(sioc:parent_of sioc:has_parent)],
);

my %MAP = (
    issue => {
        issue => [
            [$NS->ibis->generalizes,            'Generalizes'],
            [$NS->ibis->specializes,            'Specializes'],
            [$NS->ibis->suggests,                  'Suggests'],
            [$NS->ibis->uri('suggested-by'),   'Suggested By'],
            [$NS->ibis->questions,                'Questions'],
            [$NS->ibis->uri('questioned-by'), 'Questioned By'],
            #[$NS->ibis->replaces,                  'Replaces'],
            #[$NS->ibis->uri('replaced-by'),     'Replaced By'],
        ],
        position => [
            [$NS->ibis->response,              'Has Response'],
            [$NS->ibis->uri('suggested-by'),   'Suggested By'],
            [$NS->ibis->questions,                'Questions'],
        ],
        argument => [
            #[$NS->ibis->generalizes,            'Generalizes'],
            #[$NS->ibis->specializes,            'Specializes'],
            [$NS->ibis->suggests,                  'Suggests'],
            [$NS->ibis->uri('suggested-by'),   'Suggested By'],
            [$NS->ibis->questions,                'Questions'],
            [$NS->ibis->uri('questioned-by'), 'Questioned By'],
        ],
        'skos:Concept' => [
            [$NS->ibis->concerns,                  'Concerns'],
        ],
        'foaf:Person' => [
            [$NS->ibis->uri('endorsed-by'),     'Endorsed By'],
        ],
    },
    position => {
        issue => [
            [$NS->ibis->uri('responds-to'),     'Responds to'],
            [$NS->ibis->suggests,                  'Suggests'],
            [$NS->ibis->uri('questioned-by'), 'Questioned By'],
        ],
        position => [
            [$NS->ibis->generalizes,            'Generalizes'],
            [$NS->ibis->specializes,            'Specializes'],
        ],
        argument => [
            [$NS->ibis->uri('supported-by'),   'Supported By'],
            [$NS->ibis->uri('opposed-by'),       'Opposed By'],
            [$NS->ibis->uri('responds-to'),     'Responds To'],
        ],
        'skos:Concept' => [
            [$NS->ibis->concerns,                  'Concerns'],
        ],
        'foaf:Person' => [
            [$NS->ibis->uri('endorsed-by'),     'Endorsed By'],
        ],
    },
    argument => {
        issue => [
            #[$NS->ibis->generalizes,            'Generalizes'],
            #[$NS->ibis->specializes,            'Specializes'],
            [$NS->ibis->suggests,                  'Suggests'],
            [$NS->ibis->uri('suggested-by'),   'Suggested By'],
            [$NS->ibis->questions,                'Questions'],
            [$NS->ibis->uri('questioned-by'), 'Questioned By'],
        ],
        position => [
            [$NS->ibis->supports,                  'Supports'],
            [$NS->ibis->opposes,                    'Opposes'],
            [$NS->ibis->questions,                'Questions'],
            [$NS->ibis->uri('suggested-by'),   'Suggested By'],
            [$NS->ibis->response,              'Has Response'],
        ],
        argument => [
            [$NS->ibis->generalizes,            'Generalizes'],
            [$NS->ibis->specializes,            'Specializes'],
            [$NS->ibis->suggests,                  'Suggests'],
            [$NS->ibis->uri('suggested-by'),   'Suggested By'],
            [$NS->ibis->questions,                'Questions'],
            [$NS->ibis->uri('questioned-by'), 'Questioned By'],
        ],
        'skos:Concept' => [
            [$NS->ibis->concerns,                  'Concerns'],
        ],
        'foaf:Person' => [
            [$NS->ibis->uri('endorsed-by'),     'Endorsed By'],
        ],
    },
    'skos:Concept' => {
        'skos:Concept' => [
            [$NS->skos->related,            'Is Related'],
            [$NS->skos->narrower,           'Has Narrower'],
            [$NS->skos->broader,            'Has Broader'],
            #[$NS->skos->narrowerTransitive, 'Has Narrower (Transitive)'],
            #[$NS->skos->broaderTransitive,  'Has Broader (Transitive)'],
            [$NS->skos->narrowMatch,        'Has Narrower Match'],
            [$NS->skos->broadMatch,         'Has Broader Match'],
            [$NS->skos->closeMatch,         'Has Close Match'],
            [$NS->skos->exactMatch,         'Has Exact Match'],
        ],
        issue => [
            [$NS->ibis->uri('concern-of'), 'Concern Of'],
        ],
        position => [
            [$NS->ibis->uri('concern-of'), 'Concern Of'],
        ],
        argument => [
            [$NS->ibis->uri('concern-of'), 'Concern Of'],
        ],
    },
    # this is where you get a combinatorial explosion
    'foaf:Person' => {
        'org:Organization' => [
            [$NS->org->memberOf, 'Member Of'],
            [$NS->org->headOf,     'Head Of'],
        ],
        'org:FormalOrganization' => [
            [$NS->org->memberOf, 'Member Of'],
            [$NS->org->headOf,     'Head Of'],
        ],
        'org:OrganizationalUnit' => [
            [$NS->org->memberOf, 'Member Of'],
            [$NS->org->headOf,     'Head Of'],
        ],
        'org:OrganizationalCollaboration' => [
            [$NS->org->memberOf, 'Member Of'],
            [$NS->org->headOf,     'Head Of'],
        ],
        'issue' => [
            [$NS->ibis->endorses, 'Endorses'],
        ],
        'position' => [
            [$NS->ibis->endorses, 'Endorses'],
        ],
        'argument' => [
            [$NS->ibis->endorses, 'Endorses'],
        ],
    },
    'org:Organization' => {
        'org:Organization' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
        ],
        'org:FormalOrganization' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
        ],
        'org:OrganizationalCollaboration' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
        ],
        'org:OrganizationalUnit' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
            [$NS->org->hasUnit,                           'Has Unit'],
        ],
        'foaf:Person' => [
            [$NS->org->hasMember, 'Has Member'],
        ],
    },
    'org:FormalOrganization' => {
        'org:Organization' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
        ],
        'org:FormalOrganization' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
        ],
        'org:OrganizationalCollaboration' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
        ],
        'org:OrganizationalUnit' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
            [$NS->org->hasUnit,                           'Has Unit'],
        ],
        'foaf:Person' => [
            [$NS->org->hasMember,                       'Has Member'],
        ],
    },
    'org:OrganizationalCollaboration' => {
        'org:Organization' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
        ],
        'org:FormalOrganization' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
        ],
        'org:OrganizationalUnit' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
            [$NS->org->hasUnit,                           'Has Unit'],
        ],
        'foaf:Person' => [
            [$NS->org->hasMember,                       'Has Member'],
        ],
    },
    'org:OrganizationalUnit' => {
        'org:Organization' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
            [$NS->org->unitOf,                             'Unit Of'],
        ],
        'org:FormalOrganization' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
            [$NS->org->unitOf,                             'Unit Of'],
        ],
        'org:OrganizationalUnit' => [
            [$NS->org->hasSubOrganization,    'Has Sub-Organization'],
            [$NS->org->isSubOrganizationOf, 'Is Sub-Organization Of'],
            [$NS->org->linkedTo,                         'Linked To'],
            [$NS->org->hasUnit,                           'Has Unit'],
            [$NS->org->unitOf,                             'Unit Of'],
        ],
        'foaf:Person' => [
            [$NS->org->hasMember,                       'Has Member'],
        ],
    },
);


# rewrite this sucka
%MAP = map {
    my $x = $_;
    my $y = _expand($x);
    $y->uri_value => {
        map { _expand($_)->uri_value => $MAP{$x}{$_} } keys %{$MAP{$x}}
    }
} keys %MAP;

# if we see these predicates, we prefer the other one.
my %PREFER = map {
    $NS->ibis->uri($_->[0])->value => $NS->ibis->uri($_->[1]) } (
        [qw(specializes generalizes)],
        [qw(replaced-by replaces)],
        [qw(questioned-by questions)],
        [qw(suggested-by suggests)],
        [qw(response responds-to)],
        [qw(supported-by supports)],
        [qw(opposed-by opposes)],
    );

# explicitly set the sequence
my @SEQ = map { $NS->ibis->uri($_) }
    qw(supports opposes responds-to response supported-by opposed-by
       suggests suggested-by questions questioned-by generalizes specializes
       replaces replaced-by concerns concern-of);

# do {
#     my %seq;
#     my @each = map {
#         $NS->ibis->uri($_)->value } qw(Issue Position Argument);
#     my $i = 1;
#     for my $k1 (@each) {
#         for my $k2 (@each) {
#             for my $v (@{$MAP{$k1}{$k2}}) {
#                 $seq{$v->[0]->value} ||= $i++;
#             }
#         }
#     }
#     @SEQ = sort { $seq{$a} <=> $seq{$b} } keys %seq;
# };

our $UUID_RE  = qr/([0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){4}[0-9A-Fa-f]{8})/;
our $UUID_URN = qr/^urn:uuid:([0-9a-f]{8}(?:-[0-9a-f]{4}){4}[0-9a-f]{8})$/i;

has UUID_RE => (
    is      => 'ro',
    default => sub { $UUID_RE },
);

has UUID_URN => (
    is      => 'ro',
    default => sub { $UUID_URN },
);


# this is our equivalent of class data

=head2 ns

=cut

# dat *foo{THING}
unless (*RDF::Trine::NamespaceMap::list_prefixes{CODE}) {
    *RDF::Trine::NamespaceMap::list_prefixes = sub {
        keys %{$_[0]};
    };
}

has ns => (
    is      => 'ro',
    isa     => 'RDF::Trine::NamespaceMap',
    lazy    => 1,
    default => sub { $NS },
);

sub _ns {
    my $self = shift;
    my %out;
    # not sure why we need this
    my $ns = $self->ns;
    for my $prefix ($ns->list_prefixes) {
        $out{$prefix} = $ns->namespace_uri($prefix)->uri->uri_value;
    }
    \%out;
}

sub uns {
    my $self = shift;
    my $out = $self->_ns;
    #warn Data::Dumper::Dumper($out);
    URI::NamespaceMap->new($out);
}

sub xmlns {
    my $self = shift;
    my $out = $self->_ns;
    #warn $out;
    return { map { ("xmlns:$_" => $out->{$_}) } sort keys %$out };
}



has re => (
    is      => 'ro',
    isa     => 'RegexpRef',
    default => sub { $IBIS_RE },
);

=head2 labels

=cut

has labels => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { \%LABELS },
);

=head2 lprops

=cut

sub lprops {
    my (undef, $type, $alt) = @_;
    my $pair = $LPROPS{$type->uri_value} || [\@DEFAULT_LABELS, \@ALT_LABELS];
    my @out = @{$pair->[$alt ? 1 : 0]};
    wantarray ? @out : \@out;
}

=head2 inverse

=cut

has inverse => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { \%INVERSE },
);

=head2 predicate_map

=cut

has predicate_map => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { \%MAP },
);

sub predicate_seq {
    @SEQ;
}

=head2 types

=cut

sub types {
    map { $NS->ibis->uri($_) } qw(Issue Position Argument);
}

=head2 links

=cut

has links => (
    is       => 'ro',
    isa      => 'ArrayRef[HashRef]',
    lazy     => 1,
    default  => sub { [] },
);

=head2 metas

=cut

has metas => (
    is       => 'ro',
    isa      => 'ArrayRef[HashRef]',
    lazy     => 1,
    default  => sub { [] },
);

=head2 base

=cut

# has base => (
#     is  => 'rw',
#     isa => 'URI',
# );


=head1 METHODS

=cut

=head2 uuid4

=cut

sub uuid4 () {
    lc Data::GUID::Any::v4_guid_as_string();
}

=head2 uuid4urn

=cut

sub uuid4urn () {
    URI->new('urn:uuid:' . uuid4);
}

=head1 AUTHOR

dorian,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#__PACKAGE__->meta->make_immutable;

1;
