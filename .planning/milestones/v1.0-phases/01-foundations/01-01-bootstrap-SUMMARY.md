---
phase: 01-foundations
plan: 01-bootstrap
subsystem: foundations
tags: [elixir, monorepo, mix, bootstrap, oss, ex_money, cldr, swoosh]
requirements: [FND-06, OSS-11, TEST-01]
dependency_graph:
  requires: []
  provides:
    - "accrue core mix project with locked deps"
    - "accrue_admin sibling mix project via path dep"
    - "Full static config (config/{config,dev,test,runtime}.exs)"
    - "ExUnit + Mox test harness with behaviour-guarded defmock"
    - "Accrue.Cldr backend for ex_money"
    - "MIT LICENSE at monorepo root"
  affects:
    - "Every subsequent Phase 1 plan compiles against this harness"
tech_stack:
  added:
    - "ecto ~> 3.13, ecto_sql ~> 3.13, postgrex ~> 0.22"
    - "ex_money ~> 5.24 (+ transitive ex_cldr stack)"
    - "lattice_stripe ~> 0.2"
    - "oban ~> 2.21"
    - "swoosh ~> 1.25, phoenix_swoosh ~> 1.2, mjml_eex ~> 0.13"
    - "chromic_pdf ~> 1.17"
    - "nimble_options ~> 1.1, telemetry ~> 1.3, jason ~> 1.4, decimal ~> 2.0"
    - "mox ~> 1.2, stream_data ~> 1.3"
    - "ex_doc ~> 0.40, credo ~> 1.7, dialyxir ~> 1.4"
    - "phoenix ~> 1.8, phoenix_live_view ~> 1.1, phoenix_html ~> 4.2 (accrue_admin only)"
  patterns:
    - "Non-umbrella sibling monorepo (D-42)"
    - "Path dep for accrue_admin -> accrue in dev (D-43)"
    - "CLDR backend required for ex_money startup"
    - "Mox behaviour-guarded defmock pattern (compiles before behaviours exist)"
key_files:
  created:
    - accrue/mix.exs
    - accrue/mix.lock
    - accrue/lib/accrue.ex
    - accrue/lib/accrue/cldr.ex
    - accrue/config/config.exs
    - accrue/config/dev.exs
    - accrue/config/test.exs
    - accrue/config/runtime.exs
    - accrue/test/test_helper.exs
    - accrue/test/support/mox_setup.ex
    - accrue/test/support/data_case.ex
    - accrue/test/accrue_test.exs
    - accrue_admin/mix.exs
    - accrue_admin/mix.lock
    - accrue_admin/lib/accrue_admin.ex
    - accrue_admin/config/config.exs
    - accrue_admin/config/dev.exs
    - accrue_admin/config/test.exs
    - accrue_admin/test/test_helper.exs
    - LICENSE
    - .gitignore
  modified: []
decisions:
  - "Dropped :sigra from deps/0 (not yet published to Hex). Conditional compile still works via Code.ensure_loaded?/1 pattern; add back as {:sigra, ~> 0.1, optional: true} once published."
  - "Created Accrue.Cldr (minimal ex_cldr backend with :en locale + Number/Money providers) to let :ex_money start — unlocked by Plan 02's Accrue.Money wrapper."
  - "config :swoosh, :api_client, false to prevent Swoosh's Application.start from requiring hackney; host apps can re-enable with Finch when using API-based adapters."
metrics:
  duration_seconds: 329
  tasks_completed: 3
  files_created: 21
  commits: 3
completed_date: 2026-04-12
---

# Phase 01 Plan 01: Bootstrap Summary

**One-liner:** Non-umbrella monorepo scaffolded with `accrue` + `accrue_admin` sibling mix projects, locked tech-stack deps resolved, full static config wired, ExUnit/Mox harness green with a smoke test, MIT LICENSE dropped at the root.

## What Shipped

### Task 1 — `accrue/` core package (commit `b22c012`)

