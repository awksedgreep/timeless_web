defmodule TimelessWeb.Site.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    field :slug, :string
    field :tagline, :string
    field :summary, :string
    field :description_md, :string
    field :repo_url, :string
    field :docs_url, :string
    field :product_url, :string
    field :featured, :boolean, default: false
    field :sort_order, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [
      :name,
      :slug,
      :tagline,
      :summary,
      :description_md,
      :repo_url,
      :docs_url,
      :product_url,
      :featured,
      :sort_order
    ])
    |> validate_required([:name, :slug, :tagline, :summary, :description_md])
    |> unique_constraint(:slug)
  end
end
