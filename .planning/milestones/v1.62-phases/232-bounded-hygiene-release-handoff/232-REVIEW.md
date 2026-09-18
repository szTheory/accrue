---
phase: 232-bounded-hygiene-release-handoff
reviewed: 2026-09-17T00:00:00Z
depth: standard
files_reviewed: 54
files_reviewed_list:
  - .github/workflows/ci.yml
  - RELEASING.md
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - release-please-config.json
  - scripts/ci/README.md
  - scripts/ci/apple_notification_delivery_smoke.mjs
  - scripts/ci/bootstrap_stripe_provider_proof.mjs
  - scripts/ci/collect_ci_baseline.mjs
  - scripts/ci/collect_gate01_cohort.mjs
  - scripts/ci/collect_hygiene_dispositions.mjs
  - scripts/ci/collect_integration_disposition.mjs
  - scripts/ci/collect_repository_inventory.mjs
  - scripts/ci/collect_window_dispositions.mjs
  - scripts/ci/generate_phase200_closeout_reports.mjs
  - scripts/ci/main_module.mjs
  - scripts/ci/phase229_gap_closure.test.mjs
  - scripts/ci/phase_evidence_path.mjs
  - scripts/ci/provider_proof.mjs
  - scripts/ci/provider_proof_automation.mjs
  - scripts/ci/render_ci_baseline.mjs
  - scripts/ci/render_gate01_cohort.mjs
  - scripts/ci/render_hygiene_dispositions.mjs
  - scripts/ci/render_integration_disposition.mjs
  - scripts/ci/render_provider_summary.mjs
  - scripts/ci/render_repository_inventory.mjs
  - scripts/ci/render_window_dispositions.mjs
  - scripts/ci/stripe_test_fixtures.mjs
  - scripts/ci/verify_admin_ui_ratchet_ci_contract.sh
  - scripts/ci/verify_ci_baseline.mjs
  - scripts/ci/verify_ci_critical_path.mjs
  - scripts/ci/verify_ci_critical_path.test.mjs
  - scripts/ci/verify_ci_script_contract.mjs
  - scripts/ci/verify_executable_uat_contract.mjs
  - scripts/ci/verify_foundation_contrast.mjs
  - scripts/ci/verify_gate01_cohort.mjs
  - scripts/ci/verify_hygiene_dispositions.mjs
  - scripts/ci/verify_integration_disposition.mjs
  - scripts/ci/verify_phase191_ax187_coverage.mjs
  - scripts/ci/verify_phase192_scorecard.mjs
  - scripts/ci/verify_phase192_signoff.mjs
  - scripts/ci/verify_phase200_scorecard.mjs
  - scripts/ci/verify_phase200_signoff.mjs
  - scripts/ci/verify_phase229_handoff_invariants.mjs
  - scripts/ci/verify_phase230_archive_invariants.mjs
  - scripts/ci/verify_pr_body_contract.mjs
  - scripts/ci/verify_provider_proof.mjs
  - scripts/ci/verify_ratchet_ledger.mjs
  - scripts/ci/verify_recut_candidate.mjs
  - scripts/ci/verify_release_pr_readiness.sh
  - scripts/ci/verify_repository_inventory.mjs
  - scripts/ci/verify_stripe_test_fixtures.mjs
  - scripts/ci/verify_stripe_webhook_boot_evidence.mjs
  - scripts/ci/verify_ui_ratchet_signoff.mjs
  - scripts/ci/verify_window_dispositions.mjs
findings:
  critical: 2
  warning: 3
  info: 2
  total: 7
status: issues_found
---

# Phase 232: Code Review Report

**Reviewed:** 2026-09-17
**Depth:** standard
**Files Reviewed:** 54
**Status:** issues_found

## Summary

Phase 232 is release-integration hygiene: it builds merge-blocking verifiers whose whole
job is to make claims falsifiable, and by and large it does that well. The `isMainModule`
migration is a genuine improvement, the window-disposition total-map bucketing (D-13/D-14)
is correctly reachable-in-both-directions, the D-16 fix (wiring a real, SHA-pinned check of
the committed window-disposition pair into CI) is real and verified live, the hygiene
dispositions triad's no-deletion structural invariant (D-47) is real, and the sanitization
pattern reuse the phase's own SUMMARYs flagged as a workaround (`sanitizeLeakCheck` in
`collect_hygiene_dispositions.mjs`) was in fact cleaned up later in the phase into a genuine
single-source `export`/`import` (the stale comment describing the old workaround is the one
remaining defect from that history — see IN-01). No `grep -P`, no hardcoded secrets, no
`adopter-app` literal leaked into any committed artifact, and the security bar (no local
filesystem paths / adopter names in public artifacts) holds under live re-verification.

