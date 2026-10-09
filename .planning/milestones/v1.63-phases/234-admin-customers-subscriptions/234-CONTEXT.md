# Phase 234: Admin Customers & Subscriptions - Context

**Gathered:** 2026-10-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Refine existing Admin Home/search, customer list/detail, subscription list/detail, and supported subscription actions so operators investigate the correct record, understand known lifecycle facts, and see the actual consequence and outcome of an eligible action. Preserve owner and navigation context through related-record journeys. Requirements: ADM-01, ADM-03, ADM-04, SAFE-01.

This slice owns keyboard, narrow-screen, theme, state, scope, and served-render evidence for the flows it changes. Related invoice/payment/recovery/event routes may receive the bounded navigation or shared-component correction needed by those journeys; their broader refinement remains in Phases 237–238. Portal/checkout work remains in Phases 235–236, and integrated coverage/handoff in Phase 239.

The user selected every discussion area, requested parallel specialist research and a bounded adversarial follow-up, and authorized following the synthesized recommendations. These decisions are the accepted planning direction. No new billing capability, search platform, permission model, provider support, or general workflow framework is authorized.
</domain>

<decisions>
## Implementation Decisions

### Operator jobs and starting points

- **D-01:** Engineers and support/billing operators remain equal primary users of one Admin. Optimize the common sequence: identify the customer → inspect the subscription → understand facts and unknowns → choose an eligible action → review its consequence → inspect the result. Keep diagnostics available without requiring operators to understand modules, projections, jobs, or internal event names for routine work.
- **D-02:** Retain scoped Home and visible global search as complementary entry points. Home supplies specific observations and links into existing work; search supports a ticket or known-record lookup from every route. Remove unsupported overall health claims and aspirational targets such as an invoice queue reaching zero. Every visible summary and its destination must refer to the same authorized scope.
- **D-03:** Retain the existing subscription default filter `past_due,canceling`, with an explicit neutral label such as “Past due & scheduled to end” and an adjacent “All subscriptions” view. Expose the active filters. Scheduled cancellation alone is not a failure or urgent incident; the queue is neither the complete subscription population nor an exhaustive list of problems. An empty filtered view must say that the selected view has no matches.
- **D-04:** Keep global search as a bounded preview grouped by the existing customer, invoice, and subscription types. Name the actual supported matching fields; do not promise arbitrary IDs or a query syntax the current queries cannot match. Show readable identity plus existing disambiguating facts, with exact IDs available for investigation. Say results are limited; only claim additional matches when the query establishes that fact. A handoff to an existing filtered list must preserve equivalent query semantics. Do not introduce new search types, a backend, or a query language.
- **D-05:** Treat loading, no matches, empty data, partial search failure, and unavailable lookup as different states. Successful search groups can remain usable when another group fails, with a concise failure notice and safe read retry. Clear/invalidate results when query or scope changes; an older response cannot appear selectable as the current result. Keep input and keyboard response immediate without adding query fan-out or unbounded count work.

### Record hierarchy, scope, and navigation

- **D-06:** Customer detail starts with stable customer identity, authorized owner context, and a compact factual billing summary. Bring the existing peer tabs for subscriptions, invoices, and payments into a useful position; preserve their URL-backed semantics. Keep payment methods, entitlement observations, tax details, and activity reachable with deliberate grouping/disclosure. Do not add customer subroutes or force every section into a card.
- **D-07:** Subscription detail leads with customer/subscription identity, exact lifecycle, relevant dates, available plan/quantity/price facts, and the appropriate local actions. Follow with related records and history; place raw payloads and technical references behind clearly named secondary disclosure. Use definition lists for facts, tables for comparison, and timelines for chronology. The old blueprint's fixed multi-band layout is not mandatory.
- **D-08:** Link labels must predict the destination object: a customer name links to that customer, a subscription label/ID to that subscription. Keep scope and originating list/filter/sort/pagination/tab context through customer → subscription → related-record → return, including browser Back and direct deep links. Distinguish a contextual “Back to results” from a hierarchy breadcrumb. Use bounded, validated local navigation state within the configured mount; return parameters never authorize access or override current scope. No mutation drafts, credentials, step-up state, or payment tokens in URLs. Handle invalid/stale cursors with an honest scoped recovery instead of a crash or silent cross-scope fallback.
- **D-09:** Long and duplicate names must remain distinguishable using already available email, owner reference, or stable ID as appropriate. Preserve full accessible/copyable identifiers without allowing them to force page overflow. Do not invent unavailable account names or expose foreign identity in denial text. Changing owner scope invalidates pending actions and stale result context; it cannot retarget a displayed action.

