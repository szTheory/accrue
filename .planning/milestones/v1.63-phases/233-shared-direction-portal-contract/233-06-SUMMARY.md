---
phase: 233-shared-direction-portal-contract
plan: 06
subsystem: ui
tags: [css, playwright, accessibility, phoenix]
requires:
  - phase: 233-04
    provides: Current served baseline and the shared semantic direction for Admin and Portal.
provides:
  - Readable Portal status and host-accent consumers using the existing package-owned token APIs.
  - Served browser checks for token ownership, asset provenance, focus, contrast, and 320px reflow.
affects: [233-02, 233-03, 233-05, 233-07, 234, 235, 236, 237, 238, 239]
actuals:
  tokens: 108140
  tasks: 2
  commits: 3
plan_head_before: bfd3940c6e970cb72058693ce21e2313b948877e
plan_head_after: 03cd5d0b5b1939894e38e7129b286720a948ae29
commits: 3
tech-stack:
  added: []
  patterns: [served-css-source-hash-check, computed-theme-contrast-check, 320px-document-overflow-check]
key-files:
  created:
    - examples/accrue_host/e2e/phase233-semantic.spec.js
    - .planning/phases/233-shared-direction-portal-contract/captures/semantic-admin-320.png
    - .planning/phases/233-shared-direction-portal-contract/captures/semantic-portal-320-dark.png
  modified:
    - accrue/priv/static/brand.css
    - accrue_portal/priv/static/accrue_portal.css
key-decisions:
  - "Use shared semantic roles through the existing Admin --ax-* and core/Portal --accrue-* token ownership, without combining shells or assets."
  - "Tint host accent text toward the active theme ink and use a deep accent control fill so arbitrary bright accents retain readable text and focus."
requirements-completed: [SYS-01, SYS-02]
coverage:
  - id: D1
    description: "Portal status and host-accent consumers use readable text, shape cues, and focus while preserving the package-owned Admin and Portal token APIs."
    requirement: SYS-01
    verification:
      - kind: other
        ref: "cd accrue_admin && npm_config_cache=/tmp/accrue-233-npm-cache mix accrue_admin.assets.build"
        status: pass
      - kind: automated_ui
        ref: "examples/accrue_host/e2e/phase233-semantic.spec.js#current served Admin and Portal controls retain semantic contrast, focus, and 320px reflow"
        status: pass
    human_judgment: false
  - id: D2
    description: "Current served Admin and Portal CSS match their source bytes and URL hashes; representative status, focus, host-accent contrast, and 320px reflow checks pass."
    requirement: SYS-02
    verification:
      - kind: automated_ui
        ref: "examples/accrue_host/e2e/phase233-semantic.spec.js#current served Admin and Portal controls retain semantic contrast, focus, and 320px reflow"
        status: pass
    human_judgment: false
duration: 19min
completed: 2026-10-07
status: complete
---

# Phase 233 Plan 06: Shared Semantic Consumers Summary

**Portal status and arbitrary host-accent controls now retain readable cues across themes, with current served Admin and Portal output verified at 320 CSS pixels.**

## Performance

- **Duration:** 19 minutes
- **Started:** 2026-10-07T19:42:35Z
- **Completed:** 2026-10-07T20:01:16Z
- **Tasks:** 2 / 2
- **Files changed:** 5 (three source files and two inspected browser captures)

## Accomplishments

- Kept Admin's existing status, focus, surface, typography, and spacing consumers on its private `--ax-*` roles; the asset build succeeded without changing Admin CSS or generated assets.
- Updated the core brand bridge and Portal consumers so status names remain readable with distinct glyphs, focus follows a theme-aware accent text color, and primary action text stays legible for an all-white host accent.
- Added a canonical-host browser test that checks current served CSS bytes and URL digests, existing token names, representative Admin and Portal status/focus consumers, computed contrast, and no page-level horizontal overflow at 320px. Inspected the saved Admin and dark Portal captures.

## Task Commits

1. **Task 1: Align bounded Admin and Portal token consumers** — `879e23a4` (`fix`).
2. **Task 2: Verify rebuilt Admin and embedded Portal CSS as served** — `aac8ad16` (`test`).
3. **Task 2 follow-up: Protect package token ownership** — `03cd5d0b` (`test`).

## Files Created/Modified

- `accrue/priv/static/brand.css` — theme-aware accent text and deep primary control fill for the public brand bridge.
- `accrue_portal/priv/static/accrue_portal.css` — status text/glyph cues, accent-based focus, and primary action styling.
- `examples/accrue_host/e2e/phase233-semantic.spec.js` — served asset, token ownership, contrast, focus, status, and narrow viewport assertions.
- `captures/semantic-admin-320.png`, `captures/semantic-portal-320-dark.png` — inspected current served narrow viewport renders.

## Decisions Made

- Keep semantic meaning shared while preserving Admin's private tokens, public/core Portal tokens, separate assets, host branding, and audience-specific shell density.
- Use an ink-tinted host accent for text/focus and a deep accent fill for primary controls; a test with an all-white accent exposed and verified the need for this treatment.
- Leave Admin source CSS unchanged because its existing token-based status and focus consumers already met this slice's contract.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The default npm cache rejected writes with `EPERM`; the declared Admin asset build passed with the approved temporary cache at `/tmp/accrue-233-npm-cache`.
- Chromium could not launch in the default sandbox. The authorized escalated run passed the browser suite. The host emitted existing Oban notifier `too_many_connections` warnings while starting; the fixture and browser assertions completed successfully.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

This bounded semantic slice is ready for the remaining Phase 233 contract plans. Route-specific hierarchy and actions remain with their planned route owners.

---
*Phase: 233-shared-direction-portal-contract*
*Completed: 2026-10-07*

## Self-Check: PASSED

- The browser spec and both capture files exist.
- All three task commits are ancestors of the current branch tip.
- The plan evaluation scope resolves and includes the three task commits.
