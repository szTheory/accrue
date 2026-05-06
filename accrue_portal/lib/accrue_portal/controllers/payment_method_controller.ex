defmodule AccruePortal.Controllers.PaymentMethodController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  alias Accrue.Billing
  alias AccruePortal.BillingReadModel
  alias AccruePortal.Path

  def create(conn, %{"payment_method_nonce" => nonce}) when is_binary(nonce) and nonce != "" do
    customer = conn.assigns.current_customer

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

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  def delete(conn, %{"id" => id}) do
    customer = conn.assigns.current_customer

    case BillingReadModel.payment_method(customer, id) do
      {:ok, payment_method} ->
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

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  defp base_path(conn) do
    conn.assigns[:accrue_portal_mount_path] || Accrue.Config.portal_mount_path()
  end

  defp not_found(conn) do
    conn
    |> Plug.Conn.send_resp(:not_found, "Not Found")
    |> Plug.Conn.halt()
  end
end
