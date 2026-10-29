# Phase 254 design review

<!-- Generated from 254-DESIGN-REVIEW.json by scripts/ci/verify_phase254_design_review.mjs --render. Do not edit by hand. -->

**Stage:** corrected
**Source commit:** `4a018ce9a2ed17a8d8d809b71fee6d34fc423ce2`
**Fix commit:** `88cd27cdcede5f00594896b6b752069be7ede0ac`
**Scoring:** none. No aesthetic score is recorded (D-03, D-31); every cell is a source-bound claim or a mechanical result.

## Assets

| Asset | Path | sha256 |
|-------|------|--------|
| app_css | `accrue_admin/assets/css/app.css` | `25d18c954f3c95b4e0f22b01ecde4d0c8168b655e4800da149fb4283f897ee1a` |
| theme_css | `accrue_admin/assets/css/theme.css` | `fbf78dee8fb3982b2157f1db8a4be9c16f6b6fe83ef5b6ce89bc7527db602bc7` |
| accrue_admin_css | `accrue_admin/priv/static/accrue_admin.css` | `63fbca439ae348fbd4ac14b40dbc7fe8ddb48e1d4a6dc3564c0e7eb7d227f299` |
| storybook_css | `accrue_admin/priv/static/storybook.css` | `4253796170bc68e8bf398b12b3a1e9df0321798f511c5ff1bb5962f2bad84fbe` |
| served_css_route | `css-9568fe2780b1ac605777f571b8e278f5` | md5 of accrue_admin.css |

## Rubric verdicts

| Dimension | Verdict | Findings or evidence |
|-----------|---------|----------------------|
| typography | finding | DR-254-02, DR-254-03, DR-254-04, DR-254-06 |
| color | finding | DR-254-06 |
| hierarchy | finding | DR-254-01 |
| redundancy | finding | DR-254-09 |
| affordances | finding | DR-254-08 |
| microcopy | finding | DR-254-05, DR-254-07 |
| journey | assessed-no-finding | captures CAP-254-01, CAP-254-03, CAP-254-05, CAP-254-07, CAP-254-09, CAP-254-11, CAP-254-13, CAP-254-15; accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:305-309, accrue_admin/lib/accrue_admin/live/subscriptions_live.ex:328, accrue_admin/lib/accrue_admin/live/subscription_live.ex:287-298, accrue_admin/lib/accrue_admin/live/subscription_live.ex:646, accrue_admin/lib/accrue_admin/live/subscription_live.ex:406-414; Assessed from source across the capture cells, not from pixels: a collection row's identity link goes to the scoped detail route, the detail page leads with the action band whose buttons open the review drawer, the step-up form submits to one handler, and the result renders as a status region with a scoped activity link, so no dead end or unlabelled step was found on the list, detail, action, result path. Rendered keyboard order and focus return are measured by the UXQ-02 mounted journey, not by this record. |

## Captures

| Id | Key | Sourcing | State | Width | Theme | Route | png sha256 | Pass |
|----|-----|----------|-------|-------|-------|-------|------------|------|
| CAP-254-01 | `phase254-collection-multiple_rows-w320-light` | story | settled | 320 | light | `/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=multiple_rows` | pending | pending |
| CAP-254-02 | `phase254-collection-multiple_rows-w320-dark` | story | settled | 320 | dark | `/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=multiple_rows` | pending | pending |
| CAP-254-03 | `phase254-collection-multiple_rows-w1280-light` | story | settled | 1280 | light | `/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=multiple_rows` | pending | pending |
| CAP-254-04 | `phase254-collection-multiple_rows-w1280-dark` | story | settled | 1280 | dark | `/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=multiple_rows` | pending | pending |
| CAP-254-05 | `phase254-page-active-w320-light` | story | settled | 320 | light | `/billing/dev/storybook/iframe/pages/subscription?tab=active` | pending | pending |
| CAP-254-06 | `phase254-page-active-w320-dark` | story | settled | 320 | dark | `/billing/dev/storybook/iframe/pages/subscription?tab=active` | pending | pending |
| CAP-254-07 | `phase254-page-active-w1280-light` | story | settled | 1280 | light | `/billing/dev/storybook/iframe/pages/subscription?tab=active` | pending | pending |
| CAP-254-08 | `phase254-page-active-w1280-dark` | story | settled | 1280 | dark | `/billing/dev/storybook/iframe/pages/subscription?tab=active` | pending | pending |
| CAP-254-09 | `phase254-mounted-review-open-w320-light` | mounted | review-open | 320 | light | `/billing/subscriptions/:id` | pending | pending |
| CAP-254-10 | `phase254-mounted-review-open-w320-dark` | mounted | review-open | 320 | dark | `/billing/subscriptions/:id` | pending | pending |
| CAP-254-11 | `phase254-mounted-review-open-w1280-light` | mounted | review-open | 1280 | light | `/billing/subscriptions/:id` | pending | pending |
| CAP-254-12 | `phase254-mounted-review-open-w1280-dark` | mounted | review-open | 1280 | dark | `/billing/subscriptions/:id` | pending | pending |
| CAP-254-13 | `phase254-mounted-disclosure-focus-w320-light` | mounted | focus-visible | 320 | light | `/billing/subscriptions/:id` | pending | pending |
| CAP-254-14 | `phase254-mounted-disclosure-focus-w320-dark` | mounted | focus-visible | 320 | dark | `/billing/subscriptions/:id` | pending | pending |
| CAP-254-15 | `phase254-mounted-disclosure-focus-w1280-light` | mounted | focus-visible | 1280 | light | `/billing/subscriptions/:id` | pending | pending |
| CAP-254-16 | `phase254-mounted-disclosure-focus-w1280-dark` | mounted | focus-visible | 1280 | dark | `/billing/subscriptions/:id` | pending | pending |

