---
phase: 246-collection-controls-and-search
plan: 04
subsystem: ui
tags: [phoenix-liveview, responsive-tables, browser-evidence, filters, search]
requires:
  - phase: 246-01
    provides: invoice filter controls and applied-constraint behavior
  - phase: 246-02
    provides: collection filters and canonical status behavior
  - phase: 246-03
    provides: global billing search and mounted search-state fixtures
provides:
  - shared DataTable identity cells, card layout without repeated default identity, and grouped empty state
  - readable identity ordering for invoice, customer, subscription, and promotion-code tables
  - mounted responsive evidence for table states with source and served-asset digests
affects: [phase-247, admin-tables, admin-empty-states, phase-246-verification]
actuals:
  tokens: 80176
  tasks: 3
  commits: 16
plan_head_before: 89b15848dbf1047b2956ab4710a3840d8da6c675
plan_head_after: 95f0340a944f13a95541cccc33c60a060f634bea
tech-stack:
  added: []
  patterns: [shared identity-cell slots, responsive card title deduplication, revision-bound browser evidence]
key-files:
  created:
    - examples/accrue_host/e2e/phase246-table-reading.spec.js
    - .planning/phases/246-collection-controls-and-search/captures/phase246-table-reading/manifest.json
    - .planning/phases/246-collection-controls-and-search/deferred-items.md
  modified:
    - accrue_admin/lib/accrue_admin/components/data_table.ex
    - accrue_admin/lib/accrue_admin/components/empty_state.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/live/invoices_live.ex
    - accrue_admin/lib/accrue_admin/live/customers_live.ex
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
    - examples/accrue_host/lib/accrue_host_web/live/phase246_states_live.ex
key-decisions:
  - "Use one shared identity cell with separate primary and exact-copy secondary lines, retaining the existing InlineId copy action."
  - "When a card heading defaults to the first table column, omit that column from card details; preserve explicitly configured card fields and titles."
  - "Keep Phase 247 status, fee, and time semantics unchanged; the other five DataTable consumers retain their distinct payment, coupon, Connect, audit, and webhook facts."
patterns-established:
  - "Table identity: primary name or code, then separately labeled exact identifier and copy action."
  - "Default responsive cards do not repeat their heading as the first body field."
requirements-completed: [TABLE-01, FILTER-01, SEARCH-01]
coverage:
  - id: D1
    description: Shared identity and empty-state presentation retains exact identifiers and distinct absence/read-failure meaning.
    requirement: TABLE-01
    verification:
      - kind: unit
        ref: accrue_admin/test/accrue_admin/components/data_table_test.exs and accrue_admin/test/accrue_admin/components/empty_state_test.exs
        status: pass
      - kind: unit
        ref: accrue_admin/test/accrue_admin/live/invoices_live_test.exs, customers_live_test.exs, subscriptions_live_test.exs, promotion_codes_live_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Filter and search surfaces have observable coverage across their 24 applicable UI state rows.
    requirement: FILTER-01
    verification:
      - kind: automated_ui
        ref: examples/accrue_host/e2e/phase246-invoice-filters.spec.js and phase246-collection-filters.spec.js (Plans 01-02)
        status: pass
      - kind: automated_ui
        ref: examples/accrue_host/e2e/phase246-global-search.spec.js (Plan 03)
        status: pass
      - kind: automated_ui
        ref: examples/accrue_host/e2e/phase246-table-reading.spec.js (Plan 04)
        status: pass
    human_judgment: false
  - id: D3
    description: Mounted table states bind reviewed wide/narrow light/dark screenshots to the captured source and served CSS/JS.
    requirement: TABLE-01
    verification:
      - kind: e2e
        ref: examples/accrue_host/e2e/phase246-table-reading.spec.js @phase246-heldout and captures/phase246-table-reading/manifest.json
        status: pass
    human_judgment: true
    rationale: Wrapping, visual hierarchy, and responsive card duplication require inspection of the rendered images in addition to DOM and geometry assertions; all four final captures were reviewed.
metrics:
  duration: 56min
  completed: 2026-10-11
status: complete
---

# Phase 246 Plan 04: Shared Table Reading Summary

**Shared billing tables now separate names from exact copyable IDs, preserve state order on narrow cards, and group empty-state guidance.**

