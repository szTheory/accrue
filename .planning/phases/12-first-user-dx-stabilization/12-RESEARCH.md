# Phase 12: First-User DX Stabilization - Research

**Researched:** 2026-04-16
**Domain:** Phoenix/Elixir library installer UX, setup diagnostics, host-app documentation, Hex package correctness
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Installer Rerun Behavior

- **D-01:** Use a no-clobber, pristine-update installer contract. Reruns may overwrite only Accrue-stamped pristine generated files.
- **D-02:** Stamped generated files whose fingerprint no longer matches must always be treated as user-edited and skipped. `--force` must not clobber these files.
- **D-03:** Unmarked existing files must be skipped by default. `--force` may overwrite only unmarked existing files, making the destructive behavior narrow and explicit.
- **D-04:** `--write-conflicts` must become real. It should write rendered replacements or patch/manual snippets as sidecar conflict artifacts outside live compile/config paths, preferably under a dedicated dotdir such as `.accrue/conflicts/`, with target path and reason included.
- **D-05:** Installer summary output must distinguish `created`, `updated pristine`, `skipped user-edited`, `skipped exists`, `manual`, and conflict artifact paths so CI failures and first-user reruns are diagnosable.

### Actionable Setup Failures

- **D-06:** Create a centralized setup-diagnostic contract shared by installer/preflight, boot-time configuration checks, and selected webhook/admin runtime checks. The user-facing shape should include stable `code`, concise summary, fix instructions, and docs path/anchor.
- **D-07:** Keep boot-fatal setup issues as `Accrue.ConfigError` or a compatible setup exception: missing repo config, pending/missing migrations, Oban not configured or not supervised when required, production use of dev/test auth adapters, and missing webhook signing secret.
- **D-08:** Keep public HTTP webhook responses generic: bad signatures return generic `400`; host misconfiguration returns a generic server error. Detailed diagnostics belong in logs/exceptions, redacted and linked to docs.
- **D-09:** Preflight or boot checks should catch first-hour wiring mistakes where practical: webhook route missing, raw-body reader missing or in the wrong pipeline, webhook mounted behind browser/CSRF/auth pipeline, admin mount missing, and auth adapter/admin protection missing.
- **D-10:** All diagnostics must redact secret-like values (`sk_*`, `whsec_*`, env var values with `SECRET`/`KEY`) and should name env var keys/classes rather than raw values.

### Docs Shape

- **D-11:** Use a split documentation structure, not one monolithic quickstart. Keep README/package landing copy compact, create or expand a host-app-derived "First Hour" guide as the canonical setup walkthrough, and add a troubleshooting matrix linked from failure-prone steps.
- **D-12:** The First Hour guide must follow the `examples/accrue_host` path in Phoenix order: deps, installer, runtime config, migrations, Oban, webhook route/raw-body, auth/admin mount, first Fake-backed subscription, signed webhook proof, admin inspection, and tests.
- **D-13:** The troubleshooting matrix should be organized by symptom and stable diagnostic code, with "what happened", "why Accrue cares", "fix", and "how to verify" columns.
- **D-14:** Existing topic guides should stay focused: testing guide for `Accrue.Test` and Fake, webhook guide for signatures/raw body/replay, admin guide for mount/auth/session, upgrade guide for generated-code ownership.
- **D-15:** Docs copy should stay calm, precise, and host-app-evidence-based. Avoid marketing claims not proven by the dogfood harness.

### Path Dependency And Hex Validation

- **D-16:** Keep a single canonical checked-in host app at `examples/accrue_host`. Do not create dual committed example apps for path and Hex modes.
- **D-17:** Add a dependency-mode switch for the host app: path dependencies by default for monorepo dogfood, Hex-style dependencies via an explicit env flag or script mode.
- **D-18:** Hex validation should be a focused smoke, not the full Phase 13 demo path: `mix deps.get`, rerun `mix accrue.install`, compile, migrate, and run a narrow host proof suite.
- **D-19:** Keep the existing path-mode host UAT as the primary PR/release gate. Add Hex-mode validation as a package correctness check that proves install snippets and published package metadata work.
- **D-20:** Treat package versions, source refs, and HexDocs links as checked invariants. A repo script should parse package `mix.exs` values and assert README install snippets, `docs.source_ref` tag shapes, relative ExDoc links, and package guide links are correct.

### Public API Clarity

