---
phase: 165
status: clean
depth: standard
files_reviewed: 7
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
reviewed_at: 2026-06-02T01:09:00Z
---

# Phase 165 Code Review

## Scope

Reviewed source/config files changed by Phase 165:

- `.github/workflows/ci.yml`
- `examples/accrue_host/config/test.exs`
- `examples/accrue_host/e2e/onboarding_and_billing.spec.js`
- `examples/accrue_host/lib/accrue_host_web/endpoint.ex`
- `examples/accrue_host/lib/accrue_host_web/router.ex`
- `examples/accrue_host/playwright.config.js`
- `examples/accrue_host/lib/accrue_host_web/controllers/sandbox_controller.ex` (removed during review)

## Findings

No open findings.

## Resolved During Review

### Sandbox owner lifecycle

The initial custom sandbox controller was removed before this review was finalized. It had two correctness risks:

- The Playwright helper called `DELETE /api/sandbox`, but the custom router matched `DELETE /api/sandbox/:metadata`.
- The controller called `Ecto.Adapters.SQL.Sandbox.stop_owner/1` with `AccrueHost.Repo`; the API expects the owner pid returned by `start_owner!/2`.

Resolution: `examples/accrue_host/lib/accrue_host_web/endpoint.ex` now configures the built-in `Phoenix.Ecto.SQL.Sandbox` route with `at: "/api/sandbox"`, `repo: AccrueHost.Repo`, and `header: "x-sandbox-id"`. This matches the documented external-client POST/DELETE lifecycle and the checked-in Playwright helper.

## Verification

- `actionlint .github/workflows/ci.yml` passed.
- `cd examples/accrue_host && MIX_ENV=test mix compile --warnings-as-errors` passed.
- `grep -c "playwright-e2e:" .github/workflows/ci.yml` returned `1`.
- `grep -c "host-docker-smoke:" .github/workflows/ci.yml` returned `1`.
- `grep -c "continue-on-error: true" .github/workflows/ci.yml || true` returned `0`.

## Residual Risk

Focused Playwright rerun was inconclusive in the local environment because existing Phoenix server processes saturated local Postgres connections before the browser reached the billing flow. Re-run the focused spec in a clean local server/DB environment or rely on the new CI lane for a clean runner.