## Performance

- **Duration:** 56 minutes
- **Started:** 2026-10-11T18:14:05Z (first task RED commit)
- **Completed:** 2026-10-11T19:09:51Z
- **Tasks:** 3
- **Files modified:** 23, including four screenshots

## Accomplishments

- Added shared primary/secondary identity lines and bounded long-text wrapping. Invoices, customers, subscriptions, and promotion codes retain their existing exact copy actions while presenting state and other relevant facts in the plan-defined reading order.
- Grouped the shared empty-state title, explanation, and recovery action. First-run absence, filtered zero, unavailable reads, and partial reads remain distinct.
- Corrected the responsive card renderer so a default first-column heading is not repeated in the card body. Mounted assertions now wait for the actual state, row count, visible long identity, and copy control.
- Captured and reviewed desktop (1280×900) and narrow (320×820) light/dark states. Each manifest entry binds the source revision, served assets, and named PNG digest.

## Task Commits

The plan ledger measures 16 commits from `89b15848dbf1047b2956ab4710a3840d8da6c675` through `95f0340a944f13a95541cccc33c60a060f634bea`.

| Work | Commits |
| --- | --- |
| Task 1 RED/GREEN | `cef8290f` test grouped empty content; `5e05c0b2` shared identity and empty grouping |
| Task 2 RED/GREEN | `a44004df` separated invoice identity assertions; `ec8a0d13` representative table identity order |
| Task 3 and mounted refinements | `93226fdd` mounted geometry assertions; `1fef6257` heldout table states; `1735286d` visible desktop/card identity checks; `2f2ca283` deterministic long fixture initialization; `7a3995a2` initialize fixture after component mount; `45ab133a` exact capture source revision; `cbd198e2` duplicate-card RED assertion; `39759079` shared duplicate-card fix; `0080fd02` ordinary preview native-form login and connection check; `e200f3fc` remove stale warning-producing helpers |
| Detector and evidence | `ffb7f872` record deferred unrelated detector findings; `95f0340a` reviewed responsive screenshots and digest manifest |

## Verification

- `mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/empty_state_test.exs --warnings-as-errors` — 32 tests, 0 failures after the final shared-card fix.
- Four owner LiveView suites — 49 tests, 0 failures.
- Full `mix test --warnings-as-errors` in `accrue_admin` — 712 tests, 0 failures. The first full run exposed two unused test helpers; removing them produced this clean rerun.
- `mix accrue_admin.assets.build` passed using a temporary npm cache because the default cache was not writable. The served CSS and JS matched the repository assets in browser checks.
- Ordinary Fake-host journey — 1 passed. The guarded seed wrapper reported the protected Phase 243 snapshot unchanged; read-only checks found zero Phase 191 customer/subscription/invoice stress rows, six showcase invoices, and one operator account.
- Heldout browser lane — 1 passed. It asserts table loading, unavailable and partial-read states, retained content, zero/one/many actual rows, long exact ID copy, desktop/card identity uniqueness, and no horizontal overflow at 320px.
- `git diff --check` passed. The modified-file stub scan found only intentional filter input placeholders and empty hidden input values; no TODO/FIXME or unwired UI stubs were introduced.

## E1/E2/E3 UI-State Coverage

All 24 applicable rows from the plan are mapped below; no row is deferred.

