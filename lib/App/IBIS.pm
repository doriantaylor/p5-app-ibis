package App::IBIS;

use 5.012;
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

# XXX NOTE THAT THIS STRUCTURE IS ****EXTREMELY**** SENSITIVE TO
# THE SEQUENCE IT SHOWS UP IN THE CODE. DO NOT FUCK AROUND WITH IT.
BEGIN {
    # this should always go first otherwise it loads up blank
    my @INIT_ARGS = qw/ConfigLoader SubRequest/;

    # and now the debug modules
    if ($ENV{CATALYST_DEBUG}) {
        # not sure why it doesn't flip these on by default anyway
        push @INIT_ARGS, qw/-Debug StackTrace/;
        push @INIT_ARGS, '+CatalystX::Profile' if int($ENV{CATALYST_DEBUG}) > 1;
    }

    # use this for other init modules
    # push @INIT_ARGS, $whatever;

    # NOTE `perldoc -f use`: this is what `use` is shorthand for
    require Catalyst;
    Catalyst->import(@INIT_ARGS);
}

use CatalystX::RoleApplicator;

# use Catalyst qw/ConfigLoader -Debug StackTrace/;

use Convert::Color   ();
use HTTP::Negotiate  ();
use Unicode::Collate ();
use RDF::Trine qw(iri blank literal statement);
use RDF::Trine::Namespace qw(RDF);

our $VERSION = '0.13';

extends 'Catalyst';

# XXX this thing is dumb; no need to be a role, it's just data
with 'App::IBIS::Role::Schema';
with 'Role::Markup::XML';

__PACKAGE__->apply_request_class_roles(qw/
    Catalyst::TraitFor::Request::ProxyBase
/);

my (@LABELS, @ALT_LAB);

