# Stack Research

**Domain:** Open-source Elixir/Phoenix payments & billing library (Accrue)
**Researched:** 2026-04-11
**Confidence:** HIGH for version pins (Hex.pm API verified 2026-04-11); MEDIUM for integration patterns (synthesized from official docs + sibling project precedent); LOW on `mjml_eex` freshness signal (last release Dec 2025, still current head).

This document is prescriptive. Architectural decisions are already locked in `PROJECT.md`. Everything below is the concrete fill-in the roadmapper needs: exact `mix.exs` constraints, a compatibility matrix, and the integration glue between libraries.

---

## Recommended Stack

### Core Technologies — `accrue` package

| Technology | Version Constraint | Purpose | Rationale |
|------------|-------------------|---------|-----------|
| Elixir | `~> 1.17` | Language | Locked in PROJECT.md. Matches `config/runtime.exs` era, native `Ecto.Repo.transact/2`, OTP 27 baseline. |
| Erlang/OTP | `27+` | Runtime | Locked. Required for Elixir 1.17. |
| `:phoenix` | `~> 1.8` | HTTP layer (optional-not-required at runtime, but we target 1.8 conventions) | Locked. Needed for verified routes and the 1.8 LiveView stream/function-component shape in `accrue_admin`. |
| `:ecto` | `~> 3.13` | Domain modeling | Bumped from `~> 3.12` because `ecto_sql` current is **3.13.5** (2025-11-09), and Accrue's `Repo.transact/2` usage is cleanest on 3.12+. `~> 3.13` is strict enough to guarantee the API we need. |
| `:ecto_sql` | `~> 3.13` | Repo + migrations | Pinned to match `:ecto` minor. Current **3.13.5**. |
| `:postgrex` | `~> 0.22` | PG driver | Current stable is **0.22.0** (2026-01-10). Postgrex is still pre-1.0 and Ecto 3.13 accepts `~> 0.20 or ~> 1.0`; pin to `~> 0.22` to avoid a surprise `0.23` minor that could churn JSONB encoding. No extensions required — `gen_random_uuid()` is in core since PG 13, which satisfies Accrue's PG 14+ floor. Do NOT require `pg_uuidv7` — not worth the install burden. |
| `:lattice_stripe` | `~> 0.2` | Stripe API wrapper | Sibling lib, currently **0.2.0**. Use `~> 0.2` so Accrue tracks lattice_stripe minor bumps without breaking on 0.3 (which will bring Billing/Subscription resources — that will be a coordinated Accrue version bump). CRITICAL: lattice_stripe does NOT yet cover Subscription/Price/Product/Invoice/Meter — those must land in lattice_stripe before Accrue's billing phases can ship. Flag in roadmap as a cross-repo dependency. |
| `:oban` | `~> 2.21` | Async jobs (webhooks, email) | Community edition current is **2.21.1** (2026-03-26). Oban 2.21 requires Elixir 1.15+, Erlang 24+, PostgreSQL 14.0+ — all satisfied by our floor. Community edition (not Pro) is sufficient for v1.0; all features we need (retries, priority queues, uniqueness, cron, pruning) are in open-source Oban. No PG extensions required. |
| `:swoosh` | `~> 1.25` | Email delivery | Current **1.25.0** (2026-04-02). Wrapped behind `Accrue.Mailer` facade — but we list it as a direct dep (not optional) since email is a table-stakes feature and Swoosh is the Phoenix default. |
| `:phoenix_swoosh` | `~> 1.2` | HEEx template rendering for emails | Current **1.2.1** (2024-01-07). Older but stable; provides the `render_body/3` helper that lets us reuse HEEx templates for both email HTML and the PDF-source HTML. This is the glue that makes "single source of truth HEEx → email + PDF" work. |
| `:mjml_eex` | `~> 0.13` | Responsive email via MJML | Current **0.13.0** (2025-12-15). The "swoosh_mjml" name from PROJECT.md does NOT exist on Hex — the idiomatic package is Alex Koutmos's `mjml_eex`, which compiles MJML via a Rustler NIF (default) with a NodeJS fallback. Integrates with phoenix_swoosh as a template engine. **Update PROJECT.md to say `mjml_eex` not `swoosh_mjml`.** |
| `:chromic_pdf` | `~> 1.17` | Default PDF adapter | Current **1.17.1** (2026-03-19). Requires Chrome/Chromium available on the host (Chrome ≥ 91 for full-page screenshots; core rendering works on older) and Ghostscript for PDF/A. Supervise via `{ChromicPDF, on_demand: true}` in dev/test and persistent pool in prod. In library design: ChromicPDF must NOT be started by the Accrue application — it's started by the host app's supervision tree, and the `Accrue.PDF.ChromicPDF` adapter only calls into it. In tests, use `Accrue.PDF.Test` adapter so no Chrome binary is needed in CI. |
| `:nimble_options` | `~> 1.1` | Config schema + validation | Current **1.1.1** (2024-05-25). Feature-complete; slow release cadence is fine. Use for `Accrue.Config` schema, surfaced via `NimbleOptions.docs/1` in the ExDoc for `Accrue` module. |
| `:telemetry` | `~> 1.3` | Event instrumentation | Current 1.3.x. No-brainer — already transitively pulled in by Phoenix/Ecto/Oban but declare explicitly. |
| `:telemetry_metrics` | `~> 1.1` | Metric aggregation helpers | Current **1.1.0** (2025-01-24). Only needed if Accrue ships default metric definitions for users to feed into their reporter; make it **optional** since users may prefer their own `telemetry_metrics` setup. |
| `:jason` | `~> 1.4` | JSON | Current stable **1.4.4** (2024-07-26). Still the Elixir community default; Poison is abandoned. Used for the `data` jsonb columns in `accrue_webhook_events` and `accrue_events`. |

