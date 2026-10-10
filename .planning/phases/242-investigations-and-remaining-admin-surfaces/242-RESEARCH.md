<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Investigation hierarchy, evidence and replay

- **D-01:** Serve engineers and support/billing operators equally through identity/current scope → observed facts and material failures/uncertainty → supported next action → related evidence. Keep routine filters, selected lens and actionable facts visible. Use existing lists, detail fields, related links and disclosures according to their jobs; no universal columns, cards or tables.
- **D-02:** Distinguish the append-only local billing **event** from a received webhook **delivery** and its processing attempts/derived events. Use deliveries for webhook selection and result counts; source event types, actor/subject types, processor identifiers and diagnostic fields retain their exact meaning. A delivery, queued replay and resulting billing event are distinct observations.
- **D-03:** Retain familiar lazy activity/raw-data disclosure. Exact IDs, source relationships, timestamps, live/test mode, processing failures, payloads and available attempt evidence remain discoverable. Material failure, unsupported/ambiguous scope, uncertainty and replay consequence cannot depend on expanding raw JSON. Do not invent activity, causal links or a healthy state from absent evidence.
- **D-04:** Preserve the existing inline single/bulk replay review rather than introducing another wizard or universal action framework. A review identifies the exact delivery or selected set, current owner/eligibility, supported consequence and locked audit/replay wording. Selection changes or fresh scope/eligibility/material-state changes must not silently replay a different set. Dismissal cannot dispatch; step-up, fresh authorization and duplicate protections stay with their existing owners.
- **D-05:** Replay results distinguish queued/accepted, skipped/ineligible, denied, failed and unknown according to actual evidence. Enqueue acknowledgement does not imply successful processing or money movement. Reread failure after acceptance is not a failed replay that invites a blind retry. Initial/partial list failure, unavailable detail, no match and no records keep their separate supported recovery actions.

#### Bounded list returns and existing relationships

- **D-06:** Extend the accepted validated destination/label contract to the named event, webhook, coupon, promotion-code and Connect list→detail jobs. The explicit return names its actual family; direct/invalid entry uses that family's safe scoped list fallback. Structural breadcrumbs remain distinct from a contextual filtered return.
- **D-07:** Preserve only meanings supported by the destination's current decoder and list behavior: current owner, supported search/filter/lens and relevant relationship constraint. Inventory exact decoder/allowlist/encoder parity during planning. Do not preserve ignored keys or infer behavior from URL equality alone. Sorting is included only where an existing destination supports it. Pagination, accumulated rows and scroll restoration are not new acceptance promises.
- **D-08:** Reuse `ScopedPath` and freshly resolved owner scope. Reject external/scheme-relative, malformed/ambiguous, other-mount and unauthorized destinations; caller-supplied owner data cannot choose the return scope. Preserve Phase 241's validated label/path agreement and malformed-percent boundary. Do not add nested return stacks, a navigation session service or routing dependency.
- **D-09:** Existing event→source delivery/subject and coupon→promotion-code→parent links preserve authorized resource and relationship identity. Provide accurate reciprocal/source links, bounded list context and ordinary Browser Back where appropriate. Do not expand the helper to arbitrary detail origins merely to recreate a full multi-hop stack. A missing, inaccessible or unavailable relationship remains truthful and does not produce a plausible link to an unrelated record.

#### Catalog and Connect facts

- **D-10:** Keep coupon/discount terms and promotion-code identity, parent relationship, validity/activity, expiry, redemption limits and provider-defined restrictions clear. Preserve the approved resource vocabulary and distinguish a discount definition from a code that refers to it. Exact internal `Coupon`, API/model names and provider keys remain available in diagnostics; routine operator wording comes through existing Copy owners. Do not claim a missing parent or unknown limit is unrestricted, or add catalog creation/edit capabilities.
- **D-11:** Connect readiness, capabilities and requirements are stored provider observations. Keep the existing statement that the page does not track when Stripe last reported them; no invented freshness timestamp or live readiness claim. The supported platform-fee override is local policy and cannot imply remote capability/readiness changes.
- **D-12:** Apply the accepted self-contained review arrangement to the existing Connect fee form/drawer: exact account/owner, current local policy, proposed override/default consequence, supported validation and observation limits. Preserve fresh target/policy/actor authorization, step-up, exact monetary/percentage semantics, duplicate protection, associated errors and logical focus return. Do not copy billing rules into presentation or generalize a new action engine.

#### Home, navigation, search and coherent copy

- **D-13:** Retain familiar static navigation and current Home. Make current route, owner and existing scoped destinations agree across Home, sidebar, breadcrumbs and search. Search remains bounded to its existing customers/invoices/subscriptions groups; do not add a new resource index, ranking system, command family or Home metrics rebuild.
- **D-14:** Search has one authoritative active result for pointer and keyboard use. Visible highlight, accessible semantics and Enter activation agree after pointer movement, Arrow navigation, query completion, LiveView replacement and scope changes. Keep real result links, bounded groups, clear identity and existing focus containment/restoration; choose semantics appropriate to the actual widget rather than adding `aria-selected` to arbitrary links.
- **D-15:** Preserve actual asynchronous search states: empty query/list shortcuts, loading, populated results, no match, partial/unavailable group and retry of unavailable lookups. An older query or owner result must not supersede current input/scope. Retain successful groups when another fails. Search-query persistence after opening a record is not an established contract; safe scoped destination and Browser Back remain sufficient.
- **D-16:** Use consistent resource, collection-method and action vocabulary through incumbent Copy modules across lists, details, filters/chips and reviews, including earlier billing copy where needed for UXC-01. Use **payment/Payments** for routine operator work and **Charge** where exact model/API evidence requires it; distinguish events from deliveries and human labels from raw collection enums. Review dismissal describes returning to the record, distinct from a domain cancellation. Preserve `Copy.Locked` verbatim and legal/audit/provider meaning; shorten procedural narration only when factual meaning remains intact.

#### Shared system, automation and stopping rules

