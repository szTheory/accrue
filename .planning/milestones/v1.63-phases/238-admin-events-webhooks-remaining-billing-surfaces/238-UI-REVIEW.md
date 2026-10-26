# Phase 238 — UI Review

**Audited:** 2026-10-09
**Baseline:** Approved `238-UI-SPEC.md`, Phase 238 plans/summaries/validation, and the current Admin implementation
**Screenshots:** NOT captured — localhost:3000 and :5173 had no server; localhost:8080 answered but all three Playwright captures (desktop, mobile, tablet) failed. The responding endpoint was not verified as the Phase 238 Admin app, so visual findings are code-derived.
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Replay copy is precise, but Webhooks empty and unavailable states still diverge from the approved wording. |
| 2. Visuals | 3/4 | Responsive table/card and overlay structures are present; rendered hierarchy could not be inspected, and desktop columns put secondary fields before status. |
| 3. Color | 3/4 | Forced light/dark policy is represented and tested; 60/30/10 rendering and accent distribution remain unverified without an Admin capture. |
| 4. Typography | 3/4 | Geist roles are used, but the shared token scale exposes sizes beyond the phase's four documented roles. |
| 5. Spacing | 2/4 | The shared 2px spacing token is used despite the contract's explicit 4px minimum. |
| 6. Experience Design | 3/4 | Keyboard focus, modal/drawer containment, host-forced theme, and recovery paths have browser assertions; this audit could not exercise the mounted UI, and provider snapshot freshness remains unknown. |

**Overall: 17/24**

---

## Top 3 Priority Fixes

1. **Align Webhooks empty and unavailable copy with the approved contract** — operators get conflicting guidance about an empty queue or incomplete history — update the `:webhooks` resource-state strings and pass the specified unavailable copy to `DataTable`.
2. **Remove the 2px spacing exception or amend the contract deliberately** — dense table/control gaps fall below the stated 4px base — replace `--ax-space-2xs` use with an on-grid token and keep target sizing separate.
3. **Capture the mounted Admin views at contract breakpoints** — no rendered evidence exists to confirm hierarchy, clipping, theme contrast, or spacing — capture seeded Phase 238 routes in the host browser lane and retain desktop, tablet, and 320px evidence.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The contract requires “No deliveries to show” and “No webhook deliveries match these filters. Clear a filter or review all deliveries.” The `:webhooks` resource-state metadata instead defines “No webhook deliveries yet.” / “Deliveries appear after signed processor events are recorded.” and “No webhook deliveries match these filters.” / “Clear filters or adjust status and type filters to see deliveries.” (`accrue_admin/lib/accrue_admin/copy.ex:107-118`); `WebhooksLive` renders this resource-state copy for empty results (`accrue_admin/lib/accrue_admin/live/webhooks_live.ex:603-626`). The legacy `webhooks_index_*` helpers also conflict (`copy.ex:1263-1272`).
- **WARNING:** The contract's unavailable message is “Delivery history could not be loaded. Try again; the current results are not a complete history.” The shared `DataTable` default says only “This history could not be loaded. Try again.” (`accrue_admin/lib/accrue_admin/components/data_table.ex:64`), and Webhooks does not provide an override (`webhooks_live.ex:384-422`). Pass the approved resource-specific text and include the incompleteness warning.
- Positive evidence: bulk replay confirmation uses the precise queue-versus-processing wording and the requested “Queue eligible deliveries” / “Keep deliveries” controls (`webhooks_live.ex:348-367`; `accrue_admin/lib/accrue_admin/copy.ex:1280-1297`). The browser spec also asserts queue acceptance is not described as completed processing (`examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js:128-134`).

### Pillar 2: Visuals (3/4)

- **WARNING:** Screenshots were not captured. Ports 3000 and 5173 were unavailable; port 8080 answered but all Playwright screenshot attempts failed. Therefore actual hierarchy, 60/30/10 surface balance, clipping, and responsive appearance could not be judged in a rendered Phase 238 route.
- **WARNING:** The approved visual anchor puts delivery status and timestamp first. The desktop column order is Webhook, Type, Status, Endpoint, Received (`accrue_admin/lib/accrue_admin/live/webhooks_live.ex:402-407`), so identifier/type precede status and time in the source order. Reorder to status/received first if the CSS does not visually restore the specified priority; rendered evidence is needed to confirm.
- Positive structural evidence: mobile cards explicitly list Status before Type/Endpoint/Received (`webhooks_live.ex:409-415`); the shared table switches to cards below 768px (`accrue_admin/assets/css/app.css:3776-3792`). Overlay panels have a named dialog, modal semantics, and a heading fallback (`accrue_admin/lib/accrue_admin/components/overlay.ex:85-95`).

### Pillar 3: Color (3/4)

