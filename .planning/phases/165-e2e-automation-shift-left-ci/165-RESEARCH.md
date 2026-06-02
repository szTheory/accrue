# Phase 165: E2E Automation & Shift-Left CI - Research

**Status:** Completed
**Date:** 2026-06-01

## 1. Context & Objectives

The goal of Phase 165 is to shift E2E testing left by integrating Playwright E2E tests for `accrue_host` into GitHub Actions (`.github/workflows/ci.yml`). We need to automate the onboarding, checkout, and billing happy paths (E2E-01, E2E-02) and execute them in CI (E2E-03). The tests must run reliably against seeded data with zero flakiness (E2E-04). 

## 2. Implementation Strategy

### 2.1 Ecto Sandbox Configuration (D-02)

To enable isolated state management and fast parallel tests, we need to wire up `Phoenix.Ecto.Sandbox` in `examples/accrue_host`:
- **Endpoint Injection**: In `examples/accrue_host/lib/accrue_host_web/endpoint.ex`, add the `Phoenix.Ecto.Sandbox` plug before the session plug, conditionally active in the `:test` environment. It should extract a user-agent string or HTTP header (e.g. `x-sandbox-id`) to identify the test session.
- **Global Setup**: Update `examples/accrue_host/e2e/global-setup.js` (or add to `playwright.config.js`) to set a unique HTTP header per browser context that Phoenix uses to check out an Ecto sandbox transaction.

### 2.2 Playwright Configuration (D-04)

`examples/accrue_host/playwright.config.js` is currently configured for sequential execution:
```javascript
  fullyParallel: false,
  workers: 1,
```
This needs to be updated:
- Change `fullyParallel: true`
- Adjust `workers: process.env.CI ? 2 : undefined` (or to use `process.env.PLAYWRIGHT_WORKERS || '2'`) to shard properly across workers in GitHub Actions.
- Ensure the `webServer` is set to run in `MIX_ENV=test` and relies on the `Fake` processor (D-03).

### 2.3 CI Integration (D-01)

Update `.github/workflows/ci.yml` to run the E2E suite:
- Add a new job `accrue-host-e2e` (or similar) that runs on `ubuntu-24.04`.
- Setup Elixir (using existing action caches).
- Setup Node.js (v22).
- Install dependencies (`mix deps.get`, `npm ci` in `examples/accrue_host`).
- Run `npx playwright install --with-deps`.
- Run `npx playwright test`.
- Add a job to run the Docker-based check to verify the local container dev UX is intact.

### 2.4 E2E Test Files (E2E-01, E2E-02, E2E-04)

We need Playwright tests implemented in `examples/accrue_host/e2e/`:
- `e2e/onboarding.spec.js`: Test primary onboarding and checkout flow.
- `e2e/billing.spec.js`: Test billing management (upgrade, downgrade, cancel, add payment method).
- Must utilize the seeded data correctly and ensure tests do not leak state (relying on the Ecto Sandbox).
- Fake processor guarantees network determinism, preventing flake.

## 3. Recommended Plan Structure

1. **Setup Playwright Sandbox**: Configure Elixir Endpoint and Playwright to pass Ecto Sandbox tokens.
2. **Update Playwright Config**: Enable `fullyParallel: true` and set up workers.
3. **Write E2E-01**: Implement onboarding/checkout happy paths.
4. **Write E2E-02**: Implement billing management tests.
5. **CI Integration (E2E-03, E2E-04)**: Wire up the new Playwright checks and Docker validation job in `ci.yml`.

## 4. Risks & Mitigations
- **Flakiness**: Using the Ecto Sandbox and `Fake` processor (instead of Live Stripe) mitigates the risk of external network failure or data race conditions.
- **CI Times**: Adding an E2E job can slow down PRs. Mitigated by parallelization in Playwright (`fullyParallel`) and splitting jobs in GH Actions.
