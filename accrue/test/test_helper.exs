# Start the Credo application so custom check tests can use
# Credo.Test.Case (Credo.Service.SourceFileAST is required by to_source_file/1).
{:ok, _} = Application.ensure_all_started(:credo)

Accrue.MoxSetup.define_mocks()

# Configure webhook signing secrets for test fixtures (Plan 06).
# Must be set before TestRepo starts so any compile-time config reads see it.
Application.put_env(:accrue, :webhook_signing_secrets, %{
  stripe: [Accrue.WebhookFixtures.default_secret()]
})

# Start Accrue.TestRepo once for the whole test run. Individual tests
# that need a DB connection check it out via Accrue.RepoCase's setup
# block (Ecto.Adapters.SQL.Sandbox.start_owner!/2). Plan 03 Wave 2.
{:ok, _} = Accrue.TestRepo.start_link(pool: Ecto.Adapters.SQL.Sandbox)
Ecto.Adapters.SQL.Sandbox.mode(Accrue.TestRepo, :manual)

# Start Oban in :manual testing mode against Accrue.TestRepo so Plan 05's
# mailer tests can use Oban.Testing helpers (assert_enqueued, perform_job,
# etc.) without running real queues. Host applications start their own Oban
# in production — Accrue never starts Oban itself (D-27).
{:ok, _} =
  Oban.start_link(
    repo: Accrue.TestRepo,
    testing: :manual,
    queues: false,
    plugins: false,
    notifier: Oban.Notifiers.PG
  )

ExUnit.start()
