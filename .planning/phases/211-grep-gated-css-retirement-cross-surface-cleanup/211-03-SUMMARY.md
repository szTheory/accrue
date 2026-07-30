---
phase: 211-grep-gated-css-retirement-cross-surface-cleanup
plan: 03
subsystem: ui
tags: [css, storybook, phoenix_storybook, admin-ui, bundle, dead-code, ax-css]

# Dependency graph
requires:
  - phase: 211-02
    provides: "Fully-retired app.css (97 dead selectors deleted) + freshly rebuilt priv/static/accrue_admin.css bundle"
  - phase: 211-01
    provides: "verify-css-census.mjs orphan-guard script + npm run css:census alias"
provides:
  - "Recomposed priv/static/storybook.css embedding the post-retirement accrue_admin.css (no dead-class remnants)"
  - "Independent orphan-guard proof that all 97 REIGN-04 target selectors are retired from app.css and correctly scoped"
  - "Early smoke gate green (mix compile + 3 phase200 storybook unit tests) before Wave 4 full verification"
affects: [211-04, wave-4-verification, storybook-a11y]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "storybook.css is hand-recomposed via the D-04 shell recipe (awk-extract D-17 shim tail -> PSB CSS + fresh accrue_admin.css + shim tail), never hand-edited — no mix rebuild task exists for it"

key-files:
  created: []
  modified:
    - "accrue_admin/priv/static/storybook.css - recomposed from PSB CSS + fresh accrue_admin.css + byte-preserved D-17 dark-mode shim tail"

key-decisions:
  - "Skipped the recipe's leading `mix accrue_admin.assets.build` step: Plan 02 already rebuilt/committed accrue_admin.css, and this plan scopes Task 1 to storybook.css only (files_modified). Used the on-disk fresh bundle verbatim — SHA256-verified identical to the embedded section."
  - "Task 1 AC canary `ax-attention` legitimately remains at exactly 1 occurrence: `.ax-attention` is a LIVE class (referenced in dashboard_live.ex:149), correctly preserved by Plan 02. The two dead canaries (ax-home-search, ax-launcher exact-token) both drop to 0 as expected."

patterns-established:
  - "Verify bundle-embed freshness by SHA256-comparing the embedded section against the source bundle, not by canary tokens alone"

requirements-completed: [REIGN-04]

coverage:
  - id: D1
    description: "priv/static/storybook.css recomposed: PSB CSS + fresh (post-retirement) accrue_admin.css + byte-preserved D-17 dark-mode shim tail; no retired-class remnants"
    requirement: "REIGN-04"
    verification:
      - kind: other
        ref: "grep -c 'D-17 Spike B' storybook.css == 1; exact-token ax-home-search==0, ax-launcher==0; embedded accrue_admin.css section SHA256-identical to priv/static/accrue_admin.css"
        status: pass
      - kind: unit
        ref: "test/accrue_admin/dev/storybook_asset_test.exs (byte-equality of served storybook.css vs committed file)"
        status: pass
      - kind: unit
        ref: "test/accrue_admin/theme_test.exs (dark-mode shim mirrors theme.css --ax-* tokens)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Orphan guard independently confirms all 97 REIGN-04 target selectors are retired from app.css and correctly scoped (no live class over-deleted)"
    requirement: "REIGN-04"
    verification:
      - kind: other
        ref: "npm run css:census — zero target-family (home/launcher/attention/subscriptions/subscription-row/inline-worklist/health-summary) orphans"
        status: pass
    human_judgment: false
  - id: D3
    description: "Early smoke gate: mix compile picks up new bundle bytes and the three phase200 storybook unit tests pass"
    requirement: "REIGN-04"
    verification:
      - kind: unit
        ref: "mix compile (exit 0) + mix test storybook_coverage_test.exs storybook_asset_test.exs theme_test.exs — 17 tests, 0 failures"
        status: pass
    human_judgment: false

# Metrics
duration: 6 min
completed: 2026-07-28
status: complete
---

# Phase 211 Plan 03: Recompose storybook.css & orphan-guard the retired app.css Summary

**Hand-recomposed `storybook.css` off the post-retirement `accrue_admin.css` bundle (SHA256-verified embed), then proved via the orphan guard that all 97 REIGN-04 target selectors are cleanly retired from `app.css` with zero live-class over-deletion — early smoke gate green (mix compile + 17 storybook unit tests, 0 failures).**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-28T16:18:28Z
- **Completed:** 2026-07-28T16:23:40Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Recomposed `priv/static/storybook.css` (275KB stale → 190KB) via the D-04 shell recipe: awk-extracted the D-17 dark-mode shim tail byte-for-byte, then concatenated the verbatim header, PhoenixStorybook sandbox CSS, the fresh post-retirement `accrue_admin.css`, and the preserved shim tail. Embedded `accrue_admin.css` section is SHA256-identical to `priv/static/accrue_admin.css`.
- Ran the Plan 01 orphan guard (`npm run css:census`): **zero** of the 97 REIGN-04 target selectors appear as orphans in `app.css` — Plan 02's deletion is complete and correctly scoped (no live class over-deleted; all still-referenced home/launcher/attention classes correctly survive).
- Early smoke gate green: `mix compile` (exit 0, picks up new bundle bytes) + the three phase200 storybook unit tests (`storybook_coverage_test`, `storybook_asset_test`, `theme_test`) = **17 tests, 0 failures**. The asset test's byte-equality check confirms the served bundle matches the committed recomposed file; the theme test confirms the dark-mode shim tail survived intact.

