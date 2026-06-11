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

## Milestone v1.52 Requirements — Brand System

Pressure-test the brand book seed, run a user-judged SVG logo tournament to a locked winner,
and ship a committed, self-contained `brandbook/` (standalone HTML brand book, full SVG logo
system, design tokens, voice/microcopy/marketing copy). **Not a broad feature milestone** (no
billing primitives) — brand/DX investment in adopter-facing presentation surfaces; reopen
decision recorded in `PROJECT.md`. Design source: `.planning/research/v1.52-brand-system-design.md`.

**Hard logo constraints (binding on every candidate):** no rectangular background/container
shape behind the mark; logotype optically close to the mark; main lockup carries no subtitle
(separate with-subtitle variant ships); fully-integrated custom typemark options required.
**Seed latitude is evidence-gated:** Geist + existing palette are defaults; changes require a
cited failure (contrast, distinctiveness, 16px rendering) and user ratification.

### Brand Audit & DNA (AUD) — Phase 180

- [ ] **AUD-01**: Maintainer can read a 14-section pressure-test audit of `prompts/accrue-brand-book.md` where every verdict is tagged KEEP/TIGHTEN/REWORK/ADD/REMOVE with a cited justification — no churn without a cited failure.
- [ ] **AUD-02**: Maintainer ratifies a locked `BRAND-DNA.md` and a binding logo design brief (including the 4 hard logo constraints) at an explicit checkpoint before any logo work begins.
- [ ] **AUD-03**: Any proposed palette or font change cites a concrete failure (contrast, distinctiveness, 16px rendering) and is user-ratified at the audit checkpoint.

### Logo Tournament & System (LOGO) — Phases 181–183

- [ ] **LOGO-01**: A reproducible SVG generation pipeline emits exact Geist letterform outlines (opentype.js, one path per glyph) and runs automated pre-gate lints — valid SVG parse, no-rect-background, lockup gap ratio within spec, 16px legibility screenshot, monochrome derivable, no subtitle in main lockup — before any candidate reaches the user.
- [ ] **LOGO-02**: User picks 1–3 round-1 winners from a self-contained, file://-openable HTML gallery of 12–16 candidates across 4 conceptual directions (accumulation strata, stepped interval, layered arcs, fully-integrated typemarks), each rendered in a fixed context matrix (paper-light, ink-dark, 32px + 16px favicon, avatar circle-crop, README header, social card, monochrome).
- [ ] **LOGO-03**: Refinement rounds iterate on winners via a monotonic `TOURNAMENT.md` feedback ledger (verdicts recorded verbatim, constraints never re-litigated) until the user locks one winner — default 3-round cap with an explicit extend-or-settle question.
- [ ] **LOGO-04**: The locked winner is derived into a complete committed logo system in `brandbook/logo/` — primary lockup, integrated typemark, icon-only mark, monochrome positive/negative, dark/light versions, favicon (SVG/.ico/PNG), social card (SVG + PNG), with-subtitle variant, clearspace/minimum-size spec sheet — all finals outlined paths (no text elements), svgo-optimized, with accessible title/desc and OFL provenance documented.

### Design Tokens & Specimens (TOK) — Phase 184

- [ ] **TOK-01**: `brandbook/tokens/tokens.json` and `tokens.css` define raw palette, semantic color roles, typography, spacing, radius, focus-ring, and state tokens per the audit token spec.
- [ ] **TOK-02**: An automated consistency check verifies brandbook token values against the admin `ax-*` SSOT in `accrue_admin/assets/css/theme.css`, with the mapping documented — zero admin code changes this milestone.
- [ ] **TOK-03**: Palette and typography specimen artifacts exist in `brandbook/examples/`.

### Voice, Microcopy & Marketing Copy (COPY) — Phase 185

- [ ] **COPY-01**: A committed voice system defines voice principles, tone sliders, vocabulary to use/avoid, and say-this/not-this examples consistent with the ratified brand DNA.
- [ ] **COPY-02**: Ready-to-paste copy blocks exist for GitHub repo description + topics, Hex.pm package description, HexDocs intro, README hero, landing-page sections (hero/problem/solution/install/benefits/comparison/CTAs), release-note templates, and error/empty/success-state microcopy — reviewed by the user in one batch.

### HTML Brand Book & Quality Gate (BOOK) — Phase 186

- [ ] **BOOK-01**: `brandbook/index.html` is a self-contained, professional, standalone brand book — inline CSS from the v1.52 tokens, inlined SVGs, zero build step, zero JS frameworks, file://-openable — consuming the audit structure, logo system, tokens/specimens, and voice/copy.
- [ ] **BOOK-02**: The committed `brandbook/` passes the Phase-180 quality-gate checklist, stays within a ≤2 MB size budget, and passes final human UAT.

## Traceability — v1.52 Brand System

Filled by the roadmap. Coverage target: 14/14, each REQ-ID mapped to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUD-01 | Phase 180 | Pending |
| AUD-02 | Phase 180 | Pending |
| AUD-03 | Phase 180 | Pending |
| LOGO-01 | Phase 181 | Pending |
| LOGO-02 | Phase 181 | Pending |
| LOGO-03 | Phase 182 | Pending |
| LOGO-04 | Phase 183 | Pending |
| TOK-01 | Phase 184 | Pending |
| TOK-02 | Phase 184 | Pending |
| TOK-03 | Phase 184 | Pending |
| COPY-01 | Phase 185 | Pending |
| COPY-02 | Phase 185 | Pending |
| BOOK-01 | Phase 186 | Pending |
| BOOK-02 | Phase 186 | Pending |

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
