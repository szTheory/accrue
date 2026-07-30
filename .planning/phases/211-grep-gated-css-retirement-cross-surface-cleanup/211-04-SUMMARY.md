---
phase: 211-grep-gated-css-retirement-cross-surface-cleanup
plan: 04
subsystem: testing
tags: [css, dead-code, tooling, ratchet, admin-ui, e2e, playwright, verification, css-retirement]

# Dependency graph
requires:
  - phase: 211-grep-gated-css-retirement-cross-surface-cleanup
    provides: "Plan 01 orphan-guard + 514/0 baseline, Plan 02 deletion of 97 dead selectors + rebuilt accrue_admin.css/.js, Plan 03 recomposed storybook.css — the retirement this wave certifies"
provides:
  - "region-tags.js attention-rail selector fixed: points at the real live [data-ax-zone='attention-rail'] instead of the never-existed bare ax-attention-rail string (D-03)"
  - "Phase-boundary certification: full accrue_admin mix test (514/0, matches Plan 01 baseline) + full admin e2e suite (200 passed / 40 skipped / 0 failed) + phase200:storybook (17 mix + 3 e2e) all green"
  - "Scope-guardrail proof: whole-phase diff since Phase 210 commit 412ada26 touches no accrue/lib and adds no nav room/group (router.ex + nav.ex unchanged)"
  - "Human-confirmed PNG parity: subscription detail page (light + dark) shared .ax-inline-worklist*/.ax-audit-summary-row classes render unbroken post-retirement; Subscriptions list, Home, and component kitchen verified"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Phase-certification wave: CSS deletion is invisible to source-text CI, so the closing proof is a full unit+e2e run plus a human PNG-parity check on the out-of-scope surface that shares the retired classes (mirrors Phase 209-03/210-03 closing human-verify checkpoints)"
    - "Regenerate visual-parity artifacts on demand via `npm run e2e:visuals:png-only` (admin-visuals.spec.js) rather than the Docker demo host — MIX_ENV=test serves the committed, freshly-rebuilt priv/static/accrue_admin.css bundle, which is exactly what the CSS-preservation check needs"

key-files:
  created: []
  modified:
    - accrue_admin/e2e/ratchet/region-tags.js

key-decisions:
  - "D-03 scope held tight: only the attention-rail REGION_SELECTORS entry was fixed; the other 9 TODO-marked entries (toolbar, tab-bar, kpi-row, detail-panel, related-panel, timeline, payload-viewer, content-body, layer) were left untouched per the locked D-03 decision — REIGN-04 names only the ax-attention* family."
  - "The two Phase-200 evidence files (page-flow-evidence.json, storybook-a11y.json) that the e2e runs rewrote were reverted — their only diff was a generated_at timestamp (pure run-artifact churn), out of scope for 211-04 which modifies no files beyond region-tags.js."
  - "Verified against the ACTUAL Plan 01 baseline (514/0) as the reference point for 'no red left behind', not an assumed-clean baseline (per plan key_link)."

patterns-established:
  - "region-tags.js REGION_SELECTORS attention-rail now uses the data-ax-zone attribute selector, matching the phase199/210 Playwright ratchet guards and dashboard_live.ex — the canonical live selector for the attention rail."

requirements-completed: [REIGN-04]

