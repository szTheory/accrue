# Requirements: Accrue (milestone v1.27)

**Defined:** 2026-04-24  
**Core value (from `PROJECT.md`):** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

## v1.27 requirements

Pre-1.0 **closure narrative**: integrator-visible maintainer posture + SemVer intent, without billing API expansion. **PROC-08** / **FIN-03** stay **out of scope**.

### Closure narrative (docs)

- [x] **CLS-01**: A new integrator landing on the **repository root `README.md`** sees **Maintenance posture** (intake-gated work, link to **`accrue/guides/maturity-and-maintenance.md`**, pointer to **`.planning/PROJECT.md`** non-goals for **PROC-08** / **FIN-03**). The **`accrue/README.md` Start here** list includes **Maturity and maintenance** as a first-class entry.
- [x] **CLS-02**: **`RELEASING.md`** includes **Pre-1.0 closure (maintainer intent)** tying **`0.3.x`** to façade + CI proof boundary and linked-publish discipline. **`accrue/guides/upgrade.md`** includes **Pre-1.0 wrap-up semantics** pointing at **Maturity and maintenance**.
- [x] **CLS-03**: **`accrue/README.md` Stability** states that **`0.x`** is not an open-ended public feature roadmap and points to **Maturity and maintenance**.

### Friction inventory (maintainer)

- [x] **INV-05**: After **CLS-** doc landings, a dated maintainer pass **(b)** on **`.planning/research/v1.17-FRICTION-INVENTORY.md`** (no net-new **FRG-01** rows unless sourced, per **FRG-02** **S1** / **S5**) with falsifiable verifier bundle transcripts in **`.planning/milestones/v1.27-phases/85-friction-inventory-post-closure/085-VERIFICATION.md`** (same family as **INV-03** / **INV-04**). Inventory subsection **`### v1.27 INV-05 maintainer pass (2026-04-24)`** added.

## Future requirements (not v1.27)

*(Unchanged backlog — rank in a later milestone.)*

- Second processor adapter (**PROC-08**)
- App-owned finance exports (**FIN-03**)

## Out of scope (v1.27)

| Item | Reason |
|------|--------|
| **PROC-08** / **FIN-03** implementation | Explicit library non-goals until a future milestone reopens them with boundaries |
| New **`Accrue.Billing`** façade APIs | Closure narrative only — billing depth returns in a deliberate feature milestone |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CLS-01 | Phase 84 | Complete |
| CLS-02 | Phase 84 | Complete |
| CLS-03 | Phase 84 | Complete |
| INV-05 | Phase 85 | Complete |

**Coverage:** v1.27 requirements **4** — mapped **4** — unmapped **0**

---
*Requirements defined: 2026-04-24 (v1.27)*
