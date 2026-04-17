# Phase 13: Canonical Demo + Tutorial - Research

**Researched:** 2026-04-16
**Domain:** Phoenix host-demo packaging, tutorial drift control, and local verification contract
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Use a hybrid entry architecture with strict ownership: `examples/accrue_host/README.md` is the canonical clone-to-running executable path; `accrue/guides/first_hour.md` is the package-facing tutorial mirror; `scripts/ci/accrue_host_uat.sh` is the CI-equivalent verifier; the root README should only orient and link until Phase 14 expands the adoption front door.
- **D-02:** Do not make the UAT script the first teaching surface. New evaluators should see the Phoenix-order setup steps before being pointed to the full verification command.
- **D-03:** Keep Fake/test/live Stripe positioning visible in the demo docs, but the canonical local demo path must remain Fake-backed and require no live Stripe credentials.

- **D-04:** Use two named demo modes: a public-boundary `First run` path and an explicit `Seeded history` evaluation path.
- **D-05:** `First run` is the canonical tutorial story: create a Fake-backed subscription through the host UI/generated facade, post one signed webhook through the real endpoint, then inspect billing state in the mounted admin UI.
- **D-06:** `Seeded history` is allowed for deterministic admin replay/history/browser coverage where the desired state is awkward to create in a short walkthrough, such as a failed/dead webhook ready for replay.
- **D-07:** Seed scripts may use private setup only for evaluation states that users should not imitate. Subscription creation and signed webhook ingest must go through public host boundaries in the tutorial and focused proofs.
- **D-08:** Keep cancellation out of the main tutorial body unless needed as a secondary proof. It can remain in focused tests/browser smoke, but it should not distract from the first subscription, webhook, and admin inspection story.

- **D-09:** Adopt a `fast + full` verification contract, implemented primarily as package-local Mix aliases in `examples/accrue_host`.
- **D-10:** `cd examples/accrue_host && mix setup` should be the clone-to-ready command for local evaluators.
- **D-11:** Add or preserve a focused `mix verify` alias for the tutorial proof suite: installer boundary, billing facade/subscription flow, signed webhook ingest, admin mount/replay, and other short deterministic host proofs.
- **D-12:** Add or preserve `mix verify.full` as the CI-equivalent local gate that composes the core proof suite plus compile, asset build, dev boot, and browser smoke.
- **D-13:** Keep `bash scripts/ci/accrue_host_uat.sh` as a thin repo-root/GitHub Actions wrapper around the same contract. Do not introduce `make`, `just`, or a sprawl of public split-by-concern commands for this phase.

- **D-14:** Use a small shared command manifest as the source for canonical ordered command steps and mode labels across host README, First Hour guide, and UAT verification.
- **D-15:** Keep docs human-written. Do not generate large Markdown tutorial sections or adopt Livebook/literate executable docs for this shell-and-Phoenix setup path.
- **D-16:** Expand ExUnit documentation contract tests to verify command order, public API boundary mentions, forbidden private surfaces, and parity between the manifest, `examples/accrue_host/README.md`, `accrue/guides/first_hour.md`, and `scripts/ci/accrue_host_uat.sh`.
- **D-17:** Keep shell/grep-style checks only for narrow fixed invariants such as package versions, links, and required anchors; do not rely on shell grep as the main tutorial drift guard.

- **D-18:** The phase should optimize for least surprise in the Phoenix ecosystem: explicit app-local Mix commands, host-owned generated boundaries, Fake-first deterministic local evaluation, human-written ExDoc/README prose, and CI parity available after the user understands the path.

### Claude's Discretion

- Exact name, file format, and location of the shared command manifest.
- Exact implementation shape of `mix verify` and `mix verify.full`, provided the aliases are package-local, documented, and either compose or stay in parity with the root UAT wrapper.
- Exact wording of README/guide labels for `First run` and `Seeded history`.
- Exact ExUnit helper/module names for command-manifest and docs parity checks.

### Deferred Ideas (OUT OF SCOPE)