## Task Commits

1. **Task 1: Recompose priv/static/storybook.css per the D-04 shell recipe** — `117852cd` (chore)
2. **Task 2: Run the orphan-guard against the retired app.css and an early smoke test** — verification-only, no files modified (no commit)

**Plan metadata:** (docs: complete plan — this commit)

## Files Created/Modified
- `accrue_admin/priv/static/storybook.css` — recomposed from PSB CSS + fresh accrue_admin.css + byte-preserved D-17 dark-mode shim tail; dead `ax-home-search`/`ax-launcher`/`ax-attention-{action,dot,pill}` remnants dropped

## Decisions Made
- **Skipped the recipe's leading `mix accrue_admin.assets.build`:** Plan 02 already rebuilt and committed `accrue_admin.css`, and this plan's `files_modified` scopes Task 1 to `storybook.css` only. Used the on-disk fresh bundle verbatim and SHA256-verified the embedded section matches it — a stronger proof than rebuilding.
- **Verification via SHA256 embed-identity, not canary tokens alone:** the plan's `ax-attention` canary is imperfect (see deviation below), so the load-bearing proof of "stale embed replaced" is that the embedded `accrue_admin.css` section hashes identically to `priv/static/accrue_admin.css`.

## Deviations from Plan

### Documented AC clarification (no code change)

**1. [Rule 1 - Plan expectation correction] Task 1 AC canary `ax-attention` is a live class, not fully retired**
- **Found during:** Task 1 (Recompose storybook.css)
- **Issue:** Task 1's acceptance criterion expects "zero exact-token matches for ax-attention, ax-home-search, and ax-launcher" in the recomposed `storybook.css`. But `.ax-attention` (base class) is genuinely **live** — referenced in `lib/accrue_admin/live/dashboard_live.ex:149` — and was correctly preserved by Plan 02 (the orphan guard does not flag it). It therefore legitimately appears exactly once in the fresh `accrue_admin.css` and hence in the recomposed `storybook.css`.
- **Fix:** No code change — the correct behavior is to preserve the live class. The AC's canary choice was based on the assumption that the entire `ax-attention*` family would be deleted; in fact only the dead variants (`ax-attention-action`, `ax-attention-dot`, `ax-attention-pill`, etc.) were retired, which are confirmed gone. The two dead canaries `ax-home-search` (1→0) and `ax-launcher` (5→0, exact-token) both drop to 0 as the AC intends. The AC's underlying intent — "prove the stale pre-retirement embed was replaced" — is proven directly by the embedded-section SHA256 identity check.
- **Files modified:** none (verification interpretation only)
- **Verification:** `ax-home-search`=0, `ax-launcher`=0; `ax-attention`=1 (== fresh accrue_admin.css); embedded section SHA256 == source bundle; 17 storybook tests pass.
- **Committed in:** n/a (no code change)

---

**Total deviations:** 1 documented AC clarification (no code change)
**Impact on plan:** None — retirement is complete and correctly scoped. The AC's `ax-attention` canary was an imperfect proxy; the stronger SHA256 embed-identity check plus the guard's zero-target-orphan result fully satisfy the plan's intent.

## Issues Encountered
None — planned work executed cleanly.

## Known Stubs
None.

## Informational — Out-of-scope orphans (NOT deleted this phase)
The orphan guard reports **107** orphan `ax-*` selectors in `app.css`, but **none** belong to the 97 REIGN-04 target families. All 107 are pre-existing dead CSS in out-of-scope families — the largest groups: `ax-detail-*` (19), `ax-tab-*` (9), `ax-dev-*` (9), `ax-type-*` (7), `ax-summary-*` (7), `ax-input-*` (6), `ax-health-*` (6, distinct from the retired `ax-home-health-*` HealthSummary bar), `ax-drawer-*` (6), `ax-timeline-*` (4). These are outside REIGN-04's scope and were intentionally left untouched. Recorded here for a future dead-CSS sweep; they are not a Phase 211 defect.

## Next Phase Readiness
- `storybook.css` is fresh and clean; the orphan guard independently certifies the CSS retirement is complete and correctly scoped; the earliest smoke tests are green.
- Ready for **211-04** (Wave 4): fix the dangling `region-tags.js` ratchet selector (D-03) and run the full unit + e2e verification sweep plus the human-verify subscription-detail visual check.

---
*Phase: 211-grep-gated-css-retirement-cross-surface-cleanup*
*Completed: 2026-07-28*
