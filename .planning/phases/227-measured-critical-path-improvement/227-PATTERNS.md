# Phase 227: Measured Critical-Path Improvement - Pattern Map

**Mapped:** 2026-08-12  
**Files analyzed:** 8  
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | config | event-driven | same file: `host-integration`, `playwright-e2e`, `annotation-sweep` | exact |
| `scripts/ci/verify_ci_critical_path.mjs` | utility / test | file-I/O, transform | `scripts/ci/verify_ci_baseline.mjs` | exact |
| `.planning/phases/227-measured-critical-path-improvement/227-ci-contract.json` | config | transform | `.planning/phases/226-ci-baseline-proof-semantics/schema-v1.json` | role-match |
| `.planning/phases/227-measured-critical-path-improvement/fixtures/ci-critical-path-cases.json` | test fixture | batch, transform | `.planning/phases/226-ci-baseline-proof-semantics/fixtures/ci-baseline-cases.json` | exact |
| `.planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson` | model / evidence data | batch, file-I/O | `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson` | exact |
| `.planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md` | documentation / report | transform | `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md` and `render_ci_baseline.mjs` | exact |
| `.planning/phases/227-measured-critical-path-improvement/227-VERIFICATION.md` | documentation / proof record | batch | `.planning/phases/226-ci-baseline-proof-semantics/226-VERIFICATION.md` | exact |
| `scripts/ci/README.md` | documentation | request-response | same file: Phase 226 evidence section | exact |

## Pattern Assignments

### `.github/workflows/ci.yml` (config, event-driven)

**Analog:** the current graph in the same workflow.

