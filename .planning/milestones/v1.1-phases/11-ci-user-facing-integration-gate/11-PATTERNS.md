# Phase 11: CI User-Facing Integration Gate - Pattern Map

**Mapped:** 2026-04-16
**Files analyzed:** 6
**Analogs found:** 5 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | config | event-driven | `.github/workflows/ci.yml` | exact |
| `examples/accrue_host/playwright.config.js` | config | request-response | `accrue_admin/playwright.config.js` | exact |
| `examples/accrue_host/package.json` | config | request-response | `accrue_admin/package.json` | exact |
| `examples/accrue_host/e2e/phase11-host-gate.spec.js` | test | request-response | `scripts/ci/accrue_host_browser_smoke.cjs` | flow-match |
| `scripts/ci/accrue_host_uat.sh` | utility | batch | `scripts/ci/accrue_host_uat.sh` | exact |
| `scripts/ci/annotation_sweep.sh` | utility | event-driven | none found | none |

## Pattern Assignments

### `.github/workflows/ci.yml` (config, event-driven)

**Analog:** `.github/workflows/ci.yml`

Use the existing workflow as the base shape. Phase 11 should extend this file rather than invent a second mandatory gate.

**Trigger + ordered job shell** ([.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L1) and [.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L15)):
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch: {}
  schedule:
    - cron: '0 6 * * *'

jobs:
  release-gate:
    name: Release gate (elixir=${{ matrix.elixir }} otp=${{ matrix.otp }} sigra=${{ matrix.sigra }} opentelemetry=${{ matrix.opentelemetry }})
    runs-on: ubuntu-24.04
```

**Service + matrix + env pattern** ([.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L20), [.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L35), [.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L73)):
```yaml
services:
  postgres:
    image: postgres:15
    env:
      POSTGRES_PASSWORD: postgres
      POSTGRES_USER: postgres
      POSTGRES_DB: postgres
    ports:
      - 5432:5432
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5

strategy:
  fail-fast: false

env:
  MIX_ENV: test
  PGUSER: postgres
  PGPASSWORD: postgres
  PGHOST: localhost
```

**Step ordering pattern for blocking checks** ([.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L84)):
```yaml
steps:
  - uses: actions/checkout@v6

  - name: Set up BEAM
    uses: erlef/setup-beam@v1
    with:
      otp-version: ${{ matrix.otp }}
      elixir-version: ${{ matrix.elixir }}

  - name: Install Hex
    run: mix local.hex --force
```

**Cache + split restore/save PLT pattern** ([.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L96), [.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L119), [.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L137)):
```yaml
- name: Restore accrue deps cache
  uses: actions/cache@v5
  with:
    path: accrue/deps
    key: ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-${{ matrix.sigra }}-${{ matrix.opentelemetry }}-deps-${{ hashFiles('accrue/mix.lock') }}

- name: Restore accrue PLT cache
  id: accrue_plt_cache
  uses: actions/cache/restore@v5

- name: Save accrue PLT cache
  if: steps.accrue_plt_cache.outputs.cache-hit != 'true'
  uses: actions/cache/save@v5
```

**Advisory job pattern to keep live Stripe non-blocking** ([.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L222)):
```yaml
live-stripe:
  name: Live Stripe (advisory)
  runs-on: ubuntu-24.04
  if: github.event_name == 'workflow_dispatch' || github.event_name == 'schedule'
  continue-on-error: true
```

**Artifact upload pattern for failures** ([.github/workflows/accrue_admin_browser.yml](/Users/jon/projects/accrue/.github/workflows/accrue_admin_browser.yml#L78)):
```yaml
- name: Upload Playwright report
  if: failure()
  uses: actions/upload-artifact@v7
  with:
    name: accrue-admin-playwright-report
    path: accrue_admin/playwright-report
    if-no-files-found: ignore

- name: Upload Playwright traces
  if: failure()
  uses: actions/upload-artifact@v7
  with:
    name: accrue-admin-playwright-traces
    path: accrue_admin/test-results
    if-no-files-found: ignore
