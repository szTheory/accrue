---
phase: 186-html-brand-book-assembly-quality-gate
plan: "01"
subsystem: brandbook
tags: [brandbook, html-assembly, quality-gate, playwright, dark-mode]
dependency_graph:
  requires:
    - "183: brandbook/logo/*.svg (13 SVGs + 8 rasters)"
    - "184: brandbook/tokens/tokens.css"
    - "185: brandbook/voice.md, brandbook/copy.md"
  provides:
    - "brandbook/harness/package.json — zero-dep harness manifest"
    - "brandbook/harness/assemble.mjs — deterministic HTML assembler"
    - "brandbook/harness/verify-brandbook.mjs — structural + Playwright quality gate"
    - "brandbook/index.html — self-contained brand book HTML (committed output)"
  affects: []
tech_stack:
  added:
    - "Node.js ESM scripts (fs, path, url built-ins only — zero npm deps)"
    - "Playwright (reuse from brandbook/logo/harness/node_modules/) — 4-cell screenshot matrix"
  patterns:
    - "generate-tokens-css.mjs pattern: __dirname idiom, path.resolve, isMain guard, trailing newline"
    - "verify-specimens.mjs pattern: failures counter, assert(), assertContains(), early-exit, VERIFY_OK terminal tag"
    - "size-matrix-qa.mjs pattern: chromium.launch, newContext, goto, screenshot, try/finally close"
    - "Sorted determinism: readdirSync().sort() for all file arrays"
    - "T-186-01 mitigation: stripScriptElements() on all inlined SVG content"
key_files:
  created:
    - brandbook/harness/package.json
    - brandbook/harness/assemble.mjs
    - brandbook/harness/verify-brandbook.mjs
    - brandbook/index.html
    - .planning/phases/186-html-brand-book-assembly-quality-gate/qa-screenshots/light-desktop.png
    - .planning/phases/186-html-brand-book-assembly-quality-gate/qa-screenshots/dark-desktop.png
    - .planning/phases/186-html-brand-book-assembly-quality-gate/qa-screenshots/light-mobile.png
    - .planning/phases/186-html-brand-book-assembly-quality-gate/qa-screenshots/dark-mobile.png
  modified: []
decisions:
  - "Playwright import in verify-brandbook.mjs uses ../logo/harness/node_modules/playwright/index.js (not ../../logo/... as plan stated — corrected by counting directory depth from brandbook/harness/)"
  - "Playwright is CommonJS; use default import destructuring (import pkg from '...'; const { chromium } = pkg) instead of named import"
  - "mdToHtml mini-converter (Option B — no npm deps) covers 6 constructs; tables flush on non-table line or code fence open"
  - "T-186-01 mitigated in assemble.mjs via stripScriptElements() on every SVG before embedding"
  - "Dark-mode CSS uses --accrue-dark-* variable names explicitly (does not assume light names are overridden)"
metrics:
  duration: "5 minutes"
  completed: "2026-06-14"
  tasks_completed: 3
  files_created: 8
---

# Phase 186 Plan 01: Harness — Assembler & Verifier Summary

Assembled the Phase 186 engineering backbone: a zero-dep deterministic HTML assembler script and a structural + Playwright quality-gate verifier, producing a committed self-contained brand book at `brandbook/index.html`.

## What Was Built

**`brandbook/harness/package.json`** — Zero-dep harness manifest. `name=accrue-brandbook-harness`, `private:true`, `type:module`, scripts `assemble` + `verify`. No `dependencies` key.

**`brandbook/harness/assemble.mjs`** — Reads all locked source materials (13 logo SVGs, 3 specimen SVGs, tokens.css, voice.md, copy.md, README.md, LICENSE-FONTS.txt) and writes `brandbook/index.html` deterministically. Zero npm deps (Node built-ins only). Key design choices:
- `mdToHtml()` mini-converter: 6 constructs (headings, tables, code fences, bold, italic, bullets) — no `marked` dep
- Sorted `readdirSync().sort()` for all file arrays (determinism guarantee)
- `cleanSvg()` strips `<?xml?>` declarations and `<script>` elements from all inlined SVGs (T-186-01)
- Dark-mode toggle: vanilla IIFE script at bottom of `<body>`, no imports
- Dark CSS uses `--accrue-dark-*` variable names explicitly in `[data-theme="dark"]` blocks
- 10 sections with `id="section-*"` anchors; sticky header TOC; responsive layout

