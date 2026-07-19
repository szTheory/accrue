# Phase 208: Prove convergence on the representative slice + wire CI + ACCEPT - Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/workflows/ci.yml` | config/workflow | CI batch + request-response status | `.github/workflows/ci.yml` Phase 192/200 jobs | exact modification |
| `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` | utility/CI contract | batch text inspection | `scripts/ci/verify_phase200_ci_contract.sh` | exact role |
| `scripts/ci/verify_ui_ratchet_signoff.mjs` | utility/verifier | batch + file-I/O + Markdown transform | `scripts/ci/verify_phase200_signoff.mjs` | exact role |
| `scripts/ci/verify_ratchet_ledger.mjs` | utility/verifier | batch + file-I/O | same file | exact modification |
| `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` | utility/reducer | batch + transform + file-I/O | same file | exact modification |
| `accrue_admin/e2e/ratchet/ratchet-ledger.js` | model/helper | append-only event-driven + transform | same file | exact modification |
| `accrue_admin/e2e/ratchet/ledger.baseline.json` | model/baseline artifact | file-I/O snapshot | `phase-ratchet-ledger.mjs` baseline writer | exact data-flow |
| `accrue_admin/e2e/ratchet/rounds.ndjson` | model/event log | append-only event-driven | `phase-ratchet-ledger.mjs` round seal writer | exact data-flow |
| `accrue_admin/e2e/ratchet/finding-regressions.ndjson` | model/regression log | batch + file-I/O | `phase-ratchet-ledger.mjs` 0-byte NDJSON writer | exact data-flow |
| `.planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/regressions.ndjson` | model/regression log | batch + file-I/O | Phase 200 0-byte regression contract | exact data-flow |
| `accrue_admin/package.json` | config | command wiring | existing `ratchet:*` and `phase200:*` scripts | exact modification |
| `accrue_admin/priv/static/accrue_admin.css` | generated asset | static bundle file-I/O | `.github/workflows/ci.yml` asset drift gate + `assets/css/*` | role-match |
| `accrue_admin/assets/css/theme.css` | style config | static transform source | same file token registry | conditional role-match |
| `accrue_admin/assets/css/app.css` | style utility/source | static transform source | same file utility pattern | conditional role-match |
| `.planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/UI-RATCHET-SIGN-OFF.md` | documentation/evidence artifact | file-I/O + verification | `.planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/200-SIGN-OFF.md` | exact structure |

## Pattern Assignments

### `.github/workflows/ci.yml` (config/workflow, CI batch)

**Analog:** `.github/workflows/ci.yml`

**Stable job-id contract** (lines 3-14):
```yaml
# Job id contract - stable YAML `jobs:` keys relied on by docs, `act`, and anchors:
# `release-manifest-ssot`, `release-gate`, `phase18-tax-gate`, `admin-drift-docs`,
# `admin-group-contracts`, `admin-hardening-guardrails`,
# `admin-phase200-guardrails`, `host-integration`, `playwright-e2e`,
# `host-docker-smoke`, `annotation-sweep`, `live-stripe`.
# Merge-blocking on pull_request: `release-manifest-ssot`, `docs-contracts-shift-left`,
# `release-gate`, `phase18-tax-gate`, `admin-drift-docs`, `admin-group-contracts`,
# `admin-hardening-guardrails`, `admin-phase200-guardrails`,
# `host-integration`, `playwright-e2e`, `host-docker-smoke`,
# `annotation-sweep`.
```

**Job shape and contract step pattern** (lines 667-740):
```yaml
  admin-phase200-guardrails:
    name: Admin Phase 200 deterministic guardrails
    if: github.event_name != 'schedule'
    runs-on: ubuntu-24.04

    steps:
      - uses: actions/checkout@v6
      - name: Set up Node
        uses: actions/setup-node@v6
        with:
          node-version: '22'
          cache: npm
          cache-dependency-path: accrue_admin/package-lock.json
      - name: Install browser deps
        run: cd accrue_admin && npm ci
      - name: Phase 200 CI contract
        run: bash scripts/ci/verify_phase200_ci_contract.sh
      - name: Phase 200 local guardrail contract
        run: bash scripts/ci/verify_phase200_guardrail_contract.sh
      - name: Run Phase 200 deterministic guardrails
        run: bash scripts/ci/verify_phase200_admin_guardrails.sh
```

For Phase 208, copy the stable job-id/name/contract-step structure but keep the new job Node-only. Do not copy the BEAM/Postgres/Chromium setup unless a concrete verifier still requires it. The new job id/name are locked by `208-UI-SPEC.md`: `admin-ui-ratchet-guardrails` and `Admin UI ratchet guardrails`.

**Artifact upload pattern** (lines 742-774):
```yaml
      - name: Upload Phase 200 generated evidence
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: phase200-generated-evidence
          path: |
            .planning/phases/200-idempotent-verification-sign-off/baseline.union.cells.json
            .planning/phases/200-idempotent-verification-sign-off/final.cells.json
            .planning/phases/200-idempotent-verification-sign-off/scorecard.delta.json
            .planning/phases/200-idempotent-verification-sign-off/regressions.ndjson
            .planning/phases/200-idempotent-verification-sign-off/artifacts.manifest.json
            .planning/phases/200-idempotent-verification-sign-off/200-SIGN-OFF.md
          if-no-files-found: ignore
```

**Annotation sweep inclusion** (lines 1050-1090):
```yaml
  annotation-sweep:
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
        host-integration,
        playwright-e2e,
        host-docker-smoke,
      ]
    steps:
      - name: Sweep release-facing annotations
        run: >-
          bash scripts/ci/annotation_sweep.sh release-manifest-ssot docs-contracts-shift-left
          release-gate phase18-tax-gate admin-drift-docs admin-group-contracts admin-hardening-guardrails
          admin-phase200-guardrails host-integration playwright-e2e host-docker-smoke
```

Add `admin-ui-ratchet-guardrails` to both `needs` and the `annotation_sweep.sh` argument list.

