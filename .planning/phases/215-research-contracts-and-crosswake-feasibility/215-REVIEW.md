---
phase: 215-research-contracts-and-crosswake-feasibility
reviewed: 2026-08-01T02:32:55Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - accrue/lib/accrue/entitlements/decision_cases.ex
  - accrue/lib/accrue/entitlements/decision_cases/markdown.ex
  - accrue/lib/mix/tasks/accrue.entitlements.decision_cases.ex
  - accrue/priv/entitlements/v1.59-decision-cases.json
  - accrue/test/accrue/docs/v159_authority_docs_test.exs
  - accrue/test/accrue/entitlements/decision_cases_test.exs
  - accrue/test/property/entitlement_decision_cases_property_test.exs
  - accrue/test/support/entitlements/offline_golden_vector_verifier.ex
  - examples/crosswake_tracer/Package.swift
  - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
  - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift
  - examples/crosswake_tracer/capability-report.json
  - examples/crosswake_tracer/physical-device-evidence.md
  - scripts/ci/verify_v159_authority.sh
findings:
  critical: 1
  warning: 4
  info: 0
  total: 5
status: issues_found
---

# Phase 215: Code Review Report

**Reviewed:** 2026-08-01T02:32:55Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

The checked-in generated artifacts are current, the authority verifier succeeds, and the scoped Elixir and Swift suites pass. The implementation still has an unsafe concurrent cache-replacement path and several validation/test gaps that can allow a malformed or drifted entitlement corpus to be reported as valid.

## Critical Issues

### CR-01 (BLOCKER): Concurrent cache replacements share one staging pathname

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:101`
**Issue:** Every `AtomicOfflineCache.replace` invocation writes to the same `.<name>.candidate` file without synchronization. Two reconciliations can interleave: one caller can rename the other caller's candidate and report success for data it did not write, while the other then fails because its candidate has disappeared. This breaks the advertised verified allow/deny replacement boundary and can persist the wrong entitlement state under concurrent lifecycle/reconnect work.
**Fix:** Serialize replacements for a cache instance (for example, an actor or lock owned by a reference-type cache) and use a unique candidate URL per invocation. Clean the candidate in `defer` on every failure path.

```swift
let candidate = directory.appendingPathComponent(".\(url.lastPathComponent).\(UUID().uuidString).candidate")
// Execute write/fsync/replace while holding the cache's replacement lock.
defer { try? FileManager.default.removeItem(at: candidate) }
```

## Warnings

### WR-01 (WARNING): `valid?/1` does not enforce the claimed closed contract

**File:** `accrue/lib/accrue/entitlements/decision_cases.ex:73`
**Issue:** Validation accepts any atom for `evidence.kind` and does not validate either binding field. It likewise accepts arbitrary atoms for `expected.continuity` and `expected.repair`, and any integer (including a negative delta) for `revision_delta` at lines 91-96. Consequently an invalid case can pass the public `valid?/1` gate despite the test and documentation calling the D-07 schema closed.
**Fix:** Define explicit allowed sets for every enumerated field, require the expected account/device binding values or a closed binding vocabulary, and require a non-negative revision delta. Add negative tests for each field.

### WR-02 (WARNING): The offline verifier accepts untyped claims and unknown signed dispositions

**File:** `accrue/test/support/entitlements/offline_golden_vector_verifier.ex:101`
**Issue:** `verify_high_water/2` compares decoded JSON values without requiring integers; Elixir term ordering can therefore allow string-valued `revision`, `iat`, or `fresh_until` claims through. In addition, `disposition_cache/1` at lines 118-121 maps every signed disposition other than `"deny"` to `:allow`. The corresponding Swift verifier also accepts any decoded disposition as allow at `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:32`. A malformed signed vector can thus be reported as an accepted allow instead of rejected, weakening the merge-blocking verifier contract.
**Fix:** Require `revision`, `iat`, and `fresh_until` to be integers and require `disposition in ["allow", "deny"]` before high-water/cache handling. In Swift, add an equivalent closed disposition guard (preferably decode it as a two-case enum). Add malformed-type and unknown-disposition vectors that must reject.

### WR-03 (WARNING): Golden-vector expectations are parsed but never verified

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:25`
**Issue:** `Vector.expectedVerification`, `expectedReason`, and `expectedCacheDisposition` are decoded but `verifyFixture()` returns observations without comparing them to those fixture fields. The Elixir verifier has the same issue: it derives an observation at `accrue/test/support/entitlements/offline_golden_vector_verifier.ex:40-50` but never checks the fixture's declared outcome. A drifted generated vector can retain a passing implementation test while its advertised expected result is wrong.
**Fix:** After observing each vector, parse and compare all three declared expected fields to the observation; throw/return a named mismatch error. Keep the test assertions, but make the fixture self-validating so every row is covered.

### WR-04 (WARNING): Three property tests are vacuous and do not exercise a decision implementation

**File:** `accrue/test/property/entitlement_decision_cases_property_test.exs:19`
**Issue:** The generated offset, source set, and partial step are never fed into a reducer or decision function. The assertions only re-check fixed values in an immutable fixture; in particular line 51 refutes values that cannot occur because the generator at line 48 never produces them. These properties will continue to pass if ordering, survivor handling, or transactional behavior breaks in a future evaluator.
**Fix:** Expose the decision/reconciliation operation being specified and generate evidence/prior-state permutations as its input. Assert its computed disposition, snapshot, revision, and cache outcome against the canonical case; remove generators that cannot affect the assertion.

### WR-05 (WARNING): Cache durability is not established across a crash after the rename

**File:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift:102`
**Issue:** The candidate data file is synchronized, but the parent directory is never synchronized after `moveItem`/`replaceItemAt`. A process or power loss after the rename can leave the filesystem metadata update non-durable, so the stated old-or-complete-new recovery guarantee is not demonstrated. The `afterRename` fault test only observes the live process, not crash recovery.
**Fix:** Use a durability primitive that fsyncs both the candidate and its parent directory after replacement (or document/platform-gate an equivalent supported API), then add a subprocess crash/reopen test that covers both replacement branches.

---

_Reviewed: 2026-08-01T02:32:55Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
