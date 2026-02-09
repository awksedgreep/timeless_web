defmodule TimelessWebWeb.Router do
  use TimelessWebWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TimelessWebWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", TimelessWebWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/timeless", TimelessWebWeb do
    pipe_through :browser

    live "/", DashboardLive
    live "/metrics", MetricsLive
    live "/explorer", ExplorerLive
    live "/alerts", AlertsLive
    live "/annotations", AnnotationsLive
    live "/schema", SchemaLive
    live "/health", HealthLive
    live "/backup", BackupLive

    get "/backup/download/:name", BackupController, :download
  end
end
