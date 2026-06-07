defmodule AccrueAdmin.Live.SubscriptionLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.{Actor, Auth, Billing, Clock, Config, Events, PlanResolver}
  alias Accrue.Billing.Subscription
  alias Accrue.Billing.UpcomingInvoice
  alias Accrue.Dunning.Campaign
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    Detail,
    FlashGroup,
    JsonViewer,
    KpiCard,
    RelatedResources,
    StatusBadge,
    StepUpAuthModal,
    TaxOwnershipCard,
    Timeline
  }

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Subscriptions
  alias AccrueAdmin.ScopedPath
  alias AccrueAdmin.StepUp
  alias AccrueAdmin.TaxOwnershipRow

  @destructive_actions ~w(cancel_now comp_subscription)

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

        {:ok,
         socket
         |> assign_shell(admin)
         |> assign(
           :current_path,
           scoped_admin_path(admin, socket.assigns.current_owner_scope, "/subscriptions")
         )
         |> assign(:subscription, subscription)
         |> assign(:customer, subscription.customer)
         |> assign(:timeline_events, timeline_events(subscription.id))
         |> assign(:proration_options, proration_options())
         |> assign(:swap_plan_available, swap_plan_available?(subscription))
         |> assign(:related_items, related_items(subscription, mount_path, scope))
         |> assign(:flashes, [])
         |> assign(:pending_action, nil)}
    end
  end

  @impl true
  def handle_event("prepare_action", params, socket) do
    action = pending_action(params, socket)
    {:noreply, assign(socket, :pending_action, maybe_attach_preview(socket, action))}
  end

  def handle_event("cancel_pending_action", _params, socket) do
    {:noreply, assign(socket, :pending_action, nil)}
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
          {:ok, socket} -> {:noreply, socket}
          {:challenge, socket} -> {:noreply, socket}
          {:error, reason, socket} -> {:noreply, push_flash(socket, :error, inspect(reason))}
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
            %{label: @subscription.processor_id || @subscription.id}
          ]}
        />

        <Detail.summary_card
          eyebrow={Copy.subscription_detail_eyebrow()}
          title={@subscription.processor_id || @subscription.id}
        >
          <:status><StatusBadge.status_badge status={@subscription.status} /></:status>
          <:facts>
            <span><%= @customer.name || @customer.email || @customer.id %></span>
            <span>period ends <%= format_datetime(@subscription.current_period_end) %></span>
            <span><%= lifecycle_operator_summary(@subscription) %></span>
          </:facts>
        </Detail.summary_card>

        <RelatedResources.related_resources items={@related_items} />

        <FlashGroup.flash_group flashes={@flashes} />

        <section class="ax-kpi-grid" aria-label={Copy.subscription_kpi_section_aria_label()}>
          <KpiCard.kpi_card label={Copy.subscription_kpi_status_label()} value={humanize(@subscription.status)}>
            <:meta><StatusBadge.status_badge status={@subscription.status} /></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label={Copy.subscription_kpi_canonical_predicates_label()} value={predicate_summary(@subscription)}>
            <:meta>Use `Accrue.Billing.Subscription` predicates, not raw status branching.</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label={Copy.subscription_kpi_timeline_rows_label()}
            value={Integer.to_string(length(@timeline_events))}
            delta={current_price_id(@subscription) || "no current price"}
            delta_tone="cobalt"
          >
            <:meta>Ledger events already stored locally</:meta>
          </KpiCard.kpi_card>
        </section>

        <article class="ax-card" data-role="subscription-related-billing">
          <header class="ax-page-header">
            <p class="ax-eyebrow"><%= Copy.subscription_drill_related_card_title() %></p>
            <h3 class="ax-heading"><%= Copy.subscription_drill_related_card_title() %></h3>
          </header>

          <nav aria-label={Copy.subscription_drill_related_region_aria_label()} class="ax-body">
            <ul class="ax-stack-md">
              <li>
                <a
                  href={ScopedPath.build(@admin_mount_path, "/customers/#{@customer.id}", @current_owner_scope)}
                  class="ax-link"
                >
                  <%= Copy.subscription_drill_link_customer() %>
                </a>
              </li>
              <li>
                <a
                  href={ScopedPath.build(@admin_mount_path, "/invoices", @current_owner_scope, %{"customer_id" => @customer.id})}
                  class="ax-link"
                >
                  <%= Copy.subscription_drill_link_invoices_for_customer() %>
                </a>
              </li>
              <li>
                <a
                  href={ScopedPath.build(@admin_mount_path, "/payments", @current_owner_scope, %{"customer_id" => @customer.id})}
                  class="ax-link"
                >
                  <%= Copy.subscription_drill_link_charges_for_customer() %>
                </a>
              </li>
              <li>
                <a
                  href={ScopedPath.build(@admin_mount_path, "/events", @current_owner_scope)}
                  class="ax-link"
                >
                  <%= Copy.subscription_drill_link_events_index() %>
                </a>
              </li>
            </ul>
          </nav>
        </article>

        <article class="ax-card" data-role="subscription-dunning-state">
          <header class="ax-page-header">
            <p class="ax-eyebrow"><%= Copy.dunning_panel_eyebrow() %></p>
            <h3 class="ax-heading"><%= Copy.dunning_panel_title() %></h3>
          </header>

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
              <p class="ax-body"><%= Copy.dunning_empty_state_body() %></p>
              <p class="ax-body">
                <strong class="ax-label"><%= Copy.dunning_started_label() %></strong>
                <%= format_datetime(@subscription.dunning_campaign_started_at) %>
              </p>
              <p class="ax-body">
                <strong class="ax-label"><%= Copy.dunning_next_action_label() %></strong>
                <%= next_action_summary(@subscription) %>
              </p>
            <% end %>
          </div>
        </article>

        <TaxOwnershipCard.tax_ownership_card row={TaxOwnershipRow.from_subscription(@subscription, @customer)} />

        <section class="ax-grid ax-grid-2">
          <article class="ax-card">
            <section
              :if={present?(@subscription.automatic_tax_disabled_reason)}
              class="ax-card"
              data-role="tax-risk-panel"
            >
              <p class="ax-eyebrow">Tax risk</p>
              <h3 class="ax-heading">Automatic tax is currently disabled</h3>
              <p class="ax-body">
                Local reason: <%= humanize(@subscription.automatic_tax_disabled_reason) %>.
                Update the customer tax location in the host app, then retry recurring tax on this subscription.
              </p>
            </section>

            <header class="ax-page-header">
              <p class="ax-eyebrow">Admin actions</p>
              <h3 class="ax-heading">Confirmed billing changes</h3>
              <p class="ax-body">Choose an optional source event, then stage and confirm an action.</p>
              <p class="ax-body"><%= Copy.subscription_action_default_guidance() %></p>
              <p class="ax-body"><%= Copy.subscription_action_exception_guidance() %></p>
              <p class="ax-body"><%= provider_action_guidance(@subscription) %></p>
            </header>

            <div class="ax-stack-xl">
              <form phx-submit="prepare_action" data-role="cancel-now-form">
                <input type="hidden" name="action_type" value="cancel_now" />
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">
                  <%= Copy.subscription_action_cancel_now() %>
                </button>
              </form>

              <form
                :if={!braintree_processor?(@subscription)}
                phx-submit="prepare_action"
                data-role="cancel-at-period-end-form"
              >
                <input type="hidden" name="action_type" value="cancel_at_period_end" />
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">
                  <%= Copy.subscription_action_cancel_at_period_end() %>
                </button>
              </form>

              <form
                :if={!braintree_processor?(@subscription)}
                phx-submit="prepare_action"
                data-role="pause-form"
              >
                <input type="hidden" name="action_type" value="pause" />
                <label class="ax-label" for="pause-behavior">Pause behavior</label>
                <select id="pause-behavior" name="pause_behavior" class="ax-select">
                  <option value="void">Void invoices</option>
                  <option value="mark_uncollectible">Mark uncollectible</option>
                  <option value="keep_as_draft">Keep as draft</option>
                </select>
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">
                  <%= Copy.subscription_action_pause_collection() %>
                </button>
              </form>

              <form
                :if={!braintree_processor?(@subscription)}
                phx-submit="prepare_action"
                data-role="resume-form"
              >
                <input type="hidden" name="action_type" value="resume" />
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">
                  <%= Copy.subscription_action_resume() %>
                </button>
              </form>

              <form
                :if={@swap_plan_available}
                phx-submit="prepare_action"
                data-role="swap-plan-form"
              >
                <input type="hidden" name="action_type" value="swap_plan" />
                <label class="ax-label" for="new-price-id">New price id</label>
                <input id="new-price-id" type="text" name="new_price_id" value={current_price_id(@subscription)} class="ax-input" />
                <label class="ax-label" for="proration">Proration</label>
                <select id="proration" name="proration" class="ax-select">
                  <option :for={option <- @proration_options} value={option.value}><%= option.label %></option>
                </select>
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">
                  <%= Copy.subscription_action_swap_plan() %>
                </button>
              </form>

              <form
                :if={quantity_change_available?(@subscription)}
                phx-submit="prepare_action"
                data-role="quantity-update-form"
              >
                <input type="hidden" name="action_type" value="update_quantity" />
                <label class="ax-label" for="new-quantity">
                  <%= AccrueAdmin.Copy.Subscription.subscription_action_quantity_label() %>
                </label>
                <input id="new-quantity" type="number" min="1" name="new_quantity" value="1" class="ax-input" />
                <p class="ax-body">
                  <%= AccrueAdmin.Copy.Subscription.subscription_action_single_item_quantity_guidance() %>
                </p>
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">
                  <%= AccrueAdmin.Copy.Subscription.subscription_action_update_quantity() %>
                </button>
              </form>

              <form
                :if={quantity_item_changes_available?(@subscription)}
                phx-submit="prepare_action"
                data-role="item-add-form"
              >
                <input type="hidden" name="action_type" value="add_item" />
                <label class="ax-label" for="add-item-price-id">New price id</label>
                <input id="add-item-price-id" type="text" name="new_price_id" class="ax-input" />
                <label class="ax-label" for="add-item-quantity">
                  <%= AccrueAdmin.Copy.Subscription.subscription_action_quantity_label() %>
                </label>
                <input id="add-item-quantity" type="number" min="1" name="new_quantity" value="1" class="ax-input" />
                <label class="ax-label" for="add-item-proration">Proration</label>
                <select id="add-item-proration" name="proration" class="ax-select">
                  <option :for={option <- @proration_options} value={option.value}><%= option.label %></option>
                </select>
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">
                  <%= AccrueAdmin.Copy.Subscription.subscription_action_add_item() %>
                </button>
              </form>

              <form
                :if={quantity_item_changes_available?(@subscription)}
                phx-submit="prepare_action"
                data-role="item-quantity-form"
              >
                <input type="hidden" name="action_type" value="update_item_quantity" />
                <.subscription_item_select subscription={@subscription} input_name="item_id" input_id="item-quantity-id" />
                <label class="ax-label" for="item-quantity-value">
                  <%= AccrueAdmin.Copy.Subscription.subscription_action_quantity_label() %>
                </label>
                <input id="item-quantity-value" type="number" min="1" name="new_quantity" value="1" class="ax-input" />
                <label class="ax-label" for="item-quantity-proration">Proration</label>
                <select id="item-quantity-proration" name="proration" class="ax-select">
                  <option :for={option <- @proration_options} value={option.value}><%= option.label %></option>
                </select>
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">
                  <%= AccrueAdmin.Copy.Subscription.subscription_action_update_item_quantity() %>
                </button>
              </form>

              <form
                :if={quantity_item_changes_available?(@subscription)}
                phx-submit="prepare_action"
                data-role="item-remove-form"
              >
                <input type="hidden" name="action_type" value="remove_item" />
                <.subscription_item_select subscription={@subscription} input_name="item_id" input_id="item-remove-id" />
                <label class="ax-label" for="item-remove-proration">Proration</label>
                <select id="item-remove-proration" name="proration" class="ax-select">
                  <option :for={option <- @proration_options} value={option.value}><%= option.label %></option>
                </select>
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">
                  <%= AccrueAdmin.Copy.Subscription.subscription_action_remove_item() %>
                </button>
              </form>

              <p
                :if={!@swap_plan_available and braintree_processor?(@subscription)}
                class="ax-body"
                data-role="swap-plan-unavailable"
              >
                <%= Copy.subscription_action_braintree_swap_setup_guidance() %>
              </p>

              <p
                :if={braintree_processor?(@subscription)}
                class="ax-body"
                data-role="quantity-item-unsupported"
              >
                <%= AccrueAdmin.Copy.Subscription.subscription_action_braintree_quantity_item_guidance() %>
              </p>

              <form phx-submit="prepare_action" data-role="comp-form">
                <input type="hidden" name="action_type" value="comp_subscription" />
                <label class="ax-label" for="comp-price-id">Comp price id</label>
                <input id="comp-price-id" type="text" name="new_price_id" value={current_price_id(@subscription)} class="ax-input" />
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">
                  <%= Copy.subscription_action_create_comp_replacement() %>
                </button>
              </form>
            </div>

            <section :if={@pending_action} class="ax-card" data-role="confirm-panel">
              <p class="ax-label">Confirm action</p>
              <p class="ax-body"><%= confirm_copy(@pending_action) %></p>
              <section
                :if={match?(%UpcomingInvoice{}, @pending_action[:preview])}
                class="ax-stack-md"
                data-role="swap-plan-preview"
              >
                <p class="ax-label"><%= AccrueAdmin.Copy.Subscription.subscription_action_preview_heading() %></p>
                <p class="ax-body"><%= preview_summary(@pending_action.preview) %></p>
                <p class="ax-body">
                  <%= AccrueAdmin.Copy.Subscription.subscription_action_preview_total_label() %>:
                  <%= money_or_dash(@pending_action.preview.total) %>
                </p>
                <ul class="ax-stack-sm">
                  <li :for={line <- Enum.take(@pending_action.preview.lines, 3)} class="ax-body">
                    <%= preview_line_summary(line) %>
                  </li>
                </ul>
              </section>
              <div class="ax-page-header">
                <button phx-click="confirm_action" class="ax-button ax-button-primary" data-role="confirm-action">
                  Confirm <%= humanize(@pending_action.type) %>
                </button>
                <button phx-click="cancel_pending_action" class="ax-button ax-button-ghost">Cancel</button>
              </div>
            </section>
          </article>

          <Detail.detail_section title="Subscription events">
            <Timeline.timeline
              label="Subscription events"
              empty_label="No subscription events yet"
              items={timeline_items(@timeline_events)}
            />
          </Detail.detail_section>
        </section>

        <JsonViewer.json_viewer id="subscription-data" label="Subscription payload" payload={subscription_payload(@subscription)} />

        <StepUpAuthModal.step_up_auth_modal
          pending={@step_up_pending}
          challenge={@step_up_challenge}
          error={@step_up_error}
        />
      </section>
    </AppShell.app_shell>
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

  attr(:subscription, :map, required: true)
  attr(:input_name, :string, required: true)
  attr(:input_id, :string, required: true)

  defp subscription_item_select(assigns) do
    ~H"""
    <label class="ax-label" for={@input_id}>
      <%= AccrueAdmin.Copy.Subscription.subscription_action_item_id_label() %>
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

    %{
      type: Map.fetch!(params, "action_type"),
      new_price_id: blank_to_nil(params["new_price_id"]),
      new_quantity: integer_param(params["new_quantity"]),
      item_id: blank_to_nil(params["item_id"]),
      pause_behavior: blank_to_nil(params["pause_behavior"]) || "void",
      proration: blank_to_nil(params["proration"]) || "create_prorations",
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

      {:error, reason} ->
        push_flash(socket, :error, inspect(reason))
    end
    |> assign(:pending_action, nil)
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
    Billing.swap_plan(subscription, new_price_id,
      proration: String.to_existing_atom(proration),
      operation_id: operation_id
    )
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
    Billing.add_item(subscription, new_price_id,
      quantity: new_quantity,
      proration: String.to_existing_atom(proration),
      operation_id: operation_id
    )
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
    with {:ok, item} <- subscription_item(subscription, item_id) do
      Billing.update_item_quantity(item, new_quantity,
        proration: String.to_existing_atom(proration),
        operation_id: operation_id
      )
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
    with {:ok, item} <- subscription_item(subscription, item_id) do
      Billing.remove_item(item,
        proration: String.to_existing_atom(proration),
        operation_id: operation_id
      )
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

    socket
    |> assign(:subscription, subscription)
    |> assign(:customer, subscription.customer)
    |> assign(:timeline_events, timeline_events(subscription_id))
    |> assign(:swap_plan_available, swap_plan_available?(subscription))
  end

  defp push_flash(socket, kind, message) do
    assign(socket, :flashes, [%{kind: kind, message: message} | socket.assigns.flashes])
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

    "#{action_confirmation_copy(action.type)}#{source}"
  end

  defp action_confirmation_copy("cancel_now"),
    do:
      "Cancel now will execute against the local billing projection and should be treated as an exceptional hard-stop path."

  defp action_confirmation_copy("cancel_at_period_end"),
    do:
      "Cancel at period end will turn off renewal now and preserve access through the current billing period where the processor supports that semantic."

  defp action_confirmation_copy("pause"),
    do:
      "Pause collection will only succeed where the processor supports Accrue's pause semantic; Braintree does not."

  defp action_confirmation_copy("resume"),
    do:
      "Resume will unpause a paused subscription or reverse a scheduled end when the processor and current state support it; Braintree does not provide that parity."

  defp action_confirmation_copy("swap_plan"),
    do:
      "Swap plan stages a preview before commit where the provider supports upcoming-invoice previews."

  defp action_confirmation_copy("update_quantity"),
    do:
      "Update quantity commits the supported single-item quantity change path. Use item-level actions once add-ons exist."

  defp action_confirmation_copy("add_item"),
    do: "Add item will attach a new subscription item on the supported Stripe/Fake lane."

  defp action_confirmation_copy("update_item_quantity"),
    do:
      "Update item quantity will change the selected subscription item on the supported Stripe/Fake lane."

  defp action_confirmation_copy("remove_item"),
    do:
      "Remove item will delete the selected subscription item on the supported Stripe/Fake lane."

  defp action_confirmation_copy(type),
    do: "#{humanize(type)} will execute against the local billing projection."

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

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp humanize(value) when is_atom(value), do: value |> Atom.to_string() |> humanize()

  defp humanize(value) when is_binary(value) do
    value
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize(_value), do: "Unknown"

  defp format_datetime(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y %H:%M UTC")
  defp format_datetime(_value), do: "Unknown"

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

  defp lifecycle_operator_summary(subscription) do
    case predicate_summary(subscription) do
      "active" ->
        "Active and renewing. Default customer guidance should keep renewal changes explicit."

      "active · canceling" ->
        "Cancel renewal is already scheduled. Access remains until the current period end."

      summary when is_binary(summary) ->
        "Lifecycle summary: #{summary}. Keep provider-specific action promises honest."
    end
  end

  defp provider_action_guidance(subscription) do
    if braintree_processor?(subscription) do
      Copy.subscription_action_braintree_guidance()
    else
      Copy.subscription_action_stripe_guidance() <>
        " " <> AccrueAdmin.Copy.Subscription.subscription_action_supported_change_guidance()
    end
  end

  defp maybe_attach_preview(
         socket,
         %{type: "swap_plan", new_price_id: new_price_id, proration: proration} = action
       )
       when is_binary(new_price_id) do
    if preview_supported?(socket.assigns.subscription) do
      case Billing.preview_upcoming_invoice(socket.assigns.subscription,
             new_price_id: new_price_id,
             proration: String.to_existing_atom(proration)
           ) do
        {:ok, %UpcomingInvoice{} = preview} -> Map.put(action, :preview, preview)
        {:error, reason} -> Map.put(action, :preview_error, inspect(reason))
      end
    else
      action
    end
  rescue
    ArgumentError -> Map.put(action, :preview_error, inspect(:invalid_proration))
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

  defp customer_label(customer),
    do: customer.name || customer.email || customer.processor_id || customer.id

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

  defp money_or_dash(nil), do: "-"

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
          icon: :invoices,
          label: "Invoices",
          href:
            ScopedPath.build(mount_path, "/invoices", scope, %{
              "subscription_id" => subscription.id
            })
        },
        %{
          icon: :events,
          label: "Events",
          href:
            ScopedPath.build(mount_path, "/events", scope, %{
              "subject_type" => "Subscription",
              "subject_id" => subscription.id
            })
        }
      ]
  end

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