**`brandbook/harness/verify-brandbook.mjs`** — Two-phase verifier:
1. Structural (synchronous): no external src/href URLs, no JS frameworks in script bodies, data-theme present, ≥10 section IDs, logo SVGs inlined (no `<img src="*.svg">`), committed weight ≤ 2 MB via `git ls-files | xargs du -ck`
2. Playwright screenshots (async): 4-cell matrix (light+dark × desktop+mobile) → `qa-screenshots/`

**`brandbook/index.html`** — Committed output: 127 KB, fully self-contained, file://-openable, zero external refs.

**4 QA screenshots** committed in `.planning/phases/186-html-brand-book-assembly-quality-gate/qa-screenshots/`.

## Verification Results

All acceptance criteria met:

| Check | Result |
|-------|--------|
| `node brandbook/harness/assemble.mjs` exits 0 | PASS |
| `brandbook/index.html` created (127 KB) | PASS |
| Zero external src/href URLs | PASS |
| `data-theme` attribute present | PASS (21 occurrences) |
| `theme-toggle` button present | PASS (5 occurrences) |
| `--accrue-dark-base` referenced | PASS (6 occurrences) |
| No `import` in script tags | PASS |
| Re-run idempotent (`git diff --exit-code`) | PASS |
| ≥10 section IDs present | PASS (exactly 10) |
| `verify-brandbook.mjs` exits 0 + VERIFY_BRANDBOOK_OK | PASS |
| 4 screenshots produced | PASS |
| Missing index.html → FATAL exit 1 | PASS |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Playwright import path corrected**
- **Found during:** Task 3 implementation
- **Issue:** PLAN.md and PATTERNS.md both specified `"../../logo/harness/node_modules/playwright/index.js"`. From `brandbook/harness/`, `../..` resolves to the repo root, so `../../logo/harness/` would be `accrue/../logo/harness/` — outside the repo.
- **Fix:** Corrected to `"../logo/harness/node_modules/playwright/index.js"` which correctly resolves to `brandbook/logo/harness/node_modules/playwright/` (one `..` up from `brandbook/harness/` to `brandbook/`).
- **Files modified:** `brandbook/harness/verify-brandbook.mjs`
- **Commit:** 09bf64e5

**2. [Rule 1 - Bug] Playwright CommonJS default import**
- **Found during:** Task 3 execution (first run of verify-brandbook.mjs)
- **Issue:** `import { chromium } from "..."` fails because Playwright's `index.js` is a CommonJS module, not ESM. Node throws "Named export 'chromium' not found."
- **Fix:** Changed to `import playwrightPkg from "..."; const { chromium } = playwrightPkg;`
- **Files modified:** `brandbook/harness/verify-brandbook.mjs`
- **Commit:** 09bf64e5

## Known Stubs

None. All source materials are read from real committed files; the assembled HTML contains actual brand content; the verifier runs real Playwright assertions.

## Threat Flags

No new threat surface introduced. Phase 186 produces dev scripts only — no network endpoints, no auth paths, no schema changes.

T-186-01 and T-186-02 mitigations both implemented and verified:
- T-186-01: `stripScriptElements()` strips `<script>` from SVG content before embedding in HTML
- T-186-02: verify gate asserts zero `(src|href)=["']...https?://...["']` matches in committed HTML

## Self-Check: PASSED

Files exist:
- `brandbook/harness/package.json` ✓
- `brandbook/harness/assemble.mjs` ✓
- `brandbook/harness/verify-brandbook.mjs` ✓
- `brandbook/index.html` (127 KB) ✓
- 4 QA screenshots ✓

Commits exist:
- `baf9c62c` — chore(186-01): add brandbook/harness/package.json ✓
- `8cf4fe13` — feat(186-01): add assemble.mjs — deterministic HTML brand book assembler ✓
- `09bf64e5` — feat(186-01): add verify-brandbook.mjs + 4 QA screenshots ✓
