defmodule AccrueAdmin.Live.ChargeLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.{Actor, Auth, Billing, Events, Money}
  alias Accrue.Billing.{Charge, Refund}
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    FlashGroup,
    JsonViewer,
    KpiCard,
    MoneyFormatter,
    StatusBadge,
    StepUpAuthModal,
    TaxOwnershipCard,
    Timeline
  }

  alias AccrueAdmin.{StepUp, TaxOwnershipRow}

  @impl true
  def mount(%{"id" => charge_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case load_charge(charge_id) do
      nil ->
        {:ok, redirect(socket, to: admin_path(admin, "/charges"))}

      charge ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign_charge(charge)
         |> assign(:flashes, [])
         |> assign(:pending_refund, nil)}
    end
  end

  @impl true
  def handle_event("prepare_refund", params, socket) do
    case build_refund_action(params, socket.assigns.charge, socket.assigns.timeline_events) do
      {:ok, action} ->
        {:noreply, assign(socket, :pending_refund, action)}

      {:error, reason} ->
        {:noreply, push_flash(socket, :error, reason)}
    end
  end

  def handle_event("cancel_pending_refund", _params, socket) do
    {:noreply, assign(socket, :pending_refund, nil)}
  end

  def handle_event("confirm_refund", _params, socket) do
    action = socket.assigns.pending_refund

    if is_nil(action) do
      {:noreply, push_flash(socket, :warning, "Prepare a refund before confirming.")}
    else
      case StepUp.require_fresh(socket, step_up_action(action), &execute_refund(&1, action)) do
        {:ok, socket} -> {:noreply, socket}
        {:challenge, socket} -> {:noreply, socket}
        {:error, reason, socket} -> {:noreply, push_flash(socket, :error, inspect(reason))}
      end
    end
  end

  def handle_event("step_up_submit", params, socket) do
    case StepUp.verify(socket, params) do
      {:ok, socket} -> {:noreply, socket}
      {:error, _reason, socket} -> {:noreply, socket}
    end
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
      <section class="ax-page">
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: "Dashboard", href: @admin_mount_path},
              %{label: "Charges", href: @admin_mount_path <> "/charges"},
              %{label: @charge.processor_id || @charge.id}
            ]}
          />
          <p class="ax-eyebrow">Charge detail</p>
          <h2 class="ax-display"><%= @charge.processor_id || @charge.id %></h2>
          <p class="ax-body ax-page-copy">
            <%= customer_label(@customer) %> · payment status <%= humanize(@charge.status) %> · inserted <%= format_datetime(@charge.inserted_at) %>
          </p>
        </header>

        <FlashGroup.flash_group flashes={@flashes} />

        <section class="ax-kpi-grid" aria-label="Charge summary">
          <KpiCard.kpi_card label="Status" value={humanize(@charge.status)}>
            <:meta><StatusBadge.status_badge status={status_badge(@charge.status)} /></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Gross"
            value={money_text(@charge.amount_cents, @charge.currency)}
            delta={money_text(@breakdown.net_amount_minor, @charge.currency) <> " net"}
            delta_tone="moss"
          >
            <:meta><%= money_text(@breakdown.stripe_fee_minor, @charge.currency) %> Stripe fee</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Refunds"
            value={Integer.to_string(length(@refunds))}
            delta={platform_fee_summary(@breakdown.platform_fee_minor, @charge.currency)}
            delta_tone="amber"
          >
            <:meta>Fee-aware refund review</:meta>
          </KpiCard.kpi_card>
        </section>

        <TaxOwnershipCard.tax_ownership_card row={TaxOwnershipRow.from_charge(@customer)} />

        <section class="ax-grid ax-grid-2">
          <article class="ax-card">
            <header class="ax-page-header">
              <p class="ax-eyebrow">Fee breakdown</p>
              <h3 class="ax-heading">Processor and platform fees</h3>
            </header>

            <div class="ax-stack-xl">
              <div class="ax-list-row">
                <span class="ax-body">Charge amount</span>
                <MoneyFormatter.money_formatter amount_minor={@charge.amount_cents} currency={@charge.currency} customer={@customer} />
              </div>
              <div class="ax-list-row">
                <span class="ax-body">Stripe fee</span>
                <MoneyFormatter.money_formatter amount_minor={@breakdown.stripe_fee_minor} currency={@charge.currency} customer={@customer} />
              </div>
              <div :if={@breakdown.platform_fee_minor} class="ax-list-row">
                <span class="ax-body">Platform fee</span>
                <MoneyFormatter.money_formatter amount_minor={@breakdown.platform_fee_minor} currency={@charge.currency} customer={@customer} />
              </div>
              <div class="ax-list-row">
                <span class="ax-body">Net</span>
                <MoneyFormatter.money_formatter amount_minor={@breakdown.net_amount_minor} currency={@charge.currency} customer={@customer} />
              </div>
            </div>
          </article>

          <article class="ax-card">
            <header class="ax-page-header">
              <p class="ax-eyebrow">Refund</p>
              <h3 class="ax-heading">Initiate a fee-aware refund</h3>
              <p class="ax-body">
                Leave the amount blank to refund the full charge. Existing fee fields surface after
                the refund is created.
              </p>
            </header>

            <form phx-submit="prepare_refund" class="ax-stack-xl" data-role="refund-form">
              <label class="ax-label" for="refund-amount-minor">Amount in minor units</label>
              <input
                id="refund-amount-minor"
                type="text"
                name="amount_minor"
                value=""
                class="ax-input"
                placeholder={Integer.to_string(@charge.amount_cents)}
              />

              <label class="ax-label" for="refund-reason">Reason</label>
              <input id="refund-reason" type="text" name="reason" value="" class="ax-input" placeholder="requested_by_customer" />

              <.source_event_select events={@timeline_events} />

              <button type="submit" class="ax-button ax-button-primary">Refund charge</button>
            </form>

            <section :if={@pending_refund} class="ax-card" data-role="confirm-panel">
              <p class="ax-label">Confirm refund</p>
              <p class="ax-body"><%= refund_copy(@pending_refund, @charge.currency) %></p>
              <div class="ax-page-header">
                <button phx-click="confirm_refund" class="ax-button ax-button-primary" data-role="confirm-refund">
                  Confirm refund
                </button>
                <button phx-click="cancel_pending_refund" class="ax-button ax-button-ghost">Cancel</button>
              </div>
            </section>
          </article>
        </section>

        <section class="ax-card">
          <header class="ax-page-header">
            <p class="ax-eyebrow">Refunds</p>
            <h3 class="ax-heading">Refund fee outcomes</h3>
          </header>

          <div :for={refund <- @refunds} class="ax-list-row">
            <div>
              <p class="ax-label"><%= refund.stripe_id || refund.id %></p>
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
        </section>

        <section class="ax-card">
          <header class="ax-page-header">
            <p class="ax-eyebrow">Timeline</p>
            <h3 class="ax-heading">Charge events</h3>
          </header>

          <Timeline.timeline
            label="Charge events"
            empty_label="No charge-scoped events yet"
            items={timeline_items(@timeline_events)}
          />
        </section>

        <JsonViewer.json_viewer id="charge-data" label="Charge payload" payload={charge_payload(@charge, @refunds)} />

        <StepUpAuthModal.step_up_auth_modal
          pending={@step_up_pending}
          challenge={@step_up_challenge}
          error={@step_up_error}
        />
      </section>
    </AppShell.app_shell>
    """
  end

  attr(:events, :list, required: true)

  defp source_event_select(assigns) do
    ~H"""
    <label class="ax-label" for={"charge-source-event-" <> Integer.to_string(System.unique_integer([:positive]))}>
      Source event
    </label>
    <select name="source_event_id" class="ax-select">
      <option value="">None</option>
      <option :for={event <- @events} value={event.id}>
        <%= "#{event.type} ##{event.id}" %>
      </option>
    </select>
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
    |> assign(:current_path, admin_path(admin, "/charges"))
  end

  defp assign_charge(socket, charge) do
    socket
    |> assign(:charge, charge)
    |> assign(:customer, charge.customer)
    |> assign(:refunds, charge.refunds || [])
    |> assign(:timeline_events, timeline_events(charge.id))
  end

  defp load_charge(charge_id) do
    Charge
    |> Repo.get(charge_id)
    |> case do
      nil -> nil
      charge -> Repo.preload(charge, [:customer, :refunds])
    end
  end

  defp timeline_events(charge_id), do: Events.timeline_for("Charge", charge_id, limit: 25)

  defp build_refund_action(params, charge, events) do
    source_event = selected_source_event(params, events)

    with {:ok, amount_minor} <- parse_amount_minor(params["amount_minor"], charge.amount_cents) do
      {:ok,
       %{
         type: "refund",
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

  defp step_up_action(action) do
    %{
      type: "refund.issue",
      subject_type: "Charge",
      subject_id: action.source_event_id || "pending",
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
        |> push_flash(:info, "Refund created with fee-aware fields from the billing facade.")

      {:error, reason} ->
        push_flash(socket, :error, inspect(reason))
    end
    |> assign(:pending_refund, nil)
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
    charge = load_charge(charge_id)
    assign_charge(socket, charge)
  end

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

  defp refund_copy(action, currency) do
    amount = money_text(action.amount_minor, currency)

    fee_note =
      "Existing refunds will continue to show stripe_fee_refunded_amount_minor and merchant_loss_amount_minor."

    source =
      if action.source_event_id do
        " Source event ##{action.source_event_id} will be linked."
      else
        ""
      end

    "Refund #{amount}. #{fee_note}#{source}"
  end

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