**Asset freshness sibling gate** (lines 423-427):
```yaml
      - name: Rebuild package assets
        run: cd accrue_admin && mix accrue_admin.assets.build

      - name: Ensure committed bundle is fresh
        run: git diff --exit-code -- accrue_admin/priv/static/accrue_admin.css accrue_admin/priv/static/accrue_admin.js
```

### `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` (utility/CI contract, batch text inspection)

**Analog:** `scripts/ci/verify_phase200_ci_contract.sh`

**Shell contract scaffolding** (lines 1-23):
```bash
#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ci_file="$root_dir/.github/workflows/ci.yml"
runner_file="$root_dir/scripts/ci/verify_phase200_admin_guardrails.sh"
guardrail_contract_file="$root_dir/scripts/ci/verify_phase200_guardrail_contract.sh"

fail() {
  echo "verify_phase200_ci_contract: $*" >&2
  exit 1
}

require_file() {
  local file="$1"
  [ -f "$file" ] || fail "missing file: ${file#$root_dir/}"
}

require_fixed() {
  local file="$1"
  local needle="$2"
  grep -Fq "$needle" "$file" || fail "missing '${needle}' in ${file#$root_dir/}"
}
```

**Job extraction pattern** (lines 80-88):
```bash
job_body() {
  local job_id="$1"

  awk -v job_id="$job_id" '
    $0 == "  " job_id ":" { in_job = 1 }
    in_job && $0 ~ /^  [A-Za-z0-9_-]+:/ && $0 != "  " job_id ":" { exit }
    in_job { print }
  ' "$ci_file"
}
```

**Required job contents pattern** (lines 94-105, 149-155):
```bash
require_fixed "$ci_file" "admin-phase200-guardrails:"
require_fixed "$ci_file" "Admin Phase 200 deterministic guardrails"
require_fixed "$ci_file" "bash scripts/ci/verify_phase200_ci_contract.sh"
require_fixed "$ci_file" "bash scripts/ci/verify_phase200_guardrail_contract.sh"
require_fixed "$ci_file" "bash scripts/ci/verify_phase200_admin_guardrails.sh"

phase200_job="$(job_body "admin-phase200-guardrails")"
[ -n "$phase200_job" ] || fail "could not extract admin-phase200-guardrails job"
phase200_run_lines="$(printf '%s\n' "$phase200_job" | grep -E '^[[:space:]]*run:' || true)"

require_source_regex "admin-phase200-guardrails job" "$phase200_job" 'name: Phase 200 CI contract'
require_source_regex "admin-phase200-guardrails job" "$phase200_job" 'name: Phase 200 local guardrail contract'
require_source_regex "admin-phase200-guardrails job" "$phase200_job" 'name: Run Phase 200 deterministic guardrails'
require_source_regex "admin-phase200-guardrails job" "$phase200_job" 'if: always\(\)'
```

**Forbidden command pattern** (lines 167-181):
```bash
for pattern in \
  'npm run e2e([[:space:]"'\'';&|]|$)' \
  'playwright test([[:space:]]+--|[[:space:]]*(["'\'';&|]|$))' \
  'score-visuals' \
  'baseline:artifacts|baseline-artifacts' \
  'phase200-judge\.mjs' \
  'phase200-signoff\.mjs' \
  'screenshot[[:space:]_-]*capture|capture[[:space:]_-]*screenshot' \
  'trace[[:space:]_-]*capture|capture[[:space:]_-]*trace' \
  'maintainer[[:space:]_-]*sign|human[[:space:]_-]*sign'
do
  require_source_absent_regex "admin-phase200-guardrails run commands" "$phase200_run_lines" "$pattern"
done

require_no_broad_playwright "admin-phase200-guardrails run commands" "$phase200_run_lines"
```

For Phase 208 add forbidden patterns for `secrets\.`, `ANTHROPIC_API_KEY`, `ratchet-propose`, `ratchet-verify`, `ui\.round`, `ui\.fix`, browser capture commands, Playwright capture, and `--freeze` inside `admin-ui-ratchet-guardrails`.

### `scripts/ci/verify_ui_ratchet_signoff.mjs` (utility/verifier, batch + file-I/O)

**Analog:** `scripts/ci/verify_phase200_signoff.mjs`

**Imports and path constants** (lines 1-10):
```javascript
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, "..", "..");
const PHASE200_DIR = ".planning/phases/200-idempotent-verification-sign-off";
const DEFAULT_SIGNOFF_PATH = path.join(REPO_ROOT, PHASE200_DIR, "200-SIGN-OFF.md");
```

**Section/evidence helpers** (lines 124-153):
```javascript
function sectionSource(markdown, headingMatcher) {
  const lines = markdown.split(/\r?\n/);
  const start = lines.findIndex((line) => /^#{1,4}\s+/.test(line) && headingMatcher.test(line));
  if (start === -1) return "";
  const out = [];
  for (let index = start + 1; index < lines.length; index += 1) {
    if (/^#{1,4}\s+/.test(lines[index])) break;
    out.push(lines[index]);
  }
  return out.join("\n");
}

function evidenceRefs(source) {
  return Array.from(new Set(String(source).match(/(?:accrue_admin\/test-results\/|accrue_admin\/playwright-report\/|\.planning\/phases\/200-idempotent-verification-sign-off\/)[^\s),\]|]+/g) || []));
}

function validEvidenceRef(ref) {
  if (!ref || path.isAbsolute(ref) || ref.includes("\\") || ref.split("/").includes("..")) return false;
  return ref.startsWith("accrue_admin/test-results/") || ref.startsWith("accrue_admin/playwright-report/") || ref.startsWith(`${PHASE200_DIR}/`);
}
```

Adapt `PHASE200_DIR` and valid refs to Phase 208 paths plus ratchet artifacts. Reject absolute paths, backslashes, and `..`.

