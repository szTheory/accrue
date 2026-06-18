---
phase: 190
slug: navigation-data-display-meta-component-cohesion
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 190 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix component rendering, Playwright 1.59.1, and `@axe-core/playwright` 4.11.3 |
| **Config file** | `accrue_admin/mix.exs`, `accrue_admin/package.json`, `accrue_admin/playwright.config.js` |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/components/display_components_test.exs` |
| **Full suite command** | `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && mix test && npm run e2e:a11y && npm run e2e -- e2e/admin-baseline.spec.js && npm run e2e -- e2e/admin-interactions.spec.js` |
| **Estimated runtime** | Quick checks: under 30 seconds expected. Full suite: project-dependent; run at wave and phase gates. |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/components/display_components_test.exs`.
- **After every CSS-affecting task:** Run `cd accrue_admin && mix accrue_admin.assets.build` before browser checks so source CSS reaches `priv/static/accrue_admin.css`.
- **After every plan wave:** Run `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && mix test && npm run e2e:a11y && npm run e2e -- e2e/admin-baseline.spec.js`.
- **Before `/gsd:verify-work`:** Run the full suite command, including `e2e/admin-interactions.spec.js`.
- **Max feedback latency:** Keep per-task feedback under 30 seconds where possible; defer full browser sweeps to wave and phase gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 190-01-01 | TBD | 0 | GRP-01 | T-190-01 / T-190-02 | Group locators and proof surfaces expose no duplicate focus targets or misleading roles. | unit | `cd accrue_admin && mix test test/accrue_admin/dev/component_group_registry_test.exs` | No - Wave 0 | pending |
| 190-01-02 | TBD | 0 | GRP-02 | T-190-03 | Inactive desktop/mobile duplicate markup is hidden from assistive tech and keyboard focus. | unit + e2e | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/display_components_test.exs && npm run e2e -- e2e/admin-baseline.spec.js` | Partial | pending |
| 190-01-03 | TBD | 0 | GRP-03 | T-190-04 | KPI/detail/timeline groups keep hierarchy and tokenized spacing without nested card traps. | unit + e2e | `cd accrue_admin && mix test test/accrue_admin/components/display_components_test.exs && npm run e2e:a11y` | Partial | pending |
| 190-01-04 | TBD | 0 | GRP-04 | T-190-05 | Pagination, filter, sort, active, and selected states are visible, distinct, and absent/de-emphasized when unavailable. | unit + interaction e2e | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs && npm run e2e -- e2e/admin-interactions.spec.js` | Partial | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] Add `test/accrue_admin/dev/component_group_registry_test.exs`, or extend the existing registry tests, to cover Phase 187 group slugs, state inventory, proof IDs, and Phase 191 handoff tags for GRP-01.
- [ ] Add `test/accrue_admin/components/at_risk_table_test.exs`, or expand `display_components_test.exs`, to cover GRP-02 mobile card/list behavior plus empty/loading/error/no-pagination states.
- [ ] Add `e2e/admin-group-contracts.spec.js`, or a narrow block in existing baseline/interactions specs, to cover group locator visibility, mobile/desktop inactive DOM, duplicate focus-target prevention, and selected/filter-active proof.
- [ ] Update `navigation_components_test.exs` if `DropdownMenu` changes from menu-button semantics to disclosure semantics; existing expectations currently assert `role="menu"`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator-stress scan of group hierarchy and obvious next action | GRP-01, GRP-03 | Automated tests can assert structure and visibility, but final hierarchy judgment needs a human pass against the rendered admin UI. | Open `/billing/dev/components`, inspect each group specimen at desktop and mobile widths, and verify identity, status, primary action, and recovery action are immediately findable. |
| Phase 191 handoff quality | GRP-01, GRP-04 | The handoff list is a planning artifact keyed to defect IDs/tags and needs review for scope correctness. | Confirm each deferred focus trap, focus restore, Escape, click-outside, scroll reachability, overlay position, LiveView patch focus, fixture gap, and microcopy item is assigned to Phase 191 rather than implemented in Phase 190. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify steps or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing test references.
- [ ] No watch-mode flags in verification commands.
- [ ] Per-task feedback latency stays below 30 seconds where possible.
- [ ] Set `nyquist_compliant: true` in frontmatter after Wave 0 gaps are closed and all tasks map to automated or justified manual checks.

**Approval:** pending
