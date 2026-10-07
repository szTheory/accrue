defmodule AccruePortal.Controllers.PaymentMethodController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  alias Accrue.Billing
  alias Accrue.Portal.Context
  alias AccruePortal.BillingReadModel
  alias AccruePortal.Path

  def create(conn, %{"payment_method_nonce" => nonce}) when is_binary(nonce) and nonce != "" do
    customer = conn.assigns.current_customer

    case authorize(conn, :payment_method_create, customer) do
      :ok ->
        case Billing.add_payment_method(customer, %{vault_acquisition: %{reference: nonce}}) do
          {:ok, _payment_method} ->
            conn
            |> put_flash(:info, "Payment method saved.")
            |> redirect(to: Path.payment_methods(base_path(conn)))

          {:error, _reason} ->
            conn
            |> put_flash(:error, "Unable to save payment method.")
            |> redirect(to: Path.payment_methods(base_path(conn)))
        end

      :error ->
        blocked(conn)
    end
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Payment method tokenization failed.")
    |> redirect(to: Path.payment_methods(base_path(conn)))
  end

  def set_default(conn, %{"id" => id}) do
    customer = conn.assigns.current_customer

    case BillingReadModel.payment_method(customer, id) do
      {:ok, payment_method} ->
        case authorize(conn, :payment_method_default, payment_method) do
          :ok ->
            case Billing.set_default_payment_method(customer, payment_method) do
              {:ok, _customer} ->
                conn
                |> put_flash(:info, "Default payment method updated.")
                |> redirect(to: Path.payment_methods(base_path(conn)))

              {:error, _reason} ->
                conn
                |> put_flash(:error, "Unable to update default payment method.")
                |> redirect(to: Path.payment_methods(base_path(conn)))
            end

          :error ->
            blocked(conn)
        end

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  def delete(conn, %{"id" => id}) do
    customer = conn.assigns.current_customer

    case BillingReadModel.payment_method(customer, id) do
      {:ok, payment_method} ->
        case authorize(conn, :payment_method_delete, payment_method) do
          :ok ->
            case Billing.delete_payment_method(payment_method) do
              {:ok, _payment_method} ->
                conn
                |> put_flash(:info, "Payment method deleted.")
                |> redirect(to: Path.payment_methods(base_path(conn)))

              {:error, _reason} ->
                conn
                |> put_flash(:error, "Unable to delete payment method.")
                |> redirect(to: Path.payment_methods(base_path(conn)))
            end

          :error ->
            blocked(conn)
        end

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  defp base_path(conn) do
    conn.assigns[:accrue_portal_mount_path] || Accrue.Config.portal_mount_path()
  end

  defp authorize(conn, action, target) do
    case Context.authorize_action(
           conn.assigns.current_context,
           conn.assigns[:current_context_adapter],
           action,
           target
         ) do
      :ok -> :ok
      _ -> :error
    end
  end

  defp blocked(conn) do
    conn
    |> put_flash(:error, "Billing access unavailable.")
    |> redirect(to: String.trim_trailing(base_path(conn), "/") <> "/blocked")
  end

  defp not_found(conn) do
    conn
    |> Plug.Conn.send_resp(:not_found, "Not Found")
    |> Plug.Conn.halt()
  end
end
