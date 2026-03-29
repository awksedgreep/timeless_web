defmodule TimelessWebWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use TimelessWebWeb, :html

  @doc """
  Renders the shared site shell used by the app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.shell flash={@flash}>
        <h1>Content</h1>
      </Layouts.shell>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def shell(assigns) do
    ~H"""
    <div class="site-frame">
      <header class="site-header">
        <.link navigate={~p"/"} class="brand-mark" aria-label="Timeless home">
          <img src={~p"/images/logo-light.svg"} alt="Timeless" class="brand-logo brand-logo-light" />
          <img src={~p"/images/logo-dark.svg"} alt="Timeless" class="brand-logo brand-logo-dark" />
        </.link>

        <nav class="site-nav" aria-label="Primary">
          <.link navigate={~p"/projects"}>Projects</.link>
          <.link navigate={~p"/blog"}>Blog</.link>
          <.link navigate={~p"/dashboard"}>Dashboard</.link>
          <%= if @current_scope do %>
            <.link navigate={~p"/chat"}>Chat</.link>
          <% end %>
          <%= if @current_scope && @current_scope.user && @current_scope.user.is_admin do %>
            <.link navigate={~p"/admin"}>Admin</.link>
          <% end %>
        </nav>

        <div class="site-actions">
          <.theme_toggle />
          <%= if @current_scope do %>
            <span class="user-chip">{@current_scope.user.email}</span>
            <.link navigate={~p"/users/settings"} class="button-link button-link-secondary">
              Settings
            </.link>
            <.link href={~p"/users/log-out"} method="delete" class="button-link button-link-secondary">
              Log out
            </.link>
          <% else %>
            <.link navigate={~p"/users/log-in"} class="button-link button-link-secondary">
              Log in
            </.link>
            <.link navigate={~p"/users/register"} class="button-link">
              Join chat
            </.link>
          <% end %>
        </div>
      </header>

      <main>
        {render_slot(@inner_block)}
      </main>

      <footer class="site-footer">
        <div>
          <p class="footer-label">Built with Timeless</p>
          <p>Public docs and product context in front. Real dashboard running behind it.</p>
        </div>
        <div class="footer-links">
          <a
            href="https://github.com/awksedgreep/timeless_phoenix"
            target="_blank"
            rel="noopener noreferrer"
          >
            GitHub
          </a>
          <a href="https://hexdocs.pm/timeless_phoenix" target="_blank" rel="noopener noreferrer">
            Docs
          </a>
          <.link navigate={~p"/projects"}>Projects</.link>
          <.link navigate={~p"/blog"}>Blog</.link>
        </div>
      </footer>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

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

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="theme-toggle">
      <button
        class="theme-toggle-button"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4" />
      </button>

      <button
        class="theme-toggle-button"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4" />
      </button>

      <button
        class="theme-toggle-button"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4" />
      </button>
    </div>
    """
  end

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"
end
