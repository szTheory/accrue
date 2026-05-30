defmodule AccruePortal.Live.CheckoutLive do
  use Phoenix.LiveView

  require Logger

  alias Accrue.Billing
  alias Accrue.Checkout.LocalSession
  alias Accrue.Error.DiscountMappingInvalid
  alias Accrue.Portal.Checkout.CompletionJob
  alias AccruePortal.BraintreeClient
  alias AccruePortal.Copy

  @client_script_src "https://js.braintreegateway.com/web/3.132.0/js/client.min.js"
  @client_script_sri "sha384-rNv6rxT4CpVv9Kb8luV4l/GpBwbhHTmZxWbI74/LX+ShrJzh/b9AL7nynSmHDpRC"
  @hosted_fields_script_src "https://js.braintreegateway.com/web/3.132.0/js/hosted-fields.min.js"
  @hosted_fields_script_sri "sha384-QAzc9uX3XQPGzTESbnMNOUn9hY9jVL/L10Eq3Gxt4NKXIZZWzGlhnEscA3iGj8Jp"

  @impl true
  def mount(%{"token" => token}, %{"accrue_portal" => portal}, socket) do
    session = LocalSession.by_token(token)

    case session do
      %LocalSession{customer_id: customer_id} = checkout
      when customer_id == socket.assigns.current_customer.id ->
        client_token =
          case checkout_ready?(checkout) &&
                 BraintreeClient.client_token_for(socket.assigns.current_customer) do
            {:ok, value} -> value
            _ -> nil
          end

        {:ok,
         socket
         |> assign_checkout_pricing(checkout)
         |> assign(:page_title, Copy.checkout_page_title())
         |> assign(:portal, portal)
         |> assign(:base_path, portal["mount_path"])
         |> assign(:checkout_session, checkout)
         |> assign(:client_token, client_token)
         |> assign(:checkout_error, nil)
         |> assign(:checkout_success, false)
         |> assign(:promotion_code, nil)
         |> assign(:promotion_code_input, "")
         |> assign(:promo_status, nil)
         |> assign(:promo_preview, nil)
         |> assign(:client_script_src, @client_script_src)
         |> assign(:client_script_sri, @client_script_sri)
         |> assign(:hosted_fields_script_src, @hosted_fields_script_src)
         |> assign(:hosted_fields_script_sri, @hosted_fields_script_sri)}

      _ ->
        {:ok,
         socket
         |> redirect(to: portal["mount_path"])}
    end
  end

  # Fallback: "accrue_portal" session key absent (misconfigured router,
  # expired session after deploy, or direct navigation outside live_session).
  # Redirect to root rather than raising FunctionClauseError.
  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: "/")}
  end

  @impl true
  def handle_event("checkout_tokenized", %{"nonce" => nonce}, socket)
      when is_binary(nonce) and nonce != "" do
    checkout = socket.assigns.checkout_session

    if checkout_ready?(checkout) do
      case subscribe_with_checkout(socket, checkout, nonce) do
        {:ok, subscription} ->
          {:ok, _session} = LocalSession.mark_completed(checkout)
          maybe_enqueue_completion(checkout, subscription)

          case checkout.success_url do
            url when is_binary(url) and url != "" ->
              {:noreply, redirect(socket, external: url)}

            _ ->
              {:noreply,
               socket
               |> assign(:checkout_error, nil)
               |> assign(:checkout_success, true)}
          end

        {:error, %DiscountMappingInvalid{}} ->
          {:noreply,
           socket
           |> assign(:checkout_error, nil)
           |> assign(:checkout_success, false)
           |> assign(:promo_preview, nil)
           |> assign(:promo_status, Copy.checkout_promo_temporarily_unavailable())
           |> assign_base_checkout_amount()}

        {:error, reason}
        when reason in [:not_found, :inactive, :expired, :max_redemptions_reached] ->
          {:noreply,
           socket
           |> assign(:checkout_error, nil)
           |> assign(:checkout_success, false)
           |> assign(:promotion_code, nil)
           |> assign(:promo_preview, nil)
           |> assign(:promo_status, Copy.checkout_promo_invalid())
           |> assign_base_checkout_amount()}

        {:error, _reason} ->
          {:noreply,
           socket
           |> assign(:checkout_error, Copy.checkout_subscription_error())
           |> assign(:checkout_success, false)}
      end
    else
      {:noreply, assign_expired_error(socket)}
    end
  end

  def handle_event("checkout_tokenized", _params, socket) do
    {:noreply, assign(socket, :checkout_error, Copy.checkout_missing_nonce_error())}
  end

  def handle_event("validate_promo", %{"promo" => %{"code" => code}}, socket) do
    checkout = socket.assigns.checkout_session
    trimmed_code = String.trim(code)

    cond do
      not checkout_ready?(checkout) ->
        {:noreply, assign_expired_error(socket)}

      trimmed_code == "" ->
        {:noreply,
         socket
         |> assign(:promotion_code, nil)
         |> assign(:promotion_code_input, "")
         |> assign(:promo_preview, nil)
         |> assign(:promo_status, nil)
         |> assign_base_checkout_amount()}

      true ->
        case Billing.resolve_discount_mapping(trimmed_code, socket.assigns.base_amount_minor) do
          {:ok, %{amount_off_minor: amount_off_minor, estimated_total_minor: total_minor}} ->
            {:noreply,
             socket
             |> assign(:promotion_code, trimmed_code)
             |> assign(:promotion_code_input, trimmed_code)
             |> assign(:promo_status, Copy.checkout_promo_ready())
             |> assign(:promo_preview, %{
               amount_off: format_minor_amount(amount_off_minor),
               estimated_total: format_minor_amount(total_minor)
             })
             |> assign(:checkout_amount, format_minor_amount(total_minor))}

          {:error, %DiscountMappingInvalid{}} ->
            {:noreply,
             socket
             |> assign(:promotion_code, nil)
             |> assign(:promotion_code_input, trimmed_code)
             |> assign(:promo_preview, nil)
             |> assign(:promo_status, Copy.checkout_promo_temporarily_unavailable())
             |> assign_base_checkout_amount()}

          {:error, _reason} ->
            {:noreply,
             socket
             |> assign(:promotion_code, nil)
             |> assign(:promotion_code_input, trimmed_code)
             |> assign(:promo_preview, nil)
             |> assign(:promo_status, Copy.checkout_promo_invalid())
             |> assign_base_checkout_amount()}
        end
    end
  end

  def handle_event("checkout_failed", %{"message" => message}, socket) do
    {:noreply,
     socket
     |> assign(:checkout_error, Copy.checkout_card_error(message))
     |> assign(:checkout_success, false)}
  end

  def handle_event("checkout_failed", _params, socket) do
    {:noreply,
     socket
     |> assign(:checkout_error, Copy.checkout_card_error(nil))
     |> assign(:checkout_success, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="portal-shell">
      <script src={@client_script_src} integrity={@client_script_sri} crossorigin="anonymous"></script>
      <script
        src={@hosted_fields_script_src}
        integrity={@hosted_fields_script_sri}
        crossorigin="anonymous"
      >
      </script>

      <section class="portal-card portal-card-checkout">
        <p class="portal-eyebrow">Secure checkout</p>
        <h1>{Copy.checkout_heading()}</h1>
        <p :if={not @checkout_success}>
          Confirm subscription for <strong>{@checkout_session.price_id}</strong>.
        </p>
        <p :if={@checkout_success} class="portal-success-copy">Subscription created.</p>

        <div
          :if={@checkout_error}
          class="portal-inline-error"
          role="alert"
          data-checkout-error
        >
          <p>{@checkout_error}</p>
          <p :if={@checkout_error != Copy.checkout_subscription_error()}>
            {Copy.checkout_retry_help()}
          </p>
        </div>

        <div :if={not checkout_ready?(@checkout_session)} class="portal-inline-error" role="alert">
          <p>{Copy.checkout_session_expired_title()}</p>
          <p>{Copy.checkout_session_expired_body()}</p>
        </div>

        <form
          :if={@client_token && checkout_ready?(@checkout_session) && !@checkout_success}
          id="promo-code-form"
          phx-change="validate_promo"
          class="portal-promo-form"
        >
          <label class="portal-hosted-label" for="promo-code-input">
            <span>{Copy.checkout_promo_label()}</span>
          </label>
          <input
            id="promo-code-input"
            type="text"
            name="promo[code]"
            value={@promotion_code_input}
            autocomplete="off"
          />
          <p class="portal-help">{Copy.checkout_promo_hint()}</p>
          <div id="promo-status" role="status" aria-live="polite">
            <p :if={@promo_status}>{@promo_status}</p>
            <p :if={@promo_preview}>{Copy.checkout_discount_amount_label(@promo_preview.amount_off)}</p>
            <p :if={@promo_preview}>{Copy.checkout_estimated_total_label(@promo_preview.estimated_total)}</p>
            <p :if={@promo_preview} class="portal-help">{Copy.checkout_promo_preview_notice()}</p>
          </div>
        </form>

        <form
          :if={@client_token && checkout_ready?(@checkout_session) && !@checkout_success}
          id="checkout-form"
          phx-hook="BraintreeHostedFields"
          phx-submit="checkout_submit"
          class="portal-hosted-fields-form"
          data-portal-hosted-fields="checkout"
          data-client-token={@client_token}
        >
          <div class="portal-hosted-grid">
            <label class="portal-hosted-label">
              <span>Card number</span>
              <div class="portal-hosted-field" data-braintree-field="number"></div>
            </label>
            <label class="portal-hosted-label">
              <span>Expiration</span>
              <div class="portal-hosted-field" data-braintree-field="expirationDate"></div>
            </label>
            <label class="portal-hosted-label">
              <span>CVV</span>
              <div class="portal-hosted-field" data-braintree-field="cvv"></div>
            </label>
          </div>
          <p class="portal-help" data-braintree-error></p>
          <div class="portal-checkout-actions">
            <button
              type="submit"
              class="portal-button-primary"
              data-checkout-submit
              data-label-processing={Copy.checkout_processing_cta()}
            >
              {Copy.checkout_pay_cta(@checkout_amount)}
            </button>
            <a
              :if={@checkout_session.cancel_url}
              href={@checkout_session.cancel_url}
              class="portal-button-secondary"
            >
              {Copy.checkout_leave_cta()}
            </a>
          </div>
        </form>

        <a
          :if={(!@client_token || !checkout_ready?(@checkout_session)) && @checkout_session.cancel_url}
          href={@checkout_session.cancel_url}
          class="portal-button-secondary"
        >
          {Copy.checkout_leave_cta()}
        </a>
      </section>
    </main>
    """
  end

  defp assign_checkout_pricing(socket, %LocalSession{} = checkout) do
    amount_minor = checkout_amount_minor(checkout)
    amount_text = format_minor_amount(amount_minor)

    socket
    |> assign(:base_amount_minor, amount_minor)
    |> assign(:base_checkout_amount, amount_text)
    |> assign(:checkout_amount, amount_text)
  end

  defp assign_base_checkout_amount(socket) do
    assign(socket, :checkout_amount, socket.assigns.base_checkout_amount)
  end

  defp subscribe_with_checkout(socket, checkout, nonce) do
    subscribe_opts = [
      payment_method: %{vault_acquisition: %{reference: nonce}},
      operation_id: checkout.operation_id
    ]

    subscribe_opts =
      case socket.assigns.promotion_code do
        code when is_binary(code) and code != "" ->
          Keyword.put(subscribe_opts, :promotion_code, code)

        _ ->
          subscribe_opts
      end

    Billing.subscribe(socket.assigns.current_customer, checkout.price_id, subscribe_opts)
  end

  defp checkout_amount_minor(%LocalSession{line_items: [first | _]}) when is_map(first) do
    first
    |> Map.get("amount", "0.00")
    |> parse_amount_minor()
  end

  defp checkout_amount_minor(_session), do: 0

  defp parse_amount_minor(amount) when is_binary(amount) do
    amount
    |> String.trim()
    |> String.trim_leading("$")
    |> Decimal.new()
    |> Decimal.mult(Decimal.new(100))
    |> Decimal.round(0, :half_even)
    |> Decimal.to_integer()
  end

  defp format_minor_amount(amount_minor) when is_integer(amount_minor) do
    sign = if amount_minor < 0, do: "-", else: ""
    abs_minor = abs(amount_minor)
    dollars = div(abs_minor, 100)
    cents = abs_minor |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{sign}$#{dollars}.#{cents}"
  end

  defp checkout_ready?(%LocalSession{expires_at: %DateTime{} = expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :gt
  end

  defp checkout_ready?(_session), do: true

  defp assign_expired_error(socket) do
    assign(socket, :checkout_error, Copy.checkout_session_expired_body())
  end

  defp maybe_enqueue_completion(checkout, subscription) do
    case CompletionJob.enqueue(checkout.id, subscription.id) do
      {:ok, _job} ->
        :ok

      {:error, reason} ->
        Logger.warning(
          "failed to enqueue portal checkout completion for #{checkout.id}: #{inspect(reason)}"
        )

        :ok
    end
  end
end
