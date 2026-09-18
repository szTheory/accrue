---
phase: 231-exact-sha-release-gate-proof
reviewed: 2026-09-16T00:00:00Z
depth: deep
files_reviewed: 15
files_reviewed_list:
  - scripts/ci/verify_recut_candidate.mjs
  - scripts/ci/collect_window_dispositions.mjs
  - scripts/ci/render_window_dispositions.mjs
  - scripts/ci/verify_window_dispositions.mjs
  - scripts/ci/collect_gate01_cohort.mjs
  - scripts/ci/render_gate01_cohort.mjs
  - scripts/ci/verify_gate01_cohort.mjs
  - scripts/ci/collect_ci_baseline.mjs
  - scripts/ci/render_ci_baseline.mjs
  - scripts/ci/verify_ci_baseline.mjs
  - scripts/ci/collect_repository_inventory.mjs
  - scripts/ci/README.md
  - .github/workflows/ci.yml
  - .planning/WINDOWS.md
  - .planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.json
findings:
  critical: 1
  warning: 3
  info: 3
  total: 7
status: issues_found
---

# Phase 231: Code Review Report

**Reviewed:** 2026-09-16
**Depth:** deep
**Files Reviewed:** 15
**Status:** issues_found

## Summary

Phase 231 adds three new collect/render/verify triads (recut-candidate, GATE-01 cohort, window-dispositions), extends the pre-existing `collect_ci_baseline.mjs`/`verify_ci_baseline.mjs` with a required-job-set drift check, wires all of it merge-blocking into `docs-contracts-shift-left`, and drives `.planning/WINDOWS.md` to `open_count: 0`. The SUMMARY documents show real self-auditing: the team caught and fixed a genuine tautological-comparison bug in `verify_recut_candidate.mjs` (revert-proof/unique-commit-count gates) before shipping, and correctly recorded a real CI failure at the candidate SHA rather than papering over it. That work is sound.

This review found one **new**, undetected instance of the same failure-mode class the phase was explicitly hunting for — a missing invariant in the window-dispositions schema that lets a ship-window row claim `disposition: "fixed"` (i.e., "this is now safe to ship") while its own recorded `state` says the underlying check actually failed, was skipped, or never ran — and neither the collector nor the verifier catches the contradiction. It also found one fully vacuous CLI flag (`verify_recut_candidate.mjs --expected-repository`) that is required but never compared against anything, unlike its three sibling verifiers where the same-named flag does real work. Both are genuine gaps in a gate whose entire purpose is to be unforgeable. Neither is exploitable by the actual committed Phase 231 evidence (which is internally consistent), but both are latent holes a future author (or a careless auto-fix) could walk through undetected.

## Critical Issues

### CR-01: `disposition: "fixed"` is not required to imply `state: "proved"` — a ship-window row can claim "fixed" while recording its own check as failed/skipped/non_run

**File:** `scripts/ci/collect_window_dispositions.mjs:54-93` (schema: `validateWindowRow`), also `scripts/ci/verify_window_dispositions.mjs:46-81` (`assertRowJoin`, `assertEvidenceFreshness`, `assertWaiverCompleteness`)

**Issue:** `ROW_DISPOSITIONS = {"fixed", "waived"}` is the maintainer-facing ship/no-ship decision for a window row; `STATES = {"proved", "failed", "skipped", "advisory", "non_run"}` is what the re-run actually observed. `validateWindowRow` enforces:
- `state === "proved"` requires a recorded `exit_code` (line 68).
- `disposition === "waived"` requires `owner`/`rationale`/`release_impact` (lines 73-77).

There is **no rule anywhere** requiring `disposition === "fixed"` to imply `state === "proved"`. A row shaped like:
```json
{ "id": 11, "phase": "231", "kind": "unrun-verify", "disposition": "fixed",
  "state": "failed", "current_evidence": "still fails, but marking fixed anyway" }
```
passes `validateWindowRow` cleanly (no `exit_code` needed since `state !== "proved"`; no owner/rationale needed since `disposition !== "waived"`). It then passes every strict verifier flag:
- `assertRowJoin` only compares the ledger's `status` column against the record's `disposition` field (both `fixed`) — it never looks at `state` at all.
- `assertEvidenceFreshness` only checks that `current_evidence` differs byte-for-byte from the stale ledger `description` — a fabricated "still fails, but..." string trivially satisfies "not byte-identical."
- `assertWaiverCompleteness` only fires for `disposition === "waived"` rows — a `"fixed"` row is exempt by construction.
- `renderWindowDispositions`'s `bucketOf()` (render_window_dispositions.mjs:23-28) would route this row into the "Failed on the merits" bucket for *display* purposes, but that's cosmetic — the machine-checkable verifier never rejects it, and `.planning/WINDOWS.md`'s own `status` column (driven by the same `disposition`) would still read `fixed`.

This is exactly the failure class the phase was hunting for (a claim that "can never fail" under a plausible bad input) — the committed 231-WINDOW-DISPOSITIONS.json happens to be internally consistent (verified: every `fixed` row has `state: proved`; every `waived` row has `state` other than `proved`), so today's artifact is not misrepresenting anything. But the schema itself does not enforce this, so a future phase (human or automated) authoring a new window-disposition row via this same machinery could close a real regression as "fixed" while its own `state` field admits it never actually passed, and GATE-03's merge-blocking CI step (`--require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism`) would not catch it.