coverage:
  - id: D1
    description: "region-tags.js attention-rail REGION_SELECTORS entry fixed from the never-existed bare ax-attention-rail to the real live [data-ax-zone='attention-rail'] (D-03); all other TODO-marked entries untouched; self-test still passes"
    requirement: REIGN-04
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/region-tags.js (require.main self-test) → exit 0; grep attention-rail → [data-ax-zone='attention-rail']; grep -c 'TODO: confirm selector' → 9"
        status: pass
    human_judgment: false
  - id: D2
    description: "Full accrue_admin unit suite green with zero new failures versus the Plan 01 baseline (514 tests, 0 failures)"
    requirement: REIGN-04
    verification:
      - kind: unit
        ref: "cd accrue_admin && mix test → 514 tests, 0 failures (matches 211-01-SUMMARY.md baseline)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Full admin e2e suite + named gates (phase194/196/197/199, a11y) + phase200:storybook all green post-retirement — proves no e2e/test selector references any retired class"
    requirement: REIGN-04
    verification:
      - kind: e2e
        ref: "cd accrue_admin && npm run e2e → 200 passed, 40 skipped, 0 failed (phase194 10✓, phase196 8✓, phase197 15✓, phase199 19✓, admin-a11y 2✓)"
        status: pass
      - kind: e2e
        ref: "cd accrue_admin && npm run phase200:storybook → 17 mix tests 0 failures + storybook a11y 3 passed"
        status: pass
    human_judgment: false
  - id: D4
    description: "Scope guardrails: whole-phase diff since Phase 210 completion commit 412ada26 touches no core accrue/lib and adds no new nav room/group"
    requirement: REIGN-04
    verification:
      - kind: other
        ref: "git diff 412ada26..HEAD --stat -- accrue/lib → empty; git diff 412ada26..HEAD --stat -- accrue_admin/lib/accrue_admin/router.ex accrue_admin/lib/accrue_admin/nav.ex → empty"
        status: pass
    human_judgment: false
  - id: D5
    description: "Subscription detail page (light + dark) shared .ax-inline-worklist*/.ax-audit-summary-row classes render unbroken post-retirement; Subscriptions list, Home, and component kitchen render correctly with no visual regression"
    requirement: REIGN-04
    verification:
      - kind: automated_ui
        ref: "cd accrue_admin && npm run e2e:visual-regression -> toHaveScreenshot pixel-diff of subscription-detail (light+dark) + subscriptions + dashboard + component-kitchen vs committed Linux baselines under e2e/__screenshots__/visual-desktop/; 0 diffs. Blocking gate in accrue_admin_browser.yml browser-uat (quick-260729-rjo, PR #35). Audit-log render-time datetimes masked."
        status: pass
    human_judgment: false
    rationale: "The T-211-05 silent-regression risk on the shared-class detail page IS now asserted by an automated gate: quick-260729-rjo added a deterministic Playwright toHaveScreenshot pixel-diff over all four surfaces in both themes against committed CI-minted baselines, wired blocking into browser-uat. Converts the one-time human PNG approval into a permanent regression guard — no human-verify required. (Original human APPROVAL of both themes still stands as the baseline's provenance.)"

# Metrics
duration: 50 min
completed: 2026-07-29
status: complete
---

# Phase 211 Plan 04: Certification wave — region-tags D-03 fix + full-suite + PNG parity Summary

**Phase 211 certified closed: the one dangling ratchet selector (D-03) fixed to the live `[data-ax-zone='attention-rail']`, the full accrue_admin unit suite (514/0) + e2e suite (200 passed/0 failed) + storybook gate green with zero regressions, no core/nav scope breach, and a human-confirmed unbroken subscription detail page across both themes.**

## Performance

- **Duration:** ~50 min (dominated by two full e2e-suite runs: a first launch interrupted after 4 tests, then a clean 7.7m run)
- **Started:** 2026-07-28 (session start; carried across the day boundary)
- **Completed:** 2026-07-29
- **Tasks:** 3 (2 auto + 1 blocking human-verify checkpoint)
- **Files modified:** 1 (`accrue_admin/e2e/ratchet/region-tags.js`)

## Accomplishments
- **Fixed the D-03 dangling ratchet selector:** `REGION_SELECTORS["attention-rail"]` changed from the never-existed bare `"ax-attention-rail"` class to the real, live `"[data-ax-zone='attention-rail']"` — the selector already used by `dashboard_live.ex` and the phase199/210 Playwright ratchet guards. All 9 other `// TODO: confirm selector` entries left untouched (out of scope per locked D-03); the module's `require.main` self-test still exits 0.
- **Ran the full phase-boundary certification sweep:** `mix test` → **514 tests, 0 failures** (exactly matches the Plan 01 baseline — zero new failures); full `npm run e2e` → **200 passed, 40 skipped, 0 failed** including all named gates (phase194/196/197/199 + a11y, a11y showing only the 2 known deferred dark-contrast items); `npm run phase200:storybook` → **17 mix tests 0 failures + storybook a11y 3 passed**.
- **Proved the scope guardrails:** whole-phase `git diff` since the Phase 210 completion commit `412ada26` touches **no `accrue/lib`** (no core change) and leaves **`router.ex` + `nav.ex` unchanged** (no new nav room/group).
- **Delivered human-confirmed visual parity:** regenerated subscription-detail / subscriptions-list / Home / component-kitchen PNGs (light + dark) from the committed Wave-2-rebuilt bundle; the human APPROVED that the shared `.ax-inline-worklist*` and `.ax-audit-summary-row` classes survived the retirement intact in both themes, with an independent orchestrator PNG read agreeing.