**Final decision parser** (lines 191-205):
```javascript
function parseDecisionLine(markdown, failures) {
  const lines = markdown.split(/\r?\n/).filter((line) => line.startsWith("Final maintainer decision: "));
  if (lines.length !== 1) {
    failures.decision.push(`Expected exactly one final decision line, found ${lines.length}.`);
    return { decision: null, line: lines[0] || null };
  }

  const match = lines[0].match(/^Final maintainer decision: (ACCEPT|REJECT)\b/);
  if (!match) {
    failures.decision.push("Final decision line must start with Final maintainer decision: ACCEPT or Final maintainer decision: REJECT.");
    return { decision: null, line: lines[0] };
  }

  return { decision: match[1], line: lines[0] };
}
```

For Phase 208, constrain this further to the exact UI-SPEC prefix and evidence-source sentence:
`Final maintainer decision: ACCEPT (maintainer approved {YYYY-MM-DD}). Evidence source: accrue_admin/e2e/ratchet/ledger.baseline.json and .planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/UI-RATCHET-SIGN-OFF.md.`

**Top-level verifier shape** (lines 390-424):
```javascript
export function verifyPhase200Signoff(options = {}) {
  const signoffPath = path.resolve(options.signoffPath || DEFAULT_SIGNOFF_PATH);
  const phaseDir = path.resolve(options.phaseDir || path.dirname(signoffPath));
  const paths = artifactPaths(phaseDir, options.artifactPaths || {});
  const markdown = options.markdown ?? readFile(signoffPath);
  const failures = failureTemplate();

  const decision = parseDecisionLine(markdown, failures);
  validateStructure(markdown, failures);
  if (options.requireAccept && decision.decision !== "ACCEPT") {
    failures.decision.push("CI sign-off verification requires Final maintainer decision: ACCEPT.");
  }

  if (decision.decision === "ACCEPT") {
    validateAcceptArtifacts(paths, failures);
    validateAcceptScorecard(paths, failures);
    validateAcceptJudge(paths, failures);
    validateAcceptManifest(paths, markdown, failures);
    if (/\bhuman_needed\b/i.test(markdown)) failures.staleState.push("ACCEPT sign-off must not leave human_needed state.");
  }

  return {
    ok: failureCount(failures) === 0,
    decision: decision.decision,
    summary: { signoff_path: signoffPath, artifact_refs: REQUIRED_PHASE200_ARTIFACTS.filter((artifact) => markdown.includes(artifact)).length, evidence_refs: evidenceRefs(markdown).length, failures: failureCount(failures) },
    failures,
  };
}
```

**Self-test fixture and CLI pattern** (lines 548-704):
```javascript
function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase200-signoff-verifier-"));
  try {
    fixturePackage(path.join(root, "accept"));
    const accept = verifyPhase200Signoff({
      markdown: signoffMarkdown("ACCEPT"),
      signoffPath: path.join(root, "accept/200-SIGN-OFF.md"),
    });
    assertSelfTest("valid ACCEPT fixture passes", accept.ok, JSON.stringify(accept.failures));

    const noFinalLine = verifyPhase200Signoff({ markdown: signoffMarkdown("ACCEPT").replace(/^Final maintainer decision:.*$/m, ""), phaseDir: path.join(root, "accept") });
    assertSelfTest("missing final decision line fails", !noFinalLine.ok);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

function parseArgs(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--self-test") options.selfTest = true;
    else if (arg === "--signoff") options.signoffPath = path.resolve(argv[++index]);
    else if (arg === "--phase-dir") options.phaseDir = path.resolve(argv[++index]);
    else if (arg === "--require-accept") options.requireAccept = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return options;
}
```

### `scripts/ci/verify_ratchet_ledger.mjs` (utility/verifier, batch + file-I/O)

**Analog:** same file.

**Independent verifier imports/defaults** (lines 43-62):
```javascript
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as regionTags from "../../accrue_admin/e2e/ratchet/region-tags.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "..", "..");
const RATCHET_DIR = path.join(REPO_ROOT, "accrue_admin", "e2e", "ratchet");

const DEFAULT_PATHS = {
  ledgerPath: path.join(RATCHET_DIR, "findings.ledger.ndjson"),
  baselinePath: path.join(RATCHET_DIR, "ledger.baseline.json"),
  reopenMarkersPath: path.join(RATCHET_DIR, "reopen-markers.ndjson"),
  regressionsPath: path.join(RATCHET_DIR, "finding-regressions.ndjson"),
};
```

**Closed lens enum** (lines 70-78):
```javascript
const LENS_KEYS = [
  "persona:operator-founder",
  "persona:customer-support",
  "persona:finance-billing-ops",
  "persona:recovery-growth-ops",
  "persona:developer-integration",
  "persona:compliance-audit",
  "design",
];
```

**Independent fold and count recompute** (lines 145-183):
```javascript
function independentFold(rawRows) {
  const folded = new Map();
  const seqFailures = [];
  let maxSeq = -Infinity;
  for (const row of rawRows) {
    if (typeof row.seq !== "number" || !(row.seq > maxSeq)) {
      seqFailures.push(`seq not monotonic (independent recompute): finding_id=${JSON.stringify(row.finding_id)} seq=${JSON.stringify(row.seq)}`);
      continue;
    }
    maxSeq = row.seq;
    folded.set(row.finding_id, row);
  }
  return { folded, seqFailures };
}

function computeIndependentOpenCounts(foldedRowsMap) {
  const counts = {};
  for (const lens of LENS_KEYS) counts[lens] = { total: 0, minor: 0, real: 0 };
  for (const row of foldedRowsMap.values()) {
    if (row.status !== "open") continue;
    const lenses = Array.isArray(row.raised_by_lenses) ? row.raised_by_lenses : [];
    for (const lens of lenses) {
      if (!counts[lens]) continue;
      counts[lens].total += 1;
      if (row.severity === "minor") counts[lens].minor += 1;
      else if (row.severity === "real") counts[lens].real += 1;
    }
  }
  return counts;
}
```

