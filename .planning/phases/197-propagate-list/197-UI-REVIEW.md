---
phase: 197-propagate-list
reviewed: 2026-06-28
remediated: 2026-06-28
remediation_commit: 8e174eb9
status: passed_with_non_blocking_warning
baseline: .planning/phases/197-propagate-list/197-UI-SPEC.md
screenshots: not_captured
overall_score: 23/24
scores:
  copywriting: 4
  visuals: 4
  color: 3
  typography: 4
  spacing: 4
  experience_design: 4
---

# Phase 197 - UI Review

**Audited:** 2026-06-28  
**Baseline:** `197-UI-SPEC.md`  
**Screenshots:** not captured. No standard app root returned 200 at `localhost:3000`, `localhost:5173`, or `localhost:8080` during the hook; `8080` returned a redirect. This review relies on source inspection plus the existing green Phase 197 Playwright evidence.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Copy drift from the initial review was resolved by `8e174eb9`; rendered descriptions and Webhooks cancel copy now use copy helpers. |
| 2. Visuals | 4/4 | All eight pages use the PageHeader/DataTable/FilterChipBar composition and the browser contract verifies desktop/mobile list rendering. |
| 3. Color | 3/4 | Semantic `ax-*` color usage is intact, but the target LiveViews repeat hardcoded fallback hex values outside the token file. |
| 4. Typography | 4/4 | Page titles flow through one `.ax-display` h1 and table/card text stays in Body/Label/Heading roles. |
| 5. Spacing | 4/4 | No Phase 197 inline spacing literals or arbitrary px/rem values found; pages rely on component classes and `--ax-space-*` tokens. |
| 6. Experience Design | 4/4 | Default lenses, chips/counts/clear-all, four states, mobile cards, and Webhooks bulk replay are backed by focused tests and browser smoke. |

**Overall: 23/24**

---

## Remaining Priority Fixes

1. **Replace repeated brand fallback hex literals with a shared fallback/token path** - Color remains visually consistent, but token ownership is weakened across all eight target pages - Use a shared admin default brand helper or token-backed fallback instead of repeating `#5D79F6` / `#FAFBFC`.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

**RESOLVED by `8e174eb9`:** Events and Connect now render the locked Phase 197 list description helpers. `EventsLive` renders `Copy.events_list_subtitle()` (`accrue_admin/lib/accrue_admin/live/events_live.ex:120-122`), and `ConnectAccountsLive` renders `Copy.connect_accounts_list_subtitle()` (`accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex:101-103`). The updated LiveView/copy tests assert those helpers (`accrue_admin/test/accrue_admin/live/events_live_test.exs:92`, `accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs:68`, `accrue_admin/test/accrue_admin/copy_test.exs:280`, `accrue_admin/test/accrue_admin/copy_test.exs:297`).

**RESOLVED by `8e174eb9`:** `WebhooksLive` no longer renders the bulk replay cancel label inline. The confirmation button now renders `Copy.webhooks_retry_cancel_label()` (`accrue_admin/lib/accrue_admin/live/webhooks_live.ex:227-233`), the helper exists in `AccrueAdmin.Copy` (`accrue_admin/lib/accrue_admin/copy.ex:871`), and copy/LiveView tests assert it (`accrue_admin/test/accrue_admin/copy_test.exs:130`, `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs:237`).

**Pass evidence:** All eight list descriptions now render the Phase 197 list subtitle helpers directly, and the copy tests assert the expected JTBD headings, descriptions, state copy, labels, and result labels for all eight pages (`accrue_admin/test/accrue_admin/copy_test.exs:172-320`). Empty-state copy matches the four-state contract, including queue-empty distinctions for narrowed defaults (`197-UI-SPEC.md:170-181`). Post-remediation verification recorded the focused copy/Events/Connect/Webhooks command as 32 tests, 0 failures; the full Phase 197 LiveView gate as 63 tests, 0 failures; the query/copy/component gate as 64 tests, 0 failures; and `mix compile --warnings-as-errors` as passed.

### Pillar 2: Visuals (4/4)

**Pass evidence:** Every target page adopts the required PageHeader/DataTable/FilterChipBar structure: Customers (`accrue_admin/lib/accrue_admin/live/customers_live.ex:98-173`), Invoices (`accrue_admin/lib/accrue_admin/live/invoices_live.ex:95-175`), Payments (`accrue_admin/lib/accrue_admin/live/charges_live.ex:95-175`), Coupons (`accrue_admin/lib/accrue_admin/live/coupons_live.ex:102-188`), Promotion codes (`accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex:94-180`), Webhooks (`accrue_admin/lib/accrue_admin/live/webhooks_live.ex:169-285`), Events (`accrue_admin/lib/accrue_admin/live/events_live.ex:113-205`), and Connect (`accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex:94-180`).

