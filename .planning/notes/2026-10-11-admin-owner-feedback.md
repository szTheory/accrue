# Admin owner feedback — 2026-10-11

Status: owner has proposed using the collected feedback plus a full existing-Admin inspection as the next milestone (proposed v1.66, first Phase 245). Final workflow scope confirmation remains pending. Do not repeat Phase 244 or treat earlier audit passes as current owner acceptance. Keep GSD milestone tags local. Original narrow Admin Search Refinement proposal is superseded by the broader feedback-led baseline scope below.

## Search control and dialog

- Owner screenshots at 07:40–07:41 show an overcrowded topbar trigger: two bold text lines, a nested-looking action badge, shortcut, persistent accent outline. Simplify to one clear search affordance that accurately covers customers, invoices, and subscriptions.
- Dialog guidance dominates the opening state; padding, row density, footer and hierarchy need refinement. “Open a scoped list” sounds internal.
- Tiny spinner appears when idle. Source: `components/global_search.ex:278` lacks a size modifier; `.ax-spinner` declares display and needs a hidden-state check against served CSS.
- Mouse hover and keyboard active selection highlight different rows at once. Source: `assets/js/hooks/command_palette.js` and separate hover/active rules in `assets/css/app.css`. One active target should govern keyboard activation and visible selection; preserve focus and pointer usability.

## Webhook detail

Observed route: http://accrue-host-phase243-preview.localhost/admin/webhooks/19100000-0000-4000-8000-00000000a008

Source owner: `accrue_admin/lib/accrue_admin/live/webhook_live.ex`; shared Detail, Breadcrumbs, Timeline and JsonViewer components.

- Breadcrumb “Dashboard / Back to webhooks / [event ID]” mixes hierarchy with action wording. Separate any return action from destination labels; preserve actual return filters and owner scope.
- Page heading inside a summary card, “Webhook inspector” eyebrow, raw type as title, and bare “Dead” status feel awkward. Assess a page-level heading and semantic status badge without asserting failure beyond actual webhook state.
- ID and status repeat in summary and full metadata list. Reorder by operator task: identify event, understand observed processing state, see supported next action, investigate evidence. Reduce duplication and undifferentiated information dumps.
- User requests a consistent timestamp-copy convention throughout Admin: clicking a timestamp copies its exact value and gives a truthful toast. Make affordance discoverable and keyboard/touch accessible; distinguish display timezone from copied exact value. Copy feedback must reflect clipboard success/failure.
- Make investigation details easy to copy for support or LLM context. Determine exact useful scope; do not silently broaden payload exposure or authorization.
- Replay section is crowded and disjointed: “Replay delivery”, “Replay webhook”, eligibility fields, lifecycle fields and derived ledger rows. Consolidate action rationale and relevant state; place secondary technical details appropriately. Preserve confirmation, step-up authorization, scope, eligibility and truthful queued-versus-completed outcomes.
- Remove implementation narration: “Single replay calls the existing DLQ primitive directly and records an admin audit event for the operator action.” Explain what the supported action does for the operator after tracing actual behavior.
- Activity and Raw payload look like broken headings, with no obvious expand/collapse affordance. Evaluate whether collapse adds value; preserve intentional lazy loading where needed and make disclosure explicit.
- Activity shows two large disconnected empty messages. Present one coherent empty state when both histories are empty; preserve distinctions and separate unavailable from empty.
- Raw payload viewer repeats section/eyebrow/title and has crude Tree/Raw/Copy controls. Refine shared viewer controls, hierarchy and tree readability while preserving exact raw evidence and copy behavior.
- Additional 08:00 screenshot: replay area is busy, ugly and confusing. “Last attempt: No webhook deliveries need replay” and “First derived event: No billing events need admin review” appear to turn missing local history into global reassurance. Inspect source and replace with record-specific evidence-true absence wording; this is a correctness candidate as well as a presentation issue.

## Coupons and demo scenarios

Observed route: http://accrue-host-phase243-preview.localhost/admin/coupons?valid=true

Source owner: `accrue_admin/lib/accrue_admin/live/coupons_live.ex`, shared Toolbar/FilterBar/Table/EmptyState owners. Screenshots at 08:01–08:05.

