---
status: complete
phase: 234-admin-customers-subscriptions
source: [234-01-SUMMARY.md, 234-02-SUMMARY.md, 234-03-SUMMARY.md, 234-04-SUMMARY.md, 234-05-SUMMARY.md, 234-06-SUMMARY.md, 234-07-SUMMARY.md, 234-08-SUMMARY.md, 234-VERIFICATION.md]
started: 2026-10-08T02:41:22Z
updated: 2026-10-08T03:26:05.849Z
---

## Current Test

[testing complete]

## Tests

### 1. Served pre-layout baseline
expected: The customer, subscription, and drawer baseline is captured once and verified read-only by byte hashes. Verification: `examples/accrue_host/e2e/phase234-pre-layout.spec.js`.
result: pass
source: automated
coverage_id: D1

### 2. Scoped subscription links and returns
expected: Subscription list identity links open their named records and preserve bounded list context within the active organization. Verification: `subscriptions_live_test.exs`, `subscription_live_test.exs`.
result: pass
source: automated
coverage_id: D2

### 3. Forged return state and stale cursors
expected: Foreign or forged return state remains generic; stale cursors recover to the first scoped page without losing filters. Verification: `scoped_path_test.exs`, `subscriptions_live_test.exs`, `subscription_live_test.exs`.
result: pass
source: automated
coverage_id: D3

### 4. Factual scoped Home
expected: Home shows bounded audit activity and destinations under the same active owner scope, without unsupported aggregate claims. Verification: `dashboard_live_test.exs`.
result: pass
source: automated
coverage_id: D1

### 5. Global search state handling
expected: Search explains supported fields, exact IDs, partial failures, and no matches, and rejects stale query or owner-scope replies. Verification: `global_search_test.exs`.
result: pass
source: automated
coverage_id: D2

### 6. Lifecycle with missing observations
expected: Lifecycle, schedule, collection behavior, and unavailable billing observations render independently. Verification: `subscription_live_test.exs`, `subscriptions_live_test.exs`.
result: pass
source: automated
coverage_id: D1

### 7. Responsive record hierarchy
expected: Customer and subscription detail hierarchy remains readable at 320px and primary controls retain at least 44px targets. Verification: `customer_live_test.exs`, `subscription_live_test.exs`, `phase234-post-layout.spec.js`.
result: pass
source: automated
coverage_id: D2

### 8. Scoped customer and subscription routes
expected: Record links and details retain authorized owner scope and validated return routes. Verification: `subscriptions_live_test.exs`, `subscription_live_test.exs`.
result: pass
source: automated
coverage_id: D3

### 9. Eligible action review
expected: Eligible subscription actions are visible and reviewed with precise consequences and timing. Verification: `subscription_live_test.exs`.
result: pass
source: automated
coverage_id: D1

### 10. Drift blocks dispatch
expected: Scope, lifecycle, and item drift after review or step-up prevents Billing dispatch, while unrelated metadata does not invalidate the review. Verification: `subscription_live_test.exs`, `step_up_test.exs`.
result: pass
source: automated
coverage_id: D2

### 11. Stable action operation identity
expected: One operation identity survives confirmation and step-up; duplicates and stale continuations are suppressed, including after reconnect. Verification: `subscription_live_test.exs`, `step_up_test.exs`.
result: pass
source: automated
coverage_id: D1

### 12. Truthful action feedback
expected: Feedback matches available evidence; ambiguous submissions disable blind retry and provide scoped evidence paths. Verification: `subscription_live_test.exs`.
result: pass
source: automated
coverage_id: D2

### 13. Verified compensation navigation
expected: Compensation retains the original subscription context and only renders replacement navigation after owner-scoped verification. Verification: `subscription_live_test.exs`.
result: pass
source: automated
coverage_id: D3

### 14. Served Admin investigation and keyboard coverage
expected: Served owner-scoped investigation, return navigation, search-dialog keyboard interaction, narrow/coarse-pointer layout, reduced motion, and CSS asset equality work. Verification: `phase234-admin-customers-subscriptions.spec.js`.
result: pass
source: automated
coverage_id: D1

### 15. Mounted owner-denial controls
expected: Mounted owner denial, authorized counterpart, foreign payment-method event denial, and non-Admin billing-manager denial all behave as intended. Verification: `verify01-admin-denial.spec.js`.
result: pass
source: automated
coverage_id: D2

### 16. Admin suite, assets, and CI discovery
expected: Admin tests and asset build pass, and CI discovers the required browser specs. Verification: `mix test`, `mix accrue_admin.assets.build`, `.github/workflows/ci.yml`.
result: pass
source: automated
coverage_id: D3

### 17. Related-record returns
expected: Customer and subscription journeys retain authorized context through invoice and payment detail returns. Verification: `customer_live_test.exs`, `subscription_live_test.exs`, `invoice_live_test.exs`, `charge_live_test.exs`.
result: pass
source: automated
coverage_id: D1

