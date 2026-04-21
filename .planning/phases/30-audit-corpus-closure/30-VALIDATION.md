---
phase: 30
slug: audit-corpus-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-20
---

# Phase 30 — Validation Strategy

> Documentation-only phase: verification is **grep / file presence** on `.planning` artifacts.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — planning corpus only |
| **Config file** | none |
| **Quick run command** | `rg "COPY-0[123]" .planning/phases/27-microcopy-and-operator-strings/27-VERIFICATION.md` |
| **Full suite command** | See § Verification commands below |
| **Estimated runtime** | &lt; 5 seconds |

---

## Sampling Rate

- **After every task commit:** Run the plan task’s `<acceptance_criteria>` rg commands
- **After every plan wave:** Run full § Verification commands
- **Before `/gsd-verify-work`:** All grep checks green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 30-01-01 | 01 | 1 | COPY-01..03 | T-30-01-01 / — | N/A (docs) | grep | `rg "COPY-01" .planning/phases/27-microcopy-and-operator-strings/27-VERIFICATION.md` | ✅ | ⬜ pending |
| 30-02-01 | 02 | 1 | UX-01..04 | — | N/A | grep | `rg "requirements-completed: \\[UX-01\\]" .planning/phases/26-hierarchy-and-pattern-alignment/26-01-SUMMARY.md` | ✅ | ⬜ pending |
| 30-02-02 | 02 | 1 | MOB-01..03 | — | N/A | grep | `rg "requirements-completed:" .planning/phases/29-mobile-parity-and-ci/29-01-SUMMARY.md` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements (no new code or test harness).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| _None_ | — | — | — |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or grep-only acceptance
- [ ] Sampling continuity: doc tasks each have rg criteria
- [ ] No watch-mode flags
- [ ] Feedback latency &lt; 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
