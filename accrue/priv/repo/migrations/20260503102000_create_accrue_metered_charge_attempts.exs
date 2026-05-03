defmodule Accrue.Repo.Migrations.CreateAccrueMeteredChargeAttempts do
  use Ecto.Migration

  def change do
    alter table(:accrue_metered_renewals) do
      add(:paid_at, :utc_datetime_usec)
    end

    create table(:accrue_metered_charge_attempts, primary_key: false) do
      add(:id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :metered_renewal_id,
        references(:accrue_metered_renewals, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      add(:subject_uuid, :string, null: false)
      add(:status, :string, null: false, default: "pending")
      add(:processor, :string, null: false, default: "braintree")
      add(:processor_charge_id, :string)
      add(:attempted_payment_method_id, :string)
      add(:original_failed_payment_method_id, :string)
      add(:failure_class, :string)
      add(:original_failure_class, :string)
      add(:failure_code, :string)
      add(:original_failure_code, :string)
      add(:failure_message, :string)
      add(:original_failure_message, :string)
      add(:retry_at, :utc_datetime_usec)
      add(:paid_at, :utc_datetime_usec)
      add(:data, :map, null: false, default: %{})
      add(:lock_version, :integer, null: false, default: 1)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:accrue_metered_charge_attempts, [:metered_renewal_id]))
    create(unique_index(:accrue_metered_charge_attempts, [:subject_uuid]))
    create(index(:accrue_metered_charge_attempts, [:status, :retry_at]))
  end
end
