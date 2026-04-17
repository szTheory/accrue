---
phase: 20-organization-billing-with-sigra
plan: 01
subsystem: testing
tags: [sigra, organization-billing, ecto, migrations, fixtures]
requires:
  - phase: 19-tax-location-and-rollout-safety
    provides: host billing facade and focused regression harness
provides:
  - Sigra-backed organization billable proof on the existing owner contract
  - example host organization wrapper and schemas
  - host organization and membership migrations
affects: [phase-20-plan-02, phase-20-plan-03, org-billing, accrue-host]
tech-stack:
  added: [sigra]
  patterns: [Sigra host wrapper with host-owned schemas, organization billables stay on owner_type/owner_id]
key-files:
  created:
    - examples/accrue_host/lib/accrue_host/accounts/organization.ex
    - examples/accrue_host/lib/accrue_host/accounts/organization_membership.ex
    - examples/accrue_host/lib/accrue_host/organizations.ex
    - examples/accrue_host/priv/repo/migrations/20260417210000_create_organizations.exs
    - examples/accrue_host/priv/repo/migrations/20260417210100_create_organization_memberships.exs
  modified:
    - accrue/test/accrue/billable_test.exs
    - examples/accrue_host/test/accrue_host/billing_facade_test.exs
    - examples/accrue_host/test/support/fixtures/accounts_fixtures.ex
    - examples/accrue_host/mix.exs
    - examples/accrue_host/lib/accrue_host/accounts/scope.ex
key-decisions:
  - "Organization billing stays on Accrue's existing owner_type and owner_id contract; no core billing schema changes were added."
  - "The example host resolves Sigra from ../../../sigra by path unless ACCRUE_HOST_HEX_RELEASE=1 selects the versioned Hex dependency branch."
  - "Organization fixtures create orgs through Sigra.Organizations with Scope.for_user/1, and owner memberships are treated as idempotent because Sigra creates them during org creation."
patterns-established:
  - "Create host organizations through AccrueHost.Organizations.create_organization/2 with a loaded scope, not a bare user."
  - "Keep organization membership roles explicit as [:owner, :admin, :member] in both schema and fixtures."
requirements-completed: [ORG-01]
duration: 5 min
completed: 2026-04-17
---

# Phase 20 Plan 01: Organization Billing Foundation Summary

**Sigra-backed host organizations now round-trip through Accrue billing with preserved Organization ownership, concrete host schemas, and migrated org tables**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-17T19:50:00Z
- **Completed:** 2026-04-17T19:55:00Z
- **Tasks:** 3
- **Files modified:** 14

## Accomplishments
- Added ORG-01 regression coverage in `accrue` and the example host for organization-owned customers and billing state.
- Wired `examples/accrue_host` to the real local Sigra dependency and added the concrete host wrapper plus Sigra-shaped organization primitives.
- Added and applied the example host organization and membership migrations, then reran the focused host and core billing proofs.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ORG-01 regression coverage for a real Sigra-backed organization billable** - `a0f3acb` (test), `06d26e0` (feat)
2. **Task 2: Add the local Sigra dependency, host wrapper, and organization schemas** - `e207cca` (feat)
3. **Task 3: [BLOCKING] Push the host organization schema before downstream verification** - `a5d97e8` (chore)

