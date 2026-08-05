---
gsd_state_version: 1.0
milestone: v1.59
milestone_name: Account-Scoped Multi-Rail & Offline Entitlements
current_phase: 221
current_phase_name: close-gap-reference-host-apple-notification-ingress
status: executing
stopped_at: Completed 221-02-PLAN.md
last_updated: "2026-08-05T17:29:02.746Z"
last_activity: 2026-08-05
last_activity_desc: Phase 221 execution started
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 75
  completed_plans: 72
  percent: 86
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-08-05 after completing Phase 220)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** Phase 221 — close-gap-reference-host-apple-notification-ingress

## Current Position

Phase: 221 (close-gap-reference-host-apple-notification-ingress) — EXECUTING
Plan: 3 of 5
Status: Ready to execute
Last activity: 2026-08-05 — Phase 221 execution started

## Post-v1.48 Pause Rule

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

v1.55 OSS Quality Evaluation & Hardening Roadmap shipped on 2026-07-03 as maintenance / release-readiness / support-contract hardening under stable core. It was audit-only and produced evidence-backed software quality, CI/CD, and DB schema-contract artifacts plus a ranked implementation roadmap; it did not change product behavior, public APIs, DB defaults, CI required-check topology, release automation, or runtime UI.

v1.58 lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync opened 2026-07-30 as **maintenance / dependency currency plus closing a prior explicitly-deferred capability** (SEED-005's trigger fired 2026-07-29 when lattice_stripe `2.0.0` published with entitlements support, unblocking Phase 127's deferred optional Stripe-native sync). Not broad feature scope: stays inside the already-shipped entitlements feature, keeps the local plan→feature map canonical as the sole grant gate (D-01/D-11), and keeps `scripts/ci/verify_entitlement_sync_isolation.sh` green throughout.

Active v1.59 clears the reopen rule through a concrete adopter requirement and explicit strategy change. B2C Alpha needs coherent Stripe/Apple account access plus extended offline use; the reusable signal is recorded without adopter identity or PII in `.planning/research/MULTI-RAIL-OFFLINE-ENTITLEMENTS.md`.

## Milestone Progress

### v1.58 Phase Summary (SHIPPED & ARCHIVED 2026-07-31 — lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync, SEED-005)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 212 | lattice_stripe 2.x bump & green reconciliation | BUMP-01, BUMP-02, BUMP-03 | Complete |
| 213 | Stripe-native advisory entitlements sync (observational-only) | SYNC-01, SYNC-02, SYNC-03, SYNC-04, SYNC-05 | Complete |
| 214 | Docs & truth reconciliation | DOCS-01, DOCS-02, DOCS-03 | Complete (verified 9/9) |
| 214.1 | DOCS-03 writer-documentation gap closure | DOCS-03 | Complete (verified 9/9) |
| 214.2 | Diagnostic-display and pagination gap closure | SYNC-02, DOCS-03 closure evidence | Complete (verified 19/19) |

Coverage: 11/11 requirements satisfied. Phases 214.1 and 214.2 supplied closure evidence without changing the canonical requirement owners. **Dependency shape:** 212 → 213 → 214 → 214.1 → 214.2.

**Guardrails (binding, out of scope):** observational-only stays inviolable (D-01/D-11) — the Stripe-native sync is a read seam, never consulted for a grant decision; the local plan→feature map (`resolver/local_map.ex`) remains the sole canonical gate. `scripts/ci/verify_entitlement_sync_isolation.sh` stays green and is extended to cover the new client-fetch path. Pin target is `~> 2.0`, not `~> 2.1`. No new required dependencies; no new admin nav rooms; no admin redesign work (that is SEED-004 M2/M3); no `accrue_portal` work. Any processor-surface/support-matrix implication updates behavior, docs, examples/verifiers, and release notes together (stable-core rule). Sync tests use the Fake/Test processor only — no live Stripe, no Chrome, fully `async`-safe. Authoritative sources: `.planning/seeds/SEED-005-lattice-stripe-entitlements-bump.md`, `accrue/lib/accrue/entitlements/*`, `scripts/ci/verify_entitlement_sync_isolation.sh`.

**Closeout evidence:** Five phase verifications passed; the independent audit reports 11/11 requirements, 10/11 integrations, and 5/5 flows. Archives live under `.planning/milestones/v1.58-*`; remaining warning-level items are recorded under Deferred Items below.

### v1.59 Phase Summary (ACTIVE — Account-Scoped Multi-Rail & Offline Entitlements, SEED-006)

| Phase | Name | Requirements | Status |
|---|---|---|---|
| 215 | Research, contracts, and Crosswake feasibility | RSCH-01..03, RAIL-04..05 | Not started |
| 216 | Additive rail and persistence foundation | RAIL-01..03 | Not started |
| 217 | Canonical projection and compatibility | ACCT-01..05 | Complete (verified 5/5; zero human verification) |
| 218 | Apple observation and repair | AAPL-01..05 | Not started |
| 219 | Offline study contract | OFF-01..06 | Not started |
| 220 | First-adopter proof and release gates | PROOF-01..05 | Not started |

Coverage: 29/29 requirements mapped exactly once; dependency shape 215→216→217→{218,219}→220. Phase 215 must prove Crosswake feasibility before later client assumptions; Phase 219 needs the accepted Phase-215 contract and Phase 217 projection, not Apple runtime implementation. v1 scope is Stripe + Apple with a 30-day revalidation target: stale offline preserves downloaded lessons/progress while all value expansion waits for reconnect, with no independent 72-hour cutoff. Google Play, Family Sharing, offer authoring, migration/proration, and configurable risk matrices remain later.

### v1.57 Phase Summary (SHIPPED & ARCHIVED 2026-07-30 — Admin Operator Control Plane (SEED-004 M1); phase dirs in `milestones/v1.57-phases/`)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 209 | Reign Subscriptions (list + detail CSS coordination) | REIGN-01, REIGN-02, COMP-01 | Complete (2026-07-19) |
| 210 | Reign Home + certify answer-first IA & copy integrity | REIGN-03, IA-01, IA-02, IA-03, IA-04, COPY-01, COPY-02 | Complete (2026-07-19) |
| 211 | Grep-gated CSS retirement & cross-surface cleanup | REIGN-04 | Complete (2026-07-29) |

Coverage: 11/11 requirements mapped to Phases 209-211 (each REQ-ID → exactly one phase). Per-phase counts: 209→3 · 210→7 · 211→1. **Dependency shape:** strictly linear — 209 → 210 → 211 (Subscriptions before Home per the research build order; CSS retirement last, after both templates land, because `.ax-inline-worklist*` / `.ax-audit-summary-row` are shared with the out-of-scope subscription detail page `subscription_live.ex`).

**Guardrails (binding, out of scope):** admin-only (`accrue_admin` LiveView templates + `assets/css`); NO core `accrue` change (M2), NO new nav rooms (M3), NO "why blocked"/causality/diagnosis synthesis, no new deps, no Tailwind migration; `ax-*` stays the styling SSOT; no `accrue_portal` work. Keep the Cobalt / quiet-confidence brand + prior de-garish/card-grammar polish. Console **density is the point** — do not over-air (no-density-regression gate on both reign phases). Every CSS/copy change rebuilds + commits BOTH generated artifacts (`priv/static/accrue_admin.css`, `examples/accrue_host/e2e/generated/copy_strings.json`); CSS retirement is grep-gated (detail-shared classes preserved); PNG-verify against the canonical Payments/Customers/Invoices reference. Authoritative sources: `prompts/accrue_admin_operator_ui_journey_blueprint.md`, `.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md`, `research/admin-ratchet-round99-confirmed-findings.json`.

**Closeout:** milestone audit passed (11/11 requirements clean, 3/3 phase verifications, 5/5 integration checks, 5/5 flows, zero blockers); planning tag `v1.57`; archived under `.planning/milestones/v1.57-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md` and `.planning/milestones/v1.57-phases/`.

### v1.56 Phase Summary (PARKED 2026-07-19 — Admin UI Ratchet: Automated Adversarial Design Evaluation; ledger + baseline preserved in `accrue_admin/e2e/ratchet/`)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 205 | Persona + design-lens evaluator harness | EVAL-01, EVAL-02, EVAL-03, EVAL-04, EVAL-05, DEDUP-01, DEDUP-02 | Complete |
| 206 | Adversarial verifier + finding ledger + deterministic gate | DEDUP-03, VERIFY-01, VERIFY-02, VERIFY-03, LEDGER-01, LEDGER-02, LEDGER-03, LEDGER-04, LEDGER-05 | Complete |
| 207 | Orchestration + digest + one-command round/fix loop | ORCH-01, ORCH-02, ORCH-03, ORCH-04, ORCH-05, ORCH-06, ORCH-07, ORCH-08 | Complete |
| 208 | Prove convergence on slice + wire CI + ACCEPT | CONV-01, CONV-02, CONV-03, CONV-04, CONV-05, CONV-06, CONV-07 | Ready to plan |
| 209 | Full-surface sweep under the ratchet | SWEEP-01 (deferred) | Scope-gated / optional — NOT required for v1.56 sign-off |

Coverage: 31/31 requirements mapped to Phases 205-208 (each REQ-ID → exactly one phase). Per-phase counts: 205→7 · 206→9 · 207→8 · 208→7 = 31 (ORCH-07/08 folded 2026-07-03 from the Phase 205 live smoke; original ratified set was 29). Phase 209 carries only the deferred SWEEP-01 and is teed up as a safe follow-on. Authoritative design source: `~/.claude/plans/ui-ratchet-txt-i-agile-honey.md` (approved 2026-07-03).

**Dependency shape:** strictly linear — 205 → 206 → 207 → 208, with 209 an optional follow-on after 208. Two-plane architecture: a noisy off-gate LLM proposer/verifier (needs `ANTHROPIC_API_KEY`, local-only) and a deterministic CI gate (committed finding ledger + minted guards; `finding-regressions.ndjson` must be 0 bytes; LLM never on the gate path).

**Guardrails (binding, out of scope):** `accrue_admin` + dev/test-only tooling only; no new billing primitives, no breaking API/route changes, no Tailwind migration; `ax-*` stays the styling SSOT; core `accrue` stays LiveView-runtime-free; no `accrue_portal` work; ratchet tooling never leaks into adopter runtime; no 13th rubric dimension (design lens sharpens existing dims); LLM is never a CI merge gate; converging all ~23 surfaces this milestone is out of scope (prove the slice, tee up SWEEP-01).

### v1.55 Phase Summary (SHIPPED & ARCHIVED 2026-07-03 — OSS Quality Evaluation & Hardening Roadmap; phase dirs in `milestones/v1.55-phases/`)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 201 | Software quality evaluation | QLT-01, QLT-02, QLT-03, QLT-04, QLT-05 | Complete (2026-07-02) |
| 202 | CI/CD performance and determinism audit | CI-01, CI-02, CI-03, CI-04, CI-05 | Complete (2026-07-02) |
| 203 | DB schema contract ADR | DB-01, DB-02, DB-03, DB-04 | Complete (2026-07-02) |
| 204 | Ranked hardening roadmap | RD-01, RD-02, RD-03, RD-04 | Complete (2026-07-03) |

Coverage: 18/18 v1.55 requirements mapped (each REQ-ID → exactly one phase). Milestone audit passed with 4/4 phase verifications, 18/18 requirements clean by 3-source audit, 8/8 integration checks, 6/6 audit-only flows, zero blockers, and Nyquist-compliant validation metadata. Archived milestone artifacts: `.planning/milestones/v1.55-phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md`, `.planning/milestones/v1.55-phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md`, `.planning/milestones/v1.55-phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`, and `.planning/milestones/v1.55-phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md`.

**Dependency shape:** 201, 202, and 203 can be reviewed/refined independently; 204 integrates their findings into the ranked hardening plan. This milestone intentionally does not ship code or schema changes.

### v1.54 Phase Summary (SHIPPED & ARCHIVED 2026-07-01 — Admin UI Page-Level Streamlining & Storybook; phase dirs in `milestones/v1.54-phases/`)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 193 | Research, re-baseline & pattern lock | RES-01, RES-02, RES-03, RES-04, STY-01 | Complete (2026-06-25) |
| 194 | Exemplar A — Dashboard | EXE-01 | Complete (2026-06-26) |
| 195 | Exemplar B — Subscription detail | EXE-02, IXN-01 | Complete (2026-06-26) |
| 196 | Exemplar C — Subscriptions list + PageHeader | EXE-03, PGH-01 | Complete (2026-06-26) |
| 197 | Propagate LIST | PRP-01 | Complete (2026-06-28) |
| 198 | Propagate DETAIL + analytics | PRP-02 | Complete (2026-06-29) |
| 199 | Cross-cutting interaction/overlay correctness + fixture stress + microcopy | IXN-01, IXN-02, IXN-03, IXN-04, FIX-01, FIX-02, CPY-01 | Complete (2026-06-30) |
| 200 | Idempotent verification & sign-off | VER-01, VER-02, VER-03, STY-02, STY-03 | Complete (2026-06-30, accepted) |

Coverage: 23/23 v1.54 requirements mapped (each REQ-ID → exactly one phase). Per-phase counts: 193→5 · 194→1 · 195→2 · 196→2 · 197→1 · 198→1 · 199→7 · 200→4 = 23. Authoritative design source: `.planning/research/SUMMARY.md` (synthesizing FEATURES.md, ARCHITECTURE.md, PITFALLS.md, v1.54-storybook-and-forward-only-qa.md). Reuses v1.53's forward-only machinery: rubric `.planning/milestones/v1.53-phases/187-audit-baseline/187-RUBRIC.md`, `baseline.cells.json`, defect ledger `defects.ndjson`, and the `regressions.ndjson` zero-regression gate.

**Note on IXN-01:** the canonical overlay primitive contract (IXN-01) is *instantiated* for the Subscription-detail side-drawer in Phase 195 (its action-menu/side-drawer groundwork) and is owned + fully swept across all pages in Phase 199. The single-phase mapping below assigns IXN-01 to **Phase 199** (its owning/sweep phase) for traceability; Phase 195 lists it as a cross-phase dependency in the roadmap detail, not a duplicate REQ assignment.

**Dependency shape:** strictly linear — 193 → 194 → 195 → 196 → 197 → 198 → 199 → 200. Foundations + the three locked pattern specs (193) precede the three exemplars (194 Dashboard / 195 Subscription detail / 196 Subscriptions list + PageHeader); exemplars lock the patterns propagation (197 LIST / 198 DETAIL) applies; cross-cutting overlay correctness + fixture stress + microcopy (199) and idempotent verification + sign-off (200) come last.

**Forward-only gate:** the Phase-187 scored-cell baseline was extended (Phase 193) with additive `surface_type:"page-flow"` cells over the ~20 admin routes; Phase 200 scored ≥ the union baseline on every component + group + page-flow cell with zero regressions. No pixel-diff (TOOL-02 stays deferred). PhoenixStorybook is the design lab (dev/test-only), not the regression engine.

### v1.53 Phase Summary (SHIPPED & ARCHIVED 2026-06-20 — Admin UI Design-System Hardening; deps strictly linear 187→188→189→190→191→192)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 187 | Audit & Baseline | VER-01 | Complete (2026-06-15) |
| 188 | Foundations hardening | FND-01, FND-02, FND-03, FND-04, FND-05, FND-06 | Complete (2026-06-17, approved) |
| 189 | Primitive & form components + component lab | CMP-01, CMP-02, CMP-03, CMP-04, CMP-05 | Complete (2026-06-18, verified) |
| 190 | Navigation, data-display & meta-component cohesion | GRP-01, GRP-02, GRP-03, GRP-04 | Complete — shift-left UAT automated (0 human steps) |
| 191 | Page & flow interaction pass + fixture stress + microcopy | IXN-01..05, PAGE-01..04, CPY-01..03, SEED-01..02 | Complete (2026-06-19, verified) |
| 192 | Idempotent verification & sign-off | VER-02, VER-03, VER-04 | Complete (2026-06-20, approved) |

Coverage: 33/33 v1.53 requirements mapped (each REQ-ID → exactly one phase). Per-phase counts: 187→1 · 188→6 · 189→5 · 190→4 · 191→14 · 192→3 = 33. Authoritative scope source: the approved scoping plan; prior design source `.planning/research/v1.51-admin-ui-depth-design.md`.

**Dependency shape:** strictly linear — 187 → 188 → 189 → 190 → 191 → 192. Foundations (188) must precede component work (189–190); page/flow integration (191) follows group cohesion; 192 verifies everything against the Phase-187 baseline.

**Refreshed rubric:** the v1.51 10-dimension rubric extended with researched additions — interaction-integrity, layer/z-index, microcopy — scored across viewport × theme × state with live interaction testing. The Phase-187 severity-ranked defect ledger + scored baseline is the only-forward reference point; Phase 192 must score ≥ baseline on every dimension/cell with zero regressions.

**Execution model:** each phase executed research-backed and verified via the GSD UI workflow (`/gsd-ui-phase` design-contract + `/gsd-ui-review`), with an adversarial multi-lens judge (correctness, a11y, brand, interaction) and a maintainer screenshot checkpoint at every phase boundary. Final sign-off (Phase 192) closes v1.51's open photographic-sign-off tech-debt.

**Guardrails (out of scope):** no Tailwind migration (FND-04 resolves the inert config, not a migration); no new billing primitives or domain features; no breaking API/route changes (internal moves ship with redirects; component public APIs stay backward-compatible); no PhoenixStorybook dependency (extend the in-app `/dev/components` kitchen — TOOL-01 deferred); no demo/host chrome redesign (only seed/fixture data, SEED-01/02); no `accrue_portal` work; no re-churn of the v1.51 motion spec or v1.52 brand tokens absent a rubric regression or new interaction pattern.

### v1.52 Phase Summary (SHIPPED & ARCHIVED 2026-06-14 — Brand System; deps 180→181→182→183→186, with 180→{184,185}→186 side-rails)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 180 | Brand Audit & DNA Lock | AUD-01, AUD-02, AUD-03 | Complete (2026-06-12) |
| 181 | SVG Pipeline + Tournament Round 1 — Divergent | LOGO-01, LOGO-02 | Complete (2026-06-12) |
| 182 | Tournament Convergent Refinement | LOGO-03 | Complete (2026-06-13) |
| 183 | Logo System Production | LOGO-04 | Complete (2026-06-13) |
| 184 | Design Tokens & Specimens | TOK-01, TOK-02, TOK-03 | Complete (2026-06-14) |
| 185 | Voice, Microcopy & Marketing Copy | COPY-01, COPY-02 | Complete (2026-06-14) |
| 186 | HTML Brand Book Assembly & Quality Gate | BOOK-01, BOOK-02 | Complete (2026-06-14) |

