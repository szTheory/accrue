defmodule Accrue.Repo.Migrations.AddEventsTypeInsertedAtIndex do
  @moduledoc """
  Phase 4 (04-01) — composite index on `accrue_events (type, inserted_at)`
  to accelerate `Accrue.Events.bucket_by/3` bucketed-time-series queries
  per EVT-06.

  Index name is fixed (`accrue_events_type_inserted_at_idx`) because the
  Phase 4 query module references it in a `@hints` doc string for ops
  visibility.
  """

  use Ecto.Migration

  def change do
    create index(
             :accrue_events,
             [:type, :inserted_at],
             name: :accrue_events_type_inserted_at_idx
           )
  end
end
