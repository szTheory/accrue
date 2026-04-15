defmodule Accrue.Repo.Migrations.AddPhase7AdminIndexes do
  use Ecto.Migration

  def change do
    create_if_not_exists(
      index(:accrue_customers, [:inserted_at, :id], name: :accrue_customers_inserted_at_id_idx)
    )

    create_if_not_exists(index(:accrue_customers, [:email], name: :accrue_customers_email_idx))

    create_if_not_exists(
      index(:accrue_subscriptions, [:status, :inserted_at, :id],
        name: :accrue_subscriptions_status_inserted_at_id_idx
      )
    )

    create_if_not_exists(
      index(:accrue_subscriptions, [:customer_id, :inserted_at, :id],
        name: :accrue_subscriptions_customer_inserted_at_id_idx
      )
    )

    create_if_not_exists(
      index(:accrue_invoices, [:status, :inserted_at, :id],
        name: :accrue_invoices_status_inserted_at_id_idx
      )
    )

    create_if_not_exists(
      index(:accrue_invoices, [:customer_id, :inserted_at, :id],
        name: :accrue_invoices_customer_inserted_at_id_idx
      )
    )

    create_if_not_exists(
      unique_index(:accrue_invoices, [:number],
        where: "number IS NOT NULL",
        name: :accrue_invoices_number_index
      )
    )

    create_if_not_exists(
      index(:accrue_charges, [:status, :inserted_at, :id],
        name: :accrue_charges_status_inserted_at_id_idx
      )
    )

    create_if_not_exists(
      index(:accrue_charges, [:customer_id, :inserted_at, :id],
        name: :accrue_charges_customer_inserted_at_id_idx
      )
    )

    create_if_not_exists(
      index(:accrue_coupons, [:valid, :inserted_at, :id],
        name: :accrue_coupons_valid_inserted_at_id_idx
      )
    )

    create_if_not_exists(
      index(:accrue_promotion_codes, [:active, :inserted_at, :id],
        name: :accrue_promotion_codes_active_inserted_at_id_idx
      )
    )

    create_if_not_exists(
      index(:accrue_connect_accounts, [:charges_enabled, :inserted_at, :id],
        name: :accrue_connect_accounts_charges_enabled_inserted_at_id_idx
      )
    )
  end
end
