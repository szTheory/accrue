defmodule Accrue.Repo.Migrations.CreateAccrueEntitlementSummaries do
  @moduledoc """
  Phase 127 (127-01) — advisory, observational-only local cache for
  Stripe's `entitlements.active_entitlement_summary` object (ENT-10, D-05).

  One row per customer (keyed on `customer_id` — the summary object has no
  top-level `id`). Thin local projection: a `data` jsonb with the raw
  payload (including the `entitlements.url` pagination handle for the
  deferred 1.2 reconcile) plus typed columns operators read/sort/filter on.

  `on_delete: :delete_all` — the summary is meaningless without its
  customer. The partial `truncated = true` index lets operators find
  known-incomplete caches (>10 inline entitlements) fast.

  Forward-only (`change` is a pure create table).
  """

  use Ecto.Migration

  def change do
    create table(:accrue_entitlement_summaries, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :processor, :string, null: false, default: "stripe"

      add :customer_id,
          references(:accrue_customers, type: :binary_id, on_delete: :delete_all),
          null: false

      add :stripe_customer_id, :string, null: true
      add :livemode, :boolean, null: true
      add :entitlement_count, :integer, null: true
      add :truncated, :boolean, null: false, default: false
      add :data, :map, null: false, default: %{}
      add :synced_at, :utc_datetime_usec, null: true
      add :lock_version, :integer, null: false, default: 1
      add :last_stripe_event_ts, :utc_datetime_usec, null: true
      add :last_stripe_event_id, :string, null: true

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:accrue_entitlement_summaries, [:customer_id])
    create index(:accrue_entitlement_summaries, [:stripe_customer_id])
    create index(:accrue_entitlement_summaries, [:truncated], where: "truncated = true")
  end
end
