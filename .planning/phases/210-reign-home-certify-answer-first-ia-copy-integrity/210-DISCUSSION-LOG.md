# Phase 210: Reign Home + certify answer-first IA & copy integrity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-19
**Phase:** 210-reign-home-certify-answer-first-ia-copy-integrity
**Areas discussed:** WorkQueueCallout extract-or-inline, Customer-search single control, Health verdict composition, Copy voice

---

## WorkQueueCallout — extract-or-inline (COMP-01, deferred from 209 D-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Keep both inline | Home's rail (ranked P1/P2/P3 exception list) and Subscriptions' worklist (at-risk card) differ too much; resolve COMP-01 as "inline" on both; avoid a speculative abstraction. Both stay on `.ax-card`. | ✓ |
| Extract shared WorkQueueCallout | Build the one permitted new component; both pages adopt it. Only if shapes converge. | |

**User's choice:** Keep both inline (Recommended)
**Notes:** Milestone adds zero new shared components. Captured as D-01.

---

## Customer-search — which single control survives & where (IA-02 / COPY-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Fold into PageHeader :actions; drop strip + tile | Single command-palette lookup in header actions (matches 209 grammar); removes strip section + launcher tile → 3 tiles. Reads SC1 "four" as descriptive, SC2 as binding. | ✓ |
| Keep as launcher tile; drop strip + header CTA | Customer tile stays as the single control (keeps 4 tiles); header has no customer action. | |
| Header action + repurpose 4th tile | Fold to header AND invent a new fourth tile. More invention than a reign warrants. | |

**User's choice:** Fold into PageHeader :actions; drop strip + tile (Recommended)
**Notes:** Consequence flagged: ROADMAP SC1 "four launcher tiles" is superseded to three (D-02a) — planner/verifier must not flag the tile-count drop as a regression.

---

## Health verdict — placement & relation to kept KpiCard band (IA-01 / IA-04)

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror Subscriptions: StatusBadge + StatStrip in PageHeader | One verdict = StatusBadge + exposure-first StatStrip in header (209 D-03 parity); drop h1 verdict-sentence + attention-rail summary; keep KpiCard band as the drill-down. | ✓ |
| Verdict as attention-rail heading only; plain header title | Header is a plain title; verdict lives as the rail heading. Diverges from 209 header-verdict grammar. | |

**User's choice:** Mirror Subscriptions: StatusBadge + StatStrip in PageHeader (Recommended)
**Notes:** No re-duplication vs the kept "At a glance" band — StatStrip = one-line answer, KPI band = drill-down (D-03/D-03a).

---

## Copy voice — how prescriptive now (COPY-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Set principles, defer exact strings to UI-SPEC/planner | Lock rules (no "workspace" jargon, sentence case, affirmative wording, all in `AccrueAdmin.Copy`); UI-SPEC/planner pins final strings. | ✓ |
| Pin exact replacement strings now | Decide literal final copy in-discussion. Slower, largely re-does UI-SPEC work. | |

**User's choice:** Set principles, defer exact strings to UI-SPEC/planner (Recommended)
**Notes:** Captured as D-04/D-04a.

---

## Claude's Discretion

- Exact `PageHeader` slot wiring, `StatStrip` stat structs/order, `.ax-card` rail recomposition, and the three-tile launcher rebuild — left to planner/executor within any `/gsd-ui-phase 210` UI-SPEC and cross-page parity with 209.
- Cleanup of now-dead helpers/markup unreachable after the collapse.
- Whether the density-no-regression proof needs a fresh PNG baseline vs reusing the pre-reign screenshot.

## Deferred Ideas

- CSS class deletion (`.ax-home-*`/`.ax-launcher*`/`.ax-attention*`/`.ax-health-summary*`) → Phase 211 (grep-gated).
- Component-kitchen / storybook / `region-tags.js` retired-vocabulary cleanup → Phase 211.
- SEED-004 M2 (why-blocked/causality diagnosis + core fns) and M3 (new rooms + ratchet re-freeze) → future milestones.
