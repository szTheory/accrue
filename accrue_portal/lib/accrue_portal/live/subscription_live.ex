defmodule AccruePortal.Live.SubscriptionLive do
  use Phoenix.LiveView

  alias Accrue.Billing
  alias Accrue.Billing.Subscription
  alias AccruePortal.Authorize
  alias AccruePortal.Copy
  alias AccruePortal.Path

  @impl true
  def mount(%{"id" => id}, %{"accrue_portal" => portal}, socket) do
    case Authorize.subscription(socket, id) do
      {:ok, %Subscription{} = subscription} ->
        {:ok,
         socket
         |> assign(:page_title, Copy.subscription_page_title())
         |> assign(:portal, portal)
         |> assign(:base_path, portal["mount_path"])
         |> assign(:subscription, subscription)
         |> assign(:show_cancel_confirmation, false)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> assign(:page_title, Copy.subscription_not_found_title())
         |> assign(:portal, portal)
         |> assign(:base_path, portal["mount_path"])
         |> assign(:subscription, nil)
         |> assign(:show_cancel_confirmation, false)}
    end
  end

  @impl true
  def handle_event("toggle_cancel_confirmation", _params, socket) do
    {:noreply, update(socket, :show_cancel_confirmation, &(!&1))}
  end

  def handle_event(
        "cancel",
        _params,
        %{assigns: %{subscription: %Subscription{} = subscription}} = socket
      ) do
    case Authorize.subscription(socket, subscription.id) do
      {:ok, %Subscription{} = scoped_subscription} ->
        case Billing.cancel_at_period_end(scoped_subscription) do
          {:ok, updated} ->
            {:noreply,
             socket
             |> assign(:subscription, updated)
             |> assign(:show_cancel_confirmation, false)
             |> put_flash(:info, Copy.subscription_cancel_success())}

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, Copy.subscription_cancel_error())}
        end

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, Copy.subscriptions_unknown_error())}
    end
  end

  def handle_event("cancel", _params, socket), do: {:noreply, socket}

  @impl true
  def render(%{subscription: nil} = assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card">
        <h1>{Copy.subscription_not_found_title()}</h1>
        <p>{Copy.subscription_not_found_body()}</p>
        <a href={Path.home(@base_path)}>{Copy.subscription_back_home_cta()}</a>
      </section>
    </main>
    """
  end

  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card">
        <h1>{Copy.subscription_heading()}</h1>
        <ul class="portal-list">
          <li>
            <strong>{Copy.subscription_identifier_label()}</strong>
            <span>{@subscription.processor_id || @subscription.id}</span>
          </li>
          <li>
            <strong>{Copy.subscription_status_label()}</strong>
            <span>{Copy.subscription_lifecycle_label(@subscription)}</span>
          </li>
          <li>
            <strong>{Copy.subscription_summary_label()}</strong>
            <span>{Copy.subscription_lifecycle_summary(@subscription)}</span>
          </li>
          <li>
            <strong>{Copy.subscription_period_end_label()}</strong>
            <span>{format_datetime(@subscription.current_period_end)}</span>
          </li>
        </ul>
      </section>

      <section class="portal-card">
        <h2>{Copy.subscription_cancel_heading()}</h2>
        <p>{Copy.subscription_cancel_body()}</p>
        <p>{Copy.subscription_access_timing(@subscription)}</p>
        <div :if={!@show_cancel_confirmation}>
          <button phx-click="toggle_cancel_confirmation" class="portal-button-secondary">
            {Copy.subscription_cancel_cta()}
          </button>
        </div>
        <div :if={@show_cancel_confirmation}>
          <button phx-click="cancel" class="portal-button-secondary">
            {Copy.subscription_cancel_cta()}
          </button>
          <button phx-click="toggle_cancel_confirmation" class="portal-button-secondary">
            {Copy.subscription_keep_cta()}
          </button>
        </div>
      </section>
    </main>
    """
  end

  defp format_datetime(nil), do: "-"
  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d")
end
