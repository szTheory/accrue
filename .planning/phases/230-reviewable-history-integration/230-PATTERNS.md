# Phase 230: Reviewable History Integration - Pattern Map

**Mapped:** 2026-09-15
**Files analyzed:** 12 (new/modified; excludes the merge's own conflict-resolution edits, which are outside pattern-mapping scope — see note below)
**Analogs found:** 12 / 12

All analog paths below were confirmed git-tracked via `git ls-files -- <path>` before being recorded (tracked-source gate). `scripts/ci/stripe_test_fixtures.mjs`, `scripts/ci/verify_stripe_test_fixtures.mjs`, and `.tool-versions` are confirmed **untracked** on disk today — they are new-file targets for this phase (D-23, D-33), not analogs.

## Note on scope

CONTEXT.md's D-01..D-24 describe *what the candidate merge must prove*, not new application source files — the merge's own conflict resolution (`accrue/lib/accrue/config.ex`, `accrue/mix.exs`, `accrue/guides/entitlements.md`, three sibling `mix.lock` files) is produced by `git merge`/`mix deps.get`, not authored from a pattern. This map covers the **evidence-producing tooling and artifacts** Phase 230 must create/extend per D-25..D-39, since that is the actual new-code surface a planner assigns to executor tasks.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `scripts/ci/collect_integration_disposition.mjs` (new; exact name is planner's discretion per D-36/D-37) | service/utility | batch (git plumbing → sanitized JSON) | `scripts/ci/collect_repository_inventory.mjs` | exact |
| `scripts/ci/render_integration_disposition.mjs` (new) | utility/transform | transform (JSON → deterministic Markdown) | `scripts/ci/render_repository_inventory.mjs` | exact |
| `scripts/ci/verify_integration_disposition.mjs` (new) | test/utility | batch verification (recompute + fail-closed compare) | `scripts/ci/verify_repository_inventory.mjs` | exact |
| `scripts/ci/verify_repository_inventory.mjs` (**modified**, not new — D-27's explicit target) | utility | batch verification | itself (before/after diff); see "typed ref continuity" excerpt below | exact (self) |
| `scripts/ci/preserve_repository_state.sh` or a thin phase-230 wrapper around it (D-31/D-32) | utility | file-I/O (capsule/bundle mint) | `scripts/ci/preserve_repository_state.sh` | exact |
| `.planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.json` (new) | model/data | batch (collected facts) | `.planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json` | exact |
| `.planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.md` (new) | model/data | transform (rendered) | `.planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md` | exact |
| `.planning/phases/230-reviewable-history-integration/230-DISPOSITIONS.{json,md}` (new; may be folded into the above per D-36's "planner's call") | model/data | batch | same 229 inventory pair | exact |
| `.planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json` (new) | model/data | CRUD (small declared-additions ledger) | `recovery.refs` array schema inside `collect_repository_inventory.mjs` (`validateRecovery`, lines 60) + WINDOWS.md row-multiset precedent | role-match |
| `.planning/phases/230-reviewable-history-integration/230-ROLLBACK-POINT.json` (new) | model/data | event-driven (point-in-time snapshot + restore procedure) | `recovery` manifest fields (`collect_repository_inventory.mjs` `validateRecovery`) + `restore_argv` construction in `preserve_repository_state.sh` line 281 | role-match |
| `scripts/ci/README.md` (**modified** — add one evidence-table row) | config/docs | request-response (contributor lookup table) | itself, existing rows (lines 9-11, 33) | exact (self) |
| `.tool-versions` (new, currently untracked — commit as-is/extended per D-23) | config | — | `/Users/jon/getfluent/.tool-versions` (sibling project, single `nodejs` line) — no in-repo analog exists yet | no analog (see below) |

## Pattern Assignments

### `scripts/ci/collect_integration_disposition.mjs` (service/utility, batch)

**Analog:** `scripts/ci/collect_repository_inventory.mjs`

**Imports pattern** (lines 1-9):
```javascript
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import test from "node:test";
```

**Validation-primitive pattern** (lines 10-29) — reuse verbatim, do not reinvent: a small set of composable field-shape validators built on a single `fail()` thrower:
```javascript
const SHA = /^[a-f0-9]{40}$/; const DIGEST = /^[a-f0-9]{64}$/;
const fail = (message) => { throw new Error(message); };
function fields(value, allowed, label) { if (!value || Array.isArray(value) || typeof value !== "object") fail(`${label} must be an object`); for (const key of Object.keys(value)) if (!allowed.has(key)) fail(`${label} contains forbidden field: ${key}`); }
function fullSha(value, label) { if (typeof value !== "string" || !SHA.test(value)) fail(`${label} must be a full lowercase SHA`); return value; }
function digest(value, label) { if (typeof value !== "string" || !DIGEST.test(value)) fail(`${label} must be a SHA-256 digest`); return value; }
function timestamp(value, label) { if (typeof value !== "string" || !ISO.test(value) || Number.isNaN(Date.parse(value))) fail(`${label} must be an ISO-8601 timestamp`); return value; }
function relativePath(value, label) { if (typeof value !== "string" || !value || value.startsWith("/") || value.includes("\\") || value.split("/").some((part) => !part || part === "." || part === "..") || /[\0-\x1f\x7f]/.test(value)) fail(`${label} must be a normalized repository-relative path`); return value; }
function refName(value, label) { if (typeof value !== "string" || !value.startsWith("refs/") || /[\0-\x1f\x7f ~^:?*\\[\\]/.test(value)) fail(`${label} must be a safe ref name`); return value; }
function run(repo, args) { const result = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8", timeout: 15000, maxBuffer: 1000000 }); if (result.status !== 0) fail(`git ${args[0]} failed`); return result.stdout.trim(); }
```
Apply the same shape for a new `mergeCommit(value, label)` / `patchId(value, label)` validator for hazard-class rows (D-14/D-15).

**Sanitization boundary** (D-38): only allow-listed fields per record type — copy the `fields()` gate pattern; every new record type (hazard row, disposition row, excluded-commit row) gets an explicit `new Set([...])` allow-list, never an implicit passthrough.

**CLI main pattern** (line 469-470), including the `NODE_TEST_CONTEXT` self-test gate — copy verbatim, substitute the option names:
```javascript
function main() { const options = parseArgs(process.argv.slice(2)); if (!options.repo || !options.out /* + this phase's required inputs */) fail("--repo, ..., and --out are required"); const result = collectX({ /* ... */ }); fs.writeFileSync(options.out, `${JSON.stringify(result, null, 2)}\n`, { mode: 0o600 }); }
if (!process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) { try { main(); } catch (error) { console.error(`<label>: FAIL: ${error.message}`); process.exitCode = 1; } }
```

**Recompute-from-SHAs-never-transcribe pattern** (D-15 is a direct restatement of this file's existing discipline): every fact this script emits is produced by a live `run(repo, [...])` git-plumbing call inside the collector, never copied from a prior artifact or prose. This is exactly why `collect_repository_inventory.mjs` shells out to `git for-each-ref`, `git merge-base`, `git cat-file` rather than reading `229-REPOSITORY-INVENTORY.json`.

**Error handling:** every validator throws via the shared `fail()` helper; there is no try/catch inside individual validators — errors propagate to `main()`'s single catch, which prints `"<label>: FAIL: <message>"` and sets `process.exitCode = 1`. Copy this flat-throw style rather than introducing per-field try/catch.

---

### `scripts/ci/render_integration_disposition.mjs` (utility/transform, transform)

**Analog:** `scripts/ci/render_repository_inventory.mjs` (97 lines, small enough to reuse near-wholesale)

**Escaping + deterministic ordering helpers** (lines 7-9) — copy verbatim:
```javascript
const escape = (value) => String(value).replace(/[\\|`<>]/g, "\\$&").replace(/[\r\n]+/g, " ");
const order = (rows, key) => [...rows].sort((a, b) => key(a).localeCompare(key(b)));
const shellQuote = (value) => `'${String(value).replace(/'/g, `'"'"'`)}'`;
```

**Section-builder pattern** (lines 10-11) — every rendered block states Fact/State/Owner/Next-command, matching D-39's "answers what did this merge decide on my behalf in under a minute":
```javascript
function section(title, state, owner, command, evidence, rows = [], headings = []) {
  return ["## " + title, "", `**Fact:** ${escape(evidence)}. **State:** ${escape(state)}. **Owner:** ${escape(owner)}. **Next command:** \`${escape(command)}\`.`, "", ...headings, ...rows, ""];
}
```
For this phase's renderer, lead with a "Decisions adopted silently" section (D-39) before the per-hazard sections, and put convergent-identical rows (blob-identical files, D-16) in a collapsed/last section since "they owe nothing."

**Determinism contract** (D-38): `renderRepositoryInventory(inventory, validationContext)` re-validates its input via `validateInventory` before rendering (line 24) — never renders unvalidated JSON. Re-rendering must byte-equal the committed Markdown; timestamps must come from `git show -s --format=%cI <candidate>`, never `Date.now()` (D-38). Copy this validate-then-render ordering.

**CLI main + self-test gate** (lines 65-68) — identical shape to the collector's; reuse verbatim with this phase's option names.

---

### `scripts/ci/verify_integration_disposition.mjs` (test/utility, batch verification)

**Analog:** `scripts/ci/verify_repository_inventory.mjs`

**Imports + shared constants** (lines 1-30):
```javascript
import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { collectRepositoryInventory, createRepositoryValidationContext, normalizeRemoteFact, validateInventory } from "./collect_repository_inventory.mjs";
import { renderRepositoryInventory } from "./render_repository_inventory.mjs";

const BOOLEAN_FLAGS = new Set(["fixtures", "require-recovery", /* ... */]);
const VALUE_OPTIONS = new Set(["records", "rendered", "expected-repository", /* ... */]);
```
For the new verifier: import from the new `collect_integration_disposition.mjs`/`render_integration_disposition.mjs`, and define this phase's own `--require-*` flags for D-24's proof-state lexicon (e.g. `--require-ancestry`, `--require-ref-exceptions`, `--require-rollback-proof`).

**Exact-multiset completeness helpers** (lines 45-70) — reuse verbatim, this is D-37's "never non-empty checks, never asserted booleans" primitive:
```javascript
function exactMap(rows, label, keyOf, valueOf) {
  const result = new Map();
  for (const row of rows) { const key = keyOf(row); if (result.has(key)) fail(`${label} contains duplicate mapping: ${key}`); result.set(key, valueOf(row)); }
  return result;
}
function assertSameMap(authorityName, authority, candidateName, candidate) {
  const missing = [...authority.keys()].filter((key) => !candidate.has(key)).sort();
  const extra = [...candidate.keys()].filter((key) => !authority.has(key)).sort();
  const changed = [...authority.keys()].filter((key) => candidate.has(key) && candidate.get(key) !== authority.get(key)).sort();
  // ... fail with missing/extra/changed triple, never a boolean
}
function assertSameMultiset(authorityName, authority, candidateName, candidate, keyOf) {
  const expected = authority.map(keyOf).sort();
  const actual = candidate.map(keyOf).sort();
  if (expected.length !== actual.length || expected.some((value, index) => value !== actual[index])) fail(`${candidateName} differs from ${authorityName}: expected=[...] actual=[...]`);
}
```
Use `assertSameMap`/`assertSameMultiset` directly for D-28's `230-REF-EXCEPTIONS.json` exact-multiset check ("undeclared ref fails, and declared-but-absent also fails") and for the excluded-commit ledger completeness check (D-07/D-37).

**`--fixtures` self-test convention** (lines 946-965) — copy verbatim, this is the project-wide "fixtures" CLI convention every verifier in this triad shares:
```javascript
async function main() {
  const parsed = options(process.argv.slice(2)); const expectedRepository = parsed.values["expected-repository"];
  if (parsed.flags.has("fixtures")) { verifyFixtures(); console.log("<label> fixtures: PASS"); return; }
  // ... else load --records/--rendered and run the real assertions
}
if (!process.env.NODE_TEST_CONTEXT && process.argv[1] === new URL(import.meta.url).pathname) {
  main().catch((error) => { console.error(`<label>: FAIL: ${error.message}`); process.exitCode = 1; });
}
```

**Proof-state lexicon source** (D-24): reuse the `PROVIDER_STATES` enumeration pattern from `scripts/ci/collect_ci_baseline.mjs` line 12 — `new Set(["proved", "failed", "misconfigured", "blocked", "skipped", "non_run"])` — as the template for this phase's own set (`proved`/`failed`/`skipped`/`advisory`/`non_run`, explicitly forbidding `deferred`/`n/a`/`green` per D-24). Every `state: "proved"` row must carry a recorded exit code — mirror how `collect_ci_baseline.mjs` never collapses `provider_state` into the Actions `conclusion` field (kept as two separate fields throughout).

---

### `scripts/ci/verify_repository_inventory.mjs` (modified — D-27's typed ref continuity)

**Analog:** itself. This is the file D-27 explicitly says to generalize, not replace.

**Current ancestry-carve-out primitive to generalize** (lines 72-96, `assertCapturedRefContinuity`) and its exact-equality sibling (lines 98-109, `assertCanonicalRefContinuity`):
```javascript
function assertCapturedRefContinuity(authority, candidate, activeRef, capturedObject, repositoryRoot) {
  // ... exact equality for every frozen ref EXCEPT the active one, which
  // instead proves same-ref ancestry via `git merge-base --is-ancestor`.
  const missing = [...authority.keys()].filter((key) => !candidate.has(key)).sort();
  const extra = [...candidate.keys()].filter((key) => !authority.has(key)).sort();
  const changed = [...authority.keys()].filter((key) => key !== activeRef && candidate.has(key) && candidate.get(key) !== authority.get(key)).sort();
  if (missing.length || extra.length || changed.length) fail(`... missing=[...] extra=[...] changed=[...]`);
  // ... then: git cat-file -e <frozen>^{commit}; git merge-base --is-ancestor <frozen> <capturedActive>
}
```
D-27's task is to promote this from "one hardcoded active-ref carve-out" to a **typed partition**: owned `refs/heads/*`/local `refs/tags/*` → exact equality plus declared additions (checked against `230-REF-EXCEPTIONS.json`); `refs/remotes/*` → ancestry-only (generalize the `merge-base --is-ancestor` branch above to apply to any remote-tracking ref, not just the one hardcoded active ref); preservation refs → generalize `PRESERVATION_PREFIX = "refs/accrue-preserve/phase-229/"` (line 19) to a phase-parameterized constant/function, e.g. `preservationPrefix(phaseSlug)`.

**`PRESERVATION_PREFIX` + `encodedRef` pattern to parameterize** (lines 19, 38):
```javascript
const PRESERVATION_PREFIX = "refs/accrue-preserve/phase-229/";
const encodedRef = (name) => `${PRESERVATION_PREFIX}${Buffer.from(name).toString("hex")}`;
```
Both `collect_repository_inventory.mjs` line 30 and `preserve_repository_state.sh` line 233 duplicate this exact `refs/accrue-preserve/phase-229/<hex>` construction — all three call sites need to move in lockstep if the prefix becomes phase-parameterized (D-31 says "reusing 229's hex encoding verbatim," so keep the hex encoding, generalize only the phase segment).

**Declared-additions ledger check** (new, per D-28): use `assertSameMap`/exact-multiset equality (see verifier excerpt above) against `230-REF-EXCEPTIONS.json`, where each row carries a `retirement_trigger` field (D-28) — model the row shape on `recovery.refs` in `collect_repository_inventory.mjs` line 60 (`fields(ref, new Set(["original_ref", "object", "encoded_ref", "bundle_member"]), ...)`), substituting the exceptions-specific field set.

---

### `.planning/phases/230-reviewable-history-integration/230-ROLLBACK-POINT.json` (model/data)

**Analog:** the `recovery` object schema in `collect_repository_inventory.mjs` (`validateRecovery`, line 60) plus the `restore_argv` construction in `preserve_repository_state.sh` line 281:
```javascript
const refs = triples(process.env.FROZEN, ['original_ref', 'object', 'object_type']).map((ref) => ({
  ...ref,
  encoded_ref: `refs/accrue-preserve/phase-229/${Buffer.from(ref.original_ref).toString('hex')}`,
  bundle_member: true,
  restore_argv: ['git', 'update-ref', ref.original_ref, ref.object]
}));
```
D-29 requires `230-ROLLBACK-POINT.json` to carry `candidate_ref`, `candidate_object`, both parents, a pre-integration `ref->object` map, `expected_reverted_tree`, bundle/manifest digests, and `restore_argv` **as argv arrays, never shell strings** — this `restore_argv: [...]` field is the exact precedent to copy (never build a shell-string command for this field).

**Executable revert proof pattern** (D-30): run in a scratch `git clone` (not `git worktree add`) into the scratchpad, because the verifier's worktree multiset pinning (`assertSameMultiset` over `{branch, sha, dirty}` rows, line ~455) would otherwise register a new row and fail strict verification. This is a direct consequence of the `assertCompleteCategories` worktree-authority check already in `verify_repository_inventory.mjs`.

---

### `.planning/phases/230-reviewable-history-integration/230-REF-EXCEPTIONS.json` (model/data)

**Analog:** the row-multiset ledger pattern already used for `.planning/WINDOWS.md` (`directShipWindows`/`readShipWindows`, verified via `assertSameMultiset("bounded .planning/WINDOWS.md authority", ...)` at `verify_repository_inventory.mjs` line 456) — same "exact multiset, id:status rows, small and explainable" shape D-28 asks for, explicitly relocated out of `WINDOWS.md` into its own file because WINDOWS.md is itself pinned as a multiset and "would break the very check it documents."

---

### `scripts/ci/README.md` (modified — add one evidence-table row)

**Analog:** itself, existing rows (lines 9, 33):
```
| [Phase 229 repository inventory](../../.planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json), [deterministic diagnostic](../../.planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md), and exact-SHA CI monitor | Which repository objects were observed and preserved, and how to inspect the fixed repository's CI state without mutation | `node scripts/ci/ci_monitor.cjs list --repo szTheory/accrue` |
```
Add a Phase 230 row in the same three-column shape (artifact links / what-it-answers / one runnable verify command). D-39 also asks to fence the rendered disposition block so Phase 232 can splice it into the integration PR body — follow the existing fenced-example convention already used elsewhere in this README (see the `node scripts/ci/verify_ci_baseline.mjs --fixtures ...` fenced block at lines 16-17).

---

### `.tool-versions` (new, config)

**No in-repo analog** — this is the first `.tool-versions` file in this repository. Nearest external precedent is the sibling project `/Users/jon/getfluent/.tool-versions` (single `nodejs 22.14.0` line, asdf/mise format). The file currently sits untracked at repo root with exactly that one line; D-23 requires adding an `elixir 1.19.5-otp-28` line (matching `CLAUDE.md`'s `Elixir 1.19+, OTP 27+` floor and the CI matrix's `1.19.5 / OTP 28` primary target) before committing. No script reads this file today — it is a bare asdf/mise-format text file, one `tool version` pair per line.

---

## Shared Patterns

### Fail-closed validation via a shared `fail()` thrower
**Source:** `scripts/ci/collect_repository_inventory.mjs` (`fail`, `fields`, `fullSha`, `digest`, `timestamp`, `relativePath`, `refName`) and mirrored in `verify_repository_inventory.mjs`
**Apply to:** every new collect/verify script in this phase. Never `console.warn`-and-continue; every shape violation throws immediately and propagates to the top-level `main()` catch, which prints `"<label>: FAIL: <message>"` and sets `process.exitCode = 1`.

### Exact-multiset / exact-map completeness, never non-empty checks
**Source:** `exactMap`, `assertSameMap`, `assertSameMultiset` in `scripts/ci/verify_repository_inventory.mjs` lines 45-70
**Apply to:** `230-REF-EXCEPTIONS.json` verification (D-28), the excluded-commit ledger (D-07/D-37), and the six-co-touched-file / hazard-universe completeness check (D-15/D-37). Ledger sizes are asserted as literal integers, never truthy checks.

### `--fixtures` self-test + `NODE_TEST_CONTEXT` guard on every script's CLI entrypoint
**Source:** identical three-line pattern repeated at the tail of `collect_repository_inventory.mjs` (line 470), `render_repository_inventory.mjs` (line 66), and `verify_repository_inventory.mjs` (line 965)
**Apply to:** all three new phase-230 scripts, verbatim.

### `restore_argv` as argv arrays, never shell strings
**Source:** `scripts/ci/preserve_repository_state.sh` line 281 (`restore_argv: ['git', 'update-ref', ref.original_ref, ref.object]`)
**Apply to:** `230-ROLLBACK-POINT.json`'s `restore_argv` field (D-29 names this exact lesson from 229).

### Preservation ref naming: `refs/accrue-preserve/phase-<N>/<hex(original_ref)>`
**Source:** duplicated today in `collect_repository_inventory.mjs` line 30, `verify_repository_inventory.mjs` lines 19/38, and `preserve_repository_state.sh` lines 233/281
**Apply to:** the Phase-230 preservation capsule (D-31/D-32) — keep the hex encoding, generalize only the `phase-229` segment to `phase-230` (or a parameterized helper, per D-27's broader ask on the verifier side).

### Deterministic render: validate-then-render, `escape()`/`order()`/`shellQuote()` helpers, byte-equal on re-render
**Source:** `scripts/ci/render_repository_inventory.mjs` lines 7-9, 23-24
**Apply to:** `render_integration_disposition.mjs`. Timestamps must be `git show -s --format=%cI <candidate>`, never `Date.now()` (D-38).

### `resolvePhaseEvidencePath` for archive-survivable artifact paths
**Source:** `scripts/ci/phase_evidence_path.mjs` (full file, 59 lines) — checks `.planning/phases/<slug>/<artifact>` first, then falls back to `.planning/milestones/*-phases/<slug>/<artifact>`, erroring on zero or ambiguous (>1) matches.
**Apply to:** any script this phase writes that needs to locate `230-*` artifacts (or F-01..F-03's already-existing archive-resolution scripts) after a future milestone archive — this is exactly what D-22's "standing invariant" sweep must keep exercising.

### `.dialyzer_ignore.exs`-style convergent-identical proof: blob identity, not assertion
**Source:** no single file — this is a git-plumbing pattern (`git cat-file -p <blob>` / comparing tree entries) already exercised implicitly by `merge-tree --write-tree` in D-01's measured ground truth
**Apply to:** D-16's requirement that the three convergent-identical co-touched files be *proved* same-blob, not merely asserted — use `git rev-parse <ref>:<path>` on both parents and assert string equality of the two blob SHAs, recorded as a hazard row with `class: "convergent-identical"` and the two blob SHAs as evidence.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.tool-versions` | config | — | First occurrence in this repository; no in-repo precedent, only an external sibling-project reference (see above). Trivial enough (one line to add) that no code pattern is needed beyond the asdf/mise `tool version` line format. |
| Conflict-resolution edits inside `accrue/lib/accrue/config.ex`, `accrue/mix.exs`, `accrue/guides/entitlements.md`, and the three sibling `mix.lock` files (D-16..D-19) | — (produced by `git merge` / `mix deps.get`, not hand-authored) | — | Out of pattern-mapping scope: these are the *subject* of the merge's hazard analysis, not new files written from a template. Any hand-fix needed after `mix deps.get --check-locked` fails (D-18/D-19) is scoped and reversibility-tagged as "costly" per D-19 — the planner should treat each as its own narrowly-scoped fix task, not a pattern-copy task. |

## Metadata

**Analog search scope:** `scripts/ci/**`, `.planning/phases/229-repository-truth-recovery-safety/**`, `.planning/milestones/v1.61-phases/226-ci-baseline-proof-semantics/**`
**Files scanned:** `scripts/ci/collect_repository_inventory.mjs` (885 lines), `render_repository_inventory.mjs` (97 lines, read whole), `verify_repository_inventory.mjs` (966 lines, targeted ranges), `preserve_repository_state.sh` (693 lines, targeted grep+read), `phase_evidence_path.mjs` (59 lines, read whole), `collect_ci_baseline.mjs` (targeted grep), `scripts/ci/README.md` (targeted grep)
**Pattern extraction date:** 2026-09-15
