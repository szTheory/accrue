---
phase: 215
slug: research-contracts-and-crosswake-feasibility
status: validated
nyquist_compliant: true
wave_0_complete: true
updated: 2026-08-02
---

# Phase 215 — Nyquist Validation Contract

This contract records the automated coverage audited after all fifteen Phase-215 plans completed. The live audit on 2026-08-02 reran the Elixir, Swift, authority, and source-matrix gates successfully.

## Test Infrastructure

| Lane | Framework / entry point | Audit command | Result |
|---|---|---|---|
| Elixir contract and property tests | ExUnit + StreamData under `accrue/test` | `cd accrue && mix accrue.entitlements.decision_cases --check && mix test test/accrue/docs/v159_authority_docs_test.exs test/accrue/entitlements/decision_cases_test.exs test/property/entitlement_decision_cases_property_test.exs test/accrue/entitlements/source_test.exs test/accrue/entitlements/entitlement_source_matrix_guard_test.exs test/accrue/entitlements/offline_golden_vectors_test.exs` | PASS — 33 tests and 5 properties |
| Swift client/cache contract | Swift Testing under `examples/crosswake_tracer/Tests` | `cd examples/crosswake_tracer && swift test` | PASS — 23 tests in 3 suites |
| Research authority | Shell mutation/drift gate | `bash scripts/ci/verify_v159_authority.sh` | PASS |
| Source capability matrix | Shell conformance/leakage gate | `bash scripts/ci/verify_entitlement_source_matrix.sh` | PASS |

## Per-Task Coverage Map

| Plan / task | Requirements | Automated verification | Status |
|---|---|---|---|
| 215-01 T1 | RAIL-05 | `CapabilityReportTests` plus report-status and dependency assertions | COVERED |
| 215-01 T2 | RAIL-05 | Full Swift suite plus report/research separation assertions | COVERED |
| 215-02 T1 | RSCH-01, RSCH-03 | Authority/ledger/index assertions | COVERED |
| 215-02 T2 | RSCH-01, RSCH-03 | Authority shell gate plus authority ExUnit fixture | COVERED |
| 215-03 T1 | RSCH-02 | Decision-case ExUnit suite | COVERED |
| 215-03 T2 | RSCH-02 | Deterministic export check plus decision-case suite | COVERED |
| 215-03 T3 | RSCH-02 | Decision-case property suite | COVERED |
| 215-04 T1 | RAIL-04 | Source registry ExUnit suite | COVERED |
| 215-04 T2 | RAIL-04 | Source registry ExUnit suite | COVERED |
| 215-04 T3 | RAIL-04 | Source-matrix shell gate plus negative ExUnit fixture | COVERED |
| 215-05 T1 | RSCH-02, RAIL-05 | Export drift check plus decision-case suite | COVERED |
| 215-05 T2 | RSCH-02, RAIL-05 | Elixir and Swift golden-vector suites | COVERED |
| 215-06 T1 | RSCH-02 | Decision-case rejection tests | COVERED |
| 215-06 T2 | RSCH-02 | Decision-case and property suites plus production-boundary assertion | COVERED |
| 215-07 T1 | RSCH-02, RAIL-05 | Export drift check plus contradiction regressions | COVERED |
| 215-07 T2 | RSCH-02, RAIL-05 | Elixir and Swift golden-vector suites | COVERED |
| 215-08 T1 | RSCH-01, RSCH-02, RSCH-03, RAIL-04, RAIL-05 | Swift golden-vector concurrency coverage | COVERED |
| 215-08 T2 | RSCH-01, RSCH-02, RSCH-03, RAIL-04, RAIL-05 | Complete Phase-215 regression and immutable report check | COVERED |
| 215-09 T1 | RSCH-02, RAIL-05 | Export drift and exhaustive corpus-mutation tests | COVERED |
| 215-09 T2 | RSCH-02, RAIL-05 | Elixir canonical vector-binding tests | COVERED |
| 215-10 T1 | RSCH-02, RAIL-05 | Swift canonical vector-binding tests and clean report diff | COVERED |
| 215-11 T1 | RAIL-05 | Swift signed-denial/high-water tests | COVERED |
| 215-11 T2 | RAIL-05 | Separate-process cache tests plus complete phase regression | COVERED |
| 215-12 T1 | RSCH-01, RSCH-02, RSCH-03, RAIL-04, RAIL-05 | Golden-vector and separate-process ordering tests | COVERED |
| 215-12 T2 | RSCH-01, RSCH-02, RSCH-03, RAIL-04, RAIL-05 | Capability-report schema tests plus complete phase regression | COVERED |
| 215-13 T1 | RAIL-05 | Authenticated-cache and legacy-overwrite negative tests | COVERED |
| 215-13 T2 | RAIL-05 | False-proof tests plus complete phase regression | COVERED |
| 215-14 T1 | RSCH-01, RSCH-02, RSCH-03, RAIL-04, RAIL-05 | Caller-evidence provenance tests plus complete phase regression | COVERED |
| 215-15 T1 | RAIL-05 | Canonical-root hostile-fixture regression plus complete phase regression | COVERED |

