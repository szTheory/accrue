---
phase: 01-foundations
plan: 01
type: execute
wave: 0
depends_on: []
files_modified:
  - accrue/mix.exs
  - accrue/config/config.exs
  - accrue/config/dev.exs
  - accrue/config/test.exs
  - accrue/config/runtime.exs
  - accrue/lib/accrue.ex
  - accrue/test/test_helper.exs
  - accrue/test/support/data_case.ex
  - accrue/test/support/mox_setup.ex
  - accrue_admin/mix.exs
  - accrue_admin/lib/accrue_admin.ex
  - accrue_admin/config/config.exs
  - accrue_admin/config/dev.exs
  - accrue_admin/config/test.exs
  - accrue_admin/test/test_helper.exs
  - LICENSE
  - .gitignore
autonomous: true
requirements: [FND-06, OSS-11, TEST-01]
security_enforcement: enabled
tags: [elixir, monorepo, mix, bootstrap, oss]
must_haves:
  truths:
    - "A developer can run `cd accrue && mix deps.get && mix compile --warnings-as-errors` on a fresh clone and get a clean build"
    - "A developer can run `cd accrue && mix test` and the harness reports 0 failures on the smoke test"
    - "A developer can run `cd accrue_admin && mix deps.get` and see `:accrue` resolved via path dep"
    - "MIT LICENSE exists at monorepo root"
    - "Mox mocks for Accrue.Processor/Mailer/PDF/Auth are defined in test_helper.exs and compile clean after behaviours land in later plans"
    - "config/config.exs sets `config :accrue, :env, Mix.env()` so downstream plans can read the compile-time env"
    - "config/test.exs contains the full Accrue.TestRepo sandbox wiring so Plan 03 can insert against a live PG in Wave 2"
  artifacts:
    - path: "accrue/mix.exs"
      provides: "Core package project + deps + aliases + elixirc_paths for test support"
      contains: "app: :accrue"
    - path: "accrue/config/config.exs"
      provides: "Root config with `:env` key and import_config split"
      contains: "config :accrue, :env"
    - path: "accrue/config/test.exs"
      provides: "Accrue.TestRepo sandbox + Swoosh.Adapters.Test + :repo key for downstream plans"
      contains: "Ecto.Adapters.SQL.Sandbox"
    - path: "accrue/test/test_helper.exs"
      provides: "ExUnit.start, Mox.defmock for all Phase 1 behaviours, Application.put_env routing"
      contains: "ExUnit.start"
    - path: "accrue/test/support/mox_setup.ex"
      provides: "Mox.defmock calls for Accrue.ProcessorMock etc (guarded behind Code.ensure_loaded? for Wave 1 behaviours)"
    - path: "accrue_admin/mix.exs"
      provides: "Admin package with path dep on sibling accrue"
      contains: "path: \"../accrue\""
    - path: "LICENSE"
      provides: "MIT license text at monorepo root"
      contains: "MIT License"
    - path: "accrue/config/runtime.exs"
      provides: "Runtime secrets loading stub (empty for Phase 1 but present)"
  key_links:
    - from: "accrue_admin/mix.exs"
      to: "accrue/mix.exs"
      via: "path: \"../accrue\" dep"
      pattern: "path:.*\\.\\./accrue"
    - from: "accrue/mix.exs"
      to: "test/support"
      via: "elixirc_paths(:test) adds test/support"
      pattern: "elixirc_paths"
    - from: "accrue/config/config.exs"
      to: "Mix.env()"
      via: "config :accrue, :env, Mix.env() — read by Plan 05 Auth.Default boot_check"
      pattern: "config :accrue, :env"
---

