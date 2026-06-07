# accrue:generated
# accrue:fingerprint: 6a6c52370d234ef6095aa0730e7cfcc1a3516d0c573ca90acefa86c2b0dc0dfa
defmodule Accrue.Repo.Migrations.AddAutomaticTaxColumnsToBillingTables do
  @moduledoc """
  Adds narrow automatic-tax observability columns for subscriptions and invoices.

  The full processor tax payload remains in `data`; these columns only persist
  the enabled/status state Accrue needs for local queries.
  """

  use Ecto.Migration

  def change do
    alter Accrue.Migration.table(:accrue_subscriptions) do
      add(:automatic_tax, :boolean, default: false, null: false)
      add(:automatic_tax_status, :string)
    end

    alter Accrue.Migration.table(:accrue_invoices) do
      add(:automatic_tax, :boolean, default: false, null: false)
      add(:automatic_tax_status, :string)
    end
  end
end