**Pass evidence:** `PageHeader` owns the visual orientation shell and exactly one content h1 (`accrue_admin/lib/accrue_admin/components/page_header.ex:28-56`). The Phase 197 browser spec verifies exactly one h1, PageHeader markers, filter toolbar markers, list markers, chip rows, result counts, and clear-all visibility where applicable (`accrue_admin/e2e/admin-spec-list-phase197.spec.js:171-217`).

**Pass evidence:** Desktop and mobile surfaces are both exercised: the Playwright contract checks the desktop table shell, hidden mobile card list, mobile card list, hidden desktop table, and no horizontal clipping (`accrue_admin/e2e/admin-spec-list-phase197.spec.js:220-230`). Verification recorded `npm run e2e:phase197` as 15 passed / 15 skipped with no failures (`197-VERIFICATION.md:28-36`, `197-VERIFICATION.md:52-55`).

### Pillar 3: Color (3/4)

**WARNING:** The eight target LiveViews repeat hardcoded fallback brand colors (`#5D79F6`, `#FAFBFC`) 16 times (`accrue_admin/lib/accrue_admin/live/customers_live.ex:430`, `accrue_admin/lib/accrue_admin/live/invoices_live.ex:487`, `accrue_admin/lib/accrue_admin/live/charges_live.ex:506`, `accrue_admin/lib/accrue_admin/live/coupons_live.ex:456`, `accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex:471`, `accrue_admin/lib/accrue_admin/live/webhooks_live.ex:590`, `accrue_admin/lib/accrue_admin/live/events_live.ex:480`, `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex:559`). The values match the approved accent/paper references, but the UI spec identifies `theme.css` / `--ax-*` as the implementation SSOT (`197-UI-SPEC.md:99-108`). This is a warning, not a visual blocker.

**Pass evidence:** Phase 197 markup uses semantic `ax-*` classes rather than ad hoc Tailwind color classes. Webhooks uses the primary button only for the existing retry action (`accrue_admin/lib/accrue_admin/live/webhooks_live.ex:219-226`), matching the accent reservation rule (`197-UI-SPEC.md:108`). Theme tokens define the semantic color layer and focus/accent mixes centrally (`accrue_admin/assets/css/theme.css:137-178`).

### Pillar 4: Typography (4/4)

**Pass evidence:** The spec limits newly touched hierarchy to Body, Label, Heading, and Display roles (`197-UI-SPEC.md:80-95`). The implementation renders page titles through `PageHeader` as `.ax-display` (`accrue_admin/lib/accrue_admin/components/page_header.ex:36-40`), while DataTable headers and card fields use `.ax-label`, `.ax-body`, and `.ax-heading` (`accrue_admin/lib/accrue_admin/components/data_table.ex:294-296`, `accrue_admin/lib/accrue_admin/components/data_table.ex:415-436`).

**Pass evidence:** No extra h2/h3 hierarchy or Tailwind font utility drift was found in the eight target LiveViews/components. Secondary IDs/emails stay visually secondary with muted/code styling, e.g. customer email and processor IDs (`accrue_admin/lib/accrue_admin/live/customers_live.ex:225`, `accrue_admin/lib/accrue_admin/live/coupons_live.ex:231`, `accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex:235`), which matches the spec's "monospace reserved for secondary IDs" rule.

### Pillar 5: Spacing (4/4)

**Pass evidence:** The declared spacing scale is `--ax-space-2xs` through `--ax-space-3xl` with the required 4px base and allowed 2px micro rung (`accrue_admin/assets/css/theme.css:25-33`; `197-UI-SPEC.md:55-76`). Grep found no inline `style=`, `margin:`, `padding:`, `gap:`, arbitrary `px`, or arbitrary `rem` literals in the eight target LiveViews plus `PageHeader`, `FilterChipBar`, and `DataTable`.

**Pass evidence:** The pages rely on existing component classes for page rhythm, toolbar placement, list status, dense table rows, and mobile cards. The Phase 197 browser spec verifies no horizontal clipping on desktop and mobile (`accrue_admin/e2e/admin-spec-list-phase197.spec.js:220-230`).

### Pillar 6: Experience Design (4/4)

**Pass evidence:** Page-owned URL/default state is implemented for narrowed defaults and owner-scope clear paths. Examples: Invoices defaults to `status=open,uncollectible` and merges defaults through `DataTableNav` (`accrue_admin/lib/accrue_admin/live/invoices_live.ex:24`, `accrue_admin/lib/accrue_admin/live/invoices_live.ex:70-71`); Payments defaults to failed charges (`accrue_admin/lib/accrue_admin/live/charges_live.ex:24`, `accrue_admin/lib/accrue_admin/live/charges_live.ex:70-71`); Webhooks defaults to failed/dead (`accrue_admin/lib/accrue_admin/live/webhooks_live.ex:22`, `accrue_admin/lib/accrue_admin/live/webhooks_live.ex:65-66`); Connect defaults to `needs_attention=true` (`accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex:69-70`).

