---
phase: 205-persona-design-lens-evaluator-harness
plan: 01
subsystem: ratchet-identity-ssot
tags: [ratchet, dedup, claim-key, determinism, dev-test-only]
dependency_graph:
  requires: []
  provides:
    - "region-tags.js SSOT (REGION_TAGS/OVERLAY_TAGS/REGION_SELECTORS/ALLOWED_SUBSET/SYNONYM_TABLE)"
    - "pure claimKey()/findingId()/normalizeRegion()/normalizeOverlays()/assertDimension()/isAdmissibleToken()/slug()"
    - "runSelfTest() — key-free DEDUP-01/DEDUP-02 proof"
  affects:
    - "Phase 205 plans 02-05 (proposer CLI, design lens, bbox capture) import this module"
    - "Phase 206 verifier + ledger, Phase 207 digest consume the same SSOT"
tech_stack:
  added: []
  patterns:
    - "closed-enum identity re-derived by harness; model output advisory only (D-04/D-16)"
    - "pure fixture self-test twins phase200-scorecard.mjs (no key, no live model)"
    - "codepoint .sort() (never localeCompare); sentinels noregion/ov-none"
key_files:
  created:
    - accrue_admin/e2e/ratchet/region-tags.js
  modified: []
decisions:
  - "Reimplemented slug() byte-identically in region-tags.js rather than exporting it from the frozen baseline-manifest.js (D-10 lean; RESEARCH Pitfall 3 / Open Q1)"
  - "region-tags.js imports ONLY node:crypto — no baseline-manifest.js import — so slug-parity is asserted against reproduced manifest rules, keeping the self-test pure"
  - "GOLDEN_FINDING_ID pinned to f-15a8b227d09e0ea1, derived from the real findingId at authoring time"
metrics:
  duration: "4m 49s"
  completed: "2026-07-03"
  tasks: 2
  files: 1
status: complete
---

# Phase 205 Plan 01: Persona/Design-Lens Evaluator Harness — Identity SSOT Summary

Authored `accrue_admin/e2e/ratchet/region-tags.js`: the SDK-free, closed-enum identity SSOT plus the pure `claimKey()`/`findingId()`/normalizer functions the whole UI ratchet re-derives every identity field from, proven deterministic by a pure `runSelfTest()` that runs with no ANTHROPIC_API_KEY and no live model.

## What Was Built

- **Closed vocabularies (D-06/D-04):** `REGION_TAGS` (exact 14-value D-06 enum in order; `content-body` fallback, `layer` for floating layers), `OVERLAY_TAGS` (mirrors the 14 values from `baseline-manifest.js:29-44`), `REGION_SELECTORS` (region→`ax-*` map with `// TODO: confirm selector` markers where uncertain — null bbox is the safe fallback, never affects identity), `ALLOWED_SUBSET` (archetype→region-subset map per D-08), `SYNONYM_TABLE` (fixed alias→canonical map, never expands vocab).
- **Pure identity functions (D-01):** `slug()` (byte-identical reimpl of the frozen manifest, not imported), `claimKey()` (canonical `${slug(surface)}__d${NN}__${region||'noregion'}__ov-${sorted(overlays).join('+')||'none'}`), `findingId()` (`f-` + sha256 first-16-hex, matching `phase200-scorecard.mjs:238`), `normalizeRegion()` (subset→synonym→coerce `content-body`, never throws/invents), `normalizeOverlays()` (enum-throw + dedup + codepoint `.sort()`), `assertDimension()` (1..12 or throw), `isAdmissibleToken()` (D-16 justification-token gate), `allowedSubsetFor()`.
- **Self-test (D-05):** `assertSelfTest()` (verbatim from `phase200-scorecard.mjs:841`) + `runSelfTest()` covering all 7 DEDUP-02 assertion classes (idempotence, prose-independence, overlay order/dup invariance, empty-normalization, intended-distinctness negatives, closed-enum-throws, golden-hash snapshot) plus slug-parity. Standalone runner via `require.main === module`.

