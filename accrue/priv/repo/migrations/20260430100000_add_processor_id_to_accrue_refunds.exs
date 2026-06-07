defmodule Accrue.Repo.Migrations.AddProcessorIdToAccrueRefunds do
  use Ecto.Migration

  def up do
    alter Accrue.Migration.table(:accrue_refunds) do
      add(:processor_id, :string)
    end

    refunds_table = Accrue.Migration.qualified_table(:accrue_refunds)

    execute(
      "UPDATE #{refunds_table} SET processor_id = stripe_id WHERE processor_id IS NULL AND stripe_id IS NOT NULL"
    )

    create(
      Accrue.Migration.unique_index(:accrue_refunds, [:processor_id],
        where: "processor_id IS NOT NULL",
        name: :accrue_refunds_processor_id_index
      )
    )
  end

  def down do
    drop_if_exists(
      Accrue.Migration.index(:accrue_refunds, [:processor_id],
        name: :accrue_refunds_processor_id_index
      )
    )

    alter Accrue.Migration.table(:accrue_refunds) do
      remove(:processor_id)
    end
  end
end
