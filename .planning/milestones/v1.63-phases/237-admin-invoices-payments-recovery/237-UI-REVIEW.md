# Phase 237 — UI Review

**Audited:** 2026-10-08 (UTC)
**Baseline:** Approved `237-UI-SPEC.md`
**Screenshots:** fresh audit CLI recapture failed for desktop/mobile/tablet against `http://localhost:8080`; reviewed the regenerated Phase 237 captures instead. Final Playwright recapture binds all 9 source hashes and all 3 screenshot hashes/byte counts to source commit `b24092fa`; the built and served stylesheet hashes match. Captures show 320px invoice collection, 1280px invoice review, and 320px dark recovery.
**Interaction captures:** off (workflow.ui_interaction_capture is false)
**Served browser evidence:** Phase 237 Playwright passed 1/1 at `b24092fa`; all three recovery window links are asserted within the 320px viewport with no tab-row horizontal scroll. The closeout semantic type-role correction also passed the Phase 234 subscription-detail readability and asset-provenance journey.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Contract state/action copy is present; the reviewed currency code appears lowercase as `(usd)`. |
| 2. Visuals | 3/4 | The invoice hierarchy and all mobile recovery windows are clear; the collection view repeats reset-like controls. |
| 3. Color | 3/4 | Semantic light/dark treatments are shown; fallback brand hex values remain and control contrast checks are incomplete. |
| 4. Typography | 3/4 | Route content has a clear hierarchy; the inherited global-search trigger uses 900/750 weights. |
| 5. Spacing | 3/4 | Mobile filter and recovery-tab spacing now use the 4px grid; the shared invoice/charge action band retains 1px/2px values. |
| 6. Experience Design | 4/4 | Responsive bounds, focus restoration, keyboard review, scope, and recovery return context have passing browser assertions. |

**Overall: 19/24**

---

## Top 3 Priority Fixes

1. **Align the invoice/charge action band with the spacing scale** — Its shared CSS still uses 1px and 2px gaps and button padding, contrary to the contract's 4px grid. Use spacing tokens in multiples of 4px.
2. **Use semantic roles for default brand colors** — Invoice, charge, and recovery LiveViews still specify fixed `#5D79F6`/`#FAFBFC` fallback colors. Derive defaults from the active Admin semantic palette.
3. **Align shared search trigger weights with the typography contract** — The trigger and its text use 900/750 weights; use declared 400/600 roles or document a deliberate shared-shell exception.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **Fixed / positive:** `invoices_live.ex:254-275` preserves lifecycle status, adds overdue only for open invoices with a known past due date, shows a formatted date or “Due date unavailable,” and provides “View invoice” with the record identity in its accessible name. The current 320px capture shows these facts.
- **Fixed / positive:** `invoice_live.ex:523-533` names staged confirmation “Pay invoice.” The capture shows the exact target, action consequence, and reviewed amount/currency before the action.
- **Fixed / positive:** `copy/dunning.ex:51-54` uses the approved recovery read-error copy: “We couldn't load this billing data. Refresh the page or return to the list and try again.”
- **WARNING:** The review displays `$10.00 (usd)` with lowercase ISO code. Preserve consistent currency-code casing, particularly when the currency symbol is ambiguous.

### Pillar 2: Visuals (3/4)

- **Positive evidence:** The invoice page retains the intended headline and summary hierarchy. The mobile card shows invoice/customer identity, lifecycle, due-date fact, exact balance, and its action link.
- **Fixed / positive:** The 320px recovery capture shows “7 days UTC,” “30 days UTC,” and “90 days UTC” as three fully visible buttons. The browser spec checks every link's bounds and no tab-row scroll (`phase237-admin-billing.spec.js:192-205`). The prior clipped-tab finding is resolved.
- **WARNING:** The invoice screenshot shows toolbar “Clear filters,” a “Clear” action on the “Needs collection” chip, and another “Clear filters” within the active-view panel. Their different reset effects are not apparent from the repeated labels. Differentiate “Clear search filters” and “Show all invoices,” or remove a redundant control. Relevant render slots: `invoices_live.ex:120-129,176-181`.
- **Positive evidence:** The search trigger begins inside the 320px viewport and ellipsizes its helper text; its complete accessible name remains in `topbar.ex:19-32`. The payment review keeps action context and amount in a readable group.

### Pillar 3: Color (3/4)

