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
- ✅ **v1.67 Integration & CI Green** — Phases 249–251 (shipped 2026-10-26, released 1.7.0) — [archive](milestones/v1.67-ROADMAP.md)
- 🚧 **v1.68 UI Storybook Stress Testing** — Phases 252–254 (approved 2026-10-26; in progress)

## Planning Doctrine

Accrue remains in **stable-core / demand-driven expansion** posture. New feature milestones require a concrete adopter failure mode, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change recorded in `PROJECT.md` or `STRATEGY.md`.

Historical friction-backlog anchors remain canonical in the [v1.17 inventory](research/v1.17-FRICTION-INVENTORY.md): [INT-10 / Phase 63](research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63), [BIL-03 / Phase 64](research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64), and [ADM-12 / Phase 65](research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65).

Deferred StoreKit, Crosswake physical-device, and Admin UI ratchet work must be explicitly re-scoped by a future milestone before execution. Google Play remains backlogged in SEED-007 until Android is scheduled or a second adopter requires it.

## Current Position

v1.68 UI Storybook Stress Testing is active: 22 requirements across Phases 252–254. Phase 252 has execution summaries for all 10 plans and 22 automated tasks across seven waves. Phase 252 is complete: independent verification passed 73/73 observable truths, the fresh aggregate passed 21/21 lanes, and executable UAT passed 124/124. Phase 253 has six independently checked plans with 14 automated tasks across five waves and is ready to execute; its implementation and runtime acceptance remain pending. The owner approved the [reviewed subscription-first proposal](research/ui-quality-engine/MILESTONE-PROPOSAL.md) with “what do u rec? do that”; this explicit strategy decision satisfies the Planning Doctrine without reopening approval of the same scope.

v1.67 Integration & CI Green is complete (Phases 249–251, 12/12 requirements). The v1.63–v1.66 line landed on `main` through PR #49, and 1.7.0 of `accrue`, `accrue_admin` and `accrue_portal` is published to Hex with docs. Release policy (maintainer, 2026-10-26): release early and often at any natural, release-worthy stopping point.

## v1.68 — UI Storybook Stress Testing

**Goal:** A reviewer can inspect and improve the existing subscription job through real production compositions, valid shared situations and repeatable responsive/theme checks, with mounted evidence for safe operator behavior and measured recurring cost.

**Scope:** Subscription components, groups, areas and the whole list/detail/action/return job, using launch/new-account and growing-team facts in the existing Cadence world. Preserve current brand/token owners, DataTable lifecycle, the independent component kitchen, canonical example-host dev mounts, production package boundaries and supported provider/authority semantics. Wider Admin/Portal work remains outside this milestone.

**Acceptance:** Each phase proves its own observable outcomes when delivered. Phase 252 already includes rendered narrow/light/dark checks, lab-isolation negative controls and CI workflow admission; Phase 253 proves real mounted behavior. Phase 254 consolidates recurring selection, reviewed corrections and curation. Existing gates remain enforced; static stories, metadata and screenshot stability do not establish persisted effects, provider completion or aesthetic excellence. Mechanically verifiable acceptance is automated; owner manual UAT is not a completion gate.

## Phases

<details>
<summary>✅ v1.67 Integration & CI Green (Phases 249–251) — SHIPPED 2026-10-26</summary>

- [x] Phase 249: Local Gate Parity & Planning Truth (18/18 plans) — completed 2026-10-25
- [x] Phase 250: Remote Integration (7/7 plans) — completed 2026-10-25
- [x] Phase 251: 1.7.0 Release Alignment (7/7 plans) — completed 2026-10-26

</details>

### Approved Phase Sequence

- [x] **Phase 252: Production-backed Subscription Stories** - Inspect real subscription areas using validated shared situations in a safe lab whose changes invoke required CI checks. (completed 2026-10-27)
- [ ] **Phase 253: Real Groups and a Whole Subscription Job** - Inspect real collection/full-page compositions and complete the guarded subscription journey with clear, responsive presentation.
- [ ] **Phase 254: Recurring Quality, Reviewed Fixes and Curation** - Run affordable recurring checks, verify reviewed corrections and curate useful coverage before choosing the next job.

## Phase Details

### Phase 252: Production-backed Subscription Stories

