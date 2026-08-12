# Roadmap: Accrue

## Milestones

- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154-158 (shipped 2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.48 Release Readiness + Stable Core Posture** — Phases 159-162 (shipped 2026-06-01) — [archive](milestones/v1.48-ROADMAP.md)
- ✅ **v1.49 Realistic Demo App & Adoption Evidence** — Phases 163-166 (shipped 2026-06-02) — [archive](milestones/v1.49-ROADMAP.md)
- ✅ **v1.50 Admin UI Foundation** — Phases 167-173 (shipped 2026-06-02; archived 2026-06-03) — [archive](milestones/v1.50-ROADMAP.md)
- ✅ **v1.51 Admin UI: Depth Pass** — Phases 174-179 (shipped 2026-06-04) — [archive](milestones/v1.51-ROADMAP.md)
- ✅ **v1.52 Brand System** — Phases 180-186 (shipped 2026-06-14) — [archive](milestones/v1.52-ROADMAP.md)
- ✅ **v1.53 Admin UI Design-System Hardening** — Phases 187-192 (shipped 2026-06-20) — [archive](milestones/v1.53-ROADMAP.md)
- ✅ **v1.54 Admin UI Page-Level Streamlining & Storybook** — Phases 193-200 (shipped 2026-07-01) — [archive](milestones/v1.54-ROADMAP.md)
- ✅ **v1.55 OSS Quality Evaluation & Hardening Roadmap** — Phases 201-204 (shipped 2026-07-03) — [archive](milestones/v1.55-ROADMAP.md)
- ⏸️ **v1.56 Admin UI Ratchet: Automated Adversarial Design Evaluation** — Phases 205-208 (parked 2026-07-19) — [archive](milestones/v1.56-ROADMAP.md)
- ✅ **v1.57 Admin Operator Control Plane (SEED-004 M1)** — Phases 209-211 (shipped 2026-07-30) — [archive](milestones/v1.57-ROADMAP.md)
- ✅ **v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync** — Phases 212-214.2 (shipped 2026-07-31; 11/11 requirements and 5/5 flows passed with documented non-blocking tech debt) — [archive](milestones/v1.58-ROADMAP.md)
- ✅ **v1.59 Account-Scoped Multi-Rail & Offline Entitlements** — Phases 215-222 (shipped 2026-08-05; 29/29 requirements, 11/11 integration links, and 5/5 E2E flows passed) — [archive](milestones/v1.59-ROADMAP.md)
- ⏸️ **v1.60 First-Adopter iOS Bridge & Proof** — override closeout 2026-08-08; Phases 223-224 verified, Phases 225-226 deferred — [archive](milestones/v1.60-ROADMAP.md)
- 🚧 **v1.61 CI Evidence & Critical-Path Hardening** — Phases 225-227 (planned)

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

Historical friction-backlog anchors remain canonical in the [v1.17 inventory](research/v1.17-FRICTION-INVENTORY.md): [INT-10 / Phase 63](research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63), [BIL-03 / Phase 64](research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64), and [ADM-12 / Phase 65](research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65).

v1.60 clears that bar through an active first-adopter iOS delivery. It reuses the v1.59 Apple/offline contract, keeps StoreKit binding host-owned, and cannot promote Crosswake runtime capability without its separate physical-device proof. Google Play remains backlogged in SEED-007 until Android is scheduled or a second adopter requires it.

## Phases

Completed and deferred v1.60 details are retained in [the milestone archive](milestones/v1.60-ROADMAP.md). A future milestone must explicitly re-scope the deferred StoreKit and readiness work.

### 🚧 v1.61 CI Evidence & Critical-Path Hardening (Planned)

**Milestone Goal:** Restore trustworthy required CI evidence, then reduce proven critical-path waste without weakening release, host, browser, or provider proof.

**Constraints:** Treat one shared release-matrix failure signature as one incident, not four cell incidents. Investigate the recent Admin Playwright timeout trace-first; do not mask it with retries or deletion. Baseline evidence must precede topology, cache, matrix, branch-protection, or required-gate changes. Keep stable required-check identities, artifacts, and explicit provider `proved` / `skipped` / `advisory` status. StoreKit/iPhone/Crosswake and the parked Admin UI ratchet are out of scope.

- [ ] **Phase 225: Required-Lane Signal Repair** - Classify and repair current required CI failures without hiding their diagnostic evidence.
- [ ] **Phase 226: CI Baseline & Proof Semantics** - Publish the comparable-run baseline and make provider/setup ownership legible.
- [ ] **Phase 227: Measured Critical-Path Improvement** - Remove one proven setup or dependency cost while retaining every required proof.

## Phase Details

### Phase 225: Required-Lane Signal Repair

**Goal**: Maintainers can trust the current required release and Admin CI signal because every active failure has a trace-backed classification and its actual cause is repaired.
**Depends on**: Nothing (first v1.61 phase)
**Requirements**: REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):

  1. A maintainer can reproduce each current required-lane failing signature and read its classification as deterministic code/configuration, test-isolation, lifecycle, or external infrastructure.
  2. Required release and Admin checks pass after the responsible cause is repaired, while their meaningful assertions and failure artifacts remain available.
  3. A shared signature across release-matrix cells is recorded and triaged as one root-cause incident rather than counted once per cell.
  4. The Admin Playwright timeout has trace-first evidence and a diagnosis or repair path; no retry-only, masking, or test-deletion workaround represents resolution.

