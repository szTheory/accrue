defmodule AccruePortal.Live.SubscriptionsLive do
  use Phoenix.LiveView

  alias Accrue.Billing
  alias Accrue.Billing.Subscription
  alias AccruePortal.Authorize
  alias AccruePortal.BillingReadModel
  alias AccruePortal.Copy
  alias AccruePortal.Path

  @impl true
  def mount(_params, %{"accrue_portal" => portal}, socket) do
    context = socket.assigns.current_context
    customer = socket.assigns.current_customer

    {:ok,
     socket
     |> assign(:page_title, Copy.subscriptions_page_title())
     |> assign(:portal, portal)
     |> assign(:base_path, portal["mount_path"])
     |> assign(:billed_identity, billed_identity(context, customer))
     |> assign(:cancel_confirmation_id, nil)
     |> assign(:action_notice, nil)
     |> assign_subscription_result(BillingReadModel.subscription_result(customer))}
  end

  @impl true
  def handle_event("toggle_cancel_confirmation", %{"id" => id}, socket) do
    case Authorize.subscription(socket, id, :subscription_cancel) do
      {:ok, %Subscription{} = subscription} ->
        if BillingReadModel.subscription_cancel_available?(subscription) do
          confirmation_id =
            if socket.assigns.cancel_confirmation_id == id, do: nil, else: id

          {:noreply, assign(socket, :cancel_confirmation_id, confirmation_id)}
        else
          {:noreply, cancel_unavailable(socket)}
        end

      {:error, :not_found} ->
        {:noreply, cancel_unavailable(socket)}

      {:error, _reason} ->
        {:noreply, denied(socket)}
    end
  end

  def handle_event(
        "cancel",
        %{"id" => id},
        %{assigns: %{cancel_confirmation_id: id}} = socket
      ) do
    case Authorize.subscription(socket, id, :subscription_cancel) do
      {:ok, %Subscription{} = subscription} ->
        if BillingReadModel.subscription_cancel_available?(subscription) do
          case with_actor(socket, fn -> cancel_subscription(subscription) end) do
            {:ok, _updated} ->
              {:noreply,
               socket
               |> assign(:cancel_confirmation_id, nil)
               |> assign(:action_notice, Copy.subscriptions_cancel_success(subscription))
               |> put_flash(:info, Copy.subscriptions_cancel_success(subscription))
               |> assign_subscription_result(
                 BillingReadModel.subscription_result(socket.assigns.current_customer)
               )}

            {:error, _reason} ->
              {:noreply,
               socket
               |> assign(:cancel_confirmation_id, nil)
               |> assign(:action_notice, Copy.subscriptions_cancel_error(subscription))
               |> put_flash(:error, Copy.subscriptions_cancel_error(subscription))}
          end
        else
          {:noreply, cancel_unavailable(socket)}
        end

      {:error, _reason} ->
        {:noreply, denied(socket)}
    end
  end

  def handle_event("cancel", _params, socket),
    do: {:noreply, put_flash(socket, :error, Copy.subscription_cancel_requires_confirmation())}

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <AccruePortal.Layouts.breadcrumb trail={[
        %{label: Copy.breadcrumb_home(), href: Path.context(Path.home(@base_path), @current_context_pin)},
        %{label: Copy.subscriptions_heading(), href: nil}
      ]} />
      <section class="portal-card">
        <h1>{Copy.subscriptions_heading()}</h1>
        <p :if={@action_notice} class="portal-inline-status" role="status" aria-live="polite">
          {@action_notice}
        </p>
        <div :if={!@subscriptions_available?} class="portal-inline-error" role="alert">
          <strong>{Copy.subscriptions_unavailable_title()}</strong>
          <p>{Copy.subscriptions_unavailable_body()}</p>
        </div>
        <div :if={@subscriptions_available? && @subscriptions == []} class="portal-empty">
          <strong>{Copy.subscriptions_empty_title()}</strong>
          <p>{Copy.subscriptions_empty_body()}</p>
        </div>
        <ul :if={@subscriptions_available? && @subscriptions != []} class="portal-list">
          <li :for={subscription <- @subscriptions}>
            <div>
              <strong>{subscription.processor_id || subscription.id}</strong>
              <p>
                {Copy.subscriptions_status_label()}:
                <span class={["portal-status", status_variant(subscription.status)]}>
                  {Copy.subscription_lifecycle_label(subscription)}
                </span>
              </p>
              <p>{Copy.subscriptions_summary_label()}: {Copy.subscription_lifecycle_summary(subscription)}</p>
              <p>{Copy.subscription_access_timing(subscription)}</p>
              <p>
                {plan_change_summary(subscription)}
              </p>
            </div>
            <div class="portal-actions">
              <a
        href={Path.context(Path.subscriptions(@base_path) <> "/" <> subscription.id, @current_context_pin)}
                class="portal-button-secondary"
              >
                {Copy.subscriptions_view_cta()}
              </a>
              <div :if={BillingReadModel.subscription_cancel_available?(subscription)}>
                <p>{Copy.subscription_cancel_body(subscription)}</p>
                <button
                  :if={@cancel_confirmation_id != subscription.id}
                  phx-click="toggle_cancel_confirmation"
                  phx-value-id={subscription.id}
                  class="portal-button-secondary"
                >
                  {Copy.subscription_cancel_cta(subscription)}
                </button>
                <div :if={@cancel_confirmation_id == subscription.id} role="group">
                  <p>
                    {Copy.subscription_cancel_confirmation(
                      @billed_identity,
                      subscription.processor_id || subscription.id
                    )}
                  </p>
                  <button
                    phx-click="cancel"
                    phx-value-id={subscription.id}
                    class="portal-button-secondary"
                  >
                    {Copy.subscription_cancel_cta(subscription)}
                  </button>
                  <button
                    phx-click="toggle_cancel_confirmation"
                    phx-value-id={subscription.id}
                    class="portal-button-secondary"
                  >
                    {Copy.subscription_keep_cta()}
                  </button>
                </div>
              </div>
            </div>
          </li>
        </ul>
      </section>
    </main>
    """
  end

  defp cancel_subscription(%Subscription{processor: "braintree"} = subscription),
    do: Billing.cancel(subscription)

  defp cancel_subscription(%Subscription{} = subscription),
    do: Billing.cancel_at_period_end(subscription)

  defp assign_subscription_result(socket, {:ok, subscriptions}) do
    socket
    |> assign(:subscriptions_available?, true)
    |> assign(:subscriptions, subscriptions)
  end

  defp assign_subscription_result(socket, {:error, _reason}) do
    socket
    |> assign(:subscriptions_available?, false)
    |> assign(:subscriptions, [])
  end

  defp billed_identity(context, customer) do
    context.display_name || customer.name || customer.email || "this account"
  end

  defp cancel_unavailable(socket) do
    socket
    |> assign(:cancel_confirmation_id, nil)
    |> assign(:action_notice, Copy.subscription_cancel_unavailable())
    |> put_flash(:error, Copy.subscription_cancel_unavailable())
  end

  defp denied(socket) do
    message = "Your change was not submitted because billing access is unavailable."

    socket
    |> assign(:cancel_confirmation_id, nil)
    |> assign(:action_notice, message)
    |> put_flash(:error, message)
  end

  defp with_actor(socket, fun) do
    actor = socket.assigns.current_context.actor
    actor_id = Accrue.Auth.actor_id(actor) || Map.get(actor, :id) || Map.get(actor, "id")
    audit_actor = %{type: :user, id: if(is_nil(actor_id), do: nil, else: to_string(actor_id))}
    Accrue.Actor.with_actor(audit_actor, fun)
  end

  defp plan_change_summary(%Subscription{processor: "braintree"} = subscription),
    do: Copy.subscriptions_plan_change_host_managed(subscription)

  defp plan_change_summary(%Subscription{}),
    do: Copy.subscriptions_plan_change_ready()

  # Presentation-only: map a subscription lifecycle status to a status-pill
  # variant class. No copy/behavior change.
  defp status_variant(status) when status in [:active, :trialing], do: "portal-status-active"

  defp status_variant(status) when status in [:past_due, :unpaid, :incomplete],
    do: "portal-status-warning"

  defp status_variant(_status), do: "portal-status-info"
end