**Goal**: Reviewers can inspect current production subscription areas through valid, attributable stories in an isolated lab, with production boundaries and CI admission already proved.
**Depends on**: Phase 251 (v1.67 shipped); approved UI quality research and current pending requirements
**Requirements**: SBK-01, SBK-02, SBK-03, SCEN-01, SCEN-02, SCEN-03, SCEN-04, LAB-01, LAB-02, CIQ-01
**Success Criteria** (what must be TRUE):
  1. A maintainer can trace the subscription job's production callers and useful component → group → area → section → page compositions in a current coverage map, distinguish reachable/uncovered/not-applicable states, and open stable story/variation URLs identifying actor, job, input source, renderer and static/mounted proof lane; generated discovery agrees with actual rendered variations rather than metadata markers. (SBK-01, SBK-02)
  2. A reviewer can inspect complete active, scheduled-cancellation and incomplete-evidence subscription areas in actual narrow/desktop and light/dark rendered checks, using production-owned summary/facts/actions, formatting, copy, eligibility and scoped links without a copied story implementation. (SBK-03)
  3. A maintainer can reuse deterministic DB-free launch/new-account and growing-team facts with explicit actors, billed entities, supported providers, lifecycle, fixed clock and stable IDs through narrow adapters; invalid enum/orphan/provider/amount/timestamp controls fail real domain invariants, and a disposable Repo adapter separately proves actual constraints and persisted relationships. (SCEN-01, SCEN-02, SCEN-03)
  4. A reviewer can launch the documented lab on an explicit disposable database/namespace and distinct loopback port with known process identity, see unexpected-server reuse refused, and observe a negative control proving a normal test reset cannot alter review data. Ordinary and labelled held-out data remain separate and privacy-safe, guarded cleanup refuses unrelated children, and production compile/package/route checks exclude fixture payloads and dev tooling while preserving the kitchen and canonical mounts; DB-free rendering is distinguished from DB-backed startup. (SCEN-04, LAB-01, LAB-02)
  5. A maintainer can observe changes confined to each consumed story, shared scenario, component, registry, generated manifest, token or runner root invoke its named required CI owner, through representative positive path/classifier controls and an unrelated-path negative control; in-job selection alone cannot satisfy workflow admission. (CIQ-01)

**Plans**: 10/10 plans complete — all original and gap-closure plans have summaries; independent phase verification passed
**UI hint**: yes

Plans:
**Wave 1**
- [x] 252-01-PLAN.md — One active scenario through the production-owned summary/facts/action area

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 252-02-PLAN.md — Valid launch/team facts and complete retained lifecycle situations
- [x] 252-03-PLAN.md — Disposable lab ownership and real reset-isolation proof

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 252-04-PLAN.md — Persisted scenario constraints, guarded seeds and cleanup preservation
- [x] 252-05-PLAN.md — Compiled variation discovery and current caller/composition gap map

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 252-06-PLAN.md — Twelve direct width/theme render cases and twenty UI predicates
- [x] 252-07-PLAN.md — Production compile, package and route boundaries

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 252-08-PLAN.md — Required CI admission and generated automated acceptance evidence

**Wave 6 — gap closure** *(after executed 252-08)*
- [x] 252-09-PLAN.md — Prove truthful lab presentation and synthetic held-out attribution with clean/violation controls

**Wave 7 — gap closure** *(blocked on 252-09)*
- [x] 252-10-PLAN.md — Wire required CI, fresh acceptance and independently proved original prohibition descriptors

### Phase 253: Real Groups and a Whole Subscription Job

**Goal**: Operators can understand and complete the real subscription job through production-shared collection and whole-page compositions, preserving responsive access, authority and navigation context.
**Depends on**: Phase 252
**Requirements**: SBK-04, SBK-05, SBK-06, UXQ-01, UXQ-03
**Success Criteria** (what must be TRUE):
  1. A reviewer can inspect the actual subscription toolbar/results/table/pagination composition for new-host empty, filtered-empty, one-row, multiple-row and page-boundary situations plus source-supported loading/error states, with DataTable state, lifecycle and event targeting intact. (SBK-04)
  2. A reviewer can inspect a whole subscription detail screen composed from production-shared areas, including supported review/action presentation and legitimate incomplete evidence, without a parallel story page or universal page-schema rewrite. (SBK-05)
  3. An authorized operator can follow list → detail → supported action review/result → context-preserving return, with mounted automated evidence for current scope, fresh authority, exact target, applicable step-up, dismissal without dispatch and truthful outcomes; static stories make no persistence or provider-completion claim. (SBK-06)
  4. An operator can read essential identities, exact amounts, state and actions and use the selected compositions at 320 CSS px, representative wider/container widths and relevant breakpoint edges in both themes, without page-level horizontal overflow or hidden essential content. (UXQ-01)
  5. An operator can understand consistent labels, destinations, action consequences and recovery messages through existing Copy/voice/domain owners while engineering investigation retains exact IDs and evidence and locked legal/replay meaning is preserved. (UXQ-03)

**Plans**: 3/6 plans executed, 14 automated tasks — independently checked; execution pending
**UI hint**: yes

Plans:

**Wave 1**
- [x] 253-01-PLAN.md — One real production collection through mounted Storybook 1.2 transport

**Wave 2** *(blocked on Wave 1 completion; disjoint source ownership)*
- [x] 253-02-PLAN.md — Complete collection states, scoped cursor boundaries and recovery
- [x] 253-03-PLAN.md — Shared whole detail page with truthful incomplete/review/result presentation

**Wave 3** *(blocked on Wave 2 completion)*
- [ ] 253-04-PLAN.md — Complete mounted guarded journey, adversarial authority and validated return

**Wave 4** *(blocked on Wave 3 completion)*
- [ ] 253-05-PLAN.md — Responsive essential content and independently proved truthful presentation

