---
phase: 234-admin-customers-subscriptions
plan: "01"
subsystem: ui
tags: [phoenix-liveview, admin, owner-scope, cursor-navigation, playwright]

requires:
  - phase: 233-shared-direction-portal-contract
    provides: shared Admin semantic direction and host fixture/browser evidence patterns
provides:
  - bounded mount-local list return-state validation rebuilt under the current owner scope
  - correctly labeled subscription/customer links with originating subscription-list context
  - stale and invalid cursor recovery within the same owner and filter state
  - immutable pre-layout served customer, subscription, and action-drawer captures
affects: [234-02, 234-03, customer-detail-navigation, scoped-admin-routes]

actuals:
  tokens: 331789
  tasks: 2
  commits: 2
  plan_head_before: 3da32d163e9418caef313323045f9ddd11227f2a
  plan_head_after: cf03cc80215ddb7ea4b6377ddfcf523bfe610094
commits: 2
plan_head_before: 3da32d163e9418caef313323045f9ddd11227f2a
plan_head_after: cf03cc80215ddb7ea4b6377ddfcf523bfe610094

tech-stack:
  added: []
  patterns:
    - bounded route/query allowlists for local return navigation
    - scoped record existence check before accepting a signed pagination cursor

key-files:
  created:
    - examples/accrue_host/e2e/phase234-pre-layout.spec.js
    - .planning/phases/234-admin-customers-subscriptions/captures/pre-layout/manifest.json
    - .planning/phases/234-admin-customers-subscriptions/captures/pre-layout/customer-detail.png
    - .planning/phases/234-admin-customers-subscriptions/captures/pre-layout/subscription-detail.png
    - .planning/phases/234-admin-customers-subscriptions/captures/pre-layout/subscription-drawer.png
  modified:
    - accrue_admin/lib/accrue_admin/scoped_path.ex
    - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/lib/accrue_admin/queries/subscriptions.ex
    - accrue_admin/test/accrue_admin/scoped_path_test.exs
    - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs

key-decisions:
  - "Return URLs preserve only supported list state; mount, record authorization, and organization scope come from server state."
  - "A cursor is accepted only while its referenced subscription still exists in the active owner scope and filter."

patterns-established:
  - "Return-path validation: allowlist a mounted list route and its supported query keys, then rebuild through ScopedPath.build/4."
  - "Cursor recovery: clear unusable position while retaining allowed list filters and current organization scope."

requirements-completed: [ADM-03, SAFE-01]
coverage:
  - id: D1
    description: "The served pre-layout customer, subscription, and drawer baseline is captured once and verified read-only by byte hashes."
    requirement: SAFE-01
    verification:
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase234-pre-layout.spec.js (capture and read-only verification)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Subscription list identity links open their named objects and retain bounded list context in the active organization scope."
    requirement: ADM-03
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs#renders customer and subscription labels to their own destination with list context"
        status: pass
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/subscription_live_test.exs#subscription detail returns to the validated originating list in the current organization scope"
        status: pass
    human_judgment: false
  - id: D3
    description: "Foreign and forged return state remains generic and stale cursors recover to the first scoped page with the same filters."
    requirement: SAFE-01
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/scoped_path_test.exs"
        status: pass
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs#invalid cursor recovers to the first page without dropping organization or filters"
        status: pass
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/live/subscription_live_test.exs#out-of-scope subscription route redirects with denial flash before rendering detail"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-10-07
status: complete
---

# Phase 234 Plan 01: Scoped Subscription Investigation Summary

**Subscription investigation links now open the named customer or subscription, preserve validated list context, and recover stale cursors within the active owner scope.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-10-08T00:29:20Z
- **Completed:** 2026-10-08T00:40:55Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Captured served customer detail, subscription detail, and action-drawer screenshots before LiveView changes, with SHA-256 and byte-length provenance for source, assets, and images.
- Added `ScopedPath.return_path/3` to accept only mounted local list routes and supported filter keys, then rebuild under the current mount and owner scope.
- Corrected subscription list link destinations, added a contextual Back to results link, and recovered invalid or stale cursors without dropping scoped filters.
- Added positive organization-scoped mounted journeys and generic-denial, forged-return, alternate-mount, and hostile-input checks.

## Task Commits

Each task was committed atomically:

1. **Task 1: Preserve served baseline and validate bounded return state** - `88443198` (`feat`)
2. **Task 2: Trace a scoped subscription result through detail and return** - `cf03cc80` (`feat`)

## Files Created/Modified

- `examples/accrue_host/e2e/phase234-pre-layout.spec.js` - one-time baseline capture and read-only hash verification.
- `.planning/phases/234-admin-customers-subscriptions/captures/pre-layout/` - immutable evidence manifest and three served screenshots.
- `accrue_admin/lib/accrue_admin/scoped_path.ex` - bounded local return URL validation.
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` - named destinations, preserved list state, and cursor recovery.
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` - contextual return link rebuilt from server scope.
- `accrue_admin/lib/accrue_admin/queries/subscriptions.ex` - signed cursor existence check under current scope and filters.
- `accrue_admin/test/accrue_admin/{scoped_path_test.exs,live/subscriptions_live_test.exs,live/subscription_live_test.exs}` - adversarial and mounted regression coverage.

## Decisions Made

- Return URLs carry navigation state only. They cannot choose an owner, mount, detail record, credential, or mutation state.
- A signed cursor is treated as stale if its referenced row no longer matches the active owner scope and list filters.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical correctness] Reject signed cursors whose row is stale or outside the current scoped filter**
- **Found during:** Task 2 (Trace a scoped subscription result through detail and return)
- **Issue:** Cursor decoding alone returned `nil` for invalid tokens and could not distinguish a stale/deleted row from a valid first-page request.
- **Fix:** Added a bounded existence query using the existing decoded filter and `OwnerScope`; invalid or stale cursors now clear the position, preserve allowed filters, and explain the recovery.
- **Files modified:** `accrue_admin/lib/accrue_admin/queries/subscriptions.ex`, `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`, `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs`
- **Verification:** Focused three-file ExUnit run passed (38 tests, 0 failures).
- **Committed in:** `cf03cc80`

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** The scoped cursor check closes the plan’s stale-position correctness requirement without adding a service, dependency, or schema change.

## Issues Encountered

- The initial asset build was blocked by an existing root-owned npm cache. Re-running with `npm_config_cache=/tmp/accrue-npm-cache` completed successfully without modifying the shared cache or project configuration.
- Chromium initially could not launch under the restricted sandbox; the approved elevated browser run completed the one-time capture and read-only verification successfully.

## Verification

- `cd accrue_admin && mix test test/accrue_admin/scoped_path_test.exs` — passed (7 tests, 0 failures).
- `cd examples/accrue_host && PHASE234_CAPTURE_BASELINE=0 npm_config_cache=/tmp/accrue-npm-cache npm run e2e -- e2e/phase234-pre-layout.spec.js --workers=1` — passed (read-only byte-hash verification).
- `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/scoped_path_test.exs` — passed (38 tests, 0 failures).
- Changed Elixir files passed `mix format --check-formatted`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The subscription list-to-detail path now has a bounded return contract for later customer and related-record routes. Phase 234-02 can build on the helper while preserving current mount and owner scope.

---
*Phase: 234-admin-customers-subscriptions*
*Completed: 2026-10-07*

## Self-Check: PASSED

- Summary and all five baseline artifacts exist.
- Task commits `88443198` and `cf03cc80` are ancestors of HEAD.
- The measured task commit count is 2, matching the frontmatter.
