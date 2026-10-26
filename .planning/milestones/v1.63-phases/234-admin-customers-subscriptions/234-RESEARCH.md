# Phase 234: Admin Customers & Subscriptions - Research

**Researched:** 2026-10-07  
**Domain:** Accrue Admin (Phoenix LiveView, Ecto-scoped reads, billing action workflows)  
**Confidence:** HIGH for in-repository contracts; MEDIUM for final served-render behavior (not inspected in this research)

<user_constraints>
## User Constraints

### Locked Decisions

The following are copied verbatim from `234-CONTEXT.md` and are binding.

#### Operator jobs and starting points

- **D-01:** Engineers and support/billing operators remain equal primary users of one Admin. Optimize the common sequence: identify the customer → inspect the subscription → understand facts and unknowns → choose an eligible action → review its consequence → inspect the result. Keep diagnostics available without requiring operators to understand modules, projections, jobs, or internal event names for routine work.
- **D-02:** Retain scoped Home and visible global search as complementary entry points. Home supplies specific observations and links into existing work; search supports a ticket or known-record lookup from every route. Remove unsupported overall health claims and aspirational targets such as an invoice queue reaching zero. Every visible summary and its destination must refer to the same authorized scope.
- **D-03:** Retain the existing subscription default filter `past_due,canceling`, with an explicit neutral label such as “Past due & scheduled to end” and an adjacent “All subscriptions” view. Expose the active filters. Scheduled cancellation alone is not a failure or urgent incident; the queue is neither the complete subscription population nor an exhaustive list of problems. An empty filtered view must say that the selected view has no matches.
- **D-04:** Keep global search as a bounded preview grouped by the existing customer, invoice, and subscription types. Name the actual supported matching fields; do not promise arbitrary IDs or a query syntax the current queries cannot match. Show readable identity plus existing disambiguating facts, with exact IDs available for investigation. Say results are limited; only claim additional matches when the query establishes that fact. A handoff to an existing filtered list must preserve equivalent query semantics. Do not introduce new search types, a backend, or a query language.
- **D-05:** Treat loading, no matches, empty data, partial search failure, and unavailable lookup as different states. Successful search groups can remain usable when another group fails, with a concise failure notice and safe read retry. Clear/invalidate results when query or scope changes; an older response cannot appear selectable as the current result. Keep input and keyboard response immediate without adding query fan-out or unbounded count work.

#### Record hierarchy, scope, and navigation

- **D-06:** Customer detail starts with stable customer identity, authorized owner context, and a compact factual billing summary. Bring the existing peer tabs for subscriptions, invoices, and payments into a useful position; preserve their URL-backed semantics. Keep payment methods, entitlement observations, tax details, and activity reachable with deliberate grouping/disclosure. Do not add customer subroutes or force every section into a card.
- **D-07:** Subscription detail leads with customer/subscription identity, exact lifecycle, relevant dates, available plan/quantity/price facts, and the appropriate local actions. Follow with related records and history; place raw payloads and technical references behind clearly named secondary disclosure. Use definition lists for facts, tables for comparison, and timelines for chronology. The old blueprint's fixed multi-band layout is not mandatory.
- **D-08:** Link labels must predict the destination object: a customer name links to that customer, a subscription label/ID to that subscription. Keep scope and originating list/filter/sort/pagination/tab context through customer → subscription → related-record → return, including browser Back and direct deep links. Distinguish a contextual “Back to results” from a hierarchy breadcrumb. Use bounded, validated local navigation state within the configured mount; return parameters never authorize access or override current scope. No mutation drafts, credentials, step-up state, or payment tokens in URLs. Handle invalid/stale cursors with an honest scoped recovery instead of a crash or silent cross-scope fallback.
- **D-09:** Long and duplicate names must remain distinguishable using already available email, owner reference, or stable ID as appropriate. Preserve full accessible/copyable identifiers without allowing them to force page overflow. Do not invent unavailable account names or expose foreign identity in denial text. Changing owner scope invalidates pending actions and stale result context; it cannot retarget a displayed action.

#### Lifecycle, amounts, dates, and evidence

- **D-10:** Show known lifecycle independently of missing ancillary observations. An active subscription with an unavailable price or period date remains Active, with those specific facts labeled unavailable. Preserve meaningful distinctions among trialing, incomplete, incomplete-expired, past due, unpaid, canceled, cancellation scheduled, and the supported pause/collection semantics. Reuse existing core predicates and provider contracts; do not infer a generic inactive/healthy verdict from caveats, invoice totals, or historical failures.
- **D-11:** Separate current lifecycle, scheduled change, collection behavior, and historical evidence. A canceled subscription does not establish host access policy; a paused-collection fact does not automatically redefine lifecycle. State the observed fact and relevant timestamp when available. Do not invent freshness SLAs, sync ages, or a live-provider confirmation where the source has no such evidence.
- **D-12:** On the Home/customer/subscription surfaces changed here, reuse existing exact money formatting and preserve currency/minor-unit precision. Distinguish plan/unit price from an established next charge or complete subscription total; do not sum different currencies or infer a total from incomplete item metadata. Missing amount is not zero, missing date is not “Due now,” and draft/open/overdue are not interchangeable. Group valid totals by currency or omit an unsupported aggregate. Use existing date/time conventions with clear time-zone context where timing matters. Broader invoice/payment/recovery work stays in Phase 237.

#### Supported actions, confirmation, and result behavior

