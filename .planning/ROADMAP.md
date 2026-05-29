# Roadmap: Accrue v1.46

**Milestone:** v1.46 Maintenance & Closure
**Status:** Planning

## Overview

**2 phases** | **1 requirements mapped** | All covered ✓

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 151 | Maintenance & Triage | 1/3 | In Progress|  |
| 152 | Close v1.46 closure gaps | 2/3 | In Progress|  |

### Phase 152: Close v1.46 closure gaps: @since warnings, verification, Hex publish + tag

**Goal:** Fix all malformed @since annotations, run the Three Zeros closure gate green, and cut the linked 1.3.0 Hex release across all three packages (accrue, accrue_admin, accrue_portal).
**Requirements**: D-01 (target 1.3.0), D-02 (@doc since: fix), D-03 (Three Zeros gate), D-04 (Release Please pipeline)
**Depends on:** Phase 151
**Plans:** 2/3 plans executed

**Wave 1** *(parallel)*

- [x] 152-01-PLAN.md — Fix all 8 @since annotations to canonical @doc since: "1.3.0" (dunning.ex ×7, funnel_chart.ex ×1)
- [x] 152-02-PLAN.md — Run Three Zeros closure gate: mix test/dialyzer/credo/coveralls + all verify_*.sh scripts

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 152-03-PLAN.md — Release PR reconciliation: release-notes.md + CHANGELOG + Release Please PR merge + linked Hex publish

---

## Phase Details

### Phase 151: Maintenance & Triage

**Goal:** Review and address any routine maintenance, dependency updates, or open bugs. Verify that the project remains stable and in a good "done" state.

**Requirements:**

- **MNT-01**: Perform routine issue triage and repository maintenance.

**Plans:** 1/3 plans executed
**Wave 1**

- [x] 151-01-PLAN.md — Resolve webhook caching code-review feedback (ENT-10)
- [ ] 151-02-PLAN.md — Update dependencies across the monorepo

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 151-03-PLAN.md — Execute closure criteria validation and publish

**Success Criteria:**

1. No critical or high-priority bugs remain unaddressed.

## Standing Backlog (FRG-03 anchors)

These items are tracked in the v1.17 Friction Inventory and carried forward to future milestones:

- [INT-10 Phase 63](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63) — Braintree/multi-processor integration
- [BIL-03 Phase 64](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64) — Billing portal configuration
- [ADM-12 Phase 65](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65) — Admin UI role-based access