### Lifecycle, amounts, dates, and evidence

- **D-10:** Show known lifecycle independently of missing ancillary observations. An active subscription with an unavailable price or period date remains Active, with those specific facts labeled unavailable. Preserve meaningful distinctions among trialing, incomplete, incomplete-expired, past due, unpaid, canceled, cancellation scheduled, and the supported pause/collection semantics. Reuse existing core predicates and provider contracts; do not infer a generic inactive/healthy verdict from caveats, invoice totals, or historical failures.
- **D-11:** Separate current lifecycle, scheduled change, collection behavior, and historical evidence. A canceled subscription does not establish host access policy; a paused-collection fact does not automatically redefine lifecycle. State the observed fact and relevant timestamp when available. Do not invent freshness SLAs, sync ages, or a live-provider confirmation where the source has no such evidence.
- **D-12:** On the Home/customer/subscription surfaces changed here, reuse existing exact money formatting and preserve currency/minor-unit precision. Distinguish plan/unit price from an established next charge or complete subscription total; do not sum different currencies or infer a total from incomplete item metadata. Missing amount is not zero, missing date is not “Due now,” and draft/open/overdue are not interchangeable. Group valid totals by currency or omit an unsupported aggregate. Use existing date/time conventions with clear time-zone context where timing matters. Broader invoice/payment/recovery work stays in Phase 237.

### Supported actions, confirmation, and result behavior

- **D-13:** Put common eligible actions next to the facts they change; keep less common actions in the existing grouped action menu. Use one primary action per task group, with destructive actions visually distinct. Hide unauthorized and provider-unsupported mutation controls. Explain a relevant unavailable capability or state restriction in concise contextual text when its absence would be confusing, rather than displaying every possible action as a disabled button.
- **D-14:** Keep one existing drawer → review → confirm path, including required step-up. Every entry point must use the same consequence and eligibility rules. Reviews name the customer, subscription, actual action, timing, and known amount/currency/quantity/proration consequences. Preserve immediate versus period-end cancellation, configured Braintree plan resolution, unsupported previews, and item/quantity limits. Label compensation as creation of a replacement when that is what the core does, retaining source and replacement identity. Do not conflate resuming cancellation with resuming collection. Unavailable preview facts stay explicitly unavailable; never ask for confirmation of an invented exact charge.
- **D-15:** Immediately before dispatch, including after any step-up delay, freshly load the same target through the owner-scoped local query and apply current host/operator authorization, target/item ownership, lifecycle predicates, provider capability, and step-up rules. Rendered controls and cached assigns are not authority. Re-resolve item membership from the refreshed subscription. If action-relevant identity, permission, eligibility, plan/items, amount/currency, period end, or consequence changed, clear the obsolete review and explain why review is required again. Irrelevant metadata changes need not restart the flow. Scope post-action reads and replacement-record navigation too. This does not imply a new remote-provider fetch on every click or atomicity across a remote call and the database.
- **D-16:** Bind one logical staged submission to the existing operation identity through its confirmation and step-up path. Prevent duplicate dispatch in the server interaction state as well as through pending controls; reuse existing facade/provider idempotency semantics where supported. Changed action/payload/target starts a new reviewed intent. Do not claim durable exactly-once processing or cross-reconnect recovery from an ephemeral socket value. If reconnect cannot safely reconstruct the pending intent, clear it without replaying it and require a fresh read/review.
- **D-17:** Separate validation rejection, not submitted, pending, accepted, confirmed local change, failed, and outcome not confirmed according to actual returned evidence. Preserve harmless form input for definitive validation corrections. After an ambiguous timeout/error, clear the executable confirmation and show “Outcome not confirmed,” with an existing scoped record/history read path and no blind retry. A local refresh or audit event cannot by itself prove the provider did or did not act. Avoid “not submitted” or “failed” once submission may have occurred. Reuse existing error distinctions; conservatively preserve uncertainty when the result cannot be classified. Do not invent a reconciliation service, durable operation store, or automatic retry mechanism.
- **D-18:** Make outcomes visible and appropriately announced, retaining useful result links after a drawer closes. For compensation, expose the created replacement record without losing the original context. Expired/invalid step-up, denied actions, removed records, unsupported operations, duplicate messages, and reconnect must produce deliberate outcomes rather than a generic 500 or success flash. Confirmation/challenge dismissal never submits the operation.

