---
phase: 221-close-gap-reference-host-apple-notification-ingress
plan: 06
subsystem: reference-host-ingress
tags: [apple, phoenix, rate-limiting, trusted-proxy, runtime-config, mix-verify]
requires:
  - phase: 221-05
    provides: Production Apple ingress, source-contract proof, and bounded host verification
provides:
  - Catalog-bound Apple product-map validation at production boot
  - Trusted-edge peer resolution for process-local Apple backpressure
  - Deterministic regression coverage for both prior ingress-boundary gaps
affects: [reference-host, apple-notification-ingress, reconciliation-admission, deployment-guidance]
tech-stack:
  added: []
  patterns: [finite host-owned allowlists, strict trusted-proxy resolution, privacy-safe runtime errors]
key-files:
  created: []
  modified:
    - examples/accrue_host/lib/accrue_host/apple_notification_ingress.ex
    - examples/accrue_host/lib/accrue_host/apple_rate_policy.ex
    - examples/accrue_host/config/runtime.exs
    - examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs
    - examples/accrue_host/test/accrue_host/apple_rate_policy_test.exs
    - examples/accrue_host/test/install_boundary_test.exs
    - examples/accrue_host/README.md
key-decisions:
  - "Apple product-map plans resolve only from the configured host entitlement catalog, never BEAM-wide atoms."
  - "Forwarded client identity is accepted only from an exact trusted direct peer and must be one numeric IP."
patterns-established:
  - "Trusted edge: direct clients use their canonical remote IP; trusted proxies supply one strictly parsed forwarded IP."
  - "Runtime allowlists: parse deployment declarations once at boot and fail with bounded errors."
requirements-completed: [D-04, D-05, D-08]
coverage:
  - id: D1
    description: "Production Apple product maps accept only configured entitlement plan keys before atom resolution."
    requirement: D-04
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/accrue_host_web/apple_notification_ingest_test.exs test/accrue_host/apple_rate_policy_test.exs test/install_boundary_test.exs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Trusted-proxy and direct-peer backpressure identities remain isolated and spoof-resistant."
    requirement: D-08
    verification:
      - kind: integration
        ref: "test/accrue_host/apple_rate_policy_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The bounded reference-host verification lane preserves the Apple ingress contract."
    requirement: D-05
    verification:
      - kind: integration
        ref: "cd examples/accrue_host && mix verify"
        status: pass
    human_judgment: false
duration: 17min
completed: 2026-08-05
status: complete
---

# Phase 221 Plan 06: Apple Ingress Boundary Gap Closure Summary

**Apple product maps now resolve only configured entitlement plans, while the local rate backstop safely resolves a client peer across an explicit trusted edge.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-08-05T17:51:00Z
- **Completed:** 2026-08-05T18:08:35Z
- **Tasks:** 2/2
- **Files modified:** 7

## Accomplishments

- Bound `APPLE_PRODUCT_MAP_JSON` values to exact configured entitlement-plan keys before atom resolution, including rejection of existing but unconfigured VM atoms.
- Added strict trusted-proxy parsing and peer resolution: direct clients ignore forwarding headers, while trusted proxies must provide exactly one numeric client address.
- Documented the `APPLE_TRUSTED_PROXY_IPS` deployment contract and added source-level plus deterministic integration coverage.

## Task Commits

1. **Task 1: Reject product mappings outside the configured entitlement catalog** — `feb5ca48` (RED test), `d3941b00` (GREEN feature)
2. **Task 2: Enforce a trusted-edge peer-resolution contract for local backpressure** — `524396d8` (RED test), `9baf8cdf` (GREEN feature)

## Files Created/Modified

- `examples/accrue_host/lib/accrue_host/apple_notification_ingress.ex` — finite, catalog-bound product-map loader.
- `examples/accrue_host/lib/accrue_host/apple_rate_policy.ex` — trusted direct-peer and strict forwarded-IP resolver.
- `examples/accrue_host/config/runtime.exs` — production entitlement catalog and trusted-proxy wiring.
- `examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs` — configured/unconfigured product-map regressions.
- `examples/accrue_host/test/accrue_host/apple_rate_policy_test.exs` — trusted proxy, spoofing, malformed header, and parser proofs.
- `examples/accrue_host/test/install_boundary_test.exs` — runtime and README source-contract guards.
- `examples/accrue_host/README.md` — trusted-edge and local-only operational guidance.

## Decisions Made

- Use the host entitlement catalog as the only product-map plan allowlist; do not use VM atom existence as authorization.
- Deny malformed trusted-edge forwarding metadata temporarily rather than pooling it under the proxy address.

## Verification

- PASS — focused ingress, rate-policy, and source-contract suite: 23 tests, 0 failures.
- PASS — formatter check for all plan-owned Elixir files.
- PASS — `cd examples/accrue_host && mix verify`: 63 tests, 0 failures.
- PASS — plan diff contains only the seven declared reference-host files; no package source, dependency, migration, or raw-evidence fixture changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test isolation] Assigned a distinct supervised-child ID for each trusted-policy test server**
- **Found during:** Task 2
- **Issue:** The initial test helper collided with the default supervised policy child ID before exercising trusted-proxy behavior.
- **Fix:** Passed the unique server name as the ExUnit supervised child ID.
- **Files modified:** `examples/accrue_host/test/accrue_host/apple_rate_policy_test.exs`
- **Verification:** Trusted-proxy focused suite passes.
- **Committed in:** `524396d8`

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** Test-only isolation repair; no production scope expansion.

## Issues Encountered

- Existing compiler warnings in `accrue/lib/accrue/entitlements/reference_scenarios.ex` were emitted during host verification but did not fail the bounded suites and were outside this plan's host-only scope.

## Known Stubs

None.

## User Setup Required

Production adopters must set the documented `APPLE_TRUSTED_PROXY_IPS` declaration: an explicit empty string selects direct-peer mode; otherwise it is a comma-separated numeric IP allowlist.

## Next Phase Readiness

The two blocking ingress-boundary truths now have deterministic coverage. Phase verification can re-run the bounded host lane without provider credentials.

## Self-Check: PASSED

- All seven plan-owned files exist.
- All four task commits are present in git history.
