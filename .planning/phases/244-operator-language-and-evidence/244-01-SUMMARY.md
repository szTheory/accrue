---
phase: 244-operator-language-and-evidence
plan: 01
subsystem: ui
tags: [phoenix-liveview, billing-events, operator-copy, playwright]
requires:
  - phase: 243
    provides: Mounted admin preview and isolated host browser custody contract
provides:
  - Producer-backed billing event labels with neutral unknown and missing fallbacks
  - Home-to-scoped-event evidence path with exact event identity and timestamp
  - Mounted candidate inventory and revision/asset-bound browser proof
affects: [operator-language, admin-events, home-activity]
actuals:
  tokens: 6086
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [central BillingEvent copy mapping, scoped Home-to-detail evidence]
key-files:
  created:
    - .planning/phases/244-operator-language-and-evidence/244-INVENTORY.md
    - .planning/phases/244-operator-language-and-evidence/244-01-red-evidence.json
    - .planning/phases/244-operator-language-and-evidence/244-01-red-report.tap
    - examples/accrue_host/e2e/phase244-operator-evidence.spec.js
  modified:
    - accrue_admin/lib/accrue_admin/copy/billing_event.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
    - accrue_admin/lib/accrue_admin/live/event_live.ex
    - accrue_admin/test/accrue_admin/copy/billing_event_test.exs
    - accrue_admin/test/accrue_admin/live/dashboard_live_test.exs
    - accrue_admin/test/accrue_admin/live/event_live_test.exs
key-decisions:
  - "Use explicit labels only for producer-confirmed event keys; keep unknown values neutral and exact evidence in scoped detail."
  - "Use ISO 8601 for event timestamps so seconds, fractional precision, and UTC offset remain visible."
patterns-established:
  - "Home activity can use readable operation labels while scoped EventLive detail retains the raw key and exact identity."
  - "Validate served admin assets by comparing their bytes with both package and compiled outputs."
requirements-completed: [LANG-01, EVID-01, CONS-01]
coverage:
  - id: D1
    description: "Confirmed billing event keys receive distinct truthful labels and missing or unknown values remain honest."
    requirement: LANG-01
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/copy/billing_event_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Home reaches scoped event detail with exact key, customer ID, full timestamp, and matching served assets."
    requirement: EVID-01
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/live/event_live_test.exs"
        status: pass
      - kind: e2e
        ref: "npm run e2e -- e2e/phase244-operator-evidence.spec.js --project chromium-desktop --grep @phase244-desktop --workers 1"
        status: pass
    human_judgment: false
  - id: D3
    description: "Home names the Events destination and preserves owner-scoped event links."
    requirement: CONS-01
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/live/dashboard_live_test.exs"
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-10-11
status: complete
plan_head_before: 22f725b4eb43e89567579007ca0f6db4310dbaad
plan_head_after: 5a0876f939de0bbc57a91f8a09a119e1e2b69891
commits: 3
---

# Phase 244 Plan 01: Operator Language and Evidence Summary

**Home presents a producer-backed customer update label and preserves the exact scoped event key, identity, timestamp, and matching browser assets.**

## Performance

- **Duration:** 12 minutes
- **Started:** 2026-10-11T00:53:42Z
- **Completed:** 2026-10-11T01:05:32Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Confirmed mounted Home, Events, event detail, and dead webhook evidence without changing the feedback preview; recorded bounded dispositions and vocabulary ownership.
- Added the `customer.updated` Home label and retained its scoped detail destination, exact event key, subject ID, and ISO 8601 timestamp with fractional seconds.
- Added distinct copy for `customer.local_updated`, `webhook.received`, and `webhook.replay_requested`; unknown and malformed keys remain neutral or explicitly unavailable.
- Added a host Playwright proof that checks the scoped journey and verifies served CSS/JS hashes against package and compiled asset bytes.

## Task Commits

1. **Task 1: Confirm mounted candidates and prove one Home-to-event path** — `a44dbd71` (`feat`)
2. **Task 2 RED: Add semantic event label assertions** — `14a67e10` (`test`)
3. **Task 2 GREEN: Implement confirmed event labels** — `5a0876f9` (`feat`)

## TDD Gate Compliance

- **RED:** `mix test --formatter AccrueAdmin.Test.Phase244TAPFormatter test/accrue_admin/copy/billing_event_test.exs` exited 2 with 6 tests, including the named target failure: `customer.local_updated` returned the generic label instead of its expected local-only meaning. The unchanged TAP report is in `244-01-red-report.tap`; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- **GREEN:** Added only the confirmed producer-backed mappings. The planned focused suite passed with 8 tests and no failures.
- **REFACTOR:** Removed the temporary local TAP formatter after capturing classifier-accepted evidence; no dependency or permanent reporter was added.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/live/event_live_test.exs` — 15 tests, 0 failures.
- `cd accrue_admin && mix test test/accrue_admin/copy/billing_event_test.exs test/accrue_admin/live/dashboard_live_test.exs` — 8 tests, 0 failures.
- `npm run e2e -- e2e/phase244-operator-evidence.spec.js --project chromium-desktop --grep @phase244-desktop --workers 1` — 1 test passed on checkout `5a0876f939de0bbc57a91f8a09a119e1e2b69891`; served CSS and JS bytes matched packaged and compiled assets.

## Decisions Made

- Kept semantic copy as explicit producer-backed mappings rather than inferring labels from event key punctuation.
- Left existing Home projection, owner scope, event filters, raw payload, auth, billing behavior, and `Copy.Locked` text unchanged.
- Preserved honest `Unobserved` inventory dispositions where testing would have mutated the feedback preview or required inducing a read failure there.

## Deviations from Plan

The TDD evidence checker does not accept native ExUnit console output. A temporary local ExUnit TAP formatter produced the actual test-event report for classifier validation; it was removed in the GREEN commit. No dependencies were added.

## Issues Encountered

- The existing preview accessibility view did not expose stylesheet/script identities, and its browser blocked `view-source:`. The isolated host fixture resolved this by capturing served asset URLs and comparing bytes directly. The feedback preview database, sentinel, dispatch, audit, and custody were not changed.

## User Setup Required

None.

## Next Phase Readiness

The Home-to-event evidence slice and the confirmed Copy contract are complete. Inventory entries marked `Unobserved` remain explicit candidates for later work; no unobserved failure or replay outcome was presented as a mounted observation.

## Self-Check: PASSED

The summary exists, and all three task commits (`a44dbd71`, `14a67e10`, `5a0876f9`) are ancestors of the current plan head.

---
*Phase: 244-operator-language-and-evidence*
*Completed: 2026-10-11*
