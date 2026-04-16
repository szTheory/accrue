defmodule AccrueHost.Repo.Migrations.AddBillingAdminToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :billing_admin, :boolean, default: false, null: false
    end
  end
end
