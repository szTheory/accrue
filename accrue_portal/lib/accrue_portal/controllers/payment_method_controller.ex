defmodule AccruePortal.Controllers.PaymentMethodController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  alias Accrue.Billing
  alias Accrue.Portal.Context
  alias AccruePortal.BillingReadModel
  alias AccruePortal.Copy
  alias AccruePortal.Path

  def create(conn, %{"payment_method_nonce" => nonce}) when is_binary(nonce) and nonce != "" do
    customer = conn.assigns.current_customer

    case authorize_supported(conn, :payment_method_create, customer, [:vault_acquisition, :create]) do
      :ok ->
        case with_actor(conn, fn ->
               Billing.add_payment_method(customer, %{vault_acquisition: %{reference: nonce}})
             end) do
          {:ok, _payment_method} ->
            conn
            |> put_flash(:info, Copy.add_payment_method_save_success())
            |> redirect(to: payment_methods_path(conn))

          {:error, _reason} ->
            conn
            |> put_flash(:error, Copy.add_payment_method_save_error())
            |> redirect(to: payment_methods_path(conn))
        end

      :error ->
        blocked(conn)
    end
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, Copy.add_payment_method_nonce_error())
    |> redirect(to: payment_methods_path(conn))
  end

  def set_default(conn, %{"id" => id}) do
    customer = conn.assigns.current_customer

    case BillingReadModel.payment_method(customer, id) do
      {:ok, payment_method} ->
        case authorize_supported(conn, :payment_method_default, payment_method, [:set_default]) do
          :ok ->
            case with_actor(conn, fn ->
                   Billing.set_default_payment_method(customer, payment_method)
                 end) do
              {:ok, _customer} ->
                conn
                |> put_flash(:info, Copy.payment_methods_default_success())
                |> redirect(to: payment_methods_path(conn))

              {:error, _reason} ->
                conn
                |> put_flash(:error, Copy.payment_methods_default_error())
                |> redirect(to: payment_methods_path(conn))
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
        case authorize_supported(conn, :payment_method_delete, payment_method, [:delete]) do
          :ok ->
            case with_actor(conn, fn -> Billing.delete_payment_method(payment_method) end) do
              {:ok, _payment_method} ->
                conn
                |> put_flash(:info, Copy.payment_methods_delete_success())
                |> redirect(to: payment_methods_path(conn))

              {:error, _reason} ->
                conn
                |> put_flash(:error, Copy.payment_methods_delete_error())
                |> redirect(to: payment_methods_path(conn))
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

  defp payment_methods_path(conn) do
    Path.context(Path.payment_methods(base_path(conn)), conn.params["context_pin"])
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

  defp authorize_supported(conn, action, target, capabilities) do
    customer = conn.assigns.current_customer
    processor = Accrue.Processor.__impl__()

    supported? =
      customer.processor == processor.processor_name() and
        (action != :payment_method_create or customer.processor in ["braintree", "fake"]) and
        Enum.all?(capabilities, &Accrue.Processor.supports?([:payment_method, &1]))

    if supported? do
      authorize(conn, action, target)
    else
      :error
    end
  rescue
    _ -> :error
  end

  defp blocked(conn) do
    conn
    |> put_flash(:error, "Billing access unavailable.")
    |> redirect(to: String.trim_trailing(base_path(conn), "/") <> "/blocked")
  end

  defp with_actor(conn, fun) do
    actor = conn.assigns.current_actor
    actor_id = Accrue.Auth.actor_id(actor) || Map.get(actor, :id) || Map.get(actor, "id")
    actor = %{type: :user, id: if(is_nil(actor_id), do: nil, else: to_string(actor_id))}
    Accrue.Actor.with_actor(actor, fun)
  end

  defp not_found(conn) do
    conn
    |> Plug.Conn.send_resp(:not_found, "Not Found")
    |> Plug.Conn.halt()
  end
end
