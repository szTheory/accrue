defmodule AccrueHost.Repo.Migrations.CreateOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :deleted_at, :utc_datetime
      add :personal, :boolean, null: false, default: false

      add :owner_user_id, references(:users, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:slug],
             where: "deleted_at IS NULL",
             name: :organizations_slug_active_index
           )

    create index(:organizations, [:owner_user_id])
    create index(:organizations, [:personal])
  end
end
