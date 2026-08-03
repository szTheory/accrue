defmodule Accrue.Entitlements.Apple.ReconciliationWakeup do
  @moduledoc false
  use Accrue.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accrue_entitlement_apple_reconciliation_wakeups" do
    field(:lineage_id, :binary_id)
    field(:environment, Ecto.Enum, values: [:production, :sandbox])
    field(:reason, :string)
    field(:requested_at, :utc_datetime_usec)
    timestamps(type: :utc_datetime_usec)
  end

  def enqueue_in_transaction(repo, lineage_id, environment, reason, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    changeset =
      changeset(%__MODULE__{}, %{
        lineage_id: lineage_id,
        environment: environment,
        reason: to_string(reason),
        requested_at: now
      })

    repo.insert(changeset,
      on_conflict: [set: [reason: to_string(reason), requested_at: now, updated_at: now]],
      conflict_target: [:lineage_id, :environment]
    )
  end

  defp changeset(wakeup, attrs),
    do:
      cast(wakeup, attrs, [:lineage_id, :environment, :reason, :requested_at])
      |> validate_required([:lineage_id, :environment, :reason, :requested_at])
end
