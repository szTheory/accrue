defmodule AccrueAdmin.Components.DataTable do
  @moduledoc """
  Shared stateful list primitive for admin pages.
  """

  use Phoenix.LiveComponent

  @default_limit 25
  @default_dom_limit 100

  @impl true
  def update(assigns, socket) do
    params = Map.get(assigns, :params, %{})
    params_signature = signature(params)
    action = Map.get(assigns, :action, :sync)

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:selected_ids, fn -> MapSet.new() end)
      |> assign_new(:filter_fields, fn -> [] end)
      |> assign_new(:card_fields, fn -> [] end)
      |> assign_new(:card_title, fn -> nil end)
      |> assign_new(:empty_title, fn -> "No rows found" end)
      |> assign_new(:empty_copy, fn -> "Adjust the filters or wait for new activity." end)
      |> assign_new(:cursor_field, fn -> :inserted_at end)
      |> assign_new(:row_id, fn -> :id end)
      |> assign_new(:selectable, fn -> true end)
      |> assign_new(:enable_polling, fn -> true end)
      |> assign_new(:poll_interval_ms, fn -> 5_000 end)
      |> assign_new(:newer_count, fn -> 0 end)
      |> assign(:limit, normalize_positive(Map.get(assigns, :limit, @default_limit), @default_limit))
      |> assign(
        :dom_limit,
        normalize_positive(Map.get(assigns, :dom_limit, @default_dom_limit), @default_dom_limit)
      )

    socket =
      cond do
        action == :poll ->
          poll_newer(socket)

        socket.assigns[:params_signature] != params_signature ->
          reload(socket, params, reset_selection?: false, params_signature: params_signature)

        true ->
          socket
      end

    {:ok, maybe_schedule_poll(socket)}
  end

  @impl true
  def handle_event("load-more", _params, socket) do
    if is_nil(socket.assigns.next_cursor) do
      {:noreply, socket}
    else
      query_opts = [filter: socket.assigns.filter, cursor: socket.assigns.next_cursor, limit: socket.assigns.limit]
      {rows, next_cursor} = socket.assigns.query_module.list(query_opts)

      merged_rows =
        socket.assigns.rows
        |> Kernel.++(rows)
        |> Enum.take(socket.assigns.dom_limit)

      {:noreply,
       socket
       |> assign(:rows, merged_rows)
       |> assign(:next_cursor, next_cursor)
       |> prune_selected_ids()}
    end
  end

  def handle_event("toggle-row", %{"id" => row_id}, socket) do
    {:noreply, assign(socket, :selected_ids, toggle_id(socket.assigns.selected_ids, row_id))}
  end

  def handle_event("toggle-all", _params, socket) do
    visible_ids = visible_row_ids(socket)

    selected_ids =
      if all_visible_selected?(socket) do
        Enum.reduce(visible_ids, socket.assigns.selected_ids, &MapSet.delete(&2, &1))
      else
        Enum.reduce(visible_ids, socket.assigns.selected_ids, &MapSet.put(&2, &1))
      end

    {:noreply, assign(socket, :selected_ids, selected_ids)}
  end

  def handle_event("load-newer", _params, socket) do
    {:noreply,
     socket
     |> reload(socket.assigns.params, reset_selection?: false, params_signature: socket.assigns.params_signature)
     |> assign(:newer_count, 0)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section id={@id} class="ax-data-table" data-role="data-table">
      <header class="ax-data-table-header">
        <form action={@path} method="get" class="ax-data-table-filters" data-role="filter-form">
          <div :for={field <- @filter_fields} class="ax-data-table-filter">
            <label for={field_id(@id, field)} class="ax-label"><%= field_label(field) %></label>
            <.filter_input id={field_id(@id, field)} field={field} value={Map.get(@filter_params, field_param(field))} />
          </div>
          <div :for={{key, value} <- @filter_params} :if={!field_defined?(@filter_fields, key)}>
            <input type="hidden" name={key} value={value} />
          </div>
          <button type="submit" class="ax-button ax-button-primary">Apply filters</button>
          <a href={@path} class="ax-button ax-button-ghost">Clear</a>
        </form>
      </header>

      <div
        :if={@newer_count > 0}
        class="ax-card ax-data-table-poll-banner"
        data-role="poll-banner"
        data-poll-ms={@poll_interval_ms}
      >
        <p class="ax-body"><%= "#{@newer_count} new rows - click to load" %></p>
        <button
          type="button"
          phx-click="load-newer"
          phx-target={@myself}
          class="ax-button ax-button-secondary"
          data-role="load-newer"
        >
          Load newer rows
        </button>
      </div>

      <div :if={Enum.empty?(@rows)} class="ax-card ax-data-table-empty" data-role="empty-state">
        <p class="ax-heading"><%= @empty_title %></p>
        <p class="ax-body"><%= @empty_copy %></p>
      </div>

      <div :if={!Enum.empty?(@rows) and @selectable} class="ax-data-table-selection" data-role="selection-bar">
        <p class="ax-body" data-role="selected-count"><%= "#{MapSet.size(@selected_ids)} selected" %></p>
        <button
          type="button"
          phx-click="toggle-all"
          phx-target={@myself}
          class="ax-button ax-button-ghost"
          data-role="toggle-all"
        >
          <%= if all_visible_selected?(assigns), do: "Clear visible", else: "Select visible" %>
        </button>
      </div>

      <div :if={!Enum.empty?(@rows)} class="ax-card ax-data-table-shell">
        <table class="ax-data-table-grid">
          <thead>
            <tr>
              <th :if={@selectable} scope="col" class="ax-label">Select</th>
              <th :for={column <- @columns} scope="col" class="ax-label"><%= column_label(column) %></th>
            </tr>
          </thead>
          <tbody>
            <tr :for={row <- @rows} id={row_dom_id(@id, row, @row_id)} data-row-id={row_identity(row, @row_id)}>
              <td :if={@selectable}>
                <button
                  type="button"
                  phx-click="toggle-row"
                  phx-value-id={row_identity(row, @row_id)}
                  phx-target={@myself}
                  class="ax-button ax-button-ghost"
                  data-role="toggle-row"
                  data-row-id={row_identity(row, @row_id)}
                  aria-pressed={selected?(@selected_ids, row_identity(row, @row_id))}
                >
                  <%= if selected?(@selected_ids, row_identity(row, @row_id)), do: "Selected", else: "Select" %>
                </button>
              </td>
              <td :for={column <- @columns}><%= cell_value(column, row) %></td>
            </tr>
          </tbody>
        </table>
      </div>

      <div :if={!Enum.empty?(@rows)} class="ax-data-table-cards" data-role="card-list">
        <article :for={row <- @rows} class="ax-card ax-data-table-card" data-row-id={row_identity(row, @row_id)}>
          <header class="ax-data-table-card-header">
            <div>
              <p class="ax-eyebrow">Row</p>
              <p class="ax-heading"><%= card_title(@card_title, row, @columns) %></p>
            </div>
            <button
              :if={@selectable}
              type="button"
              phx-click="toggle-row"
              phx-value-id={row_identity(row, @row_id)}
              phx-target={@myself}
              class="ax-button ax-button-ghost"
              data-role="toggle-row"
              data-row-id={row_identity(row, @row_id)}
              aria-pressed={selected?(@selected_ids, row_identity(row, @row_id))}
            >
              <%= if selected?(@selected_ids, row_identity(row, @row_id)), do: "Selected", else: "Select" %>
            </button>
          </header>

          <dl class="ax-data-table-card-fields">
            <div :for={field <- card_fields(@card_fields, @columns)} class="ax-data-table-card-field">
              <dt class="ax-label"><%= column_label(field) %></dt>
              <dd class="ax-body"><%= cell_value(field, row) %></dd>
            </div>
          </dl>
        </article>
      </div>

      <footer :if={!Enum.empty?(@rows)} class="ax-data-table-footer">
        <p class="ax-body" data-role="row-count"><%= "#{length(@rows)} rows loaded" %></p>
        <button
          :if={@next_cursor}
          type="button"
          phx-click="load-more"
          phx-target={@myself}
          class="ax-button ax-button-secondary"
          data-role="load-more"
        >
          Load more
        </button>
      </footer>
    </section>
    """
  end

  attr :field, :map, required: true
  attr :id, :string, required: true
  attr :value, :any, default: nil

  defp filter_input(%{field: %{type: :select} = field} = assigns) do
    assigns = assign(assigns, :options, Map.get(field, :options, []))

    ~H"""
    <select id={@id} name={field_param(@field)} class="ax-select">
      <option value="">All</option>
      <option :for={option <- @options} value={option_value(option)} selected={option_selected?(@value, option)}>
        <%= option_label(option) %>
      </option>
    </select>
    """
  end

  defp filter_input(%{field: %{type: :checkbox}} = assigns) do
    ~H"""
    <input type="hidden" name={field_param(@field)} value="" />
    <input
      id={@id}
      type="checkbox"
      name={field_param(@field)}
      value="true"
      checked={@value in [true, "true", "1", 1]}
      class="ax-checkbox"
    />
    """
  end

  defp filter_input(assigns) do
    ~H"""
    <input id={@id} type="text" name={field_param(@field)} value={@value} class="ax-input" />
    """
  end

  defp reload(socket, params, opts) do
    filter = socket.assigns.query_module.decode_filter(params)
    filter_params = socket.assigns.query_module.encode_filter(filter) |> stringify_map()
    cursor = Map.get(params, "cursor") || Map.get(params, :cursor)
    {rows, next_cursor} = socket.assigns.query_module.list(filter: filter, cursor: cursor, limit: socket.assigns.limit)

    socket
    |> assign(:params_signature, Keyword.fetch!(opts, :params_signature))
    |> assign(:params, params)
    |> assign(:filter, filter)
    |> assign(:filter_params, filter_params)
    |> assign(:rows, rows)
    |> assign(:next_cursor, next_cursor)
    |> assign(:newer_count, 0)
    |> maybe_reset_selection(opts)
    |> prune_selected_ids()
  end

  defp maybe_reset_selection(socket, opts) do
    if Keyword.get(opts, :reset_selection?, false) do
      assign(socket, :selected_ids, MapSet.new())
    else
      socket
    end
  end

  defp prune_selected_ids(socket) do
    assign(socket, :selected_ids, MapSet.intersection(socket.assigns.selected_ids, MapSet.new(visible_row_ids(socket))))
  end

  defp visible_row_ids(source) do
    assigns = extract_assigns(source)
    Enum.map(assigns.rows, &row_identity(&1, assigns.row_id))
  end

  defp all_visible_selected?(source) do
    assigns = extract_assigns(source)
    ids = visible_row_ids(assigns)
    ids != [] and Enum.all?(ids, &MapSet.member?(assigns.selected_ids, &1))
  end

  defp selected?(selected_ids, row_id), do: MapSet.member?(selected_ids, to_string(row_id))

  defp toggle_id(selected_ids, row_id) do
    row_id = to_string(row_id)

    if MapSet.member?(selected_ids, row_id) do
      MapSet.delete(selected_ids, row_id)
    else
      MapSet.put(selected_ids, row_id)
    end
  end

  defp poll_newer(socket) do
    count =
      case top_cursor(socket) do
        nil -> 0
        cursor -> socket.assigns.query_module.count_newer_than(filter: socket.assigns.filter, cursor: cursor)
      end

    assign(socket, :newer_count, count)
  end

  defp top_cursor(socket) do
    case socket.assigns.rows do
      [row | _rest] ->
        AccrueAdmin.Queries.Cursor.encode(Map.fetch!(row, socket.assigns.cursor_field), row_identity(row, socket.assigns.row_id))

      [] ->
        nil
    end
  end

  defp maybe_schedule_poll(socket) do
    if connected?(socket) and socket.assigns.enable_polling and socket.assigns.poll_interval_ms > 0 do
      Phoenix.LiveView.send_update_after(self(), __MODULE__, [id: socket.assigns.id, action: :poll], socket.assigns.poll_interval_ms)
    end

    socket
  end

  defp normalize_positive(value, _fallback) when is_integer(value) and value > 0, do: value
  defp normalize_positive(_value, fallback), do: fallback

  defp stringify_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_value(value)} end)
  end

  defp stringify_value(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_value(value), do: value

  defp signature(params), do: params |> Enum.sort() |> :erlang.term_to_binary()

  defp field_id(table_id, field), do: "#{table_id}-filter-#{field_param(field)}"
  defp field_param(field), do: Map.get(field, :param, Map.get(field, :id) |> to_string())
  defp field_label(field), do: Map.get(field, :label) || Map.get(field, :id) |> to_string()

  defp field_defined?(fields, key) do
    Enum.any?(fields, fn field -> field_param(field) == to_string(key) end)
  end

  defp option_value({value, _label}), do: value
  defp option_value(option) when is_map(option), do: Map.get(option, :value)
  defp option_value(option), do: option

  defp option_label({_value, label}), do: label
  defp option_label(option) when is_map(option), do: Map.get(option, :label, Map.get(option, :value))
  defp option_label(option), do: option

  defp option_selected?(value, option), do: to_string(value) == to_string(option_value(option))

  defp column_label(column), do: Map.get(column, :label) || humanize(Map.get(column, :id))

  defp cell_value(column, row) do
    cond do
      function = Map.get(column, :render) -> function.(row)
      key = Map.get(column, :key) -> Map.get(row, key)
      id = Map.get(column, :id) -> Map.get(row, id)
      true -> nil
    end
  end

  defp row_identity(row, row_id) when is_function(row_id, 1), do: row_id.(row) |> to_string()
  defp row_identity(row, row_id), do: Map.fetch!(row, row_id) |> to_string()

  defp row_dom_id(table_id, row, row_id), do: "#{table_id}-row-#{row_identity(row, row_id)}"

  defp card_fields([], columns), do: columns
  defp card_fields(card_fields, _columns), do: card_fields

  defp card_title(nil, row, [first_column | _rest]), do: cell_value(first_column, row)
  defp card_title(nil, row, _columns), do: row_identity(row, :id)
  defp card_title(card_title, row, _columns) when is_function(card_title, 1), do: card_title.(row)
  defp card_title(card_title, row, _columns), do: cell_value(card_title, row)

  defp extract_assigns(%{assigns: assigns}), do: assigns
  defp extract_assigns(assigns), do: assigns

  defp humanize(nil), do: "Column"

  defp humanize(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> humanize()
  end

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
