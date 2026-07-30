---
phase: 211-grep-gated-css-retirement-cross-surface-cleanup
verified: 2026-07-29T23:58:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification — written retroactively to close a milestone-audit gap (phase shipped without a VERIFICATION.md)."
---

# Phase 211: Grep-gated CSS Retirement & Cross-Surface Cleanup — Verification Report

**Phase Goal:** With both target templates (Home + Subscriptions) reigned, retire the now-dead bespoke `.ax-*` rule sets from `accrue_admin/assets/css/app.css`, rebuild and commit the served bundle, and clean up secondary surfaces that still reference the retired vocabulary — grep-gated throughout so the out-of-scope subscription detail page keeps its shared classes.
**Verified:** 2026-07-29T23:58:00Z
**Status:** passed
**Re-verification:** No — initial verification (retroactive gap-closure during v1.57 milestone audit)

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria for REIGN-04)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Grep census confirms zero remaining references to each deleted class; the 8 bespoke families (~325 rules / 92 named classes + 5 D-01 adjacent) removed from `app.css` | ✓ VERIFIED | Exact-token `rg (?<![\w-])TOKEN(?![\w-])` over `app.css`: all 17 sampled deleted classes across every family (`ax-home-*`, `ax-launcher*`, `ax-attention*`, `ax-health-summary*`, `ax-subscriptions-*`, `ax-subscription-row-*`, `ax-dashboard-title-row`) = **0**. `app.css` 8326→6839 lines. Census guard `--self-test` passes all 6 fixtures (incl. both exact-token boundary landmines). Full census: no target-family orphan present. |
| 2 | Detail-page-shared classes preserved (`.ax-inline-worklist`, `.ax-inline-worklist-copy`, `.ax-audit-summary-row`, + `subscription_live.ex` classes); detail page renders unbroken | ✓ VERIFIED | In `app.css`: `ax-inline-worklist`=3, `ax-inline-worklist-copy`=6, `ax-audit-summary-row`=5, `ax-subscription-setup-gap`=4 (landmine intact). Diff since 412ada26 shows **none** of `subscription_live.ex`'s referenced classes were removed. Detail-page render covered by the automated Playwright `toHaveScreenshot` pixel-diff gate (blocking in `browser-uat`, PR #35) + original human PNG approval (211-04 Task 3). |
| 3 | Committed `priv/static/accrue_admin.css` rebuilt via `mix accrue_admin.assets.build` and committed in same change; guard confirms clean retirement | ✓ VERIFIED | `accrue_admin.css` = 128454 bytes (matches claim; was 157310). Retired classes = 0 in bundle; PRESERVE classes present in bundle (`ax-inline-worklist`=4, `ax-audit-summary-row`=5, `ax-subscription-setup-gap`=4). `accrue_admin.js` byte-identical (no JS source touched). All artifacts committed (clean `git status`). Guard (`verify-css-census.mjs`) exists + wired via `css:census` npm scripts. |
| 4 | Component kitchen + `storybook.css` no longer render retired vocabulary; phase200 storybook specs green; parked `region-tags.js` `.ax-attention-rail` fixed to live selector | ✓ VERIFIED | `component_kitchen_live.ex`: all 8 sampled retired classes = 0. `storybook.css`: retired remnants (`ax-home-search`/`ax-launcher`/`ax-attention-pill`/`ax-subscriptions-page`) = 0; D-17 shim marker present exactly once. `region-tags.js` attention-rail = `"[data-ax-zone='attention-rail']"`; `TODO: confirm selector` count = 9 (was 10); self-test exit 0. Storybook unit tests (coverage/asset/theme) pass within the 514/0 suite. |
| 5 | Full `mix test` + admin e2e green across phase boundary; diff touches no `accrue/lib` and adds no nav room | ✓ VERIFIED | **Live re-run:** `cd accrue_admin && mix test` → **514 tests, 0 failures** (exactly matches Plan 01 baseline). `git diff 412ada26..HEAD -- accrue/lib` = empty; `router.ex` + `nav.ex` = empty. E2E covered by automated visual-regression gate (blocking, `browser-uat`) + UAT (`npm run e2e` → 200 passed / 40 skipped / 0 failed, cited per instruction not to run the browser suite). |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue_admin/assets/css/app.css` | 97 target selectors removed; 16 PRESERVE intact | ✓ VERIFIED | 8326→6839 lines; deleted=0, PRESERVE≥1 (exact-token) |
| `accrue_admin/priv/static/accrue_admin.css` | rebuilt, shrunk, committed | ✓ VERIFIED | 128454 bytes; retired=0, PRESERVE present; committed |
| `accrue_admin/priv/static/storybook.css` | recomposed, no remnants | ✓ VERIFIED | remnants=0; D-17 marker×1; committed |
| `accrue_admin/e2e/verify-css-census.mjs` | dependency-free guard + self-test | ✓ VERIFIED | self-test 6/6 pass; npm scripts wired; committed |
| `accrue_admin/e2e/ratchet/region-tags.js` | attention-rail → live selector | ✓ VERIFIED | `[data-ax-zone='attention-rail']`; self-test exit 0 |
| `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` | no retired vocab | ✓ VERIFIED | all sampled retired classes = 0 |

### Key Link Verification

| From | To | Via | Status |
|------|----|----|--------|
| `app.css` (retired source) | `priv/static/accrue_admin.css` | `mix accrue_admin.assets.build` | ✓ WIRED — bundle contains 0 retired, PRESERVE present, 128454 bytes |
| `accrue_admin.css` | `storybook.css` embed | D-04 recompose recipe | ✓ WIRED — remnants=0, D-17 tail preserved (SHA256-verified per 211-03) |
| `dashboard_live.ex` attention rail | `region-tags.js` | `[data-ax-zone='attention-rail']` data attribute | ✓ WIRED — selector now matches live markup |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| REIGN-04 | 211-01..04 | Grep-gated bespoke `.ax-*` retirement, bundle rebuild, cross-surface cleanup, detail-shared classes preserved | ✓ SATISFIED | All 5 SCs verified above; sole requirement mapped to Phase 211 |

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `app.css` | 107 orphan `ax-*` selectors reported by full census | ℹ️ Info | **Pre-existing, out-of-scope dead CSS** (`ax-detail-*`, `ax-tab-*`, `ax-json-*`, `ax-timeline-*`, `ax-health-metric*`, etc.) — none belong to REIGN-04's 8 named families; documented in 211-03-SUMMARY; not introduced by this phase; explicitly deferred to a future dead-CSS sweep. Not a Phase 211 defect. |
| `region-tags.js` | 9 `// TODO: confirm selector` markers | ⚠️ Warning | Pre-existing (count reduced 10→9 by this phase); explicitly out of scope per the ROADMAP-locked D-03 decision (REIGN-04 names only the `ax-attention*` family). `REGION_SELECTORS` is documented non-identity metadata. Deferred by design. |

