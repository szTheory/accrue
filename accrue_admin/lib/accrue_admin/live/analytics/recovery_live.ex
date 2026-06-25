defmodule AccrueAdmin.Live.Analytics.RecoveryLive do
  @moduledoc false

  use Phoenix.LiveView

  @known_currency_atoms ~w(usd eur gbp jpy kwd)a

  alias Accrue.Analytics.Dunning
  alias AccrueAdmin.Copy

  alias AccrueAdmin.Components.{
    AppShell,
    AtRiskTable,
    Breadcrumbs,
    FunnelChart,
    KpiCard,
    WindowSelector
  }

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})
    {:ok, assign_shell(socket, admin)}
  end

  @impl true
  def handle_params(params, uri, socket) do
    window = parse_window(params["window"])
    {since, until} = window_bounds(window)

    stats = Dunning.recovered_vs_lost_mrr(since: since, until: until)
    funnel = Dunning.funnel(since: since, until: until)
    at_risk = Dunning.at_risk_subscriptions(since: since, until: until)

    locale = Accrue.Config.default_locale()

    recovered_currencies = Enum.map(stats.recovered, & &1.currency)
    lost_currencies = Enum.map(stats.lost, & &1.currency)
    currencies = Enum.uniq(recovered_currencies ++ lost_currencies)

    currencies =
      if currencies == [],
        do: [to_string(Accrue.Config.get!(:default_currency))],
        else: currencies

    kpi_pairs =
      Enum.map(currencies, fn currency ->
        recovered = Enum.find(stats.recovered, %{cents: 0}, &(&1.currency == currency))
        lost = Enum.find(stats.lost, %{cents: 0}, &(&1.currency == currency))

        currency_arg = known_currency_atom(currency)

        %{
          currency: to_string(currency),
          recovered_str: format_recovery_money(recovered.cents, currency_arg, currency, locale),
          exhausted_str: format_recovery_money(lost.cents, currency_arg, currency, locale)
        }
      end)

    {:noreply,
     socket
     |> assign(:window, window)
     |> assign(:window_selector_base_path, window_selector_base_path(uri))
     |> assign(:stats, stats)
     |> assign(:funnel, funnel)
     |> assign(:kpi_pairs, kpi_pairs)
     |> assign(:at_risk, at_risk)}
  end

  defp known_currency_atom(currency) when is_atom(currency) do
    if currency in @known_currency_atoms, do: currency
  end

  defp known_currency_atom(currency) when is_binary(currency) do
    normalized = String.downcase(currency)
    Enum.find(@known_currency_atoms, &(Atom.to_string(&1) == normalized))
  end

  defp known_currency_atom(_currency), do: nil

  defp format_recovery_money(cents, nil, currency, _locale) do
    "#{cents} #{currency |> to_string() |> String.upcase()}"
  end

  defp format_recovery_money(cents, currency, _original_currency, locale) do
    Accrue.Invoices.Render.format_money(cents, currency, locale)
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
          <div class="ax-heading-row">
            <h1 class="ax-display"><%= Copy.recovery_index_heading() %></h1>
            <a
              href="https://hexdocs.pm/accrue/analytics.html#cutoff-semantics"
              target="_blank"
              rel="noopener noreferrer"
              class="ax-help-link"
            >
              Showing data since 2024-01-01
            </a>
          </div>
          <p class="ax-body ax-page-copy"><%= Copy.recovery_index_subtitle() %></p>
          <WindowSelector.window_selector
            current_window={@window}
            base_path={@window_selector_base_path}
          />
        </header>

        <%= for kpi <- @kpi_pairs do %>
          <section class="ax-kpi-grid ax-section-gap" data-ax-zone="kpi-cluster">
            <KpiCard.kpi_card
              label={"Recovered MRR (#{String.upcase(kpi.currency)})"}
              value={kpi.recovered_str}
              delta="Amount saved by successful Dunning"
              delta_tone="moss"
              component_group="kpi-chart-table"
            >
              <:meta>Money Saved</:meta>
            </KpiCard.kpi_card>

            <KpiCard.kpi_card
              label={"Exhausted MRR (#{String.upcase(kpi.currency)})"}
              value={kpi.exhausted_str}
              delta="Annualized MRR snapshot at the exhaustion event — e.g., a $120/yr plan contributes $10/mo to Exhausted MRR."
              delta_tone="amber"
              component_group="kpi-chart-table"
            >
              <:meta>Churned Revenue</:meta>
            </KpiCard.kpi_card>
          </section>
        <% end %>

        <section data-ax-zone="task-launcher">
          <AtRiskTable.at_risk_table rows={@at_risk} base_path={@admin_mount_path} />
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
    now = DateTime.utc_now()
    since = DateTime.add(now, -7 * 86_400, :second)
    {since, now}
  end

  defp window_bounds("30d") do
    now = DateTime.utc_now()
    since = DateTime.add(now, -30 * 86_400, :second)
    {since, now}
  end

  defp window_bounds("90d") do
    now = DateTime.utc_now()
    since = DateTime.add(now, -90 * 86_400, :second)
    {since, now}
  end

  defp window_selector_base_path(uri) do
    parsed = URI.parse(uri)

    query =
      parsed.query
      |> decode_query()
      |> Map.delete("window")
      |> URI.encode_query()

    case query do
      "" -> parsed.path
      _ -> parsed.path <> "?" <> query
    end
  end

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)

  defp assign_shell(socket, admin) do
    current_path = (admin["mount_path"] || "/billing") <> "/analytics/recovery"

    socket
    |> assign(:page_title, "Recovery Dashboard")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, current_path)
    |> assign(:window_selector_base_path, current_path)
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