### 18. Forged customer return rejection
expected: Forged, foreign, stale, and alternate-mount customer returns are rejected without changing owner scope. Verification: `scoped_path_test.exs`, `invoice_live_test.exs`, `charge_live_test.exs`.
result: pass
source: automated
coverage_id: D2

### 19. Automated acceptance evidence
expected: All testable Phase 234 acceptance claims have passing executable evidence; a confirmation-only handoff is not required.
result: pass
source: automated
verification: Focused Elixir tests, asset build, real-pool search browser lane twice, and both Phase 234 served browser tests.

### 20. Database-backed global-search completion
expected: In Admin, select a nondefault organization and search for a known customer email. Wait for the real scoped query to finish, confirm the matching identity is shown and opens the correct customer, then change the query or scope and confirm the old result is no longer selectable.
result: pass
source: automated
verification: ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX=1 ACCRUE_HOST_BROWSER_PORT=4102 npm run e2e:search -- --workers=1 (two consecutive runs)

### 21. Step-up expiry
expected: After a successful step-up is more than five minutes old, start a destructive subscription action. A fresh challenge appears; canceling leaves the subscription unchanged, and no Billing call occurs before successful verification.
result: pass
source: automated
verification: cd accrue_admin && mix test test/accrue_admin/live/step_up_test.exs

### 22. Nested step-up keyboard behavior
expected: Open a destructive subscription review and trigger step-up. Tab and Shift+Tab stay inside the active challenge; Escape dismisses without mutation and focus returns to the action flow.
result: pass
source: automated
verification: env -u ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX npm run e2e -- e2e/phase234-admin-customers-subscriptions.spec.js --workers=1

### 23. Visual readability and states
expected: Inspect customer/subscription lists and details plus search/list empty and partial-error states in light and dark themes at desktop and narrow widths. Identity, lifecycle, and action facts remain readable and state copy stays clear.
result: pass
source: automated
verification: Phase 234 browser suite runs axe for customer detail and light/dark subscription detail, asserts 14px type and 1.2 line-height, checks no overflow at 320px, and pairs with passing global_search_test.exs copy coverage.

## Summary

total: 23
passed: 23
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-234-1
  truth: A real owner-scoped async global search completes from database query through rendered result and navigation, and stale matches are no longer selectable.
  status: resolved
  reason: Existing host Playwright runs use Ecto SQL Sandbox, so Task workers cannot read the seeded database; the browser remains in its loading state.
  severity: major
  test: 20
  artifacts: [examples/accrue_host/e2e/phase234-search-completion.spec.js, .github/workflows/ci.yml]
  missing: [Non-sandbox test-pool browser execution of the real async query]
  resolved_by: 234-08-PLAN.md
  resolved_at: 2026-10-08

- gap_id: G-234-2
  truth: An expired step-up grace window requires a fresh challenge and does not run the continuation before successful verification.
  status: resolved
  reason: Existing unit tests prove first challenge and grace grant but not expiry after the five-minute window.
  severity: major
  test: 21
  artifacts: [accrue_admin/test/accrue_admin/live/step_up_test.exs]
  missing: [Behavioral expired-grace test asserting zero dispatch before verification]
  resolved_by: 234-08-PLAN.md
  resolved_at: 2026-10-08

- gap_id: G-234-3
  truth: A served nested step-up dialog contains keyboard focus, Escape cancels without mutation, and focus returns to the staged action flow.
  status: resolved
  reason: The host test adapter auto-approves step-up and the current browser test never opens the nested challenge.
  severity: major
  test: 22
  artifacts: [examples/accrue_host/lib/accrue_host/auth.ex, examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js, accrue_admin/lib/accrue_admin/live/subscription_live.ex]
  missing: [Deterministic test-only challenge plus served Tab/Shift+Tab/Escape/no-mutation/focus-return assertions]
  resolved_by: 234-08-PLAN.md
  resolved_at: 2026-10-08

- gap_id: G-234-4
  truth: Recurring UI checks establish readable primary detail facts, accessible contrast/semantics, clear empty/partial-error copy, theme coverage, and narrow-screen reflow without human confirmation.
  status: resolved
  reason: Existing source tests cover state copy and saved captures exist, but current Phase 234 served evidence does not machine-check key detail typography in both themes or current browser accessibility/reflow.
  severity: major
  test: 23
  artifacts: [examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js, accrue_admin/test/accrue_admin/components/global_search_test.exs, .github/workflows/ci.yml]
  missing: [Current served theme/accessibility/computed-readability/reflow evidence linked to the blocking browser lane]
  resolved_by: 234-08-PLAN.md
  resolved_at: 2026-10-08
