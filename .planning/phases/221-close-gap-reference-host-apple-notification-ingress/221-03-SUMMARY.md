---
phase: 221-close-gap-reference-host-apple-notification-ingress
plan: "03"
subsystem: payments
tags: [apple, phoenix, plug, genserver, postgres, telemetry, privacy]
requires:
  - phase: 221-close-gap-reference-host-apple-notification-ingress
    provides: Real-router Apple ingress with durable notification intake and reconciliation wakeups
provides:
  - Supervised, process-local direct-peer fixed-window Apple notification backpressure
  - Router proof for response classes, bounded quarantine, duplicate convergence, and privacy-safe diagnostics
affects: [221-04, 221-05, examples/accrue_host]
tech-stack:
  added: []
  patterns:
    - Supervised local rate-policy callback with injectable monotonic clock
    - Fake-controlled router tests that retain PostgreSQL as duplicate correctness authority
key-files:
  created:
    - examples/accrue_host/lib/accrue_host/apple_rate_policy.ex
    - examples/accrue_host/test/accrue_host/apple_rate_policy_test.exs
  modified:
    - examples/accrue_host/lib/accrue_host/application.ex
    - examples/accrue_host/config/runtime.exs
    - examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs
key-decisions:
  - "Use a bounded, single-node direct-peer fixed window as a temporary host backstop; shared edge infrastructure remains authoritative across nodes."
  - "Keep response, quarantine, duplicate, and privacy proof at the host router while using only Fake verifier controls."
requirements-completed: [D-03, D-08, D-09, D-10, D-11]
coverage:
  - id: D1
    description: Direct-peer Apple ingress backpressure is deterministic, bounded, and ignores forwarded headers.
    requirement: D-08
    verification:
      - kind: unit
        ref: examples/accrue_host/test/accrue_host/apple_rate_policy_test.exs#allows a configured direct peer limit then temporarily denies it
        status: pass
    human_judgment: false
  - id: D2
    description: Host Apple route preserves response classes, durable quarantine, duplicate convergence, and empty evidence-safe diagnostics.
    requirement: D-03
    verification:
      - kind: integration
        ref: examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs#router maps verification rate and quarantine outcomes to empty response classes
        status: pass
    human_judgment: false
metrics:
  duration: 17min
  completed: 2026-08-05
status: complete
---

# Phase 221 Plan 03: Apple Ingress Backpressure and Edge Proof Summary

**The reference host now applies bounded local direct-peer backpressure and proves its Apple ingress contract across response, durability, concurrency, and privacy boundaries.**

## Performance

- **Duration:** 17 min
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added `AccrueHost.AppleRatePolicy`, a supervised fixed-window callback keyed exclusively from normalized direct `remote_ip`, with bounded state and injected-clock proof.
- Wired the rate callback into production Apple ingress options without changing database authority or adding dependencies.
- Expanded real-router coverage for rate/config/verification responses, parser and Plug size boundaries, durable quarantine, persistence failure, barrier-controlled duplicates, reconciliation wakeups, and negative privacy assertions.

## Verification

- PASS — `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host_web/apple_notification_ingest_test.exs test/accrue_host/apple_rate_policy_test.exs --warnings-as-errors` (10 tests, 0 failures).
- PASS — `cd examples/accrue_host && mix format --check-formatted` for all five scoped files.
- PASS — `cd examples/accrue_host && mix verify` (37 tests, 0 failures).

## Task Commits

1. **Task 1 RED: rate-policy proof** — `82ea86b4` (`test(221-03)`)
2. **Task 1 GREEN: supervised rate backstop** — `7ee71059` (`feat(221-03)`)
3. **Task 2 RED: router edge coverage** — `a4c8b22e` (`test(221-03)`)
4. **Task 2 GREEN: router edge proof** — `53566f7a` (`test(221-03)`)

## Files Created/Modified

- `examples/accrue_host/lib/accrue_host/apple_rate_policy.ex` — bounded process-local direct-peer rate-policy GenServer.
- `examples/accrue_host/lib/accrue_host/application.ex` — supervises the policy before the host endpoint.
- `examples/accrue_host/config/runtime.exs` — connects ingress to the host-owned callback.
- `examples/accrue_host/test/accrue_host/apple_rate_policy_test.exs` — deterministic fixed-window and peer-isolation proof.
- `examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs` — response, durability, concurrency, and privacy-negative router proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the default monotonic clock callback syntax**
- **Found during:** Task 1
- **Issue:** The first implementation used an invalid remote-function capture with an argument.
- **Fix:** Replaced it with a zero-arity clock function.
- **Files modified:** `examples/accrue_host/lib/accrue_host/apple_rate_policy.ex`
- **Verification:** Focused policy test passes.
- **Commit:** `7ee71059`

**Total deviations:** 1 auto-fixed (Rule 1).

## Known Stubs

None.

## Next Phase Readiness

The host now has a bounded ingress seam and merge-blocking edge proof. Plan 221-04 can add reconciliation queue/sweeper wiring without treating the local limiter or Oban uniqueness as distributed correctness authority.

## Self-Check: PASSED

- All five scoped files exist.
- All four TDD commits exist in git history.
- No plan-created source file contains TODO, FIXME, placeholder, or empty rendering stubs.
