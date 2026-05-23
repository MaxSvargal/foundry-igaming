ARG ELIXIR_VERSION=1.18.4
ARG OTP_VERSION=26.0.1
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-bookworm-20260518-slim"
ARG RUNNER_IMAGE="debian:bookworm-slim"

FROM ${BUILDER_IMAGE} AS builder

WORKDIR /app
ENV MIX_ENV=prod

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git gcc g++ make curl && \
    rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config ./config
RUN mix deps.get --only $MIX_ENV && \
    mix deps.compile

COPY . .

RUN if [ -f "assets/package.json" ]; then \
    apt-get update && apt-get install -y --no-install-recommends nodejs npm && \
    cd assets && npm ci && npm run build && cd .. && \
    rm -rf /var/lib/apt/lists/*; \
fi

RUN mix compile && \
    mix release

FROM ${RUNNER_IMAGE} AS runner

ENV LANG=C.UTF-8 LANGUAGE=C.UTF-8 LC_ALL=C.UTF-8 ELIXIR_ERL_OPTIONS="+fnu"
ENV PHX_SERVER=true

RUN apt-get update && apt-get install -y --no-install-recommends \
    libstdc++6 openssl ca-certificates bash curl git postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/igaming_ref ./

RUN mkdir -p /app/config

COPY <<EOF /app/bin/entrypoint.sh
#!/bin/bash
set -eu

APP_NAME="igaming_ref"
RELEASE_BIN="/app/bin/${APP_NAME}"

if [ ! -x "$RELEASE_BIN" ]; then
  echo "Release executable not found: $RELEASE_BIN" >&2
  exit 1
fi

export RELEASE_NAME="${APP_NAME}"
export RELEASE_NODE="${APP_NAME}@127.0.0.1"

exec "$RELEASE_BIN" start
EOF

RUN chmod +x /app/bin/entrypoint.sh

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 CMD curl -sf http://localhost:4000/health || exit 1

EXPOSE 4000
ENTRYPOINT ["/app/bin/entrypoint.sh"]
