# Roadmap: Accrue

## Milestones

- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154-158 (shipped 2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.48 Release Readiness + Stable Core Posture** — Phases 159-162 (shipped 2026-06-01) — [archive](milestones/v1.48-ROADMAP.md)
- ✅ **v1.49 Realistic Demo App & Adoption Evidence** — Phases 163-166 (shipped 2026-06-02) — [archive](milestones/v1.49-ROADMAP.md)
- ✅ **v1.50 Admin UI Foundation** — Phases 167-173 (shipped 2026-06-02 via PR #32; archived 2026-06-03) — [archive](milestones/v1.50-ROADMAP.md)
- 🚧 **v1.51 Admin UI: Depth Pass (IA + Systematic Polish)** — Phases 174-179 (planning 2026-06-03; second, depth-oriented pass on the same `accrue_admin` surface; persona-driven IA reshape + token gap-closure + systematic rubric uplift + motion + seed expressiveness + screenshot-driven visual-QA; no new billing primitives)

## Planning Doctrine

Accrue is in **stable core / demand-driven expansion** posture as of 2026-05-31. Future feature milestones require at least one of:

- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- an operational release/support failure,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

No broad feature milestone is currently open. (v1.50 Admin UI Foundation is a quality / design-system / usability investment in an already-shipped surface, justified as adopter-facing DX — it adds no new billing primitives and does not reopen broad feature scope.)

Stop rule: if proposed work is polish-only with a documented workaround and no release/adopter failure mode, record it as deferred with a revisit trigger and do not create a milestone for it.

## Phases

<details open>
<summary>🚧 v1.51 Admin UI: Depth Pass (Phases 174-179) — PLANNING (deps A→B→C→{D,E}→F)</summary>

**Posture:** Quality / adopter-facing operator-DX investment in the already-shipped `accrue_admin` surface — **not** a broad feature milestone (no new billing primitives). The second, depth-oriented pass on v1.50's foundation: re-map IA from entity-shaped to job/persona-shaped, close design-token gaps, lift the under-iterated screen tail to one rubric baseline, add restrained motion, make seed data express every state, and prove it with a screenshot-driven visual-QA loop.

**Anti-churn rule:** every change cites a justification token — (a) a rubric dimension below bar with a before-score, (b) a named persona-job the screen fails to serve, or (c) a concrete token bypass / hardcode eliminated. *"Looks nicer / my taste" is not admissible.* Frozen screens (Home, primary nav, global search) touched only on a rubric-flagged regression or a persona-job miss.

**10-dimension rubric (0–3, pass ≥2):** ① token compliance ② visual hierarchy ③ spacing rhythm ④ state coverage ⑤ responsive/mobile-first (@360px) ⑥ contrast ⑦ focus & semantics ⑧ brand expression ⑨ motion ⑩ reuse/DRY.

**Guardrails (out of scope):** no Tailwind migration (double down on custom `ax-*` CSS + tokens); no churn on frozen screens absent a flagged regression; the demo/host app (`examples/accrue_host`) UI is not a design target (only the screenshot/seed substrate); no new billing primitives; no breaking changes (route reshaping ships with redirects, component public APIs stay backward-compatible).

**Authoritative design source:** `.planning/research/v1.51-admin-ui-depth-design.md`.

### Phase Summary

- [ ] **Phase 174: A — Design-System Gap Closure & Token Completeness** — Add line-height / letter-spacing / breakpoint / transition-bundle / reading-measure tokens, kill the remaining token bypasses, and publish a component-variants reference.
- [ ] **Phase 175: B — Persona-Driven IA Spine** — Re-tier nav into a weighty Billing zone + recessed specialist rooms with attention badges, verb launchers + visible search, Customer-360 tab tiering, mandatory bidirectional threading, work-queue list defaults, and redirected route reshaping.
- [ ] **Phase 176: C — Systematic Per-Screen Rubric Uplift** — Enumerate every screen × 10 dimensions × {light,dark} × {desktop,mobile}, baseline it, and lift the under-iterated tail worst-first with a mobile-first rewrite.
- [ ] **Phase 177: D — Motion & Micro-interaction Design** — Document a token-based interaction spec + antipattern list and apply restrained, reduced-motion-honoring motion to drawers, dropdowns, the command palette, tabs, flash, and skeleton→content.
- [ ] **Phase 178: E — Seed Expressiveness & State Coverage** — Extend E2E seed fixtures + host seeds so every screen's empty/populated/overflow/error/loading and edge states are reachable on a single click-through.
- [ ] **Phase 179: F — Screenshot-Driven Visual QA Loop & Sign-off** — Sweep the full inventory across {desktop,mobile}×{light,dark}, LLM-score each PNG against the 10 dimensions, remediate until no dimension <2, and produce the final scorecard + axe sign-off.

### Phase Details

### Phase 174: A — Design-System Gap Closure & Token Completeness

**Goal:** Close every remaining design-token gap so the admin CSS resolves all spacing/type/radius/shadow/line-height/letter-spacing/breakpoint/transition values from named `ax-*` tokens, kill the last token bypasses, and give maintainers a single component-variants reference. This is the substrate the rubric uplift, motion, and seed work all build on.
**Depends on:** Nothing (foundation phase)
**Requirements:** DSY-01, DSY-02, DSY-03
**Success Criteria** (what must be TRUE):

  1. A maintainer can grep `app.css` + components and find no hardcoded px/em line-height, letter-spacing, breakpoint, or transition literals — every such value resolves from an `ax-*` token (including a reading-measure max-width container token and pre-composed transition bundles).
  2. The dunning banner and invoice screens render every brand color through tokens with zero inline-hex fallbacks and zero inline styles; no admin surface bypasses the token system.
  3. A maintainer opening `/dev/components` sees a component-variants reference enumerating every button / badge / status / card variant alongside its token mapping.

**Plans:** 7 plans (4 executed + 3 gap-closure)

Plans:
**Wave 1**

- [x] 174-01-PLAN.md — Add type micro-tokens and transition-bundle tokens to theme.css (DSY-01 substrate)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 174-02-PLAN.md — Migrate app.css literals→tokens + breakpoint registry + dunning bypass kill + guard needle + asset rebuild (DSY-01, DSY-02)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 174-03-PLAN.md — ComponentRegistry data module + kitchen variant reference extension (DSY-03)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 174-04-PLAN.md — ComponentRegistryTest drift-prevention test + full suite gate (DSY-03)

**Wave 5 — Gap Closure** *(after verification; closes VERIFICATION.md gaps)*

- [x] 174-05-PLAN.md — Fix phantom tokens in ComponentRegistry + add token-validity test (DSY-03, Gap 1)
- [x] 174-06-PLAN.md — Seed adoption-proof-matrix.md in PackageDocsVerifierTest + Stripe-only negative test (DSY-01, Gap 2)
- [x] 174-07-PLAN.md — Resolve .ax-search-trigger stale deferral comment + asset rebuild (DSY-01, Gap 3)

**UI hint**: yes

### Phase 175: B — Persona-Driven IA Spine

**Goal:** Replace the entity-shaped interior with a job/persona-shaped spine — one weighty primary Billing zone plus quiet specialist rooms that light up only when they have work — so each of the six personas reaches its job fast, no detail screen dead-ends, and no existing bookmark breaks. This resolves the v1.50 "disjoint" seam between a job-shaped Home and an entity-shaped interior.
**Depends on:** Phase 174
**Requirements:** IA-01, IA-02, IA-03, IA-04, IA-05, IA-06, IA-07
**Success Criteria** (what must be TRUE):

  1. From Home, each of the six personas can reach their primary job in ≤2 clicks via a verb-labeled task launcher ("Look up a customer," "Clear the invoice queue," "Recover at-risk revenue," "Investigate an incident") or a visible (not hotkey-only) global search field.
  2. The sidebar shows a weighted primary **Billing** zone (Customers · Subscriptions · Invoices · Payments) with **Recovery / Developer / Catalog** as visually-recessed, collapsible specialist zones that surface attention-count badges (dead-letters, at-risk) only when work exists; **Connect** stands alone.
  3. Each work-queue list opens pre-filtered to the persona queue (e.g. invoices → open/uncollectible) with an "All" view one filter-chip away.
  4. Every detail screen renders a Related-billing card with no dead ends, and a dead-lettered webhook threads Webhook → Event → affected entity; Customer-360 shows primary tabs (Subscriptions, Invoices, Payments) with advanced tabs recessed under a quieter "More" grouping.
  5. Every route changed by the IA reshape redirects from its old path (no broken bookmarks), and a compliance/audit user can reach an actor-filtered view of the event log via a saved lens without it occupying a top-level nav group.

**Plans:** 7 plans across 4 waves

Plans:
**Wave 1** *(parallel — foundation data + query fixes)*

- [x] 175-01-PLAN.md — Query multi-status extension + Wave-0 test scaffolds (IA-03, IA-04, IA-06)
- [x] 175-02-PLAN.md — AttentionCounts + NavBadgeHook + Nav/AppShell extension + copy relabels + sidebar_collapse.js (IA-01, IA-02)

**Wave 2** *(parallel — blocked on Wave 1)*

- [x] 175-03-PLAN.md — Sidebar rewrite (collapse + badges) + CSS token-gap classes + RedirectController + route reshaping (IA-02, IA-06)
- [x] 175-04-PLAN.md — Work-queue default filters (invoices/subscriptions/payments) + visible Home search field (IA-01, IA-03)

**Wave 3** *(parallel — blocked on Wave 2)*

- [x] 175-05-PLAN.md — EventLive (/events/:id) + WebhookLive Related card + Webhook→Event→entity threading (IA-04, IA-06)
- [x] 175-06-PLAN.md — Customer-360 tab tiering (More ▾) + compliance actor-lens chip on events (IA-05, IA-07)

**Wave 4** *(blocked on Wave 3)*

- [x] 175-07-PLAN.md — Related cards on 4 missing detail screens + /charges→/payments href fixes + full suite gate (IA-04)

**UI hint**: yes

### Phase 176: C — Systematic Per-Screen Rubric Uplift

**Goal:** Bring every under-iterated screen up to one consistent rubric baseline by enumerating the full touchpoint matrix, capturing baseline scores, and lifting the worst screens first — eliminating the uneven depth left after v1.50. The heavy phase; wave-split per screen-group.
**Depends on:** Phase 174, Phase 175
**Requirements:** SCR-01, SCR-02, SCR-03, SCR-04
**Success Criteria** (what must be TRUE):

  1. Every admin screen scores ≥2 on all 10 rubric dimensions in both light and dark themes.
  2. Every admin screen scores ≥2 on all 10 rubric dimensions at both desktop and mobile (usable @360px) widths.
  3. The under-iterated tail (charges, coupons, promotion-codes, connect, events, webhooks, invoice detail) is lifted to baseline with documented before/after scores per screen.
  4. Dense text/detail screens apply a reading-measure max-width container and a mobile-first responsive layout built on the Phase 174 breakpoint tokens.

**Plans:** 6 plans (5 execution + 1 human checkpoint)

Plans:
**Wave 1** *(dependency root — SCORECARD baseline + CSS fix)*

- [x] 176-01-PLAN.md — Capture 176-SCORECARD.md baseline (all 21 screens × 10 dims) + fix data-table breakpoint --ax-bp-lg→--ax-bp-md + asset rebuild (SCR-01, SCR-02, SCR-03, SCR-04)

**Wave 2** *(blocked on Wave 1 — list screen audit)*

- [ ] 176-02-PLAN.md — Audit all 9 list screens card_fields/card_title quality against persona criteria; update SCORECARD Wave 1 after-scores (SCR-01, SCR-02, SCR-03)

**Wave 3** *(parallel — blocked on Wave 2 — catalog/specialist detail; 03 and 04 run in parallel)*

- [ ] 176-03-PLAN.md — Uplift event_live (semantic dl/dt/dd facts, detail_section body, not-found state) + coupon_live (Detail alias, summary_card hero, DRY projection section) (SCR-01, SCR-02, SCR-03, SCR-04)
- [ ] 176-04-PLAN.md — Uplift promotion_code_live (Detail alias, summary_card hero, detail_section parent-coupon) + connect_account_live (.ax-measure prose) + webhook_live (DRY forensic section, .ax-measure) (SCR-01, SCR-02, SCR-03, SCR-04)

**Wave 4** *(blocked on Wave 3 — dense financial detail)*

- [ ] 176-05-PLAN.md — Apply .ax-measure to invoice_live prose (4 regions) + charge_live prose (3 regions) + audit subscription_live; complete SCORECARD final after-scores (SCR-01, SCR-02, SCR-03, SCR-04)

**Wave 5** *(blocked on Wave 4 — Nyquist gate + final verification)*

- [ ] 176-06-PLAN.md — Nyquist breakpoint guard assertions in data_table_test.exs + ax-measure misapplication guard + full suite gate + human spot-check checkpoint (SCR-01, SCR-02, SCR-03, SCR-04)

**UI hint**: yes

### Phase 177: D — Motion & Micro-interaction Design

**Goal:** Add restrained, purposeful, token-based motion to the now-stable layouts — functional feedback, never decoration — governed by a documented spec and a researched antipattern list, and fully honoring reduced-motion. Depends on stable layouts so motion is applied once, not re-thrashed.
**Depends on:** Phase 174, Phase 176
**Requirements:** MOT-01, MOT-02, MOT-03
**Success Criteria** (what must be TRUE):

  1. A documented motion/interaction spec defines what animates, why, which token, and reduced-motion behavior, including an antipattern list grounded in researched best practice (Emil Kowalski principles).
  2. Drawers, dropdowns, the command palette, tabs, flash/toasts, and skeleton→content transitions animate via Phase 174 design-token transition bundles — functional, not decorative — and badge/state changes transition through tokens.
  3. All admin motion honors `prefers-reduced-motion` (no travel/overshoot; crossfades retained), verified by an automated check.

**Plans:** TBD
**UI hint**: yes

### Phase 178: E — Seed Expressiveness & State Coverage

**Goal:** Make every screen state and edge case reachable from seeded data on a single click-through, so no screen looks good only with hand-picked IDs — and so the visual-QA loop can actually photograph every state. Feeds the QA loop.
**Depends on:** Phase 175, Phase 176
**Requirements:** SEED-01, SEED-02
**Success Criteria** (what must be TRUE):

  1. Every admin screen's empty, populated, overflow/pagination, error, and loading states are reachable from seeded data on a single click-through (via E2E seed fixtures at `/__e2e__/seed/<fixture>` + host `seeds.exs`).
  2. Each edge state (dunning/at-risk, multi-currency, long strings, dark-only contrast traps) has a seeded instance; no screen depends on hand-picked IDs to look right.

**Plans:** TBD
**UI hint**: yes

### Phase 179: F — Screenshot-Driven Visual QA Loop & Sign-off

**Goal:** Prove the milestone's "done" with evidence: sweep the full screen inventory across all four matrix cells, score each screenshot against the 10 dimensions, remediate until nothing is below bar, and sign off with a scorecard + before/after evidence + axe in both themes.
**Depends on:** Phase 174, Phase 175, Phase 176, Phase 177, Phase 178
**Requirements:** QA-01, QA-02, QA-03
**Success Criteria** (what must be TRUE):

  1. The Playwright screenshot harness sweeps the full screen inventory (all ~20 screens incl. detail pages) across {desktop, mobile} × {light, dark}.
  2. An LLM-analysis step scores each screenshot against the 10-dimension rubric and emits structured findings (screen, dimension, score, defect, suggested fix), driving a remediation loop until no dimension scores below 2.
  3. A final scorecard shows every dimension ≥2 across all four matrix cells with before/after evidence, and axe passes in both light and dark themes.

**Plans:** TBD
**UI hint**: yes

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
| 163. Realistic Domain & Rich Seeds | v1.49 | 1/1 | Complete | 2026-06-01 |
| 164. Docker DX & Optimized Caching | v1.49 | 2/2 | Complete | 2026-06-01 |
| 165. E2E Automation & Shift-Left CI | v1.49 | 4/4 | Complete | 2026-06-02 |
| 166. Adoption DX Docs | v1.49 | 3/3 | Complete | 2026-06-02 |
| 167. Design Tokens & Motion Foundation | v1.50 | ✓ | Complete | 2026-06-02 |
| 168. Typography & Icon System | v1.50 | ✓ | Complete | 2026-06-02 |
| 169. IA — Home, Nav & Search | v1.50 | ✓ | Complete | 2026-06-02 |
| 170. Cross-Screen Threading & Microcopy | v1.50 | ✓ | Complete | 2026-06-02 |
| 171. Shared Detail Components & Refactor | v1.50 | ✓ | Complete | 2026-06-02 |
| 172. Seed Enrichment & Component Kitchen | v1.50 | ✓ | Complete | 2026-06-02 |
| 173. Rubric Audit & Visual/A11y Coverage | v1.50 | ✓ | Complete | 2026-06-02 |
| 174. A — Design-System Gap Closure & Token Completeness | v1.51 | 7/7 | Complete   | 2026-06-04 |
| 175. B — Persona-Driven IA Spine | v1.51 | 7/7 | Complete   | 2026-06-04 |
| 176. C — Systematic Per-Screen Rubric Uplift | v1.51 | 1/6 | In Progress|  |
| 177. D — Motion & Micro-interaction Design | v1.51 | 0/? | Not started | - |
| 178. E — Seed Expressiveness & State Coverage | v1.51 | 0/? | Not started | - |
| 179. F — Screenshot-Driven Visual QA Loop & Sign-off | v1.51 | 0/? | Not started | - |

## Historical Backlog Anchors (not active scope)

These v1.17 FRG anchors are retained for traceability only as historical, non-active planning context. They do not create milestone scope unless a fresh sourced friction row meets the current stable-core evidence bar.

- [INT-10 Phase 63](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63) — Historical / non-active Braintree and multi-processor integration anchor; materially shipped across v1.31+ and reflected in the processor support matrix. Reopen only for a concrete adopter failure mode or operational failure in the shipped processor-support contract.
- [BIL-03 Phase 64](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64) — Historical / non-active billing portal configuration anchor; materially shipped via `accrue_portal`, guides, and host proof. Reopen only for a repeated support issue or correctness/data-loss risk in the portal support surface.
- [ADM-12 Phase 65](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65) — Historical / non-active admin UI role-based access anchor; no current broad feature scope follows from this link. Reopen only for a concrete security/compliance requirement or explicit strategy change.

## Deferred Seeds and Ideas (dormant / trigger-bound)

| Item | Status | Reason | Future owner/category | Revisit trigger |
|------|--------|--------|-----------------------|-----------------|
| SEED-001 | resolved historical context | Linked-release purpose was superseded by later linked publish work and Phase 159 release-readiness proof. | Release readiness / archive traceability | operational failure in linked release proof or explicit strategy change in release process |
| SEED-002 | dormant future roadmap | Ecosystem integrations are useful blueprints but are not v1.48 closeout blockers and do not create default milestone scope. | Future roadmap / ecosystem integrations | concrete adopter failure requiring one listed integration, repeated support issue, or explicit strategy change |
| ENT-EXT-01 | deferred | Rich metered, tiered, and range entitlement math is beyond current seat-count support and lacks a sourced adopter contract. | Entitlements extension | concrete adopter failure or explicit adopter contract requiring richer entitlement math |
| FIN-03 | standing non-goal | App-owned finance exports remain outside Accrue's declared billing-library scope. | Strategy non-goal / finance exports | explicit strategy change or correctness/security/data-loss risk that cannot be solved by host-owned exports |
