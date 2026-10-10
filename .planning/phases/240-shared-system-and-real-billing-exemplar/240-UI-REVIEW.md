# Phase 240 — UI Review

**Audited:** 2026-10-10\
**Baseline:** Approved [240-UI-SPEC.md](240-UI-SPEC.md) and locked incumbent Admin design direction\
**Screenshots:** Not captured. The phase visual-inspection budget forbids new capture or image inspection in this audit. Phase 237 captures and their measurements are historical evidence only; they predate later Phase 240 fixes and Phase 241 changes.\
**Interaction captures:** off (workflow.ui_interaction_capture is false)

This is a source and evidence reconciliation. It does not certify current mounted geometry, effective color composition, physical touch, browser zoom, or Linux pixel output. Phase 243 owns final reviewed Linux goldens.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | `Back to invoice` is now correct, but generic `Confirm` remains in the shared removal flow and the main review body repeats the action. |
| 2. Visuals | 2/4 | Source removes the old invoice-list duplication and subscription queue blocks, but current visual hierarchy cannot be verified from the historical captures. |
| 3. Color | 2/4 | Theme roles are semantic, while shared subscription health selectors still apply primary color to several nearby labels and callouts; current 60/30/10 composition is unmeasured. |
| 4. Typography | 2/4 | Current shared CSS still declares 700–950 weights, outside the contract's 400/600 exemplar roles. |
| 5. Spacing | 2/4 | Health-summary facts retain zero gap and half-pixel vertical padding, below the contract's task-separation spacing. |
| 6. Experience Design | 3/4 | Owner coverage documents guarded states and keyboard/reconnect behavior; this audit captured no live interaction states. |

**Overall: 14/24**

All findings are **WARNING** level. No source-derived defect found in this audit establishes a broken core task flow; visual pillars remain constrained by unavailable current renders.

---

## Top 3 Priority Fixes

1. **Replace out-of-contract weights in subscription health selectors** — heavy 900/950 declarations can overpower the approved hierarchy — use the existing 400/600 semantic roles in the affected subscription selectors.
2. **Give lifecycle health facts visible separation** — zero gap and half-pixel vertical padding compress distinct facts — apply approved 4px spacing roles while keeping intentional 1px rules and 2px dense-data exceptions.
3. **Verify current subscription hierarchy and accent composition in Phase 243's approved review** — historical captures predate current route code — use the owned goldens workflow to inspect the actual page before claiming visual acceptance.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The non-mutating action-review dismissal now correctly uses `Back to invoice` ([invoice.ex](../../../accrue_admin/lib/accrue_admin/copy/invoice.ex:193)); the previous finding is resolved by commit `5623c421`. The distinct manual line-item removal action still uses generic `Cancel` at line 195. Its separate destructive confirmation makes the context recoverable, but a more specific label would better satisfy the contract's action-specific wording.
- **WARNING:** The shared copy helper returns `Confirm` ([invoice.ex](../../../accrue_admin/lib/accrue_admin/copy/invoice.ex:191)); the invoice review dynamically prefixes it to action text in [invoice_live.ex](../../../accrue_admin/lib/accrue_admin/live/invoice_live.ex:1480). This yields an action-specific button, but its visible prefix is generic and should be compared against the contract's exact selected-action verb. Do not change locked legal/audit copy.
- The invoice-list copy distinguishes first-run, queue-empty, and filtered-empty states; `View invoice` is explicit, and missing due date is represented as unavailable ([invoice.ex](../../../accrue_admin/lib/accrue_admin/copy/invoice.ex:6), lines 38–50, 87–89). The earlier duplicate clear/count issue was reduced in the current invoice list component by suppressing the table toolbar's clear action, row count and empty clear control ([invoices_live.ex](../../../accrue_admin/lib/accrue_admin/live/invoices_live.ex:134), lines 136–139, 183–199). The previous audit's screenshot observation is historical, not a current visual claim.

### Pillar 2: Visuals (2/4)

- **WARNING:** Current invoice-list source groups filter controls and active lens/results under one labeled group and suppresses duplicate local count/clear controls ([invoices_live.ex](../../../accrue_admin/lib/accrue_admin/live/invoices_live.ex:176), lines 183–199). The earlier 320px capture documented a competing hierarchy before that correction; it is historical and cannot establish the current render.
- **WARNING:** The old global invoice-queue panels cited in the prior review are absent from the current `subscription_live.ex` source. Current source proceeds from summary into action controls, related resources and labeled detail disclosures ([subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:307), lines 337–385). The Phase 237 subscription screenshot predates those later route changes, so current focal point, page density, breakpoints and alignment remain unverified. Phase 243 owns final visual review.
- UI-SPEC requires a clear identity → facts → supported action → evidence scan order at 320px through desktop. Code structure suggests this order in the main subscription detail, but source structure alone does not prove rendered spacing, wrapping, or focal balance. Score remains 2 pending owned visual evidence.

### Pillar 3: Color (2/4)

