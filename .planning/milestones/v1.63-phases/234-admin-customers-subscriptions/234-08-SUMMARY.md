---
phase: 234-admin-customers-subscriptions
plan: "08"
subsystem: testing
tags: [playwright, phoenix-liveview, postgres, step-up, accessibility, gsd-uat]
requires:
  - phase: 234-02
    provides: Owner-scoped asynchronous global search and current-query result handling.
  - phase: 234-04
    provides: Reviewed subscription actions and step-up verification gates.
  - phase: 234-06
    provides: Served Admin browser journeys, action drawer, narrow layout, and CSS asset evidence.
provides:
  - A real-pool Playwright search lane that proves async query completion, owner-scoped navigation, and stale-result removal.
  - Deterministic step-up expiry and served nested-dialog keyboard/no-mutation evidence.
  - Machine-readable accessibility, type size, line-height, theme, and narrow viewport checks in the blocking browser suite.
  - A project-level default to shift testable acceptance left and avoid confirmation-only UAT.
affects: [admin-e2e, host-playwright-ci, gsd-verification]
actuals:
  tokens: 73101
  tasks: 3
  commits: 4
  plan_head_before: ae64e0cd53b852255fb6ad2760ee27f5203fdaf2
  plan_head_after: 09b6a484d0350034ad658a75fb6052fd4437d562
tech-stack:
  added: []
  patterns:
    - Opt-in normal Repo pool for browser coverage of asynchronous query workers; SQL Sandbox remains the default fixture mode.
    - Capture the LiveView process before spawning component work and route async component updates back to that process.
    - Use axe and computed DOM styles for repeatable UI evidence where cross-platform pixel snapshots add noise.
key-files:
  created:
    - examples/accrue_host/playwright.search.config.js
    - examples/accrue_host/e2e/phase234-search-completion.spec.js
    - .planning/phases/234-admin-customers-subscriptions/234-08-PLAN.md
    - .planning/phases/234-admin-customers-subscriptions/234-UAT.md
    - .planning/phases/234-admin-customers-subscriptions/234-VERIFICATION.md
  modified:
    - .github/workflows/ci.yml
    - .planning/PROJECT.md
    - CLAUDE.md
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/components/global_search.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/test/accrue_admin/components/global_search_test.exs
    - accrue_admin/test/accrue_admin/live/step_up_test.exs
    - examples/accrue_host/config/test.exs
    - examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js
    - examples/accrue_host/e2e/support/test.js
    - examples/accrue_host/lib/accrue_host/auth.ex
    - examples/accrue_host/package.json
    - examples/accrue_host/playwright.config.js
requirements-completed: [ADM-03, ADM-04, SAFE-01]
coverage:
  - id: D1
    description: Real pooled asynchronous search returns the exact scoped customer, navigates correctly, and removes stale matches.
    requirement: ADM-03
    verification:
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase234-search-completion.spec.js#global search completes real scoped database queries and removes stale matches (two runs)"
        status: pass
      - kind: other
        ref: ".github/workflows/ci.yml#playwright-e2e real database-backed global search lane"
        status: pass
    human_judgment: false
  - id: D2
    description: Expired step-up requires successful verification before continuation; Escape cancels only the nested challenge and preserves the staged action without dispatch.
    requirement: SAFE-01
    verification:
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/live/step_up_test.exs#expired grace opens a fresh challenge and blocks the continuation until verification"
        status: pass
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js#Phase 234 served Admin journeys preserve scope, focus, reflow, theme and asset provenance"
        status: pass
    human_judgment: false
  - id: D3
    description: Served detail screens meet the computed typography floor, accessibility checks pass in light and dark themes, and content reflows at 320px; search empty and partial-error copy stays covered.
    requirement: ADM-04
    verification:
      - kind: automated_ui
        ref: "examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js#Phase 234 served Admin journeys and coarse-pointer 320px case"
        status: pass
      - kind: unit
        ref: "accrue_admin/test/accrue_admin/components/global_search_test.exs#no matches are distinct from failed lookups; partial failure retains successful groups and offers a read retry"
        status: pass
      - kind: other
        ref: "cd accrue_admin && npm_config_cache=/tmp/accrue-phase234-08-npm-cache mix accrue_admin.assets.build"
        status: pass
    human_judgment: false
  - id: D4
    description: Future GSD plans default to executable acceptance evidence and skip confirmation-only UAT when all machine-verifiable claims pass.
    verification:
      - kind: other
        ref: ".planning/PROJECT.md Verification posture and CLAUDE.md Executable Acceptance Policy"
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-10-08
status: complete
---

