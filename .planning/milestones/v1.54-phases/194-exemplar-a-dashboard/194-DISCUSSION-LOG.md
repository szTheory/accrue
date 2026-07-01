# Phase 194: Exemplar A — Dashboard - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-25
**Phase:** 194-exemplar-a-dashboard
**Areas discussed:** Recovery trend, Refine depth, Machine hooks, Healthy empty-state

---

## Recovery trend ("supporting trend" interpretation)

| Option | Description | Selected |
|--------|-------------|----------|
| Keep funnel, move below table | Pure re-order: AtRiskTable above the existing FunnelChart; funnel stays as supporting viz. No new component. | ✓ |
| Funnel below + relabel as supporting | Same re-order plus visual/copy demotion of the funnel. | |
| Replace funnel with time-trend | Build a recovered-vs-lost line chart as the supporting viz (a rebuild). | |

**User's choice:** Keep funnel, move below table
**Notes:** Truest refine-not-rebuild; satisfies SPEC-OVERVIEW's "no chart before the work-queue table" without new plumbing.

---

## Refine depth (Dashboard)

| Option | Description | Selected |
|--------|-------------|----------|
| Conformance + light polish | Machine hooks + light KPI demotion / exception-rail emphasis only where the rubric flags it. | ✓ |
| Conformance hooks only | Add hooks, change nothing visual. | |
| Active visual rework | Broad type-scale/spacing/weight rework. | |

**User's choice:** Conformance + light polish
**Notes:** Light pass to move the judge-graded "exceptions higher-signal than KPIs" cell without risking the zero-regression baseline.

---

## Machine hooks (selector reconciliation)

| Option | Description | Selected |
|--------|-------------|----------|
| Add ax- hooks, keep behavior attr | Additive `data-ax-zone` + `data-ax-command-palette-trigger`; JS untouched. | ✓ |
| Rename to ax- everywhere | Rename `data-command-palette-trigger` across command_palette.js + topbar + dashboard. | |

**User's choice:** Add ax- hooks, keep behavior attr
**Notes:** Lowest-risk, additive; avoids touching the JS hook and a third surface (topbar) in an exemplar phase.

---

## Healthy empty-state

| Option | Description | Selected |
|--------|-------------|----------|
| Refine existing card | Elevate the check-circle card into a deliberate "all clear" hero; stays non-interactive. | ✓ |
| Leave as-is | Only ensure the non-interactive guard holds; no visual change. | |

**User's choice:** Refine existing card
**Notes:** Meets success criterion 1's "prominent healthy empty-state" while honoring the SPEC-OVERVIEW non-interactive guard.

---

## Claude's Discretion

- Exact `data-ax-zone` placement and the precise CSS deltas for KPI demotion / exception emphasis (bounded by "light polish" + no-Tailwind committed-bundle rebuild).
- Whether the empty-rail non-interactive guard is enforced as a new `verify_package_docs.sh` source guard (mirrored into `PackageDocsVerifierTest`) or only as a page-flow Playwright assertion — research confirms what 193 already wired vs. what 194 must add.
- Exact location of the two new `surface_type:"page-flow"` cells relative to `baseline.page-flow.cells.json`.

## Deferred Ideas

- Actual recovered-vs-lost time-trend line chart (a rebuild) — future analytics phase.
- Repo-wide rename of `data-command-palette-trigger` → `data-ax-command-palette-trigger` — dedicated tidy pass.
- Broad Dashboard type-scale/spacing rework — out of scope to protect the baseline.
- Sweeping the overview grammar across other overview pages — Phase 198.
