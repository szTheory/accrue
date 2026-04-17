# Roadmap: Accrue

## Milestones

- ✅ **v1.0 Initial Release** — Phases 1-9 shipped on 2026-04-16. Public Hex packages: `accrue` 0.1.2 and `accrue_admin` 0.1.2. Full archive: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md).
- ✅ **v1.1 Stabilization + Adoption** — Phases 10-12 plus 11.1 shipped on 2026-04-17. Proved Accrue in a realistic Phoenix host app, promoted that proof into CI, closed host-flow hermeticity gaps, and hardened first-user DX/docs. Full archive: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md).
- 🚧 **v1.2 Adoption + Trust** — Active. Make Accrue ready for new Phoenix teams to evaluate and trust through a canonical local demo, host-first onboarding docs, mature OSS adoption assets, a trust hardening bundle, and expansion discovery only.

## Phases

<details>
<summary>✅ v1.0 Initial Release (Phases 1-9) — SHIPPED 2026-04-16</summary>

- [x] Phase 1: Foundations (6/6 plans) — completed 2026-04-11
- [x] Phase 2: Schemas + Webhook Plumbing (6/6 plans) — completed 2026-04-12
- [x] Phase 3: Core Subscription Lifecycle (8/8 plans) — completed 2026-04-14
- [x] Phase 4: Advanced Billing + Webhook Hardening (8/8 plans) — completed 2026-04-14
- [x] Phase 5: Connect (7/7 plans) — completed 2026-04-14
- [x] Phase 6: Email + PDF (7/7 plans) — completed 2026-04-15
- [x] Phase 7: Admin UI (accrue_admin) (12/12 plans) — completed 2026-04-15
- [x] Phase 8: Install + Polish + Testing (9/9 plans) — completed 2026-04-15
- [x] Phase 9: Release (6/6 plans) — completed 2026-04-16

</details>

<details>
<summary>✅ v1.1 Stabilization + Adoption (Phases 10-12 plus 11.1) — SHIPPED 2026-04-17</summary>

- [x] Phase 10: Host App Dogfood Harness (7/7 plans) — completed 2026-04-16
- [x] Phase 11: CI User-Facing Integration Gate (3/3 plans) — completed 2026-04-16
- [x] Phase 11.1: Hermetic Host Flow Proofs (1/1 plans) — completed 2026-04-16
- [x] Phase 12: First-User DX Stabilization (11/11 plans) — completed 2026-04-16

</details>

<details open>
<summary>📋 v1.2 Adoption + Trust (Phases 13-16) — PLANNED</summary>

- [ ] Phase 13: Canonical Demo + Tutorial — make `examples/accrue_host` the polished local demo and tutorial proof path.
- [x] Phase 14: Adoption Front Door — align repository/package docs, issue templates, release guidance, and public support positioning. (completed 2026-04-17)
- [ ] Phase 15: Trust Hardening — add security, performance, compatibility, accessibility/responsive, secret/PII, and release-gate confidence checks.
- [ ] Phase 16: Expansion Discovery — evaluate and rank tax, revenue/export, additional processor, and org/multi-tenant billing options for the next implementation milestone.

</details>

## Phase Details

### Phase 13: Canonical Demo + Tutorial

**Goal:** Make `examples/accrue_host` the canonical local evaluation path for Accrue and document it as a tutorial from clone through first subscription and admin inspection.

**Requirements:** DEMO-01, DEMO-02, DEMO-03, DEMO-04, DEMO-05, DEMO-06, ADOPT-02

**Plans:** 3/3 plans complete

Plans:
- [x] 13-01-PLAN.md - Establish the host-local command manifest and `mix verify` / `mix verify.full` contract.
- [x] 13-02-PLAN.md - Add manifest-backed docs parity tests and narrow shell drift checks.
- [x] 13-03-PLAN.md - Rewrite the host README and First Hour guide around `First run` and `Seeded history`.

**Success criteria:**
1. A new user can run the local host demo from documented prerequisites and commands without live Stripe credentials.
2. The demo proves a Fake-backed subscription, signed webhook ingest, admin inspection/replay, and focused host tests.
3. A single CI-equivalent local command verifies the canonical demo path.
4. Tutorial commands and demo README commands are checked for drift before release.

### Phase 14: Adoption Front Door

**Goal:** Make the public repository, package docs, and support surfaces explain what Accrue is, where to start, what is stable, and how to ask for help.

