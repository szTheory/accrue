---
phase: 211-grep-gated-css-retirement-cross-surface-cleanup
plan: 02
subsystem: ui
tags: [css, tailwind, dead-code, accrue_admin, dashboard, subscriptions, bundle]

# Dependency graph
requires:
  - phase: 211-01
    provides: "verify-css-census.mjs orphan guard (class-name liveness census)"
provides:
  - "app.css retired of all 92 REIGN-04-named dead .ax-* selectors plus 5 D-01 adjacent orphan rules"
  - "Rebuilt priv/static/accrue_admin.css bundle (157310 -> 128454 bytes) reflecting the retired source"
  - "16 PRESERVE classes (incl. ax-subscription-setup-gap landmine) verified intact and live"
affects: [211-03, 211-04, storybook-recompose, region-tags-fix]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Format-preserving CSS retirement: parse -> branch-level dead-class filter -> byte-identical round-trip for untouched rules"
    - "Rebuild committed Tailwind bundle only after the final CSS edit, commit source+bundle together (Phase 209/210 convention)"

key-files:
  created: []
  modified:
    - "accrue_admin/assets/css/app.css (8326 -> 6839 lines; 92 named + 5 adjacent selectors removed)"
    - "accrue_admin/priv/static/accrue_admin.css (rebuilt, shrunk ~28.9KB)"
    - "accrue_admin/priv/static/accrue_admin.js (rebuilt, byte-identical — no JS source changed)"

key-decisions:
  - "Deleted at branch level, never rule level, for every comma-grouped selector mixing dead + live branches (both :has() rules, the 19-branch focus-visible and 10-branch hover utility rules, and 3 status-badge tone rules) — live branches preserved verbatim"
  - "Folded the 5 D-01 adjacent orphan rules into this plan per the locked D-01 decision (nested .ax-home page-header/page-actions rules + .ax-dashboard-title-row)"
  - "Refreshed one stale Phase-210 doc comment that still named .ax-launcher* so the exact-token acceptance grep resolves to 0"

patterns-established:
  - "Pattern: :not() contents excluded from dead-class detection (a dead class inside :not() does not kill a live branch); :has() contents included (a dead class inside :has() does kill the branch)"

requirements-completed: [REIGN-04]

coverage:
  - id: D1
    description: "Zero references to any of the 92 REIGN-04-named DELETE classes + 5 D-01 adjacent selectors remain in app.css"
    requirement: REIGN-04
    verification:
      - kind: other
        ref: "exact-token ripgrep (?<![\\w-])TOKEN(?![\\w-]) over app.css for all 92 dead classes + D-01 selectors -> all 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "All 16 PRESERVE classes (incl. ax-subscription-setup-gap landmine) remain present and live; both .ax-shell-content:has() rules keep their detail-page + home branches"
    requirement: REIGN-04
    verification:
      - kind: other
        ref: "exact-token ripgrep for 16 PRESERVE classes -> all >=1; :has() rules retain 2 live branches"
        status: pass
    human_judgment: false
  - id: D3
    description: "Rebuilt accrue_admin.css bundle reflects the retired CSS; accrue_admin.js byte-identical; admin suite green"
    requirement: REIGN-04
    verification:
      - kind: unit
        ref: "cd accrue_admin && mix test -> 514 tests, 0 failures (matches Wave-1 baseline)"
        status: pass
      - kind: other
        ref: "mix accrue_admin.assets.build exit 0; accrue_admin.css 157310->128454 bytes; accrue_admin.js md5 e4db3e8e unchanged"
        status: pass
    human_judgment: false
  - id: D4
    description: "Rendered dashboard/subscriptions surfaces remain visually correct after CSS retirement"
    requirement: REIGN-04
    verification:
      - kind: automated_ui
        ref: "cd accrue_admin && npm run e2e:visual-regression -> toHaveScreenshot pixel-diff of dashboard + subscriptions (light+dark) vs committed Linux baselines under e2e/__screenshots__/visual-desktop/; 0 diffs. Blocking gate in accrue_admin_browser.yml browser-uat (quick-260729-rjo, PR #35)."
        status: pass
    human_judgment: false
    rationale: "Superseded by the deterministic Playwright toHaveScreenshot gate added in quick-260729-rjo: pixel-diff of dashboard + subscriptions in both themes against committed CI-minted baselines, wired blocking into browser-uat. No human PNG review required."

# Metrics
duration: 15min
completed: 2026-07-28
status: complete
---

# Phase 211 Plan 02: Grep-gated CSS retirement (deletion) Summary

**Retired all 92 REIGN-04-named dead `.ax-home*/.ax-launcher*/.ax-attention*/.ax-health-summary*/.ax-subscriptions-*/.ax-subscription-row-*` selectors plus 5 D-01 adjacent orphan rules from app.css, preserving 16 live classes and every live comma-branch, then rebuilt the committed accrue_admin.css bundle (157KB -> 128KB).**

## Performance

