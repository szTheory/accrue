# Phase 35 — Research

**Status:** Complete (planning pass).

## Findings

- **Copy SSOT:** Tier A host contract already centralizes operator strings in `accrue_admin/lib/accrue_admin/copy.ex` (`AccrueAdmin.Copy`); `DashboardLive` still embeds many English literals — migrate them behind `Copy` functions named `dashboard_*` / `dashboard_kpi_*` for grep-friendly ownership.
- **Tests:** `dashboard_live_test.exs`, `auth_hook_test.exs`, `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs`, `accrue_admin/e2e/phase7-uat.spec.js`, `examples/accrue_host/e2e/phase13-canonical-demo.spec.js`, and `scripts/ci/accrue_host_browser_smoke.cjs` all hardcode the dashboard headline — converge ExUnit on `Copy` and JS on one `e2e/support/copy_dashboard.js` re-exported by relative `require`.
- **Tokens:** Dashboard HEEx already uses semantic `ax-*` classes from Phase 20/34; any new KPI chrome must extend `app.css` with design-token variables (no raw `#RRGGBB` in templates). `default_brand/0` accent hex remains host-injected data, not a new exception.

## Validation Architecture

- **Dimension 1–3 (unit / integration):** `mix test` on touched `accrue_admin` and `accrue_host` test files with `--warnings-as-errors`.
- **Dimension 4 (E2E):** Host Playwright `phase13-canonical-demo.spec.js` billing segment; `accrue_admin` package `e2e/phase7-uat.spec.js` if still run in CI matrix.
- **Dimension 5 (smoke):** `scripts/ci/accrue_host_browser_smoke.cjs` must stay green after string centralization.
- **Dimension 8:** Every new `Copy` function has a matching consumer test assertion or Playwright import path documented in plan acceptance criteria.