- **D-21:** Elevate the host-first API boundary as the public integration story: generated `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `AccrueAdmin.Router.accrue_admin/2`, `Accrue.Auth`, and setup errors through `Accrue.ConfigError`.
- **D-22:** Do not teach first users to depend on private/internal tables or modules such as `Accrue.Billing.Customer`, `Accrue.Billing.Subscription`, `Accrue.Webhook.WebhookEvent`, `Accrue.Events.Event`, direct Fake GenServer functions, worker internals, or package repo cleanup patterns.
- **D-23:** Add host-facing read helpers to the generated facade if needed so example UI/tests can inspect billing state without direct schema/repo coupling.
- **D-24:** Webhook examples should stay at the generated handler boundary (`MyApp.BillingHandler.handle_event/3` or equivalent) and not require reducer or dispatch-worker internals.
- **D-25:** `Accrue.ConfigError` is the setup/runtime misconfiguration contract, not everyday control flow. Docs should show how to fix it, not pattern-match on it for normal business behavior.

### Coherent Recommendation

- **D-26:** The phase should optimize for principle of least surprise: generated code is host-owned; reruns are safe; failures name the fix; docs mirror the real host path; package validation proves both monorepo and published modes; public APIs remain small and Phoenix-context-shaped.

### the agent's Discretion

- Exact module names for the diagnostic formatter/checker.
- Exact `.accrue/conflicts/` file naming scheme, as long as artifacts are outside compile/config paths and include target path/reason.
- Whether the preflight surface is `mix accrue.install --check`, `mix accrue.doctor`, or both, as long as installer and runtime diagnostics share one taxonomy.
- Exact guide names and ExDoc sidebar grouping, as long as the split docs shape and stable anchors are preserved.
- Exact narrow Hex-mode proof suite, as long as it covers installer rerun, compile, migrations, and one host-facing billing/webhook/admin proof.

### Deferred Ideas (OUT OF SCOPE)

- Maintained public demo/tutorial packaging, screenshots, README positioning as adoption assets - Phase 13.
- Security/audit pass for webhook/auth/admin boundaries - Phase 14.
- Performance, accessibility, responsive-browser, and compatibility matrices - Phase 14.
- Hosted public demo environment - future requirement `HOST-09`, not Phase 12.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DX-01 | Installer output and generated files are validated against the host app and remain idempotent on rerun. | Installer result contract, fingerprint behavior, rerun UAT expansion, conflict artifact design. [VERIFIED: codebase grep] |
| DX-02 | Setup failures for missing config, migrations, Oban, webhook secrets, auth, and admin mounts produce actionable errors. | Shared diagnostic taxonomy, boot/preflight checks, runtime redaction policy, troubleshooting anchors. [VERIFIED: codebase grep] |
| DX-03 | Quickstart docs are updated from the host-app path and avoid hand-wavy or skipped setup steps. | First Hour guide structure anchored to `examples/accrue_host`. [VERIFIED: codebase grep] |
| DX-04 | Troubleshooting docs cover the most likely first-hour failures discovered by dogfooding. | Symptom/code/fix/verify troubleshooting matrix sourced from host failures and installer/runtime checks. [VERIFIED: codebase grep] |
| DX-05 | Public APIs used by the host app are documented and avoid requiring private module knowledge. | Host-first API boundary, generated facade/read helper guidance, webhook handler boundary, `Accrue.Test` preference. [VERIFIED: codebase grep] |
| DX-06 | Package version snippets, source links, and HexDocs guide links remain correct for both packages. | Metadata verification script, ExDoc `source_ref`, README/guide drift checks, Hex dry-run usage. [VERIFIED: codebase grep] |
| DX-07 | Host-app setup supports both path-dependency development and Hex-style dependency validation. | Single host app with env-switched deps plus focused Hex smoke in CI/release validation. [VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Accrue is locked to Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, and PostgreSQL 14+. [VERIFIED: CLAUDE.md]
- `lattice_stripe`, `oban`, `swoosh`, `ecto_sql`, `postgrex`, `nimble_options`, `telemetry`, and `chromic_pdf` are required project dependencies. [VERIFIED: CLAUDE.md]
- `sigra` is optional and `phoenix_live_view` is required only in `accrue_admin`, not in core `accrue`. [VERIFIED: CLAUDE.md]
- Webhook signature verification is mandatory, raw-body capture must happen before `Plug.Parsers`, sensitive Stripe fields must not be logged, and payment method details must stay as references rather than PII. [VERIFIED: CLAUDE.md]
- Public entry points must emit telemetry and OTel helpers must remain available for billing context functions. [VERIFIED: CLAUDE.md]
- The repo is a monorepo with sibling `accrue/` and `accrue_admin/` Mix projects, shared guides/workflows, and per-package release metadata. [VERIFIED: CLAUDE.md]
- Phase 12 research must not recommend approaches that move host-owned concerns into the library supervision tree or contradict the host-owned integration model. [VERIFIED: CLAUDE.md]

## Summary

Phase 12 should be planned as one stabilization slice across five surfaces that already exist in the repo: installer primitives, boot/runtime error surfaces, package/docs metadata, the canonical host app, and the CI/release proof scripts. `Accrue.Install.Fingerprints` already enforces the core host-ownership rule by updating pristine generated files, skipping user-edited stamped files, and only overwriting unmarked files under `--force`; the missing work is the richer outcome taxonomy, real `--write-conflicts` artifacts, and broader host-app proof coverage. [VERIFIED: codebase grep]

The strongest planning move is to centralize setup diagnostics before touching docs. The repo already has multiple partial failure surfaces: `Accrue.ConfigError`, `Accrue.Auth.Default.boot_check!/0`, `Accrue.Repo.repo/0`, `Accrue.Webhook.Plug`, installer readiness output, and host-app UAT expectations. A shared diagnostic contract lets the planner sequence one implementation for stable codes, redaction, docs anchors, and preflight/boot reuse instead of scattering custom strings across installer, boot, and HTTP paths. [VERIFIED: codebase grep]

Docs and validation drift are real today. `accrue/README.md` advertises `~> 0.1.2`, but `accrue/guides/quickstart.md` still says `~> 1.0.0` and uses `webhook_signing_secret` instead of the current `webhook_signing_secrets` config shape; `accrue_admin/guides/admin_ui.md` also still says published releases depend on `accrue ~> 1.0.0`. The planner should treat metadata verification as code, not editorial cleanup, and wire it into CI plus publish dry-runs. [VERIFIED: codebase grep]

**Primary recommendation:** Implement Phase 12 in this order: shared setup-diagnostic contract, installer conflict/output contract, docs rewrite from `examples/accrue_host`, host path/Hex dependency-mode switch, then metadata drift automation. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Installer rerun safety | Mix task / code generator | Host filesystem | `mix accrue.install` owns stamping, skip/overwrite policy, and conflict artifact emission against host-owned files. [VERIFIED: codebase grep] |
| Setup diagnostics | Library runtime (`accrue`) | Mix task / host app | Boot/preflight checks belong in library/runtime code, while installer surfaces and host docs consume the same structured diagnostics. [VERIFIED: codebase grep] |
| Webhook wiring validation | Host router / Plug pipeline | Library webhook plug | Route placement and raw-body reader scope are host concerns; signature verification and ingest remain library-owned. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
| Admin mount/auth validation | Host router/auth adapter | `accrue_admin` router macro | The host owns session/auth boundary while `accrue_admin/2` provides the mount macro. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |
| Dependency-mode switching | Host Mix project | CI/release scripts | `examples/accrue_host/mix.exs` is the right place to switch path vs Hex deps, with scripts/workflows selecting the mode. [VERIFIED: codebase grep] |
| Package metadata correctness | Package `mix.exs` + docs | CI/publish workflows | `source_ref`, extras, README snippets, and Hex dry-runs are package/release concerns, not runtime concerns. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | 1.8.5 | Host-app routing, generated auth conventions, router mounts | The repo already locks onto Phoenix 1.8 semantics in `mix.exs`/`mix.lock`, and Phoenix generators explicitly treat generated code as host-owned after generation. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |
| Plug | 1.19.1 | Scoped raw-body capture before webhook parsing | `Plug.Parsers` officially supports `:body_reader`, which is exactly the supported way to preserve raw bytes before parsing. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
| Oban | 2.21.1 | Host-supervised async jobs and queue config validation | The repo already uses Oban in tests and the host app; official docs keep Oban as a separately supervised instance with explicit config and migrations. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/oban/2.17.0/installation.html] |
| ExDoc | 0.40.1 | Guide extras, source links, grouped docs | The repo already uses ExDoc in both packages, and ExDoc explicitly supports `source_ref`, extras, and grouped extras for version-correct docs. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Hex CLI | 2.2.1 docs surface | Package dry-run validation and publish checks | `mix hex.build` and `mix hex.publish --dry-run` are the official verification path for package contents and publish-time metadata. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit | bundled with Elixir 1.19.5 locally | Narrow proof files for installer/docs/host boundary regressions | Use for fast unit/proof coverage around diagnostics, docs drift, and rerun semantics. [VERIFIED: local environment][VERIFIED: codebase grep] |
| Playwright | 1.59.1 local CLI | Preserve the existing host browser smoke as a downstream regression guard | Use only for host-browser smoke already wired in CI; Phase 12 itself is not a browser-first phase. [VERIFIED: local environment][VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `mix accrue.install --check` reusing installer plumbing | `mix accrue.doctor` as a separate task | A separate doctor task may read better, but it duplicates discoverability and risks a second diagnostic taxonomy unless it wraps the same service layer. [VERIFIED: CONTEXT.md] |
| One env-switched host app | Two checked-in host apps | Two apps would duplicate docs, drift faster, and violate the locked decision to keep one canonical host app. [VERIFIED: CONTEXT.md] |
| Metadata verification script plus CI | Manual README/guide review before release | Manual review will miss drift already visible between README, quickstart, and admin guide versions. [VERIFIED: codebase grep] |

**Installation:**
```bash
cd accrue && mix deps.get
cd ../accrue_admin && mix deps.get
cd ../examples/accrue_host && mix deps.get
```

**Version verification:** Phoenix 1.8.5, Plug 1.19.1, Oban 2.21.1, and ExDoc 0.40.1 are all locked in local `mix.lock` files. [VERIFIED: mix.lock] Published package versions are `accrue` 0.1.2 and `accrue_admin` 0.1.2 as of 2026-04-16 via the Hex.pm API. [VERIFIED: hex.pm API]

## Architecture Patterns

### System Architecture Diagram

```text
Phoenix host developer input
        |
        v
