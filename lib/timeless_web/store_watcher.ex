defmodule TimelessWeb.StoreWatcher do
  @moduledoc """
  Polls the Timeless store and broadcasts changes via PubSub.
  LiveViews subscribe to "timeless:store" for real-time updates.
  """
  use GenServer

  @poll_interval 2_000
  @topic "timeless:store"

  def topic, do: @topic

  def start_link(opts) do
    store = Keyword.fetch!(opts, :store)
    GenServer.start_link(__MODULE__, store, name: __MODULE__)
  end

  @impl true
  def init(store) do
    schedule_poll()
    {:ok, %{store: store, last_hash: nil}}
  end

  @impl true
  def handle_info(:poll, state) do
    schedule_poll()
    info = Timeless.info(state.store)
    hash = {info.series_count, info.total_points, info.buffer_points, info.storage_bytes}

    if hash != state.last_hash do
      Phoenix.PubSub.broadcast(TimelessWeb.PubSub, @topic, {:store_updated, info})
      {:noreply, %{state | last_hash: hash}}
    else
      {:noreply, state}
    end
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval)
  end
end
