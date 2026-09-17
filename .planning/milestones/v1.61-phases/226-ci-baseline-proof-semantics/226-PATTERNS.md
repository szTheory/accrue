# Phase 226: CI Baseline & Proof Semantics - Pattern Map

**Mapped:** 2026-08-11  
**Files analyzed:** 16  
**Analogs found:** 15 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/ci/collect_ci_baseline.mjs` | utility | transform | `scripts/ci/verify_executable_uat_contract.mjs` | role-match |
| `scripts/ci/render_ci_baseline.mjs` | utility | transform | `scripts/ci/verify_executable_uat_contract.mjs` | role-match |
| `scripts/ci/verify_ci_baseline.mjs` | test | transform | `scripts/ci/verify_executable_uat_contract.mjs` | exact |
| `scripts/ci/verify_provider_proof.mjs` | test | transform | `scripts/ci/verify_executable_uat_contract.mjs` | role-match |
| `scripts/ci/render_provider_summary.mjs` | utility | transform | `.github/workflows/ci.yml` summary block | role-match |
| `scripts/ci/verify_ci_setup_diagnostics.sh` | test | request-response | `scripts/ci/verify_phase225_required_lane_evidence.sh` | role-match |
| `scripts/ci/accrue_host_verify_browser.sh` | utility | request-response | itself (current host proof contract) | exact modification target |
| `scripts/ci/accrue_host_uat.sh` | utility | request-response | itself (current wrapper/owner boundary) | exact modification target |
| `.github/workflows/ci.yml` | config | event-driven | existing `host-integration` / `live-stripe` jobs | exact modification target |
| `scripts/ci/README.md` | documentation | request-response | its Phase 225 triage and host-integration sections | exact modification target |
| `guides/testing-live-stripe.md` | documentation | request-response | its existing provider-parity sections | exact modification target |
| `examples/accrue_host/README.md` | documentation | request-response | its `Proof and verification` section | exact modification target |
| `.planning/phases/226-ci-baseline-proof-semantics/schema-v1.json` | config | transform | none | no close analog |
| `.planning/phases/226-ci-baseline-proof-semantics/fixtures/*` | test fixture | transform | `verify_executable_uat_contract.mjs` `selfTest()` | role-match |
| `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson` | data artifact | batch | Phase 225 incident ledger facts | partial |
| `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md` | documentation | transform | `225-CI-INCIDENTS.md` | role-match |

## Pattern Assignments

### `scripts/ci/collect_ci_baseline.mjs`, `render_ci_baseline.mjs`, and `verify_ci_baseline.mjs` (utility/test, transform)

**Analog:** `scripts/ci/verify_executable_uat_contract.mjs`

Use a dependency-free ESM Node script: built-in imports first, small named pure helpers, a `main()` argument dispatcher, and one top-level error boundary. The collector may use `gh api` for structured Actions input, but validators/renderers should read only local JSON/NDJSON fixtures and records.

**Imports and failure boundary** (`scripts/ci/verify_executable_uat_contract.mjs:3-10, 353-386`):

```javascript
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

function fail(message) {
  throw new Error(message);
}

function main() {
  const args = process.argv.slice(2);
  // parse explicit flags; print one deterministic PASS line
}

try {
  main();
} catch (error) {
  console.error(`executable UAT contract: FAIL: ${error.message}`);
  process.exitCode = 1;
}
```

**Deterministic validation pattern** (`scripts/ci/verify_executable_uat_contract.mjs:130-199`):

```javascript
for (const file of summaries) {
  const source = fs.readFileSync(path.join(phaseDir, file), "utf8");
  const metadata = frontmatter(source, file);
  if (scalar(metadata, "status") !== "complete") continue;
  // reject each missing or nonconforming invariant with a source-specific message
}

if (uat !== expectedUat) {
  fail(`${uatFile}: content does not exactly match executable SUMMARY coverage; regenerate with --write`);
}
```

**Fixture/self-test pattern** (`scripts/ci/verify_executable_uat_contract.mjs:268-351`):

```javascript
const temp = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-executable-uat-"));
try {
  // write a valid minimal fixture, assert acceptance, then mutate one invariant
  // per negative control and assert the exact rejection.
} finally {
  fs.rmSync(temp, { recursive: true, force: true });
}
```

Apply this to frozen fixture coverage: successful first attempt, failure, cancellation, rerun, provider `non_run`, provider `misconfigured`, and one repeated matrix-cell signature. Keep raw facts, calculated facts, and resulting claims separate in helpers; validators must test arithmetic, enums, allowlists, fingerprints, rerun grouping, and root-signature grouping independently.

### `scripts/ci/render_provider_summary.mjs` and `.github/workflows/ci.yml` (utility/config, transform/event-driven)

**Analog:** `.github/workflows/ci.yml` `host-integration`, `playwright-e2e`, and `live-stripe` blocks.

Preserve workflow identity, trigger selection, job graph, runner image, cache declarations, matrix, and artifact policy. Add only the selected-lane proof producer/record, `if: always()` summary consumer, and privacy-safe artifact/record plumbing. Do not make `success` or `skipped` a substitute for proof.

**Stable trigger and permissions convention** (`.github/workflows/ci.yml:19-33`):

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch: {}
  schedule:
    - cron: '0 6 * * *'

permissions:
  actions: read
  checks: read
  contents: read
```

**Host-owned proof called after explicit CI provisioning** (`.github/workflows/ci.yml:933-976`):

```yaml
- name: Set up Node
  uses: actions/setup-node@v6
  with:
    node-version: '22'
    cache: npm
    cache-dependency-path: examples/accrue_host/package-lock.json

- name: Install browser deps
  run: |
    cd examples/accrue_host && npm ci
    cd assets && npm ci

- name: Install Chromium
  run: cd examples/accrue_host && npm run e2e:install

- name: Run host integration gate
  run: bash scripts/ci/accrue_host_uat.sh
```

**Always-run artifact evidence convention** (`.github/workflows/ci.yml:980-1012`):

```yaml
- name: Upload Playwright report
  if: failure()
  uses: actions/upload-artifact@v7
  with:
    name: accrue-host-playwright-report
    path: examples/accrue_host/playwright-report
    if-no-files-found: ignore

- name: Upload Phase 15 trust screenshots
  if: always()
  uses: actions/upload-artifact@v7
  with:
    name: accrue-host-phase15-screenshots
    path: examples/accrue_host/test-results/phase15-trust
    if-no-files-found: ignore
```

**Provider trigger boundary to retain** (`.github/workflows/ci.yml:1224-1280`):

```yaml
live-stripe:
  name: Stripe test-mode parity (mandatory periodic)
  runs-on: ubuntu-24.04
  if: github.event_name == 'workflow_dispatch' || github.event_name == 'schedule'
  # existing test-mode secrets stay Actions-only
```

The summary renderer should read a redacted record and emit literal `policy`, `proof_state`, reason, raw conclusion, counts, freshness, evidence link, and one command into `$GITHUB_STEP_SUMMARY`; use the existing `if: always()` idiom above. PR/push summaries must explicitly write `non_run`, not infer or imply live proof.

### `scripts/ci/verify_ci_setup_diagnostics.sh` (test, request-response)

**Analog:** `scripts/ci/verify_phase225_required_lane_evidence.sh`

Use strict Bash with explicit repository-relative source selection, small named check helpers, fixed expectations, a preflight command check, and one terse success line. This verifier should statically/fixture-check stable setup codes, owner, narrow command, and artifact/log location without exposing environment values or credentials.

**Shell contract skeleton** (`scripts/ci/verify_phase225_required_lane_evidence.sh:1-18`):

```bash
#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() {
  echo "verify_phase225_required_lane_evidence: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is required"
}
```

**Exact contract checking style** (`scripts/ci/verify_phase225_required_lane_evidence.sh:54-96`):

```bash
for field in '**What failed:**' '**Classification:**' '**Next command:**' '**Evidence:**'; do
  printf '%s\n' "$section" | rg -Fq "$field" ||
    fail "$incident_id is missing required field: $field"
done
```

### `scripts/ci/accrue_host_verify_browser.sh` and `scripts/ci/accrue_host_uat.sh` (utility, request-response)

**Analog:** their current scripts; preserve their host boundary and lifecycle shape.

Add a small preflight/diagnostic adapter before each opaque prerequisite, not a second browser path. It must classify the locked code, print `fact`, `owner`, exact next command, and retained log/artifact location, then exit nonzero. CI continues explicitly provisioning Node/Linux browser dependencies before invoking this same host-owned contract.

**Lifecycle, cleanup, and failure-only log pattern** (`scripts/ci/accrue_host_verify_browser.sh:19-56`):

```bash
fixture_file="$(mktemp)"
browser_log_file="${ACCRUE_HOST_BROWSER_LOG:-$(mktemp)}"
browser_failed=0

cleanup() {
  if [ -n "${browser_server_pid:-}" ] && kill -0 "$browser_server_pid" >/dev/null 2>&1; then
    stop_process_tree "$browser_server_pid"
  fi
  rm -f "$fixture_file"
  if [ -z "${ACCRUE_HOST_BROWSER_LOG:-}" ] && [ "$browser_failed" != "1" ]; then
    rm -f "$browser_log_file"
  fi
}
trap cleanup EXIT
trap 'browser_failed=1; exit 130' INT TERM
```

**Stable host setup/proof sequence** (`scripts/ci/accrue_host_verify_browser.sh:61-104`):

```bash
MIX_ENV=test mix ecto.create --quiet
MIX_ENV=test mix ecto.migrate --quiet
ACCRUE_HOST_E2E_FIXTURE="$fixture_file" MIX_ENV=test mix run "$repo_root/scripts/ci/accrue_host_seed_e2e.exs"

npm ci
npm run e2e:install

PORT="$browser_port" PHX_SERVER=true MIX_ENV=test mix phx.server >"$browser_log_file" 2>&1 &
browser_server_pid=$!
```

**Repo-root delegation boundary** (`scripts/ci/accrue_host_uat.sh:19-52`):

```bash
repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
host_dir="$repo_root/examples/accrue_host"

echo "[host-integration] entry=accrue_host_uat delegating_to=mix_verify.full" >&2
cd "$host_dir"
if ! mix verify.full; then
  echo "FAILED_GATE=host-integration" >&2
  exit 1
fi
```

Keep `examples/accrue_host/playwright.config.js:18-43` unchanged in its proof semantics: `fullyParallel: false`, one worker, `trace: "retain-on-failure"`, `screenshot: "only-on-failure"`, and the host’s configured web-server contract.

### Phase-local schema, fixtures, NDJSON, and baseline Markdown (config/test fixture/data/documentation, transform/batch)

**Analog:** `.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md`

Use a compact, privacy-safe, action-first record rather than a raw-log dump. The Markdown should lead each item/cohort with what happened, literal state, owner, exact next command, and immutable run/job/artifact links; retain raw forensic material only in Actions artifacts.

**Incident grammar** (`.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md:7-22`):

```markdown
**What failed:** `Accrue.Webhook.IngestTest` asserted suite-global row counts...

**Classification:** test-isolation / over-broad-observation; high confidence.

**Next command:** `cd accrue && mix test test/accrue/webhook/ingest_test.exs --warnings-as-errors`

**Evidence:** [run 31289155535](https://github.com/szTheory/accrue/actions/runs/31289155535)...

- **Normalized signature:** ...
- **Affected cells:** ...
- **Canonical owner and repair surface:** ...
```

**Truth boundary and raw-artifact convention** (`.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md:3-5`):

```markdown
This is the privacy-safe causal index for the active required-lane signatures.
Raw logs, browser reports, traces, screenshots, server output, payloads, secrets,
and user data remain GitHub Actions artifacts.
```

For `schema-v1.json`, there is no close repository analog: make it an explicit small allowlist/enum contract, versioned at its root. `226-CI-BASELINE.ndjson` must contain only allowed sanitized fields; the renderer must be deterministic enough that `226-CI-BASELINE.md` can be regenerated and byte-compared. Store immutable URLs/IDs, never payloads, actors, raw branches, secret-presence data, or logs.

### Documentation changes (documentation, request-response)

**Analogs:** `scripts/ci/README.md:5-10`, `guides/testing-live-stripe.md:1-25`, and `examples/accrue_host/README.md:309-323`.

Extend existing maintainer entrypoints rather than create competing documentation. State the proof boundary, owner, exact local command, and linked artifact/evidence source in plain language. Update the old guide wording that calls `live-stripe` advisory: Phase 226 policy and proof state are distinct, while Fake remains PR merge proof and only a selected, configured, nonzero, passing, manifest-emitting Stripe suite is `proved`.

**CI contributor triage style** (`scripts/ci/README.md:5-10`):

```markdown
- **Release webhook test-isolation signal:** run `cd accrue && mix test ...`.
  The responsible source is `...`; it must ...

For classification, immutable Actions evidence links, current proof status, and
the required/advisory distinction, see [Phase 225's causal index](...).
Keep raw logs, reports, traces, screenshots, and payloads in Actions artifacts.
```

**Host proof ownership wording** (`examples/accrue_host/README.md:309-323`):

```markdown
- **Full local gate:** `mix verify.full` is the CI-equivalent local host gate.
- **CI wrapper:** `bash scripts/ci/accrue_host_uat.sh` is the repo-root wrapper
  used by GitHub Actions job `host-integration` for the full host stack.
```

## Shared Patterns

### Privacy-safe durable evidence

**Sources:** `225-CI-INCIDENTS.md:3-5`; `.github/workflows/ci.yml:980-1012`  
**Apply to:** collector, records, renderer, summary, docs, and workflow.

Commit only sanitized calculated facts and immutable evidence links. Keep reports, traces, screenshots, server logs, provider payloads, secrets, actor data, raw branch names, and application data in Actions artifacts.

### Literal proof semantics

**Sources:** `.github/workflows/ci.yml:1224-1280`; `guides/testing-live-stripe.md:1-25`  
**Apply to:** provider classifier, renderer, workflow, baseline, and docs.

Keep `policy`, `proof_state`, raw job conclusion, test counts, reason, and freshness separate. Provider proof is a predicate over selection, configuration/fixtures, nonzero selection, assertion result, and manifest emission—not job conclusion.

### Owner-first setup diagnostics

**Sources:** `scripts/ci/accrue_host_uat.sh:19-52`; `scripts/ci/accrue_host_verify_browser.sh:19-104`  
**Apply to:** preflight adapter, setup facts, host docs, CI summary.

Preserve the CI-provisions / host-owns-proof-contract boundary. Every classified setup failure reports its stable code, `host` or `CI` owner, one narrow command, and retained forensic location before technical detail.

### Deterministic contract verification

**Sources:** `scripts/ci/verify_executable_uat_contract.mjs:3-10,130-199,268-386`; `scripts/ci/verify_phase225_required_lane_evidence.sh:1-152`  
**Apply to:** all new validators and fixtures.

Use no new runtime dependency, deterministic fixtures with negative controls, precise failure output, and an explicit PASS summary. Validation must never contact or serialize provider secrets.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `.planning/phases/226-ci-baseline-proof-semantics/schema-v1.json` | config | transform | No checked-in versioned JSON/NDJSON CI-evidence schema exists; create the small explicit contract specified by research. |

## Metadata

**Analog search scope:** `.github/workflows/ci.yml`, `scripts/ci/`, `examples/accrue_host/`, `guides/`, Phase 225 planning artifacts  
**Files scanned:** 12  
**Pattern extraction date:** 2026-08-11
