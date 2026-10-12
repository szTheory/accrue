---
phase: 246
fixed_at: 2026-10-11T15:34:00-04:00
review_path: .planning/phases/246-collection-controls-and-search/246-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 246: Code Review Fix Report

**Fixed at:** 2026-10-11T15:34:00-04:00  
**Source review:** `.planning/phases/246-collection-controls-and-search/246-REVIEW.md`  
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: Test-mode ordinary seed can run against a remote matching database

**Files modified:** `examples/accrue_host/priv/repo/seeds/ordinary.exs`, `examples/accrue_host/lib/accrue_host/ordinary_seed_boundary.ex`, `examples/accrue_host/test/ordinary_preview_seed_test.exs`  
**Commit:** `9a508f53`  
**Applied fix:** Centralized the seed target predicate. Test mode now requires the actual PostgreSQL server address to parse as IPv4 or IPv6 loopback, alongside the test database name and `postgres` role; development still matches the resolved Compose `db` address. Added direct tests proving loopback acceptance and rejection of a matching test database on a public address, missing address, wrong database, and wrong role.  
**Verification:** `mix test test/ordinary_preview_seed_test.exs:14` — 1 test, 0 failures. Ran in the main checkout against the configured isolated test environment; the test exercises the pure address predicate and does not connect to a remote database. **Status:** fixed: requires human verification of the database-boundary logic.

### WR-01: Overlong search is reported as a no-results search

**Files modified:** `accrue_admin/lib/accrue_admin/components/global_search.ex`, `accrue_admin/test/accrue_admin/components/global_search_test.exs`  
**Commit:** `d1c467cd`  
**Applied fix:** Added a query-too-long state, canceled/invalidate prior in-flight results when it is set, rendered a 100-character limit message, and excluded invalid input from the ordinary no-results state. A subsequent valid query clears the validation state through the existing search path.  
**Verification:** `mix test test/accrue_admin/components/global_search_test.exs` — 21 tests, 0 failures. Ran in the main checkout. **Status:** fixed: requires human verification of the validation and state-transition logic.

## Skipped Issues

None.

---

_Fixed: 2026-10-11T15:34:00-04:00_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
