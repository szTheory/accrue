defmodule AccruePortal.Authorize do
  @moduledoc false

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias AccruePortal.BillingReadModel
  alias Accrue.Portal.{Context, CustomerSession}

  def current_customer!(%{assigns: %{current_customer: %Customer{} = customer}}), do: customer

  def subscription(socket, id, action \\ :read) when is_binary(id) do
    with {:ok, context} <- fresh_context(socket),
         {:ok, %Subscription{} = subscription} <-
           BillingReadModel.subscription(context.customer, id),
         :ok <-
           Context.authorize_action(
             context,
             socket.assigns[:current_context_adapter],
             action,
             subscription
           ) do
      {:ok, subscription}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :not_found}
    end
  end

  def subscription!(socket, id) when is_binary(id) do
    case subscription(socket, id) do
      {:ok, %Subscription{} = subscription} ->
        subscription

      {:error, reason} when reason in [:not_found, :forbidden] ->
        raise Ecto.NoResultsError, queryable: Subscription
    end
  end

  defp fresh_context(socket) do
    session = socket.assigns.accrue_portal_session

    resolution =
      case socket.assigns[:current_context_pin] do
        pin when is_binary(pin) and pin != "" ->
          CustomerSession.resolve_pin(session, pin,
            endpoint: socket.endpoint,
            mount_path: get_in(session, ["accrue_portal", "mount_path"])
          )

        _ ->
          CustomerSession.resolve(session, create?: false)
      end

    case resolution do
      {:ok, %Context{} = context} ->
        if context.customer.id == socket.assigns.current_customer.id and
             context.owner_type == socket.assigns.current_context.owner_type and
             context.owner_id == socket.assigns.current_context.owner_id and
             context.processor == socket.assigns.current_context.processor do
          {:ok, context}
        else
          {:error, :forbidden}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
