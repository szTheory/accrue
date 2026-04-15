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

    socket =
      socket
      |> assign(assigns)
      |> assign_new(:selected_ids, fn -> MapSet.new() end)
      |> assign_new(:filter_fields, fn -> [] end)
      |> assign_new(:empty_title, fn -> "No rows found" end)
      |> assign_new(:empty_copy, fn -> "Adjust the filters or wait for new activity." end)
      |> assign_new(:cursor_field, fn -> :inserted_at end)
      |> assign_new(:row_id, fn -> :id end)
      |> assign(:limit, normalize_positive(Map.get(assigns, :limit, @default_limit), @default_limit))
      |> assign(
        :dom_limit,
        normalize_positive(Map.get(assigns, :dom_limit, @default_dom_limit), @default_dom_limit)
      )

    if socket.assigns[:params_signature] != params_signature do
      {:ok, reload(socket, params, reset_selection?: false, params_signature: params_signature)}
    else
      {:ok, socket}
    end
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

      <div :if={Enum.empty?(@rows)} class="ax-card ax-data-table-empty" data-role="empty-state">
        <p class="ax-heading"><%= @empty_title %></p>
        <p class="ax-body"><%= @empty_copy %></p>
      </div>

      <div :if={!Enum.empty?(@rows)} class="ax-card ax-data-table-shell">
        <table class="ax-data-table-grid">
          <thead>
            <tr>
              <th :for={column <- @columns} scope="col" class="ax-label"><%= column_label(column) %></th>
            </tr>
          </thead>
          <tbody>
            <tr :for={row <- @rows} id={row_dom_id(@id, row, @row_id)} data-row-id={row_identity(row, @row_id)}>
              <td :for={column <- @columns}><%= cell_value(column, row) %></td>
            </tr>
          </tbody>
        </table>
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
    |> assign(:filter, filter)
    |> assign(:filter_params, filter_params)
    |> assign(:rows, rows)
    |> assign(:next_cursor, next_cursor)
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
    visible_ids =
      socket.assigns.rows
      |> Enum.map(&row_identity(&1, socket.assigns.row_id))
      |> MapSet.new()

    assign(socket, :selected_ids, MapSet.intersection(socket.assigns.selected_ids, visible_ids))
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

  defp row_identity(row, row_id) when is_function(row_id, 1), do: row_id.(row)
  defp row_identity(row, row_id), do: Map.fetch!(row, row_id)

  defp row_dom_id(table_id, row, row_id), do: "#{table_id}-row-#{row_identity(row, row_id)}"

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
