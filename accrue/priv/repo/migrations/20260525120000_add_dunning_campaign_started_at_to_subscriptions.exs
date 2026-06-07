defmodule Accrue.Repo.Migrations.AddDunningCampaignStartedAtToSubscriptions do
  @moduledoc """
  Phase 128 (128-02) — campaign anchor column (D-08) on `accrue_subscriptions`.

  Adds the single nullable anchor `dunning_campaign_started_at`. This column
  is the dunning-campaign identity and first-transition edge signal that the
  downstream engine keys on: the D-09 atomic `update_all WHERE is_nil(...)`
  elector (set-once start), the D-11 worker cancel-guard, and the D-12
  cancel-on-recovery clear all depend on it.

  Nullable, forward-only, mirrors the sibling `dunning_sweep_attempted_at`
  column added in `20260414130300_add_dunning_and_pause_columns_to_subscriptions`.
  Existing rows survive with a `nil` anchor — no backfill needed.

  No index: per D-08 no index is required for correctness. The optional partial
  `WHERE dunning_campaign_started_at IS NOT NULL` index is explicitly deferred
  to Phase 129.
  """

  use Ecto.Migration

  def change do
    alter Accrue.Migration.table(:accrue_subscriptions) do
      add(:dunning_campaign_started_at, :utc_datetime_usec, null: true)
    end
  end
end