- **D-13:** Put common eligible actions next to the facts they change; keep less common actions in the existing grouped action menu. Use one primary action per task group, with destructive actions visually distinct. Hide unauthorized and provider-unsupported mutation controls. Explain a relevant unavailable capability or state restriction in concise contextual text when its absence would be confusing, rather than displaying every possible action as a disabled button.
- **D-14:** Keep one existing drawer → review → confirm path, including required step-up. Every entry point must use the same consequence and eligibility rules. Reviews name the customer, subscription, actual action, timing, and known amount/currency/quantity/proration consequences. Preserve immediate versus period-end cancellation, configured Braintree plan resolution, unsupported previews, and item/quantity limits. Label compensation as creation of a replacement when that is what the core does, retaining source and replacement identity. Do not conflate resuming cancellation with resuming collection. Unavailable preview facts stay explicitly unavailable; never ask for confirmation of an invented exact charge.
- **D-15:** Immediately before dispatch, including after any step-up delay, freshly load the same target through the owner-scoped local query and apply current host/operator authorization, target/item ownership, lifecycle predicates, provider capability, and step-up rules. Rendered controls and cached assigns are not authority. Re-resolve item membership from the refreshed subscription. If action-relevant identity, permission, eligibility, plan/items, amount/currency, period end, or consequence changed, clear the obsolete review and explain why review is required again. Irrelevant metadata changes need not restart the flow. Scope post-action reads and replacement-record navigation too. This does not imply a new remote-provider fetch on every click or atomicity across a remote call and the database.
- **D-16:** Bind one logical staged submission to the existing operation identity through its confirmation and step-up path. Prevent duplicate dispatch in the server interaction state as well as through pending controls; reuse existing facade/provider idempotency semantics where supported. Changed action/payload/target starts a new reviewed intent. Do not claim durable exactly-once processing or cross-reconnect recovery from an ephemeral socket value. If reconnect cannot safely reconstruct the pending intent, clear it without replaying it and require a fresh read/review.
- **D-17:** Separate validation rejection, not submitted, pending, accepted, confirmed local change, failed, and outcome not confirmed according to actual returned evidence. Preserve harmless form input for definitive validation corrections. After an ambiguous timeout/error, clear the executable confirmation and show “Outcome not confirmed,” with an existing scoped record/history read path and no blind retry. A local refresh or audit event cannot by itself prove the provider did or did not act. Avoid “not submitted” or “failed” once submission may have occurred. Reuse existing error distinctions; conservatively preserve uncertainty when the result cannot be classified. Do not invent a reconciliation service, durable operation store, or automatic retry mechanism.
- **D-18:** Make outcomes visible and appropriately announced, retaining useful result links after a drawer closes. For compensation, expose the created replacement record without losing the original context. Expired/invalid step-up, denied actions, removed records, unsupported operations, duplicate messages, and reconnect must produce deliberate outcomes rather than a generic 500 or success flash. Confirmation/challenge dismissal never submits the operation.

#### Visual system, accessibility, and interaction

- **D-19:** Follow the ratified Admin Geist/Geist Mono/Cobalt identity, current brandbook, Phase 233 semantic direction, and existing `--ax-*` token ownership. Use calm, exact operator language. Preserve legal/replay wording contracts. The newer brandbook and current product/phase records supersede older prompt branding and speculative templates.
- **D-20:** Reuse the existing DataTable desktop table/narrow labeled-card path. Prioritize identity, exact state, relevant plan/amount/date facts, and a clear record link; all essential facts/actions remain accessible. Reserve contained horizontal scrolling for genuinely two-dimensional comparison that requires it. Avoid shrinking text or hiding essential columns to make the page fit. Ensure desktop/card variants do not create duplicate IDs, duplicate screen-reader content, or hidden focus stops.
- **D-21:** Use existing typography/spacing roles with readable hierarchy: primary content/control text generally 16px, dense secondary labels around 14px, restrained smaller metadata only when legible and secondary. Remove superseded page-specific tiny controls, excessive font weights, and cramped spacing that defeat the shared roles. Use rem-aware layout and wrapping. Favor 44px standalone touch targets on narrow/coarse-pointer layouts; this is a project usability target, distinct from WCAG 2.2 AA's 24px minimum and its exceptions. No new density setting or replacement token catalog.
- **D-22:** Preserve native link/button/form semantics, visible focus, meaningful labels, and non-color state cues across light, dark, system, and supported host-forced modes. Use the correct keyboard model for the actual tab/disclosure pattern. Modal search/drawers/challenges need named dialogs, predictable initial focus, Tab/Shift+Tab containment, Escape/close behavior, and restoration to the trigger or a logical fallback if removed. Nested step-up must leave only the active modal interactive and restore focus through the stack. Announce status without repeated/noisy announcements after patches.
- **D-23:** Keyboard navigation, close, and repeat actions respond immediately. Keep any motion brief and purposeful; reduced-motion behavior covers JavaScript timers/lifecycle delays as well as CSS. LiveView patches, reconnects, theme changes, and removal of triggers must preserve a coherent focus and pending-state lifecycle without replaying mutations. Check 320 CSS pixel reflow, zoom, long content, coarse pointers, and changed open/error states in the owning slice. Target the established AA bar; do not add AAA Focus Appearance as a completion gate or claim comprehensive certification.

#### Elixir/Phoenix boundaries, maintainability, and bounded proof