### Core Technologies — `accrue_admin` package

| Technology | Version Constraint | Purpose | Rationale |
|------------|-------------------|---------|-----------|
| `:accrue` | `== <same version>` | Core billing lib | Sibling dep via `path:` in dev (monorepo) and version-pinned in published releases. Must be exact version match per release — documented in release script. |
| `:phoenix_live_view` | `~> 1.1` | LiveView dashboard | Current **1.1.28** (2026-03-27). LiveView 1.1 is the stable line; `~> 1.1` gets us 1.1.x patches without 1.2 surprises. Admin UI is the only place LiveView appears — core `accrue` stays LiveView-free. |
| `:phoenix` | `~> 1.8` | Router/Endpoint | Same as core. |
| `:phoenix_html` | `~> 4.2` | HEEx helpers | LiveView 1.1 requires phoenix_html 4.x. |

### Optional Dependencies

| Library | Version | Marker | Integration Point |
|---------|---------|--------|-------------------|
| `:sigra` | `~> 0.1` | `optional: true` | Auto-detected; conditionally compiles `Accrue.Integrations.Sigra` adapter. See "Conditional Compilation" section below. |
| `:opentelemetry` | `~> 1.7` | `optional: true` | Current **1.7.0** (2025-10-17). Accrue's OTel span helpers no-op if `:opentelemetry` is not loaded. |
| `:opentelemetry_ecto` | `~> 1.2` | `optional: true` | Current **1.2.0** (2024-02-06). User-wired, not Accrue-wired — we document the attach call in guides. |
| `:opentelemetry_phoenix` | `~> 2.0` | `optional: true` | Current **2.0.1** (2025-02-21). Same — user wires, we document. |
| `:telemetry_metrics` | `~> 1.1` | `optional: true` | Only if user opts into Accrue's default metrics module. |

**OTel verdict:** Keep OpenTelemetry entirely optional at the mix.exs level. Accrue's core only emits `:telemetry` events (which are always on); OTel helpers live behind a `Code.ensure_loaded?(:opentelemetry)` guard and are documented as opt-in. This avoids forcing the ~15-package OTel tree on users who just want telemetry.

### Development / Test Dependencies (`accrue` package)

