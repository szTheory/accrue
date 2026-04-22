# Requirements: Accrue — v1.12 Admin & operator UX

**Defined:** 2026-04-22  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

## v1.12 Requirements

Scope is **`accrue_admin` LiveView operator surfaces**, navigation, and **VERIFY-01 / Playwright** extensions for touched admin paths — **not** **PROC-08**, **FIN-03**, new third-party UI kits, or core billing schema / processor abstraction changes unless a phase plan documents an unavoidable minimal hook (discouraged).

### Admin & operator surfaces (ADM)

- [x] **ADM-01**: Operators landing on the **default admin home** (or the phase-scoped entry surface) see at least one **credible metering- or usage-adjacent signal** (counts, recent failures, or deep link into an existing index such as webhooks/meter-related surfaces) consistent with shipped **v1.10** semantics and existing **telemetry / runbook** narratives — **no** new accounting semantics.
- [ ] **ADM-02**: At least **one** high-traffic **list or detail** flow (e.g. customer ↔ subscription ↔ invoice) is measurably smoother: fewer dead ends, clearer next actions, or preserved context — scoped in the phase plan to **concrete LiveView routes**.
- [ ] **ADM-03**: If this milestone adds or renames **primary admin navigation** entries, **labels and ordering** stay aligned with the operator mental model (**billing nouns**, not internal module names), and maintainer-facing **route matrix / README Admin routes** inventory is updated where it would otherwise drift.
- [ ] **ADM-04**: All **new or changed user-visible admin strings** introduced in **v1.12** go through **`AccrueAdmin.Copy`** (or an existing copy SSOT module) so **ExUnit** and **Playwright** do not depend on duplicate divergent literals.
- [ ] **ADM-05**: New or expanded **summary / KPI / card** rows touched in **v1.12** use **`ax-*` layout primitives and theme tokens**; any **intentional** color exceptions are documented in phase notes per **v1.6 UX-04** discipline.
- [ ] **ADM-06**: **VERIFY-01** merge-blocking vs **advisory** Stripe lane semantics remain unchanged; every **mounted-admin path materially touched** by **v1.12** gains or extends **Playwright** coverage and **axe** expectations consistent with **v1.6 / v1.7** precedent (extend existing specs where possible).

## Future (not v1.12)

- **PROC-08** second processor adapter, **FIN-03** app-owned finance exports — remain **future milestone** candidates until explicitly scoped.
- **Stripe Dashboard** meter setup UX — remains host/Stripe documentation unless a future requirement pulls UI scope in.

## Out of Scope

| Item | Reason |
|------|--------|
| New third-party UI kits or charting stacks | Same bar as **v1.6** — Phase **20/21** UI contracts. |
| Core billing API, schema, or processor changes | **v1.12** is operator presentation + verification gates. |
| Full WCAG audit of every admin string | Targeted updates for **touched** surfaces only (**ADM-06**). |
| Hex version bumps as part of milestone execution | Release tagging ships on maintainer schedule, not planning artifact edits. |

## Traceability

| Requirement | Phase | Status |
|---------------|-------|--------|
| ADM-01 | Phase 48 | Complete |
| ADM-02 | Phase 49 | Pending |
| ADM-03 | Phase 49 | Pending |
| ADM-04 | Phase 50 | Pending |
| ADM-05 | Phase 50 | Pending |
| ADM-06 | Phase 50 | Pending |

**Coverage:**

- v1.12 requirements: **6** total  
- Mapped to phases: **6**  
- Unmapped: **0**

---
*Requirements defined: 2026-04-22*  
*Last updated: 2026-04-22 after `/gsd-new-milestone` (roadmap)*