- **D-17:** Use Impeccable Operate and incumbent Cobalt, Geist/Geist Mono and package `--ax-*` roles. Carry approved typography/spacing, deliberate 2px dense and 1px structural exceptions, theme precedence, coarse-pointer geometry, keyboard/focus and state distinctions. Repeated keyboard search stays immediate; reduced motion and inactive overlays cannot delay task access or intercept input. No decorative motion or new font/UI dependency. The maintainer chose to keep the current Impeccable version during this session; no update is part of this phase.
- **D-18:** Each changed consumer receives faithful recurring proof at its existing ExUnit/query/contract, package browser or mounted host owner. Include real filter result membership, scoped returns/labels, relationship identity, replay/fee review target and consequence, fresh safety checks, selection/input transitions and distinct error outcomes. Browser tests exercise pointer→keyboard→Enter, disclosure, validation/correction/dismissal, focus, busy/reconnect and responsive/effective-theme behavior where claimed. Use authoritative state/job/dispatch/audit assertions for no-mutation claims; a page non-GET HTTP count proves only its narrower transport claim.
- **D-19:** Shift left into existing merge-blocking CI lanes when there is recurring value. Prefer the cheapest precise check and focused failure controls over duplicate fixtures/full matrices. A small faithful local helper is preferable to another dependency; retain shared money/scope/auth owners. No paid AI evaluator, fixed sleeps, blanket retries, hidden exclusions or relaxed snapshot tolerances. Canonical SUMMARY coverage and generator-owned automated UAT accompany completion; required human UAT remains zero whenever repeatable evidence can decide the claim.
- **D-20:** Source candidates require current mounted confirmation before cosmetic correction. Record source/fixture/built/compiled/served asset provenance separately from exercised behavior; explicitly build package assets and confirm current mounted bytes. Keep mutation/reset proof in disposable fixtures separate from feedback-preview custody. Update existing route/state coverage rather than creating a parallel registry. Final Linux golden/mask closure remains Phase 243.
- **D-21:** Preserve the milestone's bounded inspection budget across captures/scans/edits/rebuilds: one complete build/check and batched desktop/narrow/effective-theme inspection, one corrective batch, at most one confirming inspection per agreed delivery batch. Close a candidate as adequate/unobserved when evidence warrants. Reopen only for a named defect, safety/behavior failure, changed requirement or explicit owner feedback. Preserve honest actual-browser-zoom, physical-device, screen-reader-speech, provider and local/remote evidence limits without introducing confirmation-only UAT.

### Agent Discretion

Exact task decomposition, routine faithful copy, reuse of existing components, small helpers, appropriate accessible search mechanics, representative fixtures and precise assertions are delegated within the approved boundary. Focused implementation/command research and the phase UI contract are next; broad milestone/sibling-project research, brand setup and approval interviews are complete. No genuine product fork is currently unresolved. If new evidence exposes one, identify that concrete fork rather than reopening the whole discussion.

### Deferred Ideas (OUT OF SCOPE)

Final complete selected Linux golden/mask review and stable Fake preview handoff belong to Phase 243. Portal cleanup, new diagnosis/causality/rooms, expanded search or catalog/Connect capabilities, new provider/freshness controls, arbitrary detail-origin stacks, scroll/pagination/search-state persistence, rebrand/framework/dependency migration, paid AI ratchet, CI redesign, release publication and unrelated historical debt remain outside this milestone. No new backlog item was promoted or invented by this discussion.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| JRN-05 | Trace existing events and webhook deliveries through related evidence and supported replay review without hiding failures, uncertainty, or diagnostics. | Event/webhook query parity inventory, validated return/label extension, source and subject relationships, replay stale-state/result checks, and scoped ExUnit/LiveView/host browser owners below. |
| JRN-06 | Inspect existing discounts, promotion-code relationships, and Connect facts with supported actions and explicit stored-provider versus local-policy boundaries. | Catalog query keys and link graph, Connect observed-field query and local override review owner, relationship/inaccessibility proof owners. |
| JRN-07 | Find the correct scoped record from Home/navigation/search with visible selection consistent across pointer and keyboard. | Existing shell/global-search paths and exact CommandPalette hook gap; test owners cover query/scope completion and pointer/Arrow/Enter parity. |
| UXC-01 | Use coherent resource, collection-method, and action language across changed lists/details/filters/reviews while exact diagnostics and locked legal/audit text stay intact. | Copy module owners and current mismatched webhook row terminology; keep Copy.Locked immutable and drive corrections through focused Copy/live owners. |
</phase_requirements>

# Phase 242: Investigations and Remaining Admin Surfaces — Research

**Researched:** 2026-10-10  
**Domain:** Phoenix LiveView Admin investigation, validated list returns, scoped search, catalog and Connect operator workflows  
**Confidence:** HIGH for source ownership, decoded values, local safety seams, and available test commands; MEDIUM for intended mounted visuals/interactions until executed in this phase.

## Summary

Phase 242 should propagate the Phase 241 destination/review pattern through the five named list/detail families, then repair search's active-result state at the existing client hook and reconcile domain labels through existing Copy modules. The current destination contract is `ScopedPath`; it rebuilds a local route under the freshly resolved owner and returns its label with the path. Extend its finite list-route map and per-key size/value validation, but preserve the completed billing destinations and reject invalid/foreign origins. The five query modules already define each list's actual filters; a return allowlist must encode those consumed meanings rather than preserve arbitrary URL keys. [VERIFIED: `accrue_admin/lib/accrue_admin/scoped_path.ex:6-24,78-108,140-213`; exact source map: `@return_routes %{ "/subscriptions" => ~w(view status q customer_id), "/customers" => ~w(q owner_type has_default_payment_method), "/invoices" => ~w(view q status customer_id collection_method), "/payments" => ~w(view q status customer_id fees_settled), "/analytics/recovery" => ~w(window) }`; exact limits: `"view" => 32, "status" => 128, "q" => 200, "collection_method" => 64, "fees_settled" => 8, "customer_id" => 128, "tab" => 32, "owner_type" => 64, "has_default_payment_method" => 8, "window" => 8`.]

