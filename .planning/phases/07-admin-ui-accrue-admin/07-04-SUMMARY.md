---
phase: 07-admin-ui-accrue-admin
plan: 04
subsystem: auth
tags: [phoenix, liveview, auth, audit, postgres, step-up]
requires:
  - phase: 07-admin-ui-accrue-admin
    provides: Mounted admin live_session boundary, router-owned shell, and repo-backed admin query harness
provides:
  - Mount-time admin enforcement for the mounted billing UI
  - Shared step-up workflow with audited approve and deny paths
  - Event-ledger causality fields for admin and webhook-linked audit rows
affects: [07-05, 07-06, 07-07, 07-08, 07-09, 07-10, 07-11, 07-12]
tech-stack:
  added: [lazy_html]
  patterns: [optional auth step-up callbacks, admin step-up audit events, causal event-ledger linkage]
key-files:
  created:
    - accrue/priv/repo/migrations/20260415091000_add_admin_causality_to_events.exs
    - accrue/test/accrue/events/admin_causality_test.exs
    - accrue_admin/lib/accrue_admin/step_up.ex
    - accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex
    - accrue_admin/test/accrue_admin/live/auth_hook_test.exs
    - accrue_admin/test/accrue_admin/live/step_up_test.exs
  modified:
    - accrue/lib/accrue/auth.ex
    - accrue/lib/accrue/auth/default.ex
    - accrue/lib/accrue/events.ex
    - accrue/lib/accrue/events/event.ex
    - accrue_admin/lib/accrue_admin/auth_hook.ex
    - accrue_admin/test/support/live_case.ex
    - accrue_admin/test/test_helper.exs
key-decisions:
  - "Causal linkage uses both `caused_by_event_id` and `caused_by_webhook_event_id` so admin actions and webhook-derived follow-ons stay first-class without overloading one column."
  - "Step-up verification delegates to optional `Accrue.Auth` callbacks, with dev/test auto-approval and prod fail-closed behavior preserved in `Accrue.Auth.Default`."
  - "Step-up audit rows use a separate `admin.step_up.*` stream on `Accrue.Events` so verification outcomes are durable without polluting domain event types."
patterns-established:
  - "Admin LiveView auth pattern: resolve `current_user` from the forwarded session in `on_mount`, reject non-admins before render, and assign the admin user once for later handlers."
  - "Destructive action pattern: `AccrueAdmin.StepUp.require_fresh/4` gates the action, records `admin.step_up.ok|denied`, and carries source-event causality through the shared event ledger."
requirements-completed: [AUTH-03, EVT-09, ADMIN-21, ADMIN-22, ADMIN-23, ADMIN-26]
duration: 9m
completed: 2026-04-15
---

# Phase 7 Plan 04: Admin Auth, Step-Up, and Event Causality Summary

**Mount-time admin enforcement, shared step-up verification, and causally linked admin audit rows across core and `accrue_admin`**

## Performance

- **Duration:** 9m
- **Started:** 2026-04-15T17:19:00Z
- **Completed:** 2026-04-15T17:27:52Z
- **Tasks:** 2
- **Files modified:** 17

## Accomplishments

- Extended `Accrue.Auth` with optional step-up callbacks, a fail-closed production default, and core tests proving the default dev/test step-up path.
- Added `caused_by_event_id` and `caused_by_webhook_event_id` to `accrue_events`, with normalization and focused coverage for admin-linked audit rows.
- Implemented `AccrueAdmin.AuthHook`, a shared `AccrueAdmin.StepUp` service, and LiveView coverage proving mount-time admin rejection plus step-up approve and deny flows.

## Task Commits

1. **Task 1: Extend the core auth and event-ledger seams for admin step-up and causality** - `673d84b` (feat)
2. **Task 2: Implement admin mount-time auth enforcement and the shared step-up workflow** - `c33aec1` (feat)

## Files Created/Modified

- `accrue/lib/accrue/auth.ex` and `auth/default.ex` - optional step-up callback surface, admin heuristics, and default adapter behavior for dev/test vs prod.
- `accrue/lib/accrue/events.ex`, `events/event.ex`, and `priv/repo/migrations/20260415091000_add_admin_causality_to_events.exs` - causal linkage fields and insert support for admin and webhook-linked rows.
- `accrue/test/accrue/events/admin_causality_test.exs` and `test/test_helper.exs` - focused causality coverage plus migration bootstrap so schema-bearing tests run against the current DB shape.
- `accrue_admin/lib/accrue_admin/auth_hook.ex`, `step_up.ex`, and `components/step_up_auth_modal.ex` - mount-time admin gate, shared step-up service, and reusable prompt UI.
- `accrue_admin/test/accrue_admin/live/auth_hook_test.exs`, `step_up_test.exs`, `test/support/live_case.ex`, and `test/test_helper.exs` - repo-backed LiveView coverage and endpoint startup for the admin auth and step-up flows.
- `accrue_admin/mix.exs` and `mix.lock` - test-only `lazy_html` dependency required by Phoenix LiveView 1.1 DOM assertions.

