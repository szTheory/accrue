# Phase 15: Trust Hardening - Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 14
**Analogs found:** 13 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md` | config | request-response | `.planning/phases/14-adoption-front-door/14-SECURITY.md` | role-match |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `scripts/ci/accrue_host_uat.sh` | utility | batch | `scripts/ci/accrue_host_uat.sh` | exact |
| `scripts/ci/verify_package_docs.sh` | utility | batch | `scripts/ci/verify_package_docs.sh` | exact |
| `examples/accrue_host/mix.exs` | config | batch | `examples/accrue_host/mix.exs` | exact |
| `examples/accrue_host/playwright.config.js` | config | request-response | `accrue_admin/playwright.config.js` | role-match |
| `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` | test | request-response | `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` | exact |
| `scripts/ci/accrue_host_seed_e2e.exs` | utility | transform | `scripts/ci/accrue_host_seed_e2e.exs` | exact |
| `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` | test | request-response | `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` | exact |
| `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` | test | request-response | `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` | exact |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | test | batch | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | exact |
| `accrue/test/accrue/docs/release_guidance_test.exs` | test | request-response | `accrue/test/accrue/docs/release_guidance_test.exs` | exact |
| `RELEASING.md` | config | request-response | `RELEASING.md` | exact |
| `CONTRIBUTING.md` | config | request-response | `CONTRIBUTING.md` | exact |

## Pattern Assignments

### `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md` (config, request-response)

**Analog:** `.planning/phases/14-adoption-front-door/14-SECURITY.md`

**Frontmatter + verification summary pattern** ([14-SECURITY.md](/Users/jon/projects/accrue/.planning/phases/14-adoption-front-door/14-SECURITY.md#L1)):
```md
---
phase: 14
slug: adoption-front-door
status: verified
threats_open: 0
asvs_level: default
created: 2026-04-17
---
```

**Boundary table pattern** ([14-SECURITY.md](/Users/jon/projects/accrue/.planning/phases/14-adoption-front-door/14-SECURITY.md#L16)):
```md
## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| public repo visitor -> repository docs | ... | ... |
```

**Evidence table pattern** ([14-SECURITY.md](/Users/jon/projects/accrue/.planning/phases/14-adoption-front-door/14-SECURITY.md#L36)):
```md
| Threat ID | Category | Component | Disposition | Status | Evidence |
|-----------|----------|-----------|-------------|--------|----------|
| T-14-03-04 | D | RELEASING.md, scripts/ci/verify_package_docs.sh | mitigate | CLOSED | ... |
```

Use this structure for a boring evidence document: boundaries, evidence links, accepted host-owned assumptions, and concrete verification runs.

---

### `.github/workflows/ci.yml` (config, batch)

**Analog:** `.github/workflows/ci.yml`

**Matrix include + advisory cells pattern** ([ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L41)):
```yaml
strategy:
  fail-fast: false
  matrix:
    include:
      - elixir: '1.17.3'
        otp: '27.0'
        sigra: 'off'
        opentelemetry: 'off'
        continue-on-error: false
...
continue-on-error: ${{ matrix.continue-on-error }}
```

**Host integration gate pattern** ([ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L247)):
```yaml
host-integration:
  name: Host integration
  needs: [admin-drift-docs]
  runs-on: ubuntu-24.04
  env:
    MIX_ENV: test
    PGUSER: postgres
    PGPASSWORD: postgres
    PGHOST: localhost
    ACCRUE_HOST_PORT: 4100
    ACCRUE_HOST_BROWSER_PORT: 4101
```

**Failure-only artifact upload pattern** ([ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L321)):
```yaml
- name: Upload Playwright report
  if: failure()
  uses: actions/upload-artifact@v7

- name: Upload Playwright traces
  if: failure()
  uses: actions/upload-artifact@v7
```

**Advisory/manual job labeling pattern** ([ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L369)):
```yaml
live-stripe:
  name: Live Stripe (advisory)
  if: github.event_name == 'workflow_dispatch' || github.event_name == 'schedule'
  continue-on-error: true
