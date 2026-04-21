---
status: clean
phase: 34
reviewed: 2026-04-21
depth: quick
---

# Phase 34 — Code review

Quick pass over phase-touched Elixir and tests.

## Findings

None blocking.

- **ScopedPath / org URLs:** `ScopedPath.build/4` mirrors prior `scoped_mount_path/4` semantics; invoice and customer links always pass `@current_owner_scope` from the socket (no raw `?org=` concatenation from params alone).
- **KpiCard links:** When `href` is set, `aria_label` is supplied from `DashboardLive` for each card.
- **Nav:** `Nav.items/2` preserves prior `nav_href/3` + `org_slug/1` behavior; ordering change is data-only.

## Residual risks

- Sidebar active-state still uses `current_path == item.href` / prefix match; org-scoped paths must stay aligned with assigns (unchanged from pre-phase behavior).
