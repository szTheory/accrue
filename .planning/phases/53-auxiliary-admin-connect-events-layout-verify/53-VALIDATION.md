---
phase: 53
slug: auxiliary-admin-connect-events-layout-verify
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-22
---

# Phase 53 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue`, `accrue_admin`, `accrue_host`) + Playwright (`examples/accrue_host/e2e`) |
| **Config file** | `examples/accrue_host/playwright.config.js` (Playwright); Mix per-app |
| **Quick run command** | `cd accrue_admin && mix test` |
| **Full suite command** | `bash scripts/ci/accrue_host_verify_browser.sh` (from repo root) |
| **Estimated runtime** | ~3–15 minutes depending on Playwright project set |

## Sampling Rate

- **After every task commit touching Copy or LiveView:** `cd accrue_admin && mix test` (or scoped `mix test path/to_test.exs` when added).
- **After plan wave 1 (Copy + HEEx):** `mix test` in `accrue_admin` + compile check.
- **After plan wave 2 (VERIFY):** `bash scripts/ci/accrue_host_verify_browser.sh` **or** equivalent export + `npm run e2e -- verify01-admin-a11y.spec.js`.
- **Before `/gsd-verify-work`:** `accrue_host_verify_browser.sh` exit **0**.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 53-01-01 | 01 | 1 | AUX-03, AUX-04, AUX-05 | — | No Stripe secrets in Copy literals | unit | `cd accrue_admin && mix test` | ✅ | ⬜ pending |
| 53-01-02 | 01 | 1 | AUX-03, AUX-05 | — | N/A | unit | `cd accrue_admin && mix test` | ✅ | ⬜ pending |
| 53-02-01 | 02 | 2 | AUX-06 | — | No live credentials in specs | e2e | `bash scripts/ci/accrue_host_verify_browser.sh` | ✅ | ⬜ pending |
| 53-02-02 | 02 | 2 | AUX-06 | — | N/A | e2e | `npm run e2e -- verify01-admin-a11y.spec.js` (from `examples/accrue_host`) | ✅ | ⬜ pending |

## Wave 0 Requirements

- [x] Existing ExUnit + Playwright infrastructure covers this phase — **no new framework install**.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| *None* | — | — | All behaviors target automated Mix / Playwright / shell CI scripts. |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable for host browser lane
- [ ] `nyquist_compliant: true` set in frontmatter after wave 2 green

**Approval:** pending
