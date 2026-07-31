# Roadmap: Accrue

## Milestones

- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154-158 (shipped 2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.48 Release Readiness + Stable Core Posture** — Phases 159-162 (shipped 2026-06-01) — [archive](milestones/v1.48-ROADMAP.md)
- ✅ **v1.49 Realistic Demo App & Adoption Evidence** — Phases 163-166 (shipped 2026-06-02) — [archive](milestones/v1.49-ROADMAP.md)
- ✅ **v1.50 Admin UI Foundation** — Phases 167-173 (shipped 2026-06-02 via PR #32; archived 2026-06-03) — [archive](milestones/v1.50-ROADMAP.md)
- ✅ **v1.51 Admin UI: Depth Pass (IA + Systematic Polish)** — Phases 174-179 (shipped 2026-06-04) — [archive](milestones/v1.51-ROADMAP.md)
- ✅ **v1.52 Brand System** — Phases 180-186 (shipped 2026-06-14) — [archive](milestones/v1.52-ROADMAP.md)
- ✅ **v1.53 Admin UI Design-System Hardening** — Phases 187-192 (shipped 2026-06-20) — [archive](milestones/v1.53-ROADMAP.md)
- ✅ **v1.54 Admin UI Page-Level Streamlining & Storybook** — Phases 193-200 (shipped 2026-07-01) — [archive](milestones/v1.54-ROADMAP.md)
- ✅ **v1.55 OSS Quality Evaluation & Hardening Roadmap** — Phases 201-204 (shipped 2026-07-03) — [archive](milestones/v1.55-ROADMAP.md)
- ⏸️ **v1.56 Admin UI Ratchet: Automated Adversarial Design Evaluation** — Phases 205-208 (PARKED 2026-07-19; 205-207 shipped, 208 was 3/5 and non-converging on IA findings — the work v1.57 took on; ledger + baseline preserved in `accrue_admin/e2e/ratchet/`) — [archive](milestones/v1.56-ROADMAP.md)
- ✅ **v1.57 Admin Operator Control Plane (SEED-004 M1)** — Phases 209-211 (shipped 2026-07-30; reigned Home + Subscriptions onto the shared operator-first component vocabulary + answer-first IA, retired the bespoke `.ax-*` sets, and closed UAT via a deterministic Playwright pixel-diff gate) — [archive](milestones/v1.57-ROADMAP.md)
- 🔨 **v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync** — Phases 212-214 (ACTIVE, opened 2026-07-30; bump `lattice_stripe` 1.x→2.x with the Three Zeros gate green across all packages, adopt the new `LatticeStripe.Entitlements.*` surface as an opt-in observational-only advisory sync closing the Phase 127 deferral, and reconcile docs/truth — SEED-005)

## Planning Doctrine

Accrue is in **stable core / demand-driven expansion** posture as of 2026-05-31. Future feature milestones require at least one of:

- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- an operational release/support failure,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

**v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync is open** (Phases 212-214, opened 2026-07-30). Reopen justification class: **maintenance / dependency currency plus closing a prior explicitly-deferred capability** — SEED-005's trigger fired 2026-07-29 (lattice_stripe `2.0.0` published on Hex with entitlements support), unblocking Phase 127's deferred optional Stripe-native entitlements sync now that the `LatticeStripe.Entitlements.*` primitives exist. Recorded in `PROJECT.md`. This is **not** a broad feature milestone: it stays inside the already-shipped entitlements feature, keeps the local plan→feature map canonical as the sole grant gate (D-01/D-11), and keeps `scripts/ci/verify_entitlement_sync_isolation.sh` green (extended to the new client-fetch surface this milestone). Pin target is `~> 2.0`, not `~> 2.1`; no new required deps, no admin redesign, no `accrue_portal` work. v1.57 (SEED-004 M1) shipped 2026-07-30 under the *explicit strategy change* reopen class (flagship adopter-facing admin surface, elevated to a strategic redesign — same class accepted for v1.50–v1.54). The next SEED-004 candidate is **M2** (signature "Why blocked?" diagnosis surfaces + causality graph + the first core `accrue` diagnosis functions), deferred pending a separate `/gsd-new-milestone` reopen decision recorded in `PROJECT.md`.

**v1.56 Admin UI Ratchet is PARKED** (2026-07-19) mid-flight. Phases 205-207 shipped; Phase 208 (prove-convergence + ACCEPT) was 3/5 with 208-04/05 maintainer-gated and **non-converging because the ratchet kept surfacing information-architecture findings** — which is exactly the work v1.57/SEED-004 took on and shipped. The forward-only ledger + frozen baseline in `accrue_admin/e2e/ratchet/` are preserved untouched; per its own design the harness re-freezes the v1.57 redesign after M3 lands. The 23 round-99 confirmed IA findings were carried into v1.57 as M1 input (`research/admin-ratchet-round99-confirmed-findings.json`). To resume v1.56 later: restore from the archive and run `/gsd-execute-phase 208`.

Stop rule: if proposed work is polish-only with a documented workaround and no release/adopter failure mode, record it as deferred with a revisit trigger and do not create a milestone for it.

## Phases

### 🔨 v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync (Phases 212-214) — ACTIVE (opened 2026-07-30)

**Posture:** Move Accrue onto `lattice_stripe ~> 2.0` (major 1.x→2.x bump), reconcile the major-version deltas with the Three Zeros gate (test/dialyzer/credo/coverage) green across every package, then adopt the new `LatticeStripe.Entitlements.{ActiveEntitlement, ActiveEntitlementSummary, Feature}` surface as a client-backed, opt-in, **observational-only** advisory refresh path into the existing entitlements cache — closing the Phase 127 "optional Stripe-native entitlements sync" deferral (SEED-005) — before reconciling docs/truth. **Scope fence (binding):** the sync is a read seam, **never** a grant gate — the local plan→feature map (`resolver/local_map.ex`) remains the sole canonical gate (D-01/D-11), and `scripts/ci/verify_entitlement_sync_isolation.sh` stays green and is extended to the new client-fetch path; pin target is `~> 2.0` (not `~> 2.1`); no new required dependencies; no new admin nav rooms or admin redesign (SEED-004 M2/M3 territory); no `accrue_portal` work; sync tests run only against the Fake/Test processor (no live Stripe, no Chrome, fully `async`-safe). Any processor-surface/support-matrix implication updates behavior, docs, examples/verifiers, and release notes together in the same phase (stable-core rule). Authoritative sources: `.planning/seeds/SEED-005-lattice-stripe-entitlements-bump.md`, `accrue/lib/accrue/entitlements/*`, `scripts/ci/verify_entitlement_sync_isolation.sh`, CLAUDE.md Technology Stack + Version Compatibility Matrix, `guides/jobs_to_be_done.md` + `.planning/research/JTBD-FRONTIER.md`.

- [x] **Phase 212: lattice_stripe 2.x bump & green reconciliation** - Bump the `:lattice_stripe` pin to `~> 2.0` across every resolving package, reconcile the two verified 2.0.0 breaking vectors, and bring the Three Zeros gate green with no new skips (BUMP-01, BUMP-02, BUMP-03) — completed 2026-07-30
- [x] **Phase 213: Stripe-native advisory entitlements sync (observational-only)** - Adopt a client-backed, opt-in refresh path into the advisory cache via `LatticeStripe.Entitlements.*`, extend the isolation-guard script to the new surface, resolve the D-07 `fetch_entitled/2` question, and prove by Fake-processor test that the sync can never become a gate (SYNC-01, SYNC-02, SYNC-03, SYNC-04, SYNC-05) — final re-verification passed 13/13 truths on 2026-07-31 (completed 2026-07-30)
- [ ] **Phase 214: Docs & truth reconciliation** - Bring CLAUDE.md, the JTBD guides, and per-package changelogs/release notes into agreement with the shipped 2.x bump and the new observational sync (DOCS-01, DOCS-02, DOCS-03)

Coverage: **11/11 requirements** mapped to Phases 212-214 (each REQ-ID → exactly one phase). Per-phase counts: 212→3 · 213→5 · 214→3. Dependencies: strictly linear — 212 → 213 → 214 (nothing else compiles against 2.x until the bump lands green; the sync adoption needs the 2.x `LatticeStripe.Entitlements.*` modules present; docs reconcile against the final shipped behavior of both). Full per-phase goals + success criteria: see [Phase Details](#phase-details-v158-active-milestone).

<details>
<summary>✅ v1.57 Admin Operator Control Plane (SEED-004 M1) (Phases 209-211) — SHIPPED 2026-07-30</summary>

**Posture:** First slice (M1) of the SEED-004 redesign of `accrue_admin` from a CRUD surface into an "operator control plane over billing state." M1 reigned the two outlier pages — **Home** (`dashboard_live.ex`) and **Subscriptions** (`subscriptions_live.ex`) — onto the canonical shared component vocabulary (PageHeader / StatStrip / DataTable / FilterChipBar / `.ax-card` / Button / StatusBadge / EmptyState / KpiCard / Timeline / Icon), pivoted their information architecture to **answer-first** (one scannable health verdict + one primary action per zone, redundant bands trimmed), and retired the bespoke `.ax-home-*` / `.ax-launcher*` / `.ax-attention*` / `.ax-subscriptions-*` sets (97 selectors). Admin-only; no core `accrue` change, no new nav rooms, no new deps. UAT closed with zero human checkpoints via a new deterministic Playwright `toHaveScreenshot` pixel-diff gate.

- [x] Phase 209: Reign Subscriptions (list + detail CSS coordination) (3/3 plans) — completed 2026-07-19 (REIGN-01, REIGN-02, COMP-01)
- [x] Phase 210: Reign Home + certify answer-first IA & copy integrity (3/3 plans) — completed 2026-07-19 (REIGN-03, IA-01, IA-02, IA-03, IA-04, COPY-01, COPY-02)
- [x] Phase 211: Grep-gated CSS retirement & cross-surface cleanup (4/4 plans) — completed 2026-07-29 (REIGN-04)

Coverage: 11/11 requirements complete. Milestone audit passed (11/11 reqs, 3/3 phases, 5/5 integration, 5/5 flows). Full details: [v1.57 roadmap archive](milestones/v1.57-ROADMAP.md).

</details>

<details>
<summary>⏸️ v1.56 Admin UI Ratchet: Automated Adversarial Design Evaluation (Phases 205-208) — PARKED 2026-07-19</summary>

**Posture:** Maintainer-run, forward-only "UI Ratchet" that automates fan-out adversarial design evaluation → dedup → verify → batch-fix → re-score → loop-until-dry over `accrue_admin` (dev/test-only tooling + admin CSS polish). **PARKED mid-flight** to open v1.57: Phases 205-207 shipped; Phase 208 (prove-convergence + ACCEPT) reached 3/5 with 208-04/05 maintainer-gated and non-converging on IA findings — the work v1.57 took on and shipped. The ledger + frozen baseline in `accrue_admin/e2e/ratchet/` are preserved untouched and become the tool that re-locks the v1.57 redesign after M3. The v1.56 optional "full-surface sweep" placeholder (originally numbered 209, `SWEEP-01`) was never created as a phase; **phase number 209 was reused by v1.57**.

- [x] Phase 205: Persona + design-lens evaluator harness (5/5 plans) — completed 2026-07-03 (EVAL-01..05, DEDUP-01, DEDUP-02)
- [x] Phase 206: Adversarial verifier + finding ledger + deterministic gate (4/4 plans) — completed 2026-07-04 (DEDUP-03, VERIFY-01..03, LEDGER-01..05)
- [x] Phase 207: Orchestration + digest + one-command round/fix loop (8/8 plans) — completed 2026-07-07 (ORCH-01..08)
- [ ] Phase 208: Prove convergence on slice + wire CI + ACCEPT (3/5 plans) — PARKED (CONV-01..07)

Coverage: 31/31 requirements mapped to Phases 205-208. To resume: restore from `milestones/v1.56-ROADMAP.md` / `milestones/v1.56-phases/` and run `/gsd-execute-phase 208`. Full details: [v1.56 roadmap archive](milestones/v1.56-ROADMAP.md).

</details>

<details>
<summary>✅ v1.55 OSS Quality Evaluation & Hardening Roadmap (Phases 201-204) — SHIPPED 2026-07-03</summary>

**Posture:** Audit-only maintenance / release-readiness / support-contract hardening under stable core. The milestone produced evidence-backed audits and a ranked implementation roadmap. It did **not** change product behavior, public APIs, DB defaults, CI required-check topology, package release automation, or runtime UI.

- [x] Phase 201: Software quality evaluation (QLT-01..05). Completed 2026-07-02.
- [x] Phase 202: CI/CD performance and determinism audit (CI-01..05). Completed 2026-07-02.
- [x] Phase 203: Database schema contract ADR (DB-01..04). Completed 2026-07-02.
- [x] Phase 204: Ranked hardening roadmap (RD-01..04). Completed 2026-07-03.

Coverage: 18/18 requirements complete. Full details: [v1.55 roadmap archive](milestones/v1.55-ROADMAP.md).

</details>

<details>
<summary>✅ v1.54 Admin UI Page-Level Streamlining & Storybook (Phases 193-200) — SHIPPED 2026-07-01</summary>

- [x] Phase 193: Research, re-baseline & pattern lock (5/5 plans) — completed 2026-06-25
- [x] Phase 194: Exemplar A — Dashboard (4/4 plans) — completed 2026-06-26
- [x] Phase 195: Exemplar B — Subscription detail (8/8 plans) — completed 2026-06-26
- [x] Phase 196: Exemplar C — Subscriptions list + PageHeader (5/5 plans) — completed 2026-06-26
- [x] Phase 197: Propagate LIST (7/7 plans) — completed 2026-06-28
- [x] Phase 198: Propagate DETAIL + analytics (9/9 plans) — completed 2026-06-29
- [x] Phase 199: Cross-cutting interaction/overlay correctness + fixture stress + microcopy (15/15 plans) — completed 2026-06-30
- [x] Phase 200: Idempotent verification & sign-off (6/6 plans) — completed 2026-06-30, accepted

Coverage: 23/23 requirements complete. Full details: [v1.54 roadmap archive](milestones/v1.54-ROADMAP.md)

</details>

<details>
<summary>✅ v1.53 Admin UI Design-System Hardening (Phases 187-192) — SHIPPED 2026-06-20</summary>

- [x] Phase 187: Audit & Baseline (5/5 plans) — completed 2026-06-15 (VER-01)
- [x] Phase 188: Foundations hardening (8/8 plans) — completed 2026-06-20 (FND-01..06)
- [x] Phase 189: Primitive & form components + component lab (7/7 plans) — completed 2026-06-18 (CMP-01..05)
- [x] Phase 190: Navigation, data-display & meta-component cohesion (6/6 plans) — completed 2026-06-18 (GRP-01..04)
- [x] Phase 191: Page & flow interaction pass + fixture stress + microcopy (7/7 plans) — completed 2026-06-19 (IXN-01..05, PAGE-01..04, CPY-01..03, SEED-01..02)
- [x] Phase 192: Idempotent verification & sign-off (6/6 plans) — completed 2026-06-20 (VER-02..04)

Coverage: 33/33 requirements. Full details: [v1.53 roadmap archive](milestones/v1.53-ROADMAP.md)

</details>

<details>
<summary>✅ v1.52 Brand System (Phases 180-186) — SHIPPED 2026-06-14</summary>

- [x] Phase 180: Brand Audit & DNA Lock (4/4 plans) — completed 2026-06-12 (AUD-01..03)
- [x] Phase 181: SVG Pipeline + Tournament Round 1 — Divergent (7/7 plans) — completed 2026-06-13 (LOGO-01, LOGO-02)
- [x] Phase 182: Tournament Convergent Refinement (3/3 plans) — completed 2026-06-13 (LOGO-03); winner locked: R2-7 two-tone
- [x] Phase 183: Logo System Production (4/4 plans) — completed 2026-06-13 (LOGO-04)
- [x] Phase 184: Design Tokens & Specimens (5/5 plans) — completed 2026-06-14 (TOK-01..03)
- [x] Phase 185: Voice, Microcopy & Marketing Copy (3/3 plans) — completed 2026-06-14 (COPY-01, COPY-02)
- [x] Phase 186: HTML Brand Book Assembly & Quality Gate (3/3 plans) — completed 2026-06-14 (BOOK-01, BOOK-02)

Full details: [v1.52 roadmap archive](milestones/v1.52-ROADMAP.md)

</details>

<details>
<summary>✅ v1.51 Admin UI: Depth Pass (Phases 174-179) — SHIPPED 2026-06-04</summary>

Full details: [v1.51 roadmap archive](milestones/v1.51-ROADMAP.md)

</details>

<details>
<summary>✅ v1.50 Admin UI Foundation (Phases 167-173) — SHIPPED 2026-06-02 (PR #32; archived 2026-06-03)</summary>

- [x] Phase 167-173 — completed 2026-06-02 (AUI-01..07)

Full details: [v1.50 roadmap archive](milestones/v1.50-ROADMAP.md)

</details>

<details>
<summary>✅ v1.49 Realistic Demo App & Adoption Evidence (Phases 163-166) — SHIPPED 2026-06-02</summary>

Full details: [v1.49 roadmap archive](milestones/v1.49-ROADMAP.md)

</details>

<details>
<summary>✅ v1.48 Release Readiness + Stable Core Posture (Phases 159-162) — SHIPPED 2026-06-01</summary>

Full details: [v1.48 roadmap archive](milestones/v1.48-ROADMAP.md)

</details>

## Phase Details (v1.58 active milestone)

### Phase 212: lattice_stripe 2.x bump & green reconciliation

**Goal**: Every Accrue package (`accrue`, `accrue_admin`, `accrue_portal`, `examples/accrue_host`, and any sibling that independently pins the dep) resolves and compiles clean against `lattice_stripe ~> 2.0`, with the Three Zeros gate green — nothing else in this milestone can proceed until the bump lands green, since the Phase 213 entitlements surface only exists on 2.x.
**Depends on**: Nothing (first phase of v1.58; continues numbering from v1.57's Phase 211)
**Requirements**: BUMP-01, BUMP-02, BUMP-03
**Success Criteria** (what must be TRUE):

  1. `accrue/mix.exs` pins `{:lattice_stripe, "~> 2.0"}` (not `~> 2.1`), and `mix.lock` in `accrue`, `accrue_admin`, `accrue_portal`, and `examples/accrue_host` all resolve to the same 2.x release, committed together in one change; any sibling package that independently pins `:lattice_stripe` is bumped in lockstep in the same change.
  2. Every `LatticeStripe.*` call site across core lib, admin, portal, examples, and test support compiles with zero deprecation warnings against 2.x.
  3. The two pre-verified 2.0.0 breaking vectors — the fixture-builder `<object>_json` rename and the optional/default-wired Finch pool — are each confirmed as needing no Accrue-side change (documented), or reconciled if the pre-open confirmation turns out to be wrong.
  4. `mix test`, `mix dialyzer`, `mix credo --strict`, and coverage (the Three Zeros gate) are green across every package on the bumped deps, with zero new skips/exclusions introduced to make it pass, and any dialyzer PLT churn from the major bump absorbed (PLTs rebuild clean in CI).
  5. A fresh `mix deps.get && mix compile --warnings-as-errors` on each package from a clean checkout succeeds with no warning or error attributable to the lattice_stripe bump.

**Plans:** 1/1 plans complete

Plans:

- [x] 212-01-PLAN.md — Bump `:lattice_stripe` to `~> 2.0`, regenerate all four lockfiles in path mode, run each package's actually-configured Three Zeros gate, and commit the atomic 5-file bump plus a D-10 evidence artifact

### Phase 213: Stripe-native advisory entitlements sync (observational-only)

**Goal**: Close the Phase 127 "optional Stripe-native entitlements sync" deferral by wiring a client-backed, opt-in refresh path into the existing advisory entitlements cache via the new `LatticeStripe.Entitlements.*` 2.x surface — while proving, by test, that the sync can never become a grant gate and that the isolation guard now covers the new surface.
**Depends on**: Phase 212 (the 2.x `LatticeStripe.Entitlements.*` modules must be present and compiling)
**Requirements**: SYNC-01, SYNC-02, SYNC-03, SYNC-04, SYNC-05
**Success Criteria** (what must be TRUE):

  1. A client-backed refresh path (`Accrue.Entitlements.StripeSync` or equivalent) fetches a customer's active Stripe entitlements via `LatticeStripe.Entitlements.{ActiveEntitlement, ActiveEntitlementSummary}` and writes them into `Accrue.Billing.EntitlementSummary` — a genuine pull/refresh, not a webhook-payload-only path.
  2. The sync is off by default and only activates under the existing `stripe_native_sync: :advisory` config seam; toggling the config off makes the refresh path a no-op, and its output is observable only on diagnostic/admin read surfaces — no resolver or guard code path reads from it.
  3. `scripts/ci/verify_entitlement_sync_isolation.sh` stays green and is extended so a deliberately-wired `gate → seam` edge on the new client-fetch entry point makes the script fail — proving the isolation guard actually covers the new surface, not just the pre-existing webhook path.
  4. The D-07 `fetch_entitled/2` question left open in `admin.ex` is closed one way or the other this milestone: either implemented as part of the advisory refresh surface (observational-only), or explicitly deferred with a one-line recorded reason in code and docs — no ambiguity remains.
  5. A test suite using only the Fake/Test processor (no live Stripe, no Chrome, fully `async`-safe) proves: the cache populates correctly from `LatticeStripe.Entitlements.*` results; a grant decision is identical whether the advisory cache is empty, stale, or directly contradicts the local plan→feature map; and the config defaults to off.

**Plans:** 5/5 plans complete

Plans:
**Wave 1**

- [x] 213-01-PLAN.md — Prove the Fake-backed refresh tracer and shared pull/webhook ordering contract

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 213-02-PLAN.md — Wire the exhaustive LatticeStripe adapter and existing-queue refresh worker
- [x] 213-03-PLAN.md — Enforce the isolation boundary and close the Stripe-backed predicate ambiguity

**Wave 3** *(gap closure; blocked on completed Waves 1-2)*

- [x] 213-04-PLAN.md — Close optional-callback safety and deterministic same-second webhook ordering gaps

**Wave 4** *(gap closure; blocked on completed Wave 3)*

- [x] 213-05-PLAN.md — Extend the isolation guard across the shared Plug/LiveView Guard path

### Phase 214: Docs & truth reconciliation

**Goal**: Every public and planning doc surface that mentions `lattice_stripe`'s version or the entitlements sync status tells the same, currently-true story — closing the stale `~> 0.2` matrix cell and flipping the Phase 127 deferral note to shipped/observational.
**Depends on**: Phase 213 (docs describe the final shipped sync behavior, not a moving target)
**Requirements**: DOCS-01, DOCS-02, DOCS-03
**Success Criteria** (what must be TRUE):

  1. `CLAUDE.md`'s Technology Stack `:lattice_stripe` row and Version Compatibility Matrix anchor pin both read `~> 2.0` with an entitlements note, correcting the stale `~> 0.2` matrix cell.
  2. `guides/jobs_to_be_done.md` and `.planning/research/JTBD-FRONTIER.md` both flip the "optional Stripe-native sync deferred" status to shipped/observational, without ever describing it as authoritative for a grant decision.
  3. Per-package CHANGELOG/release notes record the major dep bump and the new advisory sync, every new public function carries an `@since` annotation, and the adoption-proof / support-matrix / planning-mirror docs describe one consistent stable-core posture (POS-03) with no contradiction between any two of them.
  4. A reviewer grepping for "lattice_stripe" or "entitlements sync" across `CLAUDE.md`, `guides/`, package CHANGELOGs, and `.planning/` mirrors finds one consistent version/status story, not several conflicting ones.

**Plans**: 2 plans

Plans:
**Wave 1**

- [x] 214-01-PLAN.md — Establish and enforce the current version/advisory-authority truth contract across public, support, adoption, and planning mirrors.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 214-02-PLAN.md — Reconcile linked release notes/changelogs and exact ExDoc `since: "1.5.0"` metadata.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 201. Software quality evaluation | v1.55 | 1/1 | Complete | 2026-07-02 |
| 202. CI/CD performance and determinism audit | v1.55 | 1/1 | Complete | 2026-07-02 |
| 203. Database schema contract ADR | v1.55 | 1/1 | Complete | 2026-07-02 |
| 204. Ranked hardening roadmap | v1.55 | 1/1 | Complete | 2026-07-03 |
| 205. Persona + design-lens evaluator harness | v1.56 | 5/5 | Complete | 2026-07-03 |
| 206. Adversarial verifier + finding ledger + deterministic gate | v1.56 | 4/4 | Complete | 2026-07-04 |
| 207. Orchestration + digest + one-command round/fix loop | v1.56 | 8/8 | Complete | 2026-07-07 |
| 208. Prove convergence on slice + wire CI + ACCEPT | v1.56 | 3/5 | Parked | - |
| 209. Reign Subscriptions (list + detail CSS coordination) | v1.57 | 3/3 | Complete | 2026-07-19 |
| 210. Reign Home + certify answer-first IA & copy integrity | v1.57 | 3/3 | Complete | 2026-07-19 |
| 211. Grep-gated CSS retirement & cross-surface cleanup | v1.57 | 4/4 | Complete | 2026-07-29 |
| 212. lattice_stripe 2.x bump & green reconciliation | v1.58 | 1/1 | Complete | 2026-07-30 |
| 213. Stripe-native advisory entitlements sync (observational-only) | v1.58 | 5/5 | Complete    | 2026-07-31 |

## Historical Backlog Anchors (not active scope)

These v1.17 FRG anchors are retained for traceability only as historical, non-active planning context. They do not create milestone scope unless a fresh sourced friction row meets the current stable-core evidence bar.

- [INT-10 Phase 63](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63) — Historical / non-active Braintree and multi-processor integration anchor; materially shipped across v1.31+. Reopen only for a concrete adopter failure mode or operational failure in the shipped processor-support contract.
- [BIL-03 Phase 64](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64) — Historical / non-active billing portal configuration anchor; materially shipped via `accrue_portal`, guides, and host proof. Reopen only for a repeated support issue or correctness/data-loss risk in the portal support surface.
- [ADM-12 Phase 65](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65) — Historical / non-active admin UI role-based access anchor. Reopen only for a concrete security/compliance requirement or explicit strategy change.

## Deferred Seeds and Ideas (dormant / trigger-bound)

| Item | Status | Reason | Future owner/category | Revisit trigger |
|------|--------|--------|-----------------------|-----------------|
| SEED-004 M2 (signature diagnostic surfaces + core diagnosis) | deferred (next after v1.57 M1) | The "Why blocked?" diagnosis card, causality graph/timeline, unified `billing_state_for_customer/1` synthesis, freshness/stale chips, and the core `accrue` diagnosis fns they require (`blocking_reason_for_owner/1`, `causality_chain_for_event/1`) + durable event-name contracts. First admin-UI line to reach into core `accrue`. | Admin UI / IA + core diagnosis | v1.57 M1 shipped 2026-07-30 → `/gsd-new-milestone` (reopen class: explicit strategy change) |
| SEED-004 M3 (new rooms + structure + ratchet re-freeze) | deferred (after M2) | New Usage/meters, checkout-sessions, Connect-capabilities, fee-reconciliation rooms; `+Usage`/`+Settings` nav groups; de-tab Customer-360; and the v1.56-ratchet re-freeze (refresh design-lens rubric + persona exemplars + re-freeze baseline) that re-locks the landed redesign. | Admin UI / IA + ratchet | after M2 lands; ratchet re-freeze is post-M3 |
| v1.56 SWEEP-01 (full-surface ratchet sweep) | parked with v1.56 | Graduate the remaining ~19 admin surfaces round-by-round under the proven ratchet. Parked with the v1.56 milestone; the ratchet re-freeze after SEED-004 lands supersedes the original sweep target. | Ratchet / admin design QA | v1.56 resumed, or post-M3 ratchet re-freeze |
| lattice_stripe 2.0.0 entitlements dep bump (SEED-005) | promoted → v1.58 (opened 2026-07-30) | Trigger fired 2026-07-29 (lattice_stripe 2.0.0 live on Hex with entitlements support); the major 1.x→2.0 bump plus Stripe-native entitlements sync adoption is now active milestone scope (Phases 212-214). | Core deps / entitlements | in flight; superseded by v1.58 closeout |
| TOOL-02 (pixel-diff visual-regression) | resolved (superseded by v1.57 gate) | Percy/Applitools-style pixel-diff tooling was deferred in favor of the scored-cell forward-only gate; v1.57 introduced a first-party deterministic Playwright `toHaveScreenshot` pixel-diff gate (4 admin surfaces × light/dark) in browser-uat. | Visual-regression tooling | broaden surface coverage, or replace with a hosted service on explicit strategy change |
| TOOL-03 (publish tokens.css distributable) | deferred (v1.53) | Standalone npm/CDN token distributable not needed for the admin passes. | Brand/token distribution | external doc/marketing-site need for distributable tokens |
| ENT-EXT-01 | deferred | Rich metered/tiered/range entitlement math beyond current seat-count support; no sourced adopter contract. | Entitlements extension | concrete adopter failure or explicit adopter contract |
| FIN-03 | standing non-goal | App-owned finance exports remain outside Accrue's declared billing-library scope. | Strategy non-goal / finance exports | explicit strategy change or correctness/security/data-loss risk not solvable by host-owned exports |
| SEED-002 | dormant future roadmap | Ecosystem integrations are useful blueprints but do not create default milestone scope. | Future roadmap / ecosystem integrations | concrete adopter failure requiring one listed integration, repeated support issue, or explicit strategy change |
| SEED-001 | resolved historical context | Linked-release purpose was superseded by later linked publish work and Phase 159 release-readiness proof. | Release readiness / archive traceability | operational failure in linked release proof or explicit strategy change in release process |
