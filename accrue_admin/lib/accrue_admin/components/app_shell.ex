defmodule AccrueAdmin.Components.AppShell do
  @moduledoc """
  Responsive layout shell shared by mounted admin LiveViews.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.{Sidebar, Topbar}

  attr(:brand, :map, required: true)
  attr(:current_path, :string, required: true)
  attr(:mount_path, :string, required: true)
  attr(:page_title, :string, required: true)
  attr(:theme, :string, default: "system")
  slot(:inner_block, required: true)

  def app_shell(assigns) do
    assigns = assign(assigns, :nav_items, nav_items(assigns.mount_path))

    ~H"""
    <div class="ax-shell" data-mount-path={@mount_path}>
      <Sidebar.sidebar brand={@brand} current_path={@current_path} items={@nav_items} />

      <div class="ax-shell-main">
        <Topbar.topbar brand={@brand} page_title={@page_title} theme={@theme} />

        <main class="ax-shell-content" id="main-content">
          <%= render_slot(@inner_block) %>
        </main>
      </div>

      <.dev_toolbar current_path={@current_path} mount_path={@mount_path} />
    </div>
    """
  end

  if Mix.env() != :prod do
    attr(:current_path, :string, required: true)
    attr(:mount_path, :string, required: true)

    defp dev_toolbar(assigns) do
      ~H"""
      <AccrueAdmin.Components.DevToolbar.dev_toolbar
        :if={AccrueAdmin.Components.DevToolbar.visible?()}
        current_path={@current_path}
        mount_path={@mount_path}
      />
      """
    end
  else
    attr(:current_path, :string, required: true)
    attr(:mount_path, :string, required: true)

    defp dev_toolbar(assigns) do
      ~H""
    end
  end

  defp nav_items(mount_path) do
    [
      %{label: "Dashboard", href: mount_path, eyebrow: "Overview"},
      %{label: "Customers", href: mount_path <> "/customers", eyebrow: "Billing data"},
      %{label: "Subscriptions", href: mount_path <> "/subscriptions", eyebrow: "Lifecycle"},
      %{label: "Invoices", href: mount_path <> "/invoices", eyebrow: "Collections"},
      %{label: "Charges", href: mount_path <> "/charges", eyebrow: "Payments"},
      %{label: "Events", href: mount_path <> "/events", eyebrow: "Ledger"},
      %{label: "Coupons", href: mount_path <> "/coupons", eyebrow: "Discounts"},
      %{label: "Promotion codes", href: mount_path <> "/promotion-codes", eyebrow: "Codes"},
      %{label: "Connect", href: mount_path <> "/connect", eyebrow: "Payouts"},
      %{label: "Webhooks", href: mount_path <> "/webhooks", eyebrow: "Operations"}
    ]
  end
end
