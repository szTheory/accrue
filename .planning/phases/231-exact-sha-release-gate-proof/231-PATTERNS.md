# Phase 231: Exact-SHA Release Gate Proof - Pattern Map

**Mapped:** 2026-09-15
**Files analyzed:** 8 (3 new triads + 2 extended files + 3 CI/ledger wiring surfaces)
**Analogs found:** 8 / 8

All analog paths verified git-tracked via `git ls-files -- <path>` (confirmed this session for every path cited below).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|-----------------|---------------|
| `scripts/ci/collect_window_dispositions.mjs` (name: discretion) | utility (collector) | transform (git/ledger facts → sanitized JSON) | `scripts/ci/collect_integration_disposition.mjs` | exact — same triad role, same "4th instance" lineage explicitly called out in CONTEXT D-26 |
| `scripts/ci/render_window_dispositions.mjs` | utility (renderer) | transform (JSON → deterministic Markdown) | `scripts/ci/render_integration_disposition.mjs` | exact |
| `scripts/ci/verify_window_dispositions.mjs` | utility (verifier) | request-response / batch (re-derive + assert exact equality) | `scripts/ci/verify_integration_disposition.mjs` | exact |
| `scripts/ci/collect_ci_baseline.mjs` (extend for GATE-02 required-job-set-drift + event-class field, D-18/D-19) | utility (collector, extended in place) | streaming (GitHub Actions run/job polling) + transform | itself — extend, do not fork (this is the analog for its own extension) | exact (self) |
| `231-GATE-01-EVIDENCE.{json,md}` collect/render/verify (or folded into an existing artifact — discretion) | utility (evidence triad) | batch (scratch-clone cohort run → evidence) | `scripts/ci/collect_repository_inventory.mjs` / `render_repository_inventory.mjs` / `verify_repository_inventory.mjs` | role-match — closest analog for "run a fixed enumerated set of local checks and record pass/fail per item with a closed reason vocabulary" |
| `231-ROLLBACK-POINT.json` (re-mint script/invocation) | utility (evidence artifact, no new script framework) | batch (scratch-clone revert proof) | Phase 230's own `230-ROLLBACK-POINT.json` generation logic (reused pattern, not a new file to design) | exact — D-07 explicitly says re-mint via the same scratch-clone `git revert -m 1` proof pattern, superseding by reference |
| `.github/workflows/ci.yml` (wire new verifiers' `--fixtures` self-tests into `docs-contracts-shift-left`) | config (CI wiring) | event-driven (CI job step) | the `verify_phase230_archive_invariants.mjs` three-step block at `.github/workflows/ci.yml:182-185` | exact |
| `scripts/ci/README.md` (add evidence-table rows for new 231 artifacts) | config (contributor docs) | transform (doc row per artifact) | the Phase 230 rows at `scripts/ci/README.md:151-161` | exact |
| `.planning/WINDOWS.md` status flips (via `gsd-tools windows waive/fixed`, NOT hand-edited) | data (terse ledger) | CRUD (status transitions only, no schema change) | itself, mutated only through `~/.claude/gsd-core/bin/lib/broken-windows.cjs`'s `markWaived`/`cmdWindowsMarkFixed` | exact — do not treat as a "new file," treat the writer CLI as the analog for *how* to touch it |

## Pattern Assignments

### `scripts/ci/collect_window_dispositions.mjs` (utility/collector, 4th triad instance)

**Analog:** `scripts/ci/collect_integration_disposition.mjs` (1259 lines, read this session)

**Imports pattern** (lines 1-7):
```javascript
#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import test from "node:test";
```

**Validation primitives** (lines 9-27) — reuse verbatim, adapting the regexes/enums to window-disposition fields:
```javascript
const SHA = /^[a-f0-9]{40}$/;
const REPOSITORY = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const ISO = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/;
const STATES = new Set(["proved", "failed", "skipped", "advisory", "non_run"]);
const REJECTED_STATES = new Set(["deferred", "n/a", "green"]);

const fail = (message) => { throw new Error(message); };
function fields(value, allowed, label) { if (!value || Array.isArray(value) || typeof value !== "object") fail(`${label} must be an object`); for (const key of Object.keys(value)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`); }
function fullSha(value, label) { if (typeof value !== "string" || !SHA.test(value)) fail(`${label} must be a full lowercase SHA`); return value; }
function run(repo, args) { const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 }); if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`); return result.stdout.trim(); }
```

