FROM perl:latest

WORKDIR /code

ENV PERL_CARTON_PATH=/carton
ENV PERL5LIB=/code/lib

RUN cpanm App::cpm \
    && cpm install -g Carton \
    && mkdir /carton /vendor \
    && useradd -m catalyst -g users \
    && chown -R catalyst:users /carton /vendor \
    && rm -f r/root/.cpanm /tmp/* /home/catalyst/.perl-cpm

COPY cpanfile cpanfile.snapshot /code/

COPY myapp.* /code/
COPY lib  /code/lib
COPY root /code/root

USER catalyst:users

RUN cpm install -L /carton \
    && rm -rf /home/catalyst/.cpanm /home/catalyst/.perl-cpm /tmp/*

VOLUME /carton

VOLUME /vendor

EXPOSE 5000

CMD ["carton", "exec", "plackup", "-Ilib", "myapp.psgi"]
