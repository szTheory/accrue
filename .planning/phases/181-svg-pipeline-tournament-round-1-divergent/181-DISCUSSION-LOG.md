# Phase 181: SVG Pipeline + Tournament Round 1 — Divergent - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-11
**Phase:** 181-SVG Pipeline + Tournament Round 1 — Divergent
**Areas discussed:** Generation approach, Gate-failure & curation policy, Legibility & self-review judging, Verdict capture mechanics

Advisor mode active (calibration tier: `minimal_decisive`). Each area was researched by a parallel gsd-advisor-researcher agent; comparison tables presented before selection. All four selections matched the researched recommendation.

---

## Generation approach

| Option | Description | Selected |
|--------|-------------|----------|
| Per-direction mini-generators (hybrid parametric) | 4 small parametric geometry modules + shared lockup/lint/Geist spine; Phase 182 variations become parameter re-renders; direction D gets bespoke glyph surgery on top | ✓ |
| Hand-authored per candidate | Max round-1 creative range; shared helpers for lockup/typography only; Phase 182 refinement becomes manual path editing | |

**User's choice:** Per-direction mini-generators (Recommended)
**Notes:** Research rationale — Phase 182's mandate sweeps exactly the dimensions a parametric model exposes (weight, motif amplitude, lockup spacing/kerning, terminals); per-direction generators neutralize the sameness risk of one shared generator.

---

## Gate-failure & curation policy

| Option | Description | Selected |
|--------|-------------|----------|
| Overgenerate + cull | 20–24 raw → gates + self-scoring cull to best 12–16, ≥3-per-direction floor with capped regeneration; rejects preserved with failure/score reasons | ✓ |
| Exact count, fix-until-pass | Generate exactly the target; iterate repairs per candidate until all lints pass; self-scoring only annotates | |

**User's choice:** Overgenerate + cull (Recommended)
**Notes:** Fix-until-pass rejected because repair loops homogenize a divergent round; culling makes "no lint failure reaches the user" structural rather than best-effort.

---

## Legibility & self-review judging

| Option | Description | Selected |
|--------|-------------|----------|
| Split judge | Deterministic pixel heuristic (pngjs) for the 16px gate; agent vision self-review with fixed rubric (0–3 NDJSON, score-visuals.mjs conventions) for quality scoring | ✓ |
| Uniform LLM judge | Extend score-visuals.mjs pattern to score both gate and self-review via @anthropic-ai/sdk; nondeterministic gate, needs API key | |

**User's choice:** Split judge (Recommended)
**Notes:** Principle recorded: lint = deterministic, review = judged. LLM gate rejected for nondeterminism + silent key-absent degradation in a "reproducible harness."

---

## Verdict capture mechanics

| Option | Description | Selected |
|--------|-------------|----------|
| Interactive gallery | Checkboxes + notes textareas + copy-verdict-block button (vanilla JS, file://-openable); emitted block matches TOURNAMENT.md schema, agent appends unmodified | ✓ |
| Static gallery + chat verdicts | User replies at checkpoint conversationally; agent transcribes verbatim into TOURNAMENT.md | |

**User's choice:** Interactive gallery (Recommended)
**Notes:** Verbatim-by-construction beats transcription for a ledger Phase 182 treats as law. Schema includes explicit kill list and agent-extracted, user-confirmed `R1-C{n}` constraint IDs separate from verbatim prose.

---

## Claude's Discretion

- Knob set per direction generator; harness module layout.
- Pixel-heuristic thresholds for the 16px lint; exact lockup gap-ratio spec value.
- Geist sourcing (vercel/geist TTF primary; woff2→TTF fallback per design source).
- Exact `.planning/` location for harness/gallery/TOURNAMENT.md (must be stable across Phases 181–183).
- Plan breakdown (~5 plans per design source).

## Deferred Ideas

None — discussion stayed within phase scope.
