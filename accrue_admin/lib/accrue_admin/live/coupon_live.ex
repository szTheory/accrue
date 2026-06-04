defmodule AccrueAdmin.Live.CouponLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.{Coupon, PromotionCode}
  alias Accrue.Repo
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, Detail, JsonViewer, KpiCard, RelatedResources}
  alias AccrueAdmin.ScopedPath

  @impl true
  def mount(%{"id" => coupon_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case Repo.get(Coupon, coupon_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, AccrueAdmin.Copy.coupon_not_found())
         |> redirect(to: admin_path(admin, "/coupons"))}

      coupon ->
        mount_path = admin["mount_path"] || "/billing"
        scope = socket.assigns.current_owner_scope

        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:coupon, coupon)
         |> assign(:promotion_codes, promotion_codes(coupon.id))
         |> assign(:related_items, related_items(coupon, mount_path, scope))}
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
        <Breadcrumbs.breadcrumbs
          items={[
            %{label: "Dashboard", href: @admin_mount_path},
            %{label: AccrueAdmin.Copy.coupon_breadcrumb_coupons(), href: @admin_mount_path <> "/coupons"},
            %{label: coupon_label(@coupon)}
          ]}
        />

        <Detail.summary_card
          eyebrow={AccrueAdmin.Copy.coupon_detail_eyebrow()}
          title={coupon_label(@coupon)}
        >
          <:facts>
            <span><%= @coupon.processor_id || @coupon.id %></span>
            <span><%= discount_summary(@coupon) %></span>
            <span><%= status_summary(@coupon) %></span>
          </:facts>
        </Detail.summary_card>

        <section class="ax-kpi-grid" aria-label={AccrueAdmin.Copy.coupon_detail_kpi_section_aria_label()}>
          <KpiCard.kpi_card label={AccrueAdmin.Copy.coupon_kpi_label_redemptions()} value={Integer.to_string(@coupon.times_redeemed || 0)}>
            <:meta><%= max_redemptions_summary(@coupon) %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label={AccrueAdmin.Copy.coupon_detail_section_promotion_codes_eyebrow()} value={Integer.to_string(length(@promotion_codes))}>
            <:meta><%= AccrueAdmin.Copy.coupon_kpi_meta_promotion_codes_linked() %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label={AccrueAdmin.Copy.coupon_kpi_label_redeem_by()} value={redeem_by_summary(@coupon)}>
            <:meta><%= AccrueAdmin.Copy.coupon_kpi_meta_redeem_by() %></:meta>
          </KpiCard.kpi_card>
        </section>

        <Detail.detail_section title={AccrueAdmin.Copy.coupon_detail_section_codes_heading()}>
          <div :for={promotion_code <- @promotion_codes} class="ax-list-row">
            <a
              href={@admin_mount_path <> "/promotion-codes/" <> promotion_code.id}
              class="ax-link"
            >
              <%= promotion_code.code || promotion_code.processor_id || promotion_code.id %>
            </a>
            <span class="ax-body">
              <%= promotion_code_status(promotion_code) %> · <%= promotion_code_redemptions(promotion_code) %>
            </span>
          </div>

          <p :if={@promotion_codes == []} class="ax-body">
            <%= AccrueAdmin.Copy.coupon_detail_promotion_codes_empty() %>
          </p>
        </Detail.detail_section>

        <Detail.detail_section title={AccrueAdmin.Copy.coupon_detail_section_projection_heading()}>
          <Detail.detail_field_list fields={[
            %{label: AccrueAdmin.Copy.coupon_detail_label_duration(), value: duration_summary(@coupon)},
            %{label: AccrueAdmin.Copy.coupon_detail_label_currency(), value: @coupon.currency || "--"},
            %{label: AccrueAdmin.Copy.coupon_detail_label_processor(), value: @coupon.processor || "--"}
          ]} />
        </Detail.detail_section>

        <RelatedResources.related_resources items={@related_items} />

        <JsonViewer.json_viewer id="coupon-payload" label={AccrueAdmin.Copy.coupon_json_payload_label()} payload={payload(@coupon)} />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, AccrueAdmin.Copy.coupon_page_title_show())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/coupons"))
  end

  defp promotion_codes(coupon_id) do
    PromotionCode
    |> where([promotion_code], promotion_code.coupon_id == ^coupon_id)
    |> order_by([promotion_code], desc: promotion_code.inserted_at, desc: promotion_code.id)
    |> Repo.all()
  end

  defp payload(coupon) do
    %{
      "metadata" => coupon.metadata || %{},
      "data" => coupon.data || %{},
      "processor_id" => coupon.processor_id,
      "duration" => coupon.duration,
      "duration_in_months" => coupon.duration_in_months
    }
  end

  defp coupon_label(coupon), do: coupon.name || coupon.processor_id || coupon.id

  defp discount_summary(%{amount_off_minor: amount, currency: currency})
       when is_integer(amount) and amount > 0,
       do: format_minor(amount, currency)

  defp discount_summary(%{amount_off_cents: amount, currency: currency})
       when is_integer(amount) and amount > 0,
       do: format_minor(amount, currency)

  defp discount_summary(%{percent_off: %Decimal{} = percent}),
    do: Decimal.to_string(percent, :normal) <> "% off"

  defp discount_summary(_coupon), do: AccrueAdmin.Copy.coupon_discount_processor_defined()

  defp status_summary(%{valid: true}), do: AccrueAdmin.Copy.coupon_status_valid()
  defp status_summary(%{valid: false}), do: AccrueAdmin.Copy.coupon_status_invalid()

  defp redeem_by_summary(%{redeem_by: %DateTime{} = value}), do: format_datetime(value)
  defp redeem_by_summary(_coupon), do: AccrueAdmin.Copy.coupon_redeem_by_no_expiry()

  defp max_redemptions_summary(%{max_redemptions: nil}),
    do: AccrueAdmin.Copy.coupon_kpi_meta_redemptions_cap()

  defp max_redemptions_summary(%{max_redemptions: max}), do: "#{max} max"

  defp duration_summary(%{duration: nil}), do: "One-off"

  defp duration_summary(%{duration: "repeating", duration_in_months: months})
       when is_integer(months),
       do: "Repeating for #{months} months"

  defp duration_summary(%{duration: duration}) when is_binary(duration),
    do: String.capitalize(duration)

  defp duration_summary(_coupon), do: "--"

  defp promotion_code_status(%{active: true, expires_at: %DateTime{} = expires_at}),
    do:
      AccrueAdmin.Copy.coupon_promotion_code_status_active_until_prefix() <>
        format_datetime(expires_at)

  defp promotion_code_status(%{active: true}),
    do: AccrueAdmin.Copy.coupon_promotion_code_status_active()

  defp promotion_code_status(%{active: false}),
    do: AccrueAdmin.Copy.coupon_promotion_code_status_inactive()

  defp promotion_code_redemptions(%{times_redeemed: used, max_redemptions: nil}),
    do: "#{used || 0} used"

  defp promotion_code_redemptions(%{times_redeemed: used, max_redemptions: max}),
    do: "#{used || 0} of #{max}"

  defp format_minor(amount_minor, currency) when is_integer(amount_minor) do
    dollars = amount_minor / 100
    code = currency |> to_string() |> String.upcase()
    :erlang.float_to_binary(dollars, decimals: 2) <> " " <> code
  end

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")

  defp related_items(coupon, mount_path, scope) do
    [
      %{
        icon: :promotions,
        label: "Promotion codes",
        href: ScopedPath.build(mount_path, "/promotion-codes", scope)
      },
      %{
        icon: :events,
        label: "Events",
        href:
          ScopedPath.build(mount_path, "/events", scope, %{
            "subject_type" => "Coupon",
            "subject_id" => coupon.id
          })
      }
    ]
  end

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
