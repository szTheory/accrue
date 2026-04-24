---
phase: 78
slug: billing-portal-on-accrue-billing-telemetry-truth
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 78 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue` mix project) |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing_portal_billing_facade_test.exs` (path per Plan 01 artifact name) |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | ~2–5 min full; ~5–15 s focused |

---

## Sampling Rate

- **After every task commit:** Run focused `mix test` on the new Billing portal facade test module
- **After every plan wave:** `cd accrue && mix test test/accrue/telemetry/billing_span_coverage_test.exs` then spot full suite if touched shared helpers
- **Before `/gsd-verify-work`:** Full `cd accrue && mix test` green
- **Max feedback latency:** 300 s (full suite ceiling)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 78-01-01 | 01 | 1 | BIL-04 | T-78-01 | No portal URL in telemetry metadata | unit | `cd accrue && mix test test/accrue/...facade...exs` | ⬜ W0 | ⬜ pending |
| 78-01-02 | 01 | 1 | BIL-04 | T-78-01 | Span tuple `[:accrue,:billing,:billing_portal,:create]` | unit | same file + `mix test test/accrue/telemetry/billing_span_coverage_test.exs` | ✅ | ⬜ pending |
| 78-02-01 | 02 | 1 | BIL-05 | — | Doc grep anchors only | doc | `rg billing_portal accrue/guides/telemetry.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — `Accrue.BillingCase`, Fake processor, billing span coverage test.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | — | All behaviors target automated ExUnit + doc grep |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