- **WARNING:** The invoice, charge, and recovery LiveViews still provide `accent_hex: "#5D79F6"` and `accent_contrast_hex: "#FAFBFC"` defaults (for example `invoices_live.ex:509`, `invoice_live.ex:1567`, `recovery_live.ex:287`). Resolve the fallback through the semantic Admin palette or document the brand-input exception.
- **Positive evidence:** Current captures show invoice collection/review in light theme and recovery in dark theme. The browser spec checks heading contrast in light and dark themes and checks that their backgrounds differ (`phase237-admin-billing.spec.js:48-71,149-187`). Accent is concentrated on primary actions and the selected window.
- **WARNING (coverage):** Contrast assertions cover heading text against the page background, not status text, selected-window boundaries, or focus/control edges. Add checks for those declared 4.5:1 and 3:1 targets.

### Pillar 4: Typography (3/4)

- **Positive evidence:** Invoice and recovery content retains a distinct heading/body/label hierarchy. The queue title composes the semantic `.ax-type-label` role (600 weight); the Phase 234 browser check confirms subscription-detail text remains at least 14px. `theme.css:13-23` declares Geist and Geist Mono.
- **WARNING:** The shared search button and text remain at weights 900 and 750 (`app.css:4599-4617,4629-4640`), outside the contract's 400/600 weights for prose and controls.
- **Audit limitation:** Fresh CLI capture failed, so this audit could not inspect computed font metrics. The regenerated source-bound captures and manifest were reviewed.

### Pillar 5: Spacing (3/4)

- **Fixed / positive:** The mobile data-table search filter now uses `flex: 0 1 auto` with a 4px stack gap (`app.css:3407-3426`); the previous 16rem vertical reservation is gone.
- **Fixed / positive:** Invoice card fields use 4px gaps (`app.css:3553-3564`). Recovery tabs now use `var(--ax-space-xs)` for both wrapped row gap and inline padding (`app.css:4059-4073`), removing the prior 2px token deviation.
- **WARNING:** The shared `.ax-detail-action-band` styling remains active in `invoice_live.ex:350` and `charge_live.ex:223`; `app.css:6207-6223` sets 1px/2px gaps and 2px/7px button padding. Replace these off-grid values with 4px multiples or semantic spacing tokens.
- **Positive evidence:** Current 320px captures show compact controls, readable card grouping, and three recovery links without horizontal overflow.

### Pillar 6: Experience Design (4/4)

- **Positive evidence:** The served E2E journey verifies mobile invoice facts/action and document bounds; opens staged review with Enter; checks target, amount, consequence, and “Pay invoice”; closes with Escape and asserts focus returns to the opener (`phase237-admin-billing.spec.js:130-187`).
- **Positive evidence:** It verifies all three recovery buttons fit in 320px and the tab row does not horizontally scroll, then follows a related record and returns with owner/window intact (`phase237-admin-billing.spec.js:189-224`). The final Phase 237 run passed 1/1 at `b24092fa`.
- **Positive evidence:** Browser coverage checks themes, reduced motion, current served stylesheet, and generic foreign-owner denial. Recovery distinguishes loading/error/empty through `recovery_live.ex:40-71,207-220` and `at_risk_table.ex:68-75,153-155,179-181`.
- **Audit limitation:** Interaction captures were disabled by configuration. The served browser test exercises the primary keyboard path, but no additional interaction-state captures were produced during this audit.

---

## Files Audited

- `.planning/phases/237-admin-invoices-payments-recovery/237-UI-SPEC.md`
- `.planning/phases/237-admin-invoices-payments-recovery/237-CONTEXT.md`
- `.planning/phases/237-admin-invoices-payments-recovery/237-01-PLAN.md` through `237-08-PLAN.md`
- `.planning/phases/237-admin-invoices-payments-recovery/237-01-SUMMARY.md` through `237-08-SUMMARY.md`
- `.planning/phases/237-admin-invoices-payments-recovery/captures/237-08/manifest.json` and its three PNG captures
- `examples/accrue_host/e2e/phase237-admin-billing.spec.js`
- `accrue_admin/lib/accrue_admin/live/{invoices_live,invoice_live,charges_live,charge_live}.ex`
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`
- `accrue_admin/lib/accrue_admin/components/{at_risk_table,data_table,detail_drawer,empty_state,money_formatter,status_badge,window_selector,topbar}.ex`
- `accrue_admin/lib/accrue_admin/copy/{invoice,dunning}.ex`
- `accrue_admin/assets/css/{app,theme}.css`

