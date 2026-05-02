defmodule AccruePortal.Controllers.CheckoutController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  alias Accrue.Billing
  alias Accrue.Checkout.LocalSession
  alias AccruePortal.Path

  def complete(conn, %{"token" => token, "payment_method_nonce" => nonce})
      when is_binary(nonce) and nonce != "" do
    customer = conn.assigns.current_customer

    case LocalSession.by_token(token) do
      %LocalSession{customer_id: customer_id} = session when customer_id == customer.id ->
        case Billing.subscribe(customer, session.price_id,
               payment_method: %{vault_acquisition: %{reference: nonce}},
               operation_id: session.operation_id
             ) do
          {:ok, _subscription} ->
            {:ok, _session} = LocalSession.mark_completed(session)

            conn
            |> put_flash(:info, "Subscription created.")
            |> redirect(to: session.success_url || Path.home(base_path(conn)))

          {:error, _reason} ->
            conn
            |> put_flash(:error, "Unable to complete checkout.")
            |> redirect(to: Path.checkout(base_path(conn), token))
        end

      _ ->
        conn
        |> put_flash(:error, "Checkout session not found.")
        |> redirect(to: Path.home(base_path(conn)))
    end
  end

  def complete(conn, %{"token" => token}) do
    conn
    |> put_flash(:error, "Payment details are required.")
    |> redirect(to: Path.checkout(base_path(conn), token))
  end

  defp base_path(conn) do
    conn.assigns[:accrue_portal_mount_path] || Accrue.Config.portal_mount_path()
  end
end
