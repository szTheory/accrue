# accrue:generated
# accrue:fingerprint: phase19-19-rollout-safety
defmodule Accrue.Repo.Migrations.AddTaxRolloutSafetyColumns do
  @moduledoc """
  Adds narrow observability columns for recurring tax-location rollback states.

  These fields keep disabled reasons and finalization error codes queryable
  without expanding local billing tables into raw provider error storage.
  """

  use Ecto.Migration

  def change do
    alter table(:accrue_subscriptions) do
      add(:automatic_tax_disabled_reason, :string)
    end

    alter table(:accrue_invoices) do
      add(:automatic_tax_disabled_reason, :string)
      add(:last_finalization_error_code, :string)
    end
  end
end