Keep UI refinements attached to existing domain owners. Events/deliveries already have lazy activity and raw JSON disclosure, event/source and event/subject links, and single/bulk replay flows. Coupons and promotion codes already link as definition → code → parent; Connect already says readiness is from the last stored Stripe snapshot and separately edits the local fee override. Search already has the intended three bounded groups and asynchronous partial failures, but the hook resets index on each LiveView update and has no pointer-to-active synchronization. These are targeted propagation tasks, not new capabilities. Source review is not mounted confirmation: execution must observe current rendered CSS/JS and browser input states before cosmetic changes. [VERIFIED: `accrue_admin/lib/accrue_admin/live/event_live.ex:162-184,302-367`; `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex:154-196,366-379`; `accrue_admin/lib/accrue_admin/live/connect_account_live.ex:168,175-209,632-638`; `accrue_admin/lib/accrue_admin/components/global_search.ex:157-185,203-352`; `accrue_admin/assets/js/hooks/command_palette.js:34-53,113-181`.]

**Primary recommendation:** Use the Phase 241 `ScopedPath.return_destination/5` and existing list/detail/review components. Add only destination-supported filters and relationships, preserve present auth/step-up/duplicate/money owners, and repair the existing `CommandPalette` state model so hover, arrows, rendered highlight/semantics, and Enter all refer to one current result.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Filter/query membership and owner scope | API / Backend | — | Query modules perform filtering, relationship predicates, and fresh owner-scoped retrieval. |
| Validated list return and matching family label | Frontend Server (SSR) | API / Backend | LiveViews own detail navigation; `ScopedPath` validates/rebuilds route and label with current owner. |
| Replay review, step-up, dispatch, audit and outcomes | API / Backend | Frontend Server (SSR) | LiveView stages interaction, while existing DLQ/auth/query owners authorize and dispatch. |
| Catalog/Connect facts and local fee override | API / Backend | Frontend Server (SSR) | Persisted records and policy logic own truth; LiveView renders/reviews it. |
| Global search active result and focus | Browser / Client | Frontend Server (SSR) | The `CommandPalette` JS hook synchronizes pointer/keyboard selection; LiveComponent owns async query/group state. |
| Shared Admin words, filters, shell navigation | Frontend Server (SSR) | Browser / Client | Existing Copy modules, route shell, and HEEx components own consistent labels and destinations. |

## Current Filter and Return Contract Inventory

All paths below are tracked production files (`git ls-files` confirmed the scoped helper, all five query modules, route LiveViews, global search, and command palette hook). Each quoted value is read from its source-of-truth file this session. The planner should add these supported keys to the route's return policy only after checking the current list lens and preserving each key's real semantics.

| List family | Exact current decoder / allowlist evidence | Encoder behavior and query semantics | Return-planning consequence |
|---|---|---|---|
| Events | `decode_filter/1` builds `q`, `type`, `actor_type`, `subject_type`, `source_webhook_event_id`; quote: `q: Behaviour.normalize_string(...)`, `type: ...`, `actor_type: ...`, `subject_type: ...`, `source_webhook_event_id: ...` [VERIFIED: `accrue_admin/lib/accrue_admin/queries/events.ex:147-172`]. | `encode_filter/1` stringifies keys and calls `Behaviour.compact_filter/1`. `q` searches `event.type`, `event.subject_id`, `event.actor_id`; exact source relationship filters `event.caused_by_webhook_event_id`. [VERIFIED: `events.ex:168-201`; source query quotes `ilike(event.type, ^pattern) or ilike(event.subject_id, ^pattern) or ilike(event.actor_id, ^pattern)` and `event.caused_by_webhook_event_id == ^webhook_event_id`.] | Keep only consumed filters. `source_webhook_event_id` is the encoded key for a webhook source; event detail relationship links need exact source identity. `subject_type` alone may not identify a concrete subject; verify whether paired `subject_id` is currently accepted before preserving anything. |
| Webhooks/deliveries | Decoder creates only `type`, `status`, `livemode`; quote: `type: Behaviour.normalize_string(...)`, `status: decode_status(...)`, `livemode: Behaviour.parse_boolean(...)` [VERIFIED: `accrue_admin/lib/accrue_admin/queries/webhooks.ex:53-61`]. | Encoder writes list statuses as comma-joined atom strings, one status as its atom string, boolean live mode as string, then compacts. [VERIFIED: `webhooks.ex:63-80`; exact branches include `{:status, values} when is_list(values)`, `{:status, value} when is_atom(value)`, `{:livemode, value} when is_boolean(value)`.] | Return keys are not named by visible source-event type. Preserve delivery filters exactly as decoder accepts them; list default lens/status handling must be inspected in `webhooks_live.ex`, and not conflated with Events filters. Current row render has a known `row_label={{"event", "events"}}` even though this list selects deliveries. |
| Coupons / discount definitions | Decoder builds `q`, `valid`; quote: `q: Behaviour.normalize_string(...)`, `valid: Behaviour.parse_boolean(...)` [VERIFIED: `accrue_admin/lib/accrue_admin/queries/coupons.ex:59-69`]. | Encoder calls `Behaviour.compact_filter(filter)`. `q` searches `coupon.name` and `coupon.processor_id`; `valid` filters `coupon.valid`. [VERIFIED: `coupons.ex:71-89`.] | Return only search and validity constraints the detail-origin list consumes. Keep raw `Coupon`/provider identifiers in diagnostics while operator labels use existing Copy. |
| Promotion codes | Decoder builds `q`, `active`, `coupon_id`; quote: `q: Behaviour.normalize_string(...)`, `active: Behaviour.parse_boolean(...)`, `coupon_id: Behaviour.normalize_string(...)` [VERIFIED: `accrue_admin/lib/accrue_admin/queries/promotion_codes.ex:59-71`]. | Encoder calls `compact_filter`; `q` searches code, processor id and joined coupon name; `active` filters the code; `coupon_id` filters its parent. [VERIFIED: `promotion_codes.ex:73-95`.] | Parent `coupon_id` is a first-class bounded return constraint and must remain the exact parent ID. Unknown parent remains missing/unavailable rather than an unrelated link. |
| Connect accounts | Decoder builds `q`, `type`, `charges_enabled`, `payouts_enabled`, `details_submitted`, `deauthorized`, `needs_attention`; quote exact keys at `connect_accounts.ex:61-89`. | Encoder calls `compact_filter`; query scopes organization accounts by account owner and exact organization ID, searches Stripe account ID/email/owner ID, filters stored observation booleans and deauthorization state, and computes attention from explicit false/missing stored evidence. [VERIFIED: `connect_accounts.ex:91-159`; quote scope predicate: `account.owner_type == "Organization" and account.owner_id == ^organization_id`; quote attention values: `"details_submitted"`, `"charges_enabled"`, `"payouts_enabled"`.] | Return only these supported list meanings. Do not relabel stored observations as current live readiness; `needs_attention` includes missing snapshot fields and is a filter classification, not a live Stripe check. |

