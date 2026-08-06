---
phase: 224-crosswake-host-command-bridge-seam
reviewed: 2026-08-06T20:21:28Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - scripts/ci/verify_crosswake_host_commands.sh
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 224: Code Review Report

**Reviewed:** 2026-08-06T20:21:28Z
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

Reviewed the Phase 224 host-command verification runner and cross-checked its pinned lock, conformance evidence, and the referenced Crosswake trusted-frame implementation. The current exact lock resolves to `fc5e399f`; both `trusted-frame` and `full` passed locally, and the trusted implementation rejects subframe, cross-origin, and non-page-world sender contexts before decoding.

The runner, however, executes an unvalidated shell program obtained from the mutable JSON lock. This defeats the expected command-boundary safety of the evidence runner and must be fixed before it is used as a trusted CI gate.

## Critical Issues

### CR-01: Lock-controlled value is executed with `eval`

**Classification:** BLOCKER

**File:** `/Users/jon/projects/accrue/scripts/ci/verify_crosswake_host_commands.sh:63-64`

**Issue:** `test_target` is read from `crosswake-source-lock.json` and passed directly to `eval`. A change such as `"test_target": "swift test ...; <arbitrary command>"` causes that arbitrary command to run in the authorized Crosswake checkout whenever `tracer`, `admission`, `lifecycle`, or `trusted-frame` is invoked. The source gate verifies the Crosswake revision and audit digest, but it does not constrain this lock field to the expected SwiftPM invocation. Consequently a data-only lock update can turn the evidence runner into an arbitrary-command execution primitive and can also silently substitute a non-conformance test for the trusted-frame proof.

**Fix:** Do not execute a command string from the lock. Keep the required command as literal argv in the runner (or compare the lock field to one exact expected literal before invoking that literal), for example:

```bash
expected_test_target='swift test --package-path packages/crosswake-shell-core-ios --filter HostCommandAdmissionTests'
test_target="$(jq -er '.test_target' "$lock")"
[[ "$test_target" == "$expected_test_target" ]] || {
  echo "unexpected pinned test target" >&2
  exit 80
}
(cd "$CROSSWAKE_SOURCE_ROOT" && swift test \
  --package-path packages/crosswake-shell-core-ios \
  --filter HostCommandAdmissionTests)
```

Use separate literal commands for modes that intentionally require different suites; do not reintroduce `eval` or shell-escaped JSON arguments.

---

_Reviewed: 2026-08-06T20:21:28Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