## Findings

### DR-254-01 hierarchy

- **Origin:** 253#1
- **Owning tier:** page
- **Disposition:** fixed
- **Verdict:** pending
- **Claim:** The subscription detail page overrides its normal group rhythm with page-tier gaps of 1px, 3px and 0 (and a raw 0 0.25rem field gap), so the summary, facts, resources and disclosure groups read as one compressed block instead of the title, lifecycle, facts hierarchy the contract specifies.
- **Rationale:** D-34: delete the page-tier overrides so the component tokens apply and replace the raw field gap with --ax-space-xs. The page tier is the lowest tier that owns these selectors. The mechanical check scanSubscriptionDetailSpacing finds them at source_commit and must find none at fix_commit.
- **Evidence:** `accrue_admin/assets/css/app.css:2988-2990`, `accrue_admin/assets/css/app.css:3050-3052`, `accrue_admin/assets/css/app.css:3060-3062`, `accrue_admin/assets/css/app.css:6709-6712`, `accrue_admin/assets/css/app.css:6720-6724`, `accrue_admin/assets/css/theme.css:35-37`
- **Tests:** `accrue_admin/e2e/subscription-design-phase254.spec.js` (computed, red-then-green, DR-254-01:computed); `scripts/ci/verify_phase254_design_review.test.mjs` (css-guard, green, scanSubscriptionDetailSpacing)
- **Red evidence:** `254-12-01-red-evidence.json`

### DR-254-02 typography

- **Origin:** 253#2
- **Owning tier:** contract
- **Disposition:** contract-amended
- **Verdict:** pending
- **Claim:** The Phase 253 audit reported the collection heading at 24px against a 28px page-heading contract. The shared display rule is already responsive (1.5rem, 24px, below 768px; 1.75rem, 28px, from 768px), so the contract row, not the rule, is wrong; the two rem literals can move to --ax-type-xl and --ax-type-2xl with no visual change.
- **Rationale:** D-34: amend the contract to a responsive heading and leave shared .ax-display semantics untouched. The heading red test is DR-254-02:source (the declared literals); DR-254-02:computed at 767 and 768 CSS px passes before and after by design.
- **Evidence:** `accrue_admin/assets/css/app.css:777-781`, `accrue_admin/assets/css/app.css:2161-2165`, `accrue_admin/assets/css/theme.css:30-31`, `accrue_admin/lib/accrue_admin/components/page_header.ex:39`
- **Tests:** `accrue_admin/e2e/subscription-design-phase254.spec.js` (source, red-then-green, DR-254-02:source); `accrue_admin/e2e/subscription-design-phase254.spec.js` (computed, green-before-and-after, DR-254-02:computed)
- **Red evidence:** `254-12-01-red-evidence.json`
- **Contract:** `.planning/phases/253-real-groups-and-a-whole-subscription-job/253-UI-SPEC.md`, section Typography, amend-row row `Page heading`
- **Amended text:** `&#124; Page heading &#124; Responsive: '--ax-type-xl' (24px) below 768px, '--ax-type-2xl' (28px) from 768px &#124; Semibold 600 &#124; 1.2 &#124;`

### DR-254-03 typography

