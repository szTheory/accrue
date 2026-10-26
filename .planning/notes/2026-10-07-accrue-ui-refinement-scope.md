---
date: "2026-10-07 08:57"
promoted: true
promoted_milestone: v1.63
delivered: 2026-10-09
---

# Accrue UI refinement: proposed milestone brief

Status: historical kickoff brief, promoted into **v1.63 — Admin and Portal UI refinement**, completed and archived on 2026-10-09 across Phases 233–239. Original recommendations below remain historical; use the [v1.63 archive](../milestones/v1.63-ROADMAP.md) for delivered scope and evidence. The separate [October 9 Admin-only stocktake](2026-10-09-admin-operator-impeccable-kickoff.md) records the new request. Do not treat this brief as an unfinished milestone or repeat its setup interview.

Accepted scope clarification: one reusable Portal supporting personal, organization/custom and mixed billing through host-defined context and action permissions. The owner accepted this direction before requesting the final pre-milestone handoff. The earlier personal-versus-workspace question is withdrawn. The researched integration contract and tradeoffs are in [Portal billable context](2026-10-07-portal-billable-context-contract.md).

## 1. Outcome and settled decisions

Deliver a coherent, readable, responsive baseline across **all existing Accrue Admin and customer Portal journeys**, including the host entry and return seams needed to use them. A support/billing operator, engineer, or customer should understand the object, the observed state, the available action, and its result without interpreting implementation jargon or guessing from color. Give the owner a working preview and concise change summary for optional feedback after automated acceptance.

Confirmed by the owner:

- Engineers and support/billing operators are equal primary Admin audiences. Customers are a separate Portal audience; Phoenix developers adopt and mount the packages.
- Refine Admin **and Portal together**. This supersedes the earlier Admin-only recommendation in the initial research.
- Support personal, organization/custom and mixed billables through the same Portal, with compatible personal defaults and host-owned selection/permissions. This product direction is settled; exact adapter signatures remain implementation choices.
- Use code-first design and inspect rendered results. No image-comp approval loop is required.
- Favor conventional controls, clear hierarchy, consistent domain language, mobile usability, and reusable building blocks.
- Prefer small understandable local code or a copied pattern over another dependency. Add a dependency only for a demonstrated capability and maintenance advantage.
- Automate routine proof and visual review as far as practical; owner feedback is optional refinement, not recurring UAT labor. Avoid paid visual judging and unbounded polish loops.

Recommended scope includes bounded corrections to UI-derived state, amounts, dates, read scope, navigation, supported-action feedback, and existing browser wiring. These directly affect whether the refined UI is trustworthy. A defect crossing a package boundary is not automatically a new feature: fix a demonstrated defect needed by an existing supported journey, with focused proof. New business policy or provider capability remains outside this brief.

## 2. Evidence and what carries forward

Three specialist strands covered product/IA/copy, design/CSS/motion, and delivery/security/verification. Each first reviewed Admin, then extended to Portal after the owner expanded scope. The coordinator compared Scrypath planning/history, current Accrue planning/source, existing visual assets, and relevant official design guidance. Recommendations are a synthesis, not measured user research.

A second, bounded adversarial pass reconciled the combined brief. It removed implied unshipped Portal features, separated Admin identity from host customer branding, made visible feedback and secure-field behavior explicit, identified the new principal/permission seam, and tightened asset/motion/provider proof claims. Further broad fan-out is unlikely to change the plan; the remaining uncertainties are named implementation probes.

- `PRODUCT.md` and `.impeccable/config.json` now record product boundaries and code-first preference. Impeccable initialization is complete; a rendered design contract and Live integration have not been established.
- v1.57 already delivered Home/Subscriptions/shared-system work. Do not replay it as unfinished. v1.56's visual ratchet failed to converge on information architecture and remains explicitly parked; this milestone needs named outcomes, not another scoring loop.
- Saved July PNGs are historical: the source tree differs from their baseline commit `f5f48daa`, including substantial CSS retirement. Magenta timestamp masks are deliberate masks, not visual defects. Commit author dates do not prove tree equality.
- No current Accrue browser render, app boot, build, or test run was performed during this research. First execution work must establish the served-source baseline before relying on screenshots or prior pass counts.
- Scrypath's useful lessons are shared-control fixes, fewer nested boxes, specific observed state, deliberate word choices, stable timestamps, evidence from rendered forms, preview isolation, and finite review. Its v1.43 plan is not evidence of finished implementation. Its palette, exact layouts, tests, and release procedure are not Accrue requirements.

## 3. Surface ownership and complete inventory

### Admin: 21 production routes

Paths are relative to the host-configurable mount. The example uses `/admin`; fixtures also use `/billing`. Keep alternate mounts and legacy `/charges` redirects working.