- Root README as the primary public adoption front door belongs to Phase 14.
- Hosted public demo remains out of scope for v1.2 unless a later milestone explicitly adds it.
- Live Stripe tutorial/demo flow remains advisory or later-phase material; Phase 13 canonical path is Fake-backed.
</user_constraints>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEMO-01 | User can clone the repository and run `examples/accrue_host` as the canonical local demo with documented prerequisites and commands. | Recommend `mix setup` as the canonical clone-to-ready entrypoint, with README/guide parity enforced by manifest-backed ExUnit tests. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix/up_and_running.html] [CITED: https://hexdocs.pm/mix/1.18.1/Mix.html] |
| DEMO-02 | User can seed or create a Fake-backed subscription in the demo without live Stripe credentials. | Existing facade and flow tests already prove Fake-backed subscribe paths; plan should keep `First run` on public boundaries and confine seeding to `Seeded history`. [VERIFIED: codebase grep] |
| DEMO-03 | User can inspect billing state and replay a webhook/admin action through the mounted admin UI in the demo. | Existing admin mount, replay, and seeded browser coverage provide the proof surface; docs need to frame them as inspection/replay steps, not internal setup. [VERIFIED: codebase grep] |
| DEMO-04 | User can run a single CI-equivalent local command that verifies the demo setup and focused host proofs. | Recommend package-local `mix verify.full` plus a thin root wrapper; current root wrapper is broad but presently fails local dev boot smoke and must be reconciled in planning. [VERIFIED: scripts/ci/accrue_host_uat.sh + local run] |
| DEMO-05 | User can understand which demo commands are for local evaluation, CI validation, Hex-style smoke validation, and production setup. | Recommend explicit command modes in one shared manifest and docs parity tests that assert labels and ordering across README, First Hour, and wrapper references. [VERIFIED: codebase grep] |
| DEMO-06 | Maintainer can detect drift between the demo path and documented tutorial commands before release. | Existing docs verifier and first-hour guide tests provide a base; phase should add manifest-backed parity checks for ordered commands and forbidden/private-surface mentions. [VERIFIED: codebase grep] |
| ADOPT-02 | User can follow a tutorial from install through first subscription, signed webhook ingest, admin inspection/replay, and focused host tests. | Existing host flow, webhook ingest, admin mount/replay, and First Hour docs establish the story pieces; phase should reorder and relabel them into one canonical narrative. [VERIFIED: codebase grep] |

## Project Constraints (from CLAUDE.md)

- The repo baseline is Elixir `1.17+`, OTP `27+`, Phoenix `1.8+`, Ecto `3.12+`, and PostgreSQL `14+`. [VERIFIED: CLAUDE.md]
- Required platform dependencies include `lattice_stripe`, `oban`, `swoosh`, `ecto_sql`, `postgrex`, `nimble_options`, `telemetry`, and `chromic_pdf`; optional deps include `sigra` and `phoenix_live_view` outside core. [VERIFIED: CLAUDE.md]
- Webhook signature verification is mandatory, raw-body capture must happen before `Plug.Parsers`, sensitive Stripe fields must not be logged, and payment method data must remain stored as processor references instead of PII. [VERIFIED: CLAUDE.md]
- All public entry points are expected to emit telemetry, and the monorepo structure keeps `accrue/` and `accrue_admin/` as sibling Mix packages with shared workflows and guides. [VERIFIED: CLAUDE.md]
- Work in this repo should go through a GSD workflow instead of ad hoc file edits. [VERIFIED: CLAUDE.md]

## Summary

The repo already contains nearly all of the behavioral proof surfaces Phase 13 needs: the host example has a checked-in Phoenix app, Fake-backed subscription facade tests, signed webhook ingest tests, admin mount and replay tests, a seeded browser smoke flow, a package-facing First Hour guide, and package docs contract tests. Those focused proofs passed locally during research. [VERIFIED: codebase grep] [VERIFIED: local test run]

The main planning work is contract consolidation, not greenfield implementation. The current docs still teach a low-level command list in `examples/accrue_host/README.md`, while the repo-root UAT wrapper already behaves like a broad release gate. That wrapper is not yet a clean package-local contract replacement, and on this machine it currently fails at bounded dev boot smoke after the test suites pass, so Phase 13 should explicitly plan a Wave 0 step to reconcile `mix verify.full` with the root wrapper instead of assuming the current shell entrypoint is already shippable. [VERIFIED: examples/accrue_host/README.md] [VERIFIED: scripts/ci/accrue_host_uat.sh + local run]

**Primary recommendation:** Center the phase on a host-local command contract of `mix setup`, `mix verify`, and `mix verify.full`, backed by a small manifest read by ExUnit parity tests, while keeping README and First Hour prose human-written and treating seeded replay state as a separate `Seeded history` mode. [CITED: https://hexdocs.pm/mix/1.18.1/Mix.html] [CITED: https://hexdocs.pm/phoenix/up_and_running.html] [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Clone-to-ready setup commands (`mix setup`) | API / Backend | Database / Storage | Mix aliases live in the host app and orchestrate dependency, migration, and asset tasks against the host database. [VERIFIED: examples/accrue_host/mix.exs] [CITED: https://hexdocs.pm/mix/1.18.1/Mix.html] |
| First-run subscription creation through host boundaries | Frontend Server (SSR) | API / Backend | The user-visible path starts in Phoenix/LiveView UI but the real ownership boundary is the generated `AccrueHost.Billing` facade and backend billing calls. [VERIFIED: codebase grep] |
| Signed webhook ingest | API / Backend | Database / Storage | The webhook endpoint verifies signatures and persists webhook/event state before later admin inspection. [VERIFIED: codebase grep] [VERIFIED: CLAUDE.md] |
| Admin inspection and replay | Frontend Server (SSR) | API / Backend | The mounted admin UI is a LiveView surface over persisted billing/webhook state and replay actions. [VERIFIED: codebase grep] |
| Seeded replay history for evaluation | Database / Storage | API / Backend | The seeded flow writes deterministic rows and jobs directly so browser/admin replay coverage can start from a prepared state. [VERIFIED: scripts/ci/accrue_host_seed_e2e.exs] |
| Tutorial drift protection | API / Backend | — | The most reliable enforcement point is ExUnit and shell verification in repo code, not the browser layer. [VERIFIED: codebase grep] |
| Browser smoke | Browser / Client | Frontend Server (SSR) | Playwright drives the published UI and validates the browser-visible story after the server is running. [VERIFIED: examples/accrue_host/e2e/phase11-host-gate.spec.js] [CITED: https://playwright.dev/docs/intro] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Mix aliases | Elixir/Mix `~> 1.17` floor; docs checked on Mix `1.18.1` | Package-local setup and verification contract | Phoenix and Mix both normalize project-local command entrypoints instead of external task runners for app setup flows. [VERIFIED: examples/accrue_host/mix.exs] [CITED: https://hexdocs.pm/mix/1.18.1/Mix.html] [CITED: https://hexdocs.pm/phoenix/up_and_running.html] |
| Phoenix | `1.8.5` (published 2026-03-05) | Canonical host app workflow and setup ordering | The example app already targets Phoenix `1.8.5`, and Phoenix docs still teach the same `deps.get` -> `ecto.create` -> `phx.server` order that the tutorial should preserve. [VERIFIED: npm/hex registry] [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix/up_and_running.html] |
| Phoenix LiveView | `1.1.28` (published 2026-03-27) | User-visible billing/admin paths in the host app | The billing flow and mounted admin UI already run through LiveView, so Phase 13 should document and verify the existing LiveView surface rather than inventing a CLI-only demo. [VERIFIED: npm/hex registry] [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit | `1.19.5` in the current local runtime | Docs contract tests and focused host proofs | Use for deterministic command-order, public-boundary, and drift checks that must run quickly in CI and locally. [VERIFIED: local command] [VERIFIED: codebase grep] |
| ExDoc | `0.40.1` (published 2026-01-31) | Package guide publication and guide grouping | Use for human-written guide surfaces such as `first_hour.md`; keep prose authored by hand and verify it with tests. [VERIFIED: npm/hex registry] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| `@playwright/test` | `1.59.1` (npm modified 2026-04-16) | Seeded browser smoke for admin replay/history coverage | Use only for the browser-visible `Seeded history` proof and `verify.full`; keep it out of the first teaching loop. [VERIFIED: npm registry] [VERIFIED: codebase grep] [CITED: https://playwright.dev/docs/intro] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Package-local Mix aliases | `make` or `just` | Rejected because locked decisions explicitly require app-local Mix ownership and Phoenix conventions. [VERIFIED: 13-CONTEXT.md] [CITED: https://hexdocs.pm/mix/1.18.1/Mix.html] |
| Human-written README/guide plus parity tests | Generated Markdown or Livebook walkthroughs | Rejected because locked decisions keep prose human-written and forbid Livebook/literate execution for this shell-and-Phoenix path. [VERIFIED: 13-CONTEXT.md] |
| ExUnit contract tests over guide text and manifest | Long-shell `doctest_file/1` examples | `doctest_file/1` exists, but ExUnit docs warn doctests are a poor fit for side effects and unsandboxed setup flows. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] |

**Installation:**
```bash
cd examples/accrue_host
mix deps.get
npm ci
npm run e2e:install
```

**Version verification:** [VERIFIED: npm/hex registry]
- `phoenix 1.8.5` published `2026-03-05T15:22:23.915693Z`
- `phoenix_live_view 1.1.28` published `2026-03-27T19:09:09.068957Z`
- `ex_doc 0.40.1` published `2026-01-31T07:51:03.131846Z`
- `@playwright/test 1.59.1` npm modified `2026-04-16T23:42:29.089Z`

## Architecture Patterns

### System Architecture Diagram
```text
Developer
  |
  v
README / First Hour guide
  |
  +--> First run commands ------------------------------+
  |                                                     |
  |                                               mix setup
  |                                                     |
  |                                                     v
  |                                              Phoenix host app
  |                                                     |
  |                                                     +--> AccrueHost.Billing facade --> Fake processor-backed billing state
  |                                                     |
  |                                                     +--> /webhooks/stripe --> signature verification --> webhook rows/events
  |                                                     |
  |                                                     +--> /billing LiveView/admin --> inspect + replay persisted state
  |
  +--> Seeded history commands -------------------------+
                                                        |
                                                        v
                                           seed script creates replay/history fixture
                                                        |
                                                        v
                                           Playwright smoke validates browser/admin flow
                                                        |
                                                        v
                                         mix verify / mix verify.full / root wrapper
                                                        |
                                                        v
                                        ExUnit + shell drift guards block docs/command drift
```

### Recommended Project Structure
```text
examples/accrue_host/
├── README.md                    # Canonical clone-to-running tutorial
├── mix.exs                      # mix setup / verify / verify.full aliases
├── demo/
│   └── command_manifest.exs     # Shared ordered command + mode metadata [ASSUMED]
├── test/
│   ├── ...                      # Focused host proofs
│   └── support/                 # Shared verify helpers
└── e2e/
    └── phase11-host-gate.spec.js # Seeded history browser smoke

accrue/
├── guides/
│   └── first_hour.md            # Package-facing mirror of canonical host path
└── test/accrue/docs/
    └── canonical_demo_*_test.exs # Manifest parity + guide contract tests [ASSUMED]
```

### Pattern 1: Package-Local Verification Alias
**What:** Define one short alias for the focused proof suite and one alias for the full local release gate. [CITED: https://hexdocs.pm/mix/1.18.1/Mix.html]  
**When to use:** Any command a maintainer or evaluator should remember and rerun from inside `examples/accrue_host`. [VERIFIED: 13-CONTEXT.md]  
**Example:**
```elixir
# Source: https://hexdocs.pm/mix/1.18.1/Mix.html
def project do
  [
    aliases: [all: ["deps.get --only #{Mix.env()}", "compile"]]
  ]
end
```

### Pattern 2: Phoenix-Order Local Tutorial
**What:** Teach setup in the same order Phoenix itself teaches new apps: fetch deps, prepare DB, boot server, then exercise the app. [CITED: https://hexdocs.pm/phoenix/up_and_running.html]  
**When to use:** The `First run` path in both `examples/accrue_host/README.md` and `accrue/guides/first_hour.md`. [VERIFIED: 13-CONTEXT.md]  
**Example:**
```text
# Source: https://hexdocs.pm/phoenix/up_and_running.html
mix deps.get
mix ecto.create
mix phx.server
```

### Pattern 3: Human-Written Guides, Data-Driven Navigation
**What:** Keep prose authored by hand, but drive navigation/grouping and parity checks from small structured metadata. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]  
**When to use:** Organizing `first_hour.md` and any future guide grouping or parity assertions. [VERIFIED: 13-CONTEXT.md]  
**Example:**
```elixir
# Source: https://hexdocs.pm/ex_doc/ExDoc.html
docs: [
  extras: ["README.md", "guides/first_hour.md"],
  groups_for_extras: ["Guides": ~r"guides/"]
]
```

### Anti-Patterns to Avoid
- **Root-wrapper-first teaching:** This hides the Phoenix-order setup path and violates locked decision `D-02`. [VERIFIED: 13-CONTEXT.md]
- **Seeded private setup in the main tutorial:** Seed scripts are for `Seeded history`, not for the canonical `First run` story. [VERIFIED: 13-CONTEXT.md]
- **Shell grep as the only drift guard:** Keep shell scripts for narrow invariants, but rely on ExUnit for ordered command and boundary semantics. [VERIFIED: 13-CONTEXT.md]
- **Alias lists that rerun the same non-reenabled Mix task multiple times:** Mix aliases only run most tasks once unless reenabled, so keep the alias graph simple and non-duplicative. [CITED: https://hexdocs.pm/mix/1.18.1/Mix.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Local task orchestration | A new bespoke CLI or `make`/`just` layer | Mix aliases in `examples/accrue_host/mix.exs` | Mix already supports project-local task composition and matches Phoenix expectations. [CITED: https://hexdocs.pm/mix/1.18.1/Mix.html] [VERIFIED: 13-CONTEXT.md] |
| Tutorial execution engine | Generated tutorial Markdown or Livebook runtime | Human-written README/guide plus manifest-backed ExUnit parity tests | Locked decisions require hand-written docs and targeted automation, not generated teaching content. [VERIFIED: 13-CONTEXT.md] |
| Browser regression driver | Homegrown HTTP/session script | Playwright smoke spec plus seeded fixture script | Playwright already provides isolation, assertions, and browser install flows; the repo already uses it. [CITED: https://playwright.dev/docs/intro] [VERIFIED: codebase grep] |
| Replay-history tutorial setup | Private inserts in the main walkthrough | Public `AccrueHost.Billing` + signed webhook for `First run`, seeded script only for `Seeded history` | The tutorial must teach supported host boundaries, not fixture-only internals. [VERIFIED: 13-CONTEXT.md] [VERIFIED: codebase grep] |

**Key insight:** The hard part in this phase is not adding more infrastructure; it is shrinking the public surface to one memorable local story while keeping the existing broader regression harness in parity behind it. [VERIFIED: codebase grep] [VERIFIED: 13-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: The README teaches an old command sequence after `mix setup` becomes canonical
**What goes wrong:** Docs continue to list `deps.get`, installer reruns, and individual tests even after the phase introduces `mix setup` and `mix verify`. [VERIFIED: examples/accrue_host/README.md]  
**Why it happens:** The current README is still written as a lower-level host harness checklist, not a canonical evaluator tutorial. [VERIFIED: examples/accrue_host/README.md]  
**How to avoid:** Move the ordered canonical commands into one manifest and assert parity from ExUnit against README and First Hour. [VERIFIED: 13-CONTEXT.md]  
**Warning signs:** Different command names or order between `examples/accrue_host/README.md`, `accrue/guides/first_hour.md`, and wrapper docs. [VERIFIED: codebase grep]

### Pitfall 2: Seeded history leaks into the main tutorial story
**What goes wrong:** The docs teach direct inserts or seed helpers instead of showing a first subscription and one signed webhook through public host boundaries. [VERIFIED: 13-CONTEXT.md]  
**Why it happens:** Seeded replay state is convenient for deterministic browser/admin coverage and can be mistaken for a user-facing path. [VERIFIED: scripts/ci/accrue_host_seed_e2e.exs]  
**How to avoid:** Keep `First run` and `Seeded history` as separate labeled modes and ban private setup references from the first-run guide tests. [VERIFIED: 13-CONTEXT.md]  
**Warning signs:** README or guide mentions internal schemas, direct webhook row inserts, or seed script commands inside the primary walkthrough. [VERIFIED: codebase grep]

### Pitfall 3: `verify.full` inherits the current dev-boot smoke failure
**What goes wrong:** Focused tests pass, then the release gate fails on server boot with `ACCRUE-DX-MIGRATIONS-PENDING`, so the advertised single local command is unreliable. [VERIFIED: scripts/ci/accrue_host_uat.sh + local run]  
**Why it happens:** The current root wrapper is broader than the tutorial proof suite and presently trips a host boot/config validation issue after the test sections succeed. [VERIFIED: scripts/ci/accrue_host_uat.sh + local run]  
**How to avoid:** Add a Wave 0 task to either repair the boot smoke path or redefine the new package-local full alias so it stays in true parity with a passing root wrapper. [VERIFIED: local run]  
**Warning signs:** `mix verify` passes but `mix verify.full` or `bash scripts/ci/accrue_host_uat.sh` dies during the bounded `mix phx.server` step. [VERIFIED: local run]

### Pitfall 4: Overusing doctests for shell-heavy tutorials
**What goes wrong:** Docs tests become brittle, side-effectful, or unsandboxed. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html]  
**Why it happens:** `doctest_file/1` looks attractive for Markdown examples, but long shell setup paths are not the kind of isolated code examples doctests are designed for. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html]  
**How to avoid:** Use doctests only for small API examples and keep shell/tutorial contract checks in ordinary ExUnit assertions. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html]  
**Warning signs:** Tests need real DB/process state or start leaving defined modules/process side effects behind. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html]

## Code Examples

Verified patterns from official sources:

### Mix Alias Composition
```elixir
# Source: https://hexdocs.pm/mix/1.18.1/Mix.html
defp aliases do
  [
    all: [&hello/1, "deps.get --only #{Mix.env()}", "compile"]
  ]
end
```

### ExDoc Extras Grouping
```elixir
# Source: https://hexdocs.pm/ex_doc/ExDoc.html
groups_for_extras: [
  "Introduction": Path.wildcard("guides/introduction/*.md"),
  "Advanced": Path.wildcard("guides/advanced/*.md")
]
```

### Playwright Install And Run
```bash
# Source: https://playwright.dev/docs/intro
npm install -D @playwright/test@latest
npx playwright install --with-deps
npx playwright test
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| External helper wrapper as the memorable command | Package-local Mix aliases with optional thin root wrapper | Current Phoenix/Mix guidance; locked for this phase in `D-09` through `D-13` | Keeps the public contract idiomatic for Phoenix users and reduces entrypoint sprawl. [CITED: https://hexdocs.pm/mix/1.18.1/Mix.html] [VERIFIED: 13-CONTEXT.md] |
| Generated auth/runtime owned by framework package | Generated code is host-owned after install | Phoenix `mix phx.gen.auth` current docs | Supports Accrue's host-owned boundary story for billing facade, auth, and router ownership. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] |
| Long shell tutorials enforced as doctests | Human-written guides with focused contract tests | ExUnit current docs | Better fit for side-effectful setup sequences and explicit public-boundary assertions. [CITED: https://hexdocs.pm/ex_unit/ExUnit.DocTest.html] |

**Deprecated/outdated:**
- Teaching the host example primarily as a Phase 10 dogfood harness is outdated for this phase; it now needs to be packaged as the canonical evaluator path. [VERIFIED: examples/accrue_host/README.md] [VERIFIED: 13-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A small repo-readable manifest should live at `examples/accrue_host/demo/command_manifest.exs` and be consumed by tests rather than by shell directly. | Recommended Project Structure | Low; the exact file path/format is discretionary, but planners need one concrete default. |
| A2 | A new docs test module under `accrue/test/accrue/docs/canonical_demo_*_test.exs` is the cleanest home for manifest parity assertions. | Recommended Project Structure | Low; any equivalent ExUnit location works if it stays package-owned and release-gated. |

## Open Questions

1. **Should Phase 13 repair the current dev-boot smoke failure or narrow the full gate until it is repaired?**
   - What we know: `bash scripts/ci/accrue_host_uat.sh` currently passes installer, focused tests, and full test suite, then fails during bounded `mix phx.server` with `ACCRUE-DX-MIGRATIONS-PENDING`. [VERIFIED: local run]
   - What's unclear: Whether this is an intended failure mode exposed by newer config validation, or an incidental regression outside the demo/tutorial repackaging work. [VERIFIED: local run]
   - Recommendation: Treat this as a Wave 0 planning decision and require either a boot-smoke fix or a documented/full-gate redesign before `mix verify.full` is declared canonical. [VERIFIED: local run]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Mix aliases, host tests, docs tests | ✓ | Mix `1.19.5`, OTP `28` in local runtime | — [VERIFIED: local command] |
| Node.js / npm | Playwright smoke and asset install | ✓ | Node `v22.14.0`, npm `11.1.0` | — [VERIFIED: local command] |
| PostgreSQL | Host setup, migrations, tests, dev boot | ✓ | `14.17`; `pg_isready` reports localhost accepting connections | — [VERIFIED: local command] |
| Playwright CLI | Browser smoke | ✓ | `1.59.1` | — [VERIFIED: local command] |
| Playwright browser cache | Browser smoke | ✓ | Cached Chromium/WebKit artifacts present under `~/Library/Caches/ms-playwright` | `npm run e2e:install` downloads required browsers. [VERIFIED: local command] [CITED: https://playwright.dev/docs/intro] |
| System Chrome/Chromium binary | Some local browser tooling | ✗ | — | Use Playwright-managed Chromium instead of relying on a system browser. [VERIFIED: local command] [CITED: https://playwright.dev/docs/intro] |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: local command]

**Missing dependencies with fallback:**
- A system Chrome/Chromium binary is missing, but the repo already uses Playwright-managed browsers as a viable fallback. [VERIFIED: local command] [CITED: https://playwright.dev/docs/intro]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit `1.19.5` + Playwright `1.59.1` [VERIFIED: local command] |
| Config file | `examples/accrue_host/test/test_helper.exs` and `examples/accrue_host/playwright.config.js` [VERIFIED: codebase grep] |
| Quick run command | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs test/accrue_host_web/subscription_flow_test.exs test/accrue_host_web/webhook_ingest_test.exs test/accrue_host_web/admin_webhook_replay_test.exs test/accrue_host_web/admin_mount_test.exs` [VERIFIED: local test run] |
| Full suite command | `bash scripts/ci/accrue_host_uat.sh` [VERIFIED: local run] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEMO-01 | Canonical local demo path stays executable from documented prerequisites | integration/docs | `bash scripts/ci/accrue_host_uat.sh` plus docs parity tests | ✅ existing, but full gate currently fails dev boot smoke [VERIFIED: local run] |
| DEMO-02 | Fake-backed subscription can be created without live Stripe creds | integration | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs test/accrue_host_web/subscription_flow_test.exs` | ✅ [VERIFIED: local test run] |
| DEMO-03 | Admin inspection and replay work through mounted UI | integration + browser smoke | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host_web/admin_webhook_replay_test.exs test/accrue_host_web/admin_mount_test.exs` and browser smoke in full gate | ✅ [VERIFIED: local test run] |
| DEMO-04 | One CI-equivalent local command verifies the canonical path | smoke/release gate | `cd examples/accrue_host && mix verify.full` | ❌ Wave 0 alias needed [VERIFIED: examples/accrue_host/mix.exs] |
| DEMO-05 | Docs distinguish local eval, CI gate, Hex smoke, and production setup | docs contract | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/package_docs_verifier_test.exs` plus new manifest parity test | ⚠️ partial; new parity test needed [VERIFIED: local test run] |
| DEMO-06 | Drift between demo path and tutorial commands is caught before release | docs contract | `cd accrue && mix test ...docs...` plus root wrapper parity assertion | ⚠️ partial; manifest-backed order test needed [VERIFIED: codebase grep] |
| ADOPT-02 | Tutorial covers install -> first subscription -> signed webhook -> admin inspect/replay -> focused tests | docs + integration | README/First Hour parity tests + focused host proofs | ⚠️ story pieces exist; canonical tutorial contract still needs packaging [VERIFIED: codebase grep] |

### Sampling Rate
- **Per task commit:** Run the focused host proof suite or the affected docs contract tests. [VERIFIED: local test run]
- **Per wave merge:** Run the focused host suite plus docs contract tests and, once introduced, `mix verify`. [VERIFIED: 13-CONTEXT.md]
- **Phase gate:** `mix verify.full` and `bash scripts/ci/accrue_host_uat.sh` should both be green or intentionally reduced to the same passing contract before `/gsd-verify-work`. [VERIFIED: 13-CONTEXT.md] [VERIFIED: local run]

### Wave 0 Gaps
- [ ] Add `mix verify` alias in `examples/accrue_host/mix.exs` so focused proofs become one package-local command. [VERIFIED: examples/accrue_host/mix.exs]
- [ ] Add `mix verify.full` alias in `examples/accrue_host/mix.exs` and make the root wrapper delegate to it. [VERIFIED: examples/accrue_host/mix.exs] [VERIFIED: scripts/ci/accrue_host_uat.sh]
- [ ] Add manifest-backed docs parity tests for README, First Hour, and wrapper command/label order. [VERIFIED: 13-CONTEXT.md]
- [ ] Resolve or intentionally redesign the failing dev boot smoke before advertising the full gate as canonical. [VERIFIED: local run]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep `/billing` behind host-owned auth generated by `mix phx.gen.auth`-style boundaries and existing session/auth plugs. [CITED: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html] [VERIFIED: codebase grep] |
| V3 Session Management | yes | Continue forwarding host session keys into the mounted admin UI instead of introducing a separate billing session scheme. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Preserve billing-admin gating proved by `admin_mount_test.exs`; anonymous and non-admin users must stay redirected away from `/billing`. [VERIFIED: local test run] |
| V5 Input Validation | yes | Keep signed webhook verification and public-boundary docs tests that forbid private surface usage in the tutorial. [VERIFIED: CLAUDE.md] [VERIFIED: codebase grep] |
| V6 Cryptography | yes | Use existing Stripe signature verification and do not hand-roll alternative signing or replay checks. [VERIFIED: CLAUDE.md] [VERIFIED: codebase grep] |

### Known Threat Patterns for Phoenix host demo + admin replay

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tampered or unsigned webhook payload reaches ingest path | Spoofing / Tampering | Verify signature before ingest, reject bad payloads, and keep raw-body capture before `Plug.Parsers`. [VERIFIED: CLAUDE.md] [VERIFIED: local test run] |
| Demo docs accidentally teach private package tables or direct inserts | Tampering | Assert public surfaces and forbidden private surfaces in docs tests; keep seeded fixtures out of `First run`. [VERIFIED: 13-CONTEXT.md] [VERIFIED: codebase grep] |
| Non-admin user reaches billing admin UI | Elevation of Privilege | Preserve host-authenticated route scope and billing-admin authorization checks. [VERIFIED: local test run] |
| Replay/admin actions lose audit trail | Repudiation | Keep admin replay emitting persisted billing/admin events tied to the source webhook. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- Local repository inspection and command runs in `/Users/jon/projects/accrue` - README, guide, Mix config, shell scripts, tests, and local verification runs. [VERIFIED: codebase grep] [VERIFIED: local run]
- https://hexdocs.pm/mix/1.18.1/Mix.html - Mix alias semantics, environment behavior, and task composition.
- https://hexdocs.pm/phoenix/up_and_running.html - Phoenix-order setup flow for local apps.
- https://hexdocs.pm/phoenix/mix_phx_gen_auth.html - Host-owned generated auth boundaries.
- https://hexdocs.pm/ex_doc/ExDoc.html - ExDoc extras and grouping.
- https://hexdocs.pm/ex_unit/ExUnit.DocTest.html - Doctest fit and limits.
- https://playwright.dev/docs/intro - Playwright install, bundled browser flow, and test runner model.
- Hex.pm package API for `phoenix`, `phoenix_live_view`, and `ex_doc` - verified current versions and publish dates. [VERIFIED: npm/hex registry]
- npm registry for `@playwright/test` - verified current version and modified date. [VERIFIED: npm registry]

### Secondary (MEDIUM confidence)
- None. All planning-significant claims above were verified from official docs, official registries, or the codebase in this session.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were verified from Hex.pm or npm, and the recommended tools are already present in the repo. [VERIFIED: npm/hex registry] [VERIFIED: codebase grep]
- Architecture: HIGH - the command surfaces, docs surfaces, tests, and wrapper behavior were all inspected directly in the codebase. [VERIFIED: codebase grep]
- Pitfalls: HIGH - the biggest phase-specific pitfalls are visible in locked decisions and one was reproduced locally via the current UAT wrapper failure. [VERIFIED: 13-CONTEXT.md] [VERIFIED: local run]

**Research date:** 2026-04-16
**Valid until:** 2026-05-16
