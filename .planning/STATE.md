---
gsd_state_version: 1.0
milestone: v1.29
milestone_name: milestone
status: planning
last_updated: "2026-04-24T18:15:00.000Z"
last_activity: 2026-04-24 — Phase **87** **INV-06** executed (**`087-01-PLAN.md`**); **v1.28** Phases **86–87** complete.
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-24)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** **v1.28** — Phases **86–87** **Complete** **2026-04-24**; next forcing function is **linked Hex publish** per **`RELEASING.md`**.

## Current Position

**Milestone:** **v1.28** — Next linked publish continuity (**planning milestones 86–87 complete** **2026-04-24**)

**Phase:** **87** — Friction inventory post-publish — **Complete** **2026-04-24**

**Plan:** **`087-01-PLAN.md`** **Complete**

**Status:** **v1.28** **PPX-05..08** + **INV-06** satisfied in **`.planning/REQUIREMENTS.md`** — **`086-VERIFICATION.md`**, **`087-VERIFICATION.md`**, **`### v1.28 INV-06 maintainer pass (2026-04-24)`** in **`v1.17-FRICTION-INVENTORY.md`**.

**Last activity:** 2026-04-25 — Quick task **260425-gr1**: dropped deprecated flat-branding-keys infrastructure (no users to migrate).

## Milestone Progress

**v1.28** (planning **2026-04-24**): Phases **86–87** **Complete** (**`086-VERIFICATION.md`**, **`087-VERIFICATION.md`**); live **`.planning/REQUIREMENTS.md`** (**PPX-05..08**, **INV-06**).

**v1.27** (shipped **2026-04-24**): Phases **84–85** — **CLS-01..03**, **INV-05**; **`milestones/v1.27-phases/`**; archives **`v1.27-ROADMAP.md`**, **`v1.27-REQUIREMENTS.md`**; tag **`v1.27`**.

**Friction inventory (FRG-01):** `.planning/research/v1.17-FRICTION-INVENTORY.md`  
**North star + stop rules (FRG-02):** `.planning/research/v1.17-north-star.md`

**Last shipped (public packages on Hex):** **`accrue` / `accrue_admin` 0.3.1`**

## Current Planning Artifacts

- **`.planning/REQUIREMENTS.md`** — **v1.28** (**PPX-05..08** + **INV-06** complete)
- **`.planning/ROADMAP.md`** — **v1.28** Phases **86–87** + shipped history
- **`086-VERIFICATION.md`** / **`087-VERIFICATION.md`** — **`.planning/milestones/v1.28-phases/`**

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| uat_gap | Phase **62** **`62-UAT.md`** | **closed** — **v1.18** |

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260425-gr1 | Drop deprecated flat-branding-keys infrastructure | 2026-04-25 | 50f80db | [260425-gr1-drop-deprecated-flat-branding-keys-infra](./quick/260425-gr1-drop-deprecated-flat-branding-keys-infra/) |

## Recent Decisions

- **2026-04-24:** **v1.28** opened — **spine B** (**next linked publish** + **INV-06**); **not** **1.0.0** (**spine A**) unless reprioritized.
- **2026-04-24:** **Phase 86** — **PPX-05..08** contract re-verification at **0.3.1** documented in **`086-VERIFICATION.md`** (no new SemVer bump in this pass).
- **2026-04-24:** **Phase 87** — **INV-06** dated maintainer pass **(b)** + **`087-VERIFICATION.md`** closed per **`.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/`**.

**Next:** **v1.28** planning spine **B** closed in-repo — follow **`RELEASING.md`** for the **next linked Hex** publish when ready.

**Completed (v1.28):** Phases **86–87** — **`milestones/v1.28-phases/086-post-publish-contract-alignment/`**, **`087-friction-inventory-post-publish/`**.

**Completed (v1.27):** Phases **84–85** — **`milestones/v1.27-phases/`**.

**Planned Phase:** — **v1.28** planning milestones **86–87** complete **2026-04-24**.
