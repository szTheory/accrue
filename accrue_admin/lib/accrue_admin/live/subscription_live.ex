defmodule AccrueAdmin.Live.SubscriptionLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.{Actor, Auth, Billing, Clock, Config, Events, PlanResolver}
  alias Accrue.Billing.{Subscription, UpcomingInvoice}
  alias Accrue.Dunning.Campaign

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    DetailDrawer,
    DropdownMenu,
    FlashGroup,
    IdBadge,
    JsonViewer,
    RelatedResources,
    StatusBadge,
    StepUpAuthModal,
    Timeline,
    Timestamp
  }

  alias AccrueAdmin.BillingPresentation
  alias AccrueAdmin.Copy
  alias AccrueAdmin.OwnerScope
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
         |> redirect(to: missing_subscription_path(admin, socket.assigns.current_owner_scope))}

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
         |> assign(:timeline_events, events)
         |> assign(:timeline_events_loaded?, true)
         |> assign(:raw_json_loaded?, false)
         |> assign(:action_result, nil)
         |> assign(:proration_options, proration_options())
         |> assign(:swap_plan_available, swap_plan_available?(subscription))
         |> assign(:related_items, related_items(subscription, mount_path, scope, nil))
         |> assign(:flashes, [])
         |> assign(:dispatch_state, :idle)
         |> assign(:drawer_action_type, nil)
         |> assign(:pending_action, nil)}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    return_destination =
      ScopedPath.return_destination(
        socket.assigns.admin_mount_path,
        Map.get(params, "return_to"),
        socket.assigns.current_owner_scope,
        socket.assigns.subscription.customer_id,
        "/subscriptions"
      )

    {:noreply,
     socket
     |> assign(:return_path, return_destination.path)
     |> assign(:return_label, return_destination.label)
     |> assign(
       :related_items,
       related_items(
         socket.assigns.subscription,
         socket.assigns.admin_mount_path,
         socket.assigns.current_owner_scope,
         return_destination.path
       )
     )}
  end

  @impl true
  def handle_event("open_action_drawer", %{"action_type" => action_type}, socket)
      when is_binary(action_type) do
    socket = ensure_timeline_events(socket)

    cond do
      outcome_requires_reconciliation?(socket) ->
        {:noreply, require_outcome_review(socket)}

      action_available?(socket.assigns.subscription, action_type) ->
        {:noreply,
         socket
         |> assign(:drawer_action_type, action_type)
         |> assign(:pending_action, nil)}

      true ->
        {:noreply, reject_unavailable_action(socket)}
    end
  end

  def handle_event("open_action_drawer", _params, socket),
    do: {:noreply, reject_unavailable_action(socket)}

  def handle_event("prepare_action", %{"action_type" => action_type} = params, socket)
      when is_binary(action_type) do
    socket = ensure_timeline_events(socket)

    if outcome_requires_reconciliation?(socket) do
      {:noreply, require_outcome_review(socket)}
    else
      prepare_staged_action(params, socket)
    end
  end

  def handle_event("prepare_action", _params, socket),
    do: {:noreply, reject_unavailable_action(socket)}

  def handle_event("cancel_pending_action", _params, socket) do
    {:noreply,
     socket
     |> dismiss_step_up_if_pending()
     |> assign(:pending_action, nil)
     |> assign(:drawer_action_type, nil)
     |> assign(:dispatch_state, :idle)}
  end

  def handle_event("load_activity", _params, socket) do
    {:noreply, ensure_timeline_events(socket)}
  end

  def handle_event("load_raw_json", _params, socket) do
    {:noreply, assign(socket, :raw_json_loaded?, true)}
  end

  def handle_event("confirm_action", _params, socket) do
    if socket.assigns[:dispatch_state] in [:awaiting_step_up, :dispatching, :submitted] do
      {:noreply, socket}
    else
      confirm_staged_action(socket)
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

  defp prepare_staged_action(params, socket) do
    case pending_action(params, socket) do
      {:ok, action} ->
        if action_available?(socket.assigns.subscription, action.type) and
             action_input_valid?(socket.assigns.subscription, action) do
          action = maybe_attach_preview(socket, action)

          action =
            action
            |> Map.put(:subscription_id, socket.assigns.subscription.id)
            |> Map.put(:review_actor_id, Auth.actor_id(socket.assigns.current_admin))
            |> Map.put(:review_scope, scope_identity(socket.assigns.current_owner_scope))
            |> Map.put(
              :review_fingerprint,
              review_fingerprint(action, socket.assigns.subscription)
            )

          {:noreply, stage_action(socket, action)}
        else
          {:noreply, reject_unavailable_action(socket)}
        end

      :error ->
        {:noreply, reject_unavailable_action(socket)}
    end
  end

  defp confirm_staged_action(socket) do
    pending_action = socket.assigns.pending_action

    case pending_action do
      nil ->
        {:noreply, push_flash(socket, :warning, Copy.subscription_select_action_warning())}

      %{type: type} = action when type in @destructive_actions ->
        case validate_review(socket, action) do
          {:ok, fresh_socket, fresh_subscription} ->
            fresh_socket = assign(fresh_socket, :dispatch_state, :awaiting_step_up)

            case StepUp.require_fresh(
                   fresh_socket,
                   step_up_action(action, fresh_subscription),
                   &execute_pending_action(&1, action)
                 ) do
              {:ok, socket} ->
                {:noreply, socket}

              {:challenge, socket} ->
                {:noreply, socket}

              {:error, _reason, socket} ->
                {:noreply,
                 socket
                 |> assign(:dispatch_state, :staged)
                 |> push_flash(:error, subscription_action_error_copy(socket, action))}
            end

          {:error, socket} ->
            {:noreply, reject_stale_review(socket)}
        end

      action ->
        {:noreply, execute_pending_action(socket, action)}
    end
  end

  attr(:subscription, :any, required: true)
  attr(:customer, :any, required: true)
  attr(:admin_mount_path, :string, required: true)
  attr(:current_owner_scope, :any, default: nil)
  attr(:flashes, :list, default: [])
  attr(:action_result, :any, default: nil)
  slot(:between_facts_and_actions)

  def subscription_area(assigns) do
    ~H"""
      <Detail.summary_card title={subscription_title(@subscription, @customer)}>
        <:status>
          <StatusBadge.status_badge
            status={@subscription.status}
            label={lifecycle_health_label(@subscription)}
            tone={lifecycle_tone(@subscription.status)}
          />
        </:status>
        <:facts>
          <IdBadge.id_badge
            id="subscription-summary-id"
            id_value={@subscription.processor_id || @subscription.id}
            label="Copy subscription ID"
            copy_label="subscription ID"
            variant="plain"
          />
        </:facts>
      </Detail.summary_card>

      <Detail.summary_list
        rows={summary_rows(@subscription, @customer, @admin_mount_path, @current_owner_scope)}
        class="ax-summary-list-compact"
      />

      <%= render_slot(@between_facts_and_actions) %>

      <section class="ax-card ax-detail-action-band" data-ax-action-band>
        <header class="ax-page-header">
          <div>
            <h2 class="ax-heading">Subscription actions</h2>
          </div>
          <div class="ax-page-actions">
            <button
              :if={action_available?(@subscription, "swap_plan")}
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
              :if={action_available?(@subscription, "cancel_at_period_end")}
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
    """
  end

  @impl true
  def render(assigns), do: subscription_page(assigns)

  attr(:brand, :map, required: true)
  attr(:current_path, :string, required: true)
  attr(:admin_mount_path, :string, required: true)
  attr(:page_title, :string, required: true)
  attr(:theme, :string, default: "system")
  attr(:active_organization_name, :string, default: nil)
  attr(:subscription, :any, required: true)
  attr(:customer, :any, required: true)
  attr(:current_owner_scope, :any, default: nil)
  attr(:return_path, :string, required: true)
  attr(:return_label, :string, required: true)
  attr(:related_items, :list, default: [])
  attr(:flashes, :list, default: [])
  attr(:action_result, :any, default: nil)
  attr(:timeline_events, :list, default: [])
  attr(:timeline_events_loaded?, :boolean, default: true)
  attr(:raw_json_loaded?, :boolean, default: false)
  attr(:proration_options, :list, default: [])
  attr(:drawer_action_type, :string, default: nil)
  attr(:pending_action, :map, default: nil)
  attr(:dispatch_state, :atom, default: :idle)
  attr(:step_up_pending, :boolean, default: false)
  attr(:step_up_challenge, :map, default: nil)
  attr(:step_up_error, :string, default: nil)
  slot(:between_facts_and_actions)

  def subscription_page(assigns) do
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
          group="Billing"
          items={[
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
        <p class="ax-detail-back-link">
          <a class="ax-link" href={@return_path}><%= @return_label %></a>
        </p>

        <.subscription_area
          subscription={@subscription}
          customer={@customer}
          admin_mount_path={@admin_mount_path}
          current_owner_scope={assigns[:current_owner_scope]}
          flashes={@flashes}
          action_result={@action_result}
        >
          <:between_facts_and_actions>
            <FlashGroup.flash_group flashes={@flashes} />
            <section
              :if={@action_result}
              class="ax-card"
              data-role="subscription-action-result"
              role="status"
              aria-live="polite"
            >
              <p class="ax-body"><%= @action_result.message %></p>
              <a :if={@action_result.href} class="ax-link" href={@action_result.href}>
                <%= @action_result.link_label %>
              </a>
            </section>
          </:between_facts_and_actions>
        </.subscription_area>

        <div data-ax-related-resources>
          <RelatedResources.related_resources items={@related_items} />
        </div>

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
                  <Timestamp.timestamp value={@subscription.dunning_campaign_started_at} id="subscription-dunning-started-at" />
                </p>
                <p class="ax-body">
                  <strong class="ax-label"><%= Copy.dunning_next_action_label() %></strong>
                  <%= next_action_summary(@subscription) %>
                </p>
              <% else %>
                <div class="ax-detail-dunning-summary" role="group" aria-label="Dunning funnel state for this subscription">
                  <span><strong>Global dunning funnel</strong><em>No subscription-level campaign here; recovery analytics still shows at-risk accounts and funnel trends.</em></span>
                  <a
                    class="ax-link"
                    href={ScopedPath.build(@admin_mount_path, "/analytics/recovery", @current_owner_scope)}
                  >
                    Open dunning funnel and at-risk analytics
                  </a>
                </div>
                <p class="ax-body">
                  <%= Copy.resource_state_copy(:dunning, :queue_empty, surface: :subscription_detail).body %>
                </p>
              <% end %>

              <div :if={Subscription.dunning_campaign_active?(@subscription)} class="ax-detail-actions-row">
                <a
                  class="ax-link"
                  href={ScopedPath.build(@admin_mount_path, "/analytics/recovery", @current_owner_scope)}
                >
                  Open dunning funnel and at-risk analytics
                </a>
              </div>
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
            <span class="ax-detail-section-title ax-detail-section-title-audit">Activity audit log</span>
          </summary>
          <div class="ax-card ax-activity-audit-strip">
            <p class="ax-label ax-activity-audit-title">Audit event table: Actor / Action / Timestamp</p>
            <% latest_audit = latest_audit_row(@timeline_events, @subscription) %>
            <div class="ax-audit-summary-row" role="group" aria-label="Latest audit event summary">
              <span><strong>Actor</strong><em><%= latest_audit.actor %></em></span>
              <span><strong>Action</strong><em><%= latest_audit.action %></em></span>
              <span><strong>Timestamp</strong><em><Timestamp.timestamp value={latest_audit.at} id="subscription-latest-audit-timestamp" /></em></span>
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
                Open Events audit log with subscription filter
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
                <Timestamp.timestamp value={row.at} id={"subscription-audit-row-#{row.id}"} />
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
          close_label={Copy.subscription_action_back_to_subscription()}
          close_event="cancel_pending_action"
        >
          <%= if @pending_action do %>
            <.pending_action_content
              pending_action={@pending_action}
              subscription={@subscription}
              customer={@customer}
              owner_scope={@current_owner_scope}
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
              id="subscription-action-confirm"
              phx-click="confirm_action"
              class="ax-button ax-button-primary"
              data-role="confirm-action"
              data-ax-action-drawer-confirm
              disabled={@dispatch_state in [:awaiting_step_up, :dispatching, :submitted]}
              phx-disable-with={"Submitting " <> action_label(@pending_action.type)}
            >
              Confirm <%= action_label(@pending_action.type) %>
            </button>
            <button phx-click="cancel_pending_action" class="ax-button ax-button-ghost">
              <%= Copy.subscription_action_back_to_subscription() %>
            </button>
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
                owner_scope={@current_owner_scope}
              />
              <button
                phx-click="confirm_action"
                class="ax-button ax-button-primary"
                data-role="confirm-action"
                data-ax-action-drawer-confirm
                disabled={@dispatch_state in [:awaiting_step_up, :dispatching, :submitted]}
                phx-disable-with={"Submitting " <> action_label(@pending_action.type)}
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
          return_focus="#subscription-action-confirm"
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
  attr(:owner_scope, :map, required: true)

  defp pending_action_content(assigns) do
    ~H"""
    <section class="ax-stack-md" data-role="confirm-panel">
      <p class="ax-label">Confirm action · <%= action_label(@pending_action.type) %></p>
      <dl class="ax-detail-field-list" data-role="subscription-action-review-facts">
        <div>
          <dt class="ax-label">Subscription</dt>
          <dd class="ax-body"><%= customer_label(@customer) %></dd>
          <dd class="ax-body">Subscription ID: <%= @subscription.id %></dd>
          <dd :if={@subscription.processor_id} class="ax-body">
            Processor subscription ID: <%= @subscription.processor_id %>
          </dd>
        </div>
        <div>
          <dt class="ax-label">Customer</dt>
          <dd class="ax-body"><%= customer_label(@customer) %> · Customer ID: <%= @customer.id %></dd>
        </div>
        <div>
          <dt class="ax-label">Owner and active scope</dt>
          <dd class="ax-body">
            Customer owner: <%= @customer.owner_type %> <%= @customer.owner_id %>.
            Active review scope: <%= owner_scope_copy(@owner_scope) %>.
          </dd>
        </div>
        <div>
          <dt class="ax-label">Current state</dt>
          <dd class="ax-body"><%= lifecycle_health_label(@subscription) %></dd>
        </div>
        <div>
          <dt class="ax-label">Current plan / price</dt>
          <dd class="ax-body"><%= current_price_id(@subscription) || "Price unavailable" %></dd>
        </div>
        <div>
          <dt class="ax-label">Current charge amount</dt>
          <dd class="ax-body">Unavailable; no estimate is shown.</dd>
        </div>
        <div :if={@pending_action[:item_id]}>
          <dt class="ax-label">Selected subscription item</dt>
          <dd class="ax-body">Item ID: <%= @pending_action.item_id %></dd>
        </div>
        <div :if={@pending_action[:new_quantity]}>
          <dt class="ax-label">Requested quantity</dt>
          <dd class="ax-body"><%= @pending_action.new_quantity %></dd>
        </div>
        <div :if={@pending_action[:new_price_id]}>
          <dt class="ax-label">Requested price</dt>
          <dd class="ax-body"><%= @pending_action.new_price_id %></dd>
        </div>
      </dl>
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
      <p
        :if={@pending_action.type == "swap_plan" and not match?(%UpcomingInvoice{}, @pending_action[:preview])}
        class="ax-body"
        data-role="subscription-preview-unavailable"
      >
        Invoice amount and currency preview are unavailable; no estimate is shown.
      </p>
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
          value: lifecycle_health_label(subscription)
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
          %{label: "Current period", value: current_period_summary(subscription, :summary)},
          %{label: "Cancellation", value: cancellation_summary(subscription)},
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
            label: "Billing evidence",
            value: Enum.join(caveats, ", "),
            action_label: "View events",
            action_context:
              Copy.action_hidden_context("View",
                resource: "events",
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
      value: renews_or_ends_summary(subscription, :summary),
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

  defp current_period_summary(
         %{
           current_period_start: %DateTime{} = starts_at,
           current_period_end: %DateTime{} = ends_at
         },
         surface
       ) do
    assigns = %{
      starts_at: starts_at,
      ends_at: ends_at,
      start_id: "subscription-period-start-#{surface}",
      end_id: "subscription-period-end-#{surface}"
    }

    ~H"""
    <span><Timestamp.timestamp value={@starts_at} id={@start_id} /> – <Timestamp.timestamp value={@ends_at} id={@end_id} /></span>
    """
  end

  defp current_period_summary(_subscription, _surface), do: not_projected_copy(:period)

  defp cancellation_summary(%{
         cancel_at_period_end: true,
         current_period_end: %DateTime{} = ending
       }),
       do: timestamp_summary("Scheduled for", ending, "subscription-cancellation-summary")

  defp cancellation_summary(%{cancel_at_period_end: true}),
    do: "Scheduled; effective date not shown"

  defp cancellation_summary(%{status: status}) when status in [:canceled, :incomplete_expired],
    do: "Canceled"

  defp cancellation_summary(_), do: "No cancellation scheduled"

  defp collection_summary(%{pause_collection: pause}) when not is_nil(pause),
    do: "Paused"

  defp collection_summary(%{status: :paused}), do: "Paused"
  defp collection_summary(_subscription), do: "Not paused"

  defp lifecycle_tone(status) when status in [:past_due, :unpaid, :incomplete], do: "amber"
  defp lifecycle_tone(:active), do: "moss"
  defp lifecycle_tone(:trialing), do: "cobalt"
  defp lifecycle_tone(_), do: "slate"

  defp projection_caveats(subscription) do
    [
      unless(match?(%DateTime{}, subscription.current_period_end),
        do: "Renewal date unavailable"
      ),
      unless(present?(current_price_id(subscription)), do: "Price unavailable"),
      "Charge amount unavailable"
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp mrr_summary(_subscription), do: not_projected_copy(:amount)

  defp lifecycle_health_label(subscription) do
    cond do
      subscription.status == :incomplete_expired ->
        "Incomplete expired"

      Subscription.canceled?(subscription) ->
        "Canceled"

      subscription.status == :unpaid ->
        "Unpaid"

      Accrue.Billing.Subscription.past_due?(subscription) ->
        "Past due"

      subscription.status == :incomplete ->
        "Incomplete"

      Subscription.trialing?(subscription) ->
        "Trialing"

      subscription.status == :paused ->
        "Paused"

      Accrue.Billing.Subscription.active?(subscription) ->
        if Subscription.trialing?(subscription), do: "Trialing", else: "Active"

      true ->
        humanize(subscription.status)
    end
  end

  defp renews_or_ends_summary(subscription, surface) do
    cond do
      Accrue.Billing.Subscription.canceled?(subscription) ->
        ended_at = subscription.ended_at || subscription.canceled_at

        if ended_at do
          timestamp_summary("Ended", ended_at, "subscription-ended-at-#{surface}")
        else
          not_projected_copy(:end_date)
        end

      Accrue.Billing.Subscription.canceling?(subscription) ->
        timestamp_summary(
          "Ends",
          subscription.current_period_end,
          "subscription-ends-at-#{surface}"
        )

      subscription.cancel_at_period_end ->
        not_projected_copy(:end_date)

      match?(%DateTime{}, subscription.current_period_end) ->
        timestamp_summary(
          "Renews",
          subscription.current_period_end,
          "subscription-renews-at-#{surface}"
        )

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
      %{label: "Current period", value: current_period_summary(subscription, :billing)},
      %{label: "Renewal", value: renews_or_ends_summary(subscription, :billing)},
      %{label: "Collection", value: collection_summary(subscription)},
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
    do: "Unavailable"

  defp not_projected_copy(:end_date),
    do: "End date unavailable"

  defp not_projected_copy(:period),
    do: "Current period unavailable"

  defp not_projected_copy(:price),
    do: "Price unavailable"

  defp not_projected_copy(:renewal),
    do: "Renewal date unavailable"

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
            action_available?(subscription, "update_quantity") &&
              action_item("update_quantity", subscription_label),
            action_available?(subscription, "add_item") &&
              action_item("add_item", subscription_label),
            action_available?(subscription, "update_item_quantity") &&
              action_item("update_item_quantity", subscription_label),
            action_available?(subscription, "remove_item") &&
              action_item("remove_item", subscription_label)
          ]
          |> Enum.reject(&(&1 in [false, nil]))
      },
      %{
        label: "Collection",
        items:
          [
            action_available?(subscription, "pause") && action_item("pause", subscription_label),
            action_available?(subscription, "resume") && action_item("resume", subscription_label)
          ]
          |> Enum.reject(&(&1 in [false, nil]))
      },
      %{
        label: "Danger zone",
        items:
          [
            action_available?(subscription, "cancel_now") &&
              action_item("cancel_now", subscription_label, danger?: true),
            action_available?(subscription, "comp_subscription") &&
              action_item("comp_subscription", subscription_label, danger?: true)
          ]
          |> Enum.reject(&(&1 in [false, nil]))
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
    "#{event.type} · #{event_actor_summary(event)}"
  end

  defp activity_audit_summary(_events, _subscription) do
    "Subscription status reviewed · Accrue system"
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
            id: "projection",
            at: subscription.inserted_at || subscription.current_period_start
          }
        ]

      rows ->
        rows
        |> Enum.take(4)
        |> Enum.map(fn event ->
          %{
            actor: event_actor_summary(event),
            action: event.type,
            id: event.id,
            at: event.inserted_at
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
      id: event.id,
      at: event.inserted_at,
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
      id: "projection",
      at: subscription.inserted_at || subscription.current_period_start,
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

  defp stage_action(socket, action) do
    previous = socket.assigns[:pending_action]
    same_intent? = intent_identity(previous) == intent_identity(action)

    action =
      Map.put(
        action,
        :operation_id,
        if(same_intent? && previous[:operation_id],
          do: previous[:operation_id],
          else: "admin-ui-" <> Ecto.UUID.generate()
        )
      )

    socket =
      if not same_intent? and socket.assigns[:step_up_pending],
        do: StepUp.dismiss_challenge(socket),
        else: socket

    socket
    |> assign(:pending_action, action)
    |> assign(:dispatch_state, :staged)
    |> maybe_clear_previous_result(not same_intent?)
  end

  defp intent_identity(nil), do: nil

  defp intent_identity(action) do
    Map.take(action, [
      :type,
      :subscription_id,
      :new_price_id,
      :new_quantity,
      :item_id,
      :pause_behavior,
      :proration,
      :source_event_id,
      :source_webhook_event_id
    ])
  end

  defp maybe_clear_previous_result(socket, true), do: assign(socket, :action_result, nil)
  defp maybe_clear_previous_result(socket, false), do: socket

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
    do:
      not braintree_processor?(subscription) and Subscription.active?(subscription) and
        not Subscription.canceled?(subscription) and not Subscription.canceling?(subscription)

  defp action_available?(subscription, "pause"),
    do:
      not braintree_processor?(subscription) and Subscription.active?(subscription) and
        not Subscription.paused?(subscription) and not Subscription.canceled?(subscription)

  defp action_available?(subscription, "resume"),
    do:
      not braintree_processor?(subscription) and
        (Subscription.paused?(subscription) or Subscription.canceling?(subscription))

  defp action_available?(subscription, "update_quantity"),
    do: quantity_change_available?(subscription)

  defp action_available?(subscription, action)
       when action in ["add_item", "update_item_quantity", "remove_item"],
       do: quantity_item_changes_available?(subscription)

  defp action_available?(subscription, action)
       when action in ["cancel_now", "comp_subscription"],
       do:
         (action == "cancel_now" and not Subscription.canceled?(subscription)) or
           (action == "comp_subscription" and not is_nil(subscription.customer_id))

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
      socket
      |> StepUp.dismiss_challenge()
      |> assign(:dispatch_state, :staged)
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
    current_action = socket.assigns[:pending_action]

    if socket.assigns[:dispatch_state] in [:dispatching, :submitted] or
         is_nil(current_action) or current_action[:operation_id] != action[:operation_id] do
      reject_stale_review(socket)
    else
      socket = assign(socket, :dispatch_state, :dispatching)

      case validate_review(socket, action) do
        {:ok, fresh_socket, fresh_subscription} ->
          if action.type not in @destructive_actions or StepUp.fresh?(fresh_socket) do
            fresh_socket =
              fresh_socket
              |> assign(:subscription, fresh_subscription)
              |> assign(:customer, fresh_subscription.customer)

            execute_pending_action_fresh(fresh_socket, action)
          else
            reject_stale_review(fresh_socket)
          end

        {:error, socket} ->
          reject_stale_review(socket)
      end
    end
  end

  defp execute_pending_action_fresh(socket, action) do
    subscription = socket.assigns.subscription

    result =
      with_admin_context(socket.assigns.current_admin, action.operation_id, fn operation_id ->
        execute_action(subscription, socket.assigns.customer, action, operation_id)
      end)

    case result do
      {:ok, {:comped, new_subscription}} ->
        present_compensation_result(socket, action, subscription.id, new_subscription)

      {:ok, %Subscription{} = updated_subscription} ->
        case refresh_subscription(socket, updated_subscription.id) do
          {:ok, refreshed} ->
            refreshed
            |> record_admin_audit(action, updated_subscription.id, updated_subscription.id)
            |> put_action_result(:confirmed, action_result_message(:confirmed))
            |> finish_action_submission(:submitted, true)

          :not_found ->
            socket
            |> put_action_result(
              :unconfirmed,
              "The provider returned a change, but the subscription is no longer available in this owner scope. Check scoped activity before taking another action."
            )
            |> finish_action_submission(:submitted, true)
        end

      {:ok, :requires_action, payment_intent} ->
        _ = payment_intent

        socket
        |> put_action_result(
          :pending,
          action_result_message(:pending)
        )
        |> finish_action_submission(:submitted, true)

      {:error, reason} ->
        handle_action_error(socket, action, reason)
    end
  end

  defp validate_review(socket, action) do
    session = socket.assigns[:accrue_admin_session] || %{}
    current_scope = socket.assigns.current_owner_scope

    params =
      if current_scope.mode == :organization,
        do: %{"org" => current_scope.organization_slug},
        else: %{}

    with {:ok, scope} <- AccrueAdmin.OwnerScope.resolve(session, params),
         true <- Auth.actor_id(scope.current_admin) == action.review_actor_id,
         true <- scope_identity(scope) == action.review_scope,
         {:ok, subscription} <- Subscriptions.detail(action.subscription_id, scope),
         true <- action_available?(subscription, action.type),
         true <- action_input_valid?(subscription, action),
         true <- review_fingerprint(action, subscription) == action.review_fingerprint do
      {:ok,
       socket
       |> assign(:current_admin, scope.current_admin)
       |> assign(:current_owner_scope, scope), subscription}
    else
      _ -> {:error, socket}
    end
  end

  defp reject_stale_review(socket) do
    socket
    |> assign(:pending_action, nil)
    |> assign(:drawer_action_type, nil)
    |> assign(:dispatch_state, :idle)
    |> push_flash(
      :warning,
      "The subscription or action details changed. Review the action again before confirming."
    )
  end

  defp scope_identity(scope) do
    {scope.mode, scope.organization_id, scope.organization_slug, scope.platform_admin?,
     scope.admin_org_ids}
  end

  defp review_fingerprint(action, subscription) do
    material_subscription = %{
      id: subscription.id,
      customer_id: subscription.customer_id,
      customer_owner_type: subscription.customer && subscription.customer.owner_type,
      customer_owner_id: subscription.customer && subscription.customer.owner_id,
      processor: subscription.processor,
      processor_id: subscription.processor_id,
      status: subscription.status,
      ended_at: subscription.ended_at,
      cancel_at_period_end: subscription.cancel_at_period_end,
      cancel_at: subscription.cancel_at,
      current_period_end: subscription.current_period_end,
      pause_collection: subscription.pause_collection,
      items:
        Enum.map(subscription.subscription_items || [], fn item ->
          Map.take(item, [:id, :processor_id, :price_id, :quantity])
        end)
    }

    material_action =
      Map.take(action, [
        :type,
        :new_price_id,
        :new_quantity,
        :item_id,
        :pause_behavior,
        :proration,
        :source_event_id,
        :source_webhook_event_id,
        :preview
      ])

    :crypto.hash(:sha256, :erlang.term_to_binary({material_subscription, material_action}))
  end

  defp action_input_valid?(_subscription, %{
         type: "swap_plan",
         new_price_id: price,
         proration: proration
       }),
       do: present?(price) and Map.has_key?(@proration_atoms, proration)

  defp action_input_valid?(_subscription, %{
         type: "update_quantity",
         new_quantity: quantity,
         proration: proration
       }),
       do: is_integer(quantity) and quantity > 0 and Map.has_key?(@proration_atoms, proration)

  defp action_input_valid?(_subscription, %{
         type: "add_item",
         new_price_id: price,
         new_quantity: quantity,
         proration: proration
       }),
       do:
         present?(price) and is_integer(quantity) and quantity > 0 and
           Map.has_key?(@proration_atoms, proration)

  defp action_input_valid?(subscription, %{
         type: "update_item_quantity",
         item_id: id,
         new_quantity: quantity,
         proration: proration
       }),
       do:
         present?(id) and is_integer(quantity) and quantity > 0 and
           Map.has_key?(@proration_atoms, proration) and
           match?({:ok, _}, subscription_item(subscription, id))

  defp action_input_valid?(subscription, %{type: "remove_item", item_id: id, proration: proration}),
       do:
         present?(id) and Map.has_key?(@proration_atoms, proration) and
           match?({:ok, _}, subscription_item(subscription, id))

  defp action_input_valid?(_subscription, %{type: "pause", pause_behavior: behavior}),
    do: behavior in @pause_behaviors

  defp action_input_valid?(_subscription, _action), do: true

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

  defp with_admin_context(user, operation_id, fun) do
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
    case Subscriptions.detail(subscription_id, socket.assigns.current_owner_scope) do
      {:ok, subscription} ->
        events = timeline_events(subscription.id)

        {:ok,
         socket
         |> assign(:subscription, subscription)
         |> assign(:customer, subscription.customer)
         |> assign(:timeline_events, events)
         |> assign(:timeline_events_loaded?, true)
         |> assign(:swap_plan_available, swap_plan_available?(subscription))}

      :not_found ->
        :not_found
    end
  end

  defp present_compensation_result(socket, action, original_id, replacement) do
    scope = socket.assigns.current_owner_scope

    with {:ok, original} <- Subscriptions.detail(original_id, scope),
         {:ok, scoped_replacement} <- Subscriptions.detail(replacement.id, scope),
         {:ok, refreshed} <- refresh_subscription(socket, original.id) do
      replacement_path =
        ScopedPath.build(
          socket.assigns.admin_mount_path,
          "/subscriptions/#{scoped_replacement.id}",
          scope,
          %{"return_to" => socket.assigns.return_path}
        )

      refreshed
      |> record_admin_audit(action, original.id, scoped_replacement.id)
      |> put_action_result(
        :confirmed,
        "Compensation created a replacement subscription.",
        replacement_path,
        "Open replacement subscription"
      )
      |> finish_action_submission(:submitted, true)
    else
      _ ->
        socket
        |> put_action_result(
          :unconfirmed,
          "The compensation request returned, but its replacement is not available in this owner scope. Check scoped subscription activity before taking another action."
        )
        |> finish_action_submission(:submitted, true)
    end
  end

  defp put_action_result(socket, kind, message, href \\ nil, link_label \\ nil) do
    assign(socket, :action_result, %{
      kind: kind,
      message: message,
      href: href || action_activity_path(socket),
      link_label: link_label || "Open scoped subscription activity"
    })
  end

  defp finish_action_submission(socket, state, clear_review?) do
    socket = assign(socket, :dispatch_state, state)

    if clear_review? do
      socket
      |> assign(:pending_action, nil)
      |> assign(:drawer_action_type, nil)
    else
      socket
    end
  end

  defp action_activity_path(socket) do
    ScopedPath.build(
      socket.assigns.admin_mount_path,
      "/events",
      socket.assigns.current_owner_scope,
      %{"subject_type" => "Subscription", "subject_id" => socket.assigns.subscription.id}
    )
  end

  @doc false
  def action_result_message(:confirmed), do: Copy.subscription_action_recorded_info()

  def action_result_message(:pending),
    do:
      "The provider requires another action. A completed subscription change is not confirmed; check scoped activity before deciding what to do next."

  def action_result_message(:failed),
    do: "The provider rejected the action. No change was accepted."

  defp outcome_requires_reconciliation?(socket) do
    match?(%{kind: :unconfirmed}, socket.assigns[:action_result])
  end

  defp require_outcome_review(socket) do
    push_flash(
      socket,
      :warning,
      "Check scoped subscription activity before starting another action for this subscription."
    )
  end

  defp unconfirmed_action_copy(_socket, _action) do
    "Outcome not confirmed. The request may have reached the provider. Check scoped subscription activity before deciding whether another action is needed; Accrue will not retry automatically."
  end

  defp handle_action_error(socket, action, reason) do
    cond do
      local_action_rejection?(reason) ->
        socket
        |> assign(:pending_action, action)
        |> assign(:drawer_action_type, action.type)
        |> put_action_result(
          :rejected,
          "The action was rejected before provider submission. Review the form values and confirm again when they are ready."
        )
        |> finish_action_submission(:staged, false)

      definitive_provider_rejection?(reason) ->
        socket
        |> put_action_result(:failed, action_result_message(:failed))
        |> finish_action_submission(:submitted, true)

      true ->
        socket
        |> put_action_result(:unconfirmed, unconfirmed_action_copy(socket, action))
        |> finish_action_submission(:submitted, true)
    end
  end

  defp definitive_provider_rejection?(%Accrue.APIError{http_status: status})
       when is_integer(status) and status >= 400 and status < 500 and
              status not in [408, 409, 429],
       do: true

  defp definitive_provider_rejection?(_reason), do: false

  defp local_action_rejection?(reason)
       when reason in [:missing_new_price_id, :invalid_proration, :invalid_quantity],
       do: true

  defp local_action_rejection?({:unsupported_action, _}), do: true
  defp local_action_rejection?(_reason), do: false

  defp push_flash(socket, kind, message) do
    assign(socket, :flashes, [%{kind: kind, message: message} | socket.assigns.flashes])
  end

  defp present?(value) when value in [nil, ""], do: false
  defp present?(_value), do: true

  defp confirm_copy(action, subscription, customer) do
    base =
      Copy.subscription_confirm_workflow_message(action.type,
        subscription_id: subscription.processor_id || subscription.id,
        customer_id: customer_label(customer),
        source_event_id: action.source_event_id
      )

    base <> " " <> review_consequence(action, subscription)
  end

  defp review_consequence(%{type: "cancel_now"}, _subscription),
    do: "This cancels the subscription immediately."

  defp review_consequence(%{type: "cancel_at_period_end"}, _subscription),
    do: "This schedules cancellation at period end."

  defp review_consequence(%{type: "pause", pause_behavior: behavior}, _subscription),
    do: "This pauses collection using #{humanize(behavior)} behavior."

  defp review_consequence(%{type: "resume"}, subscription) do
    if Subscription.paused?(subscription),
      do: "This resumes collection for the paused subscription.",
      else: "This cancels the scheduled end and keeps the subscription active."
  end

  defp review_consequence(%{type: "swap_plan"} = action, _subscription) do
    preview =
      if action[:preview],
        do: "Review the displayed invoice preview.",
        else: "Invoice amount and currency preview are unavailable."

    "This changes the plan to #{action.new_price_id || "an unselected plan"} with #{humanize(action.proration || "create_prorations")} proration. #{preview}"
  end

  defp review_consequence(%{type: "update_quantity"} = action, _subscription),
    do:
      "This changes the single subscription item quantity to #{action.new_quantity || "not selected"} with #{humanize(action.proration || "create_prorations")} proration."

  defp review_consequence(%{type: "add_item"} = action, _subscription),
    do:
      "This adds #{action.new_price_id || "an unselected price"} at quantity #{action.new_quantity || "not selected"} with #{humanize(action.proration || "create_prorations")} proration."

  defp review_consequence(%{type: type, item_id: item_id} = action, subscription)
       when type in ["update_item_quantity", "remove_item"] do
    item = Enum.find(subscription.subscription_items || [], &(to_string(&1.id) == item_id))
    item_label = if item, do: subscription_item_label(item), else: "an unavailable item"

    if type == "remove_item" do
      "This removes #{item_label} with #{humanize(action.proration || "create_prorations")} proration."
    else
      "This changes #{item_label} to quantity #{action.new_quantity || "not selected"} with #{humanize(action.proration || "create_prorations")} proration."
    end
  end

  defp review_consequence(%{type: "comp_subscription"}, _subscription),
    do: "This creates a replacement subscription; it does not change the existing subscription."

  defp review_consequence(_action, _subscription),
    do: "Review the selected billing change before confirming."

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

  defp timestamp_summary(label, %DateTime{} = value, id) do
    assigns = %{label: label, value: value, id: id}

    ~H"""
    <span><%= @label %> <Timestamp.timestamp value={@value} id={@id} /></span>
    """
  end

  defp timestamp_summary(label, _value, _id), do: label

  # The audit sentence keeps its existing human-readable event text; the exact
  # copyable timestamp is rendered separately in the adjacent audit row.
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
    Subscription.active?(subscription) and not Subscription.paused?(subscription) and
      not Subscription.canceled?(subscription) and
      (not braintree_processor?(subscription) or PlanResolver.configured?())
  end

  defp preview_supported?(subscription), do: not braintree_processor?(subscription)

  defp quantity_change_available?(subscription) do
    quantity_item_changes_available?(subscription) and single_item_subscription?(subscription)
  end

  defp quantity_item_changes_available?(subscription),
    do:
      not braintree_processor?(subscription) and Subscription.active?(subscription) and
        not Subscription.paused?(subscription) and not Subscription.canceled?(subscription)

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

  defp missing_subscription_path(admin, %{mode: :organization} = owner_scope),
    do: scoped_admin_path(admin, owner_scope, "/subscriptions")

  defp missing_subscription_path(
         admin,
         %OwnerScope{
           mode: :global,
           active_organization_id: organization_id,
           active_organization_slug: organization_slug,
           platform_admin?: platform_admin?,
           admin_org_ids: admin_org_ids
         }
       )
       when is_binary(organization_id) and is_binary(organization_slug) do
    if platform_admin? or organization_id in admin_org_ids do
      scoped_admin_path(
        admin,
        %{mode: :organization, organization_slug: organization_slug},
        "/subscriptions"
      )
    else
      admin_path(admin, "/subscriptions")
    end
  end

  defp missing_subscription_path(admin, _owner_scope), do: admin_path(admin, "/subscriptions")

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

  defp related_items(subscription, mount_path, scope, return_path) do
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

    invoice_items = [
      %{
        icon: :invoices,
        label: "Open invoices for this customer",
        value: "Customer-wide results; open status",
        href:
          ScopedPath.build(mount_path, "/invoices", scope, %{
            "customer_id" => subscription.customer_id,
            "status" => "open",
            "return_to" => return_path
          })
      },
      %{
        icon: :invoices,
        label: invoice_scope_label(scope),
        value: "All authorized open invoices",
        href:
          ScopedPath.build(mount_path, "/invoices", scope, %{
            "status" => "open",
            "return_to" => return_path
          })
      }
    ]

    customer_items ++
      invoice_items ++
      [
        %{
          icon: :payments,
          label: Copy.subscription_drill_link_charges_for_customer(),
          href:
            ScopedPath.build(mount_path, "/payments", scope, %{
              "customer_id" => subscription.customer_id,
              "return_to" => return_path
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

  defp invoice_scope_label(%{mode: :organization} = scope) do
    organization =
      scope.organization_display_name || scope.organization_slug || "selected organization"

    "All open invoices for #{organization}"
  end

  defp invoice_scope_label(_scope), do: "All open invoices in global scope"

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
