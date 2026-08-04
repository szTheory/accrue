defmodule Accrue.Repo.Migrations.PersistAccrueOfflineReconnectOutcomes do
  use Ecto.Migration

  def change do
    alter Accrue.Migration.table(:accrue_entitlement_offline_challenges) do
      add(:reconnect_outcome, :map)
    end
  end
end
