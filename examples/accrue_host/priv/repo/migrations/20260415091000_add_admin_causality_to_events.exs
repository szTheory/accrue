# accrue:generated
# accrue:fingerprint: 69e6bb0896d8760c4641e47f325474c84e82c12d66075cee3ecd3db72a58c300
defmodule Accrue.Repo.Migrations.AddAdminCausalityToEvents do
  @moduledoc """
  Adds the minimal causal-link fields Phase 7 admin actions need on the
  append-only event ledger.
  """

  use Ecto.Migration

  def change do
    alter Accrue.Migration.table(:accrue_events) do
      add(
        :caused_by_event_id,
        Accrue.Migration.references(:accrue_events,
          column: :id,
          type: :bigint,
          on_delete: :nothing
        )
      )

      add(
        :caused_by_webhook_event_id,
        Accrue.Migration.references(:accrue_webhook_events, type: :binary_id, on_delete: :nothing)
      )
    end

    create(
      Accrue.Migration.index(:accrue_events, [:caused_by_event_id],
        where: "caused_by_event_id IS NOT NULL",
        name: :accrue_events_caused_by_event_id_idx
      )
    )

    create(
      Accrue.Migration.index(:accrue_events, [:caused_by_webhook_event_id],
        where: "caused_by_webhook_event_id IS NOT NULL",
        name: :accrue_events_caused_by_webhook_event_id_idx
      )
    )

    create(
      Accrue.Migration.index(:accrue_events, [:actor_type, :caused_by_event_id, :inserted_at],
        where: "actor_type = 'admin' AND caused_by_event_id IS NOT NULL",
        name: :accrue_events_admin_causality_idx
      )
    )
  end
end
