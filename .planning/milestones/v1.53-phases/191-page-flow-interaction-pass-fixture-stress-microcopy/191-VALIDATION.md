---
phase: 191
slug: page-flow-interaction-pass-fixture-stress-microcopy
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-18
---

# Phase 191 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright 1.59.1 for browser/page-flow checks; ExUnit/Mix 1.19.5 for Elixir seed and fixture tests |
| **Config file** | `accrue_admin/playwright.config.js`, `accrue_admin/package.json`, `accrue_admin/mix.exs`, `examples/accrue_host/mix.exs` |
| **Quick run command** | `cd accrue_admin && npm run e2e:group-contracts` plus the focused Phase 191 spec once Wave 0 creates it |
| **Full suite command** | `cd accrue_admin && npm run e2e:a11y && npm run e2e:group-contracts && npm run e2e -- e2e/admin-interactions.spec.js && npm run e2e -- e2e/admin-page-flow-phase191.spec.js` plus touched Mix/host seed tests |
| **Estimated runtime** | Focused checks should stay under 60 seconds per Playwright test; full browser gates are wave/phase checks |

---

## Sampling Rate

- **After every task commit:** Run the most focused Mix or Playwright spec for touched files; after shared component or hook changes, also run `cd accrue_admin && npm run e2e:group-contracts`.
- **After every plan wave:** Run `cd accrue_admin && npm run e2e -- e2e/admin-page-flow-phase191.spec.js`, `npm run e2e:group-contracts`, touched a11y checks, and affected Mix tests.
- **Before `/gsd:verify-work`:** Run the full suite command, host seed idempotency tests, and any AX187 coverage audit command added by the plans.
- **Max feedback latency:** Keep task-level checks focused; defer the full 21-page/state/viewport/theme matrix to wave and phase gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 191-W0-01 | TBD | 0 | IXN-01, IXN-02, IXN-03, IXN-04, IXN-05, PAGE-01, PAGE-02, PAGE-03, PAGE-04, CPY-01, CPY-02, CPY-03 | T-191-01 / T-191-02 / T-191-03 | Browser regressions must prove overlays, focus, scroll, disconnected states, page-state cells, and microcopy before implementation claims pass. | e2e scaffold | `cd accrue_admin && node --check e2e/admin-page-flow-phase191.spec.js` | No - Wave 0 | pending |
| 191-W0-02 | TBD | 0 | PAGE-01, PAGE-02, PAGE-03, PAGE-04, SEED-01 | T-191-04 / T-191-05 | Fixture forcing must make every required page/state cell reachable without manual DB edits or stale privileged state. | e2e helper + source assertions | `cd accrue_admin && npm run e2e -- e2e/admin-page-flow-phase191.spec.js --grep @fixtures` | No - Wave 0 | pending |
| 191-W0-03 | TBD | 0 | SEED-01, SEED-02 | T-191-04 / T-191-05 | Seed expansion must be deterministic, idempotent, and one-click reachable from `examples/accrue_host`. | ExUnit | `cd examples/accrue_host && mix test test/seeds_idempotency_test.exs` | Partial | pending |
| 191-W0-04 | TBD | 0 | IXN-05 | T-191-06 | Every Phase 187 owner `191` defect must map to a regression assertion or explicit artifact reference using AX187 IDs or overlay tags. | source/audit | `cd accrue_admin && npm run e2e -- e2e/admin-page-flow-phase191.spec.js --grep @ax187` | No - Wave 0 | pending |
| 191-SHARED-01 | TBD | TBD | IXN-01, IXN-02, IXN-03, IXN-04 | T-191-01 / T-191-02 / T-191-03 | Modal, drawer, command-palette, dropdown, popover, toast, and mobile-nav behavior must preserve focus containment, restore trigger focus, avoid scrim/z-index regressions, and keep controls reachable. | e2e + component tests | `cd accrue_admin && npm run e2e:group-contracts && npm run e2e -- e2e/admin-page-flow-phase191.spec.js` | Partial | pending |
| 191-COPY-01 | TBD | TBD | CPY-01, CPY-02, CPY-03 | T-191-07 | Errors, empty states, permission-denied states, and destructive confirmations must be specific, recoverable, and use consistent Accrue vocabulary. | e2e DOM assertions | `cd accrue_admin && npm run e2e -- e2e/admin-page-flow-phase191.spec.js --grep @copy` | No - Wave 0 | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] Create `accrue_admin/e2e/admin-page-flow-phase191.spec.js`, or an equivalent Phase 191 spec, with AX187-tagged assertions for overlays, scroll, LiveView patch focus, disconnected/reconnecting states, page-state cells, copy, and fixture reachability.
- [ ] Add a fixture matrix helper that consumes `accrue_admin/e2e/baseline-manifest.js` `SURFACES` and the E2E seed payloads rather than creating a separate page inventory.
- [ ] Add E2E forcing helpers/endpoints for stable empty, loading, error, permission-denied, disconnected/reconnecting, null optional, boundary pagination, non-ASCII, and high-count cells.
- [ ] Extend `examples/accrue_host` seed idempotency coverage for Phase 191 records, preserving the existing keyed-insert contract.
- [ ] Add an AX187 coverage audit or equivalent assertions that map Phase 187 owner `191` defects to tests/artifact refs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator page-flow scan across the primary persona/JTBD | PAGE-01, PAGE-04, CPY-01, CPY-02, CPY-03 | Automated matrix checks can assert reachability and copy strings, but final operator usefulness needs one human pass through the rendered admin surface. | Walk the Phase 191 page matrix in light and dark at representative desktop and mobile widths; confirm the next useful action, recovery guidance, and destructive consequences are clear. |
| AX187 artifact review | IXN-05 | Coverage audit can prove references exist, but the artifact set should be reviewed to ensure the cited evidence addresses the corrected behavior, not only the old observation. | Review generated Phase 191 test output and AX187 mapping for each owner `191` row; confirm every high-priority defect is either fixed with a regression assertion or explicitly deferred with rationale. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify steps or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers the missing Phase 191 page-flow spec, fixture matrix helper, forced-state helpers, seed idempotency updates, and AX187 audit.
- [x] No watch-mode flags in verification commands.
- [x] Per-task feedback latency stays bounded by focused checks.
- [x] `nyquist_compliant` is true after the automated gate set passed and the coverage ledger was written.
- [x] Human UAT passed on 2026-06-19; user confirmed the UAT worked and approved moving beyond the checkpoint.

