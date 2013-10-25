package App::IBIS;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
/;

extends 'Catalyst';

our $VERSION = '0.01';

my %XMLNS = (
    rdf   => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    ibis  => 'http://privatealpha.com/ontology/ibis/1#',
    dct   => 'http://purl.org/dc/terms/',
    xsd   => 'http://www.w3.org/2001/XMLSchema#',
    xlink => 'http://www.w3.org/1999/xlink',
);

my $NS = RDF::Trine::NamespaceMap->new(\%XMLNS);

my $IBIS_RE = do { my $x = $NS->ibis->uri->value; qr/^$x/; };

my %LABELS = map {
    my $x = $NS->ibis->uri($_->[0]); $x->value => [$x, $_->[1]] } (
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
);

my %INVERSE = map { $NS->ibis->uri($_->[0])->value
                        => $LABELS{$NS->ibis->uri($_->[1])->value} } (
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
        ],
        argument => [
            [$NS->ibis->uri('supported-by'),   'Supported by'],
            [$NS->ibis->uri('opposed-by'),       'Opposed by'],
        ],
    },
    argument => {
        issue => [
            [$NS->ibis->suggests,                  'Suggests'],
            [$NS->ibis->uri('questioned-by'), 'Questioned by'],
        ],
        position => [
            [$NS->ibis->supports,                  'Supports'],
            [$NS->ibis->opposes,                    'Opposes'],
        ],
        argument => [
        ],
    },
);

# rewrite this sucka
%MAP = map {
    my $x = $_;
    $NS->ibis->uri(ucfirst $_)->uri_value => {
        map {
            $NS->ibis->uri(ucfirst $_)->uri_value => $MAP{$x}{$_}
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


# Configure the application.
#
# Note that settings in app_ibis.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'App::IBIS',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 0, # Send X-Catalyst header
);

# Start the application
__PACKAGE__->setup;


=head1 NAME

App::IBIS - Catalyst based application

=head1 SYNOPSIS

    script/app_ibis_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<App::IBIS::Controller::Root>, L<Catalyst>

=head1 AUTHOR

dorian,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
