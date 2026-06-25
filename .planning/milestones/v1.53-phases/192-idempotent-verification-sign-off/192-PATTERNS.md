# Phase 192: Idempotent Verification & Sign-Off - Pattern Map

**Mapped:** 2026-06-19
**Files analyzed:** 11
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/ci/verify_phase192_scorecard.mjs` | utility | transform | `scripts/ci/verify_phase191_ax187_coverage.mjs` | role-match |
| `accrue_admin/e2e/phase192-scorecard.mjs` | utility | transform | `accrue_admin/e2e/baseline-artifacts.mjs` | exact |
| `accrue_admin/e2e/phase192-gallery.mjs` | utility | file-I/O | `accrue_admin/e2e/baseline-artifacts.mjs` | role-match |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` `admin-group-contracts` job | exact |
| `accrue_admin/package.json` | config | batch | `accrue_admin/package.json` scripts | exact |
| `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` | test | request-response | `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` | exact |
| `.planning/phases/192-idempotent-verification-sign-off/final.cells.json` | model | transform | `.planning/phases/187-audit-baseline/schemas/baseline-cell.schema.json` | exact |
| `.planning/phases/192-idempotent-verification-sign-off/scorecard.delta.json` | model | transform | `accrue_admin/e2e/baseline-artifacts.mjs` cell contract | role-match |
| `.planning/phases/192-idempotent-verification-sign-off/regressions.ndjson` | model | transform | `.planning/phases/187-audit-baseline/schemas/defect.schema.json` | role-match |
| `.planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json` | model | file-I/O | `accrue_admin/e2e/baseline-artifacts.mjs` artifact manifest | exact |
| `.planning/phases/192-idempotent-verification-sign-off/192-SCORECARD.md` and `192-SIGN-OFF.md` | documentation | transform | `accrue_admin/e2e/baseline-artifacts.mjs` markdown generator | role-match |

## Pattern Assignments

### `scripts/ci/verify_phase192_scorecard.mjs` (utility, transform)

**Analog:** `scripts/ci/verify_phase191_ax187_coverage.mjs`

**Imports and repo-root pattern** (lines 1-17):
```javascript
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, "..", "..");

const LEDGER_PATH =
  process.env.PHASE191_DEFECTS_PATH ||
  path.join(REPO_ROOT, ".planning/phases/187-audit-baseline/defects.ndjson");
```

**JSON/NDJSON read and parse failure pattern** (lines 43-61):
```javascript
function readFile(filePath) {
  try {
    return fs.readFileSync(filePath, "utf8");
  } catch (error) {
    throw new Error(`Unable to read ${filePath}: ${error.message}`);
  }
}

function readNdjson(filePath) {
  return readFile(filePath)
    .split(/\r?\n/)
    .filter(Boolean)
    .map((line, index) => {
      try {
        return JSON.parse(line);
      } catch (error) {
        throw new Error(`${filePath}:${index + 1}: ${error.message}`);
      }
    });
}
```

**Failure report pattern** (lines 114-123):
```javascript
function failWithReport(sections) {
  console.error("Phase 191 AX187 coverage audit failed.");
  for (const section of sections) {
    if (section.items.length === 0) continue;
    console.error(`\n${section.title}:`);
    for (const item of section.items.slice(0, 40)) console.error(`- ${item}`);
    if (section.items.length > 40) console.error(`- ...and ${section.items.length - 40} more`);
  }
  process.exit(1);
}
```

**Core verifier pattern** (lines 130-193):
```javascript
const owner191 = readNdjson(LEDGER_PATH).filter((row) => String(row.owner_phase) === "191");
const high = owner191.filter((row) => row.severity === "high");
const medium = owner191.filter((row) => row.severity === "medium");

console.log(`Phase 191 AX187 owner count: ${owner191.length}`);
console.log(`Severity split: high=${severityCounts.high || 0}, medium=${severityCounts.medium || 0}`);

if (
  owner191.length !== 178 ||
  high.length !== 70 ||
  medium.length !== 108 ||
  missingHighDirectIds.length > 0 ||
  missingMediumCoverage.length > 0 ||
  missingD30InHandoff.length > 0 ||
  missingD30Coverage.length > 0
) {
  failWithReport([
    { title: "Unexpected ledger counts", items: /* calculated items */ [] },
    { title: "High-severity rows missing direct spec AX187 IDs", items: missingHighDirectIds },
  ]);
}

console.log("Phase 191 AX187 coverage audit passed.");
```

