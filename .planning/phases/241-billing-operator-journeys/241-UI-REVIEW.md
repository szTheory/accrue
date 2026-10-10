# Phase 241 — UI Review

**Audited:** 2026-10-10; bounded recheck after `241-UI-FIX.md`  
**Baseline:** Approved `241-UI-SPEC.md` and Phase 240 incumbent roles  
**Screenshots:** Captured mounted desktop (1280×900) and narrow (320×900) subscription views; refreshed evidence is under `evidence/phase237-exemplar/`. Package, compiled-host, and served asset digests match.  
**Interaction captures:** off (workflow.ui_interaction_capture is false)

The initial audit scored **15/24**. The scoped recheck scores **24/24**: all named visual, spacing, color, and experience findings are closed by current source, computed styles, and mounted evidence. The copy concern is nonblocking and closed without a copy change because the current labels explicitly limit what is unknown to Admin; they do not imply a provider-side state.

---

## Pillar Scores

| Pillar | Initial | Current | Recheck disposition |
|--------|---------|---------|---------------------|
| 1. Copywriting | 3/4 | 4/4 | Nonblocking wording advisory; current “in Admin” scope is explicit and truthful. |
| 2. Visuals | 2/4 | 4/4 | Summary spacing and duplicate Recovery destination corrected. |
| 3. Color | 3/4 | 4/4 | The single Recovery link uses the accent link role; warning color remains with status information. |
| 4. Typography | 2/4 | 4/4 | Subscription title now computes to 24px/600. |
| 5. Spacing | 2/4 | 4/4 | Summary and action-header gaps now compute to 4px. |
| 6. Experience Design | 3/4 | 4/4 | No-campaign state has one scoped Recovery link. |

**Initial overall: 15/24**  
**Current scoped recheck: 24/24**

---

## Top 3 Priority Fixes

All three priority fixes from the initial review are closed:

1. **Subscription identity typography** — changed to the incumbent 24px/600 title role; mounted computed style confirms `fontSize: 24px`, `fontWeight: 600`.
2. **Subscription summary spacing** — main, fact-row, and label/value gaps now compute to 4px; the desktop and 320px captures show wrapped facts remain readable.
3. **Recovery CTA duplication and color** — the no-campaign branch renders one scoped `ax-link`; the amber status treatment remains on the dunning state summary.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4; initial 3/4)

- **Closed as nonblocking advisory; no copy change warranted.** The previously questioned labels say “Price is not confirmed in admin” and “Current period is not shown in admin.” “In admin” limits the claim to the current surface’s available projection; it does not assert that the provider lacks the value. The refreshed mounted fixture shows a known price and an unavailable period, while no missing value becomes zero. Current strings are in [subscription_live.ex](accrue_admin/lib/accrue_admin/live/subscription_live.ex:1240).
- Domain action and return labels remain specific (`Cancel renewal`, `Pause collection`, `Back to subscription`, and `Back to Recovery`) and match their route or action meaning.

### Pillar 2: Visuals (4/4; initial 2/4)

- **Closed.** The subscription title and five summary facts now have readable separation at desktop and narrow widths. The fresh mounted captures show the record identity, lifecycle state, current facts, actions, and related billing in that order. Layout is defined in [subscription_live.ex](accrue_admin/lib/accrue_admin/live/subscription_live.ex:287) and [app.css](accrue_admin/assets/css/app.css:5333).
- **Closed.** The no-campaign state and active-campaign shortcut are mutually exclusive, so each renders at most one Recovery destination. See [subscription_live.ex](accrue_admin/lib/accrue_admin/live/subscription_live.ex:422) and [subscription_live.ex](accrue_admin/lib/accrue_admin/live/subscription_live.ex:437); the mounted host asserts exactly one link in the no-campaign state.
- Existing invoice review capture still shows the exact invoice, customer, owner scope, and amount together; the narrow Recovery capture retains distinct customer cards.

### Pillar 3: Color (4/4; initial 3/4)

- **Closed.** The no-campaign recovery destination is now a single `ax-link`, using the current accent link role. Amber remains on the no-campaign/status panel, not on an action control. Current markup is in [subscription_live.ex](accrue_admin/lib/accrue_admin/live/subscription_live.ex:422); obsolete amber action rules were removed from `app.css`.
- The shared theme continues to provide semantic light/dark/system roles in [theme.css](accrue_admin/assets/css/theme.css:12), and mounted asset provenance confirms the host served the package CSS and JS bytes used for the captures.

### Pillar 4: Typography (4/4; initial 2/4)

- **Closed.** The subscription identity title now uses `--ax-type-xl` at weight 600, the approved 24px title role. The refreshed mounted computed style reports 24px/600. See [app.css](accrue_admin/assets/css/app.css:5360).

### Pillar 5: Spacing (4/4; initial 2/4)

- **Closed.** Mounted computed styles report 4px for summary-main, fact-row, label/value, and action-header gaps. Source uses `--ax-space-xs` for those roles in [app.css](accrue_admin/assets/css/app.css:5333), [app.css](accrue_admin/assets/css/app.css:5377), [app.css](accrue_admin/assets/css/app.css:5387), and [app.css](accrue_admin/assets/css/app.css:6197). Long fact text retains `overflow-wrap:anywhere`.

### Pillar 6: Experience Design (4/4; initial 3/4)

- **Closed.** The no-campaign branch renders one Recovery link; the active-campaign link only renders when a campaign is active. The mounted host and subscription LiveView owner assert the unique destination.
- The corrected run record reports Subscription LiveView 39/0, Admin full suite 646/0, both warnings-as-errors compiles passed, host mounted spec 1/1, focused Phase 191 review case 1/1, and focused Phase 199 cases 2/2. The broad Phase 191 run was 26 passed/2 failed; the same two cases passed in an exact desktop/mobile rerun (12/12). This test-run caveat is preserved in [241-UI-FIX.md](241-UI-FIX.md).
- **Evidence limits:** Interaction capture remained off. Browser evidence used a deterministic mounted host and Chromium on macOS. The 320px capture is a viewport simulation, not physical-device or actual browser-zoom evidence. Assistive-technology speech and live-provider outcomes were not observed. Phase 243 still owns final Linux visual goldens.

## Files Audited

- `241-UI-SPEC.md`, `241-CONTEXT.md`, `241-VALIDATION.md`, `241-SECURITY.md`, `241-01..07-PLAN.md`, and `241-01..07-SUMMARY.md`
- `241-UI-FIX.md`
- `evidence/phase237-exemplar/manifest.json` and the refreshed desktop and narrow subscription captures, plus the invoice and Recovery mounted captures
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex`
- `accrue_admin/lib/accrue_admin/live/charge_live.ex`
- `accrue_admin/lib/accrue_admin/live/customer_live.ex`
- `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex`
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`
- `accrue_admin/lib/accrue_admin/components/at_risk_table.ex`
- `accrue_admin/assets/css/app.css`, `accrue_admin/assets/css/theme.css`
- `accrue_admin/lib/accrue_admin/copy/subscription.ex`, `accrue_admin/lib/accrue_admin/copy/invoice.ex`
- `examples/accrue_host/e2e/phase237-admin-billing.spec.js`

