---
phase: 50
slug: copy-tokens-verify-gates
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 50 — Validation Strategy

> Per-phase validation contract for **ADM-04..ADM-06** — Mix/ExUnit + host Playwright (**VERIFY-01**).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue_admin`, `accrue`) + Playwright (`examples/accrue_host`) |
| **Config** | `accrue_admin/mix.exs`, `examples/accrue_host/playwright.config.js` |
| **Quick run (admin)** | `cd accrue_admin && mix compile --warnings-as-errors && mix test` |
| **Full admin slice** | `cd accrue_admin && mix test test/accrue_admin/live/` |
| **Host e2e** | `cd examples/accrue_host && npm ci && npm run e2e` (or repo-documented scoped script) |
| **Estimated runtime** | ~2–8 minutes depending on host e2e matrix |

---

## Sampling Rate

- **After every task commit:** `cd accrue_admin && mix compile --warnings-as-errors`
- **After Copy-affecting tasks:** `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` (extend if new test files)
- **After e2e plan tasks:** Host **`npm run e2e`** (or CI-equivalent) with fixture seed per **`e2e/support/fixture.js`**
- **Before `/gsd-verify-work`:** Full gates in **`50-VERIFICATION.md`**

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 50-01-01 | 01 | 1 | ADM-05 | — | N/A | doc grep | `test -f accrue_admin/guides/theme-exceptions.md` | ✅ | ⬜ |
| 50-01-02 | 01 | 1 | ADM-05 / D-15 | — | N/A | doc grep | `test -f examples/accrue_host/docs/verify01-v112-admin-paths.md` | ✅ | ⬜ |
| 50-02-01 | 02 | 1 | ADM-04 | T-copy-01 | No secrets in Copy exports | compile | `cd accrue_admin && mix compile --warnings-as-errors` | ✅ | ⬜ |
| 50-02-02 | 02 | 1 | ADM-04 | — | N/A | unit | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` | ✅ | ⬜ |
| 50-03-01 | 03 | 2 | ADM-06 / D-23 | — | Export allowlist only | mix | `cd accrue_admin && mix accrue_admin.export_copy_strings --help` or successful run | W0 | ⬜ |
| 50-03-02 | 03 | 2 | ADM-06 | T-e2e-01 | Fixture uses synthetic data only | e2e | `cd examples/accrue_host && npm run e2e` | ✅ | ⬜ |

*Status: ⬜ pending · ✅ green · ❌ red*

---

## Wave 0 Requirements

**Existing infrastructure covers all phase requirements** — Mix, ExUnit, Playwright, and `@axe-core/playwright` are already wired (**Phase 48/49**). No new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Theme row accuracy | ADM-05 | Design intent | PR author confirms each **`theme-exceptions.md`** row matches code |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or documented compile gate
- [ ] No watch-mode flags in CI commands
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
