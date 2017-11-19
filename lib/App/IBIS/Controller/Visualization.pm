package App::IBIS::Controller::Visualization;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

App::IBIS::Controller::Visualization - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut


sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $subject = $c->req->uri->query_param('subject');

    my $viz = App::IBIS::Dotlike->new(
        model => $c->model('RDF'),
        ns => $self->ns,
        synonyms => {
        },
        inverses => {
        },
        primary => {
            'ibis:Issue' => {
                secondary  => 'ibis:Position',
                tertiary   => 'skos:Concept',
                properties => [qw(ibis:generalizes
                                ibis:suggests ibis:questioned-by)],
            },
            'ibis:Position' => {
                secondary  => 'ibis:Issue',
                tertiary   => 'skos:Concept',
                properties => 'ibis:generalizes',
                down       => 1,
            },
            'skos:Concept' => {
                secondary  => 'ibis:Issue',
                tertiary   => 'ibis:Position',
                properties => [qw(skos:narrower
                                skos:narrowerTransitive skos:related)],
                span       => 0,
            }
        },
    );


    my $doc = $viz->plot(
        subject => $subject,
    );

    $c->res->content_type('image/svg+xml');
    $c->res->body($doc->toString(1));
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
