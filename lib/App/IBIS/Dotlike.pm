package App::IBIS::Dotlike;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use App::IBIS::Types     qw(Model RDFNSMap URIObject SynMap InvMap);
use MooseX::Types::Moose qw(Str);

use MooseX::Params::Validate ();

use RDF::Trine;

with 'Role::Markup::XML';

=head1 NAME

App::IBIS::Dotlike - (Graphviz) dot-like visualization in SVG

=head1 SYNOPSIS

  my $dot = App::IBIS::Dotlike->new(%LOTS_OF_PARAMS);

  my $svg = $dot->plot(%MORE_PARAMS);

=head1 METHODS

=head2 new

=over 4

=item model

The RDF model where the data is stored.

=cut

has model => (
    is       => 'ro',
    isa      => Model,
    required => 1,
);

=item title

The default (fallback) title of the SVG image.

=cut

has title => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => 'Dot-like (as in Graphviz) Plot',
);

=item ns

A L<RDF::Trine::NamespaceMap> containing all the relevant namespaces.

=cut

has ns => (
    is      => 'ro',
    isa     => RDFNSMap,
    lazy    => 1,
    default => sub {
        RDF::Trine::NamespaceMap->new({
            rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        })
      },
);

=item base

The base URI.

=cut

has base => (
    is     => 'ro',
    isa    => URIObject,
    lazy   => 0,
    coerce => 1,
);

=item css

The URI of a CSS stylesheet.

=cut

has css => (
    is     => 'ro',
    isa    => URIObject,
    lazy   => 0,
    coerce => 1,
);

=item synonyms

This is a map of classes and properties that effectively behave as
synonyms for the key. They are typically related by:
C<rdfs:subClassOf>, C<rdfs:subPropertyOf>, C<owl:sameAs>,
C<owl:equivalentClass>, C<owl:equivalentProperty>, or a chain
thereof. This map (in lieu of a proper RDFS/OWL reasoner) is supposed
to be the result of taking that structure and flattening it.

There should be a key for each class and/or property explicitly
mentioned in the constructor spec. Values can either be a single URI
or an C<ARRAY> reference containing several. Values can be URIs,
strings, or CURIEs, and will be expanded if necessary and coerced to
L<RDF::Trine::Node::Resource> objects.

=cut

has synonyms => (
    is      => 'ro',
    isa     => SynMap,
    coerce  => 1,
    default => sub { {} },
);

=item inverses

This is a map between forward and inverse properties. Once again, in
lieu of a reasoner, these represent mappings via C<owl:inverseOf>, and
instances of C<owl:SymmetricProperty>. Values should be a single URI
and will be coerced similarly to L</synonyms>.

If the properties in either the keys or their inverses have synonyms,
the properties represented here should be the I<keys> of the
L</synonyms> map.

=cut

has inverses => (
    is      => 'ro',
    isa     => InvMap,
    coerce  => 1,
    default => sub { {} },
);

=item primary

The C<rdf:type>(s) of the subject is (are) matched against the keys of
this structure, and the corresponding C<HASH> reference in the value
informs the engine how to render it:

  primary => {
    'ibis:Issue' => {
      secondary  => 'ibis:Position',
      tertiary   => 'skos:Concept',
      properties => [qw(ibis:generalizes ibis:suggests ibis:questioned-by)],
    },
    'ibis:Position' => {
      secondary  => [qw(ibis:Issue ibis:Argument)], # can be multiple
      tertiary   => 'skos:Concept',
      properties => 'ibis:generalizes',
      down       => 1,
    },
    'skos:Concept' => {
      secondary  => 'ibis:Issue',
      tertiary   => 'ibis:Position',
      properties => [qw(skos:narrower skos:narrowerTransitive skos:related)],
      span       => 0,
    },
  },

=over 4

=item secondary

The C<rdf:type>(s) of the nodes that will occupy the I<secondary>
position, which in landscape orientation is on I<top>, and in portrait
on the I<left> (in LTR writing systems). Again, this should correspond
to a key in L</synonyms>, if applicable.

=item tertiary

The C<rdf:type>(s) of the nodes that will occupy the I<tertiary>
position, which is on the I<bottom> in landscape and I<right> in
portrait (again, in left-to-right writing systems).

=item properties

This is an L<ARRAY> reference of properties, again these should be
keys of L</synonyms> if applicable. Since RDF graphs are directed,
these properties will be considered to lead I<out>, or I<down> from
the subject.

=item up

This is an integer representing the number of levels of properties to
show ascending from the subject. Undefined or negative values are
interpreted as being unbounded.

=item down

The is the same thing, but for levels I<descending> from the subject.

=item span

This is a flag which tells the visualization to show only the nodes
connected (directly and indirectly) to the subject. This is the
default. Set to a false value to change this behaviour.

=back

=cut

has primary => (
    is      => 'ro',
    isa     => HashRef[HashRef],
);

sub BUILD {
    my $self = shift;
    # dereference 
}

=back

=head2 plot

=over 4

=item subject

This is the active subject which governs the visualization.

=back

=cut

sub plot {
    my ($self, %p) = MooseX::Params::Validate::validated_hash(
    );

    $doc;
}

__PACKAGE__->meta->make_immutable;

1;