# XXX maybe rig this up so we can configure it via the config file?
has collator => (
    is      => 'ro',
    isa     => 'Unicode::Collate',
    default => sub { Unicode::Collate->new(level => 3, identical => 1) },
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

    $app->log->debug('Statements: ' . $m->size);
    $app->log->debug('Contexts: '   . join ', ', $m->get_contexts);

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

=head2 neighbour_structs $SUBJECT

=cut

sub graph_cache_bp {
    my $c = shift;

    my $m = $c->rdf_cache;
    my @c = $m->get_contexts;
    my $g = $c->graph if @c;

    return ($m, $g);
}

sub neighbour_structs {
    my ($c, $subject, %p) = @_;
    my (%in, %res, %lit, $iter);

    my $skip_types = exists $p{types} && !$p{types};

    my ($m, $g) = $c->graph_cache_bp;
    my $ns = $c->ns;

    my $inverse = $c->inverse;

    # $c->log->debug('wtf contexts are ' . join(' ', $c->model('RDF')->get_contexts));

    # this flips around inverse relations

    my @terms = (undef, undef, $subject);
    push @terms, $g if $g;

    $iter = $m->get_statements(@terms);
    while (my $stmt = $iter->next) {
        my $p = $stmt->predicate->value;
        my $s = $stmt->subject;
        if (my $inv = $inverse->{$p}) {
            $p = $inv->[0]->value;
            # resources
            $res{$p} ||= {};
            $res{$p}{$s->value} ||= $s;
            #push @{$res{$p}}, $s;
        }
        else {
            # inverses
            $in{$p} ||= {};
            $in{$p}{$s->value} ||= $s;
            #push @{$in{$p}}, $s;
        }
    }

    # this gathers forward relations

    @terms = ($subject, undef, undef);
    push @terms, $g if $g;

    # $c->log->debug(Data::Dumper::Dumper(\@terms));

    $iter = $m->get_statements(@terms);
    while (my $stmt = $iter->next) {
        my $p = $stmt->predicate;

        # don't pollute the content with the type
        next if $skip_types and $p->equal($ns->rdf->type);

        # okay carry on
        $p = $p->value;
        my $o = $stmt->object;
        # $c->log->debug("wtf $subject $p $o");
        if ($o->is_literal) {
            $lit{$p} ||= {};
            $lit{$p}{$o->sse} = $o;
        }
        else {
            $res{$p} ||= {};
            $res{$p}{$o->value} ||= $o;
        }
    }

    my @out = (\%res, \%lit, \%in);

    wantarray ? @out : \@out;
}

=head2 types_for $SUBJECT [, %PARAMS]

=cut

sub types_for {
    my ($c, $s, %p) = @_;
    return unless $s->is_resource or $s->is_blank;

    my $tcache = $p{types} ||= {};

    my ($m, $g) = $c->graph_cache_bp;
    my $ns = $c->ns;

    my @terms = ($s, $ns->rdf->type);
    push @terms, $g if $g;

    my @types = @{
        $tcache->{$s->uri_value} ||=
            [sort { $a->uri_value cmp $b->uri_value }
             $m->objects(@terms, type => 'resource')]};

    wantarray ? @types : \@types;
}

=head2 label_for $SUBJECT

Ghetto-rig a definitive label

=cut

sub label_for {
    my ($c, $s, $alt, @rest) = @_;
    return unless $s->is_resource or $s->is_blank;

    my %p;

    if (@rest == 1 and ref $rest[0] eq 'HASH') {
        %p = %{$rest[0]};
        $alt = $p{alt} ||= $alt;
    }
    elsif (@rest % 2) {
        %p = ($alt, @rest);
        $alt = $p{alt};
    }
    elsif (ref $alt eq 'HASH') {
        %p = %$alt;
        $alt = $p{alt};
    }
    else {
        %p = @rest;
        $p{alt} ||= $alt;
    }

    my $tcache = $p{types}  ||= {};
    my $lcache = $p{labels} ||= {};

    # if this is cached we can just return
    if ($lcache->{$s->uri_value}) {
        my ($o, $p) = @{$lcache->{$s->uri_value}};
        return wantarray ? ($o, $p) : $o;
    }

    my ($m, $g) = $c->graph_cache_bp;
    my $ns = $c->ns;

    my @types = $c->types_for($s, types => $tcache);

    my (@candidates, %out);

    for my $type (@types) {
        my @preds = $c->lprops($type, $alt);

        for my $p (@preds) {
            next if $out{$p->uri_value};
            my @terms = ($s, $p);
            push @terms, $g if $g;
            my @coll = grep { $_->literal_value !~ /^\s*$/ }
                $m->objects(@terms, type => 'literal');

            if (@coll) {
                push @candidates, $p;
                $out{$p->uri_value} = \@coll;
            }
        }
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

        $lcache->{$s->uri_value} = [$o, $p];

        return wantarray ? ($o, $p) : $o;
    }
    else {
        $lcache->{$s->uri_value} = [$s, undef];

        return $s;
    }
}

=head2 uri_for

=cut

# sub uri_for {
#     my ($c, $uri, @rest) = @_;

#     if (defined $uri and ref $uri and Scalar::Util::blessed($uri)) {
#         # coerce
#         $uri = URI->new($uri->uri_value) if
#             $uri->isa('RDF::Trine::Node::Resource');

#         # bail out if it's something else
#         Carp::croak("not sure what to do with uri $uri")
#               unless $uri->isa('URI');

#         # reduce to uuid if this is a uuid
#         $uri = $uri->uuid if
#             (lc($uri->scheme // '') eq 'urn' and $uri->opaque =~ /^uuid:/i);
#     }

#     $c->SUPER::uri_for($uri, @rest);
# }

=head2 rdf_cache [ $RESET ]

Retrieve an in-memory cache of everything in C<< $c->graph >>,
optionally resetting it.

=cut

sub rdf_cache {
    my ($c, $reset) = @_;

    my $g = $c->graph;

    my $cache = $c->model('Cache')->key('graph');
    my $model = $cache->{$g->value};

    if ($model) {
        return $model unless $reset;
        # make sure we empty this thing before overwriting it in case
        # there are cyclical references
        $model->_store->nuke;
    }

    $model = $cache->{$g->value} = RDF::Trine::Model->new
        (RDF::Trine::Store::Hexastore->new);

    # run this for side effects
    $c->global_mtime(1);

    $model->add_iterator(
        $c->model('RDF')->get_statements(undef, undef, undef, $g));

    $model;
}

=head2 global_mtime

this will of course be a per-process mtime of the rdf cache but better than nothing

=cut

sub global_mtime {
    my ($c, $reset) = @_;

    my $g = $c->graph;
    my $mtimes = $c->model('Cache')->key('mtime');

    my $now = DateTime->now;

    $reset ? $mtimes->{$g->value} = $now : $mtimes->{$g->value} ||= $now;
}

=head2 graph

Return the context graph of the instance. The graph defaults to
C<< $c->req->base >> unless it is overridden directly in the
configuration, or otherwise mapped to a different URI.

(We can come back and lock the context down to the user or something
later.)

=cut

sub graph {
    my $c = shift;

    return $c->stash->{context_graph} if $c->stash->{context_graph};

    my $g = $c->req->base;
    $c->log->debug("Using base $g as context");

    if (my $cfg = $c->config->{graph}) {
        my $x = 0;
        if (ref $cfg eq 'HASH') {
            $x = 1;
            $g = $cfg->{$g} || $g;
        }
        elsif (!ref $cfg and $cfg) {
            $x = 1;
            $g = $cfg;
        }

        $c->log->debug("Using context graph $g from config") if $x;
    }

    # i suppose this could theoretically (?)
    $c->stash->{context_graph} = RDF::Trine::iri("$g");
}

=head2 stub %PARAMS

Generate a stub document with all the trimmings.

=cut

sub stub {
    my ($c, %p) = @_;

    #my %ns = (%{$self->uns}, %{$p{ns} || {}});

    # optionally multiple css files
    my $css = $c->config->{css} ||
        ['/asset/font-awesome.css', '/asset/main.css'];
    $css = [$css] unless ref $css;
    my @css = map {
        { rel => 'stylesheet', type => 'text/css',
              href => $c->uri_for($_) }
    } @$css;

    my @link = (
        # @css,
        { rel => 'alternate', type => 'application/atom+xml',
          href => $c->uri_for('feed') },
        { rel => 'alternate', type => 'text/turtle',
          href => $c->uri_for('dump') },
        { rel => 'contents index top', href => $c->uri_for('/') },
        { rel => 'meta', href => $c->uri_for('/meta') },
        @{delete $p{link} || []},
    );

    if (my $me = $c->whoami) {
        # $c->log->debug("whoami: $me");
        push @link, { rel => 'pav:retrievedBy', href => $me->value };
    }
    # else {
    #     $c->log->debug("no whoami :(");
    # }

    # my $script = $c->config->{script} ||
    #     [qw(asset/jquery.js asset/rdf asset/d3 asset/rdf-viz
    #            asset/complex asset/hierarchical asset/main.js)];
    # $script = [$script] unless ref $script;

    my ($body, $doc) = $c->_XHTML(
        link  => \@link,
        # meta  => [@{delete $p{meta} || []}],
        # head  => [
        #     map +{ -name => 'script', type => 'text/javascript',
        #            src => $c->uri_for($_) }, @$script ],
        ns    => $c->uns,
        vocab => $c->uns->xhv->uri,
        transform => $c->config->{transform},
        %p,
    );

    wantarray ? ($body, $doc) : $doc;
}

=head2 render_simple $C, $SUBJECT

Renders a simple page representing the subject and its immediate neighbours.

=cut

sub render_simple {
    my ($c, $subject, %p) = @_;

    my ($m, $g) = $c->graph_cache_bp;

    my $ns = $c->ns;

    # these are the purely reverse relations we want to show up in the
    # main body rather than the head links
    my %revp = map { $_->value => $_ } @{$p{rev} || []};

    # resources and literals
    my (%types, %labels, %terms);
    my ($res, $lit, $in) = $c->neighbour_structs($subject, types => 0);

    my ($lv, $lp) = $c->label_for($subject);

    # collect all the adjacents and flip their predicates around
    for my $pair ([$res, 0], [$in, 1], [$lit, 0]) {
        my ($struct, $rev) = @$pair;
        # $c->log->debug(Data::Dumper::Dumper($struct));
        for my $p (keys %$struct) {
            $p = iri($p); # recast hash key as resource

            # $c->log->debug($struct->{$p->uri_value});

            for my $o (values %{$struct->{$p->uri_value}}) {
                if ($o->is_resource) {
                    my $lab = $c->label_for(
                        $o, types => \%types, labels => \%labels);
                    my $terms = $terms{$lab->value} ||= {};
                    my $y = $terms->{$o->sse} ||= [$o, [], []];
                    push @{$y->[$rev ? 2 : 1]}, $p;
                }
                elsif ($o->is_literal) {
                    my $terms = $terms{$o->literal_value} ||= {};
                    my $y = $terms->{$o->sse} ||= [$o, [], []];
                    push @{$y->[1]}, $p;
                }
            }
        }
    }

    # $c->log->debug(Data::Dumper::Dumper(\%types, \%labels, \%terms));

    # the job now is to pump out two lists in lexical order of label
    my (@p, @links);
    for my $x (map { [values %{$terms{$_}}] } sort { $a cmp $b } keys %terms) {
        # term plus forward and reverse relations
        for my $y (sort { RDF::Trine::Node::compare($a->[0], $b->[0]) } @$x) {
            my $term = $y->[0];
            my @fwd  = map { $ns->abbreviate($_) } @{$y->[1]};
            my @rev  = map { $ns->abbreviate($_) } @{$y->[2]};

            my %p = (-name => 'p');

            if ($term->is_literal) {
                $p{property} = \@fwd;
                $p{-content} = $term->literal_value;
                $p{datatype} = $ns->abbreviate($term->literal_datatype)
                    if $term->has_datatype;
                $p{'xml:lang'} = $term->literal_value_language
                    if $term->has_language;
                push @p, \%p;
            }
            else {
                my $uri = URI->new($term->uri_value);
                $uri = $uri->uuid if lc $uri->scheme eq 'urn';

                # label content
                my ($lv, $lp) = @{$labels{$term->uri_value} || [$term]};
                my $c = $lv->value;

                # types
                my @t = map {
                    $ns->abbreviate($_) } @{$types{$term->uri_value}};

                # the link itself
                my %a = (href => $uri);
                $a{rel}      = \@fwd if @fwd;
                $a{rev}      = \@rev if @rev;
                $a{typeof}   = \@t if @t;

                if (@fwd or grep { $revp{$_->value} } @{$y->[2]}) {
                    if ($lp and $lv->is_literal) {
                        my %c = (-content => $lv->literal_value,
                                 property => $ns->abbreviate($lp));
                        $c{datatype} = $ns->abbreviate($lv->literal_datatype)
                            if $lv->has_datatype;
                        $c{'xml:lang'} = $lv->literal_value_language
                            if $lv->has_language;
                        $c = \%c;
                    }

                    # set the content for both link and paragraph
                    $a{-content} = $c;
                    $p{-content} = \%a;

                    push @p, \%p;
                }
                else {
                    # a purely reverse <link> in the <head>
                    $a{-name} = 'link';    # rename the link
                    $a{rel}   = '';        # empty rel to be valid (booo)
                    $a{title} = $c if $lp; # only add if it's a literal

                    push @links, \%a;
                }
            }
        }
    }

    my $types = join ' ',
        map { $ns->abbreviate($_) } $c->types_for($subject, types => \%types);
    my $id = Data::UUID::NCName::to_ncname($subject->uri_value, version => 1);
    my %attrs = (id => $id, typeof => $types, %{$p{attrs} || {}});

    my @title = ($lv->value);
    push @title, $ns->abbreviate($lp) if $lp;

    $c->stub(
        ns      => $c->uns,
        uri     => $c->req->uri,
        attr    => \%attrs,
        link    => \@links,
        title   => \@title,
        content => \@p,
    );
}


=head2 whoami

Attempt to return the C<foaf:Agent> associated with C<REMOTE_USER> if
there is one, otherwise return C<REMOTE_USER> as an
L<RDF::Trine::Node::Resource>, or C<undef> if it is not present.

=cut

sub whoami {
    my $c = shift;
    my $m = $c->rdf_cache;
    my $n = $c->ns;
    my $u = $c->req->remote_user // $c->req->env->{REMOTE_USER} // '';

    # trim the username in case there's spaces etc
    $u =~ s/\A\s*(.*?)\s*\Z/$1/;

    if ($u eq '') {
        $c->log->debug("REMOTE_USER field empty");
    }
    else {
        return $c->stash->{resolved_user} if $c->stash->{resolved_user};

        # if there is no uri scheme then we add one
        unless ($u =~ /^[A-Za-z][0-9A-Za-z+.-]:/) {
            # this is either something email-like or is not
            $u = ($u =~ /@/) ? lc("mailto:$u") : "urn:x-user:$u";
        }

        $c->log->debug("user: $u");

        $u = RDF::Trine::iri($u);
        my %uniq = map { $_->sse => $_ }
            ($m->objects($u, $n->sioc->account_of, undef, type => 'resource'),
             $m->subjects($n->foaf->account, $u));

        # there should only be one of thse
        my @out = sort values %uniq;

        return $c->stash->{resolved_user} = @out ? $out[0] : $u;
    }

    return;
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