**Baseline comparison** (lines 191-215):
```javascript
function compareAgainstBaseline(independentCounts, baselineConfirmedOpen, failures) {
  const baselineOpen = baselineConfirmedOpen || {};
  for (const lens of LENS_KEYS) {
    const independent = independentCounts[lens];
    const stored = baselineOpen[lens] || { total: 0, minor: 0, real: 0 };
    const storedTotal = stored.total ?? 0;
    const storedMinor = stored.minor ?? 0;
    const storedReal = stored.real ?? 0;
    if (independent.total !== storedTotal || independent.minor !== storedMinor || independent.real !== storedReal) {
      failures.baselineMismatch.push(`Lens ${lens}: ledger.baseline.json stores confirmed_open ${JSON.stringify({ total: storedTotal, minor: storedMinor, real: storedReal })} but the independent recompute from raw findings.ledger.ndjson rows is ${JSON.stringify(independent)}.`);
    }
  }
}
```

**Zero-byte regression check** (lines 338-359):
```javascript
function checkRegressionsZeroBytes(regressionsPath, failures) {
  let size = 0;
  try {
    size = fs.statSync(regressionsPath).size;
  } catch (error) {
    if (error && error.code === "ENOENT") {
      size = 0;
    } else {
      throw error;
    }
  }
  if (size !== 0) {
    failures.regressionsNotEmpty.push(`finding-regressions.ndjson is ${size} bytes (expected exactly 0) - real regressions may exist.`);
  }
}
```

**Top-level verifier and CLI** (lines 386-405, 634-660):
```javascript
export function verifyRatchetLedger(overridePaths = {}) {
  const paths = { ...DEFAULT_PATHS, ...overridePaths };
  const failures = failureTemplate();

  const rawRows = readRawLedgerLines(paths.ledgerPath);
  const { folded, seqFailures } = independentFold(rawRows);
  failures.seqNotMonotonic.push(...seqFailures);

  const independentCounts = computeIndependentOpenCounts(folded);
  const baseline = readBaseline(paths.baselinePath, failures);
  compareAgainstBaseline(independentCounts, baseline.confirmed_open, failures);

  checkGuardRefsIndependent(folded, REPO_ROOT, failures);
  checkJustificationTokensIndependent(folded, failures);
  checkRegressionsZeroBytes(paths.regressionsPath, failures);

  const ok = Object.values(failures).every((items) => items.length === 0);
  return { ok, failures };
}

function main() {
  if (process.argv.includes("--self-test")) {
    runSelfTest();
    return;
  }
  const result = verifyRatchetLedger(DEFAULT_PATHS);
  console.log(`[verify-ratchet-ledger] ok=${result.ok}`);
  if (!result.ok) {
    reportFailures(result.failures);
    process.exitCode = 1;
  } else {
    console.log("[verify-ratchet-ledger] independent recompute matches the committed baseline; finding-regressions.ndjson is 0 bytes.");
  }
}
```

Phase 208 should extend this script or wrap it with `--verify-frozen` for frozen/non-placeholder baseline checks and scratch fixtures for synthetic count increase plus cross-persona regression. Keep the independence rule: do not import `phase-ratchet-ledger.mjs` or `ratchet-ledger.js` into this verifier.

### `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` (utility/reducer, batch + transform + file-I/O)

**Analog:** same file.

**Imports/path constants** (lines 23-55):
```javascript
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import * as ratchetLedger from "./ratchet-ledger.js";
import baselineManifest from "../baseline-manifest.js";

const { fold, LENS_KEYS } = ratchetLedger;
const { SURFACES } = baselineManifest;
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "../../..");

const DEFAULT_PATHS = {
  ledgerPath: path.join(__dirname, "findings.ledger.ndjson"),
  baselinePath: path.join(__dirname, "ledger.baseline.json"),
  reopenMarkersPath: path.join(__dirname, "reopen-markers.ndjson"),
  regressionsPath: path.join(__dirname, "finding-regressions.ndjson"),
  roundsPath: path.join(__dirname, "rounds.ndjson"),
};
```

**Current score-floor gap to tighten** (lines 212-224):
```javascript
function computeClauseCoverageFloor(cellsCensusRows, scopeSurfaces) {
  const noFilter = scopeSurfaces == null || scopeSurfaces === "all";
  const filtered = noFilter
    ? cellsCensusRows
    : cellsCensusRows.filter((cell) => scopeSurfaces.has(cell.surface));
  return filtered.every((cell) => cell.coverage_status === "covered");
}
```

Phase 208 must add `score >= 2` enforcement here or in a verifier layer. Also guard against the vacuous pass when the filtered set is empty.

**Forward-only per-lens regression compare** (lines 317-335):
```javascript
function compareOpenCounts(currentOpenCounts, baseline) {
  const baselineOpen = baseline.confirmed_open || {};
  const regressions = [];
  for (const lens of LENS_KEYS) {
    const currentTotal = currentOpenCounts[lens].total;
    const baselineTotal = baselineOpen[lens]?.total ?? 0;
    if (currentTotal > baselineTotal) {
      regressions.push(
        regressionRow(
          "count-increase",
          lens,
          baselineTotal,
          currentTotal,
          `Lens ${lens} open-finding count increased from ${baselineTotal} to ${currentTotal}.`
        )
      );
    }
  }
  return regressions;
}
```

**Freeze writer** (lines 477-497):
```javascript
function regenerateBaseline({ baselinePath, ledgerPath }, currentOpenCounts, resolvedLocked) {
  const existing = readBaseline(baselinePath);
  const freezeFlagPresent = process.argv.includes("--freeze");

  if (existing.frozen === true && !freezeFlagPresent) {
    throw new Error("Refusing to modify a frozen baseline without --freeze (Phase 208 only).");
  }

  const epoch = existing.epoch && existing.epoch > 0 ? existing.epoch : 1;
  const newBaseline = {
    schema_version: "ratchet-ledger-baseline/1",
    frozen: freezeFlagPresent,
    epoch,
    ledger_sha256: ledgerSha256(ledgerPath),
    confirmed_open: currentOpenCounts,
    resolved_locked: resolvedLocked,
  };

  writeJson(baselinePath, newBaseline);
  return newBaseline;
}
```

Freeze stays an explicit local command. The CI job must not call any path that mutates or freezes the baseline.

