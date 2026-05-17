# Build stage
FROM elixir:1.16-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git build-base

# Copy mix files
COPY mix.exs mix.lock ./

# Install Elixir dependencies
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod && \
    mix deps.compile

# Copy application code
COPY . .

# Build assets if present
RUN if [ -f "assets/package.json" ]; then \
    apk add --no-cache nodejs npm && \
    cd assets && npm ci && npm run build && cd ..; \
fi

# Create releases
RUN MIX_ENV=prod mix compile && \
    MIX_ENV=prod mix release

# Runtime stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache openssl bash ca-certificates

WORKDIR /app

# Copy release from builder
COPY --from=builder /app/_build/prod/rel/igaming_ref ./

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Run the release
CMD ["bin/igaming_ref", "start"]
