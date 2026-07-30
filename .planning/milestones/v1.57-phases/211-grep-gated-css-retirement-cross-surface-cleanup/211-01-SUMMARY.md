---
phase: 211-grep-gated-css-retirement-cross-surface-cleanup
plan: 01
subsystem: testing
tags: [css, dead-code, tooling, node-esm, admin-ui, orphan-guard]

# Dependency graph
requires:
  - phase: 210-reign-home-certify-answer-first-ia-copy-integrity
    provides: "Home/Subscriptions markup already migrated off the .ax-*-to-retire vocabulary — the precondition that makes the 92 DELETE classes zero-reference"
provides:
  - "accrue_admin/e2e/verify-css-census.mjs — dependency-free exact-token orphan/dangling ax-* CSS census guard with --self-test mode (D-02)"
  - "css:census / css:census:self-test npm aliases"
  - "Pre-Phase-211 accrue_admin mix test baseline: 514 tests, 0 failures (Wave 4 no-regression reference)"
  - "Independent cross-validation that the guard flags all 92 RESEARCH.md named DELETE classes and none of the 16 PRESERVE classes"
affects: [211-02, 211-03, 211-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Standalone Node ESM dev-tool with a pure --self-test fixture mode (mirrors e2e/ratchet/region-tags.js runSelfTest discipline): no tmp dirs, no network, no browser"
    - "Exact-token CSS liveness matching via (?<![\\w-])TOKEN(?![\\w-]) lookaround (never substring/\\b) to avoid hyphen-suffix and data-attribute false positives"

key-files:
  created:
    - accrue_admin/e2e/verify-css-census.mjs
  modified:
    - accrue_admin/package.json

key-decisions:
  - "Guard operates at class-NAME granularity (per RESEARCH Orphan/Dangling Guard design + Pitfall 3): it flags a name only when zero-referenced anywhere in lib/storybook/test/e2e. Compound-selector-level dead rules whose class NAME is still live elsewhere (e.g. .ax-home .ax-page-actions) are intentionally NOT flagged — flagging them would be a dangerous false positive telling Wave 2 to delete a live class."
  - "No CSS deletion in this wave — this plan builds and validates the safety net and records the baseline only."

patterns-established:
  - "verify-css-census.mjs: reusable CSS-liveness census — Plan 03 re-runs it post-deletion to prove the cut is clean"

requirements-completed: []  # REIGN-04 is shared across all 4 plans (211-01..04); it stays incomplete until 211-04's SUMMARY exists (shared-ID gate).

coverage:
  - id: D1
    description: "Dependency-free ax-* CSS census guard with --self-test covering orphan, live, and both exact-token boundary landmines"
    requirement: REIGN-04
    verification:
      - kind: unit
        ref: "cd accrue_admin && npm run css:census:self-test"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pre-Phase-211 accrue_admin mix test baseline captured verbatim (514 tests, 0 failures) as the Wave 4 no-regression reference"
    requirement: REIGN-04
    verification:
      - kind: unit
        ref: "cd accrue_admin && mix test  → 514 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: "Independent cross-validation of the guard against the RESEARCH.md census: all 92 named DELETE classes flagged as orphans, all 16 PRESERVE classes excluded"
    requirement: REIGN-04
    verification:
      - kind: automated_ui
        ref: "node cross-check of npm run css:census output vs RESEARCH census: 92/92 DELETE flagged, 0/16 PRESERVE false-positives"
        status: pass
    human_judgment: false

# Metrics
duration: 16 min
completed: 2026-07-28
status: complete
---

# Phase 211 Plan 01: Orphan-guard baseline Summary

**Dependency-free exact-token `ax-*` CSS orphan/dangling census guard (`verify-css-census.mjs` + `--self-test`), independently cross-validated to flag all 92 named DELETE classes and zero PRESERVE classes, with the true pre-Phase-211 `mix test` baseline (514/0) on record for Wave 4.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-07-28T15:40:00Z (approx)
- **Completed:** 2026-07-28T15:56:49Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- Authored `accrue_admin/e2e/verify-css-census.mjs`: a standalone Node ESM guard using only `node:fs`/`node:path`/`node:url` built-ins (zero new dependencies) that extracts every `.ax-*` selector from `assets/css/app.css` and reports (a) orphans — selectors with zero exact-token references across `lib`/`storybook`/`test`/`e2e`, and (b) missing rules — `ax-*` class tokens used in `class=` markup with no matching selector (informational).
- Implemented the validated `(?<![\w-])TOKEN(?![\w-])` lookaround matching so `ax-launcher` is NOT matched by `ax-launchers` and `ax-launcher-primary` is NOT matched by `data-ax-launcher-primary` (RESEARCH Pitfall 1). `--self-test` proves both boundary landmines in-memory (<0.2s, no fs/network).
- Added `css:census` / `css:census:self-test` npm aliases (no dependency entries).
- Captured the pre-Phase-211 `accrue_admin` baseline: **514 tests, 0 failures** (no skips/excluded reported) — the Wave 4 no-regression reference point.
- Cross-validated the guard against the RESEARCH.md census: **all 92 named DELETE classes appear in the orphan report; none of the 16 PRESERVE classes appear** (guard proven trustworthy before Wave 2/3 depend on it).

## Task Commits

1. **Task 1: Author the orphan/dangling ax-* CSS census guard with --self-test** - `8b0c65fb` (feat)
2. **Task 2: Capture pre-Phase-211 mix test baseline + cross-validate guard vs census** - no code commit (read-only: runs the guard + `mix test`; results recorded here)

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Files Created/Modified
- `accrue_admin/e2e/verify-css-census.mjs` - New: exact-token orphan/dangling `ax-*` CSS census guard + `--self-test` fixtures (orphan, live, both boundary cases, plus a Pitfall 2 comma-branch bonus fixture).
- `accrue_admin/package.json` - Added `css:census` and `css:census:self-test` script aliases (no new `dependencies`/`devDependencies`).

## Baseline & Cross-Validation Evidence (verbatim)

**Pre-Phase-211 `accrue_admin` mix test baseline:**
```
514 tests, 0 failures
```
(No skipped/excluded count reported in the summary line. Note: the one known pre-existing flake — `PdfTest` — lives in core `accrue`, not `accrue_admin`, so it is out of scope for this baseline.)

**Guard real-world scan (`npm run css:census`) against current pre-deletion `assets/css/app.css`:**
- Candidate `ax-*` selectors: **702**
- Searched files: **218** (`.ex`/`.exs`/`.js` under `lib`, `storybook`, `test`, `e2e`)
- Orphan selectors reported: **202** (exit code 1 — expected, dead CSS present pre-deletion)
- Missing rules (informational): 66

**Cross-check vs RESEARCH.md census:**
- Named DELETE classes flagged as orphans: **92 / 92** — NONE missing ✓
- PRESERVE false-positives: **0 / 16** ✓
- Adjacent (D-01): `ax-dashboard-title-row` flagged ✓; `ax-page-actions` and `ax-page-header-compact` correctly NOT flagged (see deviation below).
- The 202-orphan report is a **superset of the 92+ target census** (~110 additional dead selectors outside REIGN-04's named families — e.g. `ax-detail-*`, `ax-dev-*`, `ax-type-*`, `ax-tab-more-*`, `ax-work-queue-*`). These extras are informational and OUT OF SCOPE for this phase's deletion (REIGN-04 names 8 specific families only).

## Decisions Made
- **Guard granularity is class-NAME liveness, matching the RESEARCH "Orphan/Dangling Guard" design and Pitfall 3.** It reports a selector name as orphan only when that exact token has zero references anywhere in the searched trees. This is the correct, trustworthy contract for Wave 2/3.
- **No enhancement to detect compound-selector-context dead rules.** The RESEARCH design mandates "genuinely cheap: no browser, no build step, no CSS parsing beyond regex extraction." Detecting `.ax-home .ax-page-actions`-style dead-because-of-ancestor rules would require a full descendant-combinator CSS parser and would risk false positives on live class names — explicitly out of the guard's mandate.

## Deviations from Plan

### Clarifications / documented interpretation

**1. [Rule 1-adjacent - Correctness clarification] Two of the "5 D-01 adjacent selectors" are intentionally NOT in the orphan list — the guard is correct, the acceptance criterion was over-specified**
- **Found during:** Task 2 (census cross-validation)
- **Issue:** Task 2's acceptance criterion states the guard's orphan report must "include all 97 target selectors (92 named + 5 adjacent)." The 5 D-01 adjacent items are RULE SITES (`.ax-home .ax-page-header-compact`, `.ax-home .ax-page-actions`, `.ax-home .ax-page-actions .ax-button-sm`, `.ax-dashboard-title-row`, `.ax-dashboard-title-row .ax-display`) spanning only 3 distinct class NAMES. Of those, `ax-page-header-compact` (live at `component_kitchen_live.ex:74`) and `ax-page-actions` (live at `charge_live.ex:186`, `connect_account_live.ex:177`, `subscription_live.ex:344`, `invoice_live.ex:289`, `component_kitchen_live.ex:86`) are LIVE class names — their deadness exists ONLY when nested under `.ax-home`. A class-NAME-level orphan guard cannot and must not flag them, because flagging them would tell Wave 2 to delete a class that is live on other pages (exactly the Pitfall-3 failure mode).
- **Fix:** No code change — the guard behaves correctly per its RESEARCH-specified design. Documented so Wave 2 knows the 3 compound `.ax-home ...` adjacent rules must be deleted by following RESEARCH's exact line numbers (5766, 5909, 5913, 5730, 5737), NOT via the orphan guard, and that re-running the guard afterward will (correctly) stay silent about `ax-page-actions`/`ax-page-header-compact`.
- **Files modified:** none
- **Verification:** Cross-check confirms all 92 named DELETE classes flagged, 0/16 PRESERVE false-positives, and `ax-dashboard-title-row` (the one truly zero-reference adjacent name) flagged. The guard's trustworthiness for REIGN-04's named scope is fully established.
- **Committed in:** n/a (documentation only)

---

**Total deviations:** 1 documented clarification (0 code changes)
**Impact on plan:** None on scope. The guard is proven correct and trustworthy for the 92 named DELETE families and 16 PRESERVE classes — the actual safety-net requirement for Wave 2/3. The adjacent compound rules remain Wave 2 manual-deletion targets guided by RESEARCH line numbers, as RESEARCH already documents.

## Issues Encountered
None. Both tasks completed as planned; self-test and baseline both green on first run.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- **Ready for 211-02 (deletion wave).** The orphan guard is authored, self-test-proven, and cross-validated; the pre-deletion baseline (514/0) is on record. Plan 02 can delete the 92 named DELETE classes (grouped by RESEARCH's current line ranges, sweeping the Pitfall-2 comma-branch fragments at branch level) and re-run `npm run css:census` to confirm the cut, then rebuild the bundle.
- No blockers.

## Self-Check: PASSED
- `accrue_admin/e2e/verify-css-census.mjs` exists on disk ✓
- `211-01-SUMMARY.md` exists on disk ✓
- Task 1 commit `8b0c65fb` present in git log ✓
- `css:census` / `css:census:self-test` aliases present in package.json ✓
- `npm run css:census:self-test` exits 0 (all fixtures pass) ✓
- Pre-Phase-211 baseline recorded verbatim (514 tests, 0 failures) ✓

---
*Phase: 211-grep-gated-css-retirement-cross-surface-cleanup*
*Completed: 2026-07-28*
