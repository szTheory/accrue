defmodule AccrueAdmin.Live.PromotionCodesLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.PromotionCode
  alias Accrue.Repo
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, DataTable, KpiCard}
  alias AccrueAdmin.Queries.PromotionCodes

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    {:ok,
     socket
     |> assign_shell(admin)
     |> assign(:params, %{})
     |> assign(:table_path, admin_path(admin, "/promotion-codes"))
     |> assign(:summary, promotion_code_summary())}
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
              %{label: "Promotion codes"}
            ]}
          />
          <p class="ax-eyebrow">Discount management</p>
          <h2 class="ax-display">Promotion codes as a dedicated admin surface</h2>
          <p class="ax-body ax-page-copy">
            Promotion codes are searchable independently from coupons, with direct links back to
            their parent discount definition.
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label="Promotion code summary">
          <KpiCard.kpi_card label="Codes" value={Integer.to_string(@summary.total_count)}>
            <:meta>All local promotion code rows</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Active"
            value={Integer.to_string(@summary.active_count)}
            delta={Integer.to_string(@summary.inactive_count) <> " inactive"}
            delta_tone="amber"
          >
            <:meta>Operator-visible activation state</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Expiring"
            value={Integer.to_string(@summary.expiring_count)}
            delta={Integer.to_string(@summary.redeemed_count) <> " redemptions"}
            delta_tone="cobalt"
          >
            <:meta>Codes with an explicit expiry timestamp</:meta>
          </KpiCard.kpi_card>
        </section>

        <.live_component
          module={DataTable}
          id="promotion-codes"
          query_module={PromotionCodes}
          path={@table_path}
          params={@params}
          columns={[
            %{label: "Promotion code", render: &promotion_code_link(&1, @admin_mount_path)},
            %{label: "Coupon", render: &coupon_link(&1, @admin_mount_path)},
            %{label: "Status", render: &status_summary/1},
            %{label: "Redemptions", render: &redemption_summary/1},
            %{label: "Expires", render: &expires_summary/1}
          ]}
          card_title={&card_title/1}
          card_fields={[
            %{label: "Coupon", render: &coupon_label/1},
            %{label: "Status", render: &status_summary/1},
            %{label: "Redemptions", render: &redemption_summary/1},
            %{label: "Expires", render: &expires_summary/1}
          ]}
          filter_fields={[
            %{id: :q, label: "Search"},
            %{
              id: :active,
              label: "Status",
              type: :select,
              options: [{"true", "Active"}, {"false", "Inactive"}]
            },
            %{id: :coupon_id, label: "Coupon id"}
          ]}
          empty_title="No promotion codes matched"
          empty_copy="Adjust the code filters or wait for the next projection sync."
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Promotion Codes")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/promotion-codes"))
  end

  defp promotion_code_summary do
    now = DateTime.utc_now()

    %{
      total_count: Repo.aggregate(PromotionCode, :count, :id),
      active_count:
        PromotionCode
        |> where([promotion_code], promotion_code.active == true)
        |> Repo.aggregate(:count, :id),
      inactive_count:
        PromotionCode
        |> where([promotion_code], promotion_code.active == false)
        |> Repo.aggregate(:count, :id),
      expiring_count:
        PromotionCode
        |> where(
          [promotion_code],
          not is_nil(promotion_code.expires_at) and promotion_code.expires_at >= ^now
        )
        |> Repo.aggregate(:count, :id),
      redeemed_count:
        PromotionCode
        |> select([promotion_code], coalesce(sum(promotion_code.times_redeemed), 0))
        |> Repo.one()
        |> Kernel.||(0)
    }
  end

  defp promotion_code_link(row, mount_path),
    do:
      safe_link("#{mount_path}/promotion-codes/#{row.id}", row.code || row.processor_id || row.id)

  defp coupon_link(%{coupon_id: nil}, _mount_path), do: "No coupon linked"

  defp coupon_link(row, mount_path),
    do: safe_link("#{mount_path}/coupons/#{row.coupon_id}", coupon_label(row))

  defp coupon_label(%{coupon_name: nil, coupon_id: nil}), do: "No coupon linked"
  defp coupon_label(%{coupon_name: nil, coupon_id: coupon_id}), do: coupon_id
  defp coupon_label(%{coupon_name: coupon_name}), do: coupon_name

  defp status_summary(%{active: true, expires_at: %DateTime{} = expires_at}),
    do: "Active · expires " <> format_datetime(expires_at)

  defp status_summary(%{active: true}), do: "Active"
  defp status_summary(%{active: false}), do: "Inactive"

  defp redemption_summary(row) do
    used = row.times_redeemed || 0

    case row.max_redemptions do
      nil -> "#{used} used"
      max -> "#{used} of #{max}"
    end
  end

  defp expires_summary(%{expires_at: %DateTime{} = value}), do: format_datetime(value)
  defp expires_summary(_row), do: "No expiry"

  defp card_title(row), do: row.code || row.processor_id || row.id

  defp safe_link(href, label) do
    escaped = label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    Phoenix.HTML.raw(~s(<a href="#{href}" class="ax-link">#{escaped}</a>))
  end

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
