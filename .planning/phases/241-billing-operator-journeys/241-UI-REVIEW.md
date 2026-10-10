# Phase 241 — UI Review

**Audited:** 2026-10-10; source-only final recheck after Plan08\
**Baseline:** Approved `241-UI-SPEC.md`, including Phase 240 incumbent role and spacing exceptions\
**Screenshots:** Not captured (source-only audit; no fresh visual inspection)\
**Interaction captures:** off (workflow.ui_interaction_capture is false)

Plan08 closes the action-gap spacing defect identified in the previous review. Its existing mounted Chromium owner reports 4px gaps for the invoice action band, subscription action band, and subscription dunning action row, each equal to computed `--ax-space-xs`; it also reports no ordinary overflow at 320px. Subscription primary controls measured 44px in desktop/mobile and coarse-pointer contexts. These are the documented Plan08 test results, not captures or a new run in this audit. Package asset tests verify CSS/JS/font route identity; host-served identity remains unobserved. The broader appearance, theme, and interaction contract was not re-inspected in served output, so visual and interaction scores remain bounded by current source and recorded evidence.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Current subscription unavailable-value and Recovery labels are specific and scope claims correctly. |
| 2. Visuals | 3/4 | Source hierarchy follows the contract, but current rendered hierarchy and visual balance were not inspected. |
| 3. Color | 3/4 | Semantic token/class usage is present; effective contrast and 60/30/10 composition were not freshly measured. |
| 4. Typography | 3/4 | Subscription title selects the approved 24px/600 role; cross-surface served typography is unverified. |
| 5. Spacing | 3/4 | Plan08 measured the named action groups at the 4px token; other responsive and theme spacing was not broadly rechecked. |
| 6. Experience Design | 3/4 | Source shows explicit state/accessibility patterns; keyboard, dismissal, busy, and reconnect interactions were not freshly exercised. |

**Overall: 19/24**

## Top 3 Priority Fixes

1. **Reconfirm current visual output across themes and breakpoints** — source and the focused spacing owner do not establish current composition, contrast, focus visibility, or all responsive states — inspect the built package/host output under the contract's bounded theme and viewport cases when visual evidence is next collected. **WARNING**
2. **Exercise review and dismissal interactions** — this source-only recheck cannot establish keyboard containment, Escape behavior, focus restoration, or stable busy/reconnect controls — use existing interaction owners for the changed review flows when interaction evidence is next collected. **WARNING**
3. **Keep action spacing regression coverage** — the Plan08 owner now verifies the invoice, subscription, and dunning gaps against the computed token, but its 44px height threshold is asserted for subscription actions, not invoice actions — retain the test and add an invoice hit-height assertion if that surface's standalone target guarantee is required. **WARNING**

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- Current unavailable-value text says “Amount is not confirmed in admin,” “Current period is not shown in admin,” and “Price is not confirmed in admin,” limiting claims to the Admin projection ([`subscription_live.ex`](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:1240)). Subscription action labels remain domain-specific.
- The no-campaign state identifies the Recovery destination and says “No subscription-level campaign here” ([`subscription_live.ex`](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:423)). No generic CTA or misleading zero-value copy was found in the audited subscription strings.

### Pillar 2: Visuals (3/4)

- Subscription source order leads with record identity and summary facts, then lifecycle, actions, related resources, and deeper detail ([`subscription_live.ex`](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:287)). This matches the specified hierarchy in markup, but current rendered prominence and spacing balance were not inspected.
- Source conditionally renders the no-campaign or active-campaign Recovery shortcut ([`subscription_live.ex`](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:422), [`subscription_live.ex`](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:437)). No claim is made about current screenshot appearance.

### Pillar 3: Color (3/4)

- The Recovery destination uses the purposeful `ax-link` class ([`subscription_live.ex`](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:425)); theme colors are token-backed in [`theme.css`](../../../accrue_admin/assets/css/theme.css:12).
- No current served measurement establishes the contract's 60/30/10 composition or contrast in light, dark, system, and host-forced themes. **WARNING:** those visual requirements remain unverified in this final source-only recheck.

### Pillar 4: Typography (3/4)

- The subscription title selects `--ax-type-xl` at weight 600, the contract's 24px/600 role ([`app.css`](../../../accrue_admin/assets/css/app.css:5364)). The design contract explicitly preserves incumbent semantic type roles and the two weights 400/600.
- Current computed typography across the changed surfaces was not measured. Prior host computed-style evidence belongs to its recorded earlier run and is not treated as a fresh served check.

### Pillar 5: Spacing (3/4)

- Source sets `.ax-detail-actions-row`, `.ax-detail-critical-actions`, `.ax-detail-action-band .ax-page-header`, and `.ax-detail-action-band .ax-page-actions` to `var(--ax-space-xs)` ([`app.css`](../../../accrue_admin/assets/css/app.css:6187), [`app.css`](../../../accrue_admin/assets/css/app.css:6194), [`app.css`](../../../accrue_admin/assets/css/app.css:6201), [`app.css`](../../../accrue_admin/assets/css/app.css:6207)). The token is 4px ([`theme.css`](../../../accrue_admin/assets/css/theme.css:27)).
- Plan08's recurring test measures the invoice action band, subscription action band, and active dunning action row against a computed token probe; the summary records all three at 4px, with no ordinary overflow at 320px. It records subscription primary controls at 44px in narrow and coarse-pointer contexts; invoice height was measured at 44px but has no asserted threshold. Evidence: [`241-08-SUMMARY.md`](241-08-SUMMARY.md) and [`admin-interaction-overlay-phase199.spec.js`](../../../accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js:1102). No new browser run or screenshot was performed for this audit.
- **Closed finding:** the prior 2px/3px action-gap finding is resolved by Plan08's source and documented mounted measurements. Wider Phase 241 spacing, text enlargement, and actual zoom remain outside this focused check.

### Pillar 6: Experience Design (3/4)

- Subscription source keeps the Recovery link mutually exclusive across active/no-campaign states and exposes action results with `role="status"` and `aria-live="polite"` ([`subscription_live.ex`](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:326), [`subscription_live.ex`](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:422), [`subscription_live.ex`](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:437)).
- Plan08 adds recurring geometry coverage for action spacing, narrow overflow, and subscription target sizes. This audit did not replay keyboard navigation, overlay dismissal, focus restoration, loading/busy, or reconnect behavior. **WARNING:** those interaction criteria remain code-derived or historical, not freshly validated here.

## Files Audited

- `.planning/phases/241-billing-operator-journeys/241-UI-SPEC.md`, `241-UI-REVIEW.md` (prior), `241-UI-FIX.md`, `241-08-PLAN.md`, `241-08-SUMMARY.md`
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `accrue_admin/assets/css/app.css`, `accrue_admin/assets/css/theme.css`
- `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js`