### Visual system, accessibility, and interaction

- **D-19:** Follow the ratified Admin Geist/Geist Mono/Cobalt identity, current brandbook, Phase 233 semantic direction, and existing `--ax-*` token ownership. Use calm, exact operator language. Preserve legal/replay wording contracts. The newer brandbook and current product/phase records supersede older prompt branding and speculative templates.
- **D-20:** Reuse the existing DataTable desktop table/narrow labeled-card path. Prioritize identity, exact state, relevant plan/amount/date facts, and a clear record link; all essential facts/actions remain accessible. Reserve contained horizontal scrolling for genuinely two-dimensional comparison that requires it. Avoid shrinking text or hiding essential columns to make the page fit. Ensure desktop/card variants do not create duplicate IDs, duplicate screen-reader content, or hidden focus stops.
- **D-21:** Use existing typography/spacing roles with readable hierarchy: primary content/control text generally 16px, dense secondary labels around 14px, restrained smaller metadata only when legible and secondary. Remove superseded page-specific tiny controls, excessive font weights, and cramped spacing that defeat the shared roles. Use rem-aware layout and wrapping. Favor 44px standalone touch targets on narrow/coarse-pointer layouts; this is a project usability target, distinct from WCAG 2.2 AA's 24px minimum and its exceptions. No new density setting or replacement token catalog.
- **D-22:** Preserve native link/button/form semantics, visible focus, meaningful labels, and non-color state cues across light, dark, system, and supported host-forced modes. Use the correct keyboard model for the actual tab/disclosure pattern. Modal search/drawers/challenges need named dialogs, predictable initial focus, Tab/Shift+Tab containment, Escape/close behavior, and restoration to the trigger or a logical fallback if removed. Nested step-up must leave only the active modal interactive and restore focus through the stack. Announce status without repeated/noisy announcements after patches.
- **D-23:** Keyboard navigation, close, and repeat actions respond immediately. Keep any motion brief and purposeful; reduced-motion behavior covers JavaScript timers/lifecycle delays as well as CSS. LiveView patches, reconnects, theme changes, and removal of triggers must preserve a coherent focus and pending-state lifecycle without replaying mutations. Check 320 CSS pixel reflow, zoom, long content, coarse pointers, and changed open/error states in the owning slice. Target the established AA bar; do not add AAA Focus Appearance as a completion gate or claim comprehensive certification.

### Elixir/Phoenix boundaries, maintainability, and bounded proof

