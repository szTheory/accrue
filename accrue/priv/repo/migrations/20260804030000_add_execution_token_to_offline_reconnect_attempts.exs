defmodule Accrue.Repo.Migrations.AddExecutionTokenToOfflineReconnectAttempts do
  use Ecto.Migration

  def change do
    alter Accrue.Migration.table(:accrue_entitlement_offline_reconnect_attempts) do
      add(:execution_token, :string)
    end
  end
end
