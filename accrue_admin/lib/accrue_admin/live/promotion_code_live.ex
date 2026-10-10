defmodule AccrueAdmin.Live.PromotionCodeLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.Billing.PromotionCode
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    JsonViewer,
    RelatedResources,
    Timeline
  }

  alias AccrueAdmin.ScopedPath

  @impl true
  def mount(%{"id" => promotion_code_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case read_promotion_code(promotion_code_id) do
      :unavailable ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:promotion_code_id, promotion_code_id)
         |> assign(:promotion_code, nil)
         |> assign(:related_items, [])
         |> assign(:activity_loaded?, false)
         |> assign(:raw_json_loaded?, false)
         |> assign(:read_unavailable?, true)}

      nil ->
        {:ok,
         socket
         |> put_flash(:error, AccrueAdmin.Copy.promotion_code_not_found())
         |> redirect(to: admin_path(admin, "/promotion-codes"))}

      {:ok, promotion_code} ->
        mount_path = admin["mount_path"] || "/billing"
        scope = socket.assigns.current_owner_scope

        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(:promotion_code_id, promotion_code_id)
         |> assign(:promotion_code, promotion_code)
         |> assign(:related_items, related_items(promotion_code, mount_path, scope))
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
        "/promotion-codes"
      )

    {:noreply,
     socket
     |> assign(:return_path, destination.path)
     |> assign(:return_label, destination.label)}
  end

  def handle_event("retry_read", _params, socket) do
    case read_promotion_code(socket.assigns.promotion_code_id) do
      {:ok, promotion_code} ->
        {:noreply,
         socket
         |> assign(:promotion_code, promotion_code)
         |> assign(
           :related_items,
           related_items(
             promotion_code,
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
         |> put_flash(:error, AccrueAdmin.Copy.promotion_code_not_found())
         |> redirect(
           to: admin_path(%{"mount_path" => socket.assigns.admin_mount_path}, "/promotion-codes")
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
        <div :if={@read_unavailable?} class="ax-card ax-data-table-unavailable" data-role="promotion-code-unavailable" role="alert">
          <p class="ax-heading">Promotion code record unavailable</p>
          <p class="ax-body">This promotion code and its parent coupon could not be loaded. Their details are unknown until the read succeeds.</p>
          <button type="button" phx-click="retry_read" class="ax-button ax-button-secondary" data-role="retry-promotion-code-read">Retry</button>
        </div>
        <Breadcrumbs.breadcrumbs
          :if={@promotion_code}
          items={[
            %{label: "Dashboard", href: ScopedPath.build(@admin_mount_path, "", @current_owner_scope)},
            %{
              label: AccrueAdmin.Copy.promotion_codes_breadcrumb_index(),
              href:
                ScopedPath.build(
                  @admin_mount_path,
                  "/promotion-codes",
                  @current_owner_scope
                )
            },
            %{label: @promotion_code.code || @promotion_code.processor_id || @promotion_code.id}
          ]}
        />
        <p :if={@promotion_code} class="ax-body"><a class="ax-link" href={@return_path}><%= @return_label %></a></p>

        <Detail.summary_card
          :if={@promotion_code}
          eyebrow={AccrueAdmin.Copy.promotion_code_detail_eyebrow()}
          title={@promotion_code.code || @promotion_code.processor_id || @promotion_code.id}
        >
          <:facts>
            <span><%= status_summary(@promotion_code) %></span>
            <span><%= redemption_summary(@promotion_code) %></span>
          </:facts>
        </Detail.summary_card>

        <Detail.summary_list :if={@promotion_code} rows={summary_rows(@promotion_code, @admin_mount_path)} />

        <section :if={@promotion_code} class="ax-stack-xl" aria-label="Promotion code details">
          <details class="ax-detail-section" data-ax-drill-section="parent-coupon" open>
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title"><%= AccrueAdmin.Copy.promotion_code_section_navigate_heading() %></span>
            </summary>

            <Detail.detail_field_list fields={parent_coupon_fields(@promotion_code)} />

            <p :if={@promotion_code.coupon} class="ax-body">
              <a
                href={ScopedPath.build(@admin_mount_path, "/coupons/#{@promotion_code.coupon.id}", @current_owner_scope)}
                class="ax-link"
              >
                <%= @promotion_code.coupon.name || @promotion_code.coupon.processor_id || @promotion_code.coupon.id %>
              </a>
            </p>

        <p :if={!@promotion_code.coupon} class="ax-body">
          <%= promotion_code_coupon_empty_body() %>
            </p>
          </details>

          <details class="ax-detail-section" data-ax-drill-section="redemption-boundaries">
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title"><%= AccrueAdmin.Copy.promotion_code_redemption_boundaries_heading() %></span>
            </summary>
            <Detail.detail_field_list fields={redemption_boundary_fields(@promotion_code)} />
          </details>
        </section>

        <div :if={@promotion_code} data-ax-related-resources>
          <RelatedResources.related_resources items={@related_items} />
        </div>

        <details :if={@promotion_code} class="ax-detail-section" data-ax-lazy-activity phx-click="load_activity">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title"><%= AccrueAdmin.Copy.promotion_code_lazy_activity_heading() %></span>
          </summary>
          <%= if @activity_loaded? do %>
            <Timeline.timeline
              label={AccrueAdmin.Copy.promotion_code_lazy_activity_label()}
              empty_label={AccrueAdmin.Copy.promotion_code_lazy_activity_empty_label()}
              items={activity_items(@promotion_code)}
            />
            <p :if={activity_items(@promotion_code) == []} class="ax-body">
              <%= promotion_code_activity_empty_body() %>
            </p>
          <% else %>
            <p class="ax-body"><%= AccrueAdmin.Copy.promotion_code_lazy_activity_prompt() %></p>
          <% end %>
        </details>

        <details :if={@promotion_code} class="ax-detail-section" data-ax-lazy-json phx-click="load_raw_json">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title"><%= AccrueAdmin.Copy.promotion_code_lazy_raw_data_heading() %></span>
          </summary>
          <%= if @raw_json_loaded? do %>
            <JsonViewer.json_viewer
              id="promotion-code-payload"
              label={AccrueAdmin.Copy.promotion_code_json_payload_label()}
              payload={raw_payload(@promotion_code)}
            />
          <% else %>
            <p class="ax-body"><%= AccrueAdmin.Copy.promotion_code_lazy_raw_data_prompt() %></p>
          <% end %>
        </details>
      </section>
    </AppShell.app_shell>
    """
  end

  defp read_promotion_code(promotion_code_id) do
    try do
      if Application.get_env(:accrue_admin, :env) == :test and
           Application.get_env(:accrue_admin, :phase238_read_failure_fixture) ==
             :promotion_code_detail do
        raise DBConnection.ConnectionError, message: "fixture database unavailable"
      end

      case Repo.get(PromotionCode, promotion_code_id) |> maybe_preload_coupon() do
        nil -> nil
        promotion_code -> {:ok, promotion_code}
      end
    rescue
      _error in DBConnection.ConnectionError -> :unavailable
    end
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

  defp summary_rows(promotion_code, _mount_path) do
    [
      %{label: "Active state", value: status_summary(promotion_code)},
      %{
        label: "Code",
        value: promotion_code.code || promotion_code.processor_id || promotion_code.id
      },
      %{label: "Parent coupon", value: coupon_label(promotion_code)},
      %{label: "Expiry", value: expires_summary(promotion_code)},
      %{label: "Redemption count", value: redemption_count_summary(promotion_code)},
      %{label: "Redemption limit", value: max_redemptions_summary(promotion_code)},
      %{label: "Customer restriction", value: customer_restriction_summary(promotion_code)}
    ]
  end

  defp parent_coupon_fields(promotion_code) do
    [
      %{label: "Coupon", value: coupon_label(promotion_code)},
      %{
        label: "Coupon id",
        value: coupon_identity_summary(promotion_code)
      }
    ]
  end

  defp promotion_code_coupon_empty_body do
    [
      AccrueAdmin.Copy.resource_state_copy(:coupons, :first_run_empty).body,
      AccrueAdmin.Copy.promotion_code_detail_no_coupon_projection()
    ]
    |> Enum.join(" ")
  end

  defp promotion_code_activity_empty_body do
    [
      AccrueAdmin.Copy.resource_state_copy(:promotion_codes, :queue_empty).body,
      AccrueAdmin.Copy.promotion_code_lazy_activity_empty_body()
    ]
    |> Enum.join(" ")
  end

  defp redemption_boundary_fields(promotion_code) do
    [
      %{label: "Active state", value: status_summary(promotion_code)},
      %{label: "Expiry", value: expires_summary(promotion_code)},
      %{label: "Redemption count", value: redemption_count_summary(promotion_code)},
      %{label: "Redemption limit", value: max_redemptions_summary(promotion_code)}
    ]
  end

  defp activity_items(_promotion_code), do: []

  defp raw_payload(promotion_code) do
    %{
      "metadata" => promotion_code.metadata || %{},
      "data" => promotion_code.data || %{},
      "processor_id" => promotion_code.processor_id,
      "coupon_id" => promotion_code.coupon_id,
      "last_stripe_event_id" => promotion_code.last_stripe_event_id
    }
  end

  defp coupon_label(%{coupon: %{id: id, name: name}, coupon_id: id}) when is_binary(name),
    do: name

  defp coupon_label(%{coupon: %{id: id, processor_id: processor_id}, coupon_id: id})
       when is_binary(processor_id),
       do: processor_id

  defp coupon_label(%{coupon_id: nil}), do: AccrueAdmin.Copy.promotion_codes_coupon_none_label()

  defp coupon_label(%{coupon_id: coupon_id}),
    do: AccrueAdmin.Copy.PromotionCode.promotion_code_coupon_unavailable(coupon_id)

  defp status_summary(%{active: true, expires_at: %DateTime{} = expires_at}),
    do:
      AccrueAdmin.Copy.promotion_codes_status_active_expires_separator() <>
        format_datetime(expires_at)

  defp status_summary(%{active: true}), do: AccrueAdmin.Copy.promotion_codes_status_active()
  defp status_summary(%{active: false}), do: AccrueAdmin.Copy.promotion_codes_status_inactive()

  defp status_summary(_promotion_code),
    do: AccrueAdmin.Copy.PromotionCode.promotion_code_status_unknown()

  defp redemption_summary(%{times_redeemed: used, max_redemptions: nil}) when is_integer(used),
    do: "#{used}"

  defp redemption_summary(%{times_redeemed: used, max_redemptions: max})
       when is_integer(used) and is_integer(max),
       do: "#{used} of #{max}"

  defp redemption_summary(_promotion_code),
    do: AccrueAdmin.Copy.PromotionCode.promotion_code_redemptions_unknown()

  defp max_redemptions_summary(%{max_redemptions: nil}),
    do: AccrueAdmin.Copy.promotion_code_kpi_meta_unlimited_cap()

  defp max_redemptions_summary(%{max_redemptions: max}), do: "#{max} max"

  defp redemption_count_summary(%{times_redeemed: count}) when is_integer(count),
    do: Integer.to_string(count)

  defp redemption_count_summary(_promotion_code),
    do: AccrueAdmin.Copy.PromotionCode.promotion_code_redemptions_unknown()

  defp coupon_identity_summary(%{coupon_id: nil}),
    do: AccrueAdmin.Copy.promotion_codes_coupon_none_label()

  defp coupon_identity_summary(%{coupon: %{id: id}, coupon_id: id}), do: id

  defp coupon_identity_summary(%{coupon_id: id}),
    do: AccrueAdmin.Copy.PromotionCode.promotion_code_coupon_unavailable(id)

  defp expires_summary(%{expires_at: %DateTime{} = value}), do: format_datetime(value)
  defp expires_summary(_promotion_code), do: AccrueAdmin.Copy.promotion_code_redeem_by_no_expiry()

  defp customer_restriction_summary(%{data: data}) when is_map(data) do
    case Map.get(data, "customer") || Map.get(data, :customer) || Map.get(data, "customer_id") ||
           Map.get(data, :customer_id) do
      customer when is_binary(customer) and customer != "" -> customer
      _customer -> AccrueAdmin.Copy.PromotionCode.promotion_code_customer_restriction_unknown()
    end
  end

  defp customer_restriction_summary(_promotion_code),
    do: AccrueAdmin.Copy.PromotionCode.promotion_code_customer_restriction_unknown()

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")

  defp related_items(promotion_code, mount_path, scope) do
    coupon_items =
      if promotion_code.coupon_id &&
           match?(%{id: id} when id == promotion_code.coupon_id, promotion_code.coupon) do
        value =
          case promotion_code.coupon do
            %{name: name} when is_binary(name) -> name
            %{processor_id: pid} when is_binary(pid) -> pid
            _ -> promotion_code.coupon_id
          end

        [
          %{
            icon: :coupons,
            label: "Coupon",
            value: value,
            href: ScopedPath.build(mount_path, "/coupons/#{promotion_code.coupon_id}", scope)
          }
        ]
      else
        []
      end

    coupon_items ++
      [
        %{
          icon: :events,
          label: "Events",
          href:
            ScopedPath.build(mount_path, "/events", scope, %{
              "subject_type" => "PromotionCode",
              "subject_id" => promotion_code.id
            })
        }
      ]
  end

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
