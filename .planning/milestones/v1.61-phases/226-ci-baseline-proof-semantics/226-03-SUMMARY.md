---
phase: 226-ci-baseline-proof-semantics
plan: "03"
subsystem: ci-provider-evidence
tags: [node, exunit, github-actions, stripe-test-mode, privacy]
requires:
  - phase: 226-01
    provides: privacy-safe CI evidence conventions and deterministic fixture patterns
provides:
  - fail-closed provider-proof classifier with independent policy, state, freshness, and conclusion facts
  - escaped GitHub summary rendering and exhaustive promotion-negative fixtures
  - opt-in aggregate-only ExUnit evidence-manifest formatter
affects: [226-05, 227-critical-path, live-stripe-workflow]
tech_stack:
  added: []
  patterns: [dependency-free-esm-classifier, atomic-json-manifest, aggregate-only-provider-evidence]
key_files:
  created:
    - scripts/ci/provider_proof.mjs
    - scripts/ci/render_provider_summary.mjs
    - scripts/ci/verify_provider_proof.mjs
    - .planning/phases/226-ci-baseline-proof-semantics/fixtures/provider-proof-cases.json
    - accrue/test/support/live_proof_formatter.ex
    - accrue/test/accrue/live_proof_formatter_test.exs
  modified:
    - accrue/test/test_helper.exs
decisions:
  - "Use a 24-hour cadence plus 48-hour grace only to derive stale; it never changes proof_state."
  - "Classify selected provider runs fail-closed: valid nonzero fully-passing manifest evidence is required for proved."
  - "Emit only aggregate result counts and timestamps from ExUnit; no names, messages, environment data, IDs, or payloads cross the manifest boundary."
metrics:
  duration: "~12 minutes"
  completed: "2026-08-11"
  tasks_completed: 2
  files_created: 6
status: complete
coverage:
  - id: BASE-02-state-machine
    description: "Provider proof preserves independent policy, proof state, raw conclusion, SHA history, and freshness semantics."
    human_judgment: false
    ref: "node scripts/ci/verify_provider_proof.mjs --fixtures"
    status: pass
  - id: BASE-02-promotion-negatives
    description: "Fixtures reject zero-selected, skipped, invalid-manifest, failed, blocked, stale-boundary, and summary-injection promotion paths."
    human_judgment: false
    ref: "node scripts/ci/verify_provider_proof.mjs --fixtures"
    status: pass
  - id: BASE-02-live-manifest
    description: "The opt-in ExUnit formatter atomically writes validated aggregate evidence without live credentials."
    human_judgment: false
    ref: "cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors"
    status: pass
---

# Phase 226 Plan 03: CI Baseline Proof Semantics Summary

Fail-closed Stripe test-mode proof semantics: only selected, configured, nonzero, all-passing, privacy-safe execution evidence becomes `proved`.

## Completed Tasks

1. Added a dependency-free provider classifier, escaped step-summary renderer, and exhaustive state fixture gate. A green zero-selected scheduled job is mechanically `misconfigured` and finalize exits nonzero.
2. Added an opt-in ExUnit formatter enabled only by `ACCRUE_PROVIDER_MANIFEST`; it atomically writes only aggregate selected/passed/skipped/failed counts and timestamps.

## Verification

- `node --check scripts/ci/provider_proof.mjs` — PASS
- `node --check scripts/ci/render_provider_summary.mjs` — PASS
- `node --check scripts/ci/verify_provider_proof.mjs` — PASS
- `node scripts/ci/verify_provider_proof.mjs --fixtures` — PASS
- `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors` — PASS
- Formatter integration with `ACCRUE_PROVIDER_MANIFEST`, then `validateProviderManifest` — PASS

## Decisions Made

- Use the documented daily cadence plus a reversible 48-hour grace to calculate `stale` without transferring proof to a different SHA or changing proof state.
- Keep Fake contributor/merge proof separate from Stripe parity proof; only an executed Stripe test-mode suite can provide the latter.
- Treat all provider record and summary input as untrusted: malformed manifests fail closed and control/Markdown content renders inert.

## Unresolved Assumption

BASE-02 has no SPEC edge classification. Its descriptor-less prohibition remains explicit: green, skipped, non-run, zero-selected, stale, Fake-backed, and different-SHA evidence must never promote current-SHA live-provider proof. The fixture matrix covers those promotion-negative controls.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected the freshness fixture boundary to include the daily cadence as well as the 48-hour grace.
- **Found during:** Task 1
- **Issue:** The initial fixture treated 48 hours as the full boundary instead of `24 + 48` hours.
- **Fix:** Assert freshness at exactly 72 hours and staleness one second later.
- **Files modified:** `scripts/ci/verify_provider_proof.mjs`
- **Commit:** `1b03abb8`

2. [Rule 1 - Bug] Made the formatter a valid GenServer-style ExUnit formatter.
- **Found during:** Task 2
- **Issue:** The initial direct-callback test passed, but ExUnit requires `init/1` to return `{:ok, state}` to invoke the formatter in a real test run.
- **Fix:** Added `use GenServer`, corrected the callback contract, and validated the env-driven integration manifest.
- **Files modified:** `accrue/test/support/live_proof_formatter.ex`, `accrue/test/accrue/live_proof_formatter_test.exs`
- **Commit:** `3390b656`

## Known Stubs

None.

## Self-Check: PASSED

- All six created artifacts and the modified test helper exist.
- Task commits `5c3b0965`, `1b03abb8`, `c2a0832f`, and `3390b656` exist.
