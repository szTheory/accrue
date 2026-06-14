# Phase 184: Design Tokens & Specimens - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 184-design-tokens-specimens
**Areas discussed:** tokens.json schema & SSOT, consistency-check script, token vocabulary scope, specimen artifacts

**Mode:** Advisor / cohesive one-shot synthesis (per standing user preference `feedback_decision_synthesis_style`). Four parallel `gsd-advisor-researcher` agents researched the coupled gray areas; results synthesized into a single coherent decision package. No gray area met the surface-a-fork bar (all four flagged `high-impact-fork = FALSE` — internal, reversible tooling, no published API). No multiple-choice questions were put to the user; decisions are locked defaults for sanity-check at CONTEXT/PR review.

---

## tokens.json schema & SSOT model

| Option | Description | Selected |
|--------|-------------|----------|
| DTCG-lite source + tiny `.mjs` generator → tokens.css | Hand-maintained DTCG-shaped JSON is SSOT; ~60-line Node harness generates CSS; `git diff --exit-code` gate | ✓ |
| Style Dictionary | Canonical DTCG → CSS via toolchain | (rejected: ~4.4 MB + 13 deps, hostile to buildless ≤2 MB milestone) |
| Two hand-authored files + parity check | json and css both primary; check enforces match | (rejected: keeps structural drift, builds mapping logic anyway) |
| Flat/custom JSON → generator | Non-DTCG pragmatic schema | (rejected: loses the interop that justifies a JSON sibling) |

**User's choice:** Auto-decided — DTCG (stable v2025.10) `tokens.json` as SSOT, generates `tokens.css` via small `.mjs`; no Style Dictionary.
**Notes:** DTCG reached first stable version Oct 2025, so conformance is no longer a moving target. Primer's "JSON source → generated CSS" is the exemplar. ax-mapping encoded in `$extensions`.

---

## Consistency-check script

| Option | Description | Selected |
|--------|-------------|----------|
| Node `.mjs` + postcss + culori, divergence via `$extensions` | Reuses harness convention; AST parsing + color normalization | ✓ |
| Elixir mix task / ExUnit, hand-rolled CSS scan | Idiomatic for repo, but DIY normalization is the footgun | (rejected) |
| POSIX shell + grep/awk | Zero deps but cannot parse var()/color-mix/hex-case reliably | (rejected) |

**User's choice:** Auto-decided — Node `.mjs`, `postcss-value-parser` + `culori`, divergence declared in `tokens.json` `$extensions["accrue.parity"]`, live derivation from theme.css (no snapshot), exit non-zero on undocumented drift.
**Notes:** Parity scope reconciled across two advisors — check compares *resolved concrete values* keyed by ax-map in both light and dark; light uses `var()` indirection, dark compares value-to-value; brand-only tokens skipped.

---

## Token vocabulary scope & brand↔ax mapping

| Option | Description | Selected |
|--------|-------------|----------|
| A. Minimal — 7 raw `--accrue-*` only | Smallest drift surface; semantic roles prose-only | (rejected: under-delivers §7) |
| B. Curated — raw 7 + palette-bearing semantic roles; scales by reference | Color roles duplicated+checked; type/space/radius referenced not re-declared | ✓ |
| C. Full mirror — duplicate every relevant `--ax-*` | Standalone but every value a drift liability vs read-only SSOT | (rejected) |

**User's choice:** Auto-decided — Option B. Real tokens = 7 raw + semantic color roles (surface/content/interactive/feedback/focus-ring), value-checked light+dark. Type/spacing/radius/state/motion documented by reference. Brand-only (fog, cobalt-raw, code-block, callout) marked null axMap.
**Notes:** Matches the primitive-vs-semantic split in Primer/Radix/Geist; keeps SC#2 meaningful but bounded; avoids a maintenance tax on a read-only SSOT.

---

## Specimen artifacts

| Option | Description | Selected |
|--------|-------------|----------|
| Generated SVG from tokens.json | `.mjs` emits palette/typography/spacing SVG; drift-free, diff-gated | ✓ |
| Generated HTML+inline-CSS fragments | Easier authoring but CSS-scope merge risk at Phase-186 inline | (rejected) |
| Hand-authored static SVG | Zero tooling but silently drifts on token change | (rejected) |

**User's choice:** Auto-decided — generated SVG; three files (`palette.svg`, `typography.svg`, `spacing.svg`); content checklists locked (swatches w/ hex+role+AA, type ramp w/ px+rem, spacing rulers).
**Notes:** SVG inlines cleanly into Phase-186's buildless `index.html`; generation keeps specimens in lockstep with tokens.

---

## Claude's Discretion

- DTCG group nesting / token naming and CSS var-name derivation.
- Whether specimen generators reuse logo-harness Geist/opentype.js for type-ramp metrics.
- `$extensions` namespace choice (single consistent namespace).
- Color-normalization tolerance (default exact canonical-form; epsilon only if forced).
- Prose mapping-table format for reference-only scales.
- Exact harness split (one shared `node_modules` install preferred; planner decides layout).

## Deferred Ideas

- Style Dictionary / multi-platform export — deferred, DTCG JSON keeps the door open.
- Minting `--accrue-*` tokens for spacing/radius/type scales — reference-only this phase.
- `examples/readme-header.svg` — belongs to Phase 185/186.
