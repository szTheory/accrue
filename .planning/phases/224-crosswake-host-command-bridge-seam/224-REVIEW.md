---
phase: 224-crosswake-host-command-bridge-seam
reviewed: 2026-08-06T22:10:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - scripts/ci/verify_crosswake_host_commands.sh
  - scripts/ci/test_verify_crosswake_host_commands.sh
  - /Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift
  - /Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeDelegates.swift
  - /Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift
  - /Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 224: Code Review Report

**Reviewed:** 2026-08-06T22:10:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

The focused evidence runner now correctly compares the mutable lock target as data and invokes the reviewed SwiftPM arguments literally; its isolated regression and the exact-pinned `trusted-frame` and `full` modes pass. The Crosswake host-command seam still has two correctness/security defects that allow duplicate side-effecting delegate calls and let hosts bypass mandatory descriptor validation.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Duplicate correlation IDs invoke a side-effecting host delegate more than once

**File:** `/Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:358`

**Issue:** The code invokes `delegate.handle` at lines 365-369 before it checks or reserves `terminalizedHostCommandCorrelations` (lines 376 and 401-404). Repeating an otherwise valid request with the same caller-controlled `correlationID` therefore runs the delegate every time; only subsequent replies are suppressed. A repeated `host.accrue.purchase` request can consequently cause multiple purchase attempts while the page receives at most one reply. The set also persists over session/epoch changes, so a reused ID can silently suppress a later legitimate reply.

**Fix:** Claim an invocation key before calling the delegate, scoped at least to the admitted route epoch/session and correlation ID; reject or suppress duplicate claims before the delegate executes. Remove/expire that scoped key when the route is replaced, and retain a separate terminalization guard only if asynchronous completion makes one necessary. Add tests that send the same admitted request twice and after a route update, asserting one delegate call per invocation key and one reply per accepted invocation.

### CR-02: The public initializer bypasses required host-command descriptor validation

**File:** `/Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift:39`

**Issue:** `CrosswakeShellConfig.init` stores `hostCommandDescriptors` unchanged at line 56, while the validation that is meant to reject unsupported, malformed, and duplicate descriptors exists only in the optional `validating` factory at lines 64-83. The bridge tests and production construction path use the unchecked initializer. A host can therefore install duplicate descriptors or an invalid version such as `1..` and still admit it when the route and request echo that same value, violating the setup-time closed-contract guarantee.

**Fix:** Make the only host-command-bearing construction path validate descriptors (for example, make the initializer `throws` or keep the legacy initializer unable to accept host-command descriptors and require `validating` for them). Validate a real SemVer value, reject duplicate command/capability pairs, and add regression tests proving the ordinary production construction path cannot install invalid descriptors.

---

_Reviewed: 2026-08-06T22:10:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