The exact current global return route inventory is quoted in the Summary above. In particular, route support is currently explicit for subscription/customer/invoice/payment/Recovery; the target families are not yet members of that quoted map. Preserve currently supported limits and validators; `ScopedPath` rejects scheme/host/userinfo/fragments, backslashes, malformed percent escapes, duplicate query keys, unsupported route paths, and invalid contextual customer IDs before rebuilding the path. It applies the current owner through its builder rather than trusting an owner in an incoming return. [VERIFIED: `scoped_path.ex:140-213`; exact guard quote: `is_nil(uri.scheme) and is_nil(uri.host) and is_nil(uri.userinfo) and is_nil(uri.fragment)`, duplicate check `length(keys) != MapSet.size(MapSet.new(keys))`, tab values `~w(subscriptions invoices payments)`, recovery windows `["7d", "30d", "90d"]`.]

**Smallest incumbent analog:** Phase 241's billing detail/list return at `ScopedPath` plus paired label is the correct implementation pattern. Avoid building a second URL parser. The routes to inspect/modify are each detail LiveView's current `return_destination` / detail navigation construction and its matching list route's filter decoder, encoder, and family fallback label. For hierarchy/copy, follow `event_live.ex` or `promotion_code_live.ex` as detail analogs, and `webhooks_live.ex` as the delivery/replay list analog.

## Standard Stack

### Core

| Library / owner | Version | Purpose | Why Standard |
|---|---|---|---|
| Phoenix LiveView (`accrue_admin`) | Existing locked package dependency; no change | Admin LiveViews, stateful components, staged reviews | All named surfaces already use this stack and package CI owns ExUnit/browser verification. |
| `AccrueAdmin.ScopedPath` | In-repo | Validate local list origin and build current-scope path/label pair | Existing Phase 241 return owner; preserves route allowlist and malformed-percent boundary. |
| Existing `AccrueAdmin.Queries.*` | In-repo | Decode/encode filters, execute current bounded list behavior and owner predicates | Each query module is authoritative for consumed filter semantics. |
| `CommandPalette` hook | In-repo JavaScript | Pointer/keyboard active result, highlight, Enter activation | Existing grouped search uses this hook; a focused no-dependency repair fits the seam. |

### Supporting

| Owner | Purpose | When to use |
|---|---|---|
| `Copy`, `Copy.BillingEvent`, `Copy.PromotionCode`, `Copy.Connect`, `Copy.Locked` | Human-readable vocabulary and exact locked audit/replay wording | Correct cross-route labels and detail/review copy; leave `Copy.Locked` exact. |
| `Detail`, `RelatedResources`, `Timeline`, `JsonViewer`, `DetailDrawer`, `StepUpAuthModal`, `DataTable`, `FilterChipBar` | Existing fact/link/disclosure/review/list compositions | Compose current jobs without new component framework. |
| `mix accrue_admin.assets.build` | Rebuild package-owned committed assets | Required after hook/CSS changes before host-served asset checks. |

No external dependency is recommended or required; the Package Legitimacy Audit is therefore not applicable.

## Architecture Patterns

### Recommended project structure

```text
accrue_admin/lib/accrue_admin/
├── scoped_path.ex                 # finite route allowlist, owner-rebuilt path + label
├── queries/{events,webhooks,coupons,promotion_codes,connect_accounts}.ex
├── live/{events_live,event_live,webhooks_live,webhook_live}.ex
├── live/{coupons_live,coupon_live,promotion_codes_live,promotion_code_live}.ex
├── live/{connect_accounts_live,connect_account_live}.ex
├── components/global_search.ex    # bounded async groups and scoped links
└── copy*.ex                       # routine vocabulary and locked copy owner
accrue_admin/assets/js/hooks/command_palette.js
```

### Pattern 1: Paired, validated contextual return

**What:** Read the raw local origin only as a hint; validate it against the correct mount and finite destination allowlist; decode unique safe query pairs; retain only that target list's accepted keys; use the current owner; return both rebuilt path and matching label from one helper call.

**When to use:** Named list → detail → list jobs. Use the list-family safe fallback for direct/invalid detail entry. Keep structural breadcrumbs distinct from contextual-return links.

**Implementation guidance:** Mirror the existing Phase 241 call shape. Derive query allowlisting and value validation from that destination's decoder and list rendering. Do not rely on `URI.parse` alone, URL byte equality, `history.back()` as return authorization, or incoming `org`/owner values. Test path-label agreement and query membership at helper and actual list consumers.

### Pattern 2: Preserve truthful resource relationships

**What:** Build reciprocal links from actual record relationships already loaded in query/detail state. Event source delivery or subject links use the real stored source/subject IDs; coupon detail links to its promotion-code list using the real parent ID; promotion code links to its actual coupon. A missing/out-of-scope lookup renders unavailable/not-found according to the current owner contract.

**When to use:** Existing event→delivery/subject and coupon→code→coupon worklists. Keep access checks in query/detail owners; do not synthesize a link from a type string or stale ID without proving the referenced record.

### Pattern 3: Replay review freshness and result semantics

**What:** Existing single and bulk reviews stage the exact webhook ID or canonical selected IDs, resolve current scoped records again, check live eligibility, then delegate step-up/auth/duplicate/dispatch to current owners. Results describe observed queue acceptance, skip/ineligibility, failure, denial or uncertainty distinctly. For bulk, selection and fresh eligible state must still match reviewed material state; no silent substitute set.