Coverage: 14/14 v1.52 requirements mapped (each REQ-ID → exactly one phase). Design source: `.planning/research/v1.52-brand-system-design.md`. Shipped, archived, and tagged `v1.52` on 2026-06-14.

### v1.51 Phase Summary (SHIPPED & ARCHIVED 2026-06-04 — Admin UI: Depth Pass; deps A→B→C→{D,E}→F; phase dirs in milestones/v1.51-phases/)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 174 | A — Design-System Gap Closure & Token Completeness | DSY-01, DSY-02, DSY-03 | Complete |
| 175 | B — Persona-Driven IA Spine | IA-01, IA-02, IA-03, IA-04, IA-05, IA-06, IA-07 | Complete |
| 176 | C — Systematic Per-Screen Rubric Uplift | SCR-01, SCR-02, SCR-03, SCR-04 | Complete |
| 177 | D — Motion & Micro-interaction Design | MOT-01, MOT-02, MOT-03 | Complete |
| 178 | E — Seed Expressiveness & State Coverage | SEED-01, SEED-02 | Complete |
| 179 | F — Screenshot-Driven Visual QA Loop & Sign-off | QA-01, QA-02, QA-03 | Complete |

Coverage: 22/22 v1.51 requirements mapped (each REQ-ID → exactly one phase). Design source: `.planning/research/v1.51-admin-ui-depth-design.md`.

### v1.50 Phase Summary (shipped 2026-06-02 via PR #32; archived 2026-06-03 — see milestones/v1.50-*)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 167 | Design Tokens & Motion Foundation | AUI-01 | Complete |
| 168 | Typography & Icon System | AUI-02 | Complete |
| 169 | Information Architecture — Home, Nav & Search | AUI-03 | Complete |
| 170 | Cross-Screen Threading & Microcopy | AUI-04 | Complete |
| 171 | Shared Detail Components & Screen Refactor | AUI-05 | Complete |
| 172 | Seed Enrichment & Component Kitchen | AUI-06 | Complete |
| 173 | Rubric Audit & Visual/A11y Coverage | AUI-07 | Complete |

### v1.49 Phase Summary

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 163 | Realistic Domain & Rich Seeds | EVD-01, EVD-02 | Complete |
| 164 | Docker DX & Optimized Caching | EVD-03, EVD-04 | Complete |
| 165 | E2E Automation & Shift-Left CI | E2E-01, E2E-02, E2E-03, E2E-04 | Complete |
| 166 | Adoption DX Docs | DOC-01, DOC-02, DOC-03 | Complete |

### Recently shipped milestones

**v1.55** (shipped & archived **2026-07-03**): 4 phases (**201–204**), 18 requirements. Theme: OSS Quality Evaluation & Hardening Roadmap. Audit passed; see `.planning/milestones/v1.55-ROADMAP.md`.

**v1.54** (shipped & archived **2026-07-01**): 8 phases (**193–200**), 23 requirements. Theme: Admin UI Page-Level Streamlining & Storybook. Audit passed; see `.planning/milestones/v1.54-ROADMAP.md`.

**v1.53** (shipped & archived **2026-06-20**): 6 phases (**187–192**), 33 requirements. Theme: Admin UI Design-System Hardening. See `.planning/milestones/v1.53-ROADMAP.md`.

**v1.52** (shipped & archived **2026-06-14**): 7 phases (**180–186**), 14 requirements. Theme: Brand System. See `.planning/milestones/v1.52-ROADMAP.md`.

**v1.51** (shipped & archived **2026-06-04**): 6 phases (**174–179**), 22 requirements. Theme: Admin UI Depth Pass. Audit: `.planning/milestones/v1.51-MILESTONE-AUDIT.md`.

**v1.49** (shipped & archived **2026-06-02**): 4 phases (**163–166**), 11 requirements. Theme: Realistic Demo App & Adoption Evidence. Audit: `.planning/milestones/v1.49-MILESTONE-AUDIT.md`.

**v1.48** (shipped & archived **2026-06-01**): 4 phases (**159–162**), 9 requirements. Theme: Release Readiness + Stable Core Posture. Audit: `.planning/v1.48-v1.48-MILESTONE-AUDIT.md` (or equivalent closeout proof).

**v1.47** (shipped & archived **2026-05-31**): 5 phases (**154–158**), 11 requirements. Theme: ENT-10 Polish + Adopter-Proof Completeness. Audit: `.planning/milestones/v1.47-MILESTONE-AUDIT.md`.

**v1.46** (shipped & archived **2026-05-30**): 3 phases (**151–153**), 1 requirement (MNT-01). Theme: Maintenance & Closure — routine issue triage, dependency updates, @since annotation fixes, Three Zeros gate, Hex 1.3.0 publish, and audit trail closure. Audit: `.planning/v1.46-v1.46-MILESTONE-AUDIT.md`.

**v1.45** (shipped & archived **2026-05-29**): 2 phases (**149–150**), 4 requirements (BAN-01..BAN-04). Theme: Multi-channel Dunning (In-App Banners). Audit: `.planning/v1.45-v1.45-MILESTONE-AUDIT.md`.

## Performance Metrics

**Velocity:**

- Total plans completed: 215
- Average duration: 1m
- Total execution time: 1m

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 187 P01 | 4m 12s | 2 tasks | 3 files |
| Phase 187 P02 | 6m | 3 tasks | 8 files |
| Phase 187 P03 | 19m | 2 tasks | 1 files |
| Phase 187 P04 | 9m | 2 tasks | 4 files |
| Phase 188 P01 | 16 min | 2 tasks | 5 files |
| Phase 188 P02 | 6 min | 2 tasks | 2 files |
| Phase 188 P03 | 3 min | 2 tasks | 2 files |
| Phase 188 P04 | 5 min | 2 tasks | 5 files |
| Phase 188 P05 | 9 min | 2 tasks | 5 files |
| Phase 188 P06 | 38 min | 2 tasks | 3 files |
| Phase 189 P01 | 3 min | 2 tasks | 4 files |
| Phase 189 P02 | 3 min | 2 tasks | 8 files |
| Phase 189-primitive-form-components-component-lab P03 | 25min | 2 tasks | 3 files |
| Phase 189-primitive-form-components-component-lab P05 | 8min | 3 tasks | 1 files |
| Phase 190 P01 | 7 min | 3 tasks | 5 files |
| Phase 190 P02 | 11m32s | 3 tasks | 5 files |
| Phase 190 P03 | 10m32s | 3 tasks | 10 files |
| Phase 190 P04 | 6m28s | 3 tasks | 11 files |
| Phase 190 P05 | serial | 3 tasks | 5 files |
| Phase 190 P06 | 19min | 2 tasks | 3 files |
| Phase 191 P01 | 12 min | 3 tasks | 4 files |
| Phase 191 P02 | 7 min | 2 tasks | 3 files |
| Phase 191 P06 | 7 min | 2 tasks | 4 files |
| Phase 191 P03 | 16m | 2 tasks | 10 files |
| Phase 191 P04 | 29 min | 2 tasks | 19 files |
| Phase 191 P05 | 16m 34s | 2 tasks | 13 files |
| Phase 191 P07 | 12m | 2 tasks | 3 files |
| Phase 188 P08 | 68 | 3 tasks | 11 files |
| Phase 193 P01 | 15m | 2 tasks | 4 files |
| Phase 193 P02 | 2m | 1 tasks | 1 files |
| Phase 193 P03 | 15 | 1 tasks | 2 files |
| Phase 193 P04 | 526s | 2 tasks | 7 files |
| Phase 193 P05 | 558 | - tasks | - files |
| Phase 194 P01 | 322s | 3 tasks | 3 files |
| Phase 194 P02 | 191s | 2 tasks | 1 files |
| Phase 194 P03 | 234s | 2 tasks | 2 files |
| Phase 194 P04 | 624s | 3 tasks | 2 files |
| Phase 195 P01 | 9m 15s | 3 tasks | 4 files |
| Phase 195 P02 | 9m 50s | 3 tasks | 1 files |
| Phase 195 P03 | 10m 35s | 3 tasks | 8 files |
| Phase 195 P04 | 4m 10s | 3 tasks | 4 files |
| Phase 195 P05 | 6m 54s | 3 tasks | 3 files |
| Phase 195 P06 | 7m 52s | 3 tasks | 6 files |
| Phase 195 P07 | 21m | 3 tasks | 4 files |
| Phase 195 P08 | 10m 38s | 4 tasks | 7 files |
| Phase 196 P01 | 13min | 3 tasks | 6 files |
| Phase 196 P02 | 4min | 2 tasks | 2 files |
| Phase 196 P03 | 9min | 3 tasks | 4 files |
| Phase 196 P04 | 12m | 3 tasks | 4 files |
| Phase 196 P05 | 9m | 2 tasks | 6 files |
| Phase 197 P01 | 16min | 3 tasks | 4 files |
| Phase 197-propagate-list P02 | approximately 45 minutes | 3 tasks | 8 files |
| Phase 197 P03 | 9min | 3 tasks | 10 files |
| Phase 197 P04 | 14m | 3 tasks | 4 files |
| Phase 197 P05 | 9m 38s | 2 tasks | 4 files |
| Phase 197 P06 | 1044 | 3 tasks | 7 files |
| Phase 197 P07 | 12m32s | 3 tasks | 3 files |
| Phase 198 P01 | 10m 39s | 3 tasks | 2 files |
| Phase 198 P02 | 10m | 3 tasks | 5 files |
| Phase 198 P03 | 7m 47s | 3 tasks | 6 files |
| Phase 198 P04 | 16m 39s | 3 tasks | 4 files |
| Phase 198 P08 | 8m 23s | 3 tasks | 4 files |
| Phase 198 P05 | 21m | 3 tasks | 6 files |
| Phase 198 P06 | 15m 37s | 3 tasks | 10 files |
| Phase 198 P07 | 34min | 3 tasks | 8 files |
| Phase 198-propagate-detail-analytics P09 | 16m 56s | 3 tasks | 2 files |
| Phase 199 P01 | 10m 31s | 1 tasks | 2 files |
| Phase 199 P02 | 4m 52s | 1 tasks | 4 files |
| Phase 199 P03 | 30m 06s | 1 tasks | 6 files |
| Phase 199 P04 | 16 min | 1 tasks | 3 files |
| Phase 199 P05 | 3m 12s | 1 tasks | 4 files |
| Phase 199 P11 | 6m 51s | 1 tasks | 10 files |
| Phase 199 P06 | 20m | 1 tasks | 7 files |
| Phase 199 P12 | 1h 45m 41s | 1 tasks | 13 files |
| Phase 199 P13 | 11m26s | 1 tasks | 12 files |
| Phase 199 P07 | 5m 35s | 1 tasks | 4 files |
| Phase 199 P08 | 40m | 1 tasks | 7 files |
| Phase 199 P09 | 9 min | 1 tasks | 4 files |
| Phase 199 P10 | 69m30s | 3 tasks | 8 files |
| Phase 199 P14 | 14m | 2 tasks | 8 files |
| Phase 199 P15 | 7m 28s | 1 tasks | 2 files |
| Phase 200 P01 | 14m 9s | 3 tasks | 8 files |
| Phase 200 P02 | 17min | 2 tasks | 3 files |
| Phase 200 P03 | 10m 4s | 2 tasks | 3 files |
| Phase 200 P04 | 15m | 2 tasks | 5 files |
| Phase 200 P05 | 7m 14s | 2 tasks | 5 files |
| Phase 200 P06 | 24m | 3 tasks | 5 files |
| Phase 202 P01 | 12 min | 3 tasks | 2 files |
| Phase 203 P01 | 6m 12s | 3 tasks | 2 files |
| Phase 204 P01 | 00:09:02 | 3 tasks | 2 files |
| Phase 205 P01 | 4m49s | 2 tasks | 1 files |
| Phase 205 P02 | 13m | 2 tasks | 7 files |
| Phase 205 P03 | 4m 43s | 3 tasks | 2 files |
| Phase 205 P05 | 4m | 1 tasks | 1 files |
| Phase 205 P04 | 6m4s | 2 tasks | 1 files |
| Phase 206 P01 | 10min | 2 tasks | 1 files |
| Phase 206 P02 | 25min | 2 tasks | 2 files |
| Phase 206 P03 | 8min | 3 tasks | 5 files |
| Phase 206 P04 | 15min | 2 tasks | 2 files |
| Phase 207 P01 | 5min | 2 tasks | 2 files |
| Phase 207 P02 | 3min | 2 tasks | 4 files |
| Phase 207 P03 | 18m | 2 tasks | 5 files |
| Phase 207 P04 | 18 | 3 tasks | 2 files |
| Phase 207 P05 | 8m | 2 tasks | 3 files |
| Phase 207 P6 | 20min | 2 tasks | 6 files |
| Phase 207 P07 | 9 min | 1 tasks | 1 files |
| Phase 207 P08 | 12 min | 2 tasks | 5 files |
| Phase 208 P01 | 35 min | 3 tasks | 2 files |
| Phase 208 P02 | 45 min | 2 tasks | 1 files |
| Phase 208 P03 | 55 min | 3 tasks | 3 files |
| Phase 209 P01 | 5min | 2 tasks | 0 files |
| Phase 209 P02 | 15min | 2 tasks | 3 files |
| Phase 209 P03 | 25min | 3 tasks | 3 files |
| Phase 210 P01 | 8m | 2 tasks | 3 files |
| Phase 210 P02 | ~30m | 3 tasks | 3 files |
| Phase 210 P03 | 23min | 3 tasks | 5 files |
| Phase 211 P01 | 16 min | 2 tasks | 2 files |
| Phase 211 P02 | 15 min | 2 tasks | 3 files |
| Phase 211 P03 | 6 min | 2 tasks | 1 files |
| Phase 211 P04 | 50 min | 3 tasks | 1 files |
| Phase 212 P01 | 20min | 3 tasks | 6 files |
| Phase 213 P01 | approximately 6 minutes | 2 tasks | 8 files |
| Phase 213 P02 | 6 min | 2 tasks | 4 files |
| Phase 213 P03 | 347s | 2 tasks | 7 files |
| Phase 213 P04 | 4 min | 2 tasks | 4 files |
| Phase 213 P05 | 8min | 1 tasks | 2 files |
| Phase 214 P01 | 41min | 3 tasks | 12 files |
| Phase 214 P02 | 12min | 3 tasks | 12 files |
| Phase 214-docs-truth-reconciliation P03 | 8min | 2 tasks | 4 files |
| Phase 214.1 P01 | 4m | 2 tasks | 3 files |
| Phase 214.1 P02 | 12m | 2 tasks | 4 files |
| Phase 214.1-close-gap-docs-03-reconcile-stripesync-writer-documentation P03 | 3min | 1 tasks | 2 files |
| Phase 214.1 P04 | 4m | 1 tasks | 2 files |
| Phase 214.2 P01 | 4m | 1 tasks | 6 files |
| Phase 214.2-close-gap-sync-02-docs-03-surface-advisory-entitlement-diagn P04 | 14m | 2 tasks | 4 files |
| Phase 214.2 P02 | 6m | 2 tasks | 3 files |
| Phase 214.2 P03 | 7m | 2 tasks | 6 files |
| Phase 215 P01 | 8min | 2 tasks | 8 files |
| Phase 215 P02 | 12min | 2 tasks | 6 files |
| Phase 215 P03 | 20min | 3 tasks | 7 files |
| Phase 215 P04 | 18min | 3 tasks | 9 files |
| Phase 215 P05 | 1h | 2 tasks | 6 files |
| Phase 215 P06 | 9min | 2 tasks | 4 files |
| Phase 215-research-contracts-and-crosswake-feasibility P07 | 0h 25m | 2 tasks | 8 files |
| Phase 215 P08 | 4m | 2 tasks | 5 files |
| Phase 215-research-contracts-and-crosswake-feasibility P09 | 18m | 2 tasks | 6 files |
| Phase 215 P10 | 4m | 1 tasks | 2 files |
| Phase 215-research-contracts-and-crosswake-feasibility P11 | 6 min | 2 tasks | 5 files |
| Phase 215 P12 | 4 min | 2 tasks | 4 files |
| Phase 215 P13 | 5 min | 2 tasks | 6 files |
| Phase 215 P14 | 4 min | 1 tasks | 2 files |
| Phase 215 P15 | 2 min | 1 tasks | 2 files |
| Phase 216 P01 | 6min | 1 tasks | 5 files |
| Phase 216-additive-rail-and-persistence-foundation P02 | 4min | 2 tasks | 2 files |
| Phase 216-additive-rail-and-persistence-foundation P03 | 18m | 3 tasks | 5 files |
| Phase 216-additive-rail-and-persistence-foundation P04 | 14min | 2 tasks | 6 files |
| Phase 216-additive-rail-and-persistence-foundation P05 | 5m | 2 tasks | 7 files |
| Phase 216 P06 | 6m | 2 tasks | 6 files |
| Phase 217 P01 | 10m | 1 tasks | 6 files |
| Phase 217 P02 | 24m | 2 tasks | 5 files |
| Phase 217-canonical-projection-and-compatibility P03 | 18m | 2 tasks | 5 files |
| Phase 217-canonical-projection-and-compatibility P04 | 17min | 2 tasks | 5 files |
| Phase 217 P05 | 7m | 2 tasks | 5 files |
| Phase 218-apple-observation-and-repair P01 | 0 | 1 tasks | 8 files |
| Phase 218 P02 | 3m | 1 tasks | 1 files |
| Phase 218-apple-observation-and-repair P10 | 7m | 1 tasks | 5 files |
| Phase 218-apple-observation-and-repair P11 | 31m | 3 tasks | 10 files |
| Phase 218-apple-observation-and-repair P12 | 8m | 2 tasks | 7 files |
| Phase 218 P13 | 6m | 1 tasks | 2 files |
| Phase 218-apple-observation-and-repair P14 | 6min | 1 tasks | 3 files |
| Phase 218-apple-observation-and-repair P15 | 5min | 2 tasks | 5 files |
| Phase 218 P16 | 24 min | 1 tasks | 2 files |
| Phase 219 P01 | 16min | 2 tasks | 6 files |
| Phase 219 P02 | 4min | 2 tasks | 3 files |
| Phase 219 P03 | 8m | 2 tasks | 8 files |
| Phase 219-offline-study-contract P04 | 6m | 2 tasks | 8 files |
| Phase 219-offline-study-contract P05 | 25m | 2 tasks | 6 files |
| Phase 220-first-adopter-proof-and-release-gates P01 | 15m | 2 tasks | 6 files |
| Phase 220 P02 | 9min | 2 tasks | 6 files |
| Phase 220-first-adopter-proof-and-release-gates P04 | 6min | 2 tasks | 7 files |
| Phase 220 P03 | 8min | 2 tasks | 18 files |
| Phase 220-first-adopter-proof-and-release-gates P05 | 3min | 2 tasks | 8 files |
| Phase 220-first-adopter-proof-and-release-gates P06 | 7min | 1 tasks | 4 files |
| Phase 220 P07 | 6m | 2 tasks | 4 files |
| Phase 220 P09 | 24m | 3 tasks | 4 files |
| Phase 220 P12 | 1m | 3 tasks | 7 files |
| Phase 220 P13 | 65m | 2 tasks | 6 files |
| Phase 221-close-gap-reference-host-apple-notification-ingress P01 | 1 | 2 tasks | 1 files |
| Phase 221 P02 | 14min | 1 tasks | 4 files |