| Library | Version | `only:` | Purpose |
|---------|---------|---------|---------|
| `:ex_doc` | `~> 0.40` | `[:dev]`, `runtime: false` | Current **0.40.1** (2026-01-31). ExDoc with guides + cheatmd. |
| `:credo` | `~> 1.7` | `[:dev, :test]`, `runtime: false` | Current **1.7.18** (2026-04-10). Use `credo --strict` in CI. |
| `:dialyxir` | `~> 1.4` | `[:dev, :test]`, `runtime: false` | Current **1.4.7** (2025-11-06). |
| `:mix_audit` | `~> 2.1` | `[:dev, :test]`, `runtime: false` | Current **2.1.5** (2025-06-09). Run in CI via `mix deps.audit`. |
| `:excoveralls` | `~> 0.18` | `[:test]` | Current **0.18.5** (2025-01-26). Coverage → Coveralls/Codecov. |
| `:stream_data` | `~> 1.3` | `[:dev, :test]` | Current **1.3.0** (2026-03-09). Property tests for money math (zero-decimal currencies, proration, rounding). Non-negotiable for a billing library. |
| `:mox` | `~> 1.2` | `[:test]` | Current **1.2.0** (2024-08-14). **See "Test Library Decision" below.** |
| `:bypass` | `~> 2.1` | `[:test]` | HTTP server fake for testing the Fake Processor + webhook plug. Not strictly required since lattice_stripe already has its own test helpers, but useful for end-to-end plug tests. Optional — add only if we find ourselves reaching for it. |

---

## Test Library Decision: Mox, Decisively

**Use `:mox ~> 1.2`. Do not use Mimic.**

Reasoning (resolves the Mox-vs-Mimic question from the research brief):

1. **Accrue ships three behaviours whose entire raison d'être is to be mocked:** `Accrue.Auth`, `Accrue.Mailer`, `Accrue.PDF`. These are explicit, compile-time contracts — exactly what Mox is designed for (per José Valim's "Mocks and Explicit Contracts" essay, which is still the canonical Elixir position). Mimic exists for the case where you're mocking a module you don't control; here we control everything.

2. **lattice_stripe and sigra both use Mox.** Matching the sibling-lib test style minimizes cognitive overhead when jumping between repos. (lattice_stripe: `{:mox, "~> 1.2"}`; sigra: `{:mox, "~> 1.1"}`.)

3. **We ship first-class Test adapters anyway** (`Accrue.Processor.Fake`, `Accrue.PDF.Test`, `Accrue.Mailer.Test`). These are the primary test surface for users — Mox is the secondary surface, used only when a host app wants to assert at the boundary in its own tests. A Fake adapter + Mox for behaviour overrides is a stronger story than Mimic's "runtime monkey-patch" model for a library whose sell is "test-first billing development."

4. **Mox's compile-time behaviour checking catches API drift at `mix compile`**, which matters enormously for a library where we're maintaining contracts that third-party adapters implement.

Do not depend on `:hammox` either — Mox 1.2 has runtime contract checking in `defmock` options, which is enough.

---

## Installation — mix.exs Template

### `accrue/mix.exs` (core)

```elixir
defp deps do
  [
    # --- runtime, required ---
    {:phoenix, "~> 1.8"},
    {:ecto, "~> 3.13"},
    {:ecto_sql, "~> 3.13"},
    {:postgrex, "~> 0.22"},
    {:lattice_stripe, "~> 0.2"},
    {:oban, "~> 2.21"},
    {:swoosh, "~> 1.25"},
    {:phoenix_swoosh, "~> 1.2"},
    {:mjml_eex, "~> 0.13"},
    {:chromic_pdf, "~> 1.17"},
    {:nimble_options, "~> 1.1"},
    {:telemetry, "~> 1.3"},
    {:jason, "~> 1.4"},

    # --- runtime, optional ---
    {:sigra, "~> 0.1", optional: true},
    {:opentelemetry, "~> 1.7", optional: true},
    {:opentelemetry_api, "~> 1.4", optional: true},
    {:telemetry_metrics, "~> 1.1", optional: true},

    # --- dev/test ---
    {:ex_doc, "~> 0.40", only: [:dev], runtime: false},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
    {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
    {:excoveralls, "~> 0.18", only: [:test]},
    {:stream_data, "~> 1.3", only: [:dev, :test]},
    {:mox, "~> 1.2", only: [:test]}
  ]
end
```

### `accrue_admin/mix.exs`

