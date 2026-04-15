---
phase: 07-admin-ui-accrue-admin
plan: 03
subsystem: ui
tags: [phoenix, liveview, ecto, postgres, cursor-pagination]
requires:
  - phase: 07-admin-ui-accrue-admin
    provides: Responsive shell, router-owned session payload, and package-owned admin mount boundary
provides:
  - Signed cursor pagination contract for admin billing and account lists
  - Schema-grounded `AccrueAdmin.Queries.*` modules for customers, subscriptions, invoices, charges, coupons, promotion codes, and Connect accounts
  - Phase 7 composite indexes aligned with current `accrue_*` tables and a repo-backed admin query test harness
affects: [07-04, 07-05, 07-06, 07-07, 07-08, 07-09, 07-10, 07-11, 07-12]
tech-stack:
  added: []
  patterns: [signed opaque cursor tokens, explicit row-map selects for admin lists, admin package repo-backed migration test harness]
key-files:
  created:
    - accrue_admin/lib/accrue_admin/queries/cursor.ex
    - accrue_admin/lib/accrue_admin/queries/behaviour.ex
    - accrue_admin/lib/accrue_admin/queries/customers.ex
    - accrue_admin/lib/accrue_admin/queries/subscriptions.ex
    - accrue_admin/lib/accrue_admin/queries/invoices.ex
    - accrue_admin/lib/accrue_admin/queries/charges.ex
    - accrue_admin/lib/accrue_admin/queries/coupons.ex
    - accrue_admin/lib/accrue_admin/queries/promotion_codes.ex
    - accrue_admin/lib/accrue_admin/queries/connect_accounts.ex
    - accrue_admin/test/accrue_admin/queries/query_modules_test.exs
    - accrue/priv/repo/migrations/20260415140000_add_phase7_admin_indexes.exs
  modified:
    - accrue_admin/config/test.exs
    - accrue_admin/test/test_helper.exs
key-decisions:
  - "Admin list queries return explicit row maps instead of whole schemas so metadata/data blobs do not bleed into list rendering by default."
  - "Cursor tampering fails closed to first-page semantics via HMAC-signed opaque tokens, satisfying the admin query-param threat model without introducing offset pagination."
  - "The admin package now boots its own sandboxed test repo against `accrue` migrations so list-query behavior is verified against real schema and index state."
patterns-established:
  - "Query-module pattern: decode params into typed filters, apply bounded cursor pagination, and keep joins/filters in `AccrueAdmin.Queries.*` instead of LiveViews."
  - "Admin verification pattern: start a test-only repo in `accrue_admin`, migrate against sibling `accrue/priv/repo/migrations`, and assert index presence through `pg_indexes`."
requirements-completed: [ADMIN-07, ADMIN-09, ADMIN-11, ADMIN-13, ADMIN-15, ADMIN-19]
duration: 9m
completed: 2026-04-15
---

# Phase 7 Plan 03: Admin Query Foundation Summary

**Signed cursor-paginated admin query modules and real database indexes for billing and Connect list pages**

## Performance

- **Duration:** 9m
- **Started:** 2026-04-15T17:05:00Z
- **Completed:** 2026-04-15T17:14:14Z
- **Tasks:** 1
- **Files modified:** 16

## Accomplishments

- Added the `AccrueAdmin.Queries.Behaviour` contract plus one query module per Phase 7 billing/account list surface, all grounded in current `accrue` schemas.
- Added signed time/id cursor tokens, bounded page sizes, and invalid-cursor fail-closed behavior so admin list params are resilient to tampering and offset pagination stays banned.
- Added repo-backed admin query tests and the Phase 7 index migration so later `DataTable` and page plans can build on verified query primitives instead of inventing their own data access.

## Task Commits

1. **Task 1: Add admin query contracts and supporting indexes grounded in current schemas** - `8984b04` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/queries/*.ex` - query contract, signed cursor support, and resource-specific list/count/filter logic.
- `accrue/priv/repo/migrations/20260415140000_add_phase7_admin_indexes.exs` - composite and lookup indexes for customer, subscription, invoice, charge, coupon, promotion code, and Connect account list queries.
- `accrue_admin/test/accrue_admin/queries/{cursor_test,query_modules_test}.exs` - cursor integrity, schema-grounded filter coverage, and index existence assertions.
- `accrue_admin/test/support/{test_repo,repo_case}.ex` plus `config/test.exs` and `test/test_helper.exs` - sandboxed repo startup and migration execution for admin package DB tests.

## Decisions Made

- Kept invoice and charge pagination grounded on `inserted_at` while selecting real invoice fields like `number`, `finalized_at`, and `due_date`, matching the plan’s “map drifted columns to executable schema fields” instruction.
- Reused `Accrue.Billing.Query.active/1` semantics for the admin subscription list, which intentionally includes `:trialing` rows in the “active” grouping.
- Verified indexes by querying `pg_indexes` from admin tests instead of relying on migration file inspection alone.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added repo-backed admin test infrastructure for query verification**
- **Found during:** Task 1 verification
- **Issue:** `accrue_admin` had endpoint-focused tests only; there was no sandboxed repo, migration bootstrap, or DB case template to execute the planned query/module verification against real tables.
- **Fix:** Added `AccrueAdmin.TestRepo`, `AccrueAdmin.RepoCase`, test repo config, and migration bootstrapping in `accrue_admin/test/test_helper.exs`.
- **Files modified:** `accrue_admin/config/test.exs`, `accrue_admin/test/test_helper.exs`, `accrue_admin/test/support/test_repo.ex`, `accrue_admin/test/support/repo_case.ex`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/queries/cursor_test.exs test/accrue_admin/queries/query_modules_test.exs --warnings-as-errors`
- **Committed in:** `8984b04`

**2. [Rule 3 - Blocking] Shifted the admin index migration timestamp forward so fresh DB migration order is valid**
- **Found during:** Task 1 verification
- **Issue:** The planned migration filename `20260415090000_add_phase7_admin_indexes.exs` ran before `accrue_connect_accounts` and `accrue_promotion_codes` existed on a fresh database, so migration boot failed with `undefined_table`.
- **Fix:** Moved the migration to `20260415140000_add_phase7_admin_indexes.exs`, after the existing Phase 5/6 table-creation migrations, while keeping the same index payload.
- **Files modified:** `accrue/priv/repo/migrations/20260415140000_add_phase7_admin_indexes.exs`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/queries/cursor_test.exs test/accrue_admin/queries/query_modules_test.exs --warnings-as-errors`
- **Committed in:** `8984b04`

---

**Total deviations:** 2 auto-fixed (2 Rule 3)
**Impact on plan:** Both fixes were required to make the planned query/index work executable and verifiable against a fresh database. No scope creep beyond that.

## Issues Encountered

- The admin package needed its own migrated test repo before query verification was meaningful; otherwise the task would only have compile coverage, not schema/index coverage.
- The original migration timestamp in the plan conflicted with the repo’s existing migration chronology and had to move forward to preserve fresh-DB correctness.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 07-04 can build `DataTable` and list pages on top of stable `AccrueAdmin.Queries.*` modules instead of embedding Ecto logic in LiveViews.
- Later billing/account detail pages can extend the existing query modules with narrower filters and row-shaping without reopening pagination or index design.

## Self-Check: PASSED

- Found `.planning/phases/07-admin-ui-accrue-admin/07-03-SUMMARY.md`
- Found `accrue_admin/lib/accrue_admin/queries/cursor.ex`
- Found `accrue/priv/repo/migrations/20260415140000_add_phase7_admin_indexes.exs`
- Found task commit `8984b04` in git history
