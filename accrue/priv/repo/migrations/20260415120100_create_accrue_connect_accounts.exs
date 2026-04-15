defmodule Accrue.Repo.Migrations.CreateAccrueConnectAccounts do
  @moduledoc """
  Creates `accrue_connect_accounts` per D5-02 — the local projection of
  Stripe Connected Accounts (`acct_*`). Owned by the platform; host
  tenancy is recorded via polymorphic owner_type/owner_id columns
  mirroring `accrue_customers` (D2-01, D2-02).

  Soft-deletion via `deauthorized_at` (D5-05) — rows are never hard
  deleted to preserve the audit trail.
  """

  use Ecto.Migration

  def change do
    create table(:accrue_connect_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :stripe_account_id, :string, null: false
      add :owner_type, :string
      add :owner_id, :string
      add :type, :string, null: false
      add :country, :string
      add :email, :string
      add :charges_enabled, :boolean, null: false, default: false
      add :details_submitted, :boolean, null: false, default: false
      add :payouts_enabled, :boolean, null: false, default: false
      add :capabilities, :map, default: %{}, null: false
      add :requirements, :map, default: %{}, null: false
      add :data, :map, default: %{}, null: false
      add :deauthorized_at, :utc_datetime_usec
      add :lock_version, :integer, null: false, default: 1

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:accrue_connect_accounts, [:stripe_account_id])
    create index(:accrue_connect_accounts, [:owner_type, :owner_id])

    create index(:accrue_connect_accounts, [:charges_enabled],
             where: "charges_enabled = false",
             name: :accrue_connect_accounts_not_charges_enabled_idx
           )
  end
end