Copy this shape for Phase 192: read `final.cells.json`, `scorecard.delta.json`, `regressions.ndjson`, and `artifacts.manifest.json`; print summary counts; fail with grouped sections for score downgrades, coverage downgrades, missing evidence refs, malformed rows, and non-empty regressions.

---

### `accrue_admin/e2e/phase192-scorecard.mjs` (utility, transform)

**Analog:** `accrue_admin/e2e/baseline-artifacts.mjs`

**Imports, manifest import, roots, outputs** (lines 1-30):
```javascript
import fs from "fs";
import path from "path";
import { createHash } from "crypto";
import { fileURLToPath } from "url";

import manifest from "./baseline-manifest.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const adminRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(adminRoot, "..");
const testResultsRoot = path.join(adminRoot, "test-results");
const PHASE_ARTIFACT_DIR = ".planning/phases/187-audit-baseline";
const phaseDir = path.join(repoRoot, PHASE_ARTIFACT_DIR);

const OUTPUTS = {
  cells: path.join(phaseDir, "baseline.cells.json"),
  defects: path.join(phaseDir, "defects.ndjson"),
  manifest: path.join(phaseDir, "artifacts.manifest.json"),
  markdown: path.join(phaseDir, "187-BASELINE.md"),
};
```

For Phase 192, keep this layout but set `PHASE_ARTIFACT_DIR` to `.planning/phases/192-idempotent-verification-sign-off` and outputs to `final.cells.json`, `scorecard.delta.json`, `regressions.ndjson`, `artifacts.manifest.json`, `192-SCORECARD.md`, and `192-SIGN-OFF.md`.

**Evidence allowlist and checksums** (lines 39-68):
```javascript
function relativeFromRepo(absPath) {
  return path.relative(repoRoot, absPath).split(path.sep).join("/");
}

function assertEvidencePath(absPath) {
  const rel = relativeFromRepo(absPath);
  if (!rel.startsWith("accrue_admin/test-results/")) {
    throw new Error(`Refusing to reference evidence outside accrue_admin/test-results/: ${rel}`);
  }
  return rel;
}

function sha256(absPath) {
  return createHash("sha256").update(fs.readFileSync(absPath)).digest("hex");
}
```

**Raw evidence parse pattern** (lines 79-120):
```javascript
function readJsonFile(absPath) {
  try {
    return { ok: true, value: JSON.parse(fs.readFileSync(absPath, "utf8")) };
  } catch (error) {
    return { ok: false, error };
  }
}

function readNdjsonFile(absPath) {
  const rows = [];
  const failures = [];
  const body = fs.readFileSync(absPath, "utf8");
  body.split(/\r?\n/).forEach((line, index) => {
    if (!line.trim()) return;
    try {
      rows.push(JSON.parse(line));
    } catch (error) {
      failures.push({
        kind: "harness-error",
        evidence_ref: assertEvidencePath(absPath),
        message: `Invalid NDJSON at line ${index + 1}: ${error.message}`,
      });
    }
  });
  return { rows, failures };
}
```

**Cell contract and normalization pattern** (lines 267-293, 334-359):
```javascript
function baselineCellContract(cell) {
  const contracted = {
    cell_id: cell.cell_id,
    surface: cell.surface,
    surface_type: cell.surface_type,
    mode: cell.mode,
    viewport_width: Number(cell.viewport_width),
    theme: cell.theme,
    state: cell.state,
    dimension: Number(cell.dimension),
    dimension_name: cell.dimension_name,
    score: cell.score ?? null,
    coverage_status: cell.coverage_status,
    evidence_refs: Array.from(new Set(cell.evidence_refs || [])),
    notes: cell.notes || cell.reason || "",
  };
  return contracted;
}

byId.set(id, {
  cell_id: id,
  surface: surface.surface,
  surface_type: surface.surface_type,
  mode: normalized.mode,
  viewport_width: normalized.viewport_width,
  theme: normalized.theme || "light",
  state: normalized.state || "default-populated",
  dimension: dimension.id,
  dimension_name: dimension.name,
  score: normalized.score ?? null,
  coverage_status: normalized.coverage_status || "covered",
  evidence_refs: normalized.evidence_refs || [evidence_ref],
  notes: normalized.notes || normalized.reason || "Imported from raw Phase 187 baseline evidence.",
});
```

