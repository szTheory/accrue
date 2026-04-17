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
  attr(:active_organization_name, :any, default: nil)
  slot(:inner_block, required: true)

  def app_shell(assigns) do
    assigns =
      assign(assigns, :nav_items, nav_items(assigns.mount_path, org_slug(assigns.current_path)))

    ~H"""
    <div class="ax-shell" data-mount-path={@mount_path}>
      <Sidebar.sidebar brand={@brand} current_path={@current_path} items={@nav_items} />

      <div class="ax-shell-main">
        <div :if={@active_organization_name} class="ax-active-org-banner" role="status">
          <span class="ax-label">Active organization</span>
          <span class="ax-active-org-name"><%= @active_organization_name %></span>
        </div>

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

  defp nav_items(mount_path, org_slug) do
    [
      %{label: "Dashboard", href: nav_href(mount_path, "", org_slug), eyebrow: "Overview"},
      %{
        label: "Customers",
        href: nav_href(mount_path, "/customers", org_slug),
        eyebrow: "Billing data"
      },
      %{
        label: "Subscriptions",
        href: nav_href(mount_path, "/subscriptions", org_slug),
        eyebrow: "Lifecycle"
      },
      %{
        label: "Invoices",
        href: nav_href(mount_path, "/invoices", org_slug),
        eyebrow: "Collections"
      },
      %{label: "Charges", href: nav_href(mount_path, "/charges", org_slug), eyebrow: "Payments"},
      %{label: "Events", href: nav_href(mount_path, "/events", org_slug), eyebrow: "Ledger"},
      %{label: "Coupons", href: nav_href(mount_path, "/coupons", org_slug), eyebrow: "Discounts"},
      %{
        label: "Promotion codes",
        href: nav_href(mount_path, "/promotion-codes", org_slug),
        eyebrow: "Codes"
      },
      %{label: "Connect", href: nav_href(mount_path, "/connect", org_slug), eyebrow: "Payouts"},
      %{
        label: "Webhooks",
        href: nav_href(mount_path, "/webhooks", org_slug),
        eyebrow: "Operations"
      }
    ]
  end

  defp org_slug(current_path) do
    current_path
    |> URI.parse()
    |> Map.get(:query)
    |> case do
      nil -> nil
      query -> query |> URI.decode_query() |> Map.get("org")
    end
  end

  defp nav_href(mount_path, suffix, slug) when is_binary(slug) and slug != "" do
    mount_path <> suffix <> "?org=" <> URI.encode_www_form(slug)
  end

  defp nav_href(mount_path, suffix, _slug), do: mount_path <> suffix
end
