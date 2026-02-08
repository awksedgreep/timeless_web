defmodule TimelessWebWeb.MetricsLive do
  use TimelessWebWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, metrics} = Timeless.list_metrics(store())

    socket =
      assign(socket,
        active_page: :metrics,
        refresh_seconds: 30,
        all_metrics: metrics,
        filtered_metrics: metrics,
        search: "",
        selected_metric: nil,
        metadata: nil,
        series: [],
        label_keys: []
      )

    if connected?(socket), do: schedule_refresh(socket)

    {:ok, socket}
  end

  @impl true
  def handle_info(:refresh, socket) do
    schedule_refresh(socket)
    {:ok, metrics} = Timeless.list_metrics(store())

    filtered = filter_metrics(metrics, socket.assigns.search)

    socket =
      socket
      |> assign(all_metrics: metrics, filtered_metrics: filtered)
      |> maybe_refresh_selection()

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    filtered = filter_metrics(socket.assigns.all_metrics, search)
    {:noreply, assign(socket, search: search, filtered_metrics: filtered)}
  end

  def handle_event("select_metric", %{"metric" => metric}, socket) do
    {:noreply, load_metric_detail(socket, metric)}
  end

  def handle_event("clear_selection", _params, socket) do
    {:noreply, assign(socket, selected_metric: nil, metadata: nil, series: [], label_keys: [])}
  end

  def handle_event("set_refresh", %{"interval" => val}, socket) do
    seconds = String.to_integer(val)
    {:noreply, assign(socket, refresh_seconds: seconds)}
  end

  defp schedule_refresh(socket) do
    Process.send_after(self(), :refresh, socket.assigns.refresh_seconds * 1000)
  end

  defp store do
    Application.get_env(:timeless_web, :timeless_store, :metrics)
  end

  defp filter_metrics(metrics, ""), do: metrics

  defp filter_metrics(metrics, search) do
    term = String.downcase(search)
    Enum.filter(metrics, &String.contains?(String.downcase(&1), term))
  end

  defp load_metric_detail(socket, metric) do
    {:ok, metadata} = Timeless.get_metadata(store(), metric)
    {:ok, series} = Timeless.list_series(store(), metric)

    label_keys =
      series
      |> Enum.flat_map(fn s -> Map.keys(s) end)
      |> Enum.uniq()
      |> Enum.sort()

    assign(socket,
      selected_metric: metric,
      metadata: metadata,
      series: series,
      label_keys: label_keys
    )
  end

  defp maybe_refresh_selection(%{assigns: %{selected_metric: nil}} = socket), do: socket

  defp maybe_refresh_selection(%{assigns: %{selected_metric: metric}} = socket) do
    if metric in socket.assigns.all_metrics do
      load_metric_detail(socket, metric)
    else
      assign(socket, selected_metric: nil, metadata: nil, series: [], label_keys: [])
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_page={@active_page}>
      <.page_header title="Metrics">
        <:actions>
          <span class="text-xs text-base-content/50">{length(@all_metrics)} metrics</span>
          <select id="refresh-picker" class="select select-xs select-bordered" phx-change="set_refresh" phx-hook=".RefreshPicker" name="interval">
            <option :for={s <- [5, 10, 30, 60]} value={s} selected={@refresh_seconds == s}>
              {s}s
            </option>
          </select>
        </:actions>
      </.page_header>

      <div class="flex gap-6">
        <%!-- Left Panel: Metric List --%>
        <div class="w-1/3 min-w-[240px]">
          <input
            type="text"
            placeholder="Search metrics..."
            value={@search}
            phx-change="search"
            phx-debounce="200"
            name="search"
            class="input input-sm input-bordered w-full mb-3"
          />

          <div class="space-y-1 max-h-[calc(100vh-220px)] overflow-y-auto">
            <button
              :for={metric <- @filtered_metrics}
              class={[
                "block w-full text-left px-3 py-2 rounded-lg text-sm transition-colors",
                if(metric == @selected_metric,
                  do: "bg-primary text-primary-content",
                  else: "hover:bg-base-200 text-base-content/80"
                )
              ]}
              phx-click="select_metric"
              phx-value-metric={metric}
            >
              {metric}
            </button>
            <p :if={@filtered_metrics == []} class="text-sm text-base-content/50 px-3 py-2">
              No metrics match your search
            </p>
          </div>
        </div>

        <%!-- Right Panel: Detail --%>
        <div class="flex-1">
          <div
            :if={@selected_metric == nil}
            class="card bg-base-200 border border-base-300 p-8 text-center"
          >
            <p class="text-base-content/50">Select a metric to view details</p>
          </div>

          <div :if={@selected_metric}>
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-lg font-bold">{@selected_metric}</h2>
              <div class="flex gap-2">
                <a
                  href={~p"/timeless/explorer?metric=#{@selected_metric}"}
                  class="btn btn-sm btn-primary"
                >
                  Open in Explorer
                </a>
                <button class="btn btn-sm btn-ghost" phx-click="clear_selection">
                  Close
                </button>
              </div>
            </div>

            <%!-- Metadata --%>
            <div :if={@metadata} class="card bg-base-200 border border-base-300 p-4 mb-4">
              <h3 class="text-sm font-semibold mb-2">Metadata</h3>
              <div class="grid grid-cols-2 gap-2 text-sm">
                <div :for={{key, val} <- Map.to_list(@metadata)}>
                  <span class="text-base-content/60">{key}:</span>
                  <span class="font-medium ml-1">{inspect(val)}</span>
                </div>
              </div>
            </div>

            <div :if={@metadata == nil} class="card bg-base-200 border border-base-300 p-4 mb-4">
              <p class="text-sm text-base-content/50">No registered metadata</p>
            </div>

            <%!-- Series Info --%>
            <div class="card bg-base-200 border border-base-300 p-4 mb-4">
              <h3 class="text-sm font-semibold mb-2">
                Series <span class="badge badge-sm badge-neutral ml-1">{length(@series)}</span>
              </h3>

              <div :if={@label_keys != []} class="mb-3">
                <span class="text-xs text-base-content/60">Label keys:</span>
                <span
                  :for={key <- @label_keys}
                  class="badge badge-xs badge-primary badge-outline ml-1"
                >
                  {key}
                </span>
              </div>

              <div class="overflow-x-auto max-h-64 overflow-y-auto">
                <table class="table table-xs">
                  <thead>
                    <tr>
                      <th>#</th>
                      <th>Labels</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={{series, idx} <- Enum.with_index(@series, 1)}>
                      <td class="text-base-content/50">{idx}</td>
                      <td>
                        <span :for={{k, v} <- series.labels} class="inline-block mr-2 text-xs">
                          <span class="text-base-content/60">{k}=</span>{v}
                        </span>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
