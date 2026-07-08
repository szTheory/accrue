defmodule AccrueAdmin.Components.GlobalSearch do
  @moduledoc """
  Stateful LiveComponent for global search in the admin interface.
  """
  use Phoenix.LiveComponent

  alias AccrueAdmin.Components.Icon
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.{Customers, Invoices, Subscriptions}
  alias AccrueAdmin.ScopedPath

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       # mount_path is provided by update/2 from app_shell; nil here avoids
       # silently building broken navigation links if update/2 is not called
       # (e.g. during a hot-reload partial update or future refactors).
       mount_path: nil,
       current_owner_scope: nil,
       query: "",
       results: %{customers: [], invoices: [], subscriptions: []},
       is_open: false,
       loading: false
     )}
  end

  @impl true
  def update(%{action: "toggle"}, socket) do
    if socket.assigns.is_open do
      {:ok,
       assign(socket,
         is_open: false,
         query: "",
         results: %{customers: [], invoices: [], subscriptions: []}
       )}
    else
      {:ok, assign(socket, is_open: true)}
    end
  end

  def update(%{action: "close"}, socket) do
    {:ok,
     assign(socket,
       is_open: false,
       query: "",
       results: %{customers: [], invoices: [], subscriptions: []}
     )}
  end

  def update(%{action: "open"}, socket) do
    {:ok, assign(socket, is_open: true)}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("toggle", _, socket) do
    if socket.assigns.is_open do
      {:noreply, close(socket)}
    else
      {:noreply, assign(socket, is_open: true)}
    end
  end

  def handle_event("open", _, socket) do
    {:noreply, assign(socket, is_open: true)}
  end

  def handle_event("close", _, socket) do
    {:noreply, close(socket)}
  end

  # Maximum query length accepted before hitting the DB — prevents expensive
  # ilike patterns on arbitrarily large input pasted into the search box.
  @max_query_length 100

  def handle_event("search", %{"q" => query}, socket) do
    trimmed = String.trim(query)

    cond do
      trimmed == "" ->
        {:noreply,
         assign(socket,
           query: "",
           results: empty_results(),
           loading: false
         )}

      String.length(trimmed) > @max_query_length ->
        # Reject absurdly long queries before hitting the DB.
        {:noreply, assign(socket, query: trimmed, results: empty_results(), loading: false)}

      true ->
        results = fetch_results(trimmed, socket.assigns[:current_owner_scope])
        {:noreply, assign(socket, query: trimmed, results: results, loading: false)}
    end
  end

  defp empty_results, do: %{customers: [], invoices: [], subscriptions: []}

  defp close(socket) do
    assign(socket,
      is_open: false,
      query: "",
      results: empty_results()
    )
  end

  defp fetch_results(query, owner_scope) do
    tasks = [
      customers: fn ->
        Customers.list(filter: %{q: query}, limit: 5, owner_scope: owner_scope) |> page_rows()
      end,
      invoices: fn ->
        Invoices.list(filter: %{q: query}, limit: 5, owner_scope: owner_scope) |> page_rows()
      end,
      subscriptions: fn ->
        Subscriptions.list(filter: %{q: query}, limit: 5, owner_scope: owner_scope) |> page_rows()
      end
    ]

    tasks
    |> Task.async_stream(fn {key, func} -> {key, func.()} end,
      on_timeout: :kill_task,
      timeout: 3_000
    )
    |> Enum.reduce(empty_results(), fn
      {:ok, {key, data}}, acc -> Map.put(acc, key, data)
      {:exit, _}, acc -> acc
    end)
  end

  defp page_rows({rows, _cursor}), do: rows

  @impl true
  def render(assigns) do
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
          >
          </div>

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
                  placeholder="Search customers; open billing 360"
                  autocomplete="off"
                  spellcheck="false"
                  autofocus
                  phx-debounce="150"
                  class="ax-command-palette-input"
                  id="global-search-input"
                  data-focus-trap-initial
                />
                <span id="search-spinner" class="ax-spinner" hidden={not @loading} aria-hidden="true"></span>
              </div>
            </form>

            <div class="ax-command-palette-body">
              <%= if @query == "" do %>
                <div class="ax-command-palette-empty">
                  <p class="ax-eyebrow">Jump to</p>
                  <ul class="ax-command-palette-list">
                    <li class="ax-command-palette-list-item">
                      <a class="ax-command-palette-item" href={scoped_path(@mount_path, "/customers", @current_owner_scope)} data-path={scoped_path(@mount_path, "/customers", @current_owner_scope)}>
                        <Icon.icon name={:users} size="sm" /> <span>Look up a customer</span>
                      </a>
                    </li>
                    <li class="ax-command-palette-list-item">
                      <a class="ax-command-palette-item" href={scoped_path(@mount_path, "/invoices", @current_owner_scope, %{"status" => "open"})} data-path={scoped_path(@mount_path, "/invoices", @current_owner_scope, %{"status" => "open"})}>
                        <Icon.icon name={:invoices} size="sm" /> <span>Clear the invoice queue</span>
                      </a>
                    </li>
                    <li class="ax-command-palette-list-item">
                      <a class="ax-command-palette-item" href={scoped_path(@mount_path, "/analytics/recovery", @current_owner_scope)} data-path={scoped_path(@mount_path, "/analytics/recovery", @current_owner_scope)}>
                        <Icon.icon name={:recovery} size="sm" /> <span>Recover at-risk revenue</span>
                      </a>
                    </li>
                    <li class="ax-command-palette-list-item">
                      <a class="ax-command-palette-item" href={scoped_path(@mount_path, "/webhooks", @current_owner_scope, %{"status" => "dead"})} data-path={scoped_path(@mount_path, "/webhooks", @current_owner_scope, %{"status" => "dead"})}>
                        <Icon.icon name={:webhooks} size="sm" /> <span>Investigate an incident</span>
                      </a>
                    </li>
                  </ul>
                </div>
              <% else %>
                <div class="ax-command-palette-results">
                  <%= if Enum.empty?(@results.customers) and Enum.empty?(@results.invoices) and Enum.empty?(@results.subscriptions) do %>
                    <div class="ax-command-palette-no-results">
                      <p><%= Copy.global_search_no_results_html(@query) %></p>
                    </div>
                  <% else %>
                    <%= if not Enum.empty?(@results.customers) do %>
                      <p class="ax-eyebrow">Customers</p>
                      <ul class="ax-command-palette-list">
                        <%= for customer <- @results.customers do %>
                          <li class="ax-command-palette-list-item">
                            <a class="ax-command-palette-item" href={scoped_path(@mount_path, "/customers/#{customer.id}", @current_owner_scope)} data-path={scoped_path(@mount_path, "/customers/#{customer.id}", @current_owner_scope)}>
                              <%= customer.name || customer.email %>
                            </a>
                          </li>
                        <% end %>
                      </ul>
                    <% end %>

                    <%= if not Enum.empty?(@results.invoices) do %>
                      <p class="ax-eyebrow">Invoices</p>
                      <ul class="ax-command-palette-list">
                        <%= for invoice <- @results.invoices do %>
                          <li class="ax-command-palette-list-item">
                            <a class="ax-command-palette-item" href={scoped_path(@mount_path, "/invoices/#{invoice.id}", @current_owner_scope)} data-path={scoped_path(@mount_path, "/invoices/#{invoice.id}", @current_owner_scope)}>
                              <%= invoice.number || invoice.id %>
                            </a>
                          </li>
                        <% end %>
                      </ul>
                    <% end %>

                    <%= if not Enum.empty?(@results.subscriptions) do %>
                      <p class="ax-eyebrow">Subscriptions</p>
                      <ul class="ax-command-palette-list">
                        <%= for sub <- @results.subscriptions do %>
                          <li class="ax-command-palette-list-item">
                            <a class="ax-command-palette-item" href={scoped_path(@mount_path, "/subscriptions/#{sub.id}", @current_owner_scope)} data-path={scoped_path(@mount_path, "/subscriptions/#{sub.id}", @current_owner_scope)}>
                              <%= sub.id %> - <%= sub.status %>
                            </a>
                          </li>
                        <% end %>
                      </ul>
                    <% end %>
                  <% end %>
                </div>
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

  defp scoped_path(mount_path, suffix, owner_scope, params \\ %{})
  defp scoped_path(nil, _suffix, _owner_scope, _params), do: "#"

  defp scoped_path(mount_path, suffix, owner_scope, params),
    do: ScopedPath.build(mount_path, suffix, owner_scope, params)
end
