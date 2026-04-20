---
status: clean
phase: 28-accessibility-hardening
reviewed: 2026-04-20
depth: quick
---

# Phase 28 — Code review

**Scope:** Step-up focus/dismiss paths, `DataTable` captions, VERIFY-01 Playwright + axe, theme hooks for `data-theme` / `data-theme-target`.

## Findings

None blocking. `StepUp.dismiss_challenge/1` correctly avoids `Events.record/1` and continuation execution. Escape is scoped with `phx-key="escape"`. Axe filter limits to serious/critical impacts.

## Notes

- Host e2e depends on Postgres connection budget; CI uses isolated DB. Local parallel runs may log `too_many_connections` without failing the spec.
