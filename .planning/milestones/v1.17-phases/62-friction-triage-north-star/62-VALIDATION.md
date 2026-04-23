---
phase: 62
slug: friction-triage-north-star
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-23
---

# Phase 62 — Validation Strategy

> Markdown-first phase: verification is grep + scripted CI contracts + checklist closure, not ExUnit as primary gate.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — planning artifacts only |
| **Config file** | n/a |
| **Quick run command** | `rg "v1\\.17-P0-|frg03_disposition" .planning/research/v1.17-FRICTION-INVENTORY.md` |
| **Full suite command** | `bash scripts/ci/verify_package_docs.sh` (only if plans touch `accrue/` or `accrue_admin/` package docs) |
| **Estimated runtime** | \< 60 seconds |

---

## Sampling Rate

- **After every task commit:** Quick `rg` checks from the task’s `<acceptance_criteria>`.
- **After every plan wave:** Re-read inventory P0 table + FRG-03 disposition column.
- **Before `/gsd-verify-work`:** REQUIREMENTS FRG-01..03 checkboxes + ROADMAP Phase 62 success criteria satisfied.
- **Max feedback latency:** 60 seconds per verify invocation.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 62-01-01 | 01 | 1 | FRG-01 | T-62-01 / — | No secrets in `sources` cells | grep | `rg "Inventory table" .planning/research/v1.17-FRICTION-INVENTORY.md` | ✅ | ⬜ pending |
| 62-02-01 | 02 | 1 | FRG-02 | — | Pointers only in PROJECT/STATE | grep | `rg "v1\\.17-north-star" .planning/PROJECT.md .planning/STATE.md` | ✅ | ⬜ pending |
| 62-03-01 | 03 | 2 | FRG-03 | T-62-03 / — | Signed rationale for any `not_v1.17` | manual+grep | `rg "not_v1\\.17|→6[345]" .planning/research/v1.17-FRICTION-INVENTORY.md` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements.** No new test stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| P0 triage bar soundness | FRG-01 | Judgment on two-axis labels | Maintainer reads each P0 row against **D-02a** in **62-CONTEXT.md** |
| “Zero P0” certification | FRG-03 | Only if inventory has no P0 rows | If no `v1.17-P0-` rows, confirm a signed paragraph states **evidence scan found zero P0s** and links to sources scanned |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or manual table above
- [x] Sampling continuity: planning phase uses doc grep between tasks
- [x] Wave 0 covers all MISSING references — n/a (no W0)
- [x] No watch-mode flags
- [x] Feedback latency \< 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution wave
