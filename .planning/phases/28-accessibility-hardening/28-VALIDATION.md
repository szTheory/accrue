---
phase: 28
slug: accessibility-hardening
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-20
---

# Phase 28 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue_admin`) + Playwright (`examples/accrue_host`) |
| **Config file** | `accrue_admin/test/test_helper.exs`; `examples/accrue_host/playwright.config.js` (if present) or package defaults |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs` (swap file per plan) |
| **Full suite command** | `cd accrue_admin && mix test` then `cd examples/accrue_host && npm run e2e -- e2e/verify01-admin-a11y.spec.js` (after Plan 03 adds spec) |
| **Estimated runtime** | ~60–180 seconds combined |

---

## Sampling Rate

- **After every task commit:** Run the plan’s `<automated>` command for touched tests
- **After every plan wave:** Wave 1 → `mix test` on touched `accrue_admin` paths; Wave 2 → host a11y Playwright spec
- **Before `/gsd-verify-work`:** `accrue_admin` full package tests + host a11y spec green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 28-01-* | 01 | 1 | A11Y-01 | T-28-01 | No new secret-bearing UI strings | unit | `cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs` (+ invoice/subscription as touched) | ✅ | ⬜ pending |
| 28-02-* | 02 | 1 | A11Y-02 | T-28-02 | Caption text from `Copy` only | unit | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs` + live tests for customers/webhooks | ✅ | ⬜ pending |
| 28-03-* | 03 | 2 | A11Y-03 / A11Y-04 | T-28-03 | Axe runs on authenticated path only | e2e | `cd examples/accrue_host && npm run e2e -- e2e/verify01-admin-a11y.spec.js` | ⬜ after Plan 03 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] **Existing infrastructure** — ExUnit stack and host Playwright + `@axe-core/playwright` dependency already present; Plan 03 adds the spec file.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Gradient / image contrast | A11Y-03 | Axe under-resolves non-solid backgrounds | Follow bullet checklist in `28-CONTEXT.md` D-04 after token changes |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or documented manual-only row above
- [ ] Sampling continuity: no three consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references — N/A (pre-existing)
- [ ] No watch-mode flags in CI commands
- [ ] Feedback latency under 180s for documented suite slice
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
