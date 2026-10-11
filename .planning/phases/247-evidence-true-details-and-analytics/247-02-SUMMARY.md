---
phase: 247-evidence-true-details-and-analytics
plan: "02"
subsystem: admin-ui
tags: [phoenix, liveview, intl, clipboard]
requires:
  - phase: 247-01
    provides: UTC-first timestamp component and browser formatting hook
provides:
  - Shell-wide persisted Local/UTC preference for mounted timestamp displays
  - Truthful clipboard status and selectable exact timestamp fallback
affects: [phase-247, timestamp-display, admin-clipboard]
tech-stack:
  added: []
  patterns:
    - Keep the preference in one browser module and synchronize shell controls across LiveView patches
    - Keep the original UTC ISO string available as the manual copy fallback
key-files:
  created:
    - accrue_admin/test/js/clipboard_test.mjs
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/assets/js/app.js
    - accrue_admin/assets/js/hooks/clipboard.js
    - accrue_admin/assets/js/hooks/time_display.js
    - accrue_admin/lib/accrue_admin/components/timestamp.ex
    - accrue_admin/lib/accrue_admin/components/topbar.ex
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/accrue_admin.js
    - accrue_admin/test/accrue_admin/components/app_shell_test.exs
    - accrue_admin/test/accrue_admin/components/timestamp_test.exs
    - accrue_admin/test/js/time_display_test.mjs
decisions:
  - "Default to Local when browser storage is available; use UTC if storage cannot be read and retain later choices in memory when writes fail."
  - "Only announce clipboard success after writeText resolves; show a selectable exact UTC value when timestamp copying fails."
metrics:
  duration: 4min
  completed: 2026-10-11
  commits: 2
  plan_head_before: 846c5162f7711dc78dbaa4c78b832d0e87278519
  plan_head_after: a72a3e0e9aa89868d24da7f58bebba0731cbf1f1
status: complete
requirements-completed: []
actuals:
  tokens: 154141
  tasks: 2
  commits: 2
---

# Phase 247 Plan 02: Shared Time Preference and Truthful Clipboard Summary

**Admin timestamps now share a persistent Local/UTC setting, and failed copies expose the exact original timestamp for manual selection.**

## Performance

- **Duration:** 4 minutes
- **Started:** 2026-10-11T21:20:56Z
- **Completed:** 2026-10-11T21:24:48Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Added one labeled Local/UTC selector to the shared Admin topbar. The preference persists under an Admin-specific localStorage key, stays synchronized when LiveView replaces controls, and uses an in-memory selection if storage writes fail. When storage cannot be read, timestamp display remains explicitly UTC.
- Updated timestamp nodes whenever the shared mode changes. Local display includes the resolved IANA timezone; UTC display says UTC. Date-only and malformed calendar/time values are rejected rather than normalized into another instant.
- Made mounted and first-paint clipboard paths report success only after the clipboard promise resolves. Missing APIs and rejected writes expose accessible status; timestamp failures also reveal a selectable, exact UTC ISO value. Hook mounting is idempotent and removes its handler when destroyed.
- Rebuilt the package CSS and JavaScript assets.

## Task Commits

1. **247-02-01: Share Local/UTC display choice across Admin** — `3b9d2c01` (`feat`)
2. **247-02-02: Make clipboard result and manual fallback truthful** — `a72a3e0e` (`fix`)

## Verification

- `node --test test/js/time_display_test.mjs test/js/clipboard_test.mjs` — 10 tests passed.
- `mix test test/accrue_admin/components/app_shell_test.exs test/accrue_admin/components/timestamp_test.exs test/accrue_admin/assets_test.exs` — 13 tests passed.
- `mix format --check-formatted` on the changed Elixir files and `git diff --check` passed.
- `NPM_CONFIG_CACHE=/private/tmp/accrue-npm-cache mix accrue_admin.assets.build` completed and regenerated both served bundles.

## Decisions Made

- The default mode is Local when storage is readable and has no saved preference. An inaccessible storage read selects UTC for a clear server-safe fallback; subsequent selection remains usable in memory if persistence is unavailable.
- Timestamp failure guidance uses a short live announcement and a separate visible, selectable output for the untouched UTC ISO value.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rejected impossible timestamps before browser formatting**
- **Found during:** Task 1
- **Issue:** JavaScript date parsing can normalize an impossible calendar date such as February 30 into another date, displaying an invented instant.
- **Fix:** Validate ISO date, time, and offset components before formatting; added invalid-date and invalid-time assertions.
- **Files modified:** `accrue_admin/assets/js/hooks/time_display.js`, `accrue_admin/test/js/time_display_test.mjs`
- **Commit:** `3b9d2c01`

**2. [Rule 2 - Missing Critical] Made timestamp fallback visibly selectable**
- **Found during:** Task 2
- **Issue:** The existing live-region status was visually hidden, so it could announce failure but could not serve as a practical manual-copy value.
- **Fix:** Added a visible output that contains the exact UTC ISO string after a failed timestamp write, and hides it again after success.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/timestamp.ex`, `accrue_admin/assets/css/app.css`, `accrue_admin/assets/js/hooks/time_display.js`
- **Commit:** `a72a3e0e`

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 2)

## Self-Check: PASSED

- All implementation, test, and rebuilt asset files exist.
- Task commits `3b9d2c01` and `a72a3e0e` are ancestors of the plan head.
- `git rev-list --count 846c5162f7711dc78dbaa4c78b832d0e87278519..a72a3e0e9aa89868d24da7f58bebba0731cbf1f1` reports 2 commits; realized diff size is 616,564 characters, recorded as 154,141 tokens (`chars / 4`).

---
*Phase: 247-evidence-true-details-and-analytics*
*Completed: 2026-10-11*
