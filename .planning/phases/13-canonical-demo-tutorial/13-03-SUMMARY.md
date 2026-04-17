---
phase: 13-canonical-demo-tutorial
plan: 03
subsystem: testing
tags: [docs, elixir, phoenix, tutorial, adoption]
requires:
  - phase: 13-canonical-demo-tutorial
    provides: canonical demo command manifest, host verify aliases, and docs parity guards
provides:
  - canonical Fake-first host README for the checked-in demo app
  - package-facing First Hour guide that mirrors the host tutorial on public boundaries
  - compact package README orientation that points to the canonical tutorial surfaces
affects: [examples/accrue_host, accrue-docs, phase-14-adoption-front-door]
tech-stack:
  added: []
  patterns: [host-readme-is-canonical, package-guide-mirrors-host-story, root-readme-stays-orienting]
key-files:
  created: []
  modified:
    - examples/accrue_host/README.md
    - accrue/guides/first_hour.md
    - accrue/README.md
key-decisions:
  - "The checked-in host README is the canonical executable path; the package guide mirrors it and the package README stays compact."
  - "The first-run story remains Fake-backed and credential-free while still teaching the real `/webhooks/stripe` and mounted `/billing` surfaces."
  - "Verification guidance now distinguishes `mix verify`, `mix verify.full`, the repo-root wrapper, Hex smoke, and production setup in one consistent order."
patterns-established:
  - "Document Phoenix-order setup first, then point maintainers to the full gate after the user understands the path."
  - "Keep package-facing docs on generated facades, router macros, and callback behaviors instead of private package internals."
requirements-completed: [DEMO-01, DEMO-02, DEMO-03, ADOPT-02]
duration: 2min
completed: 2026-04-17
---

# Phase 13 Plan 03: Canonical Tutorial Summary

**A Fake-first host tutorial, mirrored First Hour guide, and compact package README that now teach one coherent subscription, webhook, admin-inspection, and proof flow**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-17T01:55:53Z
- **Completed:** 2026-04-17T01:57:30Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Rewrote the checked-in host README into the canonical `First run` path with explicit `Seeded history` and verification-mode sections.
- Reworked the package-facing First Hour guide to mirror the same story using only public host-owned setup surfaces.
- Trimmed the package README back to orientation so it links into the canonical tutorial instead of duplicating it.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite the host README as the canonical `First run` path** - `4588fd8` (`docs`)
2. **Task 2: Mirror the canonical story in `accrue/guides/first_hour.md`** - `ebe7698` (`docs`)
3. **Task 3: Keep the package README as orientation, not the full front door** - `b556d71` (`docs`)

## Files Created/Modified

- `examples/accrue_host/README.md` - Canonical Fake-first local evaluation path with explicit first-run, seeded-history, and verification-mode sections.
- `accrue/guides/first_hour.md` - Package-facing tutorial mirror using `MyApp.Billing`, `use Accrue.Webhook.Handler`, `accrue_admin "/billing"`, and focused verification boundaries.
- `accrue/README.md` - Compact package orientation that points readers to `guides/first_hour.md` and the checked-in host demo path.

## Decisions Made

- Kept `examples/accrue_host/README.md` as the executable tutorial source of truth and used the package docs only to mirror or route into it.
- Preserved the real trust boundaries in the tutorial text: signed `/webhooks/stripe`, mounted `/billing`, and host-controlled auth, while avoiding private internals and live-secret guidance.
- Split verification explanations cleanly so `mix verify`, `mix verify.full`, the repo-root wrapper, Hex smoke, and production setup are no longer blended together.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 14 can build on a stable, manifest-backed adoption path without needing to untangle docs ownership first.
- The host README, First Hour guide, and package README now present one consistent set of labels and verification commands for future docs work.

## Self-Check: PASSED

- Verified `.planning/phases/13-canonical-demo-tutorial/13-03-SUMMARY.md` exists.
- Verified task commits `4588fd8`, `ebe7698`, and `b556d71` exist in git history.