**Closed enum pattern** (lines 43-51) — the row-`kind` disposition (D-22: `unrun-verify` vs `deviation`) should be a closed `Set` exactly like `HAZARD_CLASSES`:
```javascript
// D-14: closed hazard-class enumeration. Unknown class => hard failure, never pass-through.
export const HAZARD_CLASSES = new Set([
  "convergent-identical", "disjoint-hunk", "version-release-train-drift",
  "version-keyed-contract-script", "dependency-lock-drift", "schema-relaxation",
  "doc-rewrite", "archive-path-regression", "generated-artifact-staleness"
]);
```
Adapt directly to e.g. `const ROW_KINDS = new Set(["unrun-verify", "deviation"]);` and `const ROW_DISPOSITIONS = new Set(["fixed", "waived"]);` — unknown value fails hard, never pass-through.

**Row-id join pattern** — D-26 requires the sibling artifact join 1:1 by WINDOWS.md row id. Model the row schema on the excluded-commit ledger row shape (lines ~28-33, `POST_MERGE_ROW_FIELDS`/`HAZARD_FIELDS`):
```javascript
const HAZARD_FIELDS = new Set(["path", "class", "state", "exit_code", "evidence", "owner"]);
```
→ adapt to e.g. `const WINDOW_ROW_FIELDS = new Set(["id", "kind", "disposition", "state", "exit_code", "owner", "rationale", "release_impact", "current_evidence", "resolved_at"]);`

**CLI + fixture-mode wiring pattern** (lines 869-911, verbatim structure to clone):
```javascript
function parseArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    if (!argv[index].startsWith("--") || !argv[index + 1]) fail("usage: --repo PATH --expected-repository OWNER/REPO [--candidate-ref REF] --out FILE [--ledger-out FILE] ...");
    result[argv[index].slice(2)] = argv[++index];
  }
  return result;
}
function main() {
  const options = parseArgs(process.argv.slice(2));
  if (!options.repo || !options["expected-repository"] || !options.out) fail("--repo, --expected-repository, and --out are required");
  const disposition = collectIntegrationDisposition({ /* ... */ });
  fs.writeFileSync(options.out, `${JSON.stringify(disposition, null, 2)}\n`, { mode: 0o600 });
}
if (!process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  try { main(); } catch (error) { console.error(`integration disposition collect: FAIL: ${error.message}`); process.exitCode = 1; }
}
if (process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  function fixtureRepo() { /* mkdtemp scratch git repo, no network */ }
  test("...", () => { /* ... */ });
}
```
Note: `fs.writeFileSync(..., { mode: 0o600 })` on every emitted artifact — reuse verbatim (D-31 sanitization + the 229-19 0644/0600 lesson referenced in CONTEXT.md D-28).

**Error handling pattern:** every failure path is a single `fail(message)` throw (no custom error classes), caught once at the top-level `try`/`catch` in the `main()` invocation guard, printed as `<script-name>: FAIL: <message>`, `process.exitCode = 1`. Reuse verbatim — no new error-handling design needed.

---

### `scripts/ci/render_window_dispositions.mjs` (utility/renderer)

**Analog:** `scripts/ci/render_integration_disposition.mjs` (441 lines, read this session)

**Imports + escaping + splice-marker pattern** (lines 1-16):
```javascript
#!/usr/bin/env node
import fs from "node:fs";
import assert from "node:assert/strict";
import test from "node:test";
import { validateDisposition, validateDispositionLedger, HAZARD_CLASSES } from "./collect_integration_disposition.mjs";

const escape = (value) => String(value).replace(/[\\|`<>]/g, "\\$&").replace(/[\r\n]+/g, " ");
const order = (rows, key) => [...rows].sort((a, b) => key(a).localeCompare(key(b)));
function section(title, state, owner, command, evidence, rows = [], headings = []) {
  return ["## " + title, "", `**Fact:** ${escape(evidence)}. **State:** ${escape(state)}. **Owner:** ${escape(owner)}. **Next command:** \`${escape(command)}\`.`, "", ...headings, ...rows, ""];
}

