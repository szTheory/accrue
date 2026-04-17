---
phase: 21-admin-and-host-ux-proof
slug: admin-and-host-ux-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-17
---

# Phase 21 — Validation Strategy

> Feedback sampling for VERIFY-01 executable proof (Fake-backed, host + admin + browser).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + Playwright (Node) |
| **Config file** | `examples/accrue_host/playwright.config.js` |
| **Quick run command** | `cd accrue_admin && mix test --warnings-as-errors` (focused modules after each admin task) |
| **Host integration** | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors` |
| **Browser suite** | `cd examples/accrue_host && npx playwright test` |
| **Estimated runtime** | ~2–8 minutes depending on Playwright project count |

---

## Sampling Rate

- **After every admin LiveView task:** Run the plan’s `<automated>` `mix test` paths.
- **After seed/fixture change:** Run `phase13-canonical-demo.spec.js` + any new specs touching the fixture.
- **After each Playwright plan wave:** Full `npx playwright test` (or tagged subset if configured).
- **Before phase close:** Admin focused suite + host `mix test` + Playwright Chromium project green.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 1 | VERIFY-01 | T-21-01 | Fixture has no secrets beyond test passwords | integration | `host-integration` / `mix verify.full` (seed + `verify_e2e_fixture_jq.sh`) | ✅ | ✅ |
| 21-02-01 | 02 | 2 | VERIFY-01 | T-21-02 | Browser does not bypass org scope | e2e | `host-integration` Playwright (`examples/accrue_host/e2e`) | ✅ | ✅ |
| 21-03-01 | 03 | 1 | VERIFY-01 | T-21-03 | Classifier does not leak cross-owner labels | unit | `cd accrue_admin && mix test --warnings-as-errors` (plan paths) | ✅ | ✅ |
| 21-04-01 | 04 | 3 | VERIFY-01 | T-21-04 | Index rows do not show wrong-owner data | unit | `cd accrue_admin && mix test --warnings-as-errors` (index live tests) | ✅ | ✅ |
| 21-05-01 | 05 | 3 | VERIFY-01 | T-21-05 | Detail card matches list signals | unit | `cd accrue_admin && mix test --warnings-as-errors` (detail live tests) | ✅ | ✅ |
| 21-06-01 | 06 | 4 | VERIFY-01 | T-21-06 | Host facades only | integration | `host-integration` / `mix verify` + full regression | ✅ | ✅ |

---

## Wave 0 Requirements

Existing infrastructure covers requirements: Mix, Playwright, seed script present. Phase 21 extends them — no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual screenshot for marketing / README | VERIFY-01 | Optional artifact | Run Playwright with `screenshot` in headed mode locally if README needs updated images |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify (manifest: `21-UAT.md`; CI: `host-integration`)
- [x] Sampling continuity maintained across waves
- [x] No watch-mode flags in CI commands
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** CI-backed (VERIFY-01 = `mix verify.full` + README contract gate)