**Existing evidence:** `webhooks_live.ex:94-143` canonicalizes selection and stages count/IDs; `:157-241` rereads selected IDs in owner scope and maps records to queued/skipped/failed results; `:250-260` delegates actual requeue through DLQ and owner-scope authorization. Detail single replay stages `webhook_id`, requires fresh step-up, rechecks selected row state and refreshes detail after dispatch. Preserve stale selection, read failure after acceptance, and unknown reread outcome as distinct cases; don't create a blind-retry outcome.

**Current gap to plan explicitly:** the inspected bulk fold currently has only `queued`, `skipped`, and `failed` counters, and maps generic queue errors, unexpected return values, exceptions, and a pre-dispatch read error into `:failed` (`webhooks_live.ex:188-197,210-240`). The confirmation copy reports those three counts (`copy.ex:1310-1319`). Requirement D-05 distinguishes denied and unknown according to evidence; planning must inspect the DLQ error/result contract and decide which actual outcomes can be represented without fabricating distinctions. If enqueue was accepted but the follow-up read failed, preserve accepted/unknown state and never encourage blind replay. This is a source-backed gap, not an assumption that every result variant exists. [VERIFIED: `accrue_admin/lib/accrue_admin/live/webhooks_live.ex:188-240`; exact outcome atoms: `:queued`, `:skipped`, `:failed`; `accrue_admin/lib/accrue_admin/copy.ex:1310-1319`; exact display counts are `queued`, `skipped`, `failed`.]

### Pattern 4: One search result state across pointer and keyboard

**What:** The hook owns one active element/index and updates it whenever results are rebuilt, owner scope changes, pointer hover/movement chooses an item, or Arrow keys move selection. The visible highlight, focus/accessible current-item semantics, and Enter target all derive from that same item. Keep real anchor destinations and current focus trap. Maintain async generation/scope matching in LiveComponent.

**Current source observation:** `updated()` resets `activeIndex = 0`, `setupItems()` queries `.ax-command-palette-item[data-path], .ax-command-palette-item[data-action]`, arrow movement increments/decrements and wraps, `updateActiveItem()` toggles only `.ax-active`, and Enter dispatches/patches the indexed item. No hover listener appears in the hook. Plan a minimal DOM hook adjustment and `test/js/command_palette_test.mjs` controls; confirm mounted semantics and LiveView replacement before selecting the exact event/ARIA pattern.

### Anti-patterns to avoid

- Treating a billing event, delivery, processing attempt, replay enqueue acknowledgement, and later event as one object/state.
- Trusting raw return URLs, caller-supplied owner identifiers, or an origin family label that doesn't match the rebuilt path.
- Treating missing catalog parent/limit or missing Connect observation as “unlimited,” “ready,” or “healthy.”
- Replaying a changed selection or inferring processing completion from a queued result; reusing transport-only request counts for broad no-mutation claims.
- Adding search resource families, general command/action framework, navigation session stack, or blanket CSS/visual changes before current mounted evidence.
- Adding `aria-selected` to arbitrary links without choosing a suitable widget model; the current contract keeps actual links.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Scoped local return parsing | Another redirect validator, nested stack, routing dependency | `ScopedPath` finite path/query validation and owner rebuild | Existing code already handles mount boundaries, duplicate keys, malformed percent values, query limits, and paired family labels. |
| Auth, step-up, replay duplicate protection | UI-only checks or new action framework | Existing `StepUp`, query scope proof, DLQ requeue and audit owners | Correctness and authorization must be freshly enforced where mutation happens. |
| Connect fee math | Presentation-layer fee implementation | Existing `Connect.platform_fee` / preview and policy functions | Exact local money/percentage semantics are already domain owned. |
| Search results | New resource index, client cache/ranker | Current Customers/Invoices/Subscriptions queries and async result generation | Preserves bounded groups, current owner, and existing partial-failure/retry state. |
| Locked legal/replay wording | Rewritten copy | `AccrueAdmin.Copy.Locked` | This owner is explicitly verbatim and is an accepted audit/replay contract. |

## Common Pitfalls

### Destination/encoder parity drift

**What goes wrong:** A detail return appears filtered but drops a supported list filter, preserves an ignored key that has no effect, or label describes a different family than path.

**How to avoid:** Build a test matrix from each exact decoder plus its query filter clauses and list lens defaults; assert actual returned row membership, output path, owner, label, and normalized query values. The existing query return encoders are not uniform: webhook encoding special-cases list status and boolean live mode, while several others delegate to `compact_filter`.

### Inaccessible relation appears to exist

**What goes wrong:** A guessed subject/coupon/delivery URL implies accessible linked evidence when the target is missing or outside owner scope.

**How to avoid:** Prove related record under current scope before rendering a usable link; cover missing and foreign-scope cases in existing query/LiveView tests.

### Replay review becomes stale

**What goes wrong:** A selection or a row's status/owner changes between review and confirm; accepted queueing is shown as completed delivery; post-acceptance reread failure invites a duplicate replay.

**How to avoid:** Re-resolve exact selected rows and current eligibility at confirm, preserve StepUp/DLQ duplicate protections, report per-record observed results, and test authoritative job/dispatch/audit counters plus state changes. Do not claim no mutation solely from an HTTP method observer.

### Provider snapshot shown as live truth

**What goes wrong:** A stored Stripe capability or readiness value is made to look live/current despite no observation timestamp.

**How to avoid:** Preserve the visible “last stored Stripe snapshot” qualification and explicit no-report-time disclosure; keep local fee override in its own section and review.

### Pointer highlight disagrees with Enter

**What goes wrong:** Arrow selection controls `activeIndex`, but pointer movement changes visual hover without changing Enter's target, or LiveView patch resets selection unexpectedly.

**How to avoid:** Make pointer and keyboard mutations update the same active reference, rebuild safely after query/scope changes, and assert active styling, semantics, and actual destination together. Keep one current result even if no result is active.

### Cosmetic change precedes mounted evidence

**What goes wrong:** Source code appears compressed or stale while actual serving CSS/JS may come from a different build or host package mount.

**How to avoid:** Record source, fixture, built, compiled, served asset identity separately and inspect mounted desktop/narrow/effective-theme behavior before touching cosmetic candidates. Rebuild package assets explicitly and use the bounded one-inspection/correction/confirmation batch.

