---
phase: 240-shared-system-and-real-billing-exemplar
reviewed: 2026-10-09T23:15:17Z
depth: standard
files_reviewed: 33
files_reviewed_list:
  - .github/workflows/accrue_admin_browser.yml
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/js/hooks/accrue_theme.js
  - accrue_admin/assets/js/hooks/connection_state.js
  - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
  - accrue_admin/e2e/admin-page-flow-phase191.spec.js
  - accrue_admin/e2e/admin-spec-detail-phase198.spec.js
  - accrue_admin/e2e/admin-spec-list-phase196.spec.js
  - accrue_admin/e2e/visual-baseline-set.cjs
  - accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex
  - accrue_admin/lib/accrue_admin/copy/invoice.ex
  - accrue_admin/lib/accrue_admin/live/charge_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/invoices_live.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/accrue_admin.js
  - accrue_admin/test/accrue_admin/components/theme_picker_test.exs
  - accrue_admin/test/accrue_admin/copy_test.exs
  - accrue_admin/test/accrue_admin/e2e_fixtures_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
  - accrue_admin/test/accrue_admin/theme_test.exs
  - accrue_admin/test/js/command_palette_test.mjs
  - accrue_admin/test/js/focus_trap_test.mjs
  - accrue_admin/test/js/visual_baseline_set_test.mjs
  - accrue_admin/test/support/e2e_fixtures.ex
  - accrue_admin/test/support/e2e_plug.ex
  - examples/accrue_host/e2e/phase237-admin-billing.spec.js
  - examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js
  - examples/accrue_host/test/accrue_host_web/phase239_route_coverage_contract_test.exs
  - scripts/ci/verify_package_docs.sh
  - scripts/ci/verify_phase240_evidence.mjs
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 240: Code Review Report

**Reviewed:** 2026-10-09T23:15:17Z  
**Depth:** standard  
**Files Reviewed:** 33  
**Status:** issues_found

## Summary

Reviewed the scoped Admin source, browser owners, test support, and CI evidence guards. I found three WARNING-level deviations from the approved Phase 240 interaction and design contract. No critical security or data-integrity defect was confirmed. Existing Phase 234 acceptance failures and Phase 241 subscription queue changes are outside these findings.

## Warnings

### WR-01: Invoice review dismissal does not explain its non-mutating action

**Classification:** WARNING  
**File:** `accrue_admin/lib/accrue_admin/copy/invoice.ex:184`  
**Issue:** The invoice action review footer renders this copy for the dismissal button (`invoice_live.ex:538`). The Phase 240 contract requires `Back to invoice` so operators can distinguish safely returning from canceling a billing action. The current generic label is ambiguous at a consequential review step.
**Fix:** Change `invoice_confirm_cancel/0` to return `"Back to invoice"` and update its copy assertion.

### WR-02: Invoice collection page repeats filter and result hierarchy

**Classification:** WARNING  
**File:** `accrue_admin/lib/accrue_admin/live/invoices_live.ex:120-129`  
**Issue:** The page renders the filter toolbar in `PageHeader`, then independently renders a `FilterChipBar` as `list_status` at lines 184–192 with a second invoice-view lens, result count, and clear-filters link. The mounted 320px collection view therefore presents repeated filter and result context before the records, contrary to the contract's single coherent collection lens and constraints hierarchy.
**Fix:** Consolidate the lens, active constraints, result count, and clear action into one hierarchy, keeping all active filter state and actions available without a second redundant result band.

### WR-03: Shared health snapshot uses unapproved typography weights

**Classification:** WARNING  
**File:** `accrue_admin/assets/css/app.css:3616-3618`  
**Issue:** The shared health snapshot assigns `font-weight: 900` to emphasized values, and its header assigns `750` and `900` at lines 3645–3648 and 3656–3658. Phase 240's approved Admin type contract permits 400 and 600 only; these overrides also bypass the semantic role bundles. The visible shared header therefore departs from the agreed type system.
**Fix:** Remove these weight overrides and use the existing 400/600 `--ax-type-*` semantic roles for the snapshot values, status, and link.

---

_Reviewed: 2026-10-09T23:15:17Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
