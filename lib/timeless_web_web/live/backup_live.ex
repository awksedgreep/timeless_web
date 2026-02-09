defmodule TimelessWebWeb.BackupLive do
  use TimelessWebWeb, :live_view

  import TimelessWebWeb.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TimelessWeb.PubSub, TimelessWeb.StoreWatcher.topic())
    end

    socket =
      socket
      |> assign(
        active_page: :backup,
        action_loading: nil,
        action_result: nil,
        backups: []
      )
      |> load_backups()

    {:ok, socket}
  end

  @impl true
  def handle_info({:store_updated, _info}, %{assigns: %{action_loading: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_info({:store_updated, _info}, socket) do
    {:noreply, socket}
  end

  def handle_info({:run_action, :create_backup}, socket) do
    timestamp = Calendar.strftime(DateTime.utc_now(), "%Y-%m-%d_%H%M%S")
    target_dir = Path.join(backup_base_dir(), timestamp)

    message =
      try do
        {:ok, %{files: files, total_bytes: total_bytes}} = Timeless.backup(store(), target_dir)
        "Backup created: #{length(files)} files, #{format_bytes(total_bytes)}"
      rescue
        e -> "Backup failed: #{Exception.message(e)}"
      end

    {:noreply,
     socket
     |> assign(action_loading: nil, action_result: message)
     |> load_backups()}
  end

  def handle_info({:run_action, {:delete_backup, name}}, socket) do
    path = Path.join(backup_base_dir(), name)

    message =
      case File.rm_rf(path) do
        {:ok, _} -> "Backup \"#{name}\" deleted"
        {:error, reason, _} -> "Delete failed: #{inspect(reason)}"
      end

    {:noreply,
     socket
     |> assign(action_loading: nil, action_result: message)
     |> load_backups()}
  end

  @impl true
  def handle_event("create_backup", _params, socket) do
    send(self(), {:run_action, :create_backup})
    {:noreply, assign(socket, action_loading: :create_backup, action_result: nil)}
  end

  def handle_event("delete_backup", %{"name" => name}, socket) do
    send(self(), {:run_action, {:delete_backup, name}})
    {:noreply, assign(socket, action_loading: {:delete_backup, name}, action_result: nil)}
  end

  def handle_event("dismiss_result", _params, socket) do
    {:noreply, assign(socket, action_result: nil)}
  end

  defp store do
    Application.get_env(:timeless_web, :timeless_store, :metrics)
  end

  defp backup_base_dir do
    data_dir = Application.get_env(:timeless_web, :timeless_data_dir, "/tmp/timeless_dev")
    Path.join(data_dir, "backups")
  end

  defp load_backups(socket) do
    base = backup_base_dir()

    backups =
      case File.ls(base) do
        {:ok, entries} ->
          entries
          |> Enum.sort(:desc)
          |> Enum.map(fn name ->
            path = Path.join(base, name)

            case File.stat(path) do
              {:ok, %{type: :directory}} ->
                files = File.ls!(path)
                file_count = length(files)

                total_bytes =
                  files
                  |> Enum.reduce(0, fn f, acc ->
                    case File.stat(Path.join(path, f)) do
                      {:ok, %{size: size}} -> acc + size
                      _ -> acc
                    end
                  end)

                %{name: name, file_count: file_count, total_bytes: total_bytes}

              _ ->
                nil
            end
          end)
          |> Enum.reject(&is_nil/1)

        {:error, :enoent} ->
          []
      end

    assign(socket, backups: backups)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_page={@active_page}>
      <.page_header title="Backup">
        <:actions>
          <button
            class="btn btn-sm btn-primary"
            phx-click="create_backup"
            disabled={@action_loading != nil}
          >
            <span :if={@action_loading == :create_backup} class="loading loading-spinner loading-xs" />
            Create Backup
          </button>
        </:actions>
      </.page_header>

      <%!-- Action Result Banner --%>
      <div :if={@action_result} class="alert alert-info mb-4">
        <span>{@action_result}</span>
        <button class="btn btn-ghost btn-xs" phx-click="dismiss_result">Dismiss</button>
      </div>

      <%!-- Backups Table --%>
      <div :if={@backups != []} class="overflow-x-auto">
        <table class="table table-sm">
          <thead>
            <tr>
              <th>Timestamp</th>
              <th>Files</th>
              <th>Size</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={backup <- @backups}>
              <td class="font-medium">{backup.name}</td>
              <td>{backup.file_count}</td>
              <td>{format_bytes(backup.total_bytes)}</td>
              <td class="flex gap-2">
                <a
                  href={~p"/timeless/backup/download/#{backup.name}"}
                  download
                  class="btn btn-xs btn-outline"
                >
                  <.icon name="hero-arrow-down-tray" class="size-3" /> Download
                </a>
                <button
                  class="btn btn-xs btn-outline btn-error"
                  phx-click="delete_backup"
                  phx-value-name={backup.name}
                  disabled={@action_loading != nil}
                >
                  <span
                    :if={@action_loading == {:delete_backup, backup.name}}
                    class="loading loading-spinner loading-xs"
                  />
                  <.icon name="hero-trash" class="size-3" /> Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div :if={@backups == []} class="text-center py-12 text-base-content/50">
        <.icon name="hero-archive-box" class="size-12 mx-auto mb-3 opacity-50" />
        <p>No backups yet. Click "Create Backup" to get started.</p>
      </div>
    </Layouts.app>
    """
  end
end