```

Extend this file in place. Do not create a second compatibility system.

---

### `scripts/ci/accrue_host_uat.sh` (utility, batch)

**Analog:** `scripts/ci/accrue_host_uat.sh`

**Thin wrapper pattern** ([accrue_host_uat.sh](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh#L18)):
```bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
host_dir="$repo_root/examples/accrue_host"
port="${ACCRUE_HOST_PORT:-4100}"
browser_port="${ACCRUE_HOST_BROWSER_PORT:-4101}"
```

**Environment passthrough pattern** ([accrue_host_uat.sh](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh#L36)):
```bash
export ACCRUE_HOST_PORT="$port"
export ACCRUE_HOST_BROWSER_PORT="$browser_port"
export ACCRUE_HOST_SKIP_DEV_BOOT="${ACCRUE_HOST_SKIP_DEV_BOOT:-}"
export ACCRUE_HOST_SKIP_BROWSER="${ACCRUE_HOST_SKIP_BROWSER:-}"
export ACCRUE_HOST_ALLOW_GENERATED_DRIFT="${ACCRUE_HOST_ALLOW_GENERATED_DRIFT:-}"
export ACCRUE_HOST_BROWSER_LOG="${ACCRUE_HOST_BROWSER_LOG:-}"
```

**Delegation pattern** ([accrue_host_uat.sh](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh#L43)):
```bash
echo "--- delegating to host-local mix verify.full ---"
cd "$host_dir"
mix verify.full
```

Keep this wrapper thin. Phase 15 should add trust checks by extending the host-local contract, not by replacing it.

---

### `scripts/ci/verify_package_docs.sh` (utility, batch)

**Analog:** `scripts/ci/verify_package_docs.sh`

**Guard helper pattern** ([verify_package_docs.sh](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh#L9)):
```bash
fail() {
  echo "package docs verification failed: $*" >&2
  exit 1
}

require_fixed() {
  local file=$1
  local needle=$2

  grep -Fq "$needle" "$file" || fail "$file is missing: $needle"
}
```

**Negative matcher pattern** ([verify_package_docs.sh](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh#L37)):
```bash
require_absent_regex() {
  local file=$1
  local pattern=$2

  if grep -Eq "$pattern" "$file"; then
    fail "$file must not match: $pattern"
  fi
}
```

**Fixed-invariant scan pattern** ([verify_package_docs.sh](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh#L106)):
```bash
require_fixed "$ROOT_DIR/scripts/ci/accrue_host_uat.sh" "mix verify.full"
require_fixed "$ROOT_DIR/RELEASING.md" "required deterministic gate"
require_fixed "$ROOT_DIR/RELEASING.md" "provider-parity checks"
```

Use this same helper style for any new trust-language or leakage allowlist checks.

---

### `examples/accrue_host/mix.exs` (config, batch)

**Analog:** `examples/accrue_host/mix.exs`

**Preferred env + alias pattern** ([mix.exs](/Users/jon/projects/accrue/examples/accrue_host/mix.exs#L28)):
```elixir
def cli do
  [
    preferred_envs: [precommit: :test, verify: :test, "verify.full": :test]
  ]
end
```

**Verification composition pattern** ([mix.exs](/Users/jon/projects/accrue/examples/accrue_host/mix.exs#L115)):
```elixir
"verify.full": [
  "verify.install",
  "verify",
  "compile --warnings-as-errors",
  "assets.build",
  verify_regression_command(),
  verify_dev_boot_command(),
  verify_browser_command()
]
```

**Shell-script-in-alias pattern** ([mix.exs](/Users/jon/projects/accrue/examples/accrue_host/mix.exs#L297)):
```elixir
defp bash_command(script) do
  escaped =
    script
    |> String.trim()
    |> String.replace("'", ~s('"'"'))

  "cmd bash -lc '#{escaped}'"
end
```

Add any trust smoke work as another composed alias helper, not as ad hoc commands in CI.

---

### `examples/accrue_host/playwright.config.js` (config, request-response)

**Analog:** `accrue_admin/playwright.config.js`

**Shared Playwright defaults pattern** ([accrue_admin/playwright.config.js](/Users/jon/projects/accrue/accrue_admin/playwright.config.js#L7)):
```javascript
module.exports = defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: false,
  workers: 1,
  reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : [["list"]],
  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure"
  }
});
```

**Responsive project matrix pattern** ([accrue_admin/playwright.config.js](/Users/jon/projects/accrue/accrue_admin/playwright.config.js#L25)):
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
]
```

Mirror the admin package’s desktop+mobile project split inside the host example config.

---

### `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` (test, request-response)

**Analog:** `examples/accrue_host/e2e/phase13-canonical-demo.spec.js`

