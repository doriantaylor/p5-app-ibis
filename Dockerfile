from node:latest as node-prereq

ENV PATH="/code/js/node_modules/.bin:/usr/local/bin:${PATH}"
# ENV NODE_ENV=development

WORKDIR /code
COPY js /code/js

WORKDIR /code/js
# RUN npm install -g --no-audit --no-fund --link --force
RUN npm config set timeout=5 registry=http://registry.npmjs.org/
# RUN npm install -g --no-audit --no-fund rollup
RUN npm install --no-audit --no-fund --omit=optional
# RUN ls /usr/local/lib/node_modules
# RUN ls node_modules
# RUN npm bin -g
RUN npm run build

WORKDIR /code
COPY root /code/root

FROM perl:latest

WORKDIR /code

ENV PERL_CARTON_PATH=/carton
# XXX apparently this doesn't do anything:
ENV PERL5LIB=/code/lib:/carton/lib/perl5
# lol
ENV EMAIL=test@hi.lol

# RUN curl -sL https://deb.nodesource.com/setup_18.x | bash \
#      && apt-get update && apt-get install -y nodejs
# RUN apt-get update
# RUN apt-get install -y nodejs

COPY --from=node-prereq root /code/root

RUN cpanm App::cpm \
    && cpm install -g Carton Starman Plack::Middleware::ForceEnv \
    && mkdir /carton /vendor \
    && useradd -m catalyst -g users \
    && chown -R catalyst:users /carton /vendor \
    && rm -rf /root/.cpanm /tmp/* /home/catalyst/.perl-cpm

COPY cpanfile /code/
# ugh fine freeze the deps
COPY cpanfile.snapshot /code/

RUN cpm install -L /carton \
    && rm -rf /home/catalyst/.cpanm /home/catalyst/.perl-cpm /tmp/*

COPY app_ibis.psgi /code/
COPY lib  /code/lib
COPY root /code/root

# lol make this sqlite not postgres
# RUN sed -i -e 's!\(dsn.*\)dbi:Pg.*!\1dbi:SQLite:dbname=/home/catalyst/trine.db!' app_ibis.conf
RUN perl -pe 's!dbi:Pg:.*!dbi:SQLite:dbname=/home/catalyst/trine.db!' app_ibis.conf > app_ibis.conf.new && mv app_ibis.conf.new app_ibis.conf

USER catalyst:users

# arguably more trouble than it's worth
VOLUME /carton

# not sure what goes here (cargo cult)
VOLUME /vendor

EXPOSE 5000

# no clue why this thing can't just get the dirs right
# CMD ["carton", "exec", "starman", "-Ilib", "-I/carton/lib/perl5", "-e", "'enable ForceEnv => REMOTE_USER => $ENV{EMAIL}'", "app_ibis.psgi"]
CMD ["carton", "exec", "starman", "-Ilib", "-e", "'enable ForceEnv => REMOTE_USER => $ENV{EMAIL}'", "app_ibis.psgi"]
