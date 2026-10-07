defmodule Accrue.Portal.Context do
  @moduledoc """
  Server-resolved identity and presentation data for one Portal request.

  The human actor performs policy checks. The billable identifies the billing
  owner. Display fields are presentation only and never grant access.

  Context adapters expose a closed action vocabulary for reads, payment-method
  operations, subscription management, and checkout completion.
  Adapters must reload their own membership and billable records before
  authorizing an action; a session selection or pin is only a locator.
  """

  alias Accrue.Billing.Customer
  alias Accrue.Processor

  @pin_salt "accrue-portal-payment-flow-v1"
  @pin_max_age 20 * 60

  @enforce_keys [:actor, :billable, :owner_type, :owner_id, :processor]
  defstruct [
    :actor,
    :billable,
    :owner_type,
    :owner_id,
    :processor,
    :customer,
    :display_name,
    :display_detail,
    :switch_path
  ]

  @type action ::
          :read
          | :manage_payment_methods
          | :payment_method_create
          | :payment_method_default
          | :payment_method_delete
          | :manage_subscription
          | :subscription_cancel
          | :subscription_change
          | :subscription_preview
          | :checkout_validate_promo
          | :checkout_complete

  @type t :: %__MODULE__{
          actor: struct(),
          billable: struct(),
          owner_type: String.t(),
          owner_id: String.t(),
          processor: String.t(),
          customer: Customer.t() | nil,
          display_name: String.t() | nil,
          display_detail: String.t() | nil,
          switch_path: String.t() | nil
        }

  @doc "Optional host contract for resolving and authorizing Portal context."
  @callback resolve(actor :: struct(), selection :: map()) ::
              {:ok, map()} | {:error, :forbidden | :unavailable}
  @callback authorize(actor :: struct(), context :: t(), action(), target :: term()) ::
              :ok | {:error, :forbidden}

  @spec resolve(struct(), module(), map(), String.t()) :: {:ok, t()} | {:error, atom()}
  def resolve(actor, adapter, selection, mount_path)
      when is_map(actor) and is_atom(adapter) and is_map(selection) and is_binary(mount_path) do
    with {:ok, resolved} <- adapter_resolve(adapter, actor, selection),
         {:ok, context} <- build_context(actor, resolved),
         :ok <- validate_switch_path(context.switch_path, mount_path),
         :ok <- adapter_authorize(adapter, actor, context, :read, context.billable) do
      {:ok, context}
    else
      {:error, reason} when reason in [:forbidden, :unavailable] -> {:error, reason}
      {:error, _reason} -> {:error, :unavailable}
      _ -> {:error, :unavailable}
    end
  end

  def resolve(_, _, _, _), do: {:error, :unavailable}

  @doc "Signs the canonical identity and Customer locator for one short-lived form flow."
  @spec mint_pin(t(), module()) :: {:ok, String.t()} | {:error, :unavailable}
  def mint_pin(%__MODULE__{} = context, endpoint) when is_atom(endpoint) do
    with %Customer{
           id: customer_id,
           owner_type: customer_owner_type,
           owner_id: customer_owner_id,
           processor: customer_processor
         } <- context.customer,
         {:ok, owner_type, owner_id} <- owner_identity(context.billable),
         true <- owner_type == context.owner_type and owner_id == context.owner_id,
         true <-
           customer_owner_type == owner_type and customer_owner_id == owner_id and
             customer_processor == context.processor,
         true <- is_binary(context.processor) and context.processor != "" do
      pin = %{
        "owner_type" => owner_type,
        "owner_id" => owner_id,
        "processor" => context.processor,
        "customer_id" => to_string(customer_id)
      }

      {:ok, Phoenix.Token.sign(endpoint, @pin_salt, pin)}
    else
      _ -> {:error, :unavailable}
    end
  rescue
    _ -> {:error, :unavailable}
  end

  def mint_pin(_, _), do: {:error, :unavailable}

  @doc "Verifies and decodes a form-flow locator. It does not authorize the flow."
  @spec verify_pin(term(), module()) :: {:ok, map()} | {:error, :invalid}
  def verify_pin(pin, endpoint) when is_binary(pin) and is_atom(endpoint) do
    case Phoenix.Token.verify(endpoint, @pin_salt, pin, max_age: @pin_max_age) do
      {:ok,
       %{
         "owner_type" => owner_type,
         "owner_id" => owner_id,
         "processor" => processor,
         "customer_id" => customer_id
       } = payload}
      when is_binary(owner_type) and owner_type != "" and is_binary(owner_id) and owner_id != "" and
             is_binary(processor) and processor != "" and is_binary(customer_id) and
             customer_id != "" ->
        {:ok, payload}

      _ ->
        {:error, :invalid}
    end
  rescue
    _ -> {:error, :invalid}
  end

  def verify_pin(_, _), do: {:error, :invalid}

  @doc "Runs the host adapter's fresh named-action policy check for this context and target."
  @spec authorize_action(t(), module() | nil, action(), term()) :: :ok | {:error, :forbidden}
  def authorize_action(%__MODULE__{} = context, nil, action, target)
      when action in [
             :read,
             :payment_method_create,
             :payment_method_default,
             :payment_method_delete,
             :subscription_cancel,
             :subscription_change,
             :subscription_preview,
             :checkout_validate_promo,
             :checkout_complete
           ] do
    if target_in_context?(context, target), do: :ok, else: {:error, :forbidden}
  end

  def authorize_action(%__MODULE__{} = context, adapter, action, target)
      when is_atom(adapter) do
    case adapter_authorize(adapter, context.actor, context, action, target) do
      :ok -> :ok
      _ -> {:error, :forbidden}
    end
  end

  def authorize_action(_, _, _, _), do: {:error, :forbidden}

  defp target_in_context?(context, target) do
    case context.customer do
      %Customer{id: customer_id} ->
        target == context.billable or target == context.customer or
          match?(%{customer_id: ^customer_id}, target)

      _ ->
        false
    end
  end

  @spec personal(struct(), Customer.t()) :: {:ok, t()} | {:error, :unavailable}
  def personal(actor, %Customer{} = customer) do
    with {:ok, owner_type, owner_id} <- owner_identity(actor) do
      {:ok,
       %__MODULE__{
         actor: actor,
         billable: actor,
         owner_type: owner_type,
         owner_id: owner_id,
         processor: customer.processor,
         customer: customer
       }}
    else
      _ -> {:error, :unavailable}
    end
  end

  @spec with_customer(t(), Customer.t() | nil) :: t()
  def with_customer(%__MODULE__{} = context, customer), do: %{context | customer: customer}

  @spec owner_identity(struct()) :: {:ok, String.t(), String.t()} | {:error, :unavailable}
  def owner_identity(%{__struct__: module, id: id}) when is_atom(module) do
    with true <- Code.ensure_loaded?(module),
         true <- function_exported?(module, :__accrue__, 1),
         owner_type when is_binary(owner_type) and owner_type != "" <-
           module.__accrue__(:billable_type),
         {:ok, owner_id} <- lossless_id(id) do
      {:ok, owner_type, owner_id}
    else
      _ -> {:error, :unavailable}
    end
  rescue
    _ -> {:error, :unavailable}
  end

  def owner_identity(_), do: {:error, :unavailable}

  @spec valid_local_path?(term()) :: boolean()
  def valid_local_path?(path) when is_binary(path) do
    String.starts_with?(path, "/") and not String.starts_with?(path, "//") and
      not String.contains?(path, "\\") and not Regex.match?(~r/[\x00-\x1f\x7f]/, path)
  end

  def valid_local_path?(_), do: false

  defp adapter_resolve(adapter, actor, selection) do
    if function_exported?(adapter, :resolve, 2) do
      case adapter.resolve(actor, selection) do
        {:ok, resolved} when is_map(resolved) -> {:ok, resolved}
        {:error, reason} when reason in [:forbidden, :unavailable] -> {:error, reason}
        _ -> {:error, :unavailable}
      end
    else
      {:error, :unavailable}
    end
  rescue
    _ -> {:error, :unavailable}
  catch
    _, _ -> {:error, :unavailable}
  end

  defp adapter_authorize(adapter, actor, context, action, target) do
    if function_exported?(adapter, :authorize, 4) do
      case adapter.authorize(actor, context, action, target) do
        :ok -> :ok
        {:error, :forbidden} -> {:error, :forbidden}
        _ -> {:error, :unavailable}
      end
    else
      {:error, :unavailable}
    end
  rescue
    _ -> {:error, :unavailable}
  catch
    _, _ -> {:error, :unavailable}
  end

  defp build_context(actor, %{billable: billable, display_name: display_name} = resolved)
       when is_binary(display_name) do
    with {:ok, owner_type, owner_id} <- owner_identity(billable),
         true <- String.trim(display_name) != "",
         display_detail when is_nil(display_detail) or is_binary(display_detail) <-
           Map.get(resolved, :display_detail),
         switch_path when is_nil(switch_path) or is_binary(switch_path) <-
           Map.get(resolved, :switch_path) do
      {:ok,
       %__MODULE__{
         actor: actor,
         billable: billable,
         owner_type: owner_type,
         owner_id: owner_id,
         processor: Processor.name(),
         display_name: display_name,
         display_detail: display_detail,
         switch_path: switch_path
       }}
    else
      _ -> {:error, :unavailable}
    end
  end

  defp build_context(_, _), do: {:error, :unavailable}

  defp validate_switch_path(nil, _mount_path), do: :ok

  defp validate_switch_path(path, mount_path) do
    if valid_local_path?(path) and path != mount_path and
         not String.starts_with?(path, mount_path <> "/") do
      :ok
    else
      {:error, :unavailable}
    end
  end

  defp lossless_id(id) when is_binary(id) and id != "", do: {:ok, id}
  defp lossless_id(id) when is_integer(id), do: {:ok, Integer.to_string(id)}
  defp lossless_id(_), do: {:error, :unavailable}
end