- Clicking All still appears to leave Valid selected. Trace canonical URL, selected filter, server query, count and rendered rows together; distinguish focus from selection. Preserve organization scope and search when changing validity. Do not dismiss this as cosmetic.
- Remove “Promotion codes have their own list and detail surface”; “detail surface” is implementation vocabulary. Use a short useful destination link and explain coupons versus promotion codes only where it aids a decision.
- KPI strip is visually awkward; assess whether counts help this task, communicate their scope, and avoid arbitrary status coloring.
- Separate FILTERS card duplicates validity controls, default/all presets, count and clear actions already above it. Consolidate into a coherent toolbar/active-filter treatment with less framing and repetition.
- User prefers an X affordance for removing a filter chip. Retain an explicit accessible name, keyboard focus and adequate touch target; define remove-one versus reset-all behavior without ambiguity.
- Coupon names and technical IDs run together. Give the primary name and secondary identifier deliberate separation, wrapping and hierarchy; retain exact ID access/copy.
- Empty-state description is too far from its heading. Group heading and explanation tightly, then space the recovery action deliberately; avoid oversized accidental gaps.
- User requests a sanity audit of example seeds and test fixtures: representative, plausible states with internally consistent money, dates, relationships, statuses and history. Initial inspection finds phase-number names, synthetic IDs and `phase191_host` payload markers in feedback-preview data; these are test artifacts, not proof of domain inconsistency. Separate realistic operator demos from deliberate edge-case/contract fixtures rather than deleting useful Unicode, failure or boundary tests.
- User suggests quickly choosing preview scenarios (per page or across the example app) to inspect different usage states. Explore existing fixture/scenario tooling first. Keep demo controls in the evaluation host or external launcher rather than production Admin navigation. Prefer isolated, reproducible scenario datasets; preserve the current feedback DB, avoid implicit destructive reseeding, and label synthetic examples accurately. Scenario selection is a candidate scope decision, not approved new production UI.

## Connect collection and shared filter design

Observed route: http://accrue-host-phase243-preview.localhost/admin/connect?needs_attention=true; screenshot 08:06.

Owner explicitly requests Impeccable analysis, established UI conventions/least surprise, and shared design-system improvements whose benefits compound across pages. Exceptions must have a concrete task justification.

Read-only independent design/source assessments identify:

- Five categorical filter groups lack visible labels. `DataTable.filter_toolbar` hides field labels while groups have accessible names. Sighted operators cannot distinguish the two All/Enabled/Disabled groups (charges versus payouts). Restore visible labels; keep accessible grouping and native behavior.
- All five segmented controls expose every option and wrap into arbitrary rows. Use a coherent labeled grid or compact native selects; keep primary search and view visible, consider a Filters disclosure for secondary criteria. Preserve selected state visibility and predictable keyboard behavior.
- The Filters card combines the Needs attention view, All accounts preset, active constraints, count and reset, duplicating the toolbar. Connect marks both preset chips `active: true`, so the chip bar cannot distinguish active constraints from navigation choices. Separate view selection from applied filters.
- Clear filters appears twice, one detached at the far right of an extra row. Establish one reset-all action in a predictable location plus accessible remove-one X controls on genuine active chips.
- Large empty vertical gaps and an oversized card separate controls from their results. Group controls tightly with the result count, then the table. Avoid page-local spacing patches.
- “Finish account readiness” promises an action/completion on a collection page. Prefer a stable destination heading (“Connected accounts” candidate), with Needs attention as a view and concise task help. Stored provider snapshot uncertainty must remain explicit.
- KPI strip gives counts arbitrary color/emphasis; define total versus filtered counts and whether each count helps the operator's task.
- Table repeats “Last stored Stripe snapshot” in heading and rows; describe evidence provenance once while retaining exact observation timing and unavailable states.
- Account and owner raw identifiers dominate scanning; separate readable identity and secondary exact copyable IDs. Status currently contains country/email for non-deauthorized records: align column names with their actual content.

Shared direction: page identity → view/search/labeled filters → compact applied-filter summary and result count → results. Own behavior and visual rules in DataTable, FilterChipBar and existing page-header components; Connect/Coupons supply domain-specific fields. Verify actual URL, input selection, query and rendered count together; test responsive wrapping, keyboard/focus and clear/remove scope using representative consumers. No new dependency is indicated.

Evidence: independent design review and detector/browser review. Fresh Chrome tab 911200404 AX and screenshot matched the reported composition. Detector scanned ConnectAccountsLive, FilterChipBar and DataTable separately: each returned [] with exit 0. These clean results do not establish visual quality or correct filter transitions. Overlay injection was unavailable through read-only browser evaluate; no live server was started. Bootstrap used an isolated temporary engine cache after the updated launcher lacked execute permission. No source, DB or global tool changes were made by these assessments. Keyboard, narrow-screen and actual filter transitions remain unverified.