### Human Verification Required

None. The one former human checkpoint (subscription-detail visual parity, 211-04 Task 3) was converted to a deterministic, permanent automated blocking gate (Playwright `toHaveScreenshot` pixel-diff over 4 surfaces × light/dark, PR #35) and the unit suite was live re-confirmed (514/0). No behavior-dependent invariant remains unexercised.

### Gaps Summary

No gaps. All five ROADMAP success criteria for REIGN-04 are independently verified against the codebase:
- Retirement is complete and exact-token clean (0 references to any deleted class; census self-test green).
- Correctly scoped — no over-deletion: every PRESERVE class and detail-page-shared class survives; the `ax-subscription-setup-gap` landmine is intact; no `subscription_live.ex` class was removed.
- Served bundle rebuilt to 128454 bytes and committed alongside source; JS byte-identical.
- Secondary surfaces (component kitchen, storybook.css, region-tags.js) carry no retired vocabulary; the dangling ratchet selector is fixed to the live `[data-ax-zone='attention-rail']`.
- Scope fence honored — zero `accrue/lib` change, no nav room added; full unit suite green (514/0, live-verified).

The 107 out-of-scope orphan selectors and the 9 remaining `region-tags.js` TODO markers are pre-existing conditions explicitly excluded from REIGN-04's scope and documented in the plan artifacts — advisory only, not gaps.

---

_Verified: 2026-07-29T23:58:00Z_
_Verifier: Claude (gsd-verifier)_
