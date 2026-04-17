# accrue:generated
# accrue:fingerprint: phase19-18-tax-columns
defmodule Accrue.Repo.Migrations.AddAutomaticTaxColumnsToBillingTables do
  @moduledoc """
  Adds narrow automatic-tax observability columns for subscriptions and invoices.

  The full processor tax payload remains in `data`; these columns only persist
  the enabled/status state Accrue needs for local queries.
  """

  use Ecto.Migration

  def change do
    alter table(:accrue_subscriptions) do
      add(:automatic_tax, :boolean, default: false, null: false)
      add(:automatic_tax_status, :string)
    end

    alter table(:accrue_invoices) do
      add(:automatic_tax, :boolean, default: false, null: false)
      add(:automatic_tax_status, :string)
    end
  end
end
