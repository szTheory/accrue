---
phase: 20-organization-billing-with-sigra
plan: 03
subsystem: auth
tags: [sigra, liveview, organization-billing, admin-scope, testing]
requires:
  - phase: 20-organization-billing-with-sigra
    provides: Sigra-backed host organizations, memberships, and host scope hydration from plans 20-01 and 20-02
provides:
  - Shared admin owner-scope resolution for `accrue_admin` mounts
  - Router-threaded active-organization session keys for admin LiveViews
  - Host admin mount proof for owner-scope session and out-of-scope denial
affects: [phase-20-plan-04, org-billing, accrue-admin, accrue-host]
tech-stack:
  added: []
  patterns: [thread owner-scope session keys once in router, resolve current_owner_scope during on_mount]
key-files:
  created:
    - accrue_admin/lib/accrue_admin/owner_scope.ex
  modified:
    - accrue_admin/lib/accrue_admin/router.ex
    - accrue_admin/lib/accrue_admin/auth_hook.ex
    - examples/accrue_host/test/accrue_host_web/admin_mount_test.exs
key-decisions:
  - "The admin package now forwards a fixed owner-scope session contract (`active_organization_id`, `active_organization_slug`, `admin_organization_ids`) in addition to host-specified session keys."
  - "Owner scope resolves once during `AccrueAdmin.AuthHook.on_mount/4`, so downstream LiveViews can read `current_owner_scope` instead of re-parsing host session state."
patterns-established:
  - "Use `AccrueAdmin.OwnerScope.resolve/2` for global-versus-organization admin scope decisions."
  - "Keep host admin mount verification focused on forwarded session shape and mount assigns before query-level gating."
requirements-completed: [ORG-03]
duration: 9 min
completed: 2026-04-17
---

# Phase 20 Plan 03: Admin Owner Scope Summary

**`accrue_admin` now mounts with a shared owner-scope contract that carries active-organization context through the admin session and resolves out-of-scope org routes fail-closed**

## Performance

- **Duration:** 9 min
- **Started:** 2026-04-17T20:01:00Z
- **Completed:** 2026-04-17T20:09:45Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added the ORG-03 host admin mount proof for forwarded active-organization session keys and mounted `current_owner_scope`.
- Created a shared `AccrueAdmin.OwnerScope` resolver that distinguishes global versus organization admin scope and returns `:not_found` for out-of-scope org slugs.
- Threaded owner-scope session keys once in `AccrueAdmin.Router` and assigned `current_owner_scope` during `AccrueAdmin.AuthHook` mount.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ORG-03 host proof that admin mount threads organization scope into `accrue_admin`** - `8a746e1` (test)
2. **Task 2: Add ORG-03 shared admin owner scope and wire router/auth threading** - `349c6ab` (feat)

## Files Created/Modified
- `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` - proves forwarded owner-scope session keys, mounted `current_owner_scope`, and out-of-scope org denial.
- `accrue_admin/lib/accrue_admin/owner_scope.ex` - normalizes admin session data into a shared global-or-organization owner scope.
- `accrue_admin/lib/accrue_admin/router.ex` - forwards owner-scope session keys alongside host-specified session keys in one session transport.
- `accrue_admin/lib/accrue_admin/auth_hook.ex` - resolves and assigns `current_owner_scope` during admin LiveView mount.

## Decisions Made
- Used an internal `AccrueAdmin.OwnerScope` struct instead of a direct Sigra dependency so the admin package can mirror Sigra semantics while staying on its existing optional-dependency boundary.
- Scoped organization route resolution to server-forwarded session data only, with active-org slug mismatches returning `:not_found` instead of falling back to global scope.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- The RED run first failed on the intended seams: `AccrueAdmin.OwnerScope.resolve/2` did not exist and `current_owner_scope` was not assigned on mount.
- The existing host router mount did not need changes because `AccrueAdmin.Router.__session__/3` now forwards the owner-scope keys automatically.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Downstream admin query plans can now gate loaders and LiveViews off `current_owner_scope` instead of re-reading host session values.
- The host proof for the owner-scope session contract is in place and passing with the required focused verification command.

## Self-Check: PASSED

---
*Phase: 20-organization-billing-with-sigra*
*Completed: 2026-04-17*
