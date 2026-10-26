---
phase: 234-admin-customers-subscriptions
plan: "03"
subsystem: ui
tags: [phoenix-liveview, subscriptions, customer-detail, lifecycle, responsive-admin]
requires:
  - phase: 234-01
    provides: Scoped customer/subscription navigation and immutable pre-layout evidence.
  - phase: 234-02
    provides: Owner-scoped Admin activity/search foundations.
  - phase: 234-07
    provides: Record-aware ScopedPath returns preserving current owner scope.
provides:
  - Exact subscription lifecycle presentation independent of unavailable price/date observations.
  - Scoped customer and subscription evidence hierarchy with narrow-screen wrapping and controls.
  - Served post-layout screenshots and provenance manifest tied to the immutable pre-layout baseline.
affects: [234-04, 234-06, customer-detail, subscription-detail]
actuals:
  tokens: 74915
  tasks: 2
  commits: 3
  plan_head_before: d762c1041227ba464a0cebf2a5a91e3426abeb51
  plan_head_after: c977d815a2dc026878c4bdcc7158c94d552324cf
commits: 3
plan_head_before: d762c1041227ba464a0cebf2a5a91e3426abeb51
plan_head_after: c977d815a2dc026878c4bdcc7158c94d552324cf
tech-stack:
  added: []
  patterns:
    - Lifecycle display is sourced from core subscription predicates; ancillary schedule, collection, money, and dates remain separate observations.
    - Served UI evidence records source and asset hashes and links back to the immutable pre-layout manifest.
key-files:
  created:
    - examples/accrue_host/e2e/phase234-post-layout.spec.js
    - .planning/phases/234-admin-customers-subscriptions/captures/post-layout/manifest.json
    - .planning/phases/234-admin-customers-subscriptions/captures/post-layout/customer-detail.png
    - .planning/phases/234-admin-customers-subscriptions/captures/post-layout/subscription-detail.png
    - .planning/phases/234-admin-customers-subscriptions/captures/post-layout/subscription-drawer.png
  modified:
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/test/accrue_admin/live/customer_live_test.exs
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
key-decisions:
  - "Lifecycle remains exact when billing observations are missing; no synthetic zero, due-now date, mixed-currency aggregate, or unscoped webhook count is shown."
  - "Subscription navigation and display preserve the approved record-aware ScopedPath return behavior from Plan 234-07."
patterns-established:
  - "Represent current lifecycle, scheduled cancellation, collection pause, and historical evidence as distinct facts."
requirements-completed: [ADM-01, ADM-03]
coverage:
  - id: D1
    description: Subscription lifecycle, schedule, collection behavior, and unavailable billing observations render independently.
    requirement: ADM-01
    verification:
      - kind: integration
        ref: "cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Customer and subscription detail hierarchy remains readable at 320px and retains 44px primary controls.
    requirement: ADM-01
    verification:
      - kind: integration
        ref: "cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/subscription_live_test.exs"
        status: pass
      - kind: automated_ui
        ref: "examples/accrue_host/e2e/phase234-post-layout.spec.js (Playwright served-page capture and narrow-width assertions)"
        status: pass
    human_judgment: false
  - id: D3
    description: Customer/subscription links and detail context retain the authorized owner scope and validated return route.
    requirement: ADM-03
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs and test/accrue_admin/live/subscription_live_test.exs"
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-10-08
status: complete
---

# Phase 234 Plan 03: Admin Customers & Subscriptions Summary

**Customer and subscription details now keep exact lifecycle separate from billing observations, prioritize scoped evidence, and fit a 320px viewport.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-10-08T01:09:19Z
- **Completed:** 2026-10-08T01:24:14Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Kept exact lifecycle independent of missing price/date data; separated scheduled cancellation, collection pause, and historical evidence.
- Removed unsupported unscoped webhook counts and mixed-currency exposure aggregation; unavailable amount/date remain explicit.
- Reordered customer and subscription details, added narrow control targets and wrapping, and recorded served post-layout evidence against the immutable baseline.

## Task Commits

1. **Task 1: Separate exact lifecycle from missing observations** - `0d093a47` (feat)
2. **Task 2: Arrange readable customer and subscription evidence** - `6632dd2b` (feat)
3. **Task 2 verification fix: Constrain narrow customer details** - `c977d815` (fix)

## Files Created/Modified

- Customer, subscription detail/list LiveViews and their mounted tests - lifecycle facts, scoped evidence, and hierarchy.
- `accrue_admin/assets/css/app.css` and generated `accrue_admin/priv/static/accrue_admin.css` - wrapping and responsive controls.
- `examples/accrue_host/e2e/phase234-post-layout.spec.js` and post-layout captures - served evidence, provenance, and narrow-width checks.

## Decisions Made

- Retain known lifecycle when ancillary billing data is unavailable; never imply zero price, due-now timing, or cross-currency totals.
- Preserve Plan 234-07's approved record-aware `ScopedPath` return behavior in the overlapping subscription LiveView.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Constrained customer detail rows at narrow widths**
- **Found during:** Task 2 browser verification.
- **Issue:** A detail list row widened the document to 325px at a 320px viewport.
- **Fix:** Constrained page-local detail/list children and enabled wrapping; added a 320px browser assertion.
- **Files modified:** `accrue_admin/assets/css/app.css`, `examples/accrue_host/e2e/phase234-post-layout.spec.js`.
- **Verification:** Post-layout Playwright capture passed; document width was 320px.
- **Committed in:** `c977d815`.

### Process Deviation

Both plan tasks were marked `tdd="true"`, but the configured workflow reported `tdd_mode: false`; tests were added after implementation and there was no RED commit. This is recorded in `.planning/WINDOWS.md` as open deviation id 16.

**Total deviations:** 1 auto-fixed code issue and 1 process deviation.
**Impact on plan:** Required responsive behavior is now verified; no task scope was omitted.

## Issues Encountered

- The initial 320px browser run exposed a customer detail width overflow; the page-local fix resolved it. The existing topbar's negative-positioned search control does not increase document scroll width.
- Chromium required execution outside the sandbox for the local Playwright capture. Asset build succeeded with the temporary npm cache workaround.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Customer and subscription lifecycle/evidence presentation is ready for the remaining Phase 234 work. The immutable pre-layout capture is preserved, and post-layout served screenshots are linked by manifest hashes.

---
*Phase: 234-admin-customers-subscriptions*
*Completed: 2026-10-08*

## Self-Check: PASSED

- Summary and all three post-layout capture artifacts exist.
- Task commits `0d093a47`, `6632dd2b`, and `c977d815` are ancestors of HEAD.
- Measured task-commit count is 3 from `d762c1041227ba464a0cebf2a5a91e3426abeb51` through `c977d815a2dc026878c4bdcc7158c94d552324cf`.
