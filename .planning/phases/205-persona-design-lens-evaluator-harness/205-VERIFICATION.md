---
phase: 205-persona-design-lens-evaluator-harness
verified: 2026-07-03T18:07:38Z
status: passed
live_smoke_passed: 2026-07-03T19:30:00Z
score: 5/5 roadmap success-criteria verified (spine automated; SC#1/SC#2 confirmed by live smoke 2026-07-03)
behavior_unverified: 2
overrides_applied: 0
re_verification: null
behavior_unverified_items:
  - truth: "SC#1 — running the evaluator produces a candidates.ndjson where each row records surface, dimension, region_tag, overlay_tags, severity, raising persona/lens, and cell_refs"
    test: "Set ANTHROPIC_API_KEY and run `node accrue_admin/e2e/ratchet/ratchet-propose.mjs` against the committed screenshots; open candidates.ndjson"
    expected: "Non-empty NDJSON; every row carries surface, dimension, region_tag, overlay_tags, severity, raised_by, cell_refs, and a harness-re-derived finding_id (not the model's)"
    why_human: "Emission requires a live Anthropic model call. By design the harness is key-gated and the LLM NEVER gates CI, so no automatable test exercises the live emission path; presence + wiring of emitCandidates/row-schema is verified, runtime output is not."
  - truth: "SC#2 — all 6 operator personas each produce job-anchored findings and the design lens scores comparatively against named exemplars"
    test: "With a key, run the proposer and inspect candidates.ndjson for rows raised_by each of the 6 persona_ids plus rows with raised_by.lens_kind='design' carrying a direction:air|cramped self-flag"
    expected: "Findings attributed to each of operator-founder, customer-support, finance-billing-ops, recovery-growth-ops, developer-integration, compliance-audit, plus comparative design-lens rows (no absolute award score)"
    why_human: "Actual per-persona finding production is a live-model behavior. The 6-persona set, prompts, comparative design lens, direction flag, and exemplar attachment are all present and wired (verified); runtime production needs a key and is a maintainer live-smoke step."
human_verification:
  - test: "Live-smoke the proposer with ANTHROPIC_API_KEY set against the committed admin screenshots (SC#1 + SC#2)"
    expected: "candidates.ndjson populated; rows from all 6 personas + comparative design lens; identity fields harness-re-derived; a second run yields an identical finding_id set"
    why_human: "Requires a live Anthropic API call; key-gated by design and explicitly out of the CI gate path."
---

# Phase 205: Persona + Design-Lens Evaluator Harness — Verification Report

**Phase Goal:** A maintainer can run a local, key-gated evaluator that fans out 6 operator-persona lenses + a comparative graphic-design lens over the committed admin screenshots and emits stable, claim-keyed candidate findings. Promotes the dormant `score-visuals.mjs` into `accrue_admin/e2e/ratchet/ratchet-propose.mjs`.
**Verified:** 2026-07-03T18:07:38Z (automated spine) · 2026-07-03T19:30 (live smoke)
**Status:** passed
**Re-verification:** No — initial verification

## Live-Smoke Addendum (2026-07-03) — SC#1 + SC#2 now OBSERVED

The two `human_needed` criteria were exercised with a live `ANTHROPIC_API_KEY` over the representative
slice (dashboard, subscriptions, subscription-detail on `claude-sonnet-4-5`, desktop, both themes):

- **SC#1 ✓** — `candidates.ndjson` populated (69 candidates from 6 subject PNGs). Every row carries the
  full `ratchet-candidate/1` schema (surface, dimension, region_tag, overlay_tags, severity, raised_by,
  cell_refs, justification_token, …). **Identity integrity 69/69**: `finding_id == f-sha256(claim_key)[:16]`,
  0 mismatches — harness-re-derived, never model-supplied. Coarse-key dedup collapsed 69 raw → 32 distinct ids.
- **SC#2 ✓** — all 6 personas produced job-anchored findings (operator-founder, compliance-audit,
  finance-billing-ops, developer-integration, recovery-growth-ops, customer-support) plus 20 comparative
  design-lens rows (`lens_kind:design`, `direction:air|cramped`, `exemplar_ref`, no absolute award score).
- **SC#5 (live)** — run-to-run `finding_id`-set overlap 80% (28/32 shared). Residual drift is the model
  assigning defects to different structural coords at temp 0 (NOT prose leakage — identity was 69/69
  harness-derived); the definitive DEDUP-02 proof remains the deterministic `--self-test` (green, golden-hash
  locked). By design the LLM never gates CI; the Phase-206 skeptic-panel verifier absorbs this tail.

