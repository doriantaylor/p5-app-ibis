package App::IBIS::Model::RDF;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use Moose::Util::TypeConstraints;

use RDF::Trine;

extends 'Catalyst::Model::RDF';

class_type Resource => { class => 'RDF::Trine::Node::Resource' };
coerce Resource => from Str => via { RDF::Trine::Node::Resource->new(shift) };

# after BUILD => sub {
#     my $self = shift;
#     warn Data::Dumper::Dumper($self->config);
#     warn Data::Dumper::Dumper($self);
# };

has graph => (
    is      => 'ro',
    isa     => 'Resource',
    coerce  => 1,
    default => sub { RDF::Trine::Node::Nil->new },
);

=head1 NAME

App::IBIS::Model::RDF - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

dorian,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