- **WARNING:** Cobalt is reserved for primary actions, selected state and purposeful links. Current subscription health CSS uses `--ax-primary` for verdict, answer, facts, labels and body text ([app.css](../../../accrue_admin/assets/css/app.css:5395), lines 5430–5450, 5570–5578). Semantic token use is good, but the source does not establish that the full page respects the 60/30/10 compositional guide. The earlier crowded queue-accent finding is tied to route content removed since the historical capture and is not asserted as current.
- `theme.css` defines semantic, theme-aware roles (light roles at line 138 and dark roles at lines 233–250 per the prior evidence record). Phase 237 recorded computed light/dark colors, but those measurements and captures describe its then-current revision. Do not treat them as current mounted evidence.
- A broad scan across Admin LiveView/component and CSS owners finds hundreds of raw token/color references; this scope-wide count is not a count of distinct screen elements and cannot establish the on-screen accent share. Current screen composition needs the Phase 243 visual owner.

### Pillar 4: Typography (2/4)

- **WARNING:** The contract defines 400/600 weights for the exemplar. Current shared CSS retains `.ax-summary-health-verdict { font-weight: 900; }` and `.ax-summary-health-answer { font-weight: 950; }` ([app.css](../../../accrue_admin/assets/css/app.css:5430), lines 5436–5450). Other Admin selectors also contain 700, 800, 850, 900 and 950; a broad scan found 14/15/6/17/21 declarations respectively. Not all selectors apply to these routes, so counts are not presented as visible-element counts. Replace weights on the affected subscription health path with approved roles.
- The approved font families and role sizes remain defined in the design contract; no size-scale deviation was established by source review here. Phase 237 typography appearance is historical only.

### Pillar 5: Spacing (2/4)

- **WARNING:** The subscription summary fact-health selector retains `gap: 0` and `padding: 0.03125rem 0.3125rem` (0.5px vertical) ([app.css](../../../accrue_admin/assets/css/app.css:5401)). Distinct health facts can consequently run together in this element. The approved 4px ladder expects 16/24/32px separation for controls/fact groups/sections, reserving 2px for dense data and 1px for structural rules.
- The lifecycle summary container itself now uses the approved token gaps and padding (`.ax-detail-health-copy`, [app.css](../../../accrue_admin/assets/css/app.css:5497)); the old zero-gap lifecycle issue was fixed under `b0336989`. This does not resolve the separate summary-fact selector finding. No current screenshot was captured to assess actual wrapping or rendered proximity.

### Pillar 6: Experience Design (3/4)

- **WARNING:** Interaction capture was off, and no new state was driven for this audit. Therefore no current focus, hover, busy, reconnect or result state is claimed as observed. The Phase 237 mounted invoice journey is historical, as are its 320/768/1280 widths, fine/coarse-pointer contexts, effective theme checks and no-dispatch assertion.
- Positive source/evidence: the phase owner records and recurring tests cover distinct invoice empty/loading/error/unavailable states, scoped review actions, disabled/busy controls, focus containment/restoration, validation, reconnect locking, fresh authorization and no mutation replay. These are owner-backed behavior checks, not current visual captures or proof of every UI-SPEC viewport/state.
- Accessible labels and live status roles are present in current source at key surfaces (e.g. invoice filter group at [invoices_live.ex](../../../accrue_admin/lib/accrue_admin/live/invoices_live.ex:176), subscription action result at [subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:324)). Actual screen-reader speech and physical touch are not claimed.
- Actual 400% browser zoom and local Linux pixel comparison remain unverified. Phase 243 owns final reviewed Linux goldens; no baseline was inspected or regenerated here.

---

## Accepted Correction and Scope History

- `5623c421` fixed invoice-review dismissal to **Back to invoice**.
- `25af07fa` consolidated invoice filter/lens/count/clear presentation; current source suppresses duplicate count and clear controls.
- `b0336989` corrected lifecycle summary spacing and several health-summary weights. The current source still has separate summary-fact health zero/half-pixel spacing and summary-health 900/950 weights noted above.
- Subscription invoice-queue composition, accent competition and subscription invoice destinations were previously assigned to Phase 241. The specific global invoice-queue panels from the original capture are absent in current source, so they are recorded as resolved through later scope changes rather than carried forward as current defects. The current subscription page has not been visually recaptured here.
- Phase 243 retains ownership of final reviewed Linux goldens. The former **13/24** score is the original pre-fix audit score, not this current source/evidence score.

## Files Audited

- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-UI-SPEC.md`
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-CONTEXT.md`
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md`
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-01-PLAN.md` through `240-06-PLAN.md` and the six corresponding summaries
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-UI-REVIEW.md` (prior review and correction ledger)
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-REVIEW-FIX.md`
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-REVIEW-DISPOSITION.md`
- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-SECURITY.md`
- `.planning/phases/240-shared-system-and-real-billing-exemplar/captures/phase237-exemplar/manifest.json` (historical metadata; image files not inspected)
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex`
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex`
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `accrue_admin/lib/accrue_admin/copy/invoice.ex`
- `accrue_admin/assets/css/app.css`
- `accrue_admin/assets/css/theme.css`