Two real defects earn Critical status. First, the exact "guard swap only" files from
232-02's own declared scope-limiting deviation (`collect_repository_inventory.mjs`,
`render_repository_inventory.mjs`, `collect_integration_disposition.mjs`,
`render_integration_disposition.mjs`, `render_gate01_cohort.mjs`,
`verify_phase230_archive_invariants.mjs`) call `isMainModule(import.meta.url)` bare, without
the `try/catch` wrapper 232-01's own Deviation 3 established as load-bearing and explicitly
told 232-02 to "carry forward... or every migrated file will reproduce the same
bare-import-crashes-under-empty-argv1 regression." They did reproduce it — confirmed live,
reproducibly, against all six files. The D-32 meta-verifier (`verify_ci_script_contract.mjs`)
does not catch this because `assertGuardCoverage` only checks for the import statement, and
`assertNonVacuity` only spawns the file via `node --test` (a shape that never empties
`argv[1]`), so the meta-verifier's own stated purpose — "closes... the gap" of a file that
merely imports the guard without correct usage — is exactly the gap it leaves open here.
Second, `verify_release_pr_readiness.sh`'s default `TARGET_BRANCH` still points at
`integration/v1.62-candidate` (the pre-re-cut branch, superseded by 232-09's own
maintainer-directed re-cut to `integration/v1.62-candidate-recut`), so the wired CI step
proves release-readiness of a branch that is not the one 232-11's integration PR actually
targets, and nothing in `ci.yml`, `RELEASING.md`, or the script itself overrides it.

## Critical Issues

### CR-01: Six `isMainModule` call sites reproduce the exact crash class D-29 exists to prevent

**File:** `scripts/ci/collect_repository_inventory.mjs:475,477`, `scripts/ci/render_repository_inventory.mjs:67,69`, `scripts/ci/collect_integration_disposition.mjs:908,912`, `scripts/ci/render_integration_disposition.mjs:252,256`, `scripts/ci/render_gate01_cohort.mjs:67,71`, `scripts/ci/verify_phase230_archive_invariants.mjs:697`

