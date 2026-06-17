# Requirements: Accrue

Standing, posture-level requirements that persist between milestones. Milestone-specific
requirements are added here when a milestone is opened (see `.planning/ROADMAP.md`).
Accrue is in **stable core / demand-driven expansion** posture; broad feature milestones
remain closed by default per the post-v1.48 pause rule.

## Stable-Core Positioning

- [x] **POS-01**: Developer evaluating Accrue can read the public docs and package READMEs and understand that Accrue is stable-core / demand-driven expansion, not a broad feature-chasing billing product.
- [x] **POS-02**: Developer adopting Accrue can see the complete supported SaaS billing loop, processor support boundaries, and package ownership boundaries without reading planning internals.
- [x] **POS-03**: Maintainer can verify that release notes, package docs, support matrix, adoption proof docs, and planning mirrors all describe the same stable-core posture.

## Milestone v1.50 Requirements — Admin UI Foundation (shipped 2026-06-02; archived 2026-06-03)

Shipped 7/7 (AUI-01..07). Archived to `.planning/milestones/v1.50-REQUIREMENTS.md`; validated summary in `PROJECT.md`.

## Milestone v1.51 Requirements — Admin UI: Depth Pass (shipped & archived 2026-06-04)

Shipped 22/22 (DSY-01..03, IA-01..07, SCR-01..04, MOT-01..03, SEED-01..02, QA-01..03).
Archived to `.planning/milestones/v1.51-REQUIREMENTS.md`; validated summary in `PROJECT.md`.

## Milestone v1.52 Requirements — Brand System (shipped & archived 2026-06-14)

Shipped 14/14 (AUD-01..03, LOGO-01..04, TOK-01..03, COPY-01..02, BOOK-01..02) across Phases
180–186. Archived to `.planning/milestones/v1.52-REQUIREMENTS.md`; validated summary in `PROJECT.md`.

## Milestone v1.53 Requirements — Admin UI Design-System Hardening (OPEN; Phases 187–192)

**Defined:** 2026-06-14. Reopened under the post-v1.48 pause rule (explicit strategy change +
firsthand-observed interaction defects; recorded in `PROJECT.md`). Hardening pass on the
`accrue_admin` operator UI: fractal design-system audit (foundations → primitives → groups →
pages → flows), interaction-defect remediation, component-level systematization, idempotent
only-forward verification. **"User"** = the operator using the UI, the maintainer extending it,
and the contributor working in the component system. 33 requirements across 8 themes.

### FND — Foundations (tokens, layers, type, dark mode)

- [x] **FND-01**: Composed typography bundles exist as tokens (family + size + weight + line-height + tracking) and primitives consume them instead of ad-hoc per-property utility soup.
- [x] **FND-02**: A formal z-index/layer system (base → sticky → dropdown → popover → drawer → modal → toast) is tokenized; every overlay and sticky element references it and no ad-hoc z-index literals remain.
- [x] **FND-03**: The reading-measure token (`--ax-measure`) is applied to prose and dense surfaces so long text and wide tables stay readable at every breakpoint.
- [x] **FND-04**: The inert Tailwind config is resolved (removed or explicitly documented as reference-only) so there is one unambiguous styling source of truth.
- [x] **FND-05**: Every semantic role — including focus rings, scrollbars, and disabled states — has a correct, contrast-passing value in both light and dark (no role renders wrong or invisible in dark mode).
- [x] **FND-06**: Motion-token coverage is complete for every animated surface, with `prefers-reduced-motion` collapsing travel/overshoot while preserving crossfades.

### CMP — Component systematization (the "Storybook lens")

- [x] **CMP-01**: Every component is exercised in the `/dev/components` lab across its full state matrix (default / hover / focus / active / pressed / disabled / loading / selected / empty / error / overflow) in both light and dark.
- [x] **CMP-02**: Each component renders correctly with long/overflowing content (long IDs, names, URLs, module names) without clipping, overlap, or layout break.
- [ ] **CMP-03**: Each interactive component has the correct accessible role, full keyboard operation, visible focus, and accessible name; non-interactive elements expose no misleading affordances (e.g. no hover state on empty-state heroes).
- [ ] **CMP-04**: Disabled and read-only states are visually unmistakable (disabled looks disabled; enabled never looks disabled), and button text never collides with its background color.
- [ ] **CMP-05**: Component-level visual/brand fixes are made at the component root so they propagate to every consuming page (no per-page patching).

