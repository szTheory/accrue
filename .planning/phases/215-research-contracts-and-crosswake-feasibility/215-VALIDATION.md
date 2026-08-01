---
phase: 215
slug: research-contracts-and-crosswake-feasibility
status: ready
nyquist_compliant: true
wave_0_complete: true
updated: 2026-08-01
---

# Phase 215 — Gap-Closure Validation Contract

This contract defines the automated gates planned for gap-closure Plans 215-09, 215-10, and 215-11. It records what executors must run; it does not claim the newly planned implementation tests have already passed.

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
