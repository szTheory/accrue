---
phase: 25
slug: admin-ux-inventory
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-20
---

# Phase 25 — Validation Strategy

> Per-phase validation for maintainer inventory artifacts (markdown + optional `mix phx.routes`).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Mix (Elixir) + grep |
| **Config file** | `examples/accrue_host/mix.exs` (reference app for routes) |
| **Quick run command** | `rg '_TBD_' .planning/phases/25-admin-ux-inventory/25-INV-*.md \|\| test $? -eq 1` |
| **Full suite command** | `cd examples/accrue_host && mix phx.routes` (compare to INV-01) |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Quick grep for `_TBD_` on modified INV files
- **After plan wave 1 (INV-01):** `mix phx.routes` spot-check vs matrix
- **Before `/gsd-verify-work`:** No `_TBD_` in any `25-INV-*.md`; snapshot headers present on all three
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 1 | INV-01 | T-25-01 / — | No secrets in markdown | grep | `rg '_TBD_' 25-INV-01-route-matrix.md \|\| test $? -eq 1` | ✅ | ⬜ pending |
| 25-01-02 | 01 | 1 | INV-01 | — | N/A | cli | `cd examples/accrue_host && mix phx.routes` | ✅ | ⬜ pending |
| 25-02-01 | 02 | 1 | INV-02 | — | N/A | grep | `rg '_TBD_' 25-INV-02-component-coverage.md \|\| test $? -eq 1` | ✅ | ⬜ pending |
| 25-03-01 | 03 | 1 | INV-03 | — | N/A | grep | `rg '_TBD_' 25-INV-03-spec-alignment.md \|\| test $? -eq 1` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing `mix phx.routes` + `rg` cover inventory verification — no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| INV-03 status judgments | INV-03 | Requires reading UI-SPECs + code | For each clause row, confirm Evidence column path exists or N/A rationale is one line |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or grep-equivalent acceptance criteria
- [ ] Sampling continuity: INV files checked after edits
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter after execution wave passes

**Approval:** pending
