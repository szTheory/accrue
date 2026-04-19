# Roadmap: Accrue

## Milestones

- ✅ **v1.0 Initial Release** — Phases 1-9 shipped on 2026-04-16. Public Hex packages: `accrue` 0.1.2 and `accrue_admin` 0.1.2. Full archive: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md).
- ✅ **v1.1 Stabilization + Adoption** — Phases 10-12 plus 11.1 shipped on 2026-04-17. Proved Accrue in a realistic Phoenix host app, promoted that proof into CI, closed host-flow hermeticity gaps, and hardened first-user DX/docs. Full archive: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md).
- ✅ **v1.2 Adoption + Trust** — Phases 13-17 shipped on 2026-04-17. Polished the canonical local demo/tutorial, adoption front door, trust evidence, expansion recommendation, and final milestone cleanup. Full archive: [`milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md).
- ✅ **v1.3 Tax + Organization Billing** — Phases 18-22 shipped on 2026-04-17. Stripe Tax, Sigra-first organization billing, admin/host UX proof, and Stripe-native finance handoff documentation. Full archive: [`milestones/v1.3-ROADMAP.md`](milestones/v1.3-ROADMAP.md).
- ✅ **v1.4 Ecosystem stability + demo visuals** — Phase 23 shipped 2026-04-17. `lattice_stripe` lockfiles verified on latest 1.1.x; Fake-backed Playwright screenshot walkthrough documented and scripted; admin `priv/static` bundle fixed for browser LiveView. **PROC-08 deferred.**
- ✅ **v1.5 Adoption proof hardening** — Phase 24 shipped 2026-04-18. Adoption proof matrix + evaluator walkthrough script; README VERIFY-01 contract extended; CI job display name clarifies Stripe test mode; cross-links in `accrue/guides/testing.md` and `guides/testing-live-stripe.md`. Full archive: [`milestones/v1.5-ROADMAP.md`](milestones/v1.5-ROADMAP.md).

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

### Next milestone

No active phases. Start the next planning cycle with `/gsd-new-milestone` (fresh requirements and roadmap).

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

Earlier shipped phases (1–17) remain in per-milestone roadmap archives under `.planning/milestones/`.

---

For full archived phase details, decisions, and requirements traceability, see `.planning/milestones/`.
