defmodule AccruePortal.Controllers.CheckoutController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  alias Accrue.Billing
  alias Accrue.Checkout.LocalSession
  alias Accrue.CardError
  alias Accrue.Portal.{Context, CustomerSession}
  alias Accrue.Processor
  alias AccruePortal.Path

  def complete(
        conn,
        %{"token" => token, "context_pin" => pin, "payment_method_nonce" => nonce} = params
      )
      when is_binary(pin) and pin != "" and is_binary(nonce) and nonce != "" do
    with {:ok, context} <- resolve_pinned_context(conn, pin),
         %LocalSession{} = checkout <- LocalSession.by_token(token),
         true <- checkout_target?(context, checkout),
         true <- checkout_ready?(checkout),
         :ok <- validate_promotion(checkout, Map.get(params, "promotion_code")),
         :ok <-
           Context.authorize_action(
             context,
             conn.assigns[:current_context_adapter],
             :checkout_complete,
             checkout
           ) do
      case LocalSession.claim(checkout, DateTime.utc_now()) do
        {:ok, claimed} ->
          subscribe(conn, context, claimed, nonce, Map.get(params, "promotion_code"))

        {:error, _} ->
          unavailable(conn, token)
      end
    else
      {:error, :stale_promotion} -> promotion_rejected(conn, token)
      _ -> deny(conn, token)
    end
  end

  def complete(conn, %{"token" => token}), do: deny(conn, token)
  def complete(conn, _params), do: deny(conn, nil)

  defp resolve_pinned_context(conn, pin) do
    CustomerSession.resolve_pin(
      conn.assigns.accrue_portal_session,
      pin,
      endpoint: conn.private[:phoenix_endpoint],
      context_adapter: conn.assigns[:current_context_adapter],
      session_keys: conn.assigns[:current_context_session_keys] || [],
      mount_path: base_path(conn)
    )
  end

  defp subscribe(conn, context, checkout, nonce, promotion_code) do
    actor_id = Accrue.Auth.actor_id(context.actor) || Map.get(context.actor, :id)
    actor = %{type: :user, id: if(is_nil(actor_id), do: nil, else: to_string(actor_id))}

    opts =
      [
        payment_method: %{vault_acquisition: %{reference: nonce}},
        operation_id: checkout.operation_id
      ]
      |> maybe_add_promotion(promotion_code)

    result =
      Accrue.Actor.with_actor(actor, fn ->
        Billing.subscribe(context.customer, checkout.price_id, opts)
      end)

    case result do
      {:ok, _subscription} ->
        case LocalSession.mark_completed(checkout) do
          {:ok, _session} ->
            conn = put_flash(conn, :info, "Subscription created.")

            case success_destination(checkout, conn) do
              {:external, url} -> redirect(conn, external: url)
              {:local, path} -> redirect(conn, to: path)
            end

          {:error, _changeset} ->
            _ = LocalSession.mark_uncertain(checkout)
            uncertain(conn, checkout)
        end

      {:error, %CardError{}} ->
        _ = LocalSession.release_claim(checkout)
        rejected(conn, checkout)

      {:error, _reason} ->
        _ = LocalSession.mark_uncertain(checkout)
        uncertain(conn, checkout)
    end
  end

  defp checkout_target?(context, %LocalSession{} = checkout) do
    customer_matches? =
      case context.customer do
        %Accrue.Billing.Customer{id: customer_id, processor: processor} ->
          customer_id == checkout.customer_id and processor == checkout.processor

        _ ->
          false
      end

    selected_item_matches? = checkout_terms_match?(context, checkout)

    customer_matches? and selected_item_matches? and checkout.mode == "subscription" and
      checkout.ui_mode == "hosted" and context.processor == checkout.processor and
      checkout.processor == Processor.name()
  end

  defp checkout_target?(_, _), do: false

  defp validate_promotion(_checkout, nil), do: :ok
  defp validate_promotion(_checkout, ""), do: :ok

  defp validate_promotion(%LocalSession{metadata: metadata}, code) when is_binary(code) do
    case Billing.resolve_discount_mapping(code, metadata["amount_minor"]) do
      {:ok, _mapping} -> :ok
      {:error, _reason} -> {:error, :stale_promotion}
    end
  end

  defp validate_promotion(_checkout, _code), do: {:error, :stale_promotion}

  defp maybe_add_promotion(opts, code) when is_binary(code) and code != "",
    do: Keyword.put(opts, :promotion_code, code)

  defp maybe_add_promotion(opts, _code), do: opts

  defp checkout_terms_match?(
         context,
         %LocalSession{line_items: [item], metadata: metadata} = checkout
       )
       when is_map(item) and is_map(metadata) do
    amount_minor = metadata["amount_minor"]
    currency = metadata["currency"]
    amount = item["amount"]

    item["price"] == checkout.price_id and item["quantity"] == 1 and
      is_integer(amount_minor) and amount_minor >= 0 and item["amount_minor"] == amount_minor and
      valid_decimal_amount?(amount, amount_minor) and valid_currency?(currency) and
      item["currency"] == currency and metadata["processor"] == checkout.processor and
      metadata["billable_id"] == to_string(context.owner_id) and
      is_binary(metadata["plan_name"]) and String.trim(metadata["plan_name"]) != "" and
      is_binary(metadata["billable_name"]) and String.trim(metadata["billable_name"]) != "" and
      metadata["interval"] in ["day", "week", "month", "year"] and
      is_integer(metadata["interval_count"]) and metadata["interval_count"] > 0
  end

  defp checkout_terms_match?(_, _), do: false

  defp valid_decimal_amount?(amount, expected_minor) when is_integer(amount),
    do: amount == expected_minor

  defp valid_decimal_amount?(amount, expected_minor) when is_binary(amount) do
    case Decimal.parse(String.trim_leading(String.trim(amount), "$")) do
      {%Decimal{} = value, ""} ->
        Decimal.compare(Decimal.mult(value, Decimal.new(100)), Decimal.new(expected_minor)) == :eq

      _ ->
        false
    end
  rescue
    ArgumentError -> false
  end

  defp valid_decimal_amount?(_, _), do: false

  defp valid_currency?(currency), do: is_binary(currency) and currency =~ ~r/^[A-Z]{3}$/

  defp checkout_ready?(%LocalSession{} = session),
    do: LocalSession.actionable?(session, DateTime.utc_now())

  defp checkout_ready?(_), do: false

  defp success_destination(%LocalSession{success_url: url}, conn)
       when is_binary(url) and url != "" do
    uri = URI.parse(url)

    cond do
      Context.valid_local_path?(url) ->
        {:local, url}

      uri.scheme == "https" and is_binary(uri.host) and uri.host != "" and is_nil(uri.userinfo) ->
        {:external, url}

      true ->
        {:local, Path.home(base_path(conn))}
    end
  end

  defp success_destination(_, conn), do: {:local, Path.home(base_path(conn))}

  defp deny(conn, token) do
    conn
    |> put_flash(:error, "Checkout access is unavailable. No payment was submitted.")
    |> redirect(
      to:
        if(is_binary(token) and token != "",
          do: Path.checkout(base_path(conn), token),
          else: Path.home(base_path(conn))
        )
    )
  end

  defp unavailable(conn, token) do
    case LocalSession.by_token(token) do
      %LocalSession{status: status} = checkout when status in ["processing", "uncertain"] ->
        uncertain(conn, checkout)

      %LocalSession{status: "completed"} = checkout ->
        conn
        |> put_flash(
          :info,
          "This checkout has already been completed. Review your subscription status before taking another action."
        )
        |> redirect(to: Path.checkout(base_path(conn), checkout.session_token))

      _ ->
        deny(conn, token)
    end
  end

  defp rejected(conn, checkout) do
    conn
    |> put_flash(
      :error,
      "Your card was declined. No subscription was created. Please try a fresh payment method."
    )
    |> redirect(to: Path.checkout(base_path(conn), checkout.session_token))
  end

  defp promotion_rejected(conn, token) do
    conn
    |> put_flash(:error, "This promotion is unavailable. No payment was submitted.")
    |> redirect(to: Path.checkout(base_path(conn), token))
  end

  defp uncertain(conn, checkout) do
    conn
    |> put_flash(
      :error,
      "We could not confirm the payment result. Do not submit again. Check your subscription status or contact support."
    )
    |> redirect(to: Path.checkout(base_path(conn), checkout.session_token))
  end

  defp base_path(conn) do
    conn.assigns[:accrue_portal_mount_path] || Accrue.Config.portal_mount_path()
  end
end
