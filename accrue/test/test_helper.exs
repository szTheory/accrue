Accrue.MoxSetup.define_mocks()

# Start Accrue.TestRepo once for the whole test run. Individual tests
# that need a DB connection check it out via Accrue.RepoCase's setup
# block (Ecto.Adapters.SQL.Sandbox.start_owner!/2). Plan 03 Wave 2.
{:ok, _} = Accrue.TestRepo.start_link(pool: Ecto.Adapters.SQL.Sandbox)
Ecto.Adapters.SQL.Sandbox.mode(Accrue.TestRepo, :manual)

ExUnit.start()
