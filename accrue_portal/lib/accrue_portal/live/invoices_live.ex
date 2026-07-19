defmodule AccruePortal.Live.InvoicesLive do
  use Phoenix.LiveView

  alias AccruePortal.BillingReadModel
  alias AccruePortal.Copy
  alias AccruePortal.Path

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
      <AccruePortal.Layouts.breadcrumb trail={[
        %{label: Copy.breadcrumb_home(), href: Path.home(@base_path)},
        %{label: Copy.invoices_heading(), href: nil}
      ]} />
      <section class="portal-card">
        <h1>{Copy.invoices_heading()}</h1>
        <div :if={@invoices == []} class="portal-empty">
          <strong>{Copy.invoices_empty_title()}</strong>
          <p>{Copy.invoices_empty_body()}</p>
        </div>
        <ul :if={@invoices != []} class="portal-list">
          <li :for={invoice <- @invoices}>
            <div>
              <strong>{invoice.number || invoice.processor_id || invoice.id}</strong>
              <p>
                {Copy.invoices_status_label()}:
                <span class={["portal-status", status_variant(invoice.status)]}>
                  {invoice.status}
                </span>
              </p>
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

  # Presentation-only: map an invoice status to a status-pill variant class.
  # No copy/behavior change.
  defp status_variant(:paid), do: "portal-status-active"
  defp status_variant(:uncollectible), do: "portal-status-warning"
  defp status_variant(status) when status in [:open, :draft], do: "portal-status-info"
  defp status_variant(_status), do: nil
end
