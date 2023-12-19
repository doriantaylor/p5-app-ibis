package App::IBIS::Model::Cache;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

=head1 NAME

App::IBIS::Model::Cache - Super weaksauce cache

=head1 DESCRIPTION

Super weak memory cache

=head2

=cut

has _data => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { { } },
);

sub key {
    my ($self, $key, $second) = @_;
    my $out = $self->_data->{$key} ||= {};
    # $out = $out->{$second} ||= {} if defined $second;
    # $out;
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
