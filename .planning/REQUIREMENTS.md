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

## Milestone v1.53 Requirements — Admin UI Design-System Hardening (shipped & archived 2026-06-20)

Shipped 33/33 (FND-01..06, CMP-01..05, GRP-01..04, IXN-01..05, PAGE-01..04, CPY-01..03,
SEED-01..02, VER-01..04) across Phases 187–192. Archived to
`.planning/milestones/v1.53-REQUIREMENTS.md`; validated summary in `PROJECT.md`.

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