**Approval:** approved by human UAT on 2026-06-19. Signal: user reported "i did all the UAT and it worked so that passed we can move beyond the UAT now".

## Closeout Evidence

| Command | Result | Notes |
|---------|--------|-------|
| `node scripts/ci/verify_phase191_ax187_coverage.mjs` | pass | `178` owner-phase rows, `70/70` direct high-severity coverage, `108/108` medium coverage. |
| `cd accrue_admin && npm run e2e:phase191` | pass | `14 passed` on desktop/mobile. |
| `cd accrue_admin && npm run e2e:a11y` | pass | `2 passed`. |
| `cd accrue_admin && npm run e2e:group-contracts` | pass | `16 passed` after rerun without the build-lock collision. |
| `cd accrue_admin && mix test test/accrue_admin/copy_test.exs test/accrue_admin/components/app_shell_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/components/overlay_components_test.exs test/accrue_admin/e2e_fixtures_test.exs` | pass | `75 tests, 0 failures`. |
| `cd examples/accrue_host && mix test test/seeds_idempotency_test.exs test/accrue_host/phase191_seed_reachability_test.exs` | pass | 4 tests, 0 failures; host seed reachability/idempotency passed. |
| Human UAT checkpoint | pass | 2026-06-19: user confirmed all UAT worked and approved moving beyond UAT. |
