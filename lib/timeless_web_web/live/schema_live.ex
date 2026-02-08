defmodule TimelessWebWeb.SchemaLive do
  use TimelessWebWeb, :live_view

  import TimelessWebWeb.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    schema = Timeless.get_schema(store())

    {:ok,
     assign(socket,
       active_page: :schema,
       schema: schema
     )}
  end

  defp store do
    Application.get_env(:timeless_web, :timeless_store, :metrics)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_page={@active_page}>
      <.page_header title="Schema">
        <:actions>
          <span class="text-xs text-base-content/50">Read-only configuration</span>
        </:actions>
      </.page_header>

      <%!-- Stat Cards --%>
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <.stat_card
          title="Raw Retention"
          value={format_duration(@schema.raw_retention_seconds)}
          subtitle="How long raw data is kept"
        />
        <.stat_card
          title="Rollup Interval"
          value={format_duration_ms(@schema.rollup_interval)}
          subtitle="Time between rollup runs"
        />
        <.stat_card
          title="Retention Interval"
          value={format_duration_ms(@schema.retention_interval)}
          subtitle="Time between retention checks"
        />
      </div>

      <%!-- Tier Cards --%>
      <h2 class="text-lg font-semibold mb-3">Storage Tiers</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div :for={tier <- @schema.tiers} class="card bg-base-200 border border-base-300 p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="text-base font-bold">{tier.name}</h3>
            <span class="badge badge-sm badge-neutral">{tier.table_name}</span>
          </div>

          <div class="grid grid-cols-2 gap-2 text-sm mb-3">
            <div>
              <span class="text-base-content/60">Resolution</span>
              <p class="font-medium">{format_duration(tier.resolution_seconds)}</p>
            </div>
            <div>
              <span class="text-base-content/60">Retention</span>
              <p class="font-medium">{format_duration(tier.retention_seconds)}</p>
            </div>
          </div>

          <div>
            <span class="text-xs text-base-content/60">Aggregates</span>
            <div class="flex flex-wrap gap-1 mt-1">
              <span :for={agg <- tier.aggregates} class="badge badge-xs badge-primary badge-outline">
                {agg}
              </span>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