## Files Created/Modified
- `accrue/test/accrue/billable_test.exs` - proves organization billables still persist `owner_type: "Organization"` and `owner_id`.
- `examples/accrue_host/test/accrue_host/billing_facade_test.exs` - proves the host facade accepts Sigra-backed organizations for customer and billing-state lookups.
- `examples/accrue_host/test/support/fixtures/accounts_fixtures.ex` - adds organization, membership, and active-scope fixtures with explicit Sigra roles.
- `examples/accrue_host/mix.exs` - adds local `:sigra` path wiring with explicit Hex-release fallback.
- `examples/accrue_host/lib/accrue_host/accounts/organization.ex` - host-owned billable organization schema.
- `examples/accrue_host/lib/accrue_host/accounts/organization_membership.ex` - host-owned membership schema with explicit owner/admin/member roles.
- `examples/accrue_host/lib/accrue_host/organizations.ex` - concrete `use Sigra.Organizations` wrapper for the host app.
- `examples/accrue_host/priv/repo/migrations/20260417210000_create_organizations.exs` - creates organizations with owner and active-slug indexes.
- `examples/accrue_host/priv/repo/migrations/20260417210100_create_organization_memberships.exs` - creates organization memberships with uniqueness and lookup indexes.

## Decisions Made
- Used the real Sigra wrapper contract from the local Sigra example instead of inventing a compatibility seam.
- Extended `AccrueHost.Accounts.Scope` to carry `active_organization` and `membership` so host fixtures match Sigra's actual scope shape.
- Added minimal host-owned `OrganizationInvitation`, `OrganizationSlugAlias`, and `UserSession` schemas because the Sigra wrapper configuration depends on concrete modules even though this plan does not migrate or exercise those tables yet.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Landed Sigra host modules during Task 1 green phase**
- **Found during:** Task 1 (Add ORG-01 regression coverage for a real Sigra-backed organization billable)
- **Issue:** The new host regression could not compile until the concrete Sigra-backed organization modules, scope fields, and dependency wiring existed.
- **Fix:** Added the host Sigra wrapper, organization schemas, scope fields, and dependency wiring before Task 1's green verification, then left the migration files for Task 2's own commit.
- **Files modified:** `examples/accrue_host/mix.exs`, `examples/accrue_host/mix.lock`, `examples/accrue_host/lib/accrue_host/accounts/scope.ex`, `examples/accrue_host/lib/accrue_host/accounts/organization.ex`, `examples/accrue_host/lib/accrue_host/accounts/organization_membership.ex`, `examples/accrue_host/lib/accrue_host/accounts/organization_invitation.ex`, `examples/accrue_host/lib/accrue_host/accounts/organization_slug_alias.ex`, `examples/accrue_host/lib/accrue_host/accounts/user_session.ex`, `examples/accrue_host/lib/accrue_host/organizations.ex`
- **Verification:** `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs`
- **Committed in:** `06d26e0`

**2. [Rule 1 - Bug] Fixed fixture calls to match Sigra's real organization API**
- **Found during:** Task 1 (Add ORG-01 regression coverage for a real Sigra-backed organization billable)
- **Issue:** `Sigra.Organizations.create_organization/3` requires a loaded scope, and owner memberships were being inserted twice because Sigra already creates the initial owner membership atomically.
- **Fix:** Changed organization fixtures to call `Scope.for_user/1` and made membership fixture creation idempotent for existing user/organization pairs.
- **Files modified:** `examples/accrue_host/test/support/fixtures/accounts_fixtures.ex`, `examples/accrue_host/test/accrue_host/billing_facade_test.exs`
- **Verification:** `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs`
- **Committed in:** `06d26e0`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both fixes were required for the planned ORG-01 proof to compile and match Sigra's real API. No architectural scope change was introduced.

## Issues Encountered
- `MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs` first failed because the fixture passed a bare user into `Sigra.Organizations.create_organization/3`; updating it to use a real scope resolved the mismatch.
- `cd examples/accrue_host && MIX_ENV=test mix ecto.migrate` returned `Migrations already up` because the test environment had already applied the new migrations during focused verification.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The example host now has the real Sigra organization wrapper, concrete org schemas, and migrated org tables needed for active-organization host flows.
- Follow-on Phase 20 plans can build on these fixtures and schemas for active-org billing behavior, admin owner scoping, and cross-org denial proof.

## Self-Check: PASSED

---
*Phase: 20-organization-billing-with-sigra*
*Completed: 2026-04-17*
