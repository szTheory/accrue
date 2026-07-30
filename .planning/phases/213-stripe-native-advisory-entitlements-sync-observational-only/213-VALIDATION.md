---
phase: 213
slug: stripe-native-advisory-entitlements-sync-observational-only
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-30
---

# Phase 213 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Ecto SQL Sandbox, Oban.Testing, and the existing Fake processor |
| **Config file** | `accrue/test/test_helper.exs`; support cases under `accrue/test/support/` |
| **Quick run command** | `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs test/accrue/webhook/default_handler_entitlement_summary_test.exs` |
| **Full suite command** | `cd accrue && mix test.all && cd .. && bash scripts/ci/verify_entitlement_sync_isolation.sh` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task's targeted `mix test` command and `bash scripts/ci/verify_entitlement_sync_isolation.sh`.
- **After every plan wave:** Run `cd accrue && mix test.all`.
- **Before `$gsd-verify-work`:** The full suite and entitlement isolation verifier must be green.
- **Max feedback latency:** 180 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 213-01-01 | 01 | 0 | SYNC-01, SYNC-02, SYNC-05 | T-213-01 | Fake-only refresh tests cannot call live Stripe | integration | `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs` | ❌ W0 | ⬜ pending |
| 213-01-02 | 01 | 0 | SYNC-03 | T-213-02 | A gate-to-client-fetch or gate-to-reconciler edge fails closed | script/test | `bash scripts/ci/verify_entitlement_sync_isolation.sh` | ❌ W0 | ⬜ pending |
| 213-02-01 | 02 | 1 | SYNC-01, SYNC-05 | T-213-01 | Pull results populate advisory state only | integration | `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs` | ❌ W0 | ⬜ pending |
| 213-02-02 | 02 | 1 | SYNC-02, SYNC-05 | T-213-03 | Empty, stale, or contradictory advisory state cannot alter grants | integration | `cd accrue && mix test test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs` | ❌ W0 | ⬜ pending |
| 213-03-01 | 03 | 2 | SYNC-04 | — | D-07 closure is explicit in code and package docs | docs test | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | ✅ partial | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/entitlements/stripe_sync_refresh_test.exs` — covers SYNC-01, SYNC-02, and SYNC-05.
- [ ] `accrue/test/accrue/entitlements/stripe_sync_refresh_worker_test.exs` — covers the worker wrapper.
- [ ] Add a negative-path isolation fixture for the new client-fetch entry point and shared writer — covers SYNC-03.
- [ ] Extend a docs/moduledoc assertion or package-doc verifier for the D-07 closure — covers SYNC-04.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
