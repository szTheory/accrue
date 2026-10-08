defmodule AccruePortal.Live.InvoicesLive do
  use Phoenix.LiveView

  alias AccruePortal.BillingReadModel
  alias AccruePortal.Authorize
  alias AccruePortal.Copy
  alias AccruePortal.Path

  @impl true
  def mount(_params, %{"accrue_portal" => portal}, socket) do
    case Authorize.context(socket, :read) do
      {:ok, context} ->
        {:ok, invoices} = BillingReadModel.invoice_result(context.customer)

        {:ok,
         socket
         |> assign(:page_title, Copy.invoices_page_title())
         |> assign(:portal, portal)
         |> assign(:current_context, context)
         |> assign(:billing_identity, billing_identity(context))
         |> assign(:invoices, invoices)}

      {:error, _reason} ->
        {:ok,
         Phoenix.LiveView.redirect(
           socket,
           to: String.trim_trailing(portal["mount_path"], "/") <> "/blocked"
         )}
    end
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
        <p :if={@billing_identity}>
          Invoices for <strong>{@billing_identity}</strong>.
        </p>
        <div :if={@invoices == []} class="portal-empty">
          <strong>{Copy.invoices_empty_title()}</strong>
          <p>{Copy.invoices_empty_body()}</p>
        </div>
        <p :if={@invoices != []}>
          {Copy.invoices_recent_note()}
        </p>
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

  defp billing_identity(context) do
    [
      context.display_name,
      context.customer && context.customer.name,
      context.customer && context.customer.email
    ]
    |> Enum.find(fn value -> is_binary(value) and String.trim(value) != "" end)
  end
end