## Feedback Order

Run the narrowest affected suite immediately after each task, then run the plan-level integration command. Plan 215-11 must run the separate-process suite before the complete Phase-215 regression gate so restart, lock, authentication, and crash-envelope failures return focused feedback first.

## Targeted Automated Gates

| Plan | Scope | Targeted command | Planned acceptance |
|---|---|---|---|
| 215-09 | Decision-table semantics, complete offline export drift detection, and canonical Elixir binding | `cd accrue && mix accrue.entitlements.decision_cases --check && mix test test/accrue/entitlements/decision_cases_test.exs test/accrue/entitlements/offline_golden_vectors_test.exs` | Lease and continuity remain distinct; every schema/value/identity mutation and duplicate/missing/extra vector fails deterministically. |
| 215-10 | Swift exact-schema, vector identity, field-value, and canonical metadata binding | `cd examples/crosswake_tracer && swift test --filter GoldenVectorTests && cd ../.. && git diff --exit-code -- examples/crosswake_tracer/capability-report.json` | Golden-vector/canonical metadata and same-process coverage pass without changing the feasibility report. |
| 215-11 focused | Separate-process restart, interprocess lock, wrong-key/tamper, and crash-envelope behavior | `cd examples/crosswake_tracer && swift test --filter AtomicOfflineCacheProcessTests` | A fresh process restores authenticated denial/high-water state, stale allow cannot replace it, races serialize, and invalid envelopes fail closed. |
| 215-11 final | Complete Phase-215 automated regression | `bash scripts/ci/verify_v159_authority.sh && bash scripts/ci/verify_entitlement_source_matrix.sh && test -s .planning/phases/215-research-contracts-and-crosswake-feasibility/COVERAGE.md && rg -q 'No external API integration' .planning/phases/215-research-contracts-and-crosswake-feasibility/COVERAGE.md && cd accrue && mix accrue.entitlements.decision_cases --check && mix test test/accrue/entitlements/decision_cases_test.exs test/property/entitlement_decision_cases_property_test.exs test/accrue/entitlements/offline_golden_vectors_test.exs && cd ../examples/crosswake_tracer && swift test && cd ../.. && git diff --exit-code -- examples/crosswake_tracer/capability-report.json` | Authority, source, generated contract, Elixir, all Swift suites, capability semantics, and checked-in report immutability pass together. |

`scripts/ci/verify_v159_authority.sh` together with its negative ExUnit fixtures is the complete Phase-215 authority-bundle acceptance gate. No additional semantic-completeness review or maintainer approval is required by this phase.

## Capability Report Terminal Contract

`CapabilityReportTests.swift` must validate the checked-in report and mutation candidates deterministically:

- The capability identities are exactly `Capability.allRequired`, with no duplicate, unknown, or missing row.
- Every row uses only known evidence kinds and its required/evidence kinds are coherent with that capability's declaration.
- One terminal state is complete proof: every required capability is `proven`, every required evidence lane is present, and `overall_status` is `proven`.
- The other terminal state is honest blockage: unavailable authoritative Crosswake or physical-device evidence produces a consistent capability set and `overall_status: feasibility_blocked`.
- Mixed, partial, unknown-status, missing-evidence, and false-proven reports fail the automated suite.

`feasibility_blocked` is an accepted Phase-215 outcome. It prevents runtime coupling and does not emit `human_needed`, create a manual UAT checkpoint, or claim unavailable evidence was proven. The physical-device runbook and evidence file remain informational inputs for a future separately authorized runtime-coupling phase, not Phase-215 acceptance gates.

## Nyquist Coverage

| Risk | First failing signal | Final integration signal |
|---|---|---|
| Incorrect continuity or incomplete generated-corpus binding | Plan 215-09 targeted ExUnit/export command | Plan 215-11 complete regression |
| Swift ignores canonical metadata drift | Plan 215-10 `GoldenVectorTests` | Plan 215-11 complete regression |
| Restart loses denial/high-water or processes bypass serialization | Plan 215-11 `AtomicOfflineCacheProcessTests` | Full Swift package in Plan 215-11 complete regression |
| Capability report omits/duplicates rows or claims an incoherent terminal state | `CapabilityReportTests` within the full Swift package | Plan 215-11 complete regression plus report clean-diff gate |
| Authority or source contract drifts | Existing shell gate and negative ExUnit fixtures | Plan 215-11 complete regression |

All behavior-changing tasks have an automated focused gate and a complete integration gate. No watch-mode command is used.

## Manual-Only Verifications

**Manual-Only Verifications:** None for Phase 215.

## Validation Audit 2026-08-02

| Metric | Count |
|---|---:|
| Requirements audited | 5 |
| Tasks audited | 29 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
