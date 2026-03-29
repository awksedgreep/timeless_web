import Config

parse_ip = fn
  "127.0.0.1" ->
    {127, 0, 0, 1}

  "0.0.0.0" ->
    {0, 0, 0, 0}

  value ->
    value
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
end

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/timeless_web start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :timeless_web, TimelessWebWeb.Endpoint, server: true
end

config :timeless_web, TimelessWebWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /etc/timeless_web/timeless_web.db
      """

  config :timeless_web, TimelessWeb.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "5880")
  bind_ip = parse_ip.(System.get_env("PHX_IP") || "127.0.0.1")

  config :timeless_web, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :timeless_web, TimelessWebWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    check_origin: ["https://#{host}", "https://www.#{host}"] |> Enum.uniq(),
    http: [
      ip: bind_ip,
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :timeless_web, TimelessWebWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :timeless_web, TimelessWebWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  resend_api_key =
    System.get_env("RESEND_API_KEY") ||
      raise """
      environment variable RESEND_API_KEY is missing.
      Get one at https://resend.com/api-keys
      """

  config :timeless_web, TimelessWeb.Mailer,
    adapter: Swoosh.Adapters.Resend,
    api_key: resend_api_key
end
