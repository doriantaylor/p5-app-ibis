package App::IBIS::Base::Controller;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

=head1 METHODS

=cut

=head1 AUTHOR

dorian,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