- **D-24:** Keep LiveView/components responsible for interaction and presentation, Admin queries for scoped reads, and `Accrue.Billing`/core for billing mutations and domain semantics. Reuse core lifecycle predicates in a small local action mapping. Extract a private Admin helper only where real repetition or handler complexity justifies it. Do not add a public eligibility API, UI framework, new runtime dependency, role system, or duplicated billing state machine.
- **D-25:** Preserve host-owned Repo/auth/session/supervision/configuration and configurable mount paths. URLs and event payloads are untrusted navigation/action input. Apply scope to detail loads, search, aggregates, related links, action revalidation, and result refresh; a customer billing manager remains outside Admin. Keep denial generic and payment-token/credential data out of rendered HTML, errors, logs, and result evidence. Stronger permission policy must come from the existing host boundary, not an invented Admin role vocabulary.
- **D-26:** Preserve bounded cursor queries and limited search results; avoid N+1 lookups, full-population counts for decoration, and per-render remote calls. Reuse established preloads/query patterns. Query-plan or transaction changes require a measured problem in this flow; no speculative cache, new indexes, or core transaction redesign as UI work. Keep provider latency and local evidence failure distinct in diagnostics, using existing safe telemetry/audit mechanisms rather than new high-cardinality or sensitive fields.
- **D-27:** Plan acceptance alongside the changed behavior at the least costly credible layer. Pure status/money/eligibility cases belong in unit/contract coverage; mounted scope, forged events, step-up, and state changes in integration/LiveView coverage; navigation, real keyboard/focus, responsive layout, themes, and served assets in representative browser evidence. Include positive controls with denials and representative two-owner/nondefault-scope cases. Restore the skipped mounted denial proof after diagnosing its fixture/application failure. Fake remains deterministic evidence; provider-specific fixtures do not establish live-provider parity. Current rebuilt/served captures must support visual claims; old snapshots are historical references.
- **D-28:** Keep the pass finite: fix named correctness, comprehension, accessibility, and interaction defects in owned flows, reuse the existing component and CI facilities, and document cross-route effects. No all-permutations screenshot matrix, paid evaluator, global aesthetic ratchet, or unrelated test/CI overhaul. This discussion ran no application tests, browser sessions, or new renders and asserts no implementation verification.

### the agent's Discretion and Bounded Planning Probes

The researcher/planner may choose local helper/module boundaries, safe return-state encoding, exact copy and layout order, representative fixtures, and the smallest component/CSS changes that satisfy these decisions. No routine product question remains open.

Resolve these concrete probes from current code before implementation:

1. Map each existing action to core/provider lifecycle rules, including cancellation/resume, pause collection, compensation, and item membership; do not copy provider-only UI predicates as sufficient eligibility.
2. Trace step-up continuation, operation identity, duplicate dispatch, error classification, post-action scoped refresh, and replacement links end to end. If existing mechanisms cannot substantiate a guarantee, preserve a safe bounded outcome and describe the limit instead of inventing durability.
3. Reconcile search placeholder/ID claims, partial query failures, and list handoff semantics; preserve the existing supported search contract without broadening search as a feature.
4. Determine the smallest safe context-return mechanism, including alternate mounts, invalid cursors, owner switches, browser Back, and direct links.
5. Establish current served route/action renders before selecting exact spacing/table-card/tab changes; verify shared changes against adjacent consumers.

### Deferred Ideas (OUT OF SCOPE)

- New search engines/syntax/resource types, saved-view management, new customer routes, universal layouts, support/engineer modes, or density settings.
- Generalized health/risk/causality diagnosis, new billing actions, provider parity, dynamic processor routing, role management, or operator impersonation.
- Durable operation/reconciliation infrastructure, a public action-eligibility API, speculative query/index/cache changes, or core remote-transaction redesign without a demonstrated required-flow failure.
- Broader money/recovery refinement in Phase 237, events/webhooks/catalog/Connect in Phase 238, and Portal/checkout or integrated milestone handoff in their existing owning phases.
- The stale Portal evidence sentence in PRODUCT.md is a known documentation reconciliation item; it does not reopen the completed Phase 233 contract. Keep correction within a later owned docs pass.

No new product scope was added. Further broad research has reached diminishing returns; planning should resolve the named code probes and proceed with bounded implementation and evidence.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADM-01 | Operators can distinguish known subscription lifecycle from missing ancillary observations. | Reuse `Accrue.Billing.Subscription` lifecycle predicates and render status separately from missing price/date observations; test missing-data cases. |
| ADM-03 | Operators can search, enter nondefault owner scope, navigate records, and return with context. | Existing `OwnerScope`, scoped Ecto list/detail queries, cursor contract, and mount-aware paths are in place; add bounded validated return context and partial-failure handling. |
| ADM-04 | Operators can use only eligible lifecycle actions with confirmation, step-up, expiry, duplicate protection, and truthful results. | Existing drawer/step-up/facade flow is reusable, but requires fresh scoped target/authorization/eligibility checks and outcome classification before dispatch/result. |
| SAFE-01 | Mounted denials and forged actions remain denied without foreign records or payment-token data. | Reuse existing owner-scoped queries and host auth; prove positive and denial paths through LiveView and browser-representative assertions. |
</phase_requirements>

## Summary

This phase is an in-package Phoenix LiveView refinement with no new dependencies. Keep Admin interaction and presentation in LiveViews/components, scoped reads in `AccrueAdmin.Queries`, and mutation/lifecycle semantics in `Accrue.Billing`; the host continues to own Repo, authentication policy, session and mount configuration. This direction is explicit in Phase 234 context and aligns with the current Phase 233 semantic roles (`.planning/phases/233-shared-direction-portal-contract/DESIGN.md`).

