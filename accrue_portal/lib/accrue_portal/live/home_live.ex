defmodule AccruePortal.Live.HomeLive do
  use Phoenix.LiveView

  alias AccruePortal.BillingReadModel
  alias AccruePortal.Copy
  alias AccruePortal.Path

  @impl true
  def mount(_params, %{"accrue_portal" => portal} = _session, socket) do
    data = BillingReadModel.dashboard(socket.assigns.current_customer)

    {:ok,
     socket
     |> assign(:page_title, Copy.home_page_title())
     |> assign(:portal, portal)
     |> assign(:base_path, portal["mount_path"])
     |> assign(:dashboard, data)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card portal-hero">
        <div>
          <p class="portal-eyebrow">{Copy.home_eyebrow()}</p>
          <h1>{Copy.home_heading()}</h1>
          <p>{Copy.home_body()}</p>
        </div>
        <nav class="portal-nav">
          <a href={Path.subscriptions(@base_path)}>{Copy.home_manage_subscriptions_cta()}</a>
          <a href={Path.payment_methods(@base_path)}>{Copy.home_manage_payment_methods_cta()}</a>
          <a href={Path.invoices(@base_path)}>{Copy.home_manage_invoices_cta()}</a>
        </nav>
      </section>

      <section class="portal-grid">
        <article class="portal-card">
          <h2 class="portal-metric-label">{Copy.home_subscription_count_label()}</h2>
          <p class="portal-metric">{length(@dashboard.subscriptions)}</p>
        </article>
        <article class="portal-card">
          <h2 class="portal-metric-label">{Copy.home_payment_method_count_label()}</h2>
          <p class="portal-metric">{length(@dashboard.payment_methods)}</p>
        </article>
        <article class="portal-card">
          <h2 class="portal-metric-label">{Copy.home_invoice_count_label()}</h2>
          <p class="portal-metric">{length(@dashboard.invoices)}</p>
        </article>
      </section>

      <section class="portal-card">
        <h2>{Copy.home_recent_subscriptions_heading()}</h2>
        <div :if={@dashboard.subscriptions == []} class="portal-empty">
          <strong>{Copy.home_empty_title()}</strong>
          <p>{Copy.home_empty_body()}</p>
        </div>
        <ul :if={@dashboard.subscriptions != []} class="portal-list">
          <li :for={subscription <- Enum.take(@dashboard.subscriptions, 5)}>
            <div>
              <strong>{subscription.processor_id || subscription.id}</strong>
              <p>
                {Copy.home_status_prefix()}:
                <span class={["portal-status", status_variant(subscription.status)]}>
                  {subscription.status}
                </span>
              </p>
            </div>
            <a href={Path.subscriptions(@base_path)}>{Copy.home_manage_subscriptions_cta()}</a>
          </li>
        </ul>
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
end
