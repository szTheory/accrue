defmodule Accrue.Billing.MeteredChargeAttempt do
  @moduledoc """
  Durable settlement ledger for one metered renewal window.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @statuses [:pending, :retry_scheduled, :awaiting_payment_method, :paid, :failed_exhausted]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "accrue_metered_charge_attempts" do
    belongs_to(:metered_renewal, Accrue.Billing.MeteredRenewal)

    field(:subject_uuid, :string)
    field(:status, Ecto.Enum, values: @statuses, default: :pending)
    field(:processor, :string, default: "braintree")
    field(:processor_charge_id, :string)
    field(:attempted_payment_method_id, :string)
    field(:original_failed_payment_method_id, :string)
    field(:failure_class, :string)
    field(:original_failure_class, :string)
    field(:failure_code, :string)
    field(:original_failure_code, :string)
    field(:failure_message, :string)
    field(:original_failure_message, :string)
    field(:retry_at, :utc_datetime_usec)
    field(:paid_at, :utc_datetime_usec)
    field(:data, :map, default: %{})
    field(:lock_version, :integer, default: 1)

    timestamps(type: :utc_datetime_usec)
  end

  @cast_fields ~w[
    metered_renewal_id subject_uuid status processor processor_charge_id
    attempted_payment_method_id original_failed_payment_method_id
    failure_class original_failure_class failure_code original_failure_code
    failure_message original_failure_message retry_at paid_at data lock_version
  ]a

  @required_fields ~w[metered_renewal_id subject_uuid status processor]a

  @spec statuses() :: [atom()]
  def statuses, do: @statuses

  @spec changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(attempt_or_changeset, attrs \\ %{}) do
    attempt_or_changeset
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> validate_length(:subject_uuid, min: 1)
    |> validate_length(:processor, min: 1)
    |> optimistic_lock(:lock_version)
    |> foreign_key_constraint(:metered_renewal_id)
    |> unique_constraint(:metered_renewal_id)
    |> unique_constraint(:subject_uuid)
  end
end
