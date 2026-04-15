# Phase 09: Release - Pattern Map

**Mapped:** 2026-04-15
**Files analyzed:** 16
**Analogs found:** 13 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | config | event-driven | `.github/workflows/ci.yml` | exact |
| `.github/workflows/release-please.yml` | config | event-driven | `.github/workflows/ci.yml` | role-match |
| `.github/workflows/publish-hex.yml` | config | event-driven | `.github/workflows/ci.yml` | role-match |
| `release-please-config.json` | config | transform | none in repo | none |
| `.release-please-manifest.json` | config | transform | none in repo | none |
| `accrue/mix.exs` | config | transform | `accrue/mix.exs` | exact |
| `accrue_admin/mix.exs` | config | transform | `accrue_admin/mix.exs` | exact |
| `accrue/README.md` | utility (docs) | file-I/O | `accrue/guides/testing.md` | role-match |
| `accrue_admin/README.md` | utility (docs) | file-I/O | `accrue_admin/guides/admin_ui.md` | role-match |
| `accrue/CHANGELOG.md` | utility (docs) | file-I/O | none in repo | none |
| `accrue_admin/CHANGELOG.md` | utility (docs) | file-I/O | none in repo | none |
| `accrue_admin/guides/admin_ui.md` | utility (docs) | file-I/O | `accrue_admin/guides/admin_ui.md` | exact |
| `CONTRIBUTING.md` | utility (docs) | file-I/O | `guides/testing-live-stripe.md` | partial |
| `CODE_OF_CONDUCT.md` | utility (docs) | file-I/O | `guides/testing-live-stripe.md` | partial |
| `SECURITY.md` | utility (docs) | file-I/O | `guides/testing-live-stripe.md` | partial |
| `RELEASING.md` | utility (docs) | file-I/O | `guides/testing-live-stripe.md` | role-match |

## Pattern Assignments

### `.github/workflows/ci.yml` (config, event-driven)

**Analog:** `.github/workflows/ci.yml`

