---
phase: 240-shared-system-and-real-billing-exemplar
plan: "05"
subsystem: payments
tags: [billing, LiveView, Playwright, reconnect, TDD]
requires:
  - phase: 240-03
    provides: Invoice and subscription lifecycle state with deterministic test clock
provides:
  - Disposable server-held billing action fixture with dispatch and audit evidence
  - LiveView readiness-aware browser lock, replacement handling, and no-replay coverage
affects: [240-06, billing, reconnect]
actuals:
  tokens: 97760
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: ["Wait for LiveView reconnected before releasing staged controls", "Observe billing controls at document scope across overlay replacement"]
key-files:
  created:
    - .planning/phases/240-shared-system-and-real-billing-exemplar/240-05-fixture-hold-red.json
    - .planning/phases/240-shared-system-and-real-billing-exemplar/240-05-phase191-full-green.json
  modified:
    - accrue_admin/test/support/e2e_fixtures.ex
    - accrue_admin/test/support/e2e_plug.ex
    - accrue_admin/test/accrue_admin/e2e_fixtures_test.exs
    - accrue_admin/assets/js/hooks/connection_state.js
    - accrue_admin/e2e/admin-page-flow-phase191.spec.js
    - accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex
    - accrue_admin/lib/accrue_admin/live/charge_live.ex
    - accrue_admin/priv/static/accrue_admin.js
key-decisions:
  - "Browser online is only transport recovery; controls remain locked until LiveView reports reconnected."
  - "Observe at document scope because overlay controls are siblings of the LiveView shell, and preserve each replacement control's original disabled state."
  - "Use the existing Phase 191 lifecycle owner and fixture counts to verify completion and detect replay."
patterns-established:
  - "Test-only hold/release seams must reset both held state and dispatch counters between disposable scenarios."
requirements-completed: [DSN-04, UXC-02, EVR-02]
coverage:
  - id: D1
    description: A held disposable subscription cancellation stays busy until release and records a single authoritative dispatch and audit event.
    requirement: DSN-04
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/e2e_fixtures_test.exs; mix test test/accrue_admin/e2e_fixtures_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/subscription_live_test.exs"
        status: pass
      - kind: e2e
        ref: "accrue_admin/e2e/admin-page-flow-phase191.spec.js; npm run e2e:phase191"
        status: pass
    human_judgment: false
  - id: D2
    description: Billing controls stay locked through online-before-ready, repeated patches and replacement; reconnect restores current eligibility without replay and preserves original disabled state.
    requirement: UXC-02
    verification:
      - kind: e2e
        ref: "accrue_admin/e2e/admin-page-flow-phase191.spec.js; 240-05-phase191-complete.junit.xml (26 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: Busy step-up feedback exposes disabled state and a named processing label while work is active.
    requirement: EVR-02
    verification:
      - kind: e2e
        ref: "240-05-held-action-locator-green.junit.xml; 240-05-original-disabled-green.junit.xml"
        status: pass
    human_judgment: false
duration: 61min
completed: 2026-10-09
status: complete
plan_head_before: bccbe6d4650808835df358dc8012db532d03441d
plan_head_after: d224b7685e6c5723aab062fa827c1cde2f3b5e82
commits: 3
---

# Phase 240 Plan 05: Real Busy Completion and Reconnect Without Action Replay Summary

**Disposable cancellation now proves held busy feedback, exactly-once billing and audit completion, and LiveView-safe recovery.**

## Performance

- **Duration:** 61 minutes
- **Started:** 2026-10-09T21:39:06Z
- **Completed:** 2026-10-09T22:40:00Z
- **Tasks:** 2
- **Files modified:** 23 implementation and evidence files

## Accomplishments

- Added test-only hold/release controls and fixture evidence for provider dispatch, subscription status, cancellation events, and admin audit events.
- Extended the mounted Phase 191 browser owner to prove busy-to-idle behavior, repeated patch and replaced-control handling, online-before-ready locking, original disabled-state preservation, focus recovery, and no replay.
- Updated the compiled Admin JavaScript bundle and step-up/charge focus behavior to match the verified lifecycle.

## Task Commits

1. **Task 1: Hold a real disposable action and count authoritative dispatch** - `f89a8f3f` (test)
2. **Task 2: Exercise busy, patch, replacement and reconnect in mounted browser** - `6c382a15` (fix)
3. **Task 2 follow-up: Preserve original disabled state and use the actual menu trigger** - `d224b768` (test)

The final plan metadata commit is recorded in the execution completion report.

## Verification