**Requirements:** ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-04, ADOPT-05, ADOPT-06

**Plans:** 3/3 plans complete

Plans:
- [x] 14-01-PLAN.md — Create the repository front door and align package landing pages with docs contracts.
- [x] 14-02-PLAN.md — Add structured issue forms with no-secrets support intake coverage.
- [x] 14-03-PLAN.md — Clarify release/provider-parity guidance and extend the docs drift verifier.

**Success criteria:**
1. The repository root has a clear front door for Accrue, `accrue_admin`, the local demo, docs, and production hardening.
2. Package docs and README paths align around the host-first tutorial and public integration boundaries.
3. Issue templates cover bug reports, integration problems, documentation gaps, and feature requests.
4. Release guidance clearly explains Fake, Stripe test mode, live Stripe, and required vs advisory checks.

### Phase 15: Trust Hardening

**Goal:** Add the quality evidence a billing-library adopter expects before trusting Accrue in a real Phoenix app.

**Requirements:** TRUST-01, TRUST-02, TRUST-03, TRUST-04, TRUST-05, TRUST-06

**Plans:** 2/3 plans executed

Plans:
- [x] 15-01-PLAN.md — Create the checked-in trust review, leakage checks, and trust-gate release wording.
- [x] 15-02-PLAN.md — Add seeded performance smoke checks and desktop/mobile browser trust coverage to the canonical host flow.
- [ ] 15-03-PLAN.md — Extend the existing CI matrix and host integration lane for compatibility and trust-gate wiring.

**Success criteria:**
1. Security review artifacts cover webhook, auth, admin, replay, and generated-host boundaries.
2. Seeded smoke checks cover webhook ingest latency and admin page responsiveness.
3. Compatibility checks cover supported Elixir, OTP, Phoenix, and LiveView combinations.
4. Browser checks cover accessibility and responsive behavior for the demo/admin flows.
5. Public errors, logs, docs, and retained artifacts are reviewed for secrets and PII leakage.

### Phase 16: Expansion Discovery

**Goal:** Decide which mature-library expansion should come next without weakening the current Stripe-first, host-owned architecture.

**Requirements:** DISC-01, DISC-02, DISC-03, DISC-04, DISC-05

**Success criteria:**
1. Tax, revenue/export, additional processor, and org/multi-tenant options each have a decision-quality recommendation.
2. Recommendations identify likely user value, architecture impact, risk, and prerequisites.
3. Expansion candidates are ranked into next milestone, backlog, or planted seed.
4. No core billing API, schema, or processor abstraction changes are made unless needed to document a future migration path.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundations | v1.0 | 6/6 | Complete | 2026-04-11 |
| 2. Schemas + Webhook Plumbing | v1.0 | 6/6 | Complete | 2026-04-12 |
| 3. Core Subscription Lifecycle | v1.0 | 8/8 | Complete | 2026-04-14 |
| 4. Advanced Billing + Webhook Hardening | v1.0 | 8/8 | Complete | 2026-04-14 |
| 5. Connect | v1.0 | 7/7 | Complete | 2026-04-14 |
| 6. Email + PDF | v1.0 | 7/7 | Complete | 2026-04-15 |
| 7. Admin UI (accrue_admin) | v1.0 | 12/12 | Complete | 2026-04-15 |
| 8. Install + Polish + Testing | v1.0 | 9/9 | Complete | 2026-04-15 |
| 9. Release | v1.0 | 6/6 | Complete | 2026-04-16 |
| 10. Host App Dogfood Harness | v1.1 | 7/7 | Complete | 2026-04-16 |
| 11. CI User-Facing Integration Gate | v1.1 | 3/3 | Complete | 2026-04-16 |
| 11.1. Hermetic Host Flow Proofs | v1.1 | 1/1 | Complete | 2026-04-16 |
| 12. First-User DX Stabilization | v1.1 | 11/11 | Complete | 2026-04-16 |
| 13. Canonical Demo + Tutorial | v1.2 | 3/3 | Complete   | 2026-04-17 |
| 14. Adoption Front Door | v1.2 | 3/3 | Complete    | 2026-04-17 |
| 15. Trust Hardening | v1.2 | 2/3 | In Progress|  |
| 16. Expansion Discovery | v1.2 | 0/? | Planned | — |

---

For full phase details, decisions, and requirements traceability, see `.planning/milestones/`.
