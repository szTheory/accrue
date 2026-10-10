# Phase 241 — UI Review

**Audited:** 2026-10-10; source-only bounded recheck after `241-UI-FIX.md`\
**Baseline:** Approved `241-UI-SPEC.md`, inherited Phase 240 incumbent roles, and the scoped corrections recorded in `241-UI-FIX.md`\
**Screenshots:** Not captured for this recheck. Existing `evidence/phase237-exemplar/` captures and their mounted measurements are historical evidence from the prior correction batch; they are not treated as proof of current served output.\
**Interaction captures:** off (workflow.ui_interaction_capture is false)

The prior review recorded 24/24 after its correction batch. This recheck confirms the copy, title role, and single scoped Recovery destination in current source, but it cannot renew the prior mounted claims without fresh served-output inspection. Current CSS also leaves 2px internal gaps in the subscription action controls; the contract reserves 2px for dense data, so the prior blanket 24/24 disposition does not hold for the source snapshot inspected here. No implementation correction or new capture was made.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Current unavailable-value strings scope claims to Admin; action and destination labels remain specific. |
| 2. Visuals | 3/4 | Source preserves identity, lifecycle, actions, and related-resource ordering; current rendered hierarchy was not recaptured. |
| 3. Color | 3/4 | Current Recovery action is a purposeful `ax-link`; current composition and contrast across themes are unverified. |
| 4. Typography | 3/4 | Subscription title uses the approved 24px/600 token role; current served typography was not measured. |
| 5. Spacing | 2/4 | The action-control group uses a 2px gap despite the contract limiting that exception to dense data. |
| 6. Experience Design | 3/4 | Mutually exclusive Recovery branches and explicit status markup are present; interaction behavior was not freshly exercised. |

**Overall: 18/24**

## Top 3 Priority Fixes

1. **Resolve the 2px action-control gap** — operators can get crowded controls, and 2px is outside the approved dense-data exception — use the 4px token or document an approved action-group exception, then verify served geometry.
2. **Refresh current served-output evidence** — the prior capture manifest predates the source state under review, so the old 24/24 result cannot establish current visuals — rebuild and inspect the corrected package/host output when the visual-evidence budget allows.
3. **Recheck visual behavior across themes and narrow layouts** — contract requirements for effective contrast, focus, and current layout remain unverified by this source-only pass — use the existing bounded desktop/narrow and effective-theme owner checks; reserve Linux goldens for Phase 243.

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- Current unavailable-value copy says “Amount is not confirmed in admin,” “Current period is not shown in admin,” and “Price is not confirmed in admin,” limiting claims to the Admin projection ([subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:1240)). The action labels and route text remain domain-specific in the subscription owner.
- The no-campaign state names the destination as “Open dunning funnel and at-risk analytics” and the state as “No subscription-level campaign here” ([subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:423)). This is specific to the actual Recovery destination.

### Pillar 2: Visuals (3/4)

- Current markup leads with the subscription identity and summary facts, then lifecycle summary, actions, related resources, and deeper detail ([subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:287)). That source order follows the contract, but this recheck did not observe current rendered hierarchy.
- Source conditionally renders the no-campaign shortcut or active-campaign shortcut, so only one Recovery destination is emitted per state ([subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:422), [subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:437)).
- The prior review’s desktop and 320px viewport captures support the earlier correction batch only. The evidence manifest records source head `c1e3224f` and source hashes from that capture run; those measurements are historical and were not treated as current visual proof. Actual zoom, physical-device behavior, and Phase 243 Linux goldens remain outside that evidence.

### Pillar 3: Color (3/4)

- The Recovery destination uses `ax-link` rather than the removed warning-colored action treatment ([subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:425)). Shared design tokens remain the declared source of theme color roles ([theme.css](../../../accrue_admin/assets/css/theme.css:12)).
- The current source inspection confirms semantic class use but cannot substantiate the 60/30/10 composition or contrast in current light, dark, system, and host-forced rendered output. The previous mounted theme and asset measurements remain historical.

### Pillar 4: Typography (3/4)

- Subscription identity now selects `--ax-type-xl` at weight 600, matching the contract’s 24px/600 role ([app.css](../../../accrue_admin/assets/css/app.css:5364)). The current source has the intended role; the 24px computed value in the prior review is historical because this pass did not inspect served CSS.
- The contract permits 400 and 600 weights and the incumbent role map; no migration or generic four-size ceiling is implied. No current cross-surface computed-style distribution was measured.

### Pillar 5: Spacing (2/4)

- Summary main and fact spacing use the approved 4px token, and the fact label/value gap is also 4px ([app.css](../../../accrue_admin/assets/css/app.css:5337), [app.css](../../../accrue_admin/assets/css/app.css:5381), [app.css](../../../accrue_admin/assets/css/app.css:5391)).
- The action header’s outer gap uses the 4px token, but its child control group uses `gap: 0.125rem` (2px) ([app.css](../../../accrue_admin/assets/css/app.css:6201), [app.css](../../../accrue_admin/assets/css/app.css:6206)). The UI contract reserves 2px for dense-data detail, not action controls. This source finding conflicts with the prior review’s generalized statement that action-header spacing was confirmed at 4px; the prior measured values are historical and do not override the current selector. A related action row also uses a raw `0.1875rem` gap ([app.css](../../../accrue_admin/assets/css/app.css:6188)), which should be normalized or explicitly justified against the contract.

### Pillar 6: Experience Design (3/4)

- Current subscription source keeps the Recovery link mutually exclusive across active/no-campaign states, and action results use `role="status"` plus `aria-live="polite"` ([subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:422), [subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:437), [subscription_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscription_live.ex:326)).
- `241-UI-FIX.md` records the earlier focused browser, mounted-host, and Admin test outcomes. No interaction capture was enabled and this bounded audit did not replay controls, keyboard focus, busy/reconnect, or dismissal behavior. Current interaction claims therefore remain source-derived; the old runs are not represented as fresh validation.

## Files Audited

- `.planning/phases/241-billing-operator-journeys/241-UI-SPEC.md`, `241-UI-REVIEW.md` (prior), `241-UI-FIX.md`, `241-EXECUTION-GATES.md`, `241-CONTEXT.md`, and phase plan/summary records
- `.planning/phases/241-billing-operator-journeys/evidence/phase237-exemplar/manifest.json` (historical provenance only; no images inspected)
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `accrue_admin/assets/css/app.css`
- `accrue_admin/assets/css/theme.css`
