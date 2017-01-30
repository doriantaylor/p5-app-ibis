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
    ibis  => 'http://privatealpha.com/ontology/ibis/1#',
    skos  => 'http://www.w3.org/2004/02/skos/core#',
    dct   => 'http://purl.org/dc/terms/',
    xsd   => 'http://www.w3.org/2001/XMLSchema#',
    xlink => 'http://www.w3.org/1999/xlink',
);

my $NS = RDF::Trine::NamespaceMap->new(\%XMLNS);

my $IBIS_RE = do { my $x = $NS->ibis->uri->value; qr/^$x/; };

my %LABELS = map {
    my $x = $_->[0];
    $x = $x =~ /:/ ? $NS->uri($x) : $NS->ibis->uri($x);
    $x->uri_value => [$x, $_->[1]] } (
        # IBIS
        ['endorses',      'Endorses'],
        ['endorsed-by',   'Endorsed by'],
        ['generalizes',   'Generalizes'],
        ['specializes',   'Specializes'],
        ['replaces',      'Replaces'],
        ['replaced-by',   'Replaced by'],
        ['questions',     'Questions'],
        ['questioned-by', 'Questioned by'],
        ['suggests',      'Suggests'],
        ['suggested-by',  'Suggested by'],
        ['response',      'Has Response'],
        ['responds-to',   'Responds to'],
        ['supports',      'Supports'],
        ['supported-by',  'Supported by'],
        ['opposes',       'Opposes'],
        ['opposed-by',    'Opposed by'],
        # SKOS
        ['skos:related',            'Related To'],
        ['skos:narrower',           'Has Narrower'],
        ['skos:broader',            'Has Broader'],
        ['skos:narrowerTransitive', 'Has Narrower (Transitive)'],
        ['skos:broaderTransitive',  'Has Broader (Transitive)'],
        ['skos:narrowMatch',        'Has Narrower Match'],
        ['skos:broadMatch',         'Has Broader Match'],
        ['skos:closeMatch',         'Has Close Match'],
        ['skos:exactMatch',         'Has Exact Match'],
);

my %INVERSE = map {
    my ($x, $y) = @$_;
    $x = $x =~ /:/ ? $NS->uri($x) : $NS->ibis->uri($x);
    $y = $y =~ /:/ ? $NS->uri($y) : $NS->ibis->uri($y);
    $x->uri_value => $LABELS{$y->uri_value} } (
        [qw(endorses endorsed-by)],
        [qw(generalizes specializes)],
        [qw(specializes generalizes)],
        [qw(replaces replaced-by)],
        [qw(replaced-by replaces)],
        [qw(questions questioned-by)],
        [qw(questioned-by questions)],
        [qw(suggests suggested-by)],
        [qw(suggested-by suggests)],
#        [qw(questions suggests)],
#        [qw(suggests questions)],
        [qw(response responds-to)],
        [qw(responds-to response)],
        [qw(supports supported-by)],
        [qw(supported-by supports)],
        [qw(opposes opposed-by)],
        [qw(opposed-by opposes)],
        # SKOS
        [qw(skos:related skos:related)],
        [qw(skos:narrower skos:broader)],
        [qw(skos:broader skos:narrower)],
        [qw(skos:narrowerTransitive skos:broaderTransitive)],
        [qw(skos:broaderTransitive skos:narrowerTransitive)],
        [qw(skos:narrowMatch skos:broadMatch)],
        [qw(skos:broadMatch skos:narrowMatch)],
        [qw(skos:closeMatch skos:closeMatch)],
        [qw(skos:exactMatch skos:exactMatch)],
);

my %MAP = (
    issue => {
        issue => [
            [$NS->ibis->generalizes,            'Generalizes'],
            [$NS->ibis->specializes,            'Specializes'],
            [$NS->ibis->replaces,                  'Replaces'],
            [$NS->ibis->uri('replaced-by'),     'Replaced by'],
            [$NS->ibis->suggests,                  'Suggests'],
            [$NS->ibis->uri('suggested-by'),   'Suggested by'],
            [$NS->ibis->questions,                'Questions'],
            [$NS->ibis->uri('questioned-by'), 'Questioned by'],
        ],
        position => [
            [$NS->ibis->questions,                'Questions'],
            [$NS->ibis->uri('suggested-by'),   'Suggested by'],
            [$NS->ibis->response,                  'Response'],
        ],
        argument => [
            [$NS->ibis->generalizes,            'Generalizes'],
            [$NS->ibis->specializes,            'Specializes'],
            [$NS->ibis->questions,                'Questions'],
            [$NS->ibis->uri('suggested-by'),   'Suggested by'],
        ],
    },
    position => {
        issue => [
            [$NS->ibis->suggests,                  'Suggests'],
            [$NS->ibis->uri('questioned-by'), 'Questioned by'],
            [$NS->ibis->uri('responds-to'),     'Responds to'],
        ],
        position => [
            [$NS->ibis->generalizes,            'Generalizes'],
            [$NS->ibis->specializes,            'Specializes'],
        ],
        argument => [
            [$NS->ibis->uri('supported-by'),   'Supported by'],
            [$NS->ibis->uri('opposed-by'),       'Opposed by'],
        ],
    },
    argument => {
        issue => [
            [$NS->ibis->generalizes,            'Generalizes'],
            [$NS->ibis->specializes,            'Specializes'],
            [$NS->ibis->suggests,                  'Suggests'],
            [$NS->ibis->uri('questioned-by'), 'Questioned by'],
        ],
        position => [
            [$NS->ibis->supports,                  'Supports'],
            [$NS->ibis->opposes,                    'Opposes'],
        ],
        argument => [
            [$NS->ibis->generalizes,            'Generalizes'],
            [$NS->ibis->specializes,            'Specializes'],
        ],
    },
    'skos:Concept' => {
        'skos:Concept' => [
            [$NS->skos->related,            'Is Related'],
            [$NS->skos->narrower,           'Has Narrower'],
            [$NS->skos->broader,            'Has Broader'],
            [$NS->skos->narrowerTransitive, 'Has Narrower (Transitive)'],
            [$NS->skos->broaderTransitive,  'Has Broader (Transitive)'],
            [$NS->skos->narrowMatch,        'Has Narrower Match'],
            [$NS->skos->broadMatch,         'Has Broader Match'],
            [$NS->skos->closeMatch,         'Has Close Match'],
            [$NS->skos->exactMatch,         'Has Exact Match'],
        ],
    },
);

# rewrite this sucka
%MAP = map {
    my $x = $_;
    my $y = $x =~ /:/ ? $NS->uri($x) : $NS->ibis->uri(ucfirst $x);
    $y->uri_value => {
        map {
            my $z = $_ =~ /:/ ? $NS->uri($_) : $NS->ibis->uri(ucfirst $_);
            $z->uri_value => $MAP{$x}{$_}
        } keys %{$MAP{$x}}
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

my @SEQ;

    {
        my %seq;
        my @each = map {
            $NS->ibis->uri($_)->value } qw(Issue Position Argument);
        my $i = 1;
        for my $k1 (@each) {
            for my $k2 (@each) {
                for my $v (@{$MAP{$k1}{$k2}}) {
                    $seq{$v->[0]->value} ||= $i++;
                }
            }
        }
        @SEQ = sort { $seq{$a} <=> $seq{$b} } keys %seq;
    }


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
    return { map { ("xmlns:$_" => $out->{$_}) } keys %$out };
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
