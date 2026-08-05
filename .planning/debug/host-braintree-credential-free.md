---
status: resolved
trigger: "Diagnose the credential-free failure in examples/accrue_host test suite: AccrueHost.BraintreeSubscribeTest fails at test/accrue_host/braintree_subscribe_test.exs:199 with missing config :BRAINTREE_MERCHANT_ID. Determine whether this is an existing test-harness/config isolation issue and the minimal safe fix so the entire host suite can run without real credentials."
created: 2026-08-04T20:38:43Z
updated: 2026-08-05T20:42:00Z
---

## Current Focus

hypothesis: Confirmed — the test omits the Braintree subscription gateway seam required by persisted-provenance lifecycle dispatch.
test: Reproduced with credentials absent; traced exact stack; compared to established core isolation pattern; ran full host suite.
expecting: N/A — diagnosis complete.
next_action: Closed by a local cancellation-gateway stub with restored application configuration.

## Symptoms

expected: The complete accrue_host test suite runs without real Braintree credentials.
actual: AccrueHost.BraintreeSubscribeTest fails at test/accrue_host/braintree_subscribe_test.exs:199 due to missing config :BRAINTREE_MERCHANT_ID.
errors: "missing config :BRAINTREE_MERCHANT_ID"
reproduction: Run the accrue_host test suite without real Braintree credentials.
started: Unknown; failure observed in the current worktree.

## Eliminated

## Evidence

- timestamp: 2026-08-04T20:38:43Z
  checked: Git status and recent host Braintree-related history
  found: The worktree has unrelated Phase 220 changes; the host Braintree subscribe test was most recently touched in commit a401bd6f.
  implication: Investigation must avoid modifying unrelated changes and compare recent host-test history if necessary.
- timestamp: 2026-08-04T20:40:15Z
  checked: Host test configuration, AccrueCase setup, Braintree subscribe test, and adjacent Braintree payment-method test.
  found: test.exs configures a fake processor and a Braintree client-token stub, but BraintreeSubscribeTest overrides only :processor; the adjacent payment-method test explicitly replaces Braintree customer and payment-method gateways.
  implication: A missing lower-level Braintree gateway stub is a concrete candidate, while global test credentials would be an unnecessarily broad workaround.
- timestamp: 2026-08-04T20:42:30Z
  checked: Isolated BraintreeSubscribeTest run with BRAINTREE_MERCHANT_ID, BRAINTREE_PUBLIC_KEY, and BRAINTREE_PRIVATE_KEY absent.
  found: The first creation test passes; only the lifecycle cancellation test fails. Its stack trace is Braintree.Subscription.cancel/2 -> Accrue.Processor.Braintree.cancel_subscription/3 -> Accrue.Billing.SubscriptionActions.cancel/2.
  implication: The failure is not at browser acquisition or subscription creation. It is a deterministic lifecycle-dispatch test-isolation failure.
- timestamp: 2026-08-04T20:42:30Z
  checked: SubscriptionActions, GatewayRegistry, Braintree adapter, and core Braintree tests.
  found: SubscriptionActions resolves cancellation with GatewayRegistry using persisted subscription.processor; "braintree" maps to Accrue.Processor.Braintree. That adapter defaults :braintree_subscription_gateway to Braintree.Subscription, while core tests replace that config with a SubscriptionGatewayStub and restore it on exit.
  implication: The minimal safe correction is local test setup of :braintree_subscription_gateway with a cancellation stub, not test-wide credentials or a production dispatch change.
- timestamp: 2026-08-04T20:44:30Z
  checked: Complete examples/accrue_host suite with Braintree credential variables absent.
  found: 195 tests ran; the same Braintree lifecycle test was the only credential failure. A second failure in BillingFacadeTest was an independent duplicate fake subscription constraint error, not a Braintree configuration error.
  implication: The recommended test-local seam removes the credential-free blocker but should not be represented as a fix for the separate full-suite data-isolation failure.
- timestamp: 2026-08-04T20:44:30Z
  checked: Git blame and history for the lifecycle assertion.
  found: The lifecycle test was introduced in commit 9074bb805 / b1df372f2 in May 2026 with only the top-level :processor mock; no subscription-gateway override was ever added.
  implication: This is an existing test-harness gap, not caused by current Phase 220 worktree changes.

## Resolution

root_cause: The test's creation mock persists processor "braintree". Cancellation intentionally resolves persisted provenance through GatewayRegistry to Accrue.Processor.Braintree, which defaults its :braintree_subscription_gateway to real Braintree.Subscription. The test never overrides that lower-level seam, so Braintree.Subscription.cancel/2 reads live credential configuration.
fix: In BraintreeSubscribeTest only, install a minimal :braintree_subscription_gateway stub implementing cancel/2 and restore the prior env value on exit. Return a Braintree.Subscription with status "Canceled" and the same plan/period shape expected by Accrue.Processor.Braintree.translate_subscription/1.
verification: `MIX_ENV=test mix test test/accrue_host/billing_facade_test.exs test/accrue_host/braintree_subscribe_test.exs --warnings-as-errors` passed (20 tests) without Braintree credentials.
files_changed: [examples/accrue_host/test/accrue_host/braintree_subscribe_test.exs]
