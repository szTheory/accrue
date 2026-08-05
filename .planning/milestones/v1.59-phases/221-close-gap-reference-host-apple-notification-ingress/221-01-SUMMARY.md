---
phase: 221-close-gap-reference-host-apple-notification-ingress
plan: "01"
subsystem: payments
tags: [apple, phoenix, plug, verifier, runtime-configuration, host-integration]
requires:
  - phase: 220-first-adopter-proof-and-release-gates
    provides: deterministic host-proof and operator-safety boundaries for the reference host
provides:
  - Explicit wrapper-forward route composition for the host-owned Apple notification ingress
  - Production-only Apple verifier and client runtime configuration contract
affects: [221-02, 221-03, 221-04, 221-05, examples/accrue_host]
tech-stack:
  added: []
  patterns:
    - Host-owned Plug wrapper forwards unchanged to the existing Accrue notification Plug
    - One immutable production verifier config is reused by ingress and reconciliation admission
key-files:
  created:
    - .planning/phases/221-close-gap-reference-host-apple-notification-ingress/221-01-SUMMARY.md
  modified: []
key-decisions:
  - "D-01/D-06: Mount AccrueHost.AppleNotificationIngress with Phoenix forward/3; the wrapper delegates unchanged to Accrue.Entitlements.Apple.NotificationPlug and implements, rather than literally invokes, the macro contract."
  - "D-04/D-05: Use production-only Verifier.Config with identity apple-production-v1 and fail-fast APPLE_TRUST_ROOTS_PEM_PATH, APPLE_BUNDLE_ID, APPLE_APP_ID, APPLE_VERIFIER_CONFIG_VERSION, APPLE_SERVER_API_BEARER_TOKEN, and APPLE_PRODUCT_MAP_JSON inputs."
patterns-established:
  - "Wrapper-forward: host runtime ownership stays outside the Accrue package API while retaining NotificationPlug behavior unchanged."
  - "Immutable Apple verifier config: boot reads and decodes pinned PEM roots to DER once, then shares the same production config term across ingress and reconciliation."
requirements-completed: [D-01, D-04, D-05, D-06]
coverage:
  - id: D1
    description: Approved host-owned wrapper-forward route composition without an Accrue public API expansion.
    requirement: D-01
    verification:
      - kind: other
        ref: "rg -n 'defmacro accrue_apple_notifications|Accrue\\.Entitlements\\.Apple\\.NotificationPlug' accrue/lib/accrue/router.ex"
        status: pass
    human_judgment: false
  - id: D2
    description: Approved production-only immutable verifier/client runtime input contract.
    requirement: D-04
    verification:
      - kind: other
        ref: "rg -n '@enforce_keys|authorization' accrue/lib/accrue/entitlements/apple/verifier.ex accrue/lib/accrue/entitlements/apple/client.ex"
        status: pass
    human_judgment: false
metrics:
  duration: "<1 min"
  completed: 2026-08-05
status: complete
---

# Phase 221 Plan 01: Contract Decisions Summary

**Recorded the approved wrapper-forward route composition and production-only immutable Apple verifier contract that unblock the reference-host ingress tracer.**

## Performance

- **Duration:** <1 min
- **Started:** 2026-08-05T17:23:30Z
- **Completed:** 2026-08-05T17:23:30Z
- **Tasks:** 2/2 decision checkpoints resolved
- **Files modified:** 1

## Accomplishments

- Selected wrapper-forward for D-01/D-06: the host mounts `AccrueHost.AppleNotificationIngress` with Phoenix `forward/3`; its wrapper delegates unchanged to `Accrue.Entitlements.Apple.NotificationPlug`. This preserves the existing macro-defined parser/Plug contract without expanding Accrue's public API.
- Selected the D-04/D-05 production-only configuration: identity `apple-production-v1`; required runtime variables `APPLE_TRUST_ROOTS_PEM_PATH`, `APPLE_BUNDLE_ID`, `APPLE_APP_ID`, `APPLE_VERIFIER_CONFIG_VERSION`, `APPLE_SERVER_API_BEARER_TOKEN`, and `APPLE_PRODUCT_MAP_JSON`.
- Locked the operational semantics for downstream plans: read the PEM file at boot, decode it to pinned DER roots, and reuse one immutable `Verifier.Config` term for notification ingress and reconciliation admission.

## Verification

- PASS — `rg -n "defmacro accrue_apple_notifications|Accrue\\.Entitlements\\.Apple\\.NotificationPlug" accrue/lib/accrue/router.ex` confirms the existing macro hardcodes the package `NotificationPlug`.
- PASS — `rg -n "@enforce_keys|authorization" accrue/lib/accrue/entitlements/apple/verifier.ex accrue/lib/accrue/entitlements/apple/client.ex` confirms the verifier's required configuration fields and the client's bearer authorization contract.
- PASS — No source files were changed by this decision-only plan.

## Task Commits

The two checkpoint decisions were explicitly supplied by the user before execution; they require no source commit. The plan-close metadata commit records both selections.

## Files Created/Modified

- `.planning/phases/221-close-gap-reference-host-apple-notification-ingress/221-01-SUMMARY.md` — durable record of the two approved one-way contracts.

## Decisions Made

1. **D-01/D-06 route composition:** `wrapper-forward` is authoritative. The host does not literally invoke `Accrue.Router.accrue_apple_notifications/2`, because that macro hardcodes the package Plug; instead it implements that macro's contract with a host-owned `forward/3` wrapper that delegates unchanged to the same Plug.
2. **D-04/D-05 verifier/client contract:** production only. Build `Verifier.Config` with constant identity `apple-production-v1` from the six named runtime variables; load and decode the PEM path at boot into pinned DER roots and share the immutable config for ingress and reconciliation admission.

## Deviations from Plan

None - plan executed exactly as written after applying the user's explicit `option-a` selections at both blocking decision checkpoints.

## Issues Encountered

None.

## User Setup Required

None in this decision-only plan. Downstream implementation will require the approved production environment inputs; this plan records their names and semantics without recording values, roots, tokens, payloads, or certificates.

## Next Phase Readiness

Plan 221-02 can implement the tracer using the approved `wrapper-forward` composition and production-only immutable verifier configuration. No package API change is authorized.

## Self-Check: PASSED

- Summary artifact exists at the plan output path.
- Both source-contract verification commands passed.
- This plan intentionally has no source-file changes or task-level source commits.

---
*Phase: 221-close-gap-reference-host-apple-notification-ingress*
*Completed: 2026-08-05*