| Surface group | Existing job | Required refinement |
| --- | --- | --- |
| Home `/` | Find a customer; enter billing/recovery/delivery work | Specific scoped observations, proportional urgency, clear search and task entry; no invented zero-balance target or generalized health verdict. |
| Customers `/customers`, `/:id` | Find a customer, inspect subscriptions/invoices/payments/methods/entitlements/activity | Object context, useful tab/disclosure hierarchy, clear customer vs subscription links and payment-method handoffs. |
| Subscriptions `/subscriptions`, `/:id` | Inspect lifecycle and related evidence; supported cancel/pause/resume/plan/item/quantity/comp actions | Truthful lifecycle and missing-data treatment, local actions, readable details, explicit consequences and eligibility. |
| Invoices `/invoices`, `/:id` | Inspect amounts/items/collection; supported finalize/pay/void/uncollectible/PDF/item actions | Correct state definitions, per-currency amounts, due dates, suitable forms, truthful pending/outcome copy. |
| Payments `/payments`, `/:id` | Inspect payment/charge and fees; supported full/partial refunds | Consistent customer-facing payment term with precise charge/refund detail; amount, eligibility and outcome safety. |
| Recovery `/analytics/recovery`, `/analytics/recovery/subscriptions/:id` | Review recovery over a time window; inspect campaign history | Preserve owner/window/currency and return context; distinguish analytics from actionable work. |
| Events `/events`, `/:id` | Inspect local audit/billing history and linked evidence | Clear local-event meaning, useful filters, accessible IDs and payloads. |
| Webhooks `/webhooks`, `/:id` | Inspect deliveries; eligible retry/replay and resulting evidence | Delivery facts, selection scope, step-up/confirmation, accepted vs processed result and partial failures. |
| Coupons `/coupons`, `/:id` | Inspect terms/redemptions and related codes | Readable quiet inspection; no invented create/edit capability. |
| Promotion codes `/promotion-codes`, `/:id` | Inspect code/restrictions/usage/coupon | Distinct code vs coupon nouns, exact code values and relationship links. |
| Connect `/connect`, `/:id` | Inspect Stripe account readiness; local fee override | Provider specificity, local override vs remote readiness, validation/step-up/result. |

Embedded surfaces are part of coverage: organization selection, global search, filters/sort/pagination, list selection, action drawers, confirmations, step-up, payment methods, entitlements, refund history, PDFs, timelines, payloads, notices, reconnect and theme selection. A route count does not cover these transitions.

### Portal and host customer journeys

There are **seven Portal pages**, bringing the package total to **28 UI surfaces**. Paths below use the example `/billing` mount; support custom mounts. Hosted invoice links are the current invoice-access capability; no local Portal invoice detail/PDF page or subscription-resume action exists.

| Portal page | Existing job | Required refinement |
| --- | --- | --- |
| `/billing` | Billing overview and links | Lead with understandable current subscription/plan facts and next supported action; demote counts/IDs; show partial/unavailable states and an honest return path. |
| `/billing/subscriptions` | List subscriptions, enter detail, cancel renewal for eligible non-Braintree subscriptions | Exact known statuses; no “active” claim for an all-status list; consistent consequence/confirmation from list and detail. |
| `/billing/subscriptions/:id` | Inspect state/dates; supported plan preview/change and cancellation; recovery handoff | Braintree cancellation is immediate; other Portal cancellation schedules period end. Preserve these distinctions and eligibility. Braintree plan preview is unsupported. |
| `/billing/payment-methods` | Inspect masked methods; add/default/delete | Capability-aware action entry, protected/in-use/default constraints, clear confirmation, visible POST/redirect outcome. Updating a card does not prove recovery of an invoice. |
| `/billing/payment-methods/new` | Secure card acquisition through Braintree Hosted Fields | Direct-entry initialization, readiness, nonce submission, retry/back and result; unsupported providers receive an honest supported handoff. |
| `/billing/invoices` | Inspect recent invoices and open recorded hosted links | Show existing amount/currency/date/status, long/missing values and document availability. Current read is limited to 20: label it honestly, with no unsupported retention promise. |
| `/billing/checkout/:token` | Local Braintree checkout and promo preview | Correct charge terms, secure entry, provisional vs final promotion, pending/errors, expired/completed sessions, confirmation/cancel/return. The checkout token alone is not authentication. |

Four POST paths need independent acceptance: payment-method create (`/billing/payment-methods`), set default (`/:id/default`), delete (`/:id/delete`), and checkout completion (`/billing/checkout/:token/complete`). Checkout also has a distinct LiveView tokenized-event path; the same intended guards must hold for each reachable path.

Named example-host scope: `/pricing` plan/action hierarchy and chosen-plan continuity; `/app/billing` workspace selection/current subscription/plan action/immediate cancel/checkout; `/app/organization-scope`; the global workspace payment-recovery banner; relevant `/` entry labels; login/register/logout only for billing return/expiry/selection continuity. The existing host Drop-in card acquisition is a separate path from Portal Hosted Fields and needs its own visible readiness/error treatment where used. Account settings, reports and entitlement diagnostics receive compatibility/handoff checks unless a concrete billing defect requires more.

**Support both ownership models through one Portal.** Core already supports arbitrary Billable schemas and Customer identity by owner type, owner ID and processor. The proposed optional Portal adapter resolves the host-authorized billable and authorizes each operation, while the no-adapter default preserves personal billing. A person may manage their own account, a company, or several authorized accounts without becoming a vendor Admin operator. Host applications own account selection, membership and policy; no universal roles, organization tables or mandatory account picker are needed.

**This contract is not implemented by the current hooks.** `CustomerSession` derives `Billing.customer(current_user)`; the default AuthHook runs after extra mount hooks and resolves again; POST resolution is separate. Auth has no action-policy callback, and the entitlement `billable` callback is unrelated. Preserve the authenticated person as actor; never redefine `current_user` as an Organization. Use one shared resolution/authorization path across HTTP, LiveView actions and reconnect, retaining library customer/resource ownership and provider guards. Authorize before customer provisioning; an invalid explicit selection must not fall back to personal billing.