## Task Commits

1. **Task 1: Fix the dangling attention-rail selector in region-tags.js (D-03)** - `d72b3655` (fix)
2. **Task 2: Full mix test + admin e2e suite + no-core-touched / no-nav-room confirmation** - no code commit (verification only; results recorded here)
3. **Task 3: Subscription detail page PNG parity check (light + dark) and final sign-off** - blocking human-verify checkpoint; APPROVED, no code

**Plan metadata:** committed with this SUMMARY (docs: complete plan)

## Files Created/Modified
- `accrue_admin/e2e/ratchet/region-tags.js` - `REGION_SELECTORS["attention-rail"]` fixed to `"[data-ax-zone='attention-rail']"` with an updated inline comment noting the D-03 rationale (matches phase199 guard selector + dashboard_live.ex data-ax-zone attribute).

## Decisions Made
- **Held D-03 scope to the attention-rail entry only.** The other 9 TODO-marked `REGION_SELECTORS` entries stay as-is; REIGN-04 names only the `ax-attention*` family, and `REGION_SELECTORS` is documented non-identity metadata (a wrong value can never affect the ratchet's identity/claim-key), so opportunistic fixing was explicitly out of scope.
- **Reverted incidental Phase-200 evidence churn.** `page-flow-evidence.json` and `storybook-a11y.json` were rewritten by the e2e/storybook runs, but the only diff was a `generated_at` timestamp — reverted to keep the tree clean, since 211-04 modifies no files beyond region-tags.js.
- **Used `e2e:visuals:png-only` (MIX_ENV=test) for the parity artifacts** rather than the Docker demo host — the test server serves the committed, freshly-rebuilt `priv/static/accrue_admin.css`, which is precisely the bundle the CSS-preservation check must validate.

## Deviations from Plan

None - plan executed exactly as written.

The plan's Task 2 acceptance criteria were all met on the first pass (baseline match, all named gates green, both scope diffs empty), and the Task 3 checkpoint was approved without requiring any fix.

**Total deviations:** 0
**Impact on plan:** None — clean certification, no scope creep.

## Issues Encountered
- **First full e2e background run died after 4 tests** (interrupted, not a red — no failure reported, process/server gone, log stale). Resolved by re-launching the suite, which then completed cleanly (200 passed / 0 failed, 7.7m). The likely contributor was Playwright-server contention; sequencing `phase200:storybook` after (not during) the full run avoided a recurrence.
- **admin-visuals PNGs were wiped mid-flow** when the later `phase200:storybook` Playwright invocation cleared the shared `test-results/` outputDir. Resolved by regenerating them with `npm run e2e:visuals:png-only` before presenting the checkpoint.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- **Phase 211 is complete.** REIGN-04 is satisfied across all four plans (01 orphan-guard baseline, 02 deletion + bundle rebuild, 03 storybook recompose, 04 region-tags fix + certification). The CSS retirement is clean, PNG-verified, and regression-free; no core or navigation scope was breached.
- **Milestone v1.57 (Admin Operator Control Plane, M1) is complete** — Phases 209 → 210 → 211 all shipped. Ready for milestone assessment / sign-off. M2 (why-blocked/causality + core diagnosis) and M3 (new rooms + ratchet re-freeze) remain future work.
- No blockers.

## Self-Check: PASSED
- `accrue_admin/e2e/ratchet/region-tags.js` modified on disk, attention-rail → `[data-ax-zone='attention-rail']` ✓
- `211-04-SUMMARY.md` exists on disk ✓
- Task 1 commit `d72b3655` present in git log ✓
- `mix test` 514/0, `npm run e2e` 200/0 failed, `phase200:storybook` green ✓
- Scope diffs vs `412ada26` empty for `accrue/lib`, `router.ex`, `nav.ex` ✓
- Subscription detail PNG parity (light + dark) human-APPROVED ✓

---
*Phase: 211-grep-gated-css-retirement-cross-surface-cleanup*
*Completed: 2026-07-29*
