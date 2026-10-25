# Roadmap: Accrue

## Milestones

- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154–158 (2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.48 Release Readiness + Stable Core Posture** — Phases 159–162 (2026-06-01) — [archive](milestones/v1.48-ROADMAP.md)
- ✅ **v1.49 Realistic Demo App & Adoption Evidence** — Phases 163–166 (2026-06-02) — [archive](milestones/v1.49-ROADMAP.md)
- ✅ **v1.50 Admin UI Foundation** — Phases 167–173 (2026-06-02) — [archive](milestones/v1.50-ROADMAP.md)
- ✅ **v1.51 Admin UI: Depth Pass** — Phases 174–179 (2026-06-04) — [archive](milestones/v1.51-ROADMAP.md)
- ✅ **v1.52 Brand System** — Phases 180–186 (2026-06-14) — [archive](milestones/v1.52-ROADMAP.md)
- ✅ **v1.53 Admin UI Design-System Hardening** — Phases 187–192 (2026-06-20) — [archive](milestones/v1.53-ROADMAP.md)
- ✅ **v1.54 Admin UI Page-Level Streamlining & Storybook** — Phases 193–200 (2026-07-01) — [archive](milestones/v1.54-ROADMAP.md)
- ✅ **v1.55 OSS Quality Evaluation & Hardening Roadmap** — Phases 201–204 (2026-07-03) — [archive](milestones/v1.55-ROADMAP.md)
- ⏸️ **v1.56 Admin UI Ratchet: Automated Adversarial Design Evaluation** — Phases 205–208 (parked 2026-07-19) — [archive](milestones/v1.56-ROADMAP.md)
- ✅ **v1.57 Admin Operator Control Plane (SEED-004 M1)** — Phases 209–211 (2026-07-30) — [archive](milestones/v1.57-ROADMAP.md)
- ✅ **v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync** — Phases 212–214.2 (2026-07-31) — [archive](milestones/v1.58-ROADMAP.md)
- ✅ **v1.59 Account-Scoped Multi-Rail & Offline Entitlements** — Phases 215–222 (2026-08-05) — [archive](milestones/v1.59-ROADMAP.md)
- ⏸️ **v1.60 First-Adopter iOS Bridge & Proof** — Phases 223–224 verified; remaining scope deferred (2026-08-08) — [archive](milestones/v1.60-ROADMAP.md)
- ✅ **v1.61 CI Evidence & Critical-Path Hardening** — Phases 225–228 (2026-09-12) — [archive](milestones/v1.61-ROADMAP.md)
- ✅ **v1.62 Release Integration & Repository Hygiene** — Phases 229–232 (2026-09-18) — [archive](milestones/v1.62-ROADMAP.md)
- ✅ **v1.63 Admin and Portal UI refinement** — Phases 233–239 (shipped 2026-10-09) — [archive](milestones/v1.63-ROADMAP.md)
- ✅ **v1.64 Admin Operator UI Cleanup** — Phases 240–243 (shipped 2026-10-10) — [archive](milestones/v1.64-ROADMAP.md)
- ✅ **v1.65 Accrue Admin Language & Consistency** — Phase 244 (completed 2026-10-11) — [archive](milestones/v1.65-ROADMAP.md)
- ✅ **v1.66 Admin Usability and Visual Consistency** — Phases 245–248 (completed 2026-10-12) — [archive](milestones/v1.66-ROADMAP.md)
- 🚧 **v1.67 Integration & CI Green** — Phases 249–251 (in progress)

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

Historical friction-backlog anchors remain canonical in the [v1.17 inventory](research/v1.17-FRICTION-INVENTORY.md): [INT-10 / Phase 63](research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63), [BIL-03 / Phase 64](research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64), and [ADM-12 / Phase 65](research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65).

Deferred StoreKit, Crosswake physical-device, and Admin UI ratchet work must be explicitly re-scoped by a future milestone before execution. Google Play remains backlogged in SEED-007 until Android is scheduled or a second adopter requires it.

## Current Position

v1.67 Integration & CI Green is in progress. Requirements are defined (12 total) and mapped to Phases 249–251; Phase 249 has not started. v1.66 is complete and archived locally; the v1.63–v1.66 line (≈853 commits ahead of `origin/main` 7971753a) has never been CI-validated. This milestone lands it green at an exact head SHA and makes 1.7.0 release-ready. No new product behavior.

Pushing to the public remote (Phase 250) and publishing to Hex (Phase 251) each require an explicit maintainer yes. Those are irreversible external-operation decisions, not UAT. Every other acceptance item is decided by a command or a CI conclusion (Executable Acceptance Policy).

## Phases

- [ ] **Phase 249: Local Gate Parity & Planning Truth** - Every locally runnable merge-blocking `ci.yml` check passes on the integration head, and the planning state is honest
- [ ] **Phase 250: Remote Integration** - The integration head lands on `main` through one exact-SHA green PR with a merge commit
- [ ] **Phase 251: 1.7.0 Release Alignment** - The release-please 1.7.0 PR is aligned and green; Hex publication waits for an explicit maintainer yes

## Phase Details

### Phase 249: Local Gate Parity & Planning Truth

**Goal**: The integration head passes every merge-blocking check that can run locally. Each red is fixed at its source, never by weakening a gate. Planning state tells the truth about v1.67 and the out-of-band owner-feedback work.
**Depends on**: Nothing (first phase of v1.67)
**Requirements**: GREEN-01, GREEN-02, GREEN-03, GREEN-04, GREEN-05, TRUTH-01, TRUTH-02
**Success Criteria** (what must be TRUE):
  1. Every planning-doc contract step of the `docs-contracts-shift-left` job, run locally with its `ci.yml` command, exits 0 on the integration head. That covers completion evidence, PR claims, artifact fixed point, v1.17 friction / roadmap hygiene, executable UAT and committed window dispositions. No gate script loses an assertion, and no sha256-pinned archived evidence script has its recorded receipt falsified.
  2. `mix compile --warnings-as-errors` succeeds in `accrue_admin`. The admin group-contract, hardening and Phase 200 commands, the DSY-01 breakpoint-annotation check and the D-32 module-boundary check all exit 0.
  3. The Phase 190 automation contract and the Phase 190/192 browser probes pass on desktop and mobile. Each previously failing probe has a committed classification, either a source fix for a real regression or a contract update for a change made stale on purpose, with the rationale recorded.
  4. The `accrue`, `accrue_admin` and `accrue_portal` test suites, the host-integration gate and the Playwright E2E lane all pass locally on the integration head. `copy_strings.json` and visual baselines are regenerated only where an intentional change requires it.
  5. `.planning/HANDOFF.json` is gone and STATE.md reflects v1.67. Resolved debug sessions are filed. MILESTONES.md and STATE.md record commits `3d7d949d..b4a7eeac` as work done outside GSD, cite `.planning/notes/2026-10-1*-admin-owner-feedback.md` as receipts, and claim no backdated plans or phase verification.

**Plans**: 7/17 plans executed

Plans:
- [x] 249-01-PLAN.md — Admin compile warning, formatter drift, DSY-01 breakpoint annotations, PdfTest flake measurement (wave 1)
- [x] 249-02-PLAN.md — Admin credo --strict cleanup and portal endpoint test isolation (wave 2)
- [x] 249-03-PLAN.md — SL-G archived-digest scope, Phase 190 status vocabulary, executable-UAT recorded deviations (wave 1)
- [x] 249-04-PLAN.md — D-16 scoped ledger join wired in ci.yml, plus the local ci.yml replay tool (wave 1)
- [x] 249-05-PLAN.md — D-32 hash-pinned archived-evidence exemptions and guarded, self-testing scripts (wave 2)
- [x] 249-06-PLAN.md — Planning truth: handoff removal, debug filing, out-of-band owner-feedback record, current phase (wave 1)
- [x] 249-07-PLAN.md — Phase 190 group-contract probes classified and green; admin-group-contracts job (wave 3)
- [ ] 249-08-PLAN.md — Phase 192 hardening and Phase 200 guardrail jobs end to end (wave 4)
- [ ] 249-09-PLAN.md — Admin drift-docs, ratchet and non-visual browser-UAT lanes (wave 5)
- [ ] 249-10-PLAN.md — Ship-window ledger dispositions; SL-A and D-16 green (wave 6)
- [ ] 249-11-PLAN.md — In-tree replay: docs-contracts with exact pending-close texts, small jobs (wave 7)
- [ ] 249-12-PLAN.md — In-tree replay: release-gate primary cell for all three packages (wave 8)
- [ ] 249-13-PLAN.md — In-tree replay: every admin lane at the final head (wave 9)
- [ ] 249-14-PLAN.md — Scratch clones: tokens regenerate and host-integration; docker smoke routed to Phase 250 (wave 10)
- [ ] 249-15-PLAN.md — Scratch clone: playwright-e2e shards 1-3 (wave 11)
- [ ] 249-16-PLAN.md — Scratch clones: release-gate Floor, OpenTelemetry and Sigra cells (wave 12)
- [ ] 249-17-PLAN.md — Phase close: VERIFICATION, generated UAT, digest, requirements Complete, final replay (wave 13)

**UI hint**: yes

### Phase 250: Remote Integration

**Goal**: The v1.63–v1.66 work reaches `origin/main` through one PR that CI proves green at its exact head SHA. History and SHA-bound evidence stay intact.
**Depends on**: Phase 249
**Requirements**: LAND-01, LAND-02, LAND-03
**Success Criteria** (what must be TRUE):
  1. After an explicit maintainer yes, `integration/v1.63-v1.66` exists on origin. A pre-push publication-hygiene check (secrets, home paths, PII, large binaries) passed across the full pushed history, and `git ls-remote --tags origin` shows no v1.63–v1.66 milestone tags.
  2. `gh` reports every PR-required job in `ci.yml` and `accrue_admin_browser.yml` as `success`, not `skipped`, on the 40-hex head SHA recorded in the PR body. The committed PR-body file matches the live PR body byte for byte.
  3. The PR is merged with a merge commit (two parents, no squash or rebase). Every pre-merge commit SHA is reachable from `main`, and the first post-merge push run on `main` concludes `success` for all jobs.

**Plans**: TBD

### Phase 251: 1.7.0 Release Alignment

**Goal**: The release-please PR can ship 1.7.0 of `accrue`, `accrue_admin` and `accrue_portal` with adopter-readable notes. Publication happens only with an explicit maintainer yes.
**Depends on**: Phase 250
**Requirements**: RLS-01, RLS-02
**Success Criteria** (what must be TRUE):
  1. The release-please 1.7.0 PR branch carries README version pins at 1.7.0, companion notes and a curated adopter-readable CHANGELOG for all three packages. A grep of the release CHANGELOGs finds no raw phase-scoped `feat(2xx-yy)` lines.
  2. Every required check on the release PR's exact head SHA concludes `success`, not `skipped`.
  3. Hex publication of 1.7.0 happens only after a recorded explicit maintainer yes. Without one, the aligned release PR stays open and green, and the decision is recorded in STATE.md.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 249. Local Gate Parity & Planning Truth | 7/17 | In Progress | - |
| 250. Remote Integration | 0/TBD | Not started | - |
| 251. 1.7.0 Release Alignment | 0/TBD | Not started | - |

## Next

`$gsd-plan-phase 249`. Discuss first with `$gsd-discuss-phase 249` if any red's classification (regression vs stale contract) needs a decision before planning.