Pin the account displayed by each form and freshly authorize that same account at submission. An old add-card form must never target a newly selected company. Hosts can keep tabs independently pinned or explicitly invalidate changed context. Hosted provider sessions also need action-appropriate permission: local read access must not mint a broader management URL. Core and host Customer lookups currently omit processor in some paths; align them with the existing composite identity as a bounded prerequisite, without adding dynamic provider routing.

Cadence should demonstrate personal and organization billing through the same package and include a mixed-account fixture. Reuse its verified organization selection and current membership policy: owner/admin mutations and ordinary-member reads remain host rules. These role names are not library requirements. The detailed [context contract](2026-10-07-portal-billable-context-contract.md) supplies compatibility, provisioning, attribution and acceptance cases. No either/or product decision remains pending.

Stripe Checkout/customer portal and hosted invoice documents remain provider-owned. The supported Stripe facade returns upstream URLs; Braintree uses mounted local pages. Return navigation must inspect available server evidence and cannot infer a payment from `checkout=success`. Existing Braintree `return_url` is not consumed by Portal; add a usable validated return using existing host policy, with a safe fallback and no untrusted open redirect. Use existing catalog/plan metadata; generic plan discovery is not currently an API supplied by `PlanResolver`.

Ownership rule: refine shipped package UI and the example host's billing entry/return surfaces where needed to demonstrate the end-to-end journey. Do not redesign unrelated Cadence authentication/navigation/product pages. Provider-hosted pages are external boundaries: improve honest handoff, cancellation, error and return behavior, without promising control over their markup or theme.

## 4. Findings that materially change the plan

These are source findings; runtime checks are still needed for visual appearance and browser wiring.

| Priority | Finding | Consequence and bounded response |
| --- | --- | --- |
| First | `subscription_live.ex` always adds a charge-amount caveat, then checks caveats before lifecycle, producing “billing is not active” for non-past-due records | Render actual lifecycle and separate missing observations. Test active/missing-field and other statuses. Preserve supported action predicates. |
| First | Home/subscription summaries combine draft and open invoices, lose currency, and format totals as USD; missing due date becomes “Due now” | Reuse existing money formatting, group totals by currency or omit invalid aggregate, distinguish invoice states, and render absent dates honestly. No currency conversion or risk engine. |
| First | Subscription list customer-name and subscription-ID links point to the opposite object destinations | Fix labels and links, then execute the route transition and assert the resulting object and owner. |
| First | Home uses unscoped stats alongside scoped links; subscription summary includes an unscoped delivery count | Reproduce in the mounted host with two owners and fix inconsistent query scope. This is a confirmed wiring discrepancy, not a demonstrated tenant exploit. |
| First | A mounted out-of-scope denial browser case is skipped after a reported 500 | Diagnose fixture versus application wiring in the owned proof environment, restore credible browser-seam proof; retain existing server denial tests. A skip is not a pass. |
| First | Portal Hosted Fields attachment and flash display appear inconsistent with existing templates/layouts | Trace and exercise the actual mounted form; repair supported wiring/feedback within the Portal slice. Do not accept a static form screenshot as payment-flow proof. |
| First | Generic checkout subscription error says the card was charged; checkout display uses first-line USD/two-decimal formatting and absent amount can become zero | Only claim charged/completed when the result establishes it. Render available currency/amount facts with core formatting; distinguish missing from free. Do not infer a total from incomplete line items or implement new pricing policy. |
| First | Canonical host bills an Organization, while mounted Portal resolves a User customer | Support personal, organization/custom and mixed hosts through the optional resolve/authorize contract. Keep the person as actor, the billable separate, and all target/permission checks consistent across transports. |
| First | Core/host customer lookup omits processor in paths where Portal no-create resolution includes it | Select/validate the exact existing owner-type/owner-ID/processor identity; test multiple historical provider rows without introducing dynamic processor routing. |
| First | Checkout POST and LiveView readiness checks appear to differ for expired/completed sessions and promo validation | Map both reachable submission paths to the intended existing checkout contract and prove expired, completed, stale-promo and duplicate-submit behavior. Repair a demonstrated guard inconsistency as a bounded existing-flow fix. |
| Shared | Subscription CSS uses 11px labels/13px values, 1px section gaps, many 800–950 weights; page-local 24px buttons override the nominal 44px mobile rule | Restore role-based type/spacing/controls in their owning rules; fix the cascade, delete superseded declarations. |
| Shared | Mobile nav looks modal but lacks a complete modal contract; tooltips/dropdowns can remain trapped in overflowing ancestors | Complete named trigger/state/focus/dismissal/scroll behavior using existing mechanisms; supplement information cannot depend on hover. |
| Shared | Palette has repeated scale/overshoot motion; some tests insist it animate; CSS reduced motion does not prove lifecycle delays disappear | Make keyboard actions immediate; keep purposeful occasional transitions; update the old contract and verify actual dismissal/focus timing. |
| Content | Broad health claims, repeated global invoice commands, internal narration and mismatched invoice lenses are pinned by old tests | Replace unsupported claims and redundant copy while preserving scoped links, permissions, safety/legal wording and truthful results. |
| Verify | Bulk webhook selection counts may exceed actual eligible/attempted results | Exercise changed/partially eligible selection; report observed counts and outcomes instead of blanket success. |

Source anchors: `accrue_admin/lib/accrue_admin/live/{dashboard,subscriptions,subscription,webhooks}_live.ex`; `accrue_admin/assets/css/{theme,app}.css`; shared components/hooks; matching LiveView tests; `examples/accrue_host/e2e/verify01-admin-denial.spec.js`; `accrue_portal/lib/accrue_portal/{router,customer_session,billing_read_model,layouts,copy}.ex`, its live modules/controllers, and `priv/static/accrue_portal.js`; host `subscription_live.ex`, `Auth`, recovery banner and `Billing.Plans`; core `checkout/local_session.ex` and Braintree processor session creation.