# Phase 234 Plan 08: Shift-Left Verification Summary

**Real database-backed search, step-up interaction, and UI acceptance now run as executable evidence, with a durable zero-human-UAT default for future phases.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-10-08T03:12:00Z
- **Completed:** 2026-10-08T03:33:00Z
- **Tasks:** 3
- **Files modified:** 19 tracked implementation and planning files, plus this summary and the regenerated verification report

## Accomplishments

- Added a dedicated Playwright config and test that disables SQL Sandbox only for the real-query lane. The test proves current owner-scoped customer results finish loading, navigate to the right scoped customer, and disappear when the query changes. The merge-blocking CI job runs the lane on shard 1, then restores the normal Sandbox compile for later browser lanes.
- Fixed the async update target uncovered by the real browser test: the search task now routes `send_update` to its originating LiveView process rather than itself. Added a focused regression assertion for the explicit target.
- Added a five-minute step-up expiry test and a test-only TOTP adapter. The served journey checks focus wrapping, Escape cancellation, focus return to the staged review, no action result, and unchanged subscription status.
- Added axe checks for customer and subscription details, 14px/1.2 line-height assertions for primary subscription facts, light/dark coverage, and a 320px no-overflow check. Raised the affected detail text to the design-system `--ax-type-sm` and normal leading tokens.
- Recorded the project-wide shift-left policy in `.planning/PROJECT.md` and mirrored the no-confirmation-only rule in `CLAUDE.md`.

## Task Commits

1. **Task 1: Prove real asynchronous search in a safe browser lane** — `742d1872` (fix)
2. **Task 2: Verify expired and nested step-up behavior** — `a75ea845` (fix)
3. **Task 3: Make UI acceptance measurable and durable** — `7edad799` (fix)
4. **Automated UAT reconciliation** — `09b6a484` (test)

**Measured plan range:** 4 commits from `ae64e0cd53b852255fb6ad2760ee27f5203fdaf2` through `09b6a484d0350034ad658a75fb6052fd4437d562`; the final execution-state commit follows this summary.

## Files Created/Modified

- `examples/accrue_host/playwright.search.config.js` — normal-pool browser lane on a separate port.
- `examples/accrue_host/e2e/phase234-search-completion.spec.js` — real query, scoped link, and stale-result browser proof.
- `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js` — nested step-up, accessibility, readability, theme, and narrow layout checks.
- `accrue_admin/lib/accrue_admin/components/global_search.ex` — explicit LiveView process target for async results.
- `accrue_admin/test/accrue_admin/components/global_search_test.exs` and `accrue_admin/test/accrue_admin/live/step_up_test.exs` — query update target and expiry coverage.
- `examples/accrue_host/config/test.exs`, `examples/accrue_host/e2e/support/test.js`, and `examples/accrue_host/lib/accrue_host/auth.ex` — opt-in real pool and deterministic test challenge.
- `.github/workflows/ci.yml` and `examples/accrue_host/package.json` — repeatable search lane wired into required CI.
- `accrue_admin/assets/css/app.css` and `accrue_admin/priv/static/accrue_admin.css` — readable subscription detail typography in source and served asset.
- `.planning/PROJECT.md`, `CLAUDE.md`, and `234-UAT.md` — durable policy and automated acceptance record.

