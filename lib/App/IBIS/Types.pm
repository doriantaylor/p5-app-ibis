package App::IBIS::Types;

use strict;
use warnings FATAL => 'all';

use MooseX::Types::Moose qw(Maybe Defined Str Num HashRef ArrayRef);
use MooseX::Types -declare => [qw(Angle URIStr URIObject Resource
                                  NS RDFNS NSMap RDFNSMap Model SynMap InvMap)];

use RDF::Trine ();
use POSIX      ();
use URI        ();
use URI::NamespaceMap ();


subtype Angle, as Num,   where { $_ >= 0 && $_ < 360 };
coerce  Angle, from Num, via { POSIX::fmod($_, 360) };

coerce HashRef, from ArrayRef, via { { map ($_ => $_), @{$_[0]} } };
coerce HashRef, from Maybe[Str|URIObject],
    via { defined $_[0] ? {$_[0] => $_[0]} : {} };

class_type Model, { class => 'RDF::Trine::Model' };

# put all these declarations together since their type coercions interact

class_type URIObject, { class => 'URI' };
class_type Resource,  { class => 'RDF::Trine::Node::Resource' };
class_type NS,        { class => 'URI::Namespace' };
class_type RDFNS,     { class => 'RDF::Trine::Namespace' };
class_type NSMap,     { class => 'URI::NamespaceMap' };
class_type RDFNSMap,  { class => 'RDF::Trine::NamespaceMap' };

coerce URIObject, from Str,   via { URI->new($_) };
coerce URIObject, from NS,    via { URI->new($_->as_string) };
coerce URIObject, from RDFNS, via { URI->new($_->uri->uri_value) };
coerce Resource,  from Str,   via { RDF::Trine::Node::Resource->new($_[0]) };
coerce Resource,  from RDFNS, via { $_[0]->uri };
coerce Resource,  from URIObject|NS, via {
    RDF::Trine::Node::Resource->new($_[0]->as_string) };

# throw in a URI string subtype so we can ghetto rig up some coercions

# XXX fix this with a proper regex
subtype URIStr, as Str, where { /^\S*$/ };
coerce  URIStr, from URIObject|NS, via { $_[0]->as_string };
coerce  URIStr, from Resource,     via { $_[0]->uri_value };
coerce  URIStr, from RDFNS,        via { $_[0]->uri->uri_value };

# coercing both kinds of namespace map is basically the same
# operation, so we generate them.

sub via_hash_nsmap {
    my $class = shift;
    return sub {
        my %map = map +($_ => to_URIStr($_[0]{$_})), keys %{$_[0]};
        $class->new(\%map);
    };
}

sub via_swap_nstype {
    my $class = shift;
    return sub {
        my $obj = shift;
        my %map = map +($_ => to_URIStr($obj->namespace_uri($_))),
            $obj->list_prefixes;
        $class->new(\%map);
    };
}

# now do all these coercions at once

coerce NSMap,    from HashRef,  via_hash_nsmap('URI::NamespaceMap');
coerce RDFNSMap, from HashRef,  via_hash_nsmap('RDF::Trine::NamespaceMap');
coerce NSMap,    from RDFNSMap, via_swap_nstype('URI::NamespaceMap');
coerce RDFNSMap, from NSMap,    via_swap_nstype('RDF::Trine::NamespaceMap');

subtype SynMap, as HashRef[ArrayRef];
coerce SynMap, from Maybe[HashRef], via {
    my $hash = shift or return {};
    while (my ($k, $v) = each %$hash) {
        delete $hash->{$k} unless defined $v;
        $hash->{$k} = [$v] unless ref $v eq 'ARRAY';
    }
    $hash;
};

subtype InvMap, as HashRef;
coerce InvMap, from Maybe[Str], via { defined $_[0] ? { $_[0] => $_[0] } : {}};
coerce InvMap, from Maybe[URIObject|NS|RDFNS|Resource], via {
    return {} unless defined $_[0];
    return { to_URIStr($_[0]) => to_Resource($_[0]) };
};
coerce InvMap, from Maybe[URIObject],
    via { defined $_[0] ? {$_[0] => $_[0]} : {} };


1;
