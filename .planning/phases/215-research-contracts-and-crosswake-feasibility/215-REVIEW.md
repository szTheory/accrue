---
phase: 215-research-contracts-and-crosswake-feasibility
reviewed: 2026-08-02T02:46:30Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - accrue/lib/accrue/entitlements/decision_cases.ex
  - accrue/lib/accrue/entitlements/decision_cases/markdown.ex
  - accrue/lib/mix/tasks/accrue.entitlements.decision_cases.ex
  - accrue/priv/entitlements/v1.59-decision-cases.json
  - accrue/priv/entitlements/v1.59-offline-golden-vectors.json
  - accrue/test/accrue/docs/v159_authority_docs_test.exs
  - accrue/test/accrue/entitlements/decision_cases_test.exs
  - accrue/test/accrue/entitlements/offline_golden_vectors_test.exs
  - accrue/test/property/entitlement_decision_cases_property_test.exs
  - accrue/test/support/entitlements/decision_case_contract_consumer.ex
  - accrue/test/support/entitlements/offline_golden_vector_verifier.ex
  - examples/crosswake_tracer/Package.swift
  - examples/crosswake_tracer/Sources/AccrueOfflineCacheCrashHarness/main.swift
  - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
  - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/AtomicOfflineCacheProcessTests.swift
  - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift
  - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift
  - examples/crosswake_tracer/capability-report.json
  - examples/crosswake_tracer/physical-device-evidence.md
  - scripts/ci/verify_v159_authority.sh
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 215: Code Review Report

**Reviewed:** 2026-08-02T02:46:30Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Reviewed the Elixir decision corpus/exporter, offline-vector fixtures and consumers, Swift cache and feasibility gate, test coverage, and authority-verification script. The focused Elixir suite (25 tests and 5 properties) and Swift suite (23 tests) pass. However, the future transition from blocked to proven feasibility can be certified with placeholder evidence because the checked-in validator only establishes file presence and superficial text markers.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Proven capability state accepts arbitrary non-empty files as evidence

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:759`
**Issue:** In the `.proven` branch, each evidence item is accepted when its path is beneath an allowed directory, has the expected extension, and is non-empty. For example, a one-line `Evidence/CrosswakeBridge/placeholder.swift` and any non-empty `Sources/AccrueOfflineClient/*.swift` pass. Neither the source content nor a build result is bound to the report. A later report edit can therefore turn `overall_status` to `proven` without a working Crosswake bridge or native proof, defeating the stated feasibility gate.

**Fix:** Bind each evidence item to a checked, structured artifact rather than file existence. For example, require a signed/versioned manifest with immutable revision and SHA-256 for each compile unit, require bridge sources to be in a declared SwiftPM target, and validate a recorded successful build/test artifact for that pinned revision before returning `.proven`. Add a negative test using the current one-line placeholder files and assert validation rejects it.

### WR-02: Physical-device proof can be satisfied by template-like text

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:781`
**Issue:** `physicalDeviceEvidenceIsComplete` treats a physical-device record as complete if it lacks a few blocked words and contains any ISO date plus two headings. It does not require lane results, a device-class value, build invocation, attestor/reviewer identities, or non-placeholder evidence locations. A minimally edited template can therefore satisfy `.physicalDevice` and allow a report to become `.proven` despite no documented device run.

**Fix:** Parse a versioned, closed-schema evidence record and require each D-10 lane to include a real command/scenario, pass result, redacted evidence reference, UTC run date, attestation, and reviewer approval. Reject placeholders (`Pending`, `YYYY-MM-DD`, empty cells) structurally, and add mutation tests for each required field.

---

_Reviewed: 2026-08-02T02:46:30Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