```elixir
defp deps do
  [
    {:accrue, path: "../accrue"},       # dev
    # {:accrue, "== 1.0.0"},            # published — exact match, bumped in lockstep
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:phoenix_html, "~> 4.2"},
    {:jason, "~> 1.4"},

    {:ex_doc, "~> 0.40", only: [:dev], runtime: false},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
  ]
end
```

---

## Version Compatibility Matrix

| Anchor Pin | Forces | Notes |
|------------|--------|-------|
| `elixir ~> 1.17` | OTP 27+, Phoenix 1.8+, LiveView 1.1+ | Locked. |
| `ecto ~> 3.13` | `ecto_sql ~> 3.13`, `postgrex ~> 0.22` | Ecto 3.13 supports `postgrex ~> 0.20 or ~> 1.0` but we pin tighter. |
| `oban ~> 2.21` | Postgres 14+, Ecto 3.12+ | Already matches our floor. Oban uses `ecto_sql` directly; no conflict. |
| `phoenix ~> 1.8` | `phoenix_html ~> 4.1+`, `plug ~> 1.16` | Transitive. |
| `phoenix_live_view ~> 1.1` | `phoenix ~> 1.7 or ~> 1.8`, `phoenix_html ~> 4.2` | Admin-only. |
| `chromic_pdf ~> 1.17` | Chrome/Chromium on host (runtime, not mix) | Document in install guide, not enforceable via deps. |
| `mjml_eex ~> 0.13` | Rustler NIF build OR local `node` + `mjml` npm package | Default is the Rustler-built binary (no Node required at runtime). Document Rustler fallback. |
| `sigra ~> 0.1` (optional) | If present: `phoenix ~> 1.8`, `ecto ~> 3.12`, `nimble_options ~> 1.1` | All already in our deps. Zero conflict risk. |
| `lattice_stripe ~> 0.2` | `finch ~> 0.19`, `plug_crypto ~> 2.0` | Finch pulls in Mint/Mimir — ~4 transitive packages. Acceptable. |

### Elixir / OTP / Phoenix CI Matrix

| Elixir | OTP | Phoenix | Notes |
|--------|-----|---------|-------|
| 1.17.x | 27 | 1.8.x | Floor — this is the minimum supported. |
| 1.18.x | 27 | 1.8.x | Primary development target. |
| 1.18.x | 28 | 1.8.x | Forward-compat smoke test. |

Do not test against 1.16 or earlier. Do not test against Phoenix 1.7.

---

## Conditional Compilation for Optional Deps

This is the single most common source of `--warnings-as-errors` breakage for libraries. The idiomatic 2026 pattern, verified from the sibling `sigra` project's `mix.exs`:

### 1. Declare optional in `deps/0`
```elixir
{:sigra, "~> 0.1", optional: true}
```

### 2. Silence compiler warnings for undefined optional modules
In `project/0`, add `elixirc_options: elixirc_options()`:

```elixir
defp elixirc_options do
  [
    no_warn_undefined: [
      Sigra,
      Sigra.Auth,
      Sigra.Audit,
      # ... every symbol Accrue.Integrations.Sigra touches
    ]
  ]
end
```

This is the pattern sigra itself uses for its own optional deps (Bcrypt, Oban, Swoosh). It's idiomatic, not a hack.

### 3. Guard the integration module at `use` time
```elixir
defmodule Accrue.Integrations.Sigra do
  @moduledoc false
  if Code.ensure_loaded?(Sigra) do
    @behaviour Accrue.Auth
    # real impl
  else
    @moduledoc false
    # stub or not defined at all
  end
end
```

Prefer `Code.ensure_loaded?/1` over `Application.compile_env/3` because it checks at compile-time for the module's existence, not a config flag. The installer (`mix accrue.install`) handles auto-wiring: if `Sigra` is in the host app's deps, the installer sets `config :accrue, :auth_adapter, Accrue.Integrations.Sigra`.

### 4. Runtime dispatch via config, not compile-time
In `Accrue.Auth`:
```elixir
def current_user(conn), do: adapter().current_user(conn)
defp adapter, do: Application.get_env(:accrue, :auth_adapter, Accrue.Auth.Default)
```