- `mix.exs` with `@version "0.1.0"`, `app: :accrue`, `elixir: "~> 1.17"`, `elixirc_paths(:test)` adding `test/support`, `aliases.test.all` running format/credo/compile/test.
- 14 required deps pinned to the exact versions from CLAUDE.md §Technology Stack (re-verified in 01-RESEARCH.md). No `ex_money_sql` (per D-02 Accrue ships its own two-column Ecto type).
- 2 optional deps (`:opentelemetry`, `:telemetry_metrics`) declared. `:sigra` omitted — see Deviations.
- `application/0` returns `[extra_applications: [:logger]]` only. **No `mod:` key** — `Accrue.Application` lands in Plan 06 per FND-05, keeping Wave 1 plans free of OTP boot side effects.
- `config/config.exs`: `:env`, adapter placeholder keys (processor, mailer, pdf_adapter, auth_adapter, default_currency, emails, email_overrides, attach_invoice_pdf, enforce_immutability), Swoosh shim, `import_config`.
- `config/dev.exs`: `Swoosh.Adapters.Local`.
- `config/test.exs`: **Full Wave 2 wiring** — `Swoosh.Adapters.Test`, full `Accrue.TestRepo` sandbox stanza (database, pool, creds, priv), `:ecto_repos`, `:repo`. Plan 03 consumes these and never rewrites this file.
- `config/runtime.exs`: intentionally minimal at Wave 0. Stripe secrets wiring deferred to Phase 2 when a live webhook test proves the shape.
- `.gitignore` at monorepo root: `_build/`, `deps/`, `.elixir_ls/`, `priv/plts/`, `cover/`, `.DS_Store`.
- `mix deps.get` resolves clean. `mix compile --warnings-as-errors` green.

### Task 2 — `accrue_admin/` sibling + root LICENSE (commit `f35a982`)

- `accrue_admin/mix.exs` with `{:accrue, path: "../accrue"}` per D-43 dev path, plus `phoenix ~> 1.8`, `phoenix_live_view ~> 1.1`, `phoenix_html ~> 4.2`, dev-only `ex_doc`/`credo`.
- `lib/accrue_admin.ex` namespace anchor (Phase 7 lands the real dashboard).
- Config trio + `test_helper.exs` one-liner.
- `/Users/jon/projects/accrue/LICENSE` — canonical MIT text with `Copyright (c) 2026 Accrue contributors`. Satisfies OSS-11.
- Confirmed no root `mix.exs` (non-umbrella per D-42).
- `cd accrue_admin && mix deps.get` resolves `:accrue` via path plus the full Phoenix/LiveView tree.

### Task 3 — Test harness (commit `c3a6749`)

- `Accrue.MoxSetup.define_mocks/0` iterates `[{Accrue.ProcessorMock, Accrue.Processor}, {Accrue.MailerMock, Accrue.Mailer}, {Accrue.PDFMock, Accrue.PDF}, {Accrue.AuthMock, Accrue.Auth}]` with `Code.ensure_loaded?/1` + `function_exported?(behaviour, :behaviour_info, 1)` guards. Wave 0 compiles clean with zero behaviours loaded; Wave 1 plans activate their mocks automatically.
- `Accrue.DataCase` stub — `use ExUnit.CaseTemplate` with `import Ecto` / `import Ecto.Query`. Plan 03 ships the real Repo-backed `Accrue.RepoCase`.
- `test_helper.exs`: `Accrue.MoxSetup.define_mocks()` + `ExUnit.start()`.
- `accrue_test.exs`: single smoke assertion `Code.ensure_loaded(Accrue) == {:module, Accrue}`.
- `mix test` reports **1 test, 0 failures**. No "behaviour not loaded" warnings.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocker] :sigra not published to Hex**
- **Found during:** Task 1 (`mix deps.get`)
- **Issue:** The plan called for `{:sigra, "~> 0.1", optional: true}` per D-45 / CLAUDE.md §Conditional Compilation. Hex returned "No package with name sigra in registry." `:sigra` lives as a sibling project (`/Users/jon/projects/sigra`) but is not yet published.
- **Fix:** Dropped the sigra line from `deps/0` and left an inline comment pointing at the follow-up work. The CLAUDE.md conditional-compile pattern still functions via `Code.ensure_loaded?/1` and `@compile {:no_warn_undefined, Sigra.X}` guards in whichever plan eventually ships `Accrue.Integrations.Sigra` — none of which require `:sigra` to be listed in `deps/0` to work. Once `:sigra` publishes to Hex, add back the `{:sigra, "~> 0.1", optional: true}` line; no other code change needed.
- **Files modified:** `accrue/mix.exs`
- **Commit:** `b22c012`
- **Note:** The plan's acceptance criterion `grep -c 'optional: true' accrue/mix.exs` returns 3 coincidentally because the explanatory comment block contains the literal `optional: true` string. Criterion passes mechanically; update the criterion in future plans if strict dep-line counting is desired.

