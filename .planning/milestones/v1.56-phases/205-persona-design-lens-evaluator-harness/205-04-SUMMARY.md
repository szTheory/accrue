---
phase: 205-persona-design-lens-evaluator-harness
plan: 04
subsystem: ratchet-design-lens
tags: [ratchet, proposer, design-lens, few-shot, exemplars, comparative, dedup, claim-key, dev-test-only]
dependency_graph:
  requires:
    - "205-03 ratchet-propose.mjs (6 persona lenses, forced tool_use, harness-authoritative validation+claim-key gate)"
    - "205-02 exemplars/*.png + PROVENANCE.json + DESIGN-LENS-RUBRIC.md (committed exemplar set + comparative rubric)"
    - "205-01 region-tags.js SSOT (claimKey/findingId/normalizeRegion/normalizeOverlays/assertDimension/isAdmissibleToken/allowedSubsetFor/OVERLAY_TAGS)"
  provides:
    - "ratchet-propose.mjs 7th comparative graphic-design lens (lens_kind=design) with archetype-matched 2-image few-shot"
    - "design candidate fields: raised_by.lens_kind=design, direction:air|cramped, exemplar_ref (all NON-identity)"
  affects:
    - "Phase 206 verifier + operator-density-defender consume the direction flag for the asymmetric confirm bar (DEDUP-03 lens/persona frequency collapse)"
tech_stack:
  added: []
  patterns:
    - "hybrid few-shot: exactly 1 archetype-matched good + 1 bad exemplar per call, keyed off surface_type, bounded at 2 images (D-20)"
    - "comparative (not absolute-award) scoring anchored to committed exemplars + named textual tier anchors"
    - "shared identity gate reused verbatim; design non-identity fields excluded from claim_key so design/persona findings collapse to one finding_id (DEDUP-02)"
    - "optional schema props (direction/exemplar_ref) on the shared forced-tool emit_findings schema; persona lenses leave them unset"
key_files:
  created: []
  modified:
    - accrue_admin/e2e/ratchet/ratchet-propose.mjs
decisions:
  - "direction is a MANDATORY design self-flag: a design row without a valid air|cramped direction is dropped at the parse gate (guarantees the must-have invariant that every design row carries direction; consistent with per-row-drop discipline)"
  - "exemplar_ref is clamped to the committed set (PROVENANCE.json); a hallucinated ref is replaced by a deterministic default derived from dimension/direction (d8 → off-register, air → wasteful, cramped → cramped, else the surface's attached bad exemplar)"
  - "design fields are attached ONLY to design rows (persona rows unchanged) to avoid churning the plan-03 NDJSON schema; both direction and exemplar_ref are non-identity"
metrics:
  duration: "6m 4s"
  completed: "2026-07-03"
  tasks: 2
  files: 1
status: complete
---

# Phase 205 Plan 04: Comparative Design Lens Summary

Extended `accrue_admin/e2e/ratchet/ratchet-propose.mjs` with a 7th lens — a **comparative graphic-design lens** (`raised_by.lens_kind:"design"`) that runs per image after the 6 operator-persona lenses. Per call it attaches exactly one archetype-matched GOOD + one BAD committed exemplar (keyed off `surface_type`, bounded at 2 images, D-20) as few-shot, prompts the model to score the surface COMPARATIVELY against those exemplars + named textual tier anchors (Linear/Vercel/Prisma/Tailscale/Oban; Stripe density-only under the anti-fintech caveat) rather than an absolute award score, and emits design candidates carrying a mandatory `direction:air|cramped` self-flag plus an `exemplar_ref`. Design candidates flow through the SAME harness validation + claim-key gate as persona findings — no new identity path, so DEDUP-02 is preserved.

## What Was Built

- **7th design lens (Task 1):** A comparative prompt anchored to `DESIGN-LENS-RUBRIC.md` — sharpens dims 2 (hierarchy) / 3 (spacing-rhythm) / 5 (responsive) / 8 (brand-expression) with 1 (token) / 6 (contrast) as support; instructs d3 to penalize BOTH cramped AND wasteful equally (the over-whitespacing footgun is called out as the biggest brand risk); requires a `direction:air|cramped` self-flag per finding. Reuses the SAME `SYSTEM_PREAMBLE` (prompt-injection guard), forced `emit_findings` tool schema, `tool_choice`, and config-gated `temperature: 0` as the persona lenses.
- **Archetype-matched exemplar attach (Task 1):** `EXEMPLAR_PAIR_BY_SURFACE_TYPE` maps `page-flow → good/dashboard.png + bad/cramped.png` and `component`/`component-group → good/dev-components.png + bad/wasteful.png` (dense surfaces fail cramped-ward, sparse surfaces fail air-ward), with a dense-console default for unknown types. `buildDesignContent` reads the committed PNG bytes, guards each against the same 5 MB `MAX_B64_BYTES` limit (T-205-03), labels each attached image as GOOD/BAD in a preceding text block, and returns null-skip (textual fallback) on a missing file (D-19). Exactly 2 exemplar images ship per call, regardless of surface.
- **Shared identity gate reuse (Task 2):** Design raw findings are collected into the same `collected` array and run through the EXACT SAME `emitCandidates` gate — `assertDimension`, `normalizeRegion`, `normalizeOverlays`, `isAdmissibleToken`, taste denylist, then harness-re-derived `claimKey`/`findingId`/`cell_refs`. Two design-only pre-checks were added: dimension restricted to `{1,2,3,5,6,8}` (rows outside the sharpened set dropped) and a mandatory `direction` (rows without a valid `air|cramped` dropped). Design rows set `raised_by:{lens_kind:"design"}` (no persona_id/job), `direction`, and a committed-set-clamped `exemplar_ref` — all NON-identity (excluded from `claim_key`). `persona_frequency` stays `1`; design rows count toward the same N=12/image cap.
- **Schema:** Added optional `direction` (enum `air|cramped`) and `exemplar_ref` (string) properties to the shared forced-tool `emit_findings` schema; the persona lenses leave them unset.

