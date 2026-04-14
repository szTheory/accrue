defmodule Accrue.Repo.Migrations.CreateAccruePromotionCodes do
  @moduledoc """
  Phase 4 (04-01) — thin passthrough table for Stripe Promotion Codes
  (BILL-27).

  Per BILL-27 Claude's Discretion, Phase 4 denormalizes only the fields
  the admin LiveView filters/sorts on (code, active, max_redemptions,
  times_redeemed, expires_at) plus `coupon_id` as an FK to Phase 3's
  `accrue_coupons` so the admin UI can navigate the relationship.

  Uses `processor_id` convention (not `stripe_id`) matching Phase 3
  D3-15. `code` has its own unique index because Stripe promotion codes
  are case-sensitive and must round-trip losslessly.
  """

  use Ecto.Migration

  def change do
    create table(:accrue_promotion_codes, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :processor, :string, null: false, default: "stripe"
      add :processor_id, :string, null: false
      add :code, :string, null: false

      add :coupon_id,
          references(:accrue_coupons, type: :binary_id, on_delete: :nilify_all),
          null: true

      add :active, :boolean, null: false, default: true
      add :max_redemptions, :integer, null: true
      add :times_redeemed, :integer, null: false, default: 0
      add :expires_at, :utc_datetime_usec, null: true
      add :data, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}
      add :lock_version, :integer, null: false, default: 1
      add :last_stripe_event_ts, :utc_datetime_usec, null: true
      add :last_stripe_event_id, :string, null: true

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:accrue_promotion_codes, [:processor_id])
    create unique_index(:accrue_promotion_codes, [:code])
    create index(:accrue_promotion_codes, [:coupon_id])
  end
end
