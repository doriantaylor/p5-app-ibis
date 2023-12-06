#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;

use Module::Install::CPANfile;

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

catalyst_ignore(qw(
                      MANIFEST.* blib maint js node_modules Dockerfile
                      \.dockerignore .*\.(db|out|ttl|org|yml|gz|zip)
              ));

catalyst;

postamble <<'POSTAMBLE';
.PHONY : scss nodejs .nodejs

root/asset/main.scss :
	$(NOECHO) $(NOOP)

js/d3.js :
	$(NOECHO) $(NOOP)

js/rdf.js :
	$(NOECHO) $(NOOP)

js/rdf-viz.js :
	$(NOECHO) $(NOOP)

js/force-directed.js :
	$(NOECHO) $(NOOP)

js/hierarchical.js :
	$(NOECHO) $(NOOP)

root/asset/main.css : root/asset/main.scss
	if which psass > /dev/null && [ -e root/asset/main.scss ]; then cd root/asset; psass -t expanded -o main.css main.scss; cd -; fi

scss : root/asset/main.css
	$(NOECHO) $(NOOP)

# .nodejs :
# 	if which npm >/dev/null; then cd js; npm run build; cd -; fi

root/asset/d3.js : js/d3.js
	$(NOECHO) $(NOOP)

root/asset/rdf.js : js/rdf.js
	$(NOECHO) $(NOOP)

root/asset/rdf-viz.js : js/rdf-viz.js
	$(NOECHO) $(NOOP)

root/asset/force-directed.js : js/force-directed.js
	$(NOECHO) $(NOOP)

root/asset/hierarchical.js : js/hierarchical.js
	$(NOECHO) $(NOOP)

nodejs : root/asset/d3.js root/asset/rdf.js root/asset/rdf-viz.js root/asset/force-directed.js root/asset/hierarchical.js
	if which npm >/dev/null && [ -d js ]; then cd js; npm run build; cd -; fi
	# $(NOECHO) $(NOOP)

non_perl : scss nodejs
	$(NOECHO) $(NOOP)

pure_all :: non_perl
	$(NOECHO) $(NOOP)
POSTAMBLE

install_script glob('script/*.pl');
auto_install;
WriteAll;
