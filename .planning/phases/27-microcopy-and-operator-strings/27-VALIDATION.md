---
phase: 27
slug: microcopy-and-operator-strings
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-20
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `accrue_admin/test/test_helper.exs` |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/<module>_live_test.exs` (per plan) |
| **Full suite command** | `cd accrue_admin && mix test` |
| **Estimated runtime** | ~60–120 seconds (package scope) |

---

## Sampling Rate

- **After every task commit:** Run the plan’s `<automated>` command for touched LiveView tests
- **After every plan wave:** `cd accrue_admin && mix test`
- **Before `/gsd-verify-work`:** Full `accrue_admin` suite green; host `examples/accrue_host` Playwright only when plan modifies E2E-locked literals
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 1 | COPY-01 / COPY-03 | T-27-01 | No new unescaped operator content | unit | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs` (add if missing) + index tests | ✅ | ⬜ pending |
| 27-01-02 | 01 | 1 | COPY-01 | T-27-01 | N/A | unit | `cd accrue_admin && mix test test/accrue_admin/live/customers_live_test.exs` (etc.) | ✅ | ⬜ pending |
| 27-02-* | 02 | 2 | COPY-02 | T-27-02 | Flash strings remain non-secret | unit | `cd accrue_admin && mix test` (detail live tests) | ✅ | ⬜ pending |
| 27-03-* | 03 | 3 | COPY-02 / COPY-03 | T-27-03 | Locked replay/org denial verbatim | unit + e2e | `mix test` + optional `npm test` / `npx playwright test` under `examples/accrue_host` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] **Existing infrastructure** — `accrue_admin` ExUnit + host Playwright already cover mounted admin; no new framework install for Phase 27.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Tone read-through (Tier A) | COPY-01 | Subjective voice check | Spot-check rendered pages in dev against `20-UI-SPEC.md` / `21-UI-SPEC.md` tone rules |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or documented host E2E when literals change
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references — N/A (pre-existing)
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
