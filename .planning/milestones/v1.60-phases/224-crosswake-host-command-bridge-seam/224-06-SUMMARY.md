---
phase: 224-crosswake-host-command-bridge-seam
plan: "06"
subsystem: verification-security
tags: [bash, swiftpm, crosswake, command-injection, regression]
requires:
  - phase: 224-crosswake-host-command-bridge-seam
    provides: reviewed Crosswake source lock and deterministic conformance runner
provides:
  - Exact lock-target validation before focused Crosswake conformance runs
  - Literal SwiftPM argv execution with regression coverage for substituted targets
affects: [phase-224-verification, crosswake-host-command-bridge]
tech-stack:
  added: []
  patterns: [compare mutable metadata as data, execute reviewed commands as literal argv]
key-files:
  created:
    - scripts/ci/test_verify_crosswake_host_commands.sh
  modified:
    - scripts/ci/verify_crosswake_host_commands.sh
key-decisions:
  - "Treat lock test_target as untrusted data that must exactly match the reviewed command."
  - "Run focused Crosswake conformance with a hard-coded SwiftPM argv instead of shell evaluation."
patterns-established:
  - "Evidence runners validate mutable command metadata before a fixed process invocation."
requirements-completed: [BRDG-01, BRDG-02]
coverage:
  - id: D1
    description: Focused Crosswake conformance rejects shell-bearing and benign substitute targets before process execution.
    requirement: BRDG-02
    verification:
      - kind: unit
        ref: bash scripts/ci/test_verify_crosswake_host_commands.sh
        status: pass
    human_judgment: false
  - id: D2
    description: Exact pinned trusted-frame and full bridge conformance still pass while capability status remains blocked.
    requirement: BRDG-01
    verification:
      - kind: integration
        ref: CROSSWAKE_SOURCE_ROOT=/Users/jon/projects/crosswake-accrue-bridge bash scripts/ci/verify_crosswake_host_commands.sh trusted-frame && full
        status: pass
      - kind: other
        ref: jq blocked-status assertion on examples/crosswake_tracer/capability-report.json
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-08-06
status: complete
---

# Phase 224 Plan 06: Command-Safe Crosswake Evidence Runner Summary

**Focused Crosswake evidence now accepts only the reviewed target and starts `HostCommandAdmissionTests` through fixed literal SwiftPM argv.**

## Accomplishments

- Replaced lock-derived `eval` execution with byte-for-byte target validation followed by a hard-coded `swift test --package-path packages/crosswake-shell-core-ios --filter HostCommandAdmissionTests` invocation.
- Added an isolated disposable-fixture regression that records approved argv and proves shell-bearing and benign substitute targets fail with exit 80 before Swift or injected effects run.
- Re-ran exact-pin trusted-frame and full conformance at `fc5e399fcb46d78b610c81e13c644277f3fcf1c5`; the capability report remains entirely `feasibility_blocked`.

## Task Commits

1. **Task 1: Reject mutable lock programs and execute the pinned focused suite as literal argv** — `c3df98f9` (RED regression), `ded1f85b` (GREEN runner)

## Verification

- RED: `bash scripts/ci/test_verify_crosswake_host_commands.sh` failed before the runner change because the shell-bearing fixture target returned 0 rather than the required 80.
- `bash scripts/ci/test_verify_crosswake_host_commands.sh` — pass; approved invocation recorded exactly once, and shell-bearing plus benign substitute targets both reject before a new Swift invocation.
- `CROSSWAKE_SOURCE_ROOT=/Users/jon/projects/crosswake-accrue-bridge bash scripts/ci/verify_crosswake_host_commands.sh trusted-frame` — pass; 14 `HostCommandAdmissionTests` passed.
- `CROSSWAKE_SOURCE_ROOT=/Users/jon/projects/crosswake-accrue-bridge bash scripts/ci/verify_crosswake_host_commands.sh full` — pass; 28 Crosswake tests and tracer consumer passed.
- `jq -e '.overall_status == "feasibility_blocked" and all(.capabilities[]; .status == "feasibility_blocked")' examples/crosswake_tracer/capability-report.json` — pass (`true`).

## Files Created/Modified

- `scripts/ci/verify_crosswake_host_commands.sh` — validates the lock target exactly, then invokes the reviewed focused suite as literal argv.
- `scripts/ci/test_verify_crosswake_host_commands.sh` — fixture-backed regression for accepted argv and fail-closed target rejection.

## Decisions Made

- The lock's `test_target` identifies the reviewed command only through exact equality; it never selects executable syntax.
- Target mismatch uses stable exit status 80 and a privacy-safe diagnostic without echoing untrusted input.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None - this plan removes the mutable-data-to-shell execution boundary and adds no new endpoint, authentication, file-access, or schema surface.

## Next Phase Readiness

The authoritative command-injection evidence gap is closed. Crosswake implementation, source lock, audit, conformance evidence, and capability runtime claims remain unchanged; device and host-runtime feasibility are still deliberately blocked.

## Self-Check: PASSED

- `scripts/ci/verify_crosswake_host_commands.sh` and `scripts/ci/test_verify_crosswake_host_commands.sh` exist.
- Task commits `c3df98f9` and `ded1f85b` exist in git history.
