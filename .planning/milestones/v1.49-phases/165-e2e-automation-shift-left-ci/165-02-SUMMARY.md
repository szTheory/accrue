---
phase: 165-e2e-automation-shift-left-ci
plan: 02
requirements-completed: [E2E-04]
---

# 165-02 Plan Summary

## Objective
Configure Playwright to use the Ecto Sandbox infrastructure via a custom fixture and enable full parallelism.

## Changes Made
- Created `examples/accrue_host/e2e/support/test.js` providing the Ecto Sandbox Playwright fixture.
- Modified `examples/accrue_host/playwright.config.js` to enable `fullyParallel: true` and configured workers for CI.
- Updated `examples/accrue_host/lib/accrue_host_web/endpoint.ex` to use the `x-sandbox-id` header for `Phoenix.Ecto.SQL.Sandbox`.
- Migrated all `examples/accrue_host/e2e/*.spec.js` files to import `test` and `expect` from the custom fixture instead of `@playwright/test`.
- Updated `examples/accrue_host/e2e/support/fixture.js` to make `reseedFixture()` a no-op as the sandbox now handles test isolation.

## Files Modified
- `examples/accrue_host/e2e/support/test.js` (created)
- `examples/accrue_host/playwright.config.js`
- `examples/accrue_host/e2e/mobile-tag-holder.spec.js`
- `examples/accrue_host/e2e/phase102-portal-checkout.spec.js`
- `examples/accrue_host/e2e/phase13-canonical-demo.spec.js`
- `examples/accrue_host/e2e/verify01-admin-a11y.spec.js`
- `examples/accrue_host/e2e/verify01-admin-denial.spec.js`
- `examples/accrue_host/e2e/verify01-admin-mobile.spec.js`
- `examples/accrue_host/e2e/verify01-admin-mounted.spec.js`
- `examples/accrue_host/e2e/verify01-org-switching.spec.js`
- `examples/accrue_host/e2e/verify01-tax-invalid.spec.js`
- `examples/accrue_host/e2e/support/fixture.js`
- `examples/accrue_host/lib/accrue_host_web/endpoint.ex`