## Decisions Made

- Keep SQL Sandbox as the default test mode and turn it off only in the dedicated real-query browser lane.
- Use the existing merge-blocking Playwright job and its isolated Postgres service because search correctness has recurring value.
- Keep the Phase 234-06 screenshot artifact immutable; check its PNG integrity while testing current rendered asset equality and DOM/accessibility/layout metrics directly.
- Do not ask for a confirmation-only UAT response when all testable acceptance claims have passing evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Routed asynchronous search results to the LiveView process**
- **Found during:** Task 1 (real pooled search E2E)
- **Issue:** `send_update/2` ran inside `Task.start/1`; its implicit pid was the task itself, leaving the visible search stuck in its loading state even with a normal Repo pool.
- **Fix:** Captured the originating LiveView pid before spawning and passed it to `send_update/3`; added regression coverage.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/global_search.ex`, `accrue_admin/test/accrue_admin/components/global_search_test.exs`
- **Verification:** Dedicated real-pool search E2E passed twice.
- **Committed in:** `742d1872`

**2. [Rule 3 - Blocking] Restored Sandbox compilation after the dedicated search lane**
- **Found during:** Task 1 (CI lane wiring)
- **Issue:** The opt-in compile-time flag could leave the shard's host built without SQL Sandbox for a later browser lane.
- **Fix:** Added a post-search `mix compile --force` step under the default test configuration.
- **Files modified:** `.github/workflows/ci.yml`
- **Verification:** Explicitly compiled the host with the flag unset and confirmed its compile/runtime `:sql_sandbox` values are both `true`; Phase 234 Sandbox browser suite passed.
- **Committed in:** `742d1872`

**3. [Rule 3 - Blocking] Kept historical capture checks compatible with the intentional typography update**
- **Found during:** Task 3 (served browser verification)
- **Issue:** Phase 234-06's immutable manifest contains the prior CSS/source hashes, so comparing those historical values to the updated CSS falsely failed after the planned readability correction.
- **Fix:** Retained hash checks for stored historical PNGs and asserted that the current built and served CSS bytes match; current visual claims use accessibility, computed styles, and reflow checks.
- **Files modified:** `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js`
- **Verification:** Both Phase 234 served browser cases passed.
- **Committed in:** `a75ea845`

**4. [Rule 1 - Bug] Selected a visible subscription link for coarse-pointer navigation**
- **Found during:** Task 3 (320px browser verification)
- **Issue:** The first matching subscription href was a hidden auxiliary link, not a navigable row.
- **Fix:** Limited the locator to visible subscription links.
- **Files modified:** `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js`
- **Verification:** Coarse-pointer 320px browser case passed.
- **Committed in:** `a75ea845`

**Total deviations:** 4 auto-fixed (2 bugs, 2 blocking test/CI assumptions).
**Impact on plan:** Each change was needed to make the planned evidence truthful and repeatable; no external services or production auth behavior were added.

## Issues Encountered

- The default npm cache had root-owned files and caused `mix accrue_admin.assets.build` to exit with `EPERM`. Re-running with `npm_config_cache=/tmp/accrue-phase234-08-npm-cache` passed without changing global cache ownership.
- Chromium requires macOS process permission in this environment; the requested browser checks passed when rerun with that permission.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 234's machine-verifiable UAT checks are recorded as automated; the refreshed verifier report passes with 18/18 truths verified and `behavior_unverified: 0`.
- CI now carries recurring pooled search, step-up, accessibility, computed-readability, and 320px checks.

---
*Phase: 234-admin-customers-subscriptions*
*Completed: 2026-10-08*

## Self-Check: PASSED

- This summary, `234-UAT.md`, and `234-VERIFICATION.md` exist.
- Task commits `742d1872`, `a75ea845`, and `7edad799` plus UAT reconciliation commit `09b6a484` are ancestors of the current plan head.
- GSD verification status reports `passed` with 18/18 truths verified and zero behavior-unverified items.