For Phase 192, final cells should preserve the same field contract and frozen `p187__...__dXX` grammar. Add delta rows beside them instead of changing final-cell shape.

**Regression/defect row pattern** (lines 500-526):
```javascript
function defectFromInteractionRow(row, evidenceRef) {
  const coverage = ["covered", "gap", "n/a"].includes(row.coverage_status)
    ? row.coverage_status
    : "covered";
  const hasFailure = Boolean(row.failure_kind);
  const hasGap = coverage === "gap";
  if (!hasFailure && !hasGap) return null;

  const cell = interactionCellFromRow(row, evidenceRef);
  const dimension = dimensionFor(row.rubric_dimension) || dimensionFor("interaction-integrity");
  return {
    severity: severityForInteraction(row),
    surface: row.surface || row.interaction_class,
    surface_type: cell.surface_type,
    reproduction: `Run npm run e2e -- e2e/admin-interactions.spec.js and inspect ${evidenceRef} row ${row.probe_id || row.interaction_class}.`,
    expected: row.expected || `${row.interaction_class} satisfies the Phase 187 live interaction contract.`,
    actual: row.actual || row.failure_kind || "Live interaction probe recorded a gap.",
    rubric_dimension: dimension.name,
    cell_id: cell.cell_id,
    evidence_refs: interactionEvidenceRefs(row, evidenceRef),
    status: "gap",
  };
}
```

For `regressions.ndjson`, use this row style but name Phase 192-specific reasons: `score-downgrade`, `coverage-downgrade`, `missing-evidence`, `new-regression`, and `baseline-correction-required`.

**Artifact writing and main guard** (lines 756-764, 874-950):
```javascript
function writeJson(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, `${JSON.stringify(value, null, 2)}\n`);
}

function writeText(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, value);
}

export function main() {
  const inventory = evidenceInventory();
  const artifactManifest = {
    generated_at: new Date().toISOString(),
    phase: "187-audit-baseline",
    outputs: Object.fromEntries(Object.entries(OUTPUTS).map(([key, absPath]) => [key, relativeFromRepo(absPath)])),
    evidence: inventory,
    command_statuses: commandStatuses,
    observations,
    harness_failures: harnessFailures,
  };

  writeJson(OUTPUTS.cells, cells);
  writeText(OUTPUTS.defects, defects.map((defect) => JSON.stringify(defect)).join("\n") + (defects.length ? "\n" : ""));
  writeJson(OUTPUTS.manifest, artifactManifest);
  writeText(OUTPUTS.markdown, markdownSummary(cells, defects, artifactManifest));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    main();
  } catch (error) {
    console.error(`[baseline-artifacts] ${error.stack || error.message}`);
    process.exit(1);
  }
}
```

---

### `accrue_admin/e2e/phase192-gallery.mjs` (utility, file-I/O)

**Analog:** `accrue_admin/e2e/baseline-artifacts.mjs`

**Evidence inventory pattern** (lines 123-132):
```javascript
function evidenceInventory() {
  return listFiles(testResultsRoot)
    .filter((absPath) => fs.statSync(absPath).isFile())
    .filter((absPath) => path.basename(absPath) !== ".DS_Store")
    .map((absPath) => ({
      path: assertEvidencePath(absPath),
      sha256: sha256(absPath),
      bytes: fs.statSync(absPath).size,
    }))
    .sort((a, b) => a.path.localeCompare(b.path));
}
```