- **Origin:** 253#2
- **Owning tier:** component
- **Disposition:** fixed
- **Verdict:** pending
- **Claim:** Detail field labels resolve to 14px semibold uppercase (the bare .ax-field-label rule) while the contract label role is 12px semibold, so detail labels are larger than the summary keys they sit beside.
- **Rationale:** D-34: scope a font: var(--ax-type-label-sm-font) rule to .ax-field-list .ax-field-label so detail labels equal summary keys at --ax-type-xs. The bare .ax-field-label stays untouched (six form controls share it) and .ax-field-value keeps tabular-nums.
- **Evidence:** `accrue_admin/lib/accrue_admin/components/detail.ex:49-52`, `accrue_admin/assets/css/app.css:6732-6740`, `accrue_admin/assets/css/theme.css:101`
- **Tests:** `accrue_admin/e2e/subscription-design-phase254.spec.js` (computed, red-then-green, DR-254-03:computed)
- **Red evidence:** `254-12-01-red-evidence.json`

### DR-254-04 typography

- **Origin:** 253#2
- **Owning tier:** contract
- **Disposition:** contract-amended
- **Verdict:** pending
- **Claim:** Detail disclosure headings render at 20px (--ax-type-lg), which is outside the contract's declared size steps, although the brandbook's seven-step type scale in theme.css defines 20px as the title role.
- **Rationale:** D-34: the brandbook scale is authoritative, so the contract gains a Section title role; no CSS changes. The identical duplicate selector is a separate deferral (DR-254-09).
- **Evidence:** `accrue_admin/assets/css/app.css:6523-6528`, `accrue_admin/assets/css/theme.css:29`, `accrue_admin/assets/css/theme.css:105`
- **Contract:** `.planning/phases/253-real-groups-and-a-whole-subscription-job/253-UI-SPEC.md`, section Typography, add-row row `Section title`
- **Amended text:** `&#124; Section title &#124; 20px ('--ax-type-lg') &#124; Semibold 600 &#124; 1.2 &#124;`

### DR-254-05 microcopy

- **Origin:** 253#3
- **Owning tier:** copy
- **Disposition:** fixed
- **Verdict:** pending
- **Claim:** The action-result link label and its scoped events path exist twice: SubscriptionLive owns the literal and the path builder privately, and the Storybook page scenario adapter repeats both, so the static result story can drift from the mounted page.
- **Rationale:** D-34: add Copy.subscription_action_activity_link_label/0 and a public @doc false SubscriptionLive.action_activity_path/3, and have the LiveView and the story adapter call both, as the adapter already does for action_result_message/1. The result link appears after a dispatch, which none of the 16 captures reach, so the proof is an ExUnit owner test plus a literal-count guard.
- **Evidence:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex:2090-2096`, `accrue_admin/lib/accrue_admin/live/subscription_live.ex:2111-2118`, `accrue_admin/storybook/_support/subscription_page_scenarios.ex:188-197`, `accrue_admin/lib/accrue_admin/copy.ex:1001`
- **Tests:** `accrue_admin/test/accrue_admin/dev/subscription_action_copy_test.exs` (exunit, red-then-green, DR-254-05)
- **Red evidence:** `254-13-01-red-evidence.json`

### DR-254-06 typography (+ color)

- **Origin:** assessment
- **Owning tier:** component
- **Disposition:** deferred
- **Verdict:** pending
- **Claim:** The Activity audit log heading is the only section title at font-weight 950 and the only one coloured with --ax-accent-readable. The Phase 253 contract allows two weights and reserves the accent for the eligible action, the selected view, text links and focus; 950 is a third weight and the accent here marks a heading.
- **Rationale:** Whether the audit ledger heading should carry deliberate emphasis is a product and brand judgment the plan does not settle, it cannot be decided by a mechanical check, and the rule is already tagged for the type-system pass. D-36 defers anything that is not one of the five locked dispositions.
- **Evidence:** `accrue_admin/assets/css/app.css:6530-6535`, `accrue_admin/lib/accrue_admin/live/subscription_live.ex:497`

### DR-254-07 microcopy

- **Origin:** assessment
- **Owning tier:** copy
- **Disposition:** deferred
- **Verdict:** pending
- **Claim:** The audit strip is captioned "Audit event table: Actor / Action / Timestamp", which describes a table structure in implementer language, while the element below it is a three-item summary row labelled "Latest audit event summary" and no table.
- **Rationale:** A better caption needs a wording decision the plan does not make, two existing LiveView tests pin the current string, and a copy change would also regenerate the digested manifests. It is real but outside the locked correction batch, so it is deferred with the copy owner as the tier.
- **Evidence:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex:500`, `accrue_admin/lib/accrue_admin/live/subscription_live.ex:502`

### DR-254-08 affordances