```

### `examples/accrue_host/playwright.config.js` (config, request-response)

**Analog:** `accrue_admin/playwright.config.js`

Use the admin Playwright config almost verbatim, changing only the host app port, server command, project list, and output paths.

**Imports + base URL + reporter pattern** ([accrue_admin/playwright.config.js](/Users/jon/projects/accrue/accrue_admin/playwright.config.js#L1)):
```javascript
// @ts-check
const { defineConfig, devices } = require("@playwright/test");

const port = process.env.ACCRUE_ADMIN_E2E_PORT || "4017";
const baseURL = `http://127.0.0.1:${port}`;

module.exports = defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: false,
  workers: 1,
  reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : [["list"]],
```

**Failure artifact + webServer pattern** ([accrue_admin/playwright.config.js](/Users/jon/projects/accrue/accrue_admin/playwright.config.js#L14)):
```javascript
  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure"
  },
  webServer: {
    command: `MIX_ENV=test ACCRUE_ADMIN_E2E_PORT=${port} mix accrue_admin.e2e.server`,
    url: `${baseURL}/__e2e__/health`,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000
  },
```

**Project definition pattern** ([accrue_admin/playwright.config.js](/Users/jon/projects/accrue/accrue_admin/playwright.config.js#L25)):
```javascript
  projects: [
    {
      name: "chromium-desktop",
      use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } }
    },
    {
      name: "chromium-mobile",
      use: { ...devices["Pixel 5"] }
    }
  ],
  outputDir: "test-results"
});
```

For Phase 11, keep the single required blocking project from the UI contract: desktop Chromium at `1280x900`.

### `examples/accrue_host/package.json` (config, request-response)

**Analog:** `accrue_admin/package.json`

Keep the host package file minimal and Playwright-only.

**Minimal script + dependency pattern** ([accrue_admin/package.json](/Users/jon/projects/accrue/accrue_admin/package.json#L1)):
```json
{
  "name": "accrue-admin-e2e",
  "private": true,
  "scripts": {
    "e2e": "env -u NO_COLOR playwright test",
    "e2e:install": "playwright install chromium"
  },
  "devDependencies": {
    "@playwright/test": "^1.57.0"
  }
}
```

Phase 11 should copy this structure into `examples/accrue_host/package.json`, renaming the package and keeping the same script shape so CI can run `npm ci` and `npm run e2e`.

### `examples/accrue_host/e2e/phase11-host-gate.spec.js` (test, request-response)

**Analog:** `scripts/ci/accrue_host_browser_smoke.cjs`

This is the closest flow match because it already covers the exact host user/admin browser path the phase wants. Port its helper functions and assertions into Playwright Test's `test()` format.

**Imports + fixture bootstrap pattern** ([scripts/ci/accrue_host_browser_smoke.cjs](/Users/jon/projects/accrue/scripts/ci/accrue_host_browser_smoke.cjs#L3)):
```javascript
const fs = require("node:fs");
const path = require("node:path");
const { chromium, expect } = require("@playwright/test");

const baseURL = process.env.ACCRUE_HOST_BASE_URL || "http://127.0.0.1:4101";
const fixturePath = process.env.ACCRUE_HOST_E2E_FIXTURE;

if (!fixturePath) {
  throw new Error("ACCRUE_HOST_E2E_FIXTURE is required");
}

