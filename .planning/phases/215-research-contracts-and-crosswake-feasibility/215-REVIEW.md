---
phase: 215-research-contracts-and-crosswake-feasibility
reviewed: 2026-08-01T19:05:00Z
depth: standard
files_reviewed: 19
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
  - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift
  - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift
  - examples/crosswake_tracer/capability-report.json
  - examples/crosswake_tracer/physical-device-evidence.md
  - scripts/ci/verify_v159_authority.sh
findings:
  critical: 2
  warning: 3
  info: 0
  total: 5
status: issues_found
---

# Phase 215: Code Review Report

**Reviewed:** 2026-08-01T19:05:00Z
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

The Elixir and Swift test suites pass, but this review found two fail-closed contract/security gaps.  In particular, the cache forgets its ordering state across a process restart and the checked-in golden-vector metadata can drift without any current checker or test rejecting it.  The generated decision table also publishes the wrong semantic field.

## Critical Issues

### CR-01: Cache permits a stale allow to overwrite a persisted denial after restart

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:156`
**Issue:** The high-water revision and denial precedence live only in `CacheCoordinator` (lines 220-241), which is created with `revision == nil` for every new process.  `replace` persists only opaque bytes and `recover` merely deletes candidates (lines 184-190); neither restores revision/disposition from the canonical cache.  Consequently, after persisting a signed denial at revision 5, restarting the app, and receiving a verified allow at revision 4, `accepts` returns true at line 230 and overwrites the denial.  That violates the rollback/deny-precedence contract and can restore offline access from stale evidence.

**Fix:** Persist authenticated revision and disposition alongside the cached verified entitlement, load and validate that metadata before accepting a replacement, and compare it while holding an interprocess file lock.  Reject a candidate when its revision is lower, or when it equals a persisted denial.

### CR-02: Golden-vector contract metadata can drift while all fixture checks pass

**File:** `accrue/lib/accrue/entitlements/decision_cases/markdown.ex:139`
**Issue:** The offline-drift checker compares only `expected_verification`, `expected_reason`, and `expected_cache_disposition`.  It does not compare `case_id`, `contract_version`, `expected_disposition`, `compact_jws`, or enforce unique IDs.  The independent Swift verifier similarly decodes only the three expected values plus `id`, JWS, and fault point (lines 83-91 of `AccrueOfflineClient.swift`).  For example, changing `case_id` on `v1.59-offline-golden-vectors.json:6` to a nonexistent case is accepted by `mix accrue.entitlements.decision_cases --check`, the Elixir verifier tests, and the Swift tests.  The claimed canonical server/client binding can therefore silently become false.

**Fix:** Make the offline fixture byte-for-byte deterministic like the other generated files, or compare every schema field and validate unique IDs, canonical case membership, version, and expected disposition.  Have the Swift fixture decoder validate those metadata fields too.

## Warnings

### WR-01: Generated markdown labels a lease as continuity

**File:** `accrue/lib/accrue/entitlements/decision_cases/markdown.ex:13`
**Issue:** The fifth table header is `Continuity` (line 23), but each row places `expected.lease` in that column.  Generated documentation consequently reports values such as `fresh` or `denied` as a continuity value instead of `full_actions`, `cached_only`, etc., misleading contract consumers.

**Fix:** Render `expected.continuity` in the fifth position, or rename that column to `Lease` and add a separate Continuity column.

### WR-02: Contract consumer treats unrelated deliveries as the canonical event

**File:** `accrue/test/support/entitlements/decision_case_contract_consumer.ex:49`
**Issue:** `valid_deliveries?/2` accepts any valid `Ordering` with the same relation, while ignoring `provider_cursor` and `observed_at`.  A distinct newer provider event can therefore be supplied as a delivery for this case and the consumer still applies the case's transition.  This makes the conformance/property checks unable to prove that event identity and ordering are honored.

**Fix:** Require each delivery to equal `case_data.ordering`, or implement and test the intended cursor/timestamp comparison before applying a transition.

### WR-03: Swift verifier accepts duplicate security-sensitive JWS claims

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:59`
**Issue:** The Swift verifier passes header and payload JSON directly to `JSONSerialization` and never rejects duplicate `alg`, `kid`, or required claim names.  The Elixir verifier explicitly performs this check at `offline_golden_vector_verifier.ex:62-63`.  A signed compact JWS with duplicate keys can therefore be interpreted differently by the two reference consumers, defeating the stated independent verifier parity.

**Fix:** Before decoding, scan the raw header and payload bytes for exactly one occurrence of every security-sensitive key (matching the Elixir implementation), and add duplicate-key vectors that both implementations reject as malformed.

---

_Reviewed: 2026-08-01T19:05:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
