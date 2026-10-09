# Phase 240 — UI Review

**Audited:** 2026-10-09  
**Baseline:** Approved [240-UI-SPEC.md](240-UI-SPEC.md) and locked incumbent Admin design direction  
**Screenshots:** Existing committed Phase 237 mounted captures reviewed (invoice collection, invoice action review, subscription detail, recovery); no new captures taken. Actual 400% browser zoom and Linux pixel comparison were unavailable locally; emulated width/coarse-pointer evidence is not zoom proof.  
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | Invoice review still labels its return action `Cancel`, contrary to the contract's `Back to invoice` copy. |
| 2. Visuals | 2/4 | The 320px invoice capture repeats filter, lens, clear, and result context; subscription detail piles two invoice-queue blocks together. |
| 3. Color | 2/4 | Subscription detail spends Cobalt on a bordered queue preview and multiple nearby primary buttons, weakening the single-task accent hierarchy. |
| 4. Typography | 2/4 | The page styles use 700–950 font weights despite the approved 400/600-only weight contract. |
| 5. Spacing | 2/4 | The subscription lifecycle summary uses zero gap/padding and half-pixel spacing, visibly compressing separate facts. |
| 6. Experience Design | 3/4 | State and keyboard coverage are strong, but the mounted review still exposes generic dismissal wording and no interaction capture was taken for this audit. |

**Overall: 13/24**

No observed issue blocks the core invoice review or subscription task. All findings below are **WARNING** level; there are no BLOCKER findings.

---

## Top 3 Priority Fixes

1. **Restore one coherent mobile invoice-filter/results hierarchy** — operators must scan redundant controls and counts before reaching the invoice — remove the repeated lens/clear/count presentation while retaining active constraints and the one supported collection lens.
2. **Give the subscription invoice queue one clear entry point** — two adjacent queue panels and multiple Cobalt actions compete with the subscription's own facts and actions — consolidate the workspace and preview or visibly subordinate one per the approved scope.
3. **Bring invoice-review dismissal and type roles back to contract** — generic `Cancel` obscures that the action is non-mutating, while extra weights make the detail hierarchy inconsistent — label dismissal `Back to invoice` and replace 700–950 declarations with the composed 400/600 roles.

---

## Detailed Findings

### Pillar 1: Copywriting (2/4)

- **WARNING:** The mounted invoice action review says `Cancel` for the dismissal control, while the contract requires the explicit non-mutating `Back to invoice` label. It also shows `Confirm action` followed by a body beginning `Pay invoice: This will attempt...`; the action and consequence are repeated, making the panel copy procedural. The screenshot confirms the generic label at the drawer footer. See [invoice.ex](../../../accrue_admin/lib/accrue_admin/copy/invoice.ex:180) (`invoice_confirm_panel_label/0`, `invoice_confirm_cancel/0`) and [invoice_live.ex](../../../accrue_admin/lib/accrue_admin/live/invoice_live.ex:538). Keep the action-specific submit verb and legal/audit sentence, but make the safe dismissal explicit and avoid repeating the action heading in the explanatory sentence.
- **WARNING:** The narrow collection capture has both a control-form `Clear filters` and a separate lens-level clear link, plus `Showing 1 invoice` and `Showing 1 result`. The contract calls for one coherent filter hierarchy and one visible collection lens. See [invoices_live.ex](../../../accrue_admin/lib/accrue_admin/live/invoices_live.ex:120) and lines 184–192.
- Good: the visible list action is `View invoice`; missing due date is stated as unavailable; review names invoice/customer/owner and exact amount/currency. The text is specific and does not claim settlement.

### Pillar 2: Visuals (2/4)

- **WARNING:** The committed 320×800 collection capture shows the search/status/customer/collection controls, then a second `FILTERS` card containing `Invoice view`, `Needs collection`, `All invoices`, and a count, followed by another result count below the invoice card. This creates three separate scan stops for filter/lens/result context before the record. Source composes the toolbar in [invoices_live.ex](../../../accrue_admin/lib/accrue_admin/live/invoices_live.ex:120) and a filter-chip result band at lines 184–192. Remove redundant presentation while preserving semantics and actions.
- **WARNING:** The 1280×900 subscription capture places `Global invoice queue workspace` and `Global open-invoice queue rows` in adjacent blue outlined regions, with both `Work all open invoice records` and `Work all invoices in queue` prominent. This interrupts the identity → status/facts → action hierarchy and makes unrelated global queue work dominate a dense record page. See [subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:323) and lines 358–385.
- The action review is self-contained and exposes target, owner, customer, exact amount and action effect before its action button; this is a clear focal panel. The subscription identity wraps in the capture, and the mounted manifest reports long text wrapping within its measured container.

