defmodule TimelessWeb.Repo.Migrations.CreatePostsAndProjects do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :summary, :text, null: false
      add :body_md, :text, null: false
      add :published_on, :date, null: false
      add :featured, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:posts, [:slug])

    create table(:projects) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :tagline, :string, null: false
      add :summary, :text, null: false
      add :description_md, :text, null: false
      add :repo_url, :string
      add :docs_url, :string
      add :product_url, :string
      add :featured, :boolean, null: false, default: false
      add :sort_order, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:projects, [:slug])
  end
end
