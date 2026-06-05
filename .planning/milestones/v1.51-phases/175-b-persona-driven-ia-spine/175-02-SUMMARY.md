---
phase: 175-b-persona-driven-ia-spine
plan: "02"
subsystem: ui
tags: [phoenix, liveview, elixir, nav, sidebar, attention-counts, hooks, javascript, copy]

requires:
  - phase: 175-01
    provides: Wave-0 scaffold, query extensions, router assertions

provides:
  - AttentionCounts.compute/1 shared context fn (recovery + developer badge counts)
  - NavBadgeHook on_mount/4 (assigns nav_attention_counts post-auth, with DB-error rescue)
  - Nav.items/3 with :badge and :collapsible fields on every item, /payments href
  - AppShell nav_attention_counts attr threaded to Nav.items/3
  - NavBadgeHook registered in router.ex @default_on_mount after AuthHook
  - 4 copy.ex launcher verb relabels per UI-SPEC §7
  - global_search.ex quick-link strings updated to match verb relabels
  - topbar.ex search trigger text updated to "Search customers, invoices… ⌘K"
  - sidebar_collapse.js Phoenix hook (localStorage persistence, mount_path-prefixed key)
  - app.js SidebarCollapse hook registration
  - priv/static JS bundle rebuilt

affects: [175-03, 175-04, sidebar collapse Wave 2, attention badge rendering]

tech-stack:
  added: []
  patterns:
    - "AttentionCounts module: DRY extraction of dashboard badge queries for reuse in on_mount hooks"
    - "NavBadgeHook: on_mount/4 pattern (matches AuthHook contract) with rescue for DB errors"
    - "SidebarCollapse JS hook: mounted/destroyed lifecycle + localStorage with mount_path prefix"
    - "Nav.items/3: backward-compat default arg for optional third param"

key-files:
  created:
    - accrue_admin/lib/accrue_admin/attention_counts.ex
    - accrue_admin/lib/accrue_admin/nav_badge_hook.ex
    - accrue_admin/assets/js/hooks/sidebar_collapse.js
  modified:
    - accrue_admin/lib/accrue_admin/nav.ex
    - accrue_admin/lib/accrue_admin/components/app_shell.ex
    - accrue_admin/lib/accrue_admin/router.ex
    - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/components/global_search.ex
    - accrue_admin/lib/accrue_admin/components/topbar.ex
    - accrue_admin/assets/js/app.js
    - accrue_admin/priv/static/accrue_admin.js
    - accrue_admin/test/accrue_admin/nav_test.exs
    - accrue_admin/test/accrue_admin/live/dashboard_live_test.exs

key-decisions:
  - "AttentionCounts uses try/rescue in NavBadgeHook (not in the module itself) — DB errors degrade to zero counts, never crash nav mount"
  - "Nav.items/2 stays valid via Elixir default arg (attention_counts \\\\ %{}) — no callers broken"
  - "Payments href changed from /charges to /payments in Nav — aligns with IA-06 route reshape"
  - "topbar.ex search trigger text now includes ⌘K inline (removed from separate kbd element visible text, kept the kbd for styling)"
  - "dashboard_live.ex delegates recovery/developer counts to AttentionCounts.compute(nil) — two DB calls become one shared function"
  - "SidebarCollapse localStorage key prefixed ax-sidebar-{mountPath}-{group} to avoid collision across multiple admin mounts"

patterns-established:
  - "AttentionCounts pattern: extract repeated aggregate-count queries to a shared context fn, call from on_mount hooks"
  - "NavBadgeHook pattern: on_mount assigns badge data post-auth; rescue ensures bad DB state can never crash LiveView mount"
  - "SidebarCollapse: pure client-side hook, no pushEvent, uses data-controls attr to find target element by id"

requirements-completed: [IA-01, IA-02]

duration: 18min
completed: 2026-06-04
---

# Phase 175 Plan 02: Attention-Count Pipeline + Nav/Shell Contract Summary

**AccrueAdmin.AttentionCounts shared context fn, NavBadgeHook on_mount, Nav.items/3 badge/collapsible extension, 4 UI-SPEC verb relabels, and SidebarCollapse JS hook wiring the data pipeline for Wave-2 sidebar visuals**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-06-04T04:05:00Z
- **Completed:** 2026-06-04T04:11:00Z
- **Tasks:** 2 (Task 1: TDD; Task 2: auto)
- **Files modified:** 11 + 1 rebuilt static bundle

## Accomplishments

