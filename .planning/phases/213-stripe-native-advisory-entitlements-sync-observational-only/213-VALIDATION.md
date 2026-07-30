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
| 213-01-01 | 01 | 1 | SYNC-01, SYNC-02, SYNC-05 | T-213-01 | Fake-only refresh is complete-or-error, config-off performs no Processor/Repo I/O, and the SDK-owned list path reaches the persisted summary through facade metadata | integration | `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs test/accrue/webhook/default_handler_entitlement_summary_test.exs` | planned in task | ⬜ pending |
| 213-01-02 | 01 | 1 | SYNC-01, SYNC-05 | T-213-01 | Strict-greater `synced_at` ordering preserves the newest pull/webhook snapshot and the greatest real webhook watermark | concurrency/property | `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_test.exs test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs test/property/entitlement_summary_monotonic_property_test.exs` | partial + planned expansion | ⬜ pending |
| 213-02-01 | 02 | 2 | SYNC-01, SYNC-05 | T-213-04, T-213-05 | Stripe adapter fully drains the stream, exposes SDK list-path metadata, and cannot return partial success | contract/compile | `cd accrue && mix test test/accrue/processor/stripe_entitlements_contract_test.exs && mix compile --warnings-as-errors` | planned in task | ⬜ pending |
| 213-02-02 | 02 | 2 | SYNC-01, SYNC-02, SYNC-05 | T-213-06 | Existing-queue worker delegates with scalar args and inherits disabled/error semantics without scheduling itself | worker/integration | `cd accrue && mix test test/accrue/entitlements/stripe_sync_refresh_worker_test.exs test/accrue/entitlements/stripe_sync_refresh_test.exs` | planned in task | ⬜ pending |
| 213-03-01 | 03 | 2 | SYNC-03 | T-213-08 | Executable gate-to-client-fetch and gate-to-reconciler edges fail while clean/comment-only fixtures pass | script/test | `cd accrue && mix test test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs && cd .. && bash scripts/ci/verify_entitlement_sync_isolation.sh` | planned in task | ⬜ pending |
| 213-03-02 | 03 | 2 | SYNC-02, SYNC-04, SYNC-05 | T-213-07, T-213-09 | Empty, stale, and contradictory advisory state cannot alter grants; fetch_entitled/2 remains explicitly closed | integration/docs | `cd accrue && mix test test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs test/accrue/docs/package_docs_verifier_test.exs && ! rg -n 'def(p)? fetch_entitled' lib test` | partial + planned expansion | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Task-Owned Test Artifacts

There is no separate prerequisite test plan. Each missing or expanded test artifact is created test-first by the corresponding executable task:

- Plan 01 Task 1 creates `stripe_sync_refresh_test.exs`; Plan 01 Task 2 expands it and the existing webhook/concurrency/property coverage.
- Plan 02 Task 1 creates `stripe_entitlements_contract_test.exs`; Plan 02 Task 2 creates `stripe_sync_refresh_worker_test.exs`.
- Plan 03 Task 1 creates `entitlement_sync_isolation_guard_test.exs`; Plan 03 Task 2 expands the existing isolation and package-doc verifier tests.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All six tasks have an `<automated>` verify matching the executable plan
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Test-first task ownership covers every currently missing test artifact
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
