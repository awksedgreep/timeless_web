defmodule TimelessWeb.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    store_name = Application.get_env(:timeless_web, :timeless_store, :metrics)
    data_dir = Application.get_env(:timeless_web, :timeless_data_dir, "/tmp/timeless_dev")

    children = [
      TimelessWebWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:timeless_web, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TimelessWeb.PubSub},
      {Timeless, name: store_name, data_dir: data_dir},
      {Timeless.HTTP, store: store_name, port: 4001},
      {TimelessWeb.StoreWatcher, store: store_name},
      TimelessWebWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: TimelessWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    TimelessWebWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
