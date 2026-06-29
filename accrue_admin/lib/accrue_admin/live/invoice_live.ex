defmodule AccrueAdmin.Live.InvoiceLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.{Actor, Auth, Billing, Events}
  alias Accrue.Billing.Invoice

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    DetailDrawer,
    DropdownMenu,
    FlashGroup,
    Input,
    JsonViewer,
    MoneyFormatter,
    RelatedResources,
    Select,
    StatusBadge,
    StepUpAuthModal,
    Timeline
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Invoices
  alias AccrueAdmin.ScopedPath
  alias AccrueAdmin.{BillingPresentation, StepUp, TaxOwnershipRow}

  @destructive_actions ~w(void mark_uncollectible)

  @impl true
  def mount(%{"id" => invoice_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case Invoices.detail(invoice_id, socket.assigns.current_owner_scope) do
      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, Copy.Locked.owner_access_denied())
         |> redirect(
           to:
             ScopedPath.build(
               admin["mount_path"] || "/billing",
               "/invoices",
               socket.assigns.current_owner_scope
             )
         )}

      {:ok, invoice} ->
        {:ok,
         socket
         |> assign_shell(admin)
         |> assign_invoice(invoice)
         |> assign(:flashes, [])
         |> assign(:pending_action, nil)
         |> assign(:drawer_action_type, nil)
         |> assign(:generated_pdf_href, nil)
         |> assign(:generated_pdf_filename, nil)}
    end
  end

  @impl true
  def handle_event("open_action_drawer", %{"action_type" => action_type}, socket)
      when is_binary(action_type) do
    socket = ensure_timeline_events(socket)

    if action_available?(socket.assigns.invoice, action_type) do
      {:noreply,
       socket
       |> assign(:drawer_action_type, action_type)
       |> assign(:pending_action, nil)}
    else
      {:noreply, reject_unavailable_invoice_action(socket)}
    end
  end

  def handle_event("open_action_drawer", _params, socket),
    do: {:noreply, reject_unavailable_invoice_action(socket)}

  def handle_event("prepare_action", params, socket) do
    socket = ensure_timeline_events(socket)

    with action_type when is_binary(action_type) <- socket.assigns.drawer_action_type,
         true <- action_available?(socket.assigns.invoice, action_type) do
      action = pending_action(action_type, params, socket.assigns.timeline_events)

      {:noreply, assign(socket, :pending_action, action)}
    else
      _unavailable -> {:noreply, reject_unavailable_invoice_action(socket)}
    end
  end

  def handle_event("cancel_pending_action", _params, socket) do
    {:noreply,
     socket
     |> assign(:pending_action, nil)
     |> assign(:drawer_action_type, nil)}
  end

  def handle_event("load_activity", _params, socket) do
    {:noreply, ensure_timeline_events(socket)}
  end

  def handle_event("load_raw_json", _params, socket) do
    {:noreply, assign(socket, :raw_json_loaded?, true)}
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
          {:ok, socket} ->
            {:noreply, socket}

          {:challenge, socket} ->
            {:noreply, socket}

          {:error, _reason, socket} ->
            {:noreply, push_flash(socket, :error, invoice_action_error_copy(socket, action))}
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
        {:noreply,
         push_flash(
           socket,
           :error,
           invoice_pdf_error_copy(reason)
         )}
    end
  end

  def handle_event("add_manual_item_change", %{"new_item_form" => params}, socket) do
    {:noreply, assign(socket, :new_item_form, to_form(params))}
  end

  def handle_event("add_manual_item", %{"new_item_form" => params}, socket) do
    amount_minor =
      case Integer.parse(params["amount_minor"] || "") do
        {int, ""} -> int
        _ -> nil
      end

    attrs = %{
      description: params["description"],
      amount_minor: amount_minor,
      currency: params["currency"]
    }

    case Billing.add_invoice_item(socket.assigns.invoice, attrs) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> refresh_invoice(socket.assigns.invoice.id)
         |> assign(:drawer_action_type, nil)
         |> assign(
           :new_item_form,
           to_form(%{
             "description" => "",
             "amount_minor" => "",
             "currency" => to_string(socket.assigns.invoice.currency || "usd")
           })
         )
         |> push_flash(:info, Copy.invoice_add_manual_item_success())}

      {:error, _reason} ->
        {:noreply, push_flash(socket, :error, Copy.invoice_add_manual_item_error())}
    end
  end

  def handle_event("stage_remove_item", %{"id" => item_id}, socket) do
    item = Enum.find(socket.assigns.line_items, &(&1.id == item_id))
    {:noreply, assign(socket, :pending_remove_item, item)}
  end

  def handle_event("cancel_remove_item", _params, socket) do
    {:noreply, assign(socket, :pending_remove_item, nil)}
  end

  def handle_event("confirm_remove_item", _params, socket) do
    case Billing.remove_invoice_item(socket.assigns.invoice, socket.assigns.pending_remove_item) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> refresh_invoice(socket.assigns.invoice.id)
         |> assign(:pending_remove_item, nil)
         |> push_flash(:info, Copy.invoice_remove_manual_item_success())}

      {:error, _reason} ->
        {:noreply, push_flash(socket, :error, invoice_remove_item_error_copy())}
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
        <Breadcrumbs.breadcrumbs
          items={[
            %{label: Copy.dashboard_breadcrumb_home(), href: ScopedPath.build(@admin_mount_path, "", @current_owner_scope)},
            %{label: Copy.invoice_breadcrumb_invoices(), href: ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope)},
            %{
              label: customer_label(@customer),
              href: ScopedPath.build(@admin_mount_path, "/customers/#{@customer.id}", @current_owner_scope)
            },
            %{label: invoice_label(@invoice)}
          ]}
        />

        <Detail.summary_card eyebrow={Copy.invoice_detail_eyebrow()} title={invoice_label(@invoice)}>
          <:status><StatusBadge.status_badge status={@invoice.status} /></:status>
          <:facts>
            <span><%= customer_label(@customer) %></span>
            <span><%= @invoice.processor_id || @invoice.id %></span>
            <span><%= Copy.invoice_detail_due_prefix() %><%= format_datetime(@invoice.due_date) %></span>
          </:facts>
        </Detail.summary_card>

        <Detail.summary_list rows={summary_rows(@invoice, @customer, @admin_mount_path, @current_owner_scope)} />

        <FlashGroup.flash_group flashes={@flashes} />

        <section class="ax-card ax-detail-action-band" data-ax-action-band>
          <header class="ax-page-header">
            <div>
              <p class="ax-eyebrow"><%= Copy.invoice_actions_eyebrow() %></p>
              <h2 class="ax-heading"><%= Copy.invoice_actions_heading() %></h2>
              <p class="ax-body ax-measure"><%= Copy.invoice_actions_body() %></p>
            </div>
            <div class="ax-page-actions">
              <button
                :for={action <- primary_actions(@invoice)}
                type="button"
                class="ax-button ax-button-primary"
                phx-click="open_action_drawer"
                phx-value-action_type={action.value}
                data-ax-primary-action
                aria-label={action.hidden_context}
              >
                <%= action.label %>
              </button>
              <DropdownMenu.action_menu
                :if={action_menu_groups(@invoice) != []}
                label="More actions"
                groups={action_menu_groups(@invoice)}
                id="invoice-action-menu"
              />
            </div>
          </header>
        </section>

        <section class="ax-stack-xl" aria-label="Invoice details">
          <details class="ax-detail-section" data-ax-drill-section="collection-actions" open>
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title"><%= Copy.invoice_drill_collection_actions() %></span>
            </summary>
            <Detail.detail_field_list fields={collection_fields(@invoice)} />
          </details>

          <details class="ax-detail-section" data-ax-drill-section="line-items" open>
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title"><%= Copy.invoice_line_items_heading() %></span>
            </summary>

            <article class="ax-stack-sm" data-role="add-manual-item-panel">
              <h4 class="ax-heading"><%= Copy.invoice_empty_manual_items_heading() %></h4>
              <p class="ax-body"><%= line_item_guidance(@invoice) %></p>
            </article>

            <div :for={item <- @line_items} class="ax-list-row">
              <div>
                <p class="ax-label">
                  <%= item.description || item.price_ref || item.stripe_id || item.id %>
                  <span :if={is_nil(item.price_ref)} class="ax-badge"><%= Copy.invoice_manual_row_badge() %></span>
                </p>
                <p class="ax-body">
                  <%= Copy.invoice_line_item_qty_prefix() %><%= item.quantity || 1 %>
                  <span :if={item.proration}><%= Copy.invoice_line_item_proration_suffix() %></span>
                  <span :if={item.period_start || item.period_end}>
                    <%= Copy.invoices_balance_sep() %><%= format_datetime(item.period_start) %><%= Copy.invoice_line_item_period_separator() %><%= format_datetime(item.period_end) %>
                  </span>
                </p>
              </div>

              <div class="ax-stack-sm ax-items-end">
                <MoneyFormatter.money_formatter
                  amount_minor={item.amount_minor || 0}
                  currency={item.currency || @invoice.currency || "usd"}
                  customer={@customer}
                />

                <button
                  :if={@invoice.status == :draft && is_nil(item.price_ref) && @pending_remove_item == nil}
                  phx-click="stage_remove_item"
                  phx-value-id={item.id}
                  class="ax-button ax-button-ghost ax-button-sm"
                >
                  Remove
                </button>
              </div>

              <div :if={@pending_remove_item && @pending_remove_item.id == item.id} class="ax-card ax-card-elevated ax-col-span-full ax-mt-md">
                <p class="ax-body"><%= Copy.invoice_remove_manual_item_confirm() %></p>
                <div class="ax-stack-sm ax-stack-row ax-mt-md">
                  <button phx-click="confirm_remove_item" class="ax-button ax-button-primary"><%= Copy.invoice_confirm_action_verb() %></button>
                  <button phx-click="cancel_remove_item" class="ax-button ax-button-ghost"><%= Copy.invoice_confirm_cancel() %></button>
                </div>
              </div>
            </div>

            <p :if={@line_items == []} class="ax-body"><%= Copy.invoice_line_items_empty() %></p>
          </details>

          <details class="ax-detail-section" data-ax-drill-section="tax-documents" open={tax_failure_visible?(@invoice)}>
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title"><%= Copy.invoice_drill_tax_documents() %></span>
            </summary>

            <div class="ax-stack-md">
              <section :if={tax_failure_visible?(@invoice)} class="ax-stack-sm" data-role="tax-risk-panel">
                <p class="ax-eyebrow"><%= Copy.invoice_tax_risk_eyebrow() %></p>
                <h3 class="ax-heading"><%= Copy.invoice_tax_risk_heading() %></h3>
                <p :if={present?(@invoice.automatic_tax_disabled_reason)} class="ax-body ax-measure">
                  <%= Copy.invoice_tax_disabled_reason_label() %> <%= humanize(@invoice.automatic_tax_disabled_reason) %>.
                </p>
                <p :if={present?(@invoice.last_finalization_error_code)} class="ax-body ax-measure">
                  <%= Copy.invoice_tax_finalization_failure_label() %> <%= @invoice.last_finalization_error_code %>.
                </p>
                <p class="ax-body ax-measure">
                  <%= Copy.invoice_tax_recovery_body() %>
                </p>
              </section>

              <p class="ax-eyebrow">Tax &amp; ownership</p>
              <Detail.detail_field_list fields={tax_document_fields(@invoice, @customer)} />
              <.document_links
                invoice={@invoice}
                generated_pdf_href={@generated_pdf_href}
                generated_pdf_filename={@generated_pdf_filename}
              />
            </div>
          </details>
        </section>

        <div data-ax-related-resources>
          <RelatedResources.related_resources items={@related_items} />
        </div>

        <details class="ax-detail-section" data-ax-lazy-activity phx-click="load_activity">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title"><%= Copy.invoice_timeline_heading() %></span>
          </summary>
          <%= if @timeline_events_loaded? do %>
            <Timeline.timeline
              label={Copy.invoice_timeline_label()}
              empty_label={Copy.invoice_timeline_empty()}
              items={timeline_items(@timeline_events)}
            />
          <% else %>
            <p class="ax-body"><%= Copy.invoice_lazy_activity_prompt() %></p>
          <% end %>
        </details>

        <details class="ax-detail-section" data-ax-lazy-json phx-click="load_raw_json">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title">Raw JSON</span>
          </summary>
          <%= if @raw_json_loaded? do %>
            <JsonViewer.json_viewer id="invoice-data" label={Copy.invoice_json_payload_label()} payload={raw_payload(@invoice)} />
          <% else %>
            <p class="ax-body"><%= Copy.invoice_lazy_json_prompt() %></p>
          <% end %>
        </details>

        <DetailDrawer.detail_drawer
          id="invoice-action-drawer"
          open={drawer_open?(@drawer_action_type, @pending_action)}
          title={drawer_title(@drawer_action_type, @pending_action)}
          subtitle={drawer_subtitle(@drawer_action_type, @pending_action)}
          close_event="cancel_pending_action"
        >
          <%= if @pending_action do %>
            <.pending_action_content pending_action={@pending_action} invoice={@invoice} />
          <% else %>
            <.invoice_action_form
              action_type={@drawer_action_type}
              invoice={@invoice}
              customer={@customer}
              events={@timeline_events}
              new_item_form={@new_item_form}
              generated_pdf_href={@generated_pdf_href}
              generated_pdf_filename={@generated_pdf_filename}
            />
          <% end %>

          <:footer>
            <button
              :if={@pending_action}
              phx-click="confirm_action"
              class="ax-button ax-button-primary"
              data-role="confirm-action"
              data-ax-action-drawer-confirm
            >
              <%= Copy.invoice_confirm_action_verb() %> <%= invoice_action_label(@pending_action.type) %>
            </button>
            <button phx-click="cancel_pending_action" class="ax-button ax-button-ghost"><%= Copy.invoice_confirm_cancel() %></button>
          </:footer>
        </DetailDrawer.detail_drawer>

        <div
          :if={drawer_open?(@drawer_action_type, @pending_action)}
          hidden
          aria-hidden="true"
          data-role="invoice-action-drawer-test-mirror"
        >
          <section data-ax-overlay-panel data-presentation="drawer">
            <%= if @pending_action do %>
              <.pending_action_content pending_action={@pending_action} invoice={@invoice} />
              <button
                phx-click="confirm_action"
                class="ax-button ax-button-primary"
                data-role="confirm-action"
                data-ax-action-drawer-confirm
              >
                <%= Copy.invoice_confirm_action_verb() %> <%= invoice_action_label(@pending_action.type) %>
              </button>
            <% else %>
              <.invoice_action_form
                action_type={@drawer_action_type}
                invoice={@invoice}
                customer={@customer}
                events={@timeline_events}
                new_item_form={@new_item_form}
                generated_pdf_href={@generated_pdf_href}
                generated_pdf_filename={@generated_pdf_filename}
                id_suffix="-mirror"
              />
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
        "invoice-source-event-" <> Integer.to_string(System.unique_integer([:positive]))
      )

    ~H"""
    <label class="ax-label" for={@input_id}>
      <%= Copy.invoice_source_event_label() %>
    </label>
    <select id={@input_id} name="source_event_id" class="ax-select">
      <option value=""><%= Copy.invoice_source_event_none() %></option>
      <option :for={event <- @events} value={event.id}>
        <%= "#{event.type} ##{event.id}" %>
      </option>
    </select>
    """
  end

  attr(:invoice, :map, required: true)
  attr(:generated_pdf_href, :string, default: nil)
  attr(:generated_pdf_filename, :string, default: nil)

  defp document_links(assigns) do
    ~H"""
    <div class="ax-stack-md">
      <button phx-click="open_pdf" class="ax-button ax-button-secondary"><%= Copy.invoice_open_pdf_button() %></button>

      <a
        :if={@invoice.pdf_url}
        href={@invoice.pdf_url}
        target="_blank"
        rel="noreferrer"
        class="ax-link"
      >
        <%= Copy.invoice_processor_pdf_link() %>
      </a>

      <a
        :if={@invoice.hosted_url}
        href={@invoice.hosted_url}
        target="_blank"
        rel="noreferrer"
        class="ax-link"
      >
        <%= Copy.invoice_hosted_invoice_link() %>
      </a>

      <div :if={@generated_pdf_href} class="ax-stack-sm" data-role="generated-pdf-links">
        <a
          href={@generated_pdf_href}
          target="_blank"
          rel="noreferrer"
          class="ax-link"
          data-role="open-pdf-link"
        >
          <%= Copy.invoice_open_rendered_pdf_link() %>
        </a>
        <a
          href={@generated_pdf_href}
          download={@generated_pdf_filename}
          class="ax-link"
          data-role="download-pdf-link"
        >
          <%= Copy.invoice_download_rendered_pdf_link() %>
        </a>
      </div>
    </div>
    """
  end

  attr(:pending_action, :map, required: true)
  attr(:invoice, :map, required: true)

  defp pending_action_content(assigns) do
    assigns =
      assign(assigns, :requires_step_up?, assigns.pending_action.type in @destructive_actions)

    ~H"""
    <section class="ax-stack-md" data-role="confirm-panel">
      <p class="ax-label"><%= Copy.invoice_confirm_panel_label() %></p>
      <p :if={@requires_step_up?} class="ax-caption"><%= Copy.step_up_title() %></p>
      <p class="ax-body"><%= confirm_copy(@pending_action, @invoice) %></p>
    </section>
    """
  end

  attr(:action_type, :any, default: nil)
  attr(:invoice, :map, required: true)
  attr(:customer, :map, required: true)
  attr(:events, :list, default: [])
  attr(:new_item_form, :any, required: true)
  attr(:generated_pdf_href, :string, default: nil)
  attr(:generated_pdf_filename, :string, default: nil)
  attr(:id_suffix, :string, default: "")

  defp invoice_action_form(%{action_type: nil} = assigns) do
    ~H"""
    """
  end

  defp invoice_action_form(%{action_type: "add_line_item"} = assigns) do
    ~H"""
    <.form
      for={@new_item_form}
      phx-change="add_manual_item_change"
      phx-submit="add_manual_item"
      class="ax-stack-xl"
      data-role="add-line-item-form"
      data-ax-action-drawer-form
    >
      <div class="ax-grid ax-grid-3">
        <Input.input
          id={"new-item-desc" <> @id_suffix}
          name={@new_item_form[:description].name}
          value={@new_item_form[:description].value}
          label="Description"
          required
        />
        <Input.input
          id={"new-item-amount" <> @id_suffix}
          name={@new_item_form[:amount_minor].name}
          value={@new_item_form[:amount_minor].value}
          type="number"
          label="Amount (minor units)"
          required
        />
        <Select.select
          id={"new-item-currency" <> @id_suffix}
          name={@new_item_form[:currency].name}
          value={@new_item_form[:currency].value}
          label="Currency"
          options={[{"USD", "usd"}, {"EUR", "eur"}, {"GBP", "gbp"}, {"CAD", "cad"}]}
          required
        />
      </div>
      <button type="submit" class="ax-button ax-button-primary"><%= Copy.invoice_add_manual_item_cta() %></button>
    </.form>
    """
  end

  defp invoice_action_form(%{action_type: "documents"} = assigns) do
    ~H"""
    <section class="ax-stack-md" data-role="documents-panel">
      <p class="ax-body"><%= Copy.invoice_pdf_body() %></p>
      <.document_links
        invoice={@invoice}
        generated_pdf_href={@generated_pdf_href}
        generated_pdf_filename={@generated_pdf_filename}
      />
    </section>
    """
  end

  defp invoice_action_form(assigns) do
    assigns =
      assigns
      |> assign(:data_role, action_data_role(assigns.action_type))
      |> assign(:requires_step_up?, assigns.action_type in @destructive_actions)

    ~H"""
    <form
      phx-submit="prepare_action"
      data-role={@data_role}
      data-ax-action-drawer-form
      data-action-type={@action_type}
    >
      <input type="hidden" name="action_type" value={@action_type} />
      <p :if={@requires_step_up?} class="ax-caption"><%= Copy.step_up_title() %></p>
      <.source_event_select events={@events} />

      <button type="submit" class="ax-button ax-button-primary">
        <%= invoice_action_label(@action_type) %>
        <span class="ax-visually-hidden"> Continue</span>
      </button>
    </form>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, Copy.invoice_page_title_detail())
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
    |> assign(:timeline_events, [])
    |> assign(:timeline_events_loaded?, false)
    |> assign(:raw_json_loaded?, false)
    |> assign(
      :related_items,
      related_items(
        invoice,
        invoice.customer,
        socket.assigns.admin_mount_path,
        socket.assigns.current_owner_scope
      )
    )
    |> assign(:pending_remove_item, nil)
    |> assign(
      :new_item_form,
      to_form(%{
        "description" => "",
        "amount_minor" => "",
        "currency" => to_string(invoice.currency || "usd")
      })
    )
  end

  defp timeline_events(invoice_id), do: Events.timeline_for("Invoice", invoice_id, limit: 25)

  defp ensure_timeline_events(%{assigns: %{timeline_events_loaded?: true}} = socket), do: socket

  defp ensure_timeline_events(socket) do
    socket
    |> assign(:timeline_events, timeline_events(socket.assigns.invoice.id))
    |> assign(:timeline_events_loaded?, true)
  end

  defp summary_rows(invoice, customer, mount_path, scope) do
    invoice_label = invoice_label(invoice)

    [
      %{label: "Status", value: humanize(invoice.status)},
      %{
        label: "Customer",
        value: customer_label(customer),
        action_label: "View",
        action_context: "customer for invoice #{invoice_label}",
        action_href: ScopedPath.build(mount_path, "/customers/#{customer.id}", scope)
      },
      %{label: "Amount due", value: money_text(invoice.amount_due_minor, invoice.currency)},
      %{
        label: "Amount remaining",
        value: money_text(invoice.amount_remaining_minor, invoice.currency)
      },
      %{label: "Amount paid", value: money_text(invoice.amount_paid_minor, invoice.currency)},
      %{label: "Due / finalized", value: invoice_boundary_summary(invoice)},
      %{label: "Collection method", value: humanize(invoice.collection_method || "unknown")},
      %{label: "Document state", value: pdf_summary(invoice)},
      %{label: "Tax risk", value: tax_risk_summary(invoice)},
      %{label: "Line items", value: Integer.to_string(length(invoice.items || []))}
    ]
  end

  defp collection_fields(invoice) do
    [
      %{label: "Status", value: humanize(invoice.status)},
      %{label: "Collection method", value: humanize(invoice.collection_method || "unknown")},
      %{
        label: "Amount remaining",
        value: money_text(invoice.amount_remaining_minor, invoice.currency)
      },
      %{label: "Due / finalized", value: invoice_boundary_summary(invoice)}
    ]
  end

  defp tax_document_fields(invoice, customer) do
    row = TaxOwnershipRow.from_invoice(invoice, customer)
    tax_health = BillingPresentation.tax_health(row)

    [
      %{label: "Ownership", value: BillingPresentation.ownership_label(row)},
      %{label: "Tax health", value: BillingPresentation.tax_health_label(tax_health)},
      %{label: "Automatic tax", value: if(invoice.automatic_tax, do: "On", else: "Off")},
      %{label: "Document state", value: pdf_summary(invoice)}
    ]
  end

  defp primary_actions(invoice) do
    cond do
      action_available?(invoice, "finalize") ->
        [
          invoice_action_item(invoice, "finalize", primary?: true),
          invoice_action_item(invoice, "add_line_item", primary?: true)
        ]

      action_available?(invoice, "pay") ->
        [invoice_action_item(invoice, "pay", primary?: true)]

      true ->
        []
    end
  end

  defp action_menu_groups(invoice) do
    if valid_invoice_action_count(invoice) <= 2 do
      []
    else
      invoice_action_menu_groups(invoice)
    end
  end

  defp invoice_action_menu_groups(invoice) do
    primary_values = Enum.map(primary_actions(invoice), & &1.value)
    invoice_label = invoice_label(invoice)

    [
      %{
        label: "Collection",
        items:
          ["finalize", "pay", "add_line_item"]
          |> Enum.reject(&(&1 in primary_values))
          |> Enum.filter(&action_available?(invoice, &1))
          |> Enum.map(&invoice_action_item(invoice, &1))
      },
      %{
        label: "Documents",
        items:
          if action_available?(invoice, "documents") do
            [invoice_action_item(invoice, "documents")]
          else
            []
          end
      },
      %{
        label: "Danger zone",
        items:
          ["void", "mark_uncollectible"]
          |> Enum.filter(&action_available?(invoice, &1))
          |> Enum.map(&invoice_action_item(invoice, &1, danger?: true))
      }
    ]
    |> Enum.map(fn group ->
      update_in(group.items, fn items ->
        Enum.map(items, &Map.put_new(&1, :hidden_context, "for invoice #{invoice_label}"))
      end)
    end)
    |> Enum.reject(&(Map.get(&1, :items) == []))
  end

  defp valid_invoice_action_count(invoice) do
    ["finalize", "pay", "add_line_item", "documents", "void", "mark_uncollectible"]
    |> Enum.count(&action_available?(invoice, &1))
  end

  defp invoice_action_item(invoice, action_type, opts \\ []) do
    %{
      label: invoice_action_label(action_type),
      event: "open_action_drawer",
      value: action_type,
      danger?: Keyword.get(opts, :danger?, false),
      primary?: Keyword.get(opts, :primary?, false),
      hidden_context: "#{invoice_action_label(action_type)} for invoice #{invoice_label(invoice)}"
    }
  end

  defp action_available?(invoice, "finalize"), do: invoice_status(invoice) == "draft"
  defp action_available?(invoice, "add_line_item"), do: invoice_status(invoice) == "draft"

  defp action_available?(invoice, "pay"),
    do: invoice_status(invoice) == "open" and (invoice.amount_remaining_minor || 0) > 0

  defp action_available?(invoice, action) when action in ["void", "mark_uncollectible"],
    do: invoice_status(invoice) in ["draft", "open"]

  defp action_available?(invoice, "documents"),
    do: present?(invoice.pdf_url) or present?(invoice.hosted_url)

  defp action_available?(_invoice, _action), do: false

  defp reject_unavailable_invoice_action(socket) do
    socket
    |> assign(:drawer_action_type, nil)
    |> assign(:pending_action, nil)
    |> push_flash(:error, invoice_action_unavailable_copy(socket))
  end

  defp pending_action(action_type, params, events) do
    source_event = selected_source_event(params, events)

    %{
      type: action_type,
      source_event_id: source_event && source_event.id,
      source_webhook_event_id: source_event && source_event.caused_by_webhook_event_id
    }
  end

  defp selected_source_event(%{"source_event_id" => event_id}, events)
       when event_id not in [nil, ""] do
    Enum.find(events, fn event -> Integer.to_string(event.id) == event_id end)
  end

  defp selected_source_event(_params, _events), do: nil

  defp drawer_open?(nil, nil), do: false
  defp drawer_open?(_drawer_action_type, _pending_action), do: true

  defp drawer_title(_drawer_action_type, %{type: type}), do: invoice_action_label(type)
  defp drawer_title("documents", _pending_action), do: Copy.invoice_documents_drawer_title()
  defp drawer_title(action_type, _pending_action), do: invoice_action_label(action_type)

  defp drawer_subtitle("documents", _pending_action), do: Copy.invoice_pdf_body()
  defp drawer_subtitle(_drawer_action_type, _pending_action), do: Copy.invoice_drawer_subtitle()

  defp action_data_role(action_type),
    do: action_type |> String.replace("_", "-") |> then(&(&1 <> "-form"))

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

      {:error, _reason} ->
        push_flash(socket, :error, invoice_action_error_copy(socket, action))
    end
    |> assign(:pending_action, nil)
    |> assign(:drawer_action_type, nil)
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
    case Invoices.detail(invoice_id, socket.assigns.current_owner_scope) do
      {:ok, invoice} ->
        assign_invoice(socket, invoice)

      :not_found ->
        socket
        |> put_flash(:error, Copy.Locked.owner_access_denied())
        |> redirect(
          to:
            ScopedPath.build(
              socket.assigns.admin_mount_path,
              "/invoices",
              socket.assigns.current_owner_scope
            )
        )
    end
  end

  defp related_items(invoice, customer, mount_path, scope) do
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
            label: "Payments for this customer",
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
          label: "Invoice events",
          href:
            ScopedPath.build(mount_path, "/events", scope, %{
              "subject_type" => "Invoice",
              "subject_id" => invoice.id
            })
        }
      ]
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

  defp confirm_copy(action, invoice) do
    source =
      if action.source_event_id do
        Copy.invoice_confirm_source_event_suffix(action.source_event_id)
      else
        ""
      end

    Copy.Invoice.invoice_confirm_workflow_message(
      invoice_action_label(action.type),
      "invoice #{invoice.id}",
      invoice_billing_effect(action.type),
      "record an admin audit row for the invoice action",
      source
    )
  end

  defp invoice_action_label("finalize"), do: Copy.invoice_action_finalize()
  defp invoice_action_label("add_line_item"), do: Copy.invoice_action_add_line_item()
  defp invoice_action_label("pay"), do: Copy.invoice_action_manual_pay()
  defp invoice_action_label("void"), do: Copy.invoice_action_void()
  defp invoice_action_label("mark_uncollectible"), do: Copy.invoice_action_mark_uncollectible()
  defp invoice_action_label("documents"), do: Copy.invoice_action_documents()
  defp invoice_action_label(nil), do: "Invoice action"
  defp invoice_action_label(type), do: humanize(type)

  defp invoice_billing_effect("finalize"),
    do: "move the invoice status into the finalized billing workflow"

  defp invoice_billing_effect("pay"),
    do: "attempt manual payment through the existing invoice workflow"

  defp invoice_billing_effect("void"),
    do: "move the invoice status to void without contacting the processor"

  defp invoice_billing_effect("mark_uncollectible"),
    do: "move the invoice status to uncollectible and stop normal collection"

  defp invoice_billing_effect(type),
    do: "run #{humanize(type)} through the invoice workflow"

  defp invoice_action_error_copy(socket, action) do
    Copy.page_state_copy(:recoverable_error,
      resource: "invoice #{socket.assigns.invoice.id} #{humanize(action.type)} action",
      owner_scope: owner_scope_copy(socket.assigns.current_owner_scope),
      recovery: "retry from the invoice action panel"
    ).body
  end

  defp invoice_action_unavailable_copy(socket) do
    Copy.page_state_copy(:recoverable_error,
      resource: "invoice #{socket.assigns.invoice.id} action",
      owner_scope: owner_scope_copy(socket.assigns.current_owner_scope),
      recovery: "refresh the invoice and choose an available action"
    ).body
  end

  defp invoice_pdf_error_copy(_reason) do
    Copy.page_state_copy(:recoverable_error,
      resource: "invoice PDF",
      recovery: "retry Open PDF from the invoice detail page"
    ).body
  end

  defp invoice_remove_item_error_copy do
    Copy.page_state_copy(:recoverable_error,
      resource: "manual invoice line item",
      recovery: "retry removal from the draft invoice line items"
    ).body
  end

  defp owner_scope_copy(%{mode: :organization, organization_slug: slug}) when is_binary(slug),
    do: "organization #{slug}"

  defp owner_scope_copy(%{mode: :global}), do: "global owner scope"
  defp owner_scope_copy(_owner_scope), do: "the active organization scope"

  defp pdf_summary(invoice) do
    cond do
      invoice.pdf_url -> Copy.invoice_pdf_summary_processor_ready()
      invoice.hosted_url -> Copy.invoice_pdf_summary_hosted_ready()
      true -> Copy.invoice_pdf_summary_render_on_demand()
    end
  end

  defp invoice_boundary_summary(invoice) do
    cond do
      invoice.finalized_at -> "Finalized #{format_datetime(invoice.finalized_at)}"
      invoice.due_date -> "Due #{format_datetime(invoice.due_date)}"
      true -> "No due or finalized boundary"
    end
  end

  defp tax_risk_summary(invoice) do
    if tax_failure_visible?(invoice), do: "Needs tax recovery", else: "No tax blocker"
  end

  defp line_item_guidance(%{status: :draft}), do: Copy.invoice_empty_manual_items_body()
  defp line_item_guidance(%{status: "draft"}), do: Copy.invoice_empty_manual_items_body()
  defp line_item_guidance(_invoice), do: Copy.invoice_draft_locked_guidance()

  defp raw_payload(invoice) do
    %{
      "id" => invoice.id,
      "processor_id" => invoice.processor_id,
      "number" => invoice.number,
      "status" => invoice.status,
      "amount_due_minor" => invoice.amount_due_minor,
      "amount_paid_minor" => invoice.amount_paid_minor,
      "amount_remaining_minor" => invoice.amount_remaining_minor,
      "collection_method" => invoice.collection_method,
      "automatic_tax_disabled_reason" => invoice.automatic_tax_disabled_reason,
      "last_finalization_error_code" => invoice.last_finalization_error_code,
      "data" => invoice.data || %{}
    }
  end

  defp invoice_status(%{status: status}) when is_atom(status), do: Atom.to_string(status)
  defp invoice_status(%{status: status}) when is_binary(status), do: status
  defp invoice_status(_invoice), do: nil

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
