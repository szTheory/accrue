# accrue:generated
# accrue:fingerprint: fec7d9c77742234308da6c2ac5c133e7bdde318516be88a8d554bce5dd334dea
defmodule Accrue.Repo.Migrations.AddMissingCouponColumns do
  @moduledoc """
  Phase 4 (04-05) — Rule 1 bug fix: close Phase 3 `accrue_coupons`
  schema/DB drift.

  The `Accrue.Billing.Coupon` schema declares `:amount_off_minor`
  (bigint) and `:redeem_by` (utc_datetime_usec) fields from Phase 3
  D3-16 forward, but the original
  `20260412100002_create_accrue_billing_schemas.exs` migration never
  added those columns. As a result every SELECT on the table crashes
  with `column a0.amount_off_minor does not exist` the moment any
  caller hits the table.

  This migration closes the drift by adding both columns. The unit
  is `bigint` for `amount_off_minor` per D3 rollup column convention
  (same reasoning as `accrue_invoices.discount_minor`: annual /
  multi-year totals can exceed 2^31).
  """

  use Ecto.Migration

  def change do
    alter table(:accrue_coupons) do
      add :amount_off_minor, :bigint
      add :redeem_by, :utc_datetime_usec
    end
  end
end