## Accumulated Context

### Key Planning Decisions for v1.56

- **2026-07-03:** Opened v1.56 "Admin UI Ratchet: Automated Adversarial Design Evaluation" (Phases 205-209, continue-numbering from v1.55's Phase 204). Reopen decision: **explicit strategy change** (design quality of the flagship adopter-facing `accrue_admin` surface elevated to a strategic priority — same class accepted for v1.50–v1.54) **plus** a concrete maintainer request. Recorded in `PROJECT.md`.
- **2026-07-03:** Roadmap created — 5 phases (205-209); 29/29 v1 requirements mapped to Phases 205-208 (each REQ-ID → exactly one phase); Phase 209 (full-surface sweep, SWEEP-01) is scope-gated/optional and explicitly NOT required for v1.56 sign-off (confirmed maintainer decision: prove on the representative slice, tee up the ~19-surface sweep as safe follow-on). Roadmapper formalized success criteria + traceability from the approved authoritative plan `~/.claude/plans/ui-ratchet-txt-i-agile-honey.md` (did not invent a different breakdown).
- **2026-07-03:** Central design principle locked: the subjective LLM is a *proposer/ranker* only; humans triage; a committed forward-only finding ledger + minted deterministic guards are what ratchet. This reconciles the v1.54 team's deliberate refusal to let a non-deterministic LLM gate the UI — the LLM runs locally (maintainer's key, needs `ANTHROPIC_API_KEY`), CI gates the deterministic layer only (`finding-regressions.ndjson` must be 0 bytes, independently re-verified from raw ledger rows). ~90% of the mechanical foundation is reused: `admin-visuals.spec.js` capture, `score-visuals.mjs` (promoted), the 30,348-cell baseline grammar, and the `phase200-scorecard.mjs`/`verify_phase200_scorecard.mjs` forward-only reducer pattern. All new code is dev/test-only under `accrue_admin/e2e/ratchet/` + `scripts/ci/verify_ratchet_ledger.mjs` + two `mix accrue_admin.ui.*` tasks.
- **2026-07-03 (205-03):** `ratchet-propose.mjs` shipped — forked `score-visuals.mjs` into a defect-only proposer. 6 job-anchored operator-persona lenses issue forced `tool_use` (`emit_findings`) calls; the tool `enum`s are advisory only (Sonnet 4.5 lacks strict outputs) — the harness re-derives every identity field (`claim_key`/`finding_id`/`region_tag`/`overlay_tags`/`dimension`) from `region-tags.js` and ignores model-supplied identity (D-04/D-16). Guard order self-test→no-key→SDK-import (EVAL-03); `temperature: 0` config-gated (400s on 4.7+/5-family); parse-time drops (justification-token gate + taste denylist) + N=12/image cap; rows carry the full `ratchet-candidate/1` four-group schema with `cell_refs` FK into the census (D-12/D-17). Reads `tool_use .input.findings`, never `content[0]` text (Pitfall 6).
- **2026-07-03:** Biggest brand risk mitigated by design: over-whitespacing a dense operator console. The 3-role verifier includes an *operator-density-defender* that refutes any fix reducing operator density or adding marketing whitespace without a task-completion justification; every candidate must cite an admissible justification token (`rubric-dim-below-bar` | `persona-job-miss:<job>` | `token-bypass`) or it is rejected before human triage. Termination is guaranteed by a finite frozen-signature lattice + K=2 dry rounds + a 6-round hard cap escalating to the maintainer.

### Key Planning Decisions for v1.57

- **2026-07-19:** Opened v1.57 "Admin Operator Control Plane (SEED-004 M1)" (Phases 209–211, continue-numbering from v1.56's Phase 208; v1.56's placeholder Phase 209 SWEEP-01 was never created, so 209 was reused). Reopen decision: explicit strategy change (flagship adopter-facing admin surface elevated to a strategic redesign — same class accepted for v1.50–v1.54). Scope stayed admin-only: no core `accrue` change (M2), no new nav rooms (M3), no new deps, no Tailwind migration, `ax-*` stayed the styling SSOT, no `accrue_portal` work.
- **2026-07-30:** v1.57 shipped & archived. Milestone audit passed with 3/3 phase verifications, 11/11 requirements clean, 5/5 integration checks, 5/5 flows, zero blockers. UAT closed with zero human checkpoints via a new deterministic Playwright `toHaveScreenshot` pixel-diff gate (4 admin surfaces × light/dark).

### Key Planning Decisions for v1.58

