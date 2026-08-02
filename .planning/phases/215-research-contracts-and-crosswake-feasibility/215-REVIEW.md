---
phase: 215-research-contracts-and-crosswake-feasibility
reviewed: 2026-08-02T02:20:34Z
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

**Reviewed:** 2026-08-02T02:20:34Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Reassessed the current HEAD, including the 215-14 capability-report changes. The public `CapabilityReport` constructor now correctly remains blocked, resolving the prior report's false-proof finding. However, the separately public URL-based validator still treats any caller-selected directory as a trusted evidence root. Two malformed-fixture paths also fail unsafely rather than producing contract diagnostics.

Verification run: the focused Elixir suite (30 tests), `mix accrue.entitlements.decision_cases --check`, `verify_v159_authority.sh`, and `swift test` all pass. These results do not exercise the arbitrary-root provenance boundary or the malformed fixture cases below.

## Critical Issues

### CR-01: Arbitrary report URLs can establish false feasibility provenance

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:685`

**Issue:** `CheckedInCapabilityReportValidator.validate(reportURL:)` accepts a caller-selected URL and treats that URL's parent as the evidence root. A caller can create a temporary directory containing a syntactically valid `capability-report.json`, placeholder files at `Sources/AccrueOfflineClient/*.swift`, `Evidence/CrosswakeBridge/*.swift`, and `Evidence/Simulator/*.md`, plus a minimally complete `physical-device-evidence.md`; a uniformly `proven` report then passes `validProvenEvidence`. No fixed checked-in location, immutable bundle identifier, signature, or content hash ties the public entry point to the project-owned artifact. If a future feasibility gate uses this public method, untrusted local files can unlock it.

**Fix:** Remove the public arbitrary-URL entry point. Expose only a validated loader anchored to a fixed bundle resource (and validate a signed/hashed evidence manifest), or require the expected canonical report URL and reject every other standardized URL before decoding.

## Warnings

### WR-01: Fixture-controlled strings are interned as unbounded BEAM atoms

**File:** `accrue/test/support/entitlements/offline_golden_vector_verifier.ex:120`

**Issue:** The verifier calls `String.to_atom/1` on `expected_reason` from the JSON fixture. Atoms are never garbage-collected. A malformed or adversarial fixture containing many distinct fault reasons can exhaust the BEAM atom table and terminate the test VM rather than yielding a contract-validation error.

**Fix:** Use a closed mapping of permitted reasons, for example `Map.fetch(@reason_atoms, value)`, and return `{:error, :invalid_expected_reason}` for unknown values.

### WR-02: Offline drift checking raises on scalar vectors

**File:** `accrue/lib/accrue/entitlements/decision_cases/markdown.ex:167`

**Issue:** If the checked-in `vectors` list contains a scalar such as `["corrupt"]`, `duplicate_id_drift/2` calls `Map.get/2` on that scalar and raises `BadMapError`. The same unsafe assumption appears in `vector_identity_drift/3` at line 176. Consequently `mix accrue.entitlements.decision_cases --check` crashes instead of issuing its normal drift failure for a malformed artifact.

**Fix:** Verify every vector is a map before accessing `id` (for example, a `vector_id/1` helper with a non-map clause) and include a named invalid-vector diagnostic in the returned drift list.

---

_Reviewed: 2026-08-02T02:20:34Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