// D-39: a stable start/end HTML comment marker pair so Phase 232 can splice this
// block into the integration PR body without re-deriving the content.
export const SPLICE_START = "<!-- phase230-integration-disposition:start -->";
export const SPLICE_END = "<!-- phase230-integration-disposition:end -->";
```
Adapt splice markers to `<!-- phase231-window-dispositions:start/end -->` — follow the specifics guidance ("maintainer's actual question... under a minute, leading with anything `failed` or `waived`") by ordering sections `waived` → `failed`-if-any → `fixed`, mirroring how this file buckets hazards by closed class with a zero-row section rendered explicitly rather than omitted (lines 30-33).

**Closed-class bucketing pattern** (lines 30-48) — every declared `kind`/`disposition` value gets its own section even with 0 rows (never silently omit an empty bucket):
```javascript
const hazardsByClass = new Map([...HAZARD_CLASSES].map((cls) => [cls, []]));
for (const row of value.hazards) hazardsByClass.get(row.class).push(row);
```

**Determinism contract:** `renderIntegrationDisposition(disposition, opts)` is a pure function of validated JSON — no `Date.now()`, no filesystem reads beyond the input. Timestamps must come from `git show -s --format=%cI` captured at *collect* time and carried through the JSON, never generated at render time (D-31).

---

### `scripts/ci/verify_window_dispositions.mjs` (utility/verifier)

**Analog:** `scripts/ci/verify_integration_disposition.mjs` (737 lines, read this session)

**Imports pattern** (lines 1-30) — imports the collector's exported validators/constants and the renderer's render functions, never re-implements them:
```javascript
#!/usr/bin/env node
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import {
  V161_TAG_OBJECT, V161_COMMIT_OBJECT, CLOSURE_COMMITS, CANONICAL_D21_LANES,
  buildMergeCandidateForTests, collectAncestryGates, collectCoTouchedFiles,
  collectExcludedCommitLedger, collectIntegrationDisposition, collectScope,
  validateDisposition, validateDispositionLedger, validateExcludedRow, validateLaneRow
} from "./collect_integration_disposition.mjs";
import { renderIntegrationDisposition, renderExcludedLedger } from "./render_integration_disposition.mjs";
```

**Completeness-assertion helpers — reuse verbatim, do not reimplement** (lines 34-70):
```javascript
function assertSameMultiset(authorityName, authority, candidateName, candidate, keyOf) {
  const expected = authority.map(keyOf).sort();
  const actual = candidate.map(keyOf).sort();
  if (expected.length !== actual.length || expected.some((value, index) => value !== actual[index])) {
    fail(`${candidateName} differs from ${authorityName}: expected=[${expected.join(", ")}] actual=[${actual.join(", ")}]`);
  }
}
// D-37: exact-map completeness with a missing/extra/changed triple, recomputed inside
// the verifier -- never a non-empty check, never an asserted boolean.
function exactMap(rows, label, keyOf, valueOf) {
  const result = new Map();
  for (const row of rows) {
    const key = keyOf(row);
    if (result.has(key)) fail(`${label} contains duplicate mapping: ${key}`);
    result.set(key, valueOf(row));
  }
  return result;
}
function assertSameMap(authorityName, authority, candidateName, candidate) {
  const missing = [...authority.keys()].filter((key) => !candidate.has(key)).sort();
  const extra = [...candidate.keys()].filter((key) => !authority.has(key)).sort();
  const changed = [...authority.keys()].filter((key) => candidate.has(key) && candidate.get(key) !== authority.get(key)).sort();
  if (missing.length || extra.length || changed.length) {
    fail(`${candidateName} differs from ${authorityName}: missing=[${missing.join(", ")}] extra=[${extra.join(", ")}] changed=[${changed.join(", ")}]`);
  }
}
```
Apply the 1:1 row-id join (D-26) with `exactMap(windowsRows, "WINDOWS.md rows", (r) => r.id, () => true)` vs `exactMap(dispositionRows, "231-WINDOW-DISPOSITIONS rows", (r) => r.id, () => true)`, then `assertSameMap(...)` both directions — this is the *exact* mechanism already used for the hazard-universe join at `verify_integration_disposition.mjs:157-158`.

**`directShipWindows`-style authority read for the join's other half** — reuse the 10-column WINDOWS.md parser verbatim as the "live" side of the multiset/map comparison (from `scripts/ci/verify_repository_inventory.mjs:523-547`, quoted in RESEARCH.md's Pattern 3) — **do not re-implement a second WINDOWS.md parser**; import or re-derive identically.

**`--fixtures` self-test + strict-flag CLI pattern** (lines 675-737, `main()`):
```javascript
async function main() {
  const parsed = options(process.argv.slice(2));
  if (parsed.flags.has("fixtures")) { verifyFixtures(); console.log("integration disposition fixtures: PASS"); return; }
  const expectedRepository = parsed.values["expected-repository"];
  if (!expectedRepository) fail("--expected-repository is required");
  const repo = parsed.values.repo || process.cwd();
  // ... --require-* flags gate each strict assertion independently ...
  const requestedStrictFlags = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();
  const verificationSuffix = requestedStrictFlags.length
    ? ` (verified: ${requestedStrictFlags.join(", ")})`
    : " (schema-only: no --require-* flags supplied, no ... check ran)";
  console.log(`integration disposition verification: PASS${verificationSuffix}`);
}
if (process.env.NODE_TEST_CONTEXT) {
  test("integration disposition fixtures pass every negative control", () => verifyFixtures());
} else {
  main().catch((error) => { console.error(`integration disposition verify: FAIL: ${error.message}`); process.exitCode = 1; });
}
```
This is the pattern that makes a schema-only invocation *visually distinct* from a fully-strict one — carry it forward so a `verify_window_dispositions.mjs` run without `--require-...` flags can never be mistaken for full GATE-03 coverage.

**Render-determinism assertion pattern** (lines ~697-700): re-render from the committed JSON and byte-compare against the committed Markdown — reuse verbatim per D-31.

---

### `scripts/ci/collect_ci_baseline.mjs` extension (GATE-02, D-18/D-19)

**Analog:** itself — extend in place, never fork (D-19 is explicit: "Extend `scripts/ci/collect_ci_baseline.mjs` rather than writing a parallel mechanism").

**Imports pattern** (lines 1-8):
```javascript
#!/usr/bin/env node
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";
```

**Closed enum / no-alias pattern** (lines 10-11) — the exact wording D-19 cites:
```javascript
const PROVIDER_STATES = new Set(["proved", "failed", "misconfigured", "blocked", "skipped", "non_run"]);
```
There is no `success`/`green` alias reachable anywhere in this enum — extend GATE-02's records through this same closed set; never introduce a `green: true` boolean field (D-29).

**`allowedFields` sanitization pattern** (lines 25-29):
```javascript
function allowedFields(object, allowed, label) {
  if (!object || Array.isArray(object) || typeof object !== "object") fail(`${label} must be an object`);
  for (const key of Object.keys(object)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`);
}
```

**Where the required-job-set-drift assertion (D-18) belongs:** `RUN_INPUT_FIELDS`/`JOB_INPUT_FIELDS` (line 18-19) is the closed field allow-list already gating every run/job record; add an `event_class` field there (D-17's "state its event class in the first screenful") plus a `required_job_set_declared`/`required_job_set_observed` pair validated against `cohortFingerprint`'s existing `required_job_set` derivation (already read from the live job graph, per RESEARCH.md Pattern 1). Cross-check against the in-repo `ci.yml` header comment's declared list (`.github/workflows/ci.yml:9-14`) rather than `branches/main/protection` (404) or `rulesets` (`[]`) — this is a *new* assertion inside the existing verifier, not a new collector.

---

### GATE-01 evidence (scratch-clone cohort run record)

**Analog:** `scripts/ci/collect_repository_inventory.mjs` / `render_repository_inventory.mjs` / `verify_repository_inventory.mjs` — closest existing shape for "enumerate a fixed list of checks, record a closed-vocabulary outcome per item, assert completeness against the declared list."

**Closed-vocabulary parser precedent to reuse for cohort enumeration** (`verify_repository_inventory.mjs:523-547`, quoted verbatim in RESEARCH.md's Pattern 3): the exact-column, exact-count-cross-check pattern — apply the same shape to the 13-lane cohort table (12 merge-blocking jobs + `annotation-sweep` itself), sourcing the authority list from `.github/workflows/ci.yml`'s header comment (D-09) rather than a hand-maintained duplicate list in the new script.

**`assertCompleteCategories`-style completeness gate** (`verify_repository_inventory.mjs`, ~line 583-602, cited in RESEARCH.md) — reuse for "every declared merge-blocking job has exactly one evidence row with a `PROVIDER_STATES`-closed outcome."

---

### `.github/workflows/ci.yml` wiring (three-step self-test convention)

**Analog:** the `verify_phase230_archive_invariants.mjs` block, `.github/workflows/ci.yml:182-185`:
```yaml
      - name: Phase-evidence archive-path sweep (D-22 standing invariant)
        run: >-
          node --test scripts/ci/verify_phase230_archive_invariants.mjs &&
          node scripts/ci/verify_phase230_archive_invariants.mjs --fixtures &&
          node scripts/ci/verify_phase230_archive_invariants.mjs
```
And the richer four-line variant with named `--require-*` flags at lines 192-198 for the triad-with-collector case:
```yaml
      - name: Integration disposition triad units and fixture contract (D-04, D-15, D-20, D-21, D-37)
        run: >-
          node --test scripts/ci/collect_integration_disposition.mjs &&
          node --test scripts/ci/render_integration_disposition.mjs &&
          node --test scripts/ci/verify_integration_disposition.mjs &&
          node scripts/ci/verify_integration_disposition.mjs --fixtures --expected-repository szTheory/accrue --require-hazard-universe
```
New step lands inside the existing `docs-contracts-shift-left` job (this is explicitly named in RESEARCH.md's Integration Points and Architectural Responsibility Map as "where new merge-blocking verifiers land"), immediately after the Phase 230 block at line 185, following the identical `node --test <collect> && node --test <render> && node --test <verify> && node <verify> --fixtures [--require-*]` four-step shape.

---

### `scripts/ci/README.md` evidence-table row (D-32)

**Analog:** the Phase 230 rows, `scripts/ci/README.md:151, 157, 159-161`:
```markdown
The Phase 230 [integration disposition](../../.planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.json) is a fourth collect/render/verify triad instance answering "what did the v1.62 integration candidate merge decide on my behalf..." in under a minute. ...

| [Phase 230 integration disposition](...), [rendered diagnostic](...), [excluded-commit ledger](...), and [rendered ledger](...) | What the merge decided silently on the reviewer's behalf, whether every hazard and every excluded commit has an evidence-backed disposition, and where an excluded commit went | `node scripts/ci/verify_integration_disposition.mjs --records ... --candidate integration/v1.62-candidate --expected-repository szTheory/accrue --require-ancestry --require-scope --require-hazard-universe --require-excluded-ledger --require-post-merge-scope --require-determinism` |

<!-- phase230-integration-disposition:start -->
The rendered disposition Markdown is fenced with a stable `phase230-integration-disposition` start/end marker pair so a later phase can splice the rendered block into the integration PR body without re-deriving the content.
<!-- phase230-integration-disposition:end -->
```
Clone this exact three-part shape (prose paragraph answering "what question does this answer in under a minute" + evidence-table row with the exact verify command + splice-marker note) for GATE-01, GATE-02, and the window-dispositions artifacts.

---

## Shared Patterns

### Proof-state lexicon (non-negotiable, D-29)
**Source:** `scripts/ci/collect_ci_baseline.mjs:11` (`PROVIDER_STATES`) and `scripts/ci/collect_integration_disposition.mjs:12-13` (`STATES`/`REJECTED_STATES`)
**Apply to:** every new GATE-01/02/03 artifact's per-row outcome field.
```javascript
const STATES = new Set(["proved", "failed", "skipped", "advisory", "non_run"]);
const REJECTED_STATES = new Set(["deferred", "n/a", "green"]);
function state(value, label) { if (typeof value !== "string" || REJECTED_STATES.has(value) || !STATES.has(value)) fail(`${label} must be one of proved/failed/skipped/advisory/non_run`); return value; }
```
No aggregate boolean anywhere; `proved` always carries a recorded exit code (`exitCode` validator, `collect_integration_disposition.mjs:25`).

### Completeness = exact set/multiset equality (D-30)
**Source:** `scripts/ci/verify_integration_disposition.mjs:45-70` (`assertSameMultiset`, `exactMap`, `assertSameMap`)
**Apply to:** GATE-01's cohort-vs-declared-list check, GATE-02's required-job-set-vs-`ci.yml`-header check, GATE-03's WINDOWS.md-row-vs-disposition-row join. Reuse the three functions verbatim (import or copy identically) — do not write new `.every()`/`.includes()` ad hoc checks.

### `allowedFields`/`fields` schema sanitization (D-31)
**Source:** `scripts/ci/collect_ci_baseline.mjs:25-28`, `scripts/ci/collect_integration_disposition.mjs:16`
**Apply to:** every object accepted by a `validate*` function in every new artifact — no absolute paths, `$HOME`, actor names, adopter identifiers, secrets reach a committed record.

### `resolvePhaseEvidencePath` for archive-safe artifact resolution (D-32)
**Source:** `scripts/ci/phase_evidence_path.mjs:25-44`
```javascript
export function resolvePhaseEvidencePath(phaseSlug, artifactPath, { root = repositoryRoot } = {}) {
  validatePhaseSlug(phaseSlug);
  validateArtifactPath(artifactPath);
  const active = path.join(root, ".planning", "phases", phaseSlug, artifactPath);
  if (fs.existsSync(active)) return active;
  const milestonesRoot = path.join(root, ".planning", "milestones");
  const matches = fs.existsSync(milestonesRoot)
    ? fs.readdirSync(milestonesRoot, { withFileTypes: true })
      .filter((entry) => entry.isDirectory() && entry.name.endsWith("-phases"))
      .map((entry) => path.join(milestonesRoot, entry.name, phaseSlug, artifactPath))
      .filter((candidate) => fs.existsSync(candidate)).sort()
    : [];
  if (matches.length === 0) throw new Error(`missing phase evidence: ${phaseSlug}/${artifactPath}`);
  if (matches.length > 1) throw new Error(`ambiguous archived phase evidence: ${phaseSlug}/${artifactPath}`);
  return matches[0];
}
```
**Apply to:** all `231-*` artifact path resolution in every new collector/verifier — call `resolvePhaseEvidencePath("231-exact-sha-release-gate-proof", "231-WINDOW-DISPOSITIONS.json")` rather than a hardcoded literal path.

### WINDOWS.md ledger writer (D-25 — do not hand-edit)
**Source:** `~/.claude/gsd-core/bin/lib/broken-windows.cjs` (`markWaived`, `cmdWindowsMarkFixed`), invoked via `gsd-tools windows waive <id> "<reason>"` / `gsd-tools windows fixed <id>`.
**Apply to:** every WINDOWS.md status flip in this phase — never write the file directly. The writer recomputes all four frontmatter counts deterministically.

### Fixture-mode self-test convention (`--fixtures`, `NODE_TEST_CONTEXT`)
**Source:** every collector/verifier in `scripts/ci/` follows this exact split:
- `node --test <file>.mjs` — runs `node:test` unit tests guarded by `process.env.NODE_TEST_CONTEXT`.
- `node <file>.mjs --fixtures` — runs the same fixture-repo negative-control suite as a plain CLI invocation (`verifyFixtures()`), independent of any live repository state.
- `node <file>.mjs [--records ... --rendered ... --require-*]` — the real, live-repository strict mode.
**Apply to:** all three new `collect_window_dispositions.mjs`/`render_window_dispositions.mjs`/`verify_window_dispositions.mjs` files and any GATE-01/GATE-02 additions.

### Read-only observation vs. the one authorized mutation (D-14/D-20)
**Source:** `scripts/ci/ci_monitor.cjs` — `const COMMANDS = new Set(["list", "inspect", "watch"]);` (line 13); `README.md`'s explicit statement that the monitor "does not dispatch, rerun, cancel, or otherwise mutate."
**Apply to:** GATE-02's implementation — the dispatch itself (`gh workflow run ci.yml --ref integration/v1.62-candidate -f run_live_stripe=false`) is a distinct, separately-authorized step; all polling/observation after that goes through `node scripts/ci/ci_monitor.cjs watch --repo szTheory/accrue --sha <full-40-hex> --workflow CI --timeout-seconds <N> --poll-seconds <N>`. Do not write a bespoke poll loop — `watch` already implements the fail-closed deadline semantics (`MAX_TIMEOUT_SECONDS = 3600`, `MAX_POLL_SECONDS = 300`, exits `68` on deadline breach, `69` on unsuccessful completion).

## No Analog Found

None — every file/extension this phase needs has a direct or near-direct existing analog in `scripts/ci/`. This phase is explicitly framed (per RESEARCH.md's own Summary) as "evidence-assembly, not build-work": the fourth collect/render/verify triad, one extended collector, one CI wiring addition, one README addition, and ledger-writer invocations — no net-new architecture.

## Metadata

**Analog search scope:** `scripts/ci/` (all `collect_*.mjs`/`render_*.mjs`/`verify_*.mjs` triads), `.github/workflows/ci.yml`, `.planning/WINDOWS.md`, `~/.claude/gsd-core/bin/lib/broken-windows.cjs`
**Files scanned/read this session:** `scripts/ci/collect_integration_disposition.mjs`, `render_integration_disposition.mjs`, `verify_integration_disposition.mjs`, `collect_ci_baseline.mjs`, `phase_evidence_path.mjs`, `scripts/ci/README.md`, `.github/workflows/ci.yml` (lines 60-225), `scripts/ci/ci_monitor.cjs` (signature grep)
**Pattern extraction date:** 2026-09-15
