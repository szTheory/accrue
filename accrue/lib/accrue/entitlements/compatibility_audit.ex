defmodule Accrue.Entitlements.CompatibilityAudit do
  @moduledoc false

  use Accrue.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accrue_entitlement_compatibility_audits" do
    belongs_to(:account, Accrue.Entitlements.Account, type: :binary_id)
    field(:action, Ecto.Enum, values: [:compare, :enable, :backfill, :rollback])
    field(:disposition, Ecto.Enum, values: [:match, :blocked, :enabled, :rolled_back, :completed])

    field(:reason, Ecto.Enum,
      values: [
        :none,
        :unmapped_legacy,
        :projection_ambiguous,
        :normalized_mismatch,
        :comparison_unavailable,
        :clean_window_blocked,
        :parity_blocked
      ]
    )

    field(:blocker_count, :integer, default: 0)
    field(:comparison_count, :integer, default: 0)
    field(:cohort_digest, :string)
    field(:catalog_digest, :string)
    field(:config_digest, :string)
    field(:state_digest, :string)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(audit, attrs) do
    audit
    |> cast(attrs, [
      :account_id,
      :action,
      :disposition,
      :reason,
      :blocker_count,
      :comparison_count,
      :cohort_digest,
      :catalog_digest,
      :config_digest,
      :state_digest
    ])
    |> validate_required([:action, :disposition, :reason, :blocker_count, :comparison_count])
    |> validate_number(:blocker_count, greater_than_or_equal_to: 0)
    |> validate_number(:comparison_count, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:account_id,
      name: :accrue_entitlement_compatibility_audits_account_id_fkey
    )
  end
end
