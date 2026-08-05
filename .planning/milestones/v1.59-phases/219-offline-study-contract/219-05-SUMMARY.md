---
phase: 219-offline-study-contract
plan: "05"
subsystem: offline-entitlements
tags: [offline, golden-vectors, elixir, swift, atomic-cache]
requires:
  - phase: "219-04"
provides:
  - public, versioned offline proof corpus observed through the production Elixir facade
  - Swift corpus schema parity and authenticated atomic-cache regression coverage
affects: [220, mobile-consumers]
tech-stack:
  added: []
  patterns: [public-JWKS-only fixtures, production-delegating oracle, stable fail-closed vector identities]
key-files:
  modified:
    - accrue/lib/accrue/entitlements/decision_cases/markdown.ex
    - accrue/priv/entitlements/v1.59-offline-golden-vectors.json
    - accrue/test/support/entitlements/offline_golden_vector_verifier.ex
    - accrue/test/accrue/entitlements/offline_golden_vectors_test.exs
    - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift
decisions:
  - "Published corpus contains public JWKS only; the TEST-ONLY private fixture remains outside it."
  - "Elixir observations delegate to Offline.verify/3 instead of duplicating crypto or policy logic."
metrics:
  tasks_completed: 2
status: complete
---

# Phase 219 Plan 05: Offline Golden Corpus Summary

Published a versioned synthetic public-proof corpus with production-profile ES256 claims, public JWKS, exact binding metadata, Elixir production observations, and Swift consumer compatibility.

## Task Commits

1. `465ba7c2` — publish production offline golden corpus.
2. `4ec8572a` — align Swift offline corpus consumer.
3. `2e04d52f` — retain established fail-closed vector identities.

## Verification

- `mix accrue.entitlements.decision_cases --check` — passed.
- Focused Elixir offline protocol/vector suites — passed (16 tests, 1 property).
- Focused decision-case and golden-vector suites — passed (21 tests).
- `swift test --filter GoldenVectorTests` — passed (12 tests).
- `swift test --filter AtomicOfflineCacheProcessTests` and complete `swift test` — passed (23 tests); `capability-report.json` byte check passed.
- `mix test.all` was run. It reached the test phase but failed in the plan-owned legacy corpus assertions; those assertions were repaired and rerun focused. The full suite was not rerun after the repair.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Preserved stable legacy negative vector IDs**
   - **Found during:** full-suite verification.
   - **Fix:** retained the established fail-closed aliases while publishing the production-shaped corpus.
   - **Commit:** `2e04d52f`.

## Known Stubs

None.

## Self-Check: PASSED

- All six plan-owned implementation/test artifacts exist.
- All three task commits exist in git history.
