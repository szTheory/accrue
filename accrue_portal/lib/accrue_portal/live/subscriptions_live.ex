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
    {:ok,
     socket
     |> assign(:page_title, Copy.subscriptions_page_title())
     |> assign(:portal, portal)
     |> assign(:base_path, portal["mount_path"])
     |> assign(:subscriptions, BillingReadModel.subscriptions(socket.assigns.current_customer))}
  end

  @impl true
  def handle_event("cancel", %{"id" => id}, socket) do
    case Authorize.subscription(socket, id) do
      {:ok, %Subscription{} = sub} ->
        case cancel_subscription(sub) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, Copy.subscriptions_cancel_success(sub))
             |> assign(
               :subscriptions,
               BillingReadModel.subscriptions(socket.assigns.current_customer)
             )}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, Copy.subscriptions_cancel_error(sub))}
        end

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, Copy.subscriptions_unknown_error())}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card">
        <h1>{Copy.subscriptions_heading()}</h1>
        <div :if={@subscriptions == []}>
          <strong>{Copy.subscriptions_empty_title()}</strong>
          <p>{Copy.subscriptions_empty_body()}</p>
        </div>
        <ul :if={@subscriptions != []} class="portal-list">
          <li :for={subscription <- @subscriptions}>
            <div>
              <strong>{subscription.processor_id || subscription.id}</strong>
              <p>{Copy.subscriptions_status_label()}: {Copy.subscription_lifecycle_label(subscription)}</p>
              <p>{Copy.subscriptions_summary_label()}: {Copy.subscription_lifecycle_summary(subscription)}</p>
              <p>{Copy.subscription_access_timing(subscription)}</p>
            </div>
            <div>
              <a href={Path.subscriptions(@base_path) <> "/" <> subscription.id}>
                {Copy.subscriptions_view_cta()}
              </a>
              <button
                phx-click="cancel"
                phx-value-id={subscription.id}
                class="portal-button-secondary"
              >
                {Copy.subscription_cancel_cta(subscription)}
              </button>
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
end
