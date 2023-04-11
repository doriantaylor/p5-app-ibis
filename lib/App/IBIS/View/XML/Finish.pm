package App::IBIS::View::XML::Finish;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use HTTP::Negotiate ();
use Scalar::Util ();
use XML::LibXML  ();
use XML::LibXSLT ();
use URI ();

use utf8;

# this is the crap part: every xml vocab has its own syntax for things
# that contain URIs.

use constant XMLNS   => 'http://www.w3.org/XML/1998/namespace';
use constant XHTMLNS => 'http://www.w3.org/1999/xhtml';
use constant XLINKNS => 'http://www.w3.org/1999/xlink';
use constant XSLTNS  => 'http://www.w3.org/1999/XSL/Transform';
use constant RDFNS   => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
use constant SVGNS   => 'http://www.w3.org/2000/svg';
use constant ATOMNS  => 'http://www.w3.org/2005/Atom';

our $VERSION = '0.13';

my %NS = (
    xml   => XMLNS,
    xsl   => XSLTNS,
    html  => XHTMLNS,
    svg   => SVGNS,
    xlink => XLINKNS,
    rdf   => RDFNS,
    atom  => ATOMNS
);

my %REV = reverse %NS;

my %CT = (
    &XHTMLNS => [qw(application/xhtml+xml)],
    &XSLTNS  => [qw(text/xsl application/xslt+xml)],
    &RDFNS   => [qw(application/rdf+xml)],
    &SVGNS   => [qw(image/svg+xml)],
);

my $XPC = XML::LibXML::XPathContext->new;
map { $XPC->registerNs($_ => $NS{$_}) } keys %NS;
# XXX it is dumb that there is no way to do this with standard xpath.
$XPC->registerFunction(
    'namespace-decls' => sub {
        my $in  = shift;
        my $out = XML::LibXML::NodeList->new;
        for my $node ($in->get_nodelist) {
            $out->push($node) if $node->getNamespaces;
        }
        $out;
});

# Elements which contain lone text nodes which are URIs or lists of URIs

my %ELEM = (
    &ATOMNS => [qw(id logo icon uri)],
);

use constant URIXPATH => join '|', '//*[@*][not(self::html:base)]',
    map { my $x = "//$REV{$_}:"; map { "$x:$_" } @{$ELEM{$_}} } keys %ELEM;

# use constant ROOTXPATH =>
#     '/*|/html:html/html:head/descendant-or-self::*[not(self::html:base)]';
use constant ROOTXPATH => '/*';


# attributes which contain URIs or lists/constructs containing URIs

my %ATTR = (
    # parent element namespace (empty string here means any namespace)
    '' => {
        # attribute namespace
        &XLINKNS => [qw(href role arcrole)],
        &RDFNS   => [qw(about resource datatype)],
    },
    &XHTMLNS => {
        # empty namespace for attributes means no explicit prefix
        '' => [qw(href src action data longdesc about resource prefix vocab)],
    },
    &ATOMNS => {
        '' => [qw(href rel src scheme uri)],
    },
);

sub _rewrite_uris {
    my ($self, $c, $elem, $bhref) = @_;

    my $uri  = $c->req->uri->canonical;
    my $host = $c->config->{host} || $uri->host;

    # get the base (which should have been rewritten by now)
    my ($base) = $XPC->findvalue(
        'ancestor-or-self::*[@xml:base][1]/@xml:base|' .
            '/html:html/html:head/html:base[@href][1]/@href', $elem);
    $base = $base ? URI->new($base) : $uri->clone;

    my $op = sub {
        my $data = shift;

        # trim end whitespace
        $data =~ s/^\s*(.*?)\s*$/$1/sm;

        # this is a safe CURIE and should not be touched
        return $data if $data =~ /^[[][^:]+:[^]]+[]]$/;
        # this is an XSLT macro and should not be touched
        return $data if $data =~ /[{].*?[}]/;
        # this is a bnode and should not be touched
        return $data if $data =~ /^_:/;

        # split on remaining whitespace
        my @in = split /\s+/, $data;

        # turn text into absolute URIs relative to original base
        my @out;
        for my $orig (map { URI->new($_) } @in) {
            my $href = $orig->abs($base)->canonical;

            my $is_abs = $orig->eq($href);

            # rewrite authority if host matches configured canonical
            # host but Host: header is different
            if ($uri->host ne $host
                    and $href->can('host') and $href->host eq $host) {
                $href->authority($uri->authority);
            }

            # turn absolute URIs back into relative ones where
            # applicable
            push @out, $is_abs ? $href : $href->rel($base);
        }

        # join everything back into a string
        join ' ', @out;
    };

    my $ns = $elem->namespaceURI || '';

    # rewrite text content if the content model is a URI
    if (grep { $elem->localName eq $_ } @{$ELEM{$ns} || []}) {
        # get flattened text content
        my $tc = $elem->textContent;
        # nuke all child nodes
        #map { $elem->removeChild($_) } $elem->childNodes;
        $elem->removeChildNodes;

        # append new single text node with the result of the operation
        my $new = $elem->ownerDocument->createTextNode($op->($tc));
        $elem->appendChild($new);
    }

    # now do the attributes
    for my $attr ($elem->attributes) {
        # this may be littered with namespace declarations
        next unless $attr->nodeType == 2;
        my $ans = $attr->namespaceURI || '';
        my @a = (@{$ATTR{''}{''}  || []}, @{$ATTR{''}{$ans}  || []},
                 @{$ATTR{$ns}{''} || []}, @{$ATTR{$ns}{$ans} || []});
        for my $a (@a) {
            next unless $attr->localName eq $a;
            $attr->setValue($op->($attr->value));
            last;
        }
    }
}

