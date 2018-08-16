FROM elixir:1.6
MAINTAINER hex337

ARG SLACK_TOKEN
ARG KOIN_BOT_ID

ENV HOME=/usr/src/alex-koin

RUN apt-get update && apt-get install --yes \
    postgresql-client \
    vim \
    git \
    curl \
    inotify-tools

RUN mix local.hex --force \
    && mix local.rebar --force

COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

ADD . $HOME

WORKDIR $HOME
EXPOSE 4000
