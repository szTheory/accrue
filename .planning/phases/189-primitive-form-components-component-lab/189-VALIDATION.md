---
phase: 189
slug: primitive-form-components-component-lab
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-17
---

# Phase 189 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `189-RESEARCH.md` → Validation Architecture. Per-task rows are
> filled by the planner/executor once PLAN.md task IDs exist.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) + Playwright e2e (`accrue_admin/`) |
| **LiveView test case** | `AccrueAdmin.LiveCase` (`async: false` — DB sandbox) |
| **Config file** | existing — `accrue_admin/mix.exs`, `accrue_admin/playwright.config.*` |
| **Quick run command** | `mix test test/accrue_admin/dev/component_registry_test.exs` |
| **Full suite command** | `mix test && npm run e2e && npm run e2e:a11y && npm run score-visuals` |
| **Estimated runtime** | unit ~15s; full e2e+a11y+vision several minutes |

---

## Sampling Rate

- **After every task commit:** `mix test test/accrue_admin/dev/component_registry_test.exs`
- **After every plan wave:** `mix test && npm run e2e:a11y`
- **Before `/gsd:verify-work` (phase gate):** full suite must be green
- **Max feedback latency:** ~15s (registry drift quick run)

---

## Per-Requirement Verification Map

| Requirement | Behavior | Test Type | Automated Command | Signal |
|-------------|----------|-----------|-------------------|--------|
| CMP-01 | Every primitive exercised in lab across full state matrix in both themes | ExUnit registry drift + Playwright axe sweep on kitchen route | `mix test .../component_registry_test.exs` + `npm run e2e:a11y` | all `applicable_states` render (registry test); axe sweep zero violations |
| CMP-01 | Light/dark columns resolve different computed colors (D-07 not inert) | Playwright probe (new) | `npm run e2e -- e2e/admin-interactions.spec.js` | `lightBase !== darkBase` resolved-color delta assertion passes |
| CMP-02 | Long/overflowing content renders without clipping or layout break | Playwright probe (extend admin-interactions) | `npm run e2e -- e2e/admin-interactions.spec.js` | `scrollWidth <= clientWidth` for all overflow specimens |
| CMP-03 | Interactive primitives: correct role, keyboard, focus, accessible name | Playwright axe + keyboard/focus probe | `npm run e2e:a11y` + new probe in admin-interactions | axe: no button-name/label/duplicate-id violations; focus probe `outlineWidth >= 2px` |
| CMP-03 | Non-interactive elements expose no misleading affordance | Playwright cursor probe | `npm run e2e -- e2e/admin-interactions.spec.js` | `getComputedStyle(el).cursor !== "pointer"` on empty-state/badge |
| CMP-04 | Disabled/readonly visually unmistakable; button text contrast | Playwright probe + axe color-contrast | `npm run e2e:a11y` + disabled probe | axe: no color-contrast violations; disabled bg == `--ax-disabled-bg` computed value |
| CMP-05 | No per-page override of primitive `ax-*` classes; no raw inline `style` on primitives | Shell verifier + ExUnit negative fixture | `bash scripts/ci/verify_package_docs.sh` | verifier exits 0 on compliant tree; exits 1 on injected violation |

*Per-task rows (`{N}-PP-TT`) are added by the planner against PLAN.md task IDs;
each task must reference one row above or a Wave 0 dependency.*

---

## Wave 0 Requirements

- [ ] Audit missing primitive modules before writing registry entries — `grep -rn "ax-skeleton\|ax-spinner\|ax-toggle\|ax-checkbox\|ax-tooltip" accrue_admin/lib/` (textarea, checkbox, radio, toggle, spinner, skeleton, tooltip, inline-id, empty-state); decide create-module vs canonize-CSS-only per family.
- [ ] `accrue_admin/test/accrue_admin/dev/component_registry_test.exs` — extend with state-matrix structure test (e) and theme-column data-attribute test (f), in lockstep with the registry schema change (D-08).
- [ ] `accrue_admin/e2e/admin-interactions.spec.js` — add component-kitchen probe block (focus ring, overflow, resolved-color theme delta, disabled-affordance, cursor) writing the frozen `p187__{surface}__{mode}__{theme}__{state}__{dXX}` grammar.
- [ ] `accrue_admin/assets/css/app.css` — add `.ax-dev-state-grid` rules (no existing definition).
- [ ] `accrue_admin/assets/css/theme.css` — add sub-tree `.accrue-admin [data-theme="dark"]` descendant selector with the FULL dark token block (D-07 critical path).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Subjective visual hierarchy / brand polish per family | CMP-01..04 | Vision-model scoring is advisory, not a hard gate; env-gated on `ANTHROPIC_API_KEY` | `npm run score-visuals`; review per-family scores vs Phase-187 baseline; maintainer screenshot checkpoint at phase boundary |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (missing-primitive audit + harness extensions)
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