=head1 NAME

App::IBIS::View::XML::Finish - Does what it says on the tin.

=head1 DESCRIPTION

This is a Catalyst View to fix base and relative URIs in X(HT)ML
content, and other garden-variety annoyances.

=encoding utf8

=cut

sub process {
    my ($self, $c) = @_;

    my $res  = $c->res;
    my $type = $res->content_type;
    my $body = $res->body;
    my $uri  = $c->req->uri->canonical->clone;
    my $host = $c->config->{host} || $uri->host;

    if (defined $body) {
        $body  = \$body unless ref $body;

        if (Scalar::Util::blessed($body) and $body->isa('XML::LibXML::Node')) {
            # noop
            $c->log->debug('Request body is already parsed XML.');
        }
        else {
            $c->log->debug('Parsing XML body.');
            # set up the dispatcher
            my $rt   = Scalar::Util::reftype($body);
            my %keys = (GLOB => 'IO', SCALAR => 'string');
            my $key  = $keys{$rt};
            my $disp = $type =~ m!text/html! ?
                \&XML::LibXML::load_html : \&XML::LibXML::load_xml;

            # if this happens, it is a programmer error
            Carp::croak("No handler for a body of $rt reftype") unless $key;

            # now parse the body
            $body = eval { XML::LibXML->$disp(
                $key => $body, recover => 2, no_network => 1) };
            if ($@) {
                $c->log->debug($@);
                return;
            }
        }

        my $root = $body->documentElement;

        # let's make a transform override parameter
        if (my @xf = $uri->query_param('transform')) {
            # first nuke what's there
            for my $pi ($XPC->findnodes(
                q{/processing-instruction('xml-stylesheet')}, $body)) {
                if ($pi->getData
                        =~ m!\btype\s*=\s*['"]\s*(?:text|application)/xsl!i) {
                    $pi->unbindNode;
                }
            }

            # then (maybe) put it back
            if (defined $xf[0] and $xf[0] ne '') {
                my $xfuri = URI->new_abs($xf[0], $uri)->canonical;
                # but only if the domains match
                if ($xfuri->authority eq $uri->authority) {
                    my $pidata = sprintf 'href="%s" type="text/xsl"',
                        $xfuri->path_query;
                    my $pi = $body->createProcessingInstruction
                        ('xml-stylesheet', $pidata);
                    # make sure it goes in first
                    $body->hasChildNodes ?
                        $body->insertBefore($pi, $body->firstChild) :
                            $body->appendChild($pi);
                }
            }
        }

        # now we fix the links and crap
        if (defined $root) {
            # since we're in here with the root element, let's primp
            # up the content-type header
            my $ct = $res->content_type || '';
            if (($ct =~ m!(?:application|text)/xml!i or $ct !~ /xml/i)
                    and my @v = @{$CT{$root->namespaceURI || ''} || []}) {
                my $qs = 1.25; # this will get translated to 1
                @v = map +[$_, $qs *= 0.8, $_, (undef) x 4],
                    (@v, 'application/xml');
                $ct = HTTP::Negotiate::choose(\@v, $c->req->headers);
                $c->log->debug("Chose new content-type $ct");
                $res->content_type($ct);
            }

            # universal base href
            my $bhref;

            # deal with namespace declarations
            for my $elem ($XPC->findnodes('namespace-decls(//*)', $body)) {
                for my $ns ($elem->getNamespaces) {
                    my $prefix = $ns->declaredPrefix;
                    my $nsuri  = $ns->declaredURI;
                    $nsuri =~ s/^\s*(.*?)\s*$/$1/sm;
                    $nsuri = URI->new($nsuri);
                    if ($uri->host ne $host and $nsuri->can('host')
                            and $nsuri->host eq $host) {
                        $c->log->debug($nsuri);
                        my $newns = $nsuri->clone;
                        $newns->authority($uri->authority);
                        #my $activate = $elem->namespaceURI eq $nsuri;
                        $elem->setNamespaceDeclURI($prefix, $newns->as_string);
                        #($newns->as_string, $prefix, $activate);
                    }
                }
            }

            # deal with XHTML
            if ($root->namespaceURI eq XHTMLNS or $root->nodeName eq 'html') {
                #$c->log->debug('here we are folks');

                # deal with namespace
                $root->setNamespace(XHTMLNS, '', 1)
                    if $root->nodeName eq $root->localName;

                my ($pi) = $XPC->findnodes
                    (q{/processing-instruction('xml-stylesheet')}, $body);

                # deal with doctype
                $body->removeInternalSubset;
                $body->createInternalSubset('html', undef, undef) unless
                    $c->stash->{no_dtd} or ($c->stash->{xsl_no_dtd} && $pi);


                # deal with base href
                my ($base) = $XPC->findnodes
                    ('/html:html/html:head/html:base', $root);

                if ($base) {
                    my $x = $base->getAttribute('href');
                    $x =~ s/^\s*(.*?)\s*$/$1/;
                    $bhref = URI->new($x);
                }
                else {
                    $bhref = $uri->clone;
                    $base  = $body->createElementNS(XHTMLNS, 'base');
                    if (my ($head) = $XPC->findnodes
                            ('/html:html/html:head', $root)) {
                        if (my ($t) = $XPC->findnodes('html:title', $head)) {
                            $head->insertAfter($base, $t);
                        }
                        else {
                            $head->appendChild($base);
                        }
                    }
                }
                $base->setAttribute(href => $uri->as_string);

            }
            # deal with everything else
            elsif ($root->hasAttribute('xml:base')){
                # note this ONLY concerns xml:base in the ROOT ELEMENT!
                $bhref = URI->new($root->getAttribute('xml:base'));
                $root->setAttribute('xml:base', $uri->as_string);
            }
            else {
                $bhref = $c->req->uri->clone;
                $root->setAttribute('xml:base', $bhref->as_string);
            }

            # TODO overwrite xml:base on elements beneath the root

            # deal with links, etc
            if ($c->stash->{skip_rewrite}) {
                for my $elem ($XPC->findnodes(ROOTXPATH, $body)) {
                    $self->_rewrite_uris($c, $elem, $bhref);
                }
            }
            else {
                for my $elem ($XPC->findnodes(URIXPATH, $body)) {
                    #$c->log->debug($c->config->{host});
                    $self->_rewrite_uris($c, $elem, $bhref);
                }
            }
        }

        # XXX GHETTO CSV EXPORT
        my $ct = $uri->query_param('content-type');
        if ($ct and $ct =~ m!text/csv!i) {
            my (undef, @pairs) = split /\s*;\s*/, $ct;
            my %ctp = map { split /\s*=\s*/, lc $_ } @pairs;

            $c->detach('View::XML::CSV', [$ctp{header}]);

            return;
        }

        # now do the content-type header

        $res->content_type('application/xml')
            unless $res->content_type =~ /x[ms]l/i;
        $res->content_type_charset($body->encoding);

        # now serialize the body

        # note this produces a byte string, so doing this
        # for the content-length will be accurate.
        my $str = $body->toString(1);
        my $len = length $str;

        if ($body->actualEncoding =~ /utf[_-]?8/i) {
            # nevertheless, Catalyst seems to interfere, so we do this:
            $c->log->debug('re-decoding UTF-8 bytes for Catalyst');
            utf8::decode($str);
        }
        else {
            $c->log->debug(
                sprintf 'actual encoding is %s', $body->actualEncoding);
        }

        # punt it out
        $res->body($str);
        $res->content_length($len); # set this after the body

        # what do we return?
        $str;
    }
}

=head1 AUTHOR

dorian,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
