defmodule AccruePortal.Live.AddPaymentMethodLive do
  use Phoenix.LiveView

  alias AccruePortal.BraintreeClient
  alias AccruePortal.Copy
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
     |> assign(:page_title, Copy.add_payment_method_page_title())
     |> assign(:portal, portal)
     |> assign(:base_path, portal["mount_path"])
     |> assign(:client_token, client_token)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <section class="portal-card">
        <div class="portal-stack">
          <h1>{Copy.add_payment_method_heading()}</h1>
          <p>{Copy.add_payment_method_body()}</p>
        </div>

        <form
          :if={@client_token}
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
              {Copy.add_payment_method_card_number_label()}
              <div class="portal-hosted-field" data-braintree-field="number"></div>
            </label>
            <label>
              {Copy.add_payment_method_expiration_label()}
              <div class="portal-hosted-field" data-braintree-field="expirationDate"></div>
            </label>
            <label>
              {Copy.add_payment_method_cvv_label()}
              <div class="portal-hosted-field" data-braintree-field="cvv"></div>
            </label>
          </div>
          <p class="portal-help" data-braintree-error></p>
          <div class="portal-actions">
            <button type="submit" class="portal-button-primary">
              {Copy.add_payment_method_save_cta()}
            </button>
            <a href={Path.payment_methods(@base_path)} class="portal-button-secondary">
              {Copy.add_payment_method_discard_cta()}
            </a>
          </div>
        </form>

        <div :if={!@client_token} class="portal-stack">
          <p>{Copy.checkout_missing_nonce_error()}</p>
          <a href={Path.payment_methods(@base_path)} class="portal-button-secondary">
            {Copy.add_payment_method_discard_cta()}
          </a>
        </div>
      </section>
    </main>
    """
  end
end