**Fixture loading + login helper pattern** ([phase13-canonical-demo.spec.js](/Users/jon/projects/accrue/examples/accrue_host/e2e/phase13-canonical-demo.spec.js#L7)):
```javascript
function readFixture() {
  const fixturePath = process.env.ACCRUE_HOST_E2E_FIXTURE;
  if (!fixturePath) {
    throw new Error("ACCRUE_HOST_E2E_FIXTURE is required");
  }
  return JSON.parse(fs.readFileSync(path.resolve(fixturePath), "utf8"));
}
```

**Axe blocking-only assertion pattern** ([phase13-canonical-demo.spec.js](/Users/jon/projects/accrue/examples/accrue_host/e2e/phase13-canonical-demo.spec.js#L70)):
```javascript
const results = await new AxeBuilder({ page }).analyze();
const blocking = results.violations.filter((violation) =>
  ["critical", "serious"].includes(violation.impact || "")
);

expect(blocking, `${label} has critical/serious accessibility violations`).toEqual([]);
```

**Compact retained screenshot pattern** ([phase13-canonical-demo.spec.js](/Users/jon/projects/accrue/examples/accrue_host/e2e/phase13-canonical-demo.spec.js#L79)):
```javascript
const screenshotDir = path.join(process.cwd(), "test-results", "phase13-screenshots");
fs.mkdirSync(screenshotDir, { recursive: true });
await page.screenshot({ path: screenshotPath, fullPage: true });
await testInfo.attach(name, { path: screenshotPath, contentType: "image/png" });
```

**Canonical seeded admin-flow assertions** ([phase13-canonical-demo.spec.js](/Users/jon/projects/accrue/examples/accrue_host/e2e/phase13-canonical-demo.spec.js#L153)):
```javascript
await page.goto("/billing");
await expect(page.getByText("Local billing projections at a glance")).toBeVisible();
await assertNoSeriousAccessibilityViolations(page, "admin dashboard");

await page.goto(`/billing/webhooks/${fixture.webhook_id}`);
await expect(page.getByRole("heading", { name: "invoice.payment_failed" })).toBeVisible();

await page.goto(`/billing/events?source_webhook_event_id=${fixture.webhook_id}&actor_type=admin`);
await expect(page.getByRole("cell", { name: "admin.webhook.replay.completed" })).toBeVisible();
```

Extend this spec instead of introducing a separate visual-regression suite.

---

### `scripts/ci/accrue_host_seed_e2e.exs` (utility, transform)

**Analog:** `scripts/ci/accrue_host_seed_e2e.exs`

**Alias-heavy script pattern** ([accrue_host_seed_e2e.exs](/Users/jon/projects/accrue/scripts/ci/accrue_host_seed_e2e.exs#L1)):
```elixir
alias Accrue.Billing.Customer
alias Accrue.Billing.Subscription
alias Accrue.Billing.SubscriptionItem
alias Accrue.Events
alias Accrue.Webhook.WebhookEvent
alias AccrueHost.Accounts
alias AccrueHost.Accounts.User
alias AccrueHost.Repo
```

**Deterministic fixture-seeding pattern** ([accrue_host_seed_e2e.exs](/Users/jon/projects/accrue/scripts/ci/accrue_host_seed_e2e.exs#L82)):
```elixir
webhook =
  %{
    processor: "stripe",
    processor_event_id: "evt_host_browser_replay",
    type: "invoice.payment_failed",
    livemode: false,
    endpoint: :default,
    status: :received,
    raw_body: Jason.encode!(%{...}),
    received_at: DateTime.utc_now(),
    data: %{...}
  }
  |> WebhookEvent.ingest_changeset()
  |> Repo.insert!()
  |> Ecto.Changeset.change(%{status: :dead})
  |> Repo.update!()
```

**Fixture handoff pattern** ([accrue_host_seed_e2e.exs](/Users/jon/projects/accrue/scripts/ci/accrue_host_seed_e2e.exs#L162)):
```elixir
fixture = %{
  password: password,
  normal_email: normal_user.email,
  admin_email: admin_user.email,
  webhook_id: webhook.id,
  subscription_id: subscription.id,
  first_run_webhook: %{...}
}

File.mkdir_p!(Path.dirname(fixture_path))
File.write!(fixture_path, Jason.encode!(fixture, pretty: true))
```

Keep Phase 15 fixture output compact and secret-safe. Add only the IDs and timings needed by browser/perf smoke.

---

### `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` (test, request-response)

**Analog:** `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs`

**Imports + proof-case pattern** ([webhook_ingest_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs#L1)):
```elixir
defmodule AccrueHostWeb.WebhookIngestTest do
  use AccrueHost.HostFlowProofCase, async: false

  import Ecto.Query

  alias Accrue.Billing.Subscription
  alias Accrue.Events.Event
  alias Accrue.Webhook.DispatchWorker
  alias Accrue.Webhook.WebhookEvent
```

**Signed webhook proof pattern** ([webhook_ingest_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs#L17)):
```elixir
signature = LatticeStripe.Webhook.generate_test_signature(payload, @webhook_secret)

first_conn = post_webhook(payload, signature)
assert first_conn.status == 200
assert %{"ok" => true} = Jason.decode!(first_conn.resp_body)
assert Repo.aggregate(WebhookEvent, :count) == 1
assert Repo.aggregate(Oban.Job, :count) == 1
```

**Security rejection pattern** ([webhook_ingest_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs#L86)):
```elixir
tampered_payload = String.replace(payload, "sub_tampered", "sub_tampered_changed")
conn = post_webhook(tampered_payload, signature)

assert conn.status == 400
assert %{"error" => "signature_verification_failed"} = Jason.decode!(conn.resp_body)
assert Repo.aggregate(WebhookEvent, :count) == 0
```

Use this as the shape for any seeded webhook latency assertion added to host proofs.

---

### `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` (test, request-response)

**Analog:** `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs`

**LiveView proof imports pattern** ([admin_webhook_replay_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs#L1)):
```elixir
defmodule AccrueHostWeb.AdminWebhookReplayTest do
  use AccrueHost.HostFlowProofCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest
```

**Host-authenticated admin flow pattern** ([admin_webhook_replay_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs#L92)):
```elixir
conn = log_in_user(conn, admin_user)

assert {:ok, _subscription_view, subscription_html} =
         live(conn, "/billing/subscriptions/#{subscription.id}")
```

**Replay + audit assertion pattern** ([admin_webhook_replay_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs#L114)):
```elixir
{:ok, replay_view, _html} = live(conn, "/billing/webhooks/#{webhook.id}")

replay_html = render_click(element(replay_view, "[data-role='replay-single']"))
assert replay_html =~ "Webhook replay requested."

updated = Repo.get!(WebhookEvent, webhook.id)
assert updated.status == :received
```

This is the nearest analog for admin responsiveness and replay-state trust checks.

---

### `accrue/test/accrue/docs/package_docs_verifier_test.exs` (test, batch)

**Analog:** `accrue/test/accrue/docs/package_docs_verifier_test.exs`

**Shell-script verification pattern** ([package_docs_verifier_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs#L4)):
```elixir
@script_path "../scripts/ci/verify_package_docs.sh"

test "package docs verifier succeeds" do
  {output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)
  assert status == 0
end
```

**Drift-fixture failure test pattern** ([package_docs_verifier_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs#L21)):
```elixir
tmp_dir = Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")
File.rm_rf!(tmp_dir)
on_exit(fn -> File.rm_rf(tmp_dir) end)
...
{output, status} =
  System.cmd("bash", [@script_path], stderr_to_stdout: true, env: [{"ROOT_DIR", tmp_dir}])

assert status != 0
assert output =~ "RELEASING.md"
```

Use the same temp-dir drift-fixture pattern for any new trust-language or leakage scan script behavior.

---

### `accrue/test/accrue/docs/release_guidance_test.exs` (test, request-response)

**Analog:** `accrue/test/accrue/docs/release_guidance_test.exs`

**Multi-file wording contract pattern** ([release_guidance_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/release_guidance_test.exs#L4)):
```elixir
@releasing_path Path.expand("../../../../RELEASING.md", __DIR__)
@guide_path Path.expand("../../../../guides/testing-live-stripe.md", __DIR__)
@contributing_path Path.expand("../../../../CONTRIBUTING.md", __DIR__)
```

**Positive/negative wording assertions** ([release_guidance_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/release_guidance_test.exs#L8)):
```elixir
assert releasing =~ "required deterministic gate"
assert releasing =~ "provider-parity checks"
assert releasing =~ "advisory/manual before shipping your app"

refute releasing =~ "live Stripe is required for standard releases"
```

Follow this style for Phase 15 release-gate clarity and trust-artifact references.

---

### `RELEASING.md` (config, request-response)

**Analog:** `RELEASING.md`

**Lane taxonomy pattern** ([RELEASING.md](/Users/jon/projects/accrue/RELEASING.md#L5)):
```md
- `Canonical local demo: Fake` is the required deterministic gate ...
- `Provider parity: Stripe test mode` is for optional/manual provider-parity checks.
- `Advisory/manual: live Stripe` is for final app-level confidence ...
```

**Required-first sequencing pattern** ([RELEASING.md](/Users/jon/projects/accrue/RELEASING.md#L65)):
```md
## Verification before publishing

Run the required deterministic gate first:
```

Extend this file with trust-gate entries and artifact references, but keep the required/advisory taxonomy unchanged.

---

### `CONTRIBUTING.md` (config, request-response)

**Analog:** `CONTRIBUTING.md`

**Contributor guidance pattern** ([CONTRIBUTING.md](/Users/jon/projects/accrue/CONTRIBUTING.md#L42)):
```md
## Running the release gate locally

Run the release gate from each package directory before opening a PR:
```

**Credential-handling wording pattern** ([CONTRIBUTING.md](/Users/jon/projects/accrue/CONTRIBUTING.md#L65)):
```md
That lane is advisory/manual, not part of the required deterministic release gate,
and it exists to catch provider-parity drift rather than replace Fake.
Please keep real credentials out of shell history and logs.
```

Use the same short, imperative language for any new trust-gate contributor steps.

## Shared Patterns

### Authentication And Host-Owned Session Boundary
**Source:** [accrue_admin/guides/admin_ui.md](/Users/jon/projects/accrue/accrue_admin/guides/admin_ui.md#L48) and [admin_webhook_replay_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs#L92)  
**Apply to:** Trust review artifact, browser specs, admin-flow proofs

```elixir
accrue_admin "/billing",
  session_keys: [:user_token],
  on_mount: [{MyAppWeb.UserAuth, :mount_current_user}]
```

```elixir
conn = log_in_user(conn, admin_user)
assert {:ok, _view, _html} = live(conn, "/billing/webhooks/#{webhook.id}")
```

Document admin auth as host-owned. Tests should authenticate through the host session boundary, not internal package shortcuts.

### Failure-Only Artifact Retention
**Source:** [examples/accrue_host/playwright.config.js](/Users/jon/projects/accrue/examples/accrue_host/playwright.config.js#L16) and [ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L321)  
**Apply to:** Browser coverage, trust artifacts, CI uploads

```javascript
use: {
  baseURL,
  trace: "retain-on-failure",
  screenshot: "only-on-failure"
}
```

```yaml
- name: Upload Playwright report
  if: failure()
- name: Upload Playwright traces
  if: failure()
```

Success artifacts should stay compact. Rich artifacts belong on failure paths.

### Secret/PII Redaction Expectations
**Source:** [errors_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/errors_test.exs#L67), [otel_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/telemetry/otel_test.exs#L12), and [issue_templates_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/issue_templates_test.exs#L56)  
**Apply to:** Leakage review tests, docs scanners, trust review artifact

```elixir
err = Accrue.CardError.exception(code: "x", processor_error: %{secret: 1})
refute Exception.message(err) =~ "secret"
```

```elixir
refute Map.has_key?(attrs, "raw_body")
refute Map.has_key?(attrs, "api_key")
refute Map.has_key?(attrs, "webhook_secret")
refute Map.has_key?(attrs, "stripe_secret_key")
```

```elixir
Enum.each(@warning_phrases, fn phrase ->
  assert contents =~ phrase
end)
```

Keep actionable diagnostics, but assert on key names and absence of raw secret-bearing values.

### Docs Drift And Release-Language Guardrails
**Source:** [verify_package_docs.sh](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh#L23), [package_docs_verifier_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs#L21), and [release_guidance_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/release_guidance_test.exs#L8)  
**Apply to:** `RELEASING.md`, `CONTRIBUTING.md`, trust-review links, issue template wording

```bash
require_fixed "$ROOT_DIR/RELEASING.md" "required deterministic gate"
require_fixed "$ROOT_DIR/RELEASING.md" "provider-parity checks"
```

```elixir
assert output =~ "RELEASING.md"
assert output =~ "provider-parity checks"
```

```elixir
refute releasing =~ "live Stripe is required for standard releases"
```

Phase 15 should extend these wording checks rather than inventing a second docs verifier.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `scripts/ci/accrue_host_trust_smoke.exs` or equivalent new performance-summary helper | utility | transform | No current script emits compact webhook-ingest/admin-latency budget summaries; closest pieces are seeded fixture setup, host proofs, and browser smoke, but there is no exact existing performance-evidence analog. |

## Metadata

**Analog search scope:** `.github/workflows`, `scripts/ci`, `examples/accrue_host`, `accrue/test/accrue/docs`, `accrue/test/accrue`, `accrue_admin`, `.planning/phases/14-adoption-front-door`  
**Files scanned:** 20+ targeted files via `rg` + direct reads  
**Pattern extraction date:** 2026-04-17
