---
phase: 098-payment-method-crud-operator-admin
verified: 2026-04-30T21:44:54Z
status: human_needed
score: 7/7 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/7
  gaps_closed:
    - "Customers can add and replace Braintree vaulted payment methods through the host-owned vault-reference seam."
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Run the phase-gate browser lane on the mounted customer payment-method route."
    expected: "The page shows sync/default/delete plus host handoff copy only, with no embedded Braintree capture UI."
    why_human: "This requires the mounted browser route, Playwright/bootstrap setup, and visual confirmation."
  - test: "Review blocked and allowed delete confirmations in the payment-method tab."
    expected: "Copy clearly distinguishes active-subscription blocking, replacement-required blocking, and the allowed last-method delete path."
    why_human: "This is UX/copy clarity, not a binary server-path check."
---

# Phase 98: Payment Method CRUD & Operator Admin Verification Report

**Phase Goal:** Customers and operators can manage Braintree vaulted payment methods.  
**Verified:** 2026-04-30T21:44:54Z  
**Status:** human_needed  
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `Accrue.Billing` supports Braintree listing, adding, deleting, setting default, plus the canonical CRUD/update/sync surface. | ✓ VERIFIED | CRUD and sync orchestration remain wired in `accrue/lib/accrue/billing/payment_method_actions.ex:38-175`; export coverage is in `accrue/test/accrue/billing/payment_method_actions_test.exs:42-52`; targeted backend suite passed with `33 tests, 0 failures`. |
| 2 | Braintree payment-method writes refresh the local projection immediately, while `list_payment_methods/2` remains local-row-first and `sync_payment_methods/2` repairs drift. | ✓ VERIFIED | Write-through sync happens in `accrue/lib/accrue/billing/payment_method_actions.ex:57-69`, `96-110`, and `128-139`; local-row-first listing is preserved in `:152-165`; drift repair is proven in `accrue/test/accrue/billing/payment_method_crud_braintree_test.exs:291-323`. |
| 3 | Delete and replacement flows use projected active Braintree subscription `payment_method_token` data and preserve the safe last-method delete-to-no-default path. | ✓ VERIFIED | Replacement semantics are implemented in `accrue/lib/accrue/billing/payment_method_actions.ex:82-110`; delete guards use projected subscription data in `:454-498`; guarded and last-method-delete cases are covered in `accrue/test/accrue/billing/payment_method_crud_braintree_test.exs:237-289`. |
| 4 | Existing Stripe/Fake attach, detach, set-default, and list behavior remains available through compatibility wrappers. | ✓ VERIFIED | Compatibility wrappers remain in `accrue/lib/accrue/billing/payment_method_actions.ex:177-220`; regression proof passed in the targeted `accrue` suite, including `payment_method_actions_test.exs`, `default_payment_method_test.exs`, and `payment_method_list_test.exs`. |
| 5 | Operators can review inventory, sync, set default, and see guarded delete states in `AccrueAdmin` without embedded Braintree capture. | ✓ VERIFIED | LiveView handlers call `Billing.sync_payment_methods/2`, `set_default_payment_method/3`, and `delete_payment_method/2` in `accrue_admin/lib/accrue_admin/live/customer_live.ex:75-141`; the tab renders only server-driven controls plus host handoff copy in `:254-343`; `accrue_admin` proof passed with `10 tests, 0 failures`, including `accrue_admin/test/accrue_admin/live/customer_live_test.exs:275-360`. |
| 6 | Customers can add and replace Braintree vaulted payment methods through the host-owned vault-reference seam. | ✓ VERIFIED | The once-blocked lazy customer bootstrap now works because `Accrue.Processor.Braintree` implements `create_customer/2`, `retrieve_customer/2`, and `update_customer/3` in `accrue/lib/accrue/processor/braintree.ex:86-110`; the host seam still flows through `customer_for_scope/1` and canonical billing verbs in `examples/accrue_host/lib/accrue_host/billing.ex:70-120`; the host proof now uses the real Braintree processor module with only gateway stubs in `examples/accrue_host/test/accrue_host/braintree_payment_method_flow_test.exs:195-297`, and passed with `2 tests, 0 failures`. |
| 7 | Host docs, validation artifacts, and browser-proof metadata describe the same truthful operator route and phase-gate bootstrap. | ✓ VERIFIED | Validation still defines the browser gate and bootstrap in `.planning/milestones/v1.32-phases/098-payment-method-crud-operator-admin/098-VALIDATION.md:20-23,61-79`; doc and e2e route alignment exists in `examples/accrue_host/docs/verify01-v112-admin-paths.md:45-55`, `examples/accrue_host/e2e/verify01-admin-a11y.spec.js:393-429`, and `examples/accrue_host/README.md:139-140,199-200,208-209`. |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/accrue/billing.ex` | Canonical public CRUD facade and lazy customer bootstrap | ✓ VERIFIED | `customer/1` still lazily creates missing customers via `create_customer/1` at `:691-780`, and the facade remains wired to payment-method actions. |
| `accrue/lib/accrue/billing/payment_method_actions.ex` | Projection-first orchestration, replacement semantics, delete guards, immediate resync | ✓ VERIFIED | Substantive logic spans `:38-620`; add/update/delete/sync and the Braintree-specific guard paths are exercised by passing automated tests. |
| `accrue/lib/accrue/processor/braintree.ex` | Braintree customer + payment-method adapter support | ✓ VERIFIED | Customer callbacks are now implemented at `:86-110`; payment-method create/list/update/delete/default remain implemented at `:188-244`; adapter tests passed. |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | Server-driven operator UI for payment methods | ✓ VERIFIED | Sync/default/delete events plus host handoff render path are present at `:75-141` and `:254-343`, with passing LiveView tests. |
| `examples/accrue_host/lib/accrue_host/billing.ex` | Host-owned add/replace helpers passing vault references into canonical verbs | ✓ VERIFIED | The seam is still host-owned at `:97-120`, and the prerequisite `customer_for_scope/1` path is no longer hollow because real Braintree customer callbacks exist. |
| `examples/accrue_host/test/accrue_host/braintree_payment_method_flow_test.exs` | Host proof that exercises the real Braintree processor contract | ✓ VERIFIED | The test sets `:processor` to `Accrue.Processor.Braintree` and stubs only the Braintree gateways at `:208-216`, then proves add/replace at `:253-297`. |
| `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` | Phase-gate browser proof for the payment-method route | ✓ VERIFIED | The route proof exists and asserts the payment-method tab copy and controls at `:393-429`. |
| `.planning/processor-support-matrix.md` | Support-matrix truth for shipped payment-method CRUD | ✓ VERIFIED | Customer and payment-method rows are aligned at `.planning/processor-support-matrix.md:33-41`, and public facade mapping is aligned at `:63-69`; `verify_processor_support_matrix: OK` passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `accrue/lib/accrue/billing.ex` | `accrue/lib/accrue/billing/payment_method_actions.ex` | canonical facade wrappers | ✓ WIRED | `Billing` delegates to payment-method actions and the targeted backend suite passed. |
| `accrue/lib/accrue/billing.ex` | `accrue/lib/accrue/processor/braintree.ex` | lazy customer bootstrap through `Processor.create_customer/1` | ✓ WIRED | `customer/1` falls through to `create_customer/1` in `accrue/lib/accrue/billing.ex:691-780`, and the Braintree adapter now implements the needed customer callbacks in `accrue/lib/accrue/processor/braintree.ex:86-110`. |
| `accrue/lib/accrue/billing/payment_method_actions.ex` | `accrue/lib/accrue/processor/braintree.ex` | processor callbacks plus immediate resync | ✓ WIRED | Add/update/delete/list call the processor in `payment_method_actions.ex:57-64`, `96-103`, `128-134`, `158-160`; the Braintree adapter implements these callbacks in `braintree.ex:188-244`. |
| `accrue/lib/accrue/billing/payment_method_actions.ex` | `Subscription.data["payment_method_token"]` | delete dependency guard | ✓ WIRED | The guard resolves active Braintree subscription tokens at `payment_method_actions.ex:454-498`. |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | `accrue/lib/accrue/billing.ex` | server-driven events | ✓ WIRED | Sync/default/delete event handlers are wired at `customer_live.ex:75-141`. |
| `examples/accrue_host/lib/accrue_host/billing.ex` | `accrue/lib/accrue/billing.ex` | host-owned vault handoff | ✓ WIRED | Host helpers call `Billing.add_payment_method/3` and `Billing.update_payment_method/3` at `examples/accrue_host/lib/accrue_host/billing.ex:97-120`, and the proof now exercises the full seam with the real Braintree processor module. |
| `098-VALIDATION.md` | host docs/e2e bootstrap | phase-gate browser bootstrap | ✓ WIRED | Validation bootstrap commands and route-proof references are present at `098-VALIDATION.md:20-23,68-79` and matched by the host docs/e2e files. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `accrue/lib/accrue/billing/payment_method_actions.ex` | local `PaymentMethod` projection | `Processor.__impl__().create/update/detach/list_payment_methods` -> `sync_payment_methods/2` -> reprojection | Yes | ✓ FLOWING |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | `@payment_methods` | `payment_methods(customer)` query over `accrue_payment_methods` | Yes | ✓ FLOWING |
| `examples/accrue_host/lib/accrue_host/billing.ex` | `customer` for host add/replace helpers | `customer_for_scope/1` -> `Billing.customer/1` -> `Processor.create_customer/1` when missing | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Support matrix matches checked-in contract | `bash scripts/ci/verify_processor_support_matrix.sh` | `verify_processor_support_matrix: OK` | ✓ PASS |
| Backend CRUD, guards, sync, adapter, and capability coverage | `cd accrue && mix test ...payment_method... ...braintree... ...capabilities... --warnings-as-errors` | `33 tests, 0 failures` | ✓ PASS |
| Admin operator payment-method surface | `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs --warnings-as-errors` | `10 tests, 0 failures` | ✓ PASS |
| Host add/replace seam proof | `cd examples/accrue_host && mix test test/accrue_host/braintree_payment_method_flow_test.exs` | `2 tests, 0 failures` | ✓ PASS |
| Browser phase gate | `cd examples/accrue_host && npm ci && npm run e2e:install && npm run e2e:a11y` | Not run during this verification | ? SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `PROC-16` | `098-01`, `098-02` | Extend `Accrue.Billing` to provide full Braintree payment-method CRUD parity. | ✓ SATISFIED | Canonical CRUD, replacement, guarded delete, default, sync, and the host-owned add/replace seam are implemented and covered by passing backend and host tests. |
| `PROC-17` | `098-02`, `098-03` | Extend the `AccrueAdmin` customer payment methods tab for Braintree operator surfaces. | ? NEEDS HUMAN | LiveView controls, copy exports, doc/e2e route wiring, and automated tests are present, but the browser route and copy clarity still require manual verification per the phase validation contract. |

### Anti-Patterns Found

No blocker or warning-level anti-patterns were found in the phase-critical implementation files. The previous hollow host-flow proof has been replaced by a real `Accrue.Processor.Braintree` proof that only stubs gateway modules.

### Human Verification Required

### 1. Browser Route Boundary

**Test:** Start the host app and run the phase-gate browser lane on `/billing/customers/:id?tab=payment_methods&org=<slug>`.  
**Expected:** The page exposes sync/default/delete plus host handoff copy only, with no embedded Braintree fields, Hosted Fields, or Drop-in UI.  
**Why human:** Requires the mounted browser route, Playwright/bootstrap setup, and visual inspection.

### 2. Delete Warning Clarity

**Test:** Open blocked and allowed delete flows in the payment-method tab and review the confirmation copy.  
**Expected:** The UI clearly distinguishes “still funds an active subscription,” “set another default first,” and the allowed last-method delete path.  
**Why human:** This is copy/UX judgment rather than a purely binary server-path assertion.

### Gaps Summary

The prior blocking gap is closed. The Braintree adapter now implements the customer callbacks that the host-owned vault-reference seam depends on, and the host proof uses the real `Accrue.Processor.Braintree` module rather than replacing the entire processor. Automated verification shows the backend CRUD/update/sync semantics, operator LiveView controls, support-matrix truth, and host add/replace seam all working on the current branch state, including the `7b8275d` and `e277987` fixes. The only remaining checks are the manual browser/UX validations already called out by the phase validation contract, so the decisive status is `human_needed`, not `gaps_found`.

---

_Verified: 2026-04-30T21:44:54Z_  
_Verifier: Codex (gsd-verifier)_
