# Roadmap: Accrue

## Milestones

- ✅ **v1.0 Initial Release** — Phases 1-9 shipped on 2026-04-16. Public Hex packages: `accrue` 0.1.2 and `accrue_admin` 0.1.2. Full archive: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md).
- ✅ **v1.1 Stabilization + Adoption** — Phases 10-12 plus 11.1 shipped on 2026-04-17. Proved Accrue in a realistic Phoenix host app, promoted that proof into CI, closed host-flow hermeticity gaps, and hardened first-user DX/docs. Full archive: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md).
- ✅ **v1.2 Adoption + Trust** — Phases 13-17 shipped on 2026-04-17. Polished the canonical local demo/tutorial, adoption front door, trust evidence, expansion recommendation, and final milestone cleanup. Full archive: [`milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md).
- ✅ **v1.3 Tax + Organization Billing** — Phases 18-22 shipped on 2026-04-17. Stripe Tax, Sigra-first organization billing, admin/host UX proof, and Stripe-native finance handoff documentation. Full archive: [`milestones/v1.3-ROADMAP.md`](milestones/v1.3-ROADMAP.md).
- ✅ **v1.4 Ecosystem stability + demo visuals** — Phase 23 shipped 2026-04-17. `lattice_stripe` lockfiles verified on latest 1.1.x; Fake-backed Playwright screenshot walkthrough documented and scripted; admin `priv/static` bundle fixed for browser LiveView. **PROC-08 deferred.**
- ✅ **v1.5 Adoption proof hardening** — Phase 24 shipped 2026-04-18. Adoption proof matrix + evaluator walkthrough script; README VERIFY-01 contract extended; CI job display name clarifies Stripe test mode; cross-links in `accrue/guides/testing.md` and `guides/testing-live-stripe.md`. Full archive: [`milestones/v1.5-ROADMAP.md`](milestones/v1.5-ROADMAP.md).
- ✅ **v1.6 Admin UI / UX polish + audit gap closure** — Phases **25–31**: core admin polish shipped **2026-04-20**; post-ship Phases **30–31** closed strict audit corpus + advisory integration alignment **2026-04-21**. Archives: [`milestones/v1.6-ROADMAP.md`](milestones/v1.6-ROADMAP.md), [`milestones/v1.6-REQUIREMENTS.md`](milestones/v1.6-REQUIREMENTS.md), [`milestones/v1.6-MILESTONE-AUDIT.md`](milestones/v1.6-MILESTONE-AUDIT.md).
- ✅ **v1.7 Adoption DX + operator admin depth** — Phases **32–36** shipped **2026-04-21**. VERIFY-01 + doc graph, installer and CI clarity, operator home/drill/nav, dashboard `AccrueAdmin.Copy` SSOT, audit corpus + verifier ownership map. Archives: [`milestones/v1.7-ROADMAP.md`](milestones/v1.7-ROADMAP.md), [`milestones/v1.7-REQUIREMENTS.md`](milestones/v1.7-REQUIREMENTS.md), [`milestones/v1.7-MILESTONE-AUDIT.md`](milestones/v1.7-MILESTONE-AUDIT.md).
- ✅ **v1.8 Org billing recipes & host integration depth** — Phases **37–39** shipped **2026-04-22**. Delivers deferred **ORG-04**. Archives: [`milestones/v1.8-ROADMAP.md`](milestones/v1.8-ROADMAP.md), [`milestones/v1.8-REQUIREMENTS.md`](milestones/v1.8-REQUIREMENTS.md).
- ○ **v1.9 Observability & operator runbooks** — Phases **40–42** (planning opened **2026-04-21**). Requirements: [`.planning/REQUIREMENTS.md`](REQUIREMENTS.md). Gap audit: [`.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md`](research/v1.9-TELEMETRY-GAP-AUDIT.md).

## Phases

### v1.9 Observability & operator runbooks (Phases 40–42)

**Milestone goal:** Close the adoption gap between “telemetry exists” and “operators know what to subscribe to, alert on, and do next” — **without** new billing primitives or Stripe Dashboard parity.

**Depends on:** v1.0+ telemetry stack (`Accrue.Telemetry`, `Accrue.Telemetry.Ops`, optional `Accrue.Telemetry.Metrics`).

| # | Phase | Goal | Requirements |
|---|-------|------|----------------|
| 40 | Telemetry catalog + guide truth | Extend `guides/telemetry.md` (and `Accrue.Telemetry.Ops` docs) so every `[:accrue, :ops, :*]` emit is catalogued; document firehose vs ops split; reconcile against `.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md`. **Complete 2026-04-22.** | OBS-01, OBS-03, OBS-04 |
| 41 | 3/3 | Complete    | 2026-04-22 |
| 42 | Operator runbooks | Ship runbook section (guide or linked doc): ops event → suggested first action / Stripe host checks / Oban queues — especially DLQ, meters, dunning, revenue-adjacent signals, Connect failures. | RUN-01 |

**Success criteria (milestone):**

1. No undocumented `[:accrue, :ops, :*]` event from the v1.9 gap audit §1 remains absent from the published catalog (OBS-01 + OBS-04).
2. A host developer can wire `Accrue.Telemetry.Metrics.defaults/0` with documented parity to ops signals (TEL-01).
3. Runbook entries exist for each ops class called out in **RUN-01** (RUN-01).

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

Earlier shipped phases (1–17) remain in per-milestone roadmap archives under `.planning/milestones/`.

---

For full archived phase details, decisions, and requirements traceability, see `.planning/milestones/`.
