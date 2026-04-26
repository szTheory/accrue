# Start the Credo application so custom check tests can use
# Credo.Test.Case (Credo.Service.SourceFileAST is required by to_source_file/1).
{:ok, _} = Application.ensure_all_started(:credo)

# Eagerly start :mailglass and its transitive deps (uuidv7, phoenix_html, etc.)
# before any test runs. With path-dep mailglass these get pulled in via parent
# compilation order; with Hex'd mailglass the load timing depends on test
# ordering, which can surface as `UUIDv7.autogenerate/0 is undefined` and
# `Phoenix.HTML.Safe.BitString.to_iodata/1` flakes under random seeds.
{:ok, _} = Application.ensure_all_started(:mailglass)

# Force-load modules that random test ordering can leave purgable. UUIDv7 is
# used by Mailglass.Repo for delivery autogenerate; Phoenix.HTML.Safe.BitString
# implements the protocol for binary HEEx assigns. Both are present in the dep
# graph but only get auto-loaded on first reference — and some tests' module
# purge cycles can leave them unavailable mid-suite under random seeds.
Code.ensure_loaded!(UUIDv7)
Code.ensure_loaded!(Phoenix.HTML.Safe.BitString)

Accrue.MoxSetup.define_mocks()

# Configure webhook signing secrets for test fixtures (Plan 06).
# Must be set before TestRepo starts so any compile-time config reads see it.
Application.put_env(:accrue, :webhook_signing_secrets, %{
  stripe: [Accrue.WebhookFixtures.default_secret()]
})

# Start Accrue.TestRepo once for the whole test run. Individual tests
# that need a DB connection check it out via Accrue.RepoCase's setup
# block (Ecto.Adapters.SQL.Sandbox.start_owner!/2). Plan 03 Wave 2.
case Accrue.TestRepo.__adapter__().storage_up(Accrue.TestRepo.config()) do
  :ok -> :ok
  {:error, :already_up} -> :ok
end

{:ok, _} = Accrue.TestRepo.start_link(pool: Ecto.Adapters.SQL.Sandbox)
Ecto.Adapters.SQL.Sandbox.mode(Accrue.TestRepo, {:shared, self()})

{:ok, _, _} =
  Ecto.Migrator.with_repo(Accrue.TestRepo, fn repo ->
    Ecto.Migrator.run(repo, "priv/repo/migrations", :up, all: true, log: false)
  end)

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

# Exclude live-Stripe and slow tags by default. Opt in via:
#
#     mix test --only live_stripe   # or `mix test.live`
#     mix test --only slow
#
# See `accrue/test/live_stripe/` and `guides/testing-live-stripe.md`.
ExUnit.configure(exclude: [:live_stripe, :slow, :compile_matrix])

ExUnit.start()
