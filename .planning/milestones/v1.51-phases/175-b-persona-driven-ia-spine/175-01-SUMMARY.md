---
phase: 175
plan: "01"
subsystem: accrue_admin/queries
tags:
  - query-filtering
  - multi-status
  - test-scaffold
  - wave-0
dependency_graph:
  requires: []
  provides:
    - "Invoices multi-status comma-separated filtering"
    - "Subscriptions multi-status OR-dynamic filtering"
    - "Charges multi-status IN filtering"
    - "event_live_test scaffold (Wave 3 gate)"
    - "router redirect assertions (Wave 2 gate)"
  affects:
    - accrue_admin/lib/accrue_admin/queries/invoices.ex
    - accrue_admin/lib/accrue_admin/queries/subscriptions.ex
    - accrue_admin/lib/accrue_admin/queries/charges.ex
    - accrue_admin/test/accrue_admin/queries/query_modules_test.exs
    - accrue_admin/test/accrue_admin/live/event_live_test.exs
    - accrue_admin/test/accrue_admin/router_test.exs
tech_stack:
  added: []
  patterns:
    - "Ecto dynamic/2 for OR-composed multi-status filter fragments"
    - "String.split(\",\") comma-parse → IN clause for atom/string status columns"
    - "@tag :pending + @tag :skip for Wave-gate scaffold tests"
key_files:
  created:
    - accrue_admin/test/accrue_admin/live/event_live_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/queries/invoices.ex
    - accrue_admin/lib/accrue_admin/queries/subscriptions.ex
    - accrue_admin/lib/accrue_admin/queries/charges.ex
    - accrue_admin/test/accrue_admin/queries/query_modules_test.exs
    - accrue_admin/test/accrue_admin/router_test.exs
decisions:
  - "Invoices: split comma-values → atom list → Ecto IN clause (status is an atom enum)"
  - "Subscriptions: dynamic/2 OR-composition mirrors Billing.Query.* predicate semantics; single-value path routes to named filter_single_status/2 clauses unchanged"
  - "Charges: split comma-values → string list → Ecto IN clause (charge status is plain string)"
  - "Scaffold tests use @tag :skip (not just @tag :pending) so they are excluded by ExUnit default; @tag :pending documents the Wave gate intent"
metrics:
  duration: "4m"
  completed: "2026-06-04"
  tasks_completed: 2
  files_changed: 6
---

# Phase 175 Plan 01: Multi-Status Filtering + Wave-0 Scaffolds Summary

**One-liner:** Extended Invoices/Subscriptions/Charges query modules to accept comma-separated status values via Ecto IN and dynamic OR clauses, and created Wave-0 test scaffolds gating Wave 2 and Wave 3 IA work.

## What Was Built

### Task 1: Extend query modules for multi-status filtering

**Invoices (`accrue_admin/lib/accrue_admin/queries/invoices.ex`)**

Replaced the single-atom `invoice.status == ^String.to_existing_atom(status)` clause with a `filter_status/2` helper that:
- Splits the status string on `","` 
- Single value: converts to atom and uses `=` equality (backward compat)
- Multiple values: converts each to atom and uses Ecto `IN` clause (`status = ANY([:open, :uncollectible])`)
- Retains `rescue ArgumentError -> query` for invalid atom values

**Subscriptions (`accrue_admin/lib/accrue_admin/queries/subscriptions.ex`)**

The existing named-clause dispatch (`filter_status/2` → `Billing.Query.active/past_due/canceling/etc.`) was refactored into:
- `filter_single_status/2` — the original single-value named dispatch (unchanged semantics)
- `status_dynamic/1` — returns an `Ecto.Query.dynamic` fragment that mirrors each `Billing.Query.*` predicate's WHERE conditions inline
- Multi-value `filter_status/2` — splits on `","`, reduces `status_dynamic/1` results with `dynamic(^prev or ^d)`, applies as a single `where` clause

This preserves the exact predicate semantics (e.g. `canceling` checks `cancel_at_period_end + current_period_end > now`) while OR-composing them correctly.

**Charges (`accrue_admin/lib/accrue_admin/queries/charges.ex`)**