const fixture = JSON.parse(fs.readFileSync(path.resolve(fixturePath), "utf8"));
```

In the new spec, swap `chromium` bootstrap for Playwright Test fixtures (`test`, `page`, `context`), but keep the same env-driven fixture loading.

**Login helper pattern** ([scripts/ci/accrue_host_browser_smoke.cjs](/Users/jon/projects/accrue/scripts/ci/accrue_host_browser_smoke.cjs#L16)):
```javascript
async function login(page, email) {
  await page.goto(`${baseURL}/users/log-in`);
  const csrfToken = await page.locator("meta[name='csrf-token']").getAttribute("content");
  const response = await page.request.post(`${baseURL}/users/log-in`, {
    form: {
      _csrf_token: csrfToken,
      "user[email]": email,
      "user[password]": fixture.password
    }
  });

  if (!response.ok()) {
    throw new Error(`login POST failed for ${email}: ${response.status()} ${response.statusText()}`);
  }

  await page.goto(`${baseURL}/`);
  await expect(page.getByRole("link", { name: "Go to billing" })).toBeVisible();
}
```

**LiveView readiness + accessible assertion style** ([scripts/ci/accrue_host_browser_smoke.cjs](/Users/jon/projects/accrue/scripts/ci/accrue_host_browser_smoke.cjs#L53)):
```javascript
await login(page, fixture.normal_email);
await expect(page.getByRole("link", { name: "Go to billing" })).toBeVisible();
await page.getByRole("link", { name: "Go to billing" }).click();
await expect(page.getByRole("heading", { name: "Choose a plan" })).toBeVisible();

await page.waitForFunction(
  () => Boolean(document.querySelector("[data-phx-main].phx-connected")),
  null,
  { timeout: 5000 }
);

await expect(page.getByText("No billing activity yet")).toBeVisible();
```

**Primary user flow pattern** ([scripts/ci/accrue_host_browser_smoke.cjs](/Users/jon/projects/accrue/scripts/ci/accrue_host_browser_smoke.cjs#L76)):
```javascript
await page.locator("[data-plan-id='price_basic'] button", { hasText: "Start subscription" }).click();
await expect(page.getByText("Subscription started.")).toBeVisible();
await expect(page.getByRole("heading", { name: "Current subscription" })).toBeVisible();
await expect(page.getByText("Basic (price_basic)")).toBeVisible();

await page.getByRole("button", { name: "Cancel subscription" }).click();
await expect(page.getByText("Cancel subscription: Confirm cancellation before ending access.")).toBeVisible();
await page.getByRole("button", { name: "Confirm cancellation" }).click();
await expect(page.getByText("Subscription canceled.")).toBeVisible();
```

**Admin replay flow pattern** ([scripts/ci/accrue_host_browser_smoke.cjs](/Users/jon/projects/accrue/scripts/ci/accrue_host_browser_smoke.cjs#L93)):
```javascript
await context.clearCookies();
await login(page, fixture.admin_email);

await page.goto(`${baseURL}/billing`);
await expect(page.getByText("Local billing projections at a glance")).toBeVisible();

await page.goto(`${baseURL}/billing/webhooks/${fixture.webhook_id}`);
await expect(page.getByRole("heading", { name: "invoice.payment_failed" })).toBeVisible();
await page.locator("[data-role='replay-single']").click();
await expect(page.getByText("Webhook replay requested.")).toBeVisible();

await page.goto(`${baseURL}/billing/events?source_webhook_event_id=${fixture.webhook_id}&actor_type=admin`);
await expect(page.getByRole("cell", { name: "admin.webhook.replay.completed" })).toBeVisible();
```

**Secondary analog for test organization:** `accrue_admin/e2e/phase7-uat.spec.js`

Use this file for Playwright Test structure, request-fixture seeding, and `test.describe` / `test.beforeEach` organization.

**Spec structure pattern** ([accrue_admin/e2e/phase7-uat.spec.js](/Users/jon/projects/accrue/accrue_admin/e2e/phase7-uat.spec.js#L1)):
```javascript
const { test, expect } = require("@playwright/test");

