defmodule TimelessWeb.Chat do
  @moduledoc """
  Lightweight authenticated chat for builders using the Timeless site.
  """

  import Ecto.Query, warn: false

  alias TimelessWeb.Accounts.User
  alias TimelessWeb.Chat.Message
  alias TimelessWeb.Repo

  @topic "chat:lobby"

  def subscribe do
    Phoenix.PubSub.subscribe(TimelessWeb.PubSub, @topic)
  end

  def list_recent_messages(limit \\ 40) do
    Message
    |> order_by([message], asc: message.inserted_at)
    |> preload(:user)
    |> limit(^limit)
    |> Repo.all()
  end

  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  def create_message(%User{} = user, attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        message = Repo.preload(message, :user)
        Phoenix.PubSub.broadcast(TimelessWeb.PubSub, @topic, {:message_created, message})
        unless user.is_admin, do: TimelessWeb.Chat.Notifier.message_created(message)
        {:ok, message}

      error ->
        error
    end
  end
end