This combination (`no_warn_undefined` + `Code.ensure_loaded?` + runtime adapter lookup) is the pattern that survives `mix compile --warnings-as-errors` in downstream apps.

---

## Config Boundaries: Compile-time vs Runtime

As a library in 2026, Accrue should follow these rules:

| Setting | Where | Why |
|---------|-------|-----|
| `:auth_adapter`, `:pdf_adapter`, `:mailer_adapter`, `:processor` | `config/config.exs` (compile-time OK) | Adapter resolution is stable per-deploy; compile-time is fine and slightly faster at lookup. Use `Application.compile_env!/2` inside Accrue modules so misconfig fails at `mix compile`, not at runtime. |
| `:stripe_secret_key`, `:webhook_signing_secret` | `config/runtime.exs` (MUST be runtime) | Secrets come from env vars at release-start; compile-time reading leaks build secrets into release artifacts. |
| `:default_currency`, `:from_email`, brand colors | `config/runtime.exs` | Host-owned, may differ per-env. |
| `:oban` queue config | Host-owned, runtime | Accrue documents recommended queues (`accrue_webhooks: 10`, `accrue_mailers: 20`), host wires into their own Oban config. Accrue does NOT start its own Oban instance. |
| Feature flags (e.g., enable_dunning?) | `config/runtime.exs` | Want to toggle without recompile. |

**Rule of thumb:** anything validated by NimbleOptions runs through `Accrue.Config.validate!/1` at app boot (in `Accrue.Application.start/2`), reading from `Application.get_all_env(:accrue)`. This gives one error site with a clean message.

---

## Monorepo Layout — grounded in precedent

Real Elixir monorepo precedents surveyed:
- **Membrane Framework** (`membraneframework/membrane_core` + many `membrane_*_plugin` repos) — actually multi-repo, not monorepo. Reject as precedent.
- **Broadway** (`dashbitco/broadway` + `broadway_kafka` / `broadway_rabbitmq` / `broadway_sqs`) — multi-repo. Reject.
- **Nerves** (`nerves-project/nerves`) — single-repo single-package. Reject.
- **Absinthe** (`absinthe-graphql/absinthe` + `absinthe_phoenix`, `absinthe_plug`) — multi-repo. Reject.
- **Phoenix** itself (`phoenixframework/phoenix` + `phoenix_live_view` + `phoenix_ecto`) — multi-repo. Reject.
- **Oban** (`oban-bg/oban` + `oban_web` + `oban_pro`) — Oban core is single-repo; Oban Web is separate. Reject the "same repo, two packages" precedent here.
- **`lattice_stripe`** (sibling, same author) — single-repo single-package but already uses Release Please with `release-please-config.json`. Use as the template.

**Finding:** the Elixir ecosystem does NOT have a strong "two sibling packages in one repo" precedent. That's fine — this is a JavaScript/Rust-flavored pattern, and Release Please handles it natively. But it means we must lean on Release Please's generic monorepo support rather than an Elixir-specific playbook.

### Proposed layout
```
accrue/                          # repo root
├── .github/workflows/
│   ├── ci.yml                   # matrix build for both packages
│   └── release-please.yml       # shared, manifest-driven
├── .release-please-manifest.json
├── release-please-config.json
├── accrue/                      # package 1
│   ├── lib/
│   ├── test/
│   ├── mix.exs
│   ├── CHANGELOG.md             # per-package
│   └── README.md
├── accrue_admin/                # package 2
│   ├── lib/
│   ├── test/
│   ├── mix.exs
│   ├── CHANGELOG.md             # per-package
│   └── README.md
├── guides/                      # shared ExDoc guides
├── LICENSE                      # single MIT at root
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── SECURITY.md
└── README.md                    # points to both packages
```

### Release Please config for 2-package Elixir monorepo

`release-please-config.json`:
```json
{
  "separate-pull-requests": true,
  "release-type": "elixir",
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": false,
  "changelog-sections": [
    {"type": "feat", "section": "Features"},
    {"type": "fix",  "section": "Bug Fixes"},
    {"type": "perf", "section": "Performance Improvements"},
    {"type": "deps", "section": "Dependencies"},
    {"type": "chore","section": "Miscellaneous", "hidden": true}
  ],
  "packages": {
    "accrue": {
      "package-name": "accrue",
      "release-type": "elixir"
    },
    "accrue_admin": {
      "package-name": "accrue_admin",
      "release-type": "elixir"
    }
  }
}
```

