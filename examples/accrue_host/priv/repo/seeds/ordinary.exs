alias AccrueHost.Repo

# These checks inspect the connection the Repo actually opened. Environment
# labels alone are not a database boundary: DATABASE_URL/PGHOST can be pointed
# at another stack while the Compose project name still looks correct.
unless Mix.env() == :test do
  [database, role, server_address] =
    case Repo.query!("SELECT current_database(), current_user, inet_server_addr()::text") do
      %{rows: [row]} -> row
      _ -> raise "ordinary preview seed refused: could not identify connected database"
    end

  expected_address =
    case :inet.getaddr(~c"db", :inet) do
      {:ok, address} -> address |> :inet.ntoa() |> List.to_string()
      {:error, _} -> raise "ordinary preview seed refused: isolated Compose db host is unavailable"
    end

  unless database == "accrue_host_dev" and role == "postgres" and
           server_address == expected_address do
    raise "ordinary preview seed refused: connected Repo is not the isolated ordinary preview database"
  end
end

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
