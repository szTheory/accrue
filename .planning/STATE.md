---
gsd_state_version: 1.0
milestone: v1.25
milestone_name: Evidence-bound triad (friction + integrator + billing depth)
status: milestone_planned
last_updated: "2026-04-24T12:00:00.000Z"
last_activity: 2026-04-24
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-24)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** **v1.25** — friction inventory maintainer pass, integrator/proof contract alignment, and **`Accrue.Billing.create_checkout_session`** facade (**Fake** + telemetry). **PROC-08** / **FIN-03** out of scope.

## Current Position

**Milestone:** **v1.25** — Evidence-bound triad

**Phase:** Not started — next **79** (friction inventory maintainer pass)

**Plan:** —

**Status:** Milestone planned — **`REQUIREMENTS.md`** + **`ROADMAP.md`** (Phases **79–81**) + research complete; use **`/gsd-discuss-phase 79`** or **`/gsd-plan-phase 79`**.

**Last activity:** 2026-04-24 — Milestone **v1.25** opened; **`.planning/research/`** refreshed; **`v1.24`** phase trees under **`milestones/v1.24-phases/`**.

## Milestone Progress

**v1.25** (planned): Phases **79–81** — **INV-03**, **BIL-06**, **BIL-07**, **INT-12** (see **`.planning/REQUIREMENTS.md`**).

**v1.24** phases **76–78**: **Archived** **2026-04-24** — execution trees **`milestones/v1.24-phases/`**; archives **`milestones/v1.24-ROADMAP.md`**, **`v1.24-REQUIREMENTS.md`**; tag **`v1.24`**.

**Friction inventory (FRG-01):** `.planning/research/v1.17-FRICTION-INVENTORY.md`  
**North star + stop rules (FRG-02):** `.planning/research/v1.17-north-star.md`

**Last shipped (public packages on Hex):** **`accrue` / `accrue_admin` 0.3.1`** — **v1.19** Phase **68** (publish); **v1.23** Phase **75** (contract pass **2026-04-24**).

## Current Planning Artifacts

- **`.planning/REQUIREMENTS.md`** — **v1.25** requirements (**INV-03**, **INT-12**, **BIL-06**, **BIL-07**)
- **`.planning/ROADMAP.md`** — active **v1.25** phase table (**79–81**)
- **`.planning/research/SUMMARY.md`** — **v1.25** research synthesis (**2026-04-24**)

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| uat_gap | Phase **62** **`62-UAT.md`** | **closed** — **v1.18** |

## Recent Decisions

- **2026-04-24:** **`/gsd-new-milestone` v1.25** — research-first; **`STACK`/`FEATURES`/`ARCHITECTURE`/`PITFALLS`/`SUMMARY`** under **`.planning/research/`**; **`v1.24`** working phases moved to **`milestones/v1.24-phases/`** (evidence preservation).
- **2026-04-24:** **`/gsd-complete-milestone` v1.24** — archives **`milestones/v1.24-*`**, **`git rm` `.planning/REQUIREMENTS.md`**, planning tag **`v1.24`**; **`audit-open`** all clear.

**Next:** **`/gsd-discuss-phase 79`** or **`/gsd-plan-phase 79`** — friction inventory maintainer pass (**INV-03**).

**Completed (prior milestone):** **v1.24** Phases **76–78** — evidence under **`milestones/v1.24-phases/`**.
