# accrue:generated
# accrue:fingerprint: a13ac5ec504e7ae2473f6ab72a505ab9c77132608e6e36cb369bc223e5063b85
defmodule Accrue.Repo.Migrations.Phase3SchemaUpgrades do
  @moduledoc """
  Phase 3 Wave 1 schema upgrades (03-02).

  Adds the columns, tables, and indexes required for the Phase 3 core
  subscription lifecycle work: status Ecto.Enum casts, cancel-at-period-end,
  pause collection, D3-14 invoice rollup columns, D3-15 invoice items,
  D3-16 coupons redemption link, D3-45 refund fee tracking, D3-48 payment
  method fingerprint dedup, D3-52 customer default payment method FK, and
  D3-56 last-stripe-event watermarks on every billing table.

  All changes are additive. Existing Phase 2 rows survive unchanged — the
  new columns are nullable (or default to safe values where the schema
  demands non-null).
  """

  use Ecto.Migration

  def change do
    # --- accrue_subscriptions ---

    alter table(:accrue_subscriptions) do
      modify :status, :string, null: false, default: "incomplete", from: {:string, null: true}
      add :cancel_at_period_end, :boolean, null: false, default: false
      add :pause_collection, :map, null: true
      add :last_stripe_event_ts, :utc_datetime_usec, null: true
      add :last_stripe_event_id, :string, null: true
    end

    # --- accrue_subscription_items ---

    alter table(:accrue_subscription_items) do
      add :processor_plan_id, :string, null: true
      add :processor_product_id, :string, null: true
      add :current_period_start, :utc_datetime_usec, null: true
      add :current_period_end, :utc_datetime_usec, null: true
      add :last_stripe_event_ts, :utc_datetime_usec, null: true
      add :last_stripe_event_id, :string, null: true
    end

    # --- accrue_invoices (D3-14 rollup columns) ---

    alter table(:accrue_invoices) do
      modify :status, :string, null: false, default: "draft", from: {:string, null: true}
      add :subtotal_minor, :bigint, null: true
      add :tax_minor, :bigint, null: true
      add :discount_minor, :bigint, null: true
      add :total_minor, :bigint, null: true
      add :amount_due_minor, :bigint, null: true
      add :amount_paid_minor, :bigint, null: true
      add :amount_remaining_minor, :bigint, null: true
      add :number, :string, null: true
      add :hosted_url, :string, null: true
      add :pdf_url, :string, null: true
      add :period_start, :utc_datetime_usec, null: true
      add :period_end, :utc_datetime_usec, null: true
      add :collection_method, :string, null: true
      add :billing_reason, :string, null: true
      add :finalized_at, :utc_datetime_usec, null: true
      add :voided_at, :utc_datetime_usec, null: true
      add :last_stripe_event_ts, :utc_datetime_usec, null: true
      add :last_stripe_event_id, :string, null: true
    end

    # --- accrue_invoice_items (D3-15, new table) ---

    create table(:accrue_invoice_items, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")

      add :invoice_id,
          references(:accrue_invoices, type: :binary_id, on_delete: :delete_all),
          null: false

      add :stripe_id, :string, null: true
      add :description, :text, null: true
      add :amount_minor, :bigint, null: false
      add :currency, :string, null: false
      add :quantity, :integer, null: true
      add :period_start, :utc_datetime_usec, null: true
      add :period_end, :utc_datetime_usec, null: true
      add :proration, :boolean, null: false, default: false
      add :price_ref, :string, null: true
      add :subscription_item_ref, :string, null: true
      add :data, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:accrue_invoice_items, [:invoice_id])

    create unique_index(:accrue_invoice_items, [:stripe_id],
             where: "stripe_id IS NOT NULL",
             name: :accrue_invoice_items_stripe_id_index
           )

    # --- accrue_invoice_coupons (D3-16 redemption link) ---

    create table(:accrue_invoice_coupons, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")

      add :invoice_id,
          references(:accrue_invoices, type: :binary_id, on_delete: :delete_all),
          null: false

      add :coupon_id,
          references(:accrue_coupons, type: :binary_id, on_delete: :restrict),
          null: false

      add :amount_off_minor, :bigint, null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:accrue_invoice_coupons, [:invoice_id])
    create index(:accrue_invoice_coupons, [:coupon_id])

    # --- accrue_charges (fee tracking) ---

    alter table(:accrue_charges) do
      add :stripe_fee_amount_minor, :bigint, null: true
      add :stripe_fee_currency, :string, null: true
      add :fees_settled_at, :utc_datetime_usec, null: true
      add :last_stripe_event_ts, :utc_datetime_usec, null: true
      add :last_stripe_event_id, :string, null: true
    end

    # --- accrue_refunds (D3-45, new table) ---

    create table(:accrue_refunds, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")

      add :charge_id,
          references(:accrue_charges, type: :binary_id, on_delete: :restrict),
          null: false

      add :stripe_id, :string, null: true
      add :amount_minor, :bigint, null: false
      add :currency, :string, null: false
      add :reason, :string, null: true
      add :status, :string, null: false, default: "pending"
      add :stripe_fee_refunded_amount_minor, :bigint, null: true
      add :merchant_loss_amount_minor, :bigint, null: true
      add :fees_settled_at, :utc_datetime_usec, null: true
      add :data, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}
      add :lock_version, :integer, null: false, default: 1
      add :last_stripe_event_ts, :utc_datetime_usec, null: true
      add :last_stripe_event_id, :string, null: true

      timestamps(type: :utc_datetime_usec)
    end

    create index(:accrue_refunds, [:charge_id])

    create unique_index(:accrue_refunds, [:stripe_id],
             where: "stripe_id IS NOT NULL",
             name: :accrue_refunds_stripe_id_index
           )

    create index(:accrue_refunds, [:fees_settled_at],
             where: "fees_settled_at IS NULL",
             name: :accrue_refunds_unsettled_fees_index
           )

    # --- accrue_payment_methods (fingerprint dedup + expiry) ---

    alter table(:accrue_payment_methods) do
      add :exp_month, :integer, null: true
      add :exp_year, :integer, null: true
      add :last_stripe_event_ts, :utc_datetime_usec, null: true
      add :last_stripe_event_id, :string, null: true
    end

    create unique_index(:accrue_payment_methods, [:customer_id, :fingerprint],
             name: :accrue_payment_methods_customer_fingerprint_idx,
             where: "fingerprint IS NOT NULL"
           )

    # --- accrue_customers (default payment method FK + event watermark) ---

    alter table(:accrue_customers) do
      add :default_payment_method_id,
          references(:accrue_payment_methods, type: :binary_id, on_delete: :nilify_all),
          null: true

      add :last_stripe_event_ts, :utc_datetime_usec, null: true
      add :last_stripe_event_id, :string, null: true
    end
  end
end
