defmodule Accrue.Billing.Invoice do
  @moduledoc """
  Ecto schema for the `accrue_invoices` table.

  Stores the local copy of a Stripe invoice, including all rollup columns
  (`subtotal_minor`, `tax_minor`, `total_minor`, etc.) that the admin UI
  and application logic need without round-tripping to Stripe. The `data`
  jsonb column holds the full Stripe payload for callers that need the
  raw shape.

  For mutations (`finalize_invoice`, `pay_invoice`, `void_invoice`, etc.)
  see `Accrue.Billing.InvoiceActions`, which is the correct entry point
  for any write operation.

  ## Legal user-path transitions

      draft -> open | void
      open  -> paid | uncollectible | void
      paid, uncollectible, void  -> (terminal)

  ## Changeset paths

  Two changeset functions exist to support the two sources of status
  changes:

    * `changeset/2` — enforces the transition table; use for user-originated
      writes (`finalize_invoice`, `pay_invoice`, `void_invoice`).
    * `force_status_changeset/2` — bypasses transition validation; use only
      from the webhook reconcile path where Stripe is canonical.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Accrue.Billing.Metadata

  @statuses [:draft, :open, :paid, :uncollectible, :void]

  @legal_user_transitions %{
    draft: [:open, :void],
    open: [:paid, :uncollectible, :void],
    paid: [],
    uncollectible: [],
    void: []
  }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "accrue_invoices" do
    belongs_to(:customer, Accrue.Billing.Customer)
    belongs_to(:subscription, Accrue.Billing.Subscription)
    has_many(:items, Accrue.Billing.InvoiceItem)

    field(:processor, :string)
    field(:processor_id, :string)
    field(:status, Ecto.Enum, values: @statuses, default: :draft)
    field(:total_cents, :integer)
    field(:currency, :string)
    field(:due_date, :utc_datetime_usec)
    field(:paid_at, :utc_datetime_usec)

    # Rollup columns — denormalized from the Stripe invoice for local queries
    field(:subtotal_minor, :integer)
    field(:tax_minor, :integer)
    field(:automatic_tax, :boolean, default: false)
    field(:automatic_tax_status, :string)
    field(:automatic_tax_disabled_reason, :string)
    field(:last_finalization_error_code, :string)
    field(:discount_minor, :integer)
    field(:total_discount_amounts, :map, default: %{})
    field(:total_minor, :integer)
    field(:amount_due_minor, :integer)
    field(:amount_paid_minor, :integer)
    field(:amount_remaining_minor, :integer)
    field(:number, :string)
    field(:hosted_url, :string)
    field(:pdf_url, :string)
    field(:period_start, :utc_datetime_usec)
    field(:period_end, :utc_datetime_usec)
    field(:collection_method, :string)
    field(:billing_reason, :string)
    field(:finalized_at, :utc_datetime_usec)
    field(:voided_at, :utc_datetime_usec)
    field(:last_stripe_event_ts, :utc_datetime_usec)
    field(:last_stripe_event_id, :string)

    field(:metadata, :map, default: %{})
    field(:data, :map, default: %{})
    field(:lock_version, :integer, default: 1)

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    customer_id subscription_id processor processor_id
    status total_cents currency due_date paid_at
    subtotal_minor tax_minor automatic_tax automatic_tax_status automatic_tax_disabled_reason
    last_finalization_error_code discount_minor total_discount_amounts total_minor
    amount_due_minor amount_paid_minor amount_remaining_minor
    number hosted_url pdf_url period_start period_end
    collection_method billing_reason finalized_at voided_at
    last_stripe_event_ts last_stripe_event_id
    metadata data lock_version
  ]a

  @required_fields []

  @doc "Canonical list of invoice statuses."
  @spec statuses() :: [atom()]
  def statuses, do: @statuses

  @doc """
  Builds a user-path changeset. Enforces the legal transition table —
  illegal transitions add an error on `:status`.
  """
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(invoice_or_changeset, attrs \\ %{}) do
    invoice_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> Metadata.validate_metadata(:metadata)
    |> validate_transition()
    |> optimistic_lock(:lock_version)
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:subscription_id)
  end

  @doc """
  Builds a webhook-path changeset. Stripe is canonical in this path, so
  the transition table is bypassed. Use only from the webhook reconcile
  path.
  """
  @spec force_status_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def force_status_changeset(invoice_or_changeset, attrs \\ %{}) do
    invoice_or_changeset
    |> cast(attrs, @cast_fields)
    |> Metadata.validate_metadata(:metadata)
    |> optimistic_lock(:lock_version)
    |> foreign_key_constraint(:customer_id)
    |> foreign_key_constraint(:subscription_id)
  end

  @doc """
  Webhook-path discount denormalization. Mirrors Stripe's
  `discount_minor` + `total_discount_amounts` into local columns.
  Stripe is canonical — no local math, no `validate_number` guard.
  Callers pass nil-safe attrs so the cast preserves existing values
  when the webhook doesn't carry them.
  """
  @spec force_discount_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def force_discount_changeset(invoice_or_changeset, attrs \\ %{}) do
    invoice_or_changeset
    |> cast(attrs, [:discount_minor, :total_discount_amounts])
    |> optimistic_lock(:lock_version)
  end

  defp validate_transition(%Ecto.Changeset{changes: %{status: new}} = cs) do
    case cs.data.status do
      nil ->
        cs

      ^new ->
        cs

      old ->
        legal = Map.get(@legal_user_transitions, old, [])

        if new in legal do
          cs
        else
          add_error(cs, :status, "illegal user-path transition from #{old} to #{new}")
        end
    end
  end

  defp validate_transition(cs), do: cs
end