- **Duration:** 15 min
- **Started:** 2026-07-28T15:59:41Z
- **Completed:** 2026-07-28T16:15:04Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Deleted 92 zero-reference `.ax-*` selectors (44 Home/Launcher/Attention/HealthSummary in Task 1; 48 Subscriptions/SubscriptionRow in Task 2) plus the 5 D-01 adjacent orphan rules.
- Preserved all 16 PRESERVE classes verbatim, including the `ax-subscription-setup-gap` high-severity landmine (still rendered by `subscriptions_live.ex`).
- Branch-level surgery on all 9 mixed dead/live comma-groups: both `.ax-shell-content:has()` rules kept their `.ax-subscription-detail-page` + `.ax-home` branches; the global focus-visible/hover/status-badge utility rules kept every live branch.
- Rebuilt `priv/static/accrue_admin.css` (157310 → 128454 bytes); `accrue_admin.js` byte-identical (md5 `e4db3e8e…` unchanged — no JS source touched).
- Verified: exact-token grep (all 92 dead = 0, 16 PRESERVE ≥ 1), orphan guard (all 92 named classes gone from the orphan list), and `mix test` **514 tests, 0 failures** (matches the Wave-1 baseline).

## Task Commits

1. **Task 1: Delete Home/Launcher/Attention/HealthSummary dead families + 5 D-01 adjacent rules** — `5b4f4957` (refactor)
2. **Task 2: Delete Subscriptions/SubscriptionRow dead families + rebuild bundle** — `95069fb6` (refactor)

## Files Created/Modified
- `accrue_admin/assets/css/app.css` — 8326 → 6839 lines; 92 named + 5 adjacent selectors removed, 16 PRESERVE selectors + all live comma-branches intact.
- `accrue_admin/priv/static/accrue_admin.css` — rebuilt from the retired source (shrunk ~28.9KB).
- `accrue_admin/priv/static/accrue_admin.js` — rebuilt, byte-identical (no JS source change this phase).

## Decisions Made
- Executed the deletion with a deterministic, format-preserving CSS-retirement script (`/tmp/css-retire.mjs`, not committed) that removes dead comma-branches and whole dead rules while copying untouched rules byte-for-byte. Validated by a zero-diff round-trip of the pristine file with an empty dead-set before use, and by re-grepping every dead/preserve token after each pass. This produces the exact result the plan's manual grep+edit describes, with lower risk across the 92-selector / 9-comma-group surface.
- `:not()` contents are excluded from dead-class detection; `:has()` contents are included — the correct CSS-matching semantics (confirmed no dead class sits only inside a `:not()`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Refreshed a stale Phase-210 doc comment naming `.ax-launcher*`**
- **Found during:** Task 1 (Launcher family deletion)
- **Issue:** The `.ax-home-launcher-card` documentation comment still read "…does not touch any `.ax-launcher*` rule (Phase 211 retires those)". That literal `.ax-launcher*` token kept the exact-token acceptance grep for `ax-launcher` at count 1 (a comment mention), so the Task-1 acceptance criterion could not resolve to 0.
- **Fix:** Rewrote the comment to past tense ("The legacy bespoke launcher-tile rules were retired in Phase 211."), dropping the dangling `.ax-launcher*` token. `data-ax-launcher-primary` retained (does not match the exact-token pattern).
- **Files modified:** `accrue_admin/assets/css/app.css`
- **Verification:** `ax-launcher` exact-token grep = 0; comment now accurate post-retirement.
- **Committed in:** `5b4f4957` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking). **Impact on plan:** Necessary to clear the exact-token acceptance gate; the comment was made accurate, not merely silenced. No scope creep — no live rule touched.

## Issues Encountered
- **Parser edge case caught by the deferred bundle rebuild.** The first tooling pass mis-parsed the single `@supports (@starting-style {}) { … }` at-rule — CSS braces live *inside* the prelude parentheses — corrupting that block. This surfaced exactly as intended: `mix accrue_admin.assets.build` failed to parse, before anything shipped. Fixed the tooling to skip parenthesized groups when scanning for the block's opening brace, re-verified with a byte-identical pristine round-trip, then redid both passes cleanly (Task 1 commit amended, Task 2 redone). Final CSS parses in Tailwind with `@supports` intact and braces balanced (1020/1020). This is the reason the plan defers the rebuild to the end — it is the syntax gate.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Source CSS fully retired and the committed `accrue_admin.css`/`.js` bundle is fresh — ready for Plan 211-03 (storybook.css recomposition, which embeds this rebuilt `accrue_admin.css`) and Plan 211-04 (region-tags.js fix + full unit/e2e suite verification).
- REIGN-04 remains shared across sibling plans (211-01…211-04); it flips Complete only once the last declaring plan produces its SUMMARY (handled by the shared-ID gate).
- The orphan guard still reports 107 out-of-scope dead class-names (families outside REIGN-04's 8 named prefixes) — expected, advisory, and explicitly out of this phase's scope.

## Self-Check: PASSED
- Files exist: `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`, `211-02-SUMMARY.md` — all FOUND.
- Commits exist: `5b4f4957` (Task 1), `95069fb6` (Task 2) — both FOUND.
- Verifications: 92 dead tokens = 0; 16 PRESERVE ≥ 1; bundle rebuilt (js md5 unchanged); `mix test` 514/0.

---
*Phase: 211-grep-gated-css-retirement-cross-surface-cleanup*
*Completed: 2026-07-28*
