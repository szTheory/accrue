defmodule Accrue.Repo.Migrations.AddDiscountColumnsToInvoices do
  @moduledoc """
  Phase 4 (04-01) — BILL-28 discount breakdown column on
  `accrue_invoices`.

  `discount_minor` (bigint) was already added in Phase 3's rollup
  columns migration (`20260414120000_phase3_schema_upgrades`); this
  migration adds only the remaining `total_discount_amounts :map`
  column which mirrors Stripe's per-discount line-item breakdown
  (e.g., `[{"amount": 500, "discount": "di_..."}, ...]`).

  Deviation from plan (Rule 3 — pre-existing column): plan Task 3
  listed `discount_minor` as an add, but it already exists on
  `accrue_invoices` from Phase 3. Only `total_discount_amounts` is new.
  """

  use Ecto.Migration

  def change do
    alter table(:accrue_invoices) do
      add :total_discount_amounts, :map, null: false, default: %{}
    end
  end
end