### GRP — Meta-component cohesion (groups of components)

- [ ] **GRP-01**: Each recurring component group (page-header + actions + breadcrumbs; toolbar + search + filters + sort; table + empty/loading/error/pagination; KPI + chart + table; detail-header + metadata + actions; modal-confirm; drawer + form; tabs + subviews) is audited as a unit for spacing rhythm, hierarchy, and obvious next action.
- [ ] **GRP-02**: Tables degrade to readable cards/lists (not squished columns) at narrow widths, and tables are not used where a list/card pattern fits the data better.
- [ ] **GRP-03**: Nested containers do not read as an accidental "box prison," and stat/KPI cards are visually consistent across every screen.
- [ ] **GRP-04**: Pagination and similar affordances disappear or de-emphasize when there is nothing to paginate; filter/sort/active/selected states are unmistakable.

### IXN — Interaction integrity (the defects screenshots miss)

- [ ] **IXN-01**: Every modal and drawer renders above its scrim and is fully visible and interactive (never hidden behind the overlay), traps focus, restores focus to its trigger on close, and dismisses predictably via Escape and click-outside.
- [ ] **IXN-02**: Scrolling works correctly on every page and container — no scroll traps, no nested-scroll dead-ends, no content left unreachable behind sticky regions.
- [ ] **IXN-03**: Focus is never lost or hidden after a LiveView patch, and keyboard-only operation completes every primary flow.
- [ ] **IXN-04**: Floating/overlay elements (dropdowns, popovers, tooltips, toasts) appear in the correct position relative to their trigger and never obscure the controls they relate to.
- [ ] **IXN-05**: Each interaction defect recorded in the Phase-187 ledger is fixed and covered by a regression test so it cannot silently return.

### PAGE — Page/flow JTBD coverage

- [ ] **PAGE-01**: Every admin page is walked against its primary persona/JTBD across happy, empty, loading, error, permission-denied, boundary, and advanced paths, and renders correctly in each.
- [ ] **PAGE-02**: Empty states explain the next useful action and distinguish "no data" from "data unavailable" from "permission denied."
- [ ] **PAGE-03**: LiveView disconnected/reconnecting state is communicated to the operator and disables actions that cannot be performed while stale.
- [ ] **PAGE-04**: Every page is verified at 320 / 375 / 768 / 1024 / 1440 widths in light and dark with no layout break, clipping, or off-screen content.

### CPY — Microcopy

- [ ] **CPY-01**: Error messages state what happened and how to recover (no bare "oops / invalid / failed / forbidden").
- [ ] **CPY-02**: Destructive-action confirmations name the specific object and its consequence.
- [ ] **CPY-03**: Domain vocabulary is consistent across headings, tabs, filters, buttons, and alerts.

### SEED — Fixture stress (exercise the matrix)

- [ ] **SEED-01**: `examples/accrue_host` seeds reach every matrix cell in one click — null/missing optional fields, permission-denied, boundary pagination, high counts, non-ASCII names, and disconnected/reconnecting state — in addition to the existing long-name / multi-currency / dunning edge states.
- [ ] **SEED-02**: Seed expansion is idempotent (re-runnable) and deterministic, consistent with the existing keyed-insert seed contract.

### VER — Idempotent verification & sign-off

- [x] **VER-01**: A severity-ranked defect ledger plus a scored baseline (the refreshed rubric across viewport × theme × state, including live interaction testing) exists and is the only-forward reference point.
- [ ] **VER-02**: Each level (component / group / page) is scored by an adversarial multi-lens judge (correctness, a11y, brand, interaction), and the final scorecard is ≥ baseline on every dimension/cell with zero regressions.
- [ ] **VER-03**: Regression guardrails (interaction e2e, axe a11y, reduced-motion, and a component-lab coverage check) run in CI so re-running the milestone only ever finds new gaps.
- [ ] **VER-04**: The maintainer signs off on screenshots at each phase boundary, closing v1.51's open photographic-sign-off tech-debt.

