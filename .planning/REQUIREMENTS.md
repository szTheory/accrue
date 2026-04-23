# Requirements: Accrue v1.14

**Defined:** 2026-04-22  
**Milestone:** v1.14 — Companion admin + billing depth  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Research:** Domain research **skipped** for this milestone (brownfield: `accrue_admin` + `accrue` core; integrator/Hex continuity explicitly deferred to a **future** milestone).

**Theme:** Raise **core** companion admin (money-primary flows beyond the v1.13 auxiliary set) on **`AccrueAdmin.Copy`**, **`ax-*` / theme tokens**, and **VERIFY-01** gates—then ship **one** scoped **billing / Stripe** capability expansion with **Fake** regression coverage and **telemetry / guide** alignment. **Not** integrator-doc milestones, **not** release/Hex continuity as a theme, **not** **PROC-08** / **FIN-03**.

---

## Companion admin — core surfaces (ADM)

- [x] **ADM-07**: Publish an inventory of **core** `accrue_admin` mounted surfaces (**customers**, **subscriptions**, **invoices**, **charges**, **webhooks**, **dashboard**, and related detail LiveViews) vs **`AccrueAdmin.Copy`** coverage, **`ax-*` / theme token** discipline, and **VERIFY-01** (Playwright + axe) coverage—explicitly **excluding** the v1.13 auxiliary set already validated (**coupons**, **promotion codes**, **Connect**, **events**). *(Phase 54)*
- [x] **ADM-08**: Burn down **P0** gaps from **ADM-07** on **≥1** money-primary list/detail flow so operator-visible strings route through **`AccrueAdmin.Copy`** (or an established submodule), **`ax-*`/tokens** match **v1.6 UX-04** intent, and **ExUnit** / **Playwright** avoid divergent raw literals on materially touched paths. *(Phase 54)*
- [x] **ADM-09**: Extend **VERIFY-01** with **Playwright + axe** coverage for **≥1** materially changed **core** mounted route group from **ADM-08** work, consistent with **v1.12** / **v1.13** precedent. *(Phase 55)*
- [x] **ADM-10**: Record intentional **theme / layout exceptions** for **ADM-08** / **ADM-09** touches in **`accrue_admin/guides/theme-exceptions.md`** (or successor) with rationale; keep contributor checklist honest. *(Phase 55)*
- [x] **ADM-11**: If **ADM-08** introduces or extends **`AccrueAdmin.Copy`** modules, wire **`mix accrue_admin.export_copy_strings`**, **`copy_strings.json`**, and CI allowlists so literals cannot drift. *(Phase 55)*

---

## Billing / Stripe depth (BIL)

- [x] **BIL-01**: Ship **one** scoped **`Accrue.Billing`** (or adjacent public host API) capability expansion in the **Stripe-first** family—chosen and bounded in **Phase 56** planning—including **Fake-backed** regression coverage for webhook/ingest paths where applicable, and **no** **PROC-08** processor work. *(Phase 56)*
- [x] **BIL-02**: Update **`guides/telemetry.md`** (and **`guides/operator-runbooks.md`** cross-links when revenue-adjacent) for any **new or changed** `:telemetry` / **ops** signals introduced by **BIL-01**; keep catalog rows truthful vs code. *(Phase 56)*

---

## Future milestones (explicitly not v1.14)

- **Integrator / adoption** golden-path, proof-matrix expansion, and repo-root VERIFY-01 doc graph work—**deferred** to a later milestone per maintainer priority.
- **Release / continuity** (next Hex publish cadence, Release Please narrative, `verify_package_docs` / planning mirrors as a milestone theme)—**deferred** to a later milestone.
- **PROC-08** second processor adapter, **FIN-03** app-owned finance exports—remain **non-goals** until a milestone explicitly reopens them.

## Out of Scope

| Item | Reason |
|------|--------|
| Integrator / First Hour / adoption-proof matrix / package-doc milestone themes | **Explicitly later** per v1.14 charter |
| Hex publish + release-train milestone | **Explicitly later** per v1.14 charter |
| Second processor / non-Stripe processor | **PROC-08** remains non-goal |
| App-owned finance / accounting exports | **FIN-03** remains non-goal |
| New third-party UI kits or charting stacks | Same **v1.6** / **v1.12** / **v1.13** UI contract |
| Full gettext / i18n | English SSOT remains sufficient |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADM-07 | Phase 54 | Complete |
| ADM-08 | Phase 54 | Complete |
| ADM-09 | Phase 55 | Complete |
| ADM-10 | Phase 55 | Complete |
| ADM-11 | Phase 55 | Complete |
| BIL-01 | Phase 56 | Complete |
| BIL-02 | Phase 56 | Complete |

**Coverage:**

- v1.14 requirements: **7** total  
- Mapped to phases: **7**  
- Unmapped: **0** ✓

---

*Requirements defined: 2026-04-22 — `/gsd-new-milestone` v1.14.*
