defmodule AccruePortal.Live.InvoicesLive do
  use Phoenix.LiveView

  alias AccruePortal.BillingReadModel
  alias AccruePortal.Copy

  @impl true
  def mount(_params, %{"accrue_portal" => portal}, socket) do
    {:ok,
     socket
     |> assign(:page_title, Copy.invoices_page_title())
     |> assign(:portal, portal)
     |> assign(:invoices, BillingReadModel.invoices(socket.assigns.current_customer))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card">
        <h1>{Copy.invoices_heading()}</h1>
        <div :if={@invoices == []} class="portal-stack">
          <strong>{Copy.invoices_empty_title()}</strong>
          <p>{Copy.invoices_empty_body()}</p>
        </div>
        <ul :if={@invoices != []} class="portal-list">
          <li :for={invoice <- @invoices}>
            <div>
              <strong>{invoice.number || invoice.processor_id || invoice.id}</strong>
              <p>{Copy.invoices_status_label()}: {invoice.status}</p>
            </div>
            <a :if={invoice.hosted_url} href={invoice.hosted_url} class="portal-button-secondary">
              {Copy.invoices_open_cta()}
            </a>
          </li>
        </ul>
      </section>
    </main>
    """
  end
end
