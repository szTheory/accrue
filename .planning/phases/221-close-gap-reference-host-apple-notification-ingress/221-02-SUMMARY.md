---
phase: 221-close-gap-reference-host-apple-notification-ingress
plan: "02"
subsystem: payments
tags: [apple, phoenix, plug, postgres, oban, runtime-configuration]
requires:
  - phase: 221-close-gap-reference-host-apple-notification-ingress
    provides: wrapper-forward route and production-only verifier contract decisions
provides:
  - Host-owned Apple notification ingress that forwards exact captured bytes to Accrue's NotificationPlug
  - Production-only verifier configuration reused by ingress and reconciliation admission
  - Fake-backed router proof for durable Apple intake and reconciliation wakeup
affects: [221-03, 221-04, 221-05, examples/accrue_host]
tech-stack:
  added: []
  patterns:
    - Dedicated bounded Apple raw-body Phoenix pipeline separate from Stripe
    - Runtime-owned wrapper resolves notification options only at request time
    - One immutable Verifier.Config is shared by ingress and reconciliation admission
key-files:
  created:
    - examples/accrue_host/lib/accrue_host/apple_notification_ingress.ex
    - examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs
  modified:
    - examples/accrue_host/lib/accrue_host_web/router.ex
    - examples/accrue_host/config/runtime.exs
key-decisions:
  - "Use wrapper-forward: the host forwards /webhooks/apple to its own Plug, which initializes and delegates unchanged to NotificationPlug."
  - "Read production trust roots and product mappings at boot, then reuse one production Verifier.Config term across ingress and reconciliation admission."
requirements-completed: [D-01, D-02, D-03, D-04, D-05, D-06, D-09, D-11]
coverage:
  - id: D1
    description: Exact opaque JSON bytes traverse the real host router, durable Apple intake, and reconciliation wakeup before a 200 response.
    requirement: D-01
    verification:
      - kind: integration
        ref: examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs#POST /webhooks/apple preserves exact bytes before durable intake and wakeup
        status: pass
    human_judgment: false
  - id: D2
    description: Apple uses a dedicated 262,144-byte raw-body pipeline and shares one production verifier configuration across ingress and reconciliation admission.
    requirement: D-04
    verification:
      - kind: integration
        ref: examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs#Apple source keeps a dedicated bounded raw-body pipeline and shared production verifier config
        status: pass
    human_judgment: false
metrics:
  duration: 14min
  completed: 2026-08-05
status: complete
---

# Phase 221 Plan 02: Host Apple Ingress Tracer Summary

**A host-owned `/webhooks/apple` route now preserves exact request bytes through Accrue verification, PostgreSQL intake, and reconciliation wakeup before acknowledging delivery.**

## Performance

- **Duration:** 14 min
- **Tasks:** 1/1
- **Files modified:** 4 production/test files

## Accomplishments

- Added `AccrueHost.AppleNotificationIngress`, a thin runtime-option resolver that delegates unchanged to `Accrue.Entitlements.Apple.NotificationPlug`.
- Added the isolated `:accrue_apple_notifications_raw_body` pipeline with JSON parsing, the caching reader, and the 262,144-byte boundary; the existing Stripe 1,000,000-byte pipeline is unchanged.
- Added production fail-fast inputs for pinned roots, bundle/application identity, config version, bearer authorization, and product mappings; the same `verifier_config` term feeds both ingress and reconciliation admission.
- Proved the real host router sends byte-identical opaque JSON to the Fake verifier and returns 200 only after durable intake and a reconciliation wakeup exist.

## Verification

- PASS — `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host_web/apple_notification_ingest_test.exs --warnings-as-errors` (2 tests, 0 failures).
- PASS — targeted `mix format --check-formatted` for the four scoped files.
- PASS — source assertions prove the dedicated Apple pipeline, unchanged Stripe boundary, wrapper delegate, required production inputs, and shared `verifier_config` term.
- UNRUN — `cd examples/accrue_host && mix verify` stops at unrelated tracked formatting violations; details are in `deferred-items.md`.

## Task Commits

1. **Task 1 RED: add failing router tracer** — `fa20f287` (`test(221-02)`)
2. **Task 1 GREEN: implement host Apple notification ingress** — `81bdf309` (`feat(221-02)`)

## Files Created/Modified

- `examples/accrue_host/lib/accrue_host/apple_notification_ingress.ex` — host wrapper plus strict PEM-root and product-map loaders.
- `examples/accrue_host/lib/accrue_host_web/router.ex` — dedicated Apple body pipeline and wrapper-forward route.
- `examples/accrue_host/config/runtime.exs` — shared production verifier/client/admission configuration.
- `examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs` — real-router Fake verifier and durable-state proof.

## Decisions Made

- Kept the generic Accrue macro and NotificationPlug untouched; runtime ownership remains in the reference host wrapper.
- Treat production roots, app identity, client authorization, and product mapping as fail-fast runtime inputs, with no logged values or test fixtures containing provider evidence.

## Deviations from Plan

None - implementation followed the approved wrapper-forward and production-only configuration decisions exactly.

## Issues Encountered

- The full `mix verify` command is blocked before its test suite by unrelated formatting violations. The scoped formatter and focused router proof pass; the unrelated files were not changed.

## Known Stubs

None.

## Next Phase Readiness

The reference host has the proven ingress foundation needed for the remaining response-class, rate-policy, reconciliation-scheduling, and documentation work.

## Self-Check: PASSED

- All four scoped source/test files exist.
- Both TDD commits exist in git history.
- No plan-created source file contains a TODO, FIXME, placeholder, or empty rendering data stub.
