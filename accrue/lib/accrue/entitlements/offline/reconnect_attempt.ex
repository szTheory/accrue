defmodule Accrue.Entitlements.Offline.ReconnectAttempt do
  @moduledoc false
  use Accrue.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accrue_entitlement_offline_reconnect_attempts" do
    field(:challenge_id, :binary_id)
    field(:account_id, :binary_id)
    field(:device_id, :binary_id)
    field(:state, Ecto.Enum, values: [:admitted, :running, :retrying, :completed, :needs_repair])
    field(:scheduled_at, :utc_datetime_usec)
    field(:started_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)
    field(:next_attempt_at, :utc_datetime_usec)
    field(:attempt_count, :integer, default: 0)
    field(:failure_reason, :string)
    field(:due_source_count, :integer, default: 0)
    field(:revision, :integer)
    field(:execution_token, :string)
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(attempt, attrs) do
    attempt
    |> cast(attrs, [
      :challenge_id,
      :account_id,
      :device_id,
      :state,
      :scheduled_at,
      :started_at,
      :completed_at,
      :next_attempt_at,
      :attempt_count,
      :failure_reason,
      :due_source_count,
      :revision,
      :execution_token
    ])
    |> validate_required([
      :challenge_id,
      :account_id,
      :device_id,
      :state,
      :scheduled_at,
      :attempt_count
    ])
    |> validate_number(:attempt_count, greater_than_or_equal_to: 0)
    |> validate_number(:due_source_count, greater_than_or_equal_to: 0)
    |> unique_constraint(:challenge_id, name: :accrue_offline_reconnect_attempt_challenge_index)
  end
end