**Screenshot-to-cell reference pattern** (lines 245-264):
```javascript
function screenshotEvidenceByCell(inventory) {
  const refs = new Map();
  for (const item of inventory) {
    const match = item.path.match(
      /^accrue_admin\/test-results\/admin-visuals\/([^/]+)\/(.+?)(-dark)?\.png$/
    );
    if (!match) continue;

    const [, projectName, screen, darkSuffix] = match;
    const surface = surfaceForName(screen);
    const project = projectForMode(projectName);
    if (!surface || !project) continue;

    const theme = darkSuffix ? "dark" : "light";
    for (const dimension of DIMENSIONS) {
      const id = cellId(surface.surface, project.name, theme, "default-populated", dimension.id);
      refs.set(id, [...(refs.get(id) || []), item.path]);
    }
  }
  return refs;
}
```

Phase 192 gallery rows should use this evidence-ref approach, but output maintainer fields from the UI contract: `who`, `job`, `route/surface`, `state`, `theme`, `viewport`, `evidence_ref`, `why_this_matters`, and `accept/block`.

---

### `.github/workflows/ci.yml` (config, batch)

**Analog:** existing `admin-group-contracts` job in `.github/workflows/ci.yml`

**Job shell, services, and env pattern** (lines 431-457):
```yaml
admin-group-contracts:
  name: Admin group contracts (Phase 190)
  if: github.event_name != 'schedule'
  runs-on: ubuntu-24.04

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

  env:
    MIX_ENV: test
    PGUSER: postgres
    PGPASSWORD: postgres
    PGHOST: localhost
    ACCRUE_ADMIN_E2E_PORT: 4017
```

**Change detection and contract verifier pattern** (lines 463-494):
```yaml
- name: Detect Phase 190 browser-relevant changes
  id: phase190_changes
  env:
    BASE_SHA: ${{ github.event.pull_request.base.sha }}
    BEFORE_SHA: ${{ github.event.before }}
  run: |
    set -euo pipefail
    relevant=false
    if [ "$GITHUB_EVENT_NAME" = "workflow_dispatch" ]; then
      relevant=true
    else
      git diff --name-only "$from_sha" "$GITHUB_SHA" > /tmp/phase190-changed-files.txt
      if grep -Eq '^(accrue/|accrue_admin/|scripts/ci/verify_phase190_automation_contract\.sh|\.github/workflows/ci\.yml|\.planning/phases/190-navigation-data-display-meta-component-cohesion/)' /tmp/phase190-changed-files.txt; then
        relevant=true
      fi
    fi
    echo "relevant=$relevant" >> "$GITHUB_OUTPUT"

- name: Phase 190 automation contract
  run: bash scripts/ci/verify_phase190_automation_contract.sh
```

**Setup and serial Playwright command pattern** (lines 496-542):
```yaml
- name: Set up BEAM
  if: steps.phase190_changes.outputs.relevant == 'true'
  uses: erlef/setup-beam@v1
  with:
    otp-version: '28.0'
    elixir-version: '1.19.5'

- name: Set up Node
  if: steps.phase190_changes.outputs.relevant == 'true'
  uses: actions/setup-node@v6
  with:
    node-version: '22'
    cache: npm
    cache-dependency-path: accrue_admin/package-lock.json

- name: Install browser deps
  if: steps.phase190_changes.outputs.relevant == 'true'
  run: cd accrue_admin && npm ci

- name: Install Chromium
  if: steps.phase190_changes.outputs.relevant == 'true'
  run: cd accrue_admin && npx playwright install --with-deps chromium

- name: Run Phase 190 group-contract browser gate
  if: steps.phase190_changes.outputs.relevant == 'true'
  run: cd accrue_admin && npm run e2e:group-contracts
```

**Artifact upload pattern** (lines 544-558):
```yaml
- name: Upload Playwright report
  if: failure() && steps.phase190_changes.outputs.relevant == 'true'
  uses: actions/upload-artifact@v7
  with:
    name: admin-group-contracts-playwright-report
    path: accrue_admin/playwright-report
    if-no-files-found: ignore

- name: Upload Playwright traces
  if: failure() && steps.phase190_changes.outputs.relevant == 'true'
  uses: actions/upload-artifact@v7
  with:
    name: admin-group-contracts-playwright-traces
    path: accrue_admin/test-results
    if-no-files-found: ignore
```