## Promotion codes and shared timestamp/table conventions

Observed route: http://accrue-host-phase243-preview.localhost/admin/promotion-codes?active=true; screenshot 08:07.

- Carry the Coupons/Connect shared filter, chip, count and table-identity findings to this consumer. Avoid page-specific duplicate repairs.
- Status currently includes “Active · expires [timestamp]” while Expires already has its own column. Keep status and expiry separate; render each fact once in the natural scanning order. Candidate sequence: promotion code → associated coupon → status → expiry → redemptions, subject to operator-task review and responsive priority.
- Display timestamps in the user's local timezone, with timezone discoverable and unambiguous. Clipboard value should remain a canonical UTC timestamp. User suggests an optional local/UTC display toggle; assess whether a single shared preference is useful rather than adding a switch per row or timestamp. Preserve server/SSR fallback, DST correctness, exact precision and unavailable values; relative dates must not replace exact evidence.
- Consistent timestamp copying requires a visible/discoverable action, keyboard/touch access, truthful success/failure toast and a clear distinction between displayed local time and copied UTC. No implementation decision on UTC format or preference persistence yet.
- Audit table column order against each operator task rather than applying one arbitrary sequence to all data types. Prioritize identity and task-significant state, then supporting dates/counts; keep raw IDs available in secondary copyable detail.
- Main search plus separate Coupon ID field feels fragmented. Source inspection confirms `Queries.PromotionCodes.filter_query/2`: q matches promotion code, promotion processor ID or associated coupon name; coupon_id filters the exact associated local coupon UUID. It is not a second name-versus-ID search over the same object. General search should cover useful code/name/ID lookup where justified; an exact associated-coupon constraint must stay explicit if merging would change meaning. Offer a labeled Coupon filter under secondary criteria if justified, rather than an unlabeled raw-ID box. Support for coupon processor IDs in general search would be an explicit behavior change, not already implemented.
- Promotion-code names/IDs run together and wrap awkwardly, repeating Coupon table identity defects. Fix the shared primary/secondary cell pattern.

## Events collection

Observed route: http://accrue-host-phase243-preview.localhost/admin/events; screenshot 08:10.

- User requests intentional, conventional filter composition instead of many search-like boxes. Source `EventsLive.event_filter_fields/0` defines q, type, actor_type, subject_type and source_webhook_event_id without control types, so all become text inputs.
- Use one prominent general search. Pick visible labeled selects for finite actor/subject categories, and a searchable suggestion-capable event-type control if its namespace is extensible. Preserve raw/custom event keys and historical values; never restrict valid filters to only a hard-coded producer list.
- Exact source-webhook relationship filtering belongs in secondary criteria or an explicitly labeled applied constraint from a webhook link. Do not merge exact relationship constraints into ambiguous free-text behavior without a deliberate query contract.
- Place secondary filters in a coherent disclosure or labeled layout; show selected constraints as compact removable chips. All events/Admin changes are view choices, not two active filters. Remove the oversized duplicate Filters card and avoid orphan input wrapping.
- Heading/help (“Trace billing activity”, “Read the append-only billing event ledger”) and “Ledger rows / Webhook sourced” counts expose implementation vocabulary. Prefer stable destination identity and task-relevant explanation while keeping audit immutability/provenance precise when consequential.
- Event label and raw type run together; subject UUIDs dominate rows. Apply the shared primary/secondary cell pattern; preserve exact keys and identifiers. Generic Billing event labels for unknown keys are deliberate neutral fallbacks from Phase 244; expand friendly labels only with producer evidence, without inventing an outcome for unknown/historical events.
- Review column sequence for investigation: when, observed event, affected record, actor and source are candidates; choose based on scan task and narrow-screen priorities. No blanket column order is approved.
- Distinguish total ledger count, current-page count (25 here), matching total if available, and new-since-cursor count. Do not imply “Showing 25 events” is the full filtered total if it is a page size.

Shared filter direction remains the same as Coupons/Connect/Promotion codes. Apply the existing Impeccable task-oriented hierarchy, recognition, grouping and progressive-disclosure guidance; avoid repeating a full independent audit for the same demonstrated shared defect while owner feedback collection continues.

## Recovery analytics

