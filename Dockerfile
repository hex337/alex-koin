FROM elixir:1.6
MAINTAINER hex337

ARG GITHUB_TOKEN

ENV HOME=/usr/src/alex-koin

RUN apt-get update && apt-get install --yes \
    postgresql-client \
    vim \
    git \
    curl \
    inotify-tools

RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix archive.install --force https://github.com/phoenixframework/archives/raw/master/phx_new-1.3.3.ez

COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

ADD . $HOME

WORKDIR $HOME
EXPOSE 4000
