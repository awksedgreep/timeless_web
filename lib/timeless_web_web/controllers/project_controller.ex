defmodule TimelessWebWeb.ProjectController do
  use TimelessWebWeb, :controller

  alias TimelessWeb.Site

  def index(conn, _params) do
    render(conn, :index, projects: Site.list_projects())
  end

  def show(conn, %{"slug" => slug}) do
    render(conn, :show, project: Site.get_project_by_slug!(slug))
  end
end
