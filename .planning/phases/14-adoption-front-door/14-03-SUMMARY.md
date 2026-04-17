---
phase: 14-adoption-front-door
plan: 03
subsystem: docs
tags: [release-guidance, stripe, docs-contract, shell-verifier, adoption]
requires:
  - phase: 14-adoption-front-door
    provides: root README route map, support intake wording, and public-boundary adoption copy
provides:
  - release guidance that separates required Fake checks from Stripe provider-parity and live advisory lanes
  - docs contract coverage for release/support wording
  - shell verifier coverage for root README and release-guidance fixed invariants
affects: [RELEASING.md, CONTRIBUTING.md, guides/testing-live-stripe.md, scripts/ci/verify_package_docs.sh, phase-14-adoption-front-door]
tech-stack:
  added: []
  patterns: [release-verification-lanes, docs-contract-for-support-copy, fixed-string-shell-drift-guard]
key-files:
  created:
    - accrue/test/accrue/docs/release_guidance_test.exs
  modified:
    - RELEASING.md
    - CONTRIBUTING.md
    - guides/testing-live-stripe.md
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
key-decisions:
  - "Release docs treat Fake as the required deterministic lane, Stripe test mode as provider parity, and live Stripe as advisory/manual before shipping a host app."
  - "ExUnit owns the release/support semantics while the shell verifier only locks fixed strings in README and RELEASING."
  - "The summary uses the standard filename 14-03-SUMMARY.md because the plan output block contained a nonstandard path."
patterns-established:
  - "Support and release wording that changes perceived release blockers gets an ExUnit contract plus a narrow shell invariant."
  - "Provider-backed Stripe checks stay documented as separate parity and advisory lanes rather than being folded into the default release path."
requirements-completed: [ADOPT-01, ADOPT-03, ADOPT-05, ADOPT-06]
duration: 6min
completed: 2026-04-17
---

# Phase 14 Plan 03: Adoption Front Door Summary

**Release guidance that locks Fake as the required deterministic lane while Stripe test mode and live Stripe stay separate provider-parity and advisory checks**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-17T08:06:00Z
- **Completed:** 2026-04-17T08:12:05Z
- **Tasks:** 1
- **Files modified:** 6

## Accomplishments

- Updated `RELEASING.md` to separate `Canonical local demo: Fake`, `Provider parity: Stripe test mode`, and `Advisory/manual: live Stripe` with required-versus-advisory wording.
- Added `release_guidance_test.exs` so release and support copy now has an executable contract for the lane labels and safety wording.
- Extended `verify_package_docs.sh` and its ExUnit coverage so README and release-guidance fixed invariants fail loudly if they drift.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add release-guidance contracts and update release/support docs with drift guards** - `30d0344` (`docs`)

**Plan metadata:** pending

## Files Created/Modified

- `RELEASING.md` - Separates the required Fake release lane from Stripe provider-parity and live advisory checks, with explicit webhook and secret guidance.
- `CONTRIBUTING.md` - Points contributors to the Stripe test-mode provider-parity guide and repeats the shell-history/log hygiene warning.
- `guides/testing-live-stripe.md` - Reframes the suite as Stripe test-mode provider parity, not the canonical demo or required release lane.
- `scripts/ci/verify_package_docs.sh` - Locks root README and release-guidance labels as fixed-string invariants.
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` - Extends the verifier contract to cover green output plus release-guidance temp-tree drift.
- `accrue/test/accrue/docs/release_guidance_test.exs` - Adds the release/support wording contract for required, provider-parity, and advisory lanes.

## Decisions Made

- The required release blocker stays the Fake-backed deterministic lane; Stripe-backed checks exist for fidelity and shipping confidence, not for ordinary package release gating.
- The shell verifier remains narrow and grep-based, while ExUnit continues to own prose semantics and negative assertions.
- The standard summary filename `14-03-SUMMARY.md` overrides the plan output typo so phase artifacts stay consistent with the repo convention and user instruction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalized the contributor warning to the exact invariant phrase**
- **Found during:** Task 1 (Add release-guidance contracts and update release/support docs with drift guards)
- **Issue:** The first draft used `Keep real credentials...`, which failed the case-sensitive contract expecting `keep real credentials out of shell history and logs`.
- **Fix:** Updated `CONTRIBUTING.md` to include the exact invariant phrase while preserving the same guidance.
- **Files modified:** `CONTRIBUTING.md`
- **Verification:** `cd accrue && mix test test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs && bash ../scripts/ci/verify_package_docs.sh`
- **Committed in:** `30d0344` (part of Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix was a narrow wording correction needed to satisfy the new docs contract. No scope expansion.

## Issues Encountered

- The plan output block named a nonstandard summary path. Used the standard phase filename `14-03-SUMMARY.md` to match the repo convention and the execution objective.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 14 now has release/support wording that clearly distinguishes canonical Fake validation from Stripe-backed parity and advisory checks.
- Phase 15 can build trust-hardening evidence on top of explicit required-versus-advisory release language instead of redefining the release lanes.

## Self-Check: PASSED

- Verified `.planning/phases/14-adoption-front-door/14-03-SUMMARY.md` exists.
- Verified task commit `30d0344` exists in git history.
