defmodule Accrue.Entitlements.Offline.ReconnectWakeup do
  @moduledoc false
  use Accrue.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accrue_entitlement_offline_reconnect_wakeups" do
    field(:attempt_id, :binary_id)
    field(:requested_at, :utc_datetime_usec)
    timestamps(type: :utc_datetime_usec)
  end

  def enqueue_in_transaction(repo, attempt_id, now) do
    repo.insert(changeset(%__MODULE__{}, %{attempt_id: attempt_id, requested_at: now}),
      on_conflict: [set: [requested_at: now, updated_at: now]],
      conflict_target: [:attempt_id]
    )
  end

  defp changeset(wakeup, attrs),
    do:
      wakeup
      |> cast(attrs, [:attempt_id, :requested_at])
      |> validate_required([:attempt_id, :requested_at])
end