| Surface | State | Evidence |
| --- | --- | --- |
| E1 filters | empty | Invoice/collection mounted filter specs and Plan 04 empty-state assertions |
| E1 filters | loading | Shared mounted collection loading assertion |
| E1 filters | error | Shared mounted unavailable-read assertion |
| E1 filters | populated | Invoice and collection filter specs assert controls, count, URL, and rows agree |
| E1 filters | partial | Plan 04 retained-row partial-read assertion |
| E1 filters | overflow | 320px geometry assertion and wrapping CSS |
| E1 filters | zero/one/many | Mounted zero, one, and three-row fixtures plus source-backed count assertions |
| E1 filters | long text | Wide and 320px heldout Unicode/text layout backstop |
| E2 search | empty | Plan 03 mounted no-match search assertion |
| E2 search | loading | Plan 03 pending spinner and live-status assertions |
| E2 search | error | Plan 03 failed-group retry assertion |
| E2 search | populated | Plan 03 grouped results and mounted responsive checks |
| E2 search | partial | Plan 03 successful groups remain through another group's failure |
| E2 search | overflow | Plan 03 320px dialog/footer geometry assertion |
| E2 search | zero/one/many | Plan 03 empty, single, and multiple result selection checks |
| E2 search | long text | Plan 03 wide/narrow heldout query and result-name checks |
| E3 tables | empty | Shared grouped first-run/filtered-zero state assertions |
| E3 tables | loading | `Table loading` shows skeleton without record rows |
| E3 tables | error | `Table initial-error` shows unavailable state |
| E3 tables | populated | Owner LiveView assertions and mounted identity/state row checks |
| E3 tables | partial | `Table partial-error` retains a real visible row |
| E3 tables | overflow | Wide/narrow geometry assertions, including 320px no-overflow check |
| E3 tables | zero/one/many | Fixture transitions assert 0, 1, and 3 actual table rows |
| E3 tables | long text | Four final viewport/theme captures assert Unicode name, unbroken ID, exact copy, and one card identity |

The five non-target DataTable consumers were inspected. The shared identity/card behavior applies automatically; page-level identity changes were not applicable to `charges_live.ex` (payment/customer, amount, fees, and billing signals), `connect_accounts_live.ex` (owner and connection readiness/override), `coupons_live.ex` (coupon discount, validity, redeem-by and redemptions), `events_live.ex` (event/actor/source/time), or `webhooks_live.ex` (webhook type/status/endpoint/received time). These pages do not share the four target record-identity semantics, and no separate CSS repair was needed.

## Capture Evidence

Manifest: [`manifest.json`](./captures/phase246-table-reading/manifest.json). Its `source_sha` is `ffb7f872d5a06de0ab96fcf7de917e7442ac5bd4`, the committed source revision captured before the evidence-only commit. Served CSS SHA-256 is `a615ce356fc9e52e0042aa579c601d5c4759c0e487fb998cd1b7b296e9172b48`; served JS SHA-256 is `7607c7103b0fa7103f806d1ff2b8b121376f31cc163bbfe3dcc1509c07fda053`.

| PNG | Viewport/theme | SHA-256 |
| --- | --- | --- |
| `heldout-wide-light.png` | 1280×900 light | `8282200e3ced9f00b8fca7aede2b304336e639f295dc23383027726c6e579ef1` |
| `heldout-wide-dark.png` | 1280×900 dark | `6c0b78ea6ce9a19a9ec5714253cee8ef30a9d7e43ff5d18e2a2dcb4722b7d3b8` |
| `heldout-320-light.png` | 320×820 light | `8e83f3206d06073b500e46c915f12acc324d0e625f60df7488cb6fbc842150d4` |
| `heldout-320-dark.png` | 320×820 dark | `8b59e90b3ddb3e9ba51f47b408f5cc065548962714cbe237742bd4bd3951b731` |

The rendered review found one concrete defect: the default card heading repeated the full identity in its first body field. A committed RED assertion reproduced two identity cells; the shared card renderer now omits that default first column, and the final 320px captures show the identity once. Phase 245 captures were left untouched.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made the long-text fixture deterministic after the LiveComponent mount**
- **Found during:** Task 3 browser verification
- **Issue:** Initial fixture assigns could race the table component's first query and leave the requested long state unrendered.
- **Fix:** Apply the fixture transition after component mount and wait for the rendered state, exact ID, copy control, and row counts before geometry checks.
- **Files modified:** `examples/accrue_host/lib/accrue_host_web/live/phase246_states_live.ex`, `examples/accrue_host/e2e/phase246-table-reading.spec.js`
- **Verification:** Heldout browser test passes and final evidence captures the long state.
- **Committed in:** `2f2ca283`, `7a3995a2`, `1fef6257`.

