defmodule AccrueAdmin.Live.Analytics.RecoveryLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.Analytics.Dunning
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, KpiCard}

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})
    stats = Dunning.recovered_vs_lost_mrr()

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:stats, stats)}
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
          <Breadcrumbs.breadcrumbs items={[%{label: "Analytics"}, %{label: "Recovery"}]} />
          <p class="ax-eyebrow">Recovery Dashboard</p>
          <h2 class="ax-display">Revenue Recovery</h2>
        </header>

        <section class="ax-kpi-grid">
          <KpiCard.kpi_card
            label="Recovered MRR"
            value={format_minor(@stats.recovered_cents)}
            delta="Amount saved by successful Dunning"
            delta_tone="moss"
          >
            <:meta>Money Saved</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Lost MRR"
            value={format_minor(@stats.lost_cents)}
            delta="Amount lost to terminal Dunning failure"
            delta_tone="amber"
          >
            <:meta>Churned Revenue</:meta>
          </KpiCard.kpi_card>
        </section>
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Recovery Dashboard")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, (admin["mount_path"] || "/billing") <> "/analytics/recovery")
    |> assign(:active_organization_name, admin["active_organization_name"])
  end

  defp format_minor(amount_minor) when is_integer(amount_minor) do
    dollars = amount_minor / 100
    "$" <> :erlang.float_to_binary(dollars, decimals: 2)
  end

  defp format_minor(_), do: "$0.00"

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