- Required fixture, invoice, and subscription ExUnit owner: **71 tests, 0 failures**.
- Required mounted Phase 191 browser owner: **26 tests, 0 failures, 0 skipped**, across desktop and mobile Chromium projects.
- Admin asset build completed successfully. It emitted existing warnings for absent Storybook-only CSS and JavaScript paths; these are recorded in `deferred-items.md`.
- The full Phase 191 run used the freshly rebuilt package asset and host compilation.

## TDD Gate Compliance

Five actual RED reports were captured for the fixture hold, dispatch contract, premature online unlock, overlay disconnect, and reconnect focus scenarios. Each passed `gsd_run check tdd-red-evidence` before its corresponding implementation. The final browser GREEN report is `240-05-phase191-full-green.json` with its native JUnit at `240-05-phase191-complete.junit.xml`; the completed report records 26 passing tests. A subsequent disabled-state assertion exposed a browser-test menu-trigger issue, which was fixed and then covered by the final full GREEN run. No failure was fabricated, and the earlier 240-03 retrospective timing caveat remains as previously documented.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Return the provider adapter's tagged success result in the held fixture**
- **Found during:** Task 1
- **Issue:** The fixture recorded one dispatch but returned a bare response map, leaving the subscription state active instead of persisting completion.
- **Fix:** Made the fake provider return the real adapter contract `{:ok, response}` and asserted resulting state and audit/event counts.
- **Files modified:** `accrue_admin/test/support/e2e_fixtures.ex`, `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs`
- **Verification:** Required ExUnit owner and complete Phase 191 owner passed.
- **Committed in:** `f89a8f3f`

**2. [Rule 1 - Bug] Hold replacement billing controls through actual LiveView readiness**
- **Found during:** Task 2
- **Issue:** Browser transport `online` could precede LiveView readiness, and the overlay's controls sit outside the shell subtree observed by the existing hook.
- **Fix:** Observe controls from the document level, retain the lock until `reconnected()`, and restore each control's original disabled attributes after fresh readiness. Restore focus to the matching replacement action.
- **Files modified:** `accrue_admin/assets/js/hooks/connection_state.js`, `accrue_admin/lib/accrue_admin/live/charge_live.ex`, `accrue_admin/e2e/admin-page-flow-phase191.spec.js`
- **Verification:** The mounted owner exercises online-before-ready, repeated patches, replacement, original disabled state, focus, and dispatch/audit counts; final full owner passed.
- **Committed in:** `6c382a15`, `d224b768`

**3. [Rule 2 - Missing critical feedback] Expose a named busy label for step-up actions**
- **Found during:** Task 2
- **Issue:** Disabled state alone did not provide the required visible processing label for an in-flight step-up confirmation.
- **Fix:** Added the LiveView `phx-disable-with` processing label and verified busy icon, label, and disabled state.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex`, `accrue_admin/priv/static/accrue_admin.js`
- **Verification:** Held-action browser assertion and full Phase 191 owner passed.
- **Committed in:** `6c382a15`

**4. [Rule 1 - Test defect] Click the actual details summary in the browser helper**
- **Found during:** Task 2
- **Issue:** The existing helper clicked the `<details>` container, which did not open the menu in the new held-action path.
- **Fix:** Click the actual `<summary>` trigger; added a browser assertion for a control whose original disabled state must survive replacement.
- **Files modified:** `accrue_admin/e2e/admin-page-flow-phase191.spec.js`
- **Verification:** Isolated held-action target and final full Phase 191 owner passed.
- **Committed in:** `d224b768`

**Total deviations:** 4 auto-fixed (3 Rule 1, 1 Rule 2). **Impact:** Corrections were necessary to make the planned fixture and mounted lifecycle evidence faithful; no production dependencies or new mutation paths were added.

## Issues Encountered

The default npm cache was not writable, so commands used a task-local cache under `/private/tmp`. Git metadata writes required the authorized escalation path. The normal commit hook also rejected machine-local paths in raw JUnit reports; raw reports were preserved under `/private/tmp/accrue240-evidence`, while committed copies replaced only the machine-specific path prefix. All commits used standard hooks.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The held-action and reconnect contracts are covered at their existing test and browser owners. Plan 240-06 can consume these assertions and fixture seams. Linux pixel verification and golden closure remain tracked by their owning plan; this plan makes no claim about them.

---
*Phase: 240-shared-system-and-real-billing-exemplar*
*Completed: 2026-10-09*

## Self-Check: PASSED

- Summary file exists.
- Task commits `f89a8f3f`, `6c382a15`, and `d224b768` are ancestors of HEAD.