## Decisions Made

- Kept the Sigra bridge additive by extending `Accrue.Auth` via `@optional_callbacks` instead of forcing all adapters to implement new required callbacks immediately.
- Used separate `admin.step_up.ok` and `admin.step_up.denied` event types with `subject_type: "AdminUser"` so step-up outcomes remain queryable audit records without masquerading as billing events.
- Stored the step-up grace window in shared LiveView assigns for the mounted admin flow, while carrying source-event causality through the action map each page can reuse.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Bootstrapped pending core migrations in the `:accrue` test harness**
- **Found during:** Task 1 verification
- **Issue:** The focused `mix test test/accrue/events/admin_causality_test.exs --warnings-as-errors` run hit the old `accrue_events` schema because the core test DB was not applying new migrations automatically.
- **Fix:** Updated `accrue/test/test_helper.exs` to create the test DB if needed, run pending migrations in a temporary shared sandbox context, and then restore manual mode.
- **Files modified:** `accrue/test/test_helper.exs`
- **Verification:** `cd accrue && mix test test/accrue/events/admin_causality_test.exs --warnings-as-errors`
- **Committed in:** `673d84b`

**2. [Rule 3 - Blocking] Started the package-owned admin endpoint and expanded the shared LiveView harness**
- **Found during:** Task 2 verification
- **Issue:** Admin LiveView tests could not dispatch routed or isolated LiveViews because `AccrueAdmin.TestEndpoint` was configured but never started, and the shared `LiveCase` imported too little of `Phoenix.ConnTest`.
- **Fix:** Started `AccrueAdmin.TestEndpoint` in `accrue_admin/test/test_helper.exs` and broadened `LiveCase` to import `Phoenix.ConnTest` while checking out a shared sandbox owner for LiveView processes.
- **Files modified:** `accrue_admin/test/test_helper.exs`, `accrue_admin/test/support/live_case.ex`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/live/auth_hook_test.exs test/accrue_admin/live/step_up_test.exs --warnings-as-errors`
- **Committed in:** `c33aec1`

**3. [Rule 3 - Blocking] Added the missing `lazy_html` test dependency for LiveView DOM assertions**
- **Found during:** Task 2 verification
- **Issue:** Phoenix LiveView 1.1 test helpers now require `lazy_html` in test env, so every admin LiveView assertion aborted before exercising the step-up flow.
- **Fix:** Added `{:lazy_html, ">= 0.1.0", only: :test}` to `accrue_admin/mix.exs` and refreshed `mix.lock`.
- **Files modified:** `accrue_admin/mix.exs`, `accrue_admin/mix.lock`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/live/auth_hook_test.exs test/accrue_admin/live/step_up_test.exs --warnings-as-errors`
- **Committed in:** `c33aec1`

---

**Total deviations:** 3 auto-fixed (3 Rule 3)
**Impact on plan:** All three fixes were required to make the planned verification commands execute against the real schema and LiveView runtime. No scope creep beyond that support work.

## Issues Encountered

- Core schema-bearing tests were assuming an already-migrated local test DB, which broke as soon as this plan added new event-ledger columns.
- The admin package had a configured test endpoint but not a running one, so routed and isolated LiveView tests failed before reaching the auth hook or step-up service.
- Phoenix LiveView's current test DOM tooling requires `lazy_html`, and the admin package had not declared it yet.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later admin page plans can reuse `AccrueAdmin.AuthHook` for mount-time enforcement instead of rebuilding auth checks in each LiveView.
- Destructive admin actions now have one shared `AccrueAdmin.StepUp` service that can carry source-event causality into `Accrue.Events`.
- The core event ledger now exposes the causal linkage Phase 7 webhook and audit pages need for operator and webhook traceability.

## Self-Check: PASSED

- Found `.planning/phases/07-admin-ui-accrue-admin/07-04-SUMMARY.md`
- Found task commits `673d84b` and `c33aec1` in git history
