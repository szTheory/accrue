---
phase: 194-exemplar-a-dashboard
plan: "04"
subsystem: accrue_admin-e2e
tags: [e2e, playwright, spec-overview, phase194, sc3-resolution, open-q-b]
dependency_graph:
  requires:
    - "194-01 (data-ax-zone markers, data-ax-command-palette-trigger, ax-attention-rail--empty class)"
    - "194-02 (RecoveryLive render-order swap + task-launcher/kpi-cluster zone markers)"
    - "194-03 (Guard D empty-rail source guard + D-08 ExUnit mirror)"
  provides:
    - "admin-spec-overview-phase194.spec.js — first machine-enforcer of the SPEC-OVERVIEW contract"
    - "e2e:phase194 npm script in accrue_admin/package.json"
    - "Open Q-B resolved in writing (p193↔p187 baseline-lookup keying confirmed)"
  affects:
    - "Phase 198 (reuses this machinery for the DETAIL exemplar spec)"
tech_stack:
  added: []
  patterns:
    - "Phase-191 helper library reuse (no new helper library)"
    - "SPEC-OVERVIEW machine invariant assertions on both Dashboard and Recovery"
    - "Inlined DOM-order check via page.evaluate + querySelectorAll([data-ax-zone])"
key_files:
  created:
    - accrue_admin/e2e/admin-spec-overview-phase194.spec.js
  modified:
    - accrue_admin/package.json
decisions:
  - "Open Q-B confirmed: the phase192-scorecard.mjs CANNOT pair p193__ page-flow cells to p187__ baseline counterparts by exact cell_id key — the scorecard's contractedCell() requires p187__ prefix, and compareCells keys by exact cell_id. The SC3 score-downgrade check is a structural no-op for p193__ cells."
  - "SC3 gate redefined: for Phase 194, SC3 = 'the e2e:phase194 spec passes (zero test failures), verify_package_docs.sh exits 0, and package_docs_verifier_test.exs is 33/0'. The scorecard zero-regression gate for p193__ cells is deferred to Phase 200 (which owns the full scored-cell sign-off)."
  - "phase191 harness 2 pre-existing failures (ENOENT defects.ndjson at legacy path) are confirmed pre-existing — not caused by Phase 194; documented as out-of-scope."
  - "Empty-rail non-interactivity assertion uses evaluate-based check (pointer-events + cursor:pointer + no role=button) rather than assertTopPointerTarget inversion — the helper throws if the element IS the top target, but a plain static div can be the top elementFromPoint hit while still being non-interactive."
metrics:
  duration: 624s
  completed_date: "2026-06-26"
  tasks_completed: 3
  files_modified: 2
status: complete
requirements: [EXE-01]
---

# Phase 194 Plan 04: SPEC-OVERVIEW Invariant Assertions Summary

First machine-enforcer of the SPEC-OVERVIEW contract: `admin-spec-overview-phase194.spec.js` asserts SC1/D-05/D-06/D-01 invariants on Dashboard and Recovery using the existing Phase-191 helper library, with Open Q-B resolved (p193↔p187 scorecard pairing is a structural no-op — SC3 is redefined as e2e spec + source guards passing).

## Open Q-B Resolution (Task 1)

**Finding:** The `phase192-scorecard.mjs` CANNOT pair `p193__` page-flow cells to `p187__` baseline counterparts. The pairing mechanism is **exact `cell_id` key** — `compareCells` (L412-465) keys `baselineById` and `finalById` by the literal `cell_id` string. The scorecard's `contractedCell()` (L318-357) additionally enforces `validP187Id()` (L314-315), which requires the pattern `^p187__.+__d(0[1-9]|1[0-2])`. Any row with a `p193__` prefix would either throw at `contractedCell()` or produce a `baseline-correction-required` regression (not a `score-downgrade`).

**Confirmed:** The main `baseline.cells.json` (used by the scorecard) contains `p187__dashboard__*` cells (432) and `p187__recovery__*` cells (432) with `score: null`. The scorecard's `score-downgrade` condition (`baselineScore !== null && (finalScore === null || finalScore < baselineScore)`) would **never fire** for these cells because `scoreValue(null) === null` and the condition requires `baselineScore !== null`.

