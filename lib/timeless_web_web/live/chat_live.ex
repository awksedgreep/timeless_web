defmodule TimelessWebWeb.ChatLive do
  use TimelessWebWeb, :live_view

  alias TimelessWeb.Accounts
  alias TimelessWeb.Chat
  alias TimelessWeb.Chat.{Message, Notifier}

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    case Accounts.get_user_by_session_token(user_token) do
      {user, _token_inserted_at} ->
        if connected?(socket) do
          Chat.subscribe()
          if user.is_admin, do: Notifier.admin_joined()
        end

        {:ok,
         socket
         |> assign(:current_user, user)
         |> assign(:messages, Chat.list_recent_messages())
         |> assign(:message_form, to_form(Chat.change_message(%Message{}), as: :message))}

      nil ->
        {:ok, redirect(socket, to: ~p"/users/log-in")}
    end
  end

  @impl true
  def terminate(_reason, socket) do
    if socket.assigns[:current_user] && socket.assigns.current_user.is_admin do
      Notifier.admin_left()
    end
  end

  @impl true
  def handle_event("send_message", %{"message" => message_params}, socket) do
    case Chat.create_message(socket.assigns.current_user, message_params) do
      {:ok, _message} ->
        {:noreply,
         assign(socket, :message_form, to_form(Chat.change_message(%Message{}), as: :message))}

      {:error, changeset} ->
        {:noreply, assign(socket, :message_form, to_form(changeset, as: :message))}
    end
  end

  @impl true
  def handle_info({:message_created, message}, socket) do
    {:noreply, update(socket, :messages, &append_message(&1, message))}
  end

  defp append_message(messages, message) do
    (messages ++ [message]) |> Enum.take(-40)
  end
end