**Plans:** 3 plans

Plans:
**Wave 1**

- [x] 225-01-PLAN.md — Normalize both incidents and repair webhook test isolation with event-owned proof.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 225-02-PLAN.md — Partition the Admin page-flow budget and repair Phase 192 artifact truth.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 225-03-PLAN.md — Record full local evidence and bind closure to a fresh repair-commit Actions run.

### Phase 226: CI Baseline & Proof Semantics

**Goal**: Maintainers can use a durable, privacy-safe account of comparable CI runs to distinguish the actual critical path, setup ownership, and provider proof state.
**Depends on**: Phase 225
**Requirements**: BASE-01, BASE-02, OWN-01
**Success Criteria** (what must be TRUE):

  1. A maintainer can inspect a durable comparable-run baseline containing workflow wall time, queue delay, job/step durations, reruns, cache behavior, Docker/browser setup cost, provider state, and root-failure signature without sensitive values.
  2. Required, skipped, and advisory provider evidence is visibly distinct, so a skipped or non-run lane cannot be read as release proof.
  3. A host maintainer can identify whether Node, browser installation, and Playwright setup belong to the host or CI and can follow documented diagnostics for each setup failure mode.
  4. The baseline confirms the roughly 33–36 minute green-run critical path is staged release → host integration → Playwright work rather than runner queueing, or records a contrary measured result.

**Plans:** 11 plans

Plans:
**Wave 1**

- [x] 226-01-PLAN.md — Build the comparable-run schema, collector, renderer, and deterministic validation engine.
- [x] 226-03-PLAN.md — Build exhaustive provider-proof classification and a privacy-safe live-suite manifest seam.
- [x] 226-04-PLAN.md — Build stable owner-first setup diagnostics in the canonical host proof path.

**Wave 2** *(blocked on 226-01)*

- [x] 226-02-PLAN.md — Collect and publish the frozen comparable-run critical-path before-state.

**Wave 3** *(blocked on Waves 1–2)*

- [x] 226-05-PLAN.md — Wire always-run CI summaries/artifacts, reconcile maintainer docs, and close validation.

**Wave 4** *(blocked on Wave 3)*

- [x] 226-06-PLAN.md — Repair full-CI timing qualification and fail closed on calendar-impossible timestamps.

**Wave 5** *(blocked on Wave 4)*

- [x] 226-07-PLAN.md — Recollect the frozen baseline and require a reproducible cohort-percentile critical-path conclusion.

**Wave 6** *(blocked on Wave 5)*

- [x] 226-12-PLAN.md — Select compatible complete paths with visible fingerprint sensitivity and freeze the byte-reproducible baseline.

**Wave 7** *(gap closure; blocked on Wave 6)*

- [x] 226-13-PLAN.md — Fail closed on absent provider proof and incomplete DAG topology, then preserve literal host setup classifications.

**Wave 8** *(gap closure; blocked on Wave 7)*

- [x] 226-14-PLAN.md — Unify live collector job identities and make newly completed provider proof visibly fresh.

**Wave 9** *(gap closure; blocked on Wave 8)*

- [ ] 226-15-PLAN.md — Bind the collector and its live-path regression fixture to the exact docs workflow display identity.

### Phase 227: Measured Critical-Path Improvement

**Goal**: Maintainers receive one demonstrably faster CI critical path while every required release, host, browser, and provider proof remains equally identifiable and recoverable.
**Depends on**: Phase 226
**Requirements**: PATH-01, PATH-02, SAFE-01, SAFE-02
**Success Criteria** (what must be TRUE):

  1. A maintainer can see the measured critical path, the selected duplicated dependency or setup cost, its before-state evidence, and an explicit rollback procedure.
  2. One validated change reduces measured wait or duplicate work on the critical path without removing required release, host, browser, or provider evidence.
  3. Stable required-check identities and failure artifacts remain visible while relevance, dependency ordering, or caching behavior is evaluated.
  4. Each CI change has an executable or recorded negative-control and rollback result; no test is deleted or retried merely to hide a failure.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 225. Required-Lane Signal Repair | 0/3 | Not started | - |
| 226. CI Baseline & Proof Semantics | 9/10 | In progress | - |
| 227. Measured Critical-Path Improvement | 0/TBD | Not started | - |

<details>
<summary>✅ v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync (Phases 212-214.2) — SHIPPED 2026-07-31</summary>

- [x] Phase 212: lattice_stripe 2.x bump & green reconciliation (1/1 plan)
- [x] Phase 213: Stripe-native advisory entitlements sync (5/5 plans)
- [x] Phase 214: Docs & truth reconciliation (3/3 plans)
- [x] Phase 214.1: DOCS-03 writer-documentation gap closure (4/4 plans)
- [x] Phase 214.2: Diagnostic-display and pagination gap closure (4/4 plans)

Full history: [v1.58 roadmap archive](milestones/v1.58-ROADMAP.md).

</details>

Completed milestone detail is archived in [v1.59-ROADMAP.md](milestones/v1.59-ROADMAP.md).
