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
- ⏸️ **v1.56 Admin UI Ratchet: Automated Adversarial Design Evaluation** — Phases 205-208 (PARKED 2026-07-19; 205-207 shipped, 208 was 3/5 and non-converging on IA findings — the work v1.57 now takes on; ledger + baseline preserved in `accrue_admin/e2e/ratchet/`) — [archive](milestones/v1.56-ROADMAP.md)
- 🔨 **v1.57 Admin Operator Control Plane (SEED-004 M1)** — Phases 209-211 (ACTIVE, opened 2026-07-19; reign the two outlier admin pages — Home + Subscriptions — onto the shared component vocabulary and pivot their IA to answer-first, so the whole `accrue_admin` reads as one operator-first system; admin-only, no core `accrue` change, no new nav rooms, no new deps)

## Planning Doctrine

Accrue is in **stable core / demand-driven expansion** posture as of 2026-05-31. Future feature milestones require at least one of:

- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- an operational release/support failure,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

**v1.57 Admin Operator Control Plane (SEED-004 M1) is open** (Phases 209-211, opened 2026-07-19). It is **not** a broad feature milestone: it is the first slice of the SEED-004 admin redesign — an information-architecture / component-grammar pivot on the already-shipped `accrue_admin` operator UI. Reopen justification class: **explicit strategy change** (flagship adopter-facing admin surface, elevated to a strategic redesign — same class accepted for v1.50–v1.54), recorded in `PROJECT.md`. Scope is admin-only (`accrue_admin` LiveView templates + `assets/css`): **no core `accrue` change** (core diagnosis fns are M2), **no new nav rooms** (M3), no new deps, no Tailwind migration, `ax-*` stays the styling SSOT, no `accrue_portal` work. The parked v1.56 ratchet re-locks this redesign after M1 lands.

**v1.56 Admin UI Ratchet is PARKED** (2026-07-19) mid-flight to open v1.57. Phases 205-207 shipped; Phase 208 (prove-convergence + ACCEPT) was 3/5 with 208-04/05 maintainer-gated and **non-converging because the ratchet kept surfacing information-architecture findings** — which is exactly the work v1.57/SEED-004 now takes on. The forward-only ledger + frozen baseline in `accrue_admin/e2e/ratchet/` are preserved untouched; the harness becomes the tool that re-freezes the v1.57 redesign after it lands. The 23 round-99 confirmed IA findings are carried into v1.57 as M1 input (`research/admin-ratchet-round99-confirmed-findings.json`). To resume v1.56 later: restore from the archive and run `/gsd-execute-phase 208`.

Stop rule: if proposed work is polish-only with a documented workaround and no release/adopter failure mode, record it as deferred with a revisit trigger and do not create a milestone for it.

## Phases

### 🔨 v1.57 Admin Operator Control Plane (SEED-004 M1) (Phases 209-211) — ACTIVE (opened 2026-07-19)

