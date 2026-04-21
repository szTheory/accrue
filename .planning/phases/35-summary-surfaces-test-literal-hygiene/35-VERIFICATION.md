---
phase: 35
status: passed
verified: 2026-04-21
---

# Phase 35 — Verification

## Must-haves (from plans)

| Criterion | Evidence |
|-----------|----------|
| Dashboard HEEx contains no hard-coded operator English for chrome, KPI labels, meta, aria-labels, timeline labels, or static delta suffixes | `grep -E "Billing health|Local billing projections|Total local customer records" accrue_admin/lib/accrue_admin/live/dashboard_live.ex` → no matches; strings live in `AccrueAdmin.Copy`. |
| `AccrueAdmin.Copy` owns canonical strings | `dashboard_*` functions in `accrue_admin/lib/accrue_admin/copy.ex`; `grep -c "def dashboard_"` ≥ 18. |
| No bare duplicate of `dashboard_display_headline` outside `copy.ex` and `copy_dashboard.js` in tests/CI | Headline literal removed from listed tests/specs; grep checks from plan 35-02 satisfied. |
| ExUnit dashboard coverage uses `Copy` for static operator strings | `dashboard_live_test.exs`, `auth_hook_test.exs` use `alias AccrueAdmin.Copy` and `Copy.dashboard_*()`. |

## Automated checks run

- `cd accrue_admin && mix compile --warnings-as-errors`
- `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/live/auth_hook_test.exs --warnings-as-errors`
- `cd examples/accrue_host && mix test test/accrue_host_web/admin_mount_test.exs --warnings-as-errors`
- `cd examples/accrue_host && npx playwright test e2e/phase13-canonical-demo.spec.js --project=chromium-desktop`

## Requirements traceability

- **OPS-04:** Layout remains `ax-*` token classes; no new ad-hoc styling in HEEx.
- **OPS-05:** Operator-visible dashboard strings route through `AccrueAdmin.Copy` and JS mirror for asserted Playwright strings.

## Gaps

None identified for phase scope.

## Human verification

Not required for this phase (automated coverage sufficient for copy wiring).
