defmodule TimelessWebWeb.AdminPostController do
  use TimelessWebWeb, :controller

  alias TimelessWeb.Site
  alias TimelessWeb.Site.Post

  def index(conn, _params) do
    render(conn, :index, posts: Site.list_posts_for_admin())
  end

  def new(conn, _params) do
    changeset = Site.change_post(%Post{})
    render_form(conn, changeset, "New post", ~p"/admin/posts")
  end

  def create(conn, %{"post" => post_params}) do
    case Site.create_post(post_params) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post created.")
        |> redirect(to: ~p"/blog/#{post.slug}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render_form(conn, changeset, "New post", ~p"/admin/posts")
    end
  end

  def edit(conn, %{"id" => id}) do
    post = Site.get_post!(id)
    changeset = Site.change_post(post)
    render_form(conn, changeset, "Edit post", ~p"/admin/posts/#{post.id}", post: post)
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Site.get_post!(id)

    case Site.update_post(post, post_params) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post updated.")
        |> redirect(to: ~p"/blog/#{post.slug}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render_form(conn, changeset, "Edit post", ~p"/admin/posts/#{post.id}", post: post)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Site.get_post!(id)
    {:ok, _post} = Site.delete_post(post)

    conn
    |> put_flash(:info, "Post deleted.")
    |> redirect(to: ~p"/admin/posts")
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