test.describe("Phase 7 browser UAT", () => {
  test.beforeEach(async ({ request }) => {
    await reset(request);
  });

  test("operator can replay one webhook and bulk requeue a DLQ slice", async ({ page, request }) => {
    const data = await seed(request, "operator-flows");
    await login(page, `/billing/webhooks/${data.single_webhook_id}`);
    await expect(page.getByRole("heading", { name: "invoice.payment_failed" })).toBeVisible();
  });
});
```

### `scripts/ci/accrue_host_uat.sh` (utility, batch)

**Analog:** `scripts/ci/accrue_host_uat.sh`

This script already owns host setup, drift checking, bounded boot, and browser orchestration. Phase 11 should preserve its staged shell structure and swap the raw browser runner for a Playwright command.

**Shell safety + repo bootstrap pattern** ([scripts/ci/accrue_host_uat.sh](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh#L19)):
```bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
host_dir="$repo_root/examples/accrue_host"
port="${ACCRUE_HOST_PORT:-4100}"
browser_port="${ACCRUE_HOST_BROWSER_PORT:-4101}"
```

**Installer + generated drift blocker pattern** ([scripts/ci/accrue_host_uat.sh](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh#L35)):
```bash
echo "--- documented setup: deps + installer idempotence ---"
mix deps.get
mix accrue.install --yes \
  --billable AccrueHost.Accounts.User \
  --billing-context AccrueHost.Billing \
  --admin-mount /billing \
  --webhook-path /webhooks/stripe

if [ "${ACCRUE_HOST_ALLOW_GENERATED_DRIFT:-}" != "1" ]; then
  if ! git -C "$repo_root" diff --quiet -- \
    examples/accrue_host \
    ':!examples/accrue_host/README.md'; then
    echo "Generated host-app drift detected after rerunning mix accrue.install."
    git -C "$repo_root" diff --stat -- \
      examples/accrue_host \
      ':!examples/accrue_host/README.md'
    exit 1
  fi
fi
```

**Compile + targeted suite + full suite pattern** ([scripts/ci/accrue_host_uat.sh](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh#L57)):
```bash
echo "--- compile gate ---"
mix compile --warnings-as-errors

echo "--- browser asset build ---"
mix assets.build

echo "--- host UAT test suite ---"
MIX_ENV=test mix ecto.drop --quiet || true
MIX_ENV=test mix ecto.create --quiet
MIX_ENV=test mix ecto.migrate --quiet
MIX_ENV=test mix test --warnings-as-errors \
  test/install_boundary_test.exs \
  test/accrue_host/billing_facade_test.exs \
  test/accrue_host_web/subscription_flow_test.exs \
  test/accrue_host_web/webhook_ingest_test.exs \
  test/accrue_host_web/admin_mount_test.exs \
  test/accrue_host_web/admin_webhook_replay_test.exs

echo "--- full host regression suite ---"
MIX_ENV=test mix test --warnings-as-errors
```

**Bounded server smoke + cleanup trap pattern** ([scripts/ci/accrue_host_uat.sh](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh#L82)):
```bash
log_file="$(mktemp)"
cleanup() {
  if [ -n "${server_pid:-}" ] && kill -0 "$server_pid" >/dev/null 2>&1; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" >/dev/null 2>&1 || true
  fi
  rm -f "$log_file"
}
trap cleanup EXIT

PORT="$port" MIX_ENV=dev mix phx.server >"$log_file" 2>&1 &
server_pid=$!
```

**Browser stage pattern to preserve while swapping in Playwright Test** ([scripts/ci/accrue_host_uat.sh](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh#L135)):
```bash
fixture_file="$(mktemp)"
browser_log_file="$(mktemp)"

MIX_ENV=test mix ecto.drop --quiet || true
MIX_ENV=test mix ecto.create --quiet
MIX_ENV=test mix ecto.migrate --quiet
ACCRUE_HOST_E2E_FIXTURE="$fixture_file" MIX_ENV=test mix run "$repo_root/scripts/ci/accrue_host_seed_e2e.exs"