Additional Portal copy defects belong in the same bounded pass: known trial/incomplete/unpaid statuses collapse into Active/Unknown; canceled billing is stated as guaranteed loss of host access; recent-20 invoices are treated as a complete count; an unsupported seven-year retention promise appears in copy. State the actual billing facts and host-owned access/retention limits. Payment-method read errors currently pattern-match success; introduce an explicit unavailable outcome instead of converting failure into emptiness.

## 5. Decisions, alternatives and guardrails

| Decision | Recommended choice | Tradeoff / rejected default |
| --- | --- | --- |
| Visual identity | Keep Admin's ratified Geist/Geist Mono/Cobalt identity and the customer's host branding; improve hierarchy and consistency | Cadence intentionally has different customer branding. Rebranding consumes effort without evidence it fixes task problems. Existing bad geometry is not protected by brand continuity. |
| Shared system | Align semantic roles and brand tokens, preserve package ownership and audience-appropriate density | Do not make Portal depend on Admin or migrate both to a new component framework merely to share CSS. Small adapters/local patterns are acceptable. |
| Portal structure | Keep buildless Portal assets and public `--accrue-*` tokens; extract only repeated local shell/control/feedback patterns | Admin's `--ax-*` system and build task are not Portal's asset contract. Do not rename public tokens or impose the Admin shell. |
| Customer data | Lead with existing readable plan/state/date/amount; retain identifiers as supporting references | Use existing catalog labels where available. Missing plan metadata is an integration limitation, not permission to invent a price/catalog or show zero. |
| Typography and space | Essential text/actions use 14–16px roles; 12px for secondary metadata; coherent rem scale, section rhythm and line length | Avoid tiny text to preserve columns and avoid inflating all data tables. Numeric choices are design targets, not WCAG font-size rules. |
| Information hierarchy | Identity → observed state/facts → appropriate action → related records/history; retain diagnostic detail with deliberate disclosure | No compulsory card grid, six-band detail template, stats strip, health badge or decorative chart on every page. |
| Component selection | Tables for comparison, definition lists for facts, timelines for chronology, forms for decisions; mobile priority chosen explicitly | Consistency is not identical layout. Avoid nested narrow tables and using cards to repeat a few already grouped facts. |
| Navigation/actions | Labels predict destination and consequence; object actions stay local; common controls remain visible | Menus/disclosure are for secondary tasks, not a remedy for overloaded layout. Do not create separate support/engineer modes. |
| State and copy | Describe available evidence and action results precisely; maintain concise domain vocabulary | Missing/stale does not mean zero, inactive or successful. Never invent a health score, overdue date or processor outcome. |
| Responsive behavior | Reflow content, preserve essential data/actions, use purposeful table scrolling where needed; 44px standalone touch targets | Desktop compression and mobile hiding are not substitutes for hierarchy. Verify real local controls, not only the component kitchen. |
| Motion | Immediate keyboard navigation, focus and repeated task operations; short interruptible drawer/feedback motion where useful | No bounce, count-up, staggered records, animated sorting, gratuitous hover travel or animation library by default. |
| Floating surfaces | Reuse current overlay/focus/scroll mechanisms, choose explicit modal vs nonmodal semantics | Native popover is an option after support/lifecycle review, not a mandatory rewrite. Collision math alone cannot escape CSS clipping. |
| Secure payment input | Keep Hosted Fields inside the official SDK boundary; use supported container and iframe styling, ready/error/tokenize/teardown states | Outer CSS cannot style cross-origin fields. Preserve pinned scripts, SRI, CSP and nonce-only acquisition; no custom card inputs or SDK switch just for visual consistency. |
| Dependencies | Start with current Phoenix/HEEx/CSS/hooks; compare maintenance/capability cost for any addition | Copy small comprehensible patterns with license attribution; do not copy a whole framework or hand-roll payment security to avoid an existing official SDK. |
| Verification | Cheapest credible layer for each invariant, rendered browser journeys for browser behavior, bounded current visual inspection | Neither passing string tests nor pixel equality proves usable information architecture. No new paid evaluator, parallel evidence framework or blanket new CI job. |
| Scope evolution | Add a focused case for a unique surface or demonstrated consequential defect | Do not exhaust every speculative lens, rebuild core billing policy, or expand supported providers/features to improve a screenshot. |

