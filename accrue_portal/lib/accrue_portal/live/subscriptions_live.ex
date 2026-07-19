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
      <AccruePortal.Layouts.breadcrumb trail={[
        %{label: Copy.breadcrumb_home(), href: Path.home(@base_path)},
        %{label: Copy.subscriptions_heading(), href: nil}
      ]} />
      <section class="portal-card">
        <h1>{Copy.subscriptions_heading()}</h1>
        <div :if={@subscriptions == []} class="portal-empty">
          <strong>{Copy.subscriptions_empty_title()}</strong>
          <p>{Copy.subscriptions_empty_body()}</p>
        </div>
        <ul :if={@subscriptions != []} class="portal-list">
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
                href={Path.subscriptions(@base_path) <> "/" <> subscription.id}
                class="portal-button-secondary"
              >
                {Copy.subscriptions_view_cta()}
              </a>
              <button
                :if={subscription.processor != "braintree"}
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

  defp cancel_subscription(%Subscription{} = subscription),
    do: Billing.cancel_at_period_end(subscription)

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
