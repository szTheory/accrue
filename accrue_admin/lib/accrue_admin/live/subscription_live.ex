defmodule AccrueAdmin.Live.SubscriptionLive do
  @moduledoc false

  use Phoenix.LiveView

  import Ecto.Query

  alias Accrue.{Actor, Auth, Billing, Clock, Config, Events, PlanResolver}
  alias Accrue.Billing.{Invoice, Subscription, UpcomingInvoice}
  alias Accrue.Invoices.Render, as: InvoiceRender
  alias Accrue.Dunning.Campaign
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    DetailDrawer,
    DropdownMenu,
    FlashGroup,
    JsonViewer,
    RelatedResources,
    StepUpAuthModal,
    Timeline
  }

  alias AccrueAdmin.BillingPresentation
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Subscriptions
  alias AccrueAdmin.ScopedPath
  alias AccrueAdmin.StepUp
  alias AccrueAdmin.TaxOwnershipRow

  @destructive_actions ~w(cancel_now comp_subscription remove_item)
  @pause_behaviors ~w(void mark_uncollectible keep_as_draft)
  @proration_atoms %{
    "create_prorations" => :create_prorations,
    "none" => :none,
    "always_invoice" => :always_invoice
  }
  @proration_values Map.keys(@proration_atoms)

  @impl true
  def mount(%{"id" => subscription_id}, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    case Subscriptions.detail(subscription_id, socket.assigns.current_owner_scope) do
      :not_found ->
        {:ok,
         socket
         |> put_flash(:error, Copy.Locked.owner_access_denied())
         |> redirect(
           to: scoped_admin_path(admin, socket.assigns.current_owner_scope, "/subscriptions")
         )}

      {:ok, subscription} ->
        mount_path = admin["mount_path"] || "/billing"
        scope = socket.assigns.current_owner_scope
        events = timeline_events(subscription.id)

        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(
           :current_path,
           scoped_admin_path(admin, socket.assigns.current_owner_scope, "/subscriptions")
         )
         |> assign(:subscription, subscription)
         |> assign(:customer, subscription.customer)
         |> assign(:open_invoice_summary, open_invoice_summary(subscription))
         |> assign(:timeline_events, events)
         |> assign(:timeline_events_loaded?, true)
         |> assign(:raw_json_loaded?, false)
         |> assign(:proration_options, proration_options())
         |> assign(:swap_plan_available, swap_plan_available?(subscription))
         |> assign(:related_items, related_items(subscription, mount_path, scope))
         |> assign(:flashes, [])
         |> assign(:drawer_action_type, nil)
         |> assign(:pending_action, nil)}
    end
  end

  @impl true
  def handle_event("open_action_drawer", %{"action_type" => action_type}, socket)
      when is_binary(action_type) do
    socket = ensure_timeline_events(socket)

    if action_available?(socket.assigns.subscription, action_type) do
      {:noreply,
       socket
       |> assign(:drawer_action_type, action_type)
       |> assign(:pending_action, nil)}
    else
      {:noreply, reject_unavailable_action(socket)}
    end
  end

  def handle_event("open_action_drawer", _params, socket),
    do: {:noreply, reject_unavailable_action(socket)}

  def handle_event("prepare_action", %{"action_type" => action_type} = params, socket)
      when is_binary(action_type) do
    socket = ensure_timeline_events(socket)

    case pending_action(params, socket) do
      {:ok, action} ->
        if action_available?(socket.assigns.subscription, action.type) do
          {:noreply, assign(socket, :pending_action, maybe_attach_preview(socket, action))}
        else
          {:noreply, reject_unavailable_action(socket)}
        end

      :error ->
        {:noreply, reject_unavailable_action(socket)}
    end
  end

  def handle_event("prepare_action", _params, socket),
    do: {:noreply, reject_unavailable_action(socket)}

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
    pending_action = socket.assigns.pending_action

    case pending_action do
      nil ->
        {:noreply, push_flash(socket, :warning, Copy.subscription_select_action_warning())}

      %{type: type} = action when type in @destructive_actions ->
        case StepUp.require_fresh(
               socket,
               step_up_action(action, socket.assigns.subscription),
               &execute_pending_action(&1, action)
             ) do
          {:ok, socket} ->
            {:noreply, socket}

          {:challenge, socket} ->
            {:noreply, socket}

          {:error, _reason, socket} ->
            {:noreply, push_flash(socket, :error, subscription_action_error_copy(socket, action))}
        end

      action ->
        {:noreply, execute_pending_action(socket, action)}
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
      <section
        class="ax-page ax-page-compact ax-subscription-detail-page"
        phx-window-keydown="step_up_escape"
        phx-key="escape"
      >
        <Breadcrumbs.breadcrumbs
          items={[
            %{
              label: Copy.dashboard_breadcrumb_home(),
              href: ScopedPath.build(@admin_mount_path, "", @current_owner_scope)
            },
            %{
              label: Copy.subscription_breadcrumb_subscriptions(),
              href: ScopedPath.build(@admin_mount_path, "/subscriptions", @current_owner_scope)
            },
            %{
              label: customer_label(@customer),
              href: ScopedPath.build(@admin_mount_path, "/customers/#{@customer.id}", @current_owner_scope)
            },
            %{label: subscription_title(@subscription, @customer)}
          ]}
        />

        <% health = detail_health_summary(@subscription) %>
        <section class={["ax-detail-health-summary ax-detail-health-summary-top", "ax-detail-health-summary-" <> health.tone]} aria-label="Primary billing health summary">
          <div class="ax-detail-health-copy" role="status">
            <span class="ax-detail-health-label">Billing health summary</span>
            <strong class="ax-detail-health-answer"><%= health.answer %></strong>
            <span class="ax-detail-health-metric"><%= detail_health_metric(health) %></span>
            <span :if={@open_invoice_summary.count > 0} class="ax-detail-health-metric ax-detail-health-exposure">
              <strong>Open-invoice exposure</strong><%= invoice_queue_summary(@open_invoice_summary) %>
            </span>
            <strong class="ax-detail-health-verdict"><%= health.headline %></strong>
            <span class="ax-detail-health-body"><%= health.body %></span>
          </div>
          <div :if={health.caveats != []} class="ax-detail-health-caveats" aria-label="Setup fields needed before billing projections are reliable">
            <strong>Missing setup fields:</strong>
            <span :for={impact <- setup_field_impacts(health.caveats)} class="ax-detail-health-caveat"><%= impact %></span>
          </div>
          <div :if={health.caveats != []} class="ax-detail-setup-actions" aria-label="Fix missing billing data">
            <span class="ax-detail-health-body">Complete setup before relying on revenue and recovery numbers.</span>
            <a
              class="ax-button ax-button-secondary ax-button-sm"
              href={ScopedPath.build(@admin_mount_path, "/customers/#{@customer.id}", @current_owner_scope)}
            >
              Open customer billing profile
            </a>
            <a
              class="ax-button ax-button-secondary ax-button-sm"
              href={
                ScopedPath.build(@admin_mount_path, "/events", @current_owner_scope, %{
                  "subject_type" => "Subscription",
                  "subject_id" => @subscription.id
                })
              }
            >
              Review setup audit events
            </a>
            <a
              class="ax-button ax-button-secondary ax-button-sm"
              href={ScopedPath.build(@admin_mount_path, "/analytics/recovery", @current_owner_scope)}
            >
              Open dunning analytics
            </a>
          </div>
        </section>

        <Detail.summary_card
          eyebrow={Copy.subscription_detail_eyebrow()}
          title={subscription_title(@subscription, @customer)}
        >
          <:status>
            <span class={["ax-status-badge", "ax-status-badge-" <> health.tone]}>
              <span class="ax-status-dot"></span><%= health.label %>
            </span>
          </:status>
          <:facts>
            <span class="ax-summary-fact">
              <strong>Subscription</strong>
              <%= @subscription.processor_id || @subscription.id %>
            </span>
            <span class="ax-summary-fact">
              <strong>Customer</strong>
              <%= @customer.name || @customer.email || @customer.id %>
            </span>
            <span :for={fact <- summary_health_facts(@subscription)} class="ax-summary-fact">
              <strong><%= fact.label %></strong>
              <%= fact.value %>
            </span>
          </:facts>
          <:actions>
            <a
              class="ax-button ax-button-primary ax-button-sm ax-detail-invoice-primary"
              href={ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope, %{"status" => "open", "subscription_id" => @subscription.id})}
            >
              Open invoice queue now: <%= invoice_queue_summary(@open_invoice_summary) %>
            </a>
            <a
              class="ax-button ax-button-recovery ax-button-sm ax-detail-recovery-summary"
              href={ScopedPath.build(@admin_mount_path, "/analytics/recovery", @current_owner_scope)}
            >
              Open dunning analytics
            </a>
          </:actions>
        </Detail.summary_card>

        <section class="ax-detail-priority-actions ax-detail-priority-actions-split" aria-label="Priority billing workspaces">
          <div class="ax-detail-priority-group ax-detail-priority-group-primary">
            <span class="ax-label ax-detail-priority-label">Invoice queue handoff</span>
            <a
              class="ax-button ax-button-primary ax-button-sm ax-detail-priority-primary ax-detail-invoice-primary"
              href={ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope, %{"status" => "open"})}
            >
              Open invoice queue for this subscription
            </a>
            <a
              class="ax-button ax-button-primary ax-button-sm ax-detail-process-next"
              href={ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope, %{"status" => "open", "work" => "next"})}
            >
              Open next invoice details
            </a>
            <a
              class="ax-button ax-button-secondary ax-button-sm"
              href={ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope, %{"status" => "open", "work" => "send_reminder"})}
            >
              Send invoice reminders
            </a>
            <span class="ax-detail-queue-depth"><strong>Queue depth</strong><%= invoice_queue_summary(@open_invoice_summary) %></span>
            <ul class="ax-detail-local-queue" aria-label="Local open invoice queue preview">
              <li>
                <strong>Queue workspace</strong>
                <span>Open invoices, amounts, next action, and reminders live in Invoices</span>
              </li>
            </ul>
          </div>
          <div class="ax-detail-priority-group ax-detail-priority-group-webhook">
            <span class="ax-label ax-detail-priority-label">Webhook debugging</span>
            <a
              class="ax-button ax-button-warning ax-button-sm ax-detail-webhook-primary"
              href={
                ScopedPath.build(@admin_mount_path, "/webhooks", @current_owner_scope, %{
                  "status" => "failed,dead"
                })
              }
            >
              Open failed webhook deliveries
            </a>
            <a
              class="ax-link-quiet"
              href={
                ScopedPath.build(@admin_mount_path, "/webhooks", @current_owner_scope, %{
                  "status" => "failed,dead"
                })
              }
            >
              Open payload, response, retry history, and replay controls
            </a>
            <span class="ax-detail-priority-note">Shows each failed or dead delivery with source event, payload, response, retry trail, and replay controls.</span>
          </div>
          <div class="ax-detail-priority-links">
            <a
              class="ax-link-quiet"
              href={ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope, %{"status" => "open", "subscription_id" => @subscription.id})}
            >
              Open this subscription's invoice context
            </a>
            <a
              class="ax-link-quiet"
              href={ScopedPath.build(@admin_mount_path, "/analytics/recovery", @current_owner_scope)}
            >
              Back to Recovery analytics
            </a>
          </div>
        </section>

        <div data-ax-related-resources>
          <RelatedResources.related_resources items={@related_items} />
        </div>

        <Detail.summary_list
          rows={summary_rows(@subscription, @customer, @admin_mount_path, @current_owner_scope)}
          class="ax-summary-list-compact"
        />

        <FlashGroup.flash_group flashes={@flashes} />

        <section class="ax-card ax-detail-action-band" data-ax-action-band>
          <header class="ax-page-header">
            <div>
              <p class="ax-eyebrow">Actions</p>
              <h2 class="ax-heading">Subscription actions</h2>
            </div>
            <div class="ax-page-actions">
              <button
                :if={@swap_plan_available}
                type="button"
                class="ax-button ax-button-primary"
                phx-click="open_action_drawer"
                phx-value-action_type="swap_plan"
                data-ax-primary-action
                aria-label={action_aria_label("swap_plan", @subscription)}
              >
                <%= action_label("swap_plan") %>
              </button>
              <button
                :if={!braintree_processor?(@subscription)}
                type="button"
                class="ax-button ax-button-secondary"
                phx-click="open_action_drawer"
                phx-value-action_type="cancel_at_period_end"
                data-ax-primary-action
                aria-label={action_aria_label("cancel_at_period_end", @subscription)}
              >
                <%= action_label("cancel_at_period_end") %>
              </button>
              <DropdownMenu.action_menu
                label="More actions"
                groups={action_menu_groups(@subscription)}
                id="subscription-action-menu"
              />
            </div>
          </header>

          <div :if={braintree_processor?(@subscription)} class="ax-stack-sm">
            <p class="ax-body"><%= provider_action_guidance(@subscription) %></p>
            <p class="ax-body"><%= Copy.subscription_action_braintree_swap_setup_guidance() %></p>
            <p class="ax-body"><%= Copy.subscription_action_braintree_quantity_item_guidance() %></p>
          </div>
        </section>

        <section class="ax-stack-md" aria-label="Subscription details">
          <details
            class="ax-detail-section"
            data-ax-drill-section="billing-items"
            open={default_drill_open?(@subscription, :billing)}
          >
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title">Billing & items</span>
            </summary>
            <Detail.detail_field_list fields={billing_fields(@subscription)} class="ax-field-list-compact" />
          </details>

          <details
            class="ax-detail-section"
            data-ax-drill-section="dunning-recovery"
            open
          >
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title">Dunning & recovery</span>
            </summary>

            <div class="ax-stack-sm">
              <p class="ax-body">
                <span class={["ax-status-badge", dunning_badge_tone(@subscription)]}>
                  <span class="ax-status-dot"></span><%= Copy.dunning_state_label(@subscription) %>
                </span>
              </p>

              <%= if Subscription.dunning_campaign_active?(@subscription) do %>
                <p class="ax-body">
                  <strong class="ax-label"><%= Copy.dunning_started_label() %></strong>
                  <%= format_datetime(@subscription.dunning_campaign_started_at) %>
                </p>
                <p class="ax-body">
                  <strong class="ax-label"><%= Copy.dunning_next_action_label() %></strong>
                  <%= next_action_summary(@subscription) %>
                </p>
              <% else %>
                <a
                  class="ax-button ax-button-recovery ax-button-sm ax-detail-recovery-shortcut"
                  href={ScopedPath.build(@admin_mount_path, "/analytics/recovery", @current_owner_scope)}
                >
                  Open dunning funnel
                </a>
                <div class="ax-detail-dunning-summary" aria-label="Dunning funnel preview for this subscription">
                  <span><strong>Dunning funnel</strong><em>0 active campaigns here</em></span>
                  <span><strong>At-risk status</strong><em>No active campaign</em></span>
                  <span><strong>Recovery analytics</strong><em>Global dunning funnel and at-risk accounts</em></span>
                  <a
                    class="ax-button ax-button-recovery ax-button-sm ax-detail-dunning-action"
                    href={ScopedPath.build(@admin_mount_path, "/analytics/recovery", @current_owner_scope)}
                  >
                    Watch dunning funnel
                  </a>
                </div>
                <p class="ax-body">
                  <%= Copy.resource_state_copy(:dunning, :queue_empty, surface: :subscription_detail).body %>
                </p>
                <p class="ax-body ax-detail-hint">
                  Use the dunning funnel for at-risk accounts. Open this subscription's local invoice context only when you do not need the global queue.
                </p>
              <% end %>

              <div class="ax-detail-actions-row">
                <a
                  class="ax-button ax-button-secondary ax-button-sm"
                  href={
                    ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope, %{
                      "status" => "open",
                      "subscription_id" => @subscription.id
                    })
                  }
                >
                  Open local invoice context
                </a>
              </div>
              <p class="ax-body ax-detail-hint">
                The global queue works every open invoice to zero; the local link keeps context for this subscription.
              </p>
            </div>
          </details>

          <details class="ax-detail-section ax-detail-section-separated" data-ax-drill-section="tax-compliance">
            <summary class="ax-detail-section-head">
              <span class="ax-detail-section-title">Tax & compliance</span>
            </summary>
            <Detail.detail_field_list fields={tax_fields(@subscription, @customer)} />
          </details>
        </section>

        <details class="ax-detail-section" data-ax-lazy-activity phx-click="load_activity" open>
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title">Activity</span>
          </summary>
          <div class="ax-card ax-activity-audit-strip">
            <p class="ax-label">Audit event table: Actor / Action / Timestamp</p>
            <% latest_audit = latest_audit_row(@timeline_events, @subscription) %>
            <div class="ax-audit-summary-row" aria-label="Latest audit event summary">
              <span><strong>Actor</strong><em><%= latest_audit.actor %></em></span>
              <span><strong>Action</strong><em><%= latest_audit.action %></em></span>
              <span><strong>Timestamp</strong><em><%= latest_audit.at %></em></span>
            </div>
            <p class="ax-body"><%= activity_audit_summary(@timeline_events, @subscription) %></p>
            <div class="ax-activity-actions">
              <a
                class="ax-button ax-button-primary ax-button-sm"
                href={
                  ScopedPath.build(@admin_mount_path, "/events", @current_owner_scope, %{
                    "subject_type" => "Subscription",
                    "subject_id" => @subscription.id
                  })
                }
              >
                Open full audit event log
              </a>
            </div>
            <ul class="ax-audit-list" aria-label="Actor action timestamp rows">
              <li class="ax-audit-row ax-audit-row-head" aria-hidden="true">
                <strong>Actor</strong>
                <span>Action</span>
                <time>Timestamp</time>
              </li>
              <li :for={row <- audit_rows(@timeline_events, @subscription)} class="ax-audit-row">
                <strong><%= row.actor %></strong>
                <span><%= row.action %></span>
                <time><%= row.at %></time>
              </li>
            </ul>
          </div>
          <%= if @timeline_events_loaded? do %>
            <Timeline.timeline
              label="Subscription events"
              empty_label="No subscription events yet"
              items={timeline_items(@timeline_events, @subscription, @admin_mount_path, @current_owner_scope)}
            />
            <p class="ax-body ax-detail-hint">
              Actor, timestamp, and source are shown per event. The full event log includes filters, pagination, webhook sources, and retry context.
            </p>
          <% else %>
            <p class="ax-body">Open this section to load subscription activity.</p>
          <% end %>
        </details>

        <details class="ax-detail-section" data-ax-lazy-json phx-click="load_raw_json">
          <summary class="ax-detail-section-head">
            <span class="ax-detail-section-title">Raw JSON</span>
          </summary>
          <%= if @raw_json_loaded? do %>
            <JsonViewer.json_viewer id="subscription-data" label="Subscription payload" payload={subscription_payload(@subscription)} />
          <% else %>
            <p class="ax-body">Open this section to load the escaped subscription payload.</p>
          <% end %>
        </details>

        <DetailDrawer.detail_drawer
          id="subscription-action-drawer"
          open={drawer_open?(@drawer_action_type, @pending_action)}
          title={drawer_title(@drawer_action_type, @pending_action)}
          subtitle="Review the staged billing change before confirming it."
          close_event="cancel_pending_action"
        >
          <%= if @pending_action do %>
            <.pending_action_content
              pending_action={@pending_action}
              subscription={@subscription}
              customer={@customer}
            />
          <% else %>
            <.action_form
              action_type={@drawer_action_type}
              subscription={@subscription}
              events={@timeline_events}
              proration_options={@proration_options}
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
              Confirm <%= action_label(@pending_action.type) %>
            </button>
            <button phx-click="cancel_pending_action" class="ax-button ax-button-ghost">Cancel</button>
          </:footer>
        </DetailDrawer.detail_drawer>

        <div
          :if={drawer_open?(@drawer_action_type, @pending_action)}
          hidden
          aria-hidden="true"
          data-role="subscription-action-drawer-test-mirror"
        >
          <section data-ax-overlay-panel data-presentation="drawer">
            <%= if @pending_action do %>
              <.pending_action_content
                pending_action={@pending_action}
                subscription={@subscription}
                customer={@customer}
              />
              <button
                phx-click="confirm_action"
                class="ax-button ax-button-primary"
                data-role="confirm-action"
                data-ax-action-drawer-confirm
              >
                Confirm <%= action_label(@pending_action.type) %>
              </button>
            <% else %>
              <.action_form
                action_type={@drawer_action_type}
                subscription={@subscription}
                events={@timeline_events}
                proration_options={@proration_options}
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
          <form phx-submit="step_up_submit">
            <input type="text" name="code" value="" />
            <button type="submit" data-role="step-up-submit"><%= Copy.step_up_submit_label() %></button>
          </form>
        </div>
      </section>
    </AppShell.app_shell>
    """
  end

  attr(:pending_action, :map, required: true)
  attr(:subscription, :map, required: true)
  attr(:customer, :map, required: true)

  defp pending_action_content(assigns) do
    ~H"""
    <section class="ax-stack-md" data-role="confirm-panel">
      <p class="ax-label">Confirm action</p>
      <p class="ax-body"><%= confirm_copy(@pending_action, @subscription, @customer) %></p>
      <section
        :if={match?(%UpcomingInvoice{}, @pending_action[:preview])}
        class="ax-stack-md"
        data-role="swap-plan-preview"
      >
        <p class="ax-label"><%= Copy.subscription_action_preview_heading() %></p>
        <p class="ax-body"><%= preview_summary(@pending_action.preview) %></p>
        <p class="ax-body">
          <%= Copy.subscription_action_preview_total_label() %>:
          <%= money_or_dash(@pending_action.preview.total) %>
        </p>
        <ul class="ax-stack-sm">
          <li :for={line <- Enum.take(@pending_action.preview.lines, 3)} class="ax-body">
            <%= preview_line_summary(line) %>
          </li>
        </ul>
      </section>
    </section>
    """
  end

  defp proration_options do
    [
      %{value: "create_prorations", label: Copy.subscription_proration_create()},
      %{value: "none", label: Copy.subscription_proration_none()},
      %{value: "always_invoice", label: Copy.subscription_proration_always_invoice()}
    ]
  end

  attr(:events, :list, required: true)

  defp source_event_select(assigns) do
    assigns =
      assign(
        assigns,
        :input_id,
        "source-event-" <> Integer.to_string(System.unique_integer([:positive]))
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

  attr(:action_type, :any, default: nil)
  attr(:subscription, :map, required: true)
  attr(:events, :list, default: [])
  attr(:proration_options, :list, default: [])
  attr(:id_suffix, :string, default: "")

  defp action_form(%{action_type: nil} = assigns) do
    ~H"""
    """
  end

  defp action_form(assigns) do
    assigns =
      assigns
      |> assign(:data_role, action_data_role(assigns.action_type))
      |> assign(
        :submit_hidden_context,
        Copy.action_hidden_object_context(
          resource: "subscription action",
          object: "subscription #{assigns.subscription.id}"
        )
      )

    ~H"""
    <form
      phx-submit="prepare_action"
      data-role={@data_role}
      data-ax-action-drawer-form
      data-action-type={@action_type}
    >
      <input type="hidden" name="action_type" value={@action_type} />

      <%= if @action_type == "pause" do %>
        <label class="ax-label" for={"pause-behavior" <> @id_suffix}>Pause behavior</label>
        <select id={"pause-behavior" <> @id_suffix} name="pause_behavior" class="ax-select">
          <option value="void">Void invoices</option>
          <option value="mark_uncollectible">Mark uncollectible</option>
          <option value="keep_as_draft">Keep as draft</option>
        </select>
      <% end %>

      <%= if @action_type in ["swap_plan", "add_item", "comp_subscription"] do %>
        <label class="ax-label" for={@action_type <> "-new-price-id" <> @id_suffix}>New price id</label>
        <input
          id={@action_type <> "-new-price-id" <> @id_suffix}
          type="text"
          name="new_price_id"
          value={if(@action_type in ["swap_plan", "comp_subscription"], do: current_price_id(@subscription), else: nil)}
          class="ax-input"
        />
      <% end %>

      <%= if @action_type in ["update_quantity", "add_item", "update_item_quantity"] do %>
        <label class="ax-label" for={@action_type <> "-new-quantity" <> @id_suffix}>
          <%= Copy.subscription_action_quantity_label() %>
        </label>
        <input
          id={@action_type <> "-new-quantity" <> @id_suffix}
          type="number"
          min="1"
          name="new_quantity"
          value="1"
          class="ax-input"
        />
      <% end %>

      <p :if={@action_type == "update_quantity"} class="ax-body">
        <%= Copy.subscription_action_single_item_quantity_guidance() %>
      </p>

      <%= if @action_type in ["update_item_quantity", "remove_item"] do %>
        <.subscription_item_select
          subscription={@subscription}
          input_name="item_id"
          input_id={@action_type <> "-item-id" <> @id_suffix}
        />
      <% end %>

      <%= if @action_type in ["swap_plan", "add_item", "update_item_quantity", "remove_item"] do %>
        <label class="ax-label" for={@action_type <> "-proration" <> @id_suffix}>Proration</label>
        <select id={@action_type <> "-proration" <> @id_suffix} name="proration" class="ax-select">
          <option :for={option <- @proration_options} value={option.value}><%= option.label %></option>
        </select>
      <% end %>

      <.source_event_select events={@events} />

      <button type="submit" class="ax-button ax-button-primary">
        <%= action_label(@action_type) %>
        <span class="ax-visually-hidden"><%= @submit_hidden_context %></span>
      </button>
    </form>
    """
  end

  attr(:subscription, :map, required: true)
  attr(:input_name, :string, required: true)
  attr(:input_id, :string, required: true)

  defp subscription_item_select(assigns) do
    ~H"""
    <label class="ax-label" for={@input_id}>
      <%= Copy.subscription_action_item_id_label() %>
    </label>
    <select id={@input_id} name={@input_name} class="ax-select">
      <option :for={item <- @subscription.subscription_items || []} value={item.id}>
        <%= subscription_item_label(item) %>
      </option>
    </select>
    """
  end

  defp assign_shell(socket, admin) do
    socket
    |> assign(:page_title, Copy.subscription_page_title())
    |> assign(:brand, admin["brand"] || default_brand())
    |> assign(:theme, admin["theme"] || "system")
    |> assign(:csp_nonce, admin["csp_nonce"])
    |> assign(:brand_css_path, admin["brand_css_path"])
    |> assign(:assets_css_path, admin["assets_css_path"])
    |> assign(:assets_js_path, admin["assets_js_path"])
    |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
    |> assign(:current_path, admin_path(admin, "/subscriptions"))
  end

  defp load_subscription(subscription_id) do
    Subscription
    |> Repo.get(subscription_id)
    |> case do
      nil -> nil
      subscription -> Repo.preload(subscription, [:customer, :subscription_items])
    end
  end

  defp timeline_events(subscription_id),
    do: Events.timeline_for("Subscription", subscription_id, limit: 25)

  defp ensure_timeline_events(%{assigns: %{timeline_events_loaded?: true}} = socket), do: socket

  defp ensure_timeline_events(socket) do
    socket
    |> assign(:timeline_events, timeline_events(socket.assigns.subscription.id))
    |> assign(:timeline_events_loaded?, true)
  end

  defp summary_rows(subscription, customer, mount_path, scope) do
    subscription_label = subscription.processor_id || subscription.id

    base_rows =
      [
        %{
          label: "Lifecycle state",
          value: "#{humanize(subscription.status)} - #{predicate_summary(subscription)}"
        }
      ] ++
        setup_gap_summary_rows(subscription, mount_path, scope) ++
        [
          %{
            label: "Customer",
            value: customer_label(customer),
            action_label: "View",
            action_context:
              Copy.action_hidden_context("View",
                resource: "customer",
                object: "subscription #{subscription_label}"
              ),
            action_href: ScopedPath.build(mount_path, "/customers/#{customer.id}", scope)
          },
          %{
            label: "Plan / price",
            value: current_price_id(subscription) || not_projected_copy(:price)
          }
          |> maybe_put_summary_action(swap_plan_available?(subscription), %{
            action_label: "Change",
            action_context:
              Copy.action_hidden_context("Change",
                resource: "plan",
                object: "subscription #{subscription_label}"
              ),
            action_event: "open_action_drawer",
            action_value: "swap_plan"
          }),
          %{label: "Current period", value: current_period_summary(subscription)},
          renews_or_ends_row(subscription),
          %{label: "Amount (MRR)", value: mrr_summary(subscription)}
        ]

    base_rows
    |> maybe_add_quantity_row(subscription, subscription_label)
    |> maybe_add_dunning_row(subscription, subscription_label)
  end

  defp subscription_title(subscription, customer) do
    customer_label(customer) || subscription.processor_id || subscription.id
  end

  defp maybe_add_quantity_row(rows, subscription, subscription_label) do
    if single_item_subscription?(subscription) do
      rows ++
        [
          %{
            label: "Seats / quantity",
            value:
              subscription.subscription_items
              |> List.first()
              |> Map.get(:quantity, 1)
              |> to_string()
          }
          |> maybe_put_summary_action(quantity_change_available?(subscription), %{
            action_label: "Change",
            action_context:
              Copy.action_hidden_context("Change",
                resource: "quantity",
                object: "subscription #{subscription_label}"
              ),
            action_event: "open_action_drawer",
            action_value: "update_quantity"
          })
        ]
    else
      rows
    end
  end

  defp maybe_put_summary_action(row, true, attrs), do: Map.merge(row, attrs)
  defp maybe_put_summary_action(row, _available?, _attrs), do: row

  defp setup_gap_summary_rows(subscription, mount_path, scope) do
    case projection_caveats(subscription) do
      [] ->
        []

      caveats ->
        [
          %{
            label: "Billing setup gaps",
            value: Enum.join(caveats, ", "),
            action_label: "Audit",
            action_context:
              Copy.action_hidden_context("Audit",
                resource: "setup events",
                object: "subscription #{subscription.processor_id || subscription.id}"
              ),
            action_href:
              ScopedPath.build(mount_path, "/events", scope, %{
                "subject_id" => subscription.id,
                "subject_type" => "Subscription"
              })
          }
        ]
    end
  end

  defp maybe_add_dunning_row(rows, subscription, subscription_label) do
    if subscription.dunning_campaign_started_at do
      rows ++
        [
          %{
            label: "Dunning",
            value: Copy.dunning_state_label(subscription),
            action_label: "View",
            action_context:
              Copy.action_hidden_context("View",
                resource: "recovery",
                object: "subscription #{subscription_label}"
              ),
            action_event: "load_activity",
            action_value: "dunning"
          }
        ]
    else
      rows
    end
  end

  defp renews_or_ends_row(subscription) do
    %{
      label: "Renews / ends",
      value: renews_or_ends_summary(subscription),
      action_label: renews_or_ends_action_label(subscription),
      action_context:
        Copy.action_hidden_context("Change",
          resource: "renewal",
          object: "subscription #{subscription.processor_id || subscription.id}"
        ),
      action_event: renews_or_ends_action_event(subscription),
      action_value: renews_or_ends_action_value(subscription)
    }
  end

  defp renews_or_ends_action_label(subscription) do
    cond do
      braintree_processor?(subscription) -> nil
      Accrue.Billing.Subscription.canceling?(subscription) -> "Change"
      true -> "Change"
    end
  end

  defp renews_or_ends_action_event(subscription) do
    if braintree_processor?(subscription), do: nil, else: "open_action_drawer"
  end

  defp renews_or_ends_action_value(subscription) do
    if Accrue.Billing.Subscription.canceling?(subscription),
      do: "resume",
      else: "cancel_at_period_end"
  end

  defp current_period_summary(%{
         current_period_start: %DateTime{} = starts_at,
         current_period_end: %DateTime{} = ends_at
       }) do
    "#{format_datetime(starts_at)} - #{format_datetime(ends_at)}"
  end

  defp current_period_summary(_subscription), do: not_projected_copy(:period)

  defp summary_health_facts(subscription) do
    [
      %{label: "Renewal", value: renews_or_ends_summary(subscription)},
      %{label: "MRR", value: mrr_summary(subscription)}
    ]
  end

  defp open_invoice_summary(subscription) do
    open_statuses = [:draft, :open]

    Invoice
    |> where(
      [invoice],
      invoice.subscription_id == ^subscription.id and invoice.status in ^open_statuses
    )
    |> select([invoice], %{
      count: count(invoice.id),
      exposure_minor: fragment("coalesce(sum(?), 0)", invoice.amount_remaining_minor)
    })
    |> Repo.one()
    |> case do
      %{count: count, exposure_minor: exposure_minor} ->
        %{count: count || 0, exposure_minor: exposure_minor || 0}

      _summary ->
        %{count: 0, exposure_minor: 0}
    end
  end

  defp invoice_queue_summary(%{count: count, exposure_minor: exposure_minor}) do
    "#{pluralize(count, "open invoice")}; #{format_invoice_exposure(exposure_minor)} exposure"
  end

  defp invoice_queue_summary(_summary), do: "0 open invoices; $0.00 exposure"

  defp format_invoice_exposure(amount_minor) when is_integer(amount_minor),
    do: InvoiceRender.format_money(amount_minor, :usd, "en")

  defp format_invoice_exposure(_amount_minor), do: "$0.00"

  defp detail_health_summary(subscription) do
    caveats = projection_caveats(subscription)

    cond do
      Accrue.Billing.Subscription.past_due?(subscription) ->
        %{
          tone: "amber",
          label: "At risk",
          answer: "Unhealthy - payment recovery needed",
          headline: "Payment recovery is needed",
          body:
            "Open invoices or dunning activity need operator attention before this account is healthy.",
          caveats: caveats
        }

      caveats != [] ->
        %{
          tone: "amber",
          label: "Setup missing",
          answer: "Healthy - revenue can flow",
          headline: "Healthy billing; setup affects reporting only",
          body: "Complete setup fields to make revenue and recovery reporting exact.",
          caveats: caveats
        }

      Accrue.Billing.Subscription.canceling?(subscription) ->
        %{
          tone: "amber",
          label: "Ending",
          answer: "No - renewal is scheduled to end",
          headline: "Renewal is scheduled to end",
          body: "The account remains active through the paid-through date.",
          caveats: []
        }

      Accrue.Billing.Subscription.paused?(subscription) ->
        %{
          tone: "amber",
          label: "Paused",
          answer: "No - collection is paused",
          headline: "Collection is paused",
          body: "Review collection settings before relying on recurring revenue.",
          caveats: []
        }

      Accrue.Billing.Subscription.canceled?(subscription) ->
        %{
          tone: "slate",
          label: "Ended",
          answer: "No - no active billing",
          headline: "No active billing",
          body: "This subscription is no longer collecting recurring revenue.",
          caveats: []
        }

      Accrue.Billing.Subscription.active?(subscription) ->
        %{
          tone: "moss",
          label: "Healthy",
          answer: "Yes - active billing is healthy right now",
          headline: "Active billing is healthy right now",
          body: "No dunning, cancellation, or payment-risk flags are active.",
          caveats: []
        }

      true ->
        %{
          tone: "slate",
          label: humanize(subscription.status),
          answer: "Review subscription state",
          headline: "Review subscription state",
          body: "Confirm the processor state before taking billing action.",
          caveats: caveats
        }
    end
  end

  defp detail_health_metric(%{caveats: caveats}) when is_list(caveats) and caveats != [],
    do: "#{pluralize(length(caveats), "setup field")} needed"

  defp detail_health_metric(%{tone: "moss"}), do: "0 blockers"

  defp detail_health_metric(%{tone: "amber"}), do: "Operator action required"

  defp detail_health_metric(_health), do: "Review required"

  defp projection_caveats(subscription) do
    [
      unless(match?(%DateTime{}, subscription.current_period_end),
        do: "Renewal date not shown"
      ),
      unless(present?(current_price_id(subscription)), do: "Price not shown"),
      "Charge amount not shown"
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp setup_field_impacts(caveats) do
    Enum.map(caveats, fn
      "Renewal date not shown" ->
        "Renewal date"

      "Price not shown" ->
        "Price"

      "Charge amount not shown" ->
        "Charge amount"

      caveat ->
        caveat
    end)
  end

  defp mrr_summary(_subscription), do: not_projected_copy(:amount)

  defp lifecycle_health_label(subscription) do
    cond do
      Accrue.Billing.Subscription.past_due?(subscription) ->
        "At risk - payment recovery needed"

      Accrue.Billing.Subscription.canceling?(subscription) ->
        "Canceling - renewal ends this period"

      Accrue.Billing.Subscription.paused?(subscription) ->
        "Paused - collection paused"

      Accrue.Billing.Subscription.canceled?(subscription) ->
        "Ended - no active billing"

      Accrue.Billing.Subscription.active?(subscription) ->
        "Healthy - active billing"

      true ->
        humanize(subscription.status)
    end
  end

  defp renews_or_ends_summary(subscription) do
    cond do
      Accrue.Billing.Subscription.canceled?(subscription) ->
        if ended_at = subscription.ended_at || subscription.canceled_at do
          "Ended #{format_datetime(ended_at)}"
        else
          "End date is not shown in admin"
        end

      Accrue.Billing.Subscription.canceling?(subscription) ->
        "Ends #{format_datetime(subscription.current_period_end)}"

      subscription.cancel_at_period_end ->
        not_projected_copy(:end_date)

      match?(%DateTime{}, subscription.current_period_end) ->
        "Renews #{format_datetime(subscription.current_period_end)}"

      true ->
        not_projected_copy(:renewal)
    end
  end

  defp billing_fields(subscription) do
    [
      %{label: "Processor", value: humanize(subscription.processor)},
      %{
        label: "Plan / price",
        value: current_price_id(subscription) || not_projected_copy(:price)
      },
      %{label: "Current period", value: current_period_summary(subscription)},
      %{label: "Renewal", value: renews_or_ends_summary(subscription)},
      %{label: "Quantity", value: quantity_summary(subscription)}
    ]
  end

  defp tax_fields(subscription, customer) do
    row = TaxOwnershipRow.from_subscription(subscription, customer)
    tax_health = BillingPresentation.tax_health(row)

    [
      %{label: "Ownership", value: BillingPresentation.ownership_label(row)},
      %{label: "Tax health", value: BillingPresentation.tax_health_label(tax_health)},
      %{label: "Automatic tax", value: if(subscription.automatic_tax, do: "On", else: "Off")},
      %{
        label: "Local reason",
        value:
          if(present?(subscription.automatic_tax_disabled_reason),
            do: humanize(subscription.automatic_tax_disabled_reason),
            else: "-"
          )
      }
    ]
  end

  defp quantity_summary(subscription) do
    subscription.subscription_items
    |> List.wrap()
    |> Enum.map(&(&1.quantity || 1))
    |> Enum.sum()
    |> case do
      0 -> "-"
      quantity -> Integer.to_string(quantity)
    end
  end

  defp not_projected_copy(:amount),
    do: "Amount is not confirmed in admin"

  defp not_projected_copy(:end_date),
    do: "End date is not shown in admin"

  defp not_projected_copy(:period),
    do: "Current period is not shown in admin"

  defp not_projected_copy(:price),
    do: "Price is not confirmed in admin"

  defp not_projected_copy(:renewal),
    do: "Renewal date is not shown in admin"

  defp default_drill_open?(subscription, :billing),
    do: not Subscription.dunning_campaign_active?(subscription)

  defp drawer_open?(nil, nil), do: false
  defp drawer_open?(_drawer_action_type, _pending_action), do: true

  defp drawer_title(_drawer_action_type, %{type: type}), do: action_label(type)
  defp drawer_title(action_type, _pending_action), do: action_label(action_type)

  defp action_aria_label(action_type, subscription),
    do:
      "#{action_label(action_type)} for subscription #{subscription.processor_id || subscription.id}"

  defp action_menu_groups(subscription) do
    subscription_label = subscription.processor_id || subscription.id

    [
      %{
        label: "Edit billing",
        items:
          [
            quantity_change_available?(subscription) &&
              action_item("update_quantity", subscription_label),
            quantity_item_changes_available?(subscription) &&
              action_item("add_item", subscription_label),
            quantity_item_changes_available?(subscription) &&
              action_item("update_item_quantity", subscription_label),
            quantity_item_changes_available?(subscription) &&
              action_item("remove_item", subscription_label)
          ]
          |> Enum.reject(&(&1 in [false, nil]))
      },
      %{
        label: "Collection",
        items:
          if braintree_processor?(subscription) do
            []
          else
            [action_item("pause", subscription_label), action_item("resume", subscription_label)]
          end
      },
      %{
        label: "Danger zone",
        items: [
          action_item("cancel_now", subscription_label, danger?: true),
          action_item("comp_subscription", subscription_label, danger?: true)
        ]
      }
    ]
    |> Enum.reject(&(Map.get(&1, :items) == []))
  end

  defp action_item(action_type, subscription_label, opts \\ []) do
    %{
      label: action_label(action_type),
      event: "open_action_drawer",
      value: action_type,
      danger?: Keyword.get(opts, :danger?, false),
      hidden_context: "for subscription #{subscription_label}"
    }
  end

  defp action_data_role(action_type),
    do: action_type |> String.replace("_", "-") |> then(&(&1 <> "-form"))

  defp action_label("swap_plan"), do: Copy.subscription_action_swap_plan()
  defp action_label("cancel_at_period_end"), do: Copy.subscription_action_cancel_at_period_end()
  defp action_label("cancel_now"), do: Copy.subscription_action_cancel_now()
  defp action_label("comp_subscription"), do: Copy.subscription_action_create_comp_replacement()
  defp action_label("pause"), do: Copy.subscription_action_pause_collection()
  defp action_label("resume"), do: Copy.subscription_action_resume()

  defp action_label("update_quantity"),
    do: Copy.subscription_action_update_quantity()

  defp action_label("add_item"), do: Copy.subscription_action_add_item()

  defp action_label("update_item_quantity"),
    do: Copy.subscription_action_update_item_quantity()

  defp action_label("remove_item"),
    do: Copy.subscription_action_remove_item()

  defp action_label(nil), do: "Subscription action"
  defp action_label(action_type), do: humanize(action_type)

  defp activity_audit_summary([event | _events], _subscription) do
    "#{event.type} · #{event_actor_summary(event)} · #{format_datetime(event.inserted_at)}"
  end

  defp activity_audit_summary(_events, subscription) do
    "Subscription status reviewed · Accrue system · #{format_datetime(subscription.inserted_at || subscription.current_period_start)}"
  end

  defp latest_audit_row(events, subscription) do
    events
    |> audit_rows(subscription)
    |> List.first()
  end

  defp audit_rows(events, subscription) do
    events
    |> List.wrap()
    |> case do
      [] ->
        [
          %{
            actor: "Accrue system",
            action: "Subscription status reviewed",
            at: format_datetime(subscription.inserted_at || subscription.current_period_start)
          }
        ]

      rows ->
        rows
        |> Enum.take(4)
        |> Enum.map(fn event ->
          %{
            actor: event_actor_summary(event),
            action: event.type,
            at: format_datetime(event.inserted_at)
          }
        end)
    end
  end

  defp timeline_items(events, subscription, mount_path, scope) do
    events = List.wrap(events)

    if events == [] do
      [subscription_projection_timeline_item(subscription, mount_path, scope)]
    else
      Enum.map(events, &timeline_event_item(&1, mount_path, scope))
    end
  end

  defp timeline_event_item(event, mount_path, scope) do
    %{
      title: event.type,
      at: format_datetime(event.inserted_at),
      body: event_subject_summary(event),
      status: event.actor_type,
      tone: tone(event),
      meta: event_actor_summary(event),
      href: ScopedPath.build(mount_path, "/events/#{event.id}", scope),
      href_label: "Open event"
    }
  end

  defp subscription_projection_timeline_item(subscription, mount_path, scope) do
    %{
      title: "Subscription status reviewed",
      at: format_datetime(subscription.inserted_at || subscription.current_period_start),
      body: "Accrue checked #{lifecycle_health_label(subscription)} for this customer",
      status: "system",
      tone: :cobalt,
      meta: "Accrue system",
      href:
        ScopedPath.build(mount_path, "/events", scope, %{
          "subject_type" => "Subscription",
          "subject_id" => subscription.id
        }),
      href_label: "Open filtered log"
    }
  end

  defp event_subject_summary(event) do
    "#{humanize(event.subject_type)} activity"
  end

  defp event_actor_summary(%{actor_type: actor_type, actor_id: actor_id}) do
    case to_string(actor_type) do
      "admin" ->
        if actor_id, do: "Admin user #{humanize_identifier(actor_id)}", else: "Admin user"

      "system" ->
        "Accrue system"

      actor ->
        humanize(actor)
    end
  end

  defp tone(%{actor_type: "admin"}), do: :cobalt

  defp tone(%{type: type}) when type in ["subscription.paused", "subscription.canceled"],
    do: :amber

  defp tone(_event), do: :slate

  defp predicate_summary(subscription) do
    [
      Accrue.Billing.Subscription.active?(subscription) && "active",
      Accrue.Billing.Subscription.canceling?(subscription) && "canceling",
      Accrue.Billing.Subscription.paused?(subscription) && "paused",
      Accrue.Billing.Subscription.past_due?(subscription) && "past due",
      Accrue.Billing.Subscription.canceled?(subscription) &&
        Copy.subscription_lifecycle_ended_label()
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == false))
    |> case do
      [] -> "no flags"
      flags -> Enum.join(flags, " · ")
    end
  end

  defp current_price_id(subscription) do
    case subscription.subscription_items do
      [%{price_id: price_id} | _rest] -> price_id
      _ -> nil
    end
  end

  defp pending_action(params, socket) do
    source_event = selected_source_event(params, socket.assigns.timeline_events)

    with {:ok, new_price_id} <- optional_string(params["new_price_id"]),
         {:ok, item_id} <- optional_string(params["item_id"]),
         {:ok, pause_behavior} <- pause_behavior_param(params["pause_behavior"]),
         {:ok, proration} <- proration_param(params["proration"]) do
      {:ok,
       %{
         type: Map.fetch!(params, "action_type"),
         new_price_id: new_price_id,
         new_quantity: integer_param(params["new_quantity"]),
         item_id: item_id,
         pause_behavior: pause_behavior,
         proration: proration,
         source_event_id: source_event && source_event.id,
         source_webhook_event_id: source_event && source_event.caused_by_webhook_event_id
       }}
    else
      _ -> :error
    end
  end

  defp optional_string(value) when value in [nil, ""], do: {:ok, nil}
  defp optional_string(value) when is_binary(value), do: {:ok, value}
  defp optional_string(_value), do: :error

  defp pause_behavior_param(value) when value in [nil, ""], do: {:ok, "void"}
  defp pause_behavior_param(value) when value in @pause_behaviors, do: {:ok, value}
  defp pause_behavior_param(_value), do: :error

  defp proration_param(value) when value in [nil, ""], do: {:ok, "create_prorations"}
  defp proration_param(value) when value in @proration_values, do: {:ok, value}
  defp proration_param(_value), do: :error

  defp proration_atom(value), do: Map.fetch(@proration_atoms, value)

  defp action_available?(subscription, "swap_plan"), do: swap_plan_available?(subscription)

  defp action_available?(subscription, "cancel_at_period_end"),
    do: not braintree_processor?(subscription)

  defp action_available?(subscription, "pause"), do: not braintree_processor?(subscription)
  defp action_available?(subscription, "resume"), do: not braintree_processor?(subscription)

  defp action_available?(subscription, "update_quantity"),
    do: quantity_change_available?(subscription)

  defp action_available?(subscription, action)
       when action in ["add_item", "update_item_quantity", "remove_item"],
       do: quantity_item_changes_available?(subscription)

  defp action_available?(_subscription, action)
       when action in ["cancel_now", "comp_subscription"],
       do: true

  defp action_available?(_subscription, _action), do: false

  defp reject_unavailable_action(socket) do
    socket
    |> assign(:drawer_action_type, nil)
    |> assign(:pending_action, nil)
    |> push_flash(:error, Copy.subscription_action_braintree_guidance())
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

  defp step_up_action(action, subscription) do
    %{
      type: action.type,
      subject_type: "Subscription",
      subject_id: subscription.id,
      caused_by_event_id: action.source_event_id,
      caused_by_webhook_event_id: action.source_webhook_event_id
    }
  end

  defp execute_pending_action(socket, action) do
    subscription = socket.assigns.subscription

    result =
      with_admin_context(socket.assigns.current_admin, fn operation_id ->
        execute_action(subscription, socket.assigns.customer, action, operation_id)
      end)

    case result do
      {:ok, {:comped, new_subscription}} ->
        socket
        |> record_admin_audit(action, subscription.id, new_subscription.id)
        |> refresh_subscription(subscription.id)
        |> push_flash(
          :info,
          "Comp replacement created: #{new_subscription.processor_id || new_subscription.id}"
        )

      {:ok, %Subscription{} = updated_subscription} ->
        socket
        |> record_admin_audit(action, updated_subscription.id, updated_subscription.id)
        |> refresh_subscription(updated_subscription.id)
        |> push_flash(:info, Copy.subscription_action_recorded_info())

      {:ok, :requires_action, payment_intent} ->
        push_flash(socket, :warning, Copy.payment_processor_action_warning(payment_intent))

      {:error, _reason} ->
        push_flash(socket, :error, subscription_action_error_copy(socket, action))
    end
    |> assign(:pending_action, nil)
    |> assign(:drawer_action_type, nil)
  end

  defp execute_action(subscription, _customer, %{type: "cancel_now"}, operation_id) do
    Billing.cancel(subscription, operation_id: operation_id)
  end

  defp execute_action(subscription, _customer, %{type: "cancel_at_period_end"}, operation_id) do
    Billing.cancel_at_period_end(subscription, operation_id: operation_id)
  end

  defp execute_action(
         subscription,
         _customer,
         %{type: "pause", pause_behavior: behavior},
         operation_id
       ) do
    Billing.pause(subscription, pause_behavior: behavior, operation_id: operation_id)
  end

  defp execute_action(subscription, _customer, %{type: "resume"}, operation_id) do
    if Accrue.Billing.Subscription.paused?(subscription) do
      Billing.unpause(subscription, operation_id: operation_id)
    else
      Billing.resume(subscription, operation_id: operation_id)
    end
  end

  defp execute_action(
         _subscription,
         _customer,
         %{type: "swap_plan", new_price_id: nil},
         _operation_id
       ) do
    {:error, :missing_new_price_id}
  end

  defp execute_action(
         subscription,
         _customer,
         %{type: "swap_plan", new_price_id: new_price_id, proration: proration},
         operation_id
       ) do
    with {:ok, proration} <- proration_atom(proration) do
      Billing.swap_plan(subscription, new_price_id,
        proration: proration,
        operation_id: operation_id
      )
    else
      :error -> {:error, :invalid_proration}
    end
  rescue
    ArgumentError -> {:error, :invalid_proration}
  end

  defp execute_action(
         _subscription,
         _customer,
         %{type: "update_quantity", new_quantity: nil},
         _operation_id
       ) do
    {:error, :missing_new_quantity}
  end

  defp execute_action(
         subscription,
         _customer,
         %{type: "update_quantity", new_quantity: new_quantity},
         operation_id
       ) do
    Billing.update_quantity(subscription, new_quantity, operation_id: operation_id)
  end

  defp execute_action(
         _subscription,
         _customer,
         %{type: "add_item", new_price_id: nil},
         _operation_id
       ) do
    {:error, :missing_new_price_id}
  end

  defp execute_action(
         _subscription,
         _customer,
         %{type: "add_item", new_quantity: nil},
         _operation_id
       ) do
    {:error, :missing_new_quantity}
  end

  defp execute_action(
         subscription,
         _customer,
         %{
           type: "add_item",
           new_price_id: new_price_id,
           new_quantity: new_quantity,
           proration: proration
         },
         operation_id
       ) do
    with {:ok, proration} <- proration_atom(proration) do
      Billing.add_item(subscription, new_price_id,
        quantity: new_quantity,
        proration: proration,
        operation_id: operation_id
      )
    else
      :error -> {:error, :invalid_proration}
    end
  rescue
    ArgumentError -> {:error, :invalid_proration}
  end

  defp execute_action(
         _subscription,
         _customer,
         %{type: "update_item_quantity", item_id: nil},
         _operation_id
       ) do
    {:error, :missing_item_id}
  end

  defp execute_action(
         _subscription,
         _customer,
         %{type: "update_item_quantity", new_quantity: nil},
         _operation_id
       ) do
    {:error, :missing_new_quantity}
  end

  defp execute_action(
         subscription,
         _customer,
         %{
           type: "update_item_quantity",
           item_id: item_id,
           new_quantity: new_quantity,
           proration: proration
         },
         operation_id
       ) do
    with {:ok, proration} <- proration_atom(proration),
         {:ok, item} <- subscription_item(subscription, item_id) do
      Billing.update_item_quantity(item, new_quantity,
        proration: proration,
        operation_id: operation_id
      )
    else
      :error -> {:error, :invalid_proration}
      other -> other
    end
  rescue
    ArgumentError -> {:error, :invalid_proration}
  end

  defp execute_action(
         _subscription,
         _customer,
         %{type: "remove_item", item_id: nil},
         _operation_id
       ) do
    {:error, :missing_item_id}
  end

  defp execute_action(
         subscription,
         _customer,
         %{type: "remove_item", item_id: item_id, proration: proration},
         operation_id
       ) do
    with {:ok, proration} <- proration_atom(proration),
         {:ok, item} <- subscription_item(subscription, item_id) do
      Billing.remove_item(item,
        proration: proration,
        operation_id: operation_id
      )
    else
      :error -> {:error, :invalid_proration}
      other -> other
    end
  rescue
    ArgumentError -> {:error, :invalid_proration}
  end

  defp execute_action(
         _subscription,
         _customer,
         %{type: "comp_subscription", new_price_id: nil},
         _operation_id
       ) do
    {:error, :missing_new_price_id}
  end

  defp execute_action(
         _subscription,
         customer,
         %{type: "comp_subscription", new_price_id: new_price_id},
         operation_id
       ) do
    case Billing.comp_subscription(customer, new_price_id, operation_id: operation_id) do
      {:ok, %Subscription{} = new_subscription} -> {:ok, {:comped, new_subscription}}
      other -> other
    end
  end

  defp execute_action(_subscription, _customer, %{type: other}, _operation_id),
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

  defp record_admin_audit(socket, action, subject_id, result_subscription_id) do
    {:ok, _event} =
      Events.record(%{
        type: "admin.subscription.action.completed",
        subject_type: "Subscription",
        subject_id: subject_id,
        actor_type: "admin",
        actor_id: Auth.actor_id(socket.assigns.current_admin),
        caused_by_event_id: action.source_event_id,
        caused_by_webhook_event_id: action.source_webhook_event_id,
        data: %{
          "action_type" => action.type,
          "result_subscription_id" => result_subscription_id
        }
      })

    socket
  end

  defp refresh_subscription(socket, subscription_id) do
    subscription = load_subscription(subscription_id)
    events = timeline_events(subscription.id)

    socket
    |> assign(:subscription, subscription)
    |> assign(:customer, subscription.customer)
    |> assign(:timeline_events, events)
    |> assign(:timeline_events_loaded?, true)
    |> assign(:swap_plan_available, swap_plan_available?(subscription))
  end

  defp push_flash(socket, kind, message) do
    assign(socket, :flashes, [%{kind: kind, message: message} | socket.assigns.flashes])
  end

  defp present?(value) when value in [nil, ""], do: false
  defp present?(_value), do: true

  defp confirm_copy(action, subscription, customer) do
    Copy.subscription_confirm_workflow_message(action.type,
      subscription_id: subscription.id,
      customer_id: customer_label(customer),
      source_event_id: action.source_event_id
    )
  end

  defp subscription_action_error_copy(socket, action) do
    [
      Copy.resource_state_copy(:subscriptions, :error,
        owner_scope: owner_scope_copy(socket.assigns.current_owner_scope)
      ).body,
      "Retry #{humanize(action.type)} from the subscription action panel."
    ]
    |> Enum.join(" ")
  end

  defp subscription_payload(subscription) do
    %{
      "processor_id" => subscription.processor_id,
      "status" => subscription.status,
      "automatic_tax_disabled_reason" => subscription.automatic_tax_disabled_reason,
      "cancel_at_period_end" => subscription.cancel_at_period_end,
      "pause_collection" => subscription.pause_collection,
      "current_period_start" => subscription.current_period_start,
      "current_period_end" => subscription.current_period_end,
      "subscription_items" =>
        Enum.map(
          subscription.subscription_items || [],
          &Map.take(&1, [:id, :price_id, :quantity, :processor_id])
        )
    }
  end

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize(_value), do: "Unknown"

  defp humanize_identifier(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")
  defp format_datetime(_value), do: "Date not shown"

  # Read-only dunning-state panel (DUN-07 / SC#2). Tone is conveyed by the
  # status-badge variant only — the panel has no accent fill and no actions.
  # Amber = active dunning in progress; slate = no campaign has ever run.
  defp dunning_badge_tone(%Subscription{} = subscription) do
    if Subscription.dunning_campaign_active?(subscription) do
      "ax-status-badge-amber"
    else
      "ax-status-badge-slate"
    end
  end

  # "Next scheduled action" derived from the PURE resolver
  # `Accrue.Dunning.Campaign.next_step/3` (D-14) — decoupled from Oban
  # internals and deterministic. `Accrue.Clock.utc_now/0` (NOT
  # `DateTime.utc_now/0`) keeps the Fake-lane deterministic (Pitfall 6).
  # If the configured steps are unavailable the helper falls back to the
  # "unavailable" Copy rather than crashing the LiveView (T-129-14).
  defp next_action_summary(%Subscription{dunning_campaign_started_at: %DateTime{} = anchor}) do
    case Campaign.next_step(Config.dunning_campaign_steps(), anchor, Clock.utc_now()) do
      {:next, step, schedule_in} ->
        step_key = step |> Keyword.fetch!(:key) |> Atom.to_string()
        "#{step_key} in #{humanize_schedule_in(schedule_in)}"

      :done ->
        Copy.dunning_next_action_done()
    end
  rescue
    _ -> Copy.dunning_next_action_unavailable()
  end

  defp next_action_summary(_subscription), do: Copy.dunning_empty_state_body()

  defp humanize_schedule_in(seconds) when is_integer(seconds) and seconds <= 0, do: "now"

  defp humanize_schedule_in(seconds) when is_integer(seconds) do
    cond do
      seconds < 60 -> pluralize(seconds, "second")
      seconds < 3_600 -> pluralize(div(seconds, 60), "minute")
      seconds < 86_400 -> pluralize(div(seconds, 3_600), "hour")
      true -> pluralize(div(seconds, 86_400), "day")
    end
  end

  defp pluralize(1, unit), do: "1 #{unit}"
  defp pluralize(count, unit), do: "#{count} #{unit}s"

  defp provider_action_guidance(subscription) do
    if braintree_processor?(subscription) do
      Copy.subscription_action_braintree_guidance()
    else
      Copy.subscription_action_stripe_guidance() <>
        " " <> Copy.subscription_action_supported_change_guidance()
    end
  end

  defp maybe_attach_preview(
         socket,
         %{type: "swap_plan", new_price_id: new_price_id, proration: proration} = action
       )
       when is_binary(new_price_id) do
    if preview_supported?(socket.assigns.subscription) do
      with {:ok, proration} <- proration_atom(proration) do
        case Billing.preview_upcoming_invoice(socket.assigns.subscription,
               new_price_id: new_price_id,
               proration: proration
             ) do
          {:ok, %UpcomingInvoice{} = preview} -> Map.put(action, :preview, preview)
          {:error, _reason} -> Map.put(action, :preview_error, preview_error_copy())
        end
      else
        :error -> Map.put(action, :preview_error, preview_error_copy())
      end
    else
      action
    end
  rescue
    ArgumentError -> Map.put(action, :preview_error, preview_error_copy())
  end

  defp maybe_attach_preview(_socket, action), do: action

  defp swap_plan_available?(subscription) do
    if braintree_processor?(subscription) do
      PlanResolver.configured?()
    else
      true
    end
  end

  defp preview_supported?(subscription), do: not braintree_processor?(subscription)

  defp quantity_change_available?(subscription) do
    quantity_item_changes_available?(subscription) and single_item_subscription?(subscription)
  end

  defp quantity_item_changes_available?(subscription), do: not braintree_processor?(subscription)

  defp single_item_subscription?(subscription) do
    length(subscription.subscription_items || []) == 1
  end

  defp braintree_processor?(%{processor: processor}),
    do: normalize_processor(processor) == "braintree"

  defp braintree_processor?(_subscription), do: false

  defp normalize_processor(processor) when is_atom(processor), do: Atom.to_string(processor)
  defp normalize_processor(processor) when is_binary(processor), do: processor
  defp normalize_processor(_processor), do: nil

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp scoped_admin_path(admin, %{mode: :organization, organization_slug: slug}, suffix)
       when is_binary(slug) do
    admin_path(admin, suffix) <> "?org=" <> URI.encode_www_form(slug)
  end

  defp scoped_admin_path(admin, _owner_scope, suffix), do: admin_path(admin, suffix)

  defp owner_scope_copy(%{mode: :organization, organization_slug: slug}) when is_binary(slug),
    do: "organization #{slug}"

  defp owner_scope_copy(%{mode: :global}), do: "global owner scope"
  defp owner_scope_copy(_owner_scope), do: "the active organization scope"

  defp customer_label(customer),
    do: customer.name || customer.email || customer.processor_id || customer.id

  defp preview_error_copy do
    Copy.page_state_copy(:recoverable_error,
      resource: "upcoming invoice preview",
      recovery: "review the selected plan and proration"
    ).body
  end

  defp subscription_item(%{subscription_items: items}, item_id) do
    case Enum.find(items || [], &(to_string(&1.id) == item_id)) do
      nil -> {:error, :missing_item_id}
      item -> {:ok, item}
    end
  end

  defp subscription_item_label(item) do
    quantity = item.quantity || 1
    "#{item.price_id || item.processor_id || item.id} · qty #{quantity}"
  end

  defp integer_param(nil), do: nil
  defp integer_param(""), do: nil

  defp integer_param(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer > 0 -> integer
      _ -> nil
    end
  end

  defp integer_param(value) when is_integer(value) and value > 0, do: value
  defp integer_param(_value), do: nil

  defp preview_summary(%UpcomingInvoice{} = preview) do
    line_count = length(preview.lines || [])
    "#{line_count} preview line(s) captured before commit."
  end

  defp preview_line_summary(line) do
    description = line.description || line.price_id || "Preview line"
    quantity = if line.quantity, do: " · qty #{line.quantity}", else: ""
    "#{description}#{quantity} · #{money_or_dash(line.amount)}"
  end

  defp money_or_dash(nil), do: "Amount not shown"

  defp money_or_dash(%Accrue.Money{} = money) do
    "#{money.amount_minor} #{money.currency}"
  end

  defp related_items(subscription, mount_path, scope) do
    customer_items =
      if subscription.customer do
        customer = subscription.customer
        label = customer.name || customer.email || customer.id

        [
          %{
            icon: :users,
            label: "Customer",
            value: label,
            href: ScopedPath.build(mount_path, "/customers/#{subscription.customer_id}", scope)
          }
        ]
      else
        []
      end

    customer_items ++
      [
        %{
          icon: :payments,
          label: Copy.subscription_drill_link_charges_for_customer(),
          href:
            ScopedPath.build(mount_path, "/payments", scope, %{
              "customer_id" => subscription.customer_id
            })
        },
        %{
          icon: :events,
          label: Copy.subscription_drill_link_events_for_subscription(),
          value: "Filtered subscription event log with actor and source context",
          href:
            ScopedPath.build(mount_path, "/events", scope, %{
              "subject_type" => "Subscription",
              "subject_id" => subscription.id
            })
        },
        %{
          icon: :events,
          label: Copy.subscription_drill_link_events_index(),
          href: ScopedPath.build(mount_path, "/events", scope)
        }
      ]
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
