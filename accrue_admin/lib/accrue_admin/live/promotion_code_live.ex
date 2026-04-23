defmodule AccrueAdmin.Live.PromotionCodeLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.Billing.PromotionCode
  alias Accrue.Repo
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, JsonViewer, KpiCard}

  @impl true
  def mount(%{"id" => promotion_code_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case Repo.get(PromotionCode, promotion_code_id) |> maybe_preload_coupon() do
      nil ->
        {:ok, redirect(socket, to: admin_path(admin, "/promotion-codes"))}

      promotion_code ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:promotion_code, promotion_code)}
    end
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
              %{label: AccrueAdmin.Copy.promotion_codes_breadcrumb_index(), href: @admin_mount_path <> "/promotion-codes"},
              %{label: @promotion_code.code || @promotion_code.processor_id || @promotion_code.id}
            ]}
          />
          <p class="ax-eyebrow"><%= AccrueAdmin.Copy.promotion_code_detail_eyebrow() %></p>
          <h2 class="ax-display"><%= @promotion_code.code || @promotion_code.processor_id %></h2>
          <p class="ax-body ax-page-copy">
            <%= status_summary(@promotion_code) %> · <%= redemption_summary(@promotion_code) %>
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label={AccrueAdmin.Copy.promotion_code_detail_kpi_section_aria_label()}>
          <KpiCard.kpi_card label={AccrueAdmin.Copy.promotion_code_kpi_label_coupon()} value={coupon_label(@promotion_code)}>
            <:meta><%= AccrueAdmin.Copy.promotion_code_kpi_meta_parent_discount() %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label={AccrueAdmin.Copy.promotion_code_kpi_label_redemptions()} value={Integer.to_string(@promotion_code.times_redeemed || 0)}>
            <:meta><%= max_redemptions_summary(@promotion_code) %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label={AccrueAdmin.Copy.promotion_code_kpi_label_expires()} value={expires_summary(@promotion_code)}>
            <:meta><%= AccrueAdmin.Copy.promotion_code_kpi_meta_expiry_boundary() %></:meta>
          </KpiCard.kpi_card>
        </section>

        <section class="ax-card">
          <header class="ax-page-header">
            <p class="ax-eyebrow"><%= AccrueAdmin.Copy.promotion_code_section_parent_coupon_eyebrow() %></p>
            <h3 class="ax-heading"><%= AccrueAdmin.Copy.promotion_code_section_navigate_heading() %></h3>
          </header>

          <p :if={@promotion_code.coupon} class="ax-body">
            <a href={@admin_mount_path <> "/coupons/" <> @promotion_code.coupon.id} class="ax-link">
              <%= @promotion_code.coupon.name || @promotion_code.coupon.processor_id || @promotion_code.coupon.id %>
            </a>
          </p>

          <p :if={!@promotion_code.coupon} class="ax-body">
            <%= AccrueAdmin.Copy.promotion_code_detail_no_coupon_projection() %>
          </p>
        </section>

        <JsonViewer.json_viewer
          id="promotion-code-payload"
          label={AccrueAdmin.Copy.promotion_code_json_payload_label()}
          payload={payload(@promotion_code)}
        />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, AccrueAdmin.Copy.promotion_code_page_title_show())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/promotion-codes"))
  end

  defp maybe_preload_coupon(nil), do: nil
  defp maybe_preload_coupon(promotion_code), do: Repo.preload(promotion_code, :coupon)

  defp payload(promotion_code) do
    %{
      "metadata" => promotion_code.metadata || %{},
      "data" => promotion_code.data || %{},
      "processor_id" => promotion_code.processor_id,
      "coupon_id" => promotion_code.coupon_id,
      "last_stripe_event_id" => promotion_code.last_stripe_event_id
    }
  end

  defp coupon_label(%{coupon: %{name: name}}) when is_binary(name), do: name

  defp coupon_label(%{coupon: %{processor_id: processor_id}}) when is_binary(processor_id),
    do: processor_id

  defp coupon_label(%{coupon_id: nil}), do: AccrueAdmin.Copy.promotion_codes_coupon_none_label()
  defp coupon_label(%{coupon_id: coupon_id}), do: coupon_id

  defp status_summary(%{active: true, expires_at: %DateTime{} = expires_at}),
    do:
      AccrueAdmin.Copy.promotion_codes_status_active_expires_separator() <>
        format_datetime(expires_at)

  defp status_summary(%{active: true}), do: AccrueAdmin.Copy.promotion_codes_status_active()
  defp status_summary(%{active: false}), do: AccrueAdmin.Copy.promotion_codes_status_inactive()

  defp redemption_summary(%{times_redeemed: used, max_redemptions: nil}), do: "#{used || 0} used"

  defp redemption_summary(%{times_redeemed: used, max_redemptions: max}),
    do: "#{used || 0} of #{max}"

  defp max_redemptions_summary(%{max_redemptions: nil}),
    do: AccrueAdmin.Copy.promotion_code_kpi_meta_unlimited_cap()

  defp max_redemptions_summary(%{max_redemptions: max}), do: "#{max} max"

  defp expires_summary(%{expires_at: %DateTime{} = value}), do: format_datetime(value)
  defp expires_summary(_promotion_code), do: AccrueAdmin.Copy.promotion_code_redeem_by_no_expiry()

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