**Fix:** Add a cross-field invariant to `validateWindowRow` (and mirror it as an independent verifier-layer check in `verify_window_dispositions.mjs`, matching the existing "waiver completeness is re-checked independently of collection-time validation" discipline already used for waived rows):
```js
if (row.disposition === "fixed" && row.state !== "proved") {
  fail(`${label} disposition "fixed" requires state "proved" (got "${row.state}") — a row closed as fixed must have a genuinely passing re-run, never failed/skipped/advisory/non_run`);
}
```

## Warnings

### WR-01: `verify_recut_candidate.mjs --expected-repository` is required but never checked against anything

**File:** `scripts/ci/verify_recut_candidate.mjs:539-547`

**Issue:** `main()` requires `--expected-repository` (`if (!expectedRepository) fail(...)`, line 540) but the resulting `expectedRepository` variable is never read again anywhere in the file — not compared to the record, not compared to a live `git remote` value, not passed into `validateRecutRecord` or `collectRecutGates`. Contrast with the three sibling verifiers this phase itself introduced or extended:
- `verify_gate01_cohort.mjs:298` passes `expectedRepository` into `validateGate01Evidence(record, { expectedRepository })`, which asserts `evidence.repository === expectedRepository` (collect_gate01_cohort.mjs:170).
- `verify_window_dispositions.mjs:278` checks `record.repository !== parsed.values["expected-repository"]`.
- `verify_ci_baseline.mjs` threads `expectedRepository` into `createRepositoryValidationContext`, which is used throughout `normalizeRun`/`normalizeJob` to validate every `html_url` actually points at the expected owner/repo.

`verify_recut_candidate.mjs` has none of this. The flag is present in the CLI surface (and in the merge-blocking `ci.yml` step, and in `--fixtures` invocations) purely for cosmetic consistency with its siblings, but it performs zero verification. Running `node scripts/ci/verify_recut_candidate.mjs --repo . --record ... --candidate ... --expected-repository literally-anything-at-all --require-shape --require-ancestry --require-revert-proof --require-toolchain` succeeds identically regardless of what string is passed. This is the "flag that cannot be made to fail by a genuinely bad input" pattern called out as the highest-priority defect class for this review.

**Fix:** Either wire `expectedRepository` into a real check (e.g., validate it against a `repository` field the record could carry, matching the sibling schema shape — the `RECUT_RECORD_FIELDS` set currently has no `repository` field at all, which would need adding), or, if there genuinely is nothing in this record to check it against, remove the flag from the CLI surface entirely rather than leaving a decorative required argument that implies a safety property it doesn't provide.

### WR-02: `verify_ci_baseline.mjs --require-event-class`/`--require-exit-codes` vacuously pass when the records file contains zero `"run"`-kind records

**File:** `scripts/ci/verify_ci_baseline.mjs:62-79` (`verifyEventClass`, `verifyExitCodes`)

**Issue:**
```js
function verifyEventClass(records, expectedEventClass) {
  if (!expectedEventClass) fail("--require-event-class requires --expect-event-class");
  for (const record of records) {
    if (record.kind !== "run") continue;
    ...
  }
}
```
Both functions loop over `records` and only act on `kind === "run"` entries. If the `--records` NDJSON file passed to the verifier contains zero run-kind records (e.g., a truncated file, a file that only has `job` records, or a record set that dropped its `run` row due to an upstream bug), the `for` loop body never executes and the function returns normally — a silent, vacuous PASS with no run ever inspected. There is no assertion anywhere that at least one `kind: "run"` record was present and actually checked.

The real committed `231-GATE-02-EVIDENCE.ndjson` does contain exactly one run record today (confirmed), so the current evidence is not misrepresented. But the verifier itself has no floor: a caller who accidentally strips or filters the run record out of an NDJSON file before calling `--require-event-class --expect-event-class workflow_dispatch --require-exit-codes` gets a clean "PASS" with the exact same message a genuinely-verified file would produce.

