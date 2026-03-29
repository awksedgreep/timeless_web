defmodule TimelessWeb.Site.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :slug, :string
    field :summary, :string
    field :body_md, :string
    field :published_on, :date
    field :featured, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :slug, :summary, :body_md, :published_on, :featured])
    |> validate_required([:title, :slug, :summary, :body_md, :published_on])
    |> unique_constraint(:slug)
  end
end
