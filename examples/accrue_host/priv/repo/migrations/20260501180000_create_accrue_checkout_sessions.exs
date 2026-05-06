defmodule Accrue.Repo.Migrations.CreateAccrueCheckoutSessions do
  use Ecto.Migration

  def change do
    create table(:accrue_checkout_sessions, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:customer_id, references(:accrue_customers, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      add(:processor, :string, null: false)
      add(:session_token, :string, null: false)
      add(:mode, :string, null: false)
      add(:ui_mode, :string, null: false)
      add(:status, :string, null: false, default: "open")
      add(:price_id, :string, null: false)
      add(:line_items, {:array, :map}, null: false, default: [])
      add(:success_url, :text)
      add(:cancel_url, :text)
      add(:return_url, :text)
      add(:operation_id, :string)
      add(:expires_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: %{})
      add(:data, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:accrue_checkout_sessions, [:session_token]))
    create(unique_index(:accrue_checkout_sessions, [:operation_id]))
    create(index(:accrue_checkout_sessions, [:customer_id, :inserted_at]))
  end
end
