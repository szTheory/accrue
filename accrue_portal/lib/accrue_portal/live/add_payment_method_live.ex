defmodule AccruePortal.Live.AddPaymentMethodLive do
  use Phoenix.LiveView

  alias AccruePortal.BraintreeClient
  alias AccruePortal.Copy
  alias AccruePortal.Path

  @impl true
  def mount(params, %{"accrue_portal" => portal}, socket) do
    context = socket.assigns.current_context
    customer = socket.assigns.current_customer
    adapter = socket.assigns[:current_context_adapter]

    {client_token, create_denied?} =
      case Accrue.Portal.Context.authorize_action(
             context,
             adapter,
             :payment_method_create,
             customer
           ) do
        :ok ->
          case BraintreeClient.client_token_for(customer) do
            {:ok, token} -> {token, false}
            {:error, _reason} -> {nil, false}
          end

        {:error, :forbidden} ->
          {nil, true}
      end

    pin =
      socket.assigns[:current_context_pin] ||
        case Accrue.Portal.Context.mint_pin(context, socket.endpoint) do
          {:ok, value} -> value
          _ -> nil
        end

    socket =
      socket
      |> assign(:page_title, Copy.add_payment_method_page_title())
      |> assign(:portal, portal)
      |> assign(:base_path, portal["mount_path"])
      |> assign(:client_token, client_token)
      |> assign(:context_pin, pin)
      |> assign(:create_denied, create_denied?)

    if is_binary(pin) and not is_binary(Map.get(params, "context_pin")) do
      send(self(), {:patch_context_pin, pin})
    end

    {:ok, socket}
  end

  @impl true
  def handle_info({:patch_context_pin, pin}, socket) do
    {:noreply,
     Phoenix.LiveView.push_patch(socket,
       to:
         Path.payment_methods_new(socket.assigns.base_path) <>
           "?context_pin=" <> URI.encode_www_form(pin)
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <AccruePortal.Layouts.breadcrumb trail={[
        %{label: Copy.breadcrumb_home(), href: Path.home(@base_path)},
        %{label: Copy.payment_methods_heading(), href: Path.payment_methods(@base_path)},
        %{label: Copy.add_payment_method_heading(), href: nil}
      ]} />
      <section class="portal-card">
        <div class="portal-stack">
          <h1>{Copy.add_payment_method_heading()}</h1>
          <p>{Copy.add_payment_method_body()}</p>
        </div>

        <form
          :if={@client_token}
          id="payment-method-form"
          action={Path.payment_methods(@base_path)}
          method="post"
          class="portal-hosted-fields-form"
          phx-hook="BraintreeHostedFields"
          data-portal-hosted-fields="payment-method"
          data-client-token={@client_token}
        >
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
          <input type="hidden" name="context_pin" value={@context_pin} />
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
            <button type="submit" class="portal-button-primary" data-checkout-submit>
              {Copy.add_payment_method_save_cta()}
            </button>
            <a href={Path.payment_methods(@base_path)} class="portal-button-secondary">
              {Copy.add_payment_method_discard_cta()}
            </a>
          </div>
        </form>

        <div :if={!@client_token} class="portal-stack" role="status" aria-live="polite">
          <p :if={@create_denied}>{Copy.payment_method_create_denied()}</p>
          <p :if={!@create_denied}>{Copy.checkout_missing_nonce_error()}</p>
          <a href={Path.payment_methods(@base_path)} class="portal-button-secondary">
            {Copy.add_payment_method_discard_cta()}
          </a>
        </div>
      </section>
    </main>
    """
  end
end
