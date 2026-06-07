defmodule AccrueHost.Repo.Migrations.AddSigraAuthRuntimeTables do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :failed_login_attempts, :integer, null: false, default: 0
      add :locked_at, :utc_datetime
      add :password_changed_at, :utc_datetime
      add :pending_email, :citext
      add :deleted_at, :utc_datetime
      add :scheduled_deletion_at, :utc_datetime
      add :original_email, :string
      add :must_change_password, :boolean, null: false, default: false
      add :mfa_trust_epoch, :integer, null: false, default: 0
    end

    create unique_index(:users, [:pending_email],
             where: "pending_email IS NOT NULL",
             name: :users_pending_email_index
           )

    create table(:user_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :hashed_token, :binary, null: false
      add :type, :string, null: false, default: "standard"
      add :ip, :string
      add :user_agent, :text
      add :geo_city, :string
      add :geo_country_code, :string
      add :last_active_at, :utc_datetime_usec, null: false
      add :sudo_at, :utc_datetime_usec

      add :active_organization_id,
          references(:organizations, type: :binary_id, on_delete: :nilify_all)

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(:user_sessions, [:hashed_token])
    create index(:user_sessions, [:user_id])
    create index(:user_sessions, [:active_organization_id])
  end
end
