defmodule AccrueAdmin.Live.Analytics.RecoveryLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.Analytics.Dunning
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, FunnelChart, KpiCard, WindowSelector}

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})
    {:ok, assign_shell(socket, admin)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    window = parse_window(params["window"])
    {since, until} = window_bounds(window)

    stats = Dunning.recovered_vs_lost_mrr(since: since, until: until)
    funnel = Dunning.funnel(since: since, until: until)

    # DAN-13: format KPI card values via the CLDR-backed Render.format_money/3
    # driven by Accrue.Config.get!(:default_currency) (runtime read — never
    # the compile-time accessor; see RESEARCH.md Pitfall #4) plus
    # Accrue.Config.default_locale().
    currency = Accrue.Config.get!(:default_currency)
    locale = Accrue.Config.default_locale()
    recovered_str = Accrue.Invoices.Render.format_money(stats.recovered_cents, currency, locale)
    exhausted_str = Accrue.Invoices.Render.format_money(stats.lost_cents, currency, locale)

    {:noreply,
     socket
     |> assign(:window, window)
     |> assign(:stats, stats)
     |> assign(:funnel, funnel)
     |> assign(:recovered_str, recovered_str)
     |> assign(:exhausted_str, exhausted_str)}
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
          <WindowSelector.window_selector current_window={@window} base_path={@current_path} />
        </header>

        <section class="ax-kpi-grid">
          <KpiCard.kpi_card
            label="Recovered MRR"
            value={@recovered_str}
            delta="Amount saved by successful Dunning"
            delta_tone="moss"
          >
            <:meta>Money Saved</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Exhausted MRR"
            value={@exhausted_str}
            delta="Annualized MRR snapshot at the exhaustion event — e.g., a $120/yr plan contributes $10/mo to Exhausted MRR."
            delta_tone="amber"
          >
            <:meta>Churned Revenue</:meta>
          </KpiCard.kpi_card>
        </section>

        <FunnelChart.funnel_chart
          entered={@funnel.entered}
          recovered={@funnel.recovered}
          exhausted={@funnel.exhausted}
          active={@funnel.active}
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp parse_window(w) when w in ["7d", "30d", "90d"], do: w
  defp parse_window(_), do: "30d"

  defp window_bounds("7d") do
    since = DateTime.add(DateTime.utc_now(), -7 * 86_400, :second)
    {since, DateTime.utc_now()}
  end

  defp window_bounds("30d") do
    since = DateTime.add(DateTime.utc_now(), -30 * 86_400, :second)
    {since, DateTime.utc_now()}
  end

  defp window_bounds("90d") do
    since = DateTime.add(DateTime.utc_now(), -90 * 86_400, :second)
    {since, DateTime.utc_now()}
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
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
