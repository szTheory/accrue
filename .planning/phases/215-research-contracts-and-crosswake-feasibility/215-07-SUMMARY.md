---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 07
subsystem: testing
tags: [elixir, swift, jws, golden-vectors, security]
requires:
  - phase: 215-06
    provides: canonical D-07 decision-case contract
provides:
  - Deterministic signed offline golden-vector corpus
  - Field-for-field Elixir and Swift JWS observation parity
affects: [215-08, 219-crosswake]
tech-stack:
  added: []
  patterns: [ordered JSON export, corpus-as-oracle reader tests, closed disposition decoding]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/entitlements/decision_cases/markdown.ex
    - accrue/priv/entitlements/v1.59-offline-golden-vectors.json
    - accrue/test/support/entitlements/offline_golden_vector_verifier.ex
    - accrue/test/accrue/entitlements/offline_golden_vectors_test.exs
    - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift
key-decisions:
  - "Use ordered JSON objects so checked-in decision and golden fixtures are deterministic between VM processes."
  - "Treat the corpus expectation fields as the reader oracle instead of maintaining duplicated observed-result maps."
  - "Reject malformed high-water values and unknown signed dispositions before cache replacement."
requirements-completed: [RSCH-02, RAIL-05]
metrics:
  tasks_completed: 2
  files_modified: 8
status: complete
---

# Phase 215 Plan 07: Offline Golden Corpus Parity Summary

The v1.59 signed offline corpus now acts as the authoritative Elixir/Swift security oracle, including deterministic malformed-claim and unknown-disposition vectors.

## Accomplishments

- Completed the signed invalid-input corpus and corrected fault-before-replace to preserve its prior deny cache.
- Regenerated stale malformed, unknown-disposition, and wrong-type JWS bytes with the canonical test key.
- Made exporter JSON ordering stable and made drift checks report missing vectors and mutated expectation fields.
- Compared every vector's verification, bounded reason, and cache result against the declared fixture expectation in both readers.
- Closed both readers over allow/deny dispositions and integer revision, iat, and freshness claims.

## Verification

- `cd accrue && mix accrue.entitlements.decision_cases --check`
- `cd accrue && mix test test/accrue/entitlements/decision_cases_test.exs test/accrue/entitlements/offline_golden_vectors_test.exs` — 17 tests, 0 failures
- `cd examples/crosswake_tracer && swift test --filter GoldenVectorTests` — 2 tests, 0 failures
- `jq -e '.overall_status == "feasibility_blocked"' examples/crosswake_tracer/capability-report.json`

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Stabilized JSON fixture key ordering and missing-vector drift detection.
- **Found during:** Task 2
- **Issue:** exporter output could differ between processes due to map traversal order; empty vector arrays did not report omitted vectors.
- **Fix:** recursively encoded JSON with ordered objects and reported both the fixture path and missing vector IDs.
- **Files modified:** `accrue/lib/accrue/entitlements/decision_cases/markdown.ex`, `accrue/priv/entitlements/v1.59-decision-cases.json`
- **Commit:** 299da7cc

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed task commits `2cb4a5ff` and `299da7cc` exist.
- Confirmed the corpus, both readers, and parity tests exist and the named verification gates passed.
