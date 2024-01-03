# -*- mode: cperl -*-

on 'configure' => sub {
   requires 'Module::Install';
   requires 'Module::Install::CPANfile';
   requires 'Module::Install::ReadmeFromPod';
};

on 'test' => sub {
   requires 'Test::More' => '0.88';
};

on develop => sub {
    requires 'Catalyst::Devel';
};

on runtime => sub {
    recommends 'DBD::SQLite';
    recommends 'DBD::Pg';
    recommends 'Starman';
};

# moose stuff
requires 'Moose';
requires 'MooseX::Types::Moose';
requires 'MooseX::Params::Validate';
requires 'namespace::autoclean';

# catalyst stuff
requires 'Catalyst::Runtime' => '5.90019';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::SubRequest';
requires 'Catalyst::Action::RenderView';
requires 'CatalystX::RoleApplicator';
requires 'Catalyst::TraitFor::Request::ProxyBase';
requires 'Catalyst::ScriptRunner';

# This should reflect the config file format you've chosen
# See Catalyst::Plugin::ConfigLoader for supported formats
requires 'Config::General';

# app-specific third-party
requires 'Catalyst::Model::RDF'         => '0.03';
requires 'Convert::Color'               => '0.17';
requires 'Convert::Color::HUSL'         => '1.000';
requires 'CSS::Sass'                    => 'v3.6.3';
requires 'Data::GUID::Any'              => '0.004';
requires 'DateTime::Format::W3CDTF'     => '0.06';
requires 'HTTP::Negotiate'              => '6.00';
requires 'IPC::Shareable'               => '1.13';
requires 'RDF::Trine'                   => '1.019';
requires 'Unicode::Collate'             => '1.19';
requires 'URI::NamespaceMap'            => '0.06';
requires 'URI::urn::uuid'               => '0.03';
requires 'XML::LibXML';
requires 'XML::LibXSLT';

# stuff i made
requires 'Role::Markup::XML'            => '0.03';
requires 'RDF::KV'                      => '0.14';
requires 'Data::UUID::NCName'           => '0.07';
requires 'CatalystX::Action::Negotiate' => '0.05';
