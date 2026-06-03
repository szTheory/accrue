# Requirements: Accrue

Standing, posture-level requirements that persist between milestones. Milestone-specific
requirements are added here when a milestone is opened (see `.planning/ROADMAP.md`).
Accrue is in **stable core / demand-driven expansion** posture; broad feature milestones
remain closed by default per the post-v1.48 pause rule.

## Stable-Core Positioning

- [x] **POS-01**: Developer evaluating Accrue can read the public docs and package READMEs and understand that Accrue is stable-core / demand-driven expansion, not a broad feature-chasing billing product.
- [x] **POS-02**: Developer adopting Accrue can see the complete supported SaaS billing loop, processor support boundaries, and package ownership boundaries without reading planning internals.
- [x] **POS-03**: Maintainer can verify that release notes, package docs, support matrix, adoption proof docs, and planning mirrors all describe the same stable-core posture.

## Milestone v1.50 Requirements — Admin UI Foundation

A deliberate quality/polish + adopter-facing DX investment in the already-shipped
`accrue_admin` UI. **Not a broad feature milestone** — no new billing primitives; it
raises the design-system, information-architecture, and usability baseline of an existing
surface, justified as adopter-facing DX per the post-v1.48 pause rule.

- [ ] **AUI-01**: Operator sees a tightened, consistent design system — crisp radii, restrained shadows, a complete spacing scale, a distinct `--ax-info` color, money-state semantics, and token-based motion — with zero surfaces bypassing the token system (dunning banner + invoice inline styles fixed).
- [ ] **AUI-02**: Admin UI has a distinct brand identity via self-hosted display + body typefaces (tabular numerals on all figures), a heroicons inline-SVG icon system, and a favicon.
- [ ] **AUI-03**: Operator landing on the admin home gets a uk.gov-style task-launcher start page (attention rail → task launchers → demoted KPIs), a job-aligned nav regroup (Billing / Recovery / Developer / Catalog / Connect, eyebrow sublabels dropped), and an always-on `Cmd-K` global search with recents/pins.
- [ ] **AUI-04**: Operator can thread between related resources from every detail screen with no dead ends (`Customer ⇄ Subscription ⇄ Invoice ⇄ Charge ⇄ Event`), path-aware breadcrumbs, and plain-language glosses for domain jargon.
- [ ] **AUI-05**: Detail screens are composed from shared `<.detail_section>` components (the 6 large screens refactored); skeleton/loading states and entity-specific empty states exist; overlapping badge systems are consolidated.
- [ ] **AUI-06**: Seed data fully expresses every admin screen (past-due/dunning campaigns, refunds, varied invoice statuses, coupons/promo codes in use, richer Connect states); the pre-existing host seed dunning-event bug is fixed; the component kitchen exercises every component × every state.
- [ ] **AUI-07**: A 10-dimension visual/UX rubric audit passes across all screens and components, with screenshot coverage of all ~20 screens (desktop + mobile + dark) and automated axe a11y wired into the admin e2e.

## Out of Scope

Broad feature milestones remain closed by default unless reopened by a concrete adopter
failure mode, correctness/security/data-loss risk, repeated support issue, operational
failure, or explicit strategy change. Historical backlog anchors and deferred seeds are
tracked as non-active planning context in `.planning/ROADMAP.md`.