`.release-please-manifest.json`:
```json
{
  "accrue": "0.0.0",
  "accrue_admin": "0.0.0"
}
```

`release-please.yml`:
```yaml
name: Release Please
on:
  push:
    branches: [main]
permissions:
  contents: write
  pull-requests: write
jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        id: release
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
      # Conditional Hex publish steps, keyed on per-package outputs:
      - if: ${{ steps.release.outputs['accrue--release_created'] }}
        run: cd accrue && mix hex.publish --yes
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
      - if: ${{ steps.release.outputs['accrue_admin--release_created'] }}
        run: cd accrue_admin && mix hex.publish --yes
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```

**Known gotchas (from Release Please v4 field reports):**
- v4 changed output naming — outputs are now prefixed with the package path (`accrue--release_created`, not `accrue.release_created`). Verify with a dry-run before relying on them.
- `release-type: "elixir"` natively updates `mix.exs` `@version` — no custom extra-files needed if `@version "x.y.z"` is at the top of `mix.exs` (which both sibling projects already do).
- `bump-minor-pre-major: true` + `bump-patch-for-minor-pre-major: false` means `feat:` → minor, `fix:` → minor (NOT patch) pre-1.0. This matches how `lattice_stripe` is configured. Flip `bump-patch-for-minor-pre-major` to `true` if we want patch bumps for fixes pre-1.0.
- Version lockstep between `accrue` and `accrue_admin` is NOT enforced by Release Please — both can drift independently. We handle the same-day-v1.0 release by manually coordinating the two release PRs.

---

## Dialyzer PLT Caching Pattern (GitHub Actions, 2026)

Idiomatic 2026 cache key for PLT files — used by Phoenix, Ecto, and every major Elixir lib:

```yaml
- name: Restore PLT cache
  id: plt_cache
  uses: actions/cache/restore@v4
  with:
    key: plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
    restore-keys: |
      plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-
    path: |
      priv/plts

- name: Create PLTs
  if: steps.plt_cache.outputs.cache-hit != 'true'
  run: mix dialyzer --plt

- name: Save PLT cache
  if: steps.plt_cache.outputs.cache-hit != 'true'
  uses: actions/cache/save@v4
  with:
    key: ${{ steps.plt_cache.outputs.cache-primary-key }}
    path: |
      priv/plts

- name: Run dialyzer
  run: mix dialyzer --format github
```