**Posture:** First slice (M1) of the SEED-004 redesign of `accrue_admin` from a CRUD surface into an "operator control plane over billing state." M1 reigns the two outlier pages — **Home** (`dashboard_live.ex`) and **Subscriptions** (`subscriptions_live.ex`) — onto the canonical shared component vocabulary (PageHeader / StatStrip / DataTable / FilterChipBar / `.ax-card` / Button / StatusBadge / EmptyState / KpiCard / Timeline / Icon) that ~10 admin pages already follow, and pivots their information architecture to **answer-first** (one scannable health verdict + one primary action per zone, redundant bands trimmed), retiring ~325 bespoke `.ax-home-*` / `.ax-launcher*` / `.ax-attention*` / `.ax-subscriptions-*` / `.ax-inline-worklist*` rules. **Scope fence (binding):** admin-only; **no** core `accrue` change (M2), **no** new nav rooms (M3), **no** "why blocked"/causality/diagnosis synthesis, no new deps, no Tailwind migration; `ax-*` stays the styling SSOT; keep the Cobalt / quiet-confidence brand + prior de-garish/card-grammar polish. Console **density is the point** — do not over-air. Reuse shared components (compose, don't fork); at most one small new shared component (`WorkQueueCallout`) if the callout shape demonstrably repeats. Every CSS/copy change rebuilds + commits **both** generated artifacts (`priv/static/accrue_admin.css` via `mix accrue_admin.assets.build`, and `examples/accrue_host/e2e/generated/copy_strings.json` via `mix accrue_admin.export_copy_strings`); CSS retirement is grep-gated (classes shared with the out-of-scope subscription **detail** page are preserved); PNG-verify against the canonical Payments/Customers/Invoices reference. Authoritative design sources: `prompts/accrue_admin_operator_ui_journey_blueprint.md`, `.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md`, `research/admin-ratchet-round99-confirmed-findings.json`.

- [ ] **Phase 209: Reign Subscriptions (list + detail CSS coordination)** - Compose the Subscriptions list from the canonical spine — single verdict, one invoice-queue action, five bespoke bands trimmed, compact cell idiom, per-row actions out of cells — and resolve the `WorkQueueCallout` extract-or-inline decision + the detail-page shared-CSS coordination (REIGN-01, REIGN-02, COMP-01)
- [ ] **Phase 210: Reign Home + certify answer-first IA & copy integrity** - Adopt `PageHeader` and recompose Home's attention rail + launcher tiles from shared primitives, then certify the answer-first grammar and copy/nav integrity across both now-reigned pages (REIGN-03, IA-01, IA-02, IA-03, IA-04, COPY-01, COPY-02)
- [ ] **Phase 211: Grep-gated CSS retirement & cross-surface cleanup** - Retire the now-dead bespoke `.ax-*` rules (grep-gated, detail-shared classes preserved), rebuild the committed bundle, and clean up the component kitchen / storybook / `region-tags.js` selector map (REIGN-04)

Coverage: **11/11 requirements** mapped to Phases 209-211 (each REQ-ID → exactly one phase). Per-phase counts: 209→3 · 210→7 · 211→1. Dependencies: strictly linear — 209 → 210 → 211 (Subscriptions before Home per the research build order; CSS retirement last, after both templates land, because `.ax-inline-worklist*` / `.ax-audit-summary-row` are shared with the out-of-scope subscription detail page). Full per-phase goals + success criteria: see [Phase Details](#phase-details-v157-active-milestone).

<details>
<summary>⏸️ v1.56 Admin UI Ratchet: Automated Adversarial Design Evaluation (Phases 205-208) — PARKED 2026-07-19</summary>

**Posture:** Maintainer-run, forward-only "UI Ratchet" that automates fan-out adversarial design evaluation → dedup → verify → batch-fix → re-score → loop-until-dry over `accrue_admin` (dev/test-only tooling + admin CSS polish). **PARKED mid-flight** to open v1.57: Phases 205-207 shipped; Phase 208 (prove-convergence + ACCEPT) reached 3/5 with 208-04/05 maintainer-gated and non-converging on IA findings — the work v1.57 now takes on. The ledger + frozen baseline in `accrue_admin/e2e/ratchet/` are preserved untouched and become the tool that re-locks the v1.57 redesign after it lands. The v1.56 optional "full-surface sweep" placeholder (originally numbered 209, `SWEEP-01`) was never created as a phase; **phase number 209 is reused by v1.57**.

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

## Phase Details (v1.57 active milestone)

### Phase 209: Reign Subscriptions (list + detail CSS coordination)

**Goal**: The Subscriptions list (`subscriptions_live.ex`) is composed only from the canonical shared skeleton (`AppShell → section.ax-page → PageHeader → FlashGroup → DataTable` with `FilterChipBar` in `:list_status`), reads answer-first (one verdict, one invoice-queue entry point), and its per-row cells use the compact shared idiom — while the shared-CSS coordination with the out-of-scope subscription **detail** page (`subscription_live.ex`) is resolved so no later deletion can silently break it. This is the first, lowest-risk reign (Subscriptions is ~90% already on the skeleton) and it surfaces the one-new-component decision before Home needs to consume it.
**Depends on**: Nothing (first phase of v1.57)
**Requirements**: REIGN-01, REIGN-02, COMP-01
**Success Criteria** (what must be TRUE):

  1. The Subscriptions list renders from the canonical spine with **nothing** between `FlashGroup` and the `DataTable`: the five bespoke band `<section>`s (`.ax-subscriptions-invoice-strip` / `-queue-shortcut` / `-invoice-records` / `-secondary-strips` wrapping `-at-risk-strip` + `-audit-strip`) are gone, the page-level override classes (`ax-page-compact ax-subscriptions-page`, `ax-page-header-compact ax-subscriptions-header`, the `ax-kpi-row` StatStrip wrapper) are dropped, and the now-dead `open_invoice_queue/1` query is removed — with a content inventory proving every distinct operator datum (at-risk exposure, last-webhook status, open-invoice count) survives, relocated not lost.
  2. The page presents one scannable health verdict (short-noun title + a single verdict expressed via StatStrip/StatusBadge, not a full-sentence title) and exactly one invoice-queue primary action in `PageHeader` `:actions` (the triple-repeated "Open dedicated invoice queue" CTA — the most-confirmed round-99 defect — collapses to one), with the fake "Billing health overview" breadcrumb parent replaced by the real 2-crumb `[home, Subscriptions]`.
  3. Subscriptions table + card cells render via the compact shared idiom (`StatusBadge`, `ax-stack-xs`, `ax-link`, `ax-chip ax-label`) with no in-cell action buttons — the 15-20-line bespoke `identity_cell/3` + `billing_signals_cell/3` raw HTML is rebuilt and per-row actions move to a shared control (actions column or `DropdownMenu`), matching the reference pages.
  4. The `WorkQueueCallout` extract-or-inline decision is made and recorded: if the trimmed worklist callout shape demonstrably repeats (and will be reused by Home), exactly one small shared component composed from existing tokens + `.ax-card` reusing the `moss`/`cobalt`/`amber`/`slate`/`ink` tone scale is added and consumed by Subscriptions; otherwise Subscriptions composes from `.ax-card` directly and no component is added. No other new components, no new deps.
  5. Verification gates pass in-phase: no operator-density regression versus the pre-reign Subscriptions screenshot (row height, rows-per-viewport, header band height held) and PNG parity against the canonical Payments/Customers/Invoices reference; the `subscriptions_live_test:111` (`ax-kpi-row ax-subscriptions-kpi-row`) assertion and any other retired-class/copy assertions are migrated to the shared-component selector in this phase; the served `priv/static/accrue_admin.css` bundle and `examples/accrue_host/e2e/generated/copy_strings.json` are rebuilt and committed; the subscription **detail** page's shared `.ax-inline-worklist*` / `.ax-audit-summary-row` styling is preserved (retain-vs-reign decided and PNG-verified) — and the diff touches no `accrue/lib`, adds no nav room, and introduces no "why blocked"/causality synthesis.

**Plans**: 3 plans
Plans:
**Wave 1**

- [x] 209-01-PLAN.md — Baseline capture: pre-reign test-green confirmation + PNG snapshot (Subscriptions + Subscription-detail, light/dark)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 209-02-PLAN.md — Header/spine rebuild (breadcrumb, single verdict, single CTA, 4-stat StatStrip, Copy additions) + band removal/dead-code cleanup + compact cell rebuild

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 209-03-PLAN.md — D-04 shared-CSS grep-gate + detail-page PNG parity + test migration + generated-artifact rebuild

**UI hint**: yes

### Phase 210: Reign Home + certify answer-first IA & copy integrity

**Goal**: The Home page (`dashboard_live.ex`) is composed from the canonical `PageHeader` instead of a hand-rolled `<header>`, its two signature zones (attention rail + task-launcher tiles) are rebuilt from shared primitives, and — with both outlier pages now reigned — the answer-first information architecture and plain-language copy/nav integrity are certified across Home **and** Subscriptions so the whole admin reads as one operator-first system. Home is the larger lift (fully bespoke header + two zones with no shared component today) and is done second so it can consume anything Subscriptions established (including `WorkQueueCallout`).
**Depends on**: Phase 209
**Requirements**: REIGN-03, IA-01, IA-02, IA-03, IA-04, COPY-01, COPY-02
**Success Criteria** (what must be TRUE):

  1. Home is composed from the canonical `PageHeader` (breadcrumbs + title + `:description`/`:actions`/`:stat_strip`); its attention rail + four launcher tiles are rebuilt from `.ax-card` + `Button` + `Icon` + `StatusBadge` (with `EmptyState` for empty branches), and the already-canonical `KpiCard` "At a glance" band and `Timeline` activity cards are kept as-is.
  2. Each of the two pages presents exactly **one** scannable billing-health verdict (Home's verdict — rendered three times today — and the Subscriptions verdict each collapse to a single clear statement) and **one** unambiguous primary action per zone (Home's triplicated customer-search entry de-duplicates to a single discoverable control folded into `PageHeader` `:actions`; the Subscriptions invoice-queue entry stays single from Phase 209).
  3. Content on both pages is ordered answer-first (health verdict → primary action → supporting detail → records), redundant bands are trimmed with **no operator-density regression** versus each page's pre-reign baseline (verified by PNG compare against both the canonical reference and the pre-reign screenshot), and console density is preserved rather than over-aired.
  4. Operator-facing copy on both pages is plain-language (no double-negative "No — billing is not active"; "workspace" jargon clarified) and sourced from `AccrueAdmin.Copy` (no inline template literals); breadcrumbs point only to real navigable parents (no fake "Billing health overview"), and the primary customer-lookup control is discoverable rather than buried.
  5. Verification gates pass in-phase: the `dashboard_live_test` assertions at L107 (`ax-home-health-answer`), L130 (`ax-launcher-primary`), L184 (`ax-home-customer-search-cta`) and the `e2e/admin-spec-overview-phase194` + `admin-interaction-overlay-phase199` `.ax-attention-rail*` selectors are migrated to the shared-component DOM; `admin-a11y.spec.js` (axe) stays green with landmark/heading/visually-hidden semantics preserved; the served `accrue_admin.css` bundle and `copy_strings.json` are rebuilt and committed; and the diff touches no `accrue/lib`, adds no nav room, and introduces no diagnosis/causality synthesis.

**Plans**: TBD
**UI hint**: yes

### Phase 211: Grep-gated CSS retirement & cross-surface cleanup

**Goal**: With both target templates reigned, retire the now-dead bespoke `.ax-*` rule sets from `assets/css/app.css`, rebuild and commit the served bundle, and clean up the secondary surfaces that still reference the retired vocabulary (component kitchen, storybook, and the parked ratchet's `region-tags.js` selector map) — grep-gated throughout so the out-of-scope subscription detail page keeps its shared classes. CSS deletion is sequenced last, after all reigned templates land, because blind prefix-deletion is invisible to source-text CI.
**Depends on**: Phase 210 (both Home and Subscriptions must be reigned before the shared/dead CSS can be safely retired)
**Requirements**: REIGN-04
**Success Criteria** (what must be TRUE):

  1. A definitive grep census across `lib/`, `test/`, and `e2e/` confirms zero remaining references to each candidate class before deletion; the bespoke `.ax-home-*` / `.ax-launcher*` / `.ax-attention*` / `.ax-health-summary*` / `.ax-subscriptions-*` / `.ax-subscription-row-*` / `.ax-subscription-setup*` sets (~325 rules) are removed from `assets/css/app.css`.
  2. The detail-page-shared classes (`.ax-inline-worklist`, `.ax-inline-worklist-copy`, `.ax-audit-summary-row`, and any other class still referenced by `subscription_live.ex`) are **preserved**; the subscription detail page is PNG-verified unbroken after retirement.
  3. The committed `priv/static/accrue_admin.css` bundle is rebuilt via `mix accrue_admin.assets.build` and committed in the same change (no dead-CSS ship); a cheap guard confirms no orphan `ax-*` rule lacks a source reference and no source `ax-*` class lacks a rule.
  4. The component kitchen (`component_kitchen_live.ex`) and `priv/static/storybook.css` no longer render retired vocabulary (updated + `storybook.css` rebuilt), the phase200 storybook specs stay green, and the parked `region-tags.js` `.ax-attention-rail` mapping is opportunistically fixed so a future ratchet re-freeze starts from a non-dangling selector map.
  5. Full `mix test` + the admin e2e suite are green across the phase boundary (no red left behind), and the diff touches no `accrue/lib` and adds no nav room.

**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 193. Research, re-baseline & pattern lock | v1.54 | 5/5 | Complete | 2026-06-25 |
| 194. Exemplar A — Dashboard | v1.54 | 4/4 | Complete | 2026-06-26 |
| 195. Exemplar B — Subscription detail | v1.54 | 8/8 | Complete | 2026-06-26 |
| 196. Exemplar C — Subscriptions list + PageHeader | v1.54 | 5/5 | Complete | 2026-06-26 |
| 197. Propagate LIST | v1.54 | 7/7 | Complete | 2026-06-28 |
| 198. Propagate DETAIL + analytics | v1.54 | 9/9 | Complete | 2026-06-29 |
| 199. Cross-cutting interaction/overlay correctness | v1.54 | 15/15 | Complete | 2026-06-30 |
| 200. Idempotent verification & sign-off | v1.54 | 6/6 | Complete | 2026-06-30 |
| 201. Software quality evaluation | v1.55 | 1/1 | Complete | 2026-07-02 |
| 202. CI/CD performance and determinism audit | v1.55 | 1/1 | Complete | 2026-07-02 |
| 203. Database schema contract ADR | v1.55 | 1/1 | Complete | 2026-07-02 |
| 204. Ranked hardening roadmap | v1.55 | 1/1 | Complete | 2026-07-03 |
| 205. Persona + design-lens evaluator harness | v1.56 | 5/5 | Complete | 2026-07-03 |
| 206. Adversarial verifier + finding ledger + deterministic gate | v1.56 | 4/4 | Complete | 2026-07-04 |
| 207. Orchestration + digest + one-command round/fix loop | v1.56 | 8/8 | Complete | 2026-07-07 |
| 208. Prove convergence on slice + wire CI + ACCEPT | v1.56 | 3/5 | Parked | - |
| 209. Reign Subscriptions (list + detail CSS coordination) | v1.57 | 1/3 | In Progress|  |
| 210. Reign Home + certify answer-first IA & copy integrity | v1.57 | 0/0 | Not started | - |
| 211. Grep-gated CSS retirement & cross-surface cleanup | v1.57 | 0/0 | Not started | - |

## Historical Backlog Anchors (not active scope)

These v1.17 FRG anchors are retained for traceability only as historical, non-active planning context. They do not create milestone scope unless a fresh sourced friction row meets the current stable-core evidence bar.

- [INT-10 Phase 63](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63) — Historical / non-active Braintree and multi-processor integration anchor; materially shipped across v1.31+. Reopen only for a concrete adopter failure mode or operational failure in the shipped processor-support contract.
- [BIL-03 Phase 64](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64) — Historical / non-active billing portal configuration anchor; materially shipped via `accrue_portal`, guides, and host proof. Reopen only for a repeated support issue or correctness/data-loss risk in the portal support surface.
- [ADM-12 Phase 65](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65) — Historical / non-active admin UI role-based access anchor. Reopen only for a concrete security/compliance requirement or explicit strategy change.

## Deferred Seeds and Ideas (dormant / trigger-bound)

| Item | Status | Reason | Future owner/category | Revisit trigger |
|------|--------|--------|-----------------------|-----------------|
| SEED-004 M2 (signature diagnostic surfaces + core diagnosis) | deferred (next after v1.57 M1) | The "Why blocked?" diagnosis card, causality graph/timeline, unified `billing_state_for_customer/1` synthesis, freshness/stale chips, and the core `accrue` diagnosis fns they require (`blocking_reason_for_owner/1`, `causality_chain_for_event/1`) + durable event-name contracts. First admin-UI line to reach into core `accrue`. | Admin UI / IA + core diagnosis | after v1.57 M1 lands → `/gsd-new-milestone` (reopen class: explicit strategy change) |
| SEED-004 M3 (new rooms + structure + ratchet re-freeze) | deferred (after M2) | New Usage/meters, checkout-sessions, Connect-capabilities, fee-reconciliation rooms; `+Usage`/`+Settings` nav groups; de-tab Customer-360; and the v1.56-ratchet re-freeze (refresh design-lens rubric + persona exemplars + re-freeze baseline) that re-locks the landed redesign. | Admin UI / IA + ratchet | after M2 lands; ratchet re-freeze is post-M3 |
| v1.56 SWEEP-01 (full-surface ratchet sweep) | parked with v1.56 | Graduate the remaining ~19 admin surfaces round-by-round under the proven ratchet. Parked with the v1.56 milestone; the ratchet re-freeze after SEED-004 lands supersedes the original sweep target. | Ratchet / admin design QA | v1.56 resumed, or post-M3 ratchet re-freeze |
| TOOL-02 (pixel-diff visual-regression) | deferred (v1.53/v1.54) | Percy/Applitools-style pixel-diff tooling deferred in favor of the scored-cell forward-only gate over real composed routes. | Visual-regression tooling | flaky/insufficient scored-cell + judge loop, or explicit strategy change |
| TOOL-03 (publish tokens.css distributable) | deferred (v1.53) | Standalone npm/CDN token distributable not needed for the admin passes. | Brand/token distribution | external doc/marketing-site need for distributable tokens |
| ENT-EXT-01 | deferred | Rich metered/tiered/range entitlement math beyond current seat-count support; no sourced adopter contract. | Entitlements extension | concrete adopter failure or explicit adopter contract |
| FIN-03 | standing non-goal | App-owned finance exports remain outside Accrue's declared billing-library scope. | Strategy non-goal / finance exports | explicit strategy change or correctness/security/data-loss risk not solvable by host-owned exports |
| SEED-002 | dormant future roadmap | Ecosystem integrations are useful blueprints but do not create default milestone scope. | Future roadmap / ecosystem integrations | concrete adopter failure requiring one listed integration, repeated support issue, or explicit strategy change |
