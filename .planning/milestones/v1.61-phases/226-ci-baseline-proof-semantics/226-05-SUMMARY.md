---
phase: 226-ci-baseline-proof-semantics
plan: "05"
subsystem: ci
tags: [github-actions, stripe, provider-proof, setup-diagnostics, documentation]
requires:
  - phase: 226-02
    provides: frozen comparable CI baseline and rendered evidence
  - phase: 226-03
    provides: provider-proof classifier, manifest, and renderer
  - phase: 226-04
    provides: host/CI setup diagnostic registry and verifier
provides:
  - Always-run redacted provider and setup evidence from existing CI jobs
  - Maintainer triage guidance aligned to literal proof and ownership states
affects: [phase-227-optimization, ci-maintenance, provider-parity]
tech-stack:
  added: []
  patterns: [always-run evidence finalization, read-only workflow static contract, owner-first setup triage]
key-files:
  created: [.planning/phases/226-ci-baseline-proof-semantics/226-05-SUMMARY.md]
  modified: [.github/workflows/ci.yml, scripts/ci/provider_proof.mjs, scripts/ci/verify_provider_proof.mjs, scripts/ci/verify_ci_setup_diagnostics.sh, scripts/ci/README.md, guides/testing-live-stripe.md, examples/accrue_host/README.md, .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md]
key-decisions:
  - "Provider proof finalizes independently from raw job conclusion and fails closed on missing configuration or manifests."
  - "Host setup facts remain additive inside host-integration; duplicate provisioning and CI topology are preserved for Phase 227."
requirements-completed: [BASE-01, BASE-02, OWN-01]
coverage:
  - id: D1
    description: Existing live-stripe and host-integration jobs emit privacy-safe always-run provider and setup evidence.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: node scripts/ci/verify_provider_proof.mjs --fixtures && bash scripts/ci/verify_ci_setup_diagnostics.sh
        status: pass
    human_judgment: false
  - id: D2
    description: Durable CI baseline, provider proof semantics, and setup ownership remain reconciled in maintainer entrypoints.
    requirement: OWN-01
    verification:
      - kind: integration
        ref: node scripts/ci/verify_ci_baseline.mjs --fixtures && bash scripts/ci/verify_phase225_required_lane_evidence.sh
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-08-11
status: complete
---

# Phase 226 Plan 05: CI Baseline Proof Semantics Summary

**Existing CI jobs now finalize redacted Stripe proof and host-setup evidence on every outcome, with literal maintainer triage that preserves the required Fake and release-proof boundaries.**

## Performance

- **Duration:** 14 min
- **Completed:** 2026-08-11
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Added read-only static contracts plus always-run provider preflight, finalization, Markdown summary, and `live-stripe-proof` artifact plumbing without changing job topology.
- Added always-run host/CI setup summaries and the `accrue-host-ci-setup-facts` artifact while retaining existing provisioning, worker, retry, cache, and proof semantics.
- Reconciled baseline, provider-state, cadence/freshness, and seven-code setup ownership guidance; closed Phase 226's automated validation ledger.

## Task Commits

1. **Task 1: Wire always-run provider and setup summaries into stable CI jobs** — `d3632ff5` (test), `1426a6b3` (feat)
2. **Task 2: Reconcile maintainer docs and close the full Phase 226 executable contract** — `b08a3cf4` (docs)

## Files Created/Modified

- `.github/workflows/ci.yml` — additive always-run evidence steps inside the stable live Stripe and host jobs.
- `scripts/ci/provider_proof.mjs` and verifiers — fail-closed missing-manifest handling and workflow privacy/read-only contract fixtures.
- `scripts/ci/README.md`, `guides/testing-live-stripe.md`, `examples/accrue_host/README.md` — canonical triage vocabulary, state contract, and ownership matrix.
- `226-VALIDATION.md` — records all ten tasks as green after the full contract passed.

## Decisions Made

- Provider proof requires manifest-backed selected execution; a raw successful job is never sufficient.
- Workflow evidence remains strictly read-only and uses runner-temp records plus fixed artifact names.
- Phase 227 retains ownership of any provisioning/cache optimization decision.

## Verification

Passed the complete Phase 226 contract:

```bash
node scripts/ci/verify_ci_baseline.mjs --fixtures && \
node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md && \
node scripts/ci/verify_provider_proof.mjs --fixtures && \
bash scripts/ci/verify_ci_setup_diagnostics.sh && \
bash scripts/ci/verify_phase225_required_lane_evidence.sh
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Finalization now writes a misconfigured record when the suite never created its manifest.**
- **Found during:** Task 1
- **Issue:** A missing manifest caused argument parsing to fail before the redacted record could be written.
- **Fix:** Treat unreadable manifests as invalid classifier input so finalization writes a `misconfigured` record and exits nonzero.
- **Files modified:** `scripts/ci/provider_proof.mjs`, `scripts/ci/verify_provider_proof.mjs`
- **Verification:** Provider fixture suite covers the missing-manifest finalization path.
- **Committed in:** `1426a6b3`

**Total deviations:** 1 auto-fixed (Rule 1).

## Known Stubs

None.

## Next Phase Readiness

Phase 227 can use the frozen baseline and retained setup/provider records to evaluate optimization proposals without weakening current proof identity.

## Self-Check: PASSED

- Confirmed all task commits exist and all eight modified deliverables are present.
