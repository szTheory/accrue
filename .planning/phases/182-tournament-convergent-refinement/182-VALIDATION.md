---
phase: 182
slug: tournament-convergent-refinement
status: active
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
---

# Phase 182 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | node (ESM inline scripts) + grep/wc shell checks, Playwright via render-matrix |
| **Config file** | none — uses 181 harness node_modules (no separate config file needed) |
| **Quick run command** | `node -e "import('.../b-step-r2.mjs').then(m => { console.assert(m.R2_CONFIGS.length === 7); console.log('OK'); })"` (see per-task commands below) |
| **Full suite command** | `node .planning/phases/182-tournament-convergent-refinement/harness/generate-r2.mjs && node .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/render-matrix.mjs --output-dir .planning/phases/182-tournament-convergent-refinement && node .planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/build-gallery.mjs --output-dir .planning/phases/182-tournament-convergent-refinement --gallery-name round-2-gallery.html` |
| **Estimated runtime** | ~3–5 min (dominated by Playwright screenshot rendering across 7 candidates × 8 tiles) |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` verify command (listed in Per-Task map below)
- **After every plan wave:** Run the full suite command above
- **Before `/gsd:verify-work`:** Full suite must be green (gallery exists, self-review-r2.ndjson PASS, TOURNAMENT.md intact)
- **Max feedback latency:** ~5 min (Playwright-bound)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 182-01-T1 | 01 | 1 | LOGO-03 | T-182-02 | accentPathD inside existing mark `<g>` (no new transform) | node assertion | `node -e "import('.../b-step-r2.mjs').then(m => { console.assert(m.R2_CONFIGS.length===7); console.assert(m.generate(m.R2_CONFIGS[5]).accentPathD); console.log('OK'); })"` | ✅ | ⬜ pending |
| 182-01-T2 | 01 | 1 | LOGO-03 | T-182-01 | lint.mjs monoSvgString override prevents Moss SVG failing mono-deriv lint | node + grep | `node -e "const fs=await import('fs'); const s=fs.default.readFileSync('...lint.mjs','utf8'); console.assert(s.includes('monoSvgString')&&s.includes('--output-dir')); console.log('OK')" --input-type=module` | ✅ | ⬜ pending |
| 182-01-T3 | 01 | 1 | LOGO-03 | T-182-04 | WR-07 avatar-circle clip preserved in try/finally; WR-01 fullIndex prevents smoke clobber | grep | `grep -c 'fullIndex' ...render-matrix.mjs && grep -c 'border-radius: 50%' ...render-matrix.mjs && grep -c 'colorTreatment' ...build-gallery.mjs` | ✅ | ⬜ pending |
| 182-02-T1 | 02 | 2 | LOGO-03 | T-182-09 | Smoke run produces 1 candidate with no blank-render; buildMonoSvg imported (not re-implemented) | node pipeline | `grep -c 'class="candidate"' .../round-2-gallery.html` (expect ≥ 6) + `grep -c 'buildMonoSvg' .../generate-r2.mjs` (expect ≥ 1, import line) | ❌ W0 prereq | ⬜ pending |
| 182-02-T2 | 02 | 2 | LOGO-03 | T-182-10 | visual_verification=PASS before checkpoint; no score based on broken render | NDJSON check | `wc -l .../self-review-r2.ndjson` (≥ 24) + node meta-record check | ❌ W0 prereq | ⬜ pending |
| 182-02-T3 | 02 | 2 | LOGO-03 | T-182-06, T-182-07 | Round 1 block byte-identical after TOURNAMENT.md append | grep | `grep -c 'R1-C' .../TOURNAMENT.md` (≥ 4) + `grep -c 'WINNER LOCKED\|ROUND-3-APPEND-BELOW' .../TOURNAMENT.md` (≥ 1) | ❌ W0 prereq | ⬜ pending |
| 182-03-T1 | 03 | 3 | LOGO-03 | T-182-11, T-182-12 | LOCK: 182-FREEZE.md has Generator Config + Phase 183 Instructions; EXTEND: skip SUMMARY written, no FREEZE.md | grep (LOCK path) or skip check (EXTEND path) | `grep -c 'stepHeight' .../182-FREEZE.md && grep -c 'assembleLockup' .../182-FREEZE.md` (LOCK) OR `grep -c 'EXTEND Path' .../182-03-SUMMARY.md` (EXTEND) | ❌ W0 prereq | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*W0 prereq = task cannot run until earlier wave tasks complete (sequential dependency, not a missing test stub)*

---

## Wave 0 Requirements

No Wave 0 test stubs needed. This phase is a tooling pipeline (Node ESM orchestrator scripts) where verification is inline assertions and grep checks embedded directly in each task's `<automated>` block. There is no test framework to install, no conftest to scaffold, and no stub files to create before execution begins. The 181 harness `node_modules` (Playwright, pngjs, opentype.js) is the only runtime dependency and is already installed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Round 2 gallery visual judgment — user selects winner | LOGO-03 | Aesthetic decision requiring human eyes on rendered candidates across 8 context tiles | Open `round-2-gallery.html` via `file://` in a browser; review each candidate in all 8 tiles; respond to checkpoint with LOCK / EXTEND / SETTLE verdict |
| Social-card tile copy legibility at 600×315 | LOGO-03 | Visual proportionality judgment (mark size vs. copy size) | Inspect `screenshots/R2-{N}/social-card.png` for each candidate; mark should be comfortably smaller than the "accrue" heading text |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands (inline assertions and grep checks)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (each task has its own verify block)
- [x] Wave 0: not needed — see Wave 0 section above
- [x] No watch-mode flags (all verify commands are one-shot)
- [x] Feedback latency: quick checks < 5s; full Playwright pipeline ~3–5 min
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