The action, step-up, return-state, and search findings below are source-verified. In particular, `SubscriptionLive` uses provider-based action checks and dispatches with socket-assigned records, creates a fresh UUID operation identity at dispatch, and refreshes through an unscoped loader. Step-up stores a closure continuation in socket assigns. Global search executes three limited existing list queries but reduces task exits to empty result groups; its placeholder claims customer ID matching that `Customers.list/1` does not perform. [VERIFIED: `accrue_admin/lib/accrue_admin/live/subscription_live.ex:137-169,1550-1569,1603-1635,1845-1855,1878-1888`; `accrue_admin/lib/accrue_admin/step_up.ex:27-55,62-83`; `accrue_admin/lib/accrue_admin/components/global_search.ex:72-121`; `accrue_admin/lib/accrue_admin/queries/customers.ex:97-145`] Current served rendering remains to be captured during execution.

**Primary recommendation:** Plan bounded vertical slices around truthful scoped lookup/navigation and lifecycle/action correctness. At every mutation boundary re-read the same owner-scoped target, re-evaluate host auth and core/provider/item rules, and bind the reviewed intent to its operation identity. Preserve an explicit unknown outcome when provider execution may have occurred; never blind-retry. Use current shared components and capture representative rebuilt/served states during execution.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Search, detail, filters, cursor and return context | API / Backend (Admin query modules) | Browser / Client (LiveView) | Queries enforce owner-scoped bounded reads; LiveView owns interaction and URL state. |
| Host/operator authorization and owner selection | API / Backend (host boundary) | Frontend Server (LiveView mount/events) | Admin must reuse host policy and apply it for mounted/action paths; a hidden control is not authorization. |
| Lifecycle facts and action semantics | API / Backend (`Accrue.Billing`) | Frontend Server (small UI mapping) | Core predicates/facade own domain rules; UI maps eligible actions and presents consequences. |
| Mutation, step-up, operation identity, result evidence | API / Backend (Billing/Auth/Event contracts) | Frontend Server (staged interaction) | Billing dispatch and host step-up are authoritative; socket state is ephemeral orchestration only. |
| Responsive layout, themes, keyboard/focus | Browser / Client | Frontend Server (rendered markup/LiveView patches) | CSS/DOM semantics and focus lifecycle are browser behavior; current package components/tokens are shared implementation. |

## Standard Stack

### Core

| Library / subsystem | Version | Purpose | Why Standard |
|---|---:|---|---|
| Elixir / Phoenix LiveView | Current lockfile; see `accrue_admin/mix.lock` | Admin routes and server-driven interaction | Existing package implementation and tests are the authority; do not upgrade dependencies in this phase. |
| Ecto / host Repo | Current lockfile | Owner-scoped list/detail queries and cursor reads | Existing query modules compose Ecto filters with `OwnerScope`; host owns Repo configuration. |
| `Accrue.Billing` | In-repo | Mutations, provider contracts, lifecycle predicates | Locked boundary: billing semantics stay in core; no duplicate state machine. |
| Existing `AccrueAdmin.Components.*` and `--ax-*` CSS | In-repo | DataTable, details, drawers, dialogs, status, theme | Reuse current component and token ownership; Phase 233 DESIGN defines semantic direction. |

### Supporting

| Existing subsystem | Purpose | When to Use |
|---|---|---|
| `AccrueAdmin.OwnerScope` / `ScopedPath` | Authorized owner context and mount-aware URL construction | For every query, related link, return target, refresh, and navigation state. |
| `AccrueAdmin.Queries.Behaviour` / `Cursor` | Bounded list/filter/cursor contract | Keep existing pagination and invalid cursor recovery semantics. |
| `AccrueAdmin.StepUp` | Challenge, grace window, continuation and audit behavior | Preserve the existing challenge path; reassess freshness and target immediately before continuation dispatch. |
| `AccrueAdmin.BillingPresentation` and copy modules | Exact money/state/action presentation | Reuse for truthful lifecycle/amount/date values and stable wording. |

**Installation:** None. This phase is code/config within existing packages and authorizes no dependency changes.

## Architecture Patterns

### Existing ownership pattern

`LiveView event or URL -> Admin Query scoped by OwnerScope -> render bounded data`; mutation path is `reviewed UI intent -> fresh scoped target/auth/rule checks -> Accrue.Billing facade -> classify returned evidence -> scoped local refresh/result link`. Keep these responsibilities separated. This is project-specific and verified in the source files listed below.

### Action eligibility and fresh dispatch

The UI exposes action identifiers below. Its present gate is a discovery/limited capability check, not the full domain contract. The core source gives explicit preconditions for only some operations; where no lifecycle guard is in the facade function, don't claim one exists. [VERIFIED: `accrue_admin/lib/accrue_admin/live/subscription_live.ex:34-41,1550-1569,2035-2058,2089-2094`; `accrue/lib/accrue/billing/subscription_actions.ex:325-412,574-612,637-769,800-861,879-915,936-978`; `accrue/lib/accrue/billing/subscription_items.ex:29-51,58-126,135-167`; `.planning/processor-support-matrix.md:46-53,112-118`]

