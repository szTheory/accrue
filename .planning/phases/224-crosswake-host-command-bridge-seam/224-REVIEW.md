---
phase: 224-crosswake-host-command-bridge-seam
reviewed: 2026-08-07T01:14:12Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - /Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift
  - /Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift
  - /Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift
  - scripts/ci/verify_crosswake_host_commands.sh
  - scripts/ci/test_verify_crosswake_host_commands.sh
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 224: Code Review Report

**Reviewed:** 2026-08-07T01:14:12Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The literal-argv runner is safe against the tested lock-target substitution path, and the focused 17-test suite passes at the requested pin. The host-command lifecycle is still not atomic with route replacement: an old route can be admitted, claimed in the new epoch, and executed after navigation. The configuration factory also makes host-command configurations discard every pre-existing bridge delegate and accepts versions that are not strict SemVer.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Route replacement can authorize and execute a request validated for the prior route

**Classification:** BLOCKER

**File:** `/Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:310-378`

**Issue:** The protocol, route, origin, pack, and descriptor guards read `session` without `hostCommandInvocationLock`; only `claimHostCommandInvocation` locks and snapshots it. `update` changes both `session` and `routeEpoch` under that lock at lines 278-284. An invocation can therefore pass all guards using the old `dashboard` session, be pre-empted by `update(settings)`, then claim `(newEpoch, correlationID)` and snapshot the new `settings` session at lines 372-378. It dispatches the host delegate and terminalizes successfully because the claim and snapshot are now internally consistent, even though its request was authorized for a route that has been replaced. This violates the claimed route-scoped admission boundary and can run a stale side effect after navigation.

**Fix:** Serialize taking a session/epoch snapshot and all host-command admission checks with route replacement. For example, lock once, copy `(session, routeEpoch)`, validate the request against that copy, and atomically insert the invocation key only if the current epoch/session still equal the copy; release the lock before telemetry/delegate work. Add an interleaving regression that pauses after validation, calls `update`, then resumes and asserts no delegate call and no reply.

## Warnings

### WR-01: Validated host configuration silently disables all existing bridge delegates

**Classification:** WARNING

**File:** `/Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift:59-89`

**Issue:** `validating` is the only public way to configure host commands, but it calls the private initializer that sets every existing delegate (`appInfo`, haptics, permissions, notification token, share, files, and route) to `nil` at lines 60-68. A shell configured for an admitted host command consequently loses all normal bridge capabilities instead of extending its existing safe bridge configuration.

**Fix:** Let the validated construction path accept and preserve the ordinary delegate parameters (or provide a throwing host-command addition method that returns a copy retaining them). Add a regression that configures an ordinary delegate and a host descriptor together, then verifies both commands remain usable.

### WR-02: The descriptor validator is not strict Semantic Versioning

**Classification:** WARNING

**File:** `/Users/jon/projects/crosswake-accrue-bridge/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift:92-96`

**Issue:** `Character.isNumber` accepts non-ASCII numeral characters, and the check also permits leading zero components (for example, `01.0.0`). Both are invalid under SemVer's numeric identifier grammar, despite this being the sole strict descriptor-validation gate. Since bridge admission compares descriptor, manifest, and request versions for exact equality, such a malformed value can be configured and admitted if each input repeats it.

**Fix:** Validate against SemVer's ASCII grammar, including the no-leading-zero rule, or reuse a parser that exposes strict parsing. For a release-only three-component form, require each component to be `0` or `[1-9][0-9]*`; add rejection tests for `01.0.0` and a Unicode-digit version.

---

_Reviewed: 2026-08-07T01:14:12Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
