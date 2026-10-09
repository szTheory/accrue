# Phase 238 — UI Review

**Audited:** 2026-10-09  
**Baseline:** Approved `238-UI-SPEC.md` plus the implemented Admin component/theme system  
**Screenshots:** NOT captured — localhost:8080 served the Traefik dashboard, not the Phase 238 Admin app; no phase-specific screenshots were available, so visual findings are code-derived.
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Replay language is precise, but webhook empty and unavailable copy diverges from the approved contract. |
| 2. Visuals | 3/4 | DataTable preserves hierarchy and responsive card/table structure; rendered composition could not be inspected. |
| 3. Color | 3/4 | Theme-backed semantic colors are used, but source-level contract compliance and actual 60/30/10 rendering were not visually verified. |
| 4. Typography | 3/4 | Geist roles and mono values are present; shared theme exposes more size roles than the phase's four-role contract. |
| 5. Spacing | 2/4 | Shared Admin CSS uses a 2px spacing token below the declared grid; the 12px table cell padding is on-grid. |
| 6. Experience Design | 3/4 | Empty, loading, failure, retry, disclosure, and step-up states exist; the review could not exercise their mounted interaction states. |

**Overall: 17/24**

---

## Top 3 Priority Fixes

1. **Align webhook empty and unavailable messages with the contract** — operators see inconsistent recovery instructions and state labels — use “No deliveries to show” and the specified body for the empty view, and match the approved unavailable sentence and retry wording in the webhook table.
2. **Keep phase-owned spacing on the 4px grid** — the shared theme's 2px `--ax-space-2xs` token is below this phase's declared base and appears in existing shared Admin styles; the DataTable's `0.75rem` cell padding is 12px and already falls on the 4px grid.
3. **Capture the mounted screens at the contract breakpoints when the Admin app is available** — this audit could not inspect rendered balance or clipping because the detected server was the Traefik dashboard, not the Admin app. The existing Phase 238 Playwright shard already covers responsive and interaction acceptance.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The approved contract specifies the empty heading “No deliveries to show” and body “No webhook deliveries match these filters. Clear a filter or review all deliveries.” The webhook state is derived from `Copy.resource_state_copy/2` in [webhooks_live.ex](../../../accrue_admin/lib/accrue_admin/live/webhooks_live.ex#L593), while the legacy webhook-specific copy provides alternate headings/bodies (“No webhook deliveries for this organization yet” / “No webhook deliveries match these filters”) at [copy.ex](../../../accrue_admin/lib/accrue_admin/copy.ex#L1269). Verify the rendered resource-state copy and consolidate it to the approved contract; the dedicated copy currently conflicts with that contract.
- **WARNING:** The specified error copy is “Delivery history could not be loaded. Try again; the current results are not a complete history.” The live table currently passes different phrasing (retry instruction and “current results are not a complete history”) at [webhooks_live.ex](../../../accrue_admin/lib/accrue_admin/live/webhooks_live.ex#L383). Preserve the intent, but use the approved message consistently.
- Positive evidence: bulk confirmation names the selected count and states queue acceptance is not processing completion; affirmative/dismissal labels are “Queue eligible deliveries” and “Keep deliveries” in [copy.ex](../../../accrue_admin/lib/accrue_admin/copy.ex#L1280).

### Pillar 2: Visuals (3/4)

- **WARNING:** No screenshot evidence was available: localhost:8080 served the Traefik dashboard rather than the Admin app. I could verify only the template structure, not actual visual balance, clipping, or focal hierarchy.
- Positive structural evidence: the Webhooks table gives status, type, endpoint, and received-time data in both desktop columns and compact card fields, with accessible table caption and row selection labels in [webhooks_live.ex](../../../accrue_admin/lib/accrue_admin/live/webhooks_live.ex#L388) and [data_table.ex](../../../accrue_admin/lib/accrue_admin/components/data_table.ex#L482). The CSS switches to cards below 768px at [app.css](../../../accrue_admin/assets/css/app.css#L3776).
- **WARNING:** This phase's design anchor is the delivery status and timestamp first, then a readable identifier and scoped evidence. The template's desktop order begins with “Webhook” then “Type” then “Status” ([webhooks_live.ex](../../../accrue_admin/lib/accrue_admin/live/webhooks_live.ex#L393)); the actual visual prominence cannot be confirmed without captures. Consider moving status/time ahead of secondary type/endpoint data if the current CSS does not visually restore the requested hierarchy.

### Pillar 3: Color (3/4)

- **WARNING:** The implementation uses semantic Admin classes and theme CSS variables, but screenshot failure leaves the required 60/30/10 visual-area split and accent restriction unverified. Do not treat the semantic class names alone as proof of the rendered balance.
- Positive evidence: theme tokens define semantic base/elevated/accent/focus roles and light/dark variants in [theme.css](../../../accrue_admin/assets/css/theme.css#L137), while status colors have dedicated variables (success, warning, danger) in the same theme. Status text and badges are separate from primary action classes in the DataTable template.
- **WARNING:** Ten audited LiveView modules repeat the hard-coded fallback brand accent `#5D79F6` (for example [events_live.ex](../../../accrue_admin/lib/accrue_admin/live/events_live.ex#L471)). This is a brand fallback value rather than a directly styled UI element, but route-local duplication makes accent configuration drift possible; centralize it or prove that all routes consume the same semantic theme mapping.

### Pillar 4: Typography (3/4)

- **WARNING:** The phase contract defines four sizes (12/16/20/24px) and two weights (400/600). Shared theme roles include extra 14px, 18px, and 30px roles as well as several display/title roles in [theme.css](../../../accrue_admin/assets/css/theme.css#L80). The audited templates mostly use semantic `ax-*` classes, so this broader scale is inherited rather than proof that every phase page misuses type; verify the resulting rendered sizes against the four intended roles.
- Positive evidence: Geist/Geist Mono are configured, with mono code roles at 12px and 14px; inline identifiers and payloads use the shared semantic component styling. Phase summaries report mounted browser assertions for long identifiers and labels, but those assertions were not independently rerun here.

### Pillar 5: Spacing (2/4)

- **WARNING:** The approved scale states no spacing exceptions below the 4px base. The shared theme defines `--ax-space-2xs: 0.125rem` (2px) in [theme.css](../../../accrue_admin/assets/css/theme.css#L26), and existing Admin styles use it for small gaps and offsets. This is an inherited scale deviation in the shared UI foundation.
- DataTable grid cells use `padding: 0.75rem` (12px) vertically in [app.css](../../../accrue_admin/assets/css/app.css#L3754); 12px is a multiple of four and does not violate the declared grid.
- Positive evidence: primary table rhythm and filters use `--ax-space-md` (16px) and `--ax-space-xs` (4px), and mobile filters can shrink to avoid page overflow at 320px ([app.css](../../../accrue_admin/assets/css/app.css#L3386)).

### Pillar 6: Experience Design (3/4)

- **WARNING:** Interaction capture was explicitly off, and screenshots failed; states were reviewed in templates and phase evidence, not exercised live during this audit.
- Positive evidence: DataTable implements initial and partial read failures with `role="alert"`, retry actions, and a loading skeleton announced with `role="status"` in [data_table.ex](../../../accrue_admin/lib/accrue_admin/components/data_table.ex#L374). Selection count is a polite live region and the bulk CTA only renders when selection is nonempty ([data_table.ex](../../../accrue_admin/lib/accrue_admin/components/data_table.ex#L447)).
- Positive evidence: payload/activity disclosure, fresh step-up, rejected-step-up recovery, disabled duplicate submission, and replay outcome handling have corresponding test evidence in `238-05-SUMMARY.md` and `238-VALIDATION.md`. The copy distinguishes queued from processed work.
- **WARNING:** Connect explicitly labels provider data as a “last stored Stripe snapshot” and says the view does not track when Stripe last reported it at [connect_account_live.ex](../../../accrue_admin/lib/accrue_admin/live/connect_account_live.ex#L167). This is transparent, but the UI still cannot let an operator judge freshness from an observation timestamp; add that timestamp when the data model supports it.

---

## Registry Safety

`components.json` is absent and the approved UI spec records no third-party registries or added UI packages; registry source audit skipped.

## Files Audited

- `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-UI-SPEC.md`
- `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-01-PLAN.md` through `238-05-PLAN.md`
- `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-01-SUMMARY.md` through `238-05-SUMMARY.md`
- `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-VALIDATION.md`
- `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-REVIEW.md` and `238-REVIEW-DISPOSITION.md`
- `accrue_admin/lib/accrue_admin/live/{events_live,event_live,webhooks_live,webhook_live,coupons_live,coupon_live,promotion_codes_live,promotion_code_live,connect_accounts_live,connect_account_live}.ex`
- `accrue_admin/lib/accrue_admin/components/{data_table,overlay}.ex`
- `accrue_admin/lib/accrue_admin/copy.ex`
- `accrue_admin/assets/css/{theme,app}.css`
- `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js`
