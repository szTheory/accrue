# Requirements: Accrue — Milestone v1.25

**Defined:** 2026-04-24  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Research:** `.planning/research/SUMMARY.md` (milestone pass **2026-04-24**).

## v1.25 — Evidence-bound triad (friction + integrator + billing depth)

**Goal:** Post–**v1.24**, keep **FRG-01** evidence honest, ship **`Accrue.Billing.create_checkout_session/2`** (**Fake** + **`:telemetry` / span**) mirroring **BIL-04**, and align **telemetry/catalog/changelog** with **integrator proof** artifacts when checkout becomes a documented entry point. **No** **PROC-08** / **FIN-03**.

---

## Friction inventory (INV)

- [x] **INV-03**: Run a **maintainer pass** on **`.planning/research/v1.17-FRICTION-INVENTORY.md`** after **v1.24** ship: either **(a)** add **new sourced** **P1** / **P2** rows (with **`sources`**, **`ci_contract`**, **`integrator_impact`**, stable **`v1.17-P*-***` ids) for friction uncovered on **`main`**, **or** **(b)** publish an explicit **dated maintainer certification** that no new sourced rows were warranted (with pointers to **`verify_package_docs`**, **`verify_adoption_proof_matrix.sh`**, and **VERIFY-01** / **`host-integration`** green on the reviewed SHA). If **(a)** changes row counts, keep **`scripts/ci/verify_v1_17_friction_research_contract.sh`** green with same-PR update.

---

## Integrator path + proof (INT)

- [x] **INT-12**: When **BIL-06** introduces or documents **`Accrue.Billing.create_checkout_session`** on any **merge-blocking** or **golden-path** surface (**First Hour**, **`examples/accrue_host` README**, adoption proof matrix, **VERIFY-01** docs), update **all** coupled verifier needles and **ExUnit** literal harnesses in the **same PR** per **`scripts/ci/README.md`** triage (including **`docs-contracts-shift-left`** members when paths change). If the API ships **without** changing those surfaces in the same milestone, **INT-12** is satisfied by a **signed deferral** in **`81-VERIFICATION.md`** with the exact follow-up milestone hook. **Validated in Phase 81** ([`phases/081-telemetry-truth-integrator-contracts/081-VERIFICATION.md`](phases/081-telemetry-truth-integrator-contracts/081-VERIFICATION.md)).

---

## Billing / Stripe depth (BIL)

- [x] **BIL-06**: Ship **`Accrue.Billing.create_checkout_session/2`** (+ **`!`**) taking **`%Accrue.Billing.Customer{}`** and **keyword/map attrs** aligned with **`Accrue.Checkout.Session`** **except** **`:customer`** (supplied as the first argument). Validate attrs with **`NimbleOptions`**. Delegate to **`Accrue.Checkout.Session.create/1`**. Wrap in **`span_billing(:checkout_session, :create, …)`** with **PII-safe** metadata (no checkout **URL**, **`client_secret`**, or raw attrs blob in telemetry). Include **Fake-backed** **ExUnit** proving happy path + at least one failure class appropriate to the facade (validation or processor error).

- [x] **BIL-07**: Update **`accrue/guides/telemetry.md`** (and **`accrue/guides/operator-runbooks.md`** cross-links when revenue- or support-adjacent) for **`[:accrue, :billing, :checkout_session, :create]`**; keep **`accrue/test/accrue/telemetry/billing_span_coverage_test.exs`** consistent; extend **`accrue/CHANGELOG.md`** for **`accrue`** as applicable. **Validated in Phase 81** ([`phases/081-telemetry-truth-integrator-contracts/081-VERIFICATION.md`](phases/081-telemetry-truth-integrator-contracts/081-VERIFICATION.md)).

---

## Out of Scope

| Item | Reason |
|------|--------|
| **PROC-08** (second processor) | Milestone non-goal per **`.planning/PROJECT.md`**. |
| **FIN-03** (app-owned finance exports) | Milestone non-goal per **`.planning/PROJECT.md`**. |
| **Embedded Checkout UI** inside **`accrue_admin`** | Host-owned web UI; document only. |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INV-03 | Phase 79 | Complete |
| BIL-06 | Phase 80 | Complete |
| BIL-07 | Phase 81 | Pending |
| INT-12 | Phase 81 | Pending |

**Coverage:**

- v1.25 requirements: **4** total  
- Mapped to phases: **4**  
- Unmapped: **0**

---
*Requirements defined: 2026-04-24*  
*Last updated: 2026-04-24 after Phase 80 (`080-VERIFICATION.md`) — BIL-06 complete.*
