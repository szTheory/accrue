defmodule AccruePortal.Live.InvoicesLive do
  use Phoenix.LiveView

  alias AccruePortal.BillingReadModel

  @impl true
  def mount(_params, %{"accrue_portal" => portal}, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Invoices")
     |> assign(:portal, portal)
     |> assign(:invoices, BillingReadModel.invoices(socket.assigns.current_customer))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card">
        <h1>Invoices</h1>
        <ul class="portal-list">
          <li :for={invoice <- @invoices}>
            <div>
              <strong>{invoice.number || invoice.processor_id || invoice.id}</strong>
              <p>{invoice.status}</p>
            </div>
            <a :if={invoice.hosted_url} href={invoice.hosted_url} class="portal-button-secondary">Open</a>
          </li>
        </ul>
      </section>
    </main>
    """
  end
end
