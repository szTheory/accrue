defmodule Accrue.Events.Event do
  @moduledoc """
  Ecto schema for a row in the append-only `accrue_events` table.

  This module exposes a `changeset/1` for **inserts** and typed reads
  via the schema reflection. It deliberately does NOT expose update or
  delete helpers (D-12): the Postgres trigger would reject such a call
  anyway, and keeping the helpers absent from the API prevents callers
  from writing code that looks like it could work and then blows up in
  production.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @actor_types ~w[user system webhook oban admin]

  @type t :: %__MODULE__{
          id: integer() | nil,
          type: String.t() | nil,
          schema_version: integer() | nil,
          actor_type: String.t() | nil,
          actor_id: String.t() | nil,
          subject_type: String.t() | nil,
          subject_id: String.t() | nil,
          data: map(),
          trace_id: String.t() | nil,
          idempotency_key: String.t() | nil,
          caused_by_event_id: integer() | nil,
          caused_by_webhook_event_id: Ecto.UUID.t() | nil,
          inserted_at: DateTime.t() | nil
        }

  @primary_key {:id, :id, autogenerate: true}
  schema "accrue_events" do
    field(:type, :string)
    field(:schema_version, :integer, default: 1)
    field(:actor_type, :string)
    field(:actor_id, :string)
    field(:subject_type, :string)
    field(:subject_id, :string)
    field(:data, :map, default: %{})
    field(:trace_id, :string)
    field(:idempotency_key, :string)
    field(:caused_by_event_id, :integer)
    field(:caused_by_webhook_event_id, Ecto.UUID)
    field(:inserted_at, :utc_datetime_usec, read_after_writes: true)
  end

  @cast_fields ~w[
    type schema_version actor_type actor_id
    subject_type subject_id data trace_id idempotency_key
    caused_by_event_id caused_by_webhook_event_id
  ]a

  @required_fields ~w[type actor_type subject_type subject_id]a

  @doc """
  Builds an insert changeset from a plain attrs map.

  Validates required fields and the `actor_type` enum (belt-and-suspenders
  with the Postgres CHECK constraint — fails loud at the Ecto layer so
  tests don't have to hit the database for actor-type typos).
  """
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:actor_type, @actor_types)
  end
end
