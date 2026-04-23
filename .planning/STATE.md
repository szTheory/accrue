---
gsd_state_version: 1.0
milestone: v1.14
milestone_name: Companion admin + billing depth
status: planning
last_updated: "2026-04-23T02:33:07.654Z"
last_activity: 2026-04-23
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 4
  completed_plans: 2
  percent: 50
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-22)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** **v1.14** — core **`accrue_admin`** Copy / token / VERIFY parity, then one **`Accrue.Billing`** / Stripe depth slice (**Fake** + telemetry docs). Integrator/adoption and release/Hex continuity milestones are **explicitly later**.

## Current Position

Phase: 55

Plan: Not started

**Status:** Ready to plan

**Last activity:** 2026-04-23

## Milestone Progress

**Active:** **v1.14** — Phases **54–56** (see **`.planning/ROADMAP.md`**).

**Last shipped (planning):** **v1.13** — Phases **51–53** (integrator golden path + auxiliary admin parity). Archives: **`.planning/milestones/v1.13-*`**; tag **`v1.13`**.

**Last shipped (public packages on Hex):** **`accrue` / `accrue_admin` 0.3.0** (see **`accrue/mix.exs`** / **`accrue_admin/mix.exs`** **`@version`**).

## Current Planning Artifacts

- **`.planning/REQUIREMENTS.md`** — **v1.14** (**ADM-07..ADM-11**, **BIL-01..BIL-02**)
- **`.planning/ROADMAP.md`** — **v1.14** phase table + shipped milestone history
- **`.planning/PROJECT.md`** — **v1.14** current milestone block
- **`.planning/phases/01-*` … `53-*`** — prior milestone evidence (**`phases.clear` not run**)
- **`.planning/phases/54-core-admin-inventory-first-burn-down/54-CONTEXT.md`** — Phase **54** implementation decisions (**ADM-07** / **ADM-08**)
- **`.planning/phases/55-core-admin-verify-theme-copy-ci/55-CONTEXT.md`** — Phase **55** implementation decisions (**ADM-09** / **ADM-10** / **ADM-11**)

## Deferred Items

**Phase 21 UAT:** metadata row retained for traceability; scenarios are automated / resolved via quick task **260414-l9q** (see `03-HUMAN-UAT.md`).

| Category | Item | Status |
|----------|------|--------|
| uat_gap | Phase 21 — `21-UAT.md` | automated |

## Recent Decisions

- **2026-04-22:** **`/gsd-new-milestone` v1.14** — **Companion admin + billing depth**; **ADM-07..ADM-11**, **BIL-01..BIL-02**; phases **54–56**; brownfield research skipped; **`phases.clear`** skipped (preserve **1–53**).
- **2026-04-23:** **`/gsd-complete-milestone` v1.13** — archives **`milestones/v1.13-*`**, planning tag **`v1.13`**.
- **2026-04-22:** **`/gsd-discuss-phase 54`** — **`core-admin-parity.md`** SSOT, **invoices** ADM-08 anchor, router-derived **11** core rows, VERIFY expansion deferred to Phase **55**.
- **2026-04-23:** **`/gsd-discuss-phase 55`** (all areas + research synthesis) — locked **VERIFY flow ids** (`core-admin-invoices-*`), tiered **PDF/tab/download** merge-blocking contract, **`export_copy_strings`** hybrid + determinism, **`theme-exceptions.md`** SSOT + **`admin_ui.md`** link hygiene (**`55-CONTEXT.md`**).

**Next:** **`/gsd-plan-phase 55`** — core admin VERIFY + theme + copy CI (resume: **`55-CONTEXT.md`**, design: **`55-UI-SPEC.md`**).

**Completed:** Milestone **v1.13** — Phases **51–53**. Prior: **v1.12** — archived (`milestones/v1.12-*`, tag **`v1.12`**).

**Planned Phase:** 55 (Core admin VERIFY + theme + copy CI) — 2 plans — 2026-04-23T02:33:07.621Z
