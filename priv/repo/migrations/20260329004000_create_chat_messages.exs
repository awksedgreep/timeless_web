defmodule TimelessWeb.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages) do
      add :body, :text, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:chat_messages, [:user_id])
    create index(:chat_messages, [:inserted_at])
  end
end