**Reducer write boundary** (lines 503-544):
```javascript
function computeRegressions(paths) {
  const { ledgerPath, baselinePath, reopenMarkersPath } = paths;

  const ledgerRows = readNdjsonRows(ledgerPath);
  const foldedMap = fold(ledgerRows);
  const foldedFindings = Array.from(foldedMap.values());

  const currentOpenCounts = computeCurrentOpenCounts(foldedFindings);
  const baseline = readBaseline(baselinePath);

  const regressions = [
    ...compareOpenCounts(currentOpenCounts, baseline),
    ...checkGuardRefs(foldedFindings, REPO_ROOT),
    ...checkReopenMarkers(foldedFindings, baseline, reopenMarkersPath),
  ];

  const resolvedLocked = foldedFindings
    .filter((finding) => finding.status === "resolved" || finding.status === "verified-closed")
    .map((finding) => finding.claim_key);

  return { foldedFindings, currentOpenCounts, baseline, regressions, resolvedLocked };
}

function runReducer(paths = DEFAULT_PATHS) {
  const { regressionsPath, baselinePath, ledgerPath } = paths;
  const { currentOpenCounts, regressions, resolvedLocked } = computeRegressions(paths);
  writeNdjson(regressionsPath, regressions);
  const baseline = regenerateBaseline({ baselinePath, ledgerPath }, currentOpenCounts, resolvedLocked);
  return { regressions, baseline };
}
```

**Round seal event pattern** (lines 562-621):
```javascript
function sealRound(paths = DEFAULT_PATHS) {
  const rawRound = process.env.RATCHET_ROUND;
  const currentRound = Number(rawRound);
  if (rawRound === undefined || rawRound === null || String(rawRound).trim() === "" || !Number.isFinite(currentRound)) {
    console.error("[phase-ratchet-ledger] --seal-round: RATCHET_ROUND is missing or non-numeric; appending nothing to rounds.ndjson.");
    process.exitCode = 1;
    return;
  }

  const rawScope = process.env.RATCHET_SURFACES || "all";
  const scopeSurfaces = rawScope === "all" ? null : new Set(rawScope.split(",").map((s) => s.trim()).filter(Boolean));
  const { baseline } = runReducer(paths);
  const foldedFindings = Array.from(fold(readNdjsonRows(paths.ledgerPath)).values());

  const clause1 = computeClauseNewOpens(foldedFindings, currentRound);
  const clause2 = computeClauseZeroOpen(foldedFindings);
  const clause3 = computeClauseRegressionsEmpty(paths.regressionsPath, STANDING_REGRESSIONS_PATH);
  const clause4 = computeClauseCoverageFloor(readCellsCensus(CELLS_CENSUS_PATH), scopeSurfaces);
  const dry = computeDryRound([clause1, clause2, clause3, clause4]);

  const newRow = {
    schema_version: "ratchet-round-seal/1",
    round: currentRound,
    dry,
    epoch: baseline.epoch,
    scope: rawScope,
    bundle_sha256: bundleSha256(),
    seq: existingRoundsRows.length + 1,
  };
  writeNdjson(paths.roundsPath, updatedRows);
}
```

### `accrue_admin/e2e/ratchet/ratchet-ledger.js` (model/helper, append-only event-driven)

**Analog:** same file.

**Closed lens/event enums** (lines 43-85):
```javascript
const LENS_KEYS = [
  "persona:operator-founder",
  "persona:customer-support",
  "persona:finance-billing-ops",
  "persona:recovery-growth-ops",
  "persona:developer-integration",
  "persona:compliance-audit",
  "design",
];

const EVENT_TYPES = ["confirm", "resolve", "verify-close", "suppress", "reopen"];
const STATUS_VALUES = ["open", "resolved", "verified-closed", "suppressed"];
const EVENT_STATUS = {
  confirm: "open",
  resolve: "resolved",
  "verify-close": "verified-closed",
  suppress: "suppressed",
  reopen: "open",
};
```

**Append-open writer** (lines 303-346):
```javascript
function appendOpen(candidateRow, ledgerPath, extraFields = {}) {
  if (!candidateRow || typeof candidateRow !== "object") {
    throw new Error("appendOpen: candidateRow must be an object");
  }
  assertIdentity(candidateRow);

  const rows = readLedgerRows(ledgerPath);
  const seq = nextSeq(rows);
  const raisedByLenses = Array.isArray(candidateRow.raised_by_lenses)
    ? Array.from(new Set(candidateRow.raised_by_lenses)).sort()
    : [lensKeyFor(candidateRow.raised_by)];

  const row = {
    schema_version: "ratchet-finding-event/1",
    seq,
    event: "confirm",
    status: "open",
    persona_frequency: candidateRow.persona_frequency != null ? candidateRow.persona_frequency : raisedByLenses.length,
    raised_by_lenses: raisedByLenses,
    ...pick(candidateRow, IDENTITY_FIELDS),
    ...pick(candidateRow, CARRY_FIELDS),
    ...extraFields,
  };

  appendRow(ledgerPath, row);
  return row;
}
```

**Lifecycle transition writer** (lines 357-405):
```javascript
function appendLifecycleEvent(finding_id, ledgerPath, event, extraFields = {}) {
  const status = EVENT_STATUS[event];
  if (!status) {
    throw new Error(`appendLifecycleEvent: unrecognized event ${JSON.stringify(event)}`);
  }
  const rows = readLedgerRows(ledgerPath);
  const prior = latestRowForFindingId(rows, finding_id);
  if (!prior) {
    throw new Error(`appendLifecycleEvent: no existing row found for finding_id=${JSON.stringify(finding_id)} in ${ledgerPath}`);
  }
  assertIdentity(prior);
  if (!LEGAL_TRANSITIONS[prior.status] || !LEGAL_TRANSITIONS[prior.status].includes(event)) {
    throw new Error(`appendLifecycleEvent: illegal transition ${JSON.stringify(prior.status)} -> ${JSON.stringify(event)} for finding_id=${JSON.stringify(finding_id)}`);
  }

  const row = {
    schema_version: "ratchet-finding-event/1",
    seq: nextSeq(rows),
    event,
    status,
    raised_by_lenses: Array.isArray(prior.raised_by_lenses) ? prior.raised_by_lenses.slice() : [],
    ...pick(prior, IDENTITY_FIELDS),
    ...pick(prior, CARRY_FIELDS),
    ...extraFields,
  };

  appendRow(ledgerPath, row);
  return row;
}
```

