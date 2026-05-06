---
phase: 101-accrue-portal-foundation-checkout
plan: 02
subsystem: ui
tags: [phoenix, liveview, auth, csp, braintree, testing]
requires:
  - phase: 101-accrue-portal-foundation-checkout
    provides: "Plan 01 checkout-session and billing-portal contract used by the portal shell"
provides:
  - "Public `Accrue.Portal.*` mount/auth/CSP contract with `AccruePortal.*` compatibility wrappers"
  - "Single sibling `live_session :accrue_portal` with customer-aware `on_mount` hooks"
  - "Package-local portal test bootstrap and shared conn/browser case"
affects: [101-03, 101-04, 101-07, accrue_portal]
tech-stack:
  added: []
  patterns: ["public facade modules over internal package namespace", "LiveView auth via on_mount instead of router-gated session nesting"]
key-files:
  created: []
  modified:
    - accrue_portal/lib/accrue_portal/router.ex
    - accrue_portal/lib/accrue_portal/auth_hook.ex
    - accrue_portal/lib/accrue_portal/auth_plug.ex
    - accrue_portal/lib/accrue_portal/customer_session.ex
    - accrue_portal/lib/accrue_portal/csp_plug.ex
    - accrue_portal/lib/accrue_portal/brand_plug.ex
    - accrue_portal/test/test_helper.exs
    - accrue_portal/test/support/conn_case.ex
key-decisions:
  - "Made `Accrue.Portal.*` the public contract and kept `AccruePortal.*` as compatibility wrappers so current call sites keep compiling."
  - "Moved LiveView authentication to `on_mount` while retaining a dedicated auth plug only for controller POST routes."
  - "Implemented `ensure_customer_no_create` by querying the persisted customer row for the configured processor instead of lazily creating one."
patterns-established:
  - "Portal mounts as two sibling scopes: authenticated controller routes plus one sibling `live_session :accrue_portal`."
  - "Mounted portal session payload always threads brand/theme/CSP assigns through `Accrue.Portal.Router.__session__/3`."
requirements-completed: [BT-01]
duration: 6min
completed: 2026-05-01
---

# Phase 101 Plan 02: Accrue Portal Foundation & Checkout Summary

**Mounted portal shell now exposes the locked `Accrue.Portal` auth/CSP contract and ships its own package-local Phoenix test harness.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-02T02:00:00Z
- **Completed:** 2026-05-02T02:06:04Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Reworked the portal router to emit one sibling `live_session :accrue_portal`, thread brand/theme/CSP session data, and expose the new `Accrue.Portal.Router` public macro.
- Added `Accrue.Portal.AuthHook`, `AuthPlug`, and `CustomerSession` with both `:ensure_customer` and `:ensure_customer_no_create` resolution modes backed by the existing `Accrue.Auth` contract.
- Hardened the portal browser CSP for Braintree Hosted Fields and added package-local `test_helper` / `ConnCase` ownership for future router and LiveView suites.

## Task Commits

Each task was committed atomically:

1. **Task 1: Align the portal mount shell with the locked public contract** - `6ab10c3` (feat)
2. **Task 2: Establish the package-local browser harness base for later portal tests** - `3776047` (test)

## Files Created/Modified

- `accrue_portal/lib/accrue_portal/router.ex` - Public portal router contract plus compatibility wrapper and sibling-scope mount layout.
- `accrue_portal/lib/accrue_portal/auth_hook.ex` - Customer-aware `on_mount` callbacks for create and no-create flows.
- `accrue_portal/lib/accrue_portal/auth_plug.ex` - Controller-route auth assigner for POST actions outside LiveView mount.
- `accrue_portal/lib/accrue_portal/customer_session.ex` - Shared user/customer resolution with persisted-customer lookup for no-create mode.
- `accrue_portal/lib/accrue_portal/csp_plug.ex` - Braintree-specific CSP allowlist with nonce threading.
- `accrue_portal/lib/accrue_portal/brand_plug.ex` - Portal brand/theme assigns under the public namespace.
- `accrue_portal/test/test_helper.exs` - Portal package test boot sequence for repo, Oban, endpoint, and branding config.
- `accrue_portal/test/support/conn_case.ex` - Shared endpoint, router, repo, and browser/session helpers for later portal tests.

## Decisions Made

- `Accrue.Portal.*` is the stable public namespace; `AccruePortal.*` remains as compatibility glue for existing internal call sites.
- LiveView authorization now happens through `on_mount`, which avoids router-first gating for the mounted session while still protecting controller POST handlers.
- `ensure_customer_no_create` refuses to materialize missing billing customers and instead queries the persisted row for the active processor.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `MIX_ENV=test mix compile` initially failed because the working tree volume only had about `127MiB` free and an Erlang dependency could not write its test build artifact. Removing `accrue_portal/_build/test` freed enough transient space for the plan’s required verification path (`mix compile` plus harness file existence) to complete.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later portal plans can mount against the locked `Accrue.Portal` shell and rely on package-owned test bootstrap instead of borrowing host-app fixtures.
- The machine is extremely low on free disk space, so broader `MIX_ENV=test` dependency compiles may fail again until space is reclaimed.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/101-accrue-portal-foundation-checkout/101-02-SUMMARY.md`.
- Task commits `6ab10c3` and `3776047` exist in git history.