- Created `AccrueAdmin.AttentionCounts.compute/1` — extracts the past-due subscription + blocked-webhook count queries from dashboard_live.ex into a shared fn usable by any on_mount hook
- Created `AccrueAdmin.NavBadgeHook` — post-auth on_mount hook that assigns `:nav_attention_counts` to the socket, with DB-error rescue so nav never crashes on a bad query
- Extended `Nav.items/2` to `items/3` with `:badge` and `:collapsible` fields on every item; Billing zone is always-expanded (collapsible: false), specialist zones (Recovery/Developer/Catalog) are collapsible: true with badge counts
- Updated `Payments` href from `/charges` to `/payments` (IA-06 route reshape)
- Wired `nav_attention_counts` attr through AppShell to Nav.items/3 call; default `%{}` means all existing callers still compile
- Applied 4 exact verb relabels per UI-SPEC §7 to copy.ex and global_search.ex inline quick-links
- Created `sidebar_collapse.js` hook with localStorage persistence and mount_path-prefixed key to avoid collision across multiple admin mounts; registered in app.js; bundle rebuilt

## Task Commits

1. **TDD RED — failing nav tests** - `3953235d` (test)
2. **Task 1: AttentionCounts + NavBadgeHook + Nav/AppShell/Router** - `34c56512` (feat)
3. **Task 2: copy relabels + sidebar_collapse + bundle** - `bc926820` (feat)

## Files Created/Modified

- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/attention_counts.ex` — new shared context fn for badge counts
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/nav_badge_hook.ex` — new on_mount hook assigning nav_attention_counts
- `/Users/jon/projects/accrue/accrue_admin/assets/js/hooks/sidebar_collapse.js` — new JS hook for collapse persistence
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/nav.ex` — items/3 with badge/collapsible + /payments href
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/components/app_shell.ex` — nav_attention_counts attr + threading
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/router.ex` — NavBadgeHook in @default_on_mount
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/dashboard_live.ex` — delegates to AttentionCounts.compute/1
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/copy.ex` — 4 verb relabels
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/components/global_search.ex` — quick-link verb updates
- `/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/components/topbar.ex` — search trigger text update
- `/Users/jon/projects/accrue/accrue_admin/assets/js/app.js` — SidebarCollapse hook registration
- `/Users/jon/projects/accrue/accrue_admin/priv/static/accrue_admin.js` — rebuilt bundle

## Decisions Made

- `AttentionCounts.compute/1` accepts `owner_scope` but ignores it (global counts for now); scoped queries are a future enhancement documented in the module
- DB-error rescue lives in `NavBadgeHook`, not in `AttentionCounts` — keeps the module pure; the hook is the safety boundary
- `Nav.items/2` backward compat preserved via Elixir default args — no existing call site needs updating
- Dashboard `dashboard_stats/0` calls `AttentionCounts.compute(nil)` twice (once for `:recovery`, once for `:developer`) — this results in two DB round-trips; a future optimization can call it once and unpack. Acceptable for v1.0 — the counts are fast aggregate queries on indexed columns
- topbar.ex: the `⌘K` hint is now in the visible trigger text span rather than the separate `<kbd>` element which remains for styling; this matches the UI-SPEC §7 exact string "Search customers, invoices… ⌘K"

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated stale dashboard_live_test.exs assertion**
- **Found during:** Task 2 verification
- **Issue:** `dashboard_live_test.exs:113` asserted `html =~ "Debug webhooks"` — the old developer launcher title. After the verb relabel to "Investigate an incident", the test failed.
- **Fix:** Updated assertion to use `Copy.home_launcher_developer_title()` so it tracks the canonical copy function
- **Files modified:** `accrue_admin/test/accrue_admin/live/dashboard_live_test.exs`
- **Verification:** `mix test test/accrue_admin/live/dashboard_live_test.exs --seed 0` passes (1/1)
- **Committed in:** `bc926820` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — stale test string)
**Impact on plan:** Necessary for test suite to remain green after the planned copy change. No scope creep.

## Issues Encountered

- PostgreSQL "too many connections" error when first running dashboard_live_test; DB connection pool recovered within ~30 seconds without intervention.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. `NavBadgeHook` runs post-auth (after `AuthHook`) — no new trust boundary created. `SidebarCollapse` JS hook reads/writes only `localStorage` client-side state; no server events emitted. Matches the threat model in the plan (T-175-02-01 through T-175-02-SC: all accepted).

## Known Stubs

None — all data flows are wired. `AttentionCounts.compute/1` makes real DB queries. The `_owner_scope` parameter is intentionally ignored (global counts), documented in the module, and noted as a future enhancement.

## Next Phase Readiness

- Wave 2 (sidebar collapse + badge rendering in `sidebar.ex`) can now consume:
  - `nav_attention_counts` assign from NavBadgeHook on every socket
  - `:badge` and `:collapsible` fields on all Nav items
  - `SidebarCollapse` JS hook already registered in the bundle
- No blockers. All Wave-1 data contracts are in place.

---
*Phase: 175-b-persona-driven-ia-spine*
*Completed: 2026-06-04*
