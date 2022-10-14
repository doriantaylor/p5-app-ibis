FROM perl:latest

WORKDIR /code

ENV PERL_CARTON_PATH=/carton
# XXX apparently this doesn't do anything:
ENV PERL5LIB=/code/lib

RUN cpanm App::cpm \
    && cpm install -g Carton Starman \
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
RUN sed -i -e 's/\(dsn.*\)dbi:Pg/\1dbi:SQLite:dbname=trine.db/' app_ibis.conf

USER catalyst:users

RUN cpm install -L /carton \
    && rm -rf /home/catalyst/.cpanm /home/catalyst/.perl-cpm /tmp/*

VOLUME /carton

VOLUME /vendor

EXPOSE 5000

CMD ["carton", "exec", "starman", "-Ilib", "app_ibis.psgi"]