## Code Examples

### Filter key source inventory (verbatim excerpts)

These excerpts are implementation values, not suggestions; list return extensions should be tested against these current definitions.

```elixir
# Events, accrue_admin/lib/accrue_admin/queries/events.ex:149-163
q: Behaviour.normalize_string(...),
type: Behaviour.normalize_string(...),
actor_type: Behaviour.normalize_string(...),
subject_type: Behaviour.normalize_string(...),
source_webhook_event_id: Behaviour.normalize_string(...)

# Webhooks, queries/webhooks.ex:55-59
type: Behaviour.normalize_string(...),
status: decode_status(...),
livemode: Behaviour.parse_boolean(...)

# Coupons, queries/coupons.ex:62-64
q: Behaviour.normalize_string(...),
valid: Behaviour.parse_boolean(...)

# Promotion codes, queries/promotion_codes.ex:62-65
q: Behaviour.normalize_string(...),
active: Behaviour.parse_boolean(...),
coupon_id: Behaviour.normalize_string(...)

# Connect accounts, queries/connect_accounts.ex:64-83
q: Behaviour.normalize_string(...),
type: Behaviour.normalize_string(...),
charges_enabled: Behaviour.parse_boolean(...),
payouts_enabled: Behaviour.parse_boolean(...),
details_submitted: Behaviour.parse_boolean(...),
deauthorized: Behaviour.parse_boolean(...),
needs_attention: Behaviour.parse_boolean(...)
```

`...` only abbreviates the source's repeated lookup expression, not a filter name or value. The full literal key values above are quoted exactly from the opened source lines and are all the discrete names used in this code block.

### Return helper contract to preserve

```elixir
# Source: accrue_admin/lib/accrue_admin/scoped_path.ex:83-108
def return_destination(mount_path, raw_return_path, owner_scope, expected_customer_id, fallback_suffix)
    when is_binary(mount_path) and is_binary(fallback_suffix) do
  case validate_return_path(mount_path, raw_return_path) do
    {:ok, "/customers/" <> customer_id = suffix, params}
    when is_binary(expected_customer_id) and customer_id == expected_customer_id ->
      destination(mount_path, suffix, params, owner_scope)
    {:ok, "/customers/" <> _customer_id, _params} ->
      destination(mount_path, fallback_suffix, %{}, owner_scope)
    {:ok, suffix, params} -> destination(mount_path, suffix, params, owner_scope)
    :error -> destination(mount_path, fallback_suffix, %{}, owner_scope)
  end
end

defp destination(mount_path, suffix, params, owner_scope) do
  %{path: build(mount_path, suffix, owner_scope, params), label: return_label(suffix, params)}
end
```

This is the existing owner contract; new family labels and fallback suffixes should be additive clauses/entries, not a parallel implementation.

## Environment Availability

Read-only command discovery on 2026-10-10 found `node` v22.14.0, `npm` 11.1.0, `mix` 1.19.5 on Erlang/OTP 28, and the `chromium` executable on PATH. `npx` is present. No application was started and browser launch/Playwright fixture usability was not tested. [VERIFIED: command/version probes in this session; no dependency or runtime constraint was inferred from missing metadata.]

| Dependency | Required by | Available | Version | Fallback |
|---|---|---:|---|---|
| Elixir / Mix | Admin ExUnit, asset build, host integration | ✓ | Elixir 1.19.5 / Mix 1.19.5 | — |
| Erlang/OTP | Elixir runtime | ✓ | 28 | — |
| Node.js / npm / npx | Node hook tests, browser commands and package scripts | ✓ | Node 22.14.0 / npm 11.1.0 | — |
| Chromium executable | Admin/host Playwright browser proofs | ✓ | Version/launch not probed | Package browser's documented install command (`npm run e2e:install`) if needed during execution |

**Missing dependencies with no fallback:** None observed by command discovery.  
**Missing dependencies with fallback:** None observed. Host DB and actual browser-server startup remain execution-time checks, not research claims.

## Validation Architecture

Nyquist validation is enabled: `.planning/config.json` has `"nyquist_validation": true`. Per project policy, tests are to be planned but are not executed during this research. All paths below were checked against tracked files or existing package scripts; commands are rooted at the package because repository root has no monolithic Admin test runner.

### Test Framework / owner commands

