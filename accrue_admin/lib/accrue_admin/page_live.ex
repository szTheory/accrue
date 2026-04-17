defmodule AccrueAdmin.PageLive do
  @moduledoc false

  use Phoenix.LiveView

  alias AccrueAdmin.Components.AppShell

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    socket =
      socket
      |> assign(:page_title, "Billing")
      |> assign(:brand, admin["brand"] || default_brand())
      |> assign(:theme, admin["theme"] || "system")
      |> assign(:csp_nonce, admin["csp_nonce"])
      |> assign(:brand_css_path, admin["brand_css_path"])
      |> assign(:assets_css_path, admin["assets_css_path"])
      |> assign(:assets_js_path, admin["assets_js_path"])
      |> assign(:admin_mount_path, admin["mount_path"])
      |> assign(:current_path, admin["mount_path"])
      |> assign(:active_organization_name, nil)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <AppShell.app_shell
      brand={@brand}
      current_path={@current_path}
      mount_path={@admin_mount_path}
      page_title="Billing"
      theme={@theme}
    active_organization_name={@active_organization_name}
    >
      <section class="ax-page">
        <header class="ax-page-header">
          <p class="ax-eyebrow">Admin overview</p>
          <h1 class="ax-display">Billing state, modeled clearly.</h1>
          <p class="ax-body ax-page-copy">
            Review webhook failures, track customer billing health, and prepare the shared
            component layer that later admin pages will reuse.
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label="Admin shell highlights">
          <article class="ax-card ax-kpi-card">
            <p class="ax-label">Shell status</p>
            <p class="ax-kpi-value">Ready</p>
            <p class="ax-muted">Responsive navigation and theme persistence are active.</p>
          </article>

          <article class="ax-card ax-kpi-card">
            <p class="ax-label">Theme mode</p>
            <p class="ax-kpi-value"><%= String.capitalize(@theme) %></p>
            <p class="ax-muted">Cookie-backed preference with anti-FOUC protection.</p>
          </article>

          <article class="ax-card ax-kpi-card">
            <p class="ax-label">Brand accent</p>
            <p class="ax-kpi-value"><%= @brand.app_name %></p>
            <p class="ax-muted">Runtime accent values come from `Accrue.Config.branding/0`.</p>
          </article>
        </section>

        <section class="ax-card ax-empty-state" aria-labelledby="billing-records-heading">
          <div>
            <p class="ax-eyebrow">Next phase target</p>
            <h2 id="billing-records-heading" class="ax-heading">No billing records yet</h2>
          </div>
          <p class="ax-body">
            Matching records will appear here as customers subscribe, invoices are issued,
            and webhooks arrive. Clear filters or come back after the next billing event.
          </p>
          <a href={@admin_mount_path <> "/webhooks"} class="ax-link">Review webhook failures</a>
        </section>
      </section>
    </AppShell.app_shell>
    """
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
