---
phase: 238-admin-events-webhooks-remaining-billing-surfaces
plan: "05"
subsystem: testing
tags: [playwright, exunit, phoenix-liveview, axe, webhooks, admin]
requires:
  - phase: 238-01
    provides: scoped replay eligibility and deterministic result seams
  - phase: 238-02
    provides: Admin events and webhook evidence routes
  - phase: 238-03
    provides: coupon and promotion-code inspection routes
  - phase: 238-04
    provides: Connect observation and local override surfaces
provides:
  - deterministic mounted-browser evidence for the remaining Phase 238 Admin journeys
  - required Playwright shard discovery and accessibility/responsive browser assertions
  - current bulk replay confirmation-copy contract
affects: [admin-events, admin-webhooks, coupons, promotion-codes, connect, host-integration]
actuals:
  tokens: 5436
  tasks: 3
  commits: 4
tech-stack:
  added: []
  patterns:
    - Repeatable browser fixtures use fixed processor identifiers and remove dependent rows/jobs during reseed.
    - Local seeded provider observations are asserted as local evidence, not live-provider proof.
key-files:
  created:
    - examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js
  modified:
    - scripts/ci/accrue_host_seed_e2e.exs
    - accrue_admin/test/accrue_admin/copy_test.exs
    - accrue_admin/lib/accrue_admin/components/overlay.ex
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/test/accrue_admin/components/data_table_test.exs
key-decisions:
  - Keep database read failures and mixed per-row replay outcomes at the existing ExUnit seam; no production fault-injection hook was added.
  - Keep the required CI Playwright selection unchanged because the shard is unrestricted and discovers the new spec.
  - Queue acceptance copy explicitly avoids claiming downstream processing.
patterns-established:
  - Host E2E fixtures return only stable record IDs needed by browser assertions and deterministically clean dependent fixture rows.
requirements-completed: [ADM-07, ADM-08]
coverage:
  - id: D1
    description: Mounted event and webhook journeys prove owner-scoped evidence, exact links, no-match states, lazy inspection, and zero/one/many replay behavior.
    requirement: ADM-07
    verification:
      - kind: e2e
        ref: "playwright: e2e/phase238-admin-events-webhooks.spec.js — Phase 238 seeded evidence and billing projections"
        status: pass
      - kind: unit
        ref: "cd accrue_admin && mix test --warnings-as-errors (601 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: Mounted billing inspection journeys prove a global coupon/code relationship and distinguish missing Connect provider snapshot facts from the local fee override.
    requirement: ADM-08
    verification:
      - kind: e2e
        ref: "playwright: e2e/phase238-admin-events-webhooks.spec.js — seeded billing projections"
        status: pass
      - kind: unit
        ref: "cd accrue_admin && mix test --warnings-as-errors (601 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: Keyboard, axe, themes, long text, 320 CSS pixel layout, 200% zoom, and required-shard discovery are checked in the mounted browser lane.
    verification:
      - kind: automated_ui
        ref: "playwright: e2e/phase238-admin-events-webhooks.spec.js — browser checks and --list discovery"
        status: pass
    human_judgment: false
  - id: D4
    description: Bulk replay copy remains explicit about fresh eligibility and queue acceptance.
    requirement: ADM-07
    verification:
      - kind: unit
        ref: "cd accrue_admin && mix test test/accrue_admin/copy_test.exs (13 tests)"
        status: pass
    human_judgment: false
metrics:
  duration: 11min
  completed: 2026-10-09
  commits: 4
  plan_head_before: 727d4e23dbc47a90fdeff5e993068aac7933df42
  plan_head_after: 093f850a620cfc06c0d42d728cc5b1d7082eede8
status: complete
---

# Phase 238 Plan 5: Admin Events, Webhooks & Remaining Billing Surfaces Summary

**Deterministic mounted Playwright coverage now exercises scoped events, bulk replay, billing inspection, accessibility, and narrow layouts with repeatable host fixtures.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-10-09T04:07:00Z
- **Completed:** 2026-10-09T04:18:28Z
- **Tasks:** 3
- **Files modified:** 6 source/test files

## Accomplishments

- Added fixed-ID fixtures for a second dead delivery, a global coupon with a related promotion code, and a Connect account whose Stripe observation snapshot is absent; cleanup removes dependent rows and jobs on reseed.
- Added mounted browser checks for exact scoped evidence links, filtered no-match states, lazy payload/activity, zero/one/many replay, invalid step-up correction, coupon/code relationships, and separate Connect observation/local override facts.
- Added keyboard, axe, light/dark/system, 320 CSS pixel, 200% zoom, long-text, and required Playwright shard discovery checks. Updated bulk replay assertions to the current explicit copy.
- Ran the complete Admin suite warning-strict: 601 tests passed with exit code 0.

