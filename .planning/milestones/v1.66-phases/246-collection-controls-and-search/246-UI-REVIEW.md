# Phase 246 — UI Review

**Audited:** 2026-10-11  
**Baseline:** Approved [246-UI-SPEC.md](246-UI-SPEC.md), owner feedback, and Impeccable Operate guidance  
**Screenshots:** Six existing captures reviewed. They are revision-bound to pre-identity-adoption sources (`ffb7f872` for table-reading; earlier Plan 03 source digests for global search). No current-revision screenshots were captured.  
**Interaction captures:** off (`workflow.ui_interaction_capture` is false); interaction findings are code- and recorded-test-derived.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Search retry wording is clear and scoped, but differs from the approved error sentence. |
| 2. Visuals | 3/4 | The six captures show a clear search hierarchy and readable table identity; they do not show the current five-consumer identity adoption or collection toolbar. |
| 3. Color | 4/4 | Reviewed light/dark samples use the existing neutral surfaces and reserve cobalt for active/focus states. |
| 4. Typography | 4/4 | The reviewed samples maintain a readable name-to-ID hierarchy with technical identifiers in mono. |
| 5. Spacing | 3/4 | The shared segmented-control track uses 2px/3px internal geometry despite the contract declaring no spacing exceptions. |
| 6. Experience Design | 3/4 | Recorded mounted checks cover the specified interactions and states; current-revision visual evidence remains outstanding for the late identity change. |

**Overall: 20/24**

---

## Top 3 Priority Fixes

1. **Carry forward a current-source render check for the five late identity-cell consumers** — reviewers cannot visually verify their new copyable IDs from captures made before the change — capture representative wide and 320px light/dark states in the already planned Phase 248 evidence pass, bound to its source and served assets.
2. **Resolve the segmented-control spacing exception against the approved scale** — the current 2px gap and 3px inset do not meet the phase contract — use token-scale geometry if this control is touched for another named defect, or document an explicit contract exception in a future approved spec.
3. **No additional source-level shipping fix is supported by the inspected evidence.**

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**WARNING —** The global-search error reads “Results couldn't be loaded. Successful groups remain available.” and the action says “Retry failed groups” ([global_search.ex](../../../accrue_admin/lib/accrue_admin/components/global_search.ex:322)). This explains partial retention and scopes retry well, but differs from the UI-SPEC's literal “Results couldn't be loaded. Try again.” The mounted partial-search capture shows the current-style error and retry affordance at the earlier Plan 03 source revision. No task-completion defect is evident; reconcile the approved copy contract when it is next revised rather than weakening the scoped retry wording.

The same component uses the explicit search trigger, plain-language orientation and named result groups (lines 289–324). Page-specific filter labels are present in the current collection owners, and the search placeholders name implemented predicates; examples include [charges_live.ex](../../../accrue_admin/lib/accrue_admin/live/charges_live.ex:325), [subscriptions_live.ex](../../../accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:476), and [events_live.ex](../../../accrue_admin/lib/accrue_admin/live/events_live.ex:252). The error-copy mismatch is the only concrete copy deviation found in the audited scope.

### Pillar 2: Visuals (3/4)

**WARNING —** Current source uses the shared identity-cell structure and copyable IDs in the five consumers added after the captures ([coupons_live.ex](../../../accrue_admin/lib/accrue_admin/live/coupons_live.ex:255), [events_live.ex](../../../accrue_admin/lib/accrue_admin/live/events_live.ex:450), [charges_live.ex](../../../accrue_admin/lib/accrue_admin/live/charges_live.ex:278), [connect_accounts_live.ex](../../../accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex:510), [webhooks_live.ex](../../../accrue_admin/lib/accrue_admin/live/webhooks_live.ex:930)). The table captures are from `ffb7f872`, while the identity change was adopted at `d1840677` and the audited HEAD is `e1a65408`; therefore the images do not prove the appearance of those five latest renderers. The captures also show the test-only `/admin/__phase246/states` probe for table reading, not a production collection toolbar. The source and recorded mounted checks support behavior, but visual acceptance for these exact changes belongs in the already-planned Phase 248 integrated proof.

Within the evidence that is current for its source, the search dialog has a clear focal input, restrained grouped results, a subordinate footer and one active result; the table probe separates readable identity from the exact ID and wraps the long string at 320px. The identity-gap summary records five consumer fixes and passing focused tests; it does not replace current rendered evidence.

### Pillar 3: Color (4/4)

No color defect was visible in the reviewed samples. The search active row and focus treatment use the existing accent selection while the dialog/table remain on the theme's neutral elevated surfaces. The current search rules reference `--ax-interactive-selected` and `--ax-accent` at [app.css](../../../accrue_admin/assets/css/app.css:4399); the filter and chip rules use theme-aware accent and status tokens (lines 1270–1287, 1321–1323). Wide light/dark table captures preserve readable contrast and do not turn each status or filter into a bright accent. The latest identity adoption has no fresh render, so this score applies to the reviewed search/table compositions and current shared token rules, not a claim that every changed consumer was visually recaptured.

