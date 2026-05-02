defmodule AccruePortal.Live.CheckoutLive do
  use Phoenix.LiveView

  alias Accrue.Checkout.LocalSession
  alias AccruePortal.BraintreeClient
  alias AccruePortal.Path

  @impl true
  def mount(%{"token" => token}, %{"accrue_portal" => portal}, socket) do
    session = LocalSession.by_token(token)

    case session do
      %LocalSession{customer_id: customer_id} = checkout
      when customer_id == socket.assigns.current_customer.id ->
        client_token =
          case BraintreeClient.client_token_for(socket.assigns.current_customer) do
            {:ok, value} -> value
            {:error, _reason} -> nil
          end

        {:ok,
         socket
         |> assign(:page_title, "Checkout")
         |> assign(:portal, portal)
         |> assign(:base_path, portal["mount_path"])
         |> assign(:checkout_session, checkout)
         |> assign(:client_token, client_token)}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Checkout session not found.")
         |> redirect(to: portal["mount_path"])}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card">
        <h1>Checkout</h1>
        <p>Confirm subscription for <strong>{@checkout_session.price_id}</strong>.</p>

        <form
          :if={@client_token}
          action={Path.checkout_complete(@base_path, @checkout_session.session_token)}
          method="post"
          class="portal-hosted-fields-form"
          data-portal-hosted-fields="checkout"
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
          <button type="submit" class="portal-button-primary">Complete checkout</button>
        </form>

        <a :if={@checkout_session.cancel_url} href={@checkout_session.cancel_url} class="portal-button-secondary">
          Cancel
        </a>
      </section>
    </main>
    """
  end
end
