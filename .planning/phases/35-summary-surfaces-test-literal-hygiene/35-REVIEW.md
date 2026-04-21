---
phase: 35
status: clean
reviewer: cursor-agent
depth: quick
updated: 2026-04-21
---

# Phase 35 — Code review

## Scope

Dashboard copy centralization (`AccrueAdmin.Copy`, `DashboardLive`), ExUnit/host tests, Playwright specs, CI smoke, and `copy_dashboard.js` mirror.

## Findings

No blocking or high issues identified in quick review.

- **Copy / HEEx:** Dynamic KPI values still built in the LiveView; only static suffixes and labels moved to `Copy`, matching the plan.
- **JS mirror:** Values are literals duplicated intentionally with a `SYNC` header; PR discipline should keep `copy.ex` and `copy_dashboard.js` aligned (already the project pattern for this phase).

## Residual risk

Low — if `Copy` renames a function, Elixir compile catches test call sites; Playwright/Node rely on the shared module and grep-based acceptance from the plan.

## Verdict

**status: clean** — appropriate for phase goal (literal hygiene + SSOT), no security-sensitive changes.
