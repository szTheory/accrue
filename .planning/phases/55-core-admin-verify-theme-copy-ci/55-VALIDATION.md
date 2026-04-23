---
phase: 55
slug: core-admin-verify-theme-copy-ci
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 55 — Validation strategy

> Per-phase validation contract for **ADM-09** / **ADM-10** / **ADM-11** (VERIFY-01 invoice anchor, theme SSOT, copy export).

---

## Test infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright **1.57** + `@axe-core/playwright` **4.11** |
| **Config file** | `examples/accrue_host/playwright.config.js` (host app) |
| **Quick run command** | `cd examples/accrue_host && npm run e2e:a11y` (after export — see README) |
| **Full suite command** | `bash scripts/ci/accrue_host_verify_browser.sh` (repo root) |
| **Estimated runtime** | ~3–8 minutes (depends on CI cold start) |

---

## Sampling rate

- **After every task touching Elixir seed, Copy, export task, or generated JSON:** `cd accrue_admin && mix compile && mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json`
- **After every Playwright edit:** `npm run e2e:a11y` from `examples/accrue_host` with **`ACCRUE_HOST_E2E_FIXTURE`** set per README **or** full **`accrue_host_verify_browser.sh`**
- **Before merge:** `bash scripts/ci/accrue_host_verify_browser.sh` exits **0**
- **Max feedback latency:** bounded by full browser script (prefer targeted grep checks between iterations)

---

## Per-task verification map

| Task ID | Plan | Wave | Requirement | Threat ref | Secure behavior | Test type | Automated command | File exists | Status |
|---------|------|------|---------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 55-01-01 | 01 | 1 | ADM-09 | T-55-01 | Fixture auth only; no live Stripe | e2e + axe | `bash scripts/ci/accrue_host_verify_browser.sh` | ✅ | ⬜ pending |
| 55-01-02 | 01 | 1 | ADM-11 | — | JSON is operator copy only | allowlist + JSON | `rg` copyStrings ⊆ allowlist (per plan) | ✅ | ⬜ pending |
| 55-02-01 | 02 | 2 | ADM-09 | — | N/A (docs) | grep | `rg core-admin-invoices-(index|detail) accrue_admin/guides/core-admin-parity.md` | ✅ | ⬜ pending |
| 55-02-02 | 02 | 2 | ADM-10 | — | N/A | grep | `rg theme-exceptions.md accrue_admin/guides/admin_ui.md` | ✅ | ⬜ pending |
| 55-02-03 | 02 | 2 | ADM-09 | — | N/A | grep / optional script | plan-defined `bash scripts/ci/verify_*` if added | ✅ / optional | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red*

---

## Wave 0 requirements

- [x] Existing infrastructure covers all phase requirements (`verify01-admin-a11y.spec.js`, `export_copy_strings`, CI browser script).

---

## Manual-only verifications

| Behavior | Requirement | Why manual | Test instructions |
|----------|-------------|------------|-------------------|
| Playwright HTML report sanity | ADM-09 | Optional human spot-check of traces | Open `playwright-report` after local failure; confirm `@core-admin-invoices-*` filters |

---

## Validation sign-off

- [ ] All tasks have `<automated>` verify or documented grep acceptance
- [ ] Sampling continuity: invoice tasks run browser lane or strict grep substitutes
- [ ] No watch-mode flags in CI commands
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
