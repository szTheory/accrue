---
phase: 218-apple-observation-and-repair
plan: 11
subsystem: entitlements
tags: [apple, entitlements, es256, x5c, lifecycle]
requires:
  - phase: 218-09
    provides: configured opaque Apple admission
  - phase: 218-10
    provides: Apple reconciliation lifecycle seam
provides:
  - fail-closed provider expiry admission and normalization
  - opaque unbound-lineage repair regression
  - executable valid ES256 Apple-purpose chain proof
affects: [apple-verification, entitlement-projection]
tech-stack:
  added: []
  patterns: [tagged lifecycle normalization, OTP certificate-shape handling]
key-files:
  modified:
    - accrue/lib/accrue/entitlements/apple/admission.ex
    - accrue/lib/accrue/entitlements/apple/reconciliation.ex
    - accrue/lib/accrue/entitlements/apple/verifier/production.ex
key-decisions:
  - "Positive Apple lifecycle evidence requires its verified provider-specific bound."
  - "JWS x5c remains leaf-first while OTP path validation receives the reversed chain."
requirements-completed: [AAPL-01, AAPL-03, AAPL-04]
status: partial
---

# Phase 218 Plan 11: Apple observation and repair Summary

**Fail-closed Apple expiry admission and normalization, opaque repair coverage, and a real ES256 Apple-purpose positive chain verification.**

## Accomplishments

- Active Apple evidence without a parsed provider expiry is rejected before durable admission; internal normalization also rejects nil positive bounds.
- The authorized repair regression now seeds unbound state through configured opaque evidence and keeps forged public structs closed.
- A checked-in test-only P-256 x5c corpus signs a real compact JWS and exercises the Production verifier's path order, purpose extension, and ECDSA key handling.

## Task Commits

1. Task 1 — `af4f3478`, `00150fe4`
2. Task 2 — `cc40caca`, `5a649f73`
3. Task 3 — `0355a8b3`, `05f18ffd`, `c3928025`

## Verification

- `mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs` — passed twice (40 tests, 1 property).
- `mix compile --warnings-as-errors` — passed.
- Targeted `mix format --check-formatted` — passed.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] OTP path validation uses issuer-to-leaf order and exposes decoded certificate extensions.
- Fixed Production's x5c reversal, EC public-key shape, BasicConstraints, and KeyUsage handling.
- Verified by the real ES256 chain fixture.

## Known Gaps

The real-chain fixture proves the valid Apple-purpose chain only. The plan's separate valid hostile chains for wrong/missing leaf or intermediate purposes, CA leaf, and key-usage mutations have not been added, so AAPL-02 remains incomplete and this plan must not close the phase requirement.

## Self-Check: PASSED

- Task commits exist and all tracked implementation and fixture files are present.
