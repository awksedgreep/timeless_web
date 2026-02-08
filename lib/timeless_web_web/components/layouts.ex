defmodule TimelessWebWeb.Layouts do
  @moduledoc """
  Layouts and related functionality.
  """
  use TimelessWebWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  attr :active_page, :atom, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden bg-base-100">
      <aside class="w-64 flex-shrink-0 bg-base-200 border-r border-base-300 flex flex-col">
        <div class="p-4 border-b border-base-300">
          <a href={~p"/timeless"} class="flex items-center gap-2">
            <span class="text-xl font-bold text-primary">Timeless</span>
          </a>
          <p class="text-xs text-base-content/60 mt-1">Metrics Admin</p>
        </div>

        <nav class="flex-1 p-3 space-y-1 overflow-y-auto">
          <.nav_link
            href={~p"/timeless"}
            icon="hero-chart-bar-square"
            label="Dashboard"
            active={@active_page == :dashboard}
          />
          <.nav_link
            href={~p"/timeless/metrics"}
            icon="hero-chart-bar"
            label="Metrics"
            active={@active_page == :metrics}
          />
          <.nav_link
            href={~p"/timeless/explorer"}
            icon="hero-magnifying-glass"
            label="Explorer"
            active={@active_page == :explorer}
          />
          <.nav_link
            href={~p"/timeless/alerts"}
            icon="hero-bell-alert"
            label="Alerts"
            active={@active_page == :alerts}
          />
          <.nav_link
            href={~p"/timeless/annotations"}
            icon="hero-tag"
            label="Annotations"
            active={@active_page == :annotations}
          />
          <.nav_link
            href={~p"/timeless/schema"}
            icon="hero-cog-6-tooth"
            label="Schema"
            active={@active_page == :schema}
          />
          <.nav_link
            href={~p"/timeless/health"}
            icon="hero-heart"
            label="Health"
            active={@active_page == :health}
          />
        </nav>

        <div class="p-3 border-t border-base-300">
          <.theme_toggle />
        </div>
      </aside>

      <main class="flex-1 overflow-y-auto">
        <div class="p-6">
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false

  defp nav_link(assigns) do
    ~H"""
    <a
      href={@href}
      class={[
        "flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors",
        if(@active,
          do: "bg-primary text-primary-content",
          else: "text-base-content/70 hover:bg-base-300 hover:text-base-content"
        )
      ]}
    >
      <.icon name={@icon} class="size-5" />
      {@label}
    </a>
    """
  end

  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
