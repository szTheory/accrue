# Phase 253 — UI Review

**Audited:** 2026-10-27  
**Baseline:** Approved `253-UI-SPEC.md`, with `253-CONTEXT.md`, plans/summaries 01–06, production source, and current-run browser evidence  
**Screenshots:** Not captured — no pixel inspection was performed. The current run bundle proves content and geometry only.  
**Interaction captures:** off (`interaction_capture: false`)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Story result snapshots duplicate an action-result link label owned by `SubscriptionLive`. |
| 2. Visuals | 2/4 | Detail-page groups are compressed by 1–3px CSS gaps; no screenshot supports an aesthetic judgment. |
| 3. Color | 3/4 | Semantic light/dark tokens align with the contract, but the rendered 60/30/10 balance was not visually inspected. |
| 4. Typography | 2/4 | The collection H1 is 24px, detail field labels are 14px, and disclosure headings are 20px against the declared scale. |
| 5. Spacing | 2/4 | Detail-page rhythm overrides the specified scale with 1px, 3px, and zero gaps. |
| 6. Experience Design | 3/4 | State owners and mounted journey evidence are strong; this audit captured no focus or expanded interaction states. |

**Overall: 15/24**

Scores reflect source and current-run evidence. The `7707b484d6cfb0986a05ff0792dee8d2` bundle reports 151 passed responsive/content/geometry cells plus reconciliation (152/152); those assertions do not establish visual polish or color balance.

---

## Top 3 Priority Fixes

1. **Restore the detail page’s section rhythm** — the summary, facts, resources, and disclosure groups can read as one compressed block — remove the 1px/3px/zero-gap overrides and use the approved `--ax-space-*` rungs.
2. **Align the typography roles to the contract** — the collection heading and detail metadata do not follow the declared hierarchy — use 28px for the page H1, 12px for field labels, and only the agreed role sizes for section headings.
3. **Keep action-result link copy under one owner** — static result stories can drift from the mounted page — route the snapshot label through a shared `SubscriptionLive`/`Copy` helper instead of repeating its literal.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The result snapshot writes `Open scoped subscription activity` directly in the Storybook scenario adapter at `accrue_admin/storybook/_support/subscription_page_scenarios.ex:180-193`. The mounted owner independently supplies the same literal in `accrue_admin/lib/accrue_admin/live/subscription_live.ex:2090-2096`. Current wording matches, but the static and mounted result paths can diverge. Share the owner/helper for this label.
- The collection’s first-run, filtered-empty, queue-empty, loading, and destructive-review strings are sourced through the existing `Copy` and `DataTable` owners. `Retry` is short, but remains paired with a named alert and explanatory body and is explicitly retained by the contract (`data_table.ex:378-390`).

### Pillar 2: Visuals (2/4)

- **WARNING:** Source order gives the collection a clear H1, description, stat strip, filter toolbar, and results (`subscriptions_live.ex:154-198`), and the detail page leads with the subscription summary before supporting groups (`subscription_live.ex:377-424`). However, the detail page’s CSS reduces the space between those groups to 1px and 3px (`app.css:2988-2990`, `3050-3062`). This weakens the specified title → lifecycle → facts hierarchy. Restore token-sized separation.
- No screenshot or pixel-level visual inspection was available for this audit. The run bundle’s hidden-content and overflow checks are useful geometry evidence, not proof of focal point, balance, or polish.

### Pillar 3: Color (3/4)

- **WARNING:** The source uses semantic surfaces, host accent, semantic status colors, and explicit dark-theme overrides (`theme.css:147-169`, `246-264`; `app.css:2840-2843`, `2935-2968`). Status badges retain readable text and mark the dot decorative (`accrue_admin/lib/accrue_admin/components/status_badge.ex:20-25`). No color-only lifecycle state was found in the inspected components.
- The contract’s 60/30/10 visual share cannot be confirmed from token references or geometry records. Since no pixels were inspected, this pillar does not earn 4/4.

### Pillar 4: Typography (2/4)

- **WARNING:** The collection H1 uses `.ax-display`, which resolves to `1.5rem`/24px, while the contract specifies a 28px page heading (`page_header.ex:37-40`; `app.css:777-785`; `theme.css:25-32`). Bind this heading to the declared page-heading role.
- **WARNING:** Detail field labels resolve to 14px semibold (`--ax-type-sm`) rather than the specified 12px label role (`detail.ex:47-53`; `app.css:6732-6740`; `theme.css:25-32`). Detail disclosure headings also use 20px (`app.css:6515-6527`), outside the contract’s four declared size steps. Align those roles or explicitly amend the contract before treating them as compliant.
- Body copy remains Geist 16px/regular and the detail summary title is 28px/semibold; those roles match the contract (`app.css:930-934`, `5727-5735`).

### Pillar 5: Spacing (2/4)

- **WARNING:** The detail-page shell overrides its normal 16px compact gap with `0.0625rem`/1px; its detail stacks use `0.1875rem`/3px and `0.0625rem`/1px; its field lists use a zero gap (`app.css:2984-2990`, `3044-3062`, `6705-6723`). These values do not use the approved `xs`–`3xl` layout scale and leave adjacent evidence groups crowded. Restore 16–32px grouping and a token-sized fact-row rhythm.
- Collection spacing is more consistent: its page header, filter toolbar, DataTable, card rows, and footer mostly use the declared spacing tokens (`app.css:3064-3075`, `3199-3247`, `3553-3588`, `3760-3878`). The table/card switch remains at 768px (`app.css:3547-3551`, `3743-3758`); the existing run’s geometry tests cover 767/768 and container cases.

### Pillar 6: Experience Design (3/4)

- **WARNING:** No interaction captures were made because interaction capture was off. This review therefore cannot visually confirm focus treatment, disclosure expansion, drawer/step-up presentation, or keyboard progression. The source retains native anchors/buttons/disclosures, child-targeted retry/load-more actions, alert/status roles, disabled confirmation during in-flight states, and polite result announcements (`data_table.ex:378-394`, `567-584`; `subscription_live.ex:405-415`, `583-598`).
- Existing current-run evidence and mounted journey summaries cover distinct empty/loading/error/populated/partial states, real scoped navigation, inert dismissal, fresh review checks, and one authorized dispatch. Static Storybook scenarios are labelled presentation-only and are not counted as interaction proof. No new tests were run for this advisory review.

## Files Audited

- Planning baseline: `253-UI-SPEC.md`, `253-CONTEXT.md`, `253-01` through `253-06` PLAN/SUMMARY files.
- Production composition: `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`, `subscription_live.ex`, `components/data_table.ex`, `components/page_header.ex`, `components/detail.ex`, `components/status_badge.ex`, `components/id_badge.ex`, `copy/subscription.ex`.
- Styles: `accrue_admin/assets/css/app.css`, `accrue_admin/assets/css/theme.css`.
- Story surfaces/adapters: `storybook/groups/subscriptions_collection.story.exs`, `storybook/pages/subscription.story.exs`, `accrue_admin/storybook/_support/subscription_collection.ex`, `subscription_page_scenarios.ex`.
- Responsive evidence owners: `accrue_admin/e2e/phase253-composition-helpers.js`, `subscription-compositions-phase253.spec.js`, `accrue_admin/tmp/phase253/ci-results/7707b484d6cfb0986a05ff0792dee8d2/results.json`, and `accrue_admin/tmp/phase253/render-results-7707b484d6cfb0986a05ff0792dee8d2.json`.

Registry audit: skipped — `components.json` is absent and the UI spec declares no third-party registry blocks.

**Recommendation count:** 3 priority fixes; 0 additional minor recommendations.
