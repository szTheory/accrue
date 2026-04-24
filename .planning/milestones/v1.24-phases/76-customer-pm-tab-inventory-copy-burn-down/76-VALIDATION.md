---
phase: 76
slug: customer-pm-tab-inventory-copy-burn-down
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 76 — Validation Strategy

> ExUnit-first validation for customer **`payment_methods`** tab copy work (**ADM-13**, **ADM-14**).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue_admin`) |
| **Config file** | `accrue_admin/config/test.exs` (transitive) |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs` |
| **Full suite command** | `cd accrue_admin && mix test` |
| **Estimated runtime** | ~30–120 seconds (machine dependent) |

---

## Sampling Rate

- **After every task touching LiveView or Copy:** `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs`
- **After every plan wave:** `cd accrue_admin && mix test`
- **If `mix accrue_admin.export_copy_strings` is run:** Re-run host **`accrue_host_verify_browser.sh`** or full CI slice per `scripts/ci/README.md` when preparing merge

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 76-01-01 | 01 | 1 | ADM-13 | T-76-01 / — | No secrets in verification markdown | manual+grep | `rg -q 'ADM-13' .planning/phases/76-customer-pm-tab-inventory-copy-burn-down/76-VERIFICATION.md` | ✅ | ⬜ pending |
| 76-02-01 | 02 | 2 | ADM-14 | T-76-02 / — | Copy-only UX; no new PII logging | unit | `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- [x] Existing **`accrue_admin`** test stack covers **`CustomerLive`** — no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guide stub reads correctly on GitHub / ExDoc | ADM-13 | Link targets relative to repo | Open `accrue_admin/guides/` stub and confirm link resolves to `76-VERIFICATION.md`. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter when phase execution closes

**Approval:** pending