**2. [Rule 1 - Bug] Removed duplicate default card identity**
- **Found during:** Task 3 rendered review
- **Issue:** The card heading and first body field displayed the same primary identity and exact ID.
- **Fix:** Omit the first table column from default card fields only when the card title also defaults to that first column; preserve explicit card configuration.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/data_table.ex`, `examples/accrue_host/e2e/phase246-table-reading.spec.js`
- **Verification:** RED asserted 2 card identity cells; final heldout test asserts 1 and passes.
- **Committed in:** `cbd198e2` (RED), `39759079` (GREEN).

**3. [Rule 1 - Test fixture] Aligned ordinary login and connection checks with the existing host UI**
- **Found during:** Task 3 ordinary browser verification
- **Issue:** The preview presents a native form POST login flow, not visible email/password inputs; the generic connected selector also matched a hidden status node.
- **Fix:** Use the documented CSRF-protected native form POST with the local operator credential held only in a temporary environment variable, then target the visible Admin shell's connection state.
- **Files modified:** `examples/accrue_host/e2e/phase246-table-reading.spec.js`
- **Verification:** Ordinary browser journey passes against the guarded Fake host.
- **Committed in:** `0080fd02`.

**4. [Rule 1 - Test warning] Removed stale assertion helpers**
- **Found during:** Full suite verification
- **Issue:** Two test helpers became unused after identity assertion updates, causing the warnings-as-errors run to fail after executing all tests.
- **Fix:** Remove the obsolete helpers.
- **Files modified:** `accrue_admin/test/accrue_admin/live/customers_live_test.exs`, `accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs`
- **Verification:** Full suite passes with warnings as errors: 712 tests, 0 failures.
- **Committed in:** `e200f3fc`.

### Deferred Existing Findings

The single final Impeccable detector pass reported three unrelated side-border patterns and the existing Geist/Geist Mono choices. Their declarations are outside this plan's diff and are recorded in [`deferred-items.md`](./deferred-items.md) for a separate design review.

**Total deviations:** 4 auto-fixed; five unrelated detector findings recorded for later review.

## Issues Encountered

- Port 4101 was occupied by an unrelated existing process; the isolated heldout server ran on port 4102 after confirming it was free. No unknown process was terminated.
- The default npm cache was not writable; the asset build passed with a temporary cache under `/tmp`.
- The full-suite first pass exposed test warnings despite 0 assertion failures; the final warnings-as-errors rerun passed cleanly.

## User Setup Required

None.

## Next Phase Readiness

Plan 246-04 is complete. The Phase 246 implementation, all 24 UI-state rows, ordinary and heldout browser journeys, and revision-bound table evidence are ready for the phase verifier. This summary does not mark Phase 246 itself complete. No Phase 247 semantics were added.

## Self-Check: PASSED

- Summary file exists and records the measured 16-commit plan range.
- All 16 task and evidence commits listed above are ancestors of the current HEAD.
- The manifest source revision and asset/PNG hashes were verified against the captured evidence.

---
*Phase: 246-collection-controls-and-search*
*Completed: 2026-10-11*

## Task Commits

Canonical reachable commit references for evaluation-scope bookkeeping (details above and identity-gap summary).

1. **Task 1: Phase 246 implementation or verification** - `cef8290f`
2. **Task 2: Phase 246 implementation or verification** - `5e05c0b2`
3. **Task 3: Phase 246 implementation or verification** - `a44004df`
4. **Task 4: Phase 246 implementation or verification** - `ec8a0d13`
5. **Task 5: Phase 246 implementation or verification** - `93226fdd`
6. **Task 6: Phase 246 implementation or verification** - `1fef6257`
7. **Task 7: Phase 246 implementation or verification** - `2f2ca283`
8. **Task 8: Phase 246 implementation or verification** - `7a3995a2`
9. **Task 9: Phase 246 implementation or verification** - `1735286d`
10. **Task 10: Phase 246 implementation or verification** - `45ab133a`
11. **Task 11: Phase 246 implementation or verification** - `cbd198e2`
12. **Task 12: Phase 246 implementation or verification** - `39759079`
13. **Task 13: Phase 246 implementation or verification** - `0080fd02`
14. **Task 14: Phase 246 implementation or verification** - `e200f3fc`
15. **Task 15: Phase 246 implementation or verification** - `ffb7f872`
16. **Task 16: Phase 246 implementation or verification** - `95f0340a`
17. **Task 17: Phase 246 implementation or verification** - `eb3c4944`
18. **Task 18: Phase 246 implementation or verification** - `d1840677`

19. **Task 19: Review seed boundary fix** - `9a508f53`
20. **Task 20: Review search validation fix** - `d1c467cd`
