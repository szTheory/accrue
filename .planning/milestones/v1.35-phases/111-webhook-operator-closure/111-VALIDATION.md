---
phase: 111
slug: webhook-operator-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 111 — Validation Strategy

> Per-phase validation contract for processor-aware webhook/operator documentation and deterministic replay/recovery proof. Source-of-truth detail lives in `111-RESEARCH.md` §Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus static `rg` guide assertions |
| **Config file** | `accrue/test/*`, `examples/accrue_host/test/*`, `scripts/ci/accrue_host_verify_test_bounded.sh` |
| **Quick run command** | `cd accrue && mix test test/accrue/docs/testing_guide_test.exs test/accrue/billing_portal_test.exs test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs` |
| **Full suite command** | `cd accrue && mix test test/accrue/webhooks/dlq_test.exs test/mix/tasks/accrue_webhooks_replay_test.exs test/accrue/webhook/default_handler_portal_event_test.exs test/accrue/telemetry/portal_checkout_completed_test.exs test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs test/accrue/docs/testing_guide_test.exs test/accrue/billing_portal_test.exs && cd ../examples/accrue_host && ../../scripts/ci/accrue_host_verify_test_bounded.sh` |
| **Estimated runtime** | 2-4 minutes |

---

## Sampling Rate

- **After every task commit:** run that task’s local `rg` or focused `mix test` command.
- **After every plan wave:** run the quick run command.
- **Before `$gsd-verify-work`:** run the full suite command.
- **Max feedback latency:** under 5 minutes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 111-01-01 | 01 | 1 | OPS-01 | T-111-01 | webhook docs explain shared host boundary plus Braintree-specific replay and local-checkout completion truth | static | `rg -n "Braintree|portal_base_url|portal_mount_path|accrue.portal.checkout.completed|mix accrue.webhooks.replay" accrue/guides/webhooks.md accrue/guides/telemetry.md` | ✅ | ⬜ pending |
| 111-01-02 | 01 | 1 | OPS-01 | T-111-02 | runbooks and conceptual metering docs describe ordered Braintree recovery without duplicating the telemetry catalog | static | `rg -n "webhook_dlq|metered_renewal_stale_repaired|metered_missing_definition|awaiting-payment-method|failed-exhausted" accrue/guides/operator-runbooks.md accrue/guides/braintree-metered-billing.md` | ✅ | ⬜ pending |
| 111-02-01 | 02 | 2 | OPS-02 | T-111-03 | testing guide names the deterministic Braintree replay and portal-completion proof lanes explicitly | unit | `cd accrue && mix test test/accrue/docs/testing_guide_test.exs` | ✅ | ⬜ pending |
| 111-02-02 | 02 | 2 | OPS-01/OPS-02 | T-111-04 | adjacent docs and telemetry catalog assertions catch support-story drift | unit | `cd accrue && mix test test/accrue/billing_portal_test.exs test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs` | ✅ | ⬜ pending |
| 111-03-01 | 03 | 3 | OPS-02 | T-111-05 | replay and local-checkout completion proof lanes remain deterministic and processor-aware | integration | `cd accrue && mix test test/accrue/webhooks/dlq_test.exs test/mix/tasks/accrue_webhooks_replay_test.exs test/accrue/webhook/default_handler_portal_event_test.exs test/accrue/telemetry/portal_checkout_completed_test.exs` | ✅ | ⬜ pending |
| 111-03-02 | 03 | 3 | OPS-02 | T-111-06 | bounded host verifier keeps admin replay and host billing proof release-adjacent | integration | `cd examples/accrue_host && ../../scripts/ci/accrue_host_verify_test_bounded.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/guides/webhooks.md`, `accrue/guides/telemetry.md`, `accrue/guides/operator-runbooks.md`, `accrue/guides/braintree-metered-billing.md`, and `accrue/guides/testing.md` all exist.
- [x] `accrue/test/accrue/webhooks/dlq_test.exs`, `accrue/test/mix/tasks/accrue_webhooks_replay_test.exs`, `accrue/test/accrue/webhook/default_handler_portal_event_test.exs`, and `accrue/test/accrue/telemetry/portal_checkout_completed_test.exs` all exist.
- [x] `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` and `scripts/ci/accrue_host_verify_test_bounded.sh` both exist.

---

## Manual-Only Verifications

All planned phase behaviors have automated verification. No manual-only gate is required for planning.

---

## Validation Sign-Off

- [x] All tasks have automated verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers every referenced proof lane
- [x] No watch-mode flags
- [x] Feedback latency < 300 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
