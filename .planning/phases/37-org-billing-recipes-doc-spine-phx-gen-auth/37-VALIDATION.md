---
phase: 37
slug: org-billing-recipes-doc-spine-phx-gen-auth
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-21
---

# Phase 37 — Validation Strategy

> Documentation phase: feedback sampling emphasizes ExDoc build + guide contract tests, not application runtime.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `accrue/config/config.exs` (host library test config) |
| **Quick run command** | `cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs` |
| **Full suite command** | `cd accrue && mix test test/accrue/docs/` |
| **Estimated runtime** | ~15–45 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick command when the task touched `guides/organization_billing.md` or the new contract test.
- **After every plan wave:** Run `cd accrue && mix test test/accrue/docs/` plus `cd accrue && MIX_ENV=test mix docs`.
- **Before `/gsd-verify-work`:** Full doc test path green; ExDoc build completes without new guide reference errors.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-01-01 | 01 | 1 | ORG-05 | T-37-01-01 | ORG-03 checklist present in prose | unit | `cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs` | ✅ | ⬜ pending |
| 37-02-01 | 02 | 1 | ORG-05, ORG-06 | T-37-02-01 | Non-Sigra path documented before Sigra deps | unit | `cd accrue && mix test test/accrue/docs/community_auth_test.exs` | ✅ | ⬜ pending |
| 37-03-01 | 03 | 2 | ORG-05 | T-37-03-01 | Installer README pointers; no secret leakage | unit | `cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red*

---

## Wave 0 Requirements

- [x] Existing infrastructure: `accrue/test/accrue/docs/community_auth_test.exs` and `mix docs` cover baseline doc quality.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Narrative flow | ORG-05 | Editorial | Read `guides/organization_billing.md` end-to-end; confirm vertical TOC and links resolve on HexDocs preview. |

---

## Validation Sign-Off

- [ ] `nyquist_compliant: true` set after Wave 1–2 tests land
- [ ] No watch-mode flags in automated commands

**Approval:** pending
