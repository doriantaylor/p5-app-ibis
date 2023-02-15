from node:latest as node-prereq

ENV PATH="/nodejs/js/node_modules/.bin:/usr/local/bin:${PATH}"
# ENV NODE_ENV=development

WORKDIR /nodejs
COPY root /nodejs/root

# make the sass stuff happen here (and the rest of apt while we're at it)
RUN apt-get update
RUN apt-get install -y libsass-dev sassc libxml2-dev libxslt1-dev
WORKDIR /nodejs/root/asset
RUN sassc -t expanded main.scss main.css

# okay now do the javascript stuff
COPY js /nodejs/js
WORKDIR /nodejs/js
RUN npm config set registry=http://registry.npmjs.org/
RUN npm install --no-audit --no-fund --omit=optional
RUN npm run build

FROM perl:latest

WORKDIR /code

ENV PERL_CARTON_PATH=/carton
# XXX apparently this doesn't do anything:
ENV PERL5LIB=/code/lib:/carton/lib/perl5
# lol
ENV EMAIL=test@hi.lol

ENV PATH="/carton/bin:${PATH}"

COPY --from=node-prereq /nodejs/root /code/root
RUN rm -rf /nodejs

RUN cpanm App::cpm \
    && cpm install -g Carton Starman Plack::Middleware::ForceEnv \
    Catalyst::Plugin::StackTrace CSS::Sass && mkdir /carton /vendor \
    && useradd -m catalyst -g users \
    && chown -R catalyst:users /carton /vendor \
    && rm -rf /root/.{cpanm,perl-cpm} /home/catalyst/.{cpanm,perl-cpm} /tmp/*

COPY cpanfile /code/
COPY cpanfile.snapshot /code/
COPY script/get* /tmp/

RUN /tmp/get-jquery
RUN /tmp/get-fa

RUN cpm install -L /carton \
    && rm -rf /home/catalyst/.cpanm /home/catalyst/.perl-cpm /tmp/*

COPY app_ibis.* /code/
COPY lib  /code/lib

# lol make this sqlite not postgres
# RUN sed -i -e 's!\(dsn.*\)dbi:Pg.*!\1dbi:SQLite:dbname=/home/catalyst/trine.db!' app_ibis.conf
RUN perl -pi -e 's!dbi:Pg:.*!dbi:SQLite:dbname=/home/catalyst/trine.db!' app_ibis.conf

USER catalyst:users

# expose this so state persists/you can grab it off
VOLUME /home/catalyst

# arguably more trouble than it's worth
# VOLUME /carton

# not sure what goes here (cargo cult)
# VOLUME /vendor

EXPOSE 5000

# no clue why this thing can't just get the dirs right
# CMD ["cat", "app_ibis.conf"]
# CMD ["carton", "exec", "starman", "-Ilib", "-I/carton/lib/perl5", "-e", "'enable ForceEnv => REMOTE_USER => $ENV{EMAIL}'", "app_ibis.psgi"]
CMD ["carton", "exec", "starman", "-Ilib", "-e", "'enable ForceEnv => REMOTE_USER => $ENV{EMAIL}'", "app_ibis.psgi"]
