defmodule TimelessWeb.Chat.Notifier do
  @moduledoc """
  Buffers chat messages when admin is offline and sends a digest email
  after a quiet period.
  """
  use GenServer

  alias TimelessWeb.Accounts.UserNotifier

  @admin_email "mark.cotner@diablodata.com"
  # Send digest after 2 minutes of no new messages
  @digest_delay_ms :timer.minutes(2)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc "Call when admin joins the chat LiveView."
  def admin_joined do
    GenServer.cast(__MODULE__, :admin_joined)
  end

  @doc "Call when admin leaves the chat LiveView."
  def admin_left do
    GenServer.cast(__MODULE__, :admin_left)
  end

  @doc "Call when a new chat message is created (by a non-admin)."
  def message_created(message) do
    GenServer.cast(__MODULE__, {:message, message})
  end

  # Server

  @impl true
  def init(_) do
    {:ok, %{admin_online: false, buffer: [], timer: nil}}
  end

  @impl true
  def handle_cast(:admin_joined, state) do
    cancel_timer(state.timer)
    {:noreply, %{state | admin_online: true, buffer: [], timer: nil}}
  end

  @impl true
  def handle_cast(:admin_left, state) do
    {:noreply, %{state | admin_online: false}}
  end

  @impl true
  def handle_cast({:message, _message}, %{admin_online: true} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({:message, message}, state) do
    cancel_timer(state.timer)
    timer = Process.send_after(self(), :send_digest, @digest_delay_ms)
    {:noreply, %{state | buffer: state.buffer ++ [message], timer: timer}}
  end

  @impl true
  def handle_info(:send_digest, %{buffer: []} = state) do
    {:noreply, %{state | timer: nil}}
  end

  @impl true
  def handle_info(:send_digest, %{buffer: messages} = state) do
    send_digest_email(messages)
    {:noreply, %{state | buffer: [], timer: nil}}
  end

  defp cancel_timer(nil), do: :ok
  defp cancel_timer(ref), do: Process.cancel_timer(ref)

  defp send_digest_email(messages) do
    count = length(messages)

    body =
      messages
      |> Enum.map(fn msg ->
        time = Calendar.strftime(msg.inserted_at, "%H:%M UTC")
        "  [#{time}] #{msg.user.email}: #{msg.body}"
      end)
      |> Enum.join("\n")

    UserNotifier.deliver_chat_digest(
      @admin_email,
      count,
      body
    )
  end
end