**One-edge dependency pattern** ([lines 889-901](../../../.github/workflows/ci.yml#L889-L901)):

```yaml
host-integration:
  name: Host integration (required deterministic gate)
  if: github.event_name != 'schedule'
  needs: [admin-drift-docs, docs-contracts-shift-left]
  runs-on: ubuntu-24.04
```

Replace only the `needs` value with `[docs-contracts-shift-left]`. Retain the ID, display name, condition, runner, services, environment, all steps, and artifact contracts unchanged.

**Host evidence-preservation pattern** ([lines 983-1043](../../../.github/workflows/ci.yml#L983-L1043)):

```yaml
- id: host_setup_artifact
  name: Upload host and CI setup facts
  if: always()
  uses: actions/upload-artifact@v7
  with:
    name: accrue-host-ci-setup-facts
    path: ${{ runner.temp }}/accrue-host-ci-setup-facts.ndjson
    if-no-files-found: ignore

- name: Upload Playwright report
  if: failure()
  uses: actions/upload-artifact@v7
  with:
    name: accrue-host-playwright-report
```

**Browser dependency and no-cancellation pattern** ([lines 1045-1069](../../../.github/workflows/ci.yml#L1045-L1069)):

```yaml
playwright-e2e:
  name: Playwright E2E shard ${{ matrix.shard }}/${{ strategy.job-total }}
  if: github.event_name != 'schedule'
  needs: [host-integration]
  runs-on: ubuntu-24.04
  strategy:
    fail-fast: false
    matrix:
      shard: [1, 2, 3]
```

Do not change this edge, the three-shard matrix, single worker setting ([lines 1071-1079](../../../.github/workflows/ci.yml#L1071-L1079)), or failure-only report/trace uploads ([lines 1141-1155](../../../.github/workflows/ci.yml#L1141-L1155)).

**Final aggregate-failure fan-in pattern** ([lines 1193-1211](../../../.github/workflows/ci.yml#L1193-L1211)):

```yaml
annotation-sweep:
  name: Annotation sweep
  if: github.event_name != 'schedule'
  needs:
    [
      release-manifest-ssot,
      docs-contracts-shift-left,
      release-gate,
      phase18-tax-gate,
      admin-drift-docs,
      admin-group-contracts,
      admin-hardening-guardrails,
      admin-phase200-guardrails,
      admin-ui-ratchet-guardrails,
      host-integration,
      playwright-e2e,
      host-docker-smoke,
    ]
```

The new static manifest/verifier must assert this complete list byte-for-byte at the contract level; it is the safety boundary that proves both independent lanes converge.

---

### `scripts/ci/verify_ci_critical_path.mjs` (utility/test, file-I/O + transform)

**Analog:** `scripts/ci/verify_ci_baseline.mjs`.

**Imports and dependency-free convention** ([lines 1-9](../../../scripts/ci/verify_ci_baseline.mjs#L1-L9)):

```javascript
#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { collectBaseline as collectBaselineWithContext, cohortFingerprint, createRepositoryValidationContext, liveRuns, normalizeJob, normalizeRun, summarizeCohorts as summarizeCohortsWithContext, unresolvedPrerequisites, validateRecord, workflowRunnerImage } from "./collect_ci_baseline.mjs";
import { deriveStagedPathPercentiles, renderBaseline } from "./render_ci_baseline.mjs";
```

Use Node built-ins and existing Phase 226 exports; do not add a YAML parser, test runner, or a second timing collector. Keep imports narrowed to helpers actually used by the Phase 227 verifier.

**Fail-closed assertion and fixture pattern** ([lines 23-25](../../../scripts/ci/verify_ci_baseline.mjs#L23-L25), [518-554](../../../scripts/ci/verify_ci_baseline.mjs#L518-L554)):

```javascript
function fail(message) {
  throw new Error(message);
}

const temp = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-ci-baseline-"));
try {
  // Assert positive and deliberately broken contracts here.
} finally {
  fs.rmSync(temp, { recursive: true, force: true });
}
```

The `--fixtures` path should prove: the sole intended `host-integration` prerequisite, unchanged `playwright-e2e` dependency and final fan-in, required identity/artifact manifest, three-first-attempt acceptance calculation, and a controlled failed upstream lane where host/Playwright complete and `annotation-sweep` records aggregate failure.

**CLI/error contract** ([lines 557-588](../../../scripts/ci/verify_ci_baseline.mjs#L557-L588)):

```javascript
const args = process.argv.slice(2);
if (args.includes("--fixtures")) await verifyFixtures(validationContext);
if (!args.includes("--fixtures") && recordsIndex === -1) {
  fail("usage: verify_ci_baseline.mjs --fixtures | --records records.ndjson ...");
}
console.log("ci baseline fixtures: PASS");
// outer boundary
console.error(`ci baseline fixtures: FAIL: ${error.message}`);
process.exitCode = 1;
```

Mirror this one-command, nonzero-on-contract-failure CLI, changing only its script-specific argument names and PASS/FAIL prefix.

**Measured-path rules to reuse** ([`render_ci_baseline.mjs` lines 12-66](../../../scripts/ci/render_ci_baseline.mjs#L12-L66)):

```javascript
const candidates = runRows
  .filter((run) => run.event_class !== "schedule" && run.conclusion === "success" && run.run_attempt === 1);
const release = jobs.find((job) => job.stable_identity === "release-gate");
const host = jobs.find((job) => job.stable_identity === "host-integration");
const playwright = jobs.filter((job) => job.stable_identity === "playwright-e2e" || job.stable_identity.startsWith("playwright-e2e-"));
```

Phase 227 adds a strict three-observation comparison rather than changing Phase 226’s frozen 20-observation derivation. It must calculate release start → latest Playwright completion (never sum shards), show DAG-wait removal, enforce median `<= 1666s`, and keep every incompatible, retry, failed, and anomaly row visibly represented as retained or excluded.

---

### `227-ci-contract.json` (config, transform)

**Analog:** `.planning/phases/226-ci-baseline-proof-semantics/schema-v1.json`.

**Versioned, explicit whitelist structure** ([lines 1-13](../../226-ci-baseline-proof-semantics/schema-v1.json#L1-L13)):

```json
{
  "schema_version": 1,
  "record_kinds": {
    "run": ["schema_version", "kind", "run_id", "run_url", "sha"],
    "job": ["schema_version", "kind", "run_id", "job_id", "job_url", "job_name"],
    "cohort": ["schema_version", "kind", "cohort_fingerprint", "sample_count"]
  },
  "enums": {
    "conclusion": ["success", "failure", "cancelled", "skipped"],
    "provider_state": ["proved", "failed", "misconfigured", "blocked", "skipped", "non_run"]
  }
}
```

Make an explicit JSON manifest, not inferred defaults: job IDs/display names; exact `needs` arrays; release compatibility/support and provider labels; every artifact name, condition, `if-no-files-found`, and retention setting. Treat an absent or extra identity as a failure, except for explicitly additive Phase 227 evidence.

---

### `fixtures/ci-critical-path-cases.json` (test fixture, batch/transform)

**Analog:** `.planning/phases/226-ci-baseline-proof-semantics/fixtures/ci-baseline-cases.json`, loaded through a phase-relative fixture resolver ([`verify_ci_baseline.mjs` lines 42-44](../../../scripts/ci/verify_ci_baseline.mjs#L42-L44)).

```javascript
function fixturePath() {
  return path.resolve(".planning/phases/226-ci-baseline-proof-semantics/fixtures/ci-baseline-cases.json");
}
```

Keep fixture cases sanitized and deterministic. Include one accepted comparison cohort and negative cases for re-run attempt, incompatible fingerprint/event, missing or changed identity/artifact, failed retained lane, and failed restoration graph. The fixture is the repository-side negative control; the verification report records the complementary controlled Actions run.

---

### `227-CI-CRITICAL-PATH.ndjson` (model/evidence data, batch + file-I/O)

**Analog:** `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson`, validated and read line-by-line through the baseline verifier ([lines 565-576](../../../scripts/ci/verify_ci_baseline.mjs#L565-L576)).

```javascript
const records = fs.readFileSync(source, "utf8")
  .trim().split("\n").filter(Boolean).map((line) => JSON.parse(line));
const expected = renderBaseline(records, validationContext);
assert.equal(fs.readFileSync(rendered, "utf8"), expected,
  "rendered Markdown must be byte-reproducible");
```

Use one sanitized JSON object per line, retain immutable GitHub run/job URLs and fingerprint/attempt/evidence states, and never persist raw logs, actors, branches, secrets, payloads, or artifact contents. Model before snapshot linkage (including integrity/hash), all three post-change observations, visible exclusions/reliability facts, comparison calculation, static/negative-control results, and explicit keep/rollback state.

---

### `227-CI-CRITICAL-PATH.md` (documentation/report, transform)

**Analog:** generated Phase 226 report and `renderBaseline`.

**Maintainer-facing fact grammar and reproducible rendering** ([`render_ci_baseline.mjs` lines 82-92](../../../scripts/ci/render_ci_baseline.mjs#L82-L92)):

```javascript
"# CI Baseline", "", "## Current fact", "",
`**State:** ${stagedConclusion}. **Owner:** CI maintainers. **Next command:** \`node scripts/ci/verify_ci_baseline.mjs ...\`. Evidence is the immutable Actions links below.`, "",
"Privacy-safe, schema-v1 evidence. Raw logs, actors, branches, secrets, payloads, and artifact contents are not persisted.", "",
"## Comparable cohort", "",
"## Measured critical path", "",
"## Exclusions", "",
"## Reproduce", "",
```

Generate or verify Markdown deterministically from the Phase 227 NDJSON. Use the same fact → literal state → owner → one exact command → immutable links order. Report the frozen `2083s` before median and `2602s` p95, the three individual post observations, range/median, exact fingerprints and sample count, removed host DAG wait, whole-workflow context, exclusions/anomaly substantiation, proof outcomes, and the inverse patch/rollback status.

---

### `227-VERIFICATION.md` (documentation/proof record, batch)

**Analog:** `.planning/phases/226-ci-baseline-proof-semantics/226-VERIFICATION.md`.

**Evidence boundary pattern:** Phase 226 documents command, result, and immutable evidence while durable machine facts stay in NDJSON and raw forensics stay in Actions artifacts. Follow that separation for static verifier output, fixture negative control, controlled failing Actions run, three accepted first attempts, and rollback restoration run. Do not rewrite the Phase 226 baseline report, records, or schema.

---

### `scripts/ci/README.md` (documentation, request-response)

**Analog:** its Phase 226 top-of-file evidence index ([lines 3-23](../../../scripts/ci/README.md#L3-L23)).

```markdown
## Phase 226 CI evidence: read this first

| Evidence | What it answers | Command |
| --- | --- | --- |
| [CI baseline](...) and [NDJSON record](...) | Which fixed workflow cohort was measured ... | `node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository acme/accrue` |

Run the complete contract before changing any of these surfaces:

```bash
node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository acme/accrue && \
  node scripts/ci/verify_provider_proof.mjs --fixtures && \
  bash scripts/ci/verify_ci_setup_diagnostics.sh
```
```

Add a compact Phase 227 section adjacent to this guide: links to the new evidence pack/manifest, the exact static fixture command, the evidence-verification command, a plain controlled-failure/rollback procedure, and a reminder that the Phase 226 files are frozen.

## Shared Patterns

### Contract-verifier safety

**Sources:** [`verify_ci_baseline.mjs` lines 23-25](../../../scripts/ci/verify_ci_baseline.mjs#L23-L25), [557-588](../../../scripts/ci/verify_ci_baseline.mjs#L557-L588)

Use `node:assert/strict`, throw on malformed/missing input, provide `--fixtures` for negative cases, and set `process.exitCode = 1` at one outer error boundary. No `continue-on-error`, retry, or partial-success escape hatch belongs in this verifier.

### Evidence privacy and reproducibility

**Sources:** [`render_ci_baseline.mjs` lines 69-105](../../../scripts/ci/render_ci_baseline.mjs#L69-L105), [`verify_ci_baseline.mjs` lines 565-576](../../../scripts/ci/verify_ci_baseline.mjs#L565-L576)

Validate every record before rendering and byte-compare rendered Markdown to its checked-in form. Preserve only sanitized timing/identity/proof metadata and immutable URLs; keep raw artifacts linked from GitHub Actions.

### Required work and artifact retention

**Sources:** [`ci.yml` lines 983-1043](../../../.github/workflows/ci.yml#L983-L1043), [1045-1155](../../../.github/workflows/ci.yml#L1045-L1155), [1193-1211](../../../.github/workflows/ci.yml#L1193-L1211)

Independent lanes retain their own `always()` or `failure()` artifact conditions and finish before the unchanged `annotation-sweep` fan-in reports aggregate failure. Preserve `playwright-e2e` `fail-fast: false`, its single-worker environment, and its host dependency.

### Measurement acceptance

**Sources:** [`render_ci_baseline.mjs` lines 12-66](../../../scripts/ci/render_ci_baseline.mjs#L12-L66), Phase 227 locked decisions D-04 through D-07.

Eligible performance observations are successful, first-attempt, compatible same-event-class runs with immutable URLs. Measure release start through the latest Playwright shard completion; use the three-run median against `1666s`, retain all exclusions visibly, and only permit a value above `2602s` with documented external platform evidence.

## No Analog Found

None. Phase 226 provides direct repository patterns for deterministic verification, sanitized NDJSON, generated Markdown, fixtures, and recorded verification; the same CI workflow contains the exact scheduling and artifact contracts.

## Metadata

**Analog search scope:** `.github/workflows/ci.yml`, `scripts/ci/`, `.planning/phases/225-required-lane-signal-repair/`, and `.planning/phases/226-ci-baseline-proof-semantics/`  
**Files scanned:** 14  
**Pattern extraction date:** 2026-08-12