**Wave 5** *(blocked on Wave 4 completion)*
- [ ] 253-06-PLAN.md — Existing required CI owner, fresh executed evidence and automated acceptance

Cross-cutting constraints: preserve production DataTable/LiveView authority, existing Copy/scoped paths, disposable lab and package boundaries, all Phase 252 assertions and the independent kitchen. Use existing dependencies. Static stories establish settled presentation; mounted tests establish effects and fresh authority. Phase 254 recurring selection/curation remains separate. Current unclassified probe assumptions remain explicit; planning is not implementation evidence.

### Phase 254: Recurring Quality, Reviewed Fixes and Curation

**Goal**: Maintainers can sustain useful subscription quality coverage at a measured cost, verify bounded design corrections and choose the next existing UI job from explicit gaps.
**Depends on**: Phase 253
**Requirements**: CIQ-02, CIQ-03, CIQ-04, UXQ-02, UXQ-04, CURATE-01, CURATE-02
**Success Criteria** (what must be TRUE):
  1. A maintainer can see total/selected scenario IDs, changed/affected cases, stable sentinels and explicit exclusions for recurring browser checks; missing or ambiguous dependency metadata broadens selection, and independent pure-story scheduling cannot cause parallel resets of shared mounted fixtures. (CIQ-02)
  2. A maintainer can compare selected subscription states in both themes at meaningful narrow/desktop widths through the existing Linux baseline owner, with deterministic facts/fonts/motion, current source/served-asset identity, deliberate reviewed baseline changes and essential identity/money/state/actions unmasked. (CIQ-03)
  3. An operator can use selected compositions with keyboard/focus, meaningful accessible names, applicable target-size/contrast rules, supported text enlargement/reflow and normal/reduced motion; existing browser/axe/component checks prove outcomes and unresolved axe observations or standard exceptions receive explicit narrow dispositions. A maintainer can inspect one source-bound assessment/correction/confirmation record across mobile/desktop and both themes for typography, color, hierarchy, redundancy, affordances, microcopy and journey coherence, with confirmed defects fixed at their lowest owning tier and mechanically verifiable outcomes tested. (UXQ-02, UXQ-04)
  4. A maintainer can reproduce cold-start, warm-preview/focused-check and incremental CI measurements, including scenario counts, and use a frozen affordable selection/budget before widening coverage; first-slice measurements inform the freeze and deviations are explicitly resolved without weakening existing gates. Initial targets remain provisional: under 10s warm preview where feasible, under 60s focused checks, at most 3min additional warm browser work and 5min incremental CI critical path. (CIQ-04)
  5. A maintainer can inspect retirement/merge records naming reachability, reason and surviving owner/replacement for stale, impossible or duplicate stories while retaining meaningful legacy/API/negative regressions and kitchen proof, then choose the next existing UI job from a refreshed actor/job/composition gap map and distinct adopter briefs showing remaining Admin/Portal horizons, uncovered states, review triggers and maintenance cost. (CURATE-01, CURATE-02)

**Plans**: TBD
**UI hint**: yes

## Progress

**Execution order:** 252 → 253 → 254. All 22 requirements are mapped exactly once; Phase 252's ten requirements are complete, with twelve requirements remaining. Phase 252 has ten completed plans; Phase 253 has six checked plans ready to execute; Phase 254's plan count will be determined during planning.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 252. Production-backed Subscription Stories | 10/10 | Complete    | 2026-10-27 |
| 253. Real Groups and a Whole Subscription Job | 3/6 | Ready to execute | - |
| 254. Recurring Quality, Reviewed Fixes and Curation | 0/TBD | Not started | - |

## Rolling Direction Beyond v1.68

The [rolling roadmap](research/ui-quality-engine/MILESTONE-PROPOSAL.md#rolling-roadmap-beyond-the-first-milestone) carries directional horizons, not additional committed phases: **near** customer investigation, invoice/payment jobs, then recovery/webhooks after retry/campaign-history integrity; **mid** remaining Admin investigation/catalog/Connect and Portal personal/organization/read-only/host-brand jobs after current contract and explicit dev/test harness checks; **long** supported adopter incidents, cross-section journeys, justified browser/device sentinels, impact selection and continual pruning. Expansion follows demonstrated value, current gaps and measured maintenance cost rather than story counts.

**HIGH, independent correctness candidate:** `accrue_events.inserted_at` depends on the Postgres session timezone. A migration or app-side correction remains separate; fixed story clocks do not resolve it and this milestone does not authorize indefinite deferral. Other backlog remains in [current future requirements](REQUIREMENTS.md#future-requirements) and [v1.67's future requirements](milestones/v1.67-REQUIREMENTS.md#future-requirements).

## Next

Phase 253 planning is complete. Execute its six plans in wave order using `$gsd-execute-phase 253`. Research, UI and independent plan reviews are recorded in its phase directory. No Phase 253 implementation, runtime acceptance or UAT pass is claimed by planning.
