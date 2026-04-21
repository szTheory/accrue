# Phase 34: Operator home, drill flow + nav model — Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning  
**Source:** `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` (OPS-01..03), [`v1.7-MILESTONE-AUDIT.md`](../../v1.7-MILESTONE-AUDIT.md)

<domain>

## Phase boundary

Ship a **credible default admin home**, **one named cross-entity drill** with fewer dead ends (URL-stable navigation, preserved context where practical), and **nav labels/order** aligned to operator billing mental models—using **Phase 20/21 UI-SPEC** patterns and existing `accrue_admin` layout primitives. **No** new billing APIs, **no** new Stripe object types beyond current admin queries, **no** new third-party UI kits.

Depends on **Phase 33** complete.

</domain>

<canonical_refs>

## Canonical references

- `../../ROADMAP.md` — Phase 34 goals and success criteria.
- `../../REQUIREMENTS.md` — OPS-01, OPS-02, OPS-03.
- [`milestones/v1.6-ROADMAP.md`](../../milestones/v1.6-ROADMAP.md) — v1.6 shipped operator polish; cites Phase 20/21 UI-SPEC paths (use git history or restored `.planning/phases/` trees if files are absent in a sparse checkout).
- `accrue_admin` application — `AccrueAdmin.Router`, layouts, LiveViews, and `priv/static` admin styles (token and `ax-*` conventions).

</canonical_refs>
