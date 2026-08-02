---
phase: 215-research-contracts-and-crosswake-feasibility
reviewed: 2026-08-02T00:24:12Z
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
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 215: Code Review Report

**Reviewed:** 2026-08-02T00:24:12Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

The generated entitlement corpus, its exporters, and the authority script were reviewed alongside the Swift feasibility package. The scoped Elixir tests and `swift test` pass, but the Swift high-water abstraction rejects an equally revised signed denial, and the public capability-report reducer can mark an unsupported schema as proven.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Equal-revision denial is rejected by the high-water gate

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:577`

**Issue:** `ProofHighWater.accepts(newer:)` requires `candidate.revision > revision` without carrying or considering disposition. A signed denial at the same revision as an already-cached allow therefore fails the gate, despite `AtomicOfflineCache` deliberately giving a same-revision denial precedence (lines 393-395) and the golden corpus including a deny-precedence case. A caller that uses this advertised `iat`/revision/freshness gate before replacing the cache can retain an allow after a valid denial.

**Fix:** Model the candidate disposition in the gate and accept an equal-revision denial over a non-denial state, or ensure signed denials bypass this gate. For example:

```swift
public func accepts(candidate: ProofHighWater, disposition: AtomicOfflineCache.Disposition) -> Bool {
    if candidate.revision > revision {
        return candidate.issuedAt >= issuedAt && candidate.freshnessDeadline >= freshnessDeadline
    }
    return candidate.revision == revision && disposition == .deny
}
```

Add a test that starts from an allow at revision `n` and verifies a signed denial at revision `n` is admitted and replaces it.

## Warnings

### WR-01: Invalid capability-report schema can still produce a proven result

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:648`

**Issue:** `CapabilityReport.init(schemaVersion:capabilities:)` stores `schemaVersion` but never validates it. Supplying an unsupported version such as `"999"` with a complete evidence list produces `.proven` at lines 653-667. Consumers of this public model can consequently treat data outside the defined report contract as a proven feasibility result. The checked-in JSON validator does validate its schema, but the programmatic API does not.

**Fix:** Reject unsupported versions in the initializer (prefer a throwing initializer) or force `.feasibilityBlocked` unless the version is `"1.0"`; add a test covering the invalid-version path.

---

_Reviewed: 2026-08-02T00:24:12Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
