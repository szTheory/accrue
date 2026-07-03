# Roadmap: Accrue

## Milestones

- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154-158 (shipped 2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.48 Release Readiness + Stable Core Posture** — Phases 159-162 (shipped 2026-06-01) — [archive](milestones/v1.48-ROADMAP.md)
- ✅ **v1.49 Realistic Demo App & Adoption Evidence** — Phases 163-166 (shipped 2026-06-02) — [archive](milestones/v1.49-ROADMAP.md)
- ✅ **v1.50 Admin UI Foundation** — Phases 167-173 (shipped 2026-06-02 via PR #32; archived 2026-06-03) — [archive](milestones/v1.50-ROADMAP.md)
- ✅ **v1.51 Admin UI: Depth Pass [SHIPPED 2026-06-04 — see milestones/v1.51-ROADMAP.md] (IA + Systematic Polish)** — Phases 174-179 (planning 2026-06-03; second, depth-oriented pass on the same `accrue_admin` surface; persona-driven IA reshape + token gap-closure + systematic rubric uplift + motion + seed expressiveness + screenshot-driven visual-QA; no new billing primitives)
- ✅ **v1.52 Brand System** — Phases 180-186 (shipped 2026-06-14; brand audit + DNA lock, SVG logo tournament, design tokens, voice/copy, standalone HTML brand book; no billing primitives) — [archive](milestones/v1.52-ROADMAP.md)
- ✅ **v1.53 Admin UI Design-System Hardening** — Phases 187-192 (shipped 2026-06-20; fractal design-system audit foundations→primitives→groups→pages→flows + interaction-defect remediation + component-level systematization + idempotent only-forward verification on `accrue_admin`; no new billing primitives, no breaking API/route changes, no Tailwind migration) — [archive](milestones/v1.53-ROADMAP.md)
- ✅ **v1.54 Admin UI Page-Level Streamlining & Storybook** — Phases 193-200 (shipped 2026-07-01; page-level excellence on `accrue_admin` — archetype specs, gold-standard overview/list/detail exemplars, propagation across all pages, canonical overlay correctness, PhoenixStorybook dev/test-only, and zero-regression page-flow gate; no new billing primitives, no breaking API/route changes, no Tailwind migration, core stays LiveView-runtime-free) — [archive](milestones/v1.54-ROADMAP.md)
- ◆ **v1.55 OSS Quality Evaluation & Hardening Roadmap** — Phases 201-204 (active 2026-07-01; audit-only maintenance milestone to identify weakest software-quality dimensions, measure CI/CD before optimizing, lock DB schema-prefix posture, and rank follow-up hardening work; no product behavior changes)

## Planning Doctrine

Accrue is in **stable core / demand-driven expansion** posture as of 2026-05-31. Future feature milestones require at least one of:

- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- an operational release/support failure,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

Current milestone v1.55 is open as maintenance / release-readiness / support-contract hardening work. It is not a broad feature milestone and does not add billing primitives, public API surface, new UI flows, or CI topology changes by itself.

v1.54 Admin UI Page-Level Streamlining & Storybook shipped on 2026-07-01 as a quality / page-level-design / interaction-correctness investment in the already-shipped `accrue_admin` operator UI (continuing v1.53's design-system hardening). It was **not** a broad feature milestone: no new billing primitives, no breaking API/route changes, no Tailwind migration, and core `accrue` remains LiveView-runtime-free while PhoenixStorybook is `accrue_admin` dev/test-only. The reopen justification remains recorded in `PROJECT.md`: explicit strategy change for the flagship adopter-facing surface plus firsthand-observed page-level usability defects.

Stop rule: if proposed work is polish-only with a documented workaround and no release/adopter failure mode, record it as deferred with a revisit trigger and do not create a milestone for it.

## Phases

<details open>
<summary>◆ v1.55 OSS Quality Evaluation & Hardening Roadmap (Phases 201-204) — ACTIVE 2026-07-01</summary>

**Posture:** Maintenance / release-readiness / support-contract hardening milestone under stable-core. This milestone produces evidence-backed audits and a ranked implementation roadmap. It does **not** change product behavior, public APIs, DB defaults, CI required-check topology, or package release automation.

- [x] Phase 201: Software quality evaluation — produce `201-SOFTWARE-QUALITY-AUDIT.md` covering adoption, production, maintainability, supportability, UI, release, upgrade, data, security, architecture, OSS trust, and missing project-specific dimensions (QLT-01..05). Completed 2026-07-02.
- [x] Phase 202: CI/CD performance and determinism audit — produce `202-CI-CD-PERFORMANCE-AUDIT.md` with workflow topology, static critical path, measurement plan, bottlenecks, flaky/determinism risks, cache risks, and target pipeline recommendations (CI-01..05). (completed 2026-07-02)
- [x] Phase 203: Database schema contract ADR — produce `203-DB-SCHEMA-CONTRACT-ADR.md`; lock the current `billing` default, preserve explicit `public`, and define future prefix hardening checks without changing defaults now (DB-01..04). (completed 2026-07-02)
- [x] Phase 204: Ranked hardening roadmap — produce `204-HARDENING-ROADMAP.md` grouping follow-up implementation work by priority, milestone shape, impact, effort, risk reduction, and done criteria (RD-01..04). (completed 2026-07-03)

**Dependency shape:** 201, 202, and 203 can run in parallel after milestone initialization. Phase 204 consumes all three audits and must run last.

**Success criteria:**

1. Every low score or hardening recommendation cites concrete repo evidence.
2. Static CI findings are labeled separately from metrics that require GitHub run history.
3. DB schema default remains `billing`; switching to `accrue` is explicitly not part of v1.55.
4. Follow-up implementation work is ranked and sliced; polish-only work is deferred unless it reduces adoption, production, support, or maintenance risk.

Coverage: 18/18 v1.55 requirements mapped.

### Phase Details

### Phase 201: Software quality evaluation

**Goal:** Produce `201-SOFTWARE-QUALITY-AUDIT.md`, an evidence-backed evaluation of Accrue as a real OSS billing project across adoption, production, maintainability, supportability, UI, release, upgrade, data, security, architecture, OSS trust, and any missing project-specific quality dimensions.
**Depends on:** Nothing (first phase of v1.55; can run in parallel with Phases 202 and 203)
**Requirements:** QLT-01, QLT-02, QLT-03, QLT-04, QLT-05
**Canonical refs:** `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md`
**Success Criteria** (what must be TRUE):

  1. The audit covers every required software-quality dimension and adds any Accrue-specific dimensions that materially affect adopter confidence, production readiness, supportability, or maintenance risk.
  2. Every low score, concern, and recommendation cites concrete repository evidence rather than generic OSS advice.
  3. The output distinguishes audit findings from follow-up implementation work; this phase does not change product behavior, public APIs, DB defaults, CI required-check topology, or release automation.
  4. Findings are structured so Phase 204 can rank follow-up hardening work by impact, effort, risk reduction, and done criteria.

**Plans:** 1 plan

Plans:

- [x] 201-01-PLAN.md — Produce the software-quality audit and evidence map.

**UI hint:** no

### Phase 202: CI/CD performance and determinism audit

**Goal:** Produce `202-CI-CD-PERFORMANCE-AUDIT.md`, a focused audit of CI/CD topology, static critical path, measurement needs, bottlenecks, flaky/determinism risks, cache risks, and target pipeline recommendations.
**Depends on:** Nothing (can run in parallel with Phases 201 and 203)
**Requirements:** CI-01, CI-02, CI-03, CI-04, CI-05
**Canonical refs:** `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md`
**Success Criteria** (what must be TRUE):

  1. Workflow topology and static critical path findings are documented from checked-in CI configuration.
  2. Findings that require GitHub run-history metrics are clearly separated from static repository evidence.
  3. Recommendations identify duplicated, low-signal, flaky, cache-risky, or overly expensive checks without changing required-check topology in this phase.
  4. The audit gives Phase 204 enough information to rank CI/CD hardening and optimization work.

**Plans:** 1/1 plans complete

Plans:

- [x] 202-01-PLAN.md — Produce the CI/CD performance and determinism audit.

**UI hint:** no

### Phase 203: Database schema contract ADR

**Goal:** Produce `203-DB-SCHEMA-CONTRACT-ADR.md`; lock the current `billing` default schema posture, preserve explicit `public`, and define future schema-prefix hardening checks without changing defaults now.
**Depends on:** Nothing (can run in parallel with Phases 201 and 202)
**Requirements:** DB-01, DB-02, DB-03, DB-04
**Canonical refs:** `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`
**Success Criteria** (what must be TRUE):

  1. The ADR explicitly keeps `billing` as the default dedicated Postgres schema for this milestone.
  2. The ADR preserves explicit `public` handling where required by current behavior.
  3. The ADR documents why switching the default to `accrue` is out of scope for v1.55.
  4. Future schema-prefix hardening checks are described as follow-up implementation work for Phase 204 to rank.

**Plans:** 1/1 plans complete

Plans:

- [x] 203-01-PLAN.md — Produce the database schema contract ADR.

**UI hint:** no

### Phase 204: Ranked hardening roadmap

**Goal:** Produce `204-HARDENING-ROADMAP.md`, grouping follow-up implementation work by priority, milestone shape, impact, effort, risk reduction, and done criteria.
**Depends on:** Phases 201, 202, and 203
**Requirements:** RD-01, RD-02, RD-03, RD-04
**Canonical refs:** `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md`, `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md`, `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md`, `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`
**Success Criteria** (what must be TRUE):

  1. Follow-up implementation work is ranked from the Phase 201-203 audit evidence, not from unsourced preferences.
  2. Each proposed hardening slice includes priority, milestone shape, impact, effort, risk reduction, and done criteria.
  3. Polish-only work is deferred unless it reduces adoption, production, support, or maintenance risk.
  4. The roadmap preserves the v1.55 audit-only boundary and does not imply implementation happened in this milestone.

**Plans:** 1/1 plans complete

Plans:

- [x] 204-01-PLAN.md — Produce the ranked hardening roadmap from Phases 201-203.

**UI hint:** no

</details>

<details>
<summary>✅ v1.54 Admin UI Page-Level Streamlining & Storybook (Phases 193-200) — SHIPPED 2026-07-01</summary>

**Posture:** Quality / page-level-design / interaction-correctness investment in the already-shipped `accrue_admin` operator UI — **not** a broad feature milestone. Took the surface from interaction-correct building blocks to page-level excellence: specs locked, exemplars built, patterns propagated, overlays hardened, Storybook adopted dev/test-only, and the forward-only page-flow gate closed with zero regressions.

- [x] Phase 193: Research, re-baseline & pattern lock (5/5 plans) — completed 2026-06-25
- [x] Phase 194: Exemplar A — Dashboard (4/4 plans) — completed 2026-06-26
- [x] Phase 195: Exemplar B — Subscription detail (8/8 plans) — completed 2026-06-26
- [x] Phase 196: Exemplar C — Subscriptions list + PageHeader (5/5 plans) — completed 2026-06-26
- [x] Phase 197: Propagate LIST (7/7 plans) — completed 2026-06-28
- [x] Phase 198: Propagate DETAIL + analytics (9/9 plans) — completed 2026-06-29
- [x] Phase 199: Cross-cutting interaction/overlay correctness + fixture stress + microcopy (15/15 plans) — completed 2026-06-30
- [x] Phase 200: Idempotent verification & sign-off (6/6 plans) — completed 2026-06-30, accepted

Coverage: 23/23 requirements complete. Audit passed with 8/8 phase verifications, 23/23 implementation-verified requirements, 8/8 E2E flows, zero blockers, and one accepted out-of-scope deferral (TOOL-02 pixel-diff visual regression).

Full details: [v1.54 roadmap archive](milestones/v1.54-ROADMAP.md)

</details>

<details>
<summary>✅ v1.53 Admin UI Design-System Hardening (Phases 187-192) — SHIPPED 2026-06-20 (deps strictly linear 187→188→189→190→191→192)</summary>

**Posture:** Quality / interaction-correctness / design-system investment in the already-shipped `accrue_admin` operator UI — **not** a broad feature milestone (no new billing primitives, no breaking API/route changes, no Tailwind migration). Took the admin UI from *considered* (v1.51) to *interaction-correct and component-systematic*: fractal design-system audit (foundations → primitives → groups → pages → flows), behavioral interaction-defect remediation, component-level systematization, and an idempotent only-forward verification loop. Discharged v1.51's open photographic-sign-off tech-debt.

- [x] Phase 187: Audit & Baseline (5/5 plans) — completed 2026-06-15 (VER-01)
- [x] Phase 188: Foundations hardening (8/8 plans) — completed 2026-06-20 (FND-01..06)
- [x] Phase 189: Primitive & form components + component lab (7/7 plans) — completed 2026-06-18 (CMP-01..05)
- [x] Phase 190: Navigation, data-display & meta-component cohesion (6/6 plans) — completed 2026-06-18 (GRP-01..04)
- [x] Phase 191: Page & flow interaction pass + fixture stress + microcopy (7/7 plans) — completed 2026-06-19 (IXN-01..05, PAGE-01..04, CPY-01..03, SEED-01..02)
- [x] Phase 192: Idempotent verification & sign-off (6/6 plans) — completed 2026-06-20 (VER-02..04)

Coverage: 33/33 requirements. Final scorecard ≥ Phase-187 baseline across 21,276 cells with 0 regressions; maintainer sign-off ACCEPT.

Full details: [v1.53 roadmap archive](milestones/v1.53-ROADMAP.md)

</details>

<details>
<summary>✅ v1.52 Brand System (Phases 180-186) — SHIPPED 2026-06-14 (deps 180→181→182→183→186, with 180→{184,185}→186 side-rails)</summary>

**Posture:** Brand/DX investment in adopter-facing presentation surfaces (README, Hex.pm, HexDocs, social previews, admin UI identity) — **not** a broad feature milestone (no new billing primitives). Reopen decision recorded in `PROJECT.md`; justification class same as v1.50/v1.51.

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
<summary>✅ v1.51 Admin UI: Depth Pass (Phases 174-179) — SHIPPED 2026-06-04 (deps A→B→C→{D,E}→F)</summary>

**Posture:** Quality / adopter-facing operator-DX investment in the already-shipped `accrue_admin` surface — **not** a broad feature milestone (no new billing primitives). The second, depth-oriented pass on v1.50's foundation: re-map IA from entity-shaped to job/persona-shaped, close design-token gaps, lift the under-iterated screen tail to one rubric baseline, add restrained motion, make seed data express every state, and prove it with a screenshot-driven visual-QA loop.

Full details: [v1.51 roadmap archive](milestones/v1.51-ROADMAP.md)

</details>

<details>
<summary>✅ v1.50 Admin UI Foundation (Phases 167-173) — SHIPPED 2026-06-02 (PR #32; archived 2026-06-03)</summary>

- [x] Phase 167: Design Tokens & Motion Foundation — completed 2026-06-02 (AUI-01)
- [x] Phase 168: Typography & Icon System — completed 2026-06-02 (AUI-02)
- [x] Phase 169: IA — Home, Nav & Search — completed 2026-06-02 (AUI-03)
- [x] Phase 170: Cross-Screen Threading & Microcopy — completed 2026-06-02 (AUI-04)
- [x] Phase 171: Shared Detail Components & Refactor — completed 2026-06-02 (AUI-05)
- [x] Phase 172: Seed Enrichment & Component Kitchen — completed 2026-06-02 (AUI-06)
- [x] Phase 173: Rubric Audit & Visual/A11y Coverage — completed 2026-06-02 (AUI-07)

Full details: [v1.50 roadmap archive](milestones/v1.50-ROADMAP.md)

</details>

<details>
<summary>✅ v1.49 Realistic Demo App & Adoption Evidence (Phases 163-166) — SHIPPED 2026-06-02</summary>

- [x] Phase 163: Realistic Domain & Rich Seeds (1/1 plan) — completed 2026-06-01
- [x] Phase 164: Docker DX & Optimized Caching (2/2 plans) — completed 2026-06-01
- [x] Phase 165: E2E Automation & Shift-Left CI (4/4 plans) — completed 2026-06-02
- [x] Phase 166: Adoption DX Docs (3/3 plans) — completed 2026-06-02

Full details: [v1.49 roadmap archive](milestones/v1.49-ROADMAP.md)

</details>

<details>
<summary>✅ v1.48 Release Readiness + Stable Core Posture (Phases 159-162) — SHIPPED 2026-06-01</summary>

- [x] Phase 159: Linked Release Readiness + Publish Proof (2/2 plans) — completed 2026-06-01
- [x] Phase 160: Stable-Core Public Positioning (3/3 plans) — completed 2026-05-31
- [x] Phase 161: Backlog Anchor Closure + Pause Rule (1/1 plan) — completed 2026-06-01
- [x] Phase 162: Close gap: REL-01/REL-03 — linked release proof (4/4 plans) — completed 2026-06-01

Full details: [v1.48 roadmap archive](milestones/v1.48-ROADMAP.md)

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 167. Design Tokens & Motion Foundation | v1.50 | ✓ | Complete | 2026-06-02 |
| 168. Typography & Icon System | v1.50 | ✓ | Complete | 2026-06-02 |
| 169. IA — Home, Nav & Search | v1.50 | ✓ | Complete | 2026-06-02 |
| 170. Cross-Screen Threading & Microcopy | v1.50 | ✓ | Complete | 2026-06-02 |
| 171. Shared Detail Components & Refactor | v1.50 | ✓ | Complete | 2026-06-02 |
| 172. Seed Enrichment & Component Kitchen | v1.50 | ✓ | Complete | 2026-06-02 |
| 173. Rubric Audit & Visual/A11y Coverage | v1.50 | ✓ | Complete | 2026-06-02 |
| 174. A — Design-System Gap Closure & Token Completeness | v1.51 | 7/7 | Complete | 2026-06-04 |
| 175. B — Persona-Driven IA Spine | v1.51 | 7/7 | Complete | 2026-06-04 |
| 176. C — Systematic Per-Screen Rubric Uplift | v1.51 | 6/6 | Complete | 2026-06-04 |
| 177. D — Motion & Micro-interaction Design | v1.51 | 6/6 | Complete | 2026-06-04 |
| 178. E — Seed Expressiveness & State Coverage | v1.51 | 4/4 | Complete | 2026-06-04 |
| 179. F — Screenshot-Driven Visual QA Loop & Sign-off | v1.51 | 3/3 | Complete | 2026-06-05 |
| 180. Brand Audit & DNA Lock | v1.52 | 4/4 | Complete | 2026-06-12 |
| 181. SVG Pipeline + Tournament Round 1 — Divergent | v1.52 | 7/7 | Complete | 2026-06-13 |
| 182. Tournament Convergent Refinement | v1.52 | 3/3 | Complete | 2026-06-13 |
| 183. Logo System Production | v1.52 | 4/4 | Complete | 2026-06-13 |
| 184. Design Tokens & Specimens | v1.52 | 5/5 | Complete | 2026-06-14 |
| 185. Voice, Microcopy & Marketing Copy | v1.52 | 3/3 | Complete | 2026-06-14 |
| 186. HTML Brand Book Assembly & Quality Gate | v1.52 | 3/3 | Complete | 2026-06-14 |
| 187. Audit & Baseline | v1.53 | 5/5 | Complete    | 2026-06-15 |
| 188. Foundations hardening | v1.53 | 8/8 | Complete    | 2026-06-20 |
| 189. Primitive & form components + component lab | v1.53 | 7/7 | Complete   | 2026-06-18 |
| 190. Navigation, data-display & meta-component cohesion | v1.53 | 6/6 | Complete | 2026-06-18 |
| 191. Page & flow interaction pass + fixture stress + microcopy | v1.53 | 7/7 | Complete | 2026-06-19 |
| 192. Idempotent verification & sign-off | v1.53 | 6/6 | Complete   | 2026-06-20 |
| 193. Research, re-baseline & pattern lock | v1.54 | 5/5 | Complete    | 2026-06-25 |
| 194. Exemplar A — Dashboard | v1.54 | 4/4 | Complete    | 2026-06-26 |
| 195. Exemplar B — Subscription detail | v1.54 | 8/8 | Complete    | 2026-06-26 |
| 196. Exemplar C — Subscriptions list + PageHeader | v1.54 | 5/5 | Complete    | 2026-06-26 |
| 197. Propagate LIST | v1.54 | 7/7 | Complete    | 2026-06-28 |
| 198. Propagate DETAIL + analytics | v1.54 | 9/9 | Complete    | 2026-06-29 |
| 199. Cross-cutting interaction/overlay correctness + fixture stress + microcopy | v1.54 | 15/15 | Complete    | 2026-06-30 |
| 200. Idempotent verification & sign-off | v1.54 | 6/6 | Complete    | 2026-06-30 |
| 201. Software quality evaluation | v1.55 | 1/1 | Complete    | 2026-07-02 |
| 202. CI/CD performance and determinism audit | v1.55 | 1/1 | Complete    | 2026-07-02 |
| 203. Database schema contract ADR | v1.55 | 1/1 | Complete    | 2026-07-02 |
| 204. Ranked hardening roadmap | v1.55 | 1/1 | Complete    | 2026-07-03 |

## Historical Backlog Anchors (not active scope)

These v1.17 FRG anchors are retained for traceability only as historical, non-active planning context. They do not create milestone scope unless a fresh sourced friction row meets the current stable-core evidence bar.

- [INT-10 Phase 63](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63) — Historical / non-active Braintree and multi-processor integration anchor; materially shipped across v1.31+ and reflected in the processor support matrix. Reopen only for a concrete adopter failure mode or operational failure in the shipped processor-support contract.
- [BIL-03 Phase 64](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64) — Historical / non-active billing portal configuration anchor; materially shipped via `accrue_portal`, guides, and host proof. Reopen only for a repeated support issue or correctness/data-loss risk in the portal support surface.
- [ADM-12 Phase 65](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65) — Historical / non-active admin UI role-based access anchor; no current broad feature scope follows from this link. Reopen only for a concrete security/compliance requirement or explicit strategy change.

## Deferred Seeds and Ideas (dormant / trigger-bound)

| Item | Status | Reason | Future owner/category | Revisit trigger |
|------|--------|--------|-----------------------|-----------------|
| TOOL-01 (PhoenixStorybook) | adopted (v1.54) | v1.53 deferred it; v1.54 reverses the deferral — PhoenixStorybook is adopted `only: [:dev, :test]` (STY-01..03) so adopters never carry it. | Component-lab tooling | n/a — adopted |
| TOOL-02 (pixel-diff visual-regression) | deferred (v1.53/v1.54) | Percy/Applitools-style pixel-diff tooling deferred in favor of the scored-cell forward-only gate over real composed routes (it would flag every intentional v1.54 improvement as a regression). | Visual-regression tooling | flaky/insufficient scored-cell + judge loop, or explicit strategy change |
| TOOL-03 (publish tokens.css distributable) | deferred (v1.53) | Standalone npm/CDN token distributable not needed for the admin hardening/streamlining passes. | Brand/token distribution | external doc/marketing-site need for distributable tokens |
| SEED-001 | resolved historical context | Linked-release purpose was superseded by later linked publish work and Phase 159 release-readiness proof. | Release readiness / archive traceability | operational failure in linked release proof or explicit strategy change in release process |
| SEED-002 | dormant future roadmap | Ecosystem integrations are useful blueprints but are not v1.48 closeout blockers and do not create default milestone scope. | Future roadmap / ecosystem integrations | concrete adopter failure requiring one listed integration, repeated support issue, or explicit strategy change |
| SEED-003 | dormant operational hygiene | Repo hygiene checkpoints are useful before milestone/release prep but do not create product scope or force Hex publish. | Repo hygiene / release prep | before opening a new milestone, before release prep, or when local/GitHub/GSD state feels stale |
| ENT-EXT-01 | deferred | Rich metered, tiered, and range entitlement math is beyond current seat-count support and lacks a sourced adopter contract. | Entitlements extension | concrete adopter failure or explicit adopter contract requiring richer entitlement math |
| FIN-03 | standing non-goal | App-owned finance exports remain outside Accrue's declared billing-library scope. | Strategy non-goal / finance exports | explicit strategy change or correctness/security/data-loss risk that cannot be solved by host-owned exports |
