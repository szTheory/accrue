# accrue:generated
# accrue:fingerprint: 549fe1678c4121e962fbd362a34ac4278b855748c8bed9655de282b9e9407f97
defmodule Accrue.Repo.Migrations.CreateAccrueBillingSchemas do
  @moduledoc """
  Creates the remaining billing tables: payment_methods, subscriptions,
  subscription_items, charges, invoices, and coupons. All follow the
  common shape: binary_id PK, processor, processor_id, metadata, data,
  lock_version, timestamps.
  """

  use Ecto.Migration

  def change do
    # --- Payment Methods ---

    create table(:accrue_payment_methods, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")

      add :customer_id, references(:accrue_customers, type: :binary_id, on_delete: :delete_all),
        null: false

      add :processor, :string, null: false
      add :processor_id, :string
      add :type, :string
      add :is_default, :boolean, default: false, null: false
      add :fingerprint, :string
      add :card_brand, :string
      add :card_last4, :string
      add :card_exp_month, :integer
      add :card_exp_year, :integer
      add :metadata, :map, default: %{}, null: false
      add :data, :map, default: %{}, null: false
      add :lock_version, :integer, default: 1, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:accrue_payment_methods, [:customer_id])
    create index(:accrue_payment_methods, [:processor_id])

    create unique_index(:accrue_payment_methods, [:processor, :processor_id],
             where: "processor_id IS NOT NULL",
             name: :accrue_payment_methods_processor_processor_id_index
           )

    # --- Subscriptions ---

    create table(:accrue_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")

      add :customer_id, references(:accrue_customers, type: :binary_id, on_delete: :delete_all),
        null: false

      add :processor, :string, null: false
      add :processor_id, :string
      add :status, :string
      add :current_period_start, :utc_datetime_usec
      add :current_period_end, :utc_datetime_usec
      add :trial_start, :utc_datetime_usec
      add :trial_end, :utc_datetime_usec
      add :cancel_at, :utc_datetime_usec
      add :canceled_at, :utc_datetime_usec
      add :ended_at, :utc_datetime_usec
      add :metadata, :map, default: %{}, null: false
      add :data, :map, default: %{}, null: false
      add :lock_version, :integer, default: 1, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:accrue_subscriptions, [:customer_id])
    create index(:accrue_subscriptions, [:processor_id])

    create unique_index(:accrue_subscriptions, [:processor, :processor_id],
             where: "processor_id IS NOT NULL",
             name: :accrue_subscriptions_processor_processor_id_index
           )

    # --- Subscription Items ---

    create table(:accrue_subscription_items, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")

      add :subscription_id,
          references(:accrue_subscriptions, type: :binary_id, on_delete: :delete_all),
          null: false

      add :processor, :string, null: false
      add :processor_id, :string
      add :price_id, :string
      add :quantity, :integer, default: 1, null: false
      add :metadata, :map, default: %{}, null: false
      add :data, :map, default: %{}, null: false
      add :lock_version, :integer, default: 1, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:accrue_subscription_items, [:subscription_id])
    create index(:accrue_subscription_items, [:processor_id])

    create unique_index(:accrue_subscription_items, [:processor, :processor_id],
             where: "processor_id IS NOT NULL",
             name: :accrue_subscription_items_processor_processor_id_index
           )

    # --- Charges ---

    create table(:accrue_charges, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")

      add :customer_id, references(:accrue_customers, type: :binary_id, on_delete: :delete_all),
        null: false

      add :subscription_id,
          references(:accrue_subscriptions, type: :binary_id, on_delete: :nilify_all)

      add :payment_method_id,
          references(:accrue_payment_methods, type: :binary_id, on_delete: :nilify_all)

      add :processor, :string, null: false
      add :processor_id, :string
      add :amount_cents, :integer
      add :currency, :string
      add :status, :string
      add :metadata, :map, default: %{}, null: false
      add :data, :map, default: %{}, null: false
      add :lock_version, :integer, default: 1, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:accrue_charges, [:customer_id])
    create index(:accrue_charges, [:subscription_id])
    create index(:accrue_charges, [:processor_id])

    create unique_index(:accrue_charges, [:processor, :processor_id],
             where: "processor_id IS NOT NULL",
             name: :accrue_charges_processor_processor_id_index
           )

    # --- Invoices ---

    create table(:accrue_invoices, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")

      add :customer_id, references(:accrue_customers, type: :binary_id, on_delete: :delete_all),
        null: false

      add :subscription_id,
          references(:accrue_subscriptions, type: :binary_id, on_delete: :nilify_all)

      add :processor, :string, null: false
      add :processor_id, :string
      add :status, :string
      add :total_cents, :integer
      add :currency, :string
      add :due_date, :utc_datetime_usec
      add :paid_at, :utc_datetime_usec
      add :metadata, :map, default: %{}, null: false
      add :data, :map, default: %{}, null: false
      add :lock_version, :integer, default: 1, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:accrue_invoices, [:customer_id])
    create index(:accrue_invoices, [:subscription_id])
    create index(:accrue_invoices, [:processor_id])

    create unique_index(:accrue_invoices, [:processor, :processor_id],
             where: "processor_id IS NOT NULL",
             name: :accrue_invoices_processor_processor_id_index
           )

    # --- Coupons ---

    create table(:accrue_coupons, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :processor, :string, null: false
      add :processor_id, :string
      add :name, :string
      add :amount_off_cents, :integer
      add :percent_off, :decimal
      add :currency, :string
      add :duration, :string
      add :duration_in_months, :integer
      add :max_redemptions, :integer
      add :times_redeemed, :integer, default: 0, null: false
      add :valid, :boolean, default: true, null: false
      add :metadata, :map, default: %{}, null: false
      add :data, :map, default: %{}, null: false
      add :lock_version, :integer, default: 1, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:accrue_coupons, [:processor_id])

    create unique_index(:accrue_coupons, [:processor, :processor_id],
             where: "processor_id IS NOT NULL",
             name: :accrue_coupons_processor_processor_id_index
           )
  end
end
