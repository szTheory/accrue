---
phase: 186
slug: html-brand-book-assembly-quality-gate
status: final
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-14
---

# Phase 186 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js scripts + Playwright (already installed under `brandbook/logo/harness/node_modules/`; imported by relative path — no new install) |
| **Config file** | none — reuse existing harness Playwright |
| **Quick run command** | `node brandbook/harness/verify-brandbook.mjs` (structural gates: file:// open, no external src/href, no-JS-framework, dark-mode attr, section IDs, ≤2MB tracked weight) |
| **Full suite command** | `node brandbook/harness/verify-brandbook.mjs` (same script; also produces the light/dark × 360px/desktop screenshot matrix — 4 PNGs) |
| **Estimated runtime** | ~10–20 seconds (Playwright launch + 4 screenshots) |

---

## Sampling Rate

- **After every task commit:** Run the verifier's structural gates (Plan 01 authors them; Plan 02 runs them against the produced `index.html`).
- **After every plan wave:** Run `node brandbook/harness/verify-brandbook.mjs` (gates + screenshot matrix).
- **Before `/gsd:verify-work`:** Verifier green (`VERIFY_BRANDBOOK_OK`, exit 0) AND human Phase-180 quality-gate sign-off (BOOK-02).
- **Max feedback latency:** ~20 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 186-01-01 | 01 | 1 | BOOK-01 | — | static file, no inputs/network | unit | `node -e "JSON.parse(fs.readFileSync('brandbook/harness/package.json'))"` | ❌ W1-built | ⬜ pending |
| 186-01-02 | 01 | 1 | BOOK-01 | T-186-01 (no external SVG refs) | assembler rejects external `src`/`href` | integration | `node brandbook/harness/assemble.mjs && test -f brandbook/index.html` | ❌ W1-built | ⬜ pending |
| 186-01-03 | 01 | 1 | BOOK-01, BOOK-02 | T-186-01/02 | verifier asserts no-network + ≤2MB | integration | `test -f brandbook/index.html && node brandbook/harness/verify-brandbook.mjs` | ❌ W1-built | ⬜ pending |
| 186-02-01 | 02 | 2 | BOOK-01 | — | deterministic, idempotent output | integration | `node brandbook/harness/assemble.mjs && git diff --exit-code brandbook/index.html` | ❌ W1-built | ⬜ pending |
| 186-02-02 | 02 | 2 | BOOK-01, BOOK-02 | T-186-02 (no external network leak) | `VERIFY_BRANDBOOK_OK` + 4 screenshots + ≤2MB | integration | `node brandbook/harness/verify-brandbook.mjs && echo VERIFY_EXIT_0` | ❌ W1-built | ⬜ pending |
| 186-03-01 | 03 | 3 | BOOK-02 | — | n/a — human judgment | checkpoint:human-verify | N/A (exempt — subjective quality-gate review) | — | ⬜ pending |
| 186-03-02 | 03 | 3 | BOOK-02 | — | sign-off artifact present | unit | `test -f .planning/phases/186-html-brand-book-assembly-quality-gate/BOOK-02-SIGN-OFF.md && grep -q QUALITY_GATE_PASSED .planning/phases/186-html-brand-book-assembly-quality-gate/BOOK-02-SIGN-OFF.md` | ❌ W3-built | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Sampling continuity: every non-checkpoint task carries an `<automated>` verify — no window of 3 consecutive tasks lacks automated feedback.*

---

## Wave 0 Requirements

No pre-execution Wave 0 staging is required:

- **Playwright** — already installed at `brandbook/logo/harness/node_modules/playwright` (imported by relative path). No install.
- **Verifier harness** (`brandbook/harness/verify-brandbook.mjs`) — not pre-existing; it is the FIRST deliverable, created as task `186-01-03` in Wave 1, before any task consumes it (`186-02-*` depend on `186-01`). This satisfies the "test infra exists before it's exercised" rule via the wave dependency chain rather than a separate Wave 0.

*Wave 0 complete: nothing to pre-stage — infrastructure is either already installed or built as the first Wave-1 task ahead of its consumers.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Phase-180 quality-gate sign-off (designer-buildable / engineer-implementable / specific-to-Accrue / no-thrash) | BOOK-02 | Subjective design-quality judgment — cannot be mechanically asserted | User opens `brandbook/index.html` via file://, toggles light/dark, reviews against the 6 criteria, then types approval; task `186-03-01` is `autonomous: false` |

*Automated checks cover the objective criteria: file://-open, no-network, ≤2MB tracked weight, light/dark render, ≥360px responsive.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (the one checkpoint task is exempt by design)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none missing — Playwright pre-installed; verifier built first in Wave 1)
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-14