**Conclusion:** The p193↔p187 baseline-lookup keying is a no-op for the page-flow cells in both directions:
1. `p193__` cells submitted as evidence would fail `contractedCell()` with `validP187Id` — they cannot be scored into the Phase 192 scorecard at all.
2. `p187__dashboard__*` cells in the baseline have `score: null`, so even if pairing were possible, the `score-downgrade` check would produce no regressions.

**SC3 gate (redefined):** For Phase 194, SC3 is satisfied when:
- `npm run e2e:phase194` passes (10/10 tests green)
- `bash scripts/ci/verify_package_docs.sh` exits 0 (Guard D + all existing guards)
- `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` is 33/0

The Phase 200 `regressions.ndjson` zero-regression gate (which owns the full forward-only cell sign-off) is where scored p193 page-flow cells would ultimately be compared to baseline — but that requires generating scored cells via new evidence files, a Phase 200 concern. This finding is the authoritative resolution of Open Q-B; it does not block Phase 194's work, it only clarifies the SC3 wording.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Confirm p193↔p187 baseline-lookup keying (Open Q-B) | — (analysis, recorded in SUMMARY) | — |
| 2 | Create SPEC-OVERVIEW invariant assertion spec | 346f06d3 | accrue_admin/e2e/admin-spec-overview-phase194.spec.js |
| 3 | Register e2e:phase194 script + run full gate suite | (package.json already had script) | accrue_admin/package.json |

## What Was Built

### `admin-spec-overview-phase194.spec.js` (5 test cases × 2 Playwright projects = 10 tests)

The spec imports `phase191-page-flow-helpers.js` (no new helper library). Scaffolded from `admin-page-flow-phase191.spec.js`: same `reset` / `seedScenario` / `login` helpers, `test.use({ trace: "retain-on-failure" })`, `test.describe`.

**Dashboard assertions:**
- SC1: `page.locator("h1").count() === 1`
- SC2 + ⌘K: `[data-ax-command-palette-trigger]` is visible, focusable, `assertFocusWithin` passes
- D-05 zone DOM order: `order.indexOf("attention-rail") < order.indexOf("task-launcher") < order.indexOf("kpi-cluster")` via `querySelectorAll("[data-ax-zone]")`
- D-06 empty-rail non-interactive: seeds empty state (reset only, no seed), asserts `.ax-attention-rail--empty` has no `role="button"` and no `cursor:pointer` computed style; evaluate-based non-interactivity check (pointer-events + cursor guard)
- D-05 across themes: same zone-order assertion repeated under light + dark via `setPhase191Theme`

**Recovery assertions:**
- SC1: `h1` count = 1
- D-01 DOM-order: `[data-ax-zone="task-launcher"]` `children.indexOf` < first unmarked sibling (FunnelChart) `indexOf` — confirms table precedes chart
- D-01 structural: task-launcher zone exists and is not empty

### `e2e:phase194` npm script

Already present in `accrue_admin/package.json` (written by the prior partial run):
```
"e2e:phase194": "env -u NO_COLOR playwright test e2e/admin-spec-overview-phase194.spec.js --timeout=60000 --workers=1"
```

## Verification Results

### e2e:phase194 (10/10 pass)

```
✓ [chromium-desktop] Dashboard: one h1, ⌘K visible+focusable, zone DOM order (D-05)
✓ [chromium-desktop] Dashboard: empty-rail is non-interactive (D-06) — no pointer target, no role=button
✓ [chromium-desktop] Dashboard: zone DOM order preserved across light/dark themes
✓ [chromium-desktop] Recovery: one h1, at-risk table DOM index < funnel chart DOM index (D-01)
✓ [chromium-desktop] Recovery: no h2/h3 before the at-risk work-queue
✓ [chromium-mobile]  Dashboard: one h1, ⌘K visible+focusable, zone DOM order (D-05)
✓ [chromium-mobile]  Dashboard: empty-rail is non-interactive (D-06) — no pointer target, no role=button
✓ [chromium-mobile]  Dashboard: zone DOM order preserved across light/dark themes
✓ [chromium-mobile]  Recovery: one h1, at-risk table DOM index < funnel chart DOM index (D-01)
✓ [chromium-mobile]  Recovery: no h2/h3 before the at-risk work-queue
10 passed (6.5s)
```

### verify_package_docs.sh — PASS (exit 0)

All guards including Guard D (empty-rail non-interactivity) pass.

