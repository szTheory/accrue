defmodule AccrueAdmin.Live.CouponLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.{Coupon, PromotionCode}
  alias Accrue.Repo
  alias AccrueAdmin.Components.{AppShell, Breadcrumbs, JsonViewer, KpiCard}

  @impl true
  def mount(%{"id" => coupon_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case Repo.get(Coupon, coupon_id) do
      nil ->
        {:ok, redirect(socket, to: admin_path(admin, "/coupons"))}

      coupon ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:coupon, coupon)
         |> assign(:promotion_codes, promotion_codes(coupon.id))}
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
              %{label: "Coupons", href: @admin_mount_path <> "/coupons"},
              %{label: coupon_label(@coupon)}
            ]}
          />
          <p class="ax-eyebrow">Coupon detail</p>
          <h2 class="ax-display"><%= coupon_label(@coupon) %></h2>
          <p class="ax-body ax-page-copy">
            <%= @coupon.processor_id || @coupon.id %> ·
            <%= discount_summary(@coupon) %> ·
            <%= status_summary(@coupon) %>
          </p>
        </header>

        <section class="ax-kpi-grid" aria-label="Coupon summary">
          <KpiCard.kpi_card label="Redemptions" value={Integer.to_string(@coupon.times_redeemed || 0)}>
            <:meta><%= max_redemptions_summary(@coupon) %></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label="Promotion codes" value={Integer.to_string(length(@promotion_codes))}>
            <:meta>Explicit child codes linked to this coupon</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label="Redeem by" value={redeem_by_summary(@coupon)}>
            <:meta>Local expiry boundary for operator review</:meta>
          </KpiCard.kpi_card>
        </section>

        <section class="ax-card">
          <header class="ax-page-header">
            <p class="ax-eyebrow">Promotion codes</p>
            <h3 class="ax-heading">Codes linked to this coupon</h3>
          </header>

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
            No promotion codes currently reference this coupon.
          </p>
        </section>

        <section class="ax-card">
          <header class="ax-page-header">
            <p class="ax-eyebrow">Projection details</p>
            <h3 class="ax-heading">Coupon metadata and processor mirror</h3>
          </header>

          <div class="ax-page">
            <p class="ax-body">Duration: <%= duration_summary(@coupon) %></p>
            <p class="ax-body">Currency: <%= @coupon.currency || "--" %></p>
            <p class="ax-body">Processor: <%= @coupon.processor || "--" %></p>
          </div>
        </section>

        <JsonViewer.json_viewer id="coupon-payload" label="Coupon payload" payload={payload(@coupon)} />
      </section>
    </AppShell.app_shell>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Coupon")
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

  defp discount_summary(_coupon), do: "Processor-defined"

  defp status_summary(%{valid: true}), do: "Valid"
  defp status_summary(%{valid: false}), do: "Invalid"

  defp redeem_by_summary(%{redeem_by: %DateTime{} = value}), do: format_datetime(value)
  defp redeem_by_summary(_coupon), do: "No expiry"

  defp max_redemptions_summary(%{max_redemptions: nil}), do: "Unlimited cap"
  defp max_redemptions_summary(%{max_redemptions: max}), do: "#{max} max"

  defp duration_summary(%{duration: nil}), do: "One-off"

  defp duration_summary(%{duration: "repeating", duration_in_months: months})
       when is_integer(months),
       do: "Repeating for #{months} months"

  defp duration_summary(%{duration: duration}) when is_binary(duration),
    do: String.capitalize(duration)

  defp duration_summary(_coupon), do: "--"

  defp promotion_code_status(%{active: true, expires_at: %DateTime{} = expires_at}),
    do: "Active until " <> format_datetime(expires_at)

  defp promotion_code_status(%{active: true}), do: "Active"
  defp promotion_code_status(%{active: false}), do: "Inactive"

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

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
