---
phase: 15-trust-hardening
plan: 01
subsystem: testing
tags: [trust, docs, release, security, exunit, ci]
requires:
  - phase: 14-adoption-front-door
    provides: "No-secrets issue intake, release-lane wording, and grep-based docs verifier patterns"
provides:
  - "Checked-in trust review for webhook, auth, admin, replay, generated-host, artifact, and public-intake boundaries"
  - "Executable docs contracts for trust review presence and leakage-safe release language"
  - "Release and contributor wording that keeps trust evidence required and Stripe-backed parity checks advisory"
affects: [release-guidance, docs-verifier, security-review, contributor-docs]
tech-stack:
  added: []
  patterns: ["Evidence-first trust review artifact", "Grep-based docs invariants for trust and leakage wording"]
key-files:
  created:
    - .planning/phases/15-trust-hardening/15-TRUST-REVIEW.md
    - accrue/test/accrue/docs/trust_review_test.exs
    - accrue/test/accrue/docs/trust_leakage_test.exs
  modified:
    - RELEASING.md
    - CONTRIBUTING.md
    - SECURITY.md
    - guides/testing-live-stripe.md
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
    - accrue/test/accrue/docs/release_guidance_test.exs
key-decisions:
  - "Keep the trust review in the phase directory and lock it with an ExUnit docs contract instead of inventing a separate security process."
  - "Use the existing grep-based package docs verifier to enforce trust-gate wording, secret-name references, and failure-only artifact retention."
  - "Treat missing customer-data and PII warnings in public security/provider docs as trust-leakage regressions worth fixing in-place."
patterns-established:
  - "Trust artifacts should name host-owned, advisory, and environment-specific boundaries explicitly."
  - "Release docs should enumerate deterministic trust gates alongside existing package checks and keep Stripe-backed parity lanes advisory."
requirements-completed: [TRUST-01, TRUST-05, TRUST-06]
duration: 5min
completed: 2026-04-17
---

# Phase 15 Plan 01: Trust Review And Leakage Contracts Summary

**Checked-in trust review plus executable leakage and release-language contracts for trust evidence, secret-safe docs, and failure-only retained artifacts**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-17T09:29:26Z
- **Completed:** 2026-04-17T09:34:01Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md` with explicit webhook, auth, admin, replay, generated-host, retained-artifact, public docs/issues, and public errors/logs boundaries tied to existing repo evidence.
- Added ExUnit docs contracts that fail if the trust review, release wording, no-secrets guidance, secret-name references, or retained-artifact policy drift.
- Extended release and contributor guidance so deterministic trust gates stay required while Stripe test/live coverage remains provider-parity or advisory.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the checked-in trust review and its docs contract** - `d7493d5` (`test`), `a28d846` (`feat`)
2. **Task 2: Add leakage guardrails and extend release-language contracts** - `3c42f68` (`test`), `7de4df6` (`feat`)

## Files Created/Modified

- `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md` - Checked-in trust review with severity, ASVS, accepted-risk, and verification sections.
- `accrue/test/accrue/docs/trust_review_test.exs` - Docs contract for the trust review artifact.
- `accrue/test/accrue/docs/trust_leakage_test.exs` - Leakage contract for no-secrets wording and failure-only retained artifacts.
- `RELEASING.md` - Required deterministic trust-gate language and no-secrets release wording.
- `CONTRIBUTING.md` - Contributor-facing trust-gate guidance.
- `SECURITY.md` - Explicit customer-data and PII warning for public reports and retained artifacts.
- `guides/testing-live-stripe.md` - Provider-parity guidance tightened to forbid sharing secrets, customer data, and PII.
- `scripts/ci/verify_package_docs.sh` - Grep-based invariants for trust review, trust-gate wording, secret names, and failure-only artifact settings.
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` - Verifier regression coverage for trust review and retained-artifact drift.
- `accrue/test/accrue/docs/release_guidance_test.exs` - Release guidance assertions for deterministic trust gates.

## Decisions Made

- Kept the trust review adjacent to other phase evidence in `.planning/phases/15-trust-hardening/` so maintainers can inspect one checked-in artifact and one matching docs test.
- Reused the Phase 14 grep-based verifier style instead of adding a second scanning system, which keeps the release guardrail cheap and deterministic.
- Tightened `SECURITY.md` and `guides/testing-live-stripe.md` when the new leakage contract showed those public docs were missing explicit customer-data and PII wording.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Tooling] Replaced obsolete Mix verification flag during execution**
- **Found during:** Task 1 (trust review docs contract)
- **Issue:** The plan's `mix test ... -x` verification command is not supported by the current Mix version in this repo.
- **Fix:** Used `mix test ... --trace` for RED/GREEN verification and kept the repo changes scoped to the planned artifact/test work.
- **Files modified:** None
- **Verification:** `mix test test/accrue/docs/trust_review_test.exs --trace`
- **Committed in:** not applicable

**2. [Rule 2 - Missing Critical] Added explicit customer-data and PII warnings to public security/provider docs**
- **Found during:** Task 2 (leakage guardrails and release-language contracts)
- **Issue:** `SECURITY.md` and `guides/testing-live-stripe.md` mentioned secret handling, but the new leakage contract exposed missing explicit `customer data` and `PII` guidance on those public surfaces.
- **Fix:** Added direct wording to both docs and kept the leakage test enforcing that language.
- **Files modified:** `SECURITY.md`, `guides/testing-live-stripe.md`
- **Verification:** `cd accrue && mix test test/accrue/docs/trust_leakage_test.exs test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs`
- **Committed in:** `7de4df6`

---

**Total deviations:** 2 auto-fixed (1 tooling, 1 missing critical)
**Impact on plan:** Both fixes were required to finish the planned trust contracts cleanly. No architectural scope change.

## Issues Encountered

- The current Mix version rejects the plan's `-x` shorthand, so task verification used `--trace`.
- The new verifier fixture needed additional copied files (`guides/testing-live-stripe.md` and `examples/accrue_host/playwright.config.js`) once the shell verifier began checking secret-name and retained-artifact invariants.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Trust evidence for Phase 15 now has one checked-in review artifact and executable docs/leakage contracts.
- Later trust-hardening plans can extend performance, compatibility, and browser checks without redefining the release-lane or support-intake contract.

## Self-Check

PASSED

- Found `.planning/phases/15-trust-hardening/15-01-SUMMARY.md`
- Found commit `d7493d5`
- Found commit `a28d846`
- Found commit `3c42f68`
- Found commit `7de4df6`

---
*Phase: 15-trust-hardening*
*Completed: 2026-04-17*
