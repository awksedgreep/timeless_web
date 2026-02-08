defmodule TimelessWebWeb.HealthLive do
  use TimelessWebWeb, :live_view

  import TimelessWebWeb.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TimelessWeb.PubSub, TimelessWeb.StoreWatcher.topic())
    end

    socket =
      socket
      |> assign(active_page: :health, action_loading: nil, action_result: nil)
      |> load_data()

    {:ok, socket}
  end

  @impl true
  def handle_info({:store_updated, _info}, %{assigns: %{action_loading: nil}} = socket) do
    {:noreply, load_data(socket)}
  end

  def handle_info({:store_updated, _info}, socket) do
    {:noreply, socket}
  end

  def handle_info({:run_action, action}, socket) do
    result =
      case action do
        :flush -> Timeless.flush(store())
        :rollup -> Timeless.rollup(store())
        :catch_up -> Timeless.catch_up(store())
        :enforce_retention -> Timeless.enforce_retention(store())
      end

    message =
      case result do
        :ok -> "#{format_action(action)} completed successfully"
        {:ok, _} -> "#{format_action(action)} completed successfully"
        {:error, reason} -> "#{format_action(action)} failed: #{inspect(reason)}"
        results when is_list(results) -> "#{format_action(action)} completed successfully"
      end

    {:noreply,
     socket
     |> assign(action_loading: nil, action_result: message)
     |> load_data()}
  end

  @impl true
  def handle_event("run_" <> action, _params, socket) do
    action = String.to_existing_atom(action)
    send(self(), {:run_action, action})
    {:noreply, assign(socket, action_loading: action, action_result: nil)}
  end

  def handle_event("dismiss_result", _params, socket) do
    {:noreply, assign(socket, action_result: nil)}
  end

  defp store do
    Application.get_env(:timeless_web, :timeless_store, :metrics)
  end

  defp load_data(socket) do
    info = Timeless.info(store())
    assign(socket, info: info)
  end

  defp format_compression(%{bytes_per_point: bpp}) when bpp > 0 do
    ratio = Float.round((1 - bpp / 16) * 100, 1)
    "#{ratio}%"
  end

  defp format_compression(_), do: "N/A"

  defp format_action(:flush), do: "Flush"
  defp format_action(:rollup), do: "Rollup"
  defp format_action(:catch_up), do: "Catch-up"
  defp format_action(:enforce_retention), do: "Enforce retention"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_page={@active_page}>
      <.page_header title="Health">
        <:actions>
          <span class="badge badge-sm badge-ghost">live</span>
        </:actions>
      </.page_header>

      <%!-- Action Result Banner --%>
      <div :if={@action_result} class="alert alert-info mb-4">
        <span>{@action_result}</span>
        <button class="btn btn-ghost btn-xs" phx-click="dismiss_result">Dismiss</button>
      </div>

      <%!-- Stat Cards --%>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <.stat_card title="Series" value={to_string(@info.series_count)} />
        <.stat_card title="Segments" value={to_string(@info.segment_count)} />
        <.stat_card title="Total Points" value={format_number(@info.total_points)} />
        <.stat_card title="Storage" value={format_bytes(@info.storage_bytes)} />
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <.stat_card
          title="Compression"
          value={format_compression(@info)}
          subtitle={
            if @info.bytes_per_point > 0,
              do: "#{Float.round(@info.bytes_per_point, 1)} B/pt (16 B/pt uncompressed)",
              else: nil
          }
        />
        <.stat_card
          title="Buffer"
          value={"#{@info.buffer_points} pts / #{@info.buffer_shards} shards"}
        />
        <.stat_card
          title="Time Range"
          value={if @info[:oldest_timestamp], do: format_timestamp(@info.oldest_timestamp), else: "—"}
          subtitle={
            if @info[:newest_timestamp],
              do: "to #{format_timestamp(@info.newest_timestamp)}",
              else: nil
          }
        />
        <.stat_card
          title="Raw Retention"
          value={
            if @info[:raw_retention_seconds],
              do: format_duration(@info.raw_retention_seconds),
              else: "—"
          }
        />
      </div>

      <%!-- Tier Table --%>
      <div class="mb-6">
        <h2 class="text-lg font-semibold mb-3">Tier Details</h2>
        <div class="overflow-x-auto">
          <table class="table table-sm">
            <thead>
              <tr>
                <th>Tier</th>
                <th>Resolution</th>
                <th>Retention</th>
                <th>Rows</th>
                <th>Watermark</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={{name, tier} <- @info.tiers}>
                <td class="font-medium">{name}</td>
                <td>{format_duration(tier.resolution_seconds)}</td>
                <td>{tier.retention}</td>
                <td>{format_number(tier.rows)}</td>
                <td>{if tier[:watermark], do: format_timestamp(tier.watermark), else: "—"}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <%!-- Admin Actions --%>
      <div>
        <h2 class="text-lg font-semibold mb-3">Admin Actions</h2>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <button
            :for={action <- [:flush, :rollup, :catch_up, :enforce_retention]}
            class="btn btn-sm btn-outline"
            phx-click={"run_#{action}"}
            disabled={@action_loading != nil}
          >
            <span :if={@action_loading == action} class="loading loading-spinner loading-xs" />
            {format_action(action)}
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
