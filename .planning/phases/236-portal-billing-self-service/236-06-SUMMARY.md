---
phase: 236-portal-billing-self-service
plan: 06
subsystem: payments
tags: [braintree, hosted-fields, playwright, theming, nyquist]
requires:
  - phase: 236-02
    provides: Direct authorized add-card route and nonce-only submission boundary
  - phase: 236-05
    provides: Served Portal browser contract and Braintree CI lane
provides:
  - Theme-derived Hosted Fields colors with readable semantic fallback values
  - Hosted Fields refresh on Portal theme changes and LiveView updates, with lifecycle guards and teardown
  - Recurring default and host-forced theme browser verification for direct add-card
affects: [portal-billing, hosted-fields, phase-236-validation]
actuals:
  tokens: 8885
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns: [computed semantic color handoff to Hosted Fields, host theme policy selected by test environment]
key-files:
  created: [.planning/phases/236-portal-billing-self-service/236-06-SUMMARY.md]
  modified: [accrue_portal/priv/static/accrue_portal.js, examples/accrue_host/e2e/phase236-portal-self-service.spec.js, examples/accrue_host/config/test.exs, .github/workflows/ci.yml, .planning/ROADMAP.md, .planning/phases/236-portal-billing-self-service/236-VALIDATION.md]
key-decisions:
  - "The deterministic Hosted Fields mock verifies application-supplied styles, served surfaces, and lifecycle only; it does not establish live Braintree iframe rendering fidelity."
  - "Theme changes recreate Hosted Fields because the SDK creation API accepts styles and offers no general setStyle operation."
  - "Use Braintree's documented `.number`/`.expirationDate`/`.cvv` field selectors and `.invalid` state selector for style overrides."
patterns-established:
  - "Use actual computed field backgrounds and semantic Portal color roles when passing styles to secure provider fields."
  - "Register only the browser assertions applicable to the selected host theme policy so CI reports executed checks without mode-specific skips."
requirements-completed: [POR-05]
coverage:
  - id: D1
    description: Direct add-card secure fields and associated text remain readable across Portal themes and through the context-pin patch lifecycle.
    requirement: POR-05
    verification:
      - kind: e2e
        ref: "ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields' — 3 passed"
        status: pass
      - kind: e2e
        ref: "ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 ACCRUE_HOST_PORTAL_THEME=light npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields' — 2 passed"
        status: pass
      - kind: e2e
        ref: "ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 ACCRUE_HOST_PORTAL_THEME=dark npm --prefix examples/accrue_host run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js --grep 'Hosted Fields' — 2 passed"
        status: pass
    human_judgment: false
duration: 42min
completed: 2026-10-08
status: complete
plan_head_before: 2f13c9f2c141b5b3064112c40115286ff9caf992
plan_head_after: cdad46b3722ba486f890ca84704d41b834f5fcee
commits: 6
---

# Phase 236 Plan 06: Portal Billing Self-Service Summary

**Theme-derived Braintree Hosted Fields styles stay readable through direct navigation, host theme locks, and LiveView context-pin updates.**

## Performance

- **Duration:** 42 minutes
- **Started:** 2026-10-08T18:34:26Z
- **Completed:** 2026-10-08T19:15:58Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Replaced fixed light Hosted Fields colors with normalized computed Portal semantic text and readable invalid colors selected against actual secure-field backgrounds.
- Added direct-route contrast assertions for all three secure fields, placeholders, invalid styles, labels, and help text; covered context-pin patch, theme refresh, nonce clearing, and teardown.
- Added host-forced light/dark configuration and recurring CI runs. Updated both planning indexes with observed passing browser evidence and validated Nyquist status.

## Task Commits

1. **Task 1: Make direct add-card fields readable in light and dark themes** — `56f28efc` (fix)
2. **Task 2: Preserve contrast through theme changes, host locks, patches, and exit** — `5fe38525` (test), with test-registration follow-up `67dacd8e` and SDK selector alignment `cdad46b3` (test/fix)
3. **Task 3: Reconcile the Phase 236 plan and Nyquist indexes** — `cf739ab8` (docs)

**Plan metadata:** `9c735261` (GSD state, roadmap, requirement, and summary metadata commit; final metadata update follows).

## Files Created/Modified

- `accrue_portal/priv/static/accrue_portal.js` — Computes and validates semantic text, placeholder, and invalid styles; refreshes the SDK instance when effective colors change and ignores stale async creation callbacks.
- `examples/accrue_host/e2e/phase236-portal-self-service.spec.js` — Captures SDK style handoff, tests contrast and lifecycle, and checks host-locked themes on the served direct route.
- `examples/accrue_host/config/test.exs` — Allows only system, light, or dark host theme policies from the dedicated test environment variable.
- `.github/workflows/ci.yml` — Runs the focused Hosted Fields browser contract with host-forced light and dark themes in the existing blocking lane.
- `.planning/ROADMAP.md` and `236-VALIDATION.md` — Index Wave 5 and record three observed positive results.

## Decisions Made

- The deterministic mock proves styles supplied by the application, served browser surfaces, and lifecycle behavior. It does not prove real Braintree iframe rendering.
- Theme changes recreate Hosted Fields through the supported teardown/create lifecycle and clear the old nonce before the new instance is used.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reconciled the roadmap Progress row after the SDK updater could not locate its writable section**
- **Found during:** Post-task state updates
- **Issue:** `roadmap.update-plan-progress 236` reported `missing_phase_details` and left the Progress table unchanged because its write scope did not include the active-milestone table preceding the archived `<details>` blocks.
- **Fix:** Updated the existing Phase 236 row to `6/6 | In Progress`; the phase remains in progress until phase verification.
- **Files modified:** `.planning/ROADMAP.md`
- **Verification:** Confirmed the row and plan count match six plan files and six summaries; the Wave 5 index gate passes.
- **Committed in:** Final metadata commit.

**Total deviations:** 1 auto-fixed (Rule 3 — blocking index updater)
**Impact on plan:** The SDK updater could not write the intended progress row; the same roadmap row was reconciled directly. No product scope changed.

## Issues Encountered

- The first sandboxed Playwright invocation could not start Chromium (`bootstrap_check_in ... Permission denied`). The same checks ran successfully with browser process access. A first executed contrast assertion caught an unnormalized fallback hex color; normalizing the invalid color fixed it.
- The GSD roadmap updater's write scope did not recognize the active-milestone table; the row records `6/6` and `In Progress` pending phase verification.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 236's POR-05 theme gap is closed with recurring, deterministic served-route browser checks. The only remaining evidence boundary is explicitly documented: real provider iframe rendering is not established by the SDK mock.

## Self-Check: PASSED

- Summary file exists.
- Task commits `56f28efc`, `5fe38525`, `cf739ab8`, `67dacd8e`, and `cdad46b3`, plus metadata commit `9c735261`, are ancestors of the current plan head.
- Roadmap and Nyquist index checker passed after the final selector implementation and three focused browser results were recorded.

---
*Phase: 236-portal-billing-self-service*
*Completed: 2026-10-08*
