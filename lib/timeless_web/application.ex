defmodule TimelessWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TimelessWebWeb.Telemetry,
      TimelessWeb.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:timeless_web, :ecto_repos), skip: skip_migrations?()},
      {TimelessPhoenix,
       data_dir: "priv/observability",
       timeless: [
         raw_retention_seconds: 14 * 86_400,
         daily_retention_seconds: 365 * 86_400
       ],
       timeless_logs: [
         retention_max_age: 7 * 86_400,
         retention_max_size: 256 * 1_048_576
       ],
       timeless_traces: [
         retention_max_age: 7 * 86_400,
         retention_max_size: 256 * 1_048_576
       ]},
      {DNSCluster, query: Application.get_env(:timeless_web, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TimelessWeb.PubSub},
      TimelessWeb.Chat.Notifier,
      # Start to serve requests, typically the last entry
      TimelessWebWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TimelessWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TimelessWebWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
