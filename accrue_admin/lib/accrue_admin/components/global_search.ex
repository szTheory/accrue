defmodule AccrueAdmin.Components.GlobalSearch do
  @moduledoc """
  Stateful LiveComponent for global search in the admin interface.
  """
  use Phoenix.LiveComponent

  alias Accrue.Billing
  alias AccrueAdmin.Components.Icon

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       mount_path: "/billing",
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
  def handle_event("close", _, socket) do
    {:noreply,
     assign(socket,
       is_open: false,
       query: "",
       results: %{customers: [], invoices: [], subscriptions: []}
     )}
  end

  def handle_event("search", %{"q" => query}, socket) do
    if String.trim(query) == "" do
      {:noreply,
       assign(socket,
         query: "",
         results: %{customers: [], invoices: [], subscriptions: []},
         loading: false
       )}
    else
      results = fetch_results(query)
      {:noreply, assign(socket, query: query, results: results, loading: false)}
    end
  end

  defp fetch_results(query) do
    tasks = [
      customers: fn -> Billing.search_customers(query) |> Enum.take(5) end,
      invoices: fn -> Billing.search_invoices(query) |> Enum.take(5) end,
      subscriptions: fn -> Billing.search_subscriptions(query) |> Enum.take(5) end
    ]

    tasks
    |> Task.async_stream(fn {key, func} -> {key, func.()} end)
    |> Enum.reduce(%{customers: [], invoices: [], subscriptions: []}, fn {:ok, {key, data}},
                                                                         acc ->
      Map.put(acc, key, data)
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class={if @is_open, do: "ax-command-palette-wrapper", else: "hidden"}>
      <div 
        class="ax-command-palette-backdrop" 
        phx-click="close" 
        phx-target={@myself}>
      </div>
      
      <div 
        class="ax-command-palette" 
        phx-hook="CommandPalette" 
        id="command-palette-container"
        data-target={@myself}
        role="dialog"
        aria-modal="true"
        aria-label="Global search">
        
        <form phx-change="search" phx-target={@myself} onsubmit="return false;">
          <div class="ax-command-palette-input-group">
            <Icon.icon name={:search} size="md" class="ax-command-palette-search-icon" />
            <input
              type="text"
              name="q"
              value={@query}
              placeholder="Search customers, invoices, subscriptions..."
              autocomplete="off"
              spellcheck="false"
              autofocus
              phx-debounce="150"
              class="ax-command-palette-input"
              id="global-search-input"
            />
            <span id="search-spinner" class={if @loading, do: "ax-spinner", else: "hidden"} aria-hidden="true"></span>
          </div>
        </form>

        <div class="ax-command-palette-body">
          <%= if @query == "" do %>
            <div class="ax-command-palette-empty">
              <p class="ax-eyebrow">Jump to</p>
              <ul class="ax-command-palette-list">
                <li class="ax-command-palette-item" data-path={path(@mount_path, "/customers")}>
                  <Icon.icon name={:users} size="sm" /> <span>Find a customer</span>
                </li>
                <li class="ax-command-palette-item" data-path={path(@mount_path, "/invoices?status=open")}>
                  <Icon.icon name={:invoices} size="sm" /> <span>Work open invoices</span>
                </li>
                <li class="ax-command-palette-item" data-path={path(@mount_path, "/analytics/recovery")}>
                  <Icon.icon name={:recovery} size="sm" /> <span>Recover failed payments</span>
                </li>
                <li class="ax-command-palette-item" data-path={path(@mount_path, "/webhooks?status=dead")}>
                  <Icon.icon name={:webhooks} size="sm" /> <span>Debug dead-letter webhooks</span>
                </li>
              </ul>
            </div>
          <% else %>
            <div class="ax-command-palette-results">
              <%= if Enum.empty?(@results.customers) and Enum.empty?(@results.invoices) and Enum.empty?(@results.subscriptions) do %>
                <div class="ax-command-palette-no-results">
                  <p>No results found for "<%= @query %>"</p>
                </div>
              <% else %>
                <%= if not Enum.empty?(@results.customers) do %>
                  <p class="ax-eyebrow">Customers</p>
                  <ul class="ax-command-palette-list">
                    <%= for customer <- @results.customers do %>
                      <li class="ax-command-palette-item" data-path={path(@mount_path, "/customers/#{customer.id}")}>
                        <%= customer.name || customer.email %>
                      </li>
                    <% end %>
                  </ul>
                <% end %>

                <%= if not Enum.empty?(@results.invoices) do %>
                  <p class="ax-eyebrow">Invoices</p>
                  <ul class="ax-command-palette-list">
                    <%= for invoice <- @results.invoices do %>
                      <li class="ax-command-palette-item" data-path={path(@mount_path, "/invoices/#{invoice.id}")}>
                        <%= invoice.number %> - <%= invoice.amount_due %>
                      </li>
                    <% end %>
                  </ul>
                <% end %>

                <%= if not Enum.empty?(@results.subscriptions) do %>
                  <p class="ax-eyebrow">Subscriptions</p>
                  <ul class="ax-command-palette-list">
                    <%= for sub <- @results.subscriptions do %>
                      <li class="ax-command-palette-item" data-path={path(@mount_path, "/subscriptions/#{sub.id}")}>
                        <%= sub.id %> - <%= sub.status %>
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
    </div>
    """
  end

  defp path(mount_path, suffix), do: mount_path <> suffix
end
