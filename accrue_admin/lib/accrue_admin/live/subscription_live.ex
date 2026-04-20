defmodule AccrueAdmin.Live.SubscriptionLive do
  @moduledoc false

  use Phoenix.LiveView

  alias Accrue.{Actor, Auth, Billing, Events}
  alias Accrue.Billing.Subscription
  alias Accrue.Repo

  alias AccrueAdmin.Components.{
    AppShell,
    Breadcrumbs,
    FlashGroup,
    JsonViewer,
    KpiCard,
    StatusBadge,
    StepUpAuthModal,
    TaxOwnershipCard,
    Timeline
  }

  alias AccrueAdmin.TaxOwnershipRow

  alias AccrueAdmin.Copy
  alias AccrueAdmin.Queries.Subscriptions
  alias AccrueAdmin.StepUp

  @destructive_actions ~w(cancel_now comp_subscription)
  @proration_options [
    %{value: "create_prorations", label: "Create prorations"},
    %{value: "none", label: "No proration"},
    %{value: "always_invoice", label: "Always invoice"}
  ]

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
         |> assign(:proration_options, @proration_options)
         |> assign(:flashes, [])
         |> assign(:pending_action, nil)}
    end
  end

  @impl true
  def handle_event("prepare_action", params, socket) do
    {:noreply, assign(socket, :pending_action, pending_action(params, socket))}
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
              %{label: "Dashboard", href: scoped_mount_path(@admin_mount_path, "", @current_owner_scope)},
              %{
                label: "Subscriptions",
                href: scoped_mount_path(@admin_mount_path, "/subscriptions", @current_owner_scope)
              },
              %{label: @subscription.processor_id || @subscription.id}
            ]}
          />
          <p class="ax-eyebrow">Subscription detail</p>
          <h2 class="ax-display"><%= @subscription.processor_id || @subscription.id %></h2>
          <p class="ax-body ax-page-copy">
            <%= @customer.name || @customer.email || @customer.id %> · period ends <%= format_datetime(@subscription.current_period_end) %>
          </p>
        </header>

        <FlashGroup.flash_group flashes={@flashes} />

        <section class="ax-kpi-grid" aria-label="Subscription lifecycle summary">
          <KpiCard.kpi_card label="Status" value={humanize(@subscription.status)}>
            <:meta><StatusBadge.status_badge status={@subscription.status} /></:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card label="Canonical predicates" value={predicate_summary(@subscription)}>
            <:meta>Use `Accrue.Billing.Subscription` predicates, not raw status branching.</:meta>
          </KpiCard.kpi_card>

          <KpiCard.kpi_card
            label="Timeline rows"
            value={Integer.to_string(length(@timeline_events))}
            delta={current_price_id(@subscription) || "no current price"}
            delta_tone="cobalt"
          >
            <:meta>Ledger events already stored locally</:meta>
          </KpiCard.kpi_card>
        </section>

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
            </header>

            <div class="ax-stack-xl">
              <form phx-submit="prepare_action" data-role="cancel-now-form">
                <input type="hidden" name="action_type" value="cancel_now" />
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">Cancel now</button>
              </form>

              <form phx-submit="prepare_action" data-role="cancel-at-period-end-form">
                <input type="hidden" name="action_type" value="cancel_at_period_end" />
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">Cancel at period end</button>
              </form>

              <form phx-submit="prepare_action" data-role="pause-form">
                <input type="hidden" name="action_type" value="pause" />
                <label class="ax-label" for="pause-behavior">Pause behavior</label>
                <select id="pause-behavior" name="pause_behavior" class="ax-select">
                  <option value="void">Void invoices</option>
                  <option value="mark_uncollectible">Mark uncollectible</option>
                  <option value="keep_as_draft">Keep as draft</option>
                </select>
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">Pause collection</button>
              </form>

              <form phx-submit="prepare_action" data-role="resume-form">
                <input type="hidden" name="action_type" value="resume" />
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">Resume</button>
              </form>

              <form phx-submit="prepare_action" data-role="swap-plan-form">
                <input type="hidden" name="action_type" value="swap_plan" />
                <label class="ax-label" for="new-price-id">New price id</label>
                <input id="new-price-id" type="text" name="new_price_id" value={current_price_id(@subscription)} class="ax-input" />
                <label class="ax-label" for="proration">Proration</label>
                <select id="proration" name="proration" class="ax-select">
                  <option :for={option <- @proration_options} value={option.value}><%= option.label %></option>
                </select>
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">Swap plan</button>
              </form>

              <form phx-submit="prepare_action" data-role="comp-form">
                <input type="hidden" name="action_type" value="comp_subscription" />
                <label class="ax-label" for="comp-price-id">Comp price id</label>
                <input id="comp-price-id" type="text" name="new_price_id" value={current_price_id(@subscription)} class="ax-input" />
                <.source_event_select events={@timeline_events} />
                <button type="submit" class="ax-button ax-button-secondary">Create comp replacement</button>
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
              <p class="ax-eyebrow">Ledger timeline</p>
              <h3 class="ax-heading">Subscription events</h3>
            </header>

            <Timeline.timeline
              label="Subscription events"
              empty_label="No subscription events yet"
              items={timeline_items(@timeline_events)}
            />
          </article>
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

  attr(:events, :list, required: true)

  defp source_event_select(assigns) do
    ~H"""
    <label class="ax-label" for={"source-event-" <> Integer.to_string(System.unique_integer([:positive]))}>
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
    |> assign(:page_title, "Subscription")
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
      Accrue.Billing.Subscription.canceled?(subscription) && "canceled"
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

    "#{humanize(action.type)} will execute against the local billing projection.#{source}"
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

  defp admin_path(admin, suffix), do: (admin["mount_path"] || "/billing") <> suffix

  defp scoped_admin_path(admin, %{mode: :organization, organization_slug: slug}, suffix)
       when is_binary(slug) do
    admin_path(admin, suffix) <> "?org=" <> URI.encode_www_form(slug)
  end

  defp scoped_admin_path(admin, _owner_scope, suffix), do: admin_path(admin, suffix)

  defp scoped_mount_path(mount_path, suffix, %{mode: :organization, organization_slug: slug})
       when is_binary(slug) do
    mount_path <> suffix <> "?org=" <> URI.encode_www_form(slug)
  end

  defp scoped_mount_path(mount_path, suffix, _owner_scope), do: mount_path <> suffix

  defp default_brand do
    %{app_name: "Billing", logo_url: nil, accent_hex: "#5D79F6", accent_contrast_hex: "#FAFBFC"}
  end
end
