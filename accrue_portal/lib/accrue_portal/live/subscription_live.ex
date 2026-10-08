defmodule AccruePortal.Live.SubscriptionLive do
  use Phoenix.LiveView

  alias Accrue.Billing
  alias Accrue.Billing.{Subscription, UpcomingInvoice}
  alias AccruePortal.Authorize
  alias AccruePortal.BillingReadModel
  alias AccruePortal.Copy
  alias AccruePortal.Path

  @impl true
  def mount(%{"id" => id}, %{"accrue_portal" => portal}, socket) do
    case Authorize.subscription(socket, id) do
      {:ok, %Subscription{} = subscription} ->
        {:ok,
         socket
         |> assign(:page_title, Copy.subscription_page_title())
         |> assign(:portal, portal)
         |> assign(:base_path, portal["mount_path"])
         |> assign(:subscription, subscription)
         |> assign(:subscription_unavailable?, false)
         |> assign(:can_cancel?, BillingReadModel.subscription_cancel_available?(subscription))
         |> assign(
           :can_change_plan?,
           BillingReadModel.subscription_plan_change_available?(subscription)
         )
         |> assign(:show_cancel_confirmation, false)
         |> assign(:plan_change_price_id, nil)
         |> assign(:plan_change_preview, nil)
         |> assign(:action_notice, nil)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> assign(:page_title, Copy.subscription_not_found_title())
         |> assign(:portal, portal)
         |> assign(:base_path, portal["mount_path"])
         |> assign(:subscription, nil)
         |> assign(:subscription_unavailable?, false)
         |> assign(:can_cancel?, false)
         |> assign(:can_change_plan?, false)
         |> assign(:show_cancel_confirmation, false)
         |> assign(:plan_change_price_id, nil)
         |> assign(:plan_change_preview, nil)
         |> assign(:action_notice, nil)}

      {:error, _reason} ->
        {:ok,
         socket
         |> assign(:page_title, Copy.subscription_unavailable_title())
         |> assign(:portal, portal)
         |> assign(:base_path, portal["mount_path"])
         |> assign(:subscription, nil)
         |> assign(:subscription_unavailable?, true)
         |> assign(:can_cancel?, false)
         |> assign(:can_change_plan?, false)
         |> assign(:show_cancel_confirmation, false)
         |> assign(:plan_change_price_id, nil)
         |> assign(:plan_change_preview, nil)
         |> assign(:action_notice, nil)}
    end
  end

  @impl true
  def handle_event("toggle_cancel_confirmation", _params, socket) do
    case authorize_current(socket, :subscription_cancel) do
      {:ok, %Subscription{} = subscription} ->
        if BillingReadModel.subscription_cancel_available?(subscription) do
          show_confirmation? = not socket.assigns.show_cancel_confirmation

          socket =
            socket
            |> assign(:subscription, subscription)
            |> assign(:can_cancel?, true)
            |> assign(:show_cancel_confirmation, show_confirmation?)

          focus_id =
            if show_confirmation?,
              do: "cancel-confirm-#{subscription.id}",
              else: "cancel-trigger-#{subscription.id}"

          {:noreply, push_portal_focus(socket, focus_id)}
        else
          {:noreply, cancel_unavailable(socket)}
        end

      {:error, _reason} ->
        {:noreply, denied(socket)}
    end
  end

  def handle_event(
        "cancel_confirmation_escape",
        %{"key" => "Escape"},
        %{assigns: %{show_cancel_confirmation: true, subscription: %Subscription{id: id}}} =
          socket
      ) do
    {:noreply,
     socket
     |> assign(:show_cancel_confirmation, false)
     |> push_portal_focus("cancel-trigger-#{id}")}
  end

  def handle_event("cancel_confirmation_escape", _params, socket), do: {:noreply, socket}

  def handle_event(
        "preview_plan_change",
        %{"plan_change" => %{"price_id" => price_id}},
        %{assigns: %{subscription: %Subscription{}}} = socket
      ) do
    case authorize_current(socket, :subscription_preview) do
      {:ok, %Subscription{} = authorized} ->
        if BillingReadModel.subscription_plan_change_available?(authorized) do
          preview_plan_change_event(socket, authorized, price_id)
        else
          {:noreply, plan_change_unavailable(socket, authorized)}
        end

      {:error, _reason} ->
        {:noreply, denied(socket)}
    end
  end

  def handle_event(
        "confirm_plan_change",
        _params,
        %{
          assigns: %{subscription: %Subscription{}, plan_change_price_id: price_id}
        } = socket
      )
      when is_binary(price_id) do
    case authorize_current(socket, :subscription_change) do
      {:ok, %Subscription{} = authorized} ->
        if BillingReadModel.subscription_plan_change_available?(authorized) do
          case with_actor(socket, fn -> swap_plan(authorized, price_id) end) do
            {:ok, %Subscription{} = updated_subscription} ->
              {:noreply,
               socket
               |> assign(:subscription, updated_subscription)
               |> assign(
                 :can_cancel?,
                 BillingReadModel.subscription_cancel_available?(updated_subscription)
               )
               |> assign(
                 :can_change_plan?,
                 BillingReadModel.subscription_plan_change_available?(updated_subscription)
               )
               |> clear_plan_change()
               |> assign(:action_notice, Copy.subscription_plan_change_commit_success())
               |> push_portal_focus("subscription-action-notice")
               |> put_flash(:info, Copy.subscription_plan_change_commit_success())}

            {:error, _reason} ->
              {:noreply,
               socket
               |> clear_plan_change()
               |> put_flash(:error, Copy.subscription_plan_change_commit_error())}
          end
        else
          {:noreply, plan_change_unavailable(socket, authorized)}
        end

      {:error, _reason} ->
        {:noreply, denied(socket)}
    end
  end

  def handle_event("confirm_plan_change", _params, socket) do
    {:noreply, put_flash(socket, :error, Copy.subscription_plan_change_requires_preview())}
  end

  def handle_event("reset_plan_change", _params, socket) do
    {:noreply,
     socket
     |> assign(:plan_change_price_id, nil)
     |> assign(:plan_change_preview, nil)}
  end

  def handle_event(
        "cancel",
        %{"id" => id},
        %{assigns: %{subscription: %Subscription{id: expected_id}}} = socket
      )
      when id != expected_id do
    {:noreply, denied(socket)}
  end

  def handle_event(
        "cancel",
        %{"id" => id},
        %{
          assigns: %{
            subscription: %Subscription{id: id} = subscription,
            show_cancel_confirmation: true
          }
        } = socket
      ) do
    case Authorize.subscription(socket, subscription.id, :subscription_cancel) do
      {:ok, %Subscription{} = scoped_subscription} ->
        if BillingReadModel.subscription_cancel_available?(scoped_subscription) do
          case with_actor(socket, fn -> cancel_subscription(scoped_subscription) end) do
            {:ok, updated} ->
              {:noreply,
               socket
               |> assign(:subscription, updated)
               |> assign(:can_cancel?, BillingReadModel.subscription_cancel_available?(updated))
               |> assign(
                 :can_change_plan?,
                 BillingReadModel.subscription_plan_change_available?(updated)
               )
               |> assign(:show_cancel_confirmation, false)
               |> assign(:action_notice, Copy.subscription_cancel_success(scoped_subscription))
               |> push_portal_focus("subscription-action-notice")
               |> put_flash(:info, Copy.subscription_cancel_success(scoped_subscription))}

            {:error, _reason} ->
              {:noreply,
               socket
               |> assign(:show_cancel_confirmation, false)
               |> assign(:action_notice, Copy.subscription_cancel_error(scoped_subscription))
               |> put_flash(:error, Copy.subscription_cancel_error(scoped_subscription))}
          end
        else
          {:noreply, cancel_unavailable(socket)}
        end

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, Copy.subscriptions_unknown_error())}

      {:error, _reason} ->
        {:noreply, denied(socket)}
    end
  end

  def handle_event("cancel", _params, socket),
    do: {:noreply, put_flash(socket, :error, Copy.subscription_cancel_requires_confirmation())}

  defp preview_plan_change_event(socket, subscription, price_id) do
    case preview_plan_change(subscription, price_id) do
      {:ok, %UpcomingInvoice{} = preview, normalized_price_id} ->
        {:noreply,
         socket
         |> assign(:subscription, subscription)
         |> assign(:can_cancel?, BillingReadModel.subscription_cancel_available?(subscription))
         |> assign(
           :can_change_plan?,
           BillingReadModel.subscription_plan_change_available?(subscription)
         )
         |> assign(:plan_change_price_id, normalized_price_id)
         |> assign(:plan_change_preview, preview)}

      {:error, :preview_unsupported} ->
        {:noreply,
         socket
         |> assign(:plan_change_price_id, nil)
         |> assign(:plan_change_preview, nil)
         |> put_flash(
           :error,
           Copy.subscription_plan_change_preview_unavailable_body(subscription)
         )}

      {:error, :missing_reference} ->
        {:noreply, put_flash(socket, :error, Copy.subscription_plan_change_missing_reference())}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:plan_change_price_id, nil)
         |> assign(:plan_change_preview, nil)
         |> put_flash(:error, Copy.subscription_plan_change_preview_error())}
    end
  end

  @impl true
  def render(%{subscription: nil, subscription_unavailable?: true} = assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card" role="alert">
        <h1>{Copy.subscription_unavailable_title()}</h1>
        <p>{Copy.subscription_unavailable_body()}</p>
        <div class="portal-actions">
          <a href={Path.context(Path.home(@base_path), @current_context_pin)} class="portal-button-secondary">
            {Copy.subscription_back_home_cta()}
          </a>
        </div>
      </section>
    </main>
    """
  end

  def render(%{subscription: nil} = assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card">
        <h1>{Copy.subscription_not_found_title()}</h1>
        <p>{Copy.subscription_not_found_body()}</p>
        <div class="portal-actions">
          <a href={Path.context(Path.home(@base_path), @current_context_pin)} class="portal-button-secondary">
            {Copy.subscription_back_home_cta()}
          </a>
        </div>
      </section>
    </main>
    """
  end

  def render(assigns) do
    ~H"""
    <main
      class="portal-shell"
      phx-window-keydown={@show_cancel_confirmation && "cancel_confirmation_escape"}
      phx-key={@show_cancel_confirmation && "Escape"}
    >
      <AccruePortal.Layouts.breadcrumb trail={[
        %{label: Copy.breadcrumb_home(), href: Path.context(Path.home(@base_path), @current_context_pin)},
        %{label: Copy.subscriptions_heading(), href: Path.context(Path.subscriptions(@base_path), @current_context_pin)},
        %{label: Copy.subscription_heading(), href: nil}
      ]} />
      <section
        :if={recovery_prompt?(@subscription)}
        class="portal-card"
        role="alert"
        data-role="subscription-recovery-banner"
      >
        <h2>{Copy.subscription_recovery_heading()}</h2>
        <p>{Copy.subscription_recovery_body()}</p>
        <div class="portal-actions">
          <a href={Path.context(update_pm_path(@base_path, @subscription), @current_context_pin)} class="portal-button-primary">
            {Copy.subscription_recovery_cta()}
          </a>
        </div>
      </section>

      <section class="portal-card">
        <p :if={@action_notice} id="subscription-action-notice" class="portal-inline-status" role="status" aria-live="polite" tabindex="-1">
          {@action_notice}
        </p>
        <h1>{Copy.subscription_heading()}</h1>
        <ul class="portal-list">
          <li>
            <strong>{Copy.subscription_identifier_label()}</strong>
            <span>{@subscription.processor_id || @subscription.id}</span>
          </li>
          <li>
            <strong>{Copy.subscription_status_label()}</strong>
            <span class={["portal-status", status_variant(@subscription.status)]}>
              {Copy.subscription_lifecycle_label(@subscription)}
            </span>
          </li>
          <li>
            <strong>{Copy.subscription_summary_label()}</strong>
            <span>{Copy.subscription_lifecycle_summary(@subscription)}</span>
          </li>
          <li>
            <strong>{Copy.subscription_period_end_label()}</strong>
            <span>{format_datetime(@subscription.current_period_end)}</span>
          </li>
        </ul>
      </section>

      <section class="portal-card">
        <h2>{Copy.subscription_cancel_heading(@subscription)}</h2>
        <p>{Copy.subscription_access_timing(@subscription)}</p>
        <div :if={@can_cancel? && !@show_cancel_confirmation}>
          <p>{Copy.subscription_cancel_body(@subscription)}</p>
          <button
            id={"cancel-trigger-#{@subscription.id}"}
            phx-click="toggle_cancel_confirmation"
            phx-value-id={@subscription.id}
            class="portal-button-secondary"
          >
            {Copy.subscription_cancel_cta(@subscription)}
          </button>
        </div>
        <div
          :if={@can_cancel? && @show_cancel_confirmation}
          role="group"
          aria-label="Cancel subscription confirmation"
        >
          <p>{Copy.subscription_cancel_body(@subscription)}</p>
          <p>
            {Copy.subscription_cancel_confirmation(
              @current_context.display_name || @current_customer.name || @current_customer.email || "this account",
              @subscription.processor_id || @subscription.id
            )}
          </p>
          <button
            id={"cancel-confirm-#{@subscription.id}"}
            phx-click="cancel"
            phx-value-id={@subscription.id}
            class="portal-button-secondary"
          >
            {Copy.subscription_cancel_cta(@subscription)}
          </button>
          <button
            id={"cancel-keep-#{@subscription.id}"}
            phx-click="toggle_cancel_confirmation"
            phx-value-id={@subscription.id}
            class="portal-button-secondary"
          >
            {Copy.subscription_keep_cta()}
          </button>
        </div>
        <p :if={!@can_cancel?} class="portal-inline-status">
          {Copy.subscription_cancel_not_available()}
        </p>
      </section>

      <section class="portal-card">
        <h2>{Copy.subscription_plan_change_heading()}</h2>
        <%= if @can_change_plan? do %>
          <p>{Copy.subscription_plan_change_body(@subscription)}</p>
          <div>
            <p>
              <strong>{Copy.subscription_plan_change_current_label()}</strong>
              <span>{current_plan_reference(@subscription)}</span>
            </p>
            <.form id="plan-change-form" for={%{}} as={:plan_change} phx-submit="preview_plan_change">
              <label for="plan-change-price-id">{Copy.subscription_plan_change_target_label()}</label>
              <input
                id="plan-change-price-id"
                name="plan_change[price_id]"
                type="text"
                value={@plan_change_price_id}
              />
              <p>{Copy.subscription_plan_change_target_hint()}</p>
              <button type="submit" class="portal-button-secondary">
                {Copy.subscription_plan_change_preview_cta()}
              </button>
            </.form>
          </div>

          <div :if={match?(%UpcomingInvoice{}, @plan_change_preview)}>
            <h3>{Copy.subscription_plan_change_preview_heading()}</h3>
            <p>{Copy.subscription_plan_change_preview_body()}</p>
            <p>
              <strong>{Copy.subscription_plan_change_preview_total_label()}</strong>
              <span>{format_money(@plan_change_preview.total)}</span>
            </p>
            <ul class="portal-list" :if={@plan_change_preview.lines != []}>
              <li :for={line <- @plan_change_preview.lines}>
                <span>{line.description || line.price_id || "Invoice line"}</span>
                <span>{format_money(line.amount)}</span>
              </li>
            </ul>
            <div>
              <button phx-click="confirm_plan_change" class="portal-button-secondary">
                {Copy.subscription_plan_change_commit_cta()}
              </button>
              <button phx-click="reset_plan_change" class="portal-button-secondary">
                {Copy.subscription_plan_change_reset_cta()}
              </button>
            </div>
          </div>
        <% else %>
          <h3>{Copy.subscription_plan_change_preview_unavailable_heading()}</h3>
          <p>{Copy.subscription_plan_change_preview_unavailable_body(@subscription)}</p>
        <% end %>
      </section>
    </main>
    """
  end

  # Presentation-only: map a subscription lifecycle status to a status-pill
  # variant class. No copy/behavior change.
  defp status_variant(status) when status in [:active, :trialing], do: "portal-status-active"

  defp status_variant(status) when status in [:past_due, :unpaid, :incomplete],
    do: "portal-status-warning"

  defp status_variant(_status), do: "portal-status-info"

  defp format_datetime(nil), do: "Not available"
  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d")

  defp format_money(nil), do: "--"

  defp format_money(%Accrue.Money{amount_minor: amount_minor, currency: currency}) do
    Accrue.Invoices.Render.format_money(amount_minor, currency, "en")
  end

  defp cancel_subscription(%Subscription{processor: "braintree"} = subscription),
    do: Billing.cancel(subscription)

  defp cancel_subscription(%Subscription{} = subscription),
    do: Billing.cancel_at_period_end(subscription)

  defp authorize_current(socket, action) do
    case socket.assigns[:subscription] do
      %Subscription{id: id} -> Authorize.subscription(socket, id, action)
      _ -> {:error, :not_found}
    end
  end

  defp denied(socket) do
    socket
    |> assign(:show_cancel_confirmation, false)
    |> assign(:can_cancel?, false)
    |> assign(:can_change_plan?, false)
    |> clear_plan_change()
    |> assign(
      :action_notice,
      "Your change was not submitted because billing access is unavailable."
    )
    |> put_flash(:error, "Your change was not submitted because billing access is unavailable.")
  end

  defp cancel_unavailable(socket) do
    socket
    |> assign(:show_cancel_confirmation, false)
    |> assign(:can_cancel?, false)
    |> assign(:action_notice, Copy.subscription_cancel_unavailable())
    |> put_flash(:error, Copy.subscription_cancel_unavailable())
  end

  defp plan_change_unavailable(socket, subscription) do
    socket
    |> assign(:subscription, subscription)
    |> assign(:can_change_plan?, false)
    |> clear_plan_change()
    |> put_flash(:error, Copy.subscription_plan_change_preview_unavailable_body(subscription))
  end

  defp clear_plan_change(socket) do
    socket
    |> assign(:plan_change_price_id, nil)
    |> assign(:plan_change_preview, nil)
  end

  defp with_actor(socket, fun) do
    actor = socket.assigns.current_context.actor
    actor_id = Accrue.Auth.actor_id(actor) || Map.get(actor, :id) || Map.get(actor, "id")
    audit_actor = %{type: :user, id: if(is_nil(actor_id), do: nil, else: to_string(actor_id))}
    Accrue.Actor.with_actor(audit_actor, fun)
  end

  defp recovery_prompt?(%Subscription{} = subscription) do
    Subscription.past_due?(subscription) or Subscription.dunning_campaign_active?(subscription)
  end

  defp update_pm_path(base, %Subscription{processor: "braintree"}),
    do: Path.payment_methods_new(base)

  defp update_pm_path(base, %Subscription{}), do: Path.payment_methods(base)

  defp preview_plan_change(%Subscription{} = subscription, price_id) do
    normalized_price_id = normalize_price_id(price_id)

    cond do
      not BillingReadModel.subscription_plan_change_available?(subscription) ->
        {:error, :preview_unsupported}

      is_nil(normalized_price_id) ->
        {:error, :missing_reference}

      true ->
        case Billing.preview_upcoming_invoice(subscription,
               new_price_id: normalized_price_id,
               proration: :create_prorations
             ) do
          {:ok, %UpcomingInvoice{} = preview} -> {:ok, preview, normalized_price_id}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp swap_plan(%Subscription{} = subscription, price_id) do
    Billing.swap_plan(subscription, price_id, proration: :create_prorations)
  end

  defp current_plan_reference(%Subscription{} = subscription) do
    subscription
    |> primary_subscription_item()
    |> case do
      nil -> "Unavailable"
      item -> item.price_id || item.processor_id || item.id
    end
  end

  defp primary_subscription_item(%Subscription{subscription_items: [item | _]}), do: item
  defp primary_subscription_item(_subscription), do: nil

  defp normalize_price_id(price_id) when is_binary(price_id) do
    trimmed = String.trim(price_id)
    if trimmed == "", do: nil, else: trimmed
  end

  defp normalize_price_id(_price_id), do: nil

  defp push_portal_focus(socket, id),
    do: Phoenix.LiveView.push_event(socket, "portal:restore-focus", %{id: id})
end
