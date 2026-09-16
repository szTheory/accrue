# Phase 232: Bounded Hygiene & Release Handoff - Pattern Map

**Mapped:** 2026-09-16
**Files analyzed:** ~27 (6 wholly new .mjs/.sh, 1 shared helper, ~20 guard-migration edits, 5+ modified existing files, 1 re-rendered doc)
**Analogs found:** all mapped — this phase is dominated by "generalize the existing triad shape," not novel invention

All analog paths below were confirmed git-tracked (`git ls-files`) — none are `.gsd/`-mirror paths; this repo has no plugin-capability mirror layer, so the tracked-source gate is satisfied trivially for every path cited.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scripts/ci/main_module.mjs` | utility (module-boundary guard) | transform (pure function) | `scripts/ci/verify_recut_candidate.mjs` lines ~629-631 (existing inline `isMainModule` const — the only file already using that exact name) | role-match (inline pattern to extract, not a standalone module to copy) |
| `scripts/ci/collect_hygiene_dispositions.mjs` | service (evidence collector) | CRUD (git status + fs enumerate → JSON) | `scripts/ci/collect_window_dispositions.mjs` | exact (same triad family, same repo/candidate/rows shape) |
| `scripts/ci/render_hygiene_dispositions.mjs` | transform (deterministic projector) | transform (JSON → Markdown) | `scripts/ci/render_window_dispositions.mjs` | exact |
| `scripts/ci/verify_hygiene_dispositions.mjs` | test/verifier | request-response (CLI, fail-closed) | `scripts/ci/verify_window_dispositions.mjs` | exact |
| `scripts/ci/verify_ci_script_contract.mjs` | test/verifier (meta) | batch (spawns `node --test` per file) | `scripts/ci/verify_gate01_cohort.mjs` (closed-cohort completeness shape) + `scripts/ci/verify_ci_baseline.mjs` (spawns child processes) | role-match, composite |
| `scripts/ci/verify_release_pr_readiness.sh` | test/verifier (shell, external-CLI dry-run) | request-response (spawns `release-please` CLI, asserts stdout) | `scripts/ci/verify_release_preflight.sh` (closest — same "wrap and assert an external/local command sequence, fail closed" shape) and `scripts/ci/capture_linked_release_proof.sh` (closest release-domain sibling, though explicitly NOT reusable per D-40) | role-match |
| `.planning/phases/232-.../232-HYGIENE-DISPOSITIONS.{json,md}` | data artifact | CRUD | `.planning/phases/231-.../231-WINDOW-DISPOSITIONS.{json,md}` | exact (same schema family) |
| `.planning/phases/232-.../232-WINDOW-DISPOSITIONS.{json,md}` | data artifact | CRUD | `.planning/phases/231-.../231-WINDOW-DISPOSITIONS.{json,md}` | exact (own triad, own SHA per D-19) |
| `.planning/phases/232-.../232-CLEANUP-FINDINGS.json` | data artifact | CRUD (append-only, one row per commit) | `.planning/phases/230-.../230-DISPOSITIONS.json` (per-commit evidence-backed ledger shape) | role-match |
| `.github/workflows/ci.yml` (triad wiring, ~205-230) | config (CI pipeline) | request-response (job steps) | existing five-triad block, `ci.yml:150-226` (same file, adjacent lines) | exact — in-place extension |
| `.github/workflows/ci.yml` (ratchet job split, ~930-1000) | config (CI pipeline) | request-response | same job, in place | exact — restructure existing job |
| `scripts/ci/verify_window_dispositions.mjs` (D-13/14/15/16 edits) | test/verifier | request-response | itself (modify in place); `verify_gate01_cohort.mjs`'s `--require-cohort-completeness` gate for the "real, non-fixtures invocation" pattern | exact |
| `scripts/ci/render_window_dispositions.mjs` (D-13/14/15 bucketing rewrite) | transform | transform | itself (modify in place) | exact |
| ~20 `scripts/ci/*.mjs` guard migrations | utility (module-boundary guard, cross-cutting) | transform | `scripts/ci/main_module.mjs` (once built) applied to each of the 11 pathname-idiom + 9 file-URL-idiom files (see full list in Shared Patterns) | exact once helper exists |
| `scripts/ci/README.md` | config/docs | — | itself — existing "Phase 226/228/229/230/231" sectioned structure | exact — add a "guard convention" paragraph + a "Phase 232" section following the same template |
| `release-please-config.json`, `RELEASING.md` | config | — | itself, in place | exact — single-field/single-line edits |

## Pattern Assignments

### `scripts/ci/main_module.mjs` (utility, new)

**Analog:** `scripts/ci/verify_recut_candidate.mjs` (inline pattern at ~line 629, the only existing file that already names a local `isMainModule` constant, and the only one already annotated with a "do not trigger main() on import" rationale comment):

```javascript
// scripts/ci/verify_recut_candidate.mjs (current inline, broken-idiom shape to replace)
// Only run as CLI/test entrypoint when this file is the invoked script — an
// `import` from another module (e.g. a script asserting these four exports
// exist) must not trigger main()/verifyFixtures() as a side effect.
const isMainModule = process.argv[1] === new URL(import.meta.url).pathname;
if (isMainModule && process.env.NODE_TEST_CONTEXT) {
```

D-29/D-30 (locked): generalize this into a shared, **correct** helper — realpath-resolved comparison, throws on empty `argv[1]`, no `import.meta.main` (unsupported on the CI-pinned Node line). Shape to build (not copied from anywhere verbatim — this is genuinely new code per D-29):

```javascript
import { realpathSync } from "node:fs";
import { fileURLToPath } from "node:url";

export function isMainModule(moduleUrl) {
  const invoked = process.argv[1];
  if (!invoked) throw new Error("isMainModule: process.argv[1] is empty — cannot determine entrypoint");
  const modulePath = realpathSync(fileURLToPath(moduleUrl));
  const invokedPath = realpathSync(invoked);
  return modulePath === invokedPath;
}
```

**Self-test pattern to copy:** every triad file's `if (process.env.NODE_TEST_CONTEXT && ...) { test(...) }` in-file block (see `collect_window_dispositions.mjs` lines 231-452) — `main_module.mjs` needs the same `node:test` battery: space-in-path fixture, symlink fixture, relative-argv fixture, empty-argv1 throw. Use `fs.mkdtempSync` + a directory name containing a space (the repo's own probe methodology from RESEARCH.md DRIFT-3).

**Guard usage at every call site** (replaces both broken idioms):
```javascript
import { isMainModule } from "./main_module.mjs";
if (isMainModule(import.meta.url)) {
  try { main(); } catch (error) { console.error(`<name>: FAIL: ${error.message}`); process.exitCode = 1; }
}
```

---

### `scripts/ci/collect_hygiene_dispositions.mjs` / `render_hygiene_dispositions.mjs` / `verify_hygiene_dispositions.mjs` (D-45 triad)

**Analog:** `scripts/ci/collect_window_dispositions.mjs`, `render_window_dispositions.mjs`, `verify_window_dispositions.mjs` (full triad, read in full this session — all three files are ≤460 lines, small enough to imitate structurally end-to-end).

**Imports pattern** (`collect_window_dispositions.mjs` lines 1-8):
```javascript
#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import test from "node:test";
import { resolvePhaseEvidencePath, repositoryRoot } from "./phase_evidence_path.mjs";
```
Add `import { isMainModule } from "./main_module.mjs";` — this is new-this-phase, no existing triad has it yet (they'll be retrofitted per the guard migration, D-29).

**Closed-enum + fail-closed field-check pattern** (lines 10-52 of `collect_window_dispositions.mjs`) — copy verbatim shape, substitute vocabulary:
```javascript
const fail = (message) => { throw new Error(message); };
function fields(value, allowed, label) { if (!value || Array.isArray(value) || typeof value !== "object") fail(`${label} must be an object`); for (const key of Object.keys(value)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`); }
```
Sanitization: **reuse `UNSAFE_PATH_PATTERN` verbatim** from `collect_window_dispositions.mjs:44` (`/(^\/|\/Users\/|\/home\/|\$HOME)/`) — see "Shared Patterns > Sanitization regex" below for why this one, not `collect_gate01_cohort.mjs`'s `LEAK_RE`.

**Schema shape** (`collect_window_dispositions.mjs` lines 26-31): top-level `{ schema_version, repository, candidate_object, observed_at, rows }`. For the hygiene triad, `observed_at` must come from `git show -s --format=%cI <candidate>` (never `Date.now()` — see lines 179-181) and rows carry the HYG-01 vocabulary: `kind` (`untracked_file`, `stale_worktree`, `debug_session`, `remote_branch`, …), `disposition`, `state`(or equivalent), plus the D-47 cross-field invariant for `remote_branch` rows:

```javascript
// D-47 (already locked in 232-CONTEXT.md) — copy this validator shape directly:
function validateRemoteBranchRow(row) {
  if (!["retained", "superseded"].includes(row.disposition)) {
    fail(`remote_branch row ${row.name}: disposition must be "retained" or "superseded", got "${row.disposition}" — this verifier cannot express branch deletion`);
  }
  if (row.authorization_required !== false) {
    fail(`remote_branch row ${row.name}: authorization_required must be false — remote branch deletion is out of scope for this phase`);
  }
}
```

**Argv/CLI entry pattern** (`collect_window_dispositions.mjs` lines 206-229, hand-rolled `--key value` scanning — the dominant convention, matches RESEARCH.md's recommendation to pick `--fixtures` over `--self-test` to match the majority):
```javascript
function parseArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    if (!argv[index].startsWith("--") || !argv[index + 1]) fail("usage: --repo PATH --expected-repository OWNER/REPO --candidate REF_OR_SHA --records-in FILE [--out FILE]");
    result[argv[index].slice(2)] = argv[++index];
  }
  return result;
}
```

**`defaultOutPath` / `phase_evidence_path.mjs` integration** (lines 194-204) — copy verbatim, substitute `PHASE_SLUG = "232-bounded-hygiene-release-handoff"` and artifact name:
```javascript
const PHASE_SLUG = "232-bounded-hygiene-release-handoff";
const JSON_ARTIFACT = "232-HYGIENE-DISPOSITIONS.json";
export function defaultOutPath() {
  try { return resolvePhaseEvidencePath(PHASE_SLUG, JSON_ARTIFACT); }
  catch { return path.join(repositoryRoot, ".planning", "phases", PHASE_SLUG, JSON_ARTIFACT); }
}
```

**Completeness + soundness (D-46)** — this is new logic (no existing triad does bidirectional live-repo re-enumeration), but it must follow the `exactMap`/`assertSameMap` shape from `verify_window_dispositions.mjs` lines 20-38 (copy verbatim — this is the repo's one canonical "exact-map join with missing/extra/changed" helper, explicitly documented as "never a new ad hoc `.every()`/`.includes()` comparison", D-30 of Phase 231):
```javascript
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
For HYG-01 completeness: authority = live `git status --porcelain -uall` + `git worktree list` + `git branch -r` re-enumerated at verify time; candidate = the committed rows. For soundness: invert the join (every row must still exist as a live item unless it carries a terminal disposition).

**Output discipline / anti-vacuity suffix** (`verify_window_dispositions.mjs` lines 316-321) — copy verbatim, substitute the name prefix:
```javascript
const requestedStrictFlags = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();
const verificationSuffix = requestedStrictFlags.length
  ? ` (verified: ${requestedStrictFlags.join(", ")})`
  : " (schema-only: no strict flags supplied, no row-join or determinism check ran)";
console.log(`hygiene dispositions verification: PASS${verificationSuffix}`);
```
Failure lines: `hygiene dispositions collect: FAIL: <reason>` / `hygiene dispositions render: FAIL: <reason>` / `hygiene dispositions verify: FAIL: <reason>` — exact `<name>: FAIL: <reason>` prefix discipline, matching every existing triad's `catch` block (see `collect_window_dispositions.mjs:228`, `render_window_dispositions.mjs:131`, `verify_window_dispositions.mjs:327`).

**Render pattern — always-render-zero-rows** (`render_window_dispositions.mjs` lines 81-89, the exact D-15/`## Waived — the gate ran and failed` mechanism CONTEXT.md specifies for the window triad but which the hygiene triad should mirror for its own bucket set):
```javascript
const sections = BUCKETS.flatMap(({ key, title }) => {
  const rows = grouped.get(key);
  return [
    `## ${title}`, "",
    rows.length ? `${rows.length} row(s).` : "0 row(s).", "",
    ...(rows.length ? [...ROW_HEADING, ...rows.map(rowLine)] : []),
    ""
  ];
});
```

**`escape()` helper** (`render_window_dispositions.mjs` line 9) — copy verbatim for Markdown-table safety:
```javascript
const escape = (value) => String(value ?? "").replace(/[\\|`<>]/g, "\\$&").replace(/[\r\n]+/g, " ");
```

---

### `scripts/ci/verify_window_dispositions.mjs` (D-13/D-14/D-15/D-16/D-17 — modify in place)

**Analog:** itself. Current bucketing to replace (`render_window_dispositions.mjs` lines 36-48 — note this function actually lives in the **render** file, not verify; the planner should route D-13's total-map rewrite there, and D-14's cartesian-product test into `verify_window_dispositions.mjs`):

```javascript
// CURRENT (to be replaced by D-13's total map on the (disposition, state) pair):
function bucketOf(row) {
  if (row.disposition === "waived") return "waived";
  if (row.state === "failed") return "failed";
  if (row.state === "skipped" || row.state === "advisory" || row.state === "non_run") return "not_run";
  return "fixed";
}
const BUCKETS = [
  { key: "waived", title: "Waived (maintainer must accept)" },
  { key: "failed", title: "Failed on the merits" },
  { key: "not_run", title: "Skipped, advisory, or not run" },
  { key: "fixed", title: "Fixed (proved at the candidate SHA)" }
];
```

D-13 replacement shape — a total map keyed on the literal pair, `fail()` on anything unmapped (mirrors the `LEAK_RE`/sanitizer discipline of "closed enum, hard fail on anything outside it," and the existing in-code comment at lines 24-35 already names the six legal pairs and the three sub-splits D-15 wants):
```javascript
const BUCKET_OF_PAIR = new Map([
  [["waived", "failed"].join("\u0000"), "waived_gate_ran_and_failed"],
  [["waived", "skipped"].join("\u0000"), "waived_gate_never_proved"],
  [["waived", "advisory"].join("\u0000"), "waived_gate_never_proved"],
  [["waived", "non_run"].join("\u0000"), "waived_gate_never_proved"],
  [["waived", "proved"].join("\u0000"), "waived_gate_passed_anyway"], // D-15's real third case
  [["fixed", "proved"].join("\u0000"), "fixed"]
]);
function bucketOf(row) {
  const key = [row.disposition, row.state].join("\u0000");
  const bucket = BUCKET_OF_PAIR.get(key);
  if (!bucket) fail(`row ${row.id} has an unmapped (disposition, state) pair: (${row.disposition}, ${row.state})`);
  return bucket;
}
```

**`ROW_STATES` export needed for D-14's cartesian test** — `STATES` already exists at `collect_window_dispositions.mjs:16` (`new Set(["proved", "failed", "skipped", "advisory", "non_run"])`) but is **not currently exported**; export it (rename to `ROW_STATES` per D-14's exact wording, or export both names) alongside the already-exported `ROW_KINDS`/`ROW_DISPOSITIONS` at lines 23-24.

**`validateWindowRow` cross-field surface D-14 needs** (already at `collect_window_dispositions.mjs` lines 54-100) — the cartesian-product test calls this directly to derive legality:
```javascript
export function validateWindowRow(row, label) { /* ... existing body, unchanged ... */ }
```
D-14 test shape (new, to add in `verify_window_dispositions.mjs`'s in-file test block, same style as the existing `test("validateWindowRow rejects an unknown kind", ...)` at line 275):
```javascript
test("every legal (disposition, state) pair renders under exactly one declared bucket, and no bucket is unreachable", () => {
  const legalPairs = [];
  for (const disposition of ROW_DISPOSITIONS) {
    for (const state of ROW_STATES) {
      try { validateWindowRow({ ...validRow(), disposition, state, exit_code: state === "proved" ? 0 : undefined, owner: "m", rationale: "r", release_impact: "i" }, "probe"); legalPairs.push([disposition, state]); }
      catch { /* illegal pair, not in scope */ }
    }
  }
  const reachedBuckets = new Set(legalPairs.map(([d, s]) => bucketOf({ disposition: d, state: s })));
  const declaredBuckets = new Set([...BUCKET_OF_PAIR.values()]);
  assert.deepEqual([...reachedBuckets].sort(), [...declaredBuckets].sort());
});
```

**D-16 fix — wire a real (non-`--fixtures`) invocation.** Current `ci.yml:226` line to change:
```yaml
node scripts/ci/verify_window_dispositions.mjs --fixtures --expected-repository szTheory/accrue --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism
```
Add a **second, new** step alongside it (do not replace the fixtures step — both are needed) invoking against the committed pair, per D-17 pinning the literal SHA rather than the mutable `integration/v1.62-candidate` ref (comment at `ci.yml:~207` already forbids this):
```yaml
node scripts/ci/verify_window_dispositions.mjs --repo . \
  --records .planning/phases/232-bounded-hygiene-release-handoff/232-WINDOW-DISPOSITIONS.json \
  --rendered .planning/phases/232-bounded-hygiene-release-handoff/232-WINDOW-DISPOSITIONS.md \
  --candidate <PIN THE LITERAL SHA, NOT integration/v1.62-candidate> \
  --expected-repository szTheory/accrue \
  --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism
