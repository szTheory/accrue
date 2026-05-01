---
phase: 98
slug: payment-method-crud-operator-admin
status: complete
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-30
---

# Phase 98 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue`, `accrue_admin`) + host Playwright a11y/browser verification |
| **Config file** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `examples/accrue_host/package.json` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/payment_method_actions_test.exs test/accrue/billing/default_payment_method_test.exs test/accrue/billing/payment_method_crud_braintree_test.exs test/accrue/processor/braintree_test.exs --warnings-as-errors && cd ../accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs --warnings-as-errors && cd ../examples/accrue_host && mix test test/accrue_host/braintree_payment_method_flow_test.exs` |
| **Full suite command** | `bash scripts/ci/verify_processor_support_matrix.sh && cd accrue && mix test --warnings-as-errors && cd ../accrue_admin && mix test --warnings-as-errors && cd ../examples/accrue_host && mix test test/accrue_host/braintree_payment_method_flow_test.exs && npm ci && npm run e2e:install && npm run e2e:a11y` |
| **Estimated runtime** | ~240 seconds for the phase gate; task-level loops stay on ExUnit/export/check commands only |

---

## Sampling Rate

- **After every task commit:** Run the targeted ExUnit/export/check command for the files touched. Do not run Playwright at task level.
- **After every plan wave:** Run the quick run command above.
- **Before `$gsd-verify-work`:** Run the full suite command, including deterministic host JS bootstrap before Playwright.
- **Max feedback latency:** fast task loops only; full browser proof is phase-gate only

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 098-01-01 | 098-01 | 1 | PROC-16 | T-98-01 / T-98-02 | Canonical CRUD, replacement, delete-guard, and sync semantics are encoded in hermetic backend tests before implementation | ExUnit | `cd accrue && mix test test/accrue/billing/payment_method_actions_test.exs test/accrue/billing/default_payment_method_test.exs test/accrue/billing/payment_method_crud_braintree_test.exs test/accrue/processor/braintree_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 098-01-02 | 098-01 | 1 | PROC-16 | T-98-01 / T-98-03 | Billing facade, Braintree adapter, and local projection resync reject unsafe delete/default transitions and update support truth | ExUnit + support matrix | `bash scripts/ci/verify_processor_support_matrix.sh && cd accrue && mix test test/accrue/billing/payment_method_actions_test.exs test/accrue/billing/default_payment_method_test.exs test/accrue/billing/payment_method_crud_braintree_test.exs test/accrue/processor/braintree_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 098-02-01 | 098-02 | 2 | PROC-17 | T-98-04 / T-98-05 | Admin payment-method actions remain server-driven and copy-backed while exposing only truthful operator controls | LiveView + ExUnit | `cd accrue_admin && mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json && mix test test/accrue_admin/live/customer_live_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 098-02-02 | 098-02 | 2 | PROC-16, PROC-17 | T-98-04 / T-98-05 | Host-assisted add/replace proof stays outside admin and uses the narrow vault handoff into canonical CRUD verbs | Host ExUnit | `cd examples/accrue_host && mix test test/accrue_host/braintree_payment_method_flow_test.exs` | ✅ | ⬜ pending |
| 098-03-01 | 098-03 | 3 | PROC-17 | T-98-06 / T-98-07 | Browser verification remains a phase gate only, and the route proof/docs preserve the truthful operator actions plus host-owned add/replace seam | Docs/config | `rg -n "098-01-01|098-01-02|098-02-01|098-02-02|098-03-01|npm ci && npm run e2e:install && npm run e2e:a11y" .planning/milestones/v1.32-phases/098-payment-method-crud-operator-admin/098-VALIDATION.md && rg -n "host-owned|Replace payment method|Sync payment methods|npm ci|e2e:install" examples/accrue_host/docs/verify01-v112-admin-paths.md examples/accrue_host/README.md examples/accrue_host/e2e/verify01-admin-a11y.spec.js` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/billing/payment_method_crud_braintree_test.exs` — facade-level Braintree CRUD, replacement, delete-guard, and resync coverage for `PROC-16`.
- [ ] Expand `accrue/test/accrue/processor/braintree_test.exs` — adapter coverage for `Customer.find/update` and `PaymentMethod.create/find/update/delete`.
- [ ] Expand `accrue_admin/test/accrue_admin/live/customer_live_test.exs` — mutation events, blocked delete copy, sync action, and flash coverage for `PROC-17`.
- [ ] `examples/accrue_host/test/accrue_host/braintree_payment_method_flow_test.exs` — host-assisted replace proof using the existing vault handoff seam and canonical CRUD verbs.
- [ ] Update `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` if the payment-method route gains materially changed interactive chrome.

---

## Browser Gate Coverage

The phase gate is fully automated. `examples/accrue_host/e2e/verify01-admin-a11y.spec.js`
now covers the mounted payment-method route boundary directly:

- host-owned capture boundary: no embedded Braintree form fields, Hosted Fields, Drop-in UI, or Braintree iframe chrome on the admin route
- replacement-required delete confirmation: operator sees the replacement guidance and no destructive confirm button
- allowed delete confirmation: operator sees the generic warning and the destructive confirm button

The active-subscription blocked-copy path remains automated in `accrue_admin/test/accrue_admin/live/customer_live_test.exs`,
which already asserts the mounted admin customer payment-method delete flow renders
`customer_payment_methods_delete_blocked_in_use`.

## Phase-Gate Browser Bootstrap

Run Playwright only at the phase gate, after the host-side JS dependencies and browser binary are installed deterministically:

```bash
cd examples/accrue_host
npm ci
npm run e2e:install
npm run e2e:a11y
```

This bootstrap is required even on machines that have run other host specs before; do not assume prior Playwright assets are present.

---

## Validation Sign-Off

- [ ] All tasks have automated verify or a Wave 0 dependency
- [ ] Sampling continuity: no plan wave merges without the quick run command
- [x] Browser verification is included only at the phase gate, with `npm ci` and `npm run e2e:install` completed first
- [ ] No watch-mode flags
- [ ] Feedback latency stays fast at task level because Playwright is not part of per-task verification
- [x] `nyquist_compliant: true` set in frontmatter when phase closes

**Approval:** automated
