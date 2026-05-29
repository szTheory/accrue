defmodule AccrueAdmin.Live.Analytics.CampaignLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.Analytics.Dunning
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, CampaignTimeline}

  @impl true
  def mount(%{"id" => subscription_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})
    arcs = Dunning.campaign_timeline_grouped(subscription_id)
    invoice_map = Dunning.invoices_for_campaign(subscription_id)

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:subscription_id, subscription_id)
     |> assign(:arcs, arcs)
     |> assign(:invoice_map, invoice_map)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AppShell.app_shell
      brand={@brand}
      current_path={@current_path}
      mount_path={@admin_mount_path}
      page_title={@page_title}
      theme={@theme}
      active_organization_name={@active_organization_name}
    >
      <section class="ax-page">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs items={[
            %{label: "Analytics"},
            %{label: "Recovery", href: @current_path},
            %{label: "Subscription"}
          ]} />
          <h1 class="ax-heading">Dunning Timeline</h1>
          <p class="ax-body ax-muted">{@subscription_id}</p>
        </header>

        <CampaignTimeline.campaign_timeline arcs={@arcs} invoice_map={@invoice_map} />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Dunning Timeline")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, (admin["mount_path"] || "/billing") <> "/analytics/recovery")
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