mix accrue.install / --check
        |
        +--> Accrue.Install.Fingerprints ----> generated file write/skip/conflict artifact
        |
        +--> Accrue.Install.Patches ---------> router/auth/test-support/manual patch results
        |
        +--> shared SetupDiagnostic service --> code + summary + fix + docs anchor
                                               |                 |
                                               |                 +--> troubleshooting / first-hour guide anchors
                                               v
                                      runtime checks
                                               |
                         +---------------------+----------------------+
                         |                                            |
                         v                                            v
               Accrue.Application boot                     Accrue.Webhook.Plug / admin mount checks
                         |                                            |
                         +---------------------+----------------------+
                                               |
                                               v
                                  host-app validation scripts
                                               |
                         +---------------------+----------------------+
                         |                                            |
                         v                                            v
                    path-mode UAT                               Hex-mode smoke + publish dry-run
```

### Recommended Project Structure

```text
accrue/lib/accrue/install/      # installer result types, conflict artifacts, shared check orchestration
accrue/lib/accrue/              # setup-diagnostic structs/helpers and boot/runtime checks
accrue/guides/                  # First Hour guide + troubleshooting matrix + focused topic guides
examples/accrue_host/           # single canonical host app with env-switched dependency mode
scripts/ci/                     # path-mode UAT + focused Hex-mode smoke + metadata verification
```

### Pattern 1: Shared Setup-Diagnostic Taxonomy
**What:** Introduce one structured diagnostic payload, then adapt it for installer output, raised exceptions, and docs links. [VERIFIED: codebase grep]
**When to use:** Any first-hour failure that the developer can fix locally: missing repo, missing migrations, Oban not started, missing webhook secret, bad auth adapter, route/raw-body/admin wiring. [VERIFIED: CONTEXT.md]
**Example:**
```elixir
# Source: repo pattern + official ExDoc/Plug/Oban docs
defmodule Accrue.SetupDiagnostic do
  @enforce_keys [:code, :summary, :fix, :docs_path]
  defstruct [:code, :summary, :fix, :docs_path, :details]
