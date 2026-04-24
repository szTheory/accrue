# Roadmap: Accrue

## Milestones

- ✅ **v1.19 Release continuity + proof resilience** — Phases **67–69** complete **2026-04-24**. **PRF-01..02**, **REL-01..03**, **DOC-01..02**, **HYG-01**; proof contracts, **0.3.1** Hex publish, integrator + planning mirrors (**no** **PROC-08** / **FIN-03**). Requirements: [`.planning/REQUIREMENTS.md`](REQUIREMENTS.md).
- ✅ **v1.18 Onboarding confidence** — Phase **66** shipped **2026-04-23**. **UAT-01..UAT-05**, **PROOF-01**; proof-first confidence after **v1.17** (**no** **PROC-08** / **FIN-03**). Archives: [`milestones/v1.18-ROADMAP.md`](milestones/v1.18-ROADMAP.md), [`milestones/v1.18-REQUIREMENTS.md`](milestones/v1.18-REQUIREMENTS.md). Phase **66** tree: [`milestones/v1.18-phases/66-onboarding-confidence/`](milestones/v1.18-phases/66-onboarding-confidence/). **v1.17** phase working trees: [`.planning/milestones/v1.17-phases/`](milestones/v1.17-phases/).
- ✅ **v1.17 Friction-led developer readiness** — Phases **62–65** shipped **2026-04-23**. **FRG-01..FRG-03**, **INT-10**, **BIL-03**, **ADM-12**: triage-led **P0** closure across integrator/VERIFY/docs, billing, or admin — **no** **PROC-08** / **FIN-03**. Archives: [`milestones/v1.17-ROADMAP.md`](milestones/v1.17-ROADMAP.md), [`milestones/v1.17-REQUIREMENTS.md`](milestones/v1.17-REQUIREMENTS.md). Phase trees archived: [`milestones/v1.17-phases/`](milestones/v1.17-phases/).
- ✅ **v1.16 Integrator + proof continuity** — Phases **59–61** shipped **2026-04-23**. **INT-06..INT-09**: golden path + **quickstart** coherence post-**v1.15**; adoption proof matrix + evaluator + **`scripts/ci/README`** verifier map; repo-root **VERIFY-01** hop budget; **`verify_package_docs`** / **`first_hour`** / planning mirrors vs **`@version`**. Archives: [`milestones/v1.16-ROADMAP.md`](milestones/v1.16-ROADMAP.md), [`milestones/v1.16-REQUIREMENTS.md`](milestones/v1.16-REQUIREMENTS.md).
- ✅ **v1.15 Release / trust semantics** — Phases **57–58** shipped **2026-04-23**. **TRT-01..TRT-04**: **`upgrade.md`** baseline + **Hex vs `.planning/`** clarity (**`RELEASING.md`**, root **`README.md`**); demo **`Sigra` vs `Accrue.Auth`** callout (**`examples/accrue_host/README.md`**); **`accrue/README.md`** stability + **`RELEASING`** appendix pointer; **`verify_package_docs`** aligned to **`accrue_admin/mix.exs`**. Archives: [`milestones/v1.15-ROADMAP.md`](milestones/v1.15-ROADMAP.md), [`milestones/v1.15-REQUIREMENTS.md`](milestones/v1.15-REQUIREMENTS.md).
- ✅ **v1.14 Companion admin + billing depth** — Phases **54–56** shipped **2026-04-23**. Core admin **`AccrueAdmin.Copy`** / **`ax-*`** / **VERIFY-01** on invoice money-primary spine + **`Accrue.Billing.list_payment_methods`** (**Fake**, **`guides/telemetry.md`**). Integrator/adoption + release/Hex continuity **deferred**. Archives: [`milestones/v1.14-ROADMAP.md`](milestones/v1.14-ROADMAP.md), [`milestones/v1.14-REQUIREMENTS.md`](milestones/v1.14-REQUIREMENTS.md).
- ✅ **v1.13 Integrator path + secondary admin parity** — Phases **51–53** shipped **2026-04-23**. Golden-path docs + adoption proof alignment; auxiliary admin (**coupons**, **promotion codes**, **Connect**, **events**) **`AccrueAdmin.Copy`** + **`ax-*`** + **VERIFY-01**. Archives: [`milestones/v1.13-ROADMAP.md`](milestones/v1.13-ROADMAP.md), [`milestones/v1.13-REQUIREMENTS.md`](milestones/v1.13-REQUIREMENTS.md).
- ✅ **v1.12 Admin & operator UX** — Phases **48–50** shipped **2026-04-22**. Post-metering admin signals, drill/nav polish, **`AccrueAdmin.Copy`** + token discipline, VERIFY-01 / Playwright on touched routes. Archives: [`milestones/v1.12-ROADMAP.md`](milestones/v1.12-ROADMAP.md), [`milestones/v1.12-REQUIREMENTS.md`](milestones/v1.12-REQUIREMENTS.md).
- ✅ **v1.11 Public Hex release + post-release continuity** — Phases **46–47** shipped **2026-04-22**. Linked **`accrue`** / **`accrue_admin`** **0.3.0** on Hex; **`RELEASING.md`**, **`first_hour`**, **`verify_package_docs`**, and planning mirrors aligned. Archives: [`milestones/v1.11-ROADMAP.md`](milestones/v1.11-ROADMAP.md), [`milestones/v1.11-REQUIREMENTS.md`](milestones/v1.11-REQUIREMENTS.md).
- ✅ **v1.0 Initial Release** — Phases 1-9 shipped on 2026-04-16. Public Hex packages: `accrue` 0.1.2 and `accrue_admin` 0.1.2. Full archive: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md).
- ✅ **v1.1 Stabilization + Adoption** — Phases 10-12 plus 11.1 shipped on 2026-04-17. Proved Accrue in a realistic Phoenix host app, promoted that proof into CI, closed host-flow hermeticity gaps, and hardened first-user DX/docs. Full archive: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md).
- ✅ **v1.2 Adoption + Trust** — Phases 13-17 shipped on 2026-04-17. Polished the canonical local demo/tutorial, adoption front door, trust evidence, expansion recommendation, and final milestone cleanup. Full archive: [`milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md).
- ✅ **v1.3 Tax + Organization Billing** — Phases 18-22 shipped on 2026-04-17. Stripe Tax, Sigra-first organization billing, admin/host UX proof, and Stripe-native finance handoff documentation. Full archive: [`milestones/v1.3-ROADMAP.md`](milestones/v1.3-ROADMAP.md).
- ✅ **v1.4 Ecosystem stability + demo visuals** — Phase 23 shipped 2026-04-17. `lattice_stripe` lockfiles verified on latest 1.1.x; Fake-backed Playwright screenshot walkthrough documented and scripted; admin `priv/static` bundle fixed for browser LiveView. **PROC-08 deferred.**
- ✅ **v1.5 Adoption proof hardening** — Phase 24 shipped 2026-04-18. Adoption proof matrix + evaluator walkthrough script; README VERIFY-01 contract extended; CI job display name clarifies Stripe test mode; cross-links in `accrue/guides/testing.md` and `guides/testing-live-stripe.md`. Full archive: [`milestones/v1.5-ROADMAP.md`](milestones/v1.5-ROADMAP.md).
- ✅ **v1.6 Admin UI / UX polish + audit gap closure** — Phases **25–31**: core admin polish shipped **2026-04-20**; post-ship Phases **30–31** closed strict audit corpus + advisory integration alignment **2026-04-21**. Archives: [`milestones/v1.6-ROADMAP.md`](milestones/v1.6-ROADMAP.md), [`milestones/v1.6-REQUIREMENTS.md`](milestones/v1.6-REQUIREMENTS.md), [`milestones/v1.6-MILESTONE-AUDIT.md`](milestones/v1.6-MILESTONE-AUDIT.md).
- ✅ **v1.7 Adoption DX + operator admin depth** — Phases **32–36** shipped **2026-04-21**. VERIFY-01 + doc graph, installer and CI clarity, operator home/drill/nav, dashboard `AccrueAdmin.Copy` SSOT, audit corpus + verifier ownership map. Archives: [`milestones/v1.7-ROADMAP.md`](milestones/v1.7-ROADMAP.md), [`milestones/v1.7-REQUIREMENTS.md`](milestones/v1.7-REQUIREMENTS.md), [`milestones/v1.7-MILESTONE-AUDIT.md`](milestones/v1.7-MILESTONE-AUDIT.md).
- ✅ **v1.8 Org billing recipes & host integration depth** — Phases **37–39** shipped **2026-04-22**. Delivers deferred **ORG-04**. Archives: [`milestones/v1.8-ROADMAP.md`](milestones/v1.8-ROADMAP.md), [`milestones/v1.8-REQUIREMENTS.md`](milestones/v1.8-REQUIREMENTS.md).
- ✅ **v1.9 Observability & operator runbooks** — Phases **40–42** shipped **2026-04-22**. Full archive: [`milestones/v1.9-ROADMAP.md`](milestones/v1.9-ROADMAP.md), [`milestones/v1.9-REQUIREMENTS.md`](milestones/v1.9-REQUIREMENTS.md). Gap audit (research): [`research/v1.9-TELEMETRY-GAP-AUDIT.md`](research/v1.9-TELEMETRY-GAP-AUDIT.md).
- ✅ **v1.10 Metered usage + Fake parity** — Phases **43–45** shipped **2026-04-22**. **MTR-01..MTR-08** complete. Full archive: [`milestones/v1.10-ROADMAP.md`](milestones/v1.10-ROADMAP.md), [`milestones/v1.10-REQUIREMENTS.md`](milestones/v1.10-REQUIREMENTS.md). Spike (research): [`research/v1.10-METERING-SPIKE.md`](research/v1.10-METERING-SPIKE.md).

## Phases

### v1.19 Release continuity + proof resilience (Phases 67–69)

**Milestone goal:** Close **v1.17-P1-001**-class drift between **`adoption-proof-matrix.md`** and **`verify_adoption_proof_matrix.sh`**, ship **`accrue` / `accrue_admin` 0.3.1** to Hex, then align **First Hour**, **`verify_package_docs`**, and **`.planning/`** public-Hex callouts — **no** **PROC-08** / **FIN-03**.

**Depends on:** **v1.18** shipped; **v1.18** verification history under [`milestones/v1.18-phases/66-onboarding-confidence/`](milestones/v1.18-phases/66-onboarding-confidence/).

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 67 | Proof contracts | **Complete 2026-04-24** (1/1 plans; see [`phases/67-proof-contracts/67-VERIFICATION.md`](phases/67-proof-contracts/67-VERIFICATION.md)). | PRF-01, PRF-02 |
| 68 | Release train | **Complete 2026-04-24** (2/2 plans; see [`phases/68-release-train/68-VERIFICATION.md`](phases/68-release-train/68-VERIFICATION.md)). | REL-01, REL-02, REL-03 |
| 69 | Doc + planning mirrors | **Complete 2026-04-24** (2/2 plans; see [`phases/69-doc-planning-mirrors/69-VERIFICATION.md`](phases/69-doc-planning-mirrors/69-VERIFICATION.md)). | DOC-01, DOC-02, HYG-01 |

**Success criteria (milestone):**

1. **PRF-01..02**, **REL-01..03**, **DOC-01..02**, and **HYG-01** satisfied per **`.planning/REQUIREMENTS.md`** with phase verification artifacts.
2. Merge-blocking **`verify_package_docs`**, **`host-integration`**, and **VERIFY-01** contracts stay green through the publish line.
3. No **PROC-08** / **FIN-03** scope creep.

<details>
<summary>✅ v1.18 Onboarding confidence (Phase 66) — SHIPPED 2026-04-23</summary>

**Milestone goal:** Close deferred **Phase 62** human UAT confidence gaps (**UAT-01..UAT-05**) using the archived scenario baseline, then run a tight **adoption proof matrix / walkthrough / verifier** alignment pass (**PROOF-01**) — **no** new billing primitives and **no** **PROC-08** / **FIN-03**.

**Depends on:** **v1.17** shipped; **v1.17** phase artifacts under [`.planning/milestones/v1.17-phases/`](milestones/v1.17-phases/) (including archived **`62-UAT.md`**).

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 66 | Deferred UAT + evaluator proof | **Complete 2026-04-23** (3/3 plans; see [`milestones/v1.18-phases/66-onboarding-confidence/66-VERIFICATION.md`](milestones/v1.18-phases/66-onboarding-confidence/66-VERIFICATION.md)). | UAT-01, UAT-02, UAT-03, UAT-04, UAT-05, PROOF-01 |

**Success criteria (milestone):**

1. **UAT-01..UAT-05** and **PROOF-01** satisfied per archived **`.planning/milestones/v1.18-REQUIREMENTS.md`** with evidence in **`66-VERIFICATION.md`** (or cited automation paths).
2. Merge-blocking **`verify_package_docs`**, **`host-integration`**, and **VERIFY-01** contracts stay coherent with any doc or script edits.
3. No **PROC-08** / **FIN-03** scope creep.

**Archives:** [`milestones/v1.18-ROADMAP.md`](milestones/v1.18-ROADMAP.md), [`milestones/v1.18-REQUIREMENTS.md`](milestones/v1.18-REQUIREMENTS.md).

### Phase 66: Deferred UAT + evaluator proof

**Goal:** Replace “pending human UAT” with explicit **pass / automated / signed defer** outcomes for the **v1.17** friction milestone confidence spine, plus evaluator-facing proof alignment.

**Requirements:** UAT-01, UAT-02, UAT-03, UAT-04, UAT-05, PROOF-01

**Success criteria:**

1. **`66-VERIFICATION.md`** exists under **`.planning/milestones/v1.18-phases/66-onboarding-confidence/`** and tables every **UAT-** / **PROOF-** row with closure status + proof links.
2. **`STATE.md`** no longer lists the **v1.17** Phase **62** UAT gap as an open deferred item unless a row is explicitly signed **out of v1.18** with rationale.

</details>

<details>
<summary>✅ v1.17 Friction-led developer readiness (Phases 62–65) — SHIPPED 2026-04-23</summary>

**Milestone goal:** Rank **where Phoenix integrators still stall**, then close **P0** items per axis — **integrator / VERIFY / docs** (**INT-10**), **billing** (**BIL-03**), **admin/operator** (**ADM-12**) — or **certify none** with signed rationale. Avoid broad continuity sweeps without **FRG-01** evidence.

**Depends on:** **v1.16** shipped (**INT-06..INT-09**); merge-blocking **`host-integration`** + **`verify_package_docs`** baseline unchanged unless a **P0** row explicitly revises it with verifier + doc updates together.

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 62 | Friction triage + north star | Ranked inventory (**FRG-01**), north star + stop rules (**FRG-02**), scoped backlog for **63–65** (**FRG-03**). | FRG-01, FRG-02, FRG-03 |
| 63 | P0 integrator / VERIFY / docs | Close every **P0** row tagged integrator/VERIFY/docs from **FRG-03**, or downgrade with rationale; keep merge-blocking contracts green. **Complete 2026-04-23** (3/3 plans; see [`milestones/v1.17-phases/63-p0-integrator-verify-docs/63-VERIFICATION.md`](milestones/v1.17-phases/63-p0-integrator-verify-docs/63-VERIFICATION.md)). | INT-10 |
| 64 | P0 billing | Close every **P0** row tagged billing from **FRG-03**, or certify none; **Fake** + telemetry/docs/changelog alignment on code changes. **Complete 2026-04-23** (1/1 plans; see [`milestones/v1.17-phases/64-p0-billing/64-VERIFICATION.md`](milestones/v1.17-phases/64-p0-billing/64-VERIFICATION.md)). | BIL-03 |
| 65 | P0 admin / operator | Close every **P0** row tagged admin from **FRG-03**, or certify none; scoped **LiveView** / **Copy** / **VERIFY-01** on touched routes. **Complete 2026-04-23** (1/1 plans; see [`milestones/v1.17-phases/65-p0-admin-operator/65-VERIFICATION.md`](milestones/v1.17-phases/65-p0-admin-operator/65-VERIFICATION.md)). | ADM-12 |

**Success criteria (milestone):**

1. **FRG-01..FRG-03**, **INT-10**, **BIL-03**, and **ADM-12** satisfied per **`.planning/REQUIREMENTS.md`** with committed artifacts (inventory path live in **`.planning/STATE.md`**).
2. **`bash scripts/ci/verify_package_docs.sh`** green on **`main`** after any doc or snippet change in this milestone.
3. No **PROC-08** / **FIN-03** scope creep.

### Phase 62: Friction triage + north star

**Goal:** Evidence-ranked inventory + written stop rules + execution backlog for Phases **63–65**.

**Requirements:** FRG-01, FRG-02, FRG-03

**Success criteria:**

1. **FRG-01** — Inventory committed under **`.planning/`** with P0/P1/P2 + sources + deferrals; path recorded in **`.planning/STATE.md`**.
2. **FRG-02** — North star + diminishing-returns stop rules linked from **`.planning/PROJECT.md`** and **`.planning/STATE.md`**.
3. **FRG-03** — Every **P0** row from **FRG-01** maps to **INT-10**, **BIL-03**, or **ADM-12** in the backlog **or** is explicitly out of **v1.17** with rationale.

### Phase 63: P0 integrator / VERIFY / docs

**Goal:** Burn integrator/VERIFY/docs **P0** rows; no silent contract drift.

**FRG-03 slice:** [INT-10 P0 backlog](research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63)

**Requirements:** INT-10

**Success criteria:**

1. **INT-10** satisfied per **`.planning/REQUIREMENTS.md`**.
2. Merge-blocking **VERIFY-01** / **`host-integration`** / **`verify_package_docs`** semantics stay coherent with committed README + verifier changes.

### Phase 64: P0 billing

**Goal:** Burn billing **P0** rows with library-grade regressions and honest operator docs.

**FRG-03 slice:** [BIL-03 backlog anchor](research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64) *(empty P0 queue this milestone — see inventory)*

**Requirements:** BIL-03

**Success criteria:**

1. **BIL-03** satisfied per **`.planning/REQUIREMENTS.md`**.
2. No **PROC-08**; any public **`Accrue.Billing`** surface change ships **Fake** coverage and doc/telemetry/changelog alignment as applicable.

### Phase 65: P0 admin / operator

**Goal:** Burn admin **P0** rows without new third-party UI kits.

**FRG-03 slice:** [ADM-12 backlog anchor](research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65) *(empty P0 queue this milestone — see inventory)*

**Requirements:** ADM-12

**Success criteria:**

1. **ADM-12** satisfied per **`.planning/REQUIREMENTS.md`**.
2. **`AccrueAdmin.Copy`** / **`ax-*`** / **VERIFY-01** discipline preserved on touched surfaces.

</details>

<details>
<summary>✅ v1.16 Integrator + proof continuity (Phases 59–61) — SHIPPED 2026-04-23</summary>

**Milestone goal:** Close **integrator / adoption / proof** drift opened by **v1.15** trust SemVer + demo README work — **docs + verifiers + proof artifacts** only (**no** new billing APIs, **no** **PROC-08** / **FIN-03**).

**Depends on:** **v1.15** shipped; **v1.13** **INT-01..INT-05** baseline; merge-blocking **`host-integration`** contract unchanged unless explicitly revised in this milestone.

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 59 | Golden path + quickstart coherence | **Complete** **2026-04-23** (plans **2/2**) | INT-06 |
| 60 | Adoption proof + CI ownership map | **Complete** **2026-04-23** (plans **2/2**) | INT-07 |
| 61 | Root VERIFY hops + Hex doc SSOT | **Complete** **2026-04-23** (plans **2/2**) | INT-08, INT-09 |

**Success criteria (milestone):**

1. **INT-06..INT-09** satisfied with committed docs/scripts/tests as needed; **`bash scripts/ci/verify_package_docs.sh`** green.
2. No **PROC-08** / **FIN-03** scope creep.

### Phase 59: Golden path + quickstart coherence

**Goal:** **First Hour** ↔ **host README** ↔ **quickstart** consistent with **v1.15** messaging; verifier scripts green.

**Requirements:** INT-06

**Success criteria:**

1. **INT-06** satisfied — **`accrue/guides/first_hour.md`**, **`examples/accrue_host/README.md`**, and **`accrue/guides/quickstart.md`** (plus explicitly linked tutorial sections) contain **no contradictory** version pins, command order, or capsule (**H/M/R**) instructions relative to **v1.15** trust SemVer messaging and current **CI** merge-blocking contracts; **`verify_verify01_readme_contract.sh`** and **`verify_adoption_proof_matrix.sh`** (or successors) stay **green** on **`main`**.
2. No **PROC-08** / **FIN-03** scope creep.

### Phase 60: Adoption proof + CI ownership map

**Goal:** Matrix + evaluator script + contributor verifier map honest vs lanes and trust copy.

**Requirements:** INT-07

**Success criteria:**

1. **INT-07** satisfied per **`.planning/milestones/v1.16-REQUIREMENTS.md`**.
2. No **PROC-08** / **FIN-03** scope creep.

### Phase 61: Root VERIFY hops + Hex doc SSOT

**Goal:** README hop budget vs **VERIFY-01**; **`verify_package_docs`** + **`first_hour`** + planning mirrors vs **`@version`**.

**Requirements:** INT-08, INT-09

**Success criteria:**

1. **INT-08** and **INT-09** satisfied per **`.planning/milestones/v1.16-REQUIREMENTS.md`**.
2. No **PROC-08** / **FIN-03** scope creep.

**Archives:** [`milestones/v1.16-ROADMAP.md`](milestones/v1.16-ROADMAP.md), [`milestones/v1.16-REQUIREMENTS.md`](milestones/v1.16-REQUIREMENTS.md).

</details>

<details>
<summary>✅ v1.15 Release / trust semantics (Phases 57–58) — SHIPPED 2026-04-23</summary>

**Milestone goal:** Remove evaluator confusion between **Hex SemVer** (`0.3.x` today), **internal planning milestone labels** (`v1.14`, `v1.15`, …), and the **checked-in demo’s Sigra dependency** — using docs only (**no** new billing primitives, **no** **PROC-08** / **FIN-03**).

**Depends on:** **v1.14** shipped; **`verify_package_docs`** + linked **`mix.exs`** `@version` SSOT.

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 57 | Trust docs — SemVer + planning labels | **`upgrade.md`** baseline accuracy; **`RELEASING.md`** + root **`README.md`** spell Hex vs `.planning/` milestones. **Shipped 2026-04-23.** | TRT-01, TRT-02, TRT-03 |
| 58 | Demo README — Sigra vs `Accrue.Auth` | **`examples/accrue_host/README.md`** states Sigra as demo convenience and points non-Sigra hosts at **First Hour** / org billing guides; **`accrue/README.md`** stability paragraph. **Shipped 2026-04-23.** | TRT-04 |

**Success criteria (milestone):**

1. **TRT-01..TRT-04** satisfied with committed markdown and **`bash scripts/ci/verify_package_docs.sh`** green.
2. No **PROC-08** / **FIN-03** scope creep.

**Archives:** [`milestones/v1.15-ROADMAP.md`](milestones/v1.15-ROADMAP.md), [`milestones/v1.15-REQUIREMENTS.md`](milestones/v1.15-REQUIREMENTS.md).

</details>

<details>
<summary>✅ v1.14 Companion admin + billing depth (Phases 54–56) — SHIPPED 2026-04-23</summary>

**Milestone goal:** Bring **core** companion admin (customers, subscriptions, invoices, charges, webhooks, dashboard—**excluding** the v1.13 auxiliary set) to the **v1.12 / v1.13** bar for **`AccrueAdmin.Copy`**, **`ax-*` / theme tokens**, and **VERIFY-01**; then ship **one** bounded **billing / Stripe** library expansion with **Fake** regressions and honest **telemetry / operator docs**—without **PROC-08**, **FIN-03**, integrator-milestone doc scope, or release-train milestone scope.

**Depends on:** **v1.13** shipped; **Hex `0.3.0`** pair remains the published baseline; existing **VERIFY-01** + **Copy export** machinery from **v1.11–v1.13**.

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 54 | Core admin inventory + first burn-down | **ADM-07** matrix + **ADM-08** invoice Copy burn-down. **Shipped 2026-04-22.** | ADM-07, ADM-08 |
| 55 | Core admin VERIFY + theme + copy CI | **VERIFY-01** invoice anchors + **theme-exceptions** + **`export_copy_strings`**. **Shipped 2026-04-23.** | ADM-09, ADM-10, ADM-11 |
| 56 | Billing / Stripe depth + telemetry truth | **`list_payment_methods`** + telemetry/docs (**BIL-01**, **BIL-02**). **Shipped 2026-04-23.** | BIL-01, BIL-02 |

**Success criteria (milestone):**

1. **ADM-07..ADM-11** and **BIL-01..BIL-02** satisfied with committed **LiveView** / **Billing** code, tests, and phase verification notes.
2. No **PROC-08** / **FIN-03** scope creep; no new third-party UI kits.
3. **VERIFY-01** policy (**merge-blocking** vs **advisory** lanes) unchanged unless an explicit maintainer decision documents a rename (discouraged).

**Archives:** [`milestones/v1.14-ROADMAP.md`](milestones/v1.14-ROADMAP.md), [`milestones/v1.14-REQUIREMENTS.md`](milestones/v1.14-REQUIREMENTS.md).

</details>

<details>
<summary>✅ v1.13 Integrator path + secondary admin parity (Phases 51–53) — SHIPPED 2026-04-23</summary>

**Milestone goal:** A net-new Phoenix team **lands successfully on the first try**—README / **First Hour** / quickstart / VERIFY-01 tell one story—and **auxiliary admin** pages no longer feel like second-class operators next to customers/subscriptions/invoices, without **PROC-08**, **FIN-03**, or new UI kits.

**Depends on:** **v1.12** shipped; **Hex `0.3.0`** pair is the published baseline; existing **VERIFY-01** host contract and **Copy export** machinery from **v1.11–v1.12**.

| # | Phase | Goal | Requirements |
|---|-------|------|--------------|
| 51 | Integrator golden path & docs | One coherent **clone → install → Fake subscription → proof** narrative; VERIFY-01 / CI lane discoverability from repo root; first-run troubleshooting anchors with stable slugs. **Shipped 2026-04-22.** | INT-01, INT-02, INT-03 |
| 52 | Integrator proof + package alignment + auxiliary copy (part 1) | Proof artifacts and Hex-facing docs stay evidence-true while **Coupons** / **promotion codes** pick up **AccrueAdmin.Copy** SSOT. **Shipped 2026-04-23.** | INT-04, INT-05, AUX-01, AUX-02 |
| 53 | Auxiliary admin — Connect, events, layout, VERIFY | **Connect** + **events** surfaces meet copy SSOT; **`ax-*` / token** discipline + registered exceptions; **Playwright** + **axe** on all materially touched auxiliary mounted paths. **Shipped 2026-04-23.** | AUX-03, AUX-04, AUX-05, AUX-06 |

**Success criteria (milestone):**

1. **INT-01..INT-05** and **AUX-01..AUX-06** satisfied with committed docs, **LiveView**, tests, and phase verification notes.
2. No **PROC-08** / **FIN-03** scope creep; no new third-party UI kits.
3. **VERIFY-01** policy (**merge-blocking** vs **advisory** lanes) unchanged unless an explicit maintainer decision documents a rename (discouraged).

**Archives:** [`milestones/v1.13-ROADMAP.md`](milestones/v1.13-ROADMAP.md), [`milestones/v1.13-REQUIREMENTS.md`](milestones/v1.13-REQUIREMENTS.md).

</details>

<details>
<summary>✅ v1.12 Admin & operator UX (Phases 48–50) — SHIPPED 2026-04-22</summary>

**Milestone goal:** Improve **`accrue_admin`** so operators see **trustworthy billing state** faster—especially signals that matter after **metering (v1.10)**—with **smoother drills and navigation**, while keeping **Phase 20/21** contracts (**`ax-*`**, **`AccrueAdmin.Copy`**, no new UI kits) and **without** **PROC-08** / **FIN-03**.

**Depends on:** **v1.11** on Hex (**0.3.0** pair); **v1.10** metering semantics + **v1.9** telemetry/runbook narratives available for honest admin copy and links.

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 48 | Admin metering & billing signals | Ship at least one **credible metering- or usage-adjacent** operator signal on the admin entry path with honest links into existing indexes/narratives. | ADM-01 |
| 49 | Drill flows & navigation | Make **one** scoped high-traffic **list/detail** flow measurably smoother; keep **nav labels/order** and **route inventory** aligned if entries change. | ADM-02, ADM-03 |
| 50 | Copy, tokens & VERIFY gates | **`AccrueAdmin.Copy`** + **token discipline** for all **v1.12** string/layout churn; **Playwright** + **axe** parity on **all** materially touched mounted-admin paths for the milestone. | ADM-04, ADM-05, ADM-06 |

**Success criteria (milestone):**

1. **ADM-01..ADM-06** satisfied with committed **LiveView** + tests + phase verification notes.
2. No **PROC-08** / **FIN-03** scope creep; no new third-party UI kits.
3. **VERIFY-01** policy (**merge-blocking** vs **advisory** lanes) unchanged unless an explicit maintainer decision documents a rename (discouraged).

**Archives:** [`milestones/v1.12-ROADMAP.md`](milestones/v1.12-ROADMAP.md), [`milestones/v1.12-REQUIREMENTS.md`](milestones/v1.12-REQUIREMENTS.md).

</details>

<details>
<summary>✅ v1.11 Public Hex release + post-release continuity (Phases 46–47) — SHIPPED 2026-04-22</summary>

**Milestone goal:** Ship **`accrue`** and **`accrue_admin`** to **Hex** for metering + accumulated work since early **0.1.x** public cuts via **Release Please** linked releases, then fix **doc + verifier + planning** drift so published versions are the obvious install baseline.

**Depends on:** v1.10 complete (metering in tree); CI green on **`main`**.

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 46 | Release train & Hex publish | Executable maintainer path from green **`main`** → merged release PR → Hex + tags. | REL-01, REL-02, REL-04 — **Complete 2026-04-22** |
| 47 | Post-release docs & planning continuity | Remove evaluator confusion between “what Hex has” and “what the repo says.” | REL-03, DOC-01, DOC-02, HYG-01 — **Complete 2026-04-22** |

**Success criteria (milestone):**

1. Both packages appear on Hex at the **same linked** SemVer with **`accrue` published before `accrue_admin`**.
2. **`verify_package_docs`** + package docs ExUnit gate pass on **`main`** after release.
3. Planning docs no longer claim **0.1.2** as “current Hex” once a newer version is published.

**Archives:** [`milestones/v1.11-ROADMAP.md`](milestones/v1.11-ROADMAP.md), [`milestones/v1.11-REQUIREMENTS.md`](milestones/v1.11-REQUIREMENTS.md).

</details>

<details>
<summary>✅ v1.10 Metered usage + Fake parity (Phases 43–45) — SHIPPED 2026-04-22</summary>

**Milestone goal:** Prove **usage metering** end-to-end on **Fake** (and Stripe where already present) with **deterministic tests** for happy path, **sync** failures + idempotent retry telemetry, **reconciler** recovery for stuck `pending` rows, **webhook** meter error reports, and **docs/telemetry** alignment — without **PROC-08** or Stripe Dashboard meter UX ownership.

**Depends on:** v1.9 telemetry catalog + runbooks; spike `.planning/research/v1.10-METERING-SPIKE.md`.

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 43 | Meter usage happy path + Fake determinism | Lock the public reporting API + persistence + Fake success story before failure-mode work expands surface area. | MTR-01..MTR-03 — **Complete 2026-04-22** |
| 44 | Meter failures, idempotency, reconciler + webhook | Sync/reconciler/webhook failure paths share a guarded `MeterEvents` choke; `DispatchWorker` passes embedded meter object in `ctx`. | MTR-04..MTR-06 — **Complete 2026-04-22** |
| 45 | Docs + telemetry/runbook alignment | Operators and hosts can navigate metering failures using the same doc stack shipped in v1.9. | MTR-07..MTR-08 — **Complete 2026-04-22** |

**Success criteria (milestone):**

1. ExUnit (minimum) covers the spike’s **happy path**, **sync failure + idempotent retry**, **reconciler**, and **webhook** scenarios with stable telemetry keys/attrs.
2. `Accrue.Billing.report_usage` remains the **documented public** host entry point; tests do not depend on private modules for ordinary assertions.
3. `guides/telemetry.md` remains internally consistent for `meter_reporting_failed` (and related) rows across **sync / reconciler / webhook** sources.

**Phase 43 — Meter usage happy path + Fake determinism**

**Goal:** Lock the public reporting API + persistence + Fake success story before failure-mode work expands surface area.

**Success criteria:**

1. **MTR-01..MTR-03** satisfied with committed tests and docs pointers to NimbleOptions and Fake helpers.
2. No new **PROC-08** processor work; Stripe path may be documented as host-configured but Fake proves CI.

**Phase 44 — Meter failures, idempotency, reconciler + webhook**

**Goal:** Revenue-adjacent failure paths are **observable once**, **recoverable**, and **webhook-consistent** with existing `DefaultHandler` wiring.

**Success criteria:**

1. **MTR-04..MTR-06** satisfied with tests aligned to spike acceptance bullets.
2. Telemetry events match catalog metadata columns in `guides/telemetry.md` (update if intentionally extended).

**Phase 45 — Docs + telemetry/runbook alignment**

**Goal:** Operators and hosts can navigate metering failures using the same doc stack shipped in v1.9.

**Success criteria:**

1. **MTR-07..MTR-08** satisfied: guide boundary clarity + telemetry/runbook cross-links.
2. Cross-links from `guides/testing.md` or quickstart only if they reduce evaluator confusion (optional stretch inside phase close).

**Archives:** [`milestones/v1.10-ROADMAP.md`](milestones/v1.10-ROADMAP.md), [`milestones/v1.10-REQUIREMENTS.md`](milestones/v1.10-REQUIREMENTS.md).

</details>

<details>
<summary>✅ v1.9 Observability & operator runbooks (Phases 40–42) — SHIPPED 2026-04-22</summary>

**Milestone goal:** Close the adoption gap between “telemetry exists” and “operators know what to subscribe to, alert on, and do next” — **without** new billing primitives or Stripe Dashboard parity.

**Depends on:** v1.0+ telemetry stack (`Accrue.Telemetry`, `Accrue.Telemetry.Ops`, optional `Accrue.Telemetry.Metrics`).

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 40 | Telemetry catalog + guide truth | Extend `guides/telemetry.md` (and `Accrue.Telemetry.Ops` docs) so every `[:accrue, :ops, :*]` emit is catalogued; document firehose vs ops split; reconcile against `.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md`. **Complete 2026-04-22.** | OBS-01, OBS-03, OBS-04 |
| 41 | Host metrics wiring + cross-domain example | Close `Telemetry.Metrics.defaults/0` gaps vs ops emits **or** document intentional omissions; add host-copyable cross-domain subscription example. **Complete 2026-04-22.** | TEL-01, OBS-02 |
| 42 | Operator runbooks | Ship runbook section (guide or linked doc): ops event → suggested first action / Stripe host checks / Oban queues — especially DLQ, meters, dunning, revenue-adjacent signals, Connect failures. **Complete 2026-04-22.** | RUN-01 |

**Success criteria (milestone):**

1. No undocumented `[:accrue, :ops, :*]` event from the v1.9 gap audit §1 remains absent from the published catalog (OBS-01 + OBS-04).
2. A host developer can wire `Accrue.Telemetry.Metrics.defaults/0` with documented parity to ops signals (TEL-01).
3. Runbook entries exist for each ops class called out in **RUN-01** (RUN-01).

**Archives:** [`milestones/v1.9-ROADMAP.md`](milestones/v1.9-ROADMAP.md), [`milestones/v1.9-REQUIREMENTS.md`](milestones/v1.9-REQUIREMENTS.md).

</details>

<details>
<summary>✅ v1.8 Org billing recipes & host integration depth (Phases 37–39) — SHIPPED 2026-04-22</summary>

**Milestone goal:** Host teams without Sigra can adopt **org-shaped** billing using the same **row-scoped** `Accrue.Billable` + `Accrue.Auth` contracts proven in v1.3, with first-class docs and VERIFY-01 / adoption-proof traceability.

**Depends on:** v1.3 **ORG-01..03** shipped; v1.7 adoption/CI doc patterns available.

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 37 | Org billing recipes — doc spine + phx.gen.auth | Publish the non-Sigra “session → billable” spine; complete phx.gen.auth-oriented recipe with links from existing auth/Sigra guides. | ORG-05, ORG-06 |
| 38 | Org billing recipes — Pow + custom org boundaries | Pow-oriented recipe; custom org model checklist + ORG-03 anti-patterns. | ORG-07, ORG-08 |
| 39 | Org billing proof alignment | Extend adoption proof matrix and/or VERIFY-01 README contract for ≥1 non-Sigra org archetype; name owning verifier/script; preserve merge-blocking vs advisory policy. | ORG-09 |

**Phase 37 — Org billing recipes — doc spine + phx.gen.auth**

**Goal:** One authoritative doc path for non-Sigra org billing; phx.gen.auth checklist is concrete enough to implement without reading Sigra sources.

**Success criteria:**

1. New or expanded guide(s) are linked from `accrue/guides/auth_adapters.md` and/or `accrue/guides/sigra_integration.md` (“not using Sigra → …”).
2. **ORG-05** and **ORG-06** satisfied by committed docs (see archive requirements).
3. No new Accrue Hex dependencies for phx.gen.auth.

**Phase 38 — Org billing recipes — Pow + custom org boundaries**

**Goal:** Teams on Pow or fully custom org membership can see Accrue-specific obligations and sharp edges.

**Success criteria:**

1. **ORG-07** satisfied: Pow recipe published with version-agnostic host contract focus.
2. **ORG-08** satisfied: custom org recipe lists scoping rules for LiveView admin, context functions, and webhook replay alignment with **ORG-03**.

**Phase 39 — Org billing proof alignment**

**Goal:** Evaluators and CI can see non-Sigra org billing posture without diluting VERIFY-01 semantics.

**Success criteria:**

1. `examples/accrue_host/docs/adoption-proof-matrix.md` (and/or host README VERIFY-01 section) includes ≥1 **non-Sigra org** archetype row with **merge-blocking** or **advisory** label consistent with existing policy.
2. Owning verifier or script referenced in `scripts/ci/README.md` (or successor map) per v1.7 patterns.
3. **ORG-09** verified in phase close.

**Archives:** [`milestones/v1.8-ROADMAP.md`](milestones/v1.8-ROADMAP.md), [`milestones/v1.8-REQUIREMENTS.md`](milestones/v1.8-REQUIREMENTS.md).

</details>

<details>
<summary>✅ v1.6 Admin UI / UX polish (Phases 25–29) — SHIPPED 2026-04-20</summary>

**Milestone goal:** Operator-facing admin matches Phase **20/21 UI-SPEC** intent across money indexes, detail pages, and webhooks; microcopy is consistent; **a11y** and **mobile** regressions are caught by tests where ROI is highest—without new third-party UI kits.

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 25 | Admin UX inventory | Baseline map of routes, components, and spec alignment across `accrue_admin`. | INV-01..03 |
| 26 | Hierarchy and pattern alignment | `ax-*` / token consistency on touched surfaces across money indexes, detail pages, and webhooks. | UX-01..04 |
| 27 | Microcopy and operator strings | Plain-language admin copy + stable test literals. | COPY-01..03 |
| 28 | Accessibility hardening | Focus, tables, contrast; axe on mounted admin. | A11Y-01..04 |
| 29 | Mobile parity and CI | Overflow, nav, expanded `@mobile` admin coverage | MOB-01..03 |

**Depends on:** Phase 24 complete (v1.5 shipped). **Archives:** [`v1.6-ROADMAP.md`](milestones/v1.6-ROADMAP.md), [`v1.6-REQUIREMENTS.md`](milestones/v1.6-REQUIREMENTS.md), [`v1.6-MILESTONE-AUDIT.md`](milestones/v1.6-MILESTONE-AUDIT.md).

</details>

<details>
<summary>✅ v1.6 audit gap closure (Phases 30–31) — complete 2026-04-21</summary>

**Milestone goal:** Clear `/gsd-audit-milestone` gaps for shipped v1.6: restore strict COPY requirement evidence in phase verification, backfill `requirements-completed` on Phase 26/29 plan summaries, then address advisory integration notes (CI scripts, Copy SSOT, Playwright matrix consistency).

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 30 | Audit corpus closure — **complete** (2026-04-21) | `COPY-01..03` mapped in `27-VERIFICATION.md`; `requirements-completed` YAML on `26-*-SUMMARY.md` and `29-*-SUMMARY.md` where missing. | COPY-01..03; evidence backfill for UX-01..04 + MOB-01..03 (Phase 26/29 implementation unchanged) |
| 31 | Advisory integration alignment — **complete** (2026-04-21) | VERIFY-01 mobile contract + `e2e:mobile`; step-up modal Copy SSOT; fixture Playwright + docs aligned to host VERIFY-01 as merge-blocking path. | INV-01, INV-03, UX-01, MOB-01, MOB-03, A11Y-03, COPY-02, COPY-03 |

**Depends on:** v1.6 Phases 25–29 complete (shipped). **Requirements archive:** [`milestones/v1.6-REQUIREMENTS.md`](milestones/v1.6-REQUIREMENTS.md). **Audit:** [`milestones/v1.6-MILESTONE-AUDIT.md`](milestones/v1.6-MILESTONE-AUDIT.md).

**Gap closure:** Phases created by `/gsd-plan-milestone-gaps` (2026-04-20).

</details>

<details>
<summary>✅ v1.5 Adoption proof hardening (Phase 24) — SHIPPED 2026-04-18</summary>

**Milestone goal:** Make the existing **Fake-first VERIFY-01** story and the **Stripe test-mode parity** lane easy to understand for evaluators and maintainers — without changing release-blocking CI semantics.

- [x] **Phase 24: Adoption proof hardening** — Documentation + host README contract + CI display naming + cross-links (PROOF-01..03).

### Phase 24: Adoption proof hardening

**Goal:** One matrix doc ties bounded host tests, Playwright VERIFY-01, and advisory `live-stripe` / `mix test.live` together; evaluator recording checklist ships; no new billing product scope.

**Depends on:** Phase 23 (v1.4 complete)

**Requirements:** PROOF-01, PROOF-02, PROOF-03

**Success criteria:**

1. `examples/accrue_host/docs/adoption-proof-matrix.md` exists and is linked from `examples/accrue_host/README.md` (enforced by `verify_verify01_readme_contract.sh`).
2. `examples/accrue_host/docs/evaluator-walkthrough-script.md` exists and is linked from the host README.
3. `.github/workflows/ci.yml` advisory Stripe job display name states test-mode parity; `guides/testing-live-stripe.md` states job id vs key mode explicitly.
4. `accrue/guides/testing.md` links host VERIFY-01 matrix + `guides/testing-live-stripe.md`.

**Plans:** (executed inline — planning-only phase)

</details>

## Prior milestone snapshot (v1.4)

**Milestone goal:** Keep the Stripe client dependency current on published Hex within the `~> 1.1` contract, and make the existing host + mounted admin **visual** story trivial to reproduce locally and inspect from CI.

### Phase 23 (complete)

- [x] **Phase 23: Ecosystem stability + demo visuals** — Refresh `lattice_stripe` lockfiles to latest 1.1.x; document and script the `@phase15-trust` screenshot walkthrough. **PROC-08** explicitly not in this phase.

**Plans:** `23-01-PLAN.md`, `23-02-PLAN.md`

## Progress

**v1.3 (complete)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 18. Stripe Tax Core | v1.3 | 4/4 | Complete | 2026-04-17 |
| 19. Tax Location and Rollout Safety | v1.3 | 5/5 | Complete | 2026-04-17 |
| 20. Organization Billing With Sigra | v1.3 | 6/6 | Complete | 2026-04-17 |
| 21. Admin and Host UX Proof | v1.3 | 6/6 | Complete | 2026-04-17 |
| 22. Finance Handoff and Milestone Verification | v1.3 | 2/2 | Complete | 2026-04-17 |

**v1.4 (complete)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 23. Ecosystem stability + demo visuals | v1.4 | 2/2 | Complete | 2026-04-17 |

**v1.5 (complete)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 24. Adoption proof hardening | v1.5 | inline | Complete | 2026-04-18 |

**v1.6 (complete)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 25. Admin UX inventory | v1.6 | 3/3 | Complete | 2026-04-20 |
| 26. Hierarchy and pattern alignment | v1.6 | 4/4 | Complete | 2026-04-20 |
| 27. Microcopy and operator strings | v1.6 | 3/3 | Complete | 2026-04-20 |
| 28. Accessibility hardening | v1.6 | 3/3 | Complete | 2026-04-20 |
| 29. Mobile parity and CI | v1.6 | 3/3 | Complete | 2026-04-20 |

**v1.6 post-ship (complete)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 30. Audit corpus closure | v1.6 (post-ship) | 2/2 | Complete | 2026-04-21 |
| 31. Advisory integration alignment | v1.6 (post-ship) | 3/3 | Complete | 2026-04-21 |

**v1.7 (complete — 2026-04-21)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 32. Adoption discoverability + doc graph | v1.7 | — | Complete | 2026-04-21 |
| 33. Installer, host contracts + CI clarity | v1.7 | — | Complete | 2026-04-21 |
| 34. Operator home, drill flow + nav model | v1.7 | 3/3 | Complete | 2026-04-21 |
| 35. Summary surfaces + test literal hygiene | v1.7 | 2/2 | Complete | 2026-04-21 |
| 36. Audit corpus + adoption integration hardening | v1.7 | 3/3 | Complete | 2026-04-21 |

**v1.8 (complete — 2026-04-22)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 37. Org billing recipes — doc spine + phx.gen.auth | v1.8 | 3/3 | Complete | 2026-04-21 |
| 38. Org billing recipes — Pow + custom org boundaries | v1.8 | 2/2 | Complete | 2026-04-22 |
| 39. Org billing proof alignment | v1.8 | 3/3 | Complete | 2026-04-22 |

**v1.9 (complete — 2026-04-22)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 40. Telemetry catalog + guide truth | v1.9 | 3/3 | Complete | 2026-04-22 |
| 41. Host metrics wiring + cross-domain example | v1.9 | 3/3 | Complete | 2026-04-22 |
| 42. Operator runbooks | v1.9 | 2/2 | Complete | 2026-04-22 |

**v1.10 (complete — 2026-04-22)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 43. Meter usage happy path + Fake determinism | v1.10 | 3/3 | Complete | 2026-04-22 |
| 44. Meter failures, idempotency, reconciler + webhook | v1.10 | 3/3 | Complete | 2026-04-22 |
| 45. Docs + telemetry/runbook alignment | v1.10 | 4/4 | Complete | 2026-04-22 |

**v1.11 (complete — 2026-04-22)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 46. Release train & Hex publish | v1.11 | 3/3 | Complete | 2026-04-22 |
| 47. Post-release docs & planning continuity | v1.11 | 3/3 | Complete | 2026-04-22 |

**v1.12 (complete — 2026-04-22)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 48. Admin metering & billing signals | v1.12 | 1/1 | Complete | 2026-04-22 |
| 49. Drill flows & navigation | v1.12 | 2/2 | Complete | 2026-04-22 |
| 50. Copy, tokens & VERIFY gates | v1.12 | 3/3 | Complete | 2026-04-22 |

**v1.13 (complete — 2026-04-23)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 51. Integrator golden path & docs | v1.13 | 3/3 | Complete | 2026-04-22 |
| 52. Integrator proof + package alignment + auxiliary copy (part 1) | v1.13 | 3/3 | Complete | 2026-04-23 |
| 53. Auxiliary admin — Connect, events, layout, VERIFY | v1.13 | 2/2 | Complete | 2026-04-23 |

**v1.14 (complete — 2026-04-23)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 54. Core admin inventory + first burn-down | v1.14 | 2/2 | Complete | 2026-04-22 |
| 55. Core admin VERIFY + theme + copy CI | v1.14 | 2/2 | Complete | 2026-04-23 |
| 56. Billing / Stripe depth + telemetry truth | v1.14 | 2/2 | Complete | 2026-04-23 |

**v1.15 (complete — 2026-04-23)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 57. Trust docs — SemVer + planning labels | v1.15 | inline | Complete | 2026-04-23 |
| 58. Demo README — Sigra vs `Accrue.Auth` | v1.15 | inline | Complete | 2026-04-23 |

**v1.16 (complete — 2026-04-23)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 59. Golden path + quickstart coherence | v1.16 | 2/2 | Complete | 2026-04-23 |
| 60. Adoption proof + CI ownership map | v1.16 | 2/2 | Complete | 2026-04-23 |
| 61. Root VERIFY hops + Hex doc SSOT | v1.16 | 2/2 | Complete | 2026-04-23 |

**v1.17 (complete — 2026-04-23)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 62. Friction triage + north star | v1.17 | 3/3 | Complete | 2026-04-23 |
| 63. P0 integrator / VERIFY / docs | v1.17 | 3/3 | Complete | 2026-04-23 |
| 64. P0 billing | v1.17 | 1/1 | Complete | 2026-04-23 |
| 65. P0 admin / operator | v1.17 | 1/1 | Complete | 2026-04-23 |

**v1.18 (complete — 2026-04-23)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 66. Deferred UAT + evaluator proof | v1.18 | 3/3 | Complete | 2026-04-23 |

Earlier shipped phases (1–17) remain in per-milestone roadmap archives under `.planning/milestones/`.

---

For full archived phase details, decisions, and requirements traceability, see `.planning/milestones/`.
