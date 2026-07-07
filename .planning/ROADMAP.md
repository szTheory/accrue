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
- ✅ **v1.55 OSS Quality Evaluation & Hardening Roadmap** — Phases 201-204 (shipped 2026-07-03; audit-only quality evaluation, CI/CD determinism audit, DB schema-contract ADR, and ranked hardening roadmap; no product behavior changes) — [archive](milestones/v1.55-ROADMAP.md)
- 🔨 **v1.56 Admin UI Ratchet: Automated Adversarial Design Evaluation** — Phases 205-209 (ACTIVE, opened 2026-07-03; maintainer-run forward-only "UI Ratchet" that automates fan-out adversarial design evaluation → dedup → verify → batch-fix → re-score → loop-until-dry over `accrue_admin`; dev/test-only tooling + admin CSS polish; LLM proposes, humans triage, a committed ledger + minted deterministic guards ratchet; no new billing primitives, no breaking API/route changes, no Tailwind migration, core stays LiveView-runtime-free, LLM never gates CI)

## Planning Doctrine

Accrue is in **stable core / demand-driven expansion** posture as of 2026-05-31. Future feature milestones require at least one of:

- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- an operational release/support failure,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

**v1.56 Admin UI Ratchet: Automated Adversarial Design Evaluation is open** (Phases 205-209, opened 2026-07-03). It is **not** a broad feature milestone: it is a design-quality investment in the already-shipped `accrue_admin` operator UI (dev/test-only evaluation tooling + admin CSS polish). Reopen justification class: **explicit strategy change** (flagship adopter-facing admin surface design quality — same class accepted for v1.50–v1.54) **plus** a concrete maintainer request, recorded in `PROJECT.md`. No new billing primitives, no breaking API/route changes, no Tailwind migration, core `accrue` stays LiveView-runtime-free, `ax-*` stays the styling SSOT, and the LLM never gates CI.

v1.55 OSS Quality Evaluation & Hardening Roadmap shipped on 2026-07-03 as maintenance / release-readiness / support-contract hardening work. It was not a broad feature milestone and did not add billing primitives, public API surface, new UI flows, DB defaults, CI required-check topology, or release automation changes. The next likely hardening slice is the Phase 204 top-ranked "Public Truth And Proof-State Baseline" work, pending explicit milestone initialization.

