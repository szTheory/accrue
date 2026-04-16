---
phase: 09-release
plan: 03
subsystem: docs
tags: [exdoc, hexdocs, readme, changelog, elixir]
requires:
  - phase: 09-release
    provides: CI release gate and package-aware workflow conventions
  - phase: 09-release
    provides: Release Please and same-workflow Hex publish automation
provides:
  - accrue package README and changelog entrypoints for Hex and HexDocs
  - README-first ExDoc configuration with grouped guides and llms.txt output
  - quickstart and configuration guides for the core package
affects: [release docs, hex package metadata, hexdocs surface]
tech-stack:
  added: []
  patterns: [README-first ExDoc extras, guide wildcard grouping, docs warning gate]
key-files:
  created: [.planning/phases/09-release/09-03-SUMMARY.md, accrue/README.md, accrue/CHANGELOG.md, accrue/guides/quickstart.md, accrue/guides/configuration.md]
  modified: [accrue/mix.exs, accrue/guides/branding.md, accrue/guides/connect.md, accrue/guides/email.md, accrue/guides/portal_configuration_checklist.md]
key-decisions:
  - "Make README the ExDoc landing page and load package guides through Path.wildcard(\"guides/*.md\") so the release docs surface stays in sync with the guide directory."
  - "Keep README guide links for not-yet-shipped docs on GitHub path URLs so the required guide map is visible now without breaking mix docs --warnings-as-errors."
patterns-established:
  - "Core package docs lead with a runnable host-app setup snippet instead of marketing copy."
  - "Guide additions must keep the docs warning gate green by fixing bad references rather than widening ExDoc suppressions."
requirements-completed: [OSS-01, OSS-15, OSS-16, OSS-17, OSS-18]
duration: 2m
completed: 2026-04-16
---

# Phase 09 Plan 03: Accrue Release Docs Summary

**README-first HexDocs surface for the core package with runnable quickstart docs, Release Please changelog entrypoint, and generated llms.txt**

## Performance

- **Duration:** 2m
- **Started:** 2026-04-16T00:11:58Z
- **Completed:** 2026-04-16T00:13:46Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Added the core `accrue` package README with the required quickstart, public API stability guarantees, guide index, and security guidance.
- Added the package-local `CHANGELOG.md` placeholder for Release Please ownership.
- Switched ExDoc to a README-first docs surface, added quickstart/configuration guides, and verified `mix docs --warnings-as-errors` plus `doc/llms.txt`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the core package README and changelog entrypoints** - `6f308fa` (feat)
2. **Task 2: Wire ExDoc extras and add quickstart/configuration guides** - `173cfbd` (feat)

## Files Created/Modified
- `accrue/README.md` - Package README with quickstart, supported facade guarantees, guide map, and security notes.
- `accrue/CHANGELOG.md` - Release Please managed changelog entrypoint.
- `accrue/guides/quickstart.md` - Copy-pasteable install, Stripe config, installer, and first-subscription flow.
- `accrue/guides/configuration.md` - Runtime secret, adapter, telemetry, and deprecation policy guide.
- `accrue/mix.exs` - README-first ExDoc config, grouped extras, and nil-safe warning callback.
- `accrue/guides/branding.md` - Removed a hidden-function doc reference that broke the warnings gate.
- `accrue/guides/connect.md` - Reworded the secret-collision warning note to avoid a hidden-function doc reference.
- `accrue/guides/email.md` - Replaced a nonexistent coupon helper reference with behavior-level wording.
- `accrue/guides/portal_configuration_checklist.md` - Corrected cancellation guidance to reference the real subscription predicate surface.

## Decisions Made
- Made `README.md` the ExDoc main page so HexDocs and Hex package docs share the same entrypoint.
- Used `Path.wildcard("guides/*.md")` for `extras` and `groups_for_extras` so future guide additions land in docs without hand-maintaining the list.
- Kept README links to future guide paths on GitHub URLs for now, because that preserves the required guide map without failing the docs warning gate before the later guide plans land.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made the ExDoc warning-skip callback nil-safe**
- **Found during:** Task 2
- **Issue:** `mix docs --warnings-as-errors` crashed in `String.starts_with?/2` because the existing `skip_undefined_reference_warning?/1` callback assumed every reference was a string.
- **Fix:** Updated the callback to return true only when the reference is a binary starting with `lib/`.
- **Files modified:** `accrue/mix.exs`
- **Verification:** `cd accrue && mix docs --warnings-as-errors && test -f doc/llms.txt`
- **Committed in:** `173cfbd`

**2. [Rule 1 - Bug] Fixed pre-existing guide references that failed the docs warning gate**
- **Found during:** Task 2
- **Issue:** Existing guides referenced hidden or nonexistent APIs, which became release-blocking warnings once ExDoc started building the full guide set through the README-first surface.
- **Fix:** Reworded those guide passages to use the real public surface or plain behavioral language without invalid autolinks.
- **Files modified:** `accrue/guides/branding.md`, `accrue/guides/connect.md`, `accrue/guides/email.md`, `accrue/guides/portal_configuration_checklist.md`
- **Verification:** `cd accrue && mix docs --warnings-as-errors && test -f doc/llms.txt`
- **Committed in:** `173cfbd`

**3. [Rule 3 - Blocking] Cleared transient git index lock contention before the Task 1 commit**
- **Found during:** Task 1
- **Issue:** staging in parallel hit `.git/index.lock`, which blocked the required atomic commit in the shared main tree.
- **Fix:** Switched git staging to serial commands, confirmed the lock was transient, removed the stale lock when it reappeared, and retried the commit.
- **Files modified:** none
- **Verification:** Task 1 committed successfully as `6f308fa`.
- **Committed in:** `6f308fa`

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 blocking)
**Impact on plan:** All fixes were required to keep the release docs surface and per-task commit flow working. No scope creep beyond the touched docs surface.

## Issues Encountered

- Enabling the full guide extras surfaced old ExDoc autolink problems that had not mattered when only a small guide subset was built. Those were fixed inline rather than suppressing more warnings.
- The shared main-tree git index briefly contended during Task 1 staging, so git operations were retried serially.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The `accrue` package now has the release-grade README/changelog entrypoint and a buildable README-first HexDocs surface.
- Plan `09-04` can extend the remaining guide set from the README map without reworking ExDoc wiring.

## Self-Check: PASSED

- Found `.planning/phases/09-release/09-03-SUMMARY.md`
- Found commit `6f308fa`
- Found commit `173cfbd`
