defmodule Accrue.Entitlements.PurchaseOperation do
  @moduledoc false

  use Accrue.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "accrue_entitlement_purchase_operations" do
    field(:account_id, :binary_id)
    field(:operation_id, :string)
    field(:rail, Ecto.Enum, values: [:stripe])
    field(:product_id, :string)
    field(:status, Ecto.Enum, values: [:pending_reconcile, :completed])
    field(:subscription_id, :string)
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(operation, attrs) do
    operation
    |> cast(attrs, [:account_id, :operation_id, :rail, :product_id, :status, :subscription_id])
    |> validate_required([:account_id, :operation_id, :rail, :product_id, :status])
    |> unique_constraint(:operation_id,
      name: :accrue_entitlement_purchase_operations_account_operation_index
    )
  end

  def fetch(repo, account_id, operation_id) do
    repo.one(
      from(operation in __MODULE__,
        where: operation.account_id == ^account_id and operation.operation_id == ^operation_id
      )
    )
  end

  @doc """
  Claims an operation before a provider create is dispatched.

  The database's account/operation unique index is the synchronization point:
  exactly one caller receives `:claimed`; every contender receives the durable
  operation that it must reconcile instead of creating another subscription.
  """
  def claim_pending(repo, account_id, operation_id, product_id) do
    attrs = %{
      account_id: account_id,
      operation_id: operation_id,
      rail: :stripe,
      product_id: product_id,
      status: :pending_reconcile
    }

    case repo.insert(changeset(%__MODULE__{}, attrs),
           on_conflict: :nothing,
           conflict_target: [:account_id, :operation_id]
         ) do
      {:ok, %__MODULE__{id: nil}} -> {:existing, fetch(repo, account_id, operation_id)}
      {:ok, %__MODULE__{} = operation} -> {:claimed, operation}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def complete(repo, %__MODULE__{} = operation, subscription_id) do
    operation
    |> changeset(%{status: :completed, subscription_id: subscription_id})
    |> repo.update()
  end
end
