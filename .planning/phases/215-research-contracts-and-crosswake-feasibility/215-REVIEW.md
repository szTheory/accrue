---
phase: 215-research-contracts-and-crosswake-feasibility
reviewed: 2026-08-02T01:42:00Z
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
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 215: Code Review Report

**Reviewed:** 2026-08-02T01:42:00Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

The generated Elixir contract and Swift crash-cache paths were reviewed, including their test-only verifiers and checked-in feasibility evidence. The focused Elixir suite and `swift test` pass, but the public Swift capability model can still manufacture a `proven` status without any provenance validation. The contract verification code also has two malformed-input paths that can crash or permanently consume BEAM atoms instead of failing closed.

## Critical Issues

### CR-01: Public capability API can manufacture a false `proven` feasibility result

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:654`

**Issue:** `CapabilityReport.init` reduces to `.proven` when callers supply every enum capability, mark each as `.proven`, and provide the required *labels* in `evidenceKinds`. It neither validates `CapabilityEvidence.location` nor validates the underlying files/device record. The included test demonstrates this exact false-proof construction with `location: "test://native"` at `CapabilityReportTests.swift:8-20`. This contradicts the stricter comment on the checked-in validator that a data-only entry point must not decide runtime feasibility. Any future runtime consumer of this public type can therefore unlock the feasibility gate using arbitrary caller-controlled strings.

**Fix:** Do not expose a data-only initializer that returns `.proven`. Make the report construction/validation accept evidence URLs and run the same provenance checks as `CheckedInCapabilityReportValidator`, or make `CapabilityReport` an untrusted draft whose status is always blocked until a dedicated validated constructor returns a separately typed `ProvenCapabilityReport`.

## Warnings

### WR-01: Fixture-controlled strings are interned as unbounded BEAM atoms

**File:** `accrue/test/support/entitlements/offline_golden_vector_verifier.ex:120`

**Issue:** The verifier calls `String.to_atom/1` on `expected_reason` from the JSON fixture. Atoms are never garbage-collected. A malformed or adversarial fixture containing many distinct fault reasons can exhaust the BEAM atom table and terminate the test VM rather than yielding a contract-validation error.

**Fix:** Use a closed mapping of permitted reasons (for example `Map.fetch(@reason_atoms, value)`) and return `{:error, :invalid_expected_reason}` for unknown text; never create atoms from fixture input.

### WR-02: Drift checking crashes on a non-object vector instead of reporting drift

**File:** `accrue/lib/accrue/entitlements/decision_cases/markdown.ex:167`

**Issue:** When the checked-in `vectors` array contains a scalar (for example `["corrupt"]`), `duplicate_id_drift/2` calls `Map.get/2` on that value and raises `BadMapError`. `mix accrue.entitlements.decision_cases --check` therefore crashes rather than returning the normal drift diagnostic. The same unchecked map assumption occurs in `vector_identity_drift/3` at line 176. This is a malformed-artifact path that the checker is expected to reject cleanly.

**Fix:** Validate that every vector is a map before reading `id`, or use a safe helper such as `defp vector_id(%{} = vector), do: Map.get(vector, "id"); defp vector_id(_), do: nil`, then return a named invalid-vector diagnostic.

---

_Reviewed: 2026-08-02T01:42:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
