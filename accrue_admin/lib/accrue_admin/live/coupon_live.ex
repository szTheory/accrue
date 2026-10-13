defmodule AccrueAdmin.Live.CouponLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.Billing.{Coupon, PromotionCode}
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    JsonViewer,
    RelatedResources,
    Timeline
  }

  alias AccrueAdmin.Components.Timestamp

  alias AccrueAdmin.ScopedPath

  @impl true
  def mount(%{"id" => coupon_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case read_coupon(coupon_id) do
      :unavailable ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:coupon_id, coupon_id)
         |> assign(:coupon, nil)
         |> assign(:promotion_codes, [])
         |> assign(:related_items, [])
         |> assign(:activity_loaded?, false)
         |> assign(:raw_json_loaded?, false)
         |> assign(:read_unavailable?, true)}

      nil ->
        {:ok,
         socket
         |> put_flash(:error, AccrueAdmin.Copy.coupon_not_found())
         |> redirect(to: admin_path(admin, "/coupons"))}

      {:ok, coupon, codes} ->
        mount_path = admin["mount_path"] || "/billing"
        scope = socket.assigns.current_owner_scope

        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:coupon_id, coupon_id)
         |> assign(:coupon, coupon)
         |> assign(:promotion_codes, codes)
         |> assign(:related_items, related_items(coupon, mount_path, scope))
         |> assign(:activity_loaded?, false)
         |> assign(:raw_json_loaded?, false)
         |> assign(:read_unavailable?, false)}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    destination =
      ScopedPath.return_destination(
        socket.assigns.admin_mount_path,
        Map.get(params, "return_to"),
        socket.assigns.current_owner_scope,
        nil,
        "/coupons"
      )

    {:noreply,
     socket
     |> assign(:return_path, destination.path)
     |> assign(:return_label, destination.label)}
  end

  def handle_event("retry_read", _params, socket) do
    case read_coupon(socket.assigns.coupon_id) do
      {:ok, coupon, codes} ->
        {:noreply,
         socket
         |> assign(:coupon, coupon)
         |> assign(:promotion_codes, codes)
         |> assign(
           :related_items,
           related_items(
             coupon,
             socket.assigns.admin_mount_path,
             socket.assigns.current_owner_scope
           )
         )
         |> assign(:read_unavailable?, false)}

      :unavailable ->
        {:noreply, assign(socket, :read_unavailable?, true)}

      nil ->
        {:noreply,
         socket
         |> put_flash(:error, AccrueAdmin.Copy.coupon_not_found())
         |> redirect(
           to: admin_path(%{"mount_path" => socket.assigns.admin_mount_path}, "/coupons")
         )}
    end
  end

  @impl true
  def handle_event("load_activity", _params, socket) do
    {:noreply, assign(socket, :activity_loaded?, true)}
  end

  def handle_event("load_raw_json", _params, socket) do
    {:noreply, assign(socket, :raw_json_loaded?, true)}
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
      <section class="ax-page">
        <div :if={@read_unavailable?} class="ax-card ax-data-table-unavailable" data-role="coupon-unavailable" role="alert">
          <p class="ax-heading">Coupon record unavailable</p>
          <p class="ax-body">This coupon and its related codes could not be loaded. Their details are unknown until the read succeeds.</p>
          <button type="button" phx-click="retry_read" class="ax-button ax-button-secondary" data-role="retry-coupon-read">Retry</button>
        </div>
        <Breadcrumbs.breadcrumbs
          group="Catalog"
          :if={@coupon}
          items={[
            %{
              label: AccrueAdmin.Copy.coupon_breadcrumb_coupons(),
              href: ScopedPath.build(@admin_mount_path, "/coupons", @current_owner_scope)
            },
            %{label: coupon_label(@coupon)}
          ]}
        />
        <p :if={@coupon} class="ax-body"><a class="ax-link" href={@return_path}><%= @return_label %></a></p>

        <Detail.summary_card
          :if={@coupon}
          eyebrow={AccrueAdmin.Copy.coupon_detail_eyebrow()}
          title={coupon_label(@coupon)}
        >
          <:facts>
            <span><%= @coupon.processor_id || @coupon.id %></span>
            <span><%= discount_summary(@coupon) %></span>
            <span><%= status_summary(@coupon) %></span>
          </:facts>
        </Detail.summary_card>

        <Detail.summary_list :if={@coupon} rows={summary_rows(@coupon, @promotion_codes)} />

        <section :if={@coupon} class="ax-stack-xl" aria-label="Coupon details">
          <details class="ax-detail-section" data-ax-drill-section="promotion-codes" open>
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title"><%= AccrueAdmin.Copy.coupon_detail_section_codes_heading() %></span>
            </summary>

            <div :for={promotion_code <- @promotion_codes} class="ax-list-row">
              <a
                href={
                  ScopedPath.build(
                    @admin_mount_path,
                    "/promotion-codes/#{promotion_code.id}",
                    @current_owner_scope,
                    %{"return_to" => ScopedPath.build(@admin_mount_path, "/promotion-codes", @current_owner_scope, %{"coupon_id" => @coupon.id})}
                  )
                }
                class="ax-link"
              >
                <%= promotion_code.code || promotion_code.processor_id || promotion_code.id %>
              </a>
              <Detail.detail_field_list fields={promotion_code_drill_fields(promotion_code)} />
            </div>

            <p :if={@promotion_codes == []} class="ax-body">
              <%= coupon_promotion_codes_empty_body() %>
            </p>
          </details>

          <details class="ax-detail-section" data-ax-drill-section="projection-details">
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title"><%= AccrueAdmin.Copy.coupon_detail_section_projection_heading() %></span>
            </summary>
            <Detail.detail_field_list fields={projection_detail_fields(@coupon)} />
          </details>
        </section>

        <div :if={@coupon} data-ax-related-resources>
          <RelatedResources.related_resources items={@related_items} />
        </div>

        <details :if={@coupon} class="ax-detail-section" data-ax-lazy-activity phx-click="load_activity">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title"><%= AccrueAdmin.Copy.coupon_lazy_activity_heading() %></span>
          </summary>
          <%= if @activity_loaded? do %>
            <Timeline.timeline
              label={AccrueAdmin.Copy.coupon_lazy_activity_label()}
              empty_label={AccrueAdmin.Copy.coupon_lazy_activity_empty_label()}
              items={activity_items(@coupon)}
            />
            <p :if={activity_items(@coupon) == []} class="ax-body">
              <%= coupon_activity_empty_body() %>
            </p>
          <% else %>
            <p class="ax-body"><%= AccrueAdmin.Copy.coupon_lazy_activity_prompt() %></p>
          <% end %>
        </details>

        <details :if={@coupon} class="ax-detail-section" data-ax-lazy-json phx-click="load_raw_json">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title"><%= AccrueAdmin.Copy.coupon_lazy_raw_data_heading() %></span>
          </summary>
          <%= if @raw_json_loaded? do %>
            <JsonViewer.json_viewer id="coupon-payload" label={AccrueAdmin.Copy.coupon_json_payload_label()} payload={raw_payload(@coupon)} />
          <% else %>
            <p class="ax-body"><%= AccrueAdmin.Copy.coupon_lazy_raw_data_prompt() %></p>
          <% end %>
        </details>
      </section>
    </AppShell.app_shell>
    """
  end

  defp read_coupon(coupon_id) do
    try do
      if Application.get_env(:accrue_admin, :env) == :test and
           Application.get_env(:accrue_admin, :phase238_read_failure_fixture) == :coupon_detail do
        raise DBConnection.ConnectionError, message: "fixture database unavailable"
      end

      case Repo.get(Coupon, coupon_id) do
        nil -> nil
        coupon -> {:ok, coupon, promotion_codes(coupon.id)}
      end
    rescue
      _error in DBConnection.ConnectionError -> :unavailable
    end
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

  defp summary_rows(coupon, promotion_codes) do
    [
      %{label: "Valid state", value: status_summary(coupon)},
      %{label: "Discount", value: discount_summary(coupon)},
      %{label: "Duration", value: duration_summary(coupon)},
      %{label: "Redeem by", value: redeem_by_summary(coupon)},
      %{label: "Max redemptions", value: max_redemptions_summary(coupon)},
      %{label: "Current redemptions", value: redemptions_summary(coupon)},
      %{
        label: "Provider restrictions",
        value: AccrueAdmin.Copy.Coupon.coupon_provider_restrictions_unknown()
      },
      %{label: "Promotion codes", value: Integer.to_string(length(promotion_codes))}
    ]
  end

  defp promotion_code_drill_fields(promotion_code) do
    [
      %{label: "Status", value: promotion_code_status(promotion_code)},
      %{label: "Redemptions", value: promotion_code_redemptions(promotion_code)}
    ]
  end

  defp coupon_promotion_codes_empty_body do
    [
      AccrueAdmin.Copy.resource_state_copy(:promotion_codes, :first_run_empty).body,
      AccrueAdmin.Copy.coupon_detail_promotion_codes_empty()
    ]
    |> Enum.join(" ")
  end

  defp coupon_activity_empty_body do
    [
      AccrueAdmin.Copy.resource_state_copy(:coupons, :queue_empty).body,
      AccrueAdmin.Copy.coupon_lazy_activity_empty_body()
    ]
    |> Enum.join(" ")
  end

  defp projection_detail_fields(coupon) do
    [
      %{label: AccrueAdmin.Copy.coupon_detail_label_duration(), value: duration_summary(coupon)},
      %{
        label: AccrueAdmin.Copy.coupon_detail_label_currency(),
        value: coupon.currency || "Unavailable"
      },
      %{
        label: AccrueAdmin.Copy.coupon_detail_label_processor(),
        value: coupon.processor || "Unavailable"
      }
    ]
  end

  defp activity_items(_coupon), do: []

  defp raw_payload(coupon) do
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
  defp status_summary(_coupon), do: AccrueAdmin.Copy.Coupon.coupon_unknown_value()

  defp redeem_by_summary(%{redeem_by: %DateTime{} = value} = coupon),
    do: timestamp_value(value, "coupon-redeem-by-#{coupon.id}")

  defp redeem_by_summary(_coupon), do: AccrueAdmin.Copy.coupon_redeem_by_no_expiry()

  defp max_redemptions_summary(%{max_redemptions: nil}),
    do: AccrueAdmin.Copy.coupon_kpi_meta_redemptions_cap()

  defp max_redemptions_summary(%{max_redemptions: max}), do: "#{max} max"

  defp redemptions_summary(%{times_redeemed: count}) when is_integer(count),
    do: Integer.to_string(count)

  defp redemptions_summary(_coupon), do: AccrueAdmin.Copy.Coupon.coupon_redemptions_unknown()

  defp duration_summary(%{duration: nil}), do: "One-off"

  defp duration_summary(%{duration: "repeating", duration_in_months: months})
       when is_integer(months),
       do: "Repeating for #{months} months"

  defp duration_summary(%{duration: duration}) when is_binary(duration),
    do: String.capitalize(duration)

  defp duration_summary(_coupon), do: "Unavailable"

  defp promotion_code_status(%{active: true, expires_at: %DateTime{} = expires_at} = code) do
    assigns = %{
      value: expires_at,
      id: "coupon-promotion-code-expires-#{code.id}",
      prefix: AccrueAdmin.Copy.coupon_promotion_code_status_active_until_prefix()
    }

    ~H"""
    <span><%= @prefix %> <Timestamp.timestamp value={@value} id={@id} /></span>
    """
  end

  defp promotion_code_status(%{active: true}),
    do: AccrueAdmin.Copy.coupon_promotion_code_status_active()

  defp promotion_code_status(%{active: false}),
    do: AccrueAdmin.Copy.coupon_promotion_code_status_inactive()

  defp promotion_code_status(_promotion_code), do: AccrueAdmin.Copy.Coupon.coupon_unknown_value()

  defp promotion_code_redemptions(%{times_redeemed: used}) when is_integer(used),
    do: Integer.to_string(used)

  defp promotion_code_redemptions(_promotion_code),
    do: AccrueAdmin.Copy.Coupon.coupon_redemptions_unknown()

  defp format_minor(amount_minor, currency) when is_integer(amount_minor) do
    case normalize_currency(currency) do
      {:ok, currency_atom} ->
        Accrue.Invoices.Render.format_money(
          amount_minor,
          currency_atom,
          Accrue.Config.default_locale()
        )

      {:error, :missing} ->
        "Amount unavailable (currency missing)"

      {:error, {:unsupported, code}} ->
        "Amount unavailable (unsupported currency: #{code})"

      {:error, :unknown} ->
        "Amount unavailable (currency unknown)"
    end
  end

  defp normalize_currency(nil), do: {:error, :missing}

  defp normalize_currency(currency) when is_atom(currency) do
    case Money.Currency.currency_for_code(Atom.to_string(currency)) do
      {:ok, _currency} -> {:ok, currency}
      _unknown -> {:error, {:unsupported, Atom.to_string(currency)}}
    end
  end

  defp normalize_currency(currency) when is_binary(currency) do
    code = String.downcase(currency)

    try do
      code
      |> String.to_existing_atom()
      |> normalize_currency()
    rescue
      ArgumentError -> {:error, {:unsupported, currency}}
    end
  end

  defp normalize_currency(_currency), do: {:error, :unknown}

  defp timestamp_value(value, id) do
    assigns = %{value: value, id: id}

    ~H"""
    <Timestamp.timestamp value={@value} id={@id} />
    """
  end

  defp related_items(coupon, mount_path, scope) do
    [
      %{
        icon: :promotions,
        label: "Promotion codes",
        href: ScopedPath.build(mount_path, "/promotion-codes", scope, %{"coupon_id" => coupon.id})
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
