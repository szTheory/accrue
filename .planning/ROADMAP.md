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
- ✅ **v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync** — Phases 212-214.2 (shipped 2026-07-31) — [archive](milestones/v1.58-ROADMAP.md)
- ✅ **v1.59 Account-Scoped Multi-Rail & Offline Entitlements** — Phases 215-222 (shipped 2026-08-05) — [archive](milestones/v1.59-ROADMAP.md)
- ⏸️ **v1.60 First-Adopter iOS Bridge & Proof** — Phases 223-224 verified; remaining scope deferred by override closeout (2026-08-08) — [archive](milestones/v1.60-ROADMAP.md)
- ✅ **v1.61 CI Evidence & Critical-Path Hardening** — Phases 225-228 (shipped 2026-09-12) — [archive](milestones/v1.61-ROADMAP.md)
- 🚧 **v1.62 Release Integration & Repository Hygiene** — Phases 229-232 (in progress)

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

Historical friction-backlog anchors remain canonical in the [v1.17 inventory](research/v1.17-FRICTION-INVENTORY.md): [INT-10 / Phase 63](research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63), [BIL-03 / Phase 64](research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64), and [ADM-12 / Phase 65](research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65).

Deferred StoreKit, Crosswake physical-device, and Admin UI ratchet work must be explicitly re-scoped by a future milestone before execution. Google Play remains backlogged in SEED-007 until Android is scheduled or a second adopter requires it.

## Phases

### 🚧 v1.62 Release Integration & Repository Hygiene (In Progress)

**Milestone Goal:** Reconcile the completed v1.61 lineage with `main` into a clean, reviewable, fully verified release candidate, then stop before cleanup becomes churn.

- [x] **Phase 229: Repository Truth & Recovery Safety** - Establish reproducible branch, worktree, artifact, ship-window, and Actions truth without disturbing published history. (completed 2026-09-15)
- [x] **Phase 230: Reviewable History Integration** - Produce and inspect a provenance-backed integration candidate without targeting or merging `main`. (completed 2026-09-15)
- [ ] **Phase 231: Exact-SHA Release Gate Proof** - Prove complete local and GitHub gate status for the immutable candidate SHA and resolve every ship window.
- [ ] **Phase 232: Bounded Hygiene & Release Handoff** - Reconcile release-facing repository truth, make only evidence-backed cleanup, and hand off a reviewable integration and Release Please-ready state.

## Phase Details

### Phase 229: Repository Truth & Recovery Safety

**Goal**: Maintainers can safely establish reproducible repository and CI truth while preserving every pre-existing ref, tag, worktree, and user-owned artifact.
**Depends on**: Nothing (first phase)
**Requirements**: REPO-01, REPO-02, REPO-03
**Success Criteria** (what must be TRUE):

  1. A maintainer can inspect one committed inventory covering local and remote `main`, v1.61 lineage and tag, release branches, worktrees, open PRs, untracked paths, ship windows, and planning state.
  2. A maintainer can recover each pre-existing divergent local ref and user-owned untracked artifact after synchronization work, with no force-push, tag movement, or unrecorded deletion.
  3. A maintainer can use one supported command path to list, inspect, and monitor GitHub Actions runs whose failure output identifies the exact repository SHA.

**Plans**: 16/20 plans executed

### Phase 230: Reviewable History Integration

**Goal**: Maintainers can review one reversible integration candidate that reconciles remote `main`, intended v1.61 work, and all four post-archive audit-closure commits without rewriting published history.
**Depends on**: Phase 229
**Requirements**: INTG-01, INTG-02, INTG-03
**Success Criteria** (what must be TRUE):

  1. A maintainer can inspect an integration candidate containing remote-`main` changes, intended v1.61 work, and all four post-archive audit-closure commits while the v1.61 tag remains unchanged.
  2. A maintainer can inspect evidence-backed dispositions for every integration conflict and intentionally excluded commit, with focused regressions covering retained runtime, documentation, release, and CI behavior.
  3. Before a pull request targets `main`, a maintainer can verify the candidate's ancestry, changed-file scope, milestone provenance, and rollback point.

**Plans**: 7 plans

Plans:
**Wave 1**

