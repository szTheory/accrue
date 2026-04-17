# Phase 21 plan 01 — summary

- Extended `scripts/ci/accrue_host_seed_e2e.exs` with deterministic fixture data for **two host orgs** (alpha/beta), admin fixture orgs, tax-invalid and admin-denial hints, and cleanup for fixture customer emails.
- Contract: `ACCRUE_HOST_E2E_FIXTURE` path written by seed; Playwright `global-setup` / `fixture.js` unchanged in contract.
- `phase13-canonical-demo.spec.js` kept aligned with the extended fixture shape.

Verification: seed run with temp `ACCRUE_HOST_E2E_FIXTURE` per README VERIFY-01; `npx playwright test` phase13 as part of full suite.
