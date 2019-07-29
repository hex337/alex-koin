ARG ALPINE_VERSION=3.8

FROM elixir:1.7.4-alpine AS builder

ARG SLACK_TOKEN
ARG KOIN_BOT_ID

ARG APP_NAME
ARG APP_VSN
ARG MIX_ENV=prod
ARG SKIP_PHOENIX=true
ARG PHOENIX_SUBDIR=.

ENV APP_NAME=${APP_NAME} \
    APP_VSN=${APP_VSN} \
    HOME=/usr/src/alex-koin \
    KOIN_BOT_ID=${KOIN_BOT_ID} \
    MIX_ENV=${MIX_ENV} \
    SLACK_TOKEN=${SLACK_TOKEN}

WORKDIR $HOME

RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
      build-base \
      git \
      nodejs \
      yarn \
      postgresql-client && \
    mix local.rebar --force && \
    mix local.hex --force

COPY . .

RUN mix do deps.get, deps.compile, compile

# This is for a PHOENIX frontend
RUN if [ ! "$SKIP_PHOENIX" = "true" ]; then \
  cd ${PHOENIX_SUBDIR}/assets && \
  yarn install && \
  yarn deploy && \
  cd .. && \
  mix phx.digest; \
fi

RUN \
  mkdir -p /opt/built && \
  mix release --verbose && \
  cp _build/${MIX_ENV}/rel/${APP_NAME}/releases/${APP_VSN}/${APP_NAME}.tar.gz /opt/built && \
  cd /opt/built && \
  tar -xzf ${APP_NAME}.tar.gz && \
  rm ${APP_NAME}.tar.gz

FROM alpine:${ALPINE_VERSION}

ARG APP_NAME

RUN apk update && \
    apk add --no-cache \
      bash \
      openssl-dev

ENV REPLACE_OS_VARS=true \
    APP_NAME=${APP_NAME}

WORKDIR /opt/app

COPY --from=builder /opt/built .

CMD trap 'exit' INT; /opt/app/bin/${APP_NAME} foreground
