defmodule AccruePortal.Live.PaymentMethodsLive do
  use Phoenix.LiveView

  alias AccruePortal.BillingReadModel
  alias AccruePortal.BraintreeClient
  alias AccruePortal.Path

  @impl true
  def mount(_params, %{"accrue_portal" => portal}, socket) do
    client_token =
      case BraintreeClient.client_token_for(socket.assigns.current_customer) do
        {:ok, token} -> token
        {:error, _reason} -> nil
      end

    {:ok,
     socket
     |> assign(:page_title, "Payment Methods")
     |> assign(:portal, portal)
     |> assign(:base_path, portal["mount_path"])
     |> assign(:client_token, client_token)
     |> assign(
       :payment_methods,
       BillingReadModel.payment_methods(socket.assigns.current_customer)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card">
        <h1>Payment methods</h1>
        <ul class="portal-list">
          <li :for={payment_method <- @payment_methods}>
            <div>
              <strong>{payment_method.card_brand || "Card"} ending in {payment_method.card_last4}</strong>
              <p :if={payment_method.id == @current_customer.default_payment_method_id}>Default</p>
            </div>
            <div class="portal-actions">
              <form action={Path.payment_method_default(@base_path, payment_method.id)} method="post">
                <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
                <button type="submit" class="portal-button-secondary">Set default</button>
              </form>
              <form action={Path.payment_method_delete(@base_path, payment_method.id)} method="post">
                <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
                <button type="submit" class="portal-button-secondary">Delete</button>
              </form>
            </div>
          </li>
        </ul>
      </section>

      <section class="portal-card" :if={@client_token}>
        <h2>Add payment method</h2>
        <form
          action={Path.payment_methods(@base_path)}
          method="post"
          class="portal-hosted-fields-form"
          data-portal-hosted-fields="payment-method"
          data-client-token={@client_token}
        >
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
          <input type="hidden" name="payment_method_nonce" value="" data-braintree-nonce-input />
          <div class="portal-hosted-grid">
            <label>
              Card number
              <div class="portal-hosted-field" data-braintree-field="number"></div>
            </label>
            <label>
              Expiration
              <div class="portal-hosted-field" data-braintree-field="expirationDate"></div>
            </label>
            <label>
              CVV
              <div class="portal-hosted-field" data-braintree-field="cvv"></div>
            </label>
          </div>
          <p class="portal-help" data-braintree-error></p>
          <button type="submit" class="portal-button-primary">Save payment method</button>
        </form>
      </section>
    </main>
    """
  end
end
