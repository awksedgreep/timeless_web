defmodule TimelessWeb.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias TimelessWeb.Accounts.User

  schema "chat_messages" do
    field :body, :string
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body])
    |> update_change(:body, &String.trim/1)
    |> validate_required([:body])
    |> validate_length(:body, max: 1_000)
    |> assoc_constraint(:user)
  end
end
