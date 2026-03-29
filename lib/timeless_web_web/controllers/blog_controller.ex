defmodule TimelessWebWeb.BlogController do
  use TimelessWebWeb, :controller

  alias TimelessWeb.Site

  def index(conn, _params) do
    render(conn, :index, posts: Site.list_posts())
  end

  def show(conn, %{"slug" => slug}) do
    render(conn, :show, post: Site.get_post_by_slug!(slug))
  end
end
