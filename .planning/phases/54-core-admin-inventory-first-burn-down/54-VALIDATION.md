---
phase: 54
slug: core-admin-inventory-first-burn-down
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 54 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (Elixir / Phoenix / LiveView).

---

## Test Infrastructure

| Property | Value |
|----------|--------|
| **Framework** | ExUnit (`accrue_admin` test app) |
| **Config file** | `accrue_admin/config/test.exs` (transitive) |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs` |
| **Full suite command** | `cd accrue_admin && mix test` |
| **Estimated runtime** | Quick: ~15–45s; full `accrue_admin`: ~2–4min (environment dependent) |

**Monorepo note:** There is **no** root `mix.exs`; the **`accrue_admin`** package is a sibling project — always **`cd accrue_admin`** before **`mix`** commands.

---

## Sampling Rate

- **After every ADM-08 task commit:** Run the **quick** invoice LiveView tests.
- **After wave 1 (plan 01) docs commit:** `cd accrue_admin && mix compile` — **0** errors.
- **Before `/gsd-verify-work`:** `cd accrue_admin && mix test` — green.
- **Max feedback latency:** 120s for quick loop target.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 54-01-01 | 01 | 1 | ADM-07 | — | Docs only — no secrets in matrix | compile check | `mix compile` in `accrue_admin` | ✅ | ⬜ pending |
| 54-01-02 | 01 | 1 | ADM-07 | — | Docs only | grep extras | `rg "core-admin-parity" accrue_admin/mix.exs` | ✅ | ⬜ pending |
| 54-02-01 | 02 | 2 | ADM-08 | T54-Literal | No PII in Copy strings | unit | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs` | ✅ | ⬜ pending |
| 54-02-02 | 02 | 2 | ADM-08 | T54-Literal | Step-up copy stays non-leaky | unit | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements** — no new framework stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Invoice chrome readability | ADM-08 | Visual/heuristic | Boot `examples/accrue_host`, visit `/billing/invoices` and one detail — confirm headings/KPIs read correctly after Copy migration. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or compile/docs checks
- [ ] Sampling continuity: ADM-08 tasks run invoice tests between edits
- [ ] No watch-mode flags in commands
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
