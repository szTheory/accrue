# Roadmap: Accrue

## Milestones

- ✅ **v1.0 Initial Release** — Phases 1-9 shipped on 2026-04-16. Public Hex packages: `accrue` 0.1.2 and `accrue_admin` 0.1.2. Full archive: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md).
- ✅ **v1.1 Stabilization + Adoption** — Phases 10-12 plus 11.1 shipped on 2026-04-17. Proved Accrue in a realistic Phoenix host app, promoted that proof into CI, closed host-flow hermeticity gaps, and hardened first-user DX/docs. Full archive: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md).
- ✅ **v1.2 Adoption + Trust** — Phases 13-17 shipped on 2026-04-17. Polished the canonical local demo/tutorial, adoption front door, trust evidence, expansion recommendation, and final milestone cleanup. Full archive: [`milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md).
- ✅ **v1.3 Tax + Organization Billing** — Phases 18-22 shipped on 2026-04-17. Stripe Tax, Sigra-first organization billing, admin/host UX proof, and Stripe-native finance handoff documentation. Full archive: [`milestones/v1.3-ROADMAP.md`](milestones/v1.3-ROADMAP.md).
- ✅ **v1.4 Ecosystem stability + demo visuals** — Phase 23 shipped 2026-04-17. `lattice_stripe` lockfiles verified on latest 1.1.x; Fake-backed Playwright screenshot walkthrough documented and scripted; admin `priv/static` bundle fixed for browser LiveView. **PROC-08 deferred.**
- ✅ **v1.5 Adoption proof hardening** — Phase 24 shipped 2026-04-18. Adoption proof matrix + evaluator walkthrough script; README VERIFY-01 contract extended; CI job display name clarifies Stripe test mode; cross-links in `accrue/guides/testing.md` and `guides/testing-live-stripe.md`. Full archive: [`milestones/v1.5-ROADMAP.md`](milestones/v1.5-ROADMAP.md).
- ○ **v1.6 Admin UI / UX polish** — Phases **25–29** (in planning). Companion admin (`accrue_admin`) hierarchy, microcopy, accessibility, and mobile CI; host Playwright where mounted admin must be proven. Requirements: [`.planning/REQUIREMENTS.md`](REQUIREMENTS.md).

## Phases

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

### v1.6 Admin UI / UX polish (Phases 25–29)

**Milestone goal:** Operator-facing admin matches Phase **20/21 UI-SPEC** intent across money indexes, detail pages, and webhooks; microcopy is consistent; **a11y** and **mobile** regressions are caught by tests where ROI is highest—without new third-party UI kits.

| # | Phase | Goal | Requirements | Success criteria (summary) |
|---|-------|------|--------------|---------------------------|
| 25 | Admin UX inventory | Baseline map of routes, components, and spec alignment across `accrue_admin`. | INV-01..03 | Matrix + gap list checked into phase artifacts (complete 2026-04-20). |
| 26 | Hierarchy and pattern alignment | 4/4 | Complete    | 2026-04-20 |
| 27 | Microcopy and operator strings | 3/3 | Complete    | 2026-04-20 |
| 28 | Accessibility hardening | Focus, tables, contrast, optional axe on mounted admin | A11Y-01..04 | Documented checks + at least one automated gate or ADR |
| 29 | Mobile parity and CI | Overflow, nav, expanded `@mobile` admin coverage | MOB-01..03 | Playwright green on mobile project for in-scope flows |

**Depends on:** Phase 24 complete (v1.5 shipped).

**Next step:** `/gsd-discuss-phase 26` or `/gsd-plan-phase 26` (Phase 25 complete).

### Phase 25: Admin UX inventory

**Goal:** Baseline map of routes, components, and spec alignment across `accrue_admin`.

**Depends on:** Phase 24 complete (v1.5 shipped).

**Requirements:** INV-01, INV-02, INV-03

**Success criteria:**

1. Maintainer-facing **route matrix** (INV-01), **component coverage** notes (INV-02), and **spec alignment** table (INV-03) exist as phase artifacts—matrix + gap list checked into `.planning/phases/25-admin-ux-inventory/`.

**Canonical refs:** `.planning/REQUIREMENTS.md`; `.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md`; `.planning/phases/21-admin-and-host-ux-proof/21-UI-SPEC.md`

**Plans:** `25-01-PLAN.md`, `25-02-PLAN.md`, `25-03-PLAN.md` (3/3 complete, 2026-04-20)

### Phase 26: Hierarchy and pattern alignment

**Goal:** `ax-*` / token consistency on touched surfaces across money indexes, detail pages, and webhooks.

**Depends on:** Phase 25 complete (inventory baseline).

**Requirements:** UX-01, UX-02, UX-03, UX-04

**Success criteria:**

1. LiveViews updated for UX-01..03; ExUnit/HTML assertions on structure where specified in plans.
2. Theme tokens remain default on touched surfaces (UX-04); ad hoc hex documented if unavoidable.

**Canonical refs:** `.planning/REQUIREMENTS.md`; `.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md`; `.planning/phases/21-admin-and-host-ux-proof/21-UI-SPEC.md`; phase 25 inventory artifacts under `.planning/phases/25-admin-ux-inventory/`

**Plans:** 4/4 plans complete

### Phase 27: Microcopy and operator strings

**Goal:** Plain-language admin copy + stable test literals.

**Depends on:** Phase 26 (hierarchy alignment reduces churn before copy pass).

**Requirements:** COPY-01, COPY-02, COPY-03

**Success criteria:** Copy pass merged; grep or module doc for literals per REQUIREMENTS.

**Canonical refs:** `.planning/REQUIREMENTS.md`; `.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md`; `.planning/phases/21-admin-and-host-ux-proof/21-UI-SPEC.md`

**Plans:** 3/3 plans complete

### Phase 28: Accessibility hardening

**Goal:** Focus, tables, contrast; optional axe on mounted admin.

**Depends on:** Phase 27 (stable strings and structure).

**Requirements:** A11Y-01, A11Y-02, A11Y-03, A11Y-04

**Success criteria:** Documented checks + at least one automated gate or ADR per REQUIREMENTS.

**Canonical refs:** `.planning/REQUIREMENTS.md`; `.planning/phases/21-admin-and-host-ux-proof/21-UI-SPEC.md`

**Plans:** TBD

### Phase 29: Mobile parity and CI

**Goal:** Overflow, nav, expanded `@mobile` admin coverage in CI.

**Depends on:** Phase 28 where layout/focus fixes affect mobile.

**Requirements:** MOB-01, MOB-02, MOB-03

**Success criteria:** Playwright green on mobile project for in-scope flows.

**Canonical refs:** `.planning/REQUIREMENTS.md`; `examples/accrue_host` Playwright config and VERIFY-01 docs as referenced in plans.

**Plans:** TBD

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

**v1.6 (active)**

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 25. Admin UX inventory | v1.6 | 3/3 | Complete | 2026-04-20 |
| 26. Hierarchy and pattern alignment | v1.6 | 0/? | Planned | — |
| 27. Microcopy and operator strings | v1.6 | 0/? | Planned | — |
| 28. Accessibility hardening | v1.6 | 0/? | Planned | — |
| 29. Mobile parity and CI | v1.6 | 0/? | Planned | — |

Earlier shipped phases (1–17) remain in per-milestone roadmap archives under `.planning/milestones/`.

---

For full archived phase details, decisions, and requirements traceability, see `.planning/milestones/`.