**Fold/collapse pattern** (lines 472-548):
```javascript
function fold(rows) {
  const result = new Map();
  let maxSeq = -Infinity;
  for (const row of rows) {
    if (typeof row.seq !== "number" || !(row.seq > maxSeq)) {
      throw new Error(`seq not monotonic: finding_id=${JSON.stringify(row.finding_id)} seq=${JSON.stringify(row.seq)}`);
    }
    maxSeq = row.seq;
    result.set(row.finding_id, row);
  }
  return result;
}

function collapseByFindingId(candidateRows) {
  const groups = new Map();
  for (const row of candidateRows) {
    if (!groups.has(row.finding_id)) groups.set(row.finding_id, []);
    groups.get(row.finding_id).push(row);
  }
  // group by finding_id, dedupe/sort raised_by_lenses, carry representative fields
}
```

Do not add new ledger mutation paths outside these helpers. If Phase 208 needs fixture rows, write them to scratch directories inside self-tests.

### `accrue_admin/e2e/ratchet/ledger.baseline.json` (model/baseline artifact, file-I/O snapshot)

**Analog:** `phase-ratchet-ledger.mjs` `regenerateBaseline`.

**Current placeholder shape to replace** (lines 1-44):
```json
{
  "schema_version": "ratchet-ledger-baseline/1",
  "frozen": false,
  "epoch": 1,
  "ledger_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "confirmed_open": {
    "persona:operator-founder": { "total": 0, "minor": 0, "real": 0 },
    "persona:customer-support": { "total": 0, "minor": 0, "real": 0 },
    "persona:finance-billing-ops": { "total": 0, "minor": 0, "real": 0 },
    "persona:recovery-growth-ops": { "total": 0, "minor": 0, "real": 0 },
    "persona:developer-integration": { "total": 0, "minor": 0, "real": 0 },
    "persona:compliance-audit": { "total": 0, "minor": 0, "real": 0 },
    "design": { "total": 0, "minor": 0, "real": 0 }
  },
  "resolved_locked": []
}
```

Phase 208 must reject this all-zero empty-file-hash placeholder. The frozen baseline should be written only by `cd accrue_admin && node e2e/ratchet/phase-ratchet-ledger.mjs --freeze` after preflight.

### `accrue_admin/e2e/ratchet/rounds.ndjson` (model/event log, append-only event-driven)

**Analog:** `phase-ratchet-ledger.mjs` `sealRound`.

**Round row writer** (lines 603-613):
```javascript
const newRow = {
  schema_version: "ratchet-round-seal/1",
  round: currentRound,
  dry,
  epoch,
  scope: rawScope,
  bundle_sha256: bundleSha256(),
  seq: existingRoundsRows.length + 1,
};
const updatedRows = [...existingRoundsRows, newRow];
writeNdjson(paths.roundsPath, updatedRows);
```

The Phase 208 preflight/sign-off verifier should require two committed rows for `scope=foundation`, same epoch, trailing `dry === true`, and a non-null `bundle_sha256`.

### `accrue_admin/e2e/ratchet/finding-regressions.ndjson` and Phase 200 `regressions.ndjson` (model/regression logs, batch + file-I/O)

**Analogs:** `phase-ratchet-ledger.mjs` 0-byte writer and `verify_ratchet_ledger.mjs` zero-byte check.

**0-byte-on-empty writer** (`phase-ratchet-ledger.mjs` lines 126-130):
```javascript
function writeNdjson(absPath, rows) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  const text = rows.map((row) => JSON.stringify(row)).join("\n") + (rows.length ? "\n" : "");
  fs.writeFileSync(absPath, text);
}
```

**Both regression files are currently 0 bytes:**
```text
accrue_admin/e2e/ratchet/finding-regressions.ndjson
.planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/regressions.ndjson
```

### `accrue_admin/package.json` (config, command wiring)

**Analog:** existing script block and Phase 200 package contract.

**Ratchet script pattern** (lines 18-29):
```json
"ratchet:propose": "node e2e/ratchet/ratchet-propose.mjs",
"ratchet:self-test": "node e2e/ratchet/ratchet-propose.mjs --self-test",
"ratchet:verify": "node e2e/ratchet/ratchet-verify.mjs",
"ratchet:verify:self-test": "node e2e/ratchet/ratchet-verify.mjs --self-test",
"ratchet:ledger": "node e2e/ratchet/phase-ratchet-ledger.mjs && node ../scripts/ci/verify_ratchet_ledger.mjs",
"ratchet:ledger:self-test": "node e2e/ratchet/phase-ratchet-ledger.mjs --self-test && node ../scripts/ci/verify_ratchet_ledger.mjs --self-test",
"ratchet:digest": "node e2e/ratchet/ratchet-digest.mjs",
"ratchet:digest:self-test": "node e2e/ratchet/ratchet-digest.mjs --self-test",
"ui:round": "cd .. && mix accrue_admin.ui.round",
"ui:fix": "cd .. && mix accrue_admin.ui.fix"
```

**Phase 200 final guardrail script pattern** (lines 37-40):
```json
"phase200:storybook": "mix test test/accrue_admin/dev/storybook_coverage_test.exs test/accrue_admin/dev/storybook_asset_test.exs test/accrue_admin/theme_test.exs && env -u NO_COLOR playwright test e2e/admin-storybook-a11y-phase200.spec.js --workers=1",
"phase200:scorecard": "node e2e/phase200-scorecard.mjs && node ../scripts/ci/verify_phase200_scorecard.mjs",
"phase200:signoff": "node ../scripts/ci/generate_phase200_closeout_reports.mjs --record-final-statuses && node ../scripts/ci/verify_phase200_signoff.mjs --require-accept",
"phase200:guardrails": "bash ../scripts/ci/verify_phase200_admin_guardrails.sh"
```