## Task Commits

1. **Task 1: Seeded mounted evidence, replay, and billing journeys** — `40389fa9` (`test`)
2. **Task 2: Keyboard, theme, responsive, zoom, and shard assertions** — `aab8cc01` (`test`)
3. **Task 3: Current bulk replay copy contract** — `74f05d0f` (`test`)

**Auto-fix commit:** `093f850a` (`fix`) cleared two compiler warnings that blocked the required warning-strict suite.

**Plan metadata:** final documentation commit is recorded in the execution completion record.

## Files Created/Modified

- `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` — mounted route and interaction proof.
- `scripts/ci/accrue_host_seed_e2e.exs` — deterministic delivery, coupon/code, and Connect fixtures and cleanup.
- `accrue_admin/test/accrue_admin/copy_test.exs` — current replay question and dismissal copy contract.
- `accrue_admin/lib/accrue_admin/components/overlay.ex` — renders modal dialog role on a native `div`.
- `accrue_admin/lib/accrue_admin/live/webhook_live.ex` — fixes replay detail heading order and removes an unused private helper.
- `accrue_admin/test/accrue_admin/components/data_table_test.exs` — marks an unused returned HTML binding accordingly.

## Decisions Made

- Keep deterministic read-failure and mixed/failed per-row outcome checks in ExUnit, where the existing seam can control them.
- Keep `.github/workflows/ci.yml` unchanged: the existing required Playwright shard runs the complete spec set and lists both Phase 238 tests.
- Treat seeded host records as local application evidence only; no live-provider parity or downstream processing claim is made.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Accessibility bug] Corrected replay detail heading order.**
- **Found during:** Task 2 axe scan of the revealed payload state.
- **Issue:** The “Replay delivery” section used an `h3` under the page’s `h1`, producing an axe heading-order violation.
- **Fix:** Changed the section heading to `h2` while preserving its existing class styling.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex`
- **Verification:** Focused mounted browser suite passes with axe checks enabled.
- **Committed in:** `40389fa9`.

**2. [Rule 1 - Accessibility bug] Used a valid element for the modal dialog role.**
- **Found during:** Task 2 axe scan while step-up was pending.
- **Issue:** The shared overlay rendered `<article role="dialog">`, an invalid native element/role pairing.
- **Fix:** Rendered modal panels as `div`; the dialog role and ARIA naming remain on the panel.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/overlay.ex`
- **Verification:** Focused mounted browser suite passes axe checks in pending and rejected step-up states.
- **Committed in:** `40389fa9`.

**3. [Rule 3 - Blocking] Removed two warnings blocking the required Admin command.**
- **Found during:** Overall verification.
- **Issue:** An unused private helper in `WebhookLive` and an unused HTML binding in a DataTable test caused `mix test --warnings-as-errors` to exit nonzero after test execution.
- **Fix:** Removed the unreachable helper and renamed the unused binding `_html`.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex`, `accrue_admin/test/accrue_admin/components/data_table_test.exs`
- **Verification:** `mix test --warnings-as-errors` exits 0 with 601 tests passing.
- **Committed in:** `093f850a`.

**Total deviations:** 3 auto-fixed (2 accessibility bugs, 1 blocking warning cleanup).
**Impact on plan:** Fixes were limited to defects exposed by the plan’s required axe and strict test gates. The CI workflow and production test-injection surface were unchanged.

## Issues Encountered

- The first Chromium launch was blocked by macOS sandbox process bootstrap permissions before tests started. The required browser command was rerun with elevated execution and passed.
- The initial copy test contained additional retry-era wording and a stale “Cancel” label; both assertions now match the approved replay copy.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The Phase 238 browser spec is discovered by the existing required Playwright shard. No remote CI or branch-protection state was invoked or claimed.
- Read-failure and mixed replay result coverage remains at the deterministic Admin ExUnit seam.

---
*Phase: 238-admin-events-webhooks-remaining-billing-surfaces*
*Completed: 2026-10-09*

## Self-Check: PASSED

- Summary file exists at the required phase path.
- All four measured task commits are ancestors of HEAD.
- The plan ledger measures 4 commits from `plan_head_before` through `plan_head_after`.
