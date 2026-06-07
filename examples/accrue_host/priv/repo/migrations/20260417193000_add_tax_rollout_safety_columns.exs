# accrue:generated
# accrue:fingerprint: 00226d12736a9f6e9adcb908a086465dfe95c11d77799506d05fc83adfba0e55
defmodule Accrue.Repo.Migrations.AddTaxRolloutSafetyColumns do
  @moduledoc """
  Adds narrow observability columns for recurring tax-location rollback states.

  These fields keep disabled reasons and finalization error codes queryable
  without expanding local billing tables into raw provider error storage.
  """

  use Ecto.Migration

  def change do
    alter Accrue.Migration.table(:accrue_subscriptions) do
      add(:automatic_tax_disabled_reason, :string)
    end

    alter Accrue.Migration.table(:accrue_invoices) do
      add(:automatic_tax_disabled_reason, :string)
      add(:last_finalization_error_code, :string)
    end
  end
end
