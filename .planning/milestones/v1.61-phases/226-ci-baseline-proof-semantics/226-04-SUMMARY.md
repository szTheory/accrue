---
phase: 226-ci-baseline-proof-semantics
plan: "04"
subsystem: CI host-browser proof
tags: [ci, diagnostics, playwright, privacy]
requires: [226-01, 226-03]
provides: [owner-first setup diagnostics, safe setup facts]
affects: [host-integration, playwright-e2e]
tech_stack:
  added: []
  patterns: [strict-bash, fixed diagnostic registry, bounded NDJSON facts]
key_files:
  created:
    - scripts/ci/ci_setup_diagnostic.sh
    - scripts/ci/verify_ci_setup_diagnostics.sh
  modified:
    - scripts/ci/accrue_host_verify_browser.sh
    - scripts/ci/accrue_host_uat.sh
    - examples/accrue_host/package.json
decisions:
  - "Setup ownership, repair commands, and evidence locations are fixed registry values rather than caller-provided text."
  - "CI retains linux_browser_dependency ownership; the host script only classifies host proof boundaries."
metrics:
  duration: "~15 minutes"
  completed_date: "2026-08-11"
  tasks_completed: 2
  files_changed: 5
status: complete
---

# Phase 226 Plan 04: CI Setup Diagnostic Contract Summary

Host browser setup failures now resolve through a fixed owner-first registry with redacted optional NDJSON facts, while CI and local runs continue to invoke the same `mix verify.full` proof boundary.

## Tasks Completed

1. **Trace Node preflight failure to a safe host repair** — `1bca99a9`, `c43a1cb5`
   - Added the stable diagnostic registry and a fail-first Node contract fixture.
   - Declared host-owned Node `22.x` without altering package scripts, dependencies, or the lockfile.
   - Added Node preflight before browser/fixture work and optional bounded setup fact emission.

2. **Classify setup boundaries without moving the proof contract** — `bf1e0c3a`, `05f1769a`
   - Added deterministic contract cases for all seven codes, unsafe values, unknown codes, and fixture-controlled browser failures.
   - Classified fixture/database, npm, Playwright binary, server readiness, browser launch, and wrapper failures.
   - Locked single-flow/one-worker/default-zero-retry/failure-only trace and screenshot behavior, accessibility coverage, and duplicate provisioning.

## Verification

Passed:

```text
bash -n scripts/ci/ci_setup_diagnostic.sh
bash -n scripts/ci/verify_ci_setup_diagnostics.sh
bash -n scripts/ci/accrue_host_verify_browser.sh
bash -n scripts/ci/accrue_host_uat.sh
bash scripts/ci/verify_ci_setup_diagnostics.sh
```

The verifier exercises every stable code, exact owner mapping, unknown-code rejection, malicious-value rejection, optional fact output, classified browser fixtures, canonical wrapper delegation, and retained Playwright proof semantics without network or browser dependencies.

## Decisions Made

- Owner, repair command, and evidence location derive exclusively from a fixed registry; callers cannot inject rendered command text.
- Optional `ACCRUE_CI_SETUP_FACTS` records have a strict character allowlist and fixed JSON fields, excluding URLs, secrets, raw paths, payloads, and environment values.
- `linux_browser_dependency` is explicitly CI-owned and remains available for workflow provisioning work; no host test failure reports it as host-owned.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Created diagnostic registry and verifier exist and are executable.
- Task commits `1bca99a9`, `c43a1cb5`, `bf1e0c3a`, and `05f1769a` exist in git history.