<objective>
Wave 0 bootstrap. Create the sibling mix projects (`accrue/` + `accrue_admin/`), wire deps per CLAUDE.md tech stack, lay down ALL static config files (including the Accrue.TestRepo sandbox stanza for Plan 03 and the `:env` key for Plan 05's Auth.Default), set up the ExUnit/Mox test harness, and drop the MIT LICENSE. Nothing downstream compiles until this lands.

Purpose: Every subsequent Phase 1 plan depends on a working `mix compile`, `mix test`, and a fully-wired `config/*.exs` trio. By absorbing ALL static config here, Wave 2 plans (03/04/05) never touch `config/*.exs` or `lib/accrue/config.ex`, eliminating the Wave 2 file-collision class entirely.
Output: Two mix projects that compile clean with all locked deps resolved, a test harness ready for Mox-backed behaviour tests, fully-populated config files, and the LICENSE satisfying OSS-11.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/phases/01-foundations/01-CONTEXT.md
@.planning/phases/01-foundations/01-RESEARCH.md
@.planning/phases/01-foundations/01-VALIDATION.md
@CLAUDE.md

<interfaces>
<!-- Tech stack deps (from CLAUDE.md, re-verified in RESEARCH.md 2026-04-11) -->
<!-- All versions below are LOCKED. Do not drift. -->

accrue/mix.exs deps/0 (required):
```elixir
{:ecto, "~> 3.13"},
{:ecto_sql, "~> 3.13"},
{:postgrex, "~> 0.22"},
{:ex_money, "~> 5.24"},
{:lattice_stripe, "~> 0.2"},
{:oban, "~> 2.21"},
{:swoosh, "~> 1.25"},
{:phoenix_swoosh, "~> 1.2"},
{:mjml_eex, "~> 0.13"},
{:chromic_pdf, "~> 1.17"},
{:nimble_options, "~> 1.1"},
{:telemetry, "~> 1.3"},
{:jason, "~> 1.4"},
{:decimal, "~> 2.0"},
# optional
{:sigra, "~> 0.1", optional: true},
{:opentelemetry, "~> 1.7", optional: true},
{:telemetry_metrics, "~> 1.1", optional: true},
# dev/test
{:mox, "~> 1.2", only: :test},
{:stream_data, "~> 1.3", only: [:dev, :test]},
{:ex_doc, "~> 0.40", only: :dev, runtime: false},
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},
{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
```

accrue_admin/mix.exs deps/0 (required):
```elixir
{:accrue, path: "../accrue"},        # dev-path; published builds pin "~> 1.0" per D-43
{:phoenix, "~> 1.8"},
{:phoenix_live_view, "~> 1.1"},
{:phoenix_html, "~> 4.2"}
```

Static config keys set by this plan (Plan 02 will validate them, Plans 04/05 will READ them):
- `config :accrue, :env, Mix.env()` — compile_env-stable; read by Plan 05 Auth.Default
- `config :accrue, :repo, Accrue.TestRepo` (in config/test.exs only)
- `config :accrue, Accrue.TestRepo, [...]` — full sandbox stanza for Plan 03
- `config :accrue, Accrue.Mailer.Swoosh, adapter: Swoosh.Adapters.Test` (in config/test.exs)
- `config :accrue, Accrue.Mailer.Swoosh, adapter: Swoosh.Adapters.Local` (in config/dev.exs)

Mox mocks to define (Wave 1 behaviours — mocks are declared now but guarded by Code.ensure_loaded?/1 so Wave 0 tests pass before the behaviours exist):
- Accrue.ProcessorMock for Accrue.Processor
- Accrue.MailerMock for Accrue.Mailer
- Accrue.PDFMock for Accrue.PDF
- Accrue.AuthMock for Accrue.Auth
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Scaffold accrue/ mix project with locked deps + full static config wiring</name>
  <read_first>
    - CLAUDE.md §Technology Stack (the full deps table is canonical)
    - .planning/phases/01-foundations/01-RESEARCH.md §Standard Stack (version verification)
    - .planning/phases/01-foundations/01-CONTEXT.md D-42 (sibling non-umbrella layout)
    - CLAUDE.md §Config Boundaries (compile-time vs runtime)
  </read_first>
  <files>
    accrue/mix.exs
    accrue/lib/accrue.ex
    accrue/config/config.exs
    accrue/config/dev.exs
    accrue/config/test.exs
    accrue/config/runtime.exs
    .gitignore
  </files>
  <action>
Create the core `accrue/` mix project at `/Users/jon/projects/accrue/accrue/`. This is NOT `mix new` — the layout is non-umbrella sibling so hand-write files to match D-42.

1. `accrue/mix.exs`:
   - `@version "0.1.0"` at top of module (required for Release Please per CLAUDE.md §Release Please).
   - `app: :accrue`, `version: @version`, `elixir: "~> 1.17"` (floor from CLAUDE.md; dev machine has 1.19/OTP28 but floor must be 1.17).
   - `elixirc_paths(:test) -> ["lib", "test/support"]`; `elixirc_paths(_) -> ["lib"]`.
   - `deps/0` exactly as in the `<interfaces>` block above. DO NOT add `:ex_money_sql` (per A4 in RESEARCH.md; Accrue writes its own two-column Ecto type per D-02).
   - `application/0` returns `[extra_applications: [:logger]]` only — NO `mod:` key in this task. The Application module is wired in Plan 06 (FND-05). Keeping `mod:` out here means Wave 1 plans can add code without OTP app boot side effects.
   - `aliases/0`: `"test.all": ["format --check-formatted", "credo --strict", "compile --warnings-as-errors", "test"]`.
   - `package/0` stub with `licenses: ["MIT"]`, `links: %{}`, `description: "Billing state, modeled clearly."` — OSS-11 satisfied at package metadata level.

2. `accrue/lib/accrue.ex`: module with `@moduledoc` summarizing the library (one paragraph referencing PROJECT.md). No code inside.

3. `accrue/config/config.exs` — non-empty. Sets the `:env` key and the adapter/Repo placeholder keys that Plan 02's Config schema will later validate. Plans 04/05 only READ these; they never re-edit this file.
   ```elixir
   import Config

   # Compile-stable env marker. Plan 05 Auth.Default boot_check reads this via
   # Application.get_env(:accrue, :env, Mix.env()) — runtime lookup with Mix.env fallback.
   config :accrue, :env, Mix.env()

   # Placeholder keys so Plan 02's NimbleOptions schema has something to validate.
   # Plan 02 will ship the full schema; Plans 04/05 READ these, never WRITE them.
   config :accrue,
     processor: Accrue.Processor.Fake,
     mailer: Accrue.Mailer.Default,
     mailer_adapter: Accrue.Mailer.Swoosh,
     pdf_adapter: Accrue.PDF.ChromicPDF,
     auth_adapter: Accrue.Auth.Default,
     default_currency: :usd,
     emails: [],
     email_overrides: [],
     attach_invoice_pdf: true,
     enforce_immutability: false

   # Oban queue name reservation (host app owns the Oban instance — Accrue just names queues).
   # Documented here so downstream plans know the canonical queue name.
   # config :my_app, Oban,
   #   queues: [accrue_mailers: 20, accrue_webhooks: 10]

   # Swoosh mailer shim — placeholder; env-specific adapter is set in dev.exs / test.exs.
   config :accrue, Accrue.Mailer.Swoosh, adapter: Swoosh.Adapters.Local

   import_config "#{config_env()}.exs"
   ```

4. `accrue/config/dev.exs`:
   ```elixir
   import Config

   # Dev: Swoosh Local adapter writes emails to an in-process mailbox visible via
   # Swoosh.Adapters.Local.Storage.Memory / Phoenix LiveDashboard.
   config :accrue, Accrue.Mailer.Swoosh, adapter: Swoosh.Adapters.Local
   ```

5. `accrue/config/test.exs` — **FULL static wiring for Wave 2 integration tests**. This is the ONLY place test.exs is edited in Phase 1. Plan 03 consumes these keys but does not rewrite this file.
   ```elixir
   import Config

   # Swoosh test mailbox — enables Swoosh.TestAssertions.assert_email_sent/1 (Plan 05 Task 1).
   config :accrue, Accrue.Mailer.Swoosh, adapter: Swoosh.Adapters.Test

   # Accrue.TestRepo — lives in test/support only (never in lib/ — D-10). Plan 03 uses this
   # as the Repo for event-ledger integration tests. Sandbox wiring so parallel tests work.
   config :accrue, Accrue.TestRepo,
     database: "accrue_test#{System.get_env("MIX_TEST_PARTITION")}",
     pool: Ecto.Adapters.SQL.Sandbox,
     pool_size: 10,
     username: System.get_env("PGUSER", "postgres"),
     password: System.get_env("PGPASSWORD", "postgres"),
     hostname: System.get_env("PGHOST", "localhost"),
     priv: "priv/repo"

   config :accrue, ecto_repos: [Accrue.TestRepo]
   config :accrue, :repo, Accrue.TestRepo
   ```
   Note: `Accrue.TestRepo` itself is a module defined in Plan 03 Task 1 (`test/support/test_repo.ex`). Wave 0 compiles fine without the module because `:ecto_repos` is just an atom list; Ecto only resolves it at `mix ecto.*` invocation time, which Plan 03 is the first to run.

6. `accrue/config/runtime.exs`: contains `import Config` plus a comment block pointing at CLAUDE.md §Config Boundaries. DO NOT read Stripe secrets here — Plan 04's Stripe adapter reads them via `Application.get_env/3` at runtime; adding the `System.fetch_env!` calls to runtime.exs is explicitly deferred until Phase 2 when a live webhook test proves the shape. For Phase 1, runtime.exs is intentionally minimal.

7. `.gitignore`: standard Elixir — `_build/`, `deps/`, `*.ez`, `.elixir_ls/`, `priv/plts/*.plt*`, `cover/`.

Decision D-42 (sibling, non-umbrella): do NOT create an umbrella root `mix.exs`. The monorepo root has no `mix.exs`, only `LICENSE` and shared docs/CI config.

Run `cd /Users/jon/projects/accrue/accrue && mix deps.get` and confirm resolution succeeds. If any version conflict surfaces, STOP and report — do not downgrade pins without user decision.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix deps.get && mix compile --warnings-as-errors 2>&1 | tail -30</automated>
  </verify>
  <acceptance_criteria>
    - `accrue/mix.exs` exists with `@version "0.1.0"` and `app: :accrue`
    - `grep -c 'optional: true' accrue/mix.exs` returns 3 (sigra, opentelemetry, telemetry_metrics)
    - `grep 'ex_money_sql' accrue/mix.exs` returns nothing (excluded per A4)
    - `grep -q "config :accrue, :env, Mix.env" accrue/config/config.exs`
    - `grep -q "Ecto.Adapters.SQL.Sandbox" accrue/config/test.exs`
    - `grep -q "config :accrue, :repo, Accrue.TestRepo" accrue/config/test.exs`
    - `grep -q "Swoosh.Adapters.Test" accrue/config/test.exs`
    - `cd accrue && mix deps.get` exits 0
    - `cd accrue && mix compile --warnings-as-errors` exits 0
    - No `mod: {Accrue.Application, []}` line in `application/0` yet (Plan 06 adds it)
  </acceptance_criteria>
  <done>accrue package compiles clean against all 17 direct deps with zero warnings, ALL static config is wired, downstream plans can read (never write) these keys.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Scaffold accrue_admin/ mix project + root LICENSE</name>
  <read_first>
    - CLAUDE.md §Installation — mix.exs Template (accrue_admin section)
    - .planning/phases/01-foundations/01-CONTEXT.md D-42, D-43 (lockstep major, independent minor; path dep in dev)
  </read_first>
  <files>
    accrue_admin/mix.exs
    accrue_admin/lib/accrue_admin.ex
    accrue_admin/config/config.exs
    accrue_admin/config/dev.exs
    accrue_admin/config/test.exs
    accrue_admin/test/test_helper.exs
    LICENSE
  </files>
  <action>
1. `accrue_admin/mix.exs`:
   - `@version "0.1.0"` at top.
   - `app: :accrue_admin`, `version: @version`, `elixir: "~> 1.17"`.
   - `deps/0`:
     ```elixir
     [
       {:accrue, path: "../accrue"},  # Dev monorepo path; at publish time this flips to "~> 1.0" per D-43. Do NOT add both forms now.
       {:phoenix, "~> 1.8"},
       {:phoenix_live_view, "~> 1.1"},
       {:phoenix_html, "~> 4.2"},
       {:ex_doc, "~> 0.40", only: :dev, runtime: false},
       {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
     ]
     ```
   - `application/0`: `[extra_applications: [:logger]]`. No `mod:` — admin is LV code, Phase 7 wires any supervisor.
   - `package/0`: `licenses: ["MIT"]`, `description: "Admin LiveView UI for Accrue billing."`.
2. `accrue_admin/lib/accrue_admin.ex`: stub module with `@moduledoc` pointing at Phase 7.
3. `accrue_admin/config/*.exs`: trio matching accrue (bare `import Config` + env split).
4. `accrue_admin/test/test_helper.exs`: `ExUnit.start()` one-liner.
5. **Root `LICENSE`** (at `/Users/jon/projects/accrue/LICENSE`): full MIT license text with `Copyright (c) 2026 Accrue contributors`. This is the canonical monorepo LICENSE. Per D-42, no per-package copy is needed at this phase (the `package/0` `licenses: ["MIT"]` metadata is sufficient for Hex; Phase 9 may add symlinks).

Run `cd /Users/jon/projects/accrue/accrue_admin && mix deps.get` to confirm the path dep resolves. `mix compile` may produce warnings from accrue if its behaviours aren't defined yet — that's expected at Wave 0; we only require `deps.get` success and a bare compile here.
  </action>
  <verify>
    <automated>test -f /Users/jon/projects/accrue/LICENSE && grep -q "MIT License" /Users/jon/projects/accrue/LICENSE && cd /Users/jon/projects/accrue/accrue_admin && mix deps.get 2>&1 | tail -10</automated>
  </verify>
  <acceptance_criteria>
    - `/Users/jon/projects/accrue/LICENSE` contains the literal string "MIT License" and "Copyright (c) 2026"
    - `accrue_admin/mix.exs` contains `{:accrue, path: "../accrue"}`
    - `accrue_admin/mix.exs` contains `@version "0.1.0"`
    - `cd accrue_admin && mix deps.get` exits 0 with `:accrue` listed as resolved
    - No umbrella `mix.exs` file at monorepo root (`test ! -f /Users/jon/projects/accrue/mix.exs`)
  </acceptance_criteria>
  <done>Sibling monorepo layout (D-42) in place, MIT LICENSE at root (OSS-11), admin resolves core via path dep.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 3: Wire test harness — ExUnit + Mox + support modules</name>
  <read_first>
    - .planning/phases/01-foundations/01-RESEARCH.md §Mox test_helper.exs (pattern)
    - .planning/phases/01-foundations/01-CONTEXT.md D-19, D-20 (Fake processor is primary surface — TEST-01)
    - CLAUDE.md §Test Library Decision: Mox, Decisively
  </read_first>
  <files>
    accrue/test/test_helper.exs
    accrue/test/support/data_case.ex
    accrue/test/support/mox_setup.ex
    accrue/test/accrue_test.exs
  </files>
  <action>
1. `accrue/test/support/mox_setup.ex`:
   - Module `Accrue.MoxSetup` with `def define_mocks/0`.
   - Body uses `Code.ensure_loaded?/1` guards so each `Mox.defmock/2` only runs after the corresponding behaviour module is loaded. This lets Wave 0 tests pass before Wave 1 behaviours exist, and Wave 1 tests pick up mocks automatically once their behaviour compiles.
   ```elixir
   defmodule Accrue.MoxSetup do
     @moduledoc false
     def define_mocks do
       for {mock, behaviour} <- [
             {Accrue.ProcessorMock, Accrue.Processor},
             {Accrue.MailerMock, Accrue.Mailer},
             {Accrue.PDFMock, Accrue.PDF},
             {Accrue.AuthMock, Accrue.Auth}
           ] do
         if Code.ensure_loaded?(behaviour) and function_exported?(behaviour, :behaviour_info, 1) do
           Mox.defmock(mock, for: behaviour)
         end
       end
       :ok
     end
   end
   ```
2. `accrue/test/support/data_case.ex`:
   - Stub `Accrue.DataCase` using `ExUnit.CaseTemplate`. `using` block just provides `import Ecto` / `import Ecto.Query` — Plan 03 ships the real Repo-backed case (`Accrue.RepoCase`) in `test/support/repo_case.ex` when the test Repo module exists.
3. `accrue/test/test_helper.exs`:
   ```elixir
   Accrue.MoxSetup.define_mocks()
   ExUnit.start()
   ```
4. `accrue/test/accrue_test.exs`: one smoke test asserting `Code.ensure_loaded?(Accrue) == {:module, Accrue}`. This is the only test at Wave 0 — it proves the harness works and gives the Nyquist sampler a green signal before Wave 1 plans add real tests.

Note on D-20 / TEST-01: the Fake processor itself is a Plan 04 artifact. This task only makes the harness able to accept Plan 04's mocks once they exist.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix test 2>&1 | tail -20</automated>
  </verify>
  <acceptance_criteria>
    - `mix test` reports "1 test, 0 failures" (the accrue_test.exs smoke test)
    - `grep -q "Code.ensure_loaded?" accrue/test/support/mox_setup.ex` — the guards exist
    - `grep -q "Mox.defmock" accrue/test/support/mox_setup.ex` — defmock calls are present
    - No Mox warnings or errors ("behaviour not loaded") in test output
  </acceptance_criteria>
  <done>Test harness compiles and runs green with one smoke test. Mox mocks are staged to activate in Wave 1 plans without further edits to test_helper.exs.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Hex registry → mix.exs deps | Untrusted package versions pinned into build |
| Monorepo root → LICENSE consumers | License text must be unmodified MIT for downstream compliance |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-FND-01 | Tampering | Hex deps at install time | mitigate | Version pins are tight (`~>`), `mix.lock` is committed in a later plan, `mix hex.audit` runs in CI per Plan 06 |
| T-FND-02 | Information Disclosure | `config/runtime.exs` leak | accept | Empty at Wave 0; no secrets yet. Plan 04 adds `stripe_secret_key` reads via Application.get_env at call time (never compile_env per CLAUDE.md Config Boundaries) |
| T-FND-03 | Repudiation | Missing LICENSE | mitigate | MIT LICENSE dropped at root in Task 2; OSS-11 validated by grep |
</threat_model>

<verification>
- `cd accrue && mix deps.get && mix compile --warnings-as-errors && mix test` is fully green
- `cd accrue_admin && mix deps.get` resolves the sibling path dep
- `test -f LICENSE && grep -q "MIT License" LICENSE`
- `test ! -f mix.exs` at the monorepo root (confirms non-umbrella per D-42)
- `grep -q "config :accrue, :env" accrue/config/config.exs`
- `grep -q "Accrue.TestRepo" accrue/config/test.exs`
</verification>

<success_criteria>
The Wave 0 bootstrap is complete when all four Wave 1/2 plans (02 Money/Errors/Config/Telemetry, 03 Events, 04 Processor, 05 Mailer/PDF/Auth) can start work against a compiling, test-running harness with fully-wired static config without any of them needing to touch `mix.exs`, `config/*.exs`, or `test_helper.exs`.
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundations/01-01-SUMMARY.md` per the GSD summary template.
</output>