| Existing action | Current UI gate | Actual core/provider precondition | Recommended Admin mapping |
|---|---|---|---|
| `cancel_now` | Always `true` for any mounted subscription. | Facade `cancel/2` validates its options and resolves adapter, but has no lifecycle predicate in the function; support matrix says immediate cancellation is supported by Stripe, Braintree and Fake. | Offer only while current lifecycle is cancellable per existing provider/core state semantics; re-check authorization, lifecycle, and the unchanged target. Review immediate consequence, never imply that core currently enforces a status gate. |
| `cancel_at_period_end` | Any subscription except Braintree. | Core schedules via adapter `update_subscription`; matrix marks supported for Stripe/Fake and unsupported for Braintree. No facade lifecycle predicate is visible. | Restrict to eligible nonterminal current lifecycle and supported provider; display schedule date/timing from known data. |
| `resume` | Any non-Braintree subscription. | `Billing.resume/2` requires `Subscription.canceling?/1`; Braintree rejects provider-side cancellation reactivation. | Show only for `canceling?`; dispatch it only for a freshly canceling subscription. |
| `pause` / collection pause | Any non-Braintree subscription. | Core validates pause behavior and returns unsupported for Braintree, but no lifecycle predicate appears in the facade. The processor support matrix explicitly lists pause/resume as out of slice, so `not Braintree` does not establish a first-party support promise. | Preserve only already-supported configured behavior within the existing boundary; do not claim provider parity. Where support is not established, hide the action and explain the state/capability restriction. Keep collection pause distinct from lifecycle and cancellation resumption. |
| `resume` when collection is paused (`unpause`) | Same provider-only UI gate as resume. | UI dispatch branches to `Billing.unpause/2` when `paused?/1`; core requires paused and Braintree rejects it. | Make action label/consequence explicit for the current state: cancel-schedule resume vs collection unpause; re-evaluate branch after fresh load. |
| `swap_plan` | Always for non-Braintree; for Braintree only if `PlanResolver.configured?/0`. | Core requires a single existing item. Braintree additionally resolves old/new configured plans, requires target plan processor `braintree`, matching currency and billing cycle; other providers resolve adapter and use provider contract. | Revalidate current item set, provider capability, resolver result, and preview support; represent unsupported/unavailable preview facts as unknown. |
| `update_quantity` | Non-Braintree and exactly one existing item. | Core requires positive integer, rejects Braintree, and enforces single-item semantics. | Retain single-item/provider gate; validate positive quantity and refresh the actual item before review/dispatch. |
| `add_item` | Non-Braintree. | Core requires binary price ID, positive quantity (default 1 in core options), explicit supported proration, adapter support; matrix lists Fake/Stripe and excludes Braintree. | Retain provider gate; revalidate price/capability/quantity/proration payload and current subscription at dispatch. |
| `update_item_quantity` | Non-Braintree. | Core requires positive quantity, a real persisted item with parent subscription, explicit proration, and adapter support; matrix excludes Braintree. UI resolves item ID from the subscription’s current preloaded item list. | Re-resolve item membership from fresh scoped subscription after step-up; reject removed/foreign item IDs. |
| `remove_item` | Non-Braintree; destructive, so step-up is required. | Core resolves persisted item’s parent subscription, adapter support, and explicit proration; matrix excludes Braintree. | Re-resolve membership on fresh target, preserve consequence/proration review, then dispatch. |
| `comp_subscription` | Always `true` for any mounted subscription; destructive, step-up required. | Core creates a new subscription for the customer using a price spec and configured comp coupon; it is not a mutation of the source subscription. | Treat as replacement creation; validate customer/source scope and price/coupon configuration, preserve original and new subscription IDs, and scope the replacement read/link. |

Source evidence includes these exact relevant values and predicates:

> UI actions: `"cancel_now"`, `"comp_subscription"`, `"remove_item"`; pause values: `"void"`, `"mark_uncollectible"`, `"keep_as_draft"`; proration values: `"create_prorations"`, `"none"`, `"always_invoice"` (`subscription_live.ex:34-41`).
> `def resume(%Subscription{} = sub, opts) do` / `unless Subscription.canceling?(sub) do` (`subscription_actions.ex:728-736`).
> `def unpause(%Subscription{} = sub, opts) do` / `unless Subscription.paused?(sub) do` (`subscription_actions.ex:939-946`).
> The pause behavior branch matches `"void"`, `"mark_uncollectible"`, and `"keep_as_draft"` (`subscription_actions.ex:808-818`).
> Capability rows: `subscription.cancel_immediately | Supported | Supported | Supported`; `subscription.cancel_at_period_end | Supported | Supported | Unsupported`; `subscription.update_quantity | testing/local-only | native | unsupported`; `subscription_item.add | testing/local-only | native | unsupported` (`.planning/processor-support-matrix.md:46-53`). Out-of-slice wording: `pause/resume, schedules beyond the bounded swap contract, and invented preview equivalents` (`.planning/processor-support-matrix.md:112-118`).

The existing continuation is concrete: `confirm_action` passes `&execute_pending_action(&1, action)` into `StepUp.require_fresh`; `StepUp` stores that closure under `:step_up_continuation` and invokes it after successful verification. That means stale `action` and the socket's originally assigned subscription survive the delay. [VERIFIED: `subscription_live.ex:137-163`; `step_up.ex:47-55,64-83`] `OwnerScope.resolve/2` re-derives the current user through `Auth.current_user(session)` and applies `Auth.admin?/1` plus organization membership from the supplied session (`owner_scope.ex:67-120`); `Auth` exposes host `current_user/1`, `require_admin_plug/0`, and optional `admin?/1` behavior (`accrue/lib/accrue/auth.ex:19-49,51-93`). The LiveView mount hook stores that session and resolved scope (`auth_hook.ex:11-28`). Recommended bounded repair: stage target ID, action/payload fingerprint, and operation ID; before dispatch re-run `OwnerScope.resolve(saved_host_session, params_derived_from_current_scope)`, require the same actor and same scope, then use `Subscriptions.detail(target_id, resolved_scope)`, recompute core/provider/item eligibility and review consequence, and re-check step-up freshness. If host auth depends on revocable state outside its session/current-user adapter, the current package exposes no generic per-event reauthorization callback; keep this limit explicit and use only an existing host-supplied `on_mount`/session auth contract rather than inventing a role API. Material differences clear confirmation and require a fresh review; absent/denied records clear intent and return generic denial. No remote fetch or transaction redesign is implied.

