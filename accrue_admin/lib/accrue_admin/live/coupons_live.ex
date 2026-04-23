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
    active_organization_name={@active_organization_name}
    >
      <section class="ax-page">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: "Dashboard", href: @admin_mount_path},
              %{label: AccrueAdmin.Copy.coupon_breadcrumb_coupons()}
            ]}
          />
          <p class="ax-eyebrow"><%= AccrueAdmin.Copy.coupon_index_eyebrow() %></p>
          <h2 class="ax-display"><%= AccrueAdmin.Copy.coupon_index_headline() %></h2>
          <p class="ax-body ax-page-copy">
            <%= AccrueAdmin.Copy.coupon_index_body_primary() %>
          </p>
          <p class="ax-body">
            <%= AccrueAdmin.Copy.coupon_index_body_link_prefix() %>
            <a href={@promotion_codes_path} class="ax-link"><%= AccrueAdmin.Copy.coupon_index_promotion_codes_link_text() %></a>.
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label={AccrueAdmin.Copy.coupon_index_kpi_section_aria_label()}>
          <KpiCard.kpi_card label={AccrueAdmin.Copy.coupon_kpi_label_coupons()} value={Integer.to_string(@summary.total_count)}>
            <:meta><%= AccrueAdmin.Copy.coupon_kpi_meta_all_local_coupons() %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label={AccrueAdmin.Copy.coupon_kpi_label_valid()}
            value={Integer.to_string(@summary.valid_count)}
            delta={Integer.to_string(@summary.invalid_count) <> AccrueAdmin.Copy.coupon_kpi_invalid_suffix()}
            delta_tone="amber"
          >
            <:meta><%= AccrueAdmin.Copy.coupon_kpi_meta_validity_projection() %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label={AccrueAdmin.Copy.coupon_kpi_label_promotion_codes()}
            value={Integer.to_string(@summary.promotion_code_count)}
            delta={Integer.to_string(@summary.redeemed_count) <> AccrueAdmin.Copy.coupon_kpi_redemptions_suffix()}
            delta_tone="cobalt"
          >
            <:meta><%= AccrueAdmin.Copy.coupon_kpi_meta_promotion_codes_child() %></:meta>
          </KpiCard.kpi_card>
        </section>

        <.live_component
          module={DataTable}
          id="coupons"
          query_module={Coupons}
          current_owner_scope={@current_owner_scope}
          path={@table_path}
          params={@params}
          columns={[
            %{label: AccrueAdmin.Copy.coupon_table_column_coupon(), render: &coupon_link(&1, @admin_mount_path)},
            %{label: AccrueAdmin.Copy.coupon_table_column_discount(), render: &discount_summary/1},
            %{label: AccrueAdmin.Copy.coupon_table_column_redemptions(), render: &redemption_summary/1},
            %{label: AccrueAdmin.Copy.coupon_table_column_status(), render: &status_summary/1},
            %{label: AccrueAdmin.Copy.coupon_table_column_redeem_by(), render: &redeem_by_summary/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: AccrueAdmin.Copy.coupon_table_column_discount(), render: &discount_summary/1},
            %{label: AccrueAdmin.Copy.coupon_table_column_redemptions(), render: &redemption_summary/1},
            %{label: AccrueAdmin.Copy.coupon_table_column_status(), render: &status_summary/1},
            %{label: AccrueAdmin.Copy.coupon_table_column_redeem_by(), render: &redeem_by_summary/1}
          ]}
          filter_fields={[
            %{id: :q, label: AccrueAdmin.Copy.coupon_filter_label_search()},
            %{
              id: :valid,
              label: AccrueAdmin.Copy.coupon_filter_label_validity(),
              type: :select,
              options: [
                {"true", AccrueAdmin.Copy.coupon_filter_option_valid()},
                {"false", AccrueAdmin.Copy.coupon_filter_option_invalid()}
              ]
            }
          ]}
          empty_title={AccrueAdmin.Copy.coupon_table_empty_title()}
          empty_copy={AccrueAdmin.Copy.coupon_table_empty_copy()}
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, AccrueAdmin.Copy.coupon_page_title_index())
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

  defp discount_summary(_row), do: AccrueAdmin.Copy.coupon_discount_processor_defined()

  defp redemption_summary(row) do
    used = row.times_redeemed || 0

    case row.max_redemptions do
      nil -> "#{used} used"
      max -> "#{used} of #{max}"
    end
  end

  defp status_summary(%{valid: true}), do: AccrueAdmin.Copy.coupon_status_valid()
  defp status_summary(%{valid: false}), do: AccrueAdmin.Copy.coupon_status_invalid()

  defp redeem_by_summary(%{redeem_by: %DateTime{} = value}), do: format_datetime(value)
  defp redeem_by_summary(_row), do: AccrueAdmin.Copy.coupon_redeem_by_no_expiry()

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