### v1.53 Traceability (finalized by the roadmapper 2026-06-14)

| Requirement | Phase | Status |
|-------------|-------|--------|
| VER-01 | 187 | Complete |
| FND-01 | 188 | Complete |
| FND-02 | 188 | Complete |
| FND-03 | 188 | Complete |
| FND-04 | 188 | Complete |
| FND-05 | 188 | Complete |
| FND-06 | 188 | Complete |
| CMP-01 | 189 | Complete |
| CMP-02 | 189 | Complete |
| CMP-03 | 189 | Pending |
| CMP-04 | 189 | Pending |
| CMP-05 | 189 | Pending |
| GRP-01 | 190 | Pending |
| GRP-02 | 190 | Pending |
| GRP-03 | 190 | Pending |
| GRP-04 | 190 | Pending |
| IXN-01 | 191 | Pending |
| IXN-02 | 191 | Pending |
| IXN-03 | 191 | Pending |
| IXN-04 | 191 | Pending |
| IXN-05 | 191 | Pending |
| PAGE-01 | 191 | Pending |
| PAGE-02 | 191 | Pending |
| PAGE-03 | 191 | Pending |
| PAGE-04 | 191 | Pending |
| CPY-01 | 191 | Pending |
| CPY-02 | 191 | Pending |
| CPY-03 | 191 | Pending |
| SEED-01 | 191 | Pending |
| SEED-02 | 191 | Pending |
| VER-02 | 192 | Pending |
| VER-03 | 192 | Pending |
| VER-04 | 192 | Pending |

**Coverage:** 33 v1 requirements · 33 mapped · 0 unmapped ✓

Per-phase counts: 187 → 1 (VER-01) · 188 → 6 (FND-01..06) · 189 → 5 (CMP-01..05) ·
190 → 4 (GRP-01..04) · 191 → 14 (IXN-01..05 · PAGE-01..04 · CPY-01..03 · SEED-01..02) ·
192 → 3 (VER-02..04). Total = 1 + 6 + 5 + 4 + 14 + 3 = 33. No requirement maps to two phases.

### v1.53 Deferred (v2)

- **TOOL-01**: Adopt PhoenixStorybook (deferred — v1.53 extends the in-app `/dev/components` kitchen to avoid a shipped-lib dependency).
- **TOOL-02**: Pixel-diff visual-regression tooling (Percy/Applitools-style) replacing the screenshot + adversarial-judge loop.
- **TOOL-03**: Publish `brandbook/tokens/tokens.css` as a standalone distributable (npm/CDN) for external doc/marketing-site consumption.

## Out of Scope

Broad feature milestones remain closed by default unless reopened by a concrete adopter
failure mode, correctness/security/data-loss risk, repeated support issue, operational
failure, or explicit strategy change. Historical backlog anchors and deferred seeds are
tracked as non-active planning context in `.planning/ROADMAP.md`.

**v1.52-specific exclusions:** no admin `ax-*` token changes (admin `theme.css` stays SSOT;
brandbook documents the brand layer); no PDF brand book; no website/landing-page build (copy
blocks only); no binary-heavy assets beyond platform-required PNG/.ico; exploration artifacts
(galleries, rejected candidates, tournament ledger) stay in `.planning/`, not `brandbook/`;
no new billing primitives; no breaking changes.

**v1.53-specific exclusions:** no Tailwind *migration* (custom `ax-*` CSS + tokens stay SSOT;
FND-04 is a *resolution* of the inert config, not a migration); no new billing primitives or
domain features (no new package code expected); no breaking API/route changes (internal moves
ship with redirects, component public APIs stay backward-compatible); no PhoenixStorybook
dependency (extend the in-app `/dev/components` kitchen — deferred as TOOL-01); no demo/host
chrome redesign (`examples/accrue_host` UI is not a design target — only its seed/fixture data,
SEED-01/02); no `accrue_portal` work (separate package); no re-churn of the v1.51 motion spec or
v1.52 brand tokens absent a rubric regression or new interaction pattern.
</content>
