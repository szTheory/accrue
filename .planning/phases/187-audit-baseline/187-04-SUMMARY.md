---
phase: 187-audit-baseline
plan: "04"
subsystem: verification
tags: [audit-baseline, playwright, live-interactions, trace, admin-ui]

requires:
  - phase: 187-audit-baseline
    provides: Manifest, static baseline capture, artifact parser, rubric overlay tags, and interaction contracts from Plans 187-02 and 187-03
provides:
  - Test-only non-admin E2E login reachability for permission-denied probes
  - Trace-backed Playwright live interaction probes writing NDJSON observations
  - Interaction coverage rows for modal, drawer, dropdown, scroll, focus, keyboard, state, and step-up modal classes
affects: [phase-187, phase-191, phase-192, VER-01]

tech-stack:
  added: []
  patterns: [ledger-first-playwright-probes, test-only-auth-state-forcing, trace-backed-interaction-observations]

key-files:
  created:
    - accrue_admin/e2e/admin-interactions.spec.js
    - .planning/phases/187-audit-baseline/deferred-items.md
  modified:
    - accrue_admin/test/support/e2e_auth_adapter.ex
    - accrue_admin/test/support/e2e_plug.ex

key-decisions:
  - "Permission-denied forcing stays inside E2E test support through an explicit member token and login-member route."
  - "Live interaction probes record exploratory defects and gaps as NDJSON observations instead of asserting future fixed behavior."
  - "Playwright traces are the primary evidence reference for live interaction rows; generated evidence remains under accrue_admin/test-results."

patterns-established:
  - "Interaction observations carry fixed fields for probe_id, interaction_class, cell_id, surface, state, expected/actual, assertions, evidence_refs, failure_kind, and notes."
  - "Unreachable fixture paths are explicit gap observations, not omitted coverage."
  - "Playwright actionability failures become ledger evidence; the spec does not use forced clicks."

requirements-completed: [VER-01]

duration: 9m
completed: 2026-06-14
---

# Phase 187 Plan 04: Live Interaction Probes Summary

**Trace-backed live interaction probes now write a structured NDJSON ledger, with E2E-only non-admin login support for permission-denied coverage.**

## Performance

- **Duration:** 9m
- **Started:** 2026-06-14T22:53:00Z
- **Completed:** 2026-06-14T23:01:24Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added E2E-only member login support through `admin_token: "member"`, returning `%{id: "e2e_member", role: :member}` without touching production auth or router code.
- Added `admin-interactions.spec.js` with file-scoped `test.use({ trace: "on" })` and 50 valid chromium-desktop observation rows under `accrue_admin/test-results/admin-interactions/chromium-desktop/observations.ndjson`.
- Covered the required live interaction classes: modal/drawer/scrim, step-up auth modal, dropdown/popover/toast, scroll reachability, focus trap/restore, Escape/click-outside dismissal, keyboard-only flows, LiveView patch focus, hover/focus affordance, loading/error/empty, permission-denied, and disconnected/reconnecting.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add test-only permission-denied login support** - `1d09d53e` (feat)
2. **Task 2: Implement live interaction probes** - `ad6df620` (feat)

## Files Created/Modified

- `accrue_admin/e2e/admin-interactions.spec.js` - Trace-backed Playwright probe spec that writes live interaction NDJSON observations.
- `accrue_admin/test/support/e2e_auth_adapter.ex` - Adds explicit E2E member token branch.
- `accrue_admin/test/support/e2e_plug.ex` - Adds test-only `/login-member` and `/__e2e__/login-member` routes.
- `.planning/phases/187-audit-baseline/deferred-items.md` - Records the out-of-scope dashboard ExUnit failure discovered during task verification.

## Decisions Made

- Kept permission-denied forcing inside test support only, matching the plan threat model and leaving `AccrueAdmin.AuthHook`, `AccrueAdmin.OwnerScope`, production routes, and `Accrue.Auth.admin?/1` unchanged.
- Wrote ledger-first probes that record current actionability, focus, overlay, scroll, and state behavior as observations or gaps; the spec avoids permanent corrected-behavior assertions before Phase 191 fixes.
- Used generated `test-results` evidence references in observation rows and did not commit screenshots, traces, or bulky Playwright artifacts.

## Verification

- `grep -q "e2e_member" accrue_admin/test/support/e2e_auth_adapter.ex && grep -q "role: :member" accrue_admin/test/support/e2e_auth_adapter.ex && grep -q "login-member" accrue_admin/test/support/e2e_plug.ex && grep -q 'put_session(:admin_token, "member")' accrue_admin/test/support/e2e_plug.ex` exited 0.
- Source assertion for `admin-interactions.spec.js` required tokens exited 0, including `trace: "on"`, all interaction/state class tokens, StepUpAuthModal selectors, and no `{ force: true }`.
- `cd accrue_admin && npm run e2e -- e2e/admin-interactions.spec.js --project=chromium-desktop -x` exited 0 when run sequentially.
- NDJSON parser check exited 0 and found 50 rows with all required fields and all required interaction classes.
- `cd accrue_admin && mix test --warnings-as-errors test/accrue_admin` exited 2 due to an out-of-scope existing dashboard assertion failure. Isolated proof: `mix test --warnings-as-errors test/accrue_admin/live/dashboard_live_test.exs` exits 2 at `test/accrue_admin/live/dashboard_live_test.exs:91` / assertion at line 119 expecting `$42.50`.

## Deviations from Plan

None - planned implementation scope was followed.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No product UI, production auth, production routes, dependencies, or manifest contract changes were introduced.

## Issues Encountered

- The required admin ExUnit command is currently red from an unrelated dashboard test assertion expecting `$42.50`. The task changes are limited to E2E auth support and a Playwright spec, and the isolated dashboard test fails by itself. This is logged in `deferred-items.md`.
- A parallel verification attempt ran Playwright while ExUnit held the build/server lock, causing a transient `/__e2e__/reset` failure. Rerunning Playwright sequentially passed.

## Known Stubs

None. Stub scan found no task-marker comments, placeholder copy, or hardcoded empty UI data source in the created/modified plan files. Gap observations in the probe spec are intentional audit ledger rows for unreachable current fixture paths.

## Threat Flags

None. New auth reachability is test-support only, production auth files are unchanged, and generated traces/observations stay under `accrue_admin/test-results`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 187-05 can consume the live interaction NDJSON rows alongside the static baseline evidence to generate the canonical Phase 187 ledger. The only known caveat is the unrelated dashboard ExUnit failure recorded for later triage.

## Self-Check: PASSED

- Found created files: `accrue_admin/e2e/admin-interactions.spec.js`, `.planning/phases/187-audit-baseline/deferred-items.md`, and `.planning/phases/187-audit-baseline/187-04-SUMMARY.md`.
- Found task commits: `1d09d53e` and `ad6df620`.
- Verified generated evidence remains ignored under `accrue_admin/test-results/`; `git status --short` showed no untracked generated evidence files before summary/state updates.

---
*Phase: 187-audit-baseline*
*Completed: 2026-06-14*