Phase 192 should either extend this job or create `admin-hardening-guardrails` with the same setup. Run deterministic commands serially: `baseline:parse`, `verify_phase191_ax187_coverage.mjs`, `e2e:group-contracts`, `e2e:phase191`, `e2e:a11y`, reduced-motion, component-lab structural coverage, then `verify_phase192_scorecard.mjs` if generated artifacts are in scope for that CI lane.

---

### `accrue_admin/package.json` (config, batch)

**Analog:** existing scripts in `accrue_admin/package.json`

**Script naming pattern** (lines 4-13):
```json
"scripts": {
  "e2e": "env -u NO_COLOR playwright test",
  "e2e:group-contracts": "env -u NO_COLOR playwright test e2e/admin-group-contracts.spec.js --timeout=60000 --workers=1",
  "e2e:visuals:png-only": "env -u NO_COLOR playwright test e2e/admin-visuals.spec.js",
  "e2e:phase191": "env -u NO_COLOR playwright test e2e/admin-page-flow-phase191.spec.js --timeout=60000 --workers=1",
  "e2e:a11y": "env -u NO_COLOR playwright test e2e/admin-a11y.spec.js",
  "e2e:install": "playwright install chromium",
  "score-visuals": "node e2e/score-visuals.mjs",
  "baseline:artifacts": "node e2e/baseline-artifacts.mjs",
  "baseline:parse": "node -e 'const fs=require(\"fs\"), path=require(\"path\"); /* parse artifacts */ console.log(\"baseline artifacts parse ok\")'"
}
```

Add scripts in this style, for example `phase192:scorecard`, `phase192:gallery`, and `phase192:verify`. Keep `score-visuals` advisory and do not route it into required PR CI.

---

### `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` (test, request-response)

**Analog:** same file

**Test module setup pattern** (lines 1-14):
```elixir
defmodule AccrueAdmin.Dev.ComponentRegistryTest do
  @moduledoc false

  use AccrueAdmin.LiveCase, async: false
  use Phoenix.Component

  alias AccrueAdmin.Components.Button
  alias AccrueAdmin.Dev.ComponentRegistry
```

**Group contract coverage pattern** (lines 37-63):
```elixir
test "group contracts enumerate Phase 187 component groups with static UI-SPEC slugs" do
  contracts = ComponentRegistry.group_contracts()

  assert Enum.map(contracts, & &1.name) == @phase187_component_groups
  assert Enum.map(contracts, & &1.slug) == @phase190_group_slugs
  assert ComponentRegistry.component_group_slugs() == @phase190_group_slugs

  for contract <- contracts do
    assert is_binary(contract.proof_id) and contract.proof_id != ""
    assert is_list(contract.required_states) and contract.required_states != []
    assert is_list(contract.primary_components) and contract.primary_components != []
    assert is_list(contract.locators) and contract.locators != []
    assert is_list(contract.phase191_handoff_tags) and contract.phase191_handoff_tags != []
    assert String.match?(contract.slug, ~r/^[a-z0-9-]+$/)
  end
end
```

**Mounted component-lab proof pattern** (lines 288-309):
```elixir
test "mounted /dev/components page has the state grid and data-ax-state cells", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

  assert {:ok, _view, html} = live(conn, "/billing/dev/components")

  assert html =~ "ax-dev-state-grid",
         "no .ax-dev-state-grid found in /dev/components HTML"

  assert html =~ ~s(data-ax-state="default"),
         "data-ax-state=\"default\" not found in /dev/components HTML"

  assert html =~ "data-ax-na-reason",
         "data-ax-na-reason attribute not found in /dev/components HTML (n/a state cells missing)"
end
```

Use this test file for the Phase 192 component-lab structural coverage check rather than adding a new UI registry.

---

### `final.cells.json` (model, transform)

**Analog:** `.planning/phases/187-audit-baseline/schemas/baseline-cell.schema.json`

**Schema contract** (lines 8-22, 32-47, 63-100):
```json
"required": [
  "cell_id",
  "surface",
  "surface_type",
  "mode",
  "viewport_width",
  "theme",
  "state",
  "dimension",
  "dimension_name",
  "score",
  "coverage_status",
  "evidence_refs",
  "notes"
],
"surface_type": { "enum": ["component", "component-group", "page-flow"] },
"mode": { "enum": ["chromium-desktop", "chromium-mobile", "targeted"] },
"theme": { "enum": ["light", "dark"] },
"dimension": { "minimum": 1, "maximum": 12 },
"score": { "type": ["integer", "null"], "enum": [0, 1, 2, 3, null] },
"coverage_status": { "enum": ["covered", "gap", "n/a"] },
"evidence_refs": { "type": "array", "uniqueItems": true }
```

