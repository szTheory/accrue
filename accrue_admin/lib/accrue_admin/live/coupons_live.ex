defmodule AccrueAdmin.Live.CouponsLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.{Coupon, PromotionCode}
  alias Accrue.Repo
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, DataTable, KpiCard}
  alias AccrueAdmin.Queries.Coupons

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:params, %{})
     |> assign(:table_path, admin_path(admin, "/coupons"))
     |> assign(:promotion_codes_path, admin_path(admin, "/promotion-codes"))
     |> assign(:summary, coupon_summary())}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :params, params)}
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
    >
      <section class="ax-page">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: "Dashboard", href: @admin_mount_path},
              %{label: "Coupons"}
            ]}
          />
          <p class="ax-eyebrow">Discount management</p>
          <h2 class="ax-display">Coupons backed by local discount projections</h2>
          <p class="ax-body ax-page-copy">
            Coupon filters, validity, and redemption counts stay server-side and separate from
            promotion-code operations.
          </p>
          <p class="ax-body">
            Promotion codes have their own list and detail surface:
            <a href={@promotion_codes_path} class="ax-link">open promotion codes</a>.
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label="Coupon summary">
          <KpiCard.kpi_card label="Coupons" value={Integer.to_string(@summary.total_count)}>
            <:meta>All local coupon rows</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Valid"
            value={Integer.to_string(@summary.valid_count)}
            delta={Integer.to_string(@summary.invalid_count) <> " invalid"}
            delta_tone="amber"
          >
            <:meta>Current validity flag from the local projection</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Promotion codes"
            value={Integer.to_string(@summary.promotion_code_count)}
            delta={Integer.to_string(@summary.redeemed_count) <> " coupon redemptions"}
            delta_tone="cobalt"
          >
            <:meta>Separate child-code surface linked back to coupons</:meta>
          </KpiCard.kpi_card>
        </section>

        <.live_component
          module={DataTable}
          id="coupons"
          query_module={Coupons}
          path={@table_path}
          params={@params}
          columns={[
            %{label: "Coupon", render: &coupon_link(&1, @admin_mount_path)},
            %{label: "Discount", render: &discount_summary/1},
            %{label: "Redemptions", render: &redemption_summary/1},
            %{label: "Status", render: &status_summary/1},
            %{label: "Redeem by", render: &redeem_by_summary/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: "Discount", render: &discount_summary/1},
            %{label: "Redemptions", render: &redemption_summary/1},
            %{label: "Status", render: &status_summary/1},
            %{label: "Redeem by", render: &redeem_by_summary/1}
          ]}
          filter_fields={[
            %{id: :q, label: "Search"},
            %{
              id: :valid,
              label: "Validity",
              type: :select,
              options: [{"true", "Valid"}, {"false", "Invalid"}]
            }
          ]}
          empty_title="No coupons matched"
          empty_copy="Adjust the discount filters or wait for the next projection sync."
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Coupons")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/coupons"))
  end

  defp coupon_summary do
    %{
      total_count: Repo.aggregate(Coupon, :count, :id),
      valid_count: Coupon |> where([coupon], coupon.valid == true) |> Repo.aggregate(:count, :id),
      invalid_count:
        Coupon |> where([coupon], coupon.valid == false) |> Repo.aggregate(:count, :id),
      promotion_code_count: Repo.aggregate(PromotionCode, :count, :id),
      redeemed_count:
        Coupon
        |> select([coupon], coalesce(sum(coupon.times_redeemed), 0))
        |> Repo.one()
        |> Kernel.||(0)
    }
  end

  defp coupon_link(row, mount_path),
    do: safe_link("#{mount_path}/coupons/#{row.id}", coupon_label(row))

  defp coupon_label(row), do: row.name || row.processor_id || row.id

  defp discount_summary(%{amount_off_minor: amount, currency: currency})
       when is_integer(amount) and amount > 0,
       do: format_minor(amount, currency)

  defp discount_summary(%{amount_off_cents: amount, currency: currency})
       when is_integer(amount) and amount > 0,
       do: format_minor(amount, currency)

  defp discount_summary(%{percent_off: %Decimal{} = percent}),
    do: Decimal.to_string(percent, :normal) <> "% off"

  defp discount_summary(_row), do: "Processor-defined"

  defp redemption_summary(row) do
    used = row.times_redeemed || 0

    case row.max_redemptions do
      nil -> "#{used} used"
      max -> "#{used} of #{max}"
    end
  end

  defp status_summary(%{valid: true}), do: "Valid"
  defp status_summary(%{valid: false}), do: "Invalid"

  defp redeem_by_summary(%{redeem_by: %DateTime{} = value}), do: format_datetime(value)
  defp redeem_by_summary(_row), do: "No expiry"

  defp card_title(row), do: coupon_label(row)

  defp safe_link(href, label) do
    escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<a href="#{href}" class="ax-link">#{escaped}</a>))
  end

  defp format_minor(amount_minor, currency) when is_integer(amount_minor) do
    dollars = amount_minor / 100
    code = currency |> to_string() |> String.upcase()
    :erlang.float_to_binary(dollars, decimals: 2) <> " " <> code
  end

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
