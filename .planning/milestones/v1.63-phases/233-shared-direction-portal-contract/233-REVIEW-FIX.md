---
phase: 233-shared-direction-portal-contract
fixed_at: 2026-10-07T23:03:44Z
review_path: .planning/phases/233-shared-direction-portal-contract/233-REVIEW.md
iteration: 1
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 233: Code Review Fix Report

**Fixed at:** 2026-10-07T23:03:44Z  
**Source review:** `.planning/phases/233-shared-direction-portal-contract/233-REVIEW.md`  
**Iteration:** 1

**Summary:**
- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### CR-01: [BLOCKER] Checkout POST rejects supported personal legacy-processor sessions

**Files modified:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex`, `accrue_portal/test/accrue_portal/checkout_context_test.exs`, `accrue_portal/README.md`, `examples/accrue_host/config/test.exs`, `examples/accrue_host/config/runtime.exs`, `examples/accrue_host/e2e/phase233-context.spec.js`, `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js`, `examples/accrue_host/e2e/onboarding_and_billing.spec.js`, `examples/accrue_host/playwright.config.js`, `examples/accrue_host/playwright.braintree.config.js`, `examples/accrue_host/test/install_boundary_test.exs`, `examples/accrue_host/package.json`, `.github/workflows/ci.yml`, `scripts/ci/accrue_host_verify_browser.sh`
**Commits:** `d828adc9`, `3dff46b2`
**Applied fix:** The review's proposed cross-configuration POST success would dispatch a Braintree Customer's mutation through the globally configured Fake adapter. The phase contract excludes dynamic processor routing, and `SubscriptionActions` dispatches through `Processor.__impl__()`. The fix preserves personal Customer resolution for display and reads, but requires the configured processor for checkout eligibility in both LiveView and POST. A mismatched personal checkout fails before token issuance and its valid signed-pin POST is denied with zero subscription calls. Matching-processor personal POST and custom-adapter POST positive controls remain covered. The README distinguishes read identity from checkout provider eligibility. Because LocalSession records are Braintree-specific, the default Fake browser suite now explicitly verifies mismatch denial, while a separate Braintree-configured lane proves real Hosted Fields initialization, promo behavior, and the matching-provider host authorization denial. Runtime selection is test-only; production requests do not mutate processor configuration. The CI shard path and the host browser verification script run both lanes.

## Verification

Ran in the main checkout:

- RED check: the processor-mismatch test failed against the reviewed adapter-aware LiveView predicate because it rendered checkout Hosted Fields.
- Focused Portal checkout context tests: 11 tests, 0 failures.
- Full Portal suite with `--warnings-as-errors`: 72 tests, 0 failures.
- Full host suite with `--warnings-as-errors`: 219 tests, 0 failures.
- Full Fake-backed browser suite: 27 passed, 3 existing intentional skips.
- Matching Braintree browser lane: 4 passed, including promo behavior, personal Hosted Fields initialization, and organization authorization denial.
- Updated the onboarding browser assertion to require the signed `context_pin` query on its payment-method link; that test passes.
- Confirmed the browser config resolves `Accrue.Processor.Braintree` only for `MIX_ENV=test` with the dedicated lane flag; otherwise it keeps Fake.
- `mix format --check-formatted`, `git diff --check`, browser wrapper `bash -n`, package JSON parsing, and CI workflow YAML parsing passed.
- The first full host suite run exposed a stale static assertion for the prior one-line runtime config; updated the assertion for the test-only provider selector and reran the suite successfully.

---

_Fixed: 2026-10-07T23:03:44Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