Operation identity and result seams: `with_admin_context/2` currently mints `"admin-ui-" <> Ecto.UUID.generate()` inside dispatch; facade calls receive it, and Stripe core operations derive idempotency keys from that op ID (examples: cancel `subscription_actions.ex:639-653`, quantity `576-600`, and item operations `subscription_items.ex:58-88,98-124,137-167`). [VERIFIED: `subscription_live.ex:1845-1855`; `subscription_actions.ex:639-653`; `subscription_items.ex:58-88`] Mint the ID once when a validated staged intent is created and reuse through confirm and step-up. Guard an in-flight/submitted intent server-side; after reconnect, discard it rather than replay. Existing return shapes are `{:ok, %Subscription{}}`, `{:ok, {:comped, new_subscription}}`, `{:ok, :requires_action, payment_intent}`, and `{:error, reason}` in the Admin handler. [VERIFIED: `subscription_live.ex:1611-1635`] Current handler treats all errors as generic failure and clears pending intent; it cannot safely prove ambiguous provider timeout means no action. Add a conservative classifier only for already-distinguishable local validation/provider outcomes; classify unrecognized/possibly-dispatched failures as outcome-unconfirmed and clear executable confirmation.

Replacement/scoped-read seam: compensation returns the new `%Subscription{}` but current success path refreshes `subscription.id` (the source), flashes the new processor/local ID as plain text, and does not link to it. Normal refresh calls `load_subscription/1`, which uses `Repo.get` and preloads without `OwnerScope`; mount itself uses `Subscriptions.detail(id, scope)`. [VERIFIED: `subscription_live.ex:44-54,1603-1625,1801-1840,1878-1888,809-816`] Use `Subscriptions.detail(new_subscription.id, current_scope)` before exposing a replacement link; if it is not visible, retain the original detail and report a generic scoped outcome without leaking the foreign identifier. Refresh both original and replacement only through owner-scoped query functions.

### Bounded search and context

The existing search component invokes three existing query modules with `limit: 5`; customer matching is email, name, owner ID, processor ID, while subscription matching is customer email/name and subscription processor ID. The component placeholder is exactly `"Type customer name, email, or ID"`; that over-promises customer ID matching because `Customers.list/1` does not match `customer.id`. [VERIFIED: `global_search.ex:72-90,147-173`; `queries/customers.ex:97-115`; `queries/subscriptions.ex:115-141`] Keep group failures visible instead of treating exits as empty. Preserve this query contract; no generic ID search is authorized.

### Bounded return-state mechanism

Existing list filter state is URL-backed: customer/subscription list events call `DataTableNav.patch_with_filters/3`; subscriptions retain the selected `view`; customer detail reads `tab`; both query modules use opaque signed cursors through `Queries.Cursor`. Existing customer tab IDs/URL values are `"subscriptions"`, `"invoices"`, `"charges"` and `"payments"` for the charges tab (`customer_live.ex:33,834-852`). `Cursor.decode/1` returns `:error` for invalid/tampered values, and `Queries.Behaviour.decode_cursor/1` currently falls back to no cursor. [VERIFIED: `customers_live.ex:72-84`; `subscriptions_live.ex:56-83`; `customer_live.ex:33,81-90,834-852`; `data_table_nav.ex:26-59`; `queries/cursor.ex:14-42`; `queries/behaviour.ex:32-40`] Recommendation: preserve return context as an allowlisted relative route plus only current list query keys (customer `q`, `owner_type`, `has_default_payment_method`, `cursor`; subscription `q`, `status`, `customer_id`, `cursor`, `view`; customer `tab`). Do not accept absolute URLs or route prefixes outside the actual mount. Rebuild paths with `ScopedPath.build(@admin_mount_path, suffix, current_owner_scope, allowed_params)` so an authorized current `org` scope wins; never take `org` from the return blob. Keep ordinary list patches in browser history so Back works naturally; use a contextual return link for direct deep links. If cursor is malformed or no longer valid against current page data, return to the same scoped/filter view at its first page with explicit recovery copy. [VERIFIED: `scoped_path.ex:7-27`; `queries/cursor.ex:26-42`; `subscriptions_live.ex:66-83`]

### Action intent and outcome

Stage one logical reviewed action including target and relevant payload; retain its operation identity through confirmation and step-up continuation. Guard repeated events server-side as well as disabling controls. Since socket assigns and closures are ephemeral, reconnect must discard uncertain pending intent without replay. Differentiate definite validation rejection from potentially dispatched timeout/provider ambiguity; after ambiguous outcomes clear confirmation, show “Outcome not confirmed,” and provide scoped history/read path. Compensation yields a replacement subscription, so preserve both original and replacement identity.

### Anti-patterns to avoid