- **D-24:** Keep LiveView/components responsible for interaction and presentation, Admin queries for scoped reads, and `Accrue.Billing`/core for billing mutations and domain semantics. Reuse core lifecycle predicates in a small local action mapping. Extract a private Admin helper only where real repetition or handler complexity justifies it. Do not add a public eligibility API, UI framework, new runtime dependency, role system, or duplicated billing state machine.
- **D-25:** Preserve host-owned Repo/auth/session/supervision/configuration and configurable mount paths. URLs and event payloads are untrusted navigation/action input. Apply scope to detail loads, search, aggregates, related links, action revalidation, and result refresh; a customer billing manager remains outside Admin. Keep denial generic and payment-token/credential data out of rendered HTML, errors, logs, and result evidence. Stronger permission policy must come from the existing host boundary, not an invented Admin role vocabulary.
- **D-26:** Preserve bounded cursor queries and limited search results; avoid N+1 lookups, full-population counts for decoration, and per-render remote calls. Reuse established preloads/query patterns. Query-plan or transaction changes require a measured problem in this flow; no speculative cache, new indexes, or core transaction redesign as UI work. Keep provider latency and local evidence failure distinct in diagnostics, using existing safe telemetry/audit mechanisms rather than new high-cardinality or sensitive fields.
- **D-27:** Plan acceptance alongside the changed behavior at the least costly credible layer. Pure status/money/eligibility cases belong in unit/contract coverage; mounted scope, forged events, step-up, and state changes in integration/LiveView coverage; navigation, real keyboard/focus, responsive layout, themes, and served assets in representative browser evidence. Include positive controls with denials and representative two-owner/nondefault-scope cases. Restore the skipped mounted denial proof after diagnosing its fixture/application failure. Fake remains deterministic evidence; provider-specific fixtures do not establish live-provider parity. Current rebuilt/served captures must support visual claims; old snapshots are historical references.
- **D-28:** Keep the pass finite: fix named correctness, comprehension, accessibility, and interaction defects in owned flows, reuse the existing component and CI facilities, and document cross-route effects. No all-permutations screenshot matrix, paid evaluator, global aesthetic ratchet, or unrelated test/CI overhaul. This discussion ran no application tests, browser sessions, or new renders and asserts no implementation verification.

### Agent discretion and bounded planning probes

The researcher/planner may choose local helper/module boundaries, safe return-state encoding, exact copy and layout order, representative fixtures, and the smallest component/CSS changes that satisfy these decisions. No routine product question remains open.

Resolve these concrete probes from current code before implementation:

1. Map each existing action to core/provider lifecycle rules, including cancellation/resume, pause collection, compensation, and item membership; do not copy provider-only UI predicates as sufficient eligibility.
2. Trace step-up continuation, operation identity, duplicate dispatch, error classification, post-action scoped refresh, and replacement links end to end. If existing mechanisms cannot substantiate a guarantee, preserve a safe bounded outcome and describe the limit instead of inventing durability.
3. Reconcile search placeholder/ID claims, partial query failures, and list handoff semantics; preserve the existing supported search contract without broadening search as a feature.
4. Determine the smallest safe context-return mechanism, including alternate mounts, invalid cursors, owner switches, browser Back, and direct links.
5. Establish current served route/action renders before selecting exact spacing/table-card/tab changes; verify shared changes against adjacent consumers.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read the governing records and relevant implementation references before planning or implementing.** Paths are repository-relative.

### Scope, product, and current direction

- `.planning/ROADMAP.md` §Phase 234 and `.planning/REQUIREMENTS.md` — phase goal and ADM-01/03/04, SAFE-01.
- `.planning/PROJECT.md` §Current Milestone v1.63 and `PRODUCT.md` — audiences, stable-core posture, and package/host boundaries. PRODUCT's final Portal evidence bullet is stale after Phase 233; use the completed Phase 233 contract as authority for that fact.
- `.planning/notes/2026-10-07-accrue-ui-refinement-scope.md` — accepted scope, source findings, phase ownership, and bounded evidence posture; findings need current source/runtime confirmation.
- `.planning/phases/233-shared-direction-portal-contract/233-CONTEXT.md` and `.planning/phases/233-shared-direction-portal-contract/DESIGN.md` — inherited decisions and semantic roles.
- `.planning/phases/233-shared-direction-portal-contract/233-INVENTORY.md`, `.planning/phases/233-shared-direction-portal-contract/233-BASELINE.md`, and `.planning/phases/233-shared-direction-portal-contract/233-UI-DISPOSITION.md` — route ownership, capture provenance, and deferred Admin density observations.
- `.planning/processor-support-matrix.md` — actual provider capability boundary.
- `CLAUDE.md` — executable acceptance, preservation, and evidence discipline.

### Brand and historical research inputs

