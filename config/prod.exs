import Config

# Production config — hardened defaults

# Configure endpoint for web serving in production
config :igaming_ref, IgamingRef.Web.Endpoint,
  server: false,
  url: [host: System.get_env("PHX_HOST", "localhost"), port: String.to_integer(System.get_env("PORT", "4000"))],
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4000"))],
  check_origin: false,
  secret_key_base: System.get_env("SECRET_KEY_BASE", "changeme-insecure-default")

# Logging configuration
config :logger, level: :info