**Pass evidence:** High-risk query semantics are real data behavior. Webhooks safely decodes comma-separated statuses with an allowlist (`accrue_admin/lib/accrue_admin/queries/webhooks.ex:173-186`) and filters status lists (`accrue_admin/lib/accrue_admin/queries/webhooks.ex:154-164`). Connect implements `needs_attention` as an OR predicate (`accrue_admin/lib/accrue_admin/queries/connect_accounts.ex:133-144`). Payments owner scope is applied through the joined customer relation (`accrue_admin/lib/accrue_admin/queries/charges.ex:127-135`).

**Pass evidence:** The four-state contract is represented in DataTable with `data-ax-list`, `data-ax-state`, `data-ax-empty-reason`, and `aria-busy` (`accrue_admin/lib/accrue_admin/components/data_table.ex:240-249`). Loading skeletons expose one status label and hide decorative cells from assistive tech (`accrue_admin/lib/accrue_admin/components/data_table.ex:286-327`). Filtered empty states expose clear filters only when filters are active (`accrue_admin/lib/accrue_admin/components/data_table.ex:329-341`).

**Pass evidence:** Webhooks bulk replay remains page-owned and scoped. The selection message opens pending confirmation, cancel clears it, confirmation scopes selected IDs, and failures/successes flash through existing copy paths (`accrue_admin/lib/accrue_admin/live/webhooks_live.ex:87-134`). The browser spec covers the bulk queue confirmation flow (`accrue_admin/e2e/admin-spec-list-phase197.spec.js:330-347`).

**Non-blocking:** The known Dashboard `$42.50` broad-suite failure remains outside Phase 197 ownership and is documented as not blocking (`197-VERIFICATION.md:130-140`).

---

## Files Audited

- `.planning/phases/197-propagate-list/197-UI-SPEC.md`
- `.planning/phases/197-propagate-list/197-CONTEXT.md`
- `.planning/phases/197-propagate-list/197-VERIFICATION.md`
- `.planning/phases/197-propagate-list/197-01-PLAN.md` through `197-07-PLAN.md`
- `.planning/phases/197-propagate-list/197-01-SUMMARY.md` through `197-07-SUMMARY.md`
- `accrue_admin/lib/accrue_admin/live/customers_live.ex`
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex`
- `accrue_admin/lib/accrue_admin/live/charges_live.ex`
- `accrue_admin/lib/accrue_admin/live/coupons_live.ex`
- `accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex`
- `accrue_admin/lib/accrue_admin/live/webhooks_live.ex`
- `accrue_admin/lib/accrue_admin/live/events_live.ex`
- `accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex`
- `accrue_admin/lib/accrue_admin/components/page_header.ex`
- `accrue_admin/lib/accrue_admin/components/data_table.ex`
- `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex`
- `accrue_admin/lib/accrue_admin/components/stat_strip.ex`
- `accrue_admin/lib/accrue_admin/components/breadcrumbs.ex`
- `accrue_admin/lib/accrue_admin/copy.ex`
- `accrue_admin/lib/accrue_admin/copy/invoice.ex`
- `accrue_admin/lib/accrue_admin/copy/coupon.ex`
- `accrue_admin/lib/accrue_admin/copy/promotion_code.ex`
- `accrue_admin/lib/accrue_admin/copy/connect.ex`
- `accrue_admin/lib/accrue_admin/copy/billing_event.ex`
- `accrue_admin/lib/accrue_admin/queries/webhooks.ex`
- `accrue_admin/lib/accrue_admin/queries/connect_accounts.ex`
- `accrue_admin/lib/accrue_admin/queries/charges.ex`
- `accrue_admin/test/support/list_contracts.ex`
- `accrue_admin/test/accrue_admin/copy_test.exs`
- `accrue_admin/test/accrue_admin/live/customers_live_test.exs`
- `accrue_admin/test/accrue_admin/live/invoices_live_test.exs`
- `accrue_admin/test/accrue_admin/live/charges_live_test.exs`
- `accrue_admin/test/accrue_admin/live/coupons_live_test.exs`
- `accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs`
- `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs`
- `accrue_admin/test/accrue_admin/live/events_live_test.exs`
- `accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs`
- `accrue_admin/test/accrue_admin/components/page_header_test.exs`
- `accrue_admin/test/accrue_admin/components/data_table_test.exs`
- `accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs`
- `accrue_admin/test/accrue_admin/queries/query_modules_test.exs`
- `accrue_admin/e2e/admin-spec-list-phase197.spec.js`
- `accrue_admin/e2e/phase191-page-flow-helpers.js`
- `accrue_admin/package.json`
- `accrue_admin/assets/css/theme.css`
