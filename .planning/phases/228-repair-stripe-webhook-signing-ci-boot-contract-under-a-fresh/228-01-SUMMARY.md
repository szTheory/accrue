---
phase: 228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh
plan: "01"
subsystem: ci
tags: [stripe, github-actions, runtime-config, provider-proof, evidence]

requires:
  - phase: 227-measured-critical-path-improvement
    provides: terminal evidence that live Stripe boot failed on missing webhook signing configuration
provides:
  - deterministic CI-to-runtime Stripe webhook signing-secret mapping
  - fail-closed workflow and runtime negative controls
  - authoritative Phase 228 live-binding and terminal-evidence verifier
  - pre-authorization exact-once evidence schema and validated Nyquist map
affects: [228-02, 228-03, live-stripe, provider-proof]

actuals:
  tokens: 12383
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns: [trimmed runtime secret mapping, name-level CI contract fixtures, marked exact-once Markdown record, bounded GitHub Actions reconciliation]

key-files:
  created:
    - scripts/ci/verify_stripe_webhook_boot_evidence.mjs
    - accrue/test/accrue/runtime_config_test.exs
    - .planning/phases/228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md
  modified:
    - accrue/config/runtime.exs
    - .github/workflows/ci.yml
    - scripts/ci/verify_provider_proof.mjs
    - .planning/phases/228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-VALIDATION.md

key-decisions:
  - "Map a trimmed signing secret as the Stripe rotation list, but map missing input to an empty list so boot validation fails closed."
  - "Reject skipped/intentional_bypass evidence outright because the Phase 228 workflow has no reachable bypass path."
  - "Keep the evidence record unconsumed and not authorized until Plan 228-02 supplies explicit external authority."

patterns-established:
  - "Static-to-live proof: the same verifier first asserts workflow shape, then reconciles bounded run/job/artifact facts through read-only GitHub APIs."
  - "Exact-once evidence: a marked Markdown block admits only the declared field set and rejects missing, duplicate, conflicting, privacy-forbidden, or structurally impossible tuples."

requirements-completed: []

coverage:
  - id: D1
    description: "The live Stripe lane maps and preflights a nonempty webhook signing secret, while test runtime boot validates without making a processor request and empty input fails closed."
    verification:
      - kind: integration
        ref: "accrue/test/accrue/runtime_config_test.exs; mix test test/accrue/runtime_config_test.exs test/accrue/config_test.exs"
        status: pass
      - kind: other
        ref: "node scripts/ci/verify_provider_proof.mjs --fixtures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Phase 228 has exhaustive offline terminal-evidence fixtures and an unconsumed exact-once record schema before any external dispatch authority."
    verification:
      - kind: other
        ref: "node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --fixtures"
        status: pass
      - kind: other
        ref: "rg readiness_not_authorized/first-attempt/consumed/selected_count/live-stripe-proof/Phase 227 in 228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md"
        status: pass
    human_judgment: false

duration: 37min
completed: 2026-08-28
status: complete
---

# Phase 228 Plan 01: Stripe Webhook-Signing CI Boot Contract Summary

**Trimmed Stripe webhook signing configuration now crosses the live CI job into fail-closed runtime boot, backed by exhaustive offline evidence mutations and a one-attempt pre-authorization record.**

## Performance

- **Duration:** 37 min
- **Started:** 2026-08-28T18:46:42Z
- **Completed:** 2026-08-28T19:23:52Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Bound `STRIPE_WEBHOOK_SECRET` at the live-stripe job boundary, added its generic nonempty preflight term, and mapped the trimmed value into Accrue's Stripe signing-secret rotation list.
- Proved positive, ordinary Fake-backed, and empty-input runtime behavior without processor calls; added negative fixtures for missing/renamed CI edges while preserving read-only and always-run evidence controls.
- Added a dependency-free verifier for exhaustive created-run/no-run terminal tuples, static bypass impossibility, bounded read-only GitHub reconciliation, artifact comparison, and temporary-download cleanup.
- Froze the unconsumed Phase 228 evidence record before external authority and marked the deterministic Wave 1 validation map green with 1.1s measured feedback.

## Task Commits

Each task was committed atomically; Task 1 followed the required TDD split:

1. **Task 1 RED: Prove the no-network signing-secret path** - `56b49206` (test)
2. **Task 1 GREEN: Repair runtime, CI, and evidence verification** - `a76b7653` (fix)
3. **Task 2: Freeze the evidence schema and Nyquist map** - `bb6fca4a` (docs)

## Files Created/Modified

- `accrue/config/runtime.exs` - Trims the signing secret and configures fail-closed Stripe webhook signing at test-runtime boot.
- `.github/workflows/ci.yml` - Binds and preflights the same-named repository configuration in the live-stripe job.
- `scripts/ci/verify_provider_proof.mjs` - Rejects missing/renamed signing-secret edges and preserves the no-bypass finalizer contract.
- `scripts/ci/verify_stripe_webhook_boot_evidence.mjs` - Validates exact terminal tuples and reconciles future bounded GitHub run/job/artifact evidence.
- `accrue/test/accrue/runtime_config_test.exs` - Evaluates runtime config with process-global restoration and proves boot performs no Stripe processor call.
- `.planning/phases/228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md` - Defines the unconsumed exact-once evidence tuple and one-attempt ceiling.
- `.planning/phases/228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-VALIDATION.md` - Records concrete task IDs, green commands, and measured Wave 1 latency.

## Decisions Made

- Empty signing input becomes an empty Stripe rotation list, rather than a list containing an empty string, so existing boot validation rejects it deterministically.
- The live verifier accepts only proved, the workflow-reachable misconfigured/failed/blocked terminals, or a complete no-run rejection; skipped/intentional_bypass is always a contract violation.
- The readiness record does not authorize a dispatch. Plan 228-02 remains the explicit configuration and authority gate.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The sandbox initially denied Mix's local PubSub socket. The focused tests were rerun with the required local socket permission and passed 42 tests with zero failures.

## User Setup Required

None during Plan 228-01. Plan 228-02 owns the external repository-configuration confirmation and explicit dispatch decision; this plan did not inspect, print, or authorize protected values.

## TDD Gate Compliance

- RED commit `56b49206` failed on the missing CI binding and absent evidence-verifier implementation.
- GREEN commit `a76b7653` passed both Node fixture suites and the 42-test focused Mix run.

## Next Phase Readiness

- Plan 228-02 can use the committed deterministic checks and unconsumed record to confirm the external configuration without disclosure.
- No run has been dispatched, no retry exists, and Phase 227's bytes and exhausted authority remain unchanged.

## Self-Check: PASSED

- All three created deliverables and this summary exist on disk.
- Task commits `56b49206`, `a76b7653`, and `bb6fca4a` exist in repository history.

---
*Phase: 228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh*
*Completed: 2026-08-28*
