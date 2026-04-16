# accrue:generated
# accrue:fingerprint: 340325bd1def1a314b6517a839be0c4a755e4295a22faffebeb8525a30e368fb
defmodule Accrue.Repo.Migrations.CreateAccrueCustomers do
  @moduledoc """
  Creates the `accrue_customers` table with polymorphic owner_type/owner_id
  and composite unique index (D2-01, D2-02, D2-25).
  """

  use Ecto.Migration

  def change do
    create table(:accrue_customers, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :owner_type, :string, null: false
      add :owner_id, :string, null: false
      add :processor, :string, null: false
      add :processor_id, :string
      add :name, :string
      add :email, :string
      add :metadata, :map, default: %{}, null: false
      add :data, :map, default: %{}, null: false
      add :lock_version, :integer, default: 1, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:accrue_customers, [:owner_type, :owner_id, :processor],
             name: :accrue_customers_owner_type_owner_id_processor_index
           )

    create index(:accrue_customers, [:processor_id])
    create index(:accrue_customers, [:processor])
  end
end
