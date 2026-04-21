defmodule AccrueAdmin.Live.InvoiceLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.{Actor, Auth, Billing, Events}
  alias Accrue.Billing.Invoice
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    FlashGroup,
    KpiCard,
    MoneyFormatter,
    StatusBadge,
    StepUpAuthModal,
    TaxOwnershipCard,
    Timeline
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.ScopedPath
  alias AccrueAdmin.{StepUp, TaxOwnershipRow}

  @destructive_actions ~w(void mark_uncollectible)

  @impl true
  def mount(%{"id" => invoice_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case load_invoice(invoice_id) do
      nil ->
        {:ok, redirect(socket, to: admin_path(admin, "/invoices"))}

      invoice ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign_invoice(invoice)
         |> assign(:flashes, [])
         |> assign(:pending_action, nil)
         |> assign(:generated_pdf_href, nil)
         |> assign(:generated_pdf_filename, nil)}
    end
  end

  @impl true
  def handle_event("prepare_action", params, socket) do
    {:noreply,
     assign(socket, :pending_action, pending_action(params, socket.assigns.timeline_events))}
  end

  def handle_event("cancel_pending_action", _params, socket) do
    {:noreply, assign(socket, :pending_action, nil)}
  end

  def handle_event("confirm_action", _params, socket) do
    case socket.assigns.pending_action do
      nil ->
        {:noreply, push_flash(socket, :warning, Copy.invoice_select_action_warning())}

      %{type: type} = action when type in @destructive_actions ->
        case StepUp.require_fresh(
               socket,
               step_up_action(action, socket.assigns.invoice),
               &execute_action(&1, action)
             ) do
          {:ok, socket} -> {:noreply, socket}
          {:challenge, socket} -> {:noreply, socket}
          {:error, reason, socket} -> {:noreply, push_flash(socket, :error, inspect(reason))}
        end

      action ->
        {:noreply, execute_action(socket, action)}
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

  def handle_event("open_pdf", _params, socket) do
    case Billing.render_invoice_pdf(socket.assigns.invoice,
           locale: customer_locale(socket.assigns.customer)
         ) do
      {:ok, binary} ->
        href = "data:application/pdf;base64," <> Base.encode64(binary)
        filename = (socket.assigns.invoice.number || socket.assigns.invoice.id) <> ".pdf"

        {:noreply,
         socket
         |> assign(:generated_pdf_href, href)
         |> assign(:generated_pdf_filename, filename)
         |> push_flash(:info, Copy.invoice_pdf_open_info())}

      {:error, reason} ->
        {:noreply, push_flash(socket, :error, "Could not render PDF: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_info({:pdf_rendered, _html, _opts}, socket), do: {:noreply, socket}

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
      <section
        class="ax-page"
        phx-window-keydown="step_up_escape"
        phx-key="escape"
      >
        <header class="ax-page-header">
          <Breadcrumbs.breadcrumbs
            items={[
              %{label: "Dashboard", href: ScopedPath.build(@admin_mount_path, "", @current_owner_scope)},
              %{label: "Invoices", href: ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope)},
              %{
                label: customer_label(@customer),
                href: ScopedPath.build(@admin_mount_path, "/customers/#{@customer.id}", @current_owner_scope)
              },
              %{label: invoice_label(@invoice)}
            ]}
          />
          <p class="ax-eyebrow">Invoice detail</p>
          <h2 class="ax-display"><%= invoice_label(@invoice) %></h2>
          <p class="ax-body ax-page-copy">
            <%= customer_label(@customer) %> · <%= @invoice.processor_id || @invoice.id %> · due <%= format_datetime(@invoice.due_date) %>
          </p>
        </header>

        <FlashGroup.flash_group flashes={@flashes} />

        <section class="ax-kpi-grid" aria-label="Invoice summary">
          <KpiCard.kpi_card label="Status" value={humanize(@invoice.status)}>
            <:meta><StatusBadge.status_badge status={@invoice.status} /></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Amount due"
            value={money_text(@invoice.amount_due_minor, @invoice.currency)}
            delta={money_text(@invoice.amount_paid_minor, @invoice.currency) <> " paid"}
            delta_tone="cobalt"
          >
            <:meta><%= money_text(@invoice.amount_remaining_minor, @invoice.currency) %> remaining</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Line items"
            value={Integer.to_string(length(@line_items))}
            delta={pdf_summary(@invoice)}
            delta_tone="slate"
          >
            <:meta>PDF preview stays on the Phase 6 invoice render path</:meta>
          </KpiCard.kpi_card>
        </section>

        <TaxOwnershipCard.tax_ownership_card row={TaxOwnershipRow.from_invoice(@invoice, @customer)} />

        <section class="ax-grid ax-grid-2">
          <article class="ax-card">
            <section
              :if={tax_failure_visible?(@invoice)}
              class="ax-card"
              data-role="tax-risk-panel"
            >
              <p class="ax-eyebrow">Tax risk</p>
              <h3 class="ax-heading">Invoice finalization needs tax-location recovery</h3>
              <p :if={present?(@invoice.automatic_tax_disabled_reason)} class="ax-body">
                Automatic tax disabled reason: <%= humanize(@invoice.automatic_tax_disabled_reason) %>.
              </p>
              <p :if={present?(@invoice.last_finalization_error_code)} class="ax-body">
                Finalization failure code: <%= @invoice.last_finalization_error_code %>.
              </p>
              <p class="ax-body">
                This view reflects local invoice state only. Repair the customer tax location, then retry finalization from Accrue.
              </p>
            </section>

            <header class="ax-page-header">
              <p class="ax-eyebrow">Admin actions</p>
              <h3 class="ax-heading">Invoice workflow controls</h3>
              <p class="ax-body">Actions run through the existing billing facade and record admin audit rows.</p>
            </header>

            <div class="ax-stack-xl">
              <form phx-submit="prepare_action" data-role="finalize-form">
                <input type="hidden" name="action_type" value="finalize" />
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">Finalize invoice</button>
              </form>

              <form phx-submit="prepare_action" data-role="pay-form">
                <input type="hidden" name="action_type" value="pay" />
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">Manual pay</button>
              </form>

              <form phx-submit="prepare_action" data-role="void-form">
                <input type="hidden" name="action_type" value="void" />
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">Void invoice</button>
              </form>

              <form phx-submit="prepare_action" data-role="mark-uncollectible-form">
                <input type="hidden" name="action_type" value="mark_uncollectible" />
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">Mark uncollectible</button>
              </form>
            </div>

            <section :if={@pending_action} class="ax-card" data-role="confirm-panel">
              <p class="ax-label">Confirm action</p>
              <p class="ax-body"><%= confirm_copy(@pending_action) %></p>
              <div class="ax-page-header">
                <button phx-click="confirm_action" class="ax-button ax-button-primary" data-role="confirm-action">
                  Confirm <%= humanize(@pending_action.type) %>
                </button>
                <button phx-click="cancel_pending_action" class="ax-button ax-button-ghost">Cancel</button>
              </div>
            </section>
          </article>

          <article class="ax-card">
            <header class="ax-page-header">
              <p class="ax-eyebrow">PDF</p>
              <h3 class="ax-heading">Preview and download</h3>
              <p class="ax-body">Open PDF reuses `Accrue.Billing.render_invoice_pdf/2` and never invents a new storage path.</p>
            </header>

            <div class="ax-stack-xl">
              <button phx-click="open_pdf" class="ax-button ax-button-primary">Open PDF</button>

              <a
                :if={@invoice.pdf_url}
                href={@invoice.pdf_url}
                target="_blank"
                rel="noreferrer"
                class="ax-link"
              >
                Processor PDF
              </a>

              <a
                :if={@invoice.hosted_url}
                href={@invoice.hosted_url}
                target="_blank"
                rel="noreferrer"
                class="ax-link"
              >
                Hosted invoice
              </a>

              <div :if={@generated_pdf_href} class="ax-stack-sm" data-role="generated-pdf-links">
                <a
                  href={@generated_pdf_href}
                  target="_blank"
                  rel="noreferrer"
                  class="ax-link"
                  data-role="open-pdf-link"
                >
                  Open rendered PDF
                </a>
                <a
                  href={@generated_pdf_href}
                  download={@generated_pdf_filename}
                  class="ax-link"
                  data-role="download-pdf-link"
                >
                  Download rendered PDF
                </a>
              </div>
            </div>
          </article>
        </section>

        <section class="ax-card">
          <header class="ax-page-header">
            <p class="ax-eyebrow">Line items</p>
            <h3 class="ax-heading">Invoice rows</h3>
          </header>

          <div :for={item <- @line_items} class="ax-list-row">
            <div>
              <p class="ax-label"><%= item.description || item.price_ref || item.stripe_id || item.id %></p>
              <p class="ax-body">
                qty <%= item.quantity || 1 %>
                <span :if={item.proration}> · proration</span>
                <span :if={item.period_start || item.period_end}>
                  · <%= format_datetime(item.period_start) %> to <%= format_datetime(item.period_end) %>
                </span>
              </p>
            </div>
            <MoneyFormatter.money_formatter
              amount_minor={item.amount_minor || 0}
              currency={item.currency || @invoice.currency || "usd"}
              customer={@customer}
            />
          </div>

          <p :if={@line_items == []} class="ax-body">No line items are projected for this invoice yet.</p>
        </section>

        <section class="ax-card">
          <header class="ax-page-header">
            <p class="ax-eyebrow">Timeline</p>
            <h3 class="ax-heading">Invoice events</h3>
          </header>

          <Timeline.timeline
            label="Invoice events"
            empty_label="No invoice-scoped events yet"
            items={timeline_items(@timeline_events)}
          />
        </section>

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
    <label class="ax-label" for={"invoice-source-event-" <> Integer.to_string(System.unique_integer([:positive]))}>
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
    |> assign(:page_title, "Invoice")
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/invoices"))
  end

  defp assign_invoice(socket, invoice) do
    socket
    |> assign(:invoice, invoice)
    |> assign(:customer, invoice.customer)
    |> assign(:line_items, invoice.items || [])
    |> assign(:timeline_events, timeline_events(invoice.id))
  end

  defp load_invoice(invoice_id) do
    Invoice
    |> Repo.get(invoice_id)
    |> case do
      nil -> nil
      invoice -> Repo.preload(invoice, [:customer, :items])
    end
  end

  defp timeline_events(invoice_id), do: Events.timeline_for("Invoice", invoice_id, limit: 25)

  defp pending_action(params, events) do
    source_event = selected_source_event(params, events)

    %{
      type: Map.fetch!(params, "action_type"),
      source_event_id: source_event && source_event.id,
      source_webhook_event_id: source_event && source_event.caused_by_webhook_event_id
    }
  end

  defp selected_source_event(%{"source_event_id" => event_id}, events)
       when event_id not in [nil, ""] do
    Enum.find(events, fn event -> Integer.to_string(event.id) == event_id end)
  end

  defp selected_source_event(_params, _events), do: nil

  defp dismiss_step_up_if_pending(socket) do
    if socket.assigns[:step_up_pending] do
      StepUp.dismiss_challenge(socket)
    else
      socket
    end
  end

  defp step_up_action(action, invoice) do
    %{
      type: "invoice." <> action.type,
      subject_type: "Invoice",
      subject_id: invoice.id,
      caused_by_event_id: action.source_event_id,
      caused_by_webhook_event_id: action.source_webhook_event_id
    }
  end

  defp execute_action(socket, action) do
    result =
      with_admin_context(socket.assigns.current_admin, fn operation_id ->
        run_invoice_action(socket.assigns.invoice, action, operation_id)
      end)

    case result do
      {:ok, %Invoice{} = invoice} ->
        socket
        |> record_admin_audit(action, invoice.id)
        |> refresh_invoice(invoice.id)
        |> push_flash(:info, Copy.invoice_action_recorded_info())

      {:ok, :requires_action, payment_intent} ->
        push_flash(socket, :warning, Copy.payment_processor_action_warning(payment_intent))

      {:error, reason} ->
        push_flash(socket, :error, inspect(reason))
    end
    |> assign(:pending_action, nil)
  end

  defp run_invoice_action(invoice, %{type: "finalize"}, operation_id) do
    Billing.finalize_invoice(invoice, operation_id: operation_id)
  end

  defp run_invoice_action(invoice, %{type: "pay"}, operation_id) do
    Billing.pay_invoice(invoice, operation_id: operation_id)
  end

  defp run_invoice_action(invoice, %{type: "void"}, operation_id) do
    Billing.void_invoice(invoice, operation_id: operation_id)
  end

  defp run_invoice_action(invoice, %{type: "mark_uncollectible"}, operation_id) do
    Billing.mark_uncollectible(invoice, operation_id: operation_id)
  end

  defp run_invoice_action(_invoice, %{type: other}, _operation_id),
    do: {:error, {:unsupported_action, other}}

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

  defp record_admin_audit(socket, action, subject_id) do
    {:ok, _event} =
      Events.record(%{
        type: "admin.invoice.action.completed",
        subject_type: "Invoice",
        subject_id: subject_id,
        actor_type: "admin",
        actor_id: Auth.actor_id(socket.assigns.current_admin),
        caused_by_event_id: action.source_event_id,
        caused_by_webhook_event_id: action.source_webhook_event_id,
        data: %{"action_type" => action.type}
      })

    socket
  end

  defp refresh_invoice(socket, invoice_id) do
    invoice = load_invoice(invoice_id)
    assign_invoice(socket, invoice)
  end

  defp invoice_label(invoice), do: invoice.number || invoice.processor_id || invoice.id

  defp customer_label(customer),
    do: customer.name || customer.email || customer.processor_id || customer.id

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

  defp tone(%{type: type}) when type in ["invoice.marked_uncollectible", "invoice.voided"],
    do: :amber

  defp tone(%{type: "invoice.paid"}), do: :moss
  defp tone(_event), do: :slate

  defp push_flash(socket, kind, message) do
    assign(socket, :flashes, [%{kind: kind, message: message} | socket.assigns.flashes])
  end

  defp tax_failure_visible?(invoice) do
    present?(invoice.automatic_tax_disabled_reason) or
      present?(invoice.last_finalization_error_code)
  end

  defp present?(value) when value in [nil, ""], do: false
  defp present?(_value), do: true

  defp confirm_copy(action) do
    source =
      if action.source_event_id do
        " Source event ##{action.source_event_id} will be linked."
      else
        ""
      end

    "#{humanize(action.type)} will use the existing invoice workflow APIs.#{source}"
  end

  defp pdf_summary(invoice) do
    cond do
      invoice.pdf_url -> "processor PDF ready"
      invoice.hosted_url -> "hosted invoice ready"
      true -> "render on demand"
    end
  end

  defp money_text(amount_minor, currency) when is_integer(amount_minor) do
    Accrue.Invoices.Render.format_money(
      amount_minor,
      normalize_currency(currency),
      customer_locale(nil)
    )
  end

  defp money_text(_amount_minor, _currency), do: "--"

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

  defp customer_locale(%{preferred_locale: locale}) when is_binary(locale) and locale != "",
    do: locale

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
