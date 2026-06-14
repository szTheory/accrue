---
phase: 180
slug: brand-audit-dna-lock
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-11
---

# Phase 180 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — writing phase; contrast script is the only automation |
| **Config file** | none |
| **Quick run command** | `node .planning/phases/180-brand-audit-dna-lock/artifacts/contrast.js` |
| **Full suite command** | `node .planning/phases/180-brand-audit-dna-lock/artifacts/contrast.js` |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run `node .planning/phases/180-brand-audit-dna-lock/artifacts/contrast.js`
- **After every plan wave:** Run `node .planning/phases/180-brand-audit-dna-lock/artifacts/contrast.js`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~1 second

> Phase 180 produces Markdown artifacts with no test framework. Automated checks are grep assertions only.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 180-01-01 | 01 | 1 | AUD-03 | T-180-01 | Script exits 0, emits 21 rows | cli | `node artifacts/contrast.js \| grep -c "vs "` == 21 | ❌ W0 | pending |
| 180-01-02 | 01 | 1 | AUD-03 | T-180-01 | Paper vs Moss row = 3.03:1 | grep | `grep -q "Paper vs Moss: 3.03:1" artifacts/contrast-table.txt` | ❌ W0 | pending |
| 180-02-01 | 02 | 2 | AUD-01 | T-180-03 | BRAND-AUDIT.md §1–§4 substantive | grep | `grep -q "No rectangular background" BRAND-AUDIT.md` | ❌ W0 | pending |
| 180-02-02 | 02 | 2 | AUD-01/AUD-03 | T-180-03 | §5–§8 complete, --accrue-* documented | grep | `grep -q "\-\-accrue-ink" BRAND-AUDIT.md` | ❌ W0 | pending |
| 180-03-01 | 03 | 3 | AUD-01 | T-180-04 | §9–§14 authored, status: ratified | grep | `grep -q "§14" BRAND-AUDIT.md && grep -q "status: ratified" BRAND-AUDIT.md` | ❌ W0 | pending |
| 180-03-02 | 03 | 3 | AUD-02 | T-180-06/07 | DNA/brief/checklist created | grep | `test -f BRAND-DNA.md && test -f logo-brief.md && test -f quality-gate-checklist.md` | ❌ W0 | pending |
| 180-04-CP | 04 | 4 | AUD-02 | — | User ratified all artifacts | manual | AskUserQuestion checkpoint | ❌ W0 | pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

*Phase 180 is a writing/analysis phase. No test framework is installed — the contrast.js script at `artifacts/contrast.js` is the only automation. All other verification is grep-based or manual checkpoint.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| User ratification | AUD-02 | Human decision required | Type "All items resolved" after reviewing all four artifacts at the checkpoint |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 1s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-12
