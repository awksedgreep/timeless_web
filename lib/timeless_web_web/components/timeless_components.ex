defmodule TimelessWebWeb.TimelessComponents do
  @moduledoc """
  Shared UI components for the Timeless admin panel.
  """
  use Phoenix.Component

  attr :title, :string, required: true
  attr :value, :string, required: true
  attr :subtitle, :string, default: nil
  attr :class, :string, default: nil

  def stat_card(assigns) do
    ~H"""
    <div class={["card bg-base-200 border border-base-300 p-4", @class]}>
      <p class="text-xs font-medium text-base-content/60 uppercase tracking-wide">{@title}</p>
      <p class="text-2xl font-bold mt-1">{@value}</p>
      <p :if={@subtitle} class="text-xs text-base-content/50 mt-1">{@subtitle}</p>
    </div>
    """
  end

  attr :svg, :string, required: true

  def chart(assigns) do
    ~H"""
    <div class="w-full overflow-x-auto [&>svg]:max-w-[800px] [&>svg]:w-full [&>svg]:h-auto [&>svg]:mx-auto">
      {Phoenix.HTML.raw(@svg)}
    </div>
    """
  end

  attr :status, :string, required: true

  def badge(assigns) do
    color =
      case assigns.status do
        "ok" -> "badge-success"
        "pending" -> "badge-warning"
        "firing" -> "badge-error"
        "resolved" -> "badge-info"
        _ -> "badge-neutral"
      end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={["badge badge-sm", @color]}>{@status}</span>
    """
  end

  attr :title, :string, required: true
  slot :actions

  def page_header(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold">{@title}</h1>
      <div :if={@actions != []} class="flex items-center gap-2">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end
end
