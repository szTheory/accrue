# Phase 200 Storybook Coverage

**Status:** pass

## Rendered Storybook Accessibility

- Evidence: `.planning/phases/200-idempotent-verification-sign-off/evidence/storybook-a11y.json`
- Dynamic story URLs discovered: 8
- Rendered light/dark rows: 16
- Themes observed: dark, light
- Failed rendered rows: 0

## Family and Group Coverage

- Dynamic family/registry coverage: passed through `mix test test/accrue_admin/dev/storybook_coverage_test.exs test/accrue_admin/dev/storybook_asset_test.exs test/accrue_admin/theme_test.exs`.
- Storybook asset delivery and theme parity: passed through `bash scripts/ci/verify_phase200_admin_guardrails.sh`.
- /dev/components drift status: passed through the Phase 190 group contract probe.

- `page-header-actions-breadcrumbs`: covered by the Phase 190 group contract probe in `bash scripts/ci/verify_phase200_admin_guardrails.sh`
- `toolbar-search-filter-sort`: covered by the Phase 190 group contract probe in `bash scripts/ci/verify_phase200_admin_guardrails.sh`
- `table-empty-loading-error-pagination`: covered by the Phase 190 group contract probe in `bash scripts/ci/verify_phase200_admin_guardrails.sh`
- `kpi-chart-table`: covered by the Phase 190 group contract probe in `bash scripts/ci/verify_phase200_admin_guardrails.sh`
- `detail-header-metadata-actions`: covered by the Phase 190 group contract probe in `bash scripts/ci/verify_phase200_admin_guardrails.sh`
- `modal-confirm`: covered by the Phase 190 group contract probe in `bash scripts/ci/verify_phase200_admin_guardrails.sh`
- `drawer-form`: covered by the Phase 190 group contract probe in `bash scripts/ci/verify_phase200_admin_guardrails.sh`
- `tabs-subviews`: covered by the Phase 190 group contract probe in `bash scripts/ci/verify_phase200_admin_guardrails.sh`

## Canonical Artifacts

- baseline.union.cells.json
- final.cells.json
- scorecard.delta.json
- regressions.ndjson
- artifacts.manifest.json
- judge.findings.json
- 200-SCORECARD.md
- 200-STORYBOOK-COVERAGE.md
- 200-VERIFICATION.md
- 200-SIGN-OFF.md

Structured evidence remains canonical; this report summarizes the deterministic Storybook and component coverage gates.
