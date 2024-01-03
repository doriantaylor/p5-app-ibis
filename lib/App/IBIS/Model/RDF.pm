package App::IBIS::Model::RDF;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use Moose::Util::TypeConstraints;

use RDF::Trine;
use Time::HiRes ();
use DateTime;
use IPC::Shareable;

use URI;

extends 'Catalyst::Model::RDF';

class_type URIRef => { class => 'URI' };

my $NODE = class_type Node => { class => 'RDF::Trine::Node' };
coerce Node => from Str => via { RDF::Trine::iri(shift) };
coerce Node => from URIRef => via { RDF::Trine::iri(shift->as_string) };

# after BUILD => sub {
#     my $self = shift;
#     warn Data::Dumper::Dumper($self->config);
#     warn Data::Dumper::Dumper($self);
# };

# has _log => (
#     is => 'rw',
# );
#
# sub ACCEPT_CONTEXT {
#     my ($self, $c, @args) = @_;
#     if (ref $c) {
#         $self->_log($c->log);
#         return $c;
#     }
# }

has graph => (
    is      => 'ro',
    isa     => 'Node',
    coerce  => 1,
    default => sub { RDF::Trine::Node::Nil->new },
);

has _mtimes => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { IPC::Shareable->new(
        key => __PACKAGE__, mode => 0600, create => 1, destroy => 1) },
);

sub mtime {
    my ($self, $graph, $reset) = @_;
    $graph = $NODE->assert_coerce($graph);

    my $m = $self->_mtimes;
    my $g = $graph->uri_value;
    my $e = $m->{$g};
    my $t = (!$e || $reset) ? $m->{$g} = Time::HiRes::time() : $e;

    # warn Data::Dumper::Dumper($m);

    DateTime->from_epoch(epoch => $t);
}

has _cache => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

sub cache {
    my ($self, $graph, $reset) = @_;

    # coerce graph identifier
    $graph = $NODE->assert_coerce($graph);

    # global modification time
    my $gtime = $self->mtime($graph, $reset);

    # try to retrieve cache for graph
    my $pair = $self->_cache->{$graph->uri_value};
    return $pair->[1] if $pair and !$reset and $pair->[0] >= $gtime->epoch;

    # otherwise initialize and populate it
    $pair = $self->_cache->{$graph->uri_value} = [
        $gtime->epoch, RDF::Trine::Model->new(
            RDF::Trine::Store::Hexastore->new)];

    $pair->[1]->add_iterator(
        $self->get_statements(undef, undef, undef, $graph));

    $pair->[1];
}

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