- `brandbook/README.md`, `brandbook/voice.md`, `brandbook/tokens/README.md`, and `.planning/milestones/v1.52-phases/180-brand-audit-dna-lock/BRAND-DNA.md` — current ratified identity, voice, and token ownership.
- `prompts/accrue-library-summary-for-admin-ux-deep-research.md` — domain and operator jobs; historical input, not proof of current capabilities.
- `prompts/accrue_admin_operator_ui_journey_blueprint.md` — useful journey, disclosure, and evidence hypotheses; its broader features and fixed templates do not reopen scope.
- `prompts/accrue-best-practices-deep-research-independent.md` and `prompts/original-billing-ecosystem-deep-research.md` — ecosystem/DX lessons; validate current contracts and ignore obsolete versions, popularity claims, and superseded architecture proposals.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` and `prompts/GSD-REPO-HYGIENE.md` — adopter value, diminishing returns, and preservation principles only; this discussion does not invoke their release, ref, configuration, or repository-maintenance procedures.

### Source and consumer contracts

- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex`, `accrue_admin/lib/accrue_admin/components/global_search.ex`, and `accrue_admin/lib/accrue_admin/live/customers_live.ex` — entry, search, and customer list.
- `accrue_admin/lib/accrue_admin/live/customer_live.ex`, `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`, and `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — detail, list, action, and result paths.
- `accrue_admin/lib/accrue_admin/queries/customers.ex`, `accrue_admin/lib/accrue_admin/queries/subscriptions.ex`, and `accrue_admin/lib/accrue_admin/queries/invoices.ex` — current matching, bounded reads, and scope.
- `accrue_admin/lib/accrue_admin/owner_scope.ex`, `accrue_admin/lib/accrue_admin/scoped_path.ex`, `accrue_admin/lib/accrue_admin/router.ex`, and `accrue_admin/lib/accrue_admin/step_up.ex` — owner/navigation/mount/challenge boundaries.
- `accrue/lib/accrue/billing/subscription.ex` and `accrue/lib/accrue/billing/subscription_actions.ex` — lifecycle predicates and actual mutation/idempotency semantics.
- `accrue_admin/lib/accrue_admin/components/data_table.ex`, `accrue_admin/lib/accrue_admin/components/detail.ex`, `accrue_admin/lib/accrue_admin/components/tabs.ex`, `accrue_admin/lib/accrue_admin/components/detail_drawer.ex`, and `accrue_admin/lib/accrue_admin/components/money_formatter.ex` — existing reusable presentation primitives.
- `accrue_admin/assets/css/theme.css`, `accrue_admin/assets/css/app.css`, `accrue_admin/lib/accrue_admin/copy.ex`, and `accrue_admin/lib/accrue_admin/copy/subscription.ex` — tokens, actual cascade, and copy contracts.
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs`, `examples/accrue_host/e2e/verify01-admin-denial.spec.js`, `examples/accrue_host/lib/accrue_host_web/router.ex`, and `accrue_admin/README.md` — existing consumer, safety, and mount seams. Read additional tests/hooks used by the changed components during planning.

### Primary external guidance consulted