- Provider-only availability as authorization or lifecycle eligibility.
- Trusting rendered assigns after step-up or owner-scope change.
- Generating a new operation key for a retry after ambiguous execution.
- Unscoped detail/refresh/aggregate reads or raw query parameters as access proof.
- Treating failed search groups as empty results, stale search replies as current, or arbitrary IDs as searchable.
- Inferring status/health/host entitlement from missing price/date, caveats, collection pause, invoice totals, or past failures.
- New search backend, public eligibility API, role model, durable reconciliation system, dependency, query optimization, or global visual/testing framework.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Lifecycle truth and eligibility | A parallel status/action state machine | `Accrue.Billing.Subscription` predicates, facade, provider support matrix | Prevent UI/core divergence and provider capability overstatement. |
| Scope and tenant isolation | Query-param ownership or UI-only hiding | `OwnerScope`, scoped query modules, host authorization | Current scope is a security boundary and must apply at every read/write edge. |
| Cursor pagination | Offset/full-population scans | Existing `Queries.Behaviour` and `Cursor` | Existing contract bounds list work and gives a stable tie-break. |
| Exact amount formatting | Float math or hard-coded currency precision | Existing billing presentation/money formatter | Preserve currency minor-unit rules. |
| Search infrastructure | New backend, syntax, query language or resource families | Existing three list queries, limit-5 grouped preview | Explicit scope prohibits feature expansion. |
| Dialog/focus mechanics | New modal primitives | Existing overlay/drawer/step-up components and JS hooks | Maintain established keyboard and nested overlay behavior. |

## Common Pitfalls

1. **Known state disappears behind caveats.** Keep lifecycle independently visible; each unavailable observation gets its own unavailable label.
2. **Action appears eligible because processor supports it.** Verify lifecycle, host auth, subscription/item ownership, quantity limits and refreshed state using core predicates/facade rules.
3. **Step-up delay makes review stale.** The closure currently continues from the earlier action/socket target. Freshly scope/re-authorize/revalidate before continuation and require review again when a consequence-relevant value changed.
4. **“Exactly once” is promised from ephemeral state.** Socket-held identity is not durable across reconnect; don't replay or use a fresh key for an unknown result.
5. **Post-action read escapes scope.** Scope original and replacement record refresh/navigation; preserve source context for compensation.
6. **Partial search failure looks like no matches.** Keep successful groups, show unavailable group(s), provide read retry, invalidate on query/scope changes.
7. **Return state becomes authority or breaks alternate mounts.** Bound/validate allowed route/filter/tab/cursor values; build using actual configured mount and derive owner from currently authorized scope.
8. **Desktop/mobile markup diverges accessibly.** Preserve DataTable’s desktop and labeled-card variants without duplicate IDs/content or focusable hidden controls; check real served narrow and theme states.

## Code Examples

These are current in-repo contract examples, not proposed new APIs. Discrete values below are quoted verbatim from source-of-truth files.

### Owner-scoped subscription detail

`accrue_admin/lib/accrue_admin/queries/subscriptions.ex:88-102` contains:

> `def detail(id, owner_scope) when is_binary(id) do`
> `|> scope_query(owner_scope)`
> `|> where([subscription, _customer], subscription.id == ^id)`
> `nil ->`
> `:not_found`

Use this query as the basis for fresh detail/revalidation reads; do not use an unscoped loader for action results.

### Core predicates for lifecycle mapping

`accrue/lib/accrue/billing/subscription.ex:166-208` defines verbatim:

> `def canceled?(%__MODULE__{status: s}) when s in [:canceled, :incomplete_expired], do: true`
> `def canceling?(%__MODULE__{`
> `status: :active,`
> `cancel_at_period_end: true,`
> `current_period_end: %DateTime{} = cpe`
> `}) do`
> `DateTime.compare(cpe, Accrue.Clock.utc_now()) == :gt`
> `end`
> `def paused?(%__MODULE__{pause_collection: pc}) when is_map(pc), do: true`
> `def paused?(%__MODULE__{status: :paused}), do: true`

Read the complete predicates and their action callers before mapping all actions; these examples do not state the whole eligibility contract.

## Project Constraints (from CLAUDE.md)

- Before direct file-changing tools, use an applicable GSD entry point; this task is explicitly delegated research and writes only its required artifact.
- Machine-verifiable behavior must use deterministic automated assertions; do not replace it with routine human UAT.
- Use committed current-source/render evidence; historical screenshots do not prove current rendering.
- Follow safe working-tree discipline; this research makes no git mutations.

No `AGENTS.md` exists at repository root (searched this session).

## Validation Architecture