**2. [Rule 3 - Blocker] ex_money requires a CLDR backend to start its OTP app**
- **Found during:** Task 3 (`mix test`)
- **Issue:** `Money.Application.start/2` raised `RuntimeError: A default :ex_cldr backend must be configured`. The plan did not provision a CLDR backend; `:ex_money` is a listed dep.
- **Fix:** Created `Accrue.Cldr` at `accrue/lib/accrue/cldr.ex` — minimal `use Cldr` backend with `default_locale: "en"`, `locales: ["en"]`, `providers: [Cldr.Number, Money]`. Added `config :ex_cldr, default_backend: Accrue.Cldr` and `config :ex_money, default_cldr_backend: Accrue.Cldr` to `config/config.exs`. Plan 02's `Accrue.Money` wrapper (D-01) can use this backend directly or override locale list.
- **Files modified:** `accrue/lib/accrue/cldr.ex` (new), `accrue/config/config.exs`
- **Commit:** `c3a6749`

**3. [Rule 3 - Blocker] Swoosh.Application requires `:hackney` at boot**
- **Found during:** Task 3 (`mix test`)
- **Issue:** `Swoosh.Application.start/2` raised `RuntimeError: missing hackney dependency` from `Swoosh.ApiClient.Hackney.init/0`. Swoosh's default api_client expects hackney when not overridden.
- **Fix:** Added `config :swoosh, :api_client, false` to `config/config.exs`. Non-API-based adapters (`Local`, `Test`, `SMTP`) don't need an HTTP client. Host apps that use API-based adapters (SendGrid, Mailgun, Postmark) can re-enable it with Finch (which is already in the transitive dep tree via lattice_stripe/chromic_pdf).
- **Files modified:** `accrue/config/config.exs`
- **Commit:** `c3a6749`

None of these deviations required architectural decisions (Rule 4). All three are straightforward "library needs X at startup" wiring that the plan did not anticipate.

## Observed But Out of Scope

- Opentelemetry OTLP exporter warning at test boot: `OTLP exporter module 'opentelemetry_exporter' not found`. This is expected — `:opentelemetry` is optional and the exporter is user-wired per CLAUDE.md. The warning is a startup log line, not a test failure or compile warning; `mix compile --warnings-as-errors` and `mix test` are both green.

## Verification Results

```
cd accrue && mix deps.get            # 0
cd accrue && mix compile --warnings-as-errors  # 0 warnings
cd accrue && mix test                # 1 test, 0 failures
cd accrue_admin && mix deps.get      # 0, :accrue resolved via path
test -f LICENSE                      # present
grep -q "MIT License" LICENSE        # match
test ! -f /Users/jon/projects/accrue/mix.exs  # no umbrella root
grep -q "config :accrue, :env" accrue/config/config.exs  # present
grep -q "Accrue.TestRepo" accrue/config/test.exs          # present
grep -q "Ecto.Adapters.SQL.Sandbox" accrue/config/test.exs  # present
grep -q "config :accrue, :repo" accrue/config/test.exs    # present
grep -q "Swoosh.Adapters.Test" accrue/config/test.exs     # present
grep -q "Code.ensure_loaded?" accrue/test/support/mox_setup.ex  # present
grep -q "Mox.defmock" accrue/test/support/mox_setup.ex    # present
```

All green.

## Success Criteria Met

- All four Wave 1/2 plans (02 Money/Errors/Config/Telemetry, 03 Events, 04 Processor, 05 Mailer/PDF/Auth) can now start work against a compiling, test-running harness with fully-wired static config. No downstream plan needs to touch `mix.exs`, `config/*.exs`, or `test_helper.exs` — the Wave 2 file-collision class is eliminated.

## Known Stubs

None. All files either compile to working code (harness, configs, LICENSE) or are intentional Wave 0 namespace anchors (`Accrue`, `AccrueAdmin`, `Accrue.DataCase`) that are clearly marked as such in their `@moduledoc` and not wired into anything that would render incomplete output.

## Self-Check: PASSED

- `accrue/mix.exs` — FOUND
- `accrue/lib/accrue.ex` — FOUND
- `accrue/lib/accrue/cldr.ex` — FOUND
- `accrue/config/config.exs` — FOUND
- `accrue/config/dev.exs` — FOUND
- `accrue/config/test.exs` — FOUND
- `accrue/config/runtime.exs` — FOUND
- `accrue/test/test_helper.exs` — FOUND
- `accrue/test/support/mox_setup.ex` — FOUND
- `accrue/test/support/data_case.ex` — FOUND
- `accrue/test/accrue_test.exs` — FOUND
- `accrue_admin/mix.exs` — FOUND
- `accrue_admin/lib/accrue_admin.ex` — FOUND
- `accrue_admin/config/{config,dev,test}.exs` — FOUND
- `accrue_admin/test/test_helper.exs` — FOUND
- `LICENSE` — FOUND
- `.gitignore` — FOUND
- Commit `b22c012` — FOUND
- Commit `f35a982` — FOUND
- Commit `c3a6749` — FOUND