| Owner and changed behavior | Smallest incumbent analog | Focused command to assign to implementation | Failure / negative control |
|---|---|---|---|
| Return validation and path-label parity | `test/accrue_admin/scoped_path_test.exs` | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs` | Reject foreign/scheme-relative/other-mount paths, malformed percent and duplicate keys; reject caller owner; path and label must be paired. |
| Event query decoder/membership/source link | `test/accrue_admin/queries/events_test.exs`; `test/accrue_admin/live/events_live_test.exs` | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/queries/events_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs` | Unsupported key does not constrain query; verify fixture row membership and inaccessible subject/source is not linked. |
| Webhook list filters, selected-set review, result truth | `test/accrue_admin/live/webhooks_live_test.exs`, `test/accrue_admin/live/webhook_replay_test.exs`, `test/accrue_admin/live/webhook_live_test.exs` | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/webhook_live_test.exs` | Dismissal no dispatch; stale owner/status/selection, unreadable row, duplicate/not-found and enqueue/reread failure produce distinct outcomes. Assert authoritative jobs/counters/audit, not only no HTTP writes. |
| Coupons and promotion-code list/detail/parent returns | `test/accrue_admin/live/coupons_live_test.exs`, `coupon_live_test.exs`, `promotion_codes_live_test.exs`, `promotion_code_live_test.exs` | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs` | Missing or foreign parent never resolves to plausible unrelated coupon; validity/active and parent filter membership match actual rows. |
| Connect owner filters and fee-review truth | `test/accrue_admin/live/connect_accounts_live_test.exs`, `connect_account_live_test.exs`, `test/accrue_admin/copy/connect_test.exs` | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/connect_account_live_test.exs test/accrue_admin/copy/connect_test.exs` | Validate target/policy/actor freshness, step-up, exact fee preview/save outcome, stale owner, no false provider refresh/freshness claim, cancel/dismiss no write. |
| Async groups, scope changes, one active pointer/keyboard result | `test/accrue_admin/components/global_search_test.exs`, `test/js/command_palette_test.mjs` | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/components/global_search_test.exs && node --test test/js/command_palette_test.mjs` | Delayed prior query/owner cannot win; retain successful groups on partial failure; pointer → Arrow → Enter and result replacement target the visibly active real link. |
| Copy and relation terminology | `test/accrue_admin/copy/*_test.exs` (use existing module-specific tests) | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/copy` | Routine words reconcile deliveries/payment/discount; `Copy.Locked` exact output unchanged. |

### Full package/CI and mounted consumer proof

The Phase 241 CI contract confirms owner commands: `cd accrue_admin && MIX_ENV=test mix test` (646 passed at final Phase 241), `cd accrue_admin && node --test test/js/*.mjs` (41 passed), `cd examples/accrue_host && MIX_ENV=test mix test` (223 passed), and prior route/browser owners. These are prior results, not current Phase 242 executions. Existing merge-blocking CI includes `cd accrue_admin && mix test --warnings-as-errors` and `cd accrue_admin && mix accrue_admin.assets.build`; see `.github/workflows/ci.yml` Admin steps. Do not add a second suite lane or change CI design.

For changed browser behavior, preserve the owning consumer suites and add narrow assertions to existing tracked specs: `accrue_admin/e2e/admin-page-flow-phase191.spec.js`, `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js`, and `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` / `phase234-search-completion.spec.js`. Existing package scripts include `npm run e2e:phase191`, `npm run e2e:phase199`; host uses `npx playwright test e2e/phase238-admin-events-webhooks.spec.js` or `npx playwright test e2e/phase234-search-completion.spec.js` from `examples/accrue_host`. Confirm fixture routing carefully: host `/admin` is Admin, `/billing` is Portal; package fixture `/billing` is Admin. Only run host-backed suites when the host fixture is intentionally started/configured during execution.

When changing JS/CSS, rebuild with `cd accrue_admin && mix accrue_admin.assets.build`; then compile/start the designated host proof and compare source/package-built/host-compiled/served CSS, JS and font identity. A watcher, an archived capture, or passing ExUnit alone does not prove the mounted consumer. Browser acceptance should include desktop and narrow viewport, effective Light/Dark/System as applicable, coarse-pointer geometry, keyboard focus, disclosure, error/empty/partial states, and the agreed measured text stress. Text stress must be applied and measured atomically around LiveView patching. Actual browser zoom, physical devices, screen-reader speech, and provider/remote CI are separate evidence claims and must not be inferred from headless CSS zoom.

### Phase requirement → test map

| Requirement | Behavior | Test type | Automated command | File exists? |
|---|---|---|---|---|
| JRN-05 | Filter membership and exact event/delivery evidence path, safe related links/returns | Query + LiveView + browser | Focused ExUnit command above; `npx playwright test e2e/phase238-admin-events-webhooks.spec.js` in host package | ✅ tracked owners exist |
| JRN-05 | Single/bulk review freshness and queued/skipped/failed/unknown distinctions | LiveView integration + mounted browser | focused `webhook_replay_test.exs` / `webhooks_live_test.exs` + host Phase 238 | ✅ tracked owners exist |
| JRN-06 | Coupon/promotion relationship identity and actual returned filtered rows | LiveView/query assertions | focused catalog ExUnit command above | ✅ tracked owners exist |
| JRN-06 | Connect snapshot vs local override review and validation outcome | LiveView + Copy + mounted browser | focused Connect ExUnit command above, plus changed route browser owner | ✅ tracked owners exist |
| JRN-07 | Query/scope completion and pointer/Arrow/Enter same active destination | LiveComponent + Node hook + browser | global search ExUnit + `node --test test/js/command_palette_test.mjs`; host search completion | ✅ tracked owners exist |
| UXC-01 | Copy coherence across affected list/details/reviews; locked text unchanged | Copy unit + route render assertions | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/copy` plus focused touched LiveViews | ✅ existing Copy directory/tests; exact changed modules to determine during planning |

### Expected failure evidence and authoritative no-mutation observations

Expected negative controls include return origin from another mount or external host; malformed `%` escape and duplicate parameter; foreign owner/record; unknown filter key; no matching subject/parent; selection altered after review; changed delivery eligibility/owner; dispatch duplicate; read failure before dispatch; reread failure after accepted enqueue; invalid fee input; stale Connect target/policy/actor; challenge cancellation; out-of-date search generation or scope; pointer-selected link differs from Arrow/Enter. Assert the actual selected row set, current owner query, queue/job callback/dispatch/audit record, persisted local fee policy and rendered destination. A page non-GET count can support only the exact HTTP method claim; it cannot establish zero LiveView mutation.

### Visual inspection boundary and budget

Use incumbent Operate/Cobalt/Geist and package `--ax-*` roles. Per D20–21, source-only candidate findings need current mounted confirmation; collect source, test fixture, package build, host compile and served asset hashes separately from actual exercised behavior. After one complete change/check/build pass, batch desktop + narrow + effective themes, apply one corrective batch, and take at most one confirming inspection. Do not create new screenshot-matrix/golden acceptance here; Phase 243 owns selected reviewed Linux goldens and preview handoff. Report viewport/theme/text-stress and browser zoom evidence exactly as measured.

## Security Domain

Security enforcement is on by default in `.planning/config.json`. Existing owner and mutation boundaries remain authoritative; Phase 242 must extend them through every new return/link/review rather than moving checks into presentation.

### Applicable ASVS Categories

| ASVS category | Applies | Existing control / Phase 242 use |
|---|---:|---|
| V2 Authentication | Yes for replay and Connect fee writes | Existing admin auth and fresh StepUp challenge at mutation boundary; keep actor identity in audit. |
| V3 Session Management | Yes | Reuse current Phoenix/LiveView session and focus-trap lifecycle; do not introduce an alternate session/navigation state service. |
| V4 Access Control | Yes | Current owner resolution and query/detail scope proof; reject foreign owner/record returns and inaccessible relationships. Recheck inside replay/fee mutation path. |
| V5 Input Validation | Yes | `ScopedPath` route/query allowlists and value limits; current query decoders; existing fee validation. Never accept URL owner data as authority. |
| V6 Cryptography | No new crypto operation | No cryptographic implementation or key handling change in this phase; do not hand-roll any. |

### Known threat patterns

| Pattern | STRIDE | Standard mitigation |
|---|---|---|
| Open redirect / cross-mount or organization return | Spoofing / Elevation | Finite local route + key allowlist; rebuild from current mount and current owner; malformed/duplicate values fail closed. |
| IDOR through guessed subject, coupon, delivery or Connect IDs | Information disclosure / Elevation | Query/detail authorization under current owner; inaccessible behaves truthfully and emits no usable unrelated link. |
| Replay stale selection, changed status, duplicate request | Tampering / Repudiation | Exact selected set, fresh owner/eligibility/authorization, existing DLQ duplicate guard, audit; authoritative dispatch assertions. |
| Search stale async response reveals prior-owner result | Information disclosure | Keep generation/query/owner equality check in `GlobalSearch.update/2`; clear results on owner-scope change; assert stale update ignored. |
| Diagnostic payload logs sensitive data | Information disclosure | Render only existing authorized lazy payload view; don't add logs or copy provider payload into routine labels. |

OWASP's return destination guidance supports constraining and authorizing redirect targets; the project-specific helper remains the implementation. W3C disclosure guidance supports keyboard-operable show/hide controls with accurate expanded state, and W3C link-purpose guidance supports explicit destination language. [CITED: https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html] [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/link-purpose-in-context.html]

## Project Constraints (from AGENTS.md)

No repository-root `AGENTS.md` was present when checked. Applicable project-specific directions come from the required Phase Context and `.planning/REQUIREMENTS.md`: preserve route families, owner/auth/provider boundaries, immutable locked copy, existing filter meanings, existing proof owners, package asset rebuild, zero required human UAT where repeatable evidence can decide, no new dependencies or CI redesign, and Phase 243 ownership of final Linux goldens/preview. These are captured verbatim in `<user_constraints>` above.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The selected CommandPalette result should be represented using existing links plus a single active-state semantic appropriate to the mounted widget; exact attributes/event handling need mounted review. | Architecture Patterns / Validation Architecture | Incorrect semantics can create keyboard/screen-reader disagreement; settle through existing widget structure and actual accessibility assertions. |
| A2 | Intended bounded returns should include a subset of every decoder's currently supported keys, likely all relevant search/filter/relationship constraints. | Current Filter and Return Contract Inventory | A key may be expensive or misleading as return context; planning must assess each key against destination list/lens behavior and validate through row-membership tests. |
| A3 | Current production package test setup and Playwright fixture configuration remain available to Phase 242 execution. | Validation Architecture | A missing runtime/test dependency would require adjusting the command, not changing the approved product scope. |

## Open Questions

1. Which decoded event keys have paired `subject_id` support in the actual events list, and which ones are currently ignored by list rendering? Confirm in `EventsLive` before choosing the event return allowlist; do not preserve ignored parameters.
2. What exact bulk review UI currently communicates selected IDs/eligibility and stale selection? Source list staging is present, but execution must confirm mounted content; extend the existing contract to exact selected set and material-state freshness without a new wizard.
3. Which search widget semantics are exposed by current mounted DOM and Playwright accessibility tree? Use the smallest role-consistent state mapping; don't assume links should receive `aria-selected`.

## Sources

### Primary: opened source of truth

- `accrue_admin/lib/accrue_admin/scoped_path.ex` — complete route map, limits, paired path/label return, validation boundary.
- `accrue_admin/lib/accrue_admin/queries/events.ex`, `webhooks.ex`, `coupons.ex`, `promotion_codes.ex`, `connect_accounts.ex` — exact decoder, encoder and query semantics.
- `accrue_admin/lib/accrue_admin/live/events_live.ex`, `event_live.ex`, `webhooks_live.ex`, `webhook_live.ex`, `coupons_live.ex`, `coupon_live.ex`, `promotion_codes_live.ex`, `promotion_code_live.ex`, `connect_accounts_live.ex`, `connect_account_live.ex` — owning route/relation/replay/review implementations.
- `accrue_admin/lib/accrue_admin/components/global_search.ex`, `accrue_admin/assets/js/hooks/command_palette.js` — bounded groups, generation/scope handling, active selection and activation.
- Tracked tests: `accrue_admin/test/accrue_admin/scoped_path_test.exs`, route/query/Copy tests named in Validation Architecture, and `accrue_admin/test/js/command_palette_test.mjs`.
- `accrue_admin/package.json`, `examples/accrue_host/package.json`, `.github/workflows/ci.yml` — existing executable scripts and merge-blocking package lanes.
- `.planning/phases/241-billing-operator-journeys/241-HANDOFF.md`, `241-CI-CONTRACT.md`, `241-EXECUTION-GATES.md`; `.planning/research/v1.64/SUMMARY.md`, `OPERATOR-EXPERIENCE.md`, `AUTOMATION-AND-SEAMS.md` — completed decisions, current lane and evidence boundaries.

### Primary guidance

- [W3C ARIA Authoring Practices: Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/) — keyboard show/hide pattern and expanded state.
- [W3C WCAG 2.2: Link Purpose in Context](https://www.w3.org/WAI/WCAG22/Understanding/link-purpose-in-context.html) — clear link destination/purpose.
- [OWASP Unvalidated Redirects and Forwards Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html) — constrain and validate navigation destinations.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all implementation stack is already present and source/package ownership was checked; no packages added.
- Architecture: HIGH — exact query and navigation source files were opened; current return allowlist and active selection hook are directly inspected.
- Pitfalls: HIGH for safety/dataflow issues and existing code seams; MEDIUM for visible mounted behavior, because this research intentionally did not start the app, mutate fixtures, or execute tests/browser checks.

**Research date:** 2026-10-10  
**Valid until:** 2026-11-09 for stable project architecture; repeat dependency/runtime checks only if the package or CI contract changes.
