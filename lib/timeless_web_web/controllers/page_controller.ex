defmodule TimelessWebWeb.PageController do
  use TimelessWebWeb, :controller

  alias TimelessWeb.Site

  def home(conn, _params) do
    render(conn, :home,
      projects: Site.featured_projects(),
      posts: Site.recent_posts()
    )
  end
end
