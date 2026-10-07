defmodule AccruePortal.Controllers.CheckoutController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  alias Accrue.Billing
  alias Accrue.Checkout.LocalSession
  alias Accrue.Portal.{Context, CustomerSession}
  alias Accrue.Processor
  alias AccruePortal.Path

  def complete(conn, %{"token" => token, "context_pin" => pin, "payment_method_nonce" => nonce})
      when is_binary(pin) and pin != "" and is_binary(nonce) and nonce != "" do
    with {:ok, context} <- resolve_pinned_context(conn, pin),
         %LocalSession{} = checkout <- LocalSession.by_token(token),
         true <- checkout_target?(context, checkout),
         true <- checkout_ready?(checkout),
         :ok <-
           Context.authorize_action(
             context,
             conn.assigns[:current_context_adapter],
             :checkout_complete,
             checkout
           ) do
      subscribe(conn, context, checkout, nonce)
    else
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

  defp subscribe(conn, context, checkout, nonce) do
    actor_id = Accrue.Auth.actor_id(context.actor) || Map.get(context.actor, :id)
    actor = %{type: :user, id: if(is_nil(actor_id), do: nil, else: to_string(actor_id))}

    result =
      Accrue.Actor.with_actor(actor, fn ->
        Billing.subscribe(context.customer, checkout.price_id,
          payment_method: %{vault_acquisition: %{reference: nonce}},
          operation_id: checkout.operation_id
        )
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
            deny(conn, checkout.session_token)
        end

      {:error, _reason} ->
        deny(conn, checkout.session_token)
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

    selected_item_matches? =
      case checkout.line_items do
        [%{"price" => price_id, "amount" => amount} = item] ->
          price_id == checkout.price_id and valid_amount?(amount) and
            valid_currency?(item["currency"])

        _ ->
          false
      end

    customer_matches? and selected_item_matches? and checkout.mode == "subscription" and
      checkout.ui_mode == "hosted" and context.processor == checkout.processor and
      checkout.processor == Processor.name()
  end

  defp checkout_target?(_, _), do: false

  defp valid_amount?(amount) when is_integer(amount), do: amount > 0

  defp valid_amount?(amount) when is_binary(amount) do
    case Decimal.parse(String.trim_leading(String.trim(amount), "$")) do
      {%Decimal{} = value, ""} -> Decimal.compare(value, Decimal.new(0)) == :gt
      _ -> false
    end
  end

  defp valid_amount?(_), do: false
  defp valid_currency?(nil), do: true
  defp valid_currency?(currency), do: is_binary(currency) and currency =~ ~r/^[A-Za-z]{3}$/

  defp checkout_ready?(%LocalSession{status: "open", expires_at: %DateTime{} = expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :gt
  end

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

  defp base_path(conn) do
    conn.assigns[:accrue_portal_mount_path] || Accrue.Config.portal_mount_path()
  end
end
