---
phase: 193-research-re-baseline-pattern-lock
plan: "03"
subsystem: testing
tags: [playwright, e2e, overlay, portal, spike, d05, res03]

requires:
  - phase: 193-research-re-baseline-pattern-lock/193-01
    provides: phase context and D-05 decision framing from CONTEXT.md
  - phase: 191
    provides: phase191-page-flow-helpers.js with assertTopPointerTarget helper

provides:
  - spike-overlay-portal.spec.js with four D-05 proof blocks (RES-03 Spike A)
  - Empirical evidence for D-01 portal-primary decision
  - Recorded D-05 decision in file header comment

affects:
  - 195 (overlay primitive build — reads D-05 decision)
  - 199 (ScrollLock hook — Proof 3 gutter-jump delta recorded for Phase 199 to fix)

tech-stack:
  added: []
  patterns:
    - "test-fixture portal pattern: inject portal HTML via page.evaluate when production portal does not yet exist"
    - "D-05 spike measurement: record observed value with console.log + test.info annotation, do not assert future hook behavior"

key-files:
  created:
    - accrue_admin/e2e/spike-overlay-portal.spec.js
  modified:
    - accrue_admin/mix.lock

key-decisions:
  - "D-01 portal-primary confirmed: body-level #ax-overlay-root portal escapes all tested ancestors including transform:translateZ(0) — D-02 native dialog fallback NOT triggered by this spike"
  - "RES-03 Spike A resolved: all four D-05 proofs passed or recorded empirically"
  - "Proof 3 gutter-jump delta = 0px without ScrollLock hook (Phase 199 will enforce this)"

patterns-established:
  - "Spike spec uses test-fixture approach via page.evaluate when the production implementation does not yet exist — proves the pattern's empirical properties without blocking on the Phase 199 build"
  - "Measurement-only Proof 3 pattern: record delta with console.log + test.info annotation; assert typeof delta === 'number', NOT assert delta === 0"

requirements-completed:
  - RES-03

coverage:
  - id: D1
    description: "Proof 1 — overlay primary action is hit-testable above scrim via assertTopPointerTarget (portal as direct body child)"
    requirement: RES-03
    verification:
      - kind: e2e
        ref: "accrue_admin/e2e/spike-overlay-portal.spec.js#Proof 1 — primary action is hit-testable above scrim"
        status: pass
    human_judgment: false
  - id: D2
    description: "Proof 2 — portal survives LiveView navigation without orphan/double-mount; #ax-overlay-root count == 0 after navigate-away, == 1 after return"
    requirement: RES-03
    verification:
      - kind: e2e
        ref: "accrue_admin/e2e/spike-overlay-portal.spec.js#Proof 2 — portal survives LiveView navigation without orphan"
        status: pass
    human_judgment: false
  - id: D3
    description: "Proof 3 — gutter-jump delta recorded as spike finding (0px, no ScrollLock hook yet); test completes without timeout"
    requirement: RES-03
    verification:
      - kind: e2e
        ref: "accrue_admin/e2e/spike-overlay-portal.spec.js#Proof 3 — body scroll-lock gutter-jump spike measurement"
        status: pass
    human_judgment: false
  - id: D4
    description: "Proof 4 — portal escapes transform:translateZ(0) ancestor; assertTopPointerTarget passes with active transform on LiveView root"
    requirement: RES-03
    verification:
      - kind: e2e
        ref: "accrue_admin/e2e/spike-overlay-portal.spec.js#Proof 4 — portal escapes transformed ancestor"
        status: pass
    human_judgment: false
  - id: D5
    description: "D-05 recorded decision comment block present in spike-overlay-portal.spec.js with actual empirical results filled in"
    requirement: RES-03
    verification:
      - kind: e2e
        ref: "grep -c 'D-05 recorded decision' accrue_admin/e2e/spike-overlay-portal.spec.js → 1"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-06-25
status: complete
---

# Phase 193 Plan 03: D-05 Overlay Portal Spike (RES-03 Spike A) Summary

**Four-proof Playwright spike confirming portal-primary (D-01): body-level #ax-overlay-root escapes transformed ancestors, survives LiveView navigation orphan-free, and hits above scrim — D-02 native dialog fallback NOT triggered.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-25T17:35:00Z
- **Completed:** 2026-06-25T17:51:00Z
- **Tasks:** 1
- **Files modified:** 2 (spike-overlay-portal.spec.js created, mix.lock updated)

## Accomplishments

