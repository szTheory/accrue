defmodule AccruePortal.Live.CheckoutLive do
  use Phoenix.LiveView

  require Logger

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.CardError
  alias Accrue.Checkout.LocalSession
  alias Accrue.Error.DiscountMappingInvalid
  alias Accrue.Portal.{Context, CustomerSession}
  alias Accrue.Portal.Checkout.CompletionJob
  alias Accrue.Processor
  alias Accrue.Repo
  alias AccruePortal.BraintreeClient
  alias AccruePortal.Copy
  alias AccruePortal.Path

  @client_script_src "https://js.braintreegateway.com/web/3.132.0/js/client.min.js"
  @client_script_sri "sha384-rNv6rxT4CpVv9Kb8luV4l/GpBwbhHTmZxWbI74/LX+ShrJzh/b9AL7nynSmHDpRC"
  @hosted_fields_script_src "https://js.braintreegateway.com/web/3.132.0/js/hosted-fields.min.js"
  @hosted_fields_script_sri "sha384-QAzc9uX3XQPGzTESbnMNOUn9hY9jVL/L10Eq3Gxt4NKXIZZWzGlhnEscA3iGj8Jp"

  @impl true
  def mount(%{"token" => token} = params, %{"accrue_portal" => portal}, socket) do
    session = LocalSession.by_token(token)

    with %LocalSession{} = checkout <- session,
         {:ok, pin, context} <- resolve_checkout_context(socket, params["context_pin"], true),
         true <- checkout_target?(context, checkout) do
      action_target? =
        checkout_action_target?(context, checkout)

      complete_allowed? =
        action_target? and
          Context.authorize_action(
            context,
            socket.assigns[:current_context_adapter],
            :checkout_complete,
            checkout
          ) == :ok

      promo_allowed? =
        action_target? and
          Context.authorize_action(
            context,
            socket.assigns[:current_context_adapter],
            :checkout_validate_promo,
            checkout
          ) == :ok

      client_token =
        if checkout_ready?(checkout) and valid_checkout_terms?(checkout) and complete_allowed? do
          case BraintreeClient.client_token_for(context.customer) do
            {:ok, value} -> value
            _ -> nil
          end
        end

      socket =
        socket
        |> assign_checkout_pricing(checkout)
        |> assign(:page_title, Copy.checkout_page_title())
        |> assign(:portal, portal)
        |> assign(:base_path, portal["mount_path"])
        |> assign(:checkout_session, checkout)
        |> assign(:client_token, client_token)
        |> assign(:context_pin, pin)
        |> assign(:promo_allowed, promo_allowed?)
        |> assign(:completion_denied, not complete_allowed?)
        |> assign(:checkout_terms_valid, valid_checkout_terms?(checkout))
        |> assign(
          :checkout_recovery_url,
          safe_recovery_url(checkout.cancel_url, portal["mount_path"])
        )
        |> assign(:checkout_error, nil)
        |> assign(:checkout_uncertain, checkout.status in ["processing", "uncertain"])
        |> assign(:checkout_success, false)
        |> assign(:promotion_code, nil)
        |> assign(:promotion_code_input, "")
        |> assign(:promo_status, nil)
        |> assign(:promo_preview, nil)
        |> assign(:client_script_src, @client_script_src)
        |> assign(:client_script_sri, @client_script_sri)
        |> assign(:hosted_fields_script_src, @hosted_fields_script_src)
        |> assign(:hosted_fields_script_sri, @hosted_fields_script_sri)

      if is_nil(params["context_pin"]) do
        send(self(), {:patch_checkout_context_pin, pin})
      end

      {:ok, socket}
    else
      nil ->
        {:ok, redirect(socket, to: portal["mount_path"])}

      _ ->
        {:ok, redirect(socket, to: portal["blocked_path"] || portal["mount_path"])}
    end
  end

  # Fallback: "accrue_portal" session key absent (misconfigured router,
  # expired session after deploy, or direct navigation outside live_session).
  # Redirect to root rather than raising FunctionClauseError.
  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: "/")}
  end

  @impl true
  def handle_info({:patch_checkout_context_pin, pin}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         Path.context(
           Path.checkout(socket.assigns.base_path, socket.assigns.checkout_session.session_token),
           pin
         )
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  defp success_destination(url, socket) when is_binary(url) and url != "" do
    uri = URI.parse(url)

    cond do
      Context.valid_local_path?(url) ->
        {:local, url}

      uri.scheme == "https" and is_binary(uri.host) and uri.host != "" and is_nil(uri.userinfo) ->
        {:external, url}

      true ->
        {:local, Path.home(socket.assigns.base_path)}
    end
  end

  defp success_destination(_, _socket), do: :show_success

  @impl true
  def handle_event(
        "checkout_tokenized",
        %{"nonce" => nonce, "context_pin" => pin},
        socket
      )
      when is_binary(nonce) and nonce != "" and is_binary(pin) and pin != "" do
    case authorized_checkout(socket, pin, :checkout_complete) do
      {:ok, checkout, context} ->
        if checkout_ready?(checkout) do
          case LocalSession.claim(checkout, DateTime.utc_now()) do
            {:ok, claimed} ->
              case subscribe_with_checkout(socket, claimed, context, nonce) do
                {:ok, subscription} ->
                  case LocalSession.mark_completed(claimed) do
                    {:ok, _session} ->
                      maybe_enqueue_completion(claimed, subscription)

                      case success_destination(claimed.success_url, socket) do
                        {:external, url} ->
                          {:noreply, redirect(socket, external: url)}

                        {:local, path} ->
                          {:noreply, redirect(socket, to: path)}

                        :show_success ->
                          {:noreply,
                           socket
                           |> assign(:checkout_error, nil)
                           |> assign(:checkout_uncertain, false)
                           |> assign(:checkout_success, true)}
                      end

                    {:error, _reason} ->
                      _ = LocalSession.mark_uncertain(claimed)
                      {:noreply, uncertain_checkout(socket, claimed)}
                  end

                {:error, %DiscountMappingInvalid{}} ->
                  _ = LocalSession.release_claim(claimed)

                  {:noreply,
                   socket
                   |> assign(:checkout_error, nil)
                   |> assign(:checkout_uncertain, false)
                   |> assign(:checkout_success, false)
                   |> assign(:promo_preview, nil)
                   |> assign(:promo_status, Copy.checkout_promo_temporarily_unavailable())
                   |> assign_base_checkout_amount()}

                {:error, reason}
                when reason in [:not_found, :inactive, :expired, :max_redemptions_reached] ->
                  _ = LocalSession.release_claim(claimed)

                  {:noreply,
                   socket
                   |> assign(:checkout_error, nil)
                   |> assign(:checkout_uncertain, false)
                   |> assign(:checkout_success, false)
                   |> assign(:promotion_code, nil)
                   |> assign(:promo_preview, nil)
                   |> assign(:promo_status, Copy.checkout_promo_invalid())
                   |> assign_base_checkout_amount()}

                {:error, %CardError{}} ->
                  _ = LocalSession.release_claim(claimed)

                  {:noreply,
                   socket
                   |> assign(
                     :checkout_error,
                     "Your card was declined. No subscription was created. Please try a fresh payment method."
                   )
                   |> assign(:checkout_uncertain, false)
                   |> assign(:checkout_success, false)}

                {:error, _reason} ->
                  _ = LocalSession.mark_uncertain(claimed)
                  {:noreply, uncertain_checkout(socket, claimed)}
              end

            {:error, _claim_reason} ->
              claim_unavailable(socket, checkout)
          end
        else
          {:noreply, deny_checkout(socket, Copy.checkout_session_expired_body())}
        end

      _ ->
        unavailable_checkout(socket)
    end
  end

  def handle_event("checkout_tokenized", _params, socket) do
    {:noreply, deny_checkout(socket, Copy.checkout_missing_nonce_error())}
  end

  def handle_event(
        "validate_promo",
        %{"promo" => %{"code" => code}, "context_pin" => pin},
        socket
      )
      when is_binary(pin) and pin != "" do
    trimmed_code = String.trim(code)

    case authorized_checkout(socket, pin, :checkout_validate_promo) do
      {:ok, checkout, _context} ->
        if checkout_ready?(checkout) do
          if trimmed_code == "" do
            {:noreply,
             socket
             |> assign(:promotion_code, nil)
             |> assign(:promotion_code_input, "")
             |> assign(:promo_preview, nil)
             |> assign(:promo_status, nil)
             |> assign_base_checkout_amount()}
          else
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
        else
          {:noreply, deny_checkout(socket, Copy.checkout_session_expired_body())}
        end

      _ ->
        {:noreply, deny_checkout(socket, Copy.checkout_promo_unavailable())}
    end
  end

  def handle_event("validate_promo", _params, socket) do
    {:noreply, deny_checkout(socket, Copy.checkout_promo_unavailable())}
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
        <section
          class="portal-checkout-summary"
          data-testid="checkout-offer-summary"
          aria-label="Selected plan"
          data-plan-name={@checkout_terms_valid && @checkout_plan_name}
          data-amount-minor={@checkout_terms_valid && @base_amount_minor}
          data-currency={@checkout_terms_valid && @checkout_currency}
          data-interval={@checkout_terms_valid && @checkout_interval}
          data-billable={@checkout_terms_valid && @checkout_billable_name}
        >
          <h2>Selected plan</h2>
          <dl :if={@checkout_terms_valid}>
            <div><dt>Plan</dt><dd>{@checkout_plan_name}</dd></div>
            <div><dt>Billed to</dt><dd>{@checkout_billable_name}</dd></div>
            <div><dt>Charge</dt><dd>{@checkout_currency} {@base_checkout_amount} / {@checkout_interval}</dd></div>
          </dl>
          <div :if={!@checkout_terms_valid} class="portal-inline-error" role="alert">
            <p>Plan details are unavailable, so payment cannot continue.</p>
            <a :if={@checkout_recovery_url} href={@checkout_recovery_url} class="portal-button-secondary">Return to billing</a>
          </div>
        </section>
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

        <div :if={@checkout_uncertain} class="portal-inline-error" role="status" aria-live="polite" data-checkout-uncertain>
          <p>We could not confirm the payment result. Do not submit again.</p>
          <p>Check your subscription status or contact support before taking another payment action.</p>
          <a :if={@checkout_recovery_url} href={@checkout_recovery_url} class="portal-button-secondary">Return to billing</a>
        </div>

        <div :if={@completion_denied} class="portal-inline-error" role="status" aria-live="polite">
          <p>Checkout access is unavailable. No payment was submitted.</p>
        </div>

        <div :if={@checkout_session.status == "completed"} class="portal-inline-error" role="status" aria-live="polite">
          <p>This checkout has already been completed.</p>
          <p>Return to your account to review your subscription.</p>
          <a :if={@checkout_recovery_url} href={@checkout_recovery_url} class="portal-button-secondary">Return to billing</a>
        </div>

        <div :if={not checkout_ready?(@checkout_session) and @checkout_session.status == "open"} class="portal-inline-error" role="status" aria-live="polite">
          <p>{Copy.checkout_session_expired_title()}</p>
          <p>{Copy.checkout_session_expired_body()}</p>
          <a :if={@checkout_recovery_url} href={@checkout_recovery_url} class="portal-button-secondary">Return to billing</a>
        </div>

        <form
          :if={@promo_allowed && @checkout_terms_valid && checkout_ready?(@checkout_session) && !@checkout_success}
          id="promo-code-form"
          phx-change="validate_promo"
          class="portal-promo-form"
        >
          <input type="hidden" name="context_pin" value={@context_pin} />
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
          :if={@client_token && @checkout_terms_valid && checkout_ready?(@checkout_session) && !@checkout_success}
          id="checkout-form"
          action={Path.checkout_complete(@base_path, @checkout_session.session_token)}
          method="post"
          phx-hook="BraintreeHostedFields"
          phx-submit="checkout_submit"
          class="portal-hosted-fields-form"
          data-portal-hosted-fields="checkout"
          data-client-token={@client_token}
        >
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
          <input type="hidden" name="context_pin" value={@context_pin} />
          <input type="hidden" name="promotion_code" value={@promotion_code || ""} />
          <input type="hidden" name="payment_method_nonce" data-braintree-nonce-input value="" />
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
              :if={@checkout_recovery_url}
              href={@checkout_recovery_url}
              class="portal-button-secondary"
            >
              {Copy.checkout_leave_cta()}
            </a>
          </div>
        </form>

        <a
          :if={@client_token == nil && checkout_ready?(@checkout_session) && @checkout_terms_valid && @checkout_recovery_url}
          href={@checkout_recovery_url}
          class="portal-button-secondary"
        >
          {Copy.checkout_leave_cta()}
        </a>
      </section>
    </main>
    """
  end

  defp assign_checkout_pricing(socket, %LocalSession{} = checkout) do
    case checkout_terms(checkout) do
      {:ok, terms} ->
        amount_text = format_minor_amount(terms.amount_minor)

        socket
        |> assign(:base_amount_minor, terms.amount_minor)
        |> assign(:base_checkout_amount, amount_text)
        |> assign(:checkout_amount, amount_text)
        |> assign(:checkout_plan_name, terms.plan_name)
        |> assign(:checkout_billable_name, terms.billable_name)
        |> assign(:checkout_currency, terms.currency)
        |> assign(:checkout_interval, interval_label(terms.interval, terms.interval_count))

      :error ->
        socket
        |> assign(:base_amount_minor, nil)
        |> assign(:base_checkout_amount, "Unavailable")
        |> assign(:checkout_amount, "Unavailable")
        |> assign(:checkout_plan_name, "Unavailable")
        |> assign(:checkout_billable_name, "Unavailable")
        |> assign(:checkout_currency, "Unavailable")
        |> assign(:checkout_interval, "Unavailable")
    end
  end

  defp assign_base_checkout_amount(socket) do
    assign(socket, :checkout_amount, socket.assigns.base_checkout_amount)
  end

  defp subscribe_with_checkout(socket, checkout, context, nonce) do
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

    actor_id = Accrue.Auth.actor_id(context.actor) || Map.get(context.actor, :id)
    actor = %{type: :user, id: if(is_nil(actor_id), do: nil, else: to_string(actor_id))}

    Accrue.Actor.with_actor(actor, fn ->
      Billing.subscribe(context.customer, checkout.price_id, subscribe_opts)
    end)
  end

  defp resolve_checkout_context(socket, pin, _mint_if_missing?) do
    pin =
      if is_binary(pin) and pin != "" do
        pin
      else
        case Context.mint_pin(socket.assigns.current_context, socket.endpoint) do
          {:ok, value} -> value
          _ -> nil
        end
      end

    with true <- is_binary(pin) and pin != "",
         {:ok, context} <-
           CustomerSession.resolve_pin(socket.assigns.accrue_portal_session, pin,
             endpoint: socket.endpoint,
             mount_path: socket.assigns[:base_path] || Accrue.Config.portal_mount_path()
           ) do
      {:ok, pin, context}
    else
      _ -> {:error, :unavailable}
    end
  end

  defp authorized_checkout(socket, pin, action) do
    token = socket.assigns.checkout_session.session_token
    checkout = LocalSession.by_token(token)

    with %LocalSession{} = checkout <- checkout,
         {:ok, _pin, context} <- resolve_checkout_context(socket, pin, false),
         true <-
           checkout_action_target?(context, checkout),
         true <- checkout_ready?(checkout),
         :ok <-
           Context.authorize_action(
             context,
             socket.assigns[:current_context_adapter],
             action,
             checkout
           ) do
      {:ok, checkout, context}
    else
      _ -> {:error, :unavailable}
    end
  end

  defp checkout_target?(context, %LocalSession{} = checkout) do
    case Repo.get(Customer, checkout.customer_id) do
      %Customer{owner_type: owner_type, owner_id: owner_id, processor: processor} ->
        owner_type == context.owner_type and owner_id == context.owner_id and
          processor == checkout.processor

      _ ->
        false
    end
  end

  defp checkout_action_target?(context, %LocalSession{} = checkout) do
    customer_matches? =
      case context.customer do
        %Customer{id: customer_id, processor: processor} ->
          customer_id == checkout.customer_id and processor == checkout.processor

        _ ->
          false
      end

    selected_item_matches? =
      valid_checkout_terms?(checkout)

    configured_processor_matches? = checkout.processor == Processor.name()

    customer_matches? and selected_item_matches? and checkout.mode == "subscription" and
      checkout.ui_mode == "hosted" and context.processor == checkout.processor and
      configured_processor_matches?
  end

  defp valid_checkout_terms?(%LocalSession{} = checkout),
    do: match?({:ok, _}, checkout_terms(checkout))

  defp valid_checkout_terms?(_), do: false

  defp deny_checkout(socket, message) do
    socket
    |> assign(:client_token, nil)
    |> assign(:completion_denied, true)
    |> assign(:checkout_error, message)
    |> assign(:checkout_success, false)
    |> assign(:checkout_uncertain, false)
    |> assign(:promotion_code, nil)
    |> assign(:promo_preview, nil)
    |> assign(:promo_status, nil)
  end

  defp uncertain_checkout(socket, checkout) do
    %{socket | assigns: Map.put(socket.assigns, :checkout_session, checkout)}
    |> assign(:client_token, nil)
    |> assign(:checkout_error, nil)
    |> assign(:checkout_uncertain, true)
    |> assign(:checkout_success, false)
    |> assign(:promotion_code, nil)
    |> assign(:promo_preview, nil)
  end

  defp claim_unavailable(socket, checkout) do
    latest = LocalSession.by_id(checkout.id) || checkout

    case latest.status do
      "completed" ->
        {:noreply,
         socket
         |> assign(:checkout_session, latest)
         |> assign(:client_token, nil)
         |> assign(:checkout_uncertain, false)
         |> assign(:checkout_error, nil)}

      "processing" ->
        {:noreply, uncertain_checkout(socket, latest)}

      _ ->
        {:noreply, deny_checkout(socket, Copy.checkout_session_expired_body())}
    end
  end

  defp unavailable_checkout(socket) do
    checkout = LocalSession.by_token(socket.assigns.checkout_session.session_token)

    case checkout do
      %LocalSession{status: status} = latest when status in ["processing", "uncertain"] ->
        {:noreply, uncertain_checkout(socket, latest)}

      %LocalSession{status: "completed"} = latest ->
        {:noreply,
         socket
         |> assign(:checkout_session, latest)
         |> assign(:client_token, nil)
         |> assign(:checkout_uncertain, false)
         |> assign(:checkout_error, nil)
         |> assign(:checkout_success, false)}

      _ ->
        {:noreply,
         deny_checkout(socket, "Checkout access is unavailable. No payment was submitted.")}
    end
  end

  defp checkout_terms(%LocalSession{line_items: [item], metadata: metadata} = checkout)
       when is_map(item) and is_map(metadata) do
    amount_minor = Map.get(metadata, "amount_minor")
    line_amount_minor = Map.get(item, "amount_minor")
    amount = Map.get(item, "amount")
    currency = Map.get(metadata, "currency")
    interval = Map.get(metadata, "interval")
    interval_count = Map.get(metadata, "interval_count")
    plan_name = Map.get(metadata, "plan_name")
    billable_name = Map.get(metadata, "billable_name")
    billable_id = Map.get(metadata, "billable_id")
    processor = Map.get(metadata, "processor")

    with true <- Map.get(item, "price") == checkout.price_id,
         true <- Map.get(item, "quantity") == 1,
         true <- is_integer(amount_minor) and amount_minor >= 0,
         true <- line_amount_minor == amount_minor,
         true <- valid_decimal_amount?(amount, amount_minor),
         true <- is_binary(currency) and currency =~ ~r/^[A-Z]{3}$/,
         true <- interval in ["day", "week", "month", "year"],
         true <- is_integer(interval_count) and interval_count > 0,
         true <- is_binary(plan_name) and String.trim(plan_name) != "",
         true <- is_binary(billable_name) and String.trim(billable_name) != "",
         true <- is_binary(billable_id) and billable_id != "",
         true <- processor == checkout.processor do
      {:ok,
       %{
         amount_minor: amount_minor,
         currency: currency,
         interval: interval,
         interval_count: interval_count,
         plan_name: plan_name,
         billable_name: billable_name
       }}
    else
      _ -> :error
    end
  end

  defp checkout_terms(_), do: :error

  defp valid_decimal_amount?(amount, expected_minor) when is_integer(amount),
    do: amount == expected_minor

  defp valid_decimal_amount?(amount, expected_minor) when is_binary(amount) do
    case Decimal.parse(String.trim_leading(String.trim(amount), "$")) do
      {%Decimal{} = value, ""} ->
        minor = Decimal.mult(value, Decimal.new(100))

        Decimal.compare(minor, Decimal.new(0)) != :lt and
          Decimal.compare(minor, Decimal.new(expected_minor)) == :eq

      _ ->
        false
    end
  rescue
    ArgumentError -> false
  end

  defp valid_decimal_amount?(_, _), do: false

  defp interval_label(interval, 1), do: "per " <> interval
  defp interval_label(interval, count), do: "every #{count} #{interval}s"

  defp safe_recovery_url(url, fallback) when is_binary(url) do
    uri = URI.parse(url)

    cond do
      Context.valid_local_path?(url) ->
        url

      uri.scheme == "https" and is_binary(uri.host) and uri.host != "" and is_nil(uri.userinfo) ->
        url

      true ->
        fallback
    end
  end

  defp safe_recovery_url(_, fallback), do: fallback

  defp format_minor_amount(amount_minor) when is_integer(amount_minor) do
    sign = if amount_minor < 0, do: "-", else: ""
    abs_minor = abs(amount_minor)
    dollars = div(abs_minor, 100)
    cents = abs_minor |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{sign}$#{dollars}.#{cents}"
  end

  defp checkout_ready?(%LocalSession{} = session),
    do: LocalSession.actionable?(session, DateTime.utc_now())

  defp checkout_ready?(_session), do: false

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
