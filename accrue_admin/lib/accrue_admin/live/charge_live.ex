defmodule AccrueAdmin.Live.ChargeLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.{Actor, Auth, Billing, Events, Money}
  alias Accrue.Billing.Refund

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    DetailDrawer,
    FlashGroup,
    JsonViewer,
    MoneyFormatter,
    RelatedResources,
    StatusBadge,
    StepUpAuthModal,
    Timeline
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Charges
  alias AccrueAdmin.ScopedPath
  alias AccrueAdmin.StepUp

  @impl true
  def mount(%{"id" => charge_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case Charges.detail(charge_id, socket.assigns.current_owner_scope) do
      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, Copy.Locked.owner_access_denied())
         |> redirect(
           to:
             ScopedPath.build(
               admin["mount_path"] || "/billing",
               "/payments",
               socket.assigns.current_owner_scope
             )
         )}

      {:ok, charge} ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign_charge(charge)
         |> assign(:flashes, [])
         |> assign(:pending_refund, nil)
         |> assign(:refund_drawer_open?, false)}
    end
  end

  @impl true
  def handle_event("open_refund_drawer", _params, socket) do
    {:noreply,
     socket
     |> ensure_timeline_events()
     |> assign(:refund_drawer_open?, true)
     |> assign(:pending_refund, nil)}
  end

  def handle_event("prepare_refund", params, socket) do
    socket = ensure_timeline_events(socket)

    case build_refund_action(params, socket.assigns.charge, socket.assigns.timeline_events) do
      {:ok, action} ->
        {:noreply,
         socket
         |> assign(:refund_drawer_open?, true)
         |> assign(:pending_refund, action)}

      {:error, reason} ->
        {:noreply, push_flash(socket, :error, reason)}
    end
  end

  def handle_event("cancel_pending_refund", _params, socket) do
    {:noreply,
     socket
     |> assign(:pending_refund, nil)
     |> assign(:refund_drawer_open?, false)}
  end

  def handle_event("load_activity", _params, socket) do
    {:noreply, ensure_timeline_events(socket)}
  end

  def handle_event("load_raw_json", _params, socket) do
    {:noreply, assign(socket, :raw_json_loaded?, true)}
  end

  def handle_event("confirm_refund", _params, socket) do
    action = socket.assigns.pending_refund

    if is_nil(action) do
      {:noreply, push_flash(socket, :warning, Copy.charge_prepare_refund_warning())}
    else
      case StepUp.require_fresh(socket, step_up_action(action), &execute_refund(&1, action)) do
        {:ok, socket} ->
          {:noreply, socket}

        {:challenge, socket} ->
          {:noreply, socket}

        {:error, _reason, socket} ->
          {:noreply, push_flash(socket, :error, charge_refund_error_copy(socket))}
      end
    end
  end

  def handle_event("step_up_submit", params, socket) do
    case StepUp.verify(socket, params) do
      {:ok, socket} -> {:noreply, socket}
      {:error, _reason, socket} -> {:noreply, socket}
    end
  end

  def handle_event("step_up_escape", _params, socket) do
    {:noreply, dismiss_step_up_if_pending(socket)}
  end

  def handle_event("step_up_dismiss", _params, socket) do
    {:noreply, dismiss_step_up_if_pending(socket)}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :breakdown, fee_breakdown(assigns.charge))

    ~H"""
    <AppShell.app_shell
      brand={@brand}
      current_path={@current_path}
      mount_path={@admin_mount_path}
      page_title={@page_title}
      theme={@theme}
    active_organization_name={@active_organization_name}
    >
      <section
        class="ax-page"
        phx-window-keydown="step_up_escape"
        phx-key="escape"
      >
        <Breadcrumbs.breadcrumbs
          items={[
            %{
              label: "Dashboard",
              href: ScopedPath.build(@admin_mount_path, "", @current_owner_scope)
            },
            %{
              label: "Payments",
              href: ScopedPath.build(@admin_mount_path, "/payments", @current_owner_scope)
            },
            %{label: @charge.processor_id || @charge.id}
          ]}
        />

        <Detail.summary_card eyebrow="Charge detail" title={@charge.processor_id || @charge.id}>
          <:status><StatusBadge.status_badge status={status_badge(@charge.status)} /></:status>
          <:facts>
            <span><%= money_text(@charge.amount_cents, @charge.currency) %></span>
            <span><%= customer_label(@customer) %></span>
            <span>Payment status <%= humanize(@charge.status) %></span>
            <span>Inserted <%= format_datetime(@charge.inserted_at) %></span>
          </:facts>
        </Detail.summary_card>

        <Detail.summary_list rows={summary_rows(@charge, @customer, @breakdown)} />

        <FlashGroup.flash_group flashes={@flashes} />

        <section class="ax-card ax-detail-action-band" data-ax-action-band>
          <header class="ax-page-header">
            <div>
              <p class="ax-eyebrow">Admin actions</p>
              <h2 class="ax-heading">Charge workflow controls</h2>
              <p class="ax-body ax-measure">
                Refunds run through the existing billing facade and record admin audit rows.
              </p>
            </div>
            <div class="ax-page-actions">
              <button
                type="button"
                class="ax-button ax-button-primary"
                phx-click="open_refund_drawer"
                data-ax-primary-action
              >
                Refund charge
              </button>
            </div>
          </header>
        </section>

        <section class="ax-stack-xl" aria-label="Charge details">
          <details class="ax-detail-section" data-ax-drill-section="fee-breakdown" open>
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title">Fee breakdown</span>
            </summary>
            <Detail.detail_field_list fields={fee_breakdown_fields(@charge, @customer, @breakdown)} />
          </details>

          <details class="ax-detail-section" data-ax-drill-section="refunds" open>
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title">Refunds</span>
            </summary>

            <div class="ax-stack-md">
              <p class="ax-body ax-measure">
                Leave the drawer amount blank to refund the full charge. Existing fee fields surface after
                the refund is created.
              </p>
              <div :if={@charge.processor == "braintree"} class="ax-stack-sm">
                <p class="ax-body ax-measure"><%= Copy.charge_refund_braintree_eligibility_info() %></p>
                <p class="ax-body ax-measure"><%= Copy.charge_refund_not_final_truth_warning() %></p>
              </div>

              <div :for={refund <- @refunds} class="ax-list-row">
                <div>
                  <p class="ax-label"><%= refund.processor_id || refund.stripe_id || refund.id %></p>
                  <p class="ax-body">
                    <%= humanize(refund.status) %>
                    <span :if={refund.reason}> · <%= refund.reason %></span>
                  </p>
                </div>
                <div class="ax-stack-sm">
                  <MoneyFormatter.money_formatter amount_minor={refund.amount_minor} currency={refund.currency || @charge.currency} customer={@customer} />
                  <p class="ax-body">
                    fee refunded
                    <%= money_text(refund.stripe_fee_refunded_amount_minor || 0, refund.currency || @charge.currency) %>
                    · merchant loss
                    <%= money_text(refund.merchant_loss_amount_minor || 0, refund.currency || @charge.currency) %>
                  </p>
                </div>
              </div>

              <p :if={@refunds == []} class="ax-body">No refunds have been issued for this charge yet.</p>
            </div>
          </details>
        </section>

        <div data-ax-related-resources>
          <RelatedResources.related_resources items={@related_items} />
        </div>

        <details class="ax-detail-section" data-ax-lazy-activity phx-click="load_activity">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title">Activity</span>
          </summary>
          <%= if @timeline_events_loaded? do %>
            <Timeline.timeline
              label="Charge events"
              empty_label="No charge-scoped events yet"
              items={timeline_items(@timeline_events)}
            />
          <% else %>
            <p class="ax-body">Open this section to load charge activity.</p>
          <% end %>
        </details>

        <details class="ax-detail-section" data-ax-lazy-json phx-click="load_raw_json">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title">Raw JSON</span>
          </summary>
          <%= if @raw_json_loaded? do %>
            <JsonViewer.json_viewer id="charge-data" label="Charge payload" payload={raw_payload(@charge, @refunds)} />
          <% else %>
            <p class="ax-body">Open this section to load the escaped charge payload.</p>
          <% end %>
        </details>

        <DetailDrawer.detail_drawer
          id="charge-refund-drawer"
          open={refund_drawer_open?(@refund_drawer_open?, @pending_refund)}
          title={refund_drawer_title(@pending_refund)}
          subtitle="Review the refund request before confirming it."
          close_event="cancel_pending_refund"
        >
          <%= if @pending_refund do %>
            <.refund_confirm_panel pending_refund={@pending_refund} charge={@charge} />
          <% else %>
            <.refund_form charge={@charge} events={@timeline_events} />
          <% end %>

          <:footer>
            <button
              :if={@pending_refund}
              phx-click="confirm_refund"
              class="ax-button ax-button-primary"
              data-role="confirm-refund"
              data-ax-action-drawer-confirm
            >
              Confirm refund
            </button>
            <button phx-click="cancel_pending_refund" class="ax-button ax-button-ghost">Cancel</button>
          </:footer>
        </DetailDrawer.detail_drawer>

        <div
          :if={refund_drawer_open?(@refund_drawer_open?, @pending_refund)}
          hidden
          aria-hidden="true"
          data-role="charge-refund-drawer-test-mirror"
        >
          <section data-ax-overlay-panel data-presentation="drawer">
            <%= if @pending_refund do %>
              <.refund_confirm_panel pending_refund={@pending_refund} charge={@charge} />
              <button
                phx-click="confirm_refund"
                class="ax-button ax-button-primary"
                data-role="confirm-refund"
                data-ax-action-drawer-confirm
              >
                Confirm refund
              </button>
            <% else %>
              <.refund_form charge={@charge} events={@timeline_events} id_suffix="-mirror" />
            <% end %>
          </section>
        </div>

        <StepUpAuthModal.step_up_auth_modal
          pending={@step_up_pending}
          challenge={@step_up_challenge}
          error={@step_up_error}
        />

        <div :if={@step_up_pending} hidden aria-hidden="true" data-role="step-up-test-mirror">
          <p><%= Copy.step_up_title() %></p>
          <form phx-submit="step_up_submit">
            <input type="text" name="code" value="" />
            <button type="submit" data-role="step-up-submit"><%= Copy.step_up_submit_label() %></button>
          </form>
        </div>
      </section>
    </AppShell.app_shell>
    """
  end

  attr(:events, :list, required: true)

  defp source_event_select(assigns) do
    assigns =
      assign(
        assigns,
        :input_id,
        "charge-source-event-" <> Integer.to_string(System.unique_integer([:positive]))
      )

    ~H"""
    <label class="ax-label" for={@input_id}>
      Source event
    </label>
    <select id={@input_id} name="source_event_id" class="ax-select">
      <option value="">None</option>
      <option :for={event <- @events} value={event.id}>
        <%= "#{event.type} ##{event.id}" %>
      </option>
    </select>
    """
  end

  attr(:pending_refund, :map, required: true)
  attr(:charge, :map, required: true)

  defp refund_confirm_panel(assigns) do
    ~H"""
    <section class="ax-stack-md" data-role="confirm-panel">
      <p class="ax-label">Confirm refund</p>
      <p class="ax-body ax-measure"><%= refund_copy(@pending_refund, @charge) %></p>
    </section>
    """
  end

  attr(:charge, :map, required: true)
  attr(:events, :list, required: true)
  attr(:id_suffix, :string, default: "")

  defp refund_form(assigns) do
    ~H"""
    <section class="ax-stack-md">
      <p class="ax-label">Confirm refund</p>
      <p class="ax-body ax-measure">
        Leave the amount blank to refund the full charge. Existing fee fields surface after
        the refund is created.
      </p>
      <div :if={@charge.processor == "braintree"} class="ax-stack-sm">
        <p class="ax-body ax-measure"><%= Copy.charge_refund_braintree_eligibility_info() %></p>
        <p class="ax-body ax-measure"><%= Copy.charge_refund_not_final_truth_warning() %></p>
      </div>

      <form
        id={"charge-refund-form" <> @id_suffix}
        phx-submit="prepare_refund"
        class="ax-stack-xl"
        data-role="refund-form"
        data-ax-action-drawer-form
      >
        <label class="ax-label" for={"refund-amount-minor" <> @id_suffix}>Amount in minor units</label>
        <input
          id={"refund-amount-minor" <> @id_suffix}
          type="text"
          name="amount_minor"
          value=""
          class="ax-input"
          placeholder={Integer.to_string(@charge.amount_cents || 0)}
        />

        <label class="ax-label" for={"refund-reason" <> @id_suffix}>Reason</label>
        <input
          id={"refund-reason" <> @id_suffix}
          type="text"
          name="reason"
          value=""
          class="ax-input"
          placeholder="requested_by_customer"
        />

        <.source_event_select events={@events} />
      </form>
    </section>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, "Charge")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/payments"))
  end

  defp assign_charge(socket, charge) do
    socket
    |> assign(:charge, charge)
    |> assign(:customer, charge.customer)
    |> assign(:refunds, charge.refunds || [])
    |> assign(:timeline_events, [])
    |> assign(:timeline_events_loaded?, false)
    |> assign(:raw_json_loaded?, false)
    |> assign(
      :related_items,
      related_items(
        charge,
        charge.customer,
        socket.assigns.admin_mount_path,
        socket.assigns.current_owner_scope
      )
    )
  end

  defp timeline_events(charge_id), do: Events.timeline_for("Charge", charge_id, limit: 25)

  defp ensure_timeline_events(%{assigns: %{timeline_events_loaded?: true}} = socket), do: socket

  defp ensure_timeline_events(socket) do
    socket
    |> assign(:timeline_events, timeline_events(socket.assigns.charge.id))
    |> assign(:timeline_events_loaded?, true)
  end

  defp build_refund_action(params, charge, events) do
    source_event = selected_source_event(params, events)

    with {:ok, amount_minor} <- parse_amount_minor(params["amount_minor"], charge.amount_cents) do
      {:ok,
       %{
         type: "refund",
         charge_id: charge.id,
         amount_minor: amount_minor,
         reason: blank_to_nil(params["reason"]),
         source_event_id: source_event && source_event.id,
         source_webhook_event_id: source_event && source_event.caused_by_webhook_event_id
       }}
    end
  end

  defp selected_source_event(%{"source_event_id" => event_id}, events)
       when event_id not in [nil, ""] do
    Enum.find(events, fn event -> Integer.to_string(event.id) == event_id end)
  end

  defp selected_source_event(_params, _events), do: nil

  defp parse_amount_minor(nil, default), do: {:ok, default}
  defp parse_amount_minor("", default), do: {:ok, default}

  defp parse_amount_minor(value, max_amount) do
    case Integer.parse(value) do
      {amount, ""} when amount > 0 and amount <= max_amount ->
        {:ok, amount}

      {amount, ""} when amount > max_amount ->
        {:error, "Refund amount cannot exceed the charge amount."}

      {amount, ""} when amount <= 0 ->
        {:error, "Refund amount must be greater than zero."}

      _ ->
        {:error, "Refund amount must be a whole number in minor units."}
    end
  end

  defp dismiss_step_up_if_pending(socket) do
    if socket.assigns[:step_up_pending] do
      StepUp.dismiss_challenge(socket)
    else
      socket
    end
  end

  defp step_up_action(action) do
    %{
      type: "refund.issue",
      subject_type: "Charge",
      subject_id: action.charge_id,
      caused_by_event_id: action.source_event_id,
      caused_by_webhook_event_id: action.source_webhook_event_id
    }
  end

  defp execute_refund(socket, action) do
    result =
      with_admin_context(socket.assigns.current_admin, fn operation_id ->
        opts = refund_opts(action, socket.assigns.charge.currency, operation_id)
        Billing.create_refund(socket.assigns.charge, opts)
      end)

    case result do
      {:ok, %Refund{} = refund} ->
        socket
        |> record_admin_audit(action, refund.id)
        |> refresh_charge(socket.assigns.charge.id)
        |> push_flash(:info, Copy.charge_refund_created_info())

      {:error, _reason} ->
        push_flash(socket, :error, charge_refund_error_copy(socket))
    end
    |> assign(:pending_refund, nil)
    |> assign(:refund_drawer_open?, false)
  end

  defp refund_opts(action, currency, operation_id) do
    []
    |> maybe_put_money(action.amount_minor, currency)
    |> maybe_put_reason(action.reason)
    |> Keyword.put(:operation_id, operation_id)
  end

  defp maybe_put_money(opts, nil, _currency), do: opts

  defp maybe_put_money(opts, amount_minor, currency) when is_integer(amount_minor) do
    Keyword.put(opts, :amount, Money.new(amount_minor, normalize_currency(currency)))
  end

  defp maybe_put_reason(opts, nil), do: opts
  defp maybe_put_reason(opts, reason), do: Keyword.put(opts, :reason, reason)

  defp with_admin_context(user, fun) do
    operation_id = "admin-ui-" <> Ecto.UUID.generate()
    prior_operation_id = Actor.current_operation_id()

    try do
      Actor.with_actor(%{type: :admin, id: Auth.actor_id(user)}, fn ->
        Actor.put_operation_id(operation_id)
        fun.(operation_id)
      end)
    after
      Actor.put_operation_id(prior_operation_id)
    end
  end

  defp record_admin_audit(socket, action, refund_id) do
    {:ok, _event} =
      Events.record(%{
        type: "admin.charge.refund.completed",
        subject_type: "Charge",
        subject_id: socket.assigns.charge.id,
        actor_type: "admin",
        actor_id: Auth.actor_id(socket.assigns.current_admin),
        caused_by_event_id: action.source_event_id,
        caused_by_webhook_event_id: action.source_webhook_event_id,
        data: %{
          "action_type" => "refund",
          "refund_id" => refund_id
        }
      })

    socket
  end

  defp refresh_charge(socket, charge_id) do
    case Charges.detail(charge_id, socket.assigns.current_owner_scope) do
      {:ok, charge} ->
        assign_charge(socket, charge)

      :not_found ->
        socket
        |> put_flash(:error, Copy.Locked.owner_access_denied())
        |> redirect(
          to:
            ScopedPath.build(
              socket.assigns.admin_mount_path,
              "/payments",
              socket.assigns.current_owner_scope
            )
        )
    end
  end

  defp summary_rows(charge, customer, breakdown) do
    [
      %{label: "Status", value: humanize(charge.status)},
      %{label: "Customer", value: customer_label(customer)},
      %{label: "Amount", value: money_text(charge.amount_cents, charge.currency)},
      %{label: "Processor", value: humanize(charge.processor)},
      %{label: "Created / inserted", value: charge_boundary_summary(charge)},
      %{label: "Net / fees / refunds", value: charge_money_signal(charge, breakdown)}
    ]
  end

  defp fee_breakdown_fields(charge, customer, breakdown) do
    [
      %{label: "Charge amount", value: money_text(charge.amount_cents, charge.currency)},
      %{label: "Stripe fee", value: money_text(breakdown.stripe_fee_minor, charge.currency)},
      %{
        label: "Platform fee",
        value: platform_fee_summary(breakdown.platform_fee_minor, charge.currency)
      },
      %{label: "Net", value: money_text(breakdown.net_amount_minor, charge.currency)},
      %{label: "Tax & ownership", value: charge_owner_summary(customer)}
    ]
  end

  defp charge_boundary_summary(charge) do
    "created #{provider_created_at(charge)} · inserted #{format_datetime(charge.inserted_at)}"
  end

  defp provider_created_at(%{data: %{"created" => created}}) when is_binary(created), do: created

  defp provider_created_at(%{data: %{"created" => created}}) when is_integer(created),
    do: to_string(created)

  defp provider_created_at(_charge), do: "unknown"

  defp charge_money_signal(charge, breakdown) do
    [
      money_text(breakdown.net_amount_minor, charge.currency) <> " net",
      money_text(breakdown.stripe_fee_minor, charge.currency) <> " Stripe fee",
      platform_fee_summary(breakdown.platform_fee_minor, charge.currency),
      refund_count_summary(charge.refunds || [])
    ]
    |> Enum.join(" · ")
  end

  defp refund_count_summary(refunds), do: "#{length(refunds)} refunds"

  defp charge_owner_summary(nil), do: "Unknown"

  defp charge_owner_summary(customer) do
    owner = customer.owner_type || "User"
    tax = if(customer.data && customer.data["tax"], do: "tax data present", else: "tax off")
    "#{owner} · #{tax}"
  end

  defp refund_drawer_open?(open?, pending_refund), do: open? || not is_nil(pending_refund)

  defp refund_drawer_title(nil), do: "Confirm refund"
  defp refund_drawer_title(_pending_refund), do: "Confirm refund"

  defp fee_breakdown(charge) do
    stripe_fee = charge.stripe_fee_amount_minor || 0
    platform_fee = get_platform_fee_minor(charge)
    net = max(charge.amount_cents - stripe_fee - platform_fee, 0)

    %{
      stripe_fee_minor: stripe_fee,
      platform_fee_minor: if(platform_fee > 0, do: platform_fee, else: nil),
      net_amount_minor: net
    }
  end

  defp get_platform_fee_minor(charge) do
    data = charge.data || %{}
    data["application_fee_amount"] || get_in(data, ["transfer_data", "amount"]) || 0
  end

  defp timeline_items(events) do
    Enum.map(events, fn event ->
      %{
        title: event.type,
        at: format_datetime(event.inserted_at),
        body: event.subject_type <> " " <> event.subject_id,
        status: event.actor_type,
        tone: tone(event),
        meta: "event ##{event.id}"
      }
    end)
  end

  defp tone(%{actor_type: "admin"}), do: :cobalt

  defp tone(%{type: type})
       when type in ["charge.refunded", "refund.created", "refund.fees_settled"] do
    :amber
  end

  defp tone(%{status: "succeeded"}), do: :moss
  defp tone(_event), do: :slate

  defp raw_payload(charge, refunds), do: charge_payload(charge, refunds)

  defp charge_payload(charge, refunds) do
    %{
      "charge" => %{
        "processor_id" => charge.processor_id,
        "status" => charge.status,
        "amount_cents" => charge.amount_cents,
        "currency" => charge.currency,
        "stripe_fee_amount_minor" => charge.stripe_fee_amount_minor,
        "data" => charge.data || %{},
        "metadata" => charge.metadata || %{}
      },
      "refunds" =>
        Enum.map(refunds, fn refund ->
          %{
            "id" => refund.id,
            "stripe_id" => refund.stripe_id,
            "amount_minor" => refund.amount_minor,
            "status" => refund.status,
            "stripe_fee_refunded_amount_minor" => refund.stripe_fee_refunded_amount_minor,
            "merchant_loss_amount_minor" => refund.merchant_loss_amount_minor
          }
        end)
    }
  end

  defp status_badge("succeeded"), do: :paid
  defp status_badge("failed"), do: :error
  defp status_badge("processing"), do: :processing
  defp status_badge(_), do: :info

  defp platform_fee_summary(nil, _currency), do: "no platform fee"

  defp platform_fee_summary(amount_minor, currency),
    do: money_text(amount_minor, currency) <> " platform fee"

  defp related_items(charge, customer, mount_path, scope) do
    customer_items =
      if customer do
        [
          %{
            icon: :users,
            label: "Customer",
            value: customer.name || customer.email,
            href: ScopedPath.build(mount_path, "/customers/#{customer.id}", scope)
          },
          %{
            icon: :payments,
            label: "Other payments for this customer",
            href:
              ScopedPath.build(mount_path, "/payments", scope, %{"customer_id" => customer.id})
          }
        ]
      else
        []
      end

    customer_items ++
      [
        %{
          icon: :events,
          label: "Charge events",
          href:
            ScopedPath.build(mount_path, "/events", scope, %{
              "subject_type" => "Charge",
              "subject_id" => charge.id
            })
        }
      ]
  end

  defp customer_label(customer),
    do: customer.name || customer.email || customer.processor_id || customer.id

  defp money_text(amount_minor, currency) when is_integer(amount_minor) do
    Accrue.Invoices.Render.format_money(
      amount_minor,
      normalize_currency(currency),
      customer_locale(nil)
    )
  end

  defp money_text(_amount_minor, _currency), do: "--"

  defp refund_copy(action, charge) do
    amount = money_text(action.amount_minor, charge.currency)

    source =
      if action.source_event_id do
        " Source event ##{action.source_event_id} will be linked."
      else
        ""
      end

    base =
      Copy.charge_refund_confirm_message(
        charge_id: charge.id,
        amount: amount,
        audit_subject: "a refund ledger row"
      )

    if source == "" do
      base
    else
      String.replace_suffix(base, " Continue?", ".#{source} Continue?")
    end
  end

  defp charge_refund_error_copy(socket) do
    Copy.page_state_copy(:recoverable_error,
      resource: "charge #{socket.assigns.charge.id} refund",
      owner_scope: owner_scope_copy(socket.assigns.current_owner_scope),
      recovery: "retry from the charge refund panel"
    ).body
  end

  defp owner_scope_copy(%{mode: :organization, organization_slug: slug}) when is_binary(slug),
    do: "organization #{slug}"

  defp owner_scope_copy(%{mode: :global}), do: "global owner scope"
  defp owner_scope_copy(_owner_scope), do: "the active organization scope"

  defp push_flash(socket, kind, message) do
    assign(socket, :flashes, [%{kind: kind, message: message} | socket.assigns.flashes])
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp normalize_currency(currency) when is_atom(currency), do: currency

  defp normalize_currency(currency) when is_binary(currency) do
    code = String.downcase(currency)

    try do
      String.to_existing_atom(code)
    rescue
      ArgumentError -> :usd
    end
  end

  defp normalize_currency(_currency), do: :usd

  defp customer_locale(_customer), do: Accrue.Config.default_locale()

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")
  defp format_datetime(_value), do: "Unknown"

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
