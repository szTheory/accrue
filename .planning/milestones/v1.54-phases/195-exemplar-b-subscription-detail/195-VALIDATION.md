---
phase: 195
slug: exemplar-b-subscription-detail
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-26
audited: 2026-07-01
verification_report: .planning/phases/195-exemplar-b-subscription-detail/195-VERIFICATION.md
---

# Phase 195 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Mix for LiveView and component tests; Node `node --test` for JS hook tests; Playwright for browser page-flow |
| **Config file** | `accrue_admin/test`, `accrue_admin/package.json`, existing Playwright config |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/live/subscription_live_test.exs` |
| **Full suite command** | `cd accrue_admin && mix test && node --test test/js/scroll_lock_test.mjs test/js/dropdown_test.mjs && npm run e2e:phase195` |
| **Estimated runtime** | ~180 seconds targeted; full suite depends on Playwright browser startup |

---

## Sampling Rate

- **After every task commit:** Run the targeted ExUnit file for the component or LiveView touched by the task.
- **After JS hook tasks:** Run `cd accrue_admin && node --test test/js/scroll_lock_test.mjs`.
- **After every plan wave:** Run the targeted ExUnit pair plus the Phase 195 Playwright spec.
- **Before `/gsd:verify-work`:** `cd accrue_admin && mix test && node --test test/js/scroll_lock_test.mjs test/js/dropdown_test.mjs && npm run e2e:phase195` must pass, or the failure must be explicitly documented with environment evidence.
- **Max feedback latency:** 180 seconds for targeted runs.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 195-W0-01 | 195-01 | 0 | IXN-01 | T-195-overlay | Drawer overlay portals above scrim, traps focus, inerts background, locks/restores scroll, dismisses on backdrop/Escape | component + JS + browser | `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs && node --test test/js/scroll_lock_test.mjs && npm run e2e:phase195` | Plan 195-01 creates missing JS/E2E files | pending |
| 195-W0-02 | 195-02 | 0 | EXE-02 | N/A | Subscription detail renders summary-list header, <=2 primary actions, one overflow menu, one related strip, no duplicate related card | LiveView + browser | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs && npm run e2e:phase195` | LiveView test exists; E2E file created by Plan 195-01 | pending |
| 195-W0-03 | 195-02 | 0 | EXE-02, IXN-01 | T-195-action-hosting | Action forms are absent on initial load and render only inside the drawer after selecting an allowed action | LiveView + browser | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs && npm run e2e:phase195` | LiveView test exists; E2E file created by Plan 195-01 | pending |
| 195-W0-04 | 195-02, 195-07 | 0, 5 | EXE-02 | N/A | Action relabels use `AccrueAdmin.Copy` and regenerated copy fixture includes `Change plan`, `Cancel renewal`, `Cancel immediately`, and `Comp this subscription` | source + fixture | `cd accrue_admin && mix accrue_admin.export_copy_strings && git diff --check ../examples/accrue_host/e2e/generated/copy_strings.json` | Fixture exists | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `accrue_admin/test/js/scroll_lock_test.mjs` - covers lock ref count, saved scroll restore, scrollbar compensation, and `inert` toggle on `#accrue-admin-shell`.
- [ ] `accrue_admin/e2e/admin-spec-detail-phase195.spec.js` or the existing page-flow cell file - covers desktop and mobile overlay top-pointer, body-scroll unchanged, inert background, backdrop/Escape dismissal, and form-in-drawer behavior.
- [ ] `accrue_admin/test/accrue_admin/components/overlay_components_test.exs` - update existing component coverage for canonical overlay, portal attributes, drawer presentation, and action menu.
- [ ] `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` - update existing LiveView assertions from always-visible forms to six-band detail structure.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser binary availability | IXN-01 | Research verified Playwright CLI version but did not launch browsers | If `npm run e2e:phase195` fails before app interaction due to missing browser binaries, run the existing Playwright install/setup path and retry once before marking phase blocked |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency under 180 seconds for targeted runs.
- [x] `nyquist_compliant: true` set after the planner assigned concrete task IDs and Wave 0 coverage exists.

**Approval:** approved 2026-06-26 for planning; execution status rows remain pending until the Wave 0 plans run.