Use the same field names and enums. Phase 192 may add a sibling schema later, but the planner should start from this contract.

---

### `scorecard.delta.json` (model, transform)

**Analog:** `accrue_admin/e2e/baseline-artifacts.mjs`

Use the map-by-cell-id pattern from `buildBaselineCells` (lines 295-371):
```javascript
function buildBaselineCells(inventory, rawRows, harnessFailures) {
  const evidenceByCell = screenshotEvidenceByCell(inventory);
  const cells = SURFACES.flatMap((surface) => cellsForSurface(surface));
  const byId = new Map(cells.map((cell) => [cell.cell_id, cell]));

  for (const { row, evidence_ref } of rawRows) {
    const normalized = normalizeRawBaselineRow(row, evidence_ref);
    if (!normalized) continue;
    const id = normalized.cell_id || cellId(/* surface, mode, theme, state, dimension */);
    byId.set(id, { cell_id: id, /* normalized row */ });
  }

  return Array.from(byId.values())
    .map(baselineCellContract)
    .sort((a, b) => a.cell_id.localeCompare(b.cell_id));
}
```

For deltas, create `baselineById` and `finalById` maps, compare every comparable `p187__` cell, and write rows sorted by `cell_id`. Include `baseline_score`, `final_score`, `score_delta`, `baseline_coverage_status`, `final_coverage_status`, `coverage_downgrade`, `score_downgrade`, `evidence_refs`, and optional `correction_note`.

---

### `regressions.ndjson` (model, transform)

**Analog:** `.planning/phases/187-audit-baseline/schemas/defect.schema.json`

**Defect row contract to copy** (lines 8-24, 30-40, 58-74, 102-120):
```json
"required": [
  "id",
  "severity",
  "surface",
  "surface_type",
  "persona_job",
  "reproduction",
  "expected",
  "actual",
  "rubric_dimension",
  "overlay_tags",
  "cell_id",
  "evidence_refs",
  "owner_phase",
  "status",
  "notes"
],
"severity": { "enum": ["critical", "high", "medium", "low"] },
"surface_type": { "enum": ["component", "component-group", "page-flow"] },
"rubric_dimension": {
  "enum": ["token-compliance", "visual-hierarchy", "spacing-rhythm", "state-coverage", "responsive-mobile-first", "contrast", "focus-semantics", "brand-expression", "motion", "reuse-dry", "interaction-integrity", "microcopy"]
},
"evidence_refs": { "type": "array", "uniqueItems": true },
"status": { "enum": ["open", "confirmed", "gap", "n/a"] }
```

Phase 192 can use IDs like `P192-REG-001` if a new schema is introduced, but should retain the field semantics and NDJSON one-row-per-blocker format.

---

### `artifacts.manifest.json` (model, file-I/O)

**Analog:** `accrue_admin/e2e/baseline-artifacts.mjs`

**Manifest construction pattern** (lines 898-910):
```javascript
const commandStatuses = readCommandStatuses();

const artifactManifest = {
  generated_at: new Date().toISOString(),
  phase: "187-audit-baseline",
  outputs: Object.fromEntries(
    Object.entries(OUTPUTS).map(([key, absPath]) => [key, relativeFromRepo(absPath)])
  ),
  evidence: inventory,
  command_statuses: commandStatuses,
  observations,
  harness_failures: harnessFailures,
};
```

For Phase 192, set `phase: "192-idempotent-verification-sign-off"` and include links/checksums for final scorecard artifacts, Playwright reports, traces, screenshots, command logs, and curated gallery evidence refs.

---

### `192-SCORECARD.md` and `192-SIGN-OFF.md` (documentation, transform)

**Analog:** `accrue_admin/e2e/baseline-artifacts.mjs`

