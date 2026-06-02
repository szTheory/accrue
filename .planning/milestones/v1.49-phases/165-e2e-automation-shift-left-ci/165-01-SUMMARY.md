---
phase: 165-e2e-automation-shift-left-ci
plan: 01
subsystem: "tests"
tags: ["e2e", "sandbox", "playwright"]
requires: []
provides: ["E2E-04"]
affects: ["examples/accrue_host"]
tech-stack:
  added: ["Phoenix.Ecto.SQL.Sandbox"]
  patterns: ["conditional-compilation", "test-api"]
key-files:
  created: []
  modified:
    - examples/accrue_host/config/test.exs
    - examples/accrue_host/lib/accrue_host_web/endpoint.ex
    - examples/accrue_host/lib/accrue_host_web/router.ex
decisions:
  - Configure Phoenix.Ecto.SQL.Sandbox at /api/sandbox in test so Playwright tests can get dedicated Ecto sandboxes and release them through the built-in POST/DELETE lifecycle.
requirements-completed: [E2E-04]
metrics:
  duration_minutes: 1
  completed_date: "2026-06-01"
---
# Phase 165 Plan 01: E2E Automation Shift Left CI Summary

Ecto Sandbox infrastructure has been set up to allow deterministic E2E testing in Playwright via the built-in `Phoenix.Ecto.SQL.Sandbox` `/api/sandbox` endpoint.

## Deviations from Plan

The original implementation used a custom sandbox controller. Phase review replaced it with the built-in `Phoenix.Ecto.SQL.Sandbox` route because the custom DELETE route did not match the Playwright helper and could not stop the owner pid safely.

## Threat Flags

None - the Sandbox endpoint is conditionally bound to the `:test` environment.

## Self-Check: PASSED
