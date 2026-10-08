defmodule AccruePortal.Live.HomeLive do
  use Phoenix.LiveView

  alias AccruePortal.BillingReadModel
  alias AccruePortal.Copy
  alias AccruePortal.Path

  @impl true
  def mount(_params, %{"accrue_portal" => portal} = _session, socket) do
    data = BillingReadModel.dashboard(socket.assigns.current_customer)
    {subscriptions_available?, subscription_rows} = subscription_rows(data.subscriptions)

    {:ok,
     socket
     |> assign(:page_title, Copy.home_page_title())
     |> assign(:portal, portal)
     |> assign(:base_path, portal["mount_path"])
     |> assign(:subscriptions_available?, subscriptions_available?)
     |> assign(:subscription_rows, subscription_rows)
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
          <a
            class="portal-button-primary"
            href={Path.context(Path.subscriptions(@base_path), @current_context_pin)}
          >
            {Copy.home_manage_subscriptions_cta()}
          </a>
          <a
            class="portal-button-secondary"
            href={Path.context(Path.payment_methods(@base_path), @current_context_pin)}
          >
            {Copy.home_manage_payment_methods_cta()}
          </a>
          <a
            class="portal-button-secondary"
            href={Path.context(Path.invoices(@base_path), @current_context_pin)}
          >
            {Copy.home_manage_invoices_cta()}
          </a>
        </nav>
      </section>

      <section class="portal-grid">
        <.dashboard_metric
          label={Copy.home_subscription_count_label()}
          outcome={@dashboard.subscriptions}
        />
        <.dashboard_metric
          label={Copy.home_payment_method_count_label()}
          outcome={@dashboard.payment_methods}
        />
        <.dashboard_metric
          label={Copy.home_invoice_count_label()}
          note={Copy.home_invoice_count_note()}
          outcome={@dashboard.invoices}
        />
      </section>

      <section class="portal-card">
        <h2>{Copy.home_recent_subscriptions_heading()}</h2>
        <div :if={@subscriptions_available? && @subscription_rows == []} class="portal-empty">
          <strong>{Copy.home_empty_title()}</strong>
          <p>{Copy.home_empty_body()}</p>
          <a href={Path.context(Path.subscriptions(@base_path), @current_context_pin)}>
            {Copy.home_manage_subscriptions_cta()}
          </a>
        </div>
        <ul
          :if={@subscriptions_available? && @subscription_rows != []}
          class="portal-list"
        >
          <li :for={subscription <- Enum.take(@subscription_rows, 5)}>
            <div class="portal-list-primary">
              <strong>{subscription.processor_id || subscription.id}</strong>
              <p>
                {Copy.home_status_prefix()}:
                <span class={["portal-status", status_variant(subscription.status)]}>
                  {subscription.status}
                </span>
              </p>
            </div>
            <a href={Path.context(Path.subscriptions(@base_path), @current_context_pin)}>
              {Copy.home_manage_subscriptions_cta()}
            </a>
          </li>
        </ul>
        <div :if={!@subscriptions_available?} class="portal-empty portal-empty-unavailable" role="status">
          <strong>Subscriptions unavailable</strong>
          <p>{Copy.home_dashboard_unavailable()}</p>
        </div>
      </section>
    </main>
    """
  end

  attr(:label, :string, required: true)
  attr(:outcome, :any, required: true)
  attr(:note, :string, default: nil)

  defp dashboard_metric(assigns) do
    ~H"""
    <article class="portal-card" data-dashboard-metric={metric_key(@label)}>
      <h2 class="portal-metric-label">{@label}</h2>
      <p :if={is_list(read_rows(@outcome))} class="portal-metric">
        {length(read_rows(@outcome))}
      </p>
      <p :if={not is_list(read_rows(@outcome))} class="portal-metric portal-metric-unavailable" role="status">
        Unavailable
      </p>
      <p :if={@note} class="portal-metric-note">{@note}</p>
    </article>
    """
  end

  defp read_rows({:ok, rows}) when is_list(rows), do: rows
  defp read_rows(_outcome), do: :unavailable

  defp subscription_rows({:ok, rows}) when is_list(rows), do: {true, rows}
  defp subscription_rows(_outcome), do: {false, []}

  defp metric_key(label) do
    label
    |> String.downcase()
    |> String.replace(~r/[^a-z]+/, "-")
    |> String.trim("-")
  end

  # Presentation-only: map a subscription lifecycle status to a status-pill
  # variant class. No copy/behavior change.
  defp status_variant(status) when status in [:active, :trialing], do: "portal-status-active"

  defp status_variant(status) when status in [:past_due, :unpaid, :incomplete],
    do: "portal-status-warning"

  defp status_variant(_status), do: "portal-status-info"
end