**Markdown table and summary pattern** (lines 775-871):
```javascript
function markdownTable(rows, headers) {
  if (rows.length === 0) return "_None._\n";
  return [
    `| ${headers.join(" | ")} |`,
    `| ${headers.map(() => "---").join(" | ")} |`,
    ...rows.map((row) => `| ${row.join(" | ")} |`),
  ].join("\n") + "\n";
}

function markdownSummary(cells, defects, artifactManifest) {
  const covered = cells.filter((cell) => cell.coverage_status === "covered").length;
  const gaps = cells.filter((cell) => cell.coverage_status === "gap").length;
  const coverageRows = countBy(cells, (cell) => cell.coverage_status);
  const severityRows = countBy(defects, (defect) => defect.severity);

  return `# Phase 187 Baseline

Structured artifacts are canonical for Phase 187 and Phase 192 comparison:
baseline.cells.json and defects.ndjson are canonical.

## Artifact Counts

- Baseline cells: ${cells.length}
- Covered cells: ${covered}
- Gap cells: ${gaps}
- Defects: ${defects.length}
- Evidence files referenced: ${artifactManifest.evidence.length}

${markdownTable(coverageRows.map(([key, count]) => [key, count]), ["Status", "Cells"])}
${markdownTable(severityRows.map(([key, count]) => [key, count]), ["Severity", "Defects"])}
`;
}
```

For Phase 192, regenerate markdown from structured artifacts only. `192-SCORECARD.md` should summarize pass/fail, comparable cells, score downgrades, coverage downgrades, regression count, CI guardrail status, and sign-off state. `192-SIGN-OFF.md` should include curated gallery rows and the maintainer checklist from `192-UI-SPEC.md`.

## Shared Patterns

### Canonical Baseline Vocabulary

**Source:** `accrue_admin/e2e/baseline-manifest.js`
**Apply to:** scorecard reducer, gallery generator, final cells, delta rows, sign-off summaries

**Rubric dimensions and taxonomy** (lines 1-49):
```javascript
const DIMENSIONS = [
  { id: 1, name: "token-compliance" },
  { id: 2, name: "visual-hierarchy" },
  { id: 3, name: "spacing-rhythm" },
  { id: 4, name: "state-coverage" },
  { id: 5, name: "responsive-mobile-first" },
  { id: 6, name: "contrast" },
  { id: 7, name: "focus-semantics" },
  { id: 8, name: "brand-expression" },
  { id: 9, name: "motion" },
  { id: 10, name: "reuse-dry" },
  { id: 11, name: "interaction-integrity" },
  { id: 12, name: "microcopy" },
];

const STATE_TAXONOMY = [
  "default-populated",
  "empty",
  "loading",
  "error",
  "permission-denied",
  "disconnected-reconnecting",
  "overflow",
  "long-content",
  "disabled-readonly",
  "interactive-open",
];

const PROJECTS = [
  { name: "chromium-desktop", mode: "chromium-desktop", viewport_width: 1440 },
  { name: "chromium-mobile", mode: "chromium-mobile", viewport_width: 390 },
];
```

### Playwright Evidence Lens

**Source:** `accrue_admin/playwright.config.js`
**Apply to:** all browser evidence specs and CI guardrails

**Config pattern** (lines 7-36):
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
  },
  webServer: {
    command: `MIX_ENV=test ACCRUE_ADMIN_E2E_PORT=${port} mix accrue_admin.e2e.server`,
    url: `${baseURL}/__e2e__/health`,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000
  },
  projects: [
    { name: "chromium-desktop", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } } },
    { name: "chromium-mobile", use: { ...devices["Pixel 5"] } }
  ],
  outputDir: "test-results"
});
```

### Axe Accessibility Guardrail

**Source:** `accrue_admin/e2e/admin-a11y.spec.js`
**Apply to:** Phase 192 CI status and final scorecard evidence

**Scan pattern** (lines 23-28, 75-92):
```javascript
async function scan(page, theme) {
  await page.evaluate((t) => document.documentElement.setAttribute("data-theme", t), theme);
  await page.waitForTimeout(50);
  const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa"]).analyze();
  return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
}

