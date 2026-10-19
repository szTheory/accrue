defmodule AccrueAdmin.Live.Analytics.RecoveryLive do
  @moduledoc false

  use Phoenix.LiveView

  @known_currency_atoms ~w(usd eur gbp jpy kwd)a

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Dunning

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
    window = parse_window(Map.get(params, "window"))
    {since, until} = window_bounds(window)
    owner_scope = socket.assigns.current_owner_scope

    {:noreply,
     socket
     |> assign(:window, window)
     |> assign(:window_selector_base_path, window_selector_base_path(uri))
     |> assign(:stats, %{recovered: [], lost: []})
     |> assign(:funnel, %{entered: 0, recovered: 0, exhausted: 0, active: 0})
     |> assign(:kpi_pairs, [])
     |> assign(:at_risk, [])
     |> assign(:recovery_loading?, true)
     |> assign(:recovery_error, nil)
     |> start_async(:recovery_query, fn ->
       recovery_query(owner_scope, since, until)
     end)}
  end

  defp recovery_query(owner_scope, since, until) do
    case Application.get_env(:accrue_admin, :recovery_query_fun) do
      query when is_function(query, 3) ->
        query.(owner_scope, since, until)

      _ ->
        %{
          stats: Dunning.recovered_vs_lost_mrr(owner_scope, since: since, until: until),
          funnel: Dunning.funnel(owner_scope, since: since, until: until),
          at_risk: Dunning.at_risk_subscriptions(owner_scope, since: since, until: until)
        }
    end
  end

  @impl true
  def handle_async(:recovery_query, {:ok, result}, socket) do
    {:noreply,
     socket
     |> assign(:stats, result.stats)
     |> assign(:funnel, result.funnel)
     |> assign(:at_risk, result.at_risk)
     |> assign(:kpi_pairs, recovery_kpi_pairs(result.stats))
     |> assign(:recovery_loading?, false)
     |> assign(:recovery_error, nil)}
  end

  def handle_async(:recovery_query, {:exit, _reason}, socket) do
    {:noreply,
     socket
     |> assign(:stats, %{recovered: [], lost: []})
     |> assign(:funnel, %{entered: 0, recovered: 0, exhausted: 0, active: 0})
     |> assign(:kpi_pairs, [])
     |> assign(:at_risk, [])
     |> assign(:recovery_loading?, false)
     |> assign(:recovery_error, Copy.recovery_data_error_copy())}
  end

  defp recovery_kpi_pairs(stats) do
    currencies =
      Enum.map(stats.recovered, & &1.currency) ++ Enum.map(stats.lost, & &1.currency)

    currencies = Enum.uniq(currencies)
    supported_currencies = Enum.filter(currencies, &(not is_nil(known_currency_atom(&1))))
    has_unavailable_currency = length(supported_currencies) != length(currencies)
    currencies = supported_currencies ++ if(has_unavailable_currency, do: [nil], else: [])
    locale = Accrue.Config.default_locale()

    Enum.map(currencies, fn currency ->
      if is_nil(currency) do
        %{
          currency: "Unavailable",
          recovered_str: "Amount unavailable",
          exhausted_str: "Amount unavailable"
        }
      else
        recovered = Enum.find(stats.recovered, &(&1.currency == currency))
        lost = Enum.find(stats.lost, &(&1.currency == currency))

        %{
          currency: to_string(currency),
          recovered_str:
            format_recovery_money(
              recovered && recovered.cents,
              known_currency_atom(currency),
              currency,
              locale
            ),
          exhausted_str:
            format_recovery_money(
              lost && lost.cents,
              known_currency_atom(currency),
              currency,
              locale
            )
        }
      end
    end)
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

  defp format_recovery_money(nil, _currency, _original_currency, _locale),
    do: "Amount unavailable"

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
      current_owner_scope={assigns[:current_owner_scope]}
      active_organization_name={@active_organization_name}
    >
      <section class="ax-page" data-ax-overview="recovery">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs group="Recovery" items={[%{label: Copy.recovery_index_heading()}]} />
          <div class="ax-heading-row">
            <h1 class="ax-display"><%= Copy.recovery_index_heading() %></h1>
          </div>
          <p class="ax-body ax-page-copy"><%= Copy.recovery_index_subtitle() %></p>
          <p class="ax-body ax-recovery-coverage">
            Data since January 1, 2024. Reporting windows use UTC.
          </p>
          <WindowSelector.window_selector
            current_window={@window}
            base_path={@window_selector_base_path}
          />
        </header>

        <section
          class="ax-kpi-grid ax-section-gap ax-recovery-currency-groups"
          data-ax-recovery-hero
        >
          <%= for kpi <- @kpi_pairs do %>
            <div
              class="ax-recovery-currency-pair"
              data-ax-currency-pair
              data-currency={String.downcase(kpi.currency)}
            >
              <KpiCard.kpi_card
                label={Copy.recovery_recovered_mrr_label(kpi.currency)}
                value={kpi.recovered_str}
                unavailable={kpi.recovered_str == "Amount unavailable"}
                component_group="kpi-chart-table"
              >
                <:meta><%= Copy.recovery_recovered_mrr_meta() %></:meta>
              </KpiCard.kpi_card>

              <KpiCard.kpi_card
                label={Copy.recovery_exhausted_mrr_label(kpi.currency)}
                value={kpi.exhausted_str}
                unavailable={kpi.exhausted_str == "Amount unavailable"}
                component_group="kpi-chart-table"
              >
                <:meta><%= Copy.recovery_exhausted_mrr_meta() %></:meta>
              </KpiCard.kpi_card>
            </div>
          <% end %>
        </section>

        <p class="ax-body ax-recovery-definition">
          MRR is monthly recurring revenue at the time retries recovered or ended.
          An annual plan contributes one twelfth of its yearly amount.
          Unavailable amounts are not counted as zero.
        </p>

        <section data-ax-recovery-work-queue>
          <AtRiskTable.at_risk_table
            rows={@at_risk}
            base_path={@admin_mount_path}
            owner_scope={@current_owner_scope}
            current_window={@window}
            loading={@recovery_loading?}
            error={@recovery_error}
            empty_copy={
              Copy.resource_state_copy(:dunning, :queue_empty)
              |> Map.merge(%{
                heading: "No subscriptions currently need payment retry",
                body: "All subscriptions in this window recovered or exhausted their retry schedule."
              })
            }
          />
        </section>

        <section
          data-ax-recovery-supporting-funnel
          data-state={recovery_state(@recovery_loading?, @recovery_error)}
        >
          <p :if={@recovery_loading?} class="ax-body" role="status">
            Loading recovery observations for this owner and UTC window.
          </p>
          <p :if={!@recovery_loading? && is_nil(@recovery_error)} class="ax-body ax-muted ax-measure">
            Recorded outcomes cover campaigns with events in this window. The queue shows subscriptions currently in retry.
          </p>
          <FunnelChart.funnel_chart
            :if={!@recovery_loading? && is_nil(@recovery_error)}
            entered={@funnel.entered}
            recovered={@funnel.recovered}
            exhausted={@funnel.exhausted}
            active={@funnel.active}
          />
        </section>
      </section>
    </AppShell.app_shell>
    """
  end

  defp parse_window(w) when w in ["7d", "30d", "90d"], do: w
  defp parse_window(_), do: "30d"

  defp window_bounds("7d") do
    now = Accrue.Clock.utc_now()
    since = DateTime.add(now, -7 * 86_400, :second)
    {since, now}
  end

  defp window_bounds("30d") do
    now = Accrue.Clock.utc_now()
    since = DateTime.add(now, -30 * 86_400, :second)
    {since, now}
  end

  defp window_bounds("90d") do
    now = Accrue.Clock.utc_now()
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

  defp recovery_state(true, _error), do: "loading"
  defp recovery_state(false, error) when not is_nil(error), do: "error"
  defp recovery_state(false, _error), do: "ready"

  defp assign_shell(socket, admin) do
    current_path = (admin["mount_path"] || "/billing") <> "/analytics/recovery"

    socket
    |> assign(:page_title, Copy.recovery_index_heading())
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