- [x] 230-01-PLAN.md — Preservation safety barrier and typed ref continuity

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 230-02-PLAN.md — Tracer: integration candidate proven end to end with rollback proof

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 230-03-PLAN.md — Recomputed hazard universe and fail-closed dispositions
- [x] 230-05-PLAN.md — Dependency migration and focused regressions on the candidate

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 230-04-PLAN.md — Excluded-commit ledger with tree- and requirement-level supersession

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 230-06-PLAN.md — Standing archive-path invariant, code-only review branch, evidence map

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 230-07-PLAN.md — PR #44 closure, record correction, and final capsule minted last

### Phase 231: Exact-SHA Release Gate Proof

**Goal**: Maintainers can make a release decision from complete, honest local and GitHub evidence for one exact integration-candidate SHA.
**Depends on**: Phase 230
**Requirements**: GATE-01, GATE-02, GATE-03
**Success Criteria** (what must be TRUE):

  1. A fresh clean checkout of the exact candidate completes the repository's local CI-equivalent gates without ignored caches, credentials, or another worktree.
  2. A maintainer can inspect green required GitHub Actions checks for that exact SHA while each provider lane remains explicitly `proved`, `skipped`, `failed`, or `advisory`.
  3. A maintainer can inspect current evidence, owner, rationale, and release impact for every former ship window, with each fixed or explicitly waived and none unexplained.

**Plans**: 6 plans

Plans:
**Wave 1**

- [ ] 231-01-PLAN.md — Re-cut the candidate and freeze it behind a shape/ancestry verifier (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 231-02-PLAN.md — GATE-03 window-disposition collect/render/verify triad (wave 2)
- [ ] 231-03-PLAN.md — GATE-01 declared-cohort evidence and the scratch-clone run (wave 2)
- [ ] 231-04-PLAN.md — GATE-02 push, dispatch, poll, and exact-SHA check evidence (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 231-05-PLAN.md — Re-derive and dispose all ten ship windows (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 231-06-PLAN.md — CI wiring, evidence README rows, and the capsule mint (wave 4)

### Phase 232: Bounded Hygiene & Release Handoff

**Goal**: Maintainers can review a release-ready integration handoff whose repository and release-facing artifacts are truthful, recoverable, and free of demonstrated release-path drift.
**Depends on**: Phase 231
**Requirements**: HYG-01, HYG-02, HYG-03, REL-04, REL-05
**Success Criteria** (what must be TRUE):

  1. Before cleanup, a maintainer can inspect a classification of every untracked file, stale worktree, debug session, and remote maintenance or release branch as retained, committed, archived, superseded, or authorized for removal.
  2. A maintainer can verify that GSD health, planning mirrors, generated artifacts, package metadata, changelogs, and release documentation agree with the integration candidate and have no release-blocking drift.
  3. Any cleanup in the release path is backed by an objective test, lint, compiler, security, documentation-truth, dead-code, duplication, or comprehension finding, and additional passes stop once only subjective nits remain.
  4. A reviewer can assess an integration pull request with a concise risk summary, exact verification evidence, rollback instructions, and no unrelated feature scope.
  5. A reviewer can confirm Release Please is producing, or is ready to produce, a version-and-changelog-consistent release pull request without merging it or publishing packages.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 229. Repository Truth & Recovery Safety | 20/20 | Complete    | 2026-09-15 |
| 230. Reviewable History Integration | 7/7 | Complete    | 2026-09-15 |
| 231. Exact-SHA Release Gate Proof | 0/TBD | Not started | - |
| 232. Bounded Hygiene & Release Handoff | 0/TBD | Not started | - |

<details>
<summary>✅ v1.61 CI Evidence & Critical-Path Hardening (Phases 225-228) — SHIPPED 2026-09-12</summary>

- [x] Phase 225: Required-Lane Signal Repair (3/3 plans)
- [x] Phase 226: CI Baseline & Proof Semantics (17/17 plans)
- [x] Phase 227: Measured Critical-Path Improvement (7/7 plans)
- [x] Phase 228: Stripe Webhook-Signing CI Boot Contract (3/3 plans)

Full history: [v1.61 roadmap archive](milestones/v1.61-ROADMAP.md).

</details>
