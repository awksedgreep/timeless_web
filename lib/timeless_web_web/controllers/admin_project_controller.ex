defmodule TimelessWebWeb.AdminProjectController do
  use TimelessWebWeb, :controller

  alias TimelessWeb.Site
  alias TimelessWeb.Site.Project

  def index(conn, _params) do
    render(conn, :index, projects: Site.list_projects_for_admin())
  end

  def new(conn, _params) do
    changeset = Site.change_project(%Project{})
    render_form(conn, changeset, "New project", ~p"/admin/projects")
  end

  def create(conn, %{"project" => project_params}) do
    case Site.create_project(project_params) do
      {:ok, project} ->
        conn
        |> put_flash(:info, "Project created.")
        |> redirect(to: ~p"/projects/#{project.slug}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render_form(conn, changeset, "New project", ~p"/admin/projects")
    end
  end

  def edit(conn, %{"id" => id}) do
    project = Site.get_project!(id)
    changeset = Site.change_project(project)

    render_form(conn, changeset, "Edit project", ~p"/admin/projects/#{project.id}",
      project: project
    )
  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    project = Site.get_project!(id)

    case Site.update_project(project, project_params) do
      {:ok, project} ->
        conn
        |> put_flash(:info, "Project updated.")
        |> redirect(to: ~p"/projects/#{project.slug}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render_form(conn, changeset, "Edit project", ~p"/admin/projects/#{project.id}",
          project: project
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    project = Site.get_project!(id)
    {:ok, _project} = Site.delete_project(project)

    conn
    |> put_flash(:info, "Project deleted.")
    |> redirect(to: ~p"/admin/projects")
  end

  defp render_form(conn, changeset, page_title, action, extra_assigns \\ []) do
    conn
    |> assign(:page_title, page_title)
    |> render(
      :editor,
      Keyword.merge(
        [form: Phoenix.Component.to_form(changeset), action: action],
        extra_assigns
      )
    )
  end
end
