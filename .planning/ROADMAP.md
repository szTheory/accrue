# Roadmap: Accrue

## Milestones

- ✅ **v1.0 Initial Release** — Phases 1-9 shipped on 2026-04-16. Public Hex packages: `accrue` 0.1.2 and `accrue_admin` 0.1.2. Full archive: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md).
- ✅ **v1.1 Stabilization + Adoption** — Phases 10-12 plus 11.1 shipped on 2026-04-17. Proved Accrue in a realistic Phoenix host app, promoted that proof into CI, closed host-flow hermeticity gaps, and hardened first-user DX/docs. Full archive: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md).
- ✅ **v1.2 Adoption + Trust** — Phases 13-17 shipped on 2026-04-17. Polished the canonical local demo/tutorial, adoption front door, trust evidence, expansion recommendation, and final milestone cleanup. Full archive: [`milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md).
- ✅ **v1.3 Tax + Organization Billing** — Phases 18-22 shipped on 2026-04-17. Stripe Tax, Sigra-first organization billing, admin/host UX proof, and Stripe-native finance handoff documentation. Full archive: [`milestones/v1.3-ROADMAP.md`](milestones/v1.3-ROADMAP.md).
- ✅ **v1.4 Ecosystem stability + demo visuals** — Phase 23 shipped 2026-04-17. `lattice_stripe` lockfiles verified on latest 1.1.x; Fake-backed Playwright screenshot walkthrough documented and scripted; admin `priv/static` bundle fixed for browser LiveView. **PROC-08 deferred.**
- ✅ **v1.5 Adoption proof hardening** — Phase 24 shipped 2026-04-18. Adoption proof matrix + evaluator walkthrough script; README VERIFY-01 contract extended; CI job display name clarifies Stripe test mode; cross-links in `accrue/guides/testing.md` and `guides/testing-live-stripe.md`. Full archive: [`milestones/v1.5-ROADMAP.md`](milestones/v1.5-ROADMAP.md).
- ✅ **v1.6 Admin UI / UX polish + audit gap closure** — Phases **25–31**: core admin polish shipped **2026-04-20**; post-ship Phases **30–31** closed strict audit corpus + advisory integration alignment **2026-04-21**. Archives: [`milestones/v1.6-ROADMAP.md`](milestones/v1.6-ROADMAP.md), [`milestones/v1.6-REQUIREMENTS.md`](milestones/v1.6-REQUIREMENTS.md), [`milestones/v1.6-MILESTONE-AUDIT.md`](milestones/v1.6-MILESTONE-AUDIT.md).
- ○ **v1.7 Adoption DX + operator admin depth** — Phases **32–36** (requirements: `.planning/REQUIREMENTS.md`; research: `.planning/research/SUMMARY.md`). **In progress** — planning initialized 2026-04-21; Phase **36** added 2026-04-21 via `/gsd-plan-milestone-gaps` (audit corpus + adoption integration hardening).

## Phases

### v1.7 Adoption DX + operator admin depth (Phases 32–36) — ACTIVE

**Milestone goal:** Tighten **VERIFY-01** and adoption **doc/CI** discoverability without changing merge-blocking semantics, then ship **operator admin** home + drill + nav improvements using existing **UI-SPEC** and **`AccrueAdmin.Copy`** discipline, then close **milestone-audit** traceability and integration notes without reopening satisfied ADOPT behavior.

| # | Phase | Goal | Requirements |
|---|-------|------|--------------|
| 32 | Adoption discoverability + doc graph | **Complete** (2026-04-21) — VERIFY-01 / doc graph | ADOPT-01..03 |
| 33 | Installer, host contracts + CI clarity | **Complete** (2026-04-21) — installer rerun docs + CI/advisory clarity | ADOPT-04..06 |
| 34 | Operator home, drill flow + nav model | **Complete** (2026-04-21) — scoped home KPIs; customer→invoice drill; `AccrueAdmin.Nav` + README routes | OPS-01..03 |
| 35 | Summary surfaces + test literal hygiene | Token-safe KPI/summary rows; new literals via `AccrueAdmin.Copy`; tests updated. | OPS-04..05 |
| 36 | Audit corpus + adoption integration hardening | Backfill **3-source** plan traceability on Phases 32–33; document verifier ownership / dual README–guide contracts; forward-coupling notes for OPS + Copy; optional `.planning` / full-suite test tiering guidance. | ADOPT evidence + audit `gaps.integration` (see Phase 36) |

### Phase 32: Adoption discoverability + doc graph

**Goal:** Evaluators and contributors never hit contradictory “how do I run proof?” instructions.

**Depends on:** v1.6 complete (Phase 31)

**Requirements:** ADOPT-01, ADOPT-02, ADOPT-03

**Success criteria:**

1. Repository root README links into a canonical path that surfaces VERIFY-01 / `mix verify` / Playwright commands within two hops.
2. Host README contains one coherent subsection tying Fake-first runs, Playwright, and adoption matrix / walkthrough links.
3. Cross-links among guides and host docs do not assert different “primary” proof commands for the same lane.

### Phase 33: Installer, host contracts + CI clarity

**Goal:** Install reruns and automation hooks stay honest while CI remains interpretable.

**Depends on:** Phase 32

**Requirements:** ADOPT-04, ADOPT-05, ADOPT-06

**Success criteria:**

1. Documented `mix accrue.install` rerun semantics match observed behavior or documented exceptions are filed in phase notes.
2. Doc contract tests / verify scripts pass; any gap has an explicit manual verification checklist in phase verification.
3. Workflow + guide text still identifies merge-blocking Fake lanes vs advisory Stripe test-mode lanes without renaming stable job ids referenced elsewhere.

### Phase 34: Operator home, drill flow + nav model

**Goal:** Operators see value on first open and can complete one common drill with less friction.

**Depends on:** Phase 33

**Requirements:** OPS-01, OPS-02, OPS-03

**Success criteria:**

1. Default admin entry shows a bounded home/dashboard-style surface using existing layout primitives.
2. At least one specified cross-entity drill (named in PLAN) reduces dead ends or preserves context vs baseline.
3. Nav labels and ordering are updated and reflected in maintainer route inventory if tables drift.

### Phase 35: Summary surfaces + test literal hygiene

**Goal:** New polish is token-safe and test-stable.

**Depends on:** Phase 34

**Requirements:** OPS-04, OPS-05

**Success criteria:**

1. New summary/KPI UI uses theme tokens or documented exceptions per UX-04 precedent.
2. New operator-visible strings route through `AccrueAdmin.Copy` (or established SSOT); Playwright/LiveView tests updated accordingly.

### Phase 36: Audit corpus + adoption integration hardening

**Goal:** Satisfy `/gsd-audit-milestone` items that are **process and integration** shaped: complete the **three-source** matrix for shipped Phases **32–33** (`requirements-completed` YAML on plan summaries), reduce contributor confusion when **central verify scripts** span multiple ADOPT requirements, keep **root README**, `verify_verify01_readme_contract.sh`, and **guides** dual-green, and document **forward coupling** so Phases **34–35** land without surprising doc or Copy regressions.

**Depends on:** Phases **32–33** complete (functional ADOPT satisfied).

**Requirements:** Evidence and integration closure for **ADOPT-01..06** (see `.planning/v1.7-MILESTONE-AUDIT.md`); does **not** replace Phase 32/33 as owners of functional ADOPT delivery.

**Success criteria:**

1. Every completed **32-**\* / **33-**\* plan `*-SUMMARY.md` that lacked it includes a `requirements-completed` YAML block consistent with executed plans and `*-VERIFICATION.md`.
2. `CONTRIBUTING.md` or `scripts/ci/README.md` (or equivalent) maps **ADOPT** requirements to **which verifier / ExUnit file** owns them; mega-script failures print identifiable **REQ** or **check** labels where practical.
3. Dual-contract maintenance (root README ↔ VERIFY-01 contract script ↔ host/guides) is documented so editorial changes do not silently break only one gate.
4. Forward-coupling note exists for **OPS-03..OPS-05** (route matrix, `AccrueAdmin.Copy`, Playwright) so operator phases do not fork SSOT.

**Gap closure:** Closes `gaps.integration` + tech-debt rows from [`v1.7-MILESTONE-AUDIT.md`](v1.7-MILESTONE-AUDIT.md) (2026-04-21).

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

**v1.7 (active)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 32. Adoption discoverability + doc graph | v1.7 | — | Complete | 2026-04-21 |
| 33. Installer, host contracts + CI clarity | v1.7 | — | Complete | 2026-04-21 |
| 34. Operator home, drill flow + nav model | v1.7 | 3/3 | Complete | 2026-04-21 |
| 35. Summary surfaces + test literal hygiene | v1.7 | — | Not started | — |
| 36. Audit corpus + adoption integration hardening | v1.7 | — | Not started | — |

Earlier shipped phases (1–17) remain in per-milestone roadmap archives under `.planning/milestones/`.

---

For full archived phase details, decisions, and requirements traceability, see `.planning/milestones/`.
