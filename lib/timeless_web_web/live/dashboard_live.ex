defmodule TimelessWebWeb.DashboardLive do
  use TimelessWebWeb, :live_view

  import TimelessWebWeb.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TimelessWeb.PubSub, TimelessWeb.StoreWatcher.topic())
    end

    {:ok, socket |> assign(active_page: :dashboard) |> load_data()}
  end

  @impl true
  def handle_info({:store_updated, _info}, socket) do
    {:noreply, load_data(socket)}
  end

  defp store do
    Application.get_env(:timeless_web, :timeless_store, :metrics)
  end

  defp load_data(socket) do
    info = Timeless.info(store())
    {:ok, metrics} = Timeless.list_metrics(store())
    {:ok, alerts} = Timeless.list_alerts(store())

    now = System.os_time(:second)
    day_ago = now - 86_400
    {:ok, annotations} = Timeless.annotations(store(), day_ago, now)

    firing_alerts =
      alerts
      |> Enum.flat_map(fn rule ->
        rule.states
        |> Enum.filter(&(&1.state == "firing"))
        |> Enum.map(&Map.merge(&1, %{alert_name: rule.name, metric: rule.metric}))
      end)

    assign(socket,
      info: info,
      metrics_count: length(metrics),
      firing_alerts: firing_alerts,
      all_alerts: alerts,
      annotations: annotations
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_page={@active_page}>
      <.page_header title="Dashboard">
        <:actions>
          <span class="badge badge-sm badge-ghost">live</span>
        </:actions>
      </.page_header>

      <%!-- Stat Cards --%>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <.stat_card
          title="Series"
          value={to_string(@info.series_count)}
          subtitle={"#{@metrics_count} metrics"}
        />
        <.stat_card
          title="Total Points"
          value={format_number(@info.total_points)}
          subtitle={"#{format_bytes(@info.storage_bytes)} on disk"}
        />
        <.stat_card
          title="Buffer"
          value={to_string(@info.buffer_points)}
          subtitle={"#{@info.buffer_shards} shards"}
        />
        <.stat_card
          title="Compression"
          value={
            if @info.bytes_per_point > 0,
              do: "#{Float.round((1 - @info.bytes_per_point / 16) * 100, 1)}%",
              else: "N/A"
          }
          subtitle={"#{Float.round(@info.bytes_per_point, 1)} B/pt — #{format_bytes(@info.raw_compressed_bytes)} on disk"}
        />
      </div>

      <%!-- Tier Summary --%>
      <div class="mb-6">
        <h2 class="text-lg font-semibold mb-3">Storage Tiers</h2>
        <div class="overflow-x-auto">
          <table class="table table-sm">
            <thead>
              <tr>
                <th>Tier</th>
                <th>Resolution</th>
                <th>Retention</th>
                <th>Rows</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={{name, tier} <- @info.tiers}>
                <td class="font-medium">{name}</td>
                <td>{format_duration(tier.resolution_seconds)}</td>
                <td>{tier.retention}</td>
                <td>{format_number(tier.rows)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <%!-- Firing Alerts --%>
        <div>
          <h2 class="text-lg font-semibold mb-3">
            Firing Alerts <.badge :if={@firing_alerts != []} status="firing" />
            <span :if={@firing_alerts == []} class="text-sm font-normal text-base-content/50">
              None
            </span>
          </h2>
          <div :if={@firing_alerts != []} class="overflow-x-auto">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>Alert</th>
                  <th>Metric</th>
                  <th>Value</th>
                  <th>Since</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={alert <- @firing_alerts}>
                  <td class="font-medium">{alert.alert_name}</td>
                  <td>{alert.metric}</td>
                  <td>{format_value(alert.last_value)}</td>
                  <td>{format_timestamp(alert.triggered_at)}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <%!-- Recent Annotations --%>
        <div>
          <h2 class="text-lg font-semibold mb-3">
            Recent Annotations
            <span class="text-sm font-normal text-base-content/50">(last 24h)</span>
          </h2>
          <div :if={@annotations == []} class="text-sm text-base-content/50">No annotations</div>
          <div :if={@annotations != []} class="space-y-2">
            <div :for={ann <- @annotations} class="card bg-base-200 border border-base-300 p-3">
              <div class="flex items-center justify-between">
                <span class="font-medium text-sm">{ann.title}</span>
                <span class="text-xs text-base-content/50">{format_timestamp(ann.timestamp)}</span>
              </div>
              <p :if={ann[:description]} class="text-xs text-base-content/60 mt-1">
                {ann.description}
              </p>
              <div :if={ann[:tags] && ann.tags != []} class="flex gap-1 mt-1">
                <span :for={tag <- ann.tags} class="badge badge-xs badge-neutral">{tag}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
