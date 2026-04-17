---
phase: 14-adoption-front-door
plan: 02
subsystem: docs
tags: [github, issue-templates, docs-contract, exunit, adoption]
requires:
  - phase: 14-adoption-front-door
    provides: repository front door README and public boundary contract wording
provides:
  - GitHub issue chooser config with blank issues disabled
  - four focused public issue forms for bug, integration, docs, and feature intake
  - docs contract test that enforces no-secrets warnings and public-surface routing
affects: [github-support, SECURITY.md, CONTRIBUTING.md, accrue-docs, phase-14-adoption-front-door]
tech-stack:
  added: []
  patterns: [github-issue-form-taxonomy, no-secrets-support-intake, docs-contract-for-support-surfaces]
key-files:
  created:
    - .github/ISSUE_TEMPLATE/config.yml
    - .github/ISSUE_TEMPLATE/bug.yml
    - .github/ISSUE_TEMPLATE/integration-problem.yml
    - .github/ISSUE_TEMPLATE/documentation-gap.yml
    - .github/ISSUE_TEMPLATE/feature-request.yml
    - accrue/test/accrue/docs/issue_templates_test.exs
  modified: []
key-decisions:
  - "Public issue intake is limited to four focused forms and disables blank issues."
  - "Every form repeats the exact no-secrets warning and points reporters to supported public boundaries."
  - "Security and contributor/process questions route through contact links instead of a generic support issue."
patterns-established:
  - "Support-surface wording that defines stable intake behavior gets an ExUnit contract in accrue/test/accrue/docs."
  - "Issue forms should ask for sanitized host-facing context, not private module names or raw production payloads."
requirements-completed: [ADOPT-04, ADOPT-05]
duration: 2min
completed: 2026-04-17
---

# Phase 14 Plan 02: Adoption Front Door Summary

**Structured GitHub issue intake with no-secrets warnings, private security routing, and public-boundary support taxonomy**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-17T08:06:06Z
- **Completed:** 2026-04-17T08:08:35Z
- **Tasks:** 1
- **Files modified:** 6

## Accomplishments

- Added a GitHub issue chooser config that disables blank issues and routes vulnerability reports to `SECURITY.md` plus process questions to `CONTRIBUTING.md`.
- Added the four approved public issue forms for bugs, integration blockers, documentation gaps, and feature requests.
- Added an ExUnit docs contract that locks the form taxonomy, exact no-secrets language, and supported public-surface guidance in place.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the issue-template contract test and public issue forms** - `b3f38d0` (`docs`)

**Plan metadata:** pending

## Files Created/Modified

- `.github/ISSUE_TEMPLATE/config.yml` - Chooser config with blank issues disabled and private routing links.
- `.github/ISSUE_TEMPLATE/bug.yml` - Bug-report form anchored to supported public surfaces and sanitized reproduction details.
- `.github/ISSUE_TEMPLATE/integration-problem.yml` - Integration-blocker form that points users back to First Hour and Troubleshooting before filing.
- `.github/ISSUE_TEMPLATE/documentation-gap.yml` - Docs-gap form that asks for the missing or stale path and affected public surface.
- `.github/ISSUE_TEMPLATE/feature-request.yml` - Feature-request form centered on user problem, workaround, public API surface, and host-vs-library fit.
- `accrue/test/accrue/docs/issue_templates_test.exs` - Contract test that enforces the approved taxonomy, warning phrases, and support routing links.

## Decisions Made

- The chooser exposes exactly four public forms and no generic support-question template.
- The required warning language is identical across all four forms so the no-secrets policy stays grepable and testable.
- Issue prompts reference host-facing boundaries like `MyApp.Billing`, `/webhooks/stripe`, `/billing`, `Accrue.Webhook.Handler`, and `Accrue.Auth` instead of private implementation details.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first version of `issue_templates_test.exs` used `String.index/2`, which is not available in the local Elixir version. Replaced it with a small binary-match helper and reran the focused suite.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 14-03 can build release and provider-parity guidance on top of the same support taxonomy and public-boundary language.
- The issue chooser now gives maintainers structured public intake without encouraging secrets or raw production data in issues.

## Self-Check: PASSED

- Verified `.planning/phases/14-adoption-front-door/14-02-SUMMARY.md` exists.
- Verified task commit `b3f38d0` exists in git history.
