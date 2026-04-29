---
phase: 96
slug: chosen-second-provider-thin-slice
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-29
---

# Phase 96 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `accrue/test/test_helper.exs` |
| **Smoke command** | `cd accrue && mix test test/accrue/processor/braintree_test.exs test/accrue/webhook/plug_test.exs` |
| **Quick run command** | `(cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_projection_provider_test.exs test/accrue/webhook/plug_test.exs test/accrue/webhook/default_handler_test.exs test/accrue/processor/braintree_test.exs test/accrue/billing/subscription_test.exs) && (cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs)` |
| **Shared Stripe/Fake regression command** | `cd accrue && mix test test/accrue/billing/subscription_test.exs test/accrue/billing/payment_method_actions_test.exs test/accrue/processor/capabilities_test.exs test/accrue/webhook/default_handler_phase3_test.exs test/accrue/checkout/session_test.exs --max-cases 1` |
| **Full suite command** | `(cd accrue && mix test --warnings-as-errors) && (cd examples/accrue_host && mix test --warnings-as-errors)` |
| **Credentialed host proof command** | `cd examples/accrue_host && mix test test/accrue_host/braintree_subscribe_test.exs --include live_braintree` after exporting `BRAINTREE_MERCHANT_ID`, `BRAINTREE_PUBLIC_KEY`, `BRAINTREE_PRIVATE_KEY`, and `BRAINTREE_SANDBOX_PLAN_ID` |
| **Estimated runtimes** | smoke: ~20-25s; quick: ~60-75s; shared regression: ~45-60s; full: multi-minute; credentialed host proof: environment-dependent |

---

## Sampling Rate

- **After every task commit:** Run the smoke command.
- **After any shared `subscribe/3` seam change in Plan 01:** Run the quick command and the shared Stripe/Fake regression command.
- **After Plans 02-04:** Run the quick command.
- **Before Phase 96 completion:** Run the credentialed host proof command above with all `BRAINTREE_*` vars exported and capture the passing result in `96-03-SUMMARY.md`.
- **Before `$gsd-verify-work`:** Run the full suite command.
- **Max feedback latency:** 25 seconds on the smoke loop.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 96-01-01 | 01 | 1 | PROC-12 | T-96-01 | Unsupported Braintree-adjacent paths fail with `processor_operation_unsupported`; the supported subscribe path accepts only `payment_method.vault_acquisition.reference`. | unit | `cd accrue && mix test test/accrue/processor/braintree_test.exs` | ❌ W0 | ⬜ pending |
| 96-01-02 | 01 | 1 | PROC-12 | T-96-03 | Subscription projection stays provider-aware without pretending Stripe and Braintree payloads are identical. | unit | `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_projection_provider_test.exs test/accrue/processor/braintree_test.exs` | ❌ W0 | ⬜ pending |
| 96-01-03 | 01 | 1 | PROC-12 | T-96-13 | Shared Stripe/Fake facade behavior still passes after the Braintree seam changes. | regression | `cd accrue && mix test test/accrue/billing/subscription_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_projection_provider_test.exs test/accrue/processor/braintree_test.exs && mix test test/accrue/billing/subscription_test.exs test/accrue/billing/payment_method_actions_test.exs test/accrue/processor/capabilities_test.exs test/accrue/webhook/default_handler_phase3_test.exs test/accrue/checkout/session_test.exs --max-cases 1` | ❌ W0 | ⬜ pending |
| 96-02-01 | 02 | 2 | PROC-12 | T-96-04 | Webhook verification rejects malformed `bt_signature` / `bt_payload` input before persistence. | unit | `cd accrue && mix test test/accrue/webhook/plug_test.exs` | ✅ | ⬜ pending |
| 96-02-02 | 02 | 2 | PROC-12 | T-96-05 | Validated Braintree lifecycle events normalize into the shared reducer path and persist local truth without Stripe-only assumptions. | unit | `cd accrue && mix test test/accrue/webhook/plug_test.exs test/accrue/webhook/default_handler_test.exs` | ✅ | ⬜ pending |
| 96-03-01 | 03 | 3 | PROC-12 | T-96-07 | The example host owns vault acquisition, loads the browser asset explicitly, and forwards only the narrow handoff reference into `Accrue.Billing.subscribe/3`. | integration | `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs && rg -n 'import .*braintree_vault_acquisition' assets/js/app.js && rg -n 'phx-hook=|data-braintree|vault acquisition' lib/accrue_host_web/live/subscription_live.ex` | ❌ W0 | ⬜ pending |
| 96-03-03 | 03 | 3 | PROC-12 | T-96-09 | The real-provider proof lane requires `BRAINTREE_*` credentials plus `BRAINTREE_SANDBOX_PLAN_ID`, exercises the host proof path, and runs only after Plan 02 completes. | integration | `cd examples/accrue_host && mix test test/accrue_host/braintree_subscribe_test.exs --include live_braintree` | ❌ W0 | ⬜ pending |
| 96-04-01 | 04 | 4 | PROC-13 | T-96-10 | The canonical matrix and package README say Braintree is official only for gateway subscription core while checkout and billing portal remain Stripe-only. | docs | `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 96-04-02 | 04 | 4 | PROC-13 | T-96-11 | Package guides preserve Fake-first merge blocking and advisory provider-backed proof wording. | docs | `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 96-05-01 | 05 | 5 | PROC-13 | T-96-14 | Example-host docs mirror the bounded support story without broadening the promise. | docs | `bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 96-05-02 | 05 | 5 | PROC-12, PROC-13 | T-96-15 | Verifier scripts and validation tracking enforce the new wording, smoke cadence, shared regression rerun, and credentialed proof command. | docs | `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/processor/braintree_test.exs` — dedicated adapter and capability smoke for the new first-party slice
- [ ] `accrue/test/accrue/billing/subscription_test.exs` shared regression updates — explicit Stripe/Fake non-regression after the `subscribe/3` seam changes
- [ ] `examples/accrue_host/test/accrue_host/braintree_subscribe_test.exs` — canonical credentialed host proof for the Braintree-backed `subscribe/3` path
- [ ] `examples/accrue_host/assets/js/braintree_vault_acquisition.js` plus host-page wiring in `assets/js/app.js` / `lib/accrue_host_web/live/subscription_live.ex` — explicit proof-path asset loading
- [ ] Shared Braintree test fixtures/helpers — signed webhook payload helpers and fixture builders for the thin slice

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Public positioning stays honest across matrix, package docs, and host docs | PROC-13 | Copy drift is easier to miss in rendered docs than grep alone | Read `.planning/processor-support-matrix.md`, `accrue/README.md`, and `examples/accrue_host/README.md` together and confirm they all say Stripe remains the default path, Braintree is bounded to gateway subscription core, and checkout/portal stay Stripe-only. |

---

## Validation Sign-Off

- [x] All auto tasks have automated verification commands
- [x] Sampling continuity uses a sub-30-second smoke loop
- [x] Shared Stripe/Fake regression coverage is explicit after `subscribe/3` seam changes
- [ ] Wave 0 files exist
- [x] No watch-mode flags
- [x] Max feedback latency is below 30 seconds on the smoke loop
- [ ] `96-03-SUMMARY.md` includes one passing credentialed `live_braintree` command with date and sandbox plan-id source
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
