# Phase 234: Admin Customers & Subscriptions - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents. Decisions are captured in CONTEXT.md; this log preserves the alternatives and reasoning.

**Date:** 2026-10-07
**Phase:** 234-admin-customers-subscriptions
**Areas discussed:** entry/search; record hierarchy; scope/navigation; lifecycle and money/date truth; action discovery, safety, and outcomes; responsive design; accessibility/motion/themes; architecture/DX; performance/operability; evidence and scope.

## User selection and delegated decisions

The initial discussion offered four areas: starting point, record layout, action presentation, and small-screen experience. The user selected all, requested additional relevant decisions through diminishing returns, explicitly requested subagent research, and directed the assistant to synthesize and follow coherent recommendations. The user emphasized operator jobs, idiomatic Elixir/Phoenix boundaries, developer ergonomics, current brand guidance, accessibility, and user-facing language.

No subsequent choice was individually attributed to the user. The selections below are the assistant's recommendations adopted under that delegation. This superseded the routine four-question-per-area discussion loop; there was no unresolved product vision fork requiring another user question.

## Research method and stopping rule

Three parallel specialist reviews covered:

1. Operator investigation and information architecture: support and engineering jobs, entry, queues, record structure, navigation, and lifecycle truth.
2. Action safety and Elixir/Phoenix architecture: actual capability/state checks, step-up, stale targets, operation identity, local evidence, host ownership, DX, and bounded performance.
3. Visual and interaction design: current brand/components, table/card behavior, typography, themes, focus, motion, responsive states, and accessibility.

Two focused domain follow-ups challenged the proposed IA and action contracts. A final visual/interaction review checked their combined behavior. The follow-ups refined the recommendations without opening a new product direction. Stop condition: no material contradiction remained, and additional work required current rendered or executable evidence rather than another broad research cycle.

Current source and committed product/phase decisions governed. The tracked prompt corpus supplied historical domain and architectural hypotheses. The current brandbook superseded older branding. Local-only guidance was consulted without copying it into committed artifacts. Repository hygiene/release and architecture-guide prompts were not executed as workflows. No application tests, browser run, new render, feature implementation, dependency change, or external publication occurred in this discussion.

## Entry, search, and queue

| Option | Advantages | Costs / footguns | Selection |
| --- | --- | --- | --- |
| Scoped Home plus visible search | Covers both a known-customer lookup and arriving to inspect work; reuses existing routes | Home needs truthful scoped observations; search needs good identity | Adopted |
| Search as the sole entry | Very direct for ticket-driven work | Hides existing queue/overview value | Rejected |
| Existing `past_due,canceling` default, explicitly named, with All adjacent | Preserves useful work view and existing behavior | Scheduled cancellations are not inherently problems; queue is not exhaustive | Adopted |
| Default all subscriptions | Complete population immediately visible | Dilutes the existing focused work entry | Not selected |
| Bounded grouped previews with equivalent existing-list handoff | Fast familiar lookup; no new search infrastructure | Query fields differ; a five-result preview must not imply completeness | Adopted |
| New search language/backend/resource types | Broader lookup | New capability and maintenance boundary | Deferred |

**Notes:** A failed search group must not silently become an empty result. Old query/scope replies must not appear current. Disambiguate names using available data rather than requiring a new owner-display query. “View all” is allowed only when the destination reproduces matching semantics. Correcting an existing advertised ID contract is a bounded probe; arbitrary new search behavior is not assumed.

**Analogue:** Stripe's documented Dashboard search uses grouped previews with expanded results. We borrow that interaction principle without copying its larger query language or resource surface. [Stripe Dashboard search](https://docs.stripe.com/dashboard/search).

## Record structure and return context

| Option | Advantages | Costs / footguns | Selection |
| --- | --- | --- | --- |
| Identity/facts first, existing customer peer tabs, subscription facts/history/disclosure | Serves routine work while retaining engineering detail; small route change | Hidden tabs can bury context if ordered badly | Adopted |
| New customer subroutes | Separate destinations for each dataset | Unnecessary routing expansion for existing peer sections | Deferred |
| Rigid universal detail-page template | Superficial visual uniformity | Repeated boxes, misplaced facts, and excess disclosure | Rejected |
| Safe URL-backed list/tab/owner context | Supports deep links, refresh, and return to the investigation | Must bound/validate returns and handle stale cursors | Adopted |
| Return to list with owner only | Simple | Loses required filter/object context | Rejected |

