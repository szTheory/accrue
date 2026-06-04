---
phase: 179-f-screenshot-driven-visual-qa-loop-sign-off
plan: "02"
subsystem: accrue_admin/e2e
tags: [visual-qa, llm-scoring, playwright, motion-trace, e2e-tooling]
dependency_graph:
  requires: ["179-01"]
  provides: ["score-visuals-cli", "motion-trace-spec"]
  affects: ["accrue_admin/e2e/"]
tech_stack:
  added: ["score-visuals.mjs (ESM Node CLI, @anthropic-ai/sdk dynamic import)"]
  patterns:
    - "ANTHROPIC_API_KEY guard-first + dynamic SDK import prevents ERR_MODULE_NOT_FOUND in no-key path"
    - "10-dimension rubric emitted as NDJSON findings (locked schema per CONTEXT.md)"
    - "FILE-SCOPED test.use({ trace: on }) via Playwright — does not modify global config"
key_files:
  created:
    - accrue_admin/e2e/score-visuals.mjs
    - accrue_admin/e2e/admin-motion-trace.spec.js
  modified: []
decisions:
  - "Dynamic import of @anthropic-ai/sdk placed AFTER API key guard so no-key path never resolves the module — eliminates ERR_MODULE_NOT_FOUND risk when SDK is installed but key absent"
  - "test.use({ trace: on }) scoped to admin-motion-trace.spec.js only to avoid trace bloat on all other specs (global config stays retain-on-failure)"
  - "aria-controls attribute read dynamically at runtime for nav-collapse assertion — avoids hardcoding the sidebar group slug that could differ across mounts"
metrics:
  duration: "2m 20s"
  completed_date: "2026-06-04"
  tasks_completed: 2
  files_created: 2
---

# Phase 179 Plan 02: LLM Vision-Scoring Script + Motion Trace Spec Summary

LLM vision-scoring Node CLI (score-visuals.mjs) with ANTHROPIC_API_KEY-first guard and dynamic SDK import, plus Playwright motion trace spec covering all 4 animated surfaces with file-scoped trace: "on".

## What Was Built

### Task 1: score-visuals.mjs (LLM Vision-Scoring CLI)

`accrue_admin/e2e/score-visuals.mjs` — ESM Node 22 script that:

- **API key guard first:** `if (!process.env.ANTHROPIC_API_KEY)` is the first executable statement. Prints skip message and `process.exit(0)`. The `@anthropic-ai/sdk` is a DYNAMIC `await import(...)` placed AFTER the guard — the module is never resolved in the no-key path, so ERR_MODULE_NOT_FOUND cannot occur even if the SDK is installed.
- **Model:** `claude-sonnet-4-5` by default, overrideable via `SCORE_MODEL` env var.
- **PNG discovery:** Reads `test-results/admin-visuals/{chromium-desktop,chromium-mobile}/` using `fs.readdirSync`. Derives `theme` from filename suffix (`-dark.png` → dark; else light), `viewport` from subdirectory name, `screen` from stripped filename.
- **5 MB guard:** Skips PNGs whose base64 encoding exceeds 5 MB with `console.warn` (not error).
- **10-dimension rubric:** token-compliance, visual-hierarchy, spacing-rhythm, state-coverage, responsive-mobile-first, contrast, focus-semantics, brand-expression, motion, reuse-dry. Each dimension scored 0–3; pass threshold ≥ 2.
- **Findings schema (locked):** `{screen, viewport, theme, dimension, dimension_name, score, defect, suggested_fix}` — one object per dimension per PNG, emitted as NDJSON to `findings.ndjson` in RESULTS_DIR (or `--stdout`).
- **Summary line:** `[score-visuals] Scored N PNGs → M findings (K below bar)`.
- **Remediation loop documented** in file header comment: fix → rebuild → reshoot → rescore, cap 3 rounds.

### Task 2: admin-motion-trace.spec.js (Playwright Motion Trace Spec)

`accrue_admin/e2e/admin-motion-trace.spec.js` — CommonJS Playwright spec with:

- **FILE-SCOPED `test.use({ trace: "on" })`** — forces full trace recording for all 4 tests in this file only. `playwright.config.js` is unchanged (retains `trace: "retain-on-failure"`).
- **4 motion surfaces** under `test.describe("Motion trace — animated surface capture")`:
  1. **Command palette** — `#search-trigger` click opens `.ax-command-palette-wrapper` (asserts `data-open="true"`); Escape closes (asserts `data-open="false"`).
  2. **Dropdown** — `details.ax-dropdown > summary` click opens `.ax-dropdown-panel`; second summary click closes.
  3. **Nav group collapse/expand** — `[data-collapse-toggle="true"]` click; reads `data-controls` attribute to locate the controlled list element; asserts hidden then visible.
  4. **Webhook replay drawer** — `[data-role="replay-single"]` click triggers phx-click="prepare_replay"; asserts `.ax-detail-drawer-shell` becomes visible (drawer uses phx-mounted JS.show with ax-drawer-entering CSS transition, --ax-dur-3: 240ms).
- **Helpers verbatim from admin-visuals.spec.js:** `reset(request)`, `seed(request, fixture)`, `login(page, target)`.
- **`#main-content` visibility gate** after each login — stable page-settled signal used across all e2e specs.
- **Trace artifact review instructions** documented in spec comments.

## Verification Results

| Check | Result |
|-------|--------|
| `node e2e/score-visuals.mjs` (no key) | Exit 0, prints skip message |
| `npx playwright test e2e/admin-motion-trace.spec.js --list` | 8 tests (4 × 2 projects) |
| `grep "test.use.*trace.*on"` in motion spec | Present |
| `grep "trace" playwright.config.js` | `retain-on-failure` (unchanged) |
| `grep "ANTHROPIC_API_KEY"` in score-visuals.mjs | Guard present at line 35 |
| `grep "await import"` in score-visuals.mjs | Dynamic import at line 41 |
| `grep "suggested_fix"` in score-visuals.mjs | Schema fields present |
| `mix test --seed 0` | 262 tests, 0 failures |

## Deviations from Plan

None — plan executed exactly as written. The `score-visuals` npm script and `@anthropic-ai/sdk` devDependency were already present in `package.json` (added by Plan 179-01 as expected by the `depends_on` declaration).

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. score-visuals.mjs makes outbound HTTPS to `api.anthropic.com` only when `ANTHROPIC_API_KEY` is set (CI/human gate, not in automated test suite). API key is never logged or committed (env-only). PNGs sent contain seeded test data (no real PII) — consistent with T-179-03 accepted disposition.

## Self-Check

- [x] `accrue_admin/e2e/score-visuals.mjs` — exists, verified
- [x] `accrue_admin/e2e/admin-motion-trace.spec.js` — exists, verified
- [x] Commit `1f4ad886` (Task 1) — verified in git log
- [x] Commit `cfed37a6` (Task 2) — verified in git log
- [x] 262 Elixir tests green

## Self-Check: PASSED
