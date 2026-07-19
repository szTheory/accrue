# Phase 205: Persona + design-lens evaluator harness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-03
**Phase:** 205-persona-design-lens-evaluator-harness
**Areas discussed:** Claim-key composition, region_tag vocabulary, Finding emission model, Exemplar set sourcing

Process note: the user selected all four gray areas and directed a deep, parallel, subagent-backed
research pass (pros/cons/tradeoffs, lessons from real systems, DX/determinism/IA + creative-direction
lenses) synthesized into one cohesive recommendation set — "one-shot a perfect answer." Four
`gsd-advisor-researcher` subagents ran in parallel; the synthesis was reconciled and approved for
locking without per-decision back-and-forth (nothing here is irreversible or user-facing).

---

## Claim-key composition

| Option | Description | Selected |
|--------|-------------|----------|
| A. Coarse, bucket dropped entirely | `sha256(surface__dNN__region__ov-…)`; fewest flake vectors, lumpier digest | |
| B. Coarse identity + bucket as NON-identity annotation | Same key as A; `defect_bucket` (closed dim-scoped enum) carried for digest sub-grouping only | ✓ |
| C. Granular, bucket IN the key | Distinct same-cell defects stay separate ids, but adds a model-chosen identity axis → DEDUP-02 flake + conflicts DEDUP-01 | |
| D. Post-hoc keyword classifier → bucket | Reintroduces prose into identity through the back door | |

**User's choice:** Option B (via approved synthesis).
**Notes:** Resolves the ROADMAP/DEDUP-01 (coarse, ratified) vs design-doc (`+normalized_defect_bucket`)
conflict in favor of the ratified requirement. Key gate-semantics insight: coarse identity does NOT
hide a second defect — re-shoot re-emits the same coarse key so the finding stays `open` until all
matching defects are gone. Over-collapse is a digest cost, never a correctness bug. DEDUP-02 proven by
a pure `--self-test` fixture block (no live API), twinning `phase200-scorecard.mjs`'s `runSelfTest()`.

---

## region_tag vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Closed-enum constrained output | Model returns one of N; simple, screenshot-only | partial |
| (b) Harness derives region from coordinates/DOM | Model can't emit stable pixel boxes from PNGs; jitter → unstable identity | |
| (c) Hybrid — per-surface enum subset + Playwright geometry for overlay/cross-check only | Small choice set → max stability; selector-anchored overlay for free; geometry never in identity | ✓ |

**User's choice:** Option (c) hybrid (via approved synthesis).
**Notes:** 14-value closed enum anchored to real `ax-*` selectors, viewport/theme-agnostic,
`content-body` fallback, `layer` (not "overlay") for floating layers. No `empty-state` region (empty is
a state). Per-surface allowed subset (5–8) + synonym normalization + coerce-to-`content-body` on miss.
Strongest precedent = ARIA landmark roles (small disjoint closed set + generic escape hatch); anti-
pattern = Figma free-text layer names.

---

## Finding emission model

| Option | Description | Selected |
|--------|-------------|----------|
| Keep scorecard (exactly 12 rows/image, 0–3) | Positive coverage signal; but padding + no adversarial framing; census already does this | |
| Defect-only candidates, LAYERED ON the census (FK via cell_refs) | Variable 0..N blockers; census stays as ≥2 floor; cleaner worklist | ✓ |
| Replace the census entirely | Forfeits the CONV-01 ≥2 floor proof | |

**User's choice:** Defect-only, layered (via approved synthesis).
**Notes:** Severity = 2-level `{minor, real}` spoken identically proposer→verifier→ledger (verifier only
downgrades/kills) + orthogonal `job_blocking` boolean; inverted 0–3 stays in the census layer.
Mandatory `justification_token` enforced by a deterministic parse-time gate (token check + enum
validation + taste denylist + cap N=12/image). Full `candidates.ndjson` schema locked. Lessons from
ESLint/axe/RuboCop/Nielsen/SARIF/LLM-judge: identity from closed coordinates, message disposable, low
severity cardinality, comparative > absolute, justification curbs sycophancy.

---

## Exemplar set sourcing

| Option | Description | Selected |
|--------|-------------|----------|
| Doc-only (not sent to model) | Weakest comparative-score stability | |
| Full N-exemplar gallery every call | Payload bloat, diminishing returns past ~2 | |
| Hybrid: fixed archetype-matched good+bad pair inline few-shot + documented in rubric | Strongest practical stability; constant committed bytes; suppresses density footgun | ✓ |

**User's choice:** Hybrid (via approved synthesis).
**Notes:** DISCOVERY — zero admin PNGs ever committed to git, so Phase 205 needs a capture-and-curate
step (old-SHA re-capture for the "rough" bad; patch-shoot-revert for the "wasteful" bad). Committed set
= Accrue-own-only, 5 images (2 good + 3 bad covering BOTH density poles). External tiers stay textual.
BRAND CORRECTION: drop Stripe as a brand-positive exemplar (fintech; conflicts dim-8 + voice.md) — cite
only as density/IA reference. Rubric anchored to CURRENT `brandbook/` (supersedes old
`prompts/accrue-brand-book.md`). `direction: air|cramped` self-flag routes air-ward findings to a higher
206 verifier bar. `PROVENANCE.json` for auditability; version-pinned, no auto-drift.

## Claude's Discretion

- Exact `candidates.ndjson` field ordering, per-dimension `defect_bucket` sub-enum values, synonym-table
  entries, per-surface `allowed_subset` map contents, file layout under `e2e/ratchet/`.
- Whether the region SSOT is a new `ratchet/region-tags.js` vs an addition to `baseline-manifest.js`.

## Deferred Ideas

- DEDUP-03 persona-frequency collapse; adversarial verifier + ledger + gate + suppress-list (Phase 206).
- Orchestration `mix accrue_admin.ui.round`/`ui.fix` + HTML digest + region overlay + decision queue (Phase 207).
- CI `admin-ui-ratchet-guardrails` + convergence proof + ACCEPT (Phase 208).
- Full ~19-surface sweep (Phase 209, optional/scope-gated).