Replaced single string equality with `filter_status/2` that:
- Single value: uses `=` equality (backward compat)
- Multiple values: uses `IN` clause with string list (charge status is a plain string, not atom)

**Tests (`test/accrue_admin/queries/query_modules_test.exs`)**

Added a `describe "multi-status filter handling"` block with 9 new tests:
- `decode_filter` pass-through for both Invoices and Subscriptions
- `list/1` no-raise assertions for each module
- Result correctness assertions (open invoice returned, draft excluded; active subs returned)
- Charges single-value backward compat + multi-value no-raise + result correctness

Result: 16 → 16 tests all green (9 new tests added, all pass).

### Task 2: Scaffold missing test files

**`accrue_admin/test/accrue_admin/live/event_live_test.exs`** (new)

Two `@tag :pending @tag :skip` tests documenting the Wave 3 acceptance contract for `EventLive`:
1. `"GET /events/:id renders EventLive detail"` — asserts mount loads event by ID
2. `"EventLive Related card links to source webhook and affected entity"` — asserts RelatedResources wiring

**`accrue_admin/test/accrue_admin/router_test.exs`** (extended)

New `describe "/charges redirects"` block with two `@tag :pending @tag :skip` tests as the Wave 2 gate:
1. `"GET /billing/charges redirects 302 to /billing/payments"` — asserts conn.status == 302 + location header
2. `"GET /billing/charges/:id redirects 302 to /billing/payments/:id"` — same pattern for detail route

Overall: 24 tests, 0 failures, 4 skipped (the pending scaffold tests).

## Deviations from Plan

### Auto-decisions (no architectural change)

**1. [Rule 2 - Missing] Added @tag :skip alongside @tag :pending**
- **Found during:** Task 2
- **Issue:** ExUnit does not natively skip `:pending` tagged tests — only `:skip` is excluded by default. Plan said "tagged @tag :pending" but without `ExUnit.configure(exclude: [:pending])` in test_helper.exs, the `flunk` body would run and fail.
- **Fix:** Added both `@tag :pending` (documents Wave intent) and `@tag :skip` (makes ExUnit actually skip them). Zero behavior change to production code.
- **Files modified:** event_live_test.exs, router_test.exs

**2. [Rule 1 - Bug] Removed stale `rescue ArgumentError` from Invoices filter_query**
- **Found during:** Task 1 refactor
- **Issue:** The original `filter_query/2` had `rescue ArgumentError -> query` at the function-body level (lines 135-137). After extracting the atom conversion into `filter_status/2` with its own rescue, the outer rescue was redundant and could mask unrelated errors in other filter clauses.
- **Fix:** Removed the outer rescue; the rescue is now scoped inside `filter_status/2` where it belongs.
- **Files modified:** accrue_admin/lib/accrue_admin/queries/invoices.ex

## Known Stubs

None — no UI-facing placeholder text or empty data sources introduced in this plan.

## Threat Surface Scan

| Flag | File | Description |
|------|------|-------------|
| T-175-01-01 (mitigated) | invoices.ex | Comma-split atoms wrapped in `String.to_existing_atom/1` + `rescue ArgumentError`; no new SQL injection surface (Ecto parameterized queries). |
| T-175-01-02 (accepted) | subscriptions.ex | Multi-status dynamic OR does not change scope_query/2 ordering; owner scope is applied before filter_query. |

No new unplanned threat surface.

## Self-Check: PASSED

Files exist:
- FOUND: accrue_admin/lib/accrue_admin/queries/invoices.ex
- FOUND: accrue_admin/lib/accrue_admin/queries/subscriptions.ex
- FOUND: accrue_admin/lib/accrue_admin/queries/charges.ex
- FOUND: accrue_admin/test/accrue_admin/queries/query_modules_test.exs
- FOUND: accrue_admin/test/accrue_admin/live/event_live_test.exs
- FOUND: accrue_admin/test/accrue_admin/router_test.exs

Commits exist:
- FOUND: 8b3059b2 (Task 1 — multi-status query extension)
- FOUND: 6764d837 (Task 2 — scaffold test files)
