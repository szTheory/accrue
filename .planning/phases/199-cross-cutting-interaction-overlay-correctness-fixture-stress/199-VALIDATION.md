---
phase: 199
slug: cross-cutting-interaction-overlay-correctness-fixture-stress
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-29
revised: 2026-06-29
plan_count: 15
---

# Phase 199 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Node `node --test`, Playwright |
| **Config file** | `accrue_admin/package.json`, `accrue_admin/test/test_helper.exs`, `accrue_admin/playwright.config.js` |
| **Quick run command** | `cd accrue_admin && node --test test/js/scroll_lock_test.mjs test/js/focus_trap_test.mjs test/js/dropdown_test.mjs test/js/command_palette_test.mjs && mix test test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/theme_test.exs test/accrue_admin/e2e_fixtures_test.exs test/accrue_admin/copy_test.exs --max-failures 10` |
| **Full suite command** | `cd accrue_admin && npm run e2e:phase199 && env -u NO_COLOR playwright test e2e/reduced-motion.spec.js --timeout=60000 --workers=1 && mix compile --warnings-as-errors` |
| **Estimated runtime** | ~600 seconds |

---

## Sampling Rate

- **After every task commit:** Run the narrow command named in the task's `<verify>` block.
- **After every plan wave:** Run the Phase 199 browser subsets added so far plus the focused ExUnit/JS commands touched by that wave.
- **Before `/gsd:verify-work`:** Full Phase 199 browser gate, reduced-motion gate, focused ExUnit/JS gates, compile, package-doc, copy export, and rebuilt assets must be green.
- **Max feedback latency:** 15 minutes for a wave-level browser pass; under 3 minutes for narrow JS/ExUnit checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 199-W0-BROWSER | 199-01 | 0 | IXN-01, IXN-02, IXN-03, IXN-04, FIX-01, FIX-02, CPY-01 | T-199-01 / T-199-02 | Focused Phase 199 browser contract and `e2e:phase199` script exist and fail only on real behavior gaps after setup is valid. | Playwright + node check | `cd accrue_admin && node --check e2e/admin-interaction-overlay-phase199.spec.js && npm run e2e:phase199` | 199-01 | pending |
| 199-W0-JS | 199-02 | 0 | IXN-01, IXN-02, IXN-03 | T-199-03 / T-199-04 | Scroll/focus/dropdown/palette lifecycle contracts prove no stale lock, inert shell, or body focus. | Node unit | `cd accrue_admin && node --test test/js/scroll_lock_test.mjs test/js/focus_trap_test.mjs test/js/dropdown_test.mjs test/js/command_palette_test.mjs` | 199-02 | pending |
| 199-W0-EXUNIT | 199-03 | 0 | IXN-01, IXN-02, IXN-03, IXN-04, FIX-01, FIX-02, CPY-01 | T-199-05 / T-199-06 / T-199-07 | Source, theme, fixture, and copy contracts are executable before implementation starts. | ExUnit | `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/components/global_search_test.exs test/accrue_admin/components/theme_picker_test.exs test/accrue_admin/theme_test.exs test/accrue_admin/e2e_fixtures_test.exs test/accrue_admin/copy_test.exs --max-failures 10` | 199-03 | pending |
| 199-W1-OVERLAY-COMP | 199-04 | 1 | IXN-01, IXN-04 | T-199-08 / T-199-09 | Modal/drawer component paths are canonical, root is body-level, and hidden mirrors stay non-interactive. | ExUnit/source | `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/components/global_search_test.exs --max-failures 5` | 199-04 | pending |
| 199-W1-OVERLAY-JS | 199-05 | 1 | IXN-01, IXN-02, IXN-03 | T-199-10 / T-199-11 / T-199-12 | ScrollLock, FocusTrap, Overlay, and CommandPalette cleanup is deterministic and generated JS is synced. | Node + asset check | `cd accrue_admin && node --test test/js/scroll_lock_test.mjs test/js/focus_trap_test.mjs test/js/command_palette_test.mjs && mix accrue_admin.assets.build && git diff --check priv/static/accrue_admin.js` | 199-05 | pending |
| 199-W1-COPY-HELPERS | 199-11 | 1 | CPY-01, IXN-03 | T-199-25 / T-199-26 | Copy helpers and raw-string guard prove state-specific, voice-aligned copy. | ExUnit + deterministic Node guard | `cd accrue_admin && mix test test/accrue_admin/copy_test.exs --max-failures 5` | 199-11 | pending |
| 199-W2-OVERLAY-BROWSER | 199-06 | 2 | IXN-01, IXN-04 | T-199-13 / T-199-14 | Rendered overlays are top hit targets, close cleanly, and are not trapped under page wrappers. | Playwright + ExUnit | `cd accrue_admin && npm run e2e:phase199 -- --grep @overlay && mix test test/accrue_admin/components/overlay_components_test.exs --max-failures 5` | 199-06 | pending |
| 199-W2-LIST-COPY | 199-12 | 2 | CPY-01, IXN-03 | T-199-27 / T-199-28 | List/recovery pages route changed state copy through Copy helpers and keep unavailable controls absent/semantic. | ExUnit + compile | `cd accrue_admin && mix test test/accrue_admin/copy_test.exs --max-failures 5 && mix compile --warnings-as-errors` | 199-12 | pending |
| 199-W2-DETAIL-COPY | 199-13 | 2 | CPY-01, IXN-01, IXN-03 | T-199-29 / T-199-30 | Detail/analytics pages use Copy helpers and object-aware sensitive action labels. | ExUnit + compile | `cd accrue_admin && mix test test/accrue_admin/copy_test.exs --max-failures 5 && mix compile --warnings-as-errors` | 199-13 | pending |
| 199-W3-MOTION | 199-07 | 3 | IXN-02, IXN-04 | T-199-15 / T-199-16 | Drawer/mobile-sheet geometry, focus-ring immediacy, reduced motion, and generated CSS are correct. | ExUnit + Playwright + asset check | `cd accrue_admin && env -u NO_COLOR playwright test e2e/reduced-motion.spec.js --timeout=60000 --workers=1 && npm run e2e:phase199 -- --grep @motion` | 199-07 | pending |
| 199-W4-FLOATING | 199-08 | 4 | IXN-02, IXN-03 | T-199-17 / T-199-18 | Floating panels are trigger-aware, viewport-bound, and dropdowns remain non-modal. | Node + ExUnit + Playwright | `cd accrue_admin && node --test test/js/dropdown_test.mjs && mix test test/accrue_admin/components/theme_picker_test.exs --max-failures 5 && npm run e2e:phase199 -- --grep @affordance` | 199-08 | pending |
| 199-W5-THEME | 199-09 | 5 | IXN-03, IXN-04 | T-199-19 / T-199-20 | Production theme persistence and false-affordance guards pass with package-doc checks. | ExUnit + Playwright + docs | `cd accrue_admin && mix test test/accrue_admin/theme_test.exs --max-failures 5 && npm run e2e:phase199 -- --grep @theme && bash ../scripts/ci/verify_package_docs.sh` | 199-09 | pending |
| 199-W6-FIXTURE | 199-10 | 6 | FIX-01, FIX-02, IXN-01, IXN-02, IXN-03 | T-199-21 / T-199-22 / T-199-23 / T-199-24 | Deterministic route fixtures and composed flows preserve focus, scroll, and layout integrity. | ExUnit + Playwright | `cd accrue_admin && mix test test/accrue_admin/e2e_fixtures_test.exs --max-failures 5 && npm run e2e:phase199 -- --grep @fixture` | 199-10 | pending |
| 199-W7-COPY-BROWSER | 199-14 | 7 | CPY-01, IXN-01, IXN-03, FIX-01, FIX-02 | T-199-31 / T-199-32 | Shared hidden context labels and generated copy fixtures are reflected in browser @copy tests. | ExUnit + export + Playwright | `cd accrue_admin && mix test test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/components/data_table_test.exs --max-failures 10 && mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json && npm run e2e:phase199 -- --grep @copy` | 199-14 | pending |
| 199-W8-CLOSEOUT | 199-15 | 8 | IXN-01, IXN-02, IXN-03, IXN-04, FIX-01, FIX-02, CPY-01 | T-199-33 / T-199-34 | Full focused Phase 199 validation stack is green without creating Phase 200-owned artifacts. | JS + ExUnit + Playwright + compile + docs + assets | `cd accrue_admin && npm run e2e:phase199 && env -u NO_COLOR playwright test e2e/reduced-motion.spec.js --timeout=60000 --workers=1 && mix compile --warnings-as-errors` | 199-15 | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [x] `199-01-PLAN.md` maps browser contract and `e2e:phase199` script creation to IXN-01..CPY-01.
- [x] `199-02-PLAN.md` maps JS lifecycle contracts for ScrollLock, FocusTrap, Dropdown, and CommandPalette.
- [x] `199-03-PLAN.md` maps ExUnit/source contracts for overlay, command palette, theme, fixtures, and copy.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None planned | IXN-01..CPY-01 | Phase 199 scope is browser/source/test verifiable. | All phase behaviors have automated verification in PLAN.md tasks. |

---

## Validation Sign-Off

- [x] All tasks have automated verify steps or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all requirement references.
- [x] No watch-mode flags.
- [x] Feedback latency target under 15 minutes for wave gates.
- [x] `nyquist_compliant: true` set after all requirement rows mapped to executable plans.

**Approval:** ready for execution
