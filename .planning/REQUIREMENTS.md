# Requirements: Accrue v1.13

**Defined:** 2026-04-22  
**Milestone:** v1.13 — Integrator path + secondary admin parity  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

Milestone theme: **first-time integrator golden path** (host-facing docs, proof matrix, package-doc verifiers) plus **auxiliary `accrue_admin` LiveViews** (**coupons**, **promotion codes**, **Connect accounts**, **events**) raised to the **v1.6 / v1.12** bar for **`AccrueAdmin.Copy`**, **`ax-*` / theme tokens**, and **VERIFY-01** — **not** **PROC-08**, **FIN-03**, new third-party UI kits, or core billing schema changes.

---

## Integrator path (INT)

- [x] **INT-01**: A net-new Phoenix integrator can follow **one coherent golden path** from canonical repo entry through install, first Fake-backed subscription (or documented equivalent), and **VERIFY-01-class** proof **without contradictory commands or version pins** across **`examples/accrue_host/README.md`**, **`accrue/guides/first_hour.md`**, and **`accrue/guides/quickstart.md`** (plus any explicitly linked host tutorial sections).
- [x] **INT-02**: **VERIFY-01** and **merge-blocking vs advisory** verification lanes remain discoverable within the **documented hop budget** from the **repository root** (maintain or improve **v1.7 ADOPT** intent); stable anchors exist for CI job names vs human docs where ambiguity regressed.
- [x] **INT-03**: Troubleshooting / **“when it fails first”** docs cover the **highest-frequency first-run classes** (webhook signing / raw body ordering, missing or wrong secrets, **`mix accrue.install`** rerun + conflict sidecars) with **linkable headings** suitable from installer output and host README.
- [ ] **INT-04**: **`examples/accrue_host/docs/adoption-proof-matrix.md`** (and **`evaluator-walkthrough-script.md`** where impacted) stay **honest and current** relative to the golden path and CI lanes touched by **INT-01..INT-03**; any new or renamed lanes are reflected in **merge-blocking verifier** expectations where applicable.
- [ ] **INT-05**: **`verify_package_docs`**, package READMEs, and **ExDoc** install snippets remain aligned with the published **Hex `0.3.0`** pair after doc edits (**`accrue/mix.exs`** / **`accrue_admin/mix.exs`** **`@version`** remains numeric SSOT for the next bump).

---

## Auxiliary admin surfaces (AUX)

- [x] **AUX-01**: **`CouponsLive`** / **`CouponLive`** operator-visible English routes through **`AccrueAdmin.Copy`** (or an established copy submodule); **ExUnit** + **Playwright** do not assert divergent raw literals for strings governed by that SSOT on materially touched paths.
- [x] **AUX-02**: **`PromotionCodesLive`** / **`PromotionCodeLive`** meet the same **AUX-01** copy + test literal discipline.
- [x] **AUX-03**: **`ConnectAccountsLive`** / **`ConnectAccountLive`** meet the same **AUX-01** copy + test literal discipline.
- [x] **AUX-04**: **`EventsLive`** meets the same **AUX-01** copy + test literal discipline for operator-visible strings on materially touched paths.
- [x] **AUX-05**: All **v1.13**-touched auxiliary surfaces use **`ax-*` layout primitives and theme tokens** per **v1.6 UX-04**; intentional CSS/token exceptions are recorded in **`accrue_admin/guides/theme-exceptions.md`** (or successor register) with rationale.
- [x] **AUX-06**: Every **materially touched mounted-admin path** for **AUX-01..AUX-04** gains or extends **VERIFY-01** **Playwright** coverage and **axe** expectations consistent with **v1.12** precedent (reuse export/copy machinery where it reduces drift).

---

## Later milestones (not v1.13)

- **PROC-08** second processor adapter, **FIN-03** app-owned finance exports — remain **future milestone** candidates until explicitly scoped.
- **Stripe Dashboard** meter setup UX — remains host/Stripe documentation unless a future requirement pulls UI scope in.

## Out of Scope

| Item | Reason |
|------|--------|
| New billing domain primitives or migrations | v1.13 is **docs + auxiliary admin presentation + gates** |
| Second processor / non-Stripe processor work | **PROC-08** remains non-goal |
| App-owned finance / accounting exports | **FIN-03** remains non-goal |
| New third-party UI kits or charting stacks | Same **v1.6** / **v1.12** UI contract |
| Full gettext / i18n | Not required for English SSOT milestone |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INT-01 | Phase 51 | Complete |
| INT-02 | Phase 51 | Complete |
| INT-03 | Phase 51 | Complete |
| INT-04 | Phase 52 | Pending |
| INT-05 | Phase 52 | Pending |
| AUX-01 | Phase 52 | Complete |
| AUX-02 | Phase 52 | Complete |
| AUX-03 | Phase 53 | Complete |
| AUX-04 | Phase 53 | Complete |
| AUX-05 | Phase 53 | Complete |
| AUX-06 | Phase 53 | Complete |

**Coverage:**

- v1.13 requirements: **11** total  
- Mapped to phases: **11**  
- Unmapped: **0** ✓

---
*Requirements defined: 2026-04-22*  
*Last updated: 2026-04-22 after Phase 51 execution*