**Trigger and matrix pattern** ([`.github/workflows/ci.yml:3`](/Users/jon/projects/accrue/.github/workflows/ci.yml#L3), lines 3-18 and 35-70):

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch: {}

jobs:
  test:
    name: Test (elixir=${{ matrix.elixir }} otp=${{ matrix.otp }} sigra=${{ matrix.sigra }})
    runs-on: ubuntu-24.04
...
    strategy:
      fail-fast: false
      matrix:
        include:
          - elixir: '1.17.3'
            otp: '27.0'
            sigra: 'off'
            continue-on-error: false
```

**Cache and BEAM setup pattern** ([`.github/workflows/ci.yml:72`](/Users/jon/projects/accrue/.github/workflows/ci.yml#L72), lines 72-136):

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Set up BEAM
    uses: erlef/setup-beam@v1
    with:
      otp-version: ${{ matrix.otp }}
      elixir-version: ${{ matrix.elixir }}

  - name: Restore deps cache
    uses: actions/cache@v4
    with:
      path: accrue/deps
      key: ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-${{ matrix.sigra }}-deps-${{ hashFiles('accrue/mix.lock') }}

  - name: Restore PLT cache
    id: plt_cache
    uses: actions/cache/restore@v4
```

**Required gate-step pattern** ([`.github/workflows/ci.yml:95`](/Users/jon/projects/accrue/.github/workflows/ci.yml#L95), lines 95-136):

```yaml
- name: Install deps
  run: cd accrue && mix deps.get

- name: Check formatting
  run: cd accrue && mix format --check-formatted

- name: Compile (warnings as errors)
  run: cd accrue && mix compile --warnings-as-errors

- name: Run tests
  run: cd accrue && mix test --warnings-as-errors

- name: Credo (strict)
  run: cd accrue && mix credo --strict

- name: Run Dialyzer
  run: cd accrue && mix dialyzer --format github
```

**Use for Phase 09:** keep this file as the canonical workflow shape when adding the missing `with_opentelemetry` / `without_opentelemetry` dimension and when expanding gates to both packages.

---

### `.github/workflows/release-please.yml` (config, event-driven)

**Analog:** `.github/workflows/ci.yml`

**Workflow shell pattern** ([`.github/workflows/ci.yml:3`](/Users/jon/projects/accrue/.github/workflows/ci.yml#L3), lines 3-18):

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch: {}
```

**Single-job setup pattern** ([`.github/workflows/accrue_admin_assets.yml:23`](/Users/jon/projects/accrue/.github/workflows/accrue_admin_assets.yml#L23), lines 23-49):

```yaml
jobs:
  asset-freshness:
    name: Asset freshness
    runs-on: ubuntu-24.04

    steps:
      - uses: actions/checkout@v4

      - name: Set up BEAM
        uses: erlef/setup-beam@v1
```

**Recommendation:** copy the current repo's workflow skeleton, step naming, and `ubuntu-24.04` runner selection, then fill in the Release Please action block from `09-RESEARCH.md`. There is no in-repo Release Please workflow yet.

---

### `.github/workflows/publish-hex.yml` (config, event-driven)

**Analog:** `.github/workflows/ci.yml`

**Service + env pattern** ([`.github/workflows/accrue_admin_browser.yml:22`](/Users/jon/projects/accrue/.github/workflows/accrue_admin_browser.yml#L22), lines 22-43):

```yaml
services:
  postgres:
    image: postgres:15
    env:
      POSTGRES_PASSWORD: postgres
      POSTGRES_USER: postgres
      POSTGRES_DB: postgres
...
env:
  MIX_ENV: test
  PGUSER: postgres
  PGPASSWORD: postgres
  PGHOST: localhost
```

**Artifact-on-failure pattern** ([`.github/workflows/accrue_admin_browser.yml:75`](/Users/jon/projects/accrue/.github/workflows/accrue_admin_browser.yml#L75), lines 75-89):

```yaml
- name: Upload Playwright report
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: accrue-admin-playwright-report
    path: accrue_admin/playwright-report
    if-no-files-found: ignore
```

**Recommendation:** use the repo's existing Actions style for runner, checkout, BEAM setup, env injection, and failure artifacts. The actual `mix hex.publish --yes` job logic has no exact in-repo analog; take that from `09-RESEARCH.md`.

---

### `release-please-config.json` (config, transform)

**Analog:** none in repo

There is no existing JSON manifest-style release config in this repository. Planner should use the monorepo manifest examples from `09-RESEARCH.md`, not invent a new local pattern.

---

### `.release-please-manifest.json` (config, transform)

**Analog:** none in repo

There is no existing version-manifest JSON file in this repository. Planner should use the exact monorepo manifest model from `09-RESEARCH.md`.

---

### `accrue/mix.exs` (config, transform)

**Analog:** `accrue/mix.exs`

**Project metadata pattern** ([`accrue/mix.exs:7`](/Users/jon/projects/accrue/accrue/mix.exs#L7), lines 7-20):

```elixir
def project do
  [
    app: :accrue,
    version: @version,
    elixir: "~> 1.17",
    deps: deps(),
    aliases: aliases(),
    package: package(),
    description: "Billing state, modeled clearly.",
    source_url: @source_url,
    docs: docs()
  ]
end
```

**Optional dependency pattern** ([`accrue/mix.exs:68`](/Users/jon/projects/accrue/accrue/mix.exs#L68), lines 68-95):

```elixir
# Optional deps — conditionally compiled
{:phoenix, "~> 1.8", optional: true},
{:phoenix_live_view, "~> 1.1"},
{:opentelemetry, "~> 1.7", optional: true},
{:telemetry_metrics, "~> 1.1", optional: true},
{:ex_doc, "~> 0.40", only: :dev, runtime: false},
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},
{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
```

**Package + docs config pattern** ([`accrue/mix.exs:115`](/Users/jon/projects/accrue/accrue/mix.exs#L115), lines 115-142):

```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{},
    files: ~w(lib mix.exs README* LICENSE* CHANGELOG*)
  ]
end

defp docs do
  [
    main: "Accrue",
    source_ref: "v#{@version}",
    extras: [
      "guides/telemetry.md",
      "guides/testing.md",
      "guides/auth_adapters.md"
    ],
    skip_undefined_reference_warnings_on: &skip_undefined_reference_warning?/1
  ]
end
```

**Use for Phase 09:** extend the existing `package/0` and `docs/0` shape instead of replacing it. This is the house style for ExDoc extras, package files, version source, and package metadata.

---

### `accrue_admin/mix.exs` (config, transform)

**Analog:** `accrue_admin/mix.exs`

**Admin package metadata pattern** ([`accrue_admin/mix.exs:7`](/Users/jon/projects/accrue/accrue_admin/mix.exs#L7), lines 7-18):

```elixir
def project do
  [
    app: :accrue_admin,
    version: @version,
    elixir: "~> 1.17",
    deps: deps(),
    package: package(),
    description: "Admin LiveView UI for Accrue billing.",
    source_url: @source_url
  ]
end
```

**Sibling dependency pattern** ([`accrue_admin/mix.exs:35`](/Users/jon/projects/accrue/accrue_admin/mix.exs#L35), lines 35-47):

```elixir
defp deps do
  [
    # Dev monorepo path; at publish time this flips to "~> 1.0" per D-43.
    # Do NOT add both forms now.
    {:accrue, path: "../accrue"},
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:ex_doc, "~> 0.40", only: :dev, runtime: false}
  ]
end
```

**Package file list pattern** ([`accrue_admin/mix.exs:50`](/Users/jon/projects/accrue/accrue_admin/mix.exs#L50), lines 50-55):

```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{},
    files: ~w(lib config priv/static mix.exs README* LICENSE* CHANGELOG*)
  ]
end
```

**Use for Phase 09:** follow the same `project/0`, `deps/0`, `package/0` structure when adding admin docs config and publish-safe package metadata. Keep the local `path:` development pattern visible and isolated.

---

### `accrue/README.md` (utility/docs, file-I/O)

**Analog:** `accrue/guides/testing.md`

**Lead-with-working-example pattern** ([`accrue/guides/testing.md:1`](/Users/jon/projects/accrue/accrue/guides/testing.md#L1), lines 1-18):

```markdown
# Testing Accrue Billing Flows

## Fake-first Phoenix scenario

Start billing tests in the host app, not inside Accrue internals.
...
```elixir
defmodule MyApp.BillingTest do
```
```

**Checklist section pattern** ([`accrue/guides/testing.md:52`](/Users/jon/projects/accrue/accrue/guides/testing.md#L52), lines 52-95):

```markdown
Scenario checklist: successful checkout, trial conversion, failed renewal, cancellation/grace period, invoice email/PDF, webhook replay, background jobs, and provider-parity tests.

## Successful checkout
...
## Provider-parity tests
```

**Docs test pattern if README content gets assertions** ([`accrue/test/accrue/docs/testing_guide_test.exs:21`](/Users/jon/projects/accrue/accrue/test/accrue/docs/testing_guide_test.exs#L21), lines 21-31):

```elixir
test "testing guide contains copy-paste public helper strings" do
  guide = File.read!(@guide)

  assert guide =~ "use Accrue.Test"
  assert guide =~ "MyApp.Billing"
end
```

**Use for Phase 09:** README should start with a runnable quickstart, then move to guided sections. The closest local docs style is example-first markdown, not marketing copy.

---

### `accrue_admin/README.md` (utility/docs, file-I/O)

**Analog:** `accrue_admin/guides/admin_ui.md`

**Host-setup-first pattern** ([`accrue_admin/guides/admin_ui.md:1`](/Users/jon/projects/accrue/accrue_admin/guides/admin_ui.md#L1), lines 1-23):

```markdown
# AccrueAdmin Integration Guide

## Host Setup

Add the package to your router and mount it where operators expect billing controls:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
```
```

**Operational command block pattern** ([`accrue_admin/guides/admin_ui.md:50`](/Users/jon/projects/accrue/accrue_admin/guides/admin_ui.md#L50), lines 50-79):

```markdown
## Private Asset Bundle
...
```bash
cd accrue_admin
mix accrue_admin.assets.build
```

## Browser UAT
...
```bash
cd accrue_admin
npm ci
npx playwright install chromium
npm run e2e
```
```

**Use for Phase 09:** README should follow the admin guide's install/mount/run shape: setup snippet, package-specific commands, then links to deeper guides.

---

### `accrue/CHANGELOG.md` (utility/docs, file-I/O)

**Analog:** none in repo

No changelog file exists yet. Do not infer a local changelog format from unrelated docs; planner should use Release Please's generated changelog conventions from `09-RESEARCH.md`.

---

### `accrue_admin/CHANGELOG.md` (utility/docs, file-I/O)

**Analog:** none in repo

No changelog file exists yet. Use Release Please output conventions from `09-RESEARCH.md`.

---

### `accrue_admin/guides/admin_ui.md` (utility/docs, file-I/O)

**Analog:** `accrue_admin/guides/admin_ui.md`

**Sectioned install guide pattern** ([`accrue_admin/guides/admin_ui.md:5`](/Users/jon/projects/accrue/accrue_admin/guides/admin_ui.md#L5), lines 5-30):

```markdown
## Host Setup
...
`accrue_admin "/billing"` creates:

- hashed package asset routes under `/billing/assets/*`
- the main billing LiveView routes under `/billing/*`
- compile-gated dev routes under `/billing/dev/*` only outside `MIX_ENV=prod`
```

**Operational verification pattern** ([`accrue_admin/guides/admin_ui.md:66`](/Users/jon/projects/accrue/accrue_admin/guides/admin_ui.md#L66), lines 66-108):

```markdown
## Browser UAT
...
CI runs the same suite in `.github/workflows/accrue_admin_browser.yml`
...
## Prod Compile Guarantee
...
Use `MIX_ENV=prod mix compile` in `accrue_admin/` as the smoke check
```

**Use for Phase 09:** if this guide is expanded for release/docs, keep the current pattern of: concrete host wiring, then local command blocks, then CI/verification notes.

---

### `CONTRIBUTING.md` (utility/docs, file-I/O)

**Analog:** `guides/testing-live-stripe.md`

**Runbook-style numbered steps** ([`guides/testing-live-stripe.md:49`](/Users/jon/projects/accrue/guides/testing-live-stripe.md#L49), lines 49-66):

```markdown
## Running via `act` (local GitHub Actions replay)

1. Install `act`
2. Copy the secrets template
3. Populate `.secrets`
4. Run:
```

**Policy + command pairing pattern** ([`guides/testing-live-stripe.md:33`](/Users/jon/projects/accrue/guides/testing-live-stripe.md#L33), lines 33-47):

```markdown
## Running locally

```bash
cd accrue
export STRIPE_TEST_SECRET_KEY=sk_test_...
mix test.live
```
```

**Use for Phase 09:** `CONTRIBUTING.md` should be procedural. Lead with branch/commit/test/docs/release commands, not prose. There is no direct existing contributing file.

---

### `CODE_OF_CONDUCT.md` (utility/docs, file-I/O)

**Analog:** `guides/testing-live-stripe.md`

There is no conduct-policy file in the repo. The only reusable local pattern is concise markdown headings with direct instructions and no filler prose. Content should come from Contributor Covenant 2.1, per `09-RESEARCH.md`.

---

### `SECURITY.md` (utility/docs, file-I/O)

**Analog:** `guides/testing-live-stripe.md`

**Disclosure-instructions style analog** ([`guides/testing-live-stripe.md:68`](/Users/jon/projects/accrue/guides/testing-live-stripe.md#L68), lines 68-81):

```markdown
## Running via GitHub Actions manual dispatch

1. Go to **Actions**
2. Select branch and confirm.
3. The `live-stripe` job runs with `STRIPE_TEST_SECRET_KEY` injected
```

**Use for Phase 09:** `SECURITY.md` should mirror this concise instruction style: reporting path, supported versions table, response expectations. There is no exact local security-policy analog.

---

### `RELEASING.md` (utility/docs, file-I/O)

**Analog:** `guides/testing-live-stripe.md`

**Operator runbook pattern** ([`guides/testing-live-stripe.md:49`](/Users/jon/projects/accrue/guides/testing-live-stripe.md#L49), lines 49-80):

```markdown
## Running via `act` (local GitHub Actions replay)
...
## Running via GitHub Actions manual dispatch
...
## Scheduled run
```

**Philosophy / why-this-exists pattern** ([`guides/testing-live-stripe.md:83`](/Users/jon/projects/accrue/guides/testing-live-stripe.md#L83), lines 83-97):

```markdown
## Philosophy

The live-Stripe suite exists to catch one specific class of bug:
**Stripe API contract drift**.
```

**Use for Phase 09:** the same-day `1.0.0` runbook should use this exact pattern: local dry-run, GitHub dispatch path, release ordering, then a short rationale section.

## Shared Patterns

### GitHub Actions Skeleton

**Sources:** [`.github/workflows/ci.yml:72`](/Users/jon/projects/accrue/.github/workflows/ci.yml#L72), [`.github/workflows/accrue_admin_assets.yml:28`](/Users/jon/projects/accrue/.github/workflows/accrue_admin_assets.yml#L28), [`.github/workflows/accrue_admin_browser.yml:44`](/Users/jon/projects/accrue/.github/workflows/accrue_admin_browser.yml#L44)

**Apply to:** all new workflow files

```yaml
steps:
  - uses: actions/checkout@v4

  - name: Set up BEAM
    uses: erlef/setup-beam@v1
```

Keep `ubuntu-24.04`, `actions/checkout@v4`, and `erlef/setup-beam@v1` consistent across release workflows.

### Service Container and Environment Shape

**Sources:** [`.github/workflows/ci.yml:20`](/Users/jon/projects/accrue/.github/workflows/ci.yml#L20), [`.github/workflows/accrue_admin_browser.yml:22`](/Users/jon/projects/accrue/.github/workflows/accrue_admin_browser.yml#L22)

**Apply to:** workflows that need DB-backed smoke checks before publish

```yaml
services:
  postgres:
    image: postgres:15
    env:
      POSTGRES_PASSWORD: postgres
      POSTGRES_USER: postgres
      POSTGRES_DB: postgres

env:
  MIX_ENV: test
  PGUSER: postgres
  PGPASSWORD: postgres
  PGHOST: localhost
```

### ExDoc and Package Metadata

**Sources:** [`accrue/mix.exs:115`](/Users/jon/projects/accrue/accrue/mix.exs#L115), [`accrue_admin/mix.exs:50`](/Users/jon/projects/accrue/accrue_admin/mix.exs#L50)

**Apply to:** both `mix.exs` files

```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{},
    files: ~w(lib mix.exs README* LICENSE* CHANGELOG*)
  ]
end
```

For `accrue_admin`, keep the same structure but preserve package-specific file roots like `config` and `priv/static`.

### Markdown Guide Shape

**Sources:** [`accrue/guides/testing.md:1`](/Users/jon/projects/accrue/accrue/guides/testing.md#L1), [`accrue_admin/guides/admin_ui.md:5`](/Users/jon/projects/accrue/accrue_admin/guides/admin_ui.md#L5), [`guides/testing-live-stripe.md:33`](/Users/jon/projects/accrue/guides/testing-live-stripe.md#L33)

**Apply to:** `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `RELEASING.md`, admin guide updates

```markdown
# Title

## Host Setup / Running locally / Manual dispatch

```bash
cd package
mix ...
```
```

The repo's existing docs consistently lead with concrete commands and runnable snippets.

### Docs Assertion Tests

**Sources:** [`accrue/test/accrue/docs/testing_guide_test.exs:21`](/Users/jon/projects/accrue/accrue/test/accrue/docs/testing_guide_test.exs#L21), [`accrue/test/accrue/docs/community_auth_test.exs:17`](/Users/jon/projects/accrue/accrue/test/accrue/docs/community_auth_test.exs#L17)

**Apply to:** any new docs tests the planner chooses to add

```elixir
guide = File.read!(@guide)

assert guide =~ "expected phrase"
refute guide =~ "out of scope phrase"
```

This repo tests docs as plain file-content assertions. Reuse that instead of snapshotting rendered HTML.

## No Analog Found

Files with no close match in the codebase; planner should use `09-RESEARCH.md` patterns directly:

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `release-please-config.json` | config | transform | No existing manifest-style release config in repo |
| `.release-please-manifest.json` | config | transform | No existing version manifest in repo |
| `accrue/CHANGELOG.md` | utility (docs) | file-I/O | No existing changelog file to copy |
| `accrue_admin/CHANGELOG.md` | utility (docs) | file-I/O | No existing changelog file to copy |

## Metadata

**Analog search scope:** `CLAUDE.md`, `.github/workflows/*.yml`, `accrue/mix.exs`, `accrue_admin/mix.exs`, `accrue/guides/*.md`, `accrue_admin/guides/*.md`, `guides/*.md`, `accrue/test/accrue/docs/*_test.exs`

**Files scanned:** 12 codebase analog files plus 2 phase artifacts

**Pattern extraction date:** 2026-04-15
