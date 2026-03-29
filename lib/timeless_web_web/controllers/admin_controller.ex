defmodule TimelessWebWeb.AdminController do
  use TimelessWebWeb, :controller

  alias TimelessWeb.Site

  def index(conn, _params) do
    render(conn, :index,
      posts: Site.list_posts_for_admin() |> Enum.take(5),
      projects: Site.list_projects_for_admin() |> Enum.take(5)
    )
  end
end
