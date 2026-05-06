---
phase: 102
slug: coupon-discount-mapping
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-02
---

# Phase 102 — Validation Strategy

> Per-phase validation contract for the shipped coupon/discount mapping slice.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix for `accrue` and `accrue_portal` |
| **Config file** | `accrue/test/test_helper.exs` and `accrue_portal/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/discount_mapping_actions_test.exs test/accrue/billing/braintree_discount_mapping_subscribe_test.exs test/accrue/telemetry/discount_mapping_invalid_test.exs test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs && cd ../accrue_portal && mix test test/accrue_portal/live/checkout_live_discount_test.exs` |
| **Full suite command** | `cd accrue && mix test.all && cd ../accrue_admin && mix test --warnings-as-errors && cd ../accrue_portal && mix test --warnings-as-errors` |
| **Estimated runtime** | ~2-4 minutes |
| **Environment note** | Local verification used a repo-local `TMPDIR` workaround when temp-area exhaustion affected `/var/folders/...`. |

---

## Sampling Rate

- **After every task commit:** Run the smallest lane that covers the touched behavior.
- **After every plan wave:** Run the phase-local core + portal proof commands.
- **Before `$gsd-verify-work`:** Full `accrue` and `accrue_portal` suites must be green.
- **Max feedback latency:** Keep targeted feedback under ~60 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 102-01-01 | 01 | 1 | BT-04 | T-102-01 | Local discount-mapping write surface persists canonical code -> Braintree discount rows with honest eligibility semantics. | unit | `cd accrue && mix test test/accrue/billing/discount_mapping_actions_test.exs` | ✅ | ✅ green |
| 102-01-02 | 01 | 1 | BT-04/BT-05 | T-102-07 | Redemption-cap semantics mutate executable state and roll back safely on failed create paths. | unit/integration | `cd accrue && mix test test/accrue/billing/discount_mapping_actions_test.exs test/accrue/billing/braintree_discount_mapping_subscribe_test.exs` | ✅ | ✅ green |
| 102-02-01 | 02 | 2 | BT-05 | T-102-02/T-102-03 | `subscribe/3` revalidates the code, reserves the mapping, and emits `discounts.add[*].inherited_from_id` in the Braintree create payload. | integration | `cd accrue && mix test test/accrue/billing/braintree_discount_mapping_subscribe_test.exs test/accrue/processor/braintree_test.exs` | ✅ | ✅ green |
| 102-02-02 | 02 | 2 | BT-05 | T-102-04 | Drift conditions return a typed internal failure and emit ops telemetry without degrading to customer-invalid-code results. | unit/integration | `cd accrue && mix test test/accrue/telemetry/discount_mapping_invalid_test.exs test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs` | ✅ | ✅ green |
| 102-03-01 | 03 | 3 | BT-05 | T-102-05/T-102-06 | Portal checkout previews savings/total, announces promo state changes accessibly, and revalidates on final submit. | LiveView/integration | `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_discount_test.exs` | ✅ | ✅ green |

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/billing/discount_mapping_actions_test.exs` — local schema/write surface, uniqueness, eligibility, and redemption-cap semantics
- [x] `accrue/test/accrue/billing/braintree_discount_mapping_subscribe_test.exs` — request assembly, Braintree discount attachment, typed failure coverage, and reservation rollback
- [x] `accrue/test/accrue/telemetry/discount_mapping_invalid_test.exs` — operator-drift telemetry and error taxonomy
- [x] `accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs` — promo input UX, `aria-live` copy, preview totals, and submit-time revalidation
- [x] Browser proof lane `examples/accrue_host/e2e/phase102-portal-checkout.spec.js` — mounted portal preview, invalid, and drift states with automated accessibility checks
- [x] Repo-local temp-dir workaround documented and used where needed for local verification

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Braintree sandbox subscription create applies the expected Control-Panel discount | BT-05 | Requires live Braintree sandbox merchant credentials and a real discount configured upstream | `cd examples/portal_demo && BRAINTREE_ENV=sandbox MERCHANT_ID=... mix phx.server` → enter a mapped code in checkout → complete Hosted Fields submit → confirm the created subscription carries the expected Braintree discount id |

*All repo-shipped customer-facing behaviors are otherwise automated.*

---

## Validation Sign-Off

- [x] All plans bind each task to a verification lane above
- [x] Sampling continuity preserved across plans 01-03
- [x] Wave 0 proof files exist and are green
- [x] No watch-mode flags appear in verification commands
- [x] Temp-space blocker has a documented workaround for local reruns
- [x] `nyquist_compliant: true` is set in frontmatter

**Approval:** validation contract reconciled with shipped proof

## Verification Snapshot

- Core + telemetry lane: `TMPDIR=/Users/jon/projects/accrue/.tmp/phase102 mix test test/accrue/billing/discount_mapping_actions_test.exs test/accrue/billing/braintree_discount_mapping_subscribe_test.exs test/accrue/processor/braintree_test.exs test/accrue/telemetry/discount_mapping_invalid_test.exs test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs` → `34 tests, 0 failures`
- Portal lane: `TMPDIR=/Users/jon/projects/accrue/.tmp/phase102 mix test test/accrue_portal/live/checkout_live_discount_test.exs` → `3 tests, 0 failures`
- Browser lane: `npx playwright test e2e/phase102-portal-checkout.spec.js` → `4 passed`
