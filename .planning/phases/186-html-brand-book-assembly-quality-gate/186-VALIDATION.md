---
phase: 186
slug: html-brand-book-assembly-quality-gate
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
---

# Phase 186 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js script + Playwright (already installed under `brandbook/logo/harness/node_modules/`) |
| **Config file** | none — reuse existing harness Playwright |
| **Quick run command** | `node brandbook/harness/verify-brandbook.mjs` (assertions: file:// open, no external src, ≤2MB tracked weight) |
| **Full suite command** | `node brandbook/harness/verify-brandbook.mjs --screenshots` (light/dark × ≥360px/desktop matrix) |
| **Estimated runtime** | ~10–20 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick verify (structural assertions)
- **After every plan wave:** Run full verify with screenshot matrix
- **Before `/gsd:verify-work`:** Full suite green + human UAT sign-off
- **Max feedback latency:** ~20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 186-01-01 | 01 | 1 | BOOK-01 | — | static file, no inputs/network | integration | `node brandbook/harness/verify-brandbook.mjs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky — planner refines this map.*

---

## Wave 0 Requirements

- [ ] `brandbook/harness/verify-brandbook.mjs` — assembly + quality-gate verifier (imports Playwright from existing harness node_modules)

*Planner finalizes Wave 0 scope.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Phase-180 quality-gate sign-off (designer-buildable / engineer-implementable / specific-to-Accrue / no-thrash) | BOOK-02 | Subjective design-quality judgment | User opens `brandbook/index.html` via file://, reviews against the 6 criteria, signs off |

*Automated checks cover file://-open, no-network, ≤2MB, light/dark render, ≥360px responsive.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