const failures = [];
for (const [name, path] of surfaces) {
  await login(page, path);
  await expect(page.locator("#main-content")).toBeVisible();

  for (const theme of ["light", "dark"]) {
    const violations = await scan(page, theme);
    for (const v of violations) {
      failures.push(`${name} [${theme}] ${v.id}: ${v.nodes[0]?.target.join(" ")}`);
    }
  }
}

expect(failures, `axe violations:\n${failures.join("\n")}`).toEqual([]);
```

### Reduced Motion Guardrail

**Source:** `accrue_admin/e2e/reduced-motion.spec.js`
**Apply to:** Phase 192 CI status and final scorecard evidence

**Computed-token assertion pattern** (lines 63-84, 245-267):
```javascript
test("with prefers-reduced-motion:reduce, .ax-button transition-duration collapses to 0s on every segment", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await login(page, "/billing/dev/components");
  await expect(page.locator("#main-content")).toBeVisible();

  const durations = await buttonTransitionDurations(page);

  for (const seg of durations) {
    expect(seg, `under reduced-motion, every .ax-button transition segment must be "0s"`).toBe("0s");
  }
});

test("structural: no transform travel on dropdown/drawer under prefers-reduced-motion", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await login(page, "/billing/dev/components");
  const [riseSm, riseMd] = await page.evaluate(() => {
    const style = window.getComputedStyle(document.documentElement);
    return [style.getPropertyValue("--ax-rise-sm").trim(), style.getPropertyValue("--ax-rise-md").trim()];
  });
  expect(riseSm).toBe("0px");
  expect(riseMd).toBe("0px");
});
```

### Interaction Trace Guardrail

**Source:** `accrue_admin/e2e/admin-page-flow-phase191.spec.js`
**Apply to:** Phase 192 final comparison and sign-off trace refs

**Fixture and route resolution pattern** (lines 115-133, 169-195):
```javascript
async function seedPhase191Matrix(request) {
  const phase191 = await seedScenario(request, "phase191-matrix");
  const dashboard = await seedScenario(request, "dashboard");
  const operatorFlows = await seedScenario(request, "operator-flows");
  const edgeStates = await seedScenario(request, "edge-states");

  return { ...phase191, dashboard, "operator-flows": operatorFlows, "edge-states": edgeStates, phase191 };
}

async function login(page, target = "/billing") {
  await page.goto(`/__e2e__/login?to=${encodeURIComponent(target)}`);
  await expect(page.locator("#main-content, main").first()).toBeVisible();
}

for (const flow of flows) {
  const scenario = seedScenarioForSurface(flow);
  const route = resolvePhase191Route(flow, fixtureData);
  expect(route, `${flow.surface} route should resolve from ${scenario}`).toMatch(/^\/billing/);
  expect(route, `${flow.surface} route should not contain unresolved params`).not.toContain(":");
}
```

### Shell Contract Verifier

**Source:** `scripts/ci/verify_phase190_automation_contract.sh`
**Apply to:** optional Phase 192 workflow/package/artifact contract verifier

**Fail-fast fixed/regex assertions** (lines 1-31, 46-49):
```bash
#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ci_file="$root_dir/.github/workflows/ci.yml"
package_file="$root_dir/accrue_admin/package.json"

fail() {
  echo "verify_phase190_automation_contract: $*" >&2
  exit 1
}

require_fixed() {
  local file="$1"
  local needle="$2"
  grep -Fq "$needle" "$file" || fail "missing '${needle}' in ${file#$root_dir/}"
}

require_fixed "$package_file" '"e2e:group-contracts"'
require_fixed "$ci_file" "admin-group-contracts:"
require_fixed "$ci_file" "npm run e2e:group-contracts"
require_fixed "$ci_file" "verify_phase190_automation_contract.sh"
```

## No Analog Found

No files are without an analog. Phase 192 is an extension of existing Phase 187/190/191 verification machinery.

## Metadata

**Analog search scope:** `scripts/ci`, `accrue_admin/e2e`, `accrue_admin/test/accrue_admin/dev`, `accrue_admin/lib/accrue_admin/dev`, `.github/workflows`, `.planning/phases/187-audit-baseline`
**Files scanned:** 21 targeted files plus phase artifacts
**Pattern extraction date:** 2026-06-19