Observed route: http://accrue-host-phase243-preview.localhost/admin/analytics/recovery?window=30d; screenshot 08:11. Source: `live/analytics/recovery_live.ex`, shared `components/kpi_card.ex`, recovery copy in `copy.ex`.

- Long formula explanation is passed into the KPI delta treatment and renders as a huge amber pill. Delta styling should represent a compact actual change, not explanatory prose. Move metric definitions to a restrained description or contextual help; do not use warning/success color for ordinary definitions.
- Recovered cards show “Amount saved by successful Dunning” plus “Money Saved”; exhausted cards show formula plus “Churned Revenue”. These compete and may imply cash recovery or confirmed churn beyond the metric's actual evidence. Trace core analytics definitions before simplifying; MRR snapshots, payments recovered and lost revenue are distinct.
- “Showing data since 2024-01-01” looks like a date scope control or informational badge but opens external Cutoff semantics docs. Separate the actual coverage note from an explicitly named help link; verify the cutoff is authoritative/configured rather than stale hard-coded copy. Never imply changing the selected window changes retained historical coverage.
- Window control has an oversized full-width white background, only three choices occupying part of it, and apparent extra bottom space. Use the same intentional range/segmented-control geometry and selected/focus states as the shared design system; keep UTC aggregation boundaries explicit without repeating UTC in every option if a clear group label suffices.
- Four metric cards in a three-column layout leave one currency/metric orphaned on the next row. Group by currency with recovered/exhausted as a pair or use a balanced responsive grid. Keep currencies separate; no implicit conversion or combined total.
- Large “Amount unavailable” values compete with monetary values and leave blank card areas. Distinguish zero, absent currency data and failed/unavailable computation; use coherent state presentation and a useful explanation where source supports it.
- Page heading, cutoff pill, paragraph, range bar and cards lack a clear grouping rhythm. Organize page identity and concise purpose, coverage/range controls, then comparable metric groups. Reduce repetitive copy and excess vertical gaps.
- Breadcrumb Analytics / Recovery does not match visible nav hierarchy. Include in shared breadcrumb/destination consistency review; avoid inventing a navigation ancestor that operators cannot visit.
- Owner finds “Recovery” itself unclear and requests coherent operator-facing domain language throughout. Candidate “Payment recovery” names the failed-payment task more concretely, but final wording must fit the actual analytics plus at-risk work queue. Align sidebar, page title, breadcrumbs, links and empty states through shared copy owners. Avoid renaming public domain APIs or claiming that ordinary billing terminology is inherently AI-generated. Explain dunning in plain language where needed; distinguish recovered payments from monthly recurring revenue associated with recovered subscriptions.

Assessment scope is the main panel visible in the screenshot and named source owners, not unseen below-fold charts or a fresh accessibility/metric correctness certification. These are feedback candidates for the forthcoming milestone, not implemented fixes.

## Payments collection

Observed route: http://accrue-host-phase243-preview.localhost/admin/payments?status=failed; screenshot 08:20. Source owner is `live/charges_live.ex` (UI route is Payments).

- “Recover failed payments” assumes a specific action for the whole destination. General payment review serves support investigation, reconciliation, refund review and fee checks as well as failed-payment follow-up. Prefer stable Payments identity plus a clearly selected Failed view and task-specific concise help; do not imply a retry/recovery capability the page does not provide.
- “Billing signals” combines two unlabeled badges. Source `billing_signals_cell/1` puts ownership_label and tax_health_label together: User/Org identify ownership; Off is tax state, not payment status. Name these facts explicitly or move secondary facts to useful detail. Do not require a tooltip to decode bare “Off”.
- Owner suggests contextual info tooltips where genuinely useful. Use concise consequential definitions for unfamiliar metrics/states, accessible by keyboard and touch as well as hover. Primary labels must stand alone; help is supplemental and must not conceal required evidence or limitations. Prefer existing shared help pattern over a dependency.
- Fee summary combines amount/absence with provider name and settlement marker (“pending stripe fee · unsettled”). Source uses “pending” whenever stripe_fee_amount_minor is missing, and “unsettled” whenever fees_settled_at is absent. Missing local evidence does not establish a pending fee or unsettled processor outcome. Trace lifecycle/provider contracts before choosing wording; distinguish known zero, not applicable, not yet observed and unavailable.
- Present fee amount and its actual supported state with deliberate hierarchy; use a semantic badge only for a real state, and avoid cramming unrelated facts into dot-separated prose. Keep exact currency and settlement evidence available. Provider-specific Stripe fields must not imply Stripe fee semantics apply to all processors.
- Carry shared filter duplication, hidden labels, reset placement, table identity spacing and count-scope issues to Payments. KPI strip currently emphasizes succeeded/settled/refunded while the selected view is Failed; establish whether these are global scoped counts and whether they help this task.