**Package script contract pattern** (`verify_phase200_guardrail_contract.sh` lines 64-73, 125-137):
```bash
package_script_value() {
  local script_name="$1"
  node -e '
    const fs = require("fs");
    const pkg = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const script = pkg.scripts && pkg.scripts[process.argv[2]];
    if (!script) process.exit(1);
    process.stdout.write(script);
  ' "$package_file" "$script_name" || fail "missing package script: ${script_name}"
}

printf '%s\n' "$signoff_script" | grep -Fq "node ../scripts/ci/verify_phase200_signoff.mjs --require-accept" ||
  fail "phase200:signoff must require ACCEPT in CI/final guardrails"

require_fixed "$package_file" '"phase200:signoff"'
require_fixed "$package_file" '"phase200:guardrails"'
```

Add Phase 208 package aliases only for deterministic commands, for example `ratchet:signoff`, `ratchet:signoff:self-test`, and `ratchet:ledger:verify-frozen` if implemented. Do not put `--freeze`, `ui.round`, `ui.fix`, `ratchet-propose`, or `ratchet-verify` into the CI-oriented alias.

### `accrue_admin/priv/static/accrue_admin.css`, `assets/css/theme.css`, `assets/css/app.css` (generated/static CSS surfaces)

**Analogs:** `accrue_admin/assets/css/theme.css`, `accrue_admin/assets/css/app.css`, and the workflow asset drift gate.

**Source CSS import/font pattern** (`app.css` lines 1-19):
```css
@import "./theme.css";

@font-face {
  font-family: "Geist";
  font-style: normal;
  font-weight: 100 900;
  font-display: swap;
  src: url("geist-sans-vf.woff2") format("woff2");
}
@font-face {
  font-family: "Geist Mono";
  font-style: normal;
  font-weight: 100 900;
  font-display: swap;
  src: url("geist-mono-vf.woff2") format("woff2");
}
```

**Token registry pattern** (`theme.css` lines 12-33, 82-108):
```css
html.accrue-admin {
  --ax-font-sans: "Geist", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --ax-font-mono: "Geist Mono", "SFMono-Regular", "SF Mono", Consolas, "Liberation Mono", monospace;

  --ax-type-xs: 0.75rem;
  --ax-type-sm: 0.875rem;
  --ax-type-md: 1rem;
  --ax-type-lg: 1.25rem;
  --ax-type-xl: 1.5rem;
  --ax-type-2xl: 1.75rem;
  --ax-type-3xl: 2.25rem;

  --ax-space-xs: 0.25rem;
  --ax-space-sm: 0.5rem;
  --ax-space-md: 1rem;
  --ax-space-lg: 1.5rem;
  --ax-space-xl: 2rem;
  --ax-space-2xl: 3rem;
  --ax-space-3xl: 4rem;

  --ax-type-body-font: 400 var(--ax-type-md)/var(--ax-leading-normal) var(--ax-font-sans);
  --ax-type-label-font: 600 var(--ax-type-sm)/var(--ax-leading-normal) var(--ax-font-sans);
  --ax-type-code-font: 400 var(--ax-type-sm)/var(--ax-leading-normal) var(--ax-font-mono);
}
```

**Status color tokens** (`theme.css` lines 193-217):
```css
--ax-status-success-bg: #e9f5ee;
--ax-status-success-border: #8ebfa5;
--ax-status-success-text: #2f6b4f;
--ax-status-warning-bg: #fff5db;
--ax-status-warning-border: #d59a28;
--ax-status-warning-text: #7a4b00;
--ax-status-danger-bg: #fdecec;
--ax-status-danger-border: #e39b9b;
--ax-status-danger-text: #9b1c1c;
--ax-status-info-bg: #e7f2f8;
--ax-status-info-border: #8bbbd5;
--ax-status-info-text: #1c5277;
--ax-status-neutral-bg: #eef2f5;
--ax-status-neutral-border: #b9c2ca;
--ax-status-neutral-text: #24303b;
```

If implementation changes CSS, edit source CSS or Phoenix components and rebuild. Treat `accrue_admin/priv/static/accrue_admin.css` as the committed generated bundle; keep it fresh with `mix accrue_admin.assets.build` plus `git diff --exit-code`.

### `.planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/UI-RATCHET-SIGN-OFF.md` (documentation/evidence artifact, file-I/O)

**Analogs:** Phase 208 UI-SPEC plus Phase 200 sign-off.

**Required Phase 208 sections/final line** (`208-UI-SPEC.md` lines 68-88):
```markdown
## Executive Status
## Representative Slice Evidence
## Ledger Baseline Summary
## Regression Files
## CI Gate Evidence
## Persona Regression Proof
## Existing UI Gate Status
## Follow-On Runbook
## Maintainer Checkpoint

Final maintainer decision: ACCEPT (maintainer approved {YYYY-MM-DD}). Evidence source: accrue_admin/e2e/ratchet/ledger.baseline.json and .planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/UI-RATCHET-SIGN-OFF.md.
```

**Runbook headings** (`208-UI-SPEC.md` lines 92-106):
```markdown
## Run The Representative Slice
## Read The Digest
## Apply Fixes And Mint Guards
## Freeze The Baseline
## Run Deterministic Guardrails
## Graduate Another Surface
## Recover From A Regression
```

**Required CI copy** (`208-UI-SPEC.md` lines 190-204):
```markdown
| No LLM key | `PASS - ANTHROPIC_API_KEY is not required for this job` |
| Ledger reducer | `PASS - finding-regressions.ndjson is 0 bytes` |
| Independent verifier | `PASS - independent recompute matches ledger.baseline.json` |
| Synthetic count increase | `PASS - synthetic count increase blocks the gate` |
| Persona regression | `PASS - regressed lens count increase blocks the gate` |
| Existing UI gates | `PASS - admin-hardening-guardrails, admin-phase200-guardrails, and asset-drift are green` |
| Bundle freshness | `PASS - accrue_admin.css is fresh` |
```

