---
phase: 197-propagate-list
plan: "06"
status: complete
subsystem: accrue_admin
tags:
  - phase-197
  - list-propagation
  - webhooks
  - events
  - connect
dependency_graph:
  requires:
    - 197-03
  provides:
    - Webhooks LIST propagation with replay semantics preserved
    - Events LIST propagation as an all-ledger page
    - Connect accounts LIST propagation with needs_attention OR lens
  affects:
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
tech_stack:
  added: []
  patterns:
    - PageHeader filter-toolbar slot with DataTable render_filter_toolbar disabled
    - FilterChipBar list_status chips and visible-count copy
    - DataTableNav and ScopedPath owner-scope-safe query links
key_files:
  created:
    - .planning/phases/197-propagate-list/197-06-SUMMARY.md
  modified:
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
    - accrue_admin/lib/accrue_admin/copy/connect.ex
    - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
    - accrue_admin/test/accrue_admin/live/events_live_test.exs
    - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
decisions:
  - Webhooks bare /webhooks canonicalizes to status=failed,dead and keeps replay bulk actions page-local.
  - Events remains an all-ledger default; Admin changes is a quick chip using actor_type=admin.
  - Connect bare /connect canonicalizes to needs_attention=true and uses the Plan 03 OR query lens instead of AND readiness filters.
metrics:
  duration_seconds: 1049
  completed_at: "2026-06-28T17:51:15Z"
  tasks_completed: 3
  files_changed: 7
---

# Phase 197 Plan 06: Webhooks, Events, and Connect LIST Propagation Summary

Webhooks, Events, and Connect accounts now use the locked LIST contract with PageHeader chrome, URL-backed filters, FilterChipBar status rows, owner-safe clear-all links, visible counts, responsive row/card DataTable behavior, and page-specific state copy.

## Tasks Completed

| Task | Result | Commit |
|------|--------|--------|
| 1. Migrate Webhooks to the LIST exemplar while preserving replay | Bare `/webhooks` defaults to `status=failed,dead`, renders Needs replay/All deliveries chips, preserves scoped selection and replay confirmation, and keeps replay side effects guarded through existing detail checks. | `0f0298c7` |
| 2. Migrate Events to the LIST exemplar as an all-ledger page | Bare `/events` remains a full ledger, All ledger is active by default, Admin changes uses `actor_type=admin`, and chip/clear-all links use owner-safe query helpers. | `e9621426` |
| 3. Migrate Connect accounts to the LIST exemplar with needs_attention | Bare `/connect` defaults to `needs_attention=true`, renders Needs attention/All accounts chips, uses the named OR lens, and preserves scoped account detail links. | `e5fa23f5` |

## Verification

| Command | Result |
|---------|--------|
| `cd accrue_admin && mix test test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs` | Passed: 26 tests, 0 failures |
| `cd accrue_admin && mix test test/accrue_admin/queries/query_modules_test.exs --max-failures 3` | Passed: 21 tests, 0 failures |
| `cd accrue_admin && mix test test/accrue_admin/components/page_header_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs` | Passed: 37 tests, 0 failures |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking stale assertions] Updated focused tests for migrated LIST copy**
- **Found during:** Tasks 1, 2, and 3
- **Issue:** Existing assertions still expected legacy subtitles, actor-chip labels, or pre-selection bulk-action visibility after the pages moved to the locked PageHeader/list-status contract.
- **Fix:** Adjusted only the affected focused tests to assert the new contract copy and interaction states.
- **Files modified:** `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs`, `accrue_admin/test/accrue_admin/live/events_live_test.exs`, `accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs`
- **Commits:** `0f0298c7`, `e9621426`, `e5fa23f5`

**2. [Rule 2 - Missing critical contract copy] Aligned Connect result-label copy**
- **Found during:** Task 3
- **Issue:** Connect visible-count copy still used generic `account/accounts` labels rather than the locked `connected account/connected accounts` list contract.
- **Fix:** Updated `connect_accounts_list_result_label_pair/0` to return the contract label pair.
- **Files modified:** `accrue_admin/lib/accrue_admin/copy/connect.ex`
- **Commit:** `e5fa23f5`

## Auth Gates

None.

## Known Stubs

None. The only stub-scan hit was the legitimate Connect search input `placeholder` attribute, which is wired to the copy helper and rendered as expected.

## Threat Flags

None. This plan changed list rendering and query parameters only; it introduced no new endpoints, auth paths, file access patterns, package installs, or schema boundaries.

## TDD Notes

Focused RED runs were used before the task implementations, and each task finished with green focused suites. The task commits are implementation-level atomic commits rather than separate RED/GREEN commits because the executable contract tests already existed from the prior handoff and only stale assertions needed adjustment during migration.

## Self-Check: PASSED

Verified the summary file and all modified source/test files exist. Verified task commits `0f0298c7`, `e9621426`, and `e5fa23f5` are present in git history.
