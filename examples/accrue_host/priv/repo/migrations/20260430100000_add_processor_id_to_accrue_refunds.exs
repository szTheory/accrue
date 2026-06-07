# accrue:generated
# accrue:fingerprint: 6b4348da4841b32d90593cd26c46269ce27e6fba4a4533f51dd3710c2ef241a8
defmodule Accrue.Repo.Migrations.AddProcessorIdToAccrueRefunds do
  use Ecto.Migration

  def up do
    alter table(:accrue_refunds) do
      add(:processor_id, :string)
    end

    execute(
      "UPDATE accrue_refunds SET processor_id = stripe_id WHERE processor_id IS NULL AND stripe_id IS NOT NULL"
    )

    create(
      unique_index(:accrue_refunds, [:processor_id],
        where: "processor_id IS NOT NULL",
        name: :accrue_refunds_processor_id_index
      )
    )
  end

  def down do
    drop_if_exists(
      index(:accrue_refunds, [:processor_id], name: :accrue_refunds_processor_id_index)
    )

    alter table(:accrue_refunds) do
      remove(:processor_id)
    end
  end
end