## Task Commits

| Task | Name | Type | Commit | Files |
| ---- | ---- | ---- | ------ | ----- |
| 1 | Closed-enum SSOT + pure claim-key/normalizer functions | feat | `2f0abb3a` | accrue_admin/e2e/ratchet/region-tags.js |
| 2 | runSelfTest — 7 DEDUP-02 classes + golden-hash + slug parity | test | `d56b02eb` | accrue_admin/e2e/ratchet/region-tags.js |

## Verification

- Task 1 verify command prints `ok` (claimKey canonical string, sentinel string, overlay-enum throw).
- `env -u ANTHROPIC_API_KEY node accrue_admin/e2e/ratchet/region-tags.js` → all 13 `self-test pass:` lines + final `ratchet-propose claim-key self-test passed.`, exit 0.
- No SDK/manifest import (module imports only `node:crypto`) — self-test is CI-safe and key-free (EVAL-03).
- Golden-hash discipline confirmed: a simulated separator break (`_` instead of `__`) flips `findingId` to `f-9bfcf9b313479af1` ≠ pinned `f-15a8b227d09e0ea1`, so any future grammar drift fails the assertion.
- Slug parity confirmed against the frozen `baseline-manifest.js` cell grammar (`cellId('subscription-detail',…)` embeds `subscription-detail` as its surface segment; `slug('subscription-detail')` matches).

## Requirements Delivered

- **DEDUP-01** (canonical claim-key from surface+dimension+sorted overlay-tags+region, prose excluded): fully delivered + golden-hash-locked.
- **DEDUP-02** (proposer twice → identical finding_id set, proven by an automated test): proven by the pure `runSelfTest()` — idempotence + prose-independence + the other 5 classes.
- **EVAL-05** (each candidate records surface/dimension/region_tag/overlay_tags/severity/raised_by/cell_refs): the identity-recording spine (surface, dimension, region_tag, overlay_tags, claim_key, finding_id derivation) is delivered here as the SSOT; the full `candidates.ndjson` row emission (severity/raised_by/cell_refs population) is completed by the proposer CLI in plans 03/04, which import this module.

## Deviations from Plan

None — plan executed exactly as written. `slug()`-not-exported (RESEARCH Pitfall 3) was anticipated by the plan and handled via byte-identical reimplementation with a self-test parity guard.

## Known Stubs

- `REGION_SELECTORS` carries `// TODO: confirm selector` markers for 9 of 14 `ax-*` selectors (RESEARCH Open Q2, explicitly non-blocking). These feed only the deferred Phase-207 overlay render + the optional Plan-05 presence cross-check; a wrong/absent selector yields a `null` bbox (safe fallback) and can NEVER affect `region_tag`/`claim_key` (identity is derived from model output via `normalizeRegion`, never from this map). Selector confirmation is a later low-risk touch-up, not phase-gating.

## Notes for Next Plans

- Plan 03/04 (`ratchet-propose.mjs`): `await import("./region-tags.js")` yields the CommonJS exports as the interop default; call `assertDimension` / `normalizeRegion` / `normalizeOverlays` / `claimKey` / `findingId` / `isAdmissibleToken` at the parse-time gate; never trust model-supplied `claim_key`/`finding_id`.
- The tool `input_schema` `region_tag` enum should be seeded from `allowedSubsetFor(surface)` (5–8 values per D-08); the harness still hard-validates (enum is advisory on Sonnet 4.5, RESEARCH Pitfall 2).
- `ALLOWED_SUBSET` detail archetype currently lists 13 regions (all object-detail regions); trim per surface if a tighter model choice-set is desired — non-identity, safe to adjust.

## Self-Check: PASSED

- FOUND: `accrue_admin/e2e/ratchet/region-tags.js`
- FOUND: `.planning/phases/205-persona-design-lens-evaluator-harness/205-01-SUMMARY.md`
- FOUND commit: `2f0abb3a` (Task 1)
- FOUND commit: `d56b02eb` (Task 2)