end
```

### Pattern 2: No-Clobber Generated File Contract
**What:** Keep generated host files stamped and fingerprinted; only pristine stamped files may be updated automatically. [VERIFIED: codebase grep]
**When to use:** Any installer-managed file under `lib/`, `config/`, or `test/support/`. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: /accrue/lib/accrue/install/fingerprints.ex
cond do
  pristine?(path) -> {:changed, "updated pristine"}
  user_edited?(path) -> {:skipped, "user-edited"}
  Keyword.get(opts, :force, false) -> {:changed, "overwrote unmarked"}
  true -> {:skipped, "exists"}
end
```

### Pattern 3: Host-First Documentation Flow
**What:** The docs should mirror `examples/accrue_host` in execution order and point readers at host-owned generated boundaries instead of internal library modules. [VERIFIED: codebase grep]
**When to use:** README, First Hour guide, troubleshooting matrix, and public API sections. [VERIFIED: CONTEXT.md]
**Example:**
```text
deps -> mix accrue.install -> runtime.exs -> ecto.migrate -> Oban supervision
-> webhook route/raw body -> auth/admin mount -> first Fake subscription
-> signed webhook proof -> admin inspection -> focused tests
```

### Pattern 4: Dependency-Mode Switch, Not Duplicate Example Apps
**What:** Reuse the `accrue_admin` env-gated dependency pattern in the host app so one app can resolve path deps by default and Hex deps during smoke validation. [VERIFIED: codebase grep]
**When to use:** `examples/accrue_host/mix.exs` plus CI/release scripts. [VERIFIED: CONTEXT.md]
**Example:**
```elixir
defp accrue_dep do
  if System.get_env("ACCRUE_HOST_HEX_RELEASE") == "1" do
    {:accrue, "~> 0.1.2"}
  else
    {:accrue, path: "../../accrue"}
  end
end
```

