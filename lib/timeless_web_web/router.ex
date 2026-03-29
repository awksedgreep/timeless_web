defmodule TimelessWebWeb.Router do
  use TimelessWebWeb, :router

  import TimelessPhoenix.Router
  import TimelessWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TimelessWebWeb.Layouts, :root}
    plug :put_layout, html: {TimelessWebWeb.Layouts, :app}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TimelessWebWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/blog", BlogController, :index
    get "/blog/:slug", BlogController, :show
    get "/projects", ProjectController, :index
    get "/projects/:slug", ProjectController, :show
  end

  scope "/admin", TimelessWebWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin_user]

    get "/", AdminController, :index

    get "/posts", AdminPostController, :index
    get "/posts/new", AdminPostController, :new
    post "/posts", AdminPostController, :create
    get "/posts/:id/edit", AdminPostController, :edit
    put "/posts/:id", AdminPostController, :update
    delete "/posts/:id", AdminPostController, :delete

    get "/projects", AdminProjectController, :index
    get "/projects/new", AdminProjectController, :new
    post "/projects", AdminProjectController, :create
    get "/projects/:id/edit", AdminProjectController, :edit
    put "/projects/:id", AdminProjectController, :update
    delete "/projects/:id", AdminProjectController, :delete
  end

  scope "/" do
    pipe_through :browser

    timeless_phoenix_dashboard("/dashboard",
      metrics: TimelessWebWeb.Telemetry,
      live_dashboard: [allow_destructive_actions: false]
    )
  end

  # Other scopes may use custom stacks.
  # scope "/api", TimelessWebWeb do
  #   pipe_through :api
  # end

  if Application.compile_env(:timeless_web, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", TimelessWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", TimelessWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/chat", ChatController, :show
    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", TimelessWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
