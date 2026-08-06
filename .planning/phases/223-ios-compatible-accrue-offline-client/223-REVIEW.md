---
phase: 223-ios-compatible-accrue-offline-client
reviewed: 2026-08-06T16:46:04Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - packages/accrue-offline-client/Package.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/CanonicalJSONAdmission.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineReconnect.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientApple/KeychainCacheKey.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineCacheCrashHarness/main.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/GoldenVectorFixtureSupport.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineEntitlementClientTests.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineReconnectTests.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientProcessTests/AtomicOfflineCacheProcessTests.swift
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 223: Code Review Report

**Reviewed:** 2026-08-06T16:46:04Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

The Swift package and its scoped tests were reviewed at standard depth. `swift test --package-path packages/accrue-offline-client` passes (16 tests), but an unauthenticated compact-JWS input can exhaust the process, and the duplicate-member scanner rejects valid JSON strings containing escaped supplementary Unicode characters.

## Critical Issues

### CR-01: Unbounded recursive admission parser lets unauthenticated proof bytes crash the host

**Classification:** BLOCKER

**File:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/CanonicalJSONAdmission.swift:7-8`

**Issue:** `applyServerProof` invokes `CanonicalJSONAdmission.validate` before signature verification. The scanner copies the complete attacker-controlled decoded segment into an array and descends recursively through every array/object with no byte-size or nesting limit. A response such as a compact JWS whose payload decodes to tens of thousands of nested arrays reaches `value`/`array` recursively before the signature is checked; it can overflow the Swift stack and terminate the app. Very large segments can also force disproportionate allocations. The reconnect transport accepts arbitrary response bytes, so a malicious/captive network response can trigger this without a signing key.

**Fix:** Put a small, documented maximum on compact-proof and decoded header/payload lengths before Base64URL decoding, and make the scanner enforce a maximum nesting depth (or rewrite it as an iterative parser). Return `.malformed` when either limit is exceeded. Add tests using an unsigned, deeply nested payload and an oversized payload to ensure `applyServerProof` returns the bounded invalid state rather than crashing.

## Warnings

### WR-01: Valid JWT JSON using surrogate-pair escapes is rejected as malformed

**Classification:** WARNING

**File:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/CanonicalJSONAdmission.swift:59-61`

**Issue:** JSON represents non-BMP characters with two `\\u` escapes (for example, `"\\uD83D\\uDE00"`). `UnicodeScalar(0xD83D)` is nil because a surrogate is not a standalone Unicode scalar, so the guard rejects the first half even when it is followed by a valid low surrogate. Foundation accepts this JSON. Consequently, a correctly signed proof whose bounded `plans`, `features`, or another string claim contains an escaped supplementary Unicode character is refused before signature verification. The test suite covers duplicate members but has no escaped-Unicode vector.

**Fix:** Decode `\\u` escapes according to the JSON surrogate-pair rules: require a following `\\uDC00...\\uDFFF` after a high surrogate, combine the pair into one scalar, and reject lone high/low surrogates. Add signed fixtures for a valid surrogate pair and invalid lone surrogates.

---

_Reviewed: 2026-08-06T16:46:04Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
