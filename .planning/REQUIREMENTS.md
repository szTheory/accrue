# Requirements: Accrue

Standing, posture-level requirements that persist between milestones. Milestone-specific
requirements are added here when a milestone is opened (see `.planning/ROADMAP.md`).
Accrue is in **stable core / demand-driven expansion** posture; broad feature milestones
remain closed by default per the post-v1.48 pause rule.

## Stable-Core Positioning

- [x] **POS-01**: Developer evaluating Accrue can read the public docs and package READMEs and understand that Accrue is stable-core / demand-driven expansion, not a broad feature-chasing billing product.
- [x] **POS-02**: Developer adopting Accrue can see the complete supported SaaS billing loop, processor support boundaries, and package ownership boundaries without reading planning internals.
- [x] **POS-03**: Maintainer can verify that release notes, package docs, support matrix, adoption proof docs, and planning mirrors all describe the same stable-core posture.

## Milestone v1.50 Requirements — Admin UI Foundation (built & merged 2026-06-02 via PR #32; formal archive deferred)

A deliberate quality/polish + adopter-facing DX investment in the already-shipped
`accrue_admin` UI. **Not a broad feature milestone** — no new billing primitives; it
raises the design-system, information-architecture, and usability baseline of an existing
surface, justified as adopter-facing DX per the post-v1.48 pause rule.

- [x] **AUI-01**: Operator sees a tightened, consistent design system — crisp radii, restrained shadows, a complete spacing scale, a distinct `--ax-info` color, money-state semantics, and token-based motion — with zero surfaces bypassing the token system (dunning banner + invoice inline styles fixed).
- [x] **AUI-02**: Admin UI has a distinct brand identity via self-hosted display + body typefaces (tabular numerals on all figures), a heroicons inline-SVG icon system, and a favicon.
- [x] **AUI-03**: Operator landing on the admin home gets a uk.gov-style task-launcher start page (attention rail → task launchers → demoted KPIs), a job-aligned nav regroup (Billing / Recovery / Developer / Catalog / Connect, eyebrow sublabels dropped), and an always-on `Cmd-K` global search with recents/pins.
- [x] **AUI-04**: Operator can thread between related resources from every detail screen with no dead ends (`Customer ⇄ Subscription ⇄ Invoice ⇄ Charge ⇄ Event`), path-aware breadcrumbs, and plain-language glosses for domain jargon.
- [x] **AUI-05**: Detail screens are composed from shared `<.detail_section>` components (the 6 large screens refactored); skeleton/loading states and entity-specific empty states exist; overlapping badge systems are consolidated.
- [x] **AUI-06**: Seed data fully expresses every admin screen (past-due/dunning campaigns, refunds, varied invoice statuses, coupons/promo codes in use, richer Connect states); the pre-existing host seed dunning-event bug is fixed; the component kitchen exercises every component × every state.
- [x] **AUI-07**: A 10-dimension visual/UX rubric audit passes across all screens and components, with screenshot coverage of all ~20 screens (desktop + mobile + dark) and automated axe a11y wired into the admin e2e.

## Milestone v1.51 Requirements — Admin UI: Depth Pass

The second, depth-oriented pass on the same `accrue_admin` surface. Still **not a broad
feature milestone** (no new billing primitives) — it re-maps information architecture from
entity-shaped to job/persona-shaped, closes design-token gaps, lifts under-iterated screens
to one rubric baseline, adds restrained motion, makes seed data express every state, and
proves it with a screenshot-driven visual-QA loop. Design source:
`.planning/research/v1.51-admin-ui-depth-design.md`. **Anti-churn rule:** every change cites a
rubric dimension below bar, a failed persona-job, or a token bypass killed — never taste.
Rubric (0–3, pass ≥2): ① token compliance ② visual hierarchy ③ spacing rhythm ④ state coverage
⑤ responsive/mobile-first ⑥ contrast ⑦ focus & semantics ⑧ brand expression ⑨ motion ⑩ reuse/DRY.

### Design-System Completeness (DSY) — Phase 174 (A)

- [ ] **DSY-01**: Operator-facing admin CSS resolves every spacing, type, radius, shadow, line-height, letter-spacing, breakpoint, and transition value from a named `ax-*` token — no hardcoded px/em for these remain in `app.css` or components.
- [ ] **DSY-02**: The dunning banner and invoice screens render brand colors via tokens with zero inline-hex fallbacks; no surface bypasses the token system.
- [ ] **DSY-03**: A maintainer can open `/dev/components` and see a component-variants reference enumerating every button / badge / status / card variant with its token mapping.

