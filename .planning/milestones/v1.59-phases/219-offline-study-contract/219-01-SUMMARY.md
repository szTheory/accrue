---
phase: 219-offline-study-contract
plan: "01"
subsystem: entitlements
tags: [offline, es256, jose, jws, jwks, security]
requires:
  - phase: "215"
    provides: accepted offline proof contract and test-only P-256 fixture material
  - phase: "217"
    provides: canonical revisioned entitlement projection boundary
provides:
  - strict public-key-only verification for the v1.59 compact ES256 proof profile
  - host-owned signing/key-provider behaviour and deterministic public JWKS rendering
affects: [219-02, 219-03, 219-04, mobile consumers, offline proof issuance]
tech-stack:
  added: [jose 1.11.12]
  patterns: [strict compact JWS parsing, bounded decision taxonomy, local kid selection, public-only JWKS rendering]
key-files:
  created:
    - accrue/lib/accrue/entitlements/offline.ex
    - accrue/lib/accrue/entitlements/offline/proof.ex
    - accrue/lib/accrue/entitlements/offline/key_provider.ex
    - accrue/test/accrue/entitlements/offline_protocol_test.exs
  modified:
    - accrue/mix.exs
    - accrue/mix.lock
key-decisions:
  - "D-09 is published as v1.59 compact JWS with ES256, purpose-specific typ, fixed issuer/audience, and local stable kid selection."
  - "Verification returns bounded four-state decisions and never exposes JOSE/provider details."
  - "Hosts retain signing custody; public JWKS accepts only sorted EC/P-256 sig/ES256 keys and explicit retention requirements."
patterns-established:
  - "Validate compact segment shape, duplicate-sensitive members, protected header, local key, signature, claims, and high-water order before classifying a decision."
  - "Resolve host-owned provider modules at call time and render only allowlisted public JWK members."
requirements-completed: [OFF-01, OFF-06]
coverage:
  - id: D1
    description: Public-key-only v1.59 ES256 proof verification and bounded hostile-input rejection.
    requirement: OFF-01
    verification:
      - kind: unit
        ref: accrue/test/accrue/entitlements/offline_protocol_test.exs
        status: pass
      - kind: unit
        ref: accrue/test/accrue/entitlements/offline_golden_vectors_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Deterministic public-only JWKS rendering, local key rotation, and retention validation.
    requirement: OFF-06
    verification:
      - kind: unit
        ref: accrue/test/accrue/entitlements/offline_protocol_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 16min
  completed: 2026-08-03
status: complete
---

# Phase 219 Plan 01: Offline ES256 Protocol Summary

**Strict v1.59 ES256 compact-proof verification with public-only JWKS rendering and host-retained signing custody.**

## Performance

- **Duration:** 16 min
- **Completed:** 2026-08-03
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added the additive `Accrue.Entitlements.Offline` facade with typed proof claims, decision values, and public-key-only verification.
- Enforced fixed ES256/type/profile semantics, local `kid` lookup, duplicate-sensitive-member rejection, binding/temporal/high-water checks, and bounded D-06 failures.
- Added the host key-provider behaviour and deterministic JWKS renderer that rejects private, symmetric, invalid, duplicate, and prematurely retired key configurations.

## Task Commits

1. **Task 1: Verify one production-profile allow proof through the public facade** — `1c4ab5e1` (RED test), `e453fccb` (implementation).
2. **Task 2: Publish the host key-provider and public-only JWKS boundary** — `84ceeca4` (RED test), `9a207bec` (implementation).

## Files Created/Modified

- `accrue/mix.exs` and `accrue/mix.lock` — locked the approved `:jose` dependency.
- `accrue/lib/accrue/entitlements/offline.ex` — additive public verification and JWKS facade.
- `accrue/lib/accrue/entitlements/offline/proof.ex` — strict compact-proof parser, verifier, claim validation, and classifier.
- `accrue/lib/accrue/entitlements/offline/key_provider.ex` — host signing behaviour and pure public JWKS renderer.
- `accrue/test/accrue/entitlements/offline_protocol_test.exs` — production-profile, negative security, rotation, provider, and retention coverage.

## Decisions Made

- Implemented the explicitly approved D-09 `v1.59` ES256 profile exactly; no token-directed key retrieval is permitted.
- Kept signing unreachable from the public facade and allowed only seven public JWK fields in JWKS output.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Context7 was unavailable, so the installed and approved JOSE 1.11.12 source documentation was inspected locally before implementation. Existing dependency-advisory output was pre-existing and outside this plan's scope.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plans 219-02 through 219-04 can build policy, issuance, durable retention requirements, and reconnect on the typed verifier and provider seams.

## Self-Check: PASSED

- All six plan-owned artifacts exist on disk.
- RED and GREEN commits exist for both TDD tasks.
- Focused protocol, golden-vector, dependency, and format verification passed.
