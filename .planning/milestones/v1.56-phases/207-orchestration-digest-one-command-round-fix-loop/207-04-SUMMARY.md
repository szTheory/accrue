---
phase: 207-orchestration-digest-one-command-round-fix-loop
plan: 04
subsystem: accrue_admin/ui-ratchet
status: complete
tags: [digest, html-render, ratchet, offline-artifact, decisions-json, region-overlay]
requirements: [ORCH-02]
dependency_graph:
  requires:
    - "207-01 (rounds.ndjson schema + round-status marker contract)"
    - "206 ratchet-ledger.js fold()/IDENTITY_FIELDS/CARRY_FIELDS (finding-event row shape)"
    - "205 admin-visuals.spec.js captureBBoxes (.bbox.json sidecar shape)"
  provides:
    - "ratchet-digest.mjs — the per-round HTML digest renderer (ORCH-02)"
    - "decisions.json writer + row shape — the CONTRACT 207-06's apply-decisions reader depends on"
    - "npm run ratchet:digest / ratchet:digest:self-test"
  affects:
    - "207-05 (mix accrue_admin.ui.round invokes this as its final pipeline step)"
    - "207-06 (apply-decisions reads decisions.json)"
tech_stack:
  added: []
  patterns:
    - "phase192-gallery.mjs structural idiom: row-builders + failure-collecting validator + runSelfTest/--self-test/import.meta.url guard"
    - "zero external deps (node:fs/os/path/url + ./ratchet-ledger.js only) — offline self-contained HTML"
    - "independence discipline: banner re-derives convergence display, never imports 207-01's gate"
key_files:
  created:
    - accrue_admin/e2e/ratchet/ratchet-digest.mjs
  modified:
    - accrue_admin/package.json
decisions:
  - "Overlay scale uses the REAL captured widths 1280/393 (D-55 + RESEARCH Pitfall 2), overriding the UI-SPEC/CONTEXT's stale baseline-manifest 1440/390 — pinned by a self-test assertion. This is the plan's explicit instruction, not a deviation."
  - "Copied round-NN artifacts land in per-project subdirs (round-NN/{project}/{surface}{-dark}.png) to avoid the desktop/mobile filename collision on a shared surface name; image src references are relative (./{project}/…), honoring the UI-SPEC's relative-path-not-data-URI resolution."
  - "Fixed per-project DISPLAY_WIDTHS (desktop 960, mobile 393) give the absolutely-positioned overlay boxes exact px against the rendered <img> under a uniform aspect-preserving scale — deterministic, no runtime viewport math."
metrics:
  tasks_completed: 3
  files_created: 1
  files_modified: 1
  self_test_assertions: 17
  duration_minutes: 18
  completed: 2026-07-05
---

# Phase 207 Plan 04: Ratchet Digest (ORCH-02) Summary

`ratchet-digest.mjs` renders the maintainer's entire per-round read surface — a self-contained, offline, HTML-escaped digest of confirmed findings grouped by surface with correctly-scaled region overlays, a ranked auto-fixable worklist and a separate IA/product-decision queue, and a sticky summary banner in its 4 locked UI-SPEC states — then assembles the gitignored `round-NN/` artifact directory and writes the pre-filled `decisions.json` checkpoint that 207-06 consumes.

## What was built

**Task 1 — data layer** (commit `60646b0c`)
- `computeConvergenceDisplay(roundsRows)` — independently re-derives the latest round's `{round, dry, epoch, consecutiveDry, status}` for the banner using the identical K=2 / 6-cap thresholds as 207-01, without importing the gate (mirrors `verify_ratchet_ledger.mjs`'s independence discipline).
- `buildSummaryBanner(...)` — returns the exact copy for all 4 states with precedence converged > cap-reached > empty > normal.
- `partitionFindings(open)` — D-54 predicate split + exact D-56 sort keys (severity → persona_frequency desc → effort_class → finding_id), fully deterministic (every comparator ends on finding_id, independent of sort stability).
- `buildDecisionsJsonRows(worklist)` — the `{finding_id, decision:"approve", surface, summary, region_tag}` rows.
- `validateDigestRows` — twins `validateGalleryRows`'s failure-collecting-then-throw pattern.

**Task 2 — rendering + assembly** (commit `8f295de3`)
- `escapeHtml` applied to every interpolated ledger-row field (T-207-04 mitigation — first HTML-emitting script in this codebase).
- `computeOverlayScale`/`scaleBox` — the D-55 overlay math on the real 1280/393 widths.
- `assembleRoundArtifacts` — copies PNGs + `.bbox.json` FROM the flat capture dir INTO `round-NN/{project}/`, never mutating the capture dir (RESEARCH Pitfall 1 resolution).
- `renderDigestHtml` — the UI-SPEC-conformant offline document (prefers-color-scheme, system Geist, severity glyph+color, sticky banner, semantic tables + per-surface `<details>` gallery with overlays), plus `writeDecisionsJson`.

**Task 3 — self-test + wiring** (commit `4bb50b68`)
- `--self-test` (17 assertions): all 4 banner states with exact copy, XSS-escaping, no external http, partition disjointness + ordering, overlay scale pinned to 1280/393, and the decisions.json contract shape. Zero real committed files touched.
- `main()` checks `--self-test` first; the real path folds the ledger, derives the round, assembles artifacts, renders `digest.html`, writes `decisions.json`.
- `ratchet:digest` + `ratchet:digest:self-test` npm scripts added.

## Verification

- `node e2e/ratchet/ratchet-digest.mjs --self-test` → all 17 assertions pass, exit 0.
- Self-test output is byte-identical across two consecutive runs (no timestamps / non-determinism).
- `npm run ratchet:digest:self-test` resolves to the same file and passes.
- Real-path smoke run against the empty committed ledger produced `round-00/digest.html` (empty-state banner "Round 0 — 0 confirmed findings" + "No confirmed findings this round") and `decisions.json` (`[]`), both under the gitignored `test-results/` tree (smoke artifact cleaned up).

## Deviations from Plan

None — plan executed as written. The overlay-scale override to 1280/393 (vs the UI-SPEC/CONTEXT's stale 1440/390) is the plan's own explicit instruction (D-55 + RESEARCH Pitfall 2), pinned by a self-test assertion, not a deviation.

## Threat surface

T-207-04 (stored XSS in a locally-opened file) is mitigated exactly as specified: every ledger-row string field passes through `escapeHtml()` before template interpolation, proven by the dedicated `(XSS)` self-test fixture. No new package installs (T-207-SC accepted — zero external deps).

## Known Stubs

None. The digest wires real data end-to-end from `findings.ledger.ndjson` / `rounds.ndjson` / `.bbox.json`. The empty-state output on an empty ledger is the correct locked behavior, not a stub.

## Self-Check: PASSED
- FOUND: accrue_admin/e2e/ratchet/ratchet-digest.mjs
- FOUND: accrue_admin/package.json (ratchet:digest scripts)
- FOUND commit 60646b0c (Task 1), 8f295de3 (Task 2), 4bb50b68 (Task 3)
