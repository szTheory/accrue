---
phase: 190
slug: navigation-data-display-meta-component-cohesion
status: approved
nyquist_compliant: true
wave_0_complete: true
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
| **Full suite command** | `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && mix test && npm run e2e:a11y && npm run e2e -- e2e/admin-baseline.spec.js && npm run e2e -- e2e/admin-interactions.spec.js && npm run e2e:visuals:png-only` |
| **Estimated runtime** | Quick checks: under 30 seconds expected. Full suite: project-dependent; run at wave and phase gates. |

---

## Sampling Rate

- **After every task commit:** Run the applicable changed-file ExUnit command from the per-task verification map. Once Plan 03 creates AtRiskTable coverage, include `test/accrue_admin/components/at_risk_table_test.exs` in the quick data-display set.
- **After every CSS-affecting task:** Run `cd accrue_admin && mix accrue_admin.assets.build` before browser checks so source CSS reaches `priv/static/accrue_admin.css`.
- **After every plan wave:** Run `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && mix test && npm run e2e:a11y && npm run e2e -- e2e/admin-baseline.spec.js`.
- **Before `/gsd:verify-work`:** Run the full suite command, including `e2e/admin-interactions.spec.js` and `e2e/admin-visuals.spec.js` through `npm run e2e:visuals:png-only`.
- **Max feedback latency:** Keep per-task feedback under 30 seconds where possible; defer full browser sweeps to wave and phase gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 190-01-01 | 190-01 | 0 | GRP-01 | T-190-01 / T-190-02 | Group contract slugs, proof IDs, state inventory, and Phase 191 handoff tags are scaffolded before implementation waves. | unit | `cd accrue_admin && mix test test/accrue_admin/dev/component_group_registry_test.exs` | No - Wave 0 | pending |
| 190-03-01 | 190-03 | 2 | GRP-02, GRP-04 | T-190-09 / T-190-11 / T-190-12 | DataTable pagination, filtered-empty, selected/filter-active state, and inactive responsive DOM behavior are verified with same-task TDD. | unit | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs` | Partial | pending |
| 190-03-02 | 190-03 | 2 | GRP-02 | T-190-10 / T-190-11 | AtRiskTable mobile card/list behavior plus empty/loading/error/no-pagination/has-pagination states are verified with same-task TDD. | unit | `cd accrue_admin && mix test test/accrue_admin/components/at_risk_table_test.exs` | No - Plan 03 creates or expands | pending |
| 190-03-03 | 190-03 | 2 | GRP-03 | T-190-13 | KPI/detail/timeline groups keep hierarchy and tokenized spacing without nested card traps. | unit + e2e | `cd accrue_admin && mix test test/accrue_admin/components/display_components_test.exs && npm run e2e:a11y` | Partial | pending |
| 190-04-02 | 190-04 | 3 | GRP-01, GRP-04 | T-190-15 / T-190-16 | DropdownMenu disclosure semantics, navigation current state, search active state, and flash/toast layer behavior are verified with same-task TDD. | unit + interaction e2e | `cd accrue_admin && mix test test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/components/global_search_test.exs && npm run e2e -- e2e/admin-interactions.spec.js` | Partial | pending |
| 190-05-01 | 190-05 | 4 | GRP-01, GRP-02, GRP-03, GRP-04 | T-190-19 / T-190-20 / T-190-23 | Browser probes assert group locators, responsive active DOM, pagination states, active state labels, and off-screen action reachability. | e2e | `cd accrue_admin && node --check e2e/admin-group-contracts.spec.js && npm run e2e -- e2e/admin-group-contracts.spec.js` | Yes | green |
| 190-05-02 | 190-05 | 4 | GRP-01, GRP-04 | T-190-19 / T-190-20 / T-190-23 | Representative live probes sample list/table, detail, recovery/KPI, overlay, and shell/nav/tabs routes without claiming Phase 191 behavior. | e2e | `cd accrue_admin && npm run e2e:a11y && npm run e2e -- e2e/admin-baseline.spec.js && npm run e2e -- e2e/admin-interactions.spec.js && npm run e2e:visuals:png-only` | Yes | green |
| 190-05-03 | 190-05 | 4 | GRP-01, GRP-04 | T-190-21 / T-190-22 | Phase 191 receives AX187- and overlay-tag keyed handoff while validation status stays tied to actual automated evidence. | source + docs | `node -e "...handoff token check..."` | Yes | green |

*Status: pending, green, red, flaky.*

---

## Wave 0 Scaffold Requirements and Same-Task TDD Rationale

- [x] Add `test/accrue_admin/dev/component_group_registry_test.exs`, or extend the existing registry tests, to cover Phase 187 group slugs, state inventory, proof IDs, and Phase 191 handoff tags for GRP-01.
- [x] Add `e2e/admin-group-contracts.spec.js` as the Wave 0 harness scaffold with source-level contract checks and reusable helper names. Full DOM probes run in Plan 05 after the kitchen and component roots exist.
- [x] Plan 03 intentionally owns AtRiskTable component tests with `tdd="true"` because the test file must lock the final assigns/API added in the same task: mobile cards, empty/loading/error, no-pagination, and has-pagination states. This is accepted as same-task TDD rather than Wave 0 pre-scaffolding, and Plan 03 Task 2 carries the required automated `mix test test/accrue_admin/components/at_risk_table_test.exs` gate.
- [x] Plan 04 intentionally owns DropdownMenu/navigation expectation changes with `tdd="true"` because the semantics change from overclaimed menu roles to native disclosure semantics in the same component task. This is accepted as same-task TDD rather than Wave 0 pre-scaffolding, and Plan 04 Task 2 carries the required automated `mix test test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/components/global_search_test.exs` gate.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator-stress scan of group hierarchy and obvious next action | GRP-01, GRP-03 | Automated tests can assert structure and visibility, but final hierarchy judgment needs a human pass against the rendered admin UI. | Open `/billing/dev/components`, inspect each group specimen at desktop and mobile widths, and verify identity, status, primary action, and recovery action are immediately findable. |
| Phase 191 handoff quality | GRP-01, GRP-04 | The handoff list is a planning artifact keyed to defect IDs/tags and needs review for scope correctness. | Confirm each deferred focus trap, focus restore, Escape, click-outside, scroll reachability, overlay position, LiveView patch focus, fixture gap, and microcopy item is assigned to Phase 191 rather than implemented in Phase 190. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify steps or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers registry and browser-harness scaffolds; Plan 03 and Plan 04 same-task TDD exceptions are mapped above with automated gates.
- [x] No watch-mode flags in verification commands.
- [x] Per-task feedback latency stays below 30 seconds where possible.
- [x] Set `nyquist_compliant: true` in frontmatter after Wave 0 gaps are closed and all tasks map to automated or justified manual checks.

## Phase 190-05 Command Evidence

Date: 2026-06-18.

| Command | Result | Notes |
|---------|--------|-------|
| `cd accrue_admin && node --check e2e/admin-group-contracts.spec.js` | pass | JavaScript syntax check passed after final selector/proof-root fixes. |
| `cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/component_group_registry_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/at_risk_table_test.exs test/accrue_admin/components/display_components_test.exs test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/components/global_search_test.exs` | pass | 72 tests, 0 failures. The run logged an existing Postgrex `too_many_connections` message, but tests completed green. |
| `bash scripts/ci/verify_package_docs.sh` | pass | Package docs verified for accrue, accrue_admin, and accrue_portal 1.4.0. |
| `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors` | pass | Compile completed with warnings treated as errors. |
| `cd accrue_admin && npm run e2e:a11y` | pass | 2 tests passed in the full browser gate. |
| `cd accrue_admin && npm run e2e -- e2e/admin-group-contracts.spec.js` | pass | 14 tests passed across desktop and mobile after proof-root selector stabilization. |
| `cd accrue_admin && npm run e2e -- e2e/admin-interactions.spec.js --timeout=60000 --workers=1` | pass | 12 tests passed across desktop and mobile. |
| `cd accrue_admin && npm run e2e:visuals:png-only -- --timeout=60000 --workers=1` | pass | 2 tests passed across desktop and mobile. |
| `cd accrue_admin && npm run e2e -- e2e/admin-baseline.spec.js --timeout=60000 --workers=1` | blocked | Standalone bounded retry printed `Running 2 tests using 1 worker` and produced no test result before manual interrupt; Playwright reported `2 did not run`. |
| `cd accrue_admin && npm run e2e:a11y && npm run e2e -- e2e/admin-group-contracts.spec.js && npm run e2e -- e2e/admin-baseline.spec.js && npm run e2e -- e2e/admin-interactions.spec.js && npm run e2e:visuals:png-only` | partial | Axe and group contracts passed, then the chain hung during `admin-baseline.spec.js`; interrupted to keep the command bounded. |

**Approval:** approved from Phase 190-06 baseline closeout evidence. `status: approved` was set only after the exact bounded baseline command, generated evidence parser, progress parser, PNG-count guard, and artifact dry-run passed.

## Phase 190-06 Baseline Closeout Evidence

Date: 2026-06-18.

| Check | Result | Evidence |
|-------|--------|----------|
| Stale generated baseline output removed | pass | Removed `accrue_admin/test-results/admin-baseline` before the final proof run. |
| Exact bounded baseline command | pass | `cd accrue_admin && npm run e2e -- e2e/admin-baseline.spec.js --timeout=60000 --workers=1`; 8 passed in 1.8m. Static baseline capture is split into admin-route and component-kitchen tests per project so each test stays under the 60s limit: desktop routes 22.0s, desktop kitchen 20.0s, mobile routes 39.0s, mobile kitchen 27.7s. |
| Desktop cells evidence | pass | `accrue_admin/test-results/admin-baseline/chromium-desktop/cells.json`; 10,528 rows, non-empty JSON array, 616 covered Phase 190 component-group rows with generated evidence refs. |
| Mobile cells evidence | pass | `accrue_admin/test-results/admin-baseline/chromium-mobile/cells.json`; 10,528 rows, non-empty JSON array, 616 covered Phase 190 component-group rows with generated evidence refs. |
| Desktop progress evidence | pass | `accrue_admin/test-results/admin-baseline/chromium-desktop/progress.ndjson`; 95 rows, one `suite-complete`, zero `stage-error`. |
| Mobile progress evidence | pass | `accrue_admin/test-results/admin-baseline/chromium-mobile/progress.ndjson`; 95 rows, one `suite-complete`, zero `stage-error`. |
| Coverage row parser | pass | Parser rejected empty cells, invalid `coverage_status`, covered rows without refs, and gap/n/a rows without reasons; output: `baseline evidence ok`. |
| PNG duplication guard | pass | 98 generated PNGs under `accrue_admin/test-results/admin-baseline`, below the 1000-file guard. |
| Artifact generator dry-run | pass | `cd accrue_admin && npm run baseline:artifacts -- --dry-run`; exit 0 with `cells: 21056`, `defects: 625`, `evidence: 103`, `command_statuses: 0`, `harness_failures: 1`. The remaining harness-failure count is the existing artifact-generator command-status input notice, not a baseline progress `stage-error`. |

### Prior Failed Closeout Attempts

| Attempt | Result | Progress Evidence |
|---------|--------|-------------------|
| Initial exact bounded baseline command after route grouping | failed | Mobile timed out on `/billing/dev/components` during targeted breakpoint capture; `accrue_admin/test-results/admin-baseline/chromium-mobile/progress.ndjson` recorded `stage-error` before the generated directory was removed for the final proof run. |
| Exact bounded baseline command after viewport-only targeted screenshots | failed | Mobile reached `targeted-1440` for `/billing/dev/components` but still exceeded 60 seconds; progress recorded `stage-error` before the generated directory was removed for the final proof run. |
| Exact bounded baseline command after targeted fan-out scoping | failed | Mobile wrote `suite-complete` but the single static-baseline test still exceeded Playwright's 60s per-test timeout on a slower rerun; progress recorded 64.6s before the generated directory was removed for the final split-test proof run. |

The failed attempts did not approve validation. They drove the Phase 190-06 harness fixes that limit targeted breakpoint fan-out to Phase 190 component-group rows, preserve canonical capture for all selected manifest surfaces, and split the static baseline into admin-route and component-kitchen tests so the exact verifier command has stable per-test timeout margin.
