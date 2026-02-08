defmodule TimelessWebWeb.AnnotationsLive do
  use TimelessWebWeb, :live_view

  import TimelessWebWeb.FormatHelpers

  @impl true
  def mount(_params, _session, socket) do
    now = System.os_time(:second)

    {:ok,
     socket
     |> assign(
       active_page: :annotations,
       range: "24h",
       tag_filter: "",
       show_create_form: false,
       form: default_form(),
       confirm_delete: nil
     )
     |> load_annotations(now - 86_400, now)}
  end

  @impl true
  def handle_event("filter", %{"range" => range, "tags" => tags}, socket) do
    {from, to} = range_to_timestamps(range)

    socket =
      socket
      |> assign(range: range, tag_filter: tags)
      |> load_annotations(from, to, parse_tags(tags))

    {:noreply, socket}
  end

  def handle_event("toggle_create_form", _params, socket) do
    {:noreply,
     assign(socket, show_create_form: !socket.assigns.show_create_form, form: default_form())}
  end

  def handle_event("validate_annotation", %{"annotation" => params}, socket) do
    {:noreply, assign(socket, form: params)}
  end

  def handle_event("create_annotation", %{"annotation" => params}, socket) do
    timestamp =
      case params["timestamp_mode"] do
        "now" -> System.os_time(:second)
        "custom" -> parse_custom_timestamp(params["custom_timestamp"])
      end

    tags =
      params["tags"]
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)

    opts = [description: params["description"], tags: tags]

    {:ok, _} = Timeless.annotate(store(), timestamp, params["title"], opts)

    {from, to} = range_to_timestamps(socket.assigns.range)
    tags_filter = parse_tags(socket.assigns.tag_filter)

    {:noreply,
     socket
     |> assign(show_create_form: false, form: default_form())
     |> load_annotations(from, to, tags_filter)
     |> put_flash(:info, "Annotation created")}
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, confirm_delete: id)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, confirm_delete: nil)}
  end

  def handle_event("delete_annotation", %{"id" => id}, socket) do
    :ok = Timeless.delete_annotation(store(), id)

    {from, to} = range_to_timestamps(socket.assigns.range)
    tags_filter = parse_tags(socket.assigns.tag_filter)

    {:noreply,
     socket
     |> assign(confirm_delete: nil)
     |> load_annotations(from, to, tags_filter)
     |> put_flash(:info, "Annotation deleted")}
  end

  defp store do
    Application.get_env(:timeless_web, :timeless_store, :metrics)
  end

  defp load_annotations(socket, from, to, tags \\ []) do
    opts = if tags != [], do: [tags: tags], else: []
    {:ok, annotations} = Timeless.annotations(store(), from, to, opts)
    assign(socket, annotations: annotations)
  end

  defp default_form do
    %{
      "title" => "",
      "description" => "",
      "tags" => "",
      "timestamp_mode" => "now",
      "custom_timestamp" => ""
    }
  end

  defp range_to_timestamps(range) do
    now = System.os_time(:second)

    seconds =
      case range do
        "1h" -> 3_600
        "6h" -> 21_600
        "24h" -> 86_400
        "7d" -> 604_800
        "30d" -> 2_592_000
        _ -> 86_400
      end

    {now - seconds, now}
  end

  defp parse_tags(""), do: []

  defp parse_tags(tags) do
    tags |> String.split(",", trim: true) |> Enum.map(&String.trim/1)
  end

  defp parse_custom_timestamp(""), do: System.os_time(:second)

  defp parse_custom_timestamp(ts_string) do
    case Integer.parse(ts_string) do
      {ts, _} -> ts
      :error -> System.os_time(:second)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} active_page={@active_page}>
      <.page_header title="Annotations">
        <:actions>
          <button class="btn btn-sm btn-primary" phx-click="toggle_create_form">
            {if @show_create_form, do: "Cancel", else: "New Annotation"}
          </button>
        </:actions>
      </.page_header>

      <%!-- Create Form --%>
      <div :if={@show_create_form} class="card bg-base-200 border border-base-300 p-4 mb-6">
        <h3 class="text-sm font-semibold mb-3">Create Annotation</h3>
        <form phx-submit="create_annotation" phx-change="validate_annotation" class="space-y-3">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label class="label label-text text-xs">Title</label>
              <input
                type="text"
                name="annotation[title]"
                value={@form["title"]}
                required
                class="input input-sm input-bordered w-full"
                placeholder="Deployment v1.2.3"
              />
            </div>
            <div>
              <label class="label label-text text-xs">Timestamp</label>
              <div class="flex gap-2">
                <select name="annotation[timestamp_mode]" class="select select-sm select-bordered">
                  <option value="now" selected={@form["timestamp_mode"] == "now"}>Now</option>
                  <option value="custom" selected={@form["timestamp_mode"] == "custom"}>
                    Custom
                  </option>
                </select>
                <input
                  :if={@form["timestamp_mode"] == "custom"}
                  type="text"
                  name="annotation[custom_timestamp]"
                  value={@form["custom_timestamp"]}
                  class="input input-sm input-bordered flex-1"
                  placeholder="Unix timestamp"
                />
              </div>
            </div>
          </div>
          <div>
            <label class="label label-text text-xs">Description</label>
            <textarea
              name="annotation[description]"
              class="textarea textarea-sm textarea-bordered w-full"
              rows="2"
              placeholder="Optional description"
            >{@form["description"]}</textarea>
          </div>
          <div>
            <label class="label label-text text-xs">Tags (comma-separated)</label>
            <input
              type="text"
              name="annotation[tags]"
              value={@form["tags"]}
              class="input input-sm input-bordered w-full"
              placeholder="deploy, production"
            />
          </div>
          <button type="submit" class="btn btn-sm btn-primary">Create</button>
        </form>
      </div>

      <%!-- Filters --%>
      <form phx-change="filter" class="flex gap-3 mb-4 items-end">
        <div>
          <label class="label label-text text-xs">Time Range</label>
          <select name="range" class="select select-sm select-bordered">
            <option :for={r <- ["1h", "6h", "24h", "7d", "30d"]} value={r} selected={r == @range}>
              {r}
            </option>
          </select>
        </div>
        <div class="flex-1">
          <label class="label label-text text-xs">Filter Tags</label>
          <input
            type="text"
            name="tags"
            value={@tag_filter}
            class="input input-sm input-bordered w-full"
            placeholder="deploy, incident"
            phx-debounce="300"
          />
        </div>
      </form>

      <%!-- Annotations List --%>
      <div :if={@annotations == []} class="card bg-base-200 border border-base-300 p-8 text-center">
        <p class="text-base-content/50">No annotations in this time range</p>
      </div>

      <div :if={@annotations != []} class="space-y-2">
        <div :for={ann <- @annotations} class="card bg-base-200 border border-base-300 p-4">
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <div class="flex items-center gap-2">
                <span class="font-medium">{ann.title}</span>
                <span class="text-xs text-base-content/50">{format_timestamp(ann.timestamp)}</span>
              </div>
              <p :if={ann[:description]} class="text-sm text-base-content/60 mt-1">
                {ann.description}
              </p>
              <div :if={ann[:tags] && ann.tags != []} class="flex gap-1 mt-2">
                <span :for={tag <- ann.tags} class="badge badge-xs badge-neutral">{tag}</span>
              </div>
            </div>
            <div class="ml-4">
              <button
                :if={@confirm_delete != ann.id}
                class="btn btn-xs btn-ghost text-error"
                phx-click="confirm_delete"
                phx-value-id={ann.id}
              >
                Delete
              </button>
              <div :if={@confirm_delete == ann.id} class="flex gap-1">
                <button
                  class="btn btn-xs btn-error"
                  phx-click="delete_annotation"
                  phx-value-id={ann.id}
                >
                  Confirm
                </button>
                <button class="btn btn-xs btn-ghost" phx-click="cancel_delete">
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
