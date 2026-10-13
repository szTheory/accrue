defmodule AccrueAdmin.Components.GlobalSearch do
  @moduledoc "Stateful, bounded LiveComponent search preview for Admin records."

  use Phoenix.LiveComponent

  alias AccrueAdmin.Components.Icon
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.{Customers, Invoices, Subscriptions}
  alias AccrueAdmin.ScopedPath

  @max_query_length 100
  @result_limit 5
  @groups [:customers, :invoices, :subscriptions]

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       mount_path: nil,
       current_owner_scope: nil,
       query: "",
       max_query_length: @max_query_length,
       results: empty_results(),
       failures: [],
       query_too_long: false,
       is_open: false,
       loading: false,
       generation: 0
     )}
  end

  @impl true
  def update(%{action: "toggle"}, socket) do
    if socket.assigns.is_open do
      {:ok, close(socket)}
    else
      {:ok, assign(socket, is_open: true)}
    end
  end

  def update(%{action: "close"}, socket), do: {:ok, close(socket)}
  def update(%{action: "open"}, socket), do: {:ok, assign(socket, is_open: true)}

  def update(
        %{
          action: "search_results",
          query: query,
          owner_scope: owner_scope,
          generation: generation
        } = assigns,
        socket
      ) do
    if generation == socket.assigns.generation and query == socket.assigns.query and
         owner_scope == socket.assigns.current_owner_scope do
      {:ok,
       assign(socket,
         results: assigns.results,
         failures: assigns.failures,
         loading: false
       )}
    else
      {:ok, socket}
    end
  end

  def update(assigns, socket) do
    current_scope = socket.assigns.current_owner_scope
    next_scope = Map.get(assigns, :current_owner_scope, socket.assigns.current_owner_scope)
    socket = assign(socket, assigns)

    if next_scope != current_scope do
      {:ok,
       assign(socket,
         current_owner_scope: next_scope,
         query: "",
         results: empty_results(),
         failures: [],
         query_too_long: false,
         loading: false,
         generation: socket.assigns.generation + 1
       )}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    if socket.assigns.is_open do
      {:noreply, close(socket)}
    else
      {:noreply, assign(socket, is_open: true)}
    end
  end

  def handle_event("open", _params, socket), do: {:noreply, assign(socket, is_open: true)}
  def handle_event("close", _params, socket), do: {:noreply, close(socket)}

  def handle_event("search", %{"q" => query}, socket) do
    query = String.trim(query)

    cond do
      query == "" ->
        {:noreply, clear_query(socket)}

      String.length(query) > @max_query_length ->
        socket = clear_query(socket)
        {:noreply, assign(socket, query: query, query_too_long: true)}

      true ->
        {:noreply, begin_search(socket, query)}
    end
  end

  def handle_event("retry", _params, %{assigns: %{query: query}} = socket) when query != "" do
    failed_groups = socket.assigns.failures

    if failed_groups == [] do
      {:noreply, socket}
    else
      {:noreply, begin_search(socket, query, failed_groups, socket.assigns.results)}
    end
  end

  def handle_event("retry", _params, socket), do: {:noreply, socket}

  defp begin_search(socket, query) do
    begin_search(socket, query, @groups, empty_results())
  end

  defp begin_search(socket, query, groups, initial_results) do
    generation = socket.assigns.generation + 1
    owner_scope = socket.assigns.current_owner_scope
    id = socket.assigns.id
    view_pid = self()

    socket =
      assign(socket,
        query: query,
        generation: generation,
        results: initial_results,
        failures: [],
        query_too_long: false,
        loading: true
      )

    Task.start(fn ->
      {results, failures} = fetch_results(query, owner_scope, groups, initial_results)

      send_update(view_pid, __MODULE__,
        id: id,
        action: "search_results",
        query: query,
        owner_scope: owner_scope,
        generation: generation,
        results: results,
        failures: failures
      )
    end)

    socket
  end

  defp clear_query(socket) do
    assign(socket,
      query: "",
      results: empty_results(),
      failures: [],
      query_too_long: false,
      loading: false,
      generation: socket.assigns.generation + 1
    )
  end

  defp empty_results, do: %{customers: [], invoices: [], subscriptions: []}

  defp close(socket), do: socket |> clear_query() |> assign(is_open: false)

  defp fetch_results(query, owner_scope, groups, initial_results) do
    groups = if :lookup in groups, do: @groups, else: groups

    run_group_lookups(groups, initial_results, fn key ->
      case key do
        :customers ->
          Customers.list(filter: %{q: query}, limit: 5, owner_scope: owner_scope)

        :invoices ->
          Invoices.list(filter: %{q: query}, limit: 5, owner_scope: owner_scope)

        :subscriptions ->
          Subscriptions.list(filter: %{q: query}, limit: 5, owner_scope: owner_scope)
      end
    end)
  end

  @doc false
  def run_group_lookups(groups, initial_results, lookup) do
    groups = if :lookup in groups, do: @groups, else: groups

    tasks = Enum.map(groups, fn key -> {key, fn -> lookup.(key) end} end)

    tasks
    |> Enum.filter(fn {key, _func} -> key in groups end)
    |> Task.async_stream(fn {key, func} -> {key, safe_lookup(func)} end,
      on_timeout: :kill_task,
      timeout: 3_000
    )
    |> Enum.reduce({initial_results, []}, fn
      {:ok, {key, {:ok, {rows, _cursor}}}}, {results, failures} ->
        {Map.put(results, key, Enum.take(rows, @result_limit)), failures}

      {:ok, {key, {:error, _reason}}}, {results, failures} ->
        {results, [key | failures]}

      {:exit, _reason}, {results, failures} ->
        {results, [:lookup | failures]}
    end)
    |> then(fn {results, failures} -> {results, Enum.uniq(failures)} end)
  end

  defp safe_lookup(func) do
    {:ok, func.()}
  rescue
    _error -> {:error, :unavailable}
  catch
    _kind, _reason -> {:error, :unavailable}
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> Phoenix.Component.assign_new(:failures, fn -> [] end)
      |> Phoenix.Component.assign_new(:loading, fn -> false end)
      |> Phoenix.Component.assign_new(:active_result_status, fn -> "" end)

    ~H"""
    <div
      id={@id}
      class="ax-command-palette-wrapper"
      data-open={to_string(@is_open)}
      data-ax-command-palette-shell
      data-component-group="toolbar-search-filter-sort"
    >
      <div
        id={"#{@id}-controller"}
        phx-hook="CommandPalette"
        data-target={@myself}
        data-focus-trap-close-event="close"
        data-focus-trap-close-target={@myself}
        data-focus-trap-fallback="#search-trigger"
      >
        <%= if @is_open do %>
          <div
            class="ax-command-palette-backdrop"
            data-ax-command-palette-backdrop
            aria-hidden="true"
            phx-click="close"
            phx-target={@myself}
          ></div>

          <div
            class="ax-command-palette"
            id="command-palette-container"
            data-ax-command-palette-panel
            data-focus-trap-fallback
            role="dialog"
            aria-modal="true"
            aria-label="Global search"
            tabindex="-1"
          >
            <form phx-change="search" phx-target={@myself} onsubmit="return false;">
              <div class="ax-command-palette-input-group">
                <Icon.icon name={:search} size="md" class="ax-command-palette-search-icon" />
                <input
                  type="text"
                  name="q"
                  value={@query}
                  placeholder="Search customers, invoices, and subscriptions"
                  autocomplete="off"
                  spellcheck="false"
                  autofocus
                  class="ax-command-palette-input"
                  id="global-search-input"
                  role="combobox"
                  aria-haspopup="listbox"
                  aria-expanded="true"
                  aria-autocomplete="list"
                  data-focus-trap-initial
                  aria-describedby="global-search-help global-search-active-result"
                />
                <span id="search-spinner" class="ax-spinner ax-spinner-md" hidden={not @loading} aria-hidden="true"></span>
              </div>
              <p id="global-search-help" class="ax-body ax-command-palette-help">
                Search by name, email, invoice number, or ID.
              </p>
              <span id="global-search-active-result" class="ax-visually-hidden" role="status" data-active-result-status><%= @active_result_status %></span>
            </form>

            <div class="ax-command-palette-body" aria-live="polite" aria-atomic="false">
              <%= if @query == "" do %>
                <div class="ax-command-palette-empty">
                  <p class="ax-body ax-command-palette-orientation">Browse billing records</p>
                  <ul id="global-search-options-shortcuts" class="ax-command-palette-list" role="listbox" aria-label="Billing destinations">
                    <li class="ax-command-palette-list-item">
                      <a id="global-search-option-shortcut-customers" role="option" aria-selected="false" class="ax-command-palette-item" href={scoped_path(@mount_path, "/customers", @current_owner_scope)} data-path={scoped_path(@mount_path, "/customers", @current_owner_scope)}>
                        <Icon.icon name={:users} size="sm" /> <span>Customers</span>
                      </a>
                    </li>
                    <li class="ax-command-palette-list-item">
                      <a id="global-search-option-shortcut-invoices" role="option" aria-selected="false" class="ax-command-palette-item" href={scoped_path(@mount_path, "/invoices", @current_owner_scope)} data-path={scoped_path(@mount_path, "/invoices", @current_owner_scope)}>
                        <Icon.icon name={:invoices} size="sm" /> <span>Invoices</span>
                      </a>
                    </li>
                    <li class="ax-command-palette-list-item">
                      <a id="global-search-option-shortcut-subscriptions" role="option" aria-selected="false" class="ax-command-palette-item" href={scoped_path(@mount_path, "/subscriptions", @current_owner_scope)} data-path={scoped_path(@mount_path, "/subscriptions", @current_owner_scope)}>
                        <Icon.icon name={:recovery} size="sm" /> <span>Subscriptions</span>
                      </a>
                    </li>
                  </ul>
                </div>
              <% else %>
                <%= if @loading do %>
                  <p role="status">Searching billing records…</p>
                <% end %>
                <%= if @failures != [] do %>
                  <div class="ax-command-palette-error" role="status">
                    <p>Results couldn't be loaded. Successful groups remain available.</p>
                    <button type="button" class="ax-button ax-button-secondary ax-button-sm" phx-click="retry" phx-target={@myself}>
                      Retry failed groups
                    </button>
                  </div>
                <% end %>
                <%= if @query_too_long do %>
                  <p class="ax-command-palette-validation" role="status">Search is limited to <%= @max_query_length %> characters.</p>
                <% end %>
                <%= if not @query_too_long and not @loading and @failures == [] and no_results?(@results) do %>
                  <div class="ax-command-palette-no-results">
                    <p><%= Copy.global_search_no_results_html(@query) %></p>
                  </div>
                <% end %>

                <%= if @results.customers != [] do %>
                  <p class="ax-eyebrow">Customers</p>
                  <ul id="global-search-options-customers" class="ax-command-palette-list" role="listbox" aria-label="Customers" data-search-group="customers">
                    <li :for={customer <- @results.customers} class="ax-command-palette-list-item">
                      <a id={"global-search-option-customers-#{customer.id}"} role="option" aria-selected="false" class="ax-command-palette-item" href={scoped_path(@mount_path, "/customers/#{customer.id}", @current_owner_scope)} data-path={scoped_path(@mount_path, "/customers/#{customer.id}", @current_owner_scope)}>
                        <span><strong title={customer.name || customer.email || customer.id}><%= customer.name || customer.email || customer.id %></strong>
                          <small><%= customer.email %><%= if customer.owner_id, do: " · #{customer.owner_type} #{customer.owner_id}" %><%= if customer.processor_id, do: " · #{customer.processor} #{customer.processor_id}" %></small>
                          <code>Customer ID: <%= customer.id %></code>
                        </span>
                      </a>
                    </li>
                  </ul>
                <% end %>

                <%= if @results.invoices != [] do %>
                  <p class="ax-eyebrow">Invoices</p>
                  <ul id="global-search-options-invoices" class="ax-command-palette-list" role="listbox" aria-label="Invoices" data-search-group="invoices">
                    <li :for={invoice <- @results.invoices} class="ax-command-palette-list-item">
                      <a id={"global-search-option-invoices-#{invoice.id}"} role="option" aria-selected="false" class="ax-command-palette-item" href={scoped_path(@mount_path, "/invoices/#{invoice.id}", @current_owner_scope)} data-path={scoped_path(@mount_path, "/invoices/#{invoice.id}", @current_owner_scope)}>
                        <span><strong title={invoice.number || invoice.id}><%= invoice.number || invoice.id %></strong>
                          <small><span class="ax-record-label" title={invoice.customer_name}><%= invoice.customer_name %></span><%= if invoice.customer_email, do: " · #{invoice.customer_email}" %><%= if invoice.processor_id, do: " · #{invoice.processor_id}" %></small>
                          <code>Invoice ID: <%= invoice.id %></code>
                        </span>
                      </a>
                    </li>
                  </ul>
                <% end %>

                <%= if @results.subscriptions != [] do %>
                  <p class="ax-eyebrow">Subscriptions</p>
                  <ul id="global-search-options-subscriptions" class="ax-command-palette-list" role="listbox" aria-label="Subscriptions" data-search-group="subscriptions">
                    <li :for={sub <- @results.subscriptions} class="ax-command-palette-list-item">
                      <a id={"global-search-option-subscriptions-#{sub.id}"} role="option" aria-selected="false" class="ax-command-palette-item" href={scoped_path(@mount_path, "/subscriptions/#{sub.id}", @current_owner_scope)} data-path={scoped_path(@mount_path, "/subscriptions/#{sub.id}", @current_owner_scope)}>
                        <span><strong title={sub.customer_name || sub.customer_email || sub.id}><%= sub.customer_name || sub.customer_email || sub.id %></strong>
                          <small><%= sub.status %><%= if sub.customer_email, do: " · #{sub.customer_email}" %><%= if sub.processor_id, do: " · #{sub.processor_id}" %></small>
                          <code>Subscription ID: <%= sub.id %></code>
                        </span>
                      </a>
                    </li>
                  </ul>
                <% end %>
              <% end %>
            </div>

            <div class="ax-command-palette-footer">
              <span class="ax-shortcut"><kbd>↑</kbd><kbd>↓</kbd> Navigate</span>
              <span class="ax-shortcut"><kbd>↵</kbd> Select</span>
              <span class="ax-shortcut"><kbd>esc</kbd> Close</span>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp no_results?(results),
    do: Enum.all?([:customers, :invoices, :subscriptions], &(Map.fetch!(results, &1) == []))

  defp scoped_path(nil, _suffix, _owner_scope), do: "#"

  defp scoped_path(mount_path, suffix, owner_scope),
    do: ScopedPath.build(mount_path, suffix, owner_scope)
end