### Persona-Driven Information Architecture (IA) — Phase 175 (B)

- [ ] **IA-01**: From Home, each of the six personas can reach their primary job in ≤2 clicks via a verb-labeled task launcher or a visible (not hotkey-only) global search field.
- [ ] **IA-02**: The sidebar presents a weighted primary **Billing** zone with **Recovery / Developer / Catalog** as visually-recessed, collapsible specialist zones that surface attention-count badges (e.g. dead-letters, at-risk) only when work exists.
- [ ] **IA-03**: List screens open pre-filtered to the persona work-queue (e.g. invoices → open/uncollectible), with an "All" view one filter-chip away.
- [ ] **IA-04**: Every detail screen renders a Related-billing card with no dead ends; a dead-lettered webhook threads to its event(s) and onward to the affected entity.
- [ ] **IA-05**: Customer-360 presents primary tabs (Subscriptions, Invoices, Payments) with advanced tabs (Payment methods, Entitlements, Events, Metadata) recessed under a quieter "More" grouping.
- [ ] **IA-06**: Routes changed by the IA reshape redirect from their old paths, so existing bookmarks and links never break.
- [ ] **IA-07**: A compliance/audit user can reach an actor-filtered view of the event log via a saved lens (without it occupying a top-level nav group).

### Per-Screen Rubric Uplift (SCR) — Phase 176 (C)

- [ ] **SCR-01**: Every admin screen scores ≥2 on all 10 rubric dimensions in both light and dark themes.
- [ ] **SCR-02**: Every admin screen scores ≥2 on all 10 rubric dimensions at both desktop and mobile (usable @360px) widths.
- [ ] **SCR-03**: The under-iterated tail (charges, coupons, promotion-codes, connect, events, webhooks, invoice detail) is lifted to the rubric baseline, with documented before/after scores per screen.
- [ ] **SCR-04**: Dense text/detail screens apply a reading-measure max-width container and a mobile-first responsive layout built on the DSY breakpoint tokens.

### Motion & Micro-interaction (MOT) — Phase 177 (D)

- [ ] **MOT-01**: A documented motion/interaction spec defines what animates, why, which token, and reduced-motion behavior, including an antipattern list grounded in researched best practice.
- [ ] **MOT-02**: Drawers, dropdowns, the command palette, tabs, flash/toasts, and skeleton→content transitions animate via design-token transition bundles — functional, not decorative.
- [ ] **MOT-03**: All admin motion honors `prefers-reduced-motion` (no travel/overshoot; crossfades retained), verified by an automated check.

### Seed Expressiveness & State Coverage (SEED) — Phase 178 (E)

- [ ] **SEED-01**: Every admin screen's empty, populated, overflow/pagination, error, and loading states are reachable from seeded data on a single click-through.
- [ ] **SEED-02**: Edge states (dunning/at-risk, multi-currency, long strings, dark-only contrast traps) each have a seeded instance; no screen looks good only with hand-picked IDs.

### Visual-QA Loop & Sign-off (QA) — Phase 179 (F)

- [ ] **QA-01**: The Playwright screenshot harness sweeps the full screen inventory (all ~20 screens incl. detail pages) across {desktop, mobile} × {light, dark}.
- [ ] **QA-02**: An LLM-analysis step scores each screenshot against the 10-dimension rubric and emits structured findings (screen, dimension, score, defect, suggested fix).
- [ ] **QA-03**: A final scorecard shows every dimension ≥2 across all four matrix cells with before/after evidence, and axe passes in both light and dark themes.

## Out of Scope

Broad feature milestones remain closed by default unless reopened by a concrete adopter
failure mode, correctness/security/data-loss risk, repeated support issue, operational
failure, or explicit strategy change. Historical backlog anchors and deferred seeds are
tracked as non-active planning context in `.planning/ROADMAP.md`.

**v1.51-specific exclusions:** no Tailwind migration (double down on custom `ax-*` CSS + tokens);
no churn on frozen screens (Home, primary nav, global search) absent a rubric-flagged regression;
the demo/host app (`examples/accrue_host`) UI is not a design target (only the screenshot substrate);
no new billing primitives; no breaking changes (route reshaping ships with redirects, component
public APIs stay backward-compatible).
