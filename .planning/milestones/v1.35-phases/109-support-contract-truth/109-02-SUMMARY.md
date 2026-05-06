---
phase: 109-support-contract-truth
plan: 02
subsystem: docs
tags: [braintree, accrue_portal, onboarding, telemetry, production-readiness]
requires:
  - phase: 109-support-contract-truth
    provides: provider-honest checkout and billing-portal wording mirrored across support and planning surfaces
  - phase: 101-accrue-portal-foundation-checkout
    provides: shipped mounted Braintree checkout and self-serve portal runtime contract
provides:
  - First Hour, the Braintree deep guide, and the portal package README now describe one mounted Braintree onboarding contract
  - production-readiness and telemetry docs now expose mounted-path setup and failure semantics without duplicating the deep guide
  - completed SUP-02 bookkeeping for v1.35
affects: [phase-109-plan-03, package-docs, operator-guides, supportability]
tech-stack:
  added: []
  patterns: [Stripe-first onboarding spine with early Braintree branch, concise operator checklists that defer deep remediation to one mounted-path SSOT]
key-files:
  created: [.planning/milestones/v1.35-phases/109-support-contract-truth/109-02-SUMMARY.md]
  modified: [accrue/guides/first_hour.md, accrue/guides/braintree-local-portal.md, accrue/guides/production-readiness.md, accrue/guides/telemetry.md, accrue_portal/README.md, .planning/REQUIREMENTS.md, .planning/STATE.md]
key-decisions:
  - "First Hour stays Stripe-first but now branches early into the mounted Braintree contract instead of treating portal setup as hidden follow-on work."
  - "The packaged accrue_portal path is the default Braintree story; hand-rolled flows remain an explicit escape hatch."
patterns-established:
  - "Mounted Braintree setup terms (portal_mount_path, portal_base_url, Hosted Fields, auth/session continuity) must appear in the onboarding spine and then hand off to one deep guide."
  - "Operator-facing docs stay checklist and signal oriented, while deep remediation remains centralized in braintree-local-portal.md."
requirements-completed: [SUP-02]
duration: 6 min
completed: 2026-05-06
---

# Phase 109 Plan 02: Support Contract Truth Summary

**Mounted Braintree onboarding, package docs, and operator guidance now share one setup contract for local checkout and billing portal behavior**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-06T20:02:00Z
- **Completed:** 2026-05-06T20:07:43Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Branched First Hour into an early Braintree path that introduces `accrue_portal`, sibling mount, `portal_mount_path`, `portal_base_url`, auth/session continuity, and Hosted Fields / CSP expectations.
- Reframed the Braintree deep guide and `accrue_portal` README around the packaged mounted path as the default story and the hand-rolled path as the explicit escape hatch.
- Added mounted-path readiness and provider-honest checkout/billing-portal interpretation to the production-readiness and telemetry guides.

## Verification

- Task 1 verifier passed: `rg -n "portal_base_url|portal_mount_path|Hosted Fields|accrue_portal|hand-rolled|mounted local" accrue/guides/first_hour.md accrue/guides/braintree-local-portal.md accrue_portal/README.md`
- Task 2 verifier passed: `rg -n "portal_base_url|portal_mount_path|Braintree|CSP|discount preview|checkout completion|billing_portal|checkout_session" accrue/guides/production-readiness.md accrue/guides/telemetry.md`
- Plan verifier passed: `bash scripts/ci/verify_package_docs.sh` -> `package docs verified for accrue 1.0.0 and accrue_admin 1.0.0`

## Task Commits

Each task was committed atomically:

1. **Task 1: Branch First Hour and the portal docs into one mounted Braintree contract** - `e50ea5d` (docs)
2. **Task 2: Surface mounted-path readiness and failure semantics in operator-facing guides** - `0af5e94` (docs)

## Files Created/Modified

- `accrue/guides/first_hour.md` - added the provider-honest checkout/portal table and an early Braintree setup branch
- `accrue/guides/braintree-local-portal.md` - made the packaged `accrue_portal` path the SSOT and clarified the hand-rolled escape hatch
- `accrue_portal/README.md` - documented mounted local URL semantics plus the minimum auth/session and Hosted Fields contract
- `accrue/guides/production-readiness.md` - added concise Braintree mounted-path readiness and failure-semantic checklist items
- `accrue/guides/telemetry.md` - clarified how checkout and billing portal spans should be interpreted across Stripe-hosted and Braintree-local flows
- `.planning/REQUIREMENTS.md` - marked `SUP-02` complete
- `.planning/STATE.md` - advanced active plan tracking to `109-03-PLAN.md`

## Decisions Made

- Kept the onboarding spine short by introducing the mounted Braintree branch early, then handing detailed setup and failure semantics to `braintree-local-portal.md`.
- Kept operator docs terse and signal-shaped so they point at mounted-path risk and interpretation without cloning the full setup narrative.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `git commit` initially failed because `.git/index.lock` appeared stale; the lock had already cleared by the time it was inspected, so the commit was retried successfully without repo cleanup.
- `gsd-sdk query` was not available in this environment, so the required planning-state and requirement updates were applied directly to tracked files.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `SUP-02` is complete and the active state now points at `109-03-PLAN.md`.
- The final Phase 109 slice can now align example-host mirrors and verifier needles against a stable onboarding/operator contract.

## Self-Check: PASSED

- Found `.planning/milestones/v1.35-phases/109-support-contract-truth/109-02-SUMMARY.md` on disk.
- Verified task commits `e50ea5d` and `0af5e94` exist in git history.