- **WARNING:** The contract reserves accent for primary actions, active filters, focus, and primary links, and asks for an approximate 60/30/10 visual-area balance (`238-UI-SPEC.md:87-96`). Semantic theme roles exist in `accrue_admin/assets/css/theme.css:137-179`, with a distinct dark palette at `theme.css:233-250`; the current host-forced policy routes `:light`/`:dark` through `BrandPlug` and surfaces a host-set status while hiding the picker (`accrue_admin/lib/accrue_admin/brand_plug.ex:23-39`; `accrue_admin/lib/accrue_admin/components/topbar.ex:41-44`). The Playwright spec seeds a conflicting light preference and asserts forced theme/status/picker behavior (`examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js:243-257`). However, the unresolved screenshot failure prevents verification of actual surface distribution and contrast on the changed mounted Admin route.
- **WARNING:** Brand fallback accent `#5D79F6` remains duplicated in layout and route fallback maps (`accrue_admin/lib/accrue_admin/layouts.ex:15,103`; `accrue_admin/lib/accrue_admin/live/webhooks_live.ex:743`; `accrue_admin/lib/accrue_admin/live/connect_account_live.ex:1016`). These fallbacks are not evidence of accent overuse on screen, but centralizing them would reduce visual drift between routes.

### Pillar 4: Typography (3/4)

- **WARNING:** The phase declares four intended sizes (12, 16, 20, 24px) and two weights (400, 600) (`238-UI-SPEC.md:70-81`). Shared theme tokens also define 14, 18, 28, and 36px roles (`accrue_admin/assets/css/theme.css:16-23`) and composed title/display roles (`theme.css:82-105`). The broader global scale is not itself a defect on these screens, but code-only review cannot establish that Phase 238 content uses only the declared roles or that its hierarchy matches the contract.
- Positive evidence: the contract's long identifiers/payloads have a monospace role, and the browser spec includes a 120-character identifier containment assertion (`examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js:231-240`).

### Pillar 5: Spacing (2/4)

- **WARNING:** The contract states “No spacing exceptions below the 4px base grid” (`238-UI-SPEC.md:54-66`), while the shared Admin token scale defines `--ax-space-2xs: 0.125rem` (2px) and documents its dense-table use (`accrue_admin/assets/css/theme.css:25-33`). This directly violates the declared scale. The DataTable grid's 12px vertical padding is on-grid and not a violation (`accrue_admin/assets/css/app.css:3752-3758`).
- Positive evidence: primary DataTable rhythm uses 16px and compact filters use the 4px token (`app.css:3384-3411`). Target dimensions are treated separately from spacing tokens by the contract.

### Pillar 6: Experience Design (3/4)

- **WARNING:** Interaction capture was off, and static screenshots failed, so this audit did not interact with the live UI. The current browser spec provides repeatable evidence for selection confirmation, keyboard initial focus, Tab containment, Escape dismissal, focus restoration, rejected step-up correction, Connect drawer keyboard save/cancel, and the host-forced theme lane (`examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js:65-134,175-198,243-258`). The recent `FocusTrap` change schedules a single initial-focus attempt for inactive confirmation content and preserves active-trap focus handling (`accrue_admin/assets/js/hooks/focus_trap.js:95-164`); this is aligned with the phase keyboard requirements.
- **WARNING:** The Connect screen transparently says its Stripe readiness/capability values are a last stored snapshot but that the page does not track when Stripe last reported them (`accrue_admin/lib/accrue_admin/live/connect_account_live.ex:167-169`). Operators therefore cannot assess snapshot age from this view. Add an observation timestamp when the model supplies one; until then retain the explicit unknown-freshness wording.
- Positive evidence: overlay semantics and escape behavior are wired in shared components (`overlay.ex:62-95`; `focus_trap.js:219-253`), and the host-forced theme check verifies persisted preference conflict does not break the filtered list, enabled status control, or axe scan (`phase238-admin-events-webhooks.spec.js:243-257`).

## Registry Safety

`components.json` is absent and `238-UI-SPEC.md` records no third-party registry or added UI package (`shadcn_initialized: false`; `238-UI-SPEC.md:142-148`). Registry source audit skipped.

## Files Audited

- `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-01-PLAN.md` through `238-05-PLAN.md`
- `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-01-SUMMARY.md` through `238-05-SUMMARY.md`
- `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-UI-SPEC.md`
- `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-VALIDATION.md`
- `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-UI-REVIEW.md` (prior findings only)
- `accrue_admin/lib/accrue_admin/components/{app_shell,overlay,step_up_auth_modal,topbar}.ex`
- `accrue_admin/lib/accrue_admin/layouts.ex`
- `accrue_admin/lib/accrue_admin/live/{connect_account_live,webhooks_live}.ex`
- `accrue_admin/assets/js/hooks/focus_trap.js`
- `accrue_admin/assets/css/{theme,app}.css`
- `accrue_admin/lib/accrue_admin/{brand_plug,copy}.ex`
- `accrue_admin/lib/accrue_admin/components/data_table.ex`
- `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js`