- [Phoenix LiveView security model](https://phoenix-live-view.hexdocs.pm/security-model.html) — authorization at navigation/event boundaries. Installed Admin lockfile has LiveView 1.1.31; newer documentation informs principles, not automatic API availability.
- [Stripe Dashboard search](https://docs.stripe.com/dashboard/search) — grouped previews and expanded results as a comparison; no commitment to its broader search syntax.
- [Pay subscriptions](https://github.com/pay-rails/pay/blob/main/docs/6_subscriptions.md) and [Laravel Cashier](https://laravel.com/framework/docs/13.x/billing) — explicit lifecycle operations and provider-dependent semantics as DX lessons.
- [Stripe idempotent requests](https://docs.stripe.com/api/idempotent_requests) — same-intent retry semantics and limits; no provider-wide or permanent exactly-once claim.
- [Carbon data table guidance](https://www.carbondesignsystem.com/building-blocks/core/components/data-table/guidelines), [GOV.UK tabs](https://design-system.service.gov.uk/components/tabs/), and [GOV.UK summary lists](https://design-system.service.gov.uk/components/summary-list/) — task-appropriate comparison, peer sections, and key/value facts.
- [WAI-ARIA modal dialogs](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/), [WCAG 2.2 Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html), and [Target Size Minimum](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) — interaction/reflow/target criteria and their actual scope.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets and patterns

- DataTable already supplies desktop/card variants, query-driven filtering, and pagination. Customer tabs already use URL state. ScopedPath already handles configured mount and organization query context; it does not by itself preserve every originating filter.
- Shared details, IDs, related resources, timelines, overlays, status badges, money formatting, and package-owned copy exist. Extend actual repeated needs rather than create a new component family.
- Admin actions already call the Billing facade and have drawers, previews, confirmation, step-up, operation IDs, and local audit evidence. Those are the starting mechanisms, not proof their current composition handles every stale/duplicate/error case.

### Current source findings to address or reproduce

- Subscription list identity links reverse the displayed customer/subscription destinations; detail returns lose source filters.
- Detail caveats can override known lifecycle; Home/list summaries contain unsupported health/amount/scope assumptions, including an unscoped failed-delivery count.
- Global search limits each group and can silently discard failed group queries. Supported matching fields differ among entities.
- Several action allowances are provider-only; core resume has a narrower lifecycle precondition. Confirmation uses socket-held data, and post-action refresh includes an unscoped read.
- Admin generates an operation ID at dispatch. Compensation creates a replacement, while normal refresh focuses on the original. Preserve the distinction and investigate replay/error behavior from actual source.
- Customer tabs currently follow several other sections. Existing CSS includes cramped subscription typography and local overrides that can defeat narrow control rules. Their current rendered effects must be inspected during execution.

### Integration and evidence limits

- Admin data scope and host/operator authorization are separate constraints. Reuse both; do not transplant the Portal billable adapter or invent universal tenancy.
- Phase 233 captures prove only their documented source, viewport, and state. This discussion's research is source inspection and design synthesis, not user testing, a fresh screenshot audit, or completed acceptance.
- Specialist passes covered investigation/JTBD, action safety/architecture/DX, visual/accessibility/interaction, followed by focused contradiction checks. They converged; remaining uncertainty is implementation evidence covered by the bounded probes above.
</code_context>

<specifics>
## Specific Examples

- A support operator searches in a nondefault owner scope, distinguishes two same-name customers, opens a subscription, follows its invoice/history link, then returns to the same filtered page and customer tab.
- An Active subscription with missing price/period metadata displays Active and specific unavailable facts, without a fabricated amount, due date, or access conclusion.
- A scheduled cancellation appears in the explicitly selected work view with neutral “scheduled to end” wording and a known date when available.
- A webhook changes the relevant subscription state while an operator completes step-up. Dispatch refreshes the target and requests review of the changed consequence instead of executing the stale confirmation.
- An uncertain compensation response shows “Outcome not confirmed” and a local history link; it does not offer a fresh-key retry or claim no replacement was created.
</specifics>

<deferred>
## Deferred Ideas

- New search engines/syntax/resource types, saved-view management, new customer routes, universal layouts, support/engineer modes, or density settings.
- Generalized health/risk/causality diagnosis, new billing actions, provider parity, dynamic processor routing, role management, or operator impersonation.
- Durable operation/reconciliation infrastructure, a public action-eligibility API, speculative query/index/cache changes, or core remote-transaction redesign without a demonstrated required-flow failure.
- Broader money/recovery refinement in Phase 237, events/webhooks/catalog/Connect in Phase 238, and Portal/checkout or integrated milestone handoff in their existing owning phases.
- The stale Portal evidence sentence in PRODUCT.md is a known documentation reconciliation item; it does not reopen the completed Phase 233 contract. Keep correction within a later owned docs pass.

No new product scope was added. Further broad research has reached diminishing returns; planning should resolve the named code probes and proceed with bounded implementation and evidence.
</deferred>

---

*Phase: 234-admin-customers-subscriptions*
*Context gathered: 2026-10-07*
