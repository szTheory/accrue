defmodule Accrue.Repo.Migrations.AddDunningAndPauseColumnsToSubscriptions do
  @moduledoc """
  Phase 4 (04-01) — dunning grace-period overlay columns (D4-02) and
  pause/resume columns (BILL-11) on `accrue_subscriptions`, plus
  `discount_id` passthrough column for BILL-28 sub-level discount
  composition.

  All additions are nullable — existing Phase 3 rows survive unchanged.
  Dunning-driven writes MUST flow through `force_status_changeset/2`
  (D3-17) on the webhook path; this migration only adds the schema
  surface. Logic lives in plans 04-03 (dunning sweeper) and 04-04
  (pause/resume).

  Partial index on `past_due_since IS NOT NULL` accelerates the 15-min
  sweeper query per D4-02 without bloating the main write path.
  """

  use Ecto.Migration

  def change do
    alter table(:accrue_subscriptions) do
      add :past_due_since, :utc_datetime_usec, null: true
      add :dunning_sweep_attempted_at, :utc_datetime_usec, null: true
      add :paused_at, :utc_datetime_usec, null: true
      add :pause_behavior, :string, null: true
      add :discount_id, :string, null: true
    end

    create index(
             :accrue_subscriptions,
             [:past_due_since],
             where: "past_due_since IS NOT NULL",
             name: :accrue_subscriptions_past_due_since_idx
           )
  end
end
