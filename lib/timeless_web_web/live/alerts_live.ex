defmodule TimelessWebWeb.AlertsLive do
  use TimelessWebWeb, :live_view

  import TimelessWebWeb.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, metrics} = Timeless.list_metrics(store())

    socket =
      socket
      |> assign(
        active_page: :alerts,
        refresh_seconds: 30,
        metrics: metrics,
        show_create_form: false,
        form: default_form(),
        confirm_delete: nil,
        evaluating: false
      )
      |> load_alerts()

    if connected?(socket), do: schedule_refresh(socket)

    {:ok, socket}
  end

  @impl true
  def handle_info(:refresh, socket) do
    schedule_refresh(socket)
    {:noreply, load_alerts(socket)}
  end

  def handle_info(:evaluate_done, socket) do
    {:noreply,
     socket
     |> assign(evaluating: false)
     |> load_alerts()
     |> put_flash(:info, "Alert evaluation complete")}
  end

  @impl true
  def handle_event("toggle_create_form", _params, socket) do
    {:noreply,
     assign(socket, show_create_form: !socket.assigns.show_create_form, form: default_form())}
  end

  def handle_event("validate_alert", %{"alert" => params}, socket) do
    {:noreply, assign(socket, form: params)}
  end

  def handle_event("create_alert", %{"alert" => params}, socket) do
    opts = [
      name: params["name"],
      metric: params["metric"],
      condition: String.to_existing_atom(params["condition"]),
      threshold: parse_float(params["threshold"]),
      duration: parse_int(params["duration"]),
      aggregate: String.to_existing_atom(params["aggregate"]),
      webhook_url: nullify_blank(params["webhook_url"])
    ]

    case Timeless.create_alert(store(), opts) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(show_create_form: false, form: default_form())
         |> load_alerts()
         |> put_flash(:info, "Alert rule created")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to create: #{inspect(reason)}")}
    end
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, confirm_delete: id)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, confirm_delete: nil)}
  end

  def handle_event("delete_alert", %{"id" => id}, socket) do
    :ok = Timeless.delete_alert(store(), id)

    {:noreply,
     socket
     |> assign(confirm_delete: nil)
     |> load_alerts()
     |> put_flash(:info, "Alert rule deleted")}
  end

  def handle_event("evaluate_alerts", _params, socket) do
    pid = self()

    Task.start(fn ->
      Timeless.evaluate_alerts(store())
      send(pid, :evaluate_done)
    end)

    {:noreply, assign(socket, evaluating: true)}
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

  defp load_alerts(socket) do
    {:ok, alerts} = Timeless.list_alerts(store())
    assign(socket, alerts: alerts)
  end

  defp default_form do
    %{
      "name" => "",
      "metric" => "",
      "condition" => "above",
      "threshold" => "",
      "duration" => "60",
      "aggregate" => "avg",
      "webhook_url" => ""
    }
  end

  defp parse_float(s) do
    case Float.parse(s) do
      {f, _} -> f
      :error -> 0.0
    end
  end

  defp parse_int(s) do
    case Integer.parse(s) do
      {i, _} -> i
      :error -> 60
    end
  end

  defp nullify_blank(""), do: nil
  defp nullify_blank(s), do: s

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_page={@active_page}>
      <.page_header title="Alerts">
        <:actions>
          <button
            class="btn btn-sm btn-outline"
            phx-click="evaluate_alerts"
            disabled={@evaluating}
          >
            <span :if={@evaluating} class="loading loading-spinner loading-xs" /> Evaluate Now
          </button>
          <button class="btn btn-sm btn-primary" phx-click="toggle_create_form">
            {if @show_create_form, do: "Cancel", else: "New Alert"}
          </button>
          <select id="refresh-picker" class="select select-xs select-bordered" phx-change="set_refresh" phx-hook=".RefreshPicker" name="interval">
            <option :for={s <- [5, 10, 30, 60]} value={s} selected={@refresh_seconds == s}>
              {s}s
            </option>
          </select>
        </:actions>
      </.page_header>

      <%!-- Create Form --%>
      <div :if={@show_create_form} class="card bg-base-200 border border-base-300 p-4 mb-6">
        <h3 class="text-sm font-semibold mb-3">Create Alert Rule</h3>
        <form phx-submit="create_alert" phx-change="validate_alert" class="space-y-3">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label class="label label-text text-xs">Name</label>
              <input
                type="text"
                name="alert[name]"
                value={@form["name"]}
                required
                class="input input-sm input-bordered w-full"
                placeholder="High CPU"
              />
            </div>
            <div>
              <label class="label label-text text-xs">Metric</label>
              <select name="alert[metric]" class="select select-sm select-bordered w-full" required>
                <option value="">Select metric...</option>
                <option :for={m <- @metrics} value={m} selected={@form["metric"] == m}>{m}</option>
              </select>
            </div>
          </div>
          <div class="grid grid-cols-1 sm:grid-cols-4 gap-3">
            <div>
              <label class="label label-text text-xs">Condition</label>
              <select name="alert[condition]" class="select select-sm select-bordered w-full">
                <option
                  :for={c <- ["above", "below", "equal"]}
                  value={c}
                  selected={@form["condition"] == c}
                >
                  {c}
                </option>
              </select>
            </div>
            <div>
              <label class="label label-text text-xs">Threshold</label>
              <input
                type="number"
                step="any"
                name="alert[threshold]"
                value={@form["threshold"]}
                required
                class="input input-sm input-bordered w-full"
              />
            </div>
            <div>
              <label class="label label-text text-xs">Duration (s)</label>
              <input
                type="number"
                name="alert[duration]"
                value={@form["duration"]}
                class="input input-sm input-bordered w-full"
              />
            </div>
            <div>
              <label class="label label-text text-xs">Aggregate</label>
              <select name="alert[aggregate]" class="select select-sm select-bordered w-full">
                <option
                  :for={a <- ["avg", "min", "max", "sum", "count", "last"]}
                  value={a}
                  selected={@form["aggregate"] == a}
                >
                  {a}
                </option>
              </select>
            </div>
          </div>
          <div>
            <label class="label label-text text-xs">Webhook URL (optional)</label>
            <input
              type="url"
              name="alert[webhook_url]"
              value={@form["webhook_url"]}
              class="input input-sm input-bordered w-full"
              placeholder="https://hooks.example.com/..."
            />
          </div>
          <button type="submit" class="btn btn-sm btn-primary">Create</button>
        </form>
      </div>

      <%!-- Alert Rules --%>
      <div :if={@alerts == []} class="card bg-base-200 border border-base-300 p-8 text-center">
        <p class="text-base-content/50">No alert rules configured</p>
      </div>

      <div class="space-y-4">
        <div :for={rule <- @alerts} class="card bg-base-200 border border-base-300 p-4">
          <div class="flex items-start justify-between mb-3">
            <div>
              <div class="flex items-center gap-2">
                <h3 class="font-bold">{rule.name}</h3>
                <.badge :if={Enum.any?(rule.states, &(&1.state == "firing"))} status="firing" />
                <.badge :if={Enum.all?(rule.states, &(&1.state == "ok"))} status="ok" />
              </div>
              <p class="text-sm text-base-content/60 mt-1">
                {rule.metric} — {rule.condition} {format_value(rule.threshold)} for {rule.duration}s ({rule.aggregate})
              </p>
            </div>
            <div>
              <button
                :if={@confirm_delete != rule.id}
                class="btn btn-xs btn-ghost text-error"
                phx-click="confirm_delete"
                phx-value-id={rule.id}
              >
                Delete
              </button>
              <div :if={@confirm_delete == rule.id} class="flex gap-1">
                <button class="btn btn-xs btn-error" phx-click="delete_alert" phx-value-id={rule.id}>
                  Confirm
                </button>
                <button class="btn btn-xs btn-ghost" phx-click="cancel_delete">
                  Cancel
                </button>
              </div>
            </div>
          </div>

          <%!-- Per-series state table --%>
          <div :if={rule.states != []} class="overflow-x-auto">
            <table class="table table-xs">
              <thead>
                <tr>
                  <th>Series</th>
                  <th>State</th>
                  <th>Last Value</th>
                  <th>Triggered At</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={state <- rule.states}>
                  <td class="text-xs">
                    {state[:labels] |> inspect()}
                  </td>
                  <td><.badge status={state.state} /></td>
                  <td>{format_value(state.last_value)}</td>
                  <td>{format_timestamp(state[:triggered_at])}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <p :if={rule.states == []} class="text-xs text-base-content/50">No series evaluated yet</p>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
