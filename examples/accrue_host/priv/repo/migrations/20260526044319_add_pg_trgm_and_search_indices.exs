# accrue:generated
# accrue:fingerprint: 067910f5787f83bf3111c85c98c116758469a6fd9422794e0770a9e169f04d8d
defmodule Accrue.Repo.Migrations.AddPgTrgmAndSearchIndices do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"

    # Customers
    create index(:accrue_customers, ["email gin_trgm_ops"],
             using: :gin,
             concurrently: true,
             name: :accrue_customers_email_trgm_index
           )

    create index(:accrue_customers, ["name gin_trgm_ops"],
             using: :gin,
             concurrently: true,
             name: :accrue_customers_name_trgm_index
           )

    # Subscriptions
    create index(:accrue_subscriptions, ["processor_id gin_trgm_ops"],
             using: :gin,
             concurrently: true,
             name: :accrue_subscriptions_processor_id_trgm_index
           )

    # Invoices
    create index(:accrue_invoices, ["processor_id gin_trgm_ops"],
             using: :gin,
             concurrently: true,
             name: :accrue_invoices_processor_id_trgm_index
           )

    create index(:accrue_invoices, ["number gin_trgm_ops"],
             using: :gin,
             concurrently: true,
             name: :accrue_invoices_number_trgm_index
           )
  end

  def down do
    drop index(:accrue_customers, ["email gin_trgm_ops"],
           name: :accrue_customers_email_trgm_index
         )

    drop index(:accrue_customers, ["name gin_trgm_ops"], name: :accrue_customers_name_trgm_index)

    drop index(:accrue_subscriptions, ["processor_id gin_trgm_ops"],
           name: :accrue_subscriptions_processor_id_trgm_index
         )

    drop index(:accrue_invoices, ["processor_id gin_trgm_ops"],
           name: :accrue_invoices_processor_id_trgm_index
         )

    drop index(:accrue_invoices, ["number gin_trgm_ops"],
           name: :accrue_invoices_number_trgm_index
         )

    execute "DROP EXTENSION IF EXISTS pg_trgm"
  end
end
