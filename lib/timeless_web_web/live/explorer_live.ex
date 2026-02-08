defmodule TimelessWebWeb.ExplorerLive do
  use TimelessWebWeb, :live_view

  import TimelessWebWeb.FormatHelpers

  @time_ranges %{
    "15m" => 900,
    "1h" => 3_600,
    "6h" => 21_600,
    "24h" => 86_400,
    "7d" => 604_800
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok, metrics} = Timeless.list_metrics(store())

    {:ok,
     assign(socket,
       active_page: :explorer,
       metrics: metrics,
       form: default_form(),
       chart_mode: "js",
       chart_svg: nil,
       chart_data: nil,
       results: nil,
       forecast_enabled: false,
       forecast_horizon: "60",
       anomaly_enabled: false,
       anomaly_sensitivity: "medium",
       code_snippet: nil,
       timings: nil
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    case params["metric"] do
      nil ->
        {:noreply, socket}

      metric ->
        form = %{socket.assigns.form | "metric" => metric}
        {:noreply, assign(socket, form: form)}
    end
  end

  @impl true
  def handle_event("update_form", params, socket) do
    form = Map.merge(socket.assigns.form, extract_form_params(params))

    socket =
      socket
      |> assign(form: form)
      |> maybe_assign(params, "forecast_horizon", :forecast_horizon)
      |> maybe_assign(params, "anomaly_sensitivity", :anomaly_sensitivity)

    {:noreply, socket}
  end

  def handle_event("toggle_forecast", _params, socket) do
    {:noreply, assign(socket, forecast_enabled: !socket.assigns.forecast_enabled)}
  end

  def handle_event("toggle_anomalies", _params, socket) do
    {:noreply, assign(socket, anomaly_enabled: !socket.assigns.anomaly_enabled)}
  end

  def handle_event("toggle_chart_mode", _params, socket) do
    new_mode = if socket.assigns.chart_mode == "js", do: "svg", else: "js"

    socket =
      socket
      |> assign(chart_mode: new_mode)
      |> then(fn s ->
        if new_mode == "js" && s.assigns.chart_data do
          push_event(s, "uplot-data", %{json: s.assigns.chart_data})
        else
          s
        end
      end)

    {:noreply, socket}
  end

  def handle_event("query", _params, socket) do
    %{"metric" => metric, "range" => range, "bucket" => bucket, "aggregate" => aggregate} =
      socket.assigns.form

    {transform, post_op} = parse_transform(socket.assigns.form)

    if metric == "" do
      {:noreply, put_flash(socket, :error, "Please select a metric")}
    else
      now = System.os_time(:second)
      range_seconds = Map.get(@time_ranges, range, 3_600)
      from = now - range_seconds

      {query_us, {:ok, series}} =
        :timer.tc(fn ->
          {:ok, s} = run_query(metric, aggregate, bucket, from, now, transform)
          {:ok, apply_post_op(s, post_op)}
        end)

      chart_opts = build_chart_opts(socket, store(), metric, series, from, now)

      {chart_us, svg} =
        :timer.tc(fn ->
          Timeless.Chart.render(metric, series, chart_opts)
        end)

      chart_data = build_chart_data(metric, series, chart_opts)

      total_points = series |> Enum.map(fn s -> length(s.data) end) |> Enum.sum()
      results = build_results_summary(series)
      snippet = build_code_snippet(metric, range, bucket, aggregate, {transform, post_op})

      socket =
        socket
        |> assign(
          chart_svg: svg,
          chart_data: chart_data,
          results: results,
          code_snippet: snippet,
          timings: %{
            query_us: query_us,
            chart_us: chart_us,
            total_us: query_us + chart_us,
            total_points: total_points,
            series_count: length(series)
          }
        )
        |> push_event("uplot-data", %{json: chart_data})

      {:noreply, socket}
    end
  end

  defp store do
    Application.get_env(:timeless_web, :timeless_store, :metrics)
  end

  defp default_form do
    %{
      "metric" => "",
      "range" => "1h",
      "bucket" => "minute",
      "aggregate" => "avg",
      "transform" => "none",
      "transform_arg1" => "",
      "transform_arg2" => ""
    }
  end

  defp run_query(metric, "none", _bucket, from, now, transform) do
    {:ok, series} = Timeless.query_multi(store(), metric, %{}, from: from, to: now)

    series =
      Enum.map(series, fn s ->
        Map.put(s, :data, Timeless.Transform.apply(s.points, transform))
      end)

    {:ok, series}
  end

  defp run_query(metric, aggregate, bucket, from, now, transform) do
    opts = [
      from: from,
      to: now,
      bucket: String.to_existing_atom(bucket),
      aggregate: String.to_existing_atom(aggregate),
      transform: transform
    ]

    Timeless.query_aggregate_multi(store(), metric, %{}, opts)
  end

  defp extract_form_params(params) do
    Map.take(params, ["metric", "range", "bucket", "aggregate", "transform", "transform_arg1", "transform_arg2"])
  end

  defp maybe_assign(socket, params, param_key, assign_key) do
    case params[param_key] do
      nil -> socket
      value -> assign(socket, [{assign_key, value}])
    end
  end

  defp build_chart_opts(socket, store, metric, series, from, now) do
    opts = [theme: :auto]

    opts =
      if socket.assigns.forecast_enabled do
        horizon = parse_int(socket.assigns.forecast_horizon, 60)
        # Use first series labels for forecast
        labels =
          case series do
            [%{labels: l} | _] -> l
            _ -> %{}
          end

        case Timeless.forecast(store, metric, labels, horizon: horizon, from: from, to: now) do
          {:ok, forecast_data} -> Keyword.put(opts, :forecast, forecast_data)
          _ -> opts
        end
      else
        opts
      end

    opts =
      if socket.assigns.anomaly_enabled do
        sensitivity = String.to_existing_atom(socket.assigns.anomaly_sensitivity)

        labels =
          case series do
            [%{labels: l} | _] -> l
            _ -> %{}
          end

        case Timeless.detect_anomalies(store, metric, labels,
               sensitivity: sensitivity,
               from: from,
               to: now
             ) do
          {:ok, anomaly_data} -> Keyword.put(opts, :anomalies, anomaly_data)
          _ -> opts
        end
      else
        opts
      end

    opts
  end

  defp build_results_summary(series) do
    Enum.map(series, fn s ->
      values = Enum.map(s.data, fn {_ts, v} -> v end)

      %{
        labels: s.labels,
        point_count: length(s.data),
        min: if(values != [], do: Enum.min(values), else: nil),
        max: if(values != [], do: Enum.max(values), else: nil),
        latest: if(values != [], do: List.last(values), else: nil)
      }
    end)
  end

  defp build_code_snippet(metric, range, _bucket, "none", {transform, post_op}) do
    transform_line = transform_snippet_line(transform)
    post_line = post_op_snippet(post_op)
    img_params = img_transform_param(transform)

    """
    store = #{inspect(store())}
    now = System.os_time(:second)
    from = now - #{Map.get(@time_ranges, range, 3_600)}

    {:ok, series} = Timeless.query_multi(store, "#{metric}", %{},
      from: from, to: now
    )
    #{transform_line}#{post_line}
    svg = Timeless.Chart.render("#{metric}", series, theme: :auto)

    # Embed in any HTML/PHP page:
    # <img src="/timeless/chart/#{metric}?range=#{range}#{img_params}" />
    # Or paste the SVG output directly into your markup\
    """
  end

  defp build_code_snippet(metric, range, bucket, aggregate, {transform, post_op}) do
    transform_opt = transform_snippet_opt(transform)
    post_line = post_op_snippet(post_op)
    img_params = img_transform_param(transform)

    """
    store = #{inspect(store())}
    now = System.os_time(:second)
    from = now - #{Map.get(@time_ranges, range, 3_600)}

    {:ok, series} = Timeless.query_aggregate_multi(store, "#{metric}", %{},
      from: from, to: now,
      bucket: :#{bucket}, aggregate: :#{aggregate}#{transform_opt}
    )
    #{post_line}
    svg = Timeless.Chart.render("#{metric}", series, theme: :auto)

    # Embed in any HTML/PHP page:
    # <img src="/timeless/chart/#{metric}?range=#{range}&bucket=#{bucket}&aggregate=#{aggregate}#{img_params}" />
    # Or paste the SVG output directly into your markup\
    """
  end

  defp post_op_snippet(nil), do: ""
  defp post_op_snippet(:rate), do: "\n# Per-second rate of change\nseries = Enum.map(series, fn s ->\n  rated = s.data |> Enum.chunk_every(2, 1, :discard) |> Enum.map(fn [{t1,v1},{t2,v2}] -> {t2, (v2-v1)/(t2-t1)} end)\n  %{s | data: rated}\nend)"
  defp post_op_snippet(:nn_rate), do: "\n# Non-negative rate (counter-safe)\nseries = Enum.map(series, fn s ->\n  rated = s.data |> Enum.chunk_every(2, 1, :discard) |> Enum.map(fn [{t1,v1},{t2,v2}] -> {t2, max((v2-v1)/(t2-t1), 0.0)} end)\n  %{s | data: rated}\nend)"
  defp post_op_snippet(:delta), do: "\n# Delta (change between points)\nseries = Enum.map(series, fn s ->\n  deltas = s.data |> Enum.chunk_every(2, 1, :discard) |> Enum.map(fn [{_,v1},{t2,v2}] -> {t2, v2-v1} end)\n  %{s | data: deltas}\nend)"
  defp post_op_snippet({:moving_avg, w}), do: "\n# Moving average (window: #{w})\nseries = Enum.map(series, fn s ->\n  {ts, vs} = {Enum.map(s.data, &elem(&1,0)), Enum.map(s.data, &elem(&1,1))}\n  smoothed = vs |> Enum.chunk_every(#{w}, 1, :discard) |> Enum.map(&(Enum.sum(&1)/length(&1)))\n  %{s | data: Enum.zip(Enum.drop(ts, #{w - 1}), smoothed)}\nend)"

  defp transform_snippet_line(nil), do: ""
  defp transform_snippet_line({:multiply, n}), do: "\nseries = Enum.map(series, &Map.update!(&1, :data, fn d -> Timeless.Transform.apply(d, {:multiply, #{n}}) end))"
  defp transform_snippet_line({:divide, n}), do: "\nseries = Enum.map(series, &Map.update!(&1, :data, fn d -> Timeless.Transform.apply(d, {:divide, #{n}}) end))"
  defp transform_snippet_line({:offset, n}), do: "\nseries = Enum.map(series, &Map.update!(&1, :data, fn d -> Timeless.Transform.apply(d, {:offset, #{n}}) end))"
  defp transform_snippet_line({:log10}), do: "\nseries = Enum.map(series, &Map.update!(&1, :data, fn d -> Timeless.Transform.apply(d, {:log10}) end))"
  defp transform_snippet_line({:scale, m, b}), do: "\nseries = Enum.map(series, &Map.update!(&1, :data, fn d -> Timeless.Transform.apply(d, {:scale, #{m}, #{b}}) end))"

  defp transform_snippet_opt(nil), do: ""
  defp transform_snippet_opt({:multiply, n}), do: ",\n    transform: {:multiply, #{n}}"
  defp transform_snippet_opt({:divide, n}), do: ",\n    transform: {:divide, #{n}}"
  defp transform_snippet_opt({:offset, n}), do: ",\n    transform: {:offset, #{n}}"
  defp transform_snippet_opt({:log10}), do: ",\n    transform: {:log10}"
  defp transform_snippet_opt({:scale, m, b}), do: ",\n    transform: {:scale, #{m}, #{b}}"

  defp img_transform_param(nil), do: ""
  defp img_transform_param({:multiply, n}), do: "&transform=multiply:#{n}"
  defp img_transform_param({:divide, n}), do: "&transform=divide:#{n}"
  defp img_transform_param({:offset, n}), do: "&transform=offset:#{n}"
  defp img_transform_param({:log10}), do: "&transform=log10"
  defp img_transform_param({:scale, m, b}), do: "&transform=scale:#{m}:#{b}"

  defp build_chart_data(title, series, chart_opts) do
    series_data =
      Enum.map(series, fn s ->
        sorted = Enum.sort_by(s.data, &elem(&1, 0))
        label = s.labels |> Map.values() |> Enum.join(", ")

        %{
          label: if(label == "", do: title, else: label),
          timestamps: Enum.map(sorted, fn {ts, _v} -> ts end),
          values: Enum.map(sorted, fn {_ts, v} -> v end)
        }
      end)

    forecast =
      case Keyword.get(chart_opts, :forecast, []) do
        [] ->
          nil

        points ->
          sorted = Enum.sort_by(points, &elem(&1, 0))

          %{
            timestamps: Enum.map(sorted, fn {ts, _} -> ts end),
            values: Enum.map(sorted, fn {_, v} -> v end)
          }
      end

    anomalies =
      case Keyword.get(chart_opts, :anomalies, []) do
        [] ->
          nil

        points ->
          %{
            timestamps: Enum.map(points, fn {ts, _} -> ts end),
            values: Enum.map(points, fn {_, v} -> v end)
          }
      end

    Jason.encode!(%{title: title, series: series_data, forecast: forecast, anomalies: anomalies})
  end

  defp parse_transform(%{"transform" => "none"}), do: {nil, nil}
  defp parse_transform(%{"transform" => "rate"}), do: {nil, :rate}
  defp parse_transform(%{"transform" => "nn_rate"}), do: {nil, :nn_rate}
  defp parse_transform(%{"transform" => "delta"}), do: {nil, :delta}
  defp parse_transform(%{"transform" => "moving_avg", "transform_arg1" => n}), do: {nil, {:moving_avg, max(round(parse_number(n)), 2)}}
  defp parse_transform(%{"transform" => "multiply", "transform_arg1" => n}), do: {{:multiply, parse_number(n)}, nil}
  defp parse_transform(%{"transform" => "divide", "transform_arg1" => n}), do: {{:divide, parse_number(n)}, nil}
  defp parse_transform(%{"transform" => "offset", "transform_arg1" => n}), do: {{:offset, parse_number(n)}, nil}
  defp parse_transform(%{"transform" => "log10"}), do: {{:log10}, nil}
  defp parse_transform(%{"transform" => "scale", "transform_arg1" => m, "transform_arg2" => b}),
    do: {{:scale, parse_number(m), parse_number(b)}, nil}
  defp parse_transform(_), do: {nil, nil}

  defp parse_number(s) when is_binary(s) do
    case Float.parse(s) do
      {f, _} -> f
      :error -> 1.0
    end
  end
  defp parse_number(_), do: 1.0

  defp apply_post_op(series, nil), do: series

  defp apply_post_op(series, :rate) do
    Enum.map(series, fn s ->
      sorted = Enum.sort_by(s.data, &elem(&1, 0))

      rated =
        sorted
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [{t1, v1}, {t2, v2}] ->
          dt = t2 - t1
          {t2, if(dt > 0, do: (v2 - v1) / dt, else: 0.0)}
        end)

      %{s | data: rated}
    end)
  end

  defp apply_post_op(series, :nn_rate) do
    Enum.map(series, fn s ->
      sorted = Enum.sort_by(s.data, &elem(&1, 0))

      rated =
        sorted
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [{t1, v1}, {t2, v2}] ->
          dt = t2 - t1
          rate = if(dt > 0, do: (v2 - v1) / dt, else: 0.0)
          {t2, max(rate, 0.0)}
        end)

      %{s | data: rated}
    end)
  end

  defp apply_post_op(series, :delta) do
    Enum.map(series, fn s ->
      sorted = Enum.sort_by(s.data, &elem(&1, 0))

      deltas =
        sorted
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [{_t1, v1}, {t2, v2}] ->
          {t2, v2 - v1}
        end)

      %{s | data: deltas}
    end)
  end

  defp apply_post_op(series, {:moving_avg, window}) do
    Enum.map(series, fn s ->
      sorted = Enum.sort_by(s.data, &elem(&1, 0))
      values = Enum.map(sorted, &elem(&1, 1))
      timestamps = Enum.map(sorted, &elem(&1, 0))

      smoothed =
        values
        |> Enum.chunk_every(window, 1, :discard)
        |> Enum.map(fn chunk -> Enum.sum(chunk) / length(chunk) end)

      # Moving average drops (window-1) points from the start
      drop = window - 1
      ts_trimmed = Enum.drop(timestamps, drop)

      Enum.zip(ts_trimmed, smoothed)
      |> then(fn data -> %{s | data: data} end)
    end)
  end

  defp format_us(us) when us >= 1_000_000, do: "#{Float.round(us / 1_000_000, 1)}s"
  defp format_us(us) when us >= 1_000, do: "#{Float.round(us / 1_000, 1)}ms"
  defp format_us(us), do: "#{us}us"

  defp parse_int(s, default) do
    case Integer.parse(s) do
      {i, _} -> i
      :error -> default
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_page={@active_page}>
      <.page_header title="Explorer">
        <:actions>
          <span class="text-xs text-base-content/50">Interactive query builder</span>
        </:actions>
      </.page_header>

      <%!-- Query Form --%>
      <div class="card bg-base-200 border border-base-300 p-4 mb-6">
        <form phx-change="update_form" phx-submit="query" class="space-y-3">
          <div class="grid grid-cols-1 sm:grid-cols-4 gap-3">
            <div>
              <label class="label label-text text-xs">Metric</label>
              <select name="metric" class="select select-sm select-bordered w-full" required>
                <option value="">Select metric...</option>
                <option :for={m <- @metrics} value={m} selected={@form["metric"] == m}>{m}</option>
              </select>
            </div>
            <div>
              <label class="label label-text text-xs">Time Range</label>
              <select name="range" class="select select-sm select-bordered w-full">
                <option
                  :for={r <- ["15m", "1h", "6h", "24h", "7d"]}
                  value={r}
                  selected={@form["range"] == r}
                >
                  {r}
                </option>
              </select>
            </div>
            <div>
              <label class="label label-text text-xs">Aggregate</label>
              <select name="aggregate" class="select select-sm select-bordered w-full">
                <option value="none" selected={@form["aggregate"] == "none"}>None (raw)</option>
                <option
                  :for={a <- ["avg", "min", "max", "sum", "count", "last", "first"]}
                  value={a}
                  selected={@form["aggregate"] == a}
                >
                  {a}
                </option>
              </select>
            </div>
            <div>
              <label class="label label-text text-xs">Bucket</label>
              <select
                name="bucket"
                class="select select-sm select-bordered w-full"
                disabled={@form["aggregate"] == "none"}
              >
                <option
                  :for={b <- ["minute", "hour", "day"]}
                  value={b}
                  selected={@form["bucket"] == b}
                >
                  {b}
                </option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-4 gap-3">
            <div>
              <label class="label label-text text-xs">Transform</label>
              <select name="transform" class="select select-sm select-bordered w-full">
                <option value="none" selected={@form["transform"] == "none"}>None</option>
                <option value="rate" selected={@form["transform"] == "rate"}>Rate (Δ/s)</option>
                <option value="nn_rate" selected={@form["transform"] == "nn_rate"}>Rate NN (Δ/s, ≥0)</option>
                <option value="delta" selected={@form["transform"] == "delta"}>Delta (Δ)</option>
                <option value="moving_avg" selected={@form["transform"] == "moving_avg"}>Moving Avg</option>
                <option value="multiply" selected={@form["transform"] == "multiply"}>Multiply (×n)</option>
                <option value="divide" selected={@form["transform"] == "divide"}>Divide (÷n)</option>
                <option value="offset" selected={@form["transform"] == "offset"}>Offset (+n)</option>
                <option value="scale" selected={@form["transform"] == "scale"}>Scale (m×x+b)</option>
                <option value="log10" selected={@form["transform"] == "log10"}>Log₁₀</option>
              </select>
            </div>
            <div :if={@form["transform"] == "moving_avg"}>
              <label class="label label-text text-xs">Window (points)</label>
              <input
                type="number"
                min="2"
                step="1"
                name="transform_arg1"
                value={if @form["transform_arg1"] == "", do: "5", else: @form["transform_arg1"]}
                class="input input-sm input-bordered w-full"
                placeholder="e.g. 5"
              />
            </div>
            <div :if={@form["transform"] in ["multiply", "divide", "offset"]}>
              <label class="label label-text text-xs">Value</label>
              <input
                type="number"
                step="any"
                name="transform_arg1"
                value={@form["transform_arg1"]}
                class="input input-sm input-bordered w-full"
                placeholder={
                  case @form["transform"] do
                    "multiply" -> "e.g. 100"
                    "divide" -> "e.g. 10"
                    "offset" -> "e.g. -273.15"
                    _ -> ""
                  end
                }
              />
            </div>
            <div :if={@form["transform"] == "scale"}>
              <label class="label label-text text-xs">Multiplier (m)</label>
              <input
                type="number"
                step="any"
                name="transform_arg1"
                value={@form["transform_arg1"]}
                class="input input-sm input-bordered w-full"
                placeholder="e.g. 1.8"
              />
            </div>
            <div :if={@form["transform"] == "scale"}>
              <label class="label label-text text-xs">Offset (b)</label>
              <input
                type="number"
                step="any"
                name="transform_arg2"
                value={@form["transform_arg2"]}
                class="input input-sm input-bordered w-full"
                placeholder="e.g. 32"
              />
            </div>
          </div>

          <%!-- Analysis Toggles --%>
          <div class="flex flex-wrap gap-4 items-center">
            <label class="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                class="checkbox checkbox-sm"
                checked={@forecast_enabled}
                phx-click="toggle_forecast"
              />
              <span class="text-sm">Forecast</span>
            </label>
            <input
              :if={@forecast_enabled}
              type="number"
              name="forecast_horizon"
              value={@forecast_horizon}
              class="input input-xs input-bordered w-24"
              placeholder="Horizon (pts)"
            />

            <label class="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                class="checkbox checkbox-sm"
                checked={@anomaly_enabled}
                phx-click="toggle_anomalies"
              />
              <span class="text-sm">Anomaly Detection</span>
            </label>
            <select
              :if={@anomaly_enabled}
              name="anomaly_sensitivity"
              class="select select-xs select-bordered"
            >
              <option
                :for={s <- ["low", "medium", "high"]}
                value={s}
                selected={@anomaly_sensitivity == s}
              >
                {s}
              </option>
            </select>

            <div class="ml-auto flex items-center gap-2">
              <button
                type="button"
                phx-click="toggle_chart_mode"
                class={[
                  "btn btn-sm btn-outline gap-1",
                  if(@chart_mode == "js", do: "btn-accent", else: "btn-secondary")
                ]}
              >
                <%= if @chart_mode == "js" do %>
                  <span class="text-xs font-mono">JS</span>
                <% else %>
                  <span class="text-xs font-mono">SVG</span>
                <% end %>
              </button>
              <button type="submit" class="btn btn-sm btn-primary">
                Run Query
              </button>
            </div>
          </div>
        </form>
      </div>

      <%!-- Timings --%>
      <div :if={@timings} class="flex flex-wrap gap-3 mb-3 text-xs">
        <span class="badge badge-sm badge-primary badge-outline">
          Query: {format_us(@timings.query_us)}
        </span>
        <span class="badge badge-sm badge-primary badge-outline">
          <%= if @chart_mode == "js" do %>
            Chart: client
          <% else %>
            Chart: {format_us(@timings.chart_us)}
          <% end %>
        </span>
        <span class="badge badge-sm badge-primary">
          <%= if @chart_mode == "js" do %>
            Total: {format_us(@timings.query_us)}+client
          <% else %>
            Total: {format_us(@timings.total_us)}
          <% end %>
        </span>
        <span class="text-base-content/50">
          {@timings.series_count} series, {@timings.total_points} points
        </span>
      </div>

      <%!-- Chart --%>
      <%= if @chart_mode == "js" do %>
        <div :if={@chart_data} class="card bg-base-200 border border-base-300 p-4 mb-6">
          <div id="uplot-chart" phx-hook=".UPlotChart" data-chart={@chart_data} phx-update="ignore"></div>
        </div>
      <% else %>
        <div :if={@chart_svg} class="card bg-base-200 border border-base-300 p-4 mb-6">
          <.chart svg={@chart_svg} />
        </div>
      <% end %>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".UPlotChart">
        const COLORS = ["#2563eb", "#dc2626", "#16a34a", "#d97706", "#7c3aed", "#0891b2", "#be185d", "#65a30d"];
        const FORECAST_COLOR = "#8b5cf6";
        const ANOMALY_COLOR = "#ef4444";

        function isDarkTheme() {
          return document.documentElement.getAttribute("data-theme") === "dark" ||
            (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches);
        }

        function renderChart(el, json) {
          const data = JSON.parse(json);
          const dark = isDarkTheme();

          const tsSet = new Set();
          data.series.forEach(s => s.timestamps.forEach(t => tsSet.add(t)));
          if (data.forecast) data.forecast.timestamps.forEach(t => tsSet.add(t));
          const allTs = Array.from(tsSet).sort((a, b) => a - b);

          const uData = [allTs];
          const uSeries = [{}];

          data.series.forEach((s, i) => {
            const lookup = new Map();
            s.timestamps.forEach((t, j) => lookup.set(t, s.values[j]));
            uData.push(allTs.map(t => lookup.has(t) ? lookup.get(t) : null));
            uSeries.push({
              label: s.label,
              stroke: COLORS[i % COLORS.length],
              width: 1.5,
              points: { show: allTs.length < 100, size: 4 },
            });
          });

          if (data.forecast && data.forecast.timestamps.length > 0) {
            const lookup = new Map();
            data.forecast.timestamps.forEach((t, j) => lookup.set(t, data.forecast.values[j]));
            uData.push(allTs.map(t => lookup.has(t) ? lookup.get(t) : null));
            uSeries.push({
              label: "Forecast",
              stroke: FORECAST_COLOR,
              width: 2,
              dash: [6, 3],
              points: { show: false },
            });
          }

          if (data.anomalies && data.anomalies.timestamps.length > 0) {
            const lookup = new Map();
            data.anomalies.timestamps.forEach((t, j) => lookup.set(t, data.anomalies.values[j]));
            uData.push(allTs.map(t => lookup.has(t) ? lookup.get(t) : null));
            uSeries.push({
              label: "Anomalies",
              stroke: ANOMALY_COLOR,
              fill: ANOMALY_COLOR + "40",
              width: 0,
              points: { show: true, size: 8, fill: ANOMALY_COLOR, stroke: "#ffffff" },
              paths: () => null,
            });
          }

          const width = el.parentElement ? el.parentElement.clientWidth - 32 : 800;

          const opts = {
            title: data.title,
            width: Math.max(width, 400),
            height: 300,
            cursor: { show: true, drag: { x: true, y: false } },
            scales: { x: { time: true } },
            axes: [
              {
                stroke: dark ? "#e5e7eb" : "#374151",
                grid: { stroke: dark ? "#374151" : "#e5e7eb", width: 1 },
                ticks: { stroke: dark ? "#374151" : "#e5e7eb" },
              },
              {
                stroke: dark ? "#e5e7eb" : "#374151",
                grid: { stroke: dark ? "#374151" : "#e5e7eb", width: 1 },
                ticks: { stroke: dark ? "#374151" : "#e5e7eb" },
              },
            ],
            series: uSeries,
          };

          return new window.uPlot(opts, uData, el);
        }

        function rebuild(hook, json) {
          if (hook._chart) { hook._chart.destroy(); hook._chart = null; }
          hook.el.innerHTML = "";
          hook._json = json;
          hook._chart = renderChart(hook.el, json);
        }

        export default {
          mounted() {
            const initial = this.el.getAttribute("data-chart");
            if (initial) rebuild(this, initial);

            this.handleEvent("uplot-data", ({ json }) => rebuild(this, json));

            this._ro = new ResizeObserver(() => {
              if (this._chart && this._json) {
                const w = this.el.parentElement ? this.el.parentElement.clientWidth - 32 : 800;
                this._chart.setSize({ width: Math.max(w, 400), height: 300 });
              }
            });
            this._ro.observe(this.el.parentElement || this.el);
          },
          destroyed() {
            if (this._ro) { this._ro.disconnect(); this._ro = null; }
            if (this._chart) { this._chart.destroy(); this._chart = null; }
          },
        };
      </script>

      <%!-- Results Table --%>
      <div :if={@results} class="card bg-base-200 border border-base-300 p-4 mb-6">
        <h3 class="text-sm font-semibold mb-3">Results Summary</h3>
        <div class="overflow-x-auto">
          <table class="table table-sm">
            <thead>
              <tr>
                <th>Labels</th>
                <th>Points</th>
                <th>Min</th>
                <th>Max</th>
                <th>Latest</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={row <- @results}>
                <td class="text-xs">
                  <span :for={{k, v} <- row.labels} class="inline-block mr-2">
                    <span class="text-base-content/60">{k}=</span>{v}
                  </span>
                </td>
                <td>{row.point_count}</td>
                <td>{format_value(row.min)}</td>
                <td>{format_value(row.max)}</td>
                <td>{format_value(row.latest)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <%!-- Code Snippet --%>
      <div :if={@code_snippet} class="card bg-base-200 border border-base-300 p-4">
        <h3 class="text-sm font-semibold mb-2">Equivalent Elixir Code</h3>
        <pre class="bg-base-300 rounded-lg p-3 text-xs overflow-x-auto"><code>{@code_snippet}</code></pre>
      </div>
    </Layouts.app>
    """
  end
end