### Pillar 3: Color (2/4)

- **WARNING:** Cobalt is appropriate for selected navigation, links, and the primary action, but the subscription screenshot applies it to the workspace CTA, several links, a bordered preview region, a second queue CTA, and related-resource icons. That is a crowded accent share for a page whose main task is subscription review. Relevant owners are [subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:323) and [app.css](../../../accrue_admin/assets/css/app.css:5874). Keep Cobalt on the one primary task action and selected/current state; soften the queue preview border and secondary queue entry point.
- Theme tokens themselves are semantic and theme-aware: [theme.css](../../../accrue_admin/assets/css/theme.css:138) defines light roles and lines 233–250 define dark base/accent/focus roles. The mounted manifest records effective light and dark computed colors, so this score is for composition, not token absence.
- Source scan found 39 matches for accent-role use across the audited UI/CSS owners; this count is across CSS selectors and component files, not a count of distinct on-screen elements. The screenshots are the evidence for the observed density.

### Pillar 4: Typography (2/4)

- **WARNING:** The contract explicitly approves only 400 and 600 weights for the exemplar, but shared CSS uses 700, 800, 900, and 950 (for example [app.css](../../../accrue_admin/assets/css/app.css:5423), 5488, 5503). The subscription capture's very heavy labels and callouts create an uneven hierarchy against normal-weight facts. Replace these declarations with the existing semantic roles where they affect this route, without flattening the approved size scale.
- The 12/14/16/20/24/28px role steps and 12/14px mono exceptions are explicitly approved in the spec; their presence is not a finding. Geist and Geist Mono are the incumbent fonts.

### Pillar 5: Spacing (2/4)

- **WARNING:** The subscription lifecycle summary intentionally has `gap: 0` and `padding: 0` at [app.css](../../../accrue_admin/assets/css/app.css:5430), while its child uses `gap: 0.03125rem 0.25rem` and `padding: 0.03125rem 0.25rem` (0.5px and 4px) at lines 5477–5478. The capture shows lifecycle, status, verdict, explanation, and evidence cue nearly flush on one band. Use the approved spacing roles to separate the task-critical label and answer; reserve 2px for dense data and 1px for structural rules.
- The contract's 4px ladder and its intentional 2px dense-data / 1px structural exceptions are otherwise present in [theme.css](../../../accrue_admin/assets/css/theme.css:25). No blanket scale migration is recommended.

### Pillar 6: Experience Design (3/4)

- **WARNING:** The review's dismissal remains generic `Cancel` rather than the specified `Back to invoice`; this weakens the meaning of a critical review step even though the action is available. See [invoice.ex](../../../accrue_admin/lib/accrue_admin/copy/invoice.ex:184).
- Positive evidence: the Phase 237 mounted journey opened the real scoped invoice review without dispatching it, and recorded served/package CSS, JS, and font hash agreement. The manifest records 320/768/1280 viewport checks, both fine/coarse pointer contexts, light/dark effective colors, and `action_confirmed_or_dispatched: false`; these are emulated/fixture-backed limits, not physical touch or actual browser zoom proof.
- Source and owner summaries document keyboard focus containment/restoration, validation correction, reduced-motion teardown, loading/disabled states, reconnect locking, fresh authorization, and no replay. Loading/error/empty/unsupported/unconfirmed outcomes are represented in the invoice/subscription owners. The current visual captures do not show those transient states, and interaction capture was off; findings for those states are therefore based on code and recorded owner evidence rather than newly observed interaction captures.
- Scope limits remain honest: actual 400% browser zoom and local Linux pixel comparison were unavailable; Phase 243 owns final reviewed Linux goldens. The unrelated host `verify.full` failure recorded in `240-COVERAGE.md` is not scored as a visual defect.

---

## Files Audited

- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-UI-SPEC.md`
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-CONTEXT.md`
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md`
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-01-PLAN.md` through `240-06-PLAN.md` and all six corresponding `240-0N-SUMMARY.md` files
- `.planning/phases/240-shared-system-and-real-billing-exemplar/captures/phase237-exemplar/manifest.json` and committed `invoice-collection.png`, `invoice-review.png`, `subscription-detail.png`, `recovery.png`
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex`
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex`
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `accrue_admin/lib/accrue_admin/copy/invoice.ex`
- `accrue_admin/lib/accrue_admin/components/detail.ex`
- `accrue_admin/assets/css/app.css`
- `accrue_admin/assets/css/theme.css`