- **2026-07-30:** Opened v1.58 "lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync" (Phases 212-214, continue-numbering from v1.57's Phase 211). Reopen decision: **maintenance / dependency currency** (major-version bump of a required core dependency, cf. v1.46) **plus closing a prior explicitly-deferred capability** (SEED-005's trigger fired 2026-07-29 when lattice_stripe `2.0.0` published with entitlements support, unblocking Phase 127's deferred optional Stripe-native sync). Recorded in `PROJECT.md`.
- **2026-07-30:** Roadmap created — 3 phases (212–214), 11/11 v1 requirements mapped (each REQ-ID → exactly one phase), strictly linear deps 212→213→214 (the bump must land green before the 2.x `LatticeStripe.Entitlements.*` modules exist for Phase 213 to consume; docs in Phase 214 reconcile against the final shipped behavior of both). The recommended 3-phase split from the milestone brief was used as-is (SYNC's 5 requirements cohere tightly around one client-fetch+cache-write+isolation-guard+test-proof story, so it was not further split).
- **2026-07-30:** Locked guardrails threaded into every phase's success criteria: observational-only stays inviolable (D-01/D-11) — the Stripe-native sync is a read seam, never a grant gate, and the local plan→feature map (`resolver/local_map.ex`) remains canonical; `scripts/ci/verify_entitlement_sync_isolation.sh` stays green and is extended to the new client-fetch path; pin target is `~> 2.0`, not `~> 2.1`; Three Zeros (test/dialyzer/credo/coverage) green across all packages is the Phase 212 exit gate; sync tests use only the Fake/Test processor (no live Stripe, no Chrome, fully `async`-safe).
- **2026-07-31:** Milestone audit found DOCS-03 unsatisfied: the release truth contract hard-pins 1.4.0 and rejects the aligned Release Please 1.5.0 candidate. v1.58 remains active; do not tag/archive as verified until Phase 214 re-verifies.

### Key Planning Decisions for active v1.59

- **2026-07-31:** Activated v1.59 "Account-Scoped Multi-Rail & Offline Entitlements" (Phases 215-220) from promoted SEED-006. Driving adopter is anonymized as B2C Alpha; no adopter identity or PII is permitted in planning, fixtures, tokens, telemetry, or diagnostics.
- **2026-07-31:** The versioned canonical research bundle — `.planning/research/v1.59-SUMMARY.md`, `v1.59-DECISION-TABLE.md`, `v1.59-PITFALLS.md`, and `RESEARCH-INDEX.md` — controls milestone policy. It supersedes stale historical 72-hour offline wording: revalidation targets 30 days (shortened by known provider bounds); stale offline keeps downloaded lessons and progress usable but blocks new premium downloads and every other value-expanding action until reconnect; there is no independent 72-hour cutoff.
- **2026-07-31:** Entitlement access is rail-neutral and account-scoped; lifecycle control remains resource/rail-aware. `Accrue.Processor` remains the controllable gateway seam; Apple uses a narrower verified lifecycle observer.
- **2026-07-31:** Additive compatibility is binding: retain `processor`, bare default-rail `price_ids`, deterministic `customer/1`, existing gate return types, gateway `Subscription`, and Stripe-only observational `EntitlementSummary`; add rails/default rail, qualified products, multi-customer reads, capabilities/management actions, and snapshot APIs.
- **2026-07-31:** Offline proof is compact ES256 JWS, device P-256-bound, account-revisioned, and atomically replaced on reconnect by a fresh allow proof or signed deny tombstone. It is never provider truth and contains no raw provider payload or adopter identity.
- **2026-07-31:** Purchase eligibility blocks an equivalent second-rail purchase by default, with an explicit host warning/override path; no automatic lifecycle migration, cancellation, refund, transfer, or proration. Apple ownership conflicts quarantine and never use heuristic or automatic reassignment.
- **2026-07-31:** Google Play is SEED-007 and stays dormant until Android is scheduled or a second adopter requires it. Family Sharing, offers, cross-rail migration/proration, arbitrary TTL/risk knobs, and advanced attestation are later.

### Key Planning Decisions for v1.54

- **2026-06-24:** Opened v1.54 "Admin UI Page-Level Streamlining & Storybook" (Phases 193–200, continue-numbering from v1.53's Phase 192). Reopen decision: explicit strategy change (page-level design quality of the flagship adopter-facing surface elevated to strategic priority — same class as v1.50/v1.51/v1.52/v1.53) **plus firsthand-observed page-level usability defects** in the running demo (modal-behind-scrim, scroll traps, floating/mispositioned overlays, won't-dismiss, hover-on-non-interactive empty states, disabled-looks-enabled). No new billing primitives, no breaking API/route changes, no Tailwind migration, core stays LiveView-runtime-free. Recorded in `PROJECT.md`.
- **2026-06-25:** Roadmap created — 8 phases (193–200), 23/23 requirements mapped (each REQ-ID → exactly one phase), strictly linear deps 193→194→195→196→197→198→199→200. Roadmapper formalized success criteria + traceability from the approved 8-phase plan + research SUMMARY (did not invent a different breakdown).
- **2026-06-25:** The milestone backbone is structural, not cosmetic — the maintainer's reported defects are page-composition/runtime-interaction failures invisible to the existing source-text gates. Two-part backbone: (a) one canonical overlay primitive (body-level portal + ref-counted iOS-safe scroll-lock + `inert` background + single dismissal contract + origin-aware enter motion) every modal/drawer/popover routes through; (b) a rendered state-matrix gate — PhoenixStorybook (dev/test-only) + axe-core + Playwright interaction battery, folded into v1.53's forward-only cell-baseline as `surface_type:"page-flow"` cells under the unchanged `regressions.ndjson` rule. Prevention via source-lint where mechanical (3 new guards); rendered-detection in CI where compositional.
- **2026-06-25:** Reverses v1.53's TOOL-01 deferral — PhoenixStorybook is **adopted** `only: [:dev, :test]`, mounted via a `Code.ensure_loaded?`-guarded sibling-scope router wrap (Mailglass precedent) so adopters never carry it and a host dev compile exposes no storybook route. The in-app `/dev/components` kitchen stays as a second renderer (registry stays SSOT) backing the Phase-189/190 drift tests. TOOL-02 (pixel-diff VR) stays deferred — the scored-cell forward-only gate over real composed routes is the mechanism (pixel-diff would flag every intentional v1.54 improvement as a regression).
- **2026-06-25:** IXN-01 (canonical overlay primitive) is *instantiated* for the Subscription-detail side-drawer in Phase 195 (its action-menu/side-drawer groundwork is a cross-phase dependency) but is **owned/assigned to Phase 199** (the full cross-cutting sweep) for single-phase traceability — avoids a duplicate REQ assignment while making the dependency explicit in the roadmap detail. Page-design work is archetype-driven: lock three pattern specs (193), nail one exemplar per archetype (194 Dashboard / 195 Subscription detail / 196 Subscriptions list + PageHeader), then propagate (197 LIST / 198 DETAIL).

### Key Planning Decisions for v1.53

- **2026-06-18 (Phase 189, post-execution):** Reversed locked decisions **D-05/D-07** — the `/billing/dev/components` lab now renders a **single state-matrix column following the global topbar theme toggle** instead of side-by-side light/dark columns. Rationale: dark-mode verification is redundant (`admin-a11y.spec.js` already scans every surface in both themes via the global toggle); the D-07 `.accrue-admin [data-theme="dark"]` sub-tree mechanism was bug-prone (dark-column contrast bug) and complex; two-column broke mobile (~195k px). Removed dark column, headers, the `themeColumnDeltaProbe` e2e, and the per-column `color` re-declaration; `theme.css` sub-tree block retained as harmless dead code (avoids frozen-foundation + FND-05 verifier churn). Recorded in 189-CONTEXT.md / 189-UI-SPEC.md.
- **2026-06-14:** Opened v1.53 "Admin UI Design-System Hardening" (Phases 187–192, continue-numbering from v1.52's Phase 186). Reopen decision: explicit strategy change (flagship adopter-facing surface design quality elevated to strategic priority — same class as v1.50/v1.51/v1.52) **plus firsthand-observed interaction defects** in the running demo. No new billing primitives, no breaking API/route changes, no Tailwind migration. Recorded in `PROJECT.md`.
- **2026-06-14:** Six-phase structure approved via an ExitPlanMode-approved scoping plan; roadmapper formalized success criteria + traceability only (did not invent a different breakdown). Strictly linear deps 187→188→189→190→191→192.
- **2026-06-14:** Differentiated value over v1.51: v1.51 audited *screens*, not *components in isolation* (only 7 of 28 specced); its sign-off was LLM-scored stills (logged `tech_debt`) blind to interaction bugs; component-*group* cohesion + a few foundation gaps (typography bundles, z-index formalization, inert-Tailwind decision) left open. v1.53 closes all of these and discharges v1.51's photographic-sign-off tech-debt.
- **2026-06-14:** Refreshed rubric = v1.51's 10 dimensions + researched additions (interaction-integrity, layer/z-index, microcopy), scored across viewport × theme × state with live interaction testing. Phase-187 severity-ranked defect ledger + scored baseline is the only-forward reference; Phase 192 must be ≥ baseline with zero regressions.
- **2026-06-14:** Component lab = extend the in-app `/dev/components` kitchen (TOOL-01 PhoenixStorybook deferred). Sign-off = adversarial multi-lens judge + maintainer screenshot checkpoint at every phase boundary, executed via the GSD UI workflow (`/gsd-ui-phase` + `/gsd-ui-review`).

### Key Planning Decisions for v1.52

- **2026-06-11:** Opened v1.52 "Brand System". Reopen decision: brand/DX investment in adopter-facing presentation surfaces — same justification class as v1.50/v1.51; no billing primitives. Recorded in `PROJECT.md`.
- **2026-06-11:** User decisions ratified (via AskUserQuestion in design phase): full checkpoint set; round 1 = 12–16 concepts across 4 directions; seed latitude is evidence-gated (Geist + palette are defaults).
- **2026-06-11:** Hard logo constraints locked (binding on every candidate): no rect background/container shape; logotype optically close to mark; main lockup no subtitle (with-subtitle variant ships separately); fully-integrated custom typemark options required.
- **2026-06-11:** Admin `ax-*` tokens in `accrue_admin/assets/css/theme.css` stay SSOT and are untouched this milestone — brandbook documents the brand layer only.
- **2026-06-11:** Exploration artifacts (galleries, rejected candidates, TOURNAMENT.md) stay in `.planning/milestones/v1.52-phases/` — not in `brandbook/`.
- **2026-06-11:** `brandbook/` size budget ≤ 2 MB enforced at Phase 186 verification.

### Key Planning Decisions for v1.49

- **2026-06-01:** Focus on a highly realistic click-around demo for `examples/accrue_host` to serve as adoption evidence.
- **2026-06-01:** E2E Playwright tests must be deterministic, flake-free, and integrated into CI (shift-left devops mindset).
- **2026-06-01:** Docker DX must be seamless with optimized cache layers to allow maintainers and adopters to iterate quickly without redownloading dependencies (Tailwind, Hex deps).
- **2026-06-02:** Core onboarding and billing Playwright coverage is consolidated into a single serial spec because the Fake processor is shared process state; CI must preserve serial execution for sensitive subscription-mutating flows.
- **2026-06-02:** CI now enforces Phase 165 through native sharded Playwright E2E, Docker Compose boot smoke, and mandatory periodic live-Stripe parity.
- **2026-06-02:** v1.49 shipped and archived. Future milestones return to stable-core / demand-driven expansion posture unless reopened by concrete adopter, correctness, security, operational, or strategy evidence.

### Historical Research Assets

- **v1.17 Friction Inventory (FRG-01):** `.planning/research/v1.17-FRICTION-INVENTORY.md`
- **v1.17 North Star:** `.planning/research/v1.17-north-star.md` — stop rules S1–S5.
- **v1.47 Research:** `.planning/research/SUMMARY.md`
- **v1.51 Admin UI Depth Design:** `.planning/research/v1.51-admin-ui-depth-design.md` (prior design source carried forward for v1.53/v1.54)
- **v1.52 Brand System Design:** `.planning/research/v1.52-brand-system-design.md`
- **v1.54 Research (archived source):** `.planning/research/SUMMARY.md` (page-level streamlining + Storybook synthesis of FEATURES.md, ARCHITECTURE.md, PITFALLS.md, v1.54-storybook-and-forward-only-qa.md)

### Roadmap Evolution

- v1.48 shipped and archived 2026-06-01: Phases 159–162
- v1.49 shipped and archived 2026-06-02: Phases 163–166
- v1.50 shipped and archived 2026-06-03: Phases 167–173
- v1.51 shipped and archived 2026-06-04: Phases 174–179
- v1.52 shipped and archived 2026-06-14: Phases 180–186
- v1.53 shipped and archived 2026-06-20: Phases 187–192
- v1.54 opened 2026-06-24 and shipped 2026-07-01: Phases 193–200 archived under `.planning/milestones/v1.54-phases/`
- v1.55 shipped and archived 2026-07-03: Phases 201-204
- v1.56 opened 2026-07-03: Phases 205-209 (205-208 committed, 209 scope-gated/optional) — roadmap created, ready to plan Phase 205
- v1.57 opened 2026-07-19 and shipped 2026-07-30: Phases 209-211
- v1.58 opened 2026-07-30: Phases 212-214 — roadmap created, ready to plan Phase 212
- v1.59 activated 2026-07-31: Phases 215-220 — 29/29 requirements mapped; dependency shape 215→216→217→{218,219}→220; ready to plan Phase 215
- Phase 221 added: Close gap: reference-host Apple notification ingress
- Phase 214.1 inserted after Phase 214: Close gap: DOCS-03 — reconcile StripeSync writer documentation (URGENT)
- Phase 214.2 inserted after Phase 214: Close gap: SYNC-02/DOCS-03 — surface advisory entitlement diagnostics (URGENT)

### Decisions

Decisions are logged in PROJECT.md. Recent decisions affecting current work:

- **2026-07-30:** Opened v1.58 "lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync" (Phases 212-214). Reopen class: maintenance / dependency currency plus closing a prior explicitly-deferred capability (SEED-005). Roadmap created with 3 phases, 11/11 requirements mapped, strictly linear deps 212→213→214.
- **2026-07-31:** Activated v1.59 "Account-Scoped Multi-Rail & Offline Entitlements" (Phases 215-220), 29/29 requirements mapped, from sourced adopter signal B2C Alpha. The versioned research bundle supersedes historical 72-hour offline wording: the 30-day revalidation target permits stale downloaded study/progress but blocks value expansion until reconnect.
- **2026-07-30:** Shipped & archived v1.57 "Admin Operator Control Plane (SEED-004 M1)" (Phases 209–211). Milestone audit passed; 11/11 requirements complete; phase trees archived under `.planning/milestones/v1.57-phases/`.
- **2026-07-01:** Closed v1.54 "Admin UI Page-Level Streamlining & Storybook" (Phases 193–200). Audit passed; 23/23 requirements complete; phase trees archived under `.planning/milestones/v1.54-phases/`; no active milestone-specific requirements remain.
- **2026-06-14:** Opened v1.53 "Admin UI Design-System Hardening" (Phases 187–192). Quality / interaction-correctness investment in the already-shipped `accrue_admin` surface; no new billing primitives. Roadmap created with 6 phases, 33/33 requirements mapped.
- **2026-06-11:** Opened v1.52 "Brand System". This explicitly does not open new broad feature scope, but rather invests in adopter-facing brand presentation surfaces (logo, brand book, design tokens, voice/copy). Roadmap created with 7 phases (180–186).
- **2026-06-02:** Closed v1.49 after fresh audit passed 11/11 requirements and archived ROADMAP, REQUIREMENTS, MILESTONE-AUDIT, and phase artifacts under `.planning/milestones/`.
- [Phase 187]: Layer/z-index is an overlay tag, not a thirteenth rubric dimension. — Plan 187-01 preserves the 12-dimension contract and keeps layer failures searchable without double-counting.
- [Phase 187]: Structured baseline and defect artifacts are canonical when markdown disagrees. — Plan 187-01 schemas make baseline.cells.json and defects.ndjson the Phase 192 comparison source of truth.
- [Phase 187]: Phase 187 defects route to owner phases 188, 189, 190, or 191. — Plan 187-01 fixed downstream remediation ownership before manifest and harness work.
- [Phase 187]: Phase 187 matrix identity is manifest-owned; model and raw evidence metadata are advisory. — Plan 187-02 uses the manifest as the source of truth for cell IDs and enrichment.
- [Phase 187]: Targeted breakpoint rows use mode targeted plus numeric viewport_width/breakpoint and targeted_label. — Plan 187-02 rejects legacy targeted-320 mode strings.
- [Phase 187]: Evidence artifacts stay under accrue_admin/test-results with checksums; committed planning artifacts store references only. — Plan 187-02 avoids committing screenshots, traces, or external artifacts.
- [Phase 187]: Static baseline component rows resolve manifest /dev/components to the actual /billing/dev/components route. — The admin dev component kitchen is mounted under the /billing admin scope, and resolving it in the harness keeps component/component-group evidence reachable without changing manifest identity.
- [Phase 187]: Permission-denied forcing stays inside E2E test support. — Plan 187-04 uses an explicit `member` token and `login-member` helper route without changing production admin auth.
- [Phase 187]: Live interaction probes record observations instead of corrected-behavior regressions. — Plan 187-04 writes trace-backed NDJSON rows for current behavior and leaves permanent regression tests to Phase 191 fixes.
- [Phase 189]: D-07 CSS gate: sub-tree .accrue-admin [data-theme='dark'] selector with FULL dark token set is the CSS prerequisite; browser-level color delta verified in Plan 06 themeColumnDeltaProbe
- [Phase 189]: Structural tests (e) and (f) are data-contract-only (no page mount); HTML mount assertions for data-ax-state and data-theme attributes are Plan 03 test (g)
- [Phase ?]: StatusBadge ink tone maps to neutral (not danger) — ax-status-badge-ink removed from Plan 04 danger grouping; ink is catch-all unknown status
- [Phase 190]: Plan 01 uses AccrueAdmin.Dev.ComponentRegistry.group_contracts/0 as the canonical Wave 0 group contract source.
- [Phase 190]: Plan 01 keeps the Playwright Wave 0 harness source-level only until later plans render data-component-group DOM specimens.
- [Phase 190]: Plan 01 records Phase 191 handoff tags in contracts and the ledger without implementing focus, Escape, click-outside, fixture, or microcopy behavior in Wave 0.
- [Phase 190]: 190-02: Component groups render from ComponentRegistry.group_contracts/0 rather than duplicated kitchen data. — Keeps the proof surface coupled to the authoritative registry from 190-01.
- [Phase 190]: 190-02: Drawer proof styling is contained in the kitchen specimen while Phase 191 owns full drawer interaction behavior. — Allows visual proof without expanding this plan into flow interaction work.
- [Phase 190]: 190-02: Mounted coverage uses Floki-scoped group-root assertions so unrelated page text cannot satisfy detail/table proof requirements. — Makes registry proof tests robust against incidental labels elsewhere in the kitchen.
- [Phase 190]: 190-03: DataTable selection controls derive aria labels from row content for contextual row actions. — Improves accessibility while preserving existing LiveComponent selection behavior.
- [Phase 190]: 190-03: AtRiskTable accepts optional amount fields and falls back when existing recovery rows omit money data. — Keeps the new component compatible with current call sites without widening query scope in this plan.
- [Phase 190]: 190-03: Detail sections are unframed while summary headers remain framed. — Avoids card-in-card page rhythm while keeping object identity headers visually grouped.
- [Phase 190-04]: Breadcrumbs remain breadcrumb-only; page-header/actions/breadcrumbs is a composed page-header proof surface. — The Breadcrumbs component owns orientation and current crumb semantics, not the full page-header/action band.
- [Phase 190-04]: DropdownMenu uses native disclosure semantics and does not claim menu/menuitem roles until true menu-button keyboard behavior is implemented. — The component is built on details/summary and Phase 191 owns true menu keyboard behavior if needed.
- [Phase 190-04]: Drawer/modal group contracts define structure, IDs, action order, sizing, scrollable bodies, and layer tokens while Phase 191 owns full trap/restore/dismissal behavior. — This keeps Phase 190 bounded to reusable group structure and tokenized layers.
- [Phase 190]: 190-05: Use grp190 proof roots rather than generic data-component-group selectors because nested reusable components also expose group locators. — Browser and ExUnit probes both found nested component group attributes; proof IDs are the stable root contract.
- [Phase 190]: 190-05: Keep validation pending-baseline-evidence until admin-baseline.spec.js completes. — All other automated gates passed, but baseline hung under bounded retry and cannot support approved validation status.
- [Phase 191]: Phase 191 page-flow inventory derives from baseline-manifest.js, not a second route list.
- [Phase 191]: High-severity owner_phase 191 AX187 rows must be directly cited in the Phase 191 spec; medium rows may be covered by AX187 ID or normalized overlay tag.
- [Phase 191]: Phase 191 matrix route records use static test-only UUIDs so reset plus reseed returns stable detail route IDs. — Plan 191-02 requires deterministic route IDs for page-flow fixtures.
- [Phase 191]: The phase191-matrix endpoint remains in test/support E2E plug routes only; no production router or auth paths changed. — T-191-04 mitigation requires fixture reachability without production forced-state routes or auth bypasses.
- [Phase 191-06]: Phase 191 host fixture rows use the phase191_host namespace, separate from browser-only e2e_phase191 forcing data. — Keeps local click-through seed data distinct from test-only E2E forcing rows.
- [Phase 191-06]: Host seed route IDs are deterministic for binary-id billing rows; append-only event reachability is keyed by idempotency_key. — Binary route records need stable local detail links while event rows preserve append-only semantics.
- [Phase 191-03]: FocusTrap stays package-local instead of adding a third-party focus-management dependency. — Avoids Phase 191 dependency scope while satisfying overlay focus integrity.
- [Phase 191-03]: Step-up modal Escape, outside click, and cancel all dismiss through step_up_dismiss while confirmation remains an explicit submit path. — Preserves the security boundary that destructive confirmation requires an explicit submit.
- [Phase 191-03]: The generated admin JS bundle is committed with the hook registration so served admin assets include FocusTrap. — Generated runtime assets must match app.js hook registration.
- [Phase 191]: Phase 191 focus verification uses data-phase191-focus anchors on shared components instead of brittle page-specific selectors. — Keeps patch-focus verification stable across routes and reusable components.
- [Phase 191]: Admin static JS/CSS bundles are committed with source hook and CSS changes so served admin assets match implementation. — The admin E2E server serves compiled assets, so generated bundles must track hook registration and CSS updates.
- [Phase 191]: Connection state is sourced from LiveView lifecycle events and expressed through a shared shell hook/status region. — Satisfies T-191-08 without adding manually clickable status state.
- [Phase 191]: Page-state and destructive-action copy belongs in AccrueAdmin.Copy modules, not inline LiveView strings. — Plan 191-05 centralizes CPY/PAGE microcopy contracts for reuse and browser verification.
- [Phase 191]: Visible action failures use recoverable resource-specific copy instead of raw inspect(reason). — Mitigates T-191-10 information disclosure while preserving operator recovery guidance.
- [Phase 191]: Browser copy assertions target mounted page-flow DOM states, avoiding auth redirects with unstable empty bodies. — Keeps Phase 191 DOM checks deterministic without changing auth routing in this plan.
- [Phase ?]: data-ax-force=focus detached DOM probe for headless Chromium focus-ring e2e
- [Phase ?]: Production copy fix in subscription.ex preferred over relaxing CPY-02 assertions
- [Phase ?]: Stale webhook test assertions aligned with current copy functions
- [Phase ?]: Three archetype spec guides (SPEC-OVERVIEW/LIST/DETAIL) authored as ExDoc guides with GOV.UK-style machine invariant tables; phoenix_storybook dep added as Plan 04 prerequisite
- [Phase ?]: 21 PAGE_FLOWS surfaces in baseline-manifest.js (not 22 as estimated); 9,072 p193-prefixed page-flow cells generated as additive sibling to baseline.cells.json for Phase 200 zero-regression gate
- [Phase ?]: D-01 portal-primary confirmed
- [Phase ?]: D-01 portal-primary confirmed by D-05 spike: body-level #ax-overlay-root escapes transform ancestors, survives LiveView navigation, hit-testable above scrim (RES-03 Spike A resolved)
- [Phase ?]: Proof 3 gutter-jump delta = 0px without ScrollLock hook — Phase 199 to enforce delta == 0
- [Phase ?]: D-17 spike B: CSS class shim (.psb-sandbox.accrue-admin.ax-theme-dark-shim) chosen over JS hook for Storybook dark-mode
- [Phase ?]: D-17 spike C: inert attribute chosen for background-suppression in overlays; browser floor (Chrome 102+/Firefox 112+/Safari 15.5+) satisfied by target audience
- [Phase ?]: D-17 spike D: Storybook CSS/JS served via AccrueAdmin.Assets committed-bundle route; no Tailwind rebuild required
- [Phase ?]: Code.ensure_loaded?(PhoenixStorybook.Router) mandatory in router wrap — host apps without the dep compile clean in dev and prod
- [Phase ?]: Fix violations before adding guards — Guard A spacing exceptions annotated with ax-spacing-exception comments, Guard B skip-link fixed to :focus-visible, Guard C min-width:0 added
- [Phase ?]: Planted CSS violations in PackageDocsVerifier tests use append+trailing-newline to preserve seeded app.css coverage for earlier guards
- [Phase ?]: Guard D (empty-rail non-interactivity source lint) bans cursor:pointer on .ax-attention-rail--empty; D-08 ExUnit mirror keeps guard and test suite coupled
- [Phase ?]: Phase 194 Plan 04: p193↔p187 scorecard pairing structural no-op — SC3 redefined as e2e:phase194 pass + source guards
- [Phase 195]: Plan 195-01 intentionally remains RED-only; implementation is owned by later Phase 195 plans. — The plan objective is Wave 0 RED validation coverage; later plans green the implementation.
- [Phase 195]: EXE-02 and IXN-01 remain pending after 195-01; this plan addresses them with RED coverage only. — The underlying Subscription detail conversion and full overlay implementation are split across later Phase 195 and Phase 199 plans.
- [Phase 195]: Plan 195-02 intentionally remains RED-only; implementation is owned by later Phase 195 plans. — The plan objective is Wave 0 RED LiveView validation coverage; later plans green the Subscription detail implementation.
- [Phase 195]: EXE-02 and IXN-01 remain pending after 195-02; this plan addresses them with RED coverage only. — The underlying Subscription detail conversion and overlay interaction implementation are split across later Phase 195 and Phase 199 plans.
- [Phase 195-03]: Use pinned LiveView .portal with #ax-overlay-root as the canonical overlay transport for modal/drawer/popover presentations.
- [Phase 195-03]: Keep IXN-01 requirement completion pending for Phase 199; 195-03 ships the prerequisite overlay API/root/wrapper slice.
- [Phase 195]: Phase 195-04: Overlay composes FocusTrap lifecycle and gates ScrollLock to modal/drawer presentations.
- [Phase 195]: Phase 195-04: IXN-01 remains pending for the Phase 199 cross-page overlay sweep; this plan ships the Phase 195 JS prerequisite.
- [Phase 195]: 195-05: Overlay CSS presentation layers use existing --ax-z-drawer, --ax-z-modal, and --ax-z-popover tokens; IXN-01 remains pending for Phase 199 sweep.
- [Phase 195]: 195-05: Drawer CSS is mobile-first bottom sheet below md and right-docked at min(34rem, 92vw) for md+ desktop geometry.
- [Phase 195-06]: Detail.summary_list/1 uses row maps for strings, rendered HTML values, and optional Change/View actions while detail_field_list/1 remains read-only drill UI. — Keeps header row actions separate from drill-section read-only fields for Phase 198 propagation.
- [Phase 195-06]: DropdownMenu.action_menu/1 stays non-modal details/menu UI; drawer and StepUp surfaces remain the overlay/modal boundary. — Matches D-04: action menus are lightweight disclosure menus and must not inherit scroll-lock, inert, or aria-modal behavior.
- [Phase 195-06]: EXE-02 and IXN-01 remain pending after prerequisite primitives; 195-07 owns the page conversion and Phase 199 owns the cross-page overlay sweep. — Prevents a prerequisite primitive plan from closing broader page-conversion and cross-page overlay requirements early.
- [Phase 195]: Subscription detail uses the six-band DETAIL spine with drawer-hosted actions and lazy Activity/JSON. — Plan 195-07 converted SubscriptionLive into the Phase 195 exemplar.
- [Phase 195]: Subscription drawer labels are routed through AccrueAdmin.Copy and exported for anti-drift checks. — Keeps LiveView and browser fixture labels aligned.
- [Phase 195-08]: Storybook coverage is additive and keeps `/dev/components` untouched.
- [Phase 195-08]: Subscription detail action-menu remains non-portaled in Phase 195; Phase 199 owns transformed-ancestor, overflow clipping, and stacking-context audit before any portal exception.
- [Phase 195-08]: Task 4 was verification-only because the final Phase 195 gate passed without additional code changes.
- [Phase 196]: 196-01 kept Wave 0 test-only: no PageHeader/DataTable/Subscriptions runtime behavior was implemented.
- [Phase 196]: 196-01 scoped propagation coverage to Subscriptions; broader LIST rollout remains Phase 197 work.
- [Phase 196]: 196-01 owner-scope clear-all is asserted in LiveView tests with an authorized organization session.
- [Phase 196]: PageHeader composes Breadcrumbs and renders caller-owned description, stat_strip, actions, and filter_toolbar slots without owning list/resource state. — Locks PGH-01 before Subscriptions adoption and Phase 197 propagation.
- [Phase 196]: Storybook coverage stays focused and static for the PageHeader contract; runtime page adoption remains deferred to later Phase 196 plans. — Keeps D-16 and D-17 propagation and Storybook boundaries intact.
- [Phase 196]: 196-03: DataTable keeps backward-compatible derived state defaults while allowing explicit list_state and empty_reason for LIST pages.
- [Phase 196]: 196-03: DataTable.filter_toolbar remains parent-targeted for data_table_filter so PageHeader can host filters without owning state.
- [Phase 196]: 196-03: FilterChipBar renders caller-supplied result counts and clear-all hrefs without mutating URLs.
- [Phase 196]: Phase 196 Plan 04 keeps PageHeader slot-only; SubscriptionsLive and DataTableNav own list state and filter mutation. — Preserves D-02 and D-10 by letting PageHeader host slots without owning list/filter state.
- [Phase 196]: Phase 196 Playwright contract remains scoped to Subscriptions LIST; Phase 197 propagation, overlay flows, portal UI, and Storybook-wide sweeps stay out of scope. — Preserves the 196-05 ownership boundary while proving EXE-03/PGH-01 on the exemplar.
- [Phase 196]: DataTable loading status supports page-specific copy through loading_label while preserving a generic default. — Browser validation required exact Subscriptions loading copy without breaking existing DataTable callers.
- [Phase 197]: Phase 197 Wave 0 remains validation-only: RED contracts define required LIST propagation behavior before runtime migrations. — 197-01 created test/support, ExUnit, and Playwright contracts only; runtime LIST changes are intentionally deferred to later Phase 197 plans.
- [Phase 197]: Phase 197 browser coverage is project-scoped instead of an exhaustive matrix. — Desktop all-page and representative deep checks run on chromium-desktop, while mobile all-page card smoke runs on chromium-mobile.
- [Phase 197-propagate-list]: 197-02 reused AccrueAdmin.ListContracts from 197-01 as the source of RED LiveView contract assertions. — Keeps route, list id, lens, state, and copy expectations aligned across ExUnit and browser validation.
- [Phase 197-propagate-list]: 197-02 remained test-only; runtime LIST propagation is intentionally left RED for follow-up implementation plans. — The plan objective was to lock LiveView contracts before runtime propagation work.
- [Phase 197]: Webhooks replay defaults decode through an allowlisted multi-status status param instead of atom conversion from raw URL text. — Prevents arbitrary existing atoms from URL input while preserving failed/dead replay queue semantics.
- [Phase 197]: Connect Needs attention is a query-owned OR lens; individual readiness filters remain explicit AND filters. — Default queue behavior now matches operator intent without changing explicit filter composition.
- [Phase 197]: Payments owner scope is enforced in Charges.list/1 and count_newer_than/1 through the joined customer owner relation. — Charges already joins Customers for list projection, matching the existing Invoices tenant-boundary pattern.
- [Phase 197]: 197-04: Customers stays all-default while exposing Missing payment method as a quick lens.
- [Phase 197]: 197-04: Coupons and Promotion codes use valid=true/active=true defaults with view=all as the all-records escape hatch.
- [Phase 197]: 197-04: PageHeader owns list filters while DataTable exposes list_status for FilterChipBar counts and chips.
- [Phase ?]: Kept payments backed by AccrueAdmin.Queries.Charges while presenting payment terminology in the LIST UI.
- [Phase ?]: Preserved organization scope through default queue redirects, clear-all links, row links, and summary counts for invoices and payments.
- [Phase 197]: Plan 197-06 keeps Webhooks replay page-local while making status=failed,dead the default Needs replay lens. — Replay selected IDs cross into DLQ.requeue side effects, so scoped selection/detail guards stayed in WebhooksLive instead of being generalized.
- [Phase 197]: Plan 197-06 keeps Events as an all-ledger default and exposes Admin changes via actor_type=admin. — Events is an append-only audit ledger, so bare /events must not manufacture a queue or hide rows.
- [Phase 197]: Plan 197-06 uses Connect needs_attention=true as the OR readiness lens instead of composing readiness filters. — The Plan 03 query seam owns the OR semantics for deauthorized, onboarding, charges, and payouts attention states.
- [Phase 197]: Phase 197 browser smoke waits for LiveView default URL push_patch before asserting queue params. — The final Playwright gate exposed a timing-only failure when URL params were sampled immediately after login.
- [Phase 197]: Phase 197 query contract tests assert filtered inclusion/exclusion instead of singleton global fixture lists. — The focused gate can run after E2E fixtures seed additional valid rows, so tests must prove semantics rather than database exclusivity.
- [Phase 198]: Phase 198 contract uses explicit page target matrices and existing seeded fixtures, not generic runtime abstractions. — This keeps the Wave 0 contract concrete and within the plan boundary that forbids DetailPage and AnalyticsPage abstractions.
- [Phase 198]: Recovery analytics assertions use Phase 198-specific hero, work queue, and supporting funnel markers. — This avoids importing Phase 199 or dashboard zone-order requirements into the Phase 198 browser contract.
- [Phase 198]: Representative drawer and step-up probes are desktop-only while mobile keeps structural route checks. — The contract still covers mobile invariants without forcing desktop drawer behavior into mobile layouts.
- [Phase 198]: Plan 198-02 intentionally ships RED LiveView contract tests only; runtime migrations remain in later Phase 198 plans. — The plan objective was to lock high-risk detail contracts before implementation, and user scope explicitly forbade production migrations.
- [Phase 198]: High-risk action contracts assert intent-opened drawers and StepUp challenge behavior instead of visible initial forms. — Sensitive invoice, charge, webhook, connect, and customer payment-method flows must stay server-owned and challenge fresh identity before execution.
- [Phase 198]: Customer-360 peer navigation is locked to Subscriptions, Invoices, and Payments, with payments and charges URLs resolving to Payments. — D-05 through D-07 remove the broad More bucket and keep Customer peer record sets explicit.
- [Phase 198]: Kept 198-03 test-only: runtime DETAIL and analytics rewrites remain owned by later Phase 198 implementation plans. — This plan is Wave 0 contract coverage; production runtime rewrites are intentionally deferred to later Phase 198 plans.
- [Phase 198]: Documented focused RED verification failures as expected conformance gaps, not setup or fixture failures. — Each focused verification command reached the intended tests and failed only on missing contract markers/docs owned by later implementation work.
- [Phase 198]: 198-04: Kept Customer peer navigation as plain scoped links, not ARIA tabs, because no full tab keyboard component was introduced. — Customer peer record sets remain link/patched subviews and no ARIA tab keyboard implementation was added.
- [Phase 198]: 198-04: Kept Customer payment-method action state page-owned in CustomerLive and revalidated payment-method ids before mutation. — The Phase 198 threat model required server-side validation for payment-method browser events.
- [Phase 198]: 198-04: Used the existing DetailDrawer overlay pattern instead of adding a generic DetailPage or action DSL. — Phase 198 D-01 required existing LiveView composition idioms and no generic DetailPage schema.
- [Phase 198]: Recovery uses Recovery-specific data-ax markers instead of Dashboard data-ax-zone markers. — Plan 198-08 keeps Recovery as a Recovery-specific overview and avoids imposing Dashboard zone grammar on the work queue.
- [Phase 198]: Campaign facts stay page-local in CampaignLive and use existing Dunning analytics calls. — This keeps Campaign as an explicit detail drill-down and preserves cross-package boundary constraints without a generic AnalyticsPage abstraction.
- [Phase 198]: AtRiskTable is documented as Recovery's work queue before the supporting funnel. — The component docs now match the locked overview grammar and prevent the stale below-funnel role from returning.
- [Phase 198]: Plan 198-05 kept invoice and charge action state page-owned in LiveView instead of introducing a generic DetailPage DSL.
- [Phase 198]: Plan 198-05 bound charge refund StepUp challenges to the charge id so the sensitive operation is tied to the money object.
- [Phase 198]: 198-06: Coupon, promotion-code, and event pages remain read-only: no action bands, overflow menus, or mutation events were added. — Preserves reference/ledger semantics and satisfies T-198-22/T-198-24.
- [Phase 198]: 198-06: Raw payloads render only from bottom lazy sections through JsonViewer; EventLive omits the raw marker when event data is empty. — Mitigates raw projection payload exposure per T-198-21 and keeps empty-payload pages quiet.
- [Phase 198]: 198-06: Activity sections are lazy and intentionally empty where these pages have no activity source yet. — Matches the plan requirement to render approved quiet empty-state behavior rather than omit activity markers.
- [Phase 198]: Kept Connect platform fee override and Webhook replay in DetailDrawer flows with server-owned pending action state. — Preserves the plan's intent gating and server-owned action cap for sensitive admin operations.
- [Phase 198]: Required StepUp.require_fresh for both sensitive saves because the plan recorded no lower-risk exception. — Mitigates T-198-25 and T-198-26 without broadening action behavior.
- [Phase 198]: Rendered webhook raw payload only through the lazy Raw payload section while keeping summary/drill state visible. — Mitigates T-198-28 and preserves SPEC-DETAIL first-scan hierarchy.
- [Phase 198-propagate-detail-analytics]: Kept Plan 09 scoped to verification-file changes only; production drawer/focus gaps were documented instead of editing LiveViews or overlay components.
- [Phase 198-propagate-detail-analytics]: Event browser smoke now targets a seeded event with raw payload so the lazy raw-data invariant is tested without contradicting EventLive's no-payload exception.
- [Phase 198-propagate-detail-analytics]: Charge browser StepUp coverage proceeds through a constrained DOM click only when the pointer assertion reports the known offscreen confirm gap.
- [Phase 199]: Phase 199 browser contract uses explicit target arrays for overlay, motion, theme, affordance, fixture, and copy checks — Keeps the Wave 0 browser contract concrete and scoped to test-only scaffolding
- [Phase 199]: Focused Phase 199 browser gate may stay red only for real behavior gaps after setup passes — Later Phase 199 plans are responsible for driving the browser contract green
- [Phase 199]: Plan 199-02 remains test-only; command-palette backdrop close is the single intentional RED JS lifecycle contract for later Phase 199 implementation.
- [Phase 199]: Dropdown Node tests explicitly pin non-modal behavior: no scroll lock, inert state, or aria-modal semantics.
- [Phase 199]: Plan 199-03 remains validation scaffolding; production component, fixture, and copy changes are left to later Phase 199 implementation plans. — The plan objective was to lock ExUnit source contracts before later production changes.
- [Phase 199]: The command palette may either migrate to Overlay or declare explicit overlay-equivalent focus/portal markers; the current source satisfies neither contract. — This keeps the Phase 199 command-palette contract implementation-flexible while exposing the current source gap.
- [Phase 199]: 199-04 kept GlobalSearch as a named overlay-equivalent command-palette wrapper instead of migrating it through Overlay. — The existing CommandPalette hook already owns Escape and focus restoration, and Phase 199 research allowed named wrappers with equivalent markers.
- [Phase 199]: 199-04 routed touched command-palette no-results copy through AccrueAdmin.Copy with safe query escaping. — The Phase 199 UI contract requires touched page-level copy to use the copy SSOT while preserving safe rendering for user query text.
- [Phase 199]: Plan 199-05 kept CommandPalette as the named overlay-equivalent wrapper and made backdrop close hook-owned. — This follows Plan 199-04's named-wrapper decision while avoiding duplicate delegated close handling from LiveView's top-level click listener.
- [Phase 199]: 199-11 added shared Copy.resource_state_copy/3 and hidden action context helpers for CPY-01 list/detail call sites. — Centralizing the messages keeps later Phase 199 list and detail sweeps consistent while allowing deterministic guards to reject generic raw fallback strings.
- [Phase 199]: Plan 199-06: ScrollLock reconciles against live lockable overlay DOM, and FocusTrap uses a topmost-trap stack for nested drawer-to-step-up flows.
- [Phase 199]: Plan 199-07 pairs drawer enter transforms by breakpoint and disables inherited transitions on focus-ring states. — Preserves desktop right-dock and mobile bottom-sheet geometry while making keyboard focus appear immediately outside reduced-motion mode.
- [Phase 199]: 199-12: Use Copy.resource_state_copy/3 at each list LiveView state resolver instead of adding page-specific helper sets. — Centralizes list-state microcopy while keeping each page's state classifier local and explicit.
- [Phase 199]: 199-12: Pass dunning queue copy into AtRiskTable from RecoveryLive so recovery empty-state copy uses the shared Copy surface. — Recovery's queue copy is rendered by a component, so the page must supply Copy-backed text instead of duplicating raw strings inside the component.
- [Phase 199]: 199-13: Detail and campaign source contracts explicitly enumerate named files to close the wildcard checker gap. — The automated wildcard checker could not expand the relevant LiveView glob, so the plan now has an explicit source contract.
- [Phase 199]: 199-13: Existing detail/domain Copy helpers were preserved while shared resource-state helpers were used for empty, error, and page-state copy. — This keeps domain copy stable while proving CPY-01 adoption through the shared helper surface.
- [Phase 199]: 199-13: Read-only Coupon, Promotion Code, and Event detail pages remain action-band-free while their empty and activity copy routes through Copy helpers. — The plan required helper-backed copy without introducing interaction surfaces on read-only reference details.
- [Phase 199]: Kept dropdowns as native non-modal details disclosures and added viewport clamping in the shared dropdown hook instead of introducing overlay portals or modal behavior. — Preserves the Phase 199 non-modal affordance contract while fixing viewport clipping.
- [Phase 199]: Applied horizontal clamping through the existing transform pipeline for floating dropdown panels. — Keeps mobile action-menu animation and final geometry aligned across viewport stress cases.
- [Phase 199]: 199-09: Treat malformed accrue_theme cookies as untrusted input and fall back to localStorage/default theme resolution before CSS loads. — Mitigates T-199-19 and prevents malformed cookies from aborting the anti-FOUC theme boot path.
- [Phase 199]: 199-09: Keep fixed-shell audit coverage source-level and marker-backed in app.css. — The existing overlay architecture already satisfies the browser contract, so source markers cover transform/filter/backdrop-filter/contain/perspective risks without runtime churn.
- [Phase 199]: 199-10: Phase 199 fixture browser checks use a single phase199-interaction-matrix seed with compatibility aliases for existing Phase 199 targets. — Keeps the route-flow stress data deterministic while avoiding duplicate fixture setup across legacy Phase 199 test targets.
- [Phase 199]: 199-10: Overlay and focus assertions wait for settled LiveView cleanup, and staged drawer teardown restores focus to the stable main region. — Browser failures showed focus and overlay cleanup are asynchronous across route patches and staged action drawers.
- [Phase 199]: Summary-list row actions accept action_context, hidden_context, and context aliases for accessible object context. — Plan 199-14 needed repeated action labels to carry object context without changing visible layout.
- [Phase 199]: Phase 199 browser copy checks read generated copy_strings.json for the clear-filter label. — Browser copy assertions should consume the exporter-owned fixture when they depend on allowlisted copy.
- [Phase 199]: 199-15: FocusTrap visibility treats connected focus targets as visible in non-browser lifecycle tests while preserving browser style and rect checks. — The closeout JS lifecycle gate exposed a focus-restore bug in the Node test environment; the runtime bundle was rebuilt with the fix.
- [Phase 200]: 200-01: Keep ComponentRegistry as the single source of truth for generated Storybook metadata through RegistryStory helpers.
- [Phase 200]: 200-01: Serve Storybook committed CSS/JS from dev-only /dev/storybook asset routes because the backend config uses absolute Storybook asset paths.
- [Phase 200]: Storybook browser scans target rendered .psb-sandbox content while asset checks prove committed Storybook CSS/JS delivery. — VER-02 and STY-03 need AccrueAdmin rendered story evidence, not upstream PhoenixStorybook chrome audit results.
- [Phase 200]: Production theme/no-FOUC proof uses accrue_theme cookie/localStorage/system inputs; direct data-theme forcing is isolated to settled axe scans. — The plan prohibits using direct data-theme forcing as persistence proof, so the production test exercises the actual anti-FOUC boot path.
- [Phase 200]: Page-flow evidence seeds Phase 191 route ids alongside Phase 199 interaction fixtures to close p193 cells while preserving guardrail linkage. — The Phase 193 baseline route helper requires Phase 191 route ids; Phase 199 remains referenced for overlay/focus/scroll regression continuity.
- [Phase 200]: 200-03 keeps Phase 200 scorecard outputs under .planning/phases/200-idempotent-verification-sign-off/ and never writes archived Phase 187 or Phase 192 output paths. - Preserves archive immutability while producing derived union and scorecard artifacts.
- [Phase 200]: 200-03 verifier rejects absolute refs, backslashes, .. segments, refs outside allowed generated roots, and unmanifested evidence refs. - This makes artifacts.manifest.json the enforceable evidence boundary for final scorecard packages.
- [Phase 200]: 200-03 p193 rows started as baseline-only placeholders and closed in final artifacts as covered with score >= 2 plus evidence refs.
- [Phase 200]: Plan 200-04 deferred VER-03 final ACCEPT to Plan 200-06; Plan 200-06 recorded the final ACCEPT after explicit maintainer approval.
- [Phase 200]: Phase 200 sign-off REJECT drafts are structurally valid with named repairs; ACCEPT is fail-closed on missing artifacts, non-empty regressions, unresolved judge blockers, and stale p193 rows.
- [Phase 200]: 200-05: Use a dedicated admin-phase200-guardrails CI job for deterministic Phase 200 verification instead of mutating the archived Phase 192 guardrail lane.
- [Phase 200]: 200-05: Run Phase 200 scorecard verification baseline-only until final artifacts exist; full verification runs automatically once Plan 200-06 generates them.
- [Phase 200]: 200-05: Keep CI run lines deterministic and small by routing expensive browser and verifier checks through verify_phase200_admin_guardrails.sh.
- [Phase 200]: 200-06 records final maintainer ACCEPT only after explicit approval, empty regressions, passing scorecard/sign-off verifiers, zero judge blockers, and completed VER-01, VER-02, VER-03, STY-02, and STY-03 rows.
- [Phase 202]: Phase 202 preserves high-value CI gates and requires measurement before topology changes. — The audit found duplicated CI work, but Phase 202 is audit-only; Phase 204 should rank measured implementation slices.
- [Phase 202]: Phase 202 classifies live Stripe as proved only when Stripe test mode runs with required secrets and fixtures. — Skipped provider tests are skipped/not proved, while Fake-backed deterministic tests remain the merge-blocking default.
- [Phase 203]: Keep `billing` as the default Accrue-owned Postgres schema for v1.55 and v1.x. — ADR 203-01 locks the current executable contract and avoids default-rename upgrade risk.
- [Phase 203]: Keep explicit `public` as a supported opt-out, not a deprecated path. — Existing public-schema installs must be able to pin placement before recompiling.
- [Phase 203]: Reject default `accrue` for v1.55. — `billing.accrue_*` is clearer than `accrue.accrue_*`, and a rename is not worth the compatibility burden.
- [Phase 203]: Treat schema-prefix hardening checks as Phase 204 inputs, not shipped Phase 203 behavior. — Phase 204 owns final cross-audit ordering after consuming Phases 201, 202, and 203.
- [Phase 204]: Phase 204 locked the hardening order around public truth, evaluator proof, provider semantics, release safety, CI baseline data, schema guards, package listing trust, host browser setup, release-gate cleanup, and portal readiness.
- [Phase 204]: Phase 204 keeps CI topology, cache, gate, and branch-protection work behind baseline summaries from Phase 202 evidence.
- [Phase 204]: Phase 204 preserves the Phase 203 database contract: default billing prefix, explicit public references, no search_path primary contract, and no schema rename or data movement.
- [Phase ?]: [Phase 205]: slug() reimplemented byte-identically in ratchet/region-tags.js (SDK/manifest-free SSOT); DEDUP-01/02 proven by pure key-free runSelfTest with pinned golden hash
- [Phase ?]: 205-02 design-lens assets: off-register shipped as own-render PNG; bad poles via CSSOM setProperty (nonce-only CSP blocks style tags); fixed 1280px capture avoids downscale/sharp dep
- [Phase 206]: appendResolved/appendVerifiedClosed/appendSuppressed take only finding_id, looking up the latest existing row in the ledger for identity re-derivation; only appendOpen takes the full candidate row. — Plan 206-01 (ratchet-ledger.js) — matches the plan's specified per-helper signatures while still re-validating identity via region-tags.js on every append
- [Phase 206]: appendOpen rejects a non-admissible justification_token via isAdmissibleToken before writing. — Plan 206-01 — Rule 2 auto-fix: the plan required importing isAdmissibleToken but didn't spell out a call site; enforcing it on the new-finding write path closes that gap
- [Phase 206]: 206-02: region-tags.js and ratchet-ledger.js imported via static top-level ESM import (not deferred to GUARD 3) since ratchet-verify.mjs's own --self-test needs synchronous access before any key check; only @anthropic-ai/sdk is dynamically imported behind the key guard.
- [Phase 206]: 206-02: ratchet-verify.mjs is the single writer (D-35) appending 2-of-3-panel-confirmed candidates into the committed findings.ledger.ndjson; medianClamp() is downgrade-only (D-13) and the candidate's own justification_token is independently re-gated via isAdmissibleToken() regardless of panel vote (VERIFY-03).
- [Phase 206]: phase-ratchet-ledger.mjs uses a static ESM import of ratchet-ledger.js (CJS) rather than a dynamic await import() — no SDK-guard ordering constraint exists in this file — 206-02 already proved the static-import interop form works via cjs-module-lexer against the same CJS sibling; simpler and behavior-identical
- [Phase 206]: regenerateBaseline() runs unconditionally on every non-self-test phase-ratchet-ledger.mjs invocation, not gated on regressions being absent — Per D-37, an unfrozen baseline is designed to track current counts on every run so Phase 207's ui.fix re-scoring can recompute it during iteration; only --freeze (Phase 208) makes it sticky
- [Phase ?]: [Phase 206-04] LENS_KEYS and GUARD_HOME_SPECS are duplicated as local constants in verify_ratchet_ledger.mjs (not imported) — genuine independence from the deterministic reducer's own copies of these enums is the whole point of the CI re-verifier.
- [Phase ?]: [Phase 206-04] Added checkJustificationTokensIndependent() (region-tags.js's isAdmissibleToken) as a defense-in-depth re-check beyond the plan's literal action text, since the plan flagged isAdmissibleToken as the one deliberate reuse exception.
- [Phase 207]: Round markers (.round-next/.round-status) live under gitignored test-results/, NOT DEFAULT_PATHS — ephemeral scalar handoffs to the Elixir orchestrator, not gate artifacts (207-01).
- [Phase 207]: The seal-round CLI always exits 0 on success (escalation belongs to the later Elixir ui.round task); only missing/non-numeric RATCHET_ROUND exits 1 and appends nothing, T-207-07 (207-01).
- [Phase 207]: 207-02: Ratchet request builders take systemPreamble/toolSchema as explicit params (not closure) so the mandated key-free --self-test-first guard can call them before SYSTEM_PREAMBLE initializes without a TDZ error; cache_control ephemeral lands on exactly 3 stable-prefix positions (system text block, tools[0], image block) with no field reordering.
- [Phase ?]: 2026-07-05 (207-06): Exported isValidSuppressedReason from ratchet-ledger.js (defined but unexported) so ui.fix apply-decisions validates the whole reject batch up-front — the abort-before-any-apply/zero-partial-apply invariant needs validation decoupled from appendSuppressed.
- [Phase ?]: 2026-07-05 (207-06): ratchet-fix probe verdict policy — objective kinds (contrast/motion) re-measured against their invariant; other kinds trust the maintainer's approved resolution (present=false). ui.fix runs zero evaluator fan-out (D-50), grep-proven.
- [Phase ?]: 209-01: No source/test/CSS touched -- both tasks read-only evidence capture (12/12 green tests + 8-PNG light/dark/desktop/mobile baseline preserved outside git for Plan 03's density-no-regression diff).
- [Phase ?]: COMP-01 resolves inline (D-02) for 209-02: no WorkQueueCallout component file created; Subscriptions composes directly from PageHeader/StatStrip/StatusBadge.
- [Phase ?]: Playwright's default outputDir clearing destroyed Plan 01's pre-reign PNG baseline mid-Task-1; fell back to Plan 01's recorded prose geometry notes as the comparison target instead of pixel diffing.
- [Phase ?]: Added the 6 new Plan-02 Copy.Subscription functions to the export_copy_strings mix task's static allowlist — without this, rebuilding the anti-drift copy_strings.json artifact was a silent no-op.
- [Phase ?]: Removed two coincidentally-passing '$0.00' assertions and one stale duplicate 'Open failed-delivery debugger' assertion from subscriptions_live_test.exs that the plan's literal line-range instructions would have kept, since all three tested content that no longer renders post-reign.
- [Phase ?]: Home reign verdict language reuses Subscriptions' exact literals (Healthy / Action required) for cross-page parity
- [Phase ?]: Added 4 new Home Copy fns to export_copy_strings allowlist so they appear in copy_strings.json
- [Phase ?]: 210-02: Home reigned onto PageHeader spine — single StatusBadge verdict (data-ax-health-verdict) + exposure-first StatStrip, one command-palette customer-lookup, three .ax-card launcher tiles (customer tile removed per D-02a)
- [Phase ?]: 210-02: Launcher tile actions styled secondary so the page keeps exactly one primary cobalt CTA (header); CSS additive-only, retired .ax-launcher*/.ax-attention* rules preserved for Phase 211
- [Phase 210]: 210-03: certified the Home reign — restructured StatStrip linked stat (stretched-link inside <dd>) to satisfy axe definition-list on both Home + Subscriptions; restored attention-rail forced-focus ring under [data-ax-force~=focus]; migrated stale kpi-row/data-table ratchet guards. All named gates green except 2 approved-deferred dark-mode contrast items.
- [Phase ?]: lattice_stripe bumped ~> 1.1 to ~> 2.0 (resolves 2.1.0) across all 4 packages; zero Accrue-side code changes needed
- [Phase ?]: Host lockfile stale hex-mode entries required explicit mix deps.unlock (not just deps.update) to remove — D-05 assumption corrected
- [Phase ?]: Pull and webhook entitlement-summary writes share Accrue.Entitlements.Reconcile so advisory cache ordering has one implementation.
- [Phase ?]: Pull writes use pull_started_at as synced_at and carry forward the greatest real webhook watermark.
- [Phase ?]: Identical pull snapshots short-circuit as :unchanged before DB upsert and do not duplicate the ledger.
- [Phase 213]: Stripe adapter drains the ActiveEntitlement stream through the processor facade and projects only bounded webhook-compatible fields. — Keeps raw LatticeStripe references confined to stripe.ex and preserves the public list callback shape.
- [Phase 213]: RefreshWorker uses the existing accrue_webhooks queue with scalar customer_id args and no scheduler. — Preserves host-owned Oban wiring and keeps advisory refresh off request paths without introducing an always-on poller.
- [Phase ?]: The static entitlement isolation guard rejects executable list_active_entitlements and Reconcile references from gate-path files while allowing explanatory comments and moduledocs.
- [Phase ?]: fetch_entitled/2 is closed and will-not-build; Stripe-native entitlement data remains diagnostic through StripeSync.summary_for_customer/1 and Admin.resolve_for_customer/1, never an authorization predicate.
- [Phase 213]: Callback-omitting adapters return a bounded unsupported_operation APIError instead of a false empty snapshot or UndefinedFunctionError. — Preserves the optional Processor contract while avoiding a misleading successful empty advisory snapshot.
- [Phase 213]: Same-second webhook summaries are ordered by {synced_at, event_id}; the bytewise-greater event id wins. — Makes reducer and database conflict handling converge deterministically independent of arrival order.
- [Phase 213]: Guard joins the always-on entitlement gate-path scan inventory without changing production Guard runtime behavior.
- [Phase 213]: The existing scanner's comment and triple-quoted doc filtering remains unchanged; coverage is strengthened by hermetic Guard fixtures instead of broadening an allowlist.
- [Phase ?]: Current-truth checks are scoped to active public/planning surfaces; dated phase, archive, and seed evidence remains historical.
- [Phase ?]: Stripe-native entitlement sync is optional, default-off, observational diagnostics; local plan-to-feature mapping remains the only Accrue grant authority.
- [Phase ?]: Adoption proof for advisory sync is deterministic docs/isolation verification, not live Stripe merge gating.
- [Phase ?]: Release Please remains the only writer for numbered package changelog sections and package @version values; main carries only Unreleased and hand-authored next-release prose.
- [Phase ?]: Admin and portal changelog entries are compatibility-only; substantive advisory sync capability belongs to the core accrue changelog.
- [Phase ?]: Exactly StripeSync.refresh/2, Processor.list_active_entitlements/2 callback, Processor.list_active_entitlements/2 facade, and Processor.Fake.put_entitlements/2 carry since 1.5.0 metadata.
- [Phase ?]: Linked Release Please candidates require stable equal SemVer and matching package-local numbered sections before release-note verification accepts them.
- [Phase ?]: Verification and UAT default to executable evidence; credentials and irreversible publishing are authorization gates.
- [Phase ?]: Document webhook and client-backed pull refresh as opt-in writers of one advisory row while preserving local plan-to-feature mapping as the sole grant authority.
- [Phase ?]: Phase 214.1 executable correction is green, but only independent v1.58 re-audit can change the historical audit or authorize archive.
- [Phase ?]: Scoped the StripeSync shared-reconciler verifier assertion to public one-way-dependency prose.
- [Phase ?]: Proved public-prose drift through an alias-preserving ROOT_DIR production-verifier fixture.
- [Phase ?]: Advanced only the uniquely attributed DOCS-03 traceability cell after focused verifier and preservation checks passed.
- [Phase ?]: CustomerLive consumes one core diagnostic value; only its local branch controls the Access headline.
- [Phase ?]: Client-backed pull documentation is exhaustive; webhook snapshots remain advisory and may be incomplete.
- [Phase ?]: The existing package-doc verifier and ROOT_DIR fixtures enforce entitlement completeness wording.
- [Phase ?]: Advisory diagnostics use complete normalized maps with independent local and advisory failures.
- [Phase ?]: Provenance derives only from the exact pull stamp or webhook watermark; no freshness inference is emitted.
- [Phase ?]: Stripe observations remain separate from the local access headline; bounded previews retain full Raw data evidence.
- [Phase ?]: Crosswake runtime coupling remains feasibility_blocked until pinned bridge and dated physical-device evidence exist.
- [Phase ?]: Client/device feasibility excludes server/vector/JWS contract-test status; those tests remain independently merge-blocking.
- [Phase ?]: Use v1.59-AUTHORITY.md and an adjacent stable amendment ledger for precedence, dated reassessment, and history-preserving supersession.
- [Phase ?]: Treat normalized monitor/trigger/owner/response watchlist tuples as unique and fail closed when incomplete or duplicate.
- [Phase ?]: Decision cases remain internal data-only structs; renderers and exports do not implement reducer logic.
- [Phase ?]: Generated Markdown and JSON fail closed on byte drift through a bounded Mix task.
- [Phase ?]: Entitlement source capability is a closed, processor-free inspection boundary.
- [Phase ?]: Apple management returns stable external guidance; unavailable control remains a typed error.
- [Phase ?]: Pinned ES256 fixture verification uses OTP and CryptoKit only; no runtime issuer or dependency.
- [Phase ?]: Candidate durability plus atomic rename is the cache visibility boundary for deterministic fault tests.
- [Phase ?]: D-07 validation uses explicit closed vocabularies and a bounded snapshot shape.
- [Phase ?]: The contract consumer remains compiled only from test/support and interprets a caller-supplied canonical case.
- [Phase ?]: Use ordered JSON objects so checked-in decision and golden fixtures are deterministic between VM processes.
- [Phase ?]: Treat the corpus expectation fields as the reader oracle instead of maintaining duplicated observed-result maps.
- [Phase ?]: Reject malformed high-water values and unknown signed dispositions before cache replacement.
- [Phase ?]: Shared coordinators are keyed by standardized cache path, not held globally.
- [Phase ?]: The checked-in capability report remains feasibility_blocked until bridge and device evidence exist.
- [Phase ?]: Decision table renders canonical continuity separately from lease; offline corpus validation rejects complete schema and canonical metadata drift.
- [Phase ?]: Swift test fixtures bind exactly to the generated corpus and decision-case metadata before JWS or cache observation.
- [Phase ?]: Passing Swift contract tests do not establish Crosswake bridge or physical-device feasibility.
- [Phase ?]: Authenticated cache envelopes bind payload, ordering metadata, and standardized path with a caller-supplied HMAC key.
- [Phase ?]: Per-path advisory locks serialize cache restore through durable replacement across processes.
- [Phase ?]: ProofHighWater and authenticated cache replacement share one disposition-aware ordering rule.
- [Phase ?]: Only CapabilityReport schema 1.0 may reduce to proven; unsupported schemas fail closed.
- [Phase ?]: Production AtomicOfflineCache construction and replacement require host authentication plus explicit disposition and revision.
- [Phase ?]: Checked-in capability proof is evaluated relative to its report root and remains blocked without pinned bridge and completed device evidence.
- [Phase ?]: Caller-controlled capability status, evidence kind, and location data is always feasibility_blocked.
- [Phase ?]: Only CheckedInCapabilityReportValidator.validate(reportURL:) may return proven because its URL establishes the evidence root.
- [Phase ?]: Only the validator-owned checked-in capability-report.json URL may reach proven-producing evaluation.
- [Phase ?]: The internal mutation-test validation seam inherits canonical report identity requirements.
- [Phase ?]: Kept :processor as the default Stripe rail alias; Apple remains processor-free.
- [Phase ?]: Reload account after conflict-safe insertion to return the database-authoritative UUID.
- [Phase ?]: Host-fake is controllable only in deterministic test/proof configuration; Stripe remains the sole production gateway rail.
- [Phase ?]: Explicit multi-rail price aliases use full qualified tuples; legacy raw price_ids retain the LocalMap guard.
- [Phase ?]: PostgreSQL partial unique indexes are the authority for qualified observation, grant, and device identity races.
- [Phase ?]: Observation storage is privacy-bounded: normalized metadata and digest only, with paired opaque evidence reference and expiry.
- [Phase ?]: Keep generated hosts on the active legacy Stripe processor example; present concurrent Stripe and Apple registration as an explicitly commented opt-in block.
- [Phase ?]: Use fixed normalized IDs, timestamps, digests, and bounded metadata for persistence fixtures rather than provider payloads.
- [Phase ?]: RAIL-03 persistence hardening normalizes blank provider identities, permits only bounded opaque evidence locators, and binds grant provenance with a composite PostgreSQL foreign key.
- [Phase ?]: Provider identity collisions retain global rail/environment keys but return an opaque ownership error across accounts.
- [Phase ?]: Phase 217 backend verification is zero-human and rejects tracer or human-verify tasks when opted in.
- [Phase ?]: Equivalent source retractions preserve the revision when plan-level authorization bounds remain unchanged.
- [Phase ?]: Snapshot source summaries carry bounded logical_plan provenance so purchase equivalence is exact and cross-plan-safe.
- [Phase ?]: Compatibility multi_rail config dispatches through a fail-closed LocalMap/canonical authority seam.
- [Phase ?]: Existing subscriptions and items resolve adapters from persisted processor provenance; configured processor remains for creation.
- [Phase ?]: Apple management is a successful externally-managed source outcome, never a billing mutation.
- [Phase ?]: Apple lineage claims compare verified account tokens under a PostgreSQL row lock; projector remains the sole grant and revision writer.
- [Phase ?]: Rejected app_store_server_library; Plan 218-03 uses Accrue-owned private verifier fallback with no verifier dependency.
- [Phase ?]: Due checkpoint locks and state transitions, not Oban uniqueness, are the scheduled dispatch authority.
- [Phase ?]: Missing or malformed scheduled-worker configuration persists needs_repair before cancellation.
- [Phase ?]: Required Apple access bounds are validated at both configured admission and lifecycle normalization seams.
- [Phase ?]: Apple JWS x5c stays leaf-first externally and is reversed only for OTP path validation.
- [Phase ?]: Apple signedDate certificate time is selected only per delayed reconciliation JWS; live paths retain current-clock policy.
- [Phase ?]: Apple PKIX checks every configured host-pinned root and manually validates all certificate windows at the resolved policy instant.
- [Phase ?]: Verified unmapped Apple products preserve logical_plan: nil so existing Intake quarantine remains non-granting and reconciliation-local.
- [Phase ?]: Notification application identity is validated only from the authenticated outer data map.
- [Phase ?]: Apple Notifications V2 rejects missing, empty, or malformed raw-body capture with retryable 503 before verification or persistence.
- [Phase ?]: Apple JWS negative tests flip decoded ES256 signature bytes while preserving protected header and payload segments.
- [Phase ?]: Reconciliation locks the local environment-qualified lineage and sends only its original transaction ID to Apple endpoints.
- [Phase ?]: D-09 v1.59 ES256 compact proof profile is published with local stable kid selection.
- [Phase ?]: Offline verification returns bounded four-state decisions and never exposes JOSE/provider details.
- [Phase ?]: Offline JWKS rendering is public-only, deterministic, and retention-aware behind a host key-provider behaviour.
- [Phase ?]: D-01 remains exactly fresh | stale_offline | denied | invalid; reconnect_required is only a next action.
- [Phase ?]: Unknown actions and unsupported fresh actions fail closed with reconnect_required.
- [Phase ?]: Denied and invalid preserve local-progress handling without authorizing entitlement-gated study or value expansion.
- [Phase ?]: Offline registration stores exact public P-256 JWK material and recomputed RFC-7638 thumbprints only.
- [Phase ?]: One-time challenge authority is serialized with PostgreSQL locks; raw nonce and idempotency key are digested before persistence.
- [Phase ?]: Locked issuance uses account/device FOR UPDATE and canonical Snapshot reads.
- [Phase ?]: Unbounded offline proofs retain their verification key indefinitely.
- [Phase ?]: Reference scenarios are strict data-only contracts with closed evidence lanes.
- [Phase ?]: Closed entitlement diagnostics expose only normalized state, bounded ages, and opaque correlation; host authorization resolves the account before the call.
- [Phase ?]: Public support and limit cells are fixture-derived; procedural prose remains outside the generated matrix.
- [Phase ?]: Only deterministic_conformance has merge authority; Crosswake runtime capability remains feasibility_blocked.
- [Phase ?]: Repairs are distinct host-authorized actions with account locks and immutable operation-ID audit records; no generic executor.
- [Phase ?]: Reference host adopts the installer-owned v1.59 entitlement migration sequence before exposing repair controls.
- [Phase ?]: Generated capability facts remain separate from hand-authored release guidance and runbooks.
- [Phase ?]: v1.59 repairs stay host-authorized, bounded, and explicitly exclude financial or ownership mutation.
- [Phase ?]: Composed the release gate from the canonical fixture check instead of duplicating generated exact-fact assertions.
- [Phase ?]: Scoped prose rejection checks to public and procedural regions so runbook prohibition text remains valid.
- [Phase ?]: Fixture operation payloads select bounded production commands but contain no result reducer.
- [Phase ?]: Crosswake remains feasibility_blocked; Swift coverage is client-schema evidence only.
- [Phase ?]: Fixture action kinds select production calls while Projector and Offline remain decision authorities.
- [Phase ?]: Device replacement reuses the existing registration PoP/challenge boundary with database locks and no migration.
- [Phase ?]: device_replace fixtures are synthetic references; production dispatch and durable-state observation remain the authority.
- [Phase ?]: Non-offline reference commands reject offline verification fields; lifecycle collection reads production facts.
- [Phase ?]: D-01/D-06: wrapper-forward—mount AccrueHost.AppleNotificationIngress with Phoenix forward/3; delegate unchanged to Accrue.Entitlements.Apple.NotificationPlug; no Accrue public API expansion.
- [Phase ?]: D-04/D-05: production-only apple-production-v1 Verifier.Config; require six APPLE_* inputs, decode pinned PEM roots to DER at boot, and reuse one immutable config for ingress and reconciliation admission.
- [Phase ?]: D-01/D-06: host wrapper forwards the dedicated Apple route to the unchanged NotificationPlug.
- [Phase ?]: D-04/D-05: one production Verifier.Config term is reused by ingress and reconciliation admission.

### Pending Todos

- **White-label billing portal design system** (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`) — Capture follow-up from CohortFlow `/billing` UAT: make `accrue_portal` white-label friendly, align the demo portal with host brand colors, style the unstyled `/billing/subscriptions` `View details` link, and plan a broader portal UI component/design-system pass.
- **[RESOLVED 2026-06-18 via `/gsd-debug`] Phase-187 `Admin live interaction baseline` e2e times out (>300s).** Root cause was NOT DOM-size/per-node iteration (disproven — selectors resolve in 10–80ms): `probeAffordanceAndStates` called unbounded `await locator.hover()` on a disabled `.ax-button` (Phase 189 added disabled specimens to the kitchen); `.ax-button:disabled` has `pointer-events: none` (app.css:1332), so Playwright's hover actionability check never resolves and inherits the 180s test budget — ×2 serial projects → >300s. Fix: bound `hover()`/`focus()` with `{ timeout: 1_000 }` in `accrue_admin/e2e/admin-interactions.spec.js`. Re-verified: 2 passed (25.7s) both projects. Session: `.planning/debug/resolved/phase-187-baseline-timeout.md`.
- **[RESOLVED 2026-06-18 via `/gsd-quick` 260618-3pu] Component-lab family headers used `String.upcase(family)`** (rendered "BUTTON"/"FORM-FIELD"). Replaced with a `family_label/1` map in `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` covering all 16 `applicable_states` families with the approved Phase-189 UI-SPEC `####` copywriting labels + a humanizing catch-all for future families. `189-UI-REVIEW.md` WARNING discharged.

### Blockers/Concerns

- (Resolved/obsolete: the 190-05 `admin-baseline.spec.js` hang note was cleared 2026-06-21 — Phase 190 and the full v1.53 milestone subsequently shipped & verified, so the bounded-retry concern no longer applies.)
- Phase 196 final full-suite gate: cd accrue_admin && mix test --warnings-as-errors fails outside Phase 196 in dashboard_live_test.exs:91 (missing $42.50) and webhooks_live_test.exs:106 (audit count expected 1, observed 2). Focused Phase 196 tests, package docs, assets, and e2e:phase196 pass.
- Phase 208 Plan 04 blocked at Task 1: ANTHROPIC_API_KEY is absent from the execution environment; ledger.baseline.json remains frozen:false and live convergence/freeze must not proceed without maintainer local key.

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260731-n4f | Automate Phase 214.2 integration and E2E verification with zero human UAT | 2026-07-31 | cda60887, d2ee7a42 | Verified | [260731-n4f-automate-phase-214-2-integration-and-e2e](./quick/260731-n4f-automate-phase-214-2-integration-and-e2e/) |
| 260618-3pu | Component-lab family-label map (replace `String.upcase(family)` with UI-SPEC labels) | 2026-06-18 | b5cf3527 |  | [260618-3pu-component-lab-family-label-map](./quick/260618-3pu-component-lab-family-label-map/) |
| 260620-gmv | Green main CI — format test file + harden CMP-05 xargs guards (GNU-vs-BSD portability) | 2026-06-20 | 0ce75413 |  | [260620-gmv-fix-ci-format-xargs](./quick/260620-gmv-fix-ci-format-xargs/) |
| 260620-lie | Fix host login 500 — validate stale `active_organization_id` against live memberships before session insert (FK crash) | 2026-06-20 | 69867bb9 |  | [260620-lie-fix-stale-active-org-login](./quick/260620-lie-fix-stale-active-org-login/) |
| 260620-luy | Use the real Accrue brand mark in admin chrome (sidebar + favicon), theme-aware; white-label `logo_url` still overrides | 2026-06-20 | d307f091 |  | [260620-luy-admin-brand-mark](./quick/260620-luy-admin-brand-mark/) |
| 260620-mfh | Host dev DX — hot-reload sibling Accrue libs (`reloadable_apps` + live_reload `dirs`/patterns), no `restart web`; CSS still needs `assets.build` | 2026-06-20 | 60920f46 |  | [260620-mfh-host-sibling-hot-reload](./quick/260620-mfh-host-sibling-hot-reload/) |
| 260620-mn0 | Admin sidebar — render combined Accrue logo lockup (one theme-aware SVG), drop duplicated `app_name`/`Accrue Admin` brand text | 2026-06-20 | 54163ace |  | [260620-mn0-admin-sidebar-logo-lockup](./quick/260620-mn0-admin-sidebar-logo-lockup/) |
| 260620-n4q | Redesign theme picker as on-brand segmented control (icon+text, radiogroup+arrow-keys); extract `ThemePicker` component + register in component lab | 2026-06-20 | ec45880e |  | [260620-n4q-theme-picker-segmented](./quick/260620-n4q-theme-picker-segmented/) |
| 260620-ps2 | Elevate Timeline into a proper on-brand timeline — continuous vertical rail + threaded-feed entries (borderless, hover surface), reuse `StatusBadge` (tone passthrough), `<time>` tabular figures, dedicated empty state; register `timeline` family in component lab | 2026-06-20 | f6cda082 |  | [260620-ps2-elevate-the-timeline-component-into-a-pr](./quick/260620-ps2-elevate-the-timeline-component-into-a-pr/) |
| 260621-h72 | Webhooks DLQ page — design-system tightening + selection-driven retry | 2026-06-21 | 745462ec |  | [260621-h72-webhooks-dlq-design-system-tightening-an](./quick/260621-h72-webhooks-dlq-design-system-tightening-an/) |
| 260622-nob | Finish host Playwright e2e CI green-up (spec-drift realigns + stale committed copy_strings.json regen) | 2026-06-22 | 0a2f25ba |  | [260622-nob-fix-two-host-playwright-e2e-spec-drift-a](./quick/260622-nob-fix-two-host-playwright-e2e-spec-drift-a/) |
| 260621-idn | Fix `/billing/events` crash (`FunctionClauseError` in `Cursor.encode/2`) — widen cursor to integer PKs + 3 regression specs | 2026-06-21 | 4a937532 |  | [260621-idn-fix-admin-events-cursor-crash-integer-pk](./quick/260621-idn-fix-admin-events-cursor-crash-integer-pk/) |
| 260621-io6 | Shared DataTable UX + customers redesign (infinite scroll, SPA filters, click-to-copy IdBadge) | 2026-06-21 | 12e64d57 |  | [260621-io6-shared-datatable-infinite-scroll-spa-fil](./quick/260621-io6-shared-datatable-infinite-scroll-spa-fil/) |
| 260621-knk | Realistic fictional-SaaS demo seed data (data-only `examples/accrue_host`, idempotent) | 2026-06-21 | fdb6daee |  | [260621-knk-realistic-fictional-saas-demo-seed-data-](./quick/260621-knk-realistic-fictional-saas-demo-seed-data-/) |
| 260621-lzc | Repair host e2e test `admin_webhook_replay_test.exs` orphaned by 260621-h72 (security property preserved) | 2026-06-21 | 42b75764 |  | [260621-lzc-repair-host-admin-webhook-replay-test-to](./quick/260621-lzc-repair-host-admin-webhook-replay-test-to/) |
| 260621-mr6 | Admin webhooks DataTable polish — truthful filtered-empty state, spacing, mobile-first filter grid, native checkboxes | 2026-06-21 | 9aa35ced |  | [260621-mr6-webhooks-datatable-polish](./quick/260621-mr6-webhooks-datatable-polish/) |
| 260621-nr8 | Admin nav — live navigation + visible loading stripe + remove sidebar collapse | 2026-06-21 | 76ea8393 |  | [260621-nr8-admin-nav-live-nav-no-collapse](./quick/260621-nr8-admin-nav-live-nav-no-collapse/) |
| 260621-olr | Admin list pages — compact stat strip + condensed instant-apply filter toolbar across all 9 list pages | 2026-06-21 | d127a7e0 |  | [260621-olr-list-page-stat-strip-filter-toolbar](./quick/260621-olr-list-page-stat-strip-filter-toolbar/) |
| 260622-fql | Admin page headers — one consistent JTBD-oriented voice across every section | 2026-06-22 | 68fb8bc5 |  | [260622-fql-admin-header-microcopy-voice](./quick/260622-fql-admin-header-microcopy-voice/) |
| 260622-h7h | Green the package-docs CI gate — app.css doc-contract violations (DSY-01 media annotation + FND-01/02 fixes) | 2026-06-22 | 60fb1c06 |  | [260622-h7h-dsy01-theme-picker-media-annotation](./quick/260622-h7h-dsy01-theme-picker-media-annotation/) |
| 260622-i2c | Green the accrue_admin Playwright browser UAT — 8 spec-drift realigns + 1 responsive `.ax-kpi-delta` fix | 2026-06-22 | 90952f5f |  | [260622-i2c-admin-uat-green-up](./quick/260622-i2c-admin-uat-green-up/) |
| 260704-i4p | Seed admin-UI blueprint redesign as post-v1.56 program — synthesis doc + SEED-004 + ROADMAP row (docs-only, no milestone opened) | 2026-07-04 | a7ae001c |  | [260704-i4p-admin-ui-blueprint-redesign-seed](./quick/260704-i4p-admin-ui-blueprint-redesign-seed/) |
| 260718-g6b | Click-to-copy demo credentials on host login page — email + per-card password chips, daisyUI toast, zero reflow (Playwright 10/10) | 2026-07-18 | b4407552 |  | [260718-g6b-login-copy-credentials](./quick/260718-g6b-login-copy-credentials/) |
| 260718-i32 | One-click "Enter workspace" + persistent "Switch account" nav dropdown — real pre-filled Sigra login w/ safe return_to, lands in persona billing view (Playwright 8/8) | 2026-07-18 | 228591f5 |  | [260718-i32-one-click-jump-into-account-persistent-d](./quick/260718-i32-one-click-jump-into-account-persistent-d/) |
| 260718-iwa | Remove automatic-tax friction + "Record learner activity" button from /app/billing demo; uncovered pre-existing Fake sequential-ID collision (seeds run in separate node) crashing subscribe → follow-up to fix | 2026-07-18 | a4661ee1 |  | [260718-iwa-billing-remove-tax-and-usage-button](./quick/260718-iwa-billing-remove-tax-and-usage-button/) |
| 260718-jmi | Boot-time Fake↔DB rehydration (new core `Fake.load_fixtures/1` seam + host boot hook) + swap-route plan changes; fixes /app/billing subscribe/change/cancel for seeded personas (Playwright 7/7, unit 23/0 + 5/0) | 2026-07-18 | ffdad355, c23a6656 |  | [260718-jmi-fake-db-consistency-boot-hydration](./quick/260718-jmi-fake-db-consistency-boot-hydration/) |
| 260718-kf9 | Put "Scale Customer" persona on the real Scale plan (price_metered) instead of orphan price_premium + move :advanced_reports entitlement with it; /app/billing now labels+highlights the plan (Playwright, unit 3/0) | 2026-07-18 | 1ba06cba |  | [260718-kf9-scale-persona-real-plan](./quick/260718-kf9-scale-persona-real-plan/) |
| 260718-osx | Polish + Cadence-brand the `accrue_portal` customer portal (`/billing`) — built the plumbed-but-unrendered host-brand bridge (nonce'd `:root` override from `@brand`, additive `--accrue-brand-*`/surface tokens in core `brand.css`, `:font_stack` through BrandPlug, `.portal-topbar` chrome) + token-driven CSS polish (killed hardcoded `#2f6e58`/gradient, type scale, hover/`:focus-visible`, status pills) across all 7 portal pages; neutral-Accrue fallback preserved (portal compile clean, tests 36/0) | 2026-07-18 | ca5dd2f7, 690e03f2, 5f221975 |  | [260718-osx-portal-billing-cadence-polish](./quick/260718-osx-portal-billing-cadence-polish/) |
| 260718-qni | Add a short JTBD subtitle to each persona in the nav "Switch account" dropdown — new `:jtbd` field in `DemoBrand` + two-line dropdown item (label + workspace tag, JTBD line) so picking a persona reads as choosing a scenario (compile clean, login_test 2/0) | 2026-07-18 | ae940cb1 |  | [260718-qni-add-short-jtbd-line-to-each-persona-in-t](./quick/260718-qni-add-short-jtbd-line-to-each-persona-in-t/) |
| 260718-s1y | Real light/dark/system theming for the `accrue_portal` customer portal — three-state `[data-theme]` model in core `brand.css` (was OS-only `prefers-color-scheme`), `--accrue-brand-accent-text` + derived `-strong` so a single host accent stays legible in both modes, an idiomatic 3-way topbar picker (monitor/sun/moon, SSR-active, `accrue_theme` cookie persist, CSP-safe delegated JS). Library-only (compile clean, portal tests 36/0). DEFERRED: single-mode config API, admin config surface, admin re-skin→SEED-004, dunning banner | 2026-07-18 | 3a7284f4, ba6a715c |  | [260718-s1y-portal-light-dark-system-theming-picker-](./quick/260718-s1y-portal-light-dark-system-theming-picker-/) |
| 260718-s9z | Style the `/app/billing` dunning banner to match Cadence — host `Layouts.app/1` now passes a Cadence-styled slot (utility-composed amber warning card: hero-exclamation-triangle + title + detail) to the headless `AccrueAdmin.Components.DunningBanner` instead of falling through to its unstyled `ax-banner` default, and moved it inside the `max-w-6xl` column so it aligns with the cards. Host-only, gate/component untouched (compile clean) | 2026-07-18 | e76ad7e1 |  | [260718-s9z-style-the-app-billing-dunning-banner-to-](./quick/260718-s9z-style-the-app-billing-dunning-banner-to-/) |
| 260718-sic | Adopter portal theme opt-out — new published `:branding` option `theme: :system\|:light\|:dark`. `:system` (default) keeps the cookie-driven 3-way picker; `:light`/`:dark` force that mode server-side (cookie ignored) + hide the picker. Effective-theme + `locked` computed in `BrandPlug`, threaded via router `__session__` + `AuthHook` socket, gates the layout picker (`:if={not @theme_locked}`); `:system` path now also sanitizes the raw `accrue_theme` cookie before `data-theme`. Library-only, additive/non-breaking (accrue config 21/0, accrue_portal 37/0). Deferred remaining: admin theme/brand settings surface, admin re-skin→SEED-004 | 2026-07-18 | c1d8ba2e, 228fceb1 |  | [260718-sic-adopter-portal-theme-opt-out-branding-th](./quick/260718-sic-adopter-portal-theme-opt-out-branding-th/) |
| 260718-t4g | Portal return-navigation + dunning-banner CTA. PART A (`accrue_portal`, library): idiomatic "way back" — clickable brand→home in the persistent topbar + a shared `AccruePortal.Layouts.breadcrumb/1` component (called fully-qualified) inserted as first child of `.portal-shell` on the 5 sub-pages (subscriptions/subscription-detail/payment-methods/add-card/invoices; NOT home or checkout); `:base_path` assigned globally in `AuthHook.mount_customer`; new `Copy.breadcrumb_home` ("Account"); token-driven `.portal-breadcrumb*`/`.portal-brand-link` CSS (recompile re-hashes); a11y (`nav[aria-label=Breadcrumb]`, `<ol>`, `aria-current`, focus rings). PART B (`examples/accrue_host`, demo-only): the styled `/app/billing` dunning banner now carries a "Update payment method" CTA → `/billing/payment-methods` (surfaces the portal). Library+demo, no core change (accrue_portal 37/0 incl. 2 new breadcrumb assertions, host compile clean) | 2026-07-19 | ad1cccde, 80ee1c5c |  | [260718-t4g-portal-nav-breadcrumbs-dunning-cta](./quick/260718-t4g-portal-nav-breadcrumbs-dunning-cta/) |
| 260718-u1s | `accrue_admin` foundation token corrections (Phase 1 of the admin re-skin gameplan — keep Cobalt, fix polish). Three deterministic `--ax-*` fixes in `theme.css`/`app.css`: (1) **light-mode contrast pass** — raised faint `--ax-border` `rgba(36,48,59,.12)`→`.2` + `-strong`→`.32`, verified surface layering + `--ax-muted` ≥4.5:1, no invisible status borders (light was washed-out/borderless; dark got its contrast pass in v1.53, light hadn't); (2) **de-hardcode stray cobalt literals** — `--ax-accent-readable`/`--ax-focus-ring`/`--ax-focus-shadow` (light `#174ea6`/rgba(93,121,246); dark `#9bb5ff`/rgba(155,181,255)) + sidebar `.ax-sidebar-link-active` dark pins (`#1f283d`→12% `color-mix` renders exact at cobalt; `#f4f7fa`→`var(--ax-primary)`) now derive from `--ax-accent`, so a swapped admin accent follows (were pinned blue); (3) **single-source dark set** — triplicated dark `--ax-*` (3 selectors) collapsed to the CSS-minimum 2 rule bodies (system stays media-gated), dark rendering byte-identical for non-accent tokens. Cobalt kept as ratified interaction accent (Moss=success only); NO palette change, NO component restyle. Source-only + committed bundle rebuild; live-verified served bundle (md5 `8fcc2c5b`) carries new borders/mixes, 0 stray cobalt literals. accrue_admin compile clean, ratchet ledger+verify self-tests 0. Parked (needs maintainer `ANTHROPIC_API_KEY`): v1.56 Phase 208-04/05 live ratchet convergence + freeze + ACCEPT, then component de-garish pass | 2026-07-19 | 2c6da192, 89410264, 42e2be0b, 8dbad259 |  | [260718-u1s-accrue-admin-foundation-token-corrections](./quick/260718-u1s-accrue-admin-foundation-token-corrections/) |
| 260719-ey5 | `accrue_admin` component de-garish + density polish (Phase 2 of the re-skin gameplan — keep Cobalt, calm saturation). VISUAL polish, token/class-level, NO IA/layout/copy (IA→SEED-004), NO palette change. De-saturated the genuinely-garish status treatments to the brand's tinted-surface + border + strong-hue-on-text pattern: **the solid red `.ax-home-header-health` "Billing status: Unhealthy" headline bar** (`--ax-status-danger-solid` fill→`color-mix(danger-bg 45%, elevated)` tint, border 2px→1px, white text→`--ax-status-danger-text`/`--ax-primary`, +padding) — the biggest eyesore; the solid amber header health chip `.ax-home-health-status`; `.ax-button-primary` DARK fill softened via `color-mix(--ax-accent 62%, --ax-elevated)` (light untouched, white text AA); `.ax-home-customer-search-strip` blue band 76%→35%; `.ax-attention-summary-warning` verdict tint 66%→40%. Density: `.ax-banner` vertical padding md→sm. Deliberately LEFT already-calm treatments (attention-row, priority pills/dots, health-summary tints, solid warning/recovery on BUTTON CTAs, already-tight table td/related/detail). VISUALLY VERIFIED by orchestrator via Playwright PNG re-capture (dashboard+subscriptions, light+dark) — both themes now read calm/coherent/legible AA, dramatic improvement over the washed-out+garish originals. accrue_admin compile+build clean, bundle committed. Cobalt + all hues preserved. **SWEEP follow-ups** (same task, PNG-verified across dashboard/subscriptions/subscription-detail/customer-detail): fixed the detail-page twin of the red bar (`.ax-detail-health-summary-danger`/`-slate` solid→tinted, matching the already-tinted `-moss` sibling) + `.ax-dev-health-snapshot` solid→tinted; fixed a layout-breaking long-name overflow (`.ax-inline-worklist-copy`/`strong` → `min-width:0` + `overflow-wrap:anywhere`, names WRAP not stretch). Only solid `--ax-status-*-solid` fills remaining are button CTAs (correct). NOTE: deeper "why is this ugly" drivers (redundant stacked bands restating the same job, too many competing filled-primary buttons) are IA = SEED-004, NOT CSS — flagged to user, not faked with styling | 2026-07-19 | f8c528cc, 341fafba, b775b121, 0b0adc75, 47dd0906, 6e5e53a3, c2f2d6d4 |  | [260719-ey5-accrue-admin-component-polish-density-satura](./quick/260719-ey5-accrue-admin-component-polish-density-satura/) |
| 260719-fz6 | `accrue_admin` **console-card grammar** normalization (Phase 2b — Home + Subscriptions read "accidental/weird borders/spacing" while **Customers looks good** = user's reference). Root cause: good pages inherit base `.ax-card` grammar (`radius-lg`, `space-lg` pad, plain surface) but Home zones + the `.ax-inline-worklist` strip base had DRIFTED into ad-hoc per-zone values (3–6px/0 padding, `radius-sm`, 1–3px gaps, accent border+tint on many competing zones, bordered-boxes-in-bordered-boxes). Defined ONE **console-card grammar** (`--ax-radius-md`, space-token padding `sm`/`md`, one section rhythm `--ax-space-md`, plain `1px --ax-border`, **at most one accent zone**, **de-nest** boxes-in-boxes) — calibrated to KEEP console density (NOT airy Customers 24px). Home (Task 1, `22deb9d7`): normalized `.ax-home*`/`.ax-launcher*`/`.ax-attention*`; neutralized customer-search strip; de-nested `.ax-attention-summary` (box→bottom-divider); single accent = primary launcher. Subscriptions (Task 2, `a3b582e0`): the win = neutralizing the `.ax-inline-worklist` base (was accent-border+tint by default → why every band differed); de-nested record sub-cards + the table Signals/audit column (per-box borders → borderless fields w/ status left-accent bars + spacing). PNG-VERIFIED by orchestrator (dashboard+subscriptions, light+dark) vs Customers ref — both now read as one intentional system, still dense. CSS-only, Cobalt+hues kept, NO IA/copy change (redundant-bands/competing-primaries stay SEED-004). compile+build clean | 2026-07-19 | 22deb9d7, a3b582e0 |  | [260719-fz6-admin-home-subscriptions-card-grammar](./quick/260719-fz6-admin-home-subscriptions-card-grammar/) |

| 260719-ix8 | Architecture + code walkthrough HexDocs, secure theme-aware Mermaid, and adaptive Accrue docs branding | 2026-07-19 | 677b2b58, 65ab4b50, 825ffeb9 | Verified | [260719-ix8-author-architecture-and-code-walkthrough](./quick/260719-ix8-author-architecture-and-code-walkthrough/) |
| 260729-rjo | Deterministic Playwright `toHaveScreenshot` visual-regression CI gate to retire Phase 211's two human-only visual UAT checkpoints (211-02 D4, 211-04 D5). Part A (implementation) on branch `visual-regression-gate-phase211`: `toHaveScreenshot` tolerance config + committed `snapshotPathTemplate`, exact-pin `@playwright/test@1.59.1`, shared `e2e/support/admin-visual-helpers.js`, new `admin-visual-regression-phase211.spec.js` (4 surfaces × light/dark, per-surface datetime masks) isolated in its own `visual-desktop` Playwright project so the default `npm run e2e` stays green pre-baseline, `e2e:visual-regression` script, baseline-presence-guarded blocking gate + `pull_request` `visual-baselines-mint` job in `accrue_admin_browser.yml`. No `accrue/lib`, no nav. **PENDING (orchestrator): CI mint Linux baselines → commit under `e2e/__screenshots__/visual-desktop/` → gate flips blocking+green → merge → Part B (flip D4/D5 coverage, `211-VALIDATION.md`, re-run `/gsd-verify-work 211`).** | 2026-07-29 | 9186ca3f, b36881e6, 2967c917, b9129b88 | Part A ✓ — CI baselines pending | [260729-rjo-add-a-deterministic-playwright-visual-re](./quick/260729-rjo-add-a-deterministic-playwright-visual-re/) |

### Milestone Intake Rules

- Default to maintenance/release-readiness unless new work has a sourced adopter, correctness, security, operational, or strategic reason.
- Do not create a milestone for polish-only work with a documented workaround.
- Any processor-surface change must update runtime behavior, support matrix, docs, examples/verifiers, and release notes together.

## Deferred Items

### Recorded at v1.58 milestone close (2026-07-31)

The milestone audit classified these as non-blocking technical debt; none breaks a requirement, end-to-end flow, or the local-map-only grant boundary:

| Category | Item | Status |
|----------|------|--------|
| processor | Advertise the implemented Stripe-native callback through capability discovery | deferred |
| sync | Reject non-Stripe customer rows before Stripe-native processor I/O | deferred |
| worker | Cancel malformed refresh-worker arguments deterministically | deferred |
| integration | Document or intentionally add a production enqueue policy for the host-owned worker | deferred |
| validation | Promote Phase 214.2 `VALIDATION.md` from `ready` to authoritative `validated` | deferred |

### Acknowledged at v1.57 milestone close (2026-07-30)

1 open artifact acknowledged and deferred at milestone close (`override_closeout`). Its substance was absorbed into the Phase 210 Home reign — an unclosed tracking stub, not outstanding v1.57 scope (the milestone audit flagged it in the same stale-quick_tasks tech-debt bucket):

| Category | Item | Status |
|----------|------|--------|
| quick_task | 260719-fz6-admin-home-border-spacing-grammar | missing (pre-v1.57 de-garish/card-grammar polish; work shipped under Phase 210 Home reign) |

### Acknowledged at v1.53 milestone close (2026-06-20)

9 open artifacts acknowledged and deferred at milestone close — all carryover from earlier milestones or future-roadmap work, none v1.53-scoped:

| Category | Item | Status |
|----------|------|--------|
| quick_task | admin-shared-detail-components (20260602) | missing (v1.50-era; superseded by shipped shared detail components) |
| quick_task | 260413-jri-bump-lattice-stripe-to-1-0-and-unblock-p | unknown (historical) |
| quick_task | 260414-l9q-automate-phase-3-human-verification-item | unknown (historical) |
| quick_task | 260602-6xv-seamless-multi-project-docker-dx-for-exa | unknown (v1.49/v1.50 Docker DX; shipped) |
| quick_task | 260604-tjz-docker-dx-for-accrue-host-admin-ui-ephem | unknown (Docker DX; shipped) |
| quick_task | 260605-dkx-docker-native-boot-shared-traefik-proxy | unknown (Docker DX; shipped, committed main 260605-dkx) |
| quick_task | 260605-gys-add-dedicated-admin-example-com-billing- | unknown (historical) |
| todo | 2026-06-19-brandbook-use-accrue-favicon.md | pending (brandbook follow-up) |
| todo | 2026-06-19-white-label-billing-portal-design-system.md | pending (future portal design-system pass) |

### Acknowledged at v1.54 milestone close (2026-07-01)

10 open artifacts acknowledged and deferred at milestone close. These are historical carryover or future-roadmap items; none blocked v1.54 closeout.

| Category | Item | Status |
|----------|------|--------|
| quick_task | admin-shared-detail-components (20260602) | missing (historical; shared detail/PageHeader work has shipped in later admin milestones) |
| quick_task | 260413-jri-bump-lattice-stripe-to-1-0-and-unblock-p | unknown (historical) |
| quick_task | 260414-l9q-automate-phase-3-human-verification-item | unknown (historical) |
| quick_task | 260602-6xv-seamless-multi-project-docker-dx-for-exa | unknown (v1.49/v1.50 Docker DX carryover; shipped) |
| quick_task | 260604-tjz-docker-dx-for-accrue-host-admin-ui-ephem | unknown (Docker DX carryover; shipped) |
| quick_task | 260605-dkx-docker-native-boot-shared-traefik-proxy | unknown (Docker DX carryover; shipped) |
| quick_task | 260605-gys-add-dedicated-admin-example-com-billing- | unknown (historical) |
| todo | 2026-06-19-brandbook-use-accrue-favicon.md | pending (brandbook follow-up) |
| todo | 2026-06-19-white-label-billing-portal-design-system.md | pending (future portal design-system pass) |
| todo | 2026-06-21-shared-page-header-component-for-accrue-admin.md | pending artifact; PageHeader shipped in v1.54, todo left for manual cleanup |

### v1.54 tooling note (recorded at milestone open 2026-06-24)

| Category | Item | Status | Note |
|----------|------|--------|------|
| tooling | TOOL-01 — adopt PhoenixStorybook | **adopted (v1.54)** | v1.53 extended the in-app `/dev/components` kitchen and deferred TOOL-01; v1.54 reverses that deferral — `phoenix_storybook` `only: [:dev, :test]` (STY-01..03). Kitchen stays as a second renderer (registry SSOT) backing Phase-189/190 drift tests. |
| tooling | TOOL-02 — pixel-diff visual-regression (Percy/Applitools) | deferred (continued) | Scored-cell forward-only gate over real composed routes is the mechanism; pixel-diff would flag every intentional v1.54 improvement as a regression. |
| tooling | TOOL-03 — publish `brandbook/tokens/tokens.css` as npm/CDN distributable | deferred | Not needed for the admin streamlining pass. |

### Resolved CI hygiene issue — nightly live-stripe canary no-secret path (resolved 2026-07-03)

The scheduled `live-stripe` job (`.github/workflows/ci.yml`, "Stripe test-mode parity (mandatory periodic)", 06:00 UTC cron + manual dispatch) previously failed when Stripe secrets were absent. **Not merge-blocking** — it never runs on push/PR, but it kept the dashboard red.

- **Root cause:** missing GitHub secrets appear as blank environment variables. `runtime.exs` and the `:live_stripe` test modules treated blank values as present, which selected the Stripe processor with an empty `:stripe_secret_key` before skip tags could protect the suite.
- **Resolution:** blank `STRIPE_TEST_SECRET_KEY`, `ACCRUE_LIVE_BASIC_PRICE`, and `ACCRUE_LIVE_PRO_PRICE` values are now treated the same as missing values. `mix test.live` skips cleanly without secrets.
- **revisit_trigger:** before relying on live Stripe API-drift detection, configure the repository secrets with a real Stripe test-mode key and matching price fixtures, then confirm a workflow-dispatch run executes the suite instead of skipping.

### Standing scope deferrals

| Category | Item | Status | Reason | Future owner/category | revisit_trigger | Deferred At |
|----------|------|--------|--------|-----------------------|-----------------|-------------|
| scope | Rich metered/tiered/range entitlement math (beyond seat counts) | out of scope v1.39 | Current entitlement support intentionally covers local plan and seat-style quantities without a sourced adopter contract for richer math. | Entitlements extension | concrete adopter failure or explicit adopter contract requiring richer entitlement math | 2026-05-22 |
| scope | Atomic seat enforcement / membership management | host-owned; documented recipe, not core API | Membership ownership remains app-specific and Accrue does not own host user/team schemas. | Host integration recipe | concrete adopter failure showing documented host-owned enforcement is insufficient | 2026-05-22 |
| scope | Typed upstream Stripe Entitlements resources + live API reads | shipped observationally in v1.58 Phase 213 | `lattice_stripe` 2.x now supplies the typed advisory read; it remains isolated from the canonical grant gate. | Stripe advisory overlay | closed; do not repurpose `EntitlementSummary` for v1.59 canonical grants | 2026-05-22 |
| scope | Multi-channel (SMS/push) dunning via Chimeway | out of scope v1.45; deferred | In-app and email dunning closed the current story without adding extra compliance and channel-delivery scope. | Dunning ecosystem integration | repeated support issue or concrete adopter failure requiring SMS/push orchestration | 2026-05-28 |
| strategy_non_goal | FIN-03 finance exports · MRR/ARR product · MoR processors · Hyperwallet | explicit standing non-goals | Accrue is a billing/subscription library, not an accounting, merchant-of-record, or payout product. | Strategy non-goal | explicit strategy change or correctness/security/data-loss risk that cannot be handled by host-owned exports | carried |
| seed | SEED-002-ecosystem-integrations — Chimeway/Mailglass ecosystem integrations | backlogged; future-roadmap seed, not a closeout blocker | Ecosystem blueprints are dormant future-roadmap material and do not open milestone scope by themselves. | Future roadmap / ecosystem integrations | concrete adopter failure requiring an integration, repeated support issue, or explicit strategy change | 2026-05-31 |
| seed | SEED-003-repo-hygiene-before-new-milestone | backlogged; operational hygiene seed, not product scope | Repo/worktree/GitHub/GSD hygiene is useful before a new milestone or release prep but does not force a Hex publish. | Repo hygiene / release prep | before opening a new milestone, before release prep, or when local/GitHub/GSD state feels stale | 2026-07-01 |
| seed | SEED-004-admin-ui-blueprint-redesign — first-principles admin/operator UI redesign ("operator control plane over billing state"); north-star `prompts/accrue_admin_operator_ui_journey_blueprint.md`, synthesis `.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md` | backlogged; post-v1.56 multi-milestone program, not a v1.56 closeout blocker | New target (distinct from the v1.56 ratchet machinery); reaches into core `accrue` diagnosis fns (first for the admin-UI line). Recommended M1 IA/grammar → M2 signature surfaces+core diagnosis → M3 new rooms. | Admin UI / IA redesign (+ core diagnosis) | after v1.56 ships → `/gsd-new-milestone` (reopen class: explicit strategy change — flagship admin surface) | 2026-07-04 |
| seed | SEED-006-account-multi-rail-offline-entitlements | promoted; active v1.59 | Concrete B2C Alpha requirement for coherent Stripe/Apple account access and extended offline use. | Core entitlements / mobile billing | current milestone; Phase 215 is ready to plan | 2026-07-31 |
| seed | SEED-007-google-play-billing-rail | backlogged | Preserve the v1.59 seam as a reusable rail contract without paying Android lifecycle cost before demand. | Mobile billing / entitlements | Android scheduled or second adopter requires Google Play | 2026-07-31 |

## Session Continuity

Last session: 2026-08-05T17:29:02.726Z
Stopped at: Completed 221-02-PLAN.md
Resume file: None

## Operator Next Steps

- Plan Phase 215 with $gsd-plan-phase 215
