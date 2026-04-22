---
phase: 49
slug: drill-flows-navigation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for **ADM-02** / **ADM-03** drill work (**ExUnit** + mounted host smoke).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) |
| **Config file** | `accrue_admin/mix.exs`, `examples/accrue_host/mix.exs` |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` |
| **Full suite command** | `mix test` at repo root (or CI-equivalent: `accrue_admin` + `accrue_host` per workspace CI) |
| **Estimated runtime** | ~2–5 minutes local (depends on machine) |

---

## Sampling Rate

- **After every task commit:** Run **`cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs`**
- **After wave 2 (host):** Run **`cd examples/accrue_host && mix test test/accrue_host_web/admin_mount_test.exs`** (or full host suite if cheap)
- **Before `/gsd-verify-work`:** Full **`accrue_admin`** LiveView tests green for touched modules

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 49-01-01 | 01 | 1 | ADM-02 | T-nav-01 | Org slug preserved in customer/invoice/charge links | unit | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` | ✅ | ⬜ pending |
| 49-01-02 | 01 | 1 | ADM-02 | T-copy-01 | No new PII patterns in Copy beyond labels | unit | `cd accrue_admin && mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 49-02-01 | 02 | 2 | ADM-02 | T-mount-01 | Host-mounted subscription route reachable under auth | integration | `cd examples/accrue_host && mix test test/accrue_host_web/admin_mount_test.exs` | ✅ | ⬜ pending |
| 49-02-02 | 02 | 2 | ADM-03 | — | README/router alignment note only | doc grep | `rg -n 'sidebar|router' accrue_admin/README.md` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- [x] Existing **`LiveCase`** + **`ConnCase`** cover this phase — **no** new test framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Visual breadcrumb spacing | ADM-02 | Browser chrome | Open **`/subscriptions/:id`** in dev — confirm crumb spacing matches **`InvoiceLive`** |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or documented grep gates
- [ ] Sampling continuity: LiveView tests run after UI edits
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
