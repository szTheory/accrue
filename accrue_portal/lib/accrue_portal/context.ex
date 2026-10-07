defmodule Accrue.Portal.Context do
  @moduledoc """
  Server-resolved identity and presentation data for one Portal request.

  The human actor performs policy checks. The billable identifies the billing
  owner. Display fields are presentation only and never grant access.

  Context adapters expose a closed action vocabulary: `:read`,
  `:manage_payment_methods`, `:manage_subscription`, and `:complete_checkout`.
  Adapters must reload their own membership and billable records before
  authorizing an action; a session selection or pin is only a locator.
  """

  alias Accrue.Billing.Customer
  alias Accrue.Processor

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
          | :manage_subscription
          | :complete_checkout

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

  @spec personal(struct(), Customer.t()) :: {:ok, t()} | {:error, :unavailable}
  def personal(actor, %Customer{} = customer) do
    with {:ok, owner_type, owner_id} <- owner_identity(actor) do
      {:ok,
       %__MODULE__{
         actor: actor,
         billable: actor,
         owner_type: owner_type,
         owner_id: owner_id,
         processor: Processor.name(),
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
