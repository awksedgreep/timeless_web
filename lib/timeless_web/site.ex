defmodule TimelessWeb.Site do
  @moduledoc """
  Public-facing content for the Timeless website.
  """

  import Ecto.Query, warn: false

  alias TimelessWeb.Repo
  alias TimelessWeb.Site.Post
  alias TimelessWeb.Site.Project

  def list_posts_for_admin do
    Post
    |> order_by([post], desc: post.published_on, asc: post.title)
    |> Repo.all()
  end

  def list_posts do
    Post
    |> order_by([post], desc: post.featured, desc: post.published_on, asc: post.title)
    |> Repo.all()
  end

  def recent_posts(limit \\ 3) do
    Post
    |> order_by([post], desc: post.featured, desc: post.published_on, asc: post.title)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_post_by_slug!(slug), do: Repo.get_by!(Post, slug: slug)
  def get_post!(id), do: Repo.get!(Post, id)

  def create_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  def delete_post(%Post{} = post), do: Repo.delete(post)

  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def list_projects_for_admin do
    Project
    |> order_by([project], desc: project.featured, asc: project.sort_order, asc: project.name)
    |> Repo.all()
  end

  def list_projects do
    Project
    |> order_by([project], desc: project.featured, asc: project.sort_order, asc: project.name)
    |> Repo.all()
  end

  def featured_projects(limit \\ 3) do
    Project
    |> order_by([project], desc: project.featured, asc: project.sort_order, asc: project.name)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_project_by_slug!(slug), do: Repo.get_by!(Project, slug: slug)
  def get_project!(id), do: Repo.get!(Project, id)

  def create_project(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  def delete_project(%Project{} = project), do: Repo.delete(project)

  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end
end