### Anti-Patterns to Avoid

- **Stringly scattered diagnostics:** Do not add new one-off error strings in installer, boot, and docs independently; that prevents stable codes and doc anchors. [VERIFIED: codebase grep]
- **Adjacent conflict files in live code paths:** Do not emit `.conflict.ex` or similar beside live source files; those paths are easy to compile, format, or commit accidentally. [VERIFIED: CONTEXT.md]
- **Private-module teaching in docs:** Do not make first users learn internal schemas, event rows, worker internals, or Fake GenServer calls. [VERIFIED: CONTEXT.md]
- **Dual example app strategy:** Do not split path-mode and Hex-mode into separate checked-in host apps. [VERIFIED: CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Raw-body preservation | Custom request buffering layer | `Plug.Parsers` with `:body_reader` | This is the official extension point and keeps webhook scoping explicit. [CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
| Queue lifecycle / supervision checks | Custom background-job runtime | Oban config + host supervision | Oban is already present and officially expects host config plus supervisor wiring. [CITED: https://hexdocs.pm/oban/2.17.0/installation.html] |
| Version-correct source links | Hand-built GitHub URLs in docs | ExDoc `source_url` + `source_ref` | ExDoc already generates version-specific source links when both are configured. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Package contents validation | Ad hoc tarball inspection | `mix hex.build --unpack` and `mix hex.publish --dry-run` | Hex already provides official local package/publish verification. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Auth ownership messaging | Custom philosophy docs divorced from Phoenix practice | Phoenix generated-auth precedent | Phoenix explicitly says generated auth code is in-app and becomes the app's responsibility after generation. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |

**Key insight:** The phase is mostly about tightening contracts around existing standards, not inventing new infrastructure. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Summary Counts Hide The Real Rerun Outcome
**What goes wrong:** The installer currently reports only coarse `changed`, `skipped`, and `manual` totals, which is too weak for CI or first-user reruns. [VERIFIED: codebase grep]
**Why it happens:** `Mix.Tasks.Accrue.Install.print_summary/3` collapses richer `Fingerprints.write/3` reasons into simple counts. [VERIFIED: codebase grep]
**How to avoid:** Carry normalized outcome atoms all the way through templates and patches, then summarize by `created`, `updated_pristine`, `skipped_user_edited`, `skipped_exists`, `manual`, and `conflict_artifact`. [VERIFIED: CONTEXT.md]
**Warning signs:** CI reports generic drift after rerunning the installer but cannot say whether it was safe drift, user edits, or manual patch work. [VERIFIED: codebase grep]

### Pitfall 2: Docs Drift Faster Than Code
**What goes wrong:** The repo already has version/config drift between README, quickstart, and admin docs. [VERIFIED: codebase grep]
**Why it happens:** The current docs are not derived from package metadata and do not have a dedicated metadata drift test. [VERIFIED: codebase grep]
**How to avoid:** Add one script/test that parses package versions and docs config from `mix.exs` and verifies snippets, `source_ref`, guide links, and expected relative paths. [VERIFIED: CONTEXT.md]
**Warning signs:** `README.md` says `0.1.2` while guides still say `1.0.0`, or guides use config keys no longer present in code. [VERIFIED: codebase grep]

### Pitfall 3: Boot Checks And Troubleshooting Pages Diverge
**What goes wrong:** Developers see one runtime error message, one installer warning, and a differently worded guide entry for the same setup problem. [VERIFIED: codebase grep]
**Why it happens:** Existing checks are spread across `Accrue.Config`, `Accrue.Auth.Default`, `Accrue.Repo`, and webhook code without a shared presentation layer. [VERIFIED: codebase grep]
**How to avoid:** Put stable diagnostic codes and docs anchors in one service and make each surface render from it. [VERIFIED: CONTEXT.md]
**Warning signs:** Same root cause appears in docs and code with different names, or docs anchors change without code updates. [VERIFIED: codebase grep]

### Pitfall 4: Hex Validation Expands Into A Second Full CI Pipeline
**What goes wrong:** The planner may accidentally duplicate the entire path-mode host UAT for Hex mode. [VERIFIED: CONTEXT.md]
**Why it happens:** Hex-mode support sounds broader than it is, but the locked scope only requires install/package correctness smoke. [VERIFIED: CONTEXT.md]
**How to avoid:** Keep Hex mode to `deps.get`, installer rerun, compile, migrate, and one narrow host proof suite. [VERIFIED: CONTEXT.md]
**Warning signs:** Proposed plan adds Playwright/browser duplication or a second committed example app. [VERIFIED: CONTEXT.md]

## Code Examples

Verified patterns from official sources and the repo:

### Scoped Raw Body Reader For Webhooks
```elixir
# Source: https://hexdocs.pm/plug/Plug.Parsers.html + examples/accrue_host/lib/accrue_host_web/router.ex
pipeline :accrue_webhook_raw_body do
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
    length: 1_000_000
end
```

### Host-Supervised Oban Wiring
```elixir
# Source: https://hexdocs.pm/oban/2.17.0/installation.html
config :my_app, Oban,
  repo: MyApp.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 10]

children = [
  MyApp.Repo,
  {Oban, Application.fetch_env!(:my_app, Oban)}
]
```

### ExDoc Version-Specific Source Links
```elixir
# Source: https://hexdocs.pm/ex_doc/ExDoc.html + accrue/mix.exs
docs: [
  main: "readme",
  source_ref: "accrue-v#{@version}",
  extras: ["README.md" | Path.wildcard("guides/*.md")]
]
```

### Host-Owned Generated Auth Precedent
```text
Phoenix says generated auth code lives in your application and becomes your responsibility to modify and maintain after generation.
```
[CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic quickstart plus implied host setup | Host-derived First Hour guide plus symptom/code troubleshooting | Phase 12 target, planned 2026-04-16 | Lowers first-hour ambiguity and gives diagnostics a canonical docs home. [VERIFIED: CONTEXT.md] |
| Path-only host app assumptions | One host app with explicit path/Hex mode switch | Phase 12 target, planned 2026-04-16 | Keeps monorepo dogfood while proving published package correctness. [VERIFIED: CONTEXT.md] |
| Coarse installer summary | Typed install outcome contract with conflict artifacts | Phase 12 target, planned 2026-04-16 | Makes reruns diagnosable and CI-safe. [VERIFIED: CONTEXT.md] |
| Manual package docs review | Automated snippet/source_ref/link verification plus Hex dry-run | Phase 12 target, planned 2026-04-16 | Prevents already-visible metadata drift. [VERIFIED: CONTEXT.md][CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |

**Deprecated/outdated:**
- `accrue/guides/quickstart.md` using `{:accrue, "~> 1.0.0"}` is outdated relative to current published package version `0.1.2`. [VERIFIED: codebase grep][VERIFIED: hex.pm API]
- `accrue/guides/quickstart.md` uses `webhook_signing_secret` while current config and tests use `webhook_signing_secrets`. [VERIFIED: codebase grep]
- `accrue_admin/guides/admin_ui.md` stating published releases depend on `accrue ~> 1.0.0` is outdated relative to current published package version `0.1.2`. [VERIFIED: codebase grep][VERIFIED: hex.pm API]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All claims in this research were verified or cited — no user confirmation needed.

## Open Questions

1. **Should the user-facing preflight command be `mix accrue.install --check`, `mix accrue.doctor`, or both?**
   - What we know: The locked decision allows any entrypoint as long as installer and runtime diagnostics share one taxonomy. [VERIFIED: CONTEXT.md]
   - What's unclear: Which command shape will be easiest for first users to discover without duplicating implementation. [VERIFIED: CONTEXT.md]
   - Recommendation: Implement one shared diagnostic service first, then expose `--check`; add a `mix accrue.doctor` alias only if docs/readability still feel weak. [VERIFIED: codebase grep]

2. **Does the generated host billing facade need new read helpers in this phase?**
   - What we know: Current generated `AccrueHost.Billing` only exposes `subscribe`, `swap_plan`, `cancel`, and `customer_for`, while the context allows adding host-facing read helpers if example UI/tests still reach into private schemas. [VERIFIED: codebase grep][VERIFIED: CONTEXT.md]
   - What's unclear: Whether planned docs/examples can stay entirely on current public helpers once rewritten. [VERIFIED: codebase grep]
   - Recommendation: Audit Phase 12 docs/examples first; add only the smallest read helpers needed to remove private schema teaching. [VERIFIED: CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | package tests, Mix tasks, docs | ✓ | 1.19.5 | — |
| Erlang/OTP | Elixir runtime | ✓ | 28 / erts-16.3 | — |
| Node.js | host browser smoke and npm scripts | ✓ | 22.14.0 | — |
| npm | host browser smoke | ✓ | 11.1.0 | — |
| PostgreSQL client/server | host UAT, migrations, Oban-backed proofs | ✓ | 14.17 client, local server accepting connections | — |
| Playwright CLI | host browser smoke | ✓ | 1.59.1 | — |
| Chrome/Chromium binary | ChromicPDF or direct browser binary assumptions | ✗ | — | Use Playwright-managed Chromium in host/browser scripts; keep PDF tests on `Accrue.PDF.Test`. |

**Missing dependencies with no fallback:**
- None for planning/research. [VERIFIED: local environment]

**Missing dependencies with fallback:**
- No system Chrome/Chromium binary was found locally, but Playwright is available and current tests already avoid requiring Chrome for PDF coverage by using `Accrue.PDF.Test`. [VERIFIED: local environment][VERIFIED: codebase grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 local runtime, with Oban test mode and Phoenix host proofs. [VERIFIED: local environment][VERIFIED: codebase grep] |
| Config file | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `examples/accrue_host/test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/install_boundary_test.exs test/accrue_host_web/webhook_ingest_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `bash scripts/ci/accrue_host_uat.sh` plus `cd accrue && mix test.all` and `cd accrue_admin && mix test --warnings-as-errors` for package-level drift. [VERIFIED: codebase grep] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DX-01 | Installer rerun stays idempotent and preserves host ownership | unit + host proof | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs` | ✅ |
| DX-02 | Setup failures produce actionable diagnostics | unit + host proof | `cd accrue && mix test test/accrue/auth_test.exs test/accrue/config_test.exs test/accrue/webhook/plug_test.exs` | ✅ partial |
| DX-03 | First Hour docs follow host setup path | docs test | `cd accrue && mix test test/accrue/docs/*.exs` | ✅ partial |
| DX-04 | Troubleshooting docs map symptom/code/fix/verify | docs test | `cd accrue && mix test test/accrue/docs/*.exs` | ❌ Wave 0 |
| DX-05 | Public host-facing API is the documented boundary | host proof | `cd examples/accrue_host && MIX_ENV=test mix test test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs` | ✅ |
| DX-06 | Version snippets, source links, and guide links stay correct | script + docs test | `bash scripts/ci/verify_package_docs.sh` | ❌ Wave 0 |
| DX-07 | Host app passes path mode and Hex mode smoke | integration | `bash scripts/ci/accrue_host_uat.sh` and `bash scripts/ci/accrue_host_hex_smoke.sh` | path ✅ / Hex ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/install_boundary_test.exs test/accrue_host_web/webhook_ingest_test.exs` [VERIFIED: codebase grep]
- **Per wave merge:** `bash scripts/ci/accrue_host_uat.sh` [VERIFIED: codebase grep]
- **Phase gate:** Full suite green, metadata verifier green, and Hex smoke green before `/gsd-verify-work`. [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] `accrue/test/accrue/docs/first_hour_guide_test.exs` — asserts the host-path order, public API mentions, and no private-module teaching for DX-03/DX-05. [VERIFIED: codebase grep]
- [ ] `accrue/test/accrue/docs/troubleshooting_guide_test.exs` — asserts stable diagnostic code anchors, columns, and symptom coverage for DX-04. [VERIFIED: codebase grep]
- [ ] `scripts/ci/verify_package_docs.sh` with a corresponding test — verifies package versions, `source_ref`, README snippets, and guide links for DX-06. [VERIFIED: codebase grep]
- [ ] `scripts/ci/accrue_host_hex_smoke.sh` — switches the host app to Hex deps and runs the narrow smoke for DX-07. [VERIFIED: CONTEXT.md]
- [ ] Expand installer tests for real `--write-conflicts` artifacts and categorized summaries; current tests prove idempotence and redaction but not the locked conflict-artifact contract. [VERIFIED: codebase grep][VERIFIED: CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep host-owned auth boundary; production default auth adapter must fail closed via `Accrue.Auth.Default.boot_check!/0`. [VERIFIED: codebase grep] |
| V3 Session Management | yes | Admin mount continues to depend on host session keys and host router/session setup, not package-owned session logic. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Preserve admin mount protection at the host router boundary and avoid documenting private bypasses. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Use structured diagnostics and existing config validation rather than string parsing; keep installer/runtime validation centralized. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | Never hand-roll webhook signature logic; keep Stripe signature verification and raw-body preservation on existing library paths. [VERIFIED: CLAUDE.md][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret leakage in installer/runtime messages | Information Disclosure | Reuse existing redaction rules for `sk_*`, `whsec_*`, and env-var assignments; diagnostics should name keys, not values. [VERIFIED: codebase grep][VERIFIED: CONTEXT.md] |
| Mis-scoped webhook parser lets signatures fail or be bypassed | Tampering | Keep raw-body reader on webhook-only pipeline before parsing; do not move it into global browser/api pipelines. [VERIFIED: codebase grep][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
| Dev-permissive auth reaches production | Elevation of Privilege | Preserve `Accrue.Auth.Default.boot_check!/0` fail-closed behavior and make docs/tests keep that path explicit. [VERIFIED: codebase grep] |
| Docs teach internal modules as stable APIs | Security Misconfiguration | Keep public docs at host facade/router/test boundaries only. [VERIFIED: CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `CLAUDE.md` - project constraints, dependency and security rules checked locally. [VERIFIED: CLAUDE.md]
- `.planning/phases/12-first-user-dx-stabilization/12-CONTEXT.md` - locked decisions, discretion, and deferred scope. [VERIFIED: codebase grep]
- `accrue/lib/accrue/install/fingerprints.ex` - current stamped-file contract. [VERIFIED: codebase grep]
- `accrue/lib/mix/tasks/accrue.install.ex` - current installer output and summary behavior. [VERIFIED: codebase grep]
- `accrue/lib/accrue/install/patches.ex` - current patch/manual behavior and missing conflict artifacts. [VERIFIED: codebase grep]
- `accrue/lib/accrue/errors.ex`, `accrue/lib/accrue/config.ex`, `accrue/lib/accrue/repo.ex`, `accrue/lib/accrue/auth/default.ex`, `accrue/lib/accrue/webhook/plug.ex`, `accrue/lib/accrue/application.ex` - setup/runtime failure surfaces. [VERIFIED: codebase grep]
- `examples/accrue_host/mix.exs`, `examples/accrue_host/README.md`, `scripts/ci/accrue_host_uat.sh`, `.github/workflows/ci.yml` - host validation and CI gate shape. [VERIFIED: codebase grep]
- `accrue/mix.exs`, `accrue_admin/mix.exs`, `accrue/README.md`, `accrue/guides/quickstart.md`, `accrue_admin/guides/admin_ui.md`, `accrue_admin/README.md` - package metadata and docs drift. [VERIFIED: codebase grep]
- Hex.pm API: `https://hex.pm/api/packages/accrue`, `https://hex.pm/api/packages/accrue_admin` - latest published package versions and update timestamps. [VERIFIED: hex.pm API]
- https://hexdocs.pm/phoenix/mix_phx_gen_auth.html - generated auth code ownership and router/auth conventions. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html]
- https://hexdocs.pm/plug/Plug.Parsers.html - `:body_reader` support and parser scoping. [CITED: https://hexdocs.pm/plug/Plug.Parsers.html]
- https://hexdocs.pm/oban/2.17.0/installation.html - Oban migration/config/supervision guidance. [CITED: https://hexdocs.pm/oban/2.17.0/installation.html]
- https://hexdocs.pm/ex_doc/ExDoc.html - `source_ref`, extras, and group guidance. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
- https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html - local package build verification. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html]
- https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html - dry-run publish checks and docs publishing behavior. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

### Secondary (MEDIUM confidence)

- `https://hex.pm/packages/accrue_admin` - package page confirms `accrue_admin` 0.1.2 on Hex UI and update date. [CITED: https://hex.pm/packages/accrue_admin]

### Tertiary (LOW confidence)

- None. [VERIFIED: research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended components are either already in the repo or documented in official Phoenix/Plug/Oban/ExDoc/Hex sources. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/plug/Plug.Parsers.html]
- Architecture: HIGH - the phase scope is tightly constrained by local code and locked decisions, with no major library-selection uncertainty left. [VERIFIED: CONTEXT.md][VERIFIED: codebase grep]
- Pitfalls: HIGH - multiple active drifts and current failure surfaces are directly visible in the repo. [VERIFIED: codebase grep]

**Research date:** 2026-04-16
**Valid until:** 2026-05-16 for planning structure; recheck Hex package versions and docs pages earlier if releases land.