## Invoices collection and task-based filter behavior

Observed route: http://accrue-host-phase243-preview.localhost/admin/invoices?status=open%2Cuncollectible; screenshot 08:21.

- Invoice identity column consumes most width while status/due-date columns crowd the right edge. Rows appear excessively tall with large blank areas; name/customer text still runs together. Trace owning table markup and CSS before assigning cause. Use deliberate column sizing, shared cell padding and primary/secondary identity separation; ensure responsive priority without hiding essential money or status evidence.
- Consider restrained semantic status badges with text; unify their meanings across lists/details. Color is supplemental, and ordinary states must not all become warnings or success signals.
- URL already encodes a status combination (open,uncollectible), while visible status control says All statuses. Verify control state against URL/query/results; this may be a representation defect, not lack of backend multi-status capability.
- Owner requests multi-status selection where it supports actual operator work. A multi-select with labeled checkboxes can support open plus uncollectible, while single-choice controls remain appropriate for mutually exclusive views. Do not add multi-select to every filter mechanically; define within-field OR versus across-field AND, readable applied-state summary, clear-one/clear-all behavior, URL persistence and keyboard/touch access.
- Navigation “Invoices queue”, breadcrumb “Invoices”, heading “Clear open receivables” and selected Needs collection view use different destination/task names. Keep destination stable, expose queue/view as a selected task, and retain general history/investigation access without making it look secondary or unavailable.
- Shared acceptance principle from owner: choose filters, column ordering and disclosure based on primary and secondary jobs to be done, including common investigation/review paths and less-common exact-ID/relationship searches. Use one coherent default experience with discoverable advanced criteria rather than unrelated special-purpose controls or a flood of filters. Validate actual tasks, not just aesthetic component parity.

## Subscriptions collection

Observed route: http://accrue-host-phase243-preview.localhost/admin/subscriptions?status=past_due%2Ccanceling; screenshots at 08:25. First attached image repeats Invoices; use the supplied Subscriptions route, DOM excerpts and other screenshots for subscription findings.

- Generic page-level “Action required” badge does not explain the actual issue or next step. Tie attention indicators to specific observed conditions and supported actions, preferably near relevant rows/action context. Do not imply all past-due or scheduled-cancellation records require the same operator action.
- Header links styled as primary/secondary action buttons (“Open invoice queue”, “Webhooks: debug failed deliveries”, “Events audit log”) duplicate global navigation and lack a clear relationship to the current task. Keep contextual cross-links only where a demonstrated investigation task justifies them; label destination/reason clearly and preserve relevant customer/record/filter scope. A fixed subscription.created filter must not imply it represents every issue in a past-due/canceling view.
- Work-queue chip bar combines At risk, dunning funnel counts, All preset, invoice queue workspace link and subscription-row count. Separate view choice, applied constraints, evidence count and related destinations. “Open invoice queue workspace” and “dunning funnel” are candidates for plain task language.
- Long synthetic customer names make the identity column enormous, pushing state, price, dates and secondary facts offscreen. Constrain shared cell layout, wrap long unbroken text, distinguish readable identity from exact secondary IDs, and preserve access to full/copyable values. Maintain useful column priorities without requiring horizontal scrolling for routine desktop scanning. Keep adversarial long-name fixtures in tests but out of ordinary realistic preview scenarios.
- State badges carry compound paragraphs (“Active · cancellation scheduled”). Separate actual subscription state from scheduled change, with compact text and deliberate hierarchy rather than oversized wrapping pills. Keep both facts and effective date accurate.
- “Signals” is vague; ownership and tax should have explicit labels and appropriate priority rather than a grab bag of chips. Reuse shared semantics across Payments/Invoices/Subscriptions.
- “Setup gap” blocks cram missing plan/amount, unconfirmed price and renewal information into narrow cells. Missing Admin evidence must not be presented as a confirmed host misconfiguration. Prefer concise unknown/unavailable values, relevant supporting detail on demand and a real recovery path where available; ordinary missing metadata should not automatically become a warning block.
- “No renewal data” appears beside a specific renews/ends date. Trace which distinct fields each refers to and explain precisely; do not conflate known period-end timing with unknown future price/renewal detail.
- Owner points out that main search already advertises customer ID while a second Customer ID field also appears. Source `Queries.Subscriptions.filter_query/2` confirms q actually matches customer email, customer name and subscription processor ID; it does not match customer ID or actor. Exact customer_id is a separate relationship constraint. This is also a copy/query mismatch: test and align advertised search capabilities before consolidation. Consolidate overlapping entry points when meaning is equivalent, otherwise make exact “Customer” filtering explicitly secondary. Avoid duplicating the same ID task as two unlabeled search boxes.
- Carry multi-status picker representation, shared toolbar/chip cleanup, table geometry, timestamp and destination naming conventions to this consumer.

