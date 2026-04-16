defmodule Accrue.Webhook.WebhookEvent do
  @moduledoc """
  Ecto schema for the `accrue_webhook_events` table.

  This is the single-table ledger for all inbound webhook events from
  any processor. The `status` column projects Oban's job lifecycle
  onto a queryable field for admin UI and retention management (D2-33).

  ## Status lifecycle

      :received -> :processing -> :succeeded
                               -> :failed -> :dead
      :dead -> :replayed -> :received (replay cycle)

  ## Raw body storage

  `raw_body` is stored as `:binary` (PostgreSQL `bytea`) for byte-exact
  forensic replay of signature verification (research Q1). The `Inspect`
  protocol is implemented to EXCLUDE `raw_body` from inspect output to
  prevent accidental PII logging (T-2-04a).

  ## Idempotency

  The unique index on `(processor, processor_event_id)` ensures each
  event is persisted at most once (D2-25). Duplicate POSTs return the
  existing row without re-enqueuing.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  @statuses [:received, :processing, :succeeded, :failed, :dead, :replayed]
  @endpoints [:default, :connect]

  schema "accrue_webhook_events" do
    field(:processor, :string)
    field(:processor_event_id, :string)
    field(:type, :string)
    field(:livemode, :boolean, default: false)
    field(:status, Ecto.Enum, values: @statuses, default: :received)
    field(:endpoint, Ecto.Enum, values: @endpoints, default: :default)
    field(:raw_body, :binary, redact: true)
    field(:received_at, :utc_datetime_usec)
    field(:processed_at, :utc_datetime_usec)
    field(:data, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Returns the list of valid webhook event statuses.
  """
  @spec statuses() :: [atom()]
  def statuses, do: @statuses

  @ingest_fields ~w[processor processor_event_id type livemode endpoint raw_body received_at data]a
  @ingest_required ~w[processor processor_event_id type]a

  @doc """
  Builds a changeset for the hot-path webhook insert.

  Only casts the fields needed at ingestion time. Status defaults to
  `:received` via the schema default.
  """
  @spec ingest_changeset(map()) :: Ecto.Changeset.t()
  def ingest_changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> cast(attrs, @ingest_fields)
    |> validate_required(@ingest_required)
    |> unique_constraint([:processor, :processor_event_id],
      name: :accrue_webhook_events_processor_event_id_index
    )
  end

  @doc """
  Builds a changeset for status transitions.

  Used by the Oban dispatch worker to move events through
  `:processing` -> `:succeeded` / `:failed` / `:dead` and by the
  replay path to reset to `:received`.
  """
  @spec status_changeset(%__MODULE__{}, atom()) :: Ecto.Changeset.t()
  def status_changeset(%__MODULE__{} = event, new_status) when new_status in @statuses do
    event
    |> change(status: new_status)
    |> maybe_set_processed_at(new_status)
  end

  defp maybe_set_processed_at(changeset, status)
       when status in [:succeeded, :failed, :dead] do
    put_change(changeset, :processed_at, DateTime.utc_now() |> DateTime.truncate(:microsecond))
  end

  defp maybe_set_processed_at(changeset, _status), do: changeset
end
