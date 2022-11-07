#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;

# Complain loudly if you don't have Catalyst::Devel installed or
# haven't said 'make dist' to create a standalone tarball.
use Module::Install::Catalyst;

name 'App-IBIS';
all_from 'lib/App/IBIS.pm';

# need these files
requires_external_bin 'npm';
requires_external_bin 'psass';

# this makes it more amenable to dockerization among other things
cpanfile;

catalyst_ignore(
    qw(
          MANIFEST.* blib maint js node_modules
          .*\.(db|out|ttl|org|yml|gz|zip) Dockerfile \.dockerignore
  ));

catalyst;

preamble <<'PREAMBLE';
non_perl :
	$(PERL) maint/preinstall.pl

pure_all :: non_perl
	$(NOECHO) $(NOOP)
PREAMBLE

install_script glob('script/*.pl');
auto_install;
WriteAll;