**Fix:** Assert a non-zero count of inspected run records when the flag is active:
```js
function verifyEventClass(records, expectedEventClass) {
  if (!expectedEventClass) fail("--require-event-class requires --expect-event-class");
  const runs = records.filter((r) => r.kind === "run");
  if (!runs.length) fail("--require-event-class found no run-kind records to verify");
  for (const record of runs) { ... }
}
```
(and the equivalent for `verifyExitCodes`, scoped to `provider_state === "proved"` rows, if that's meant to be an unconditional expectation for the GATE-02 use case).

### WR-03: `collect_gate01_cohort.mjs`'s `OUT_OF_COHORT_LANES` is a hand-maintained literal, unlike the live-derived merge-blocking cohort it's unioned with

**File:** `scripts/ci/collect_gate01_cohort.mjs:41-48`

**Issue:** `declaredMergeBlockingJobs`/`annotationSweepNeeds` are deliberately derived live from `ci.yml` so the required set can never silently go stale (per the module's own D-09/D-18 comments). `OUT_OF_COHORT_LANES`, however, is a plain hardcoded array of six strings (`live-stripe`, `provider-proof-trigger`, `provider-proof-incident`, `ios-offline-client`, `mix hex.publish --dry-run`, `gh workflow run ci.yml`) with no live cross-check against anything in the repository — it's just unioned with the live-derived set (`collectGate01Cohort` line 201: `const expectedJobs = [...declared, ...OUT_OF_COHORT_LANES];`). If one of these six named lanes is renamed, removed, or a new one is introduced in a future phase, nothing fails until a maintainer manually notices the evidence rows no longer make sense — `assertExactSet` will happily accept a stale hardcoded name paired with a stale evidence row that no longer corresponds to anything real, since both sides of that particular comparison are equally hand-authored.

**Fix:** Not blocking for this phase (the six lanes are a legitimately fixed, rarely-changing list), but worth a one-line code comment or a follow-up ticket noting that this specific list has no live-derivation cross-check the way the merge-blocking cohort does, so a rename elsewhere in the repo won't be caught here.

## Info

### IN-01: `verify_window_dispositions.mjs` and `verify_gate01_cohort.mjs` lack the `isMainModule` guard their sibling `verify_recut_candidate.mjs` uses

**File:** `scripts/ci/verify_window_dispositions.mjs:301-305`, `scripts/ci/verify_gate01_cohort.mjs:322-326`

**Issue:** `verify_recut_candidate.mjs` (line 575-579) and every `collect_*.mjs`/`render_*.mjs` module in this phase guard their test-registration/CLI-execution with `process.argv[1] === new URL(import.meta.url).pathname` so that merely `import`-ing the module (e.g., from another script or a future test file) never triggers `main()` or registers a `node:test` case as a side effect. `verify_window_dispositions.mjs` and `verify_gate01_cohort.mjs` instead do:
```js
if (process.env.NODE_TEST_CONTEXT) {
  test("... fixtures pass every negative control", () => verifyFixtures());
} else {
  main().catch(...);
}
```
with no `isMainModule` check at all. Today nothing imports these two files from another module, so this is harmless in practice. But it's an inconsistent, easy-to-regress pattern: if a future script imports either verifier to reuse a helper, and `NODE_TEST_CONTEXT` happens to be set (as it is throughout `node --test` runs across this directory), the import would silently re-register the fixtures test a second time or attempt to run `main()` a second time as an unintended side effect.

**Fix:** Add the same `isMainModule` guard used by every other module in this phase.

### IN-02: Sanitization regex inconsistency between the window-dispositions and gate01-cohort triads

**File:** `scripts/ci/collect_window_dispositions.mjs:44` vs `scripts/ci/collect_gate01_cohort.mjs:14`

**Issue:** `collect_window_dispositions.mjs`'s `UNSAFE_PATH_PATTERN = /(^\/|\/Users\/|\/home\/|\$HOME)/` rejects any string starting with a bare `/` in addition to `/Users/`, `/home/`, `$HOME`. `collect_gate01_cohort.mjs`'s `LEAK_RE = /\/Users\/|\/home\/|\$HOME/` does not check for a leading `/` at all — a value like `/etc/some-secret-path` would pass gate01's sanitizer but fail window-dispositions'. The gate01 module's own comment explains this is deliberately mirroring the specific `grep -nE '/Users/|/home/|\$HOME'` command used elsewhere, so it's a documented choice rather than an oversight, but the two D-31 "privacy sanitization" implementations in the same phase now disagree on what counts as an unsafe path.

**Fix:** No action required for this phase's own data (job/command names are all known-safe literals), but worth converging the two patterns in a future pass so "D-31 sanitization" means the same thing everywhere.

### IN-03: GATE-03's live-artifact join is proven once, not re-verified on every subsequent PR

**File:** `.github/workflows/ci.yml` (the "Window dispositions triad units and fixture contract" step)

**Issue:** The new merge-blocking CI step runs `node scripts/ci/verify_window_dispositions.mjs --fixtures ...` — i.e., only the hermetic self-test against synthetic fixture ledgers, never the real `--records .../231-WINDOW-DISPOSITIONS.json --rendered .../231-WINDOW-DISPOSITIONS.md` invocation against the live, committed `.planning/WINDOWS.md`. This mirrors the explicit, already-documented precedent set by Phase 229's repository-inventory verifier (`229-VERIFICATION.md § Operating Constraint`: strict verification of a *published* capsule is deliberately not run recurringly because it fails on any subsequent planning-doc edit). Given that precedent, this is a consistent, intentional design choice, not a phase-231-introduced defect — but it does mean that if a future phase reopens a `WINDOWS.md` row, or if a hand-edit to the committed `231-WINDOW-DISPOSITIONS.json` desyncs it from the ledger, CI will not catch it; only a manually re-run `verify_window_dispositions.mjs --records ...` invocation would.

**Fix:** No action required; noting for awareness given this review's mandate to flag anything that could let a stale/bad state pass as proven.

---

_Reviewed: 2026-09-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