**Notes:** Stable customer context stays above tabs. A customer name and a subscription identifier must link to the object they name. A hierarchy breadcrumb and a return to originating results serve different purposes. Preserve harmless navigation state; never serialize action authority or payment data into it.

**Analogues:** GOV.UK documents tabs for related peer sections and summary lists for key/value facts; both reinforce choosing components by the information task. This is a design inference, not evidence of measured Accrue operator preference. [Tabs](https://design-system.service.gov.uk/components/tabs/), [summary lists](https://design-system.service.gov.uk/components/summary-list/).

## Lifecycle, amount, and date interpretation

| Option | Advantages | Costs / footguns | Selection |
| --- | --- | --- | --- |
| Exact lifecycle plus separate unknown observations | Known Active remains clear even with missing price/date metadata | Requires deliberate grouping and copy | Adopted |
| One computed health/inactive verdict | Compact | Collapses distinct facts into unsupported conclusions | Rejected |
| Exact currency/date facts and qualified plan price | Honest display across existing records | Some summaries must be omitted or split by currency | Adopted |
| Default absent values to zero, USD, or now | Uniform-looking output | Materially misleading billing meaning | Rejected |

**Notes:** Scheduled cancellation, paused collection, subscription status, host access policy, and historical failures remain distinct. The plan must reuse core semantics and prove their edge cases. Money/date corrections on these surfaces are necessary here; they do not pull the entire invoice/recovery phase forward.

## Actions, eligibility, and step-up

| Option | Advantages | Costs / footguns | Selection |
| --- | --- | --- | --- |
| Common eligible actions by their facts, secondary grouped menu | Discoverable routine work and controlled visual weight | All entry points must share rules | Adopted |
| Every action visible and disabled when unavailable | Discoverability of a theoretical action set | Wall of controls and implied unsupported features | Rejected; use brief contextual reasons when useful |
| Drawer → action-specific review → confirmation with existing step-up | Preserves a clear consequence and decision point | Stale review must be invalidated after material change | Adopted |
| Immediate menu mutations | Fewer clicks | Conceals consequence and defeats existing protection | Rejected |
| Fresh scoped local target and rule checks at dispatch/after challenge | Prevents stale assigns from becoming authority | Still not remote/database atomicity | Adopted |
| Trust previously rendered/socket state | Less local work | Can miss state, membership, eligibility, or item changes | Rejected |

**Notes:** Existing core predicates should inform a small Admin action mapping; there is no need to publish a new generic eligibility API. Compensation requires source/replacement clarity. Supported Braintree behavior and previews remain different from Stripe. Refresh/result navigation needs the same owner boundary as the original load. Hide unauthorized/unsupported mutation controls; explain relevant state restrictions without leaking foreign records.

**Lessons from other libraries:** Pay and Cashier make explicit lifecycle verbs and cancellation timing useful to adopters. Their documented processor/state distinctions warn against a misleading universal “cancel/resume” UI. These are contract-design lessons, not claims that either library has a proven usability failure. Preserve Accrue's own facade and capability matrix. [Pay subscriptions](https://github.com/pay-rails/pay/blob/main/docs/6_subscriptions.md), [Cashier billing](https://laravel.com/framework/docs/13.x/billing).

**Phoenix grounding:** LiveView's security guidance places authorization at mount/navigation/event boundaries; a hidden button does not protect its event. The recommendation uses existing host authorization and scoped reads. Current web guidance may be newer than the lockfile; planning must use installed APIs. [LiveView security](https://phoenix-live-view.hexdocs.pm/security-model.html).

## Duplicate messages, ambiguous outcome, and recovery

| Option | Advantages | Costs / footguns | Selection |
| --- | --- | --- | --- |
| One operation identity per staged logical submission, server pending-state control, existing adapter semantics | Preserves the intended retry/dedup boundary | Socket identity is not durable across arbitrary reconnects; provider capabilities vary | Adopted within demonstrated existing guarantees |
| Fresh operation key for an uncertain retry | Simple to submit again | May create another replacement/item after the original succeeded remotely | Rejected |
| Explicit unconfirmed outcome with local record/history reads | Honest and avoids blind resubmission | Cannot promise immediate resolution of provider truth | Adopted |
| Durable workflow/reconciliation platform | Could track outcomes across failures | New persistence, recovery, and public contract | Deferred absent a concrete required-flow failure |

**Notes:** Definitive input rejection can retain safe fields for correction. Once a provider may have acted, neither “not submitted” nor a generic failure claim is justified. A local audit event is useful evidence of its own event, not independent webhook or processor confirmation. Materially changed intent gets a new review; lost pending intent on reconnect is never replayed automatically.

**Primary-source limit:** Stripe documents idempotency against the same request identity and finite retention. It is not proof of durable exactly-once behavior across Accrue's providers. [Stripe idempotent requests](https://docs.stripe.com/api/idempotent_requests).

## Responsive presentation, brand, and accessibility

| Option | Advantages | Costs / footguns | Selection |
| --- | --- | --- | --- |
| Existing desktop table/narrow labeled-card pattern | Comparison on desktop; readable lookup on narrow screens | Variant markup can diverge or duplicate IDs/focus stops | Adopted with parity checks |
| Table with horizontal scrolling at every width | Stable columns | Harder narrow-screen lookup | Only for essential two-dimensional comparison |
| Cards at every width | Readable individual records | Loses desktop scan/comparison efficiency | Rejected |
| Existing Admin tokens, readable type, measured spacing | Keeps recognizable identity and package contracts | Requires deleting conflicting route overrides | Adopted |
| New framework/token catalog/density mode | Broad customization potential | Scope and maintenance growth without task evidence | Rejected |

**Notes:** Identity/state/action context stays discoverable when tabs/cards change layout. Coarse-pointer controls target 44px under the project direction, while AA's minimum target rule is 24px with exceptions. Reflow and focus criteria apply to actual changed routes, not just component samples. Only the active nested modal can be interactive; focus restoration must handle removed triggers. Reduced motion includes JavaScript timing. Do not elevate AAA Focus Appearance into a new gate.

**Primary guidance:** APG describes modal focus and dismissal, WCAG defines the reflow/target boundaries, and Carbon offers comparison-table patterns. These guide the existing implementation without introducing their component libraries. [Modal dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/), [Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html), [Target Size Minimum](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html), [Carbon tables](https://www.carbondesignsystem.com/building-blocks/core/components/data-table/guidelines).

## Architecture, performance, and evidence

**Selected:** Admin owns interactions and scoped reads; core Billing owns billing rules and mutations; the host retains policy, Repo, and runtime ownership. Extract private helpers only for demonstrated repetition/complexity. Keep bounded reads, cursor pagination, safe existing diagnostics, and no remote calls solely to decorate a render. Measure a relevant slow query before changing indexes/caches/transactions.

**Rejected/deferred:** a generic action platform, new public eligibility API, new role vocabulary, speculative performance infrastructure, broad dependency upgrades, and a new testing or visual-evaluation platform.

**Proof direction:** Small pure and contract checks cover semantic branches; mounted integration proves scope/action checks; representative browser cases prove navigation, keyboard/overlay lifecycle, reflow, themes, and served assets. Include positive controls and two-owner/nondefault-scope journeys. No recurring manual UAT for machine-verifiable behavior and no live-provider parity claim from Fake. Execution must capture current source and assets; this research does not establish current rendering.

## Source discrepancies and remaining probes

Source inspections identified reversed customer/subscription links, lost return filters, caveat-first lifecycle summaries, unscoped summary/refresh reads, provider-only action allowances, dispatch-created operation IDs, and dropped search-group failures. Current rendered effects and precise failure behavior remain for planning/execution to establish.

The final Portal evidence sentence in PRODUCT.md predates the completed Phase 233 contract. It is marked stale in CONTEXT.md, with a later owned documentation correction; no Portal scope was reopened. Historical blueprint proposals and old ecosystem/version/popularity claims were not treated as current facts.

No product decision remains open. The five bounded code/render probes in CONTEXT.md are implementation research, not a request for another interview.

## Deferred Ideas

New capabilities, broader search, new rooms/routes, generalized diagnoses/risk scores, density/persona modes, provider parity, universal tenancy, durable workflow infrastructure, and unrelated route-family work retain their existing out-of-scope or later-phase disposition. No new milestone or recurring research loop was created.