**Issue:** `main_module.mjs`'s `isMainModule()` throws (rather than returning a silent
`false`) when `process.argv[1]` is empty — a deliberate D-29 design choice. Every other
call site in the cohort wraps the call as `let invokedAsEntrypoint = false; try {
invokedAsEntrypoint = isMainModule(import.meta.url); } catch { invokedAsEntrypoint = false;
}`, exactly the pattern 232-01-SUMMARY.md's Deviation 3 established and explicitly told
232-02 to carry forward ("or every migrated file will reproduce the same
bare-import-crashes-under-empty-argv1 regression"). These six files instead call it bare
inside a top-level `if`:
```js
if (!process.env.NODE_TEST_CONTEXT && isMainModule(import.meta.url)) { ... }
```
232-02-SUMMARY.md's own key-decisions confirm these six were migrated as "guard swap only"
— a mechanical idiom-1/idiom-2 text replacement, not the wrapped pattern. Confirmed
reproducible live:
```
$ node --input-type=module -e "import('./scripts/ci/collect_repository_inventory.mjs')"
Uncaught Error: isMainModule: process.argv[1] is empty -- cannot determine the invoking entrypoint
```
Same crash confirmed for `render_gate01_cohort.mjs`, `collect_integration_disposition.mjs`,
`render_integration_disposition.mjs`, `render_repository_inventory.mjs`, and
`verify_phase230_archive_invariants.mjs` (this last one already has real
`node:test` registrations so its crash is somewhat softer in the `node --test` case, but the
bare `import()` case still throws uncaught).

This is not a hypothetical: `scripts/ci/verify_ci_script_contract.mjs` (the D-32
meta-verifier whose stated purpose is "closes both gaps" — vacuity and guard coverage) does
NOT catch it. `assertGuardCoverage` only regex-checks for the import statement
(`/from\s+["']\.\/main_module\.mjs["']/` + `/\bisMainModule\b/`), never for the try/catch
wrapping. `assertNonVacuity` spawns each file via `node --test --test-reporter=tap <file>`,
which always sets a real, non-empty `argv[1]` — a shape that can never trigger the throw. So
the meta-verifier is green (`node scripts/ci/verify_ci_script_contract.mjs --repo .
--expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity
--require-cohort-floor` passes) while six of the cohort's files still have the exact
ambiguous-entrypoint crash defect the whole migration exists to eliminate. Any future caller
that dynamically imports one of these modules with an ambiguous entrypoint (the same
methodology 232-04's own `<verify>` block used for `collect_window_dispositions.mjs` before
that file's Rule-1 fix) will crash instead of resolving to "not the entrypoint" — a
merge-blocking gate silently converts a benign import into an uncaught exception.

**Fix:** Apply the same `try { invokedAsEntrypoint = isMainModule(import.meta.url); } catch
{ invokedAsEntrypoint = false; }` wrapper to all six files, matching the pattern already used
by `verify_gate01_cohort.mjs`, `verify_repository_inventory.mjs`,
`verify_integration_disposition.mjs`, `collect_gate01_cohort.mjs`, and
`collect_window_dispositions.mjs`/`render_window_dispositions.mjs` (post-232-04). Then
strengthen `assertGuardCoverage` in `verify_ci_script_contract.mjs` to also assert the
try/catch shape is present (e.g. a regex for `catch` within N lines after the
`isMainModule(` call, or a live dynamic-import probe per file with `argv[1]` cleared) so this
class cannot silently regress again.

### CR-02: `verify_release_pr_readiness.sh` defaults to the stale, superseded candidate branch

**File:** `scripts/ci/verify_release_pr_readiness.sh:39`

**Issue:**
```bash
TARGET_BRANCH=${RELEASE_PR_READINESS_TARGET_BRANCH:-integration/v1.62-candidate}
```
This script (232-05) was authored and its default hardcoded before 232-09's re-cut. 232-09's
own SUMMARY records, as its single most load-bearing carry-forward fact: "**The re-cut
candidate lives at branch `integration/v1.62-candidate-recut`
(`c1397fe9127a9b4b2b1d3a0758d57879b14f4604`), NOT at `integration/v1.62-candidate` (still
`f524f2a6`, unchanged)**... any downstream reference to 'the re-cut candidate branch' must
target `integration/v1.62-candidate-recut` explicitly." Confirmed live — the two branches
still resolve to different SHAs today:
```
$ git rev-parse origin/integration/v1.62-candidate origin/integration/v1.62-candidate-recut
f524f2a6b16d3576829632ab6fa77d24b718e6f7
c1397fe9127a9b4b2b1d3a0758d57879b14f4604
```
232-11's integration PR body and `ci.yml`'s D-16 window-dispositions step were both updated
to reference `integration/v1.62-candidate-recut` (SHA-pinned) — this script was not. Nothing
in `.github/workflows/ci.yml`'s wired step (`Release PR readiness dry run (REL-05)`,
line ~360), `RELEASING.md`, or the script itself sets
`RELEASE_PR_READINESS_TARGET_BRANCH` to override the stale default. The script's own header
comment still asserts "The integration candidate is the branch this milestone's REL-04
integration PR targets for merge into `main`" — a factually false statement as of 232-09's
own recorded deviation. REL-05's entire premise is "prove the branch that will actually
become the release PR is ready"; this proves that property about a branch that provably will
not (the old candidate was explicitly abandoned in favor of a new branch name specifically
because the old one could not be fast-forwarded without a force-push the plan's own
prohibitions forbid). A green run of this CI step is therefore not evidence about the
candidate that matters.

**Fix:** Update the default to `integration/v1.62-candidate-recut` (or better, derive it
from the same source of truth `232-ROLLBACK-POINT.json`/`232-WINDOW-DISPOSITIONS.json`
already pin, so a future re-cut cannot silently strand this script again), and refresh the
header comment's factual claim about which branch the integration PR targets.

## Warnings

### WR-01: `assertGuardCoverage` cannot distinguish a correct guard from a crash-prone one

**File:** `scripts/ci/verify_ci_script_contract.mjs:64-71`

**Issue:** Beyond the six files CR-01 names concretely, `assertGuardCoverage`'s regex check
(`importsGuard = /from\s+["']\.\/main_module\.mjs["']/.test(source) &&
/\bisMainModule\b/.test(source)`) is structurally incapable of ever detecting the
bare-vs-wrapped distinction — it is satisfied by mere textual presence of the import and the
identifier, matching the exact "verifier can pass while the property it claims to check is
false" failure mode this review was asked to prioritize. Any future file that copies the
bare idiom (an easy mistake, since it is shorter to write and both the collect/render
variants of `repository_inventory`, `integration_disposition`, and `gate01_cohort` already
demonstrate it in the tree as a copyable precedent) will pass this gate silently.

**Fix:** See CR-01's fix — this is the same finding from the meta-verifier's side; listed
separately because it is worth fixing independently of the six current offenders (a
regression-proofing fix, not just a today's-bugs fix).

### WR-02: `collect_hygiene_dispositions.mjs`'s provenance comment is stale and now describes a workaround that was removed

**File:** `scripts/ci/collect_hygiene_dispositions.mjs:57-70`

**Issue:** The comment block above `sanitizeStrings()` says, verbatim: "It is NOT re-exported
from `collect_window_dispositions.mjs` (that file is outside this plan's `files_modified`
scope, so it cannot be edited to add an `export` keyword) and it is deliberately bound under
a name outside the `PATTERN`/`_RE` suffix convention... so Task 1's own `<verify>` census
... continues to report exactly 2." But the actual code three lines above imports the real
thing:
```js
import { UNSAFE_PATH_PATTERN } from "./collect_window_dispositions.mjs";
```
and `collect_window_dispositions.mjs:56` does now `export const UNSAFE_PATH_PATTERN = ...`.
The `sanitizeLeakCheck`-named copy 232-07-SUMMARY.md's Deviation 1 describes was evidently
superseded later in the phase (verify_pr_body_contract.mjs's own header comment even says
"the same pattern `collect_hygiene_dispositions.mjs` already reuses" — describing the
current, correct import-based state), but the in-file comment explaining the old workaround
was never updated to match. A maintainer reading this file in isolation is told a false fact
about the codebase's own extensibility (that the upstream file "cannot" export the pattern)
and about the naming rationale (a name "deliberately outside the `PATTERN`/`_RE` convention"
that no longer exists in the file at all — there is no `sanitizeLeakCheck` identifier left).
This is exactly the kind of stale-comment-instead-of-enforced-invariant drift D-13's own
"comments do not fail CI" framing warns about elsewhere in this phase.

**Fix:** Delete or rewrite the comment to describe the actual current state (a real,
single-source `export`/`import` of `UNSAFE_PATH_PATTERN`, no copy, no naming workaround).

### WR-03: `verify_pr_body_contract.mjs` is unreferenced by `ci.yml` and `scripts/ci/README.md`

**File:** `scripts/ci/verify_pr_body_contract.mjs`, `.github/workflows/ci.yml`, `scripts/ci/README.md`

**Issue:** Per `232-RESEARCH.md`'s own Phase Requirements table this was flagged "new,
optional" for REL-04, and 232-11's plan scope was explicitly Tasks 1-2 only (Task 3, the
checkpoint to open the PR, was deliberately not run) — so non-wiring is plausibly by design
rather than an oversight. Flagging as a Warning (not Critical) because the merge-blocking
contract is genuinely optional per its own design doc, but noting it because
`scripts/ci/README.md` documents every other wired triad/meta-verifier's CI step and command
(see the `CI script contract (D-32)` entry) and says nothing about this one, so a reader has
no way to tell "deliberately not wired" from "forgotten."

**Fix:** Either wire a step running `node --test --test-reporter=tap
scripts/ci/verify_pr_body_contract.mjs && node scripts/ci/verify_pr_body_contract.mjs
--fixtures ...` (hermetic, no reason not to), or add one README line stating it is
intentionally not CI-wired and why (a PR body file that does not exist as a tracked artifact
until a PR is drafted).

## Info

### IN-01: `render_gate01_cohort.mjs` has no CLI usage/help output despite being wired as a CI entrypoint

**File:** `scripts/ci/render_gate01_cohort.mjs:66`

**Issue:** `function main() { ... }` throws a bare `new Error("--input, --out, and
--expected-repository are required")` (mirrored in several sibling render_*.mjs files) with
no `--help`. Consistent with 232-CONTEXT.md's own noted convention drift ("`--help` exists
essentially nowhere"), already flagged as a deferred idea in this phase's own CONTEXT.md, not
a new finding — recorded here only because it recurs in this review's priority file set and
is easy to fix incrementally rather than as its own phase.

**Fix:** No action required this phase (explicitly deferred by 232-CONTEXT.md's own deferred
list — "adding `--help` everywhere... broader than this phase"). No fix suggested beyond what
CONTEXT.md already scoped out.

### IN-02: `verify_release_pr_readiness.sh`'s stale header comment compounds CR-02

**File:** `scripts/ci/verify_release_pr_readiness.sh:35-41`

**Issue:** Beyond the functional default (CR-02), the explanatory comment directly above it
states factually incorrect provenance ("The integration candidate is the branch this
milestone's REL-04 integration PR targets for merge into `main`") for the same reason as
CR-02. Listed separately at Info level because it is pure documentation debt once CR-02 is
fixed — the same edit closes both.

**Fix:** Same edit as CR-02's fix.

---

_Reviewed: 2026-09-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