- Created `accrue_admin/e2e/spike-overlay-portal.spec.js` with four D-05 proof blocks satisfying RES-03 Spike A
- All 8 Playwright tests pass green (4 proofs × 2 browser projects: chromium-desktop + chromium-mobile)
- Proof 3 recorded gutter-jump delta = 0px as a spike finding (no assertion — ScrollLock hook lands in Phase 199)
- D-05 recorded-decision comment block filled in with actual empirical results
- mix.lock updated with phoenix_storybook, mdex, makeup_eex, makeup_html transitive deps (required by Phase 193 Plan 03+ work)

## Task Commits

1. **Task 1: Write and run spike-overlay-portal.spec.js** - `9dc907df` (feat)

## Files Created/Modified

- `accrue_admin/e2e/spike-overlay-portal.spec.js` — D-05 four-proof spike spec (RES-03 Spike A provenance artifact)
- `accrue_admin/mix.lock` — updated with phoenix_storybook and mdex transitive deps fetched during task

## Decisions Made

- **D-01 portal-primary confirmed:** All four D-05 proofs passed. Body-level `#ax-overlay-root` as a direct `<body>` child escapes `transform:translateZ(0)` re-rooting, survives LiveView navigation cleanly, and the primary action is always hit-testable above the scrim. D-02 (native `<dialog>`) fallback was NOT triggered by this spike.
- **Test-fixture approach selected:** Since DetailDrawer does NOT yet use a body-level portal (it renders inline with `:if={@open}` + phx-mounted/phx-remove), the spec injects a minimal portal fixture via `page.evaluate` to prove the four empirical properties of the portal PATTERN. The /* D-05 recorded decision */ header documents this path explicitly.
- **Proof 3 is a measurement, not an assertion:** The ScrollLock hook (Phase 199) does not exist yet. Proof 3 records `delta = 0px` via `console.log` and `test.info()` annotation without asserting the value. The test asserts only that `typeof delta === 'number'` (measurement succeeded).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Moved test.use({ trace }) from describe-group to top level**
- **Found during:** Task 1 — first Playwright run
- **Issue:** `test.use({ trace: "retain-on-failure" })` inside a `test.describe` block throws an error when `workers: 1` is configured: "Cannot use({ trace }) in a describe group, because it forces a new worker"
- **Fix:** Moved `test.use({ trace: "retain-on-failure" })` to file top level (above the describe block), which is the correct Playwright pattern
- **Files modified:** accrue_admin/e2e/spike-overlay-portal.spec.js
- **Verification:** All 8 tests pass after fix
- **Committed in:** 9dc907df (Task 1 commit, fix applied before commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — Playwright API constraint)
**Impact on plan:** Minor structural fix, no scope change.

## Issues Encountered

- `mix deps.get` was required before the Playwright server could start — `phoenix_storybook` was declared in mix.exs but not yet fetched. Ran `mix deps.get` + `mix compile` (both MIX_ENV=dev and MIX_ENV=test) before first test run.

## Known Stubs

None — the spike spec is intentionally a test-fixture approach (page.evaluate portal injection) because the production portal implementation lands in Phase 199. This is the specified design, not a stub.

## Threat Surface Scan

No new security-relevant surface introduced. The `accrue_admin/e2e/` directory is excluded from the Hex tarball by `package.files` (`~w(lib config guides priv/static mix.exs README* LICENSE* CHANGELOG*)`), satisfying T-193-06. The `page.evaluate` transform injection (T-193-05) is scoped to E2E test context only.

## Self-Check

- [x] spike-overlay-portal.spec.js exists: confirmed
- [x] `grep -c "D-05 recorded decision" ...` → 1: confirmed
- [x] `grep -c "assertTopPointerTarget" ...` → 3: confirmed (Proofs 1, 4, and injectPortalFixture usage)
- [x] All 8 Playwright tests pass: 8 passed (6.4s)
- [x] Task commit 9dc907df exists: confirmed

## Self-Check: PASSED

## Next Phase Readiness

- RES-03 Spike A is resolved with a recorded decision: portal primary (D-01) confirmed
- Phase 195 can build the production overlay primitive against the empirically-proven properties
- Phase 199 should implement the ScrollLock hook (gutter-jump Proof 3 records 0px as the baseline without the hook)
- No D-02 (native dialog) fallback surfaces identified — all four proof conditions pass with the portal approach

---
*Phase: 193-research-re-baseline-pattern-lock*
*Completed: 2026-06-25*
