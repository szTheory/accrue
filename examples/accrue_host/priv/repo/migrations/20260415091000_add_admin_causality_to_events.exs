# accrue:generated
# accrue:fingerprint: d5ad141130d306efa28cfa49222ad311f63e5f35ab4cc375641f701a474c2793
defmodule Accrue.Repo.Migrations.AddAdminCausalityToEvents do
  @moduledoc """
  Adds the minimal causal-link fields Phase 7 admin actions need on the
  append-only event ledger.
  """

  use Ecto.Migration

  def change do
    alter table(:accrue_events) do
      add(
        :caused_by_event_id,
        references(:accrue_events, column: :id, type: :bigint, on_delete: :nothing)
      )

      add(
        :caused_by_webhook_event_id,
        references(:accrue_webhook_events, type: :binary_id, on_delete: :nothing)
      )
    end

    create(
      index(:accrue_events, [:caused_by_event_id],
        where: "caused_by_event_id IS NOT NULL",
        name: :accrue_events_caused_by_event_id_idx
      )
    )

    create(
      index(:accrue_events, [:caused_by_webhook_event_id],
        where: "caused_by_webhook_event_id IS NOT NULL",
        name: :accrue_events_caused_by_webhook_event_id_idx
      )
    )

    create(
      index(:accrue_events, [:actor_type, :caused_by_event_id, :inserted_at],
        where: "actor_type = 'admin' AND caused_by_event_id IS NOT NULL",
        name: :accrue_events_admin_causality_idx
      )
    )
  end
end