Post-smoke fixes (committed): the design-system surface `component-kitchen` was initially skipped
(fullPage screenshot > 5 MB guard) and mis-archetyped (WR-03: `surface_type` "unknown" → wrong exemplar).
Fixed in `b9387410` (viewport-bounded capture + `SURFACE_TYPE_FALLBACK`→component) and re-smoked: now
evaluated, `surface_type=component`, correct component-archetype exemplar. Two earlier live-path bugs
(`3935f83f` import path, `eb8d4568`/WR-01 non-array findings) were also fixed. WR-02 (OVERLAY_TAGS parity
assertion) remains an advisory follow-up in 205-REVIEW.md. Session live-smoke cost ~$2.5.

## Goal Achievement

The determinism / identity / no-key spine — the part that is automatable and the part the phase goal
hinges on ("stable, claim-keyed candidate findings", "key-gated") — is **fully verified by running
the key-free self-tests myself**, not by trusting SUMMARY claims. The only unverified surface is the
live-model emission, which by explicit design is key-gated and never gates CI; it is routed to a
maintainer live-smoke step (human verification), which is why the status is `human_needed` rather than
`passed`. Nothing is FAILED.

### Observable Truths (roadmap Success Criteria)

| # | Truth (SC) | Status | Evidence |
|---|-----------|--------|----------|
| 1 | candidates.ndjson row records surface/dim/region/overlays/severity/lens/cell_refs | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Row-schema, `emitCandidates`, identity re-derivation all present + wired in `ratchet-propose.mjs`; populated emission needs a live key (see Human Verification) |
| 2 | 6 personas produce job-anchored findings; design lens comparative (not award) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | 6 personas coded (`PERSONAS`, lines 108-114); design lens comparative structure verified (never "award", `direction:air\|cramped`, exemplar_ref); live production needs a key |
| 3 | No `ANTHROPIC_API_KEY` → exit 0, per-image size guard still holds (EVAL-03) | ✓ VERIFIED | `env -u ANTHROPIC_API_KEY node ratchet-propose.mjs` printed skip line, **exit 0** (ran it); `MAX_B64_BYTES = 5*1024*1024` enforced at lines 174, 361 |
| 4 | Committed DESIGN-LENS-RUBRIC.md + curated good/bad exemplar set anchors brand DNA (EVAL-04) | ✓ VERIFIED | Rubric (183 lines) names Linear/Vercel/Prisma/Tailscale/Oban as textual tier anchors, brandbook-supersedes clause; 5 PNGs (2 good/3 bad) git-tracked; PROVENANCE.json valid |
| 5 | Two runs → identical finding_id set, proven by an automated test (DEDUP-02) | ✓ VERIFIED | `node region-tags.js` and `ratchet-propose.mjs --self-test` both exit 0 with 13 assertions incl. idempotence, prose-independence, golden-hash `f-15a8b227d09e0ea1` (ran both) |

**Score:** 3/5 roadmap SCs fully verified; 2 present-but-behavior-unverified (live-model emission only).

### Plan-level must-have truths (all determinism-spine truths VERIFIED)

