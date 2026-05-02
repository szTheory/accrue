defmodule AccruePortal.Live.SubscriptionsLive do
  use Phoenix.LiveView

  alias Accrue.Billing
  alias Accrue.Billing.Subscription
  alias AccruePortal.BillingReadModel

  @impl true
  def mount(_params, %{"accrue_portal" => portal}, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Subscriptions")
     |> assign(:portal, portal)
     |> assign(:subscriptions, BillingReadModel.subscriptions(socket.assigns.current_customer))}
  end

  @impl true
  def handle_event("cancel", %{"id" => id}, socket) do
    subscription =
      socket.assigns.subscriptions
      |> Enum.find(&(&1.id == id))

    case subscription do
      %Subscription{} = sub ->
        case Billing.cancel(sub) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, "Subscription canceled.")
             |> assign(
               :subscriptions,
               BillingReadModel.subscriptions(socket.assigns.current_customer)
             )}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Unable to cancel subscription.")}
        end

      nil ->
        {:noreply, put_flash(socket, :error, "Unknown subscription.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card">
        <h1>Subscriptions</h1>
        <ul class="portal-list">
          <li :for={subscription <- @subscriptions}>
            <div>
              <strong>{subscription.processor_id || subscription.id}</strong>
              <p>{subscription.status}</p>
            </div>
            <button phx-click="cancel" phx-value-id={subscription.id} class="portal-button-secondary">
              Cancel
            </button>
          </li>
        </ul>
      </section>
    </main>
    """
  end
end
