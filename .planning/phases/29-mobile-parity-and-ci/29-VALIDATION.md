---
phase: 29
slug: mobile-parity-and-ci
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-20
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright (Node, `@playwright/test`) |
| **Config file** | `examples/accrue_host/playwright.config.js` |
| **Quick run command** | `cd examples/accrue_host && npx playwright test e2e/verify01-admin-mobile.spec.js --project=chromium-mobile` |
| **Full suite command** | `cd examples/accrue_host && npm run e2e` (or `bash scripts/ci/accrue_host_verify_browser.sh` from repo root) |
| **Estimated runtime** | ~120–300s full e2e (webServer boot); mobile-only file ~30–90s additional within full run |

---

## Sampling Rate

- **After every task commit:** Quick run on `chromium-mobile` for the MOB spec file (or grep that changed files are covered).
- **After every plan wave:** `npm run e2e` from `examples/accrue_host` when Playwright assets changed.
- **Before `/gsd-verify-work`:** Full browser lane green per VERIFY-01 docs.
- **Max feedback latency:** Bounded by single `chromium-mobile` file pass when iterating.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 29-01-01 | 01 | 1 | MOB-01 | — | N/A | e2e helper | `npx playwright test e2e/phase13-canonical-demo.spec.js --project=chromium-desktop` | ✅ | ⬜ pending |
| 29-02-01 | 02 | 2 | MOB-01, MOB-03 | — | N/A | e2e | `npx playwright test e2e/verify01-admin-mobile.spec.js --project=chromium-mobile` | ❌ W0 | ⬜ pending |
| 29-02-02 | 02 | 2 | MOB-02 | — | N/A | e2e | same as 29-02-01 | ❌ W0 | ⬜ pending |
| 29-03-01 | 03 | 2 | MOB-02 | — | N/A | doc | `grep -F "Mounted admin — mobile shell" examples/accrue_host/README.md` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements — Playwright + host seed scripts already present; no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Drawer animation polish | MOB-02 | Pixel-perfect motion not asserted | Optional: run `npm run e2e:visuals` and eyeball `chromium-mobile` trace |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable for host e2e
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