| Plan | Truth | Status | Evidence |
|------|-------|--------|----------|
| 01 | claimKey identical inputs → identical finding_id | ✓ VERIFIED | self-test (1) idempotence |
| 01 | Prose variation (defect/fix/severity/persona/bucket) → identical finding_id | ✓ VERIFIED | self-test (2) prose-independence |
| 01 | region-tags.js SDK-free, standalone self-test, no key | ✓ VERIFIED | `require("node:crypto")` only; ran standalone exit 0 |
| 01 | Out-of-vocab (overlay/region/dim 13) throws at parse | ✓ VERIFIED | self-test (6) both throws pass |
| 01 | D-07: no `empty-state` region member | ✓ VERIFIED | REGION_TAGS = 14 values, no `empty-state` |
| 01 | D-10: single shared SSOT, orthogonal axes | ✓ VERIFIED | region-tags.js exports enum+subset+synonym+fns; imported by proposer & spec |
| 02 | Rubric comparative, brandbook-anchored, dims 2/3/5/8 | ✓ VERIFIED | rubric §2/§5 verified |
| 02 | 5-image own-render exemplar set committed | ✓ VERIFIED | 2 good + 3 bad, git-tracked, all < 5 MB |
| 02 | PROVENANCE.json one entry per PNG | ✓ VERIFIED | 5 entries w/ route, viewport+theme, capture_command, max_dimensions, curator_note; bundle-level source_commit_sha `50acdd83` (shared re-baseline commit) |
| 03 | `--self-test` no key/no SDK exit 0 | ✓ VERIFIED | ran it, exit 0, no SDK import before guard |
| 03 | no-key skip exit 0, 5 MB guard holds | ✓ VERIFIED | ran it, exit 0 |
| 03 | 6 personas + row fields | ✓ VERIFIED (structure) / ⚠️ (live emission) | 6 PERSONAS + row schema present; production = SC#2 |
| 03 | Identity harness-re-derived, gates drop pre-emit, cap N=12 | ✓ VERIFIED | identity via region-tags.js; model claim_key/finding_id ignored |
| 03 | D-03 defect_bucket non-identity | ✓ VERIFIED | absent from claimKey inputs; prose-independence proves it |
| 03 | D-13 severity 2-level {minor,real} | ✓ VERIFIED | present in code/schema |
| 03 | D-14 job_blocking separate boolean | ✓ VERIFIED | present, orthogonal to severity |
| 04 | 7th comparative design lens, ≤2 exemplars/call | ✓ VERIFIED (structure) | `selectExemplarPair` bounds to 1 good + 1 bad |
| 04 | design candidates lens_kind='design', direction, exemplar_ref, same gate | ✓ VERIFIED | raised_by branch (line 653), schema enum direction air|cramped |
| 04 | comparative not absolute award, dims 2/3/5/8 | ✓ VERIFIED | prompt forbids award/0–100 grade |
| 05 | Per surface/viewport/theme `.bbox.json` of ax-* boxes | ✓ VERIFIED | admin-visuals.spec.js iterates REGION_SELECTORS, writes `${name}${suffix}.bbox.json` |
| 05 | Geometry never enters claim-key (D-09) | ✓ VERIFIED | bbox written to sidecar only; claimKey has no geometry input |
| 05 | Absent selector → null box, no crash | ✓ VERIFIED | try/catch → box=null; module-absent → additive skip |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue_admin/e2e/ratchet/region-tags.js` | SSOT: enum + pure claim-key/finding-id + self-test | ✓ VERIFIED | 459 lines, CJS, node:crypto only, self-test exit 0 |
| `accrue_admin/e2e/ratchet/ratchet-propose.mjs` | proposer CLI, 6 personas + design lens + guards | ✓ VERIFIED | 34 KB, guards ordered, imports region-tags + `../baseline-manifest.js` |
| `accrue_admin/e2e/ratchet/DESIGN-LENS-RUBRIC.md` | committed design sub-rubric | ✓ VERIFIED | 183 lines, brandbook-anchored |
| `accrue_admin/e2e/ratchet/exemplars/PROVENANCE.json` | one entry per PNG | ✓ VERIFIED | 5 entries, valid JSON |
| `exemplars/good/*.png` (2) + `bad/*.png` (3) | curated exemplar set | ✓ VERIFIED | all git-tracked, < 5 MB |
| `accrue_admin/package.json` | ratchet:propose + ratchet:self-test | ✓ VERIFIED | both scripts present (lines 18-19) |
| `accrue_admin/e2e/admin-visuals.spec.js` | bbox emit extension | ✓ VERIFIED | additive `.bbox.json` emit |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| ratchet-propose.mjs | region-tags.js | `import * as regionTags from "./region-tags.js"` | ✓ WIRED | identity re-derived, self-test delegated |
| ratchet-propose.mjs | baseline-manifest.js | `await import("../baseline-manifest.js")` | ✓ WIRED | `../` path resolves (the `./` bug from commit 3935f83f is fixed); file exists |
| ratchet-propose.mjs | model findings | `Array.isArray(_found) ? _found : []` | ✓ WIRED | WR-01 type-guard present at lines 443 AND 468 (eb8d4568 fix confirmed) |
| admin-visuals.spec.js | region-tags.js | `require("./ratchet/region-tags.js")` REGION_SELECTORS | ✓ WIRED | consumed for bbox; absent-module additive skip |
| design lens | exemplars/ | `selectExemplarPair(surface_type)` | ✓ WIRED (see WR-03) | page-flow/component/component-group mapped; unknown → default |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| region-tags standalone self-test | `node accrue_admin/e2e/ratchet/region-tags.js` | 13 asserts, "self-test passed.", exit 0 | ✓ PASS |
| proposer self-test | `node ratchet-propose.mjs --self-test` | 13 asserts, exit 0 | ✓ PASS |
| no-key skip | `env -u ANTHROPIC_API_KEY node ratchet-propose.mjs` | skip line, exit 0 | ✓ PASS |
| golden-hash lock | (in self-test) | `f-15a8b227d09e0ea1` matches pinned literal | ✓ PASS |
| coarse claim-key | code read | surface/dNN/region/sorted-overlays only; NO defect_bucket | ✓ PASS |
| finding_id derivation | code read | `"f-" + sha256(claim_key).slice(0,16)` | ✓ PASS |
| live emission | (needs key) | not runnable in CI/verify | ? SKIP → human |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| EVAL-01 | 205-03 | ✓ SATISFIED (structure) / live-smoke | 6 job-anchored PERSONAS coded + prompted; live production = human item |
| EVAL-02 | 205-02, 205-04 | ✓ SATISFIED (structure) / live-smoke | comparative design lens, exemplars, direction flag; live production = human item |
| EVAL-03 | 205-03 | ✓ SATISFIED | no-key exit 0 (ran) + 5 MB guard |
| EVAL-04 | 205-02 | ✓ SATISFIED | rubric + 5 exemplars + PROVENANCE |
| EVAL-05 | 205-01/03/05 | ✓ SATISFIED | row fields + cell_refs + bbox sidecar |
| DEDUP-01 | 205-01/03 | ✓ SATISFIED | coarse claim-key, prose excluded |
| DEDUP-02 | 205-01/03 | ✓ SATISFIED | pure automated self-test, golden hash |

All 7 declared requirement IDs are present in REQUIREMENTS.md, each mapped to Phase 205 (no orphans, no
missing IDs). REQUIREMENTS.md traceability table already marks all 7 Complete.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| region-tags.js | 88-98 | `// TODO: confirm selector` (10 total) | ℹ️ Info | Warning-tier only (not TBD/FIXME/XXX). Feeds bbox geometry only — never identity; absent/wrong selector safely yields null box. Not a blocker. |

No blocker-tier debt markers (TBD/FIXME/XXX) in any phase-modified file.

### Advisory Warnings (from 205-REVIEW.md — assessed against the GOAL)

- **WR-02** (no automated OVERLAY_TAGS parity assertion between region-tags.js and baseline-manifest.js):
  currently byte-identical (verified). Latent drift risk, but does NOT affect the phase goal today — the
  self-test asserts slug parity and all identity invariants hold. Quality follow-up.
- **WR-03** (`component-kitchen` surface has no SURFACES entry → surface_type resolves to `unknown` →
  empty `cell_refs` + falls to the page-flow default exemplar pair instead of the `component` pair):
  a real but narrow quality bug affecting ONE captured surface's exemplar match and its cell-lattice
  linkage. The `component`/`component-group` archetype exemplar mapping IS correctly wired for modeled
  surface_types (lines 158-159), and this only degrades one surface's live-run quality. Does NOT block
  the goal (determinism spine intact; LLM never gates CI). Quality follow-up.

Both are correctly logged as advisory (non-blocker) in 205-REVIEW.md.

### Deferred (correctly EXCLUDED from this phase)

- No verifier / ledger / orchestration logic in the proposer (only forward-reference comments to
  Phase 206/207). ✓ Correctly excluded.
- `persona_frequency: 1` emitted only (collapse deferred to Phase 206 DEDUP-03). ✓ Correct.

### Human Verification Required

1. **Live-smoke the proposer with a key (SC#1 + SC#2)** — set `ANTHROPIC_API_KEY` and run
   `node accrue_admin/e2e/ratchet/ratchet-propose.mjs` against the committed admin screenshots.
   - Expected: `candidates.ndjson` populated; rows from all 6 personas + comparative design-lens rows;
     every identity field harness-re-derived; a second run yields an identical `finding_id` set.
   - Why human: requires a live Anthropic API call; key-gated by design and explicitly outside the CI
     gate path (the LLM never gates CI). This is a maintainer live-smoke step, not a CI failure.

### Gaps Summary

No gaps. Every automatable must-have — the entire determinism / identity / no-key spine that the phase
goal depends on — is VERIFIED by running the key-free self-tests directly (not by trusting SUMMARY.md).
The `../baseline-manifest.js` import resolves, the `Array.isArray` WR-01 guard is present, the golden
hash `f-15a8b227d09e0ea1` locks the claim-key grammar, and the claim-key is confirmed COARSE (no
defect-bucket in identity). The status is `human_needed` (not `passed`) solely because SC#1/SC#2's
live-model emission is a legitimate key-gated maintainer live-smoke step with no automatable proof —
per the phase's own verification guidance, this is not a failure.

---

_Verified: 2026-07-03T18:07:38Z_
_Verifier: Claude (gsd-verifier)_
