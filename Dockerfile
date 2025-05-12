ARG ELIXIR_VERSION=1.18.3
ARG OTP_VERSION=27.3.4
ARG DEBIAN_VERSION=bookworm-20250428-slim
ARG NODE_VERSION=24.0.1-bookworm-slim
ARG ASSETS_IMAGE="node:${NODE_VERSION}"
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${ASSETS_IMAGE} AS assets
WORKDIR /app/assets
COPY assets .
RUN npm install

FROM ${BUILDER_IMAGE} AS builder
RUN apt-get update -y \
  && apt-get install -y \
    build-essential \
    git \
  && apt-get clean \
  && rm -f /var/lib/apt/lists/*_*
WORKDIR /app
RUN mix do local.hex --force, local.rebar --force
ARG MIX_ENV="prod"
ENV MIX_ENV=${MIX_ENV}
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile
COPY priv priv
COPY lib lib
COPY --from=assets /app/assets ./assets/
RUN mix assets.deploy
RUN mix compile
COPY config/runtime.exs config/
COPY rel rel
RUN mix release

FROM ${RUNNER_IMAGE}
RUN apt-get update -y \
  && apt-get install -y \
    libncurses5 \
    libstdc++6 \
    locales ca-certificates \
    openssl \
    tini \
  && apt-get clean \
  && rm -f /var/lib/apt/lists/*_*
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
  && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
WORKDIR /app
RUN chown nobody /app
ARG MIX_ENV="prod"
ENV MIX_ENV=${MIX_ENV}
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/growth ./
USER nobody
ENTRYPOINT ["tini", "-s", "--"]
CMD ["/app/bin/server"]
