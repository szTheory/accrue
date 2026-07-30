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

## Planning Doctrine

Accrue is in **stable core / demand-driven expansion** posture as of 2026-05-31. Future feature milestones require at least one of:

- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- an operational release/support failure,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

**No broad feature milestone is currently open.** v1.57 (SEED-004 M1) shipped 2026-07-30 under the *explicit strategy change* reopen class (flagship adopter-facing admin surface, elevated to a strategic redesign — same class accepted for v1.50–v1.54). The next SEED-004 candidate is **M2** (signature "Why blocked?" diagnosis surfaces + causality graph + the first core `accrue` diagnosis functions), deferred pending a `/gsd-new-milestone` reopen decision recorded in `PROJECT.md`.

**v1.56 Admin UI Ratchet is PARKED** (2026-07-19) mid-flight. Phases 205-207 shipped; Phase 208 (prove-convergence + ACCEPT) was 3/5 with 208-04/05 maintainer-gated and **non-converging because the ratchet kept surfacing information-architecture findings** — which is exactly the work v1.57/SEED-004 took on and shipped. The forward-only ledger + frozen baseline in `accrue_admin/e2e/ratchet/` are preserved untouched; per its own design the harness re-freezes the v1.57 redesign after M3 lands. The 23 round-99 confirmed IA findings were carried into v1.57 as M1 input (`research/admin-ratchet-round99-confirmed-findings.json`). To resume v1.56 later: restore from the archive and run `/gsd-execute-phase 208`.

Stop rule: if proposed work is polish-only with a documented workaround and no release/adopter failure mode, record it as deferred with a revisit trigger and do not create a milestone for it.

## Phases

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
| lattice_stripe 2.0.0 entitlements dep bump (SEED-005) | ready (not auto-executed) | lattice_stripe 2.0.0 is live on Hex with entitlements support; the major 1.x→2.0 bump is earmarked. Promote via a new milestone or run standalone. | Core deps / entitlements | maintainer promotes, or an entitlements feature needs the 2.0 surface |
| TOOL-02 (pixel-diff visual-regression) | resolved (superseded by v1.57 gate) | Percy/Applitools-style pixel-diff tooling was deferred in favor of the scored-cell forward-only gate; v1.57 introduced a first-party deterministic Playwright `toHaveScreenshot` pixel-diff gate (4 admin surfaces × light/dark) in browser-uat. | Visual-regression tooling | broaden surface coverage, or replace with a hosted service on explicit strategy change |
| TOOL-03 (publish tokens.css distributable) | deferred (v1.53) | Standalone npm/CDN token distributable not needed for the admin passes. | Brand/token distribution | external doc/marketing-site need for distributable tokens |
| ENT-EXT-01 | deferred | Rich metered/tiered/range entitlement math beyond current seat-count support; no sourced adopter contract. | Entitlements extension | concrete adopter failure or explicit adopter contract |
| FIN-03 | standing non-goal | App-owned finance exports remain outside Accrue's declared billing-library scope. | Strategy non-goal / finance exports | explicit strategy change or correctness/security/data-loss risk not solvable by host-owned exports |
| SEED-002 | dormant future roadmap | Ecosystem integrations are useful blueprints but do not create default milestone scope. | Future roadmap / ecosystem integrations | concrete adopter failure requiring one listed integration, repeated support issue, or explicit strategy change |
| SEED-001 | resolved historical context | Linked-release purpose was superseded by later linked publish work and Phase 159 release-readiness proof. | Release readiness / archive traceability | operational failure in linked release proof or explicit strategy change in release process |
