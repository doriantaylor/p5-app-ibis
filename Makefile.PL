#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;

# Complain loudly if you don't have Catalyst::Devel installed or
# haven't said 'make dist' to create a standalone tarball.
use Module::Install::Catalyst;

name 'App-IBIS';
all_from 'lib/App/IBIS.pm';

requires 'Catalyst::Runtime' => '5.90019';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'CatalystX::RoleApplicator';
requires 'Catalyst::TraitFor::Request::ProxyBase';
requires 'Moose';
requires 'MooseX::Types::Moose';
requires 'MooseX::Params::Validate';
requires 'namespace::autoclean';

# This should reflect the config file format you've chosen
# See Catalyst::Plugin::ConfigLoader for supported formats
requires 'Config::General';

# app-specific third-party
requires 'Catalyst::Model::RDF'         => '0.03';
requires 'Data::GUID::Any'              => '0.004';
requires 'RDF::Trine'                   => '1.007';
requires 'URI::NamespaceMap'            => '0.06';
requires 'URI::urn::uuid'               => '0.03';
requires 'DateTime::Format::W3CDTF'     => '0.06';
requires 'HTTP::Negotiate'              => '6.00';
requires 'Convert::Color::HUSL'         => '1.000';
requires 'Unicode::Collate'             => '1.19';

# stuff i made
requires 'Role::Markup::XML'            => '0.03';
requires 'RDF::KV'                      => '0.04';
requires 'Data::UUID::NCName'           => '0.03';
requires 'CatalystX::Action::Negotiate' => '0.04';

test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