Key elements:
- `actions/cache/restore@v4` + `actions/cache/save@v4` split (not the combined `actions/cache@v4`) so saves only happen on cache miss — prevents cache thrashing.
- PLT path must be `priv/plts` (or whatever's in `mix.exs` `dialyzer.plt_local_path`).
- Cache key is OTP version × Elixir version × mix.lock hash — NOT on git SHA.
- `--format github` surfaces warnings as GitHub Actions annotations.

In a monorepo, run this twice (once per package `cd accrue && ...`, once per `cd accrue_admin && ...`) with distinct PLT paths.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `:mox` | `:mimic` | Only if we end up needing to mock modules we don't own (e.g., if we decide to mock `LatticeStripe.Customer` directly in adapter tests rather than dispatching through our own behaviour). We shouldn't, because the Fake Processor pattern eliminates this need. |
| `:mox` | `:hammox` | If we hit a case where Mox 1.2's contract-checking isn't strict enough. Unlikely. |
| `:chromic_pdf` | `:gotenberg` (sidecar) | When host app runs in a Chrome-hostile environment (some serverless, some locked-down containers). Documented as a custom `Accrue.PDF` adapter, not as a first-party default. |
| `:mjml_eex` | `:mjmleex` (Elonsoft) | `mjml_eex` has more downloads, active maintenance (0.13 in Dec 2025), and a Rustler NIF backend. Only choose `mjmleex` if Rustler build fails on a target arch. |
| `:phoenix_swoosh` | Hand-rolled EEx + Swoosh.Email | Phoenix Swoosh is 300 lines and provides exactly the template integration we need. No reason to hand-roll. |
| `:jason` | `:poison`, `:jiffy`, `JSON` (stdlib 1.18+) | **Reconsider `JSON` (OTP 28 stdlib module)** post-v1.0. For v1.0 stay on `:jason` — it's zero-dep in practice (already transitive through Phoenix/Ecto) and every Elixir library is tested against it. OTP 28's native `JSON` isn't universally adopted in the Phoenix ecosystem yet. |
| `:oban` (community) | `:oban_pro` | Oban Pro's features (workflows, batches, smart engines) are not needed for v1.0. Accrue only uses Oban for webhook retry and email dispatch — both core-edition features. |
| `:opentelemetry` as required dep | `:opentelemetry` as optional dep | We went with optional. OTel's dep tree is ~15 packages and forces users who just want `:telemetry` to carry it. |
| `:nimble_options` | `:vex`, hand-rolled `with`-chains | NimbleOptions is the ecosystem default since Phoenix started using it for router/plug opts. Hand-rolled validation fails at the "docs generation" step — NimbleOptions gives us `Accrue.Config` docs for free. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `:stripity_stripe` | Pinned to 2019 Stripe API; Bling's dependence on it is exactly the gap we're replacing. | `:lattice_stripe` (our own, tracking Stripe `2026-03-25.dahlia`). |
| `:bamboo` | Maintenance-mode; Phoenix moved to Swoosh as default in 1.6. | `:swoosh`. |
| `:poison` | Abandoned; Jason is ~2× faster and is the ecosystem default. | `:jason`. |
| `:exq` / `:verk` / `:rihanna` | Either abandoned or niche. Oban is the Elixir job-queue standard in 2026. | `:oban`. |
| `:httpoison` / `:tesla` for Stripe calls | Accrue should not make HTTP calls directly — all Stripe traffic goes through `:lattice_stripe`, which uses `:finch` internally. | `:lattice_stripe`. |
| `:commanded` / `:eventstore` | CQRS/ES is the wrong abstraction for billing — already rejected in PROJECT.md key decisions. | Append-only `accrue_events` table. |
| `:pdf_generator` | Wraps wkhtmltopdf, which is archived and has unpatched CVEs. | `:chromic_pdf`. |
| `:absinthe` (GraphQL) | Accrue is not GraphQL-shaped — REST-ish context functions are idiomatic Phoenix. | Plain `Accrue.Billing` context. |
| `:ueberauth` | Not our layer — Accrue doesn't own auth. | `Accrue.Auth` behaviour, host app owns Ueberauth/Sigra/phx.gen.auth. |
| `:mock` (the library) | Global mutation, flaky under async, community consensus is to avoid. | `:mox`. |
| `pg_uuidv7` Postgres extension | Adds install burden; `gen_random_uuid()` is in PG 14 core and is good enough. UUIDv7 benefits are marginal for Accrue's access patterns. | Built-in `gen_random_uuid()`. |
| `:decimal` as an unpinned transitive | Pin it explicitly — money math correctness depends on it. | `{:decimal, "~> 2.0"}` (already transitive through Ecto, but pin it). |

**Add `{:decimal, "~> 2.0"}` to the core deps list** — already transitive, but for a billing library it's load-bearing and should be explicit.

---

## Full Expected Transitive Footprint

Approximate top-level dep count for `accrue/`: **~15 direct runtime + ~50-60 transitive**. This is comparable to a Phoenix 1.8 app with Oban and Swoosh — no surprises. The ChromicPDF system dependency (Chrome binary) is the only non-Hex install burden on users, and it's opt-out via the `Accrue.PDF` behaviour.

---

## Sources

- Hex.pm API (verified 2026-04-11, HIGH confidence):
  - https://hex.pm/api/packages/oban → 2.21.1 (2026-03-26)
  - https://hex.pm/api/packages/chromic_pdf → 1.17.1 (2026-03-19)
  - https://hex.pm/api/packages/swoosh → 1.25.0 (2026-04-02)
  - https://hex.pm/api/packages/phoenix → 1.8.5 (2026-03-05)
  - https://hex.pm/api/packages/phoenix_live_view → 1.1.28 (2026-03-27)
  - https://hex.pm/api/packages/ecto_sql → 3.13.5 (2026-03-03)
  - https://hex.pm/api/packages/ecto → 3.13.5 (2025-11-09)
  - https://hex.pm/api/packages/postgrex → 0.22.0 (2026-01-10)
  - https://hex.pm/api/packages/mimic → 2.3.0 (2026-01-17)
  - https://hex.pm/api/packages/mox → 1.2.0 (2024-08-14)
  - https://hex.pm/api/packages/mjml_eex → 0.13.0 (2025-12-15)
  - https://hex.pm/api/packages/phoenix_swoosh → 1.2.1 (2024-01-07)
  - https://hex.pm/api/packages/nimble_options → 1.1.1 (2024-05-25)
  - https://hex.pm/api/packages/opentelemetry → 1.7.0 (2025-10-17)
  - https://hex.pm/api/packages/opentelemetry_ecto → 1.2.0 (2024-02-06)
  - https://hex.pm/api/packages/opentelemetry_phoenix → 2.0.1 (2025-02-21)
  - https://hex.pm/api/packages/telemetry_metrics → 1.1.0 (2025-01-24)
  - https://hex.pm/api/packages/ex_doc → 0.40.1 (2026-01-31)
  - https://hex.pm/api/packages/credo → 1.7.18 (2026-04-10)
  - https://hex.pm/api/packages/dialyxir → 1.4.7 (2025-11-06)
  - https://hex.pm/api/packages/stream_data → 1.3.0 (2026-03-09)
  - https://hex.pm/api/packages/excoveralls → 0.18.5 (2025-01-26)
  - https://hex.pm/api/packages/mix_audit → 2.1.5 (2025-06-09)
- Sibling project source-of-truth (HIGH confidence):
  - `/Users/jon/projects/lattice_stripe/mix.exs` — dep versions, release-please-config.json
  - `/Users/jon/projects/sigra/mix.exs` — optional-dep pattern, `no_warn_undefined`, test tools
- Release Please for Elixir (MEDIUM confidence — one primary source):
  - https://elixirschool.com/blog/managing-releases-with-release-please
  - https://github.com/googleapis/release-please-action (v4)
- Mocking library positioning (MEDIUM confidence — synthesis across sources):
  - https://dashbit.co/blog/mocks-and-explicit-contracts (Valim, canonical)
  - https://hexdocs.pm/mimic/Mimic.html
  - https://github.com/edgurgel/mimic
- ChromicPDF requirements (MEDIUM confidence — official docs do not specify exact Chrome minimum for base rendering):
  - https://hexdocs.pm/chromic_pdf/ChromicPDF.html
- Oban 2.21 requirements (HIGH confidence):
  - https://github.com/oban-bg/oban

---

## Flags for Roadmap Consumer

1. **PROJECT.md says `swoosh_mjml` — that package does NOT exist.** The correct package is `:mjml_eex`. Update PROJECT.md in the next transition.
2. **`lattice_stripe` lacks Billing/Subscription/Invoice coverage.** Accrue's billing phases are blocked on lattice_stripe extensions (or Accrue contributing them upstream). The roadmap must sequence a "lattice_stripe Tier 3 contributions" workstream before, or interleaved with, Accrue's billing domain phases.
3. **`:postgrex` is still pre-1.0.** A `0.23` release during Accrue's build could cause churn. Watch upstream.
4. **`phoenix_swoosh 1.2.1` is over 2 years old.** Still canonical, but if it goes unmaintained a fork may be needed — unlikely in the v1.0 window.
5. **`nimble_options 1.1.1` hasn't released in 2 years.** Feature-complete, not abandoned — confirmed via ecosystem usage. Safe.
6. **Version lockstep between `accrue` and `accrue_admin`** is a manual process under Release Please — document the release runbook clearly.
7. **ChromicPDF's Chrome-binary dependency** is the one install-burden item for users. The `Accrue.PDF` behaviour makes this opt-outable, but it should be called out loudly in the installation guide.

---
*Stack research for: Elixir/Phoenix open-source payments library*
*Researched: 2026-04-11*