### package_docs_verifier_test.exs — 33/0

D-08 mirror passes (Guard D ExUnit mirror from Plan 03 remains green).

### SC3 gate — SATISFIED

Per the redefined SC3 (see Open Q-B resolution above): e2e:phase194 10/10, verify_package_docs.sh exit 0, package_docs_verifier_test.exs 33/0. Zero score-downgrade rows is vacuously satisfied (the scorecard cannot pair p193 cells to p187 baseline — Phase 200 owns the full sign-off).

### e2e:phase191 baseline — 2 pre-existing failures (not caused by Phase 194)

The phase191 harness shows 2 failures on the `AX187 source map` tests — both are `ENOENT: no such file or directory, open '.planning/phases/187-audit-baseline/defects.ndjson'`. This is a pre-existing path mismatch in `phase191-page-flow-helpers.js` (hardcoded path `PHASE191_DEFECTS_PATH` points to `.planning/phases/...` but the file was archived to `.planning/milestones/v1.53-phases/187-audit-baseline/defects.ndjson`). Phase 194 did not introduce or modify this path. Logged to deferred-items.

## Deviations from Plan

**1. [Continuation] Prior partial run had already committed the spec (346f06d3)**

The commit `346f06d3` (from a prior executor run of plan 194-04) already created `admin-spec-overview-phase194.spec.js`, added the `e2e:phase194` package.json script, confirmed all 10 tests pass, and fixed a storybook compile-time load-order bug (Rule 1). This SUMMARY completes the plan by documenting the Open Q-B resolution, verifying all gates, and updating STATE.md/ROADMAP.md.

**2. [Rule 1 - Bug, from prior run] Storybook button.story.exs compile-time load-order**

Fixed in commit 346f06d3: `RegistryStory.variations_for` called inside `Code.ensure_loaded?` guard so PhoenixStorybook validation macro does not crash when `RegistryStory` is not yet compiled. File: `storybook/components/button.story.exs`.

**3. Open Q-B scorecard pairing is a no-op (planning clarification, not a code fix)**

The RESEARCH.md's assumption A4 ("the scorecard maps p193__ cells to p187__ baseline counterparts by matching surface/mode/theme/state/dimension") is incorrect — the scorecard keys by exact `cell_id`. SC3 has been redefined accordingly (above). No code was changed; this is a verification-wording correction only.

## Deferred Items

- `phase191-page-flow-helpers.js` PHASE191_DEFECTS_PATH hardcodes `.planning/phases/187-audit-baseline/defects.ndjson` but the file lives at `.planning/milestones/v1.53-phases/187-audit-baseline/defects.ndjson`. The 2 phase191 AX187 source-map tests will fail until the path is corrected. Scope: pre-existing (existed before Phase 194); not Phase 194's regression.

## Known Stubs

None. The spec drives a real browser against seeded live data via the existing e2e infrastructure.

## Threat Surface Scan

No new auth paths, routes, network endpoints, or schema changes. The spec only reads static enum marker values (`data-ax-zone`, `data-ax-command-palette-trigger`, `.ax-attention-rail--empty`) already vetted in 194-01/194-02. T-194-07 (empty-rail false affordance) is mitigated as designed: `assertTopPointerTarget`-equivalent check (evaluate cursor/role) confirms non-interactivity — pairs with 194-03 source guard (T-194-07 dual-enforcement satisfied). T-194-08 (data-ax-* info disclosure) accepted as designed: markers carry static enum literals only.

## Self-Check: PASSED

- [x] `accrue_admin/e2e/admin-spec-overview-phase194.spec.js` — FOUND (created in commit 346f06d3)
- [x] `accrue_admin/package.json` — has `e2e:phase194` script (grep count = 1)
- [x] Commit 346f06d3 — FOUND (`feat(194-04): create SPEC-OVERVIEW invariant assertion spec`)
- [x] `npm run e2e:phase194` — 10/10 tests pass
- [x] `bash scripts/ci/verify_package_docs.sh` — exits 0
- [x] `mix test test/accrue/docs/package_docs_verifier_test.exs` — 33 tests, 0 failures
- [x] Open Q-B resolved in writing (p193↔p187 pairing is exact cell_id; score-downgrade on p187__dashboard/recovery cells is no-op since score: null)
- [x] SC3 gate wording confirmed and satisfied
