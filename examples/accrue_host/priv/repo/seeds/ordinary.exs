alias AccrueHost.Repo

unless System.get_env("COMPOSE_PROJECT_NAME") == "accrue-host-phase245-ordinary" do
  raise "ordinary preview seed refused: unexpected COMPOSE_PROJECT_NAME"
end

unless System.get_env("ACCRUE_HOST_SKIP_SEEDS") == "1" do
  raise "ordinary preview seed refused: boot must use ACCRUE_HOST_SKIP_SEEDS=1"
end

unless Application.fetch_env!(:accrue, :processor) == Accrue.Processor.Fake do
  raise "ordinary preview seed refused: processor must be Accrue.Processor.Fake"
end

import Ecto.Query

background_already_seeded? =
  Repo.exists?(
    from(event in Accrue.Events.Event,
      where: like(event.idempotency_key, "seed-bg-sub-%")
    )
  )

# This remains an eval_file chain so repeated runs in one BEAM node re-run the
# ordinary idempotent seeds. The background family uses random UUIDs; skip that
# bulk insert once its append-only seed events prove the family is present.
Code.eval_file("helpers.exs", __DIR__)
Code.eval_file("hero_accounts.exs", __DIR__)

unless background_already_seeded? do
  Code.eval_file("background_data.exs", __DIR__)
end

Code.eval_file("showcase.exs", __DIR__)