**Phase 200 sign-off structure** (`200-SIGN-OFF.md` lines 1-57):
```markdown
# Phase 200 Maintainer Sign-Off

## Executive Status

ACCEPT - maintainer approval was received on 2026-06-30, and deterministic Phase 200 artifacts satisfy the all-or-nothing gate.

This file is the sole Phase 200 maintainer decision surface. Structured artifacts remain canonical; markdown summarizes the evidence and repair path.

## Deterministic Artifact Summary

| Artifact | Status | Reference |
| --- | --- | --- |
| `baseline.union.cells.json` | PRESENT | `.planning/phases/200-idempotent-verification-sign-off/baseline.union.cells.json` |

## Maintainer Checkpoint

| Check | Status | Evidence |
| --- | --- | --- |
| Exact final decision line | ACCEPT | `.planning/phases/200-idempotent-verification-sign-off/200-SIGN-OFF.md` |

Final maintainer decision: ACCEPT (maintainer approved 2026-06-30). Evidence source: .planning/phases/200-idempotent-verification-sign-off/artifacts.manifest.json and .planning/phases/200-idempotent-verification-sign-off/judge.findings.json.
```

Use Phase 200's evidence-first tone, but Phase 208 statuses must be `PASS`, `BLOCKED`, `PENDING`, or `N/A`, not `PRESENT`/`ACCEPT` table statuses outside the final decision line.

## Shared Patterns

### Deterministic CI Plane

**Source:** `phase-ratchet-ledger.mjs` lines 1-21; `verify_ratchet_ledger.mjs` lines 1-41; `208-UI-SPEC.md` lines 190-206  
**Apply to:** workflow job, ledger verifier, sign-off verifier, package scripts

- No Anthropic SDK import, no network call, no `ANTHROPIC_API_KEY`.
- CI reads committed artifacts and scratch fixtures.
- CI must not run `ratchet-propose`, `ratchet-verify`, `ui.round`, `ui.fix`, Playwright capture, or `--freeze`.
- Visible status copy uses text states and names the artifact to inspect.

### Self-Test Discipline

**Source:** `verify_ratchet_ledger.mjs` lines 412-449, 465-619; `phase-ratchet-ledger.mjs` lines 630-670, 966-969; `verify_phase200_signoff.mjs` lines 543-648  
**Apply to:** every new or extended `.mjs` verifier

`--self-test` runs before real file reads, uses `fs.mkdtempSync`, writes fixtures under temp dirs, asserts red and green paths, and cleans up in `finally`.

### Shell Contract Error Handling

**Source:** `verify_phase200_ci_contract.sh` lines 1-23; `verify_phase192_ci_contract.sh` lines 43-61  
**Apply to:** `verify_admin_ui_ratchet_ci_contract.sh`

Use `set -euo pipefail`, a local `fail()` function, `require_file`, `require_fixed`, `require_source_fixed`, `require_source_regex`, and `require_source_absent_regex`. Extract only the target job body with `awk` before testing forbidden commands.

### Append-Only Ledger and Regression Logs

**Source:** `ratchet-ledger.js` lines 21-31, 286-405, 472-548; `phase-ratchet-ledger.mjs` lines 126-130, 603-613  
**Apply to:** `findings.ledger.ndjson`, `rounds.ndjson`, `finding-regressions.ndjson`

Ledger lifecycle rows are append-only and monotonic by `seq`. Regression files are NDJSON with an exact 0-byte pass state. Round rows are append-only evidence and must not be regenerated out from under review.

### Baseline Freeze Boundary

**Source:** `phase-ratchet-ledger.mjs` lines 477-497; `ledger.baseline.json` lines 1-44  
**Apply to:** baseline freeze, CI verifier, sign-off verifier

The baseline writer sets `frozen` from the explicit `--freeze` flag and refuses to modify an already frozen baseline without the flag. Phase 208 must reject the current placeholder all-zero empty-file-hash baseline before ACCEPT.

### Representative Slice Source of Truth

**Source:** `accrue_admin/e2e/baseline-manifest.js` lines 250-261  
**Apply to:** score-floor checks, sign-off evidence, runbook
```javascript
const SLICES = {
  foundation: ["component-kitchen", "dashboard", "subscription-detail", "subscriptions"],
};
```

Use `SLICES.foundation` exactly. If mapping `component-kitchen` to Phase 200 cell-census surfaces, add a tested helper that fails when zero rows are examined.

### Evidence Before Markdown

**Source:** `generate_phase200_closeout_reports.mjs` lines 328-365; `verify_phase200_signoff.mjs` lines 294-372  
**Apply to:** `UI-RATCHET-SIGN-OFF.md`, sign-off verifier

Structured artifacts and command statuses feed Markdown. Markdown is the maintainer-readable decision surface, not the source of truth for computed evidence.

### CSS and Asset Freshness

**Source:** `theme.css` lines 12-217; `app.css` lines 1-19; `.github/workflows/ci.yml` lines 423-427  
**Apply to:** incidental admin UI fixes and `accrue_admin/priv/static/accrue_admin.css`

Use existing `ax-*` tokens/components. Rebuild assets and verify the committed static bundle diff. Do not introduce Tailwind, shadcn, external registries, or new runtime dependencies.

## No Analog Found

None. Every Phase 208 implementation surface has a direct or role-level analog. The only new semantics are Phase 208-specific acceptance predicates: frozen non-placeholder baseline, `SLICES.foundation` score >= 2, synthetic count-increase proof, cross-persona/lens regression proof, and the exact `UI-RATCHET-SIGN-OFF.md` section/final-line contract.

## Metadata

**Analog search scope:** `.github/workflows`, `scripts/ci`, `accrue_admin/e2e/ratchet`, `accrue_admin/e2e`, `accrue_admin/assets/css`, `accrue_admin/priv/static`, `accrue_admin/package.json`, `.planning/phases`, `.planning/milestones`  
**Files scanned:** 80+ via `rg` over workflow, verifier, ratchet, package, CSS, and planning artifacts  
**Files/ranges read:** 35+ targeted ranges, with large files read by line-bounded sections  
**Pattern extraction date:** 2026-07-07