PORT="$browser_port" PHX_SERVER=true MIX_ENV=test mix phx.server >"$browser_log_file" 2>&1 &
browser_server_pid=$!
```

Phase 11 should keep this seeded-fixture and server-log pattern, then run host Playwright via `npm run e2e` so `ci.yml` can upload the generated report plus the captured server log on failure.

## Shared Patterns

### Playwright Failure Artifacts
**Source:** [accrue_admin/playwright.config.js](/Users/jon/projects/accrue/accrue_admin/playwright.config.js#L13), [.github/workflows/accrue_admin_browser.yml](/Users/jon/projects/accrue/.github/workflows/accrue_admin_browser.yml#L78)
**Apply to:** `examples/accrue_host/playwright.config.js`, `.github/workflows/ci.yml`
```javascript
reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : [["list"]],
use: {
  baseURL,
  trace: "retain-on-failure",
  screenshot: "only-on-failure"
}
```

```yaml
- name: Upload Playwright report
  if: failure()
  uses: actions/upload-artifact@v7

- name: Upload Playwright traces
  if: failure()
  uses: actions/upload-artifact@v7
```

### Host Browser Fixture Seeding
**Source:** [scripts/ci/accrue_host_uat.sh](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh#L158), [scripts/ci/accrue_host_seed_e2e.exs](/Users/jon/projects/accrue/scripts/ci/accrue_host_seed_e2e.exs#L10)
**Apply to:** `scripts/ci/accrue_host_uat.sh`, `examples/accrue_host/e2e/phase11-host-gate.spec.js`
```bash
fixture_file="$(mktemp)"
ACCRUE_HOST_E2E_FIXTURE="$fixture_file" MIX_ENV=test mix run "$repo_root/scripts/ci/accrue_host_seed_e2e.exs"
```

```elixir
password = "hello world!"
fixture_path = System.fetch_env!("ACCRUE_HOST_E2E_FIXTURE")
```

### Accessible Browser Assertions
**Source:** [scripts/ci/accrue_host_browser_smoke.cjs](/Users/jon/projects/accrue/scripts/ci/accrue_host_browser_smoke.cjs#L53), [accrue_admin/e2e/phase7-uat.spec.js](/Users/jon/projects/accrue/accrue_admin/e2e/phase7-uat.spec.js#L31)
**Apply to:** `examples/accrue_host/e2e/phase11-host-gate.spec.js`
```javascript
await expect(page.getByRole("heading", { name: "Choose a plan" })).toBeVisible();
await expect(page.getByText("No billing activity yet")).toBeVisible();
await expect(page.getByRole("heading", { name: "invoice.payment_failed" })).toBeVisible();
```

Prefer `getByRole`, `getByText`, and existing accessible copy. Only keep `data-plan-id` / `data-role` selectors where the UI already exposes them as stable action hooks.

### Drift and Warning Blocking
**Source:** [scripts/ci/accrue_host_uat.sh](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh#L44), [.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L107)
**Apply to:** `.github/workflows/ci.yml`, `scripts/ci/accrue_host_uat.sh`
```bash
if ! git -C "$repo_root" diff --quiet -- \
  examples/accrue_host \
  ':!examples/accrue_host/README.md'; then
  exit 1
fi
```

```yaml
- name: Accrue compile
  run: cd accrue && mix compile --warnings-as-errors

- name: Accrue admin docs
  run: cd accrue_admin && MIX_ENV=dev mix docs --warnings-as-errors
```

### Keep Live Stripe Advisory
**Source:** [.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L222)
**Apply to:** `.github/workflows/ci.yml`
```yaml
if: github.event_name == 'workflow_dispatch' || github.event_name == 'schedule'
continue-on-error: true
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `scripts/ci/annotation_sweep.sh` | utility | event-driven | No existing script in `scripts/ci/` or `.github/workflows/` queries GitHub Actions jobs/check-run annotations. If the planner keeps the optional sweep, it should use `11-RESEARCH.md` as the source pattern and treat this as a new script. |

## Metadata

**Analog search scope:** `.github/workflows/`, `scripts/ci/`, `examples/accrue_host/`, `accrue_admin/`
**Files scanned:** 12 primary files plus repository-wide grep for annotation/artifact patterns
**Pattern extraction date:** 2026-04-16
