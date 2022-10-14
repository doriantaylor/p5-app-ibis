FROM perl:latest

WORKDIR /code

ENV PERL_CARTON_PATH=/carton
# XXX apparently this doesn't do anything:
ENV PERL5LIB=/code/lib:/carton/lib/perl5

RUN cpanm App::cpm \
    && cpm install -g Carton Starman Plack::Middleware::ForceEnv \
    && mkdir /carton /vendor \
    && useradd -m catalyst -g users \
    && chown -R catalyst:users /carton /vendor \
    && rm -rf /root/.cpanm /tmp/* /home/catalyst/.perl-cpm

COPY cpanfile /code/
# ugh fine freeze the deps
COPY cpanfile.snapshot /code/

COPY app_ibis.* /code/
COPY lib  /code/lib
COPY root /code/root

# lol make this sqlite not postgres
RUN sed -i -e 's!\(dsn.*\)dbi:Pg.*!\1dbi:SQLite:dbname=/home/catalyst/trine.db!' app_ibis.conf

USER catalyst:users

RUN cpm install -L /carton \
    && rm -rf /home/catalyst/.cpanm /home/catalyst/.perl-cpm /tmp/*

# arguably more trouble than it's worth
VOLUME /carton

# not sure what goes here (cargo cult)
VOLUME /vendor

EXPOSE 5000

# lol
ENV EMAIL=test@hi.lol

# no clue why this thing can't just get the dirs right
CMD ["carton", "exec", "starman", "-Ilib", "-I/carton/lib/perl5", "-e", "'enable ForceEnv => REMOTE_USER => $ENV{EMAIL}'", "app_ibis.psgi"]
