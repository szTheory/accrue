# Phase 35: Summary surfaces + test literal hygiene — Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning  
**Source:** `.planning/ROADMAP.md`, [`milestones/v1.7-REQUIREMENTS.md`](../../milestones/v1.7-REQUIREMENTS.md) (OPS-04..05), v1.6 **UX-04** / **Copy** precedent

<domain>

## Phase boundary

Add or expand **summary / KPI** rows using **theme tokens** (`--ax-*`, `ax-*`) and documented exceptions per **UX-04** discipline. All **new operator-visible strings** go through **`AccrueAdmin.Copy`** (or established SSOT); **Playwright** and **LiveView** tests must not duplicate divergent literals.

Depends on **Phase 34** (nav and drill baseline so new summaries sit in a coherent shell).

</domain>

<canonical_refs>

## Canonical references

- `../../REQUIREMENTS.md` — OPS-04, OPS-05.
- `accrue_admin` — `AccrueAdmin.Copy`, KPI/summary components (e.g. `KpiCard` pattern), scoped CSS root `html.accrue-admin`.
- Token exception discipline — see v1.6 hierarchy phase notes in git history or any restored `26-theme-exceptions.md`; otherwise document new exceptions in this phase’s `*-PLAN.md` / notes.

</canonical_refs>
