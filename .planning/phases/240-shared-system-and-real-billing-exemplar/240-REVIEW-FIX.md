---
phase: 240
fixed_at: 2026-10-09T23:33:13Z
review_path: .planning/phases/240-shared-system-and-real-billing-exemplar/240-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 240: Code Review Fix Report

**Fixed at:** 2026-10-09T23:33:13Z  
**Source review:** `.planning/phases/240-shared-system-and-real-billing-exemplar/240-REVIEW.md`  
**Iteration:** 1

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### WR-01: Invoice review dismissal does not explain its non-mutating action

**Files modified:** `accrue_admin/lib/accrue_admin/copy.ex`, `accrue_admin/lib/accrue_admin/copy/invoice.ex`, `accrue_admin/lib/accrue_admin/live/invoice_live.ex`, `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`, `examples/accrue_host/e2e/phase237-admin-billing.spec.js`  
**Commit:** `5623c421`  
**Applied fix:** The staged invoice action review now says “Back to invoice.” Draft line-item removal retains the separate “Cancel” label. The invoice owner test and mounted browser assertion check the safe dismissal wording; the action-specific submit control and audit/legal copy remain intact.

### WR-02: Invoice collection page repeats filter and result hierarchy

**Files modified:** `accrue_admin/lib/accrue_admin/components/data_table.ex`, `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex`, `accrue_admin/lib/accrue_admin/live/invoices_live.ex`, `accrue_admin/test/accrue_admin/live/invoices_live_test.exs`, `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`  
**Commit:** `25af07fa`  
**Applied fix:** Invoice filters, lens, active constraints, result count, and the single clear-all action now share one list-context hierarchy immediately above the records. The redundant footer count and duplicate clear controls are suppressed for invoices. The existing `Needs collection`, `All invoices`, filter removal links, URL scope, and query behavior are retained. `accrue_admin/priv/static/accrue_admin.css` was rebuilt in this commit and includes the shared WR-03 stylesheet changes as well.

### WR-03: Shared health snapshot uses unapproved typography weights

**Files modified:** `accrue_admin/assets/css/app.css`, `examples/accrue_host/e2e/phase237-admin-billing.spec.js`  
**Commit:** `b0336989`  
**Applied fix:** Shared health snapshot and lifecycle summary weights now use the approved 400/600 roles. The lifecycle summary and its copy use incumbent spacing tokens instead of zero and half-pixel separation. The approved six type sizes and intentional 2px dense / 1px structural exceptions remain unchanged. A mounted subscription assertion checks computed spacing and weights.

## Verification

**Verification ran in the main checkout.**

- **RED, ExUnit owners before production edits:** the focused invoice owner command executed 37 tests and produced 3 assertion failures on the new dismissal/filter-hierarchy expectations.
- **RED, mounted health presentation before package rebuild:** Phase 237’s mounted Chromium assertion failed with computed lifecycle `row-gap: 0px`.
- **GREEN, ExUnit owners:** `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/invoices_live_test.exs` — 37 tests, 0 failures.
- **Package assets:** `cd accrue_admin && mix accrue_admin.assets.build` — completed successfully.
- **Host asset compilation:** `cd examples/accrue_host && MIX_ENV=test mix compile --warnings-as-errors` — completed successfully.
- **Mounted confirmation:** `cd examples/accrue_host && CI=1 npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop --reporter=junit` — 1 test, 0 failures, 0 skipped, 0 errors. This checked the invoice review wording, subscription spacing and typography, and package / compiled / served asset identity. Captures were directed to a temporary location so the pre-existing Phase 237 captures were preserved.
- **JavaScript syntax:** `node --check examples/accrue_host/e2e/phase237-admin-billing.spec.js` — passed.

The project’s ExUnit command used its native formatter; no ExUnit JUnit formatter was available. Its output was not converted into a synthetic report or classifier verdict.

## Deferred scope

Global invoice queue workspace consolidation and subscription invoice destination changes remain with Phase 241 authority. They were not changed in this corrective batch.

---

_Fixed: 2026-10-09T23:33:13Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
