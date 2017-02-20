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
    StackTrace
/;
#     +CatalystX::Profile
# /;

extends 'Catalyst';

use Convert::Color   ();
use HTTP::Negotiate  ();
use Unicode::Collate ();

our $VERSION = '0.04';

my (@LABELS, @ALT_LAB);

# XXX maybe rig this up so we can configure it via the config file?
has collator => (
    is      => 'ro',
    isa     => 'Unicode::Collate',
    default => sub { Unicode::Collate->new },
);

after setup_finalize => sub {
    my $app = shift;

    # TODO prepare palette 
    my $p = $app->config->{palette};
    for my $t (sort keys %{$p->{class}}) {
        if ($t =~ /:/) {
            chomp (my $hex = $p->{class}{$t});

            # correct shorthand hex values and coerce to Convert::Color
            $hex =~ /^#?([0-9A-Fa-f]{3})|([0-9A-Fa-f]{6})$/;
            if ($1 ne '') {
                $hex = 'rgb8:' . join '', map { ($_) x 2 } split //, $1;
            }
             elsif ($2 ne '') {
                $hex = "rgb8:$2";
            }
            else {
                # XXX not sure what to do here
                next;
            }

            my $co = Convert::Color->new($hex);

            $app->log->debug(sprintf "%s\tH:%03.2f\tS:%03.2f\tL:%03.2f",
                             $t, $co->convert_to('husl')->hsl);
        }
    }

    # populate labels

    my $m  = $app->model('RDF');
    my $ns = $m->ns;

    $app->log->debug('Contexts: ', $m->get_contexts);

    @LABELS  = grep { defined $_ } map { $ns->uri($_) }
        qw(skos:prefLabel rdfs:label foaf:name dct:title
         dc:title dct:identifier dc:identifier rdf:value);
    @ALT_LAB = grep { defined $_ } map { $ns->uri($_) }
        qw(skos:altLabel bibo:shortTitle dct:alternative);

};

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

=head1 METHODS

=head2 label_for $SUBJECT

Ghetto-rig a definitive label

=cut

sub label_for {
    my ($c, $s, $alt) = @_;
    return unless $s->is_resource or $s->is_blank;

    my $m  = $c->model('RDF');
    my $g  = $m->graph;
    my $ns = $m->ns;

    # get the sequence of candidates
    my @candidates = $alt ? (@ALT_LAB, @LABELS) : (@LABELS, @ALT_LAB);

    # pull them all out
    my %out;
    for my $p (@candidates) {
        my @coll = grep { $_->is_literal and $_->literal_value !~ /^\s*$/ }
            $m->objects($s, $p);

        $out{$p->uri_value} = \@coll if @coll;
    }

    # now do content negotiation to them
    my (@variants, $qs);
    for my $i (1..@candidates) {
        my $p = $candidates[$i-1];
        $qs = 1/$i;
        for my $o (@{$out{$p->uri_value}}) {
            my $lang = $o->literal_value_language;
            my $size = length $o->literal_value;
            $size = 1/$size unless $alt; # choose the longest one
            push @variants, [[$o, $p], $qs, undef, undef, undef, $lang, $size];
        }
    }

    if (my @out = HTTP::Negotiate::choose(\@variants, $c->req->headers)) {
        my ($o, $p) = @{$out[0][0]};

        return wantarray ? ($o, $p) : $o;
    }
    else {
        return $s;
    }
}

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