## Task Commits

| Task | Name | Type | Commit | Files |
| ---- | ---- | ---- | ------ | ----- |
| 1 | Comparative design lens + archetype-matched exemplar attach | feat | `cd5c09ba` | ratchet-propose.mjs |
| 2 | Design-candidate emission through the shared identity gate | feat | `ab843076` | ratchet-propose.mjs |

## Verification

- `node accrue_admin/e2e/ratchet/ratchet-propose.mjs --self-test` → green (plan-01 `runSelfTest()`; identity unchanged, DEDUP-01/02 hold key-free).
- `node --check accrue_admin/e2e/ratchet/ratchet-propose.mjs` → passes.
- Source greps: `design`/`exemplar`/`direction` all present; `/lens_kind.{0,6}design/` and `/exemplar_ref/` both match.
- Synthetic exemplar-attach + derivation walk (no key): every `surface_type` selects a good+bad pair whose committed PNGs read well under 5 MB base64; `deriveExemplarRef` returns `off-register` for d8, `wasteful` for air, `cramped` for cramped, honors a valid supplied ref, and replaces a hallucinated ref with the deterministic default — the load-bearing non-identity derivation, exercised directly.
- No stray persona-variable reference remains in the `emitCandidates` loop (branch uses `item.persona`/`item.design`).
- Live maintainer smoke (`ANTHROPIC_API_KEY=… npm --prefix accrue_admin run ratchet:propose`) is non-gating and deferred to the maintainer (LLM output is non-deterministic; never on the CI path). NOTE: a pre-existing plan-03 manifest import path bug blocks the live path — see Deferred Issues.

## Requirements Delivered

- **EVAL-02** — the graphic-design lens scores COMPARATIVELY against named quiet-dev-tooling exemplars (not an absolute award score), anchored to `brandbook/` via the committed `DESIGN-LENS-RUBRIC.md` + the archetype-matched few-shot exemplar pair.

## Deviations from Plan

None material. One in-discretion choice (D-08/robustness): `direction` is treated as strictly mandatory for design rows — a design finding lacking a valid `air|cramped` value is dropped at the parse gate rather than emitted with a null direction, which guarantees the plan must-have that every design row carries a `direction` self-flag and keeps the Phase-206 asymmetric-confirm-bar input well-formed. `exemplar_ref` is clamped to the committed set with a deterministic dimension/direction-derived default so a hallucinated reference can never point outside the version-pinned exemplar gallery.

## Deferred Issues

- **plan-03 manifest import path (out of scope):** `ratchet-propose.mjs` Guard 3 imports `./baseline-manifest.js`, which resolves to `ratchet/baseline-manifest.js` (nonexistent) instead of `../baseline-manifest.js`. This throws `ERR_MODULE_NOT_FOUND` on a live key-present run but sits behind the no-key `exit 0` guard, so it does not affect this plan's gates (`--self-test`, `node --check`) or the deterministic identity path. Introduced by plan 03, not by any 205-04 change; logged to `deferred-items.md` with a one-line fix for a follow-up. Not fixed here per the execute-plan scope boundary.

## Known Stubs

- The live Anthropic design-lens call (`buildDesignContent` → `client.messages.create`) is exercised only under a real key via the maintainer smoke; with no key the harness exits at Guard 2. The deterministic gate/derivation path (dimension restriction, direction requirement, `exemplar_ref` clamp, exemplar reads under the 5 MB guard) IS covered key-free by `--self-test` + the synthetic walk above. By design — the LLM never gates CI.

## Self-Check: PASSED

- FOUND: `accrue_admin/e2e/ratchet/ratchet-propose.mjs` (design lens + emit branch)
- FOUND commit: `cd5c09ba` (Task 1)
- FOUND commit: `ab843076` (Task 2)
- FOUND: `.planning/phases/205-persona-design-lens-evaluator-harness/205-04-SUMMARY.md`
