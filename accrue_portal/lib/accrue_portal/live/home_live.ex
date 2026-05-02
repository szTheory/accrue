defmodule AccruePortal.Live.HomeLive do
  use Phoenix.LiveView

  alias AccruePortal.BillingReadModel
  alias AccruePortal.Path

  @impl true
  def mount(_params, %{"accrue_portal" => portal} = _session, socket) do
    data = BillingReadModel.dashboard(socket.assigns.current_customer)

    {:ok,
     socket
     |> assign(:page_title, "Billing Portal")
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
          <p class="portal-eyebrow">Customer billing</p>
          <h1>Billing portal</h1>
          <p>Manage subscriptions, payment methods, invoices, and checkout from one mounted package.</p>
        </div>
        <nav class="portal-nav">
          <a href={Path.subscriptions(@base_path)}>Subscriptions</a>
          <a href={Path.payment_methods(@base_path)}>Payment methods</a>
          <a href={Path.invoices(@base_path)}>Invoices</a>
        </nav>
      </section>

      <section class="portal-grid">
        <article class="portal-card">
          <h2>Subscriptions</h2>
          <p class="portal-metric">{length(@dashboard.subscriptions)}</p>
        </article>
        <article class="portal-card">
          <h2>Payment methods</h2>
          <p class="portal-metric">{length(@dashboard.payment_methods)}</p>
        </article>
        <article class="portal-card">
          <h2>Invoices</h2>
          <p class="portal-metric">{length(@dashboard.invoices)}</p>
        </article>
      </section>

      <section class="portal-card">
        <h2>Recent subscriptions</h2>
        <ul class="portal-list">
          <li :for={subscription <- Enum.take(@dashboard.subscriptions, 5)}>
            <span>{subscription.status}</span>
            <span>{subscription.processor_id || subscription.id}</span>
          </li>
        </ul>
      </section>
    </main>
    """
  end
end
