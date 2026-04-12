defmodule Accrue.Billing.Customer do
  @moduledoc """
  Ecto schema for the `accrue_customers` table.

  The Customer is the fully-realized polymorphic schema linking a host
  app's billable record (User, Organization, Team, etc.) to a processor
  customer (e.g. Stripe `cus_xxx`).

  ## Polymorphic ownership

  `owner_type` and `owner_id` are explicit string columns (D2-01, D2-02),
  lossless across UUID, bigint, ULID, or any future PK format. The composite
  unique index `(owner_type, owner_id, processor)` enforces one customer per
  billable per processor.

  ## Metadata

  The `metadata` field follows the exact Stripe metadata contract (D2-07):
  flat `%{String.t() => String.t()}`, max 50 keys, keys max 40 chars,
  values max 500 chars, no nested maps. See `Accrue.Billing.Metadata`.

  ## Optimistic locking

  All writes use `Ecto.Changeset.optimistic_lock/2` on `lock_version`
  to prevent torn writes when a user update and webhook reconcile race
  on the same customer (D2-09).
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_customers" do
    field :owner_type, :string
    field :owner_id, :string
    field :processor, :string
    field :processor_id, :string
    field :name, :string
    field :email, :string
    field :metadata, :map, default: %{}
    field :data, :map, default: %{}
    field :lock_version, :integer, default: 1

    has_many :payment_methods, Accrue.Billing.PaymentMethod
    has_many :subscriptions, Accrue.Billing.Subscription
    has_many :charges, Accrue.Billing.Charge
    has_many :invoices, Accrue.Billing.Invoice

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    owner_type owner_id processor processor_id
    name email metadata data lock_version
  ]a

  @required_fields ~w[owner_type owner_id processor]a

  @doc """
  Builds a changeset for creating or updating a Customer.

  Validates required fields, enforces Stripe-compatible metadata
  constraints, and applies optimistic locking.
  """
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(customer_or_changeset, attrs \\ %{}) do
    customer_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
    |> unique_constraint(:owner_id,
      name: :accrue_customers_owner_type_owner_id_processor_index
    )
  end
end
