---
phase: 215-research-contracts-and-crosswake-feasibility
reviewed: 2026-08-02T01:10:30Z
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
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 215: Code Review Report

**Reviewed:** 2026-08-02T01:10:30Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

The Elixir decision corpus, generated fixtures, CI authority check, Swift harness, and capability artifact were reviewed. The scoped Elixir and Swift test suites pass, but the public cache API can discard a verified denial through an unauthenticated path, and the checked-in capability-report validator treats arbitrary text as sufficient evidence for a `proven` terminal state. Both defeat the intended fail-closed feasibility and entitlement guarantees.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Unauthenticated public cache path can overwrite a verified denial

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:324-338`

**Issue:** `AtomicOfflineCache(url:)` is public and its public `replace(with:)` method writes raw payload bytes with an implicit `.allow` and `Int64.max`. When that API is used for the same path as an authenticated cache, `loadVerifiedEnvelope()` deliberately returns `nil` without an authentication key (line 412), and `CacheCoordinator.accepts` explicitly admits the raw max-revision allow (line 511). Consequently, a caller can overwrite a persisted, authenticated signed denial with arbitrary unauthenticated data. This bypasses both the HMAC verification and same-revision deny precedence that the authenticated API is meant to enforce.

**Fix:** Remove the unauthenticated initializer and raw replacement API from the production target, or make them internal test-only seams compiled only for tests. Require an authentication key and an explicit verified disposition/revision for every public write. For example:

```swift
public init(url: URL, authenticationKey: SymmetricKey) { /* ... */ }

public func replaceVerified(
    payload: Data,
    disposition: Disposition,
    revision: Int64
) throws {
    // authenticated envelope path only
}
```

### CR-02: Capability report can assert false feasibility proof with placeholder evidence

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:699-727`

**Issue:** `CheckedInCapabilityReportValidator.validate` accepts every all-`proven` report whose evidence locations are merely non-empty (line 713). It does not reject `unavailable:` locations in the proven state, require evidence locations to resolve to the required compile-unit/device records, or validate the report's required top-level `reason`. A modified checked-in report can therefore change all statuses and `overall_status` to `proven`, retain the current unavailable/placeholder strings (or replace them with arbitrary text), and pass this validator. Any automation consuming the validator can falsely unlock a feasibility-gated runtime coupling.

**Fix:** Treat the report as a closed schema and validate proof locations by evidence kind. At minimum, reject unavailable/pending placeholder locations for `.proven`, require a non-empty reason with semantics consistent with the terminal status, and require each location to be a permitted, existing evidence artifact. Add mutation tests for a false-proven report carrying the current `unavailable:` locations and for omitted/mismatched reason.

---

_Reviewed: 2026-08-02T01:10:30Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