## Customers and selective semantic emphasis

Observed route: http://accrue-host-phase243-preview.localhost/admin/customers; owner DOM excerpt for owner_type filter.

- Payment method “Missing” may deserve restrained semantic emphasis when actionable, while ordinary populated values remain plain. Avoid alert fatigue and badge-everything styling; missing method alone is not proof of a billing failure or required action. Determine eligibility/context before assigning warning semantics.
- “All owner types” exposes the data-model term. Review natural operator wording for User/Organization/Team/Workspace choices; candidate field label “Billed account” or “Account type” depends on actual host ownership semantics. Keep meaning precise, preserve custom host-defined owner types, and do not conflate billing ownership with permissions or authenticated actor.
- Carry shared filtering, table identity/status/timestamp, count and task hierarchy rules to Customers.

## Proposed milestone brief and evidence contract

Owner requests a complete screenshot-based inspection of every existing Admin UI surface, especially previously unseen list/detail pages, and extrapolation from the confirmed feedback. The aim is a substantially better baseline so the next owner pass finds fewer, more targeted defects. Scope is existing Admin refinement, not only search. No new billing features, Portal work, rebrand or dependency is implied.

Coverage must be an enumerated route/component/state inventory with explicit inspected, unavailable and not-applicable entries; never claim “every surface” based on a few list screenshots. Include individual detail pages, representative dialogs/drawers, tabs/disclosures, populated/empty/loading/unavailable states, and supported operator-role/owner-scope differences where they materially affect the UI. Capture wide/narrow and light/dark exemplars in bounded batches, with served asset/revision and fixture/scenario identity. Do not require a combinatorial screenshot explosion; justify representative coverage and record gaps.

Use Impeccable for each distinct surface's actual rendered hierarchy, spacing, control conventions, plain language and task comprehension. Reuse demonstrated shared findings; avoid repeated full critiques and costly review loops for identical component defects. Combine screenshot inspection with actual mouse/keyboard/touch behavior where relevant. Screenshots and detector results alone cannot establish behavior or accessibility.

Implementation should consolidate shared collection controls, table cells/statuses, page identity/breadcrumbs, timestamp display/copy, empty states, detail disclosures/payload controls and metric-card semantics at their existing owners. Keep a small vocabulary/destination map and explicit justified exceptions. Preserve exact billing evidence, money/currencies, uncertain outcomes, URL filters, host-defined scope, authorization and supported action boundaries.

Carry all concrete feedback above into requirements/phase context with source pointers and observable acceptance. Keep correctness candidates distinct: status picker versus query disagreement, advertised search versus actual predicates, missing history versus success claims, absent fee observations versus pending/settled states, and metric/copy mismatch. Do not discard those as visual polish.

Realistic preview data needs a bounded integrity review and separation from adversarial test fixtures. Scenario switching is a possible evaluation-host tool, not automatically a new production Admin feature; decide the minimum useful mechanism after reviewing existing tooling. Preserve current preview data during inventory.

Suggested milestone name: **v1.66 — Admin Usability and Visual Consistency**. Next phase is **245**; planning should split shared patterns, detail/analytics refinements, realistic evaluation and integrated evidence into coherent delivery units as needed rather than forcing all work into one phase.

## Working direction

Use Impeccable for task-oriented refinement within the existing Accrue identity. Favor plain language, coherent shared patterns, exact evidence on demand, and bounded rendered inspection. No new dependency is indicated. Collect additional owner feedback before fixing final milestone scope. Existing v1.64/v1.65 evidence remains revision-bound; new changes require their own owning behavior and rendered checks.

Impeccable updater repaired separately: cached npm CLI 3.5.0 followed one redirect while official bundle endpoint required two; curl followed redirects and validated the ZIP. Existing user installs in `.agents` and `.claude` updated successfully to 4.5.2. Accrue source was unchanged by that repair.
