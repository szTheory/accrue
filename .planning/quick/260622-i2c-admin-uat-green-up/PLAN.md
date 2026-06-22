---
quick_id: 260622-i2c
slug: admin-uat-green-up
date: 2026-06-22
---

# Green the accrue_admin Playwright browser UAT (pre-existing e2e spec-drift + 1 real responsive bug)

Main CI's only remaining red is the accrue_admin **Playwright browser UAT** (also folded into the
Release gate via the Phase 192 step). The doc-contract gate is already fixed (260622-h7h). The UAT
failures are **pre-existing e2e spec-drift** from the redesign arc (h72 webhooks selection-retry →
io6 customers → olr stat-strip → fql headers) that shipped without updating the Playwright specs
(every task ran only `mix test`, never the UAT) — PLUS one genuine responsive bug. fql did NOT
cause this; it fixed the `/Invoices/i` assertion.

Local UAT runs (config auto-boots `mix accrue_admin.e2e.server`; chromium installed). Iterate
locally — do NOT push-wait-CI. **Done = full admin UAT green locally on BOTH `chromium-desktop` and
`chromium-mobile`.**

## How to run locally (from accrue_admin/)
- Full suite: `npx playwright test` (both projects). Single spec: `npx playwright test e2e/<file> --project=chromium-desktop`.
- Kill stale servers between runs if needed: `pkill -f accrue_admin.e2e.server`. Port 4017.
- First boot compiles + migrates the test DB (~1-2 min). reuseExistingServer is on locally.

## Confirmed contracts the specs must align to (the redesign is intentional/correct)
- **Webhooks bulk replay is selection-driven** (h72): select rows via `[data-role="toggle-all"]`
  (or `[data-role="toggle-row"]`), THEN click `[data-role="bulk-action"]` (only renders when ≥1
  selected) → confirm via `[data-role="confirm-retry-selected"]` (NOT old `prepare-bulk-replay` /
  `confirm-bulk-replay`). Confirm panel is `data-role="bulk-replay-confirm"`. New confirm copy
  (`copy.ex` ~725): "Retry N webhook events? They failed every automatic retry — retrying runs them
  through processing again." (no "failed or dead webhook rows", no scope line). Webhooks h1 = "Webhooks".
- **Customers** has NO `status` filter (io6): honored params are `q`, `owner_type`,
  `has_default_payment_method`. Trigger the empty/recovery state via `?q=<no-match>` →
  `[data-role="empty-state"]` with "No records match these filters" + "Clear filters".
- **List pages use the stat strip** (olr): `.ax-stat-strip` `<dl>`, NOT `.ax-kpi-grid`/`.ax-kpi-card`
  (dashboard + recovery + detail pages KEEP `.ax-kpi-card`). New plain-noun h1s + rewritten
  subtitles (fql).
- **Selection/filter contracts** (from data_table.ex): `data-role` = `filter-form`, `clear-filters`,
  `bulk-action`, `toggle-all`, `toggle-row`, `empty-state`; the visible Apply button is gone (hidden
  submit kept).

## Work
1. **Run the full UAT locally; enumerate EVERY failing test** across all specs + both projects
   (known: `admin-page-flow-phase191.spec.js` :197/:307/:352; `phase7-uat.spec.js` webhooks bulk;
   plus ~6 more flagged — `admin-baseline`, `admin-interactions` focus-ring, `admin-motion-trace`,
   `dropdown-dismiss`, `admin-group-contracts` Phase-190 probe). Map each to its cause.
2. **Fix the spec-drift** by updating the assertions to the CORRECT new contracts above. Precise
   mapped edits:
   - `admin-page-flow-phase191.spec.js:307` + `phase7-uat.spec.js` webhooks block → selection-driven
     flow + new confirm copy (toggle-all → bulk-action → confirm-retry-selected).
   - `admin-page-flow-phase191.spec.js:352` → `/billing/customers?q=zzz-no-such-customer-xyz` (or any
     no-match `q`) instead of `?status=no-records`.
   - The ~6 others: run, read the failing assertion + page snapshot, update to the shipped DOM/copy.
3. **Fix the ONE real app bug** (not a spec edit): `admin-page-flow-phase191.spec.js:197` —
   `customer-detail` document overflows ~34-53px at 320px (long unbreakable customer name). Fix in
   `lib/accrue_admin/live/customer_live.ex` (+ app.css if needed): add `overflow-wrap:anywhere` /
   `min-width:0` / `word-break` on the page header (`ax-page-header` h1) and the customer-summary
   grid so `documentOverflow ≤ 1` at 320px. Do NOT loosen the helper (`phase191-page-flow-helpers.js`).
   If app.css changes → rebuild the committed bundle (`mix accrue_admin.assets.build`) + commit both.

## Guardrails
- Update specs to the CORRECT shipped contract — do NOT weaken/skip assertions just to force green
  (the clipping test is a real bug → fix the app). If a failing test reflects a genuine UI defect (not
  drift), fix the app, not the spec.
- Do NOT touch `examples/accrue_host/**` specs/tests or its mix.lock. accrue_admin e2e only.
- Don't touch StatusBadge, CSP, ROADMAP.md, `.planning/research/.cache/`.
- If app CSS/JS changes, rebuild + commit the priv/static bundle (assets_test md5).
- On `main`, non-worktree. Orchestrator commits docs; executor commits code.

## Verify (record in SUMMARY)
- `cd accrue_admin && npx playwright test` → **0 failures**, both projects, every spec.
- `mix compile --warnings-as-errors` clean; `mix test` still green (350/0 baseline) if app code changed.
- List exactly which specs were drift-updated vs which were real app fixes.