Validation is enabled in `.planning/config.json` (`workflow.nyquist_validation: true`). This is planning guidance only; no test, browser, asset build, or application run was performed.

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit in `accrue_admin/test`; Playwright package lane in `accrue_admin/e2e`, adopter-host lane in `examples/accrue_host/e2e` |
| Config | `accrue_admin/mix.exs`; `accrue_admin/playwright.config.js`; `examples/accrue_host/playwright.config.js` |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/step_up_test.exs` |
| Browser lane example | `cd examples/accrue_host && npm run e2e -- e2e/phase233-semantic.spec.js --workers=1` |
| Admin build | `cd accrue_admin && mix accrue_admin.assets.build` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated command | Existing file / gap |
|---|---|---|---|---|
| ADM-01 | Active/trialing/etc remains known with absent price/date/ancillary facts; dates/amounts remain truthful | ExUnit unit + LiveView | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs` | Existing tests; extend named cases. |
| ADM-03 | Search fields/partial failure, owner scope, correct links, filters/tab/cursor return, alternate mount and stale cursor | ExUnit + browser | `cd accrue_admin && mix test test/accrue_admin/components/global_search_test.exs test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/scoped_path_test.exs` | Existing tests; add failures/return journey assertions. |
| ADM-04 | Forged/ineligible action rejection, fresh after step-up, duplicate guard, changed intent review, ambiguity, scoped refresh and replacement link | ExUnit LiveView + browser | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/step_up_test.exs` | Existing files; restore skipped mounted-denial proof after fixture diagnosis. |
| SAFE-01 | Two-owner positive/negative controls; forged events expose no foreign data/token | ExUnit LiveView; browser representative | Same LiveView command above; then host browser lane | Existing customer/subscription tests; explicit coverage gap noted in D-27. |

### Finite browser evidence

There are two distinct Playwright lanes. `accrue_admin/playwright.config.js` owns Admin package E2E (`accrue_admin/e2e`) and starts `mix accrue_admin.e2e.server`; `examples/accrue_host/playwright.config.js` owns adopter-host E2E (`examples/accrue_host/e2e`) and starts the host app. The provided command `cd examples/accrue_host && npm run e2e -- e2e/phase233-semantic.spec.js --workers=1` runs only the host lane. [VERIFIED: `accrue_admin/playwright.config.js:1-44`; `examples/accrue_host/playwright.config.js:1-51`; `examples/accrue_host/package.json:scripts.e2e`]

Put phase-specific Admin served-flow coverage in `examples/accrue_host/e2e` if it needs the host’s deterministic auth/organization fixtures and execute it through the host lane. Use `accrue_admin/e2e` only for package-owned visual/interaction behavior served by the Admin E2E server; do not expect that command to run an Admin package spec. For the host spec, cover one two-owner/nondefault-scope journey and one action/step-up outcome: direct deep link, contextual return/browser Back, malformed or stale cursor recovery, keyboard search/drawer/challenge focus, 320 CSS px/coarse pointer and representative light/dark/open/error states. Inspect current served renders; do not infer them from snapshots or run an all-permutations matrix. This is a test-location/command distinction, not a proposal to duplicate specs.

### Wave 0 gaps

- Diagnose and restore the skipped mounted owner-denial proof, preserving a positive control.
- Add focused assertions for partial search task failures, stale-query invalidation, exact return-state/mount handling, post-step-up fresh eligibility, duplicate dispatch, ambiguous result behavior, and scoped compensation replacement navigation.
- Add the finite host browser spec at `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js` and run using the example host Playwright config; existing broad browser specs do not by themselves prove this phase’s specific route/action contract.

## Security Domain

Security enforcement is enabled by default; Phase 234 explicitly includes SAFE-01. Use host authorization plus owner-scoped query reads for every detail, aggregate, related link, action revalidation, and result refresh. Treat URL and LiveView event payloads as untrusted; a hidden button is not a control. Denials should stay generic and must not reveal foreign identity, credentials, or payment-token values. Browser return context cannot set scope or authorize records.

| ASVS area | Applies | Standard control |
|---|---|---|
| V2 Authentication | Yes | Existing host `Accrue.Auth` and Admin mount boundary; no new auth system. |
| V3 Session Management | Yes | Preserve host session, configurable mount, step-up grace/challenge lifecycle. |
| V4 Access Control | Yes | Fresh host/operator authorization plus `OwnerScope`-scoped target and item checks. |
| V5 Input Validation | Yes | Parse/bound filter, cursor, return path and action fields; reject forged/stale values. |
| V6 Cryptography | Conditional | No new crypto; use existing auth/step-up/provider tokenization contracts and never expose token material. |

## Environment Availability

No external service or new tool is required for implementation. Current package metadata declares Node `22.x` for the example host, and the project uses existing Elixir/Mix and Playwright lanes. [VERIFIED: `examples/accrue_host/package.json:engines.node`; `accrue_admin/playwright.config.js`; `examples/accrue_host/playwright.config.js`] Runtime availability was not checked here; do not infer missing dependencies from that. Per task constraints, no installs, builds, application tests, or browser runs were performed.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Exact current served appearance of Admin customer/subscription routes is unknown until execution captures fresh renders. | Summary / Validation | Choosing spacing or layout without this can miss the actual UI defect. |
| A2 | Test fixture support for deterministic two-owner scope and step-up state needs inspection before implementation. | Validation | Could require fixture repair before assertions can prove denial and positive controls. |

## Open Questions

No product question remains open. Source implementation questions are the five bounded probes copied above; the planner should assign each probe to an implementation/evidence task. Exact step-up continuation behavior must be revisited when applying fresh authorization and target checks; this research does not claim durable idempotency or remote/database atomicity.

## Sources

### Primary (HIGH confidence)

- `234-CONTEXT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `CLAUDE.md` — locked scope, requirements, acceptance, and working constraints.
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — action gates, event path, step-up continuation, result handling, operation identity, refresh and lifecycle display.
- `accrue_admin/lib/accrue_admin/step_up.ex` — grace window, continuation, challenge and audit behavior.
- `accrue_admin/lib/accrue_admin/queries/{subscriptions,customers,behaviour}.ex` — scope, filters and cursor contracts.
- `accrue_admin/lib/accrue_admin/components/global_search.ex` — fields/limits, parallel group queries and failed-task reduction.
- `accrue_admin/lib/accrue_admin/{owner_scope,scoped_path}.ex` — current authorized scope and mount-aware links.
- `accrue/lib/accrue/billing/{subscription,subscription_actions,query}.ex` — core lifecycle/action rules.
- `.planning/phases/233-shared-direction-portal-contract/DESIGN.md` — current semantic roles and Admin token ownership.
- `accrue_admin/test` and `accrue_admin/e2e` — available automated test lanes.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — inspected existing implementation and lockfile/package layout; no new packages are recommended.
- Architecture: HIGH — current source and locked context agree on query/core/host boundaries.
- Pitfalls: HIGH for source-observed hazards; MEDIUM for browser/render consequences pending fresh served evidence.

**Research date:** 2026-10-07  
**Valid until:** 2026-11-06 for stable in-repo architecture; re-read current action/query source before implementation if it changes.