v1.54 Admin UI Page-Level Streamlining & Storybook shipped on 2026-07-01 as a quality / page-level-design / interaction-correctness investment in the already-shipped `accrue_admin` operator UI (continuing v1.53's design-system hardening). It was **not** a broad feature milestone: no new billing primitives, no breaking API/route changes, no Tailwind migration, and core `accrue` remains LiveView-runtime-free while PhoenixStorybook is `accrue_admin` dev/test-only. The reopen justification remains recorded in `PROJECT.md`: explicit strategy change for the flagship adopter-facing surface plus firsthand-observed page-level usability defects.

Stop rule: if proposed work is polish-only with a documented workaround and no release/adopter failure mode, record it as deferred with a revisit trigger and do not create a milestone for it.

## Phases

### 🔨 v1.56 Admin UI Ratchet: Automated Adversarial Design Evaluation (Phases 205-209) — ACTIVE (opened 2026-07-03)

**Posture:** Design-quality investment in the flagship adopter-facing `accrue_admin` operator UI via a maintainer-run, forward-only "UI Ratchet" — **not** a broad feature milestone. Reopen justification (recorded in `PROJECT.md`): **explicit strategy change** (same class accepted for v1.50–v1.54) **plus** a concrete maintainer request. Scope stays within `accrue_admin` + dev/test-only tooling: no new billing primitives, no breaking API/route changes, no Tailwind migration, `ax-*` stays the styling SSOT, core `accrue` stays LiveView-runtime-free, no `accrue_portal` work, and ratchet tooling never leaks into adopter runtime. The LLM runs locally (maintainer's key) as a proposer/ranker only; CI gates the deterministic layer only (the LLM is never on the gate path). Authoritative design source: `~/.claude/plans/ui-ratchet-txt-i-agile-honey.md`.

- [x] **Phase 205: Persona + design-lens evaluator harness** - Local, key-gated evaluator fans out 6 operator personas + a comparative graphic-design lens over committed screenshots and emits stable, claim-keyed candidate findings (EVAL-01..05, DEDUP-01, DEDUP-02) (completed 2026-07-04)
- [x] **Phase 206: Adversarial verifier + finding ledger + deterministic gate** - Candidates collapse, are adversarially confirmed (2-of-3 skeptic panel + mandatory justification token), persist to a committed forward-only ledger, and are protected by a deterministic sibling gate the LLM never touches (DEDUP-03, VERIFY-01..03, LEDGER-01..05) (completed 2026-07-04)
- [ ] **Phase 207: Orchestration + digest + one-command round/fix loop** - Two `mix accrue_admin.ui.*` commands drive the whole pipeline with a rendered digest, minimal batch-approve checkpoints, auto-minted guards, and guaranteed termination, plus proposer prompt-caching + a surface-subset filter (ORCH-01..08)
- [ ] **Phase 208: Prove convergence on the representative slice + wire CI + ACCEPT** - Run the ratchet to convergence on the slice, freeze the first baseline, add the deterministic-only CI job, keep existing gates green, and land maintainer ACCEPT + a follow-on runbook (CONV-01..07)
- [ ] **Phase 209: Full-surface sweep under the ratchet** — **SCOPE-GATED / OPTIONAL (teed up, NOT required for v1.56 sign-off)** - Graduate the remaining ~19 admin surfaces round-by-round to 2 dry rounds each with no regressions (deferred SWEEP-01)

Coverage: **31/31 requirements** mapped to Phases 205-208 (each REQ-ID → exactly one phase; ORCH-07/08 folded 2026-07-03 from the Phase 205 live smoke — the original ratified set was 29). Phase 209 carries only the deferred SWEEP-01 and is explicitly optional/scope-gated. Dependencies: strictly linear 205 → 206 → 207 → 208, with 209 an optional follow-on after 208. Full per-phase goals + success criteria: see [Phase Details](#phase-details-v156-active-milestone).

<details>
<summary>✅ v1.55 OSS Quality Evaluation & Hardening Roadmap (Phases 201-204) — SHIPPED 2026-07-03</summary>

**Posture:** Audit-only maintenance / release-readiness / support-contract hardening under stable core. The milestone produced evidence-backed audits and a ranked implementation roadmap. It did **not** change product behavior, public APIs, DB defaults, CI required-check topology, package release automation, or runtime UI.

- [x] Phase 201: Software quality evaluation — adoption, production, maintainability, supportability, UI, release, upgrade, data, security, architecture, OSS trust, and project-specific quality dimensions (QLT-01..05). Completed 2026-07-02.
- [x] Phase 202: CI/CD performance and determinism audit — workflow topology, static critical path, measurement plan, bottlenecks, flaky/determinism risks, cache risks, and target pipeline recommendations (CI-01..05). Completed 2026-07-02.
- [x] Phase 203: Database schema contract ADR — default `billing` schema kept, explicit `public` preserved, future prefix hardening described without changing defaults (DB-01..04). Completed 2026-07-02.
- [x] Phase 204: Ranked hardening roadmap — top 10 future hardening items grouped by priority, milestone shape, impact, effort, risk reduction, and done criteria (RD-01..04). Completed 2026-07-03.

Coverage: 18/18 requirements complete. Audit passed with 4/4 phase verifications, 18/18 requirements clean by 3-source audit, 8/8 integration checks, 6/6 audit-only flows, and zero blockers.

Full details: [v1.55 roadmap archive](milestones/v1.55-ROADMAP.md), [requirements archive](milestones/v1.55-REQUIREMENTS.md), [audit archive](milestones/v1.55-MILESTONE-AUDIT.md), and [phase artifacts](milestones/v1.55-phases/).

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

## Phase Details (v1.56 active milestone)

### Phase 205: Persona + design-lens evaluator harness

**Goal**: A maintainer can run a local, key-gated evaluator that fans out 6 operator-persona lenses + a comparative graphic-design lens over the committed admin screenshots and emits stable, claim-keyed candidate findings. Promotes the dormant `score-visuals.mjs` into `accrue_admin/e2e/ratchet/ratchet-propose.mjs`.
**Depends on**: Nothing (first phase of v1.56; reuses the existing capture harness + 30,348-cell grammar)
**Requirements**: EVAL-01, EVAL-02, EVAL-03, EVAL-04, EVAL-05, DEDUP-01, DEDUP-02
**Success Criteria** (what must be TRUE):

  1. Maintainer runs the evaluator locally and gets a `candidates.ndjson` where each row records surface, rubric dimension, region tag, overlay tags, severity, the raising persona/lens, and `cell_refs` into the existing 30,348-cell grammar.
  2. All 6 operator personas (Operator/Founder, Customer Support, Finance/Billing Ops, Recovery/Growth Ops, Developer/Integration, Compliance/Audit) each produce job-anchored findings from their entry point, and the graphic-design lens scores comparatively against named quiet-dev-tooling exemplars (Linear / Vercel / Stripe / Prisma) rather than emitting an absolute "award" score.
  3. Running the evaluator with no `ANTHROPIC_API_KEY` exits 0 (no failure) and the existing per-image size guard still holds, so it is safe to invoke anywhere.
  4. A committed `DESIGN-LENS-RUBRIC.md` sub-rubric plus a curated, license-clean good/bad exemplar set (sourced from repo history) anchors the design lens to the locked brand DNA ("quiet polish, well-made dev tooling, not fintech").
  5. Running the proposer twice on unchanged screenshots yields an identical `finding_id` set — proven by an automated test — because each finding's canonical claim-key is derived from surface + dimension + sorted overlay-tags + region and excludes the LLM free-text.

**Plans**: 2/5 plans executed
**Wave 1**

- [x] 205-01-PLAN.md — Determinism SSOT (`region-tags.js`): closed-enum vocab + pure claim-key/finding-id + DEDUP self-test (DEDUP-01, DEDUP-02)
- [x] 205-02-PLAN.md — Design sub-rubric + curated good/bad exemplar set + PROVENANCE.json (EVAL-02, EVAL-04)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 205-03-PLAN.md — Proposer CLI: guards + 6 persona lenses + harness-validation gate + `candidates.ndjson` (EVAL-01, EVAL-03, EVAL-05)
- [x] 205-05-PLAN.md — Capture-time `.bbox.json` region-selector emit for the 207 overlay + presence cross-check (EVAL-05)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 205-04-PLAN.md — Comparative graphic-design lens integration (few-shot exemplars, `direction` flag) (EVAL-02)

### Phase 206: Adversarial verifier + finding ledger + deterministic gate

**Goal**: Candidate findings are collapsed across lenses, adversarially confirmed, persisted to a committed forward-only ledger, and protected by a deterministic sibling gate that the LLM never touches — the pawl that lets the UI only move forward.
**Depends on**: Phase 205 (consumes `candidates.ndjson` + claim-keys)
**Requirements**: DEDUP-03, VERIFY-01, VERIFY-02, VERIFY-03, LEDGER-01, LEDGER-02, LEDGER-03, LEDGER-04, LEDGER-05
**Success Criteria** (what must be TRUE):

  1. Findings raised independently by multiple personas/lenses collapse into a single work item carrying a `persona_frequency` count.
  2. Each candidate faces a 3-role adversarial skeptic panel (persona advocate, brand purist, operator-density defender) and is dropped unless at least 2 of 3 confirm; the operator-density-defender refutes any fix that would cut operator information density or add marketing-style whitespace without a concrete task-completion justification; and a candidate that cites no admissible justification token (`rubric-dim-below-bar` | `persona-job-miss:<job>` | `token-bypass`) is rejected before any human sees it.
  3. Confirmed findings persist to a committed `findings.ledger.ndjson` with an explicit lifecycle (`open → resolved → verified-closed`, or `suppressed` with a reason) and foreign-key `cell_refs`, and a committed `ledger.baseline.json` high-water baseline records `confirmed_open` counts per lens plus the `resolved_locked` claim-key set.
  4. The deterministic reducer emits a regression row when any lens's open count exceeds baseline, when a `resolved` finding's minted guard is missing/deleted, or when a `resolved_locked` claim reopens without a maintainer reopen marker; the gate passes only when `finding-regressions.ndjson` is 0 bytes and is independently re-verified by a CI script that recomputes counts from raw ledger rows (a hand-edited baseline that disagrees fails).
  5. Both the gate reducer and its verifier pass a `--self-test` proving that count-increase, missing-guard, and reopened-locked-claim each produce a regression row while a clean ledger produces zero.

**Plans**: 4 plans
**Wave 1**

- [x] 206-01-PLAN.md — Shared `ratchet-ledger.js` lifecycle helper: DEDUP-03 collapse + append/fold reducer (DEDUP-03)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 206-02-PLAN.md — `ratchet-verify.mjs`: 3-role adversarial skeptic panel + median-clamp + committed ledger writer (VERIFY-01, VERIFY-02, VERIFY-03, LEDGER-01)
- [x] 206-03-PLAN.md — `phase-ratchet-ledger.mjs`: deterministic gate reducer + committed ledger/baseline/reopen-marker quadruple (LEDGER-02, LEDGER-03, LEDGER-05)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 206-04-PLAN.md — `scripts/ci/verify_ratchet_ledger.mjs`: independent CI re-verifier + npm script wiring (LEDGER-04, LEDGER-05)

### Phase 207: Orchestration + digest + one-command round/fix loop

**Goal**: The whole pipeline is driven by two `mix` commands with a rendered digest and minimal maintainer checkpoints, resolutions auto-mint deterministic guards, and the loop provably terminates.
**Depends on**: Phase 206 (needs the verifier, ledger, and gate to orchestrate around)
**Requirements**: ORCH-01, ORCH-02, ORCH-03, ORCH-04, ORCH-05, ORCH-06, ORCH-07, ORCH-08
**Success Criteria** (what must be TRUE):

  1. Maintainer runs `mix accrue_admin.ui.round` and it builds assets, boots the admin, seeds, captures, fans out evaluators, dedups, verifies, ranks, and renders a digest in one command.
  2. The digest is a rendered HTML gallery grouping screenshots by surface with confirmed findings overlaid on their region, a ranked worklist, and a separate "decisions needed" queue for IA/product-decision items.
  3. Maintainer can batch-approve all auto-fixable confirmed findings in one action, or reject an individual finding into a suppress-list with a reason that feeds dedup so it never resurfaces.
  4. Maintainer runs `mix accrue_admin.ui.fix` and it applies the approved batch, rebuilds and commits the CSS bundle, re-captures, re-scores, updates the ledger, and auto-mints a deterministic guard (a targeted assertion in an existing spec, or a `ledger-count` guard for pure-taste findings) for each resolved finding so it cannot silently reopen.
  5. The loop reports convergence after K=2 consecutive dry rounds and escalates to the maintainer at a 6-round hard cap instead of looping indefinitely.
  6. Repeated `ui.round` runs on unchanged inputs reuse a cached prompt prefix (system preamble + tool schema + design-lens exemplar images) via Anthropic `cache_control`, measurably reducing per-run input tokens/cost, with identity (`claim_key`/`finding_id`) and the no-key/`--self-test` paths unchanged (ORCH-07). *(Folded from the Phase 205 live smoke: the proposer currently makes 7 uncached calls/screenshot, re-sending the schema + images each time.)*
  7. A maintainer can scope a round to a surface subset (the representative slice or a single surface) through a documented flag on `mix accrue_admin.ui.round`, without hand-pruning `test-results/` PNGs; an unscoped round still sweeps the full configured surface set (ORCH-08). *(Folded from the Phase 205 live smoke: there is currently no subset filter, so a slice run required manual pruning.)*

**Plans**: 8/8 plans executed
**Wave 1**

- [x] 207-01-PLAN.md
- [x] 207-02-PLAN.md

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 207-03-PLAN.md
- [x] 207-04-PLAN.md

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 207-05-PLAN.md

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 207-06-PLAN.md

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 207-07-PLAN.md — CR-01 digest accepts nullable `suggested_fix` without aborting the round (ORCH-01, ORCH-02)
- [x] 207-08-PLAN.md — CR-02 guard-mint completeness and scoped `ui.fix` CSS commit (ORCH-04, ORCH-05)

### Phase 208: Prove convergence on the representative slice + wire CI + ACCEPT

**Goal**: Prove the ratchet converges the representative slice end-to-end, freeze the first baseline, wire the deterministic-only CI gate beside the existing ones, and land maintainer ACCEPT with a runbook that tees up the full sweep.
**Depends on**: Phase 207 (needs the one-command round/fix loop)
**Requirements**: CONV-01, CONV-02, CONV-03, CONV-04, CONV-05, CONV-06, CONV-07
**Success Criteria** (what must be TRUE):

  1. The ratchet runs to `CONVERGED (2 dry rounds)` on the representative slice (design-system foundation + a few component families, plus dashboard, subscription-detail, and subscriptions-list) with every slice cell scoring ≥ 2 and both `regressions.ndjson` and `finding-regressions.ndjson` empty, and the first non-empty `ledger.baseline.json` is frozen as the slice high-water mark.
  2. A new deterministic-only CI job `admin-ui-ratchet-guardrails` passes on a PR with no `ANTHROPIC_API_KEY` and blocks on a synthetic ledger count-increase.
  3. A change that improves one persona but regresses another is caught by the ledger (the regressed lens's open count rises → gate red), proven by an automated test.
  4. Existing UI gates (`admin-hardening-guardrails`, `admin-phase200-guardrails`, asset-drift) remain green and the committed `accrue_admin.css` bundle stays fresh.
  5. A `UI-RATCHET-SIGN-OFF.md` carries the maintainer `ACCEPT` line enforced by a sign-off verifier (mirroring the Phase 200 pattern), and a documented runbook enables graduating any remaining admin surface under the ratchet as a safe follow-on round.

**Plans**: TBD
**UI hint**: yes

### Phase 209: Full-surface sweep under the ratchet (SCOPE-GATED / OPTIONAL)

**Goal**: Graduate the remaining ~19 admin surfaces round-by-round to 2 dry rounds each under the proven ratchet, with no regressions. **Optional follow-on — explicitly NOT required for v1.56 milestone sign-off** (confirmed maintainer decision: tee it up, do not force it into this milestone). Maps only the deferred `SWEEP-01`; no v1 (committed) requirement is assigned here.
**Depends on**: Phase 208 (the ratchet must be proven + CI-gated first)
**Requirements**: SWEEP-01 (deferred / not part of the v1.56 committed set)
**Success Criteria** (what must be TRUE):

  1. Each remaining admin surface reaches 2 consecutive dry rounds under the ratchet with `finding-regressions.ndjson` empty.
  2. No lens's `confirmed_open` count regresses above its frozen baseline across the sweep, and existing UI gates stay green.

**Plans**: TBD (deferred — not scheduled for v1.56)

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
| 205. Persona + design-lens evaluator harness | v1.56 | 5/5 | Complete    | 2026-07-03 |
| 206. Adversarial verifier + finding ledger + deterministic gate | v1.56 | 4/4 | Complete    | 2026-07-04 |
| 207. Orchestration + digest + one-command round/fix loop | v1.56 | 8/8 | Complete   | 2026-07-07 |
| 208. Prove convergence on slice + wire CI + ACCEPT | v1.56 | 0/0 | Not started | - |
| 209. Full-surface sweep under the ratchet (optional/scope-gated) | v1.56 | 0/0 | Scope-gated | - |

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
| SEED-004 (Admin UI blueprint redesign) | backlogged future roadmap (post-v1.56) | First-principles admin/operator UI redesign toward an "operator control plane over billing state" — IA restructure (+Usage/+Settings, de-tab Customer-360, lens-default lists), signature diagnostic surfaces ("Why blocked?" card, causality graph), sensitive-action A/B/C, new rooms (Usage/checkout/fee-recon). A genuine *new target*, distinct from the v1.56 ratchet (machinery). Reaches into core `accrue` diagnosis fns (first time in the admin-UI line). North-star: `prompts/accrue_admin_operator_ui_journey_blueprint.md`; synthesis: [`.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md`](.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md); seed: [`SEED-004`](.planning/seeds/SEED-004-admin-ui-blueprint-redesign.md). | Admin UI / IA redesign (+ core diagnosis) | after v1.56 ships → `/gsd-new-milestone` (reopen class: explicit strategy change — flagship admin surface) |
