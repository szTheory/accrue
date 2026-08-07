---
phase: 224-crosswake-host-command-bridge-seam
reviewed: 2026-08-07T01:20:18Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - examples/crosswake_tracer/capability-report.json
  - scripts/ci/test_verify_crosswake_host_commands.sh
  - scripts/ci/verify_crosswake_host_commands.sh
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 224: Code Review Report

**Reviewed:** 2026-08-07T01:20:18Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

The literal Swift invocation correctly removes the prior shell-evaluation path, and the new regression script passes. However, the remote-identity sanitization rejects any otherwise-valid HTTPS checkout that has credentials embedded in its origin URL, making the gate unusable in that supported configuration.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Credential-bearing HTTPS remotes can never pass the source gate

**Classification:** BLOCKER

**File:** `scripts/ci/verify_crosswake_host_commands.sh:25`

**Issue:** The single-quoted `sed` replacement contains `\\1`, which passes two backslashes to `sed`; it produces a literal `\\1***@…` instead of reinserting the captured `https://` prefix. For example, an origin of `https://token@github.com/szTheory/crosswake.git` becomes `\\1***@github.com/szTheory/crosswake.git`, never matching the lock's `https://github.com/szTheory/crosswake.git`. Consequently any checkout using an authenticated HTTPS remote exits 68 before running verification. The new regression test uses only an unauthenticated origin, so it does not catch this failure.

**Fix:** Use a single backreference slash in the replacement and add a fixture whose `git remote get-url origin` returns a credential-bearing HTTPS URL:

```bash
remote="$(git -C "$CROSSWAKE_SOURCE_ROOT" remote get-url origin | sed -E 's#(https?://)[^/@]+@#\1***@#')"
```

---

_Reviewed: 2026-08-07T01:20:18Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