- **Origin:** assessment
- **Owning tier:** component
- **Disposition:** deferred
- **Verdict:** pending
- **Claim:** The subscription detail disclosures use &lt;summary class="ax-detail-section-head"&gt;, a flex row with a 22px minimum height, and do not use .ax-disclosure-summary, which gives the webhook detail disclosures a 44px target, a pointer cursor, a chevron and an explicit focus ring. Whether the default marker and focus ring render acceptably is a runtime question; this record asserts only the class difference.
- **Rationale:** Target size and keyboard focus are measured by the UXQ-02 probes (254-11): if they route a defect on summary.ax-detail-section-head it is fixed in the correction batch as a routed accessibility defect; otherwise sharing .ax-disclosure-summary across detail views is a design decision that reaches several LiveViews and is deferred (D-36). 254-13 re-disposition: none of the 30 routed accessibility entries (register at eefee2a62958dbdefe426d5434ed133e91b3e8ec) names summary.ax-detail-section-head (A11Y-254-22 names summary.ax-button, the menu button), and the 151 composition cells now report 0 observations, so no defect was routed and the finding stays deferred (D-36).
- **Evidence:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex:488`, `accrue_admin/assets/css/app.css:6480-6494`, `accrue_admin/lib/accrue_admin/live/webhook_live.ex:273`

### DR-254-09 redundancy

- **Origin:** assessment
- **Owning tier:** component
- **Disposition:** deferred
- **Verdict:** pending
- **Claim:** The detail section title is declared twice with the same colour, size and weight: once globally and once scoped to .ax-subscription-detail-page.
- **Rationale:** D-36 names the duplicate disclosure selectors as a known deferral: removing either rule is a cleanup with no visible effect and sits outside the correction batch.
- **Evidence:** `accrue_admin/assets/css/app.css:6515-6521`, `accrue_admin/assets/css/app.css:6523-6528`

## Amendments

- **AMD-254-03** (D-33): D-33 capture cell "collection populated" -> the Phase 253 multiple_rows collection story, key phase254-collection-multiple_rows-w&lt;width&gt;-&lt;theme&gt;. The Phase 253 collection universe has no populated state: the compiled collection states are new_host_empty, filtered_empty, queue_empty, one_row, multiple_rows, page_boundary, loading, unavailable, partial_cursor_error and incomplete_projection. multiple_rows is the populated collection. Owner acknowledgement: 2026-10-28 owner-accepted at plan time.
- **AMD-254-04** (D-34, D-35): D-35 shows every correction red on the pre-fix commit, which for the heading amendment would be a computed assertion at 767 and 768 CSS px -> The heading amendment's red is carried by DR-254-02:source (the declared font-size literals 1.5rem and 1.75rem against var(--ax-type-xl) and var(--ax-type-2xl)); DR-254-02:computed at 767 and 768 CSS px passes before and after by design. The shared .ax-display rule was already responsive (24px below 768px, 28px from 768px), so the contract row was wrong and the rendered heading does not change; a computed assertion cannot be red for a contract-only amendment, while the token literals are a real source change that can. Owner acknowledgement: 2026-10-28 owner-accepted at plan time.
- **AMD-254-05** (D-08, D-36): Design corrections are confined to the 16 D-33 capture cells (D-36) -> Routed accessibility defects are fixed wherever 254-11 observed them (D-08 W4): 10 routed cells fall inside the 16 captures and 102 composition cells fall outside them, and all are fixed in this batch with their register entries deleted. An accessibility defect is fixed at the lowest tier that owns it, not only on the cells that happen to be captured; the cells outside the 16 are listed here so the wider reach is a recorded, owner-accepted decision rather than silent scope growth. Owner acknowledgement: 2026-10-28 owner-accepted at plan time.

## Changed baselines

None.

## Deferred

| Id | Subject | Tier | Trigger | Finding |
|----|---------|------|---------|---------|
| DEF-254-01 | Global .ax-stack-sm resolves to the same gap as .ax-stack-md (both var(--ax-space-md)) and is widely used | component | A spacing-scale pass that re-examines the .ax-stack-* rungs with its own baseline review. |  |
| DEF-254-02 | Bare .ax-field-label uppercases and enlarges form control labels (checkbox, input, radio, select, textarea, toggle share it) | component | A form label pass; D-34 forbids touching the bare rule in this batch. |  |
| DEF-254-03 | Duplicate detail section title selectors | component | The next cleanup of the detail section CSS. | DR-254-09 |
| DEF-254-04 | Activity audit log heading weight 950 and accent colour | component | The type-system pass that retires the 209/210 type exceptions, or a contract row for emphasised section titles. | DR-254-06 |
| DEF-254-05 | Audit strip caption in implementer language | copy | A UX writing pass over the audit strip, with an owner-approved caption. | DR-254-07 |
| DEF-254-06 | Detail disclosure summaries lack the shared disclosure summary treatment | component | A design decision to share .ax-disclosure-summary across detail views (the 254-11 probes routed no defect on the summary, so that trigger did not fire). | DR-254-08 |