### Pillar 4: Typography (4/4)

No typography defect was visible in the reviewed samples. The dialog keeps record names prominent, secondary details subdued and exact IDs in a distinct code treatment; the 320px table sample still keeps the customer name recognizable above the wrapped identifier. Current identity markup preserves these semantic layers through primary and secondary slots in [data_table.ex](../../../accrue_admin/lib/accrue_admin/components/data_table.ex:14). Shared filter chips use 14px/600, matching the UI-SPEC's compact label role ([app.css](../../../accrue_admin/assets/css/app.css:1257)). No font-family change is indicated by this audit.

### Pillar 5: Spacing (3/4)

**WARNING —** `.ax-segmented` sets a 2px internal gap and 3px track inset ([app.css](../../../accrue_admin/assets/css/app.css:1036)), while the approved scale explicitly says there are no exceptions and disallows new sub-4px geometry. Its own comments call these values exceptions. This is a concrete contract mismatch, although the reviewed dialog and table captures do not show a broken layout. Avoid a standalone cosmetic pass; if another named defect requires changing this control, align it to the 4px scale or obtain a spec-level exception.

The shared collection layout otherwise uses the declared spacing tokens for toolbar gaps, chip wrapping, 44px removal targets, identity separation and table/card layout (for example [app.css](../../../accrue_admin/assets/css/app.css:3477), 3604–3642). The E1 controls themselves were not visually captured in the six requested images, so their exact rendered grouping is not independently judged here.

### Pillar 6: Experience Design (3/4)

**WARNING —** The available image set does not include a current-source collection-filter capture, and the table captures predate the five identity renderers added by `d1840677`. This leaves a targeted visual-proof gap for the latest rendered hierarchy, even though [246-VALIDATION.md](246-VALIDATION.md) and the Plan 04 summary record the mounted E1/E2/E3 state and behavior checks. The recommended next step is the bounded Phase 248 render proof, not an unscoped browser rebuild in this audit.

Code and recorded tests show visible labels/legends, a true checkbox-group legend, a native secondary `Filters` disclosure, a single scoped reset, accessible remove names and a 44px target ([data_table.ex](../../../accrue_admin/lib/accrue_admin/components/data_table.ex:621), [filter_chip_bar.ex](../../../accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex:83), [app.css](../../../accrue_admin/assets/css/app.css:1300)). Plan summaries report URL/control/query/row, pointer/keyboard/ARIA/Enter, loading/partial/error, and responsive zero/one/many checks passing. This review did not repeat those browser interactions. Interaction screenshots are off per configuration; no interaction state is claimed as freshly captured.

---

## Files Audited

- `.planning/phases/246-collection-controls-and-search/246-UI-SPEC.md`
- `.planning/phases/246-collection-controls-and-search/246-CONTEXT.md`
- `.planning/phases/246-collection-controls-and-search/246-VALIDATION.md`
- `.planning/phases/246-collection-controls-and-search/246-01-PLAN.md` through `246-04-PLAN.md`
- `.planning/phases/246-collection-controls-and-search/246-01-SUMMARY.md` through `246-04-SUMMARY.md`
- `.planning/phases/246-collection-controls-and-search/246-IDENTITY-GAP-SUMMARY.md`
- `.planning/notes/2026-10-11-admin-owner-feedback.md`
- `PRODUCT.md`
- `accrue_admin/lib/accrue_admin/components/data_table.ex`
- `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex`
- `accrue_admin/lib/accrue_admin/components/global_search.ex`
- `accrue_admin/lib/accrue_admin/live/{charges,coupons,connect_accounts,customers,events,invoices,promotion_codes,subscriptions,webhooks}_live.ex`
- `accrue_admin/assets/css/{app,theme}.css`
- Six existing PNGs under `.planning/phases/246-collection-controls-and-search/captures/phase246-{global-search,table-reading}/` and their manifests
- `$HOME/.agents/skills/impeccable/SKILL.md`

**Registry audit:** skipped; `components.json`/shadcn is not initialized and the approved UI-SPEC lists no third-party registries.

**Recommendation count:** 1 priority evidence follow-up; 1 minor contract-alignment recommendation; 0 blockers.

## Current Render Proof Closure

The previously missing E1 and five late identity consumers now have 24 populated mounted captures in `captures/phase246-current-proof`, from 39a52efe with unchanged final product sources and assets. Two browser lanes passed; manifest validator passed; all 24 full-page images were inspected by the executor. Parent reviewed the montage and source delta. The narrow cards now reuse their identity helper with unique DOM IDs; copy controls meet 44×44 targets. The earlier visual-proof warnings are resolved; original scores and minor contract advisories are retained as historical observations. This does not claim owner acceptance.
