---
phase: 199
slug: cross-cutting-interaction-overlay-correctness-fixture-stress
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-29
---

# Phase 199 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Node `node --test`, Playwright |
| **Config file** | `accrue_admin/package.json`, `accrue_admin/test/test_helper.exs`, `accrue_admin/playwright.config.js` |
| **Quick run command** | `cd accrue_admin && node --test test/js/scroll_lock_test.mjs test/js/focus_trap_test.mjs test/js/dropdown_test.mjs && mix test test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/theme_test.exs test/accrue_admin/e2e_fixtures_test.exs test/accrue_admin/copy_test.exs` |
| **Full suite command** | `cd accrue_admin && npm run e2e:phase199 && npm run e2e:phase195 && npm run e2e:phase198 && env -u NO_COLOR playwright test e2e/reduced-motion.spec.js --timeout=60000 --workers=1` |
| **Estimated runtime** | ~600 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick command, or the narrow command named in the task's `<verify>` block.
- **After every plan wave:** Run the full command for all Phase 199 browser coverage added so far.
- **Before `/gsd:verify-work`:** Full Phase 199 browser gate, reduced-motion gate, focused ExUnit/JS gates, and rebuilt assets must be green.
- **Max feedback latency:** 15 minutes for a wave-level browser pass; under 3 minutes for narrow JS/ExUnit checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 199-W0-IXN-01 | TBD | 0 | IXN-01 | T-199-overlay-bg / T-199-overlay-dismiss | Modal/drawer surfaces portal to `#ax-overlay-root`, isolate background, scroll-lock only when modal, and restore state after rapid dismissal. | ExUnit + JS + Playwright | `cd accrue_admin && node --test test/js/scroll_lock_test.mjs test/js/focus_trap_test.mjs && npm run e2e:phase199` | W0 | pending |
| 199-W0-IXN-02 | TBD | 0 | IXN-02 | T-199-focus-motion | Drawer/mobile-sheet geometry, focus trap/restore, focus ring immediacy, and reduced-motion behavior are observable in browser specs. | CSS/source + Playwright | `cd accrue_admin && env -u NO_COLOR playwright test e2e/reduced-motion.spec.js --timeout=60000 --workers=1 && npm run e2e:phase199` | W0 | pending |
| 199-W0-IXN-03 | TBD | 0 | IXN-03 | T-199-affordance-theme | Non-interactive surfaces expose no actionable affordances; disabled/hidden affordances are semantically correct; theme persistence avoids wrong-theme flash. | ExUnit + Playwright | `cd accrue_admin && mix test test/accrue_admin/theme_test.exs && npm run e2e:phase199` | W0 | pending |
| 199-W0-IXN-04 | TBD | 0 | IXN-04 | T-199-stacking-context | Overlay shells remain outside transformed, filtered, contained, or perspective page wrappers and are top hit targets above scrims. | Source audit + Playwright | `cd accrue_admin && npm run e2e:phase199` | W0 | pending |
| 199-W0-FIX-01 | TBD | 0 | FIX-01 | T-199-flow-state | Multi-step list/detail/nested detail/drill/back fixtures preserve focus and scroll integrity across each transition. | Playwright | `cd accrue_admin && npm run e2e:phase199` | W0 | pending |
| 199-W0-FIX-02 | TBD | 0 | FIX-02 | T-199-edge-fixtures | Long content, zero-decimal currency, past-due dunning, and overflow fixtures are deterministic and reveal no clipping or squish. | ExUnit + Playwright | `cd accrue_admin && mix test test/accrue_admin/e2e_fixtures_test.exs && npm run e2e:phase199` | W0 | pending |
| 199-W0-CPY-01 | TBD | 0 | CPY-01 | T-199-copy-context | Page-level strings route through copy modules, first-run and filtered empties differ, and action labels include visible or hidden object/action context. | ExUnit + Playwright | `cd accrue_admin && mix test test/accrue_admin/copy_test.exs && npm run e2e:phase199` | W0 | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` - browser contract for IXN-01..04, FIX-01..02, and CPY-01 route evidence.
- [ ] `accrue_admin/package.json` - `e2e:phase199` script mapped to the focused Phase 199 spec with one worker.
- [ ] `accrue_admin/test/js/scroll_lock_test.mjs` - nested lock, double-toggle, final restore, `--ax-scrollbar-comp`, and shell `inert` coverage.
- [ ] `accrue_admin/test/js/focus_trap_test.mjs` - focus entry, wrap, outside-focus redirect, Escape close, and restore coverage.
- [ ] `accrue_admin/test/accrue_admin/components/overlay_components_test.exs` - structural overlay, dropdown exception, command palette, and hidden mirror assertions.
- [ ] `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs` - deterministic edge fixture idempotency for any Phase 199 fixture extension.
- [ ] `accrue_admin/test/accrue_admin/copy_test.exs` - page-level copy and accessible action-context regression coverage.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None planned | IXN-01..CPY-01 | Phase 199 scope is browser/source/test verifiable. | All phase behaviors must have automated verification in the PLAN.md tasks. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify steps or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing requirement references.
- [ ] No watch-mode flags.
- [ ] Feedback latency under 15 minutes for wave gates.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 exists and all requirement rows map to executable tasks.

**Approval:** pending
