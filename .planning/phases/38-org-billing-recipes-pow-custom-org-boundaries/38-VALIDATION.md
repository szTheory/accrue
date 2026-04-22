---
phase: 38
slug: org-billing-recipes-pow-custom-org-boundaries
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-21
---

# Phase 38 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `accrue/config/config.exs` + `accrue/mix.exs` (host test deps unchanged) |
| **Quick run command** | `cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs` |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | ~30–120 seconds (machine dependent) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/accrue/docs/organization_billing_guide_test.exs`
- **After every plan wave:** Run `mix test test/accrue/docs/organization_billing_guide_test.exs` + `MIX_ENV=test mix docs`
- **Before `/gsd-verify-work`:** Full `mix test` green for touched packages
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 38-01-01 | 01 | 1 | ORG-07 | T-38-01-01 | Pow doc does not imply org membership is implicit | unit | `cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs` | ✅ | ⬜ pending |
| 38-01-02 | 01 | 1 | ORG-07 | T-38-01-02 | auth_adapters cross-link only — no secret material | unit | `rg -n 'organization_billing\\.md#|Pow-oriented' accrue/guides/auth_adapters.md` | ✅ | ⬜ pending |
| 38-02-01 | 02 | 2 | ORG-08 | T-38-02-01 | Anti-pattern table names all ORG-03 path classes | unit | `mix test test/accrue/docs/organization_billing_guide_test.exs` | ✅ | ⬜ pending |
| 38-02-02 | 02 | 2 | ORG-08 | T-38-02-02 | Replay scoping explicitly documented | unit | `rg -n 'webhook replay|actor_id|membership' accrue/guides/organization_billing.md` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements.** No new test framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ExDoc TOC readability | ORG-07 | heading hierarchy | Open generated docs locally; confirm new H2s appear in sidebar |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