```

---

### `.planning/phases/231-.../231-WINDOW-DISPOSITIONS.md` (D-20 — presentation-only re-render)

**Analog:** itself + `render_window_dispositions.mjs`. Task shape: `node scripts/ci/render_window_dispositions.mjs --records .planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.json --out .planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.md` after the D-13/14/15 renderer rewrite, then `git diff` must touch **zero bytes of `231-WINDOW-DISPOSITIONS.json`** and the SUMMARY must quote the before/after tuple-equality proof (`assert.equal(oldRender(json), newRender(json))` is expected to now be FALSE post-D-13 — the proof is instead that `render(json)` under the new renderer, run twice, is stable, and that the `.json` bytes are untouched via `git diff --stat`).

---

### `scripts/ci/verify_ci_script_contract.mjs` (D-32 meta-verifier, new)

**Analog for the "closed cohort, non-empty expected count" shape:** `scripts/ci/verify_gate01_cohort.mjs`'s `--require-cohort-completeness` gate (326 lines total — read structurally; the load-bearing idiom is asserting a **committed, non-zero expected count** rather than trusting a live glob length, exactly as D-32 specifies: "a committed non-empty expected file count so it cannot pass on a zero-match glob"). Also analog for **spawning `node --test` as a child process and parsing its exit code / TAP output**: `scripts/ci/verify_ci_baseline.mjs` (spawns child `node --test` runs; grep this file directly for its `spawnSync("node", ["--test", "--test-reporter=tap", ...])` invocation pattern before writing the meta-verifier's spawn loop — read that file's spawn helper, not reproduced here, as the closest concrete precedent for `--test-reporter=tap` usage called out by D-33).

**Assertions D-32 requires, each keyed to a concrete check:**
1. `node --test --test-reporter=tap <file>` exits 0 for every `scripts/ci/*.mjs` (spawn loop, one per file).
2. At least one TAP line whose name is not the file path itself (non-vacuity) — parse TAP `ok`/`not ok` lines, assert `names.some(name => name !== filePath)`.
3. Every file either imports `isMainModule` from `./main_module.mjs` (grep the source text) or matches `*.test.mjs`.
4. A committed non-empty expected file count (42 per RESEARCH.md's re-measurement on 2026-09-16 — **re-measure at plan/execution time**, do not hardcode 42 as a permanent constant; store it as a comparison against a live `readdirSync` count with a floor assertion, same "committed but must still equal a live recount" discipline as `WINDOWS_HEADER`'s frontmatter counts in `collect_window_dispositions.mjs` lines 166-171).

---

### `scripts/ci/verify_release_pr_readiness.sh` (D-39, REL-05 proof)

**Analog:** `scripts/ci/verify_release_preflight.sh` (59 lines, full file read) for the `set -euo pipefail` + `run()` wrapper + sequential-assertion shape:
```bash
#!/usr/bin/env bash
set -euo pipefail
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root_dir"
run() {
  printf '\n==> %s\n' "$1"
  shift
  "$@"
}
```

**`fail()` + `ROOT_DIR` shape** — closer analog for the `fail()` function specifically, from `verify_release_manifest_alignment.sh` (91 lines, full file read):
```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=${ROOT_DIR:-$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
)}
fail() {
  echo "[verify_release_manifest_alignment] $*" >&2
  exit 1
}
command -v jq >/dev/null 2>&1 || fail "jq is required but not installed"
```

**Do NOT reuse `capture_linked_release_proof.sh`'s logic directly** — D-40 explicitly rules it out (it asserts `hex.pm` already serves the version, a post-publish proof by construction). Only its `usage()`-heredoc-and-flag-parsing convention is worth skimming (40 lines read) if the script needs a `--auto`/explicit-args split; REL-05's script does not need that complexity — it takes no flags beyond running `npx --yes release-please@17.6.0 release-pr --dry-run` once and grepping the output.

**Assertions D-39 requires, each keyed to a concrete grep against the dry-run's stdout/log:**
```bash
DRYRUN_LOG="$(mktemp)"
npx --yes release-please@17.6.0 release-pr --dry-run --repo-url "https://github.com/${GITHUB_REPOSITORY:-szTheory/accrue}" --token "$GITHUB_TOKEN" > "$DRYRUN_LOG" 2>&1 || fail "release-please dry-run exited non-zero"
grep -q "Expected N commits, only found M" "$DRYRUN_LOG" && fail "release-please truncation warning detected (D-38) — raise commit-search-depth"
grep -c "updating module attribute version" "$DRYRUN_LOG" | grep -qx 3 || fail "expected exactly 3 'updating module attribute version' lines"
# ... plus: updates: 7, all three packages present with the same version, version > current manifest, stable semver
```
Archive `$DRYRUN_LOG` as the REL-05 artifact per D-39's last sentence.

**CI wiring analog** — `verify_release_manifest_alignment.sh` is invoked at `ci.yml:278` as a bare `run: bash scripts/ci/verify_release_manifest_alignment.sh` step; wire the new script the same way, in the same job (the release-lane job containing `ci.yml:278/281`), gated behind token availability per D-39's own caveat ("needs a token and a pushed branch").

---

### Guard-idiom migration (D-28/D-29, ~20 files)

**Broken idiom 1 — `argv[1] === new URL(import.meta.url).pathname`** (11 files, confirmed via `grep -l` this session):
`scripts/ci/collect_gate01_cohort.mjs`, `collect_integration_disposition.mjs`, `collect_repository_inventory.mjs`, `collect_window_dispositions.mjs`, `render_integration_disposition.mjs`, `render_repository_inventory.mjs`, `render_gate01_cohort.mjs`, `render_window_dispositions.mjs`, `verify_phase230_archive_invariants.mjs`, `verify_integration_disposition.mjs`, `verify_recut_candidate.mjs`.

Representative broken snippet (`collect_window_dispositions.mjs:227-229`):
```javascript
if (!process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  try { main(); } catch (error) { console.error(`window dispositions collect: FAIL: ${error.message}`); process.exitCode = 1; }
}
```
Migration: replace `process.argv[1] === new URL(import.meta.url).pathname` with `isMainModule(import.meta.url)`; the `!process.env.NODE_TEST_CONTEXT` branch-split convention (test-mode fixtures run in a *separate* `if (process.env.NODE_TEST_CONTEXT && ...)` block later in the same file, see `collect_window_dispositions.mjs:231`) is a pre-existing, orthogonal pattern — preserve it, only swap the guard expression.

**Broken idiom 2 — `` import.meta.url === `file://${argv[1]}` `` ** (9 files, confirmed via `grep -l` this session — RESEARCH.md's DRIFT-4 re-measured 9, not D-28's estimated 5):
`scripts/ci/provider_proof.mjs`, `render_provider_summary.mjs`, `stripe_test_fixtures.mjs`, `verify_phase200_scorecard.mjs`, `verify_phase192_scorecard.mjs`, `verify_phase192_signoff.mjs`, `verify_ratchet_ledger.mjs`, `verify_phase200_signoff.mjs`, `verify_ui_ratchet_signoff.mjs`.

Representative broken snippet (`verify_phase200_signoff.mjs:708`):
```javascript
if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
```
Migration: replace the whole condition with `isMainModule(import.meta.url)`.

**Already-correct-name precedent (1 file):** `scripts/ci/verify_recut_candidate.mjs` already declares a local `const isMainModule = process.argv[1] === new URL(import.meta.url).pathname;` (line ~629) — this is the file named in CONTEXT.md's canonical_refs as "the guard template to generalize." It is counted in the 11-file pathname-idiom bucket above (its *implementation* is still broken), but its *naming choice* (`isMainModule`) is exactly what the new shared helper should be called, so migrating this file is a rename-the-import + delete-the-local-const edit, not a new-name introduction.

**22 "neither idiom" files** — do NOT treat uniformly. Per RESEARCH.md DRIFT-4/Pitfall 4, this bucket splits into: (a) `*.test.mjs` files, correctly guard-free by D-32's own carve-out (no action needed); (b) `NODE_TEST_CONTEXT`-branching-without-`isMainModule` files, specifically `verify_gate01_cohort.mjs` (per 231-REVIEW.md IN-01 — confirm this pairs with `verify_window_dispositions.mjs`, which is on the pathname-idiom-11 list already, so IN-01's second file is `verify_gate01_cohort.mjs` specifically) — these need `isMainModule` added, not just idiom-swapped; (c) shell (`.sh`) and CJS (`.cjs`) files in the same directory that are out of scope for an ESM `isMainModule` helper entirely (`ci_monitor.cjs`, all `*.sh` files) — exclude these from the D-29 migration's file count.

---

### `admin-ui-ratchet-guardrails` job split (D-23/D-24/D-25)

**Analog:** itself, `.github/workflows/ci.yml` lines 931-1000 (full block read this session). Current structure to split:
```yaml
admin-ui-ratchet-guardrails:
  name: Admin UI ratchet guardrails
  if: github.event_name != 'schedule'
  needs: [admin-hardening-guardrails, admin-phase200-guardrails]
  runs-on: ubuntu-24.04
  continue-on-error: true   # ci.yml:945 — job-level, bundles 3 passing steps with 2 parked ones
  steps:
    - name: Run ratchet ledger self-tests        # genuinely passing
      run: cd accrue_admin && npm run ratchet:ledger:self-test
    - name: Verify frozen ratchet evidence         # PARKED — fails on the merits (frozen: false)
      run: cd accrue_admin && npm run ratchet:ledger:verify-frozen
    - name: Verify UI ratchet sign-off self-test   # genuinely passing
      run: cd accrue_admin && npm run ratchet:signoff:self-test
    - name: Verify UI ratchet sign-off             # PARKED
      run: cd accrue_admin && npm run ratchet:signoff
    - name: Phase 208 CI contract                  # genuinely passing (per D-23's framing)
      run: cd accrue_admin && npm run ratchet:ci-contract
    - name: Ratchet status summary                 # DEAD — unconditional, no if: always(), unreachable (D-24)
      run: |
        { echo "## Admin UI ratchet guardrails" ... } >> "$GITHUB_STEP_SUMMARY"
```
D-23 split target: `admin-ui-ratchet-selftests` (blocking, no `continue-on-error`, holding `ratchet:ledger:self-test` + `ratchet:signoff:self-test` + `ratchet:ci-contract`) and `admin-ui-ratchet-guardrails [parked]` (non-blocking, `continue-on-error: true`, holding `ratchet:ledger:verify-frozen` + `ratchet:signoff`, D-26's expiry-trigger check added as a new step).

D-24 replacement for "Ratchet status summary" — no existing file in this repo prints real ledger numbers into `$GITHUB_STEP_SUMMARY` conditionally with `if: always()` as a precedent to copy verbatim; build new, following the `if: always()` + `uses: actions/upload-artifact@v7` `if-no-files-found: ignore` idiom already present two steps below it (`ci.yml:~988-1000`) as the "read real state, don't fabricate" sibling pattern:
```yaml
- name: Ratchet status summary
  if: always()
  run: |
    node -e "const l = require('./accrue_admin/e2e/ratchet/ledger.baseline.json'); console.log('frozen:', l.frozen, 'open findings:', l.findings?.length ?? 'unknown')" >> "$GITHUB_STEP_SUMMARY"
```
(exact JS/field names must be re-derived from the live `ledger.baseline.json` schema at execution time, not assumed).

D-25 exclusion-key edit — `ci.yml:1346`:
```yaml
ANNOTATION_SWEEP_EXCLUDE: advisory,ratchet
```
→
```yaml
ANNOTATION_SWEEP_EXCLUDE: advisory,parked
```
with the job's `name:` field carrying the literal string `[parked]` (D-25 requires both edits land in one commit since the sweep matches job-name fragments — see `annotation_sweep.sh` invocation at `ci.yml:1350-1352` for the exact job-name list the sweep greps against; `admin-ui-ratchet-guardrails` must be renamed there too if the job name itself changes).

## Shared Patterns

### `<name>: FAIL: <reason>` output discipline
**Source:** every existing triad's catch block, e.g. `collect_window_dispositions.mjs:228`, `render_window_dispositions.mjs:131`, `verify_window_dispositions.mjs:327`.
**Apply to:** every new script this phase adds (`main_module.mjs`'s own errors, the hygiene triad's three files, `verify_ci_script_contract.mjs`, `verify_release_pr_readiness.sh`'s `fail()`).
```javascript
try { main(); } catch (error) { console.error(`<name>: FAIL: ${error.message}`); process.exitCode = 1; }
```

### `PASS (verified: ...)` / `PASS (schema-only: ...)` anti-vacuity suffix
**Source:** `verify_window_dispositions.mjs:317-321`, `verify_recut_candidate.mjs:~620-624`.
**Apply to:** `verify_hygiene_dispositions.mjs` and `verify_ci_script_contract.mjs` — both must print which strict flags actually ran.

### Sanitization regex — pick ONE of the two existing divergent patterns, do not mint a third
**Source A (broader, recommended):** `scripts/ci/collect_window_dispositions.mjs:44`
```javascript
const UNSAFE_PATH_PATTERN = /(^\/|\/Users\/|\/home\/|\$HOME)/;
```
**Source B (narrower — matches a literal grep gate elsewhere, no leading-`/` anchor):** `scripts/ci/collect_gate01_cohort.mjs:14`
```javascript
// D-31: mirrors the literal grep pattern used by Task 3's committed-evidence
// verify command (`grep -nE '/Users/|/home/|\$HOME'`), so schema-level
// rejection and the file-level grep gate can never silently diverge.
const LEAK_RE = /\/Users\/|\/home\/|\$HOME/;
```
**Apply to:** `collect_hygiene_dispositions.mjs` and any other new-this-phase collector touching string fields that might carry a local path. **Recommendation for the planner:** reuse Source A (`UNSAFE_PATH_PATTERN`) verbatim — it is strictly broader (also catches a bare leading `/`, which a hygiene classifier enumerating local filesystem paths is more likely to emit than the window-dispositions ledger ever was) and is already exported-by-convention from its collector module (import it from `collect_window_dispositions.mjs` rather than duplicating, if the hygiene triad chooses to share helper modules per CONTEXT.md's "Claude's Discretion" note — or copy the literal regex if triads are kept independent). Do not build a third pattern; 231-REVIEW.md IN-02 already flags the A/B divergence as an open, deferred item — this phase should not add a C variant.

### `phase_evidence_path.mjs` integration for new artifacts
**Source:** `resolvePhaseEvidencePath(PHASE_SLUG, ARTIFACT)` with a try/catch fallback to the direct `.planning/phases/<slug>/<artifact>` path, used identically in all four existing collectors and renderers (e.g. `collect_window_dispositions.mjs:194-204`, `render_window_dispositions.mjs:105-111`).
**Apply to:** every new `.json`/`.md` artifact path this phase writes (`232-HYGIENE-DISPOSITIONS.*`, `232-WINDOW-DISPOSITIONS.*`).

### `exactMap` / `assertSameMap` join helper
**Source:** `verify_window_dispositions.mjs:20-38` (explicitly documented as copied verbatim from `verify_integration_disposition.mjs`/`verify_repository_inventory.mjs` — this is already the repo's one shared join idiom, D-30 of Phase 231).
**Apply to:** HYG-01's completeness/soundness checks (D-46) in `verify_hygiene_dispositions.mjs`, and `232-CLEANUP-FINDINGS.json`'s per-commit join-completeness assertion (D-58).

### Argv convention: `--fixtures` over `--self-test`
**Source:** RESEARCH.md's measured split (11 files use `--fixtures`, 10 use `--self-test`) and the existing GATE-01/02/03 triads' own choice of `--fixtures` (`ci.yml:150-226` block).
**Apply to:** the new hygiene triad and `verify_ci_script_contract.mjs` — use `--fixtures`, matching the majority and the immediately-adjacent calling convention already in `ci.yml`.

### CI wiring block shape
**Source:** `ci.yml:150-226`, the existing five-consecutive-triad `run:` multi-line block pattern (`node --test <collect> && node --test <render> && node --test <verify> && node <verify>.mjs --fixtures --expected-repository szTheory/accrue --require-...`).
**Apply to:** every new triad step added to the `docs-and-bash-contracts-shift-left` job (or its current literal name — re-confirm the exact job id at execution time, CONTEXT.md's `## Integration Points` calls it `docs-and-bash-contracts-shift-left`).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `main_module.mjs`'s realpath-based comparison logic itself | utility | transform | No existing file in this repo does realpath resolution for a module-boundary guard — every existing guard is one of the two broken idioms this phase retires. The *shape* (a standalone helper module with a named export) has a naming precedent (`phase_evidence_path.mjs` — a small, standalone, imported-everywhere `.mjs` utility with `export function`s and no CLI entrypoint of its own) worth skimming for file-layout convention, but the actual comparison logic is genuinely new per D-29. |
| `232-CLEANUP-FINDINGS.json`'s per-commit join-completeness assertion | verifier logic | CRUD | No existing artifact ties a commit SHA to a "command, before-exit, after-exit" triple; closest structural sibling is `230-DISPOSITIONS.json`'s per-excluded-commit-SHA ledger (cited above as role-match), but the finding schema itself (D-58) is new. |
| `verify_pr_body_contract.mjs` (mentioned as optional in RESEARCH.md's Phase Requirements table for REL-04) | verifier | request-response | RESEARCH.md itself marks this "new, optional" with no existing analog; REL-04's PR-body requirements (D-59/60/61) are more naturally satisfied by manual authorship following the density/provenance-split rules than by a new automated linter — flag for planner discretion, not a hard requirement. |

## Metadata

**Analog search scope:** `scripts/ci/` (all 89 files listed via `ls`), `.github/workflows/ci.yml` (1503 lines, targeted `sed`/`grep` reads), `.planning/phases/231-.../`, `.planning/phases/230-.../` (referenced, not re-read in full — their shape is already documented in `scripts/ci/README.md`'s own per-phase sections, which were read in full).
**Files scanned:** 12 full-file reads (`collect_window_dispositions.mjs`, `render_window_dispositions.mjs`, `verify_window_dispositions.mjs`, `verify_release_manifest_alignment.sh` head, `verify_release_preflight.sh` full, `capture_linked_release_proof.sh` head, `scripts/ci/README.md` first ~200 lines) + targeted `grep`/`sed` reads of `verify_recut_candidate.mjs` (guard site), `collect_gate01_cohort.mjs` (sanitization regex site + imports), `verify_phase200_signoff.mjs` (file-URL guard site), `.github/workflows/ci.yml` (triad-wiring, ratchet-job, annotation-sweep line ranges), plus two full-repository `grep -l` census passes for the two guard idioms.
**Pattern extraction date:** 2026-09-16
