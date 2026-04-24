---
phase: 77
slug: customer-pm-tab-verify-theme-copy-export
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 77 — Validation Strategy

> Per-phase validation contract for **ADM-15** (VERIFY-01 + axe + customer PM route) and **ADM-16** (theme register / copy export alignment).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright (host `examples/accrue_host`) + Mix (accrue_admin export task) |
| **Config file** | `examples/accrue_host/playwright.config.js` (implicit) |
| **Quick run command** | `cd examples/accrue_host && npx playwright test e2e/verify01-admin-a11y.spec.js --grep "payment_methods"` |
| **Full suite command** | `bash scripts/ci/accrue_host_verify_browser.sh` (from repo root) |
| **Estimated runtime** | ~3–8 minutes (browser script; depends on cold compile) |

---

## Sampling Rate

- **After every task commit touching Playwright or Copy:** Run quick Playwright grep command above **or** full `accrue_host_verify_browser.sh` before pushing.
- **After every plan wave:** Full browser script on release-critical merges.
- **Before `/gsd-verify-work`:** `accrue_host_verify_browser.sh` green (or documented skip env).
- **Max feedback latency:** Bounded by CI job (acceptable for VERIFY phases).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 77-01-01 | 01 | 1 | ADM-15 | T-77-01 | No secrets in Playwright logs; fixture path from env only | e2e | `cd examples/accrue_host && npx playwright test e2e/verify01-admin-a11y.spec.js --grep "payment_methods"` | ✅ | ⬜ pending |
| 77-01-02 | 01 | 1 | ADM-15 | T-77-02 | Doc matrix uses placeholders not live IDs | static | `rg -nF "ADM-15" examples/accrue_host/docs/verify01-v112-admin-paths.md` | ✅ | ⬜ pending |
| 77-02-01 | 02 | 2 | ADM-16 | T-77-03 | Theme doc: no PAN/CVC pasted | static | `rg -n "Phase 77" accrue_admin/guides/theme-exceptions.md` | ✅ | ⬜ pending |
| 77-02-02 | 02 | 2 | ADM-16 | — | Mix export deterministic | mix | `cd accrue_admin && mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements.** No new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | — | All behaviors have automated or `rg`-verifiable checks |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or static `rg` gates
- [ ] Sampling continuity: Playwright run after PM-tab test lands
- [ ] Wave 0 N/A — satisfied
- [ ] No watch-mode flags in commands
- [ ] `nyquist_compliant: true` set in frontmatter when phase verified

**Approval:** pending