Pattern guidance supports this composition: [GOV.UK summary lists](https://design-system.service.gov.uk/components/summary-list/) distinguish facts from tables, and [details](https://design-system.service.gov.uk/components/details/) reserve disclosure for information fewer users need. [Carbon's table guidance](https://www.carbondesignsystem.com/building-blocks/core/components/data-table/guidelines) emphasizes room for data and appropriate row/global actions. These are precedents for our decisions, not dependencies or visual templates.

### Building-block coverage

The existing Admin manifest has 21 component families and eight composition groups. Reconcile its consumers once rather than create another registry. Portal contributes its small repeated controls and secure-payment integration; each item below needs applicable default/hover/focus/active/disabled/read-only/pending/invalid/open behavior, without generating meaningless states for noninteractive content.

| Building blocks | Contract to settle in actual consumers |
| --- | --- |
| App shell, navigation, topbar, breadcrumbs, page header/actions | Current location/scope, actual heading structure, readable wrapping, persistent desktop navigation and complete phone drawer behavior. |
| Buttons, icon controls, text/number inputs, selects | Named intent, real focus, consistent geometry/spacing, label/error association, stable pending state and touch targets. |
| Status, flash group, dunning/recovery banner | Specific fact/severity, appropriate persistence and announcement, no color-only meaning or false claim; Portal gets visible feedback. |
| Cards/KPIs, stat summaries, charts, detail facts/fields/sections | Correct units/scopes, readable key/value hierarchy, honest unknown/zero and meaningful grouping; no mandatory card or KPI treatment. |
| Data table/mobile records, selection, empty/loading/error/pagination | Essential identity/state/action, comparison where needed, reachable full values, distinct filtered-empty and failed data; only one representation keyboard-accessible. |
| Search, filter chips, sort, reporting-window selector | Discoverable query/scope, understandable result/filter state, immediate keyboard operation and preserved URL/back context. |
| Tabs/subviews and related resources | Accurate names/destinations, accessible keyboard semantics, meaningful counts and return context. |
| Dropdown, tooltip, detail drawer, modal confirmation, step-up | Proper modal/nonmodal behavior, clipping/layers, topmost dismissal, focus containment/restoration and scroll ownership through patches. |
| Timeline, JSON viewer, identifiers/copy | Useful chronology, inspectable technical evidence, wrapping or intentional local scroll, truthful clipboard feedback; never hide essential facts behind hover. |
| Portal shell/summary row/inline confirmation, secure fields, promo preview | Customer-readable task flow, consistent outcomes, provider-aware consequence, readiness and final-validation boundary; real nonce submission and cleanup. |

The eight existing Admin composition groups cover header/actions/breadcrumbs; toolbar/search/filter/sort; table/empty/loading/error/pagination; KPI/chart/table; detail header/metadata/actions; modal confirm; drawer/form; tabs/subviews. This inventory describes coverage, not a requirement to use every group on every page.

## 6. Domain language and state contracts

Use a short glossary tied to existing `Copy` modules and package concepts. No new copy-management framework.

| Concept | Operator/customer wording rule |
| --- | --- |
| Customer / organization | Keep the billed party and current authorization scope explicit; do not use these nouns interchangeably. |
| Subscription | Lifecycle status is one fact. Outstanding invoices, next renewal and missing local observations are separate facts. |
| Invoice | Draft, Open, Paid, Void and Uncollectible remain distinct. “Overdue” requires applicable due-date evidence. Name the current view/filter. |
| Payment / charge / refund | Use Payments for navigation; explain processor charge detail where relevant. A refund request, pending refund and completed refund are distinct. |
| Event / webhook delivery | Events describe recorded billing/audit history; webhooks describe received delivery/processing evidence. Retry/replay wording states what was queued, not assumed downstream completion. |
| Plan / coupon / promotion code | Plan names and amounts remain understandable to customers; a coupon defines terms, a promotion code is the entered code. Do not globally replace technical nouns where precision matters. |
| Missing / empty / unavailable | First run, empty queue, no matches, unavailable data, unsupported action and denied access need different wording and recovery. |
| Dates / amounts | Show currency and correct minor units; separate currencies in totals. Use stable readable dates with exact detail available where useful. Clipboard success follows actual success. |

Preserve locked replay/legal wording and action consequences. Ordinary copy may be shortened or renamed deliberately, with its tests/exports updated. This is not permission to globally rewrite public API names.

## 7. Candidate outcome phases and dependency order

Phase numbers are proposals. Each implementation phase must carry its own states, accessibility, mobile behavior, copy, current render inspection, and executable acceptance. Those are not deferred wholesale to the final phase.

| Phase | User-visible outcome | Scope and exit |
| --- | --- | --- |
| 233 — Current baseline and shared visual direction | One coherent direction is visible in a real Admin detail and a Portal overview | Inventory served routes/embedded flows; establish isolated proof and retained preview; capture current surfaces; settle type/space/state/control roles in code; create `DESIGN.md` and scoped UI contract; fix representative density/truthfulness; record old-test migration and package ownership. Settle the bounded generic Portal resolve/authorize contract and provider identity before dependent checkout/self-service slices; probe card binding/feedback and checkout guards. No standalone weeks-long design-system rewrite. |
| 234 — Admin customer and subscription work | Operators can investigate the right customer/subscription and complete supported lifecycle work | Home/search/context, customer/list/detail, subscription/list/detail, truthful state/money/date/scope, eligible actions/confirmations/evidence; direction-honest navigation and retained filters/owner. |
| 235 — Customer plan selection and checkout | Customers can understand an offer and complete or safely leave supported checkout | Host billing entry, package checkout, provider handoff/Hosted Fields, promo/validation/pending/failure/cancel/return states, mobile form completion and current-source asset delivery. |
| 236 — Customer billing self-service | Customers can understand and manage their existing billing within supported capabilities | Portal overview, subscriptions, invoice access through existing hosted links, payment methods, supported plan/cancellation actions, confirmations, notices, theme/branding and safe return to host. No new Portal resume action or local PDF route is implied. |
| 237 — Admin invoices, payments and recovery | Operators can complete money/recovery tasks and inspect the actual result | Invoice states/amounts/items/actions, charge/refund journeys, recovery time/currency/window/history, local context and provider limitations. |
| 238 — Admin diagnosis and remaining surfaces | Engineers can inspect/replay safely; all remaining routes use the settled system | Events/Webhooks/search handoffs and partial results; Coupons/Promotion codes/Connect; unique permissions, data, action and empty/error cases. |
| 239 — Integrated quality and clean handoff | Both interfaces have current evidence and a stable feedback preview | Complete route disposition, representative cross-audience journeys, remaining shared keyboard/motion/theme/reflow issues, current screenshots, required gates, assets/copy/docs, CSS retirement and task-owned cleanup. |

Dependency shape: 233 precedes all propagation; 234 establishes Admin context for 237/238; 235 and 236 share Portal helpers and should have explicit ownership/order. Parallel execution is useful only after shared contracts stabilize and file ownership is disjoint. Keep one owner for each shared CSS/hook/copy file; do not send several workers to append competing overrides to `app.css`.

## 8. Proposed requirements and acceptance allocation

| ID | Requirement and decisive example | Primary phase |
| --- | --- | --- |
| BASE-01 | Current route/flow/component/state inventory with evidence provenance; existing screenshot drift cannot silently become current truth | 233 |
| SYS-01 | Consistent tokens/type/spacing/radii/shadow/layer/control states across real consumers; remove superseded local overrides | 233 |
| SYS-02 | Audience-specific layouts share brand/semantic roles without a new package dependency or forced common template | 233 |
| ADM-01 | Active subscription + missing ancillary data remains Active with specific unknown facts; all lifecycle branches covered | 234 |
| ADM-02 | Draft/open/overdue/null date and USD/EUR/zero-/three-decimal cases render and link truthfully | 234, 237 |
| ADM-03 | Search → nondefault owner → customer → subscription → related record → return retains correct scope/object/context | 234 |
| ADM-04 | Supported lifecycle action preserves eligibility, confirmation, invalid/expired step-up, duplicate protection and evidence | 234 |
| CKO-01 | Supported checkout uses the actual visible form and browser payment hook; valid submit, invalid input, provider failure, cancellation and retry have honest outcomes | 235 |
| CKO-02 | Hosted provider handoff and mounted checkout remain distinct, capability-aware and safe on return; Fake proof never claims live provider parity | 235 |
| CKO-03 | Both reachable checkout submit paths reject/handle expired, already-completed, stale-promo and repeated submission according to existing contract; no invented charge or zero-price claim | 235 |
| CKO-04 | Plan selection survives sign-in/return; actual charge terms come from trusted available metadata; unavailable charge terms produce a clear recovery path instead of asking the customer to authorize a guessed/unknown amount; uncertain result does not invite blind resubmission | 235 |
| POR-01 | All Portal customer views and supported actions are legible, responsive, scoped and consistent with host branding | 236 |
| POR-02 | Payment method add/default/remove and supported subscription change/cancel preserve capability and ownership; list/detail entry points disclose matching consequences before confirmation | 236 |
| POR-03 | Invoice list/existing hosted access and return navigation expose correct customer-specific evidence and handle missing/unauthorized records safely | 236 |
| POR-04 | Success/failure is visible and announced after actual LiveView events and POST/redirects; failed read is not an empty list and generic checkout failure never asserts a charge | 235–236 |
| POR-05 | Direct add-card navigation initializes secure fields; field text/placeholders and focused/invalid containers remain readable in either shell theme; theme/patch changes preserve entered data using supported SDK behavior | 235–236 |
| POR-06 | Trial/incomplete/unpaid/canceled labels preserve known billing state without asserting host access; recent-invoice limits and retention/document availability are truthful | 236 |
| POR-07 | Host return is usable and validated; direct/spoofed success query cannot mark a payment complete; cancel/leave does not imply subscription cancellation | 235–236 |
| POR-08 | One Portal serves personal, organization/custom and mixed hosts with clear billed-entity labels; simple personal use has no required company model or picker; customer billing managers gain no operator access | 233, 236 |
| ADM-05 | Invoice payment/finalization and refunds show exact amount/currency/consequence; accepted, requires-action, failed and completed differ | 237 |
| ADM-06 | Recovery keeps window/owner/currency and historical failures separate from current state | 237 |
| ADM-07 | Event/delivery investigation and replay retain precise evidence, eligibility and step-up; partial selection cannot claim full success | 238 |
| ADM-08 | Coupons, promotion codes and Connect cover all existing read/action states without implying unavailable capabilities | 238 |
| INT-01 | Real Tab/Shift+Tab/Escape/focus restoration work through validation, LiveView patch, nested overlay, removed trigger and reconnect | Each; close 239 |
| INT-02 | Narrow/coarse-pointer controls are usable; 320 CSS-pixel reflow and zoom preserve essential content/actions without page-wide overflow | Each; close 239 |
| INT-03 | Light/dark/system, forced host light/dark, one representative accent and host→Portal theme handoff work; ordinary keyboard actions and reduced-motion lifecycle are immediate | Each; close 239 |
| INT-04 | Empty/no-match/unavailable/unsupported/denied/pending/error/long-content states are deliberately covered at the cheapest credible layer | Each; close 239 |
| SAFE-01 | Actual mounted owner/customer denials and forged actions remain protected; no foreign record or payment token data is exposed | 234–236, 239 |
| SAFE-02 | Optional host adapter resolves billable separately from actor and freshly authorizes each action/intent across HTTP, LiveView and reconnect; unauthorized selection/provisioning/foreign targets fail safely; personal default remains compatible | 233, 235–236 |
| SAFE-03 | Forms/checkout remain pinned to displayed billable/customer/provider across switches and tabs; lookups use full owner/provider identity; hosted-session grants cannot exceed action permissions | 233, 235–236 |
| SHIP-01 | Generated Admin assets, Portal assets, fonts, mounts, CSP, copy exports and documented host integration match served source | Each; close 239 |
| SHIP-02 | Every route/unique interaction has coverage disposition; current required gates and inspected representative renders support completion claims | 239 |
| SHIP-03 | Existing component examples/docs match production; task-owned debris is removed; optional feedback preview survives separately from mutation proof | 239 |
| SHIP-04 | Adopter docs and canonical examples cover personal default, organization/custom and mixed resolution through one Portal; existing actor attribution and default integration remain valid without new auth/runtime dependencies | 233, 236, 239 |

These are requirements to promote and refine at milestone creation, not executed checkmarks. Existing equivalent tests should be reused. A named requirement can have several acceptance cases; a test count is not a coverage definition.

## 9. Automation, visual review and cost control

1. **Establish reality early.** Start the current source in the canonical example using existing instance mechanisms. Identify checkout, asset hashes, fixtures, browser/OS, theme and viewport. No Accrue server was running during research. Keep a persistent feedback preview separate from destructive/resetting proof commands; the host wrapper drops its test DB and Admin reset fixtures share state.
2. **One complete inventory, sampled combinations.** Capture every owned route once for the initial contact sheet, including Portal/host seams; inspect the actual images. Retain focused representative desktop/mobile and light/dark regression scenes for each distinct page family. Explicitly cover opened dialogs/Hosted Fields/validation/replay, which default captures may hide. Do not multiply every route × state × theme × viewport, and do not let a small screenshot budget excuse an unreviewed unique surface.
3. **Proof at the right layer.** ExUnit/LiveView for state/currency/eligibility/permissions/rendered forms; Playwright for real navigation, hooks, focus, CSS, reflow and mounted integration. Exercise rendered controls and causal record/event IDs. Hidden mirror forms, direct URL jumps around a navigation step, broad success counts and synthetic focus are insufficient for the corresponding user behavior.
4. **Preserve useful gates, migrate obsolete decisions.** Record old assertion → protected behavior → replacement assertion → retired visual choice. Keep server authorization, irreversible-action safeguards and locked copy. Reuse existing required CI and browser launches; do not revive parked ratchet acceptance or loosen all historical checks. The ratchet guardrail is parked; its machinery selftests and waiver/expiry relationships remain blocking. Confirm configured CI jobs and actual results separately. Refresh existing pixel baselines in their established Linux/browser environment; removing them or triggering a conditional skip is not a successful migration.
5. **Review in bounded batches.** For each delivered slice, collect named findings, fix a batch, then confirm the affected scenes. Stop discretionary aesthetic variation after the direction and criteria are met. Consequential broken behavior remains a defect to fix; a review budget cannot turn it into completion. Review the integrated contact sheet once, rerunning affected scenes after shared changes.
6. **No added model/API spend.** Use current local browser tooling and agent inspection. Reuse deterministic Fake/provider-contract fixtures. Provider-live lanes require their own existing credentials and value; they are not invented as a blanket UI gate.
7. **Measure modestly.** Record existing bundle bytes, font/assets failures, representative cold/warm task timings and repeated hook lifecycle behavior. Set regression limits from evidence; no arbitrary Lighthouse perfection target. Record incremental CI runtime after implementation, not a speculative saving.

Accessibility target remains WCAG AA, with automated checks and real keyboard/reflow/state evidence. Current axe scope does not prove full conformance. Inspect newly open/error states and disposition incomplete/new lesser-severity findings; do not claim certification. [Playwright's accessibility guidance](https://playwright.dev/docs/accessibility-testing) describes the limits of automation; [APG modal guidance](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) informs focus and dismissal behavior.

Portal needs explicit coverage placement: the current host mobile project selects an Admin-specific file, and Admin's component/visual/build checks do not cover Portal automatically. Add a targeted Portal mobile case to the existing host lane. For card wiring, use the real shipped Portal JS and a small test-only substitute at the SDK boundary; assert actual tokenize/event-or-POST behavior and resulting record identity. Keep independent pinned-script/CSP/SRI contracts. This proves local integration, not live provider network behavior or real cross-origin field accessibility. Initial-page axe cannot establish either.

Prove secure-field lifecycle through delayed SDK readiness, failed initialization/tokenization, retry, promo-triggered LiveView patch, theme change mid-entry, disconnect and navigation during initialization. No duplicate frames/listeners/subscriptions, silent enabled-but-inert submit, lost non-sensitive form input, or false success. Verify what the pinned SDK supports before requiring dynamic iframe restyling; a stable secure-field palette readable inside both shell themes is a valid smaller solution. A test substitute cannot prove actual cross-origin field retention or accessibility. Treat the host's existing Drop-in flow separately from Portal Hosted Fields; use each where its existing customer journey actually leads.

Theme continuity is also an integration seam: Cadence uses `phx:theme` storage, while Portal/Admin use `accrue_theme`. A small documented host bridge can preserve the choice; respect forced host theme policy and do not build a universal theme manager. Portal assets are buildless but embedded at compile time: recompile package/host router after changes and retrieve the expected new hashes/bytes. Admin's build command does not perform that Portal work.

Motion policy applies to both audiences: repeated keyboard interactions are immediate, occasional transitions are short and interruptible, and reduced motion removes nonessential travel/scale/shimmer without hiding busy/results. Preserve current tokens where appropriate. [Kowalski's guidance](https://emilkowal.ski/ui/you-dont-need-animations) supplies the frequency/purpose rationale; it does not imply using React or adding a spring library to Phoenix.

## 10. Adversarial review and scope boundary

- A beautiful badge can still lie. Assert missing/stale/mixed-state counterexamples independently of visual styling.
- Shared branding can erase customer needs. Portal needs task clarity and reassuring payment feedback; Admin needs efficient comparison and investigation. Share roles, not every composition or control density.
- “Copy before dependency” can create an unmaintainable widget or insecure payment input. Keep official processor SDK/tokenization and server trust boundaries; copy only small owned patterns with clear provenance.
- Simplification can hide a consequence, unsupported capability or engineer evidence. Keep necessary facts/actions visible and deeper evidence reachable.
- Browser success on the first organization or Fake processor can hide scoping and provider errors. Prove an actual nondefault-scope transition and preserve provider-specific deterministic cases.
- A screenshot refresh can enshrine a regression. Inspect changed images and semantic behavior before accepting a baseline; mask only genuinely volatile timestamps, never substantive money/status/action text.
- CSS cleanup can break host branding, stacking, fonts or compiled delivery. Migrate by component ownership and check actual delivered assets; a local source edit does not prove a mounted package changed.
- Exhaustive automation can become its own project. Reuse registries, fixtures, jobs and required GSD evidence; add only checks with a named failure they can discriminate, including a known-positive control for absence guards.

Outside scope: new processors, billing actions, checkout capabilities, diagnosis/causality APIs, risk scores, currency conversion, Usage/fee-reconciliation rooms, broad auth/runtime redesign, unrelated host pages, provider-hosted visual redesign, rebrand/framework migration, new density/settings mode, new paid evaluator, and wholesale CI rearchitecture. Existing checkout and Portal are explicitly included; “new checkout capability” is the exclusion. The narrowly described generic Portal resolve/authorize contract supports the library's personal/company/custom use cases. Universal tenancy/roles/account discovery, consolidated payer arrangements, operator impersonation and dynamic multi-provider routing remain outside this integration change.

## 11. Completion and next transition

The milestone is complete when every current owned surface has a disposition, requirements have current executable evidence, representative rendered results have actually been inspected, necessary asset/copy/docs changes ship with source, no new unexplained skips substitute for acceptance, and the preview and cleanup handoff are accurate. Use existing SUMMARY/executable-UAT/VERIFICATION and archive-aware evidence rules; preserve the honestly parked ratchet lane. Optional owner taste feedback can open a subsequent bounded iteration.

Before formal activation, consume this brief through the new-milestone workflow, reconcile the stale completed-v1.62 planning header with the recorded release/resting state, and promote the requirement/phase proposals into the canonical PROJECT/REQUIREMENTS/ROADMAP artifacts. Do not invent unfinished release work from stale historical wording. No further broad research or repeated audience/build-path interview is needed.

Authority should remain clear: `PRODUCT.md` owns product boundaries; ratified brand records and source tokens own identity; the future `DESIGN.md` records the rendered visual direction; phase UI-SPEC describes scoped application/acceptance; source/components own implementation. Link these records rather than copying conflicting token catalogs into every phase.

## 12. Evidence index

Local inputs: `PRODUCT.md`; `.impeccable/config.json`; `.planning/milestones/v1.52-phases/180-brand-audit-dna-lock/BRAND-DNA.md`; `brandbook/voice.md`; `.planning/processor-support-matrix.md`; `.planning/seeds/SEED-004-admin-ui-blueprint-redesign.md`; v1.56/v1.57 milestone records; Admin router/baseline manifest, components, hooks, CSS, LiveViews and existing tests; Portal router/components/layouts/assets and canonical host billing source; current CI workflows and browser wrappers. Source locations are relative to the repository, not machine-specific paths.

Scrypath inputs (sibling project, read-only): `.planning/reference/OPERATOR-UI-QUALITY.md`, `OPERATOR-UI-REFINEMENT.md`, `.planning/research/v1.42/UI-{SYSTEM,STRUCTURE,AUTOMATION}.md`, phase173 context/UI-SPEC and recent commits. Transfer lessons only; its active work and repository were not modified.

Further primary references used by the specialists: [Stripe subscription lifecycle](https://docs.stripe.com/billing/subscriptions/overview), [Stripe invoice transitions](https://docs.stripe.com/invoicing/integration/workflow-transitions), [Stripe customer management](https://docs.stripe.com/customer-management), [Stripe checkout return](https://docs.stripe.com/payments/checkout/custom-success-page?payment-ui=stripe-hosted), [Braintree Hosted Fields overview](https://developer.paypal.com/braintree/docs/guides/hosted-fields/overview/javascript/v3/), [Hosted Fields styling](https://developer.paypal.com/braintree/docs/guides/hosted-fields/styling/javascript/v3/), [HostedFields API](https://braintree.github.io/braintree-web/current/HostedFields.html), [Drop-in customization](https://developer.paypal.com/braintree/docs/guides/drop-in/customization/javascript/v3/), [Phoenix JS interop](https://phoenix-live-view.hexdocs.pm/js-interop.html), [CSS cascade](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascade/Introduction), [Popover API](https://developer.mozilla.org/en-US/docs/Web/API/Popover_API), [reduced motion](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion), [Playwright visual comparisons](https://playwright.dev/docs/test-snapshots), [Lighthouse performance scoring](https://developer.chrome.com/docs/lighthouse/performance/performance-scoring). External patterns inform recommendations; repository support contracts determine Accrue capability. Current Phoenix and Braintree documentation can be newer than installed/pinned versions, so implementation must use APIs present in the checkout. Online sources were inspected on 2026-10-07.
