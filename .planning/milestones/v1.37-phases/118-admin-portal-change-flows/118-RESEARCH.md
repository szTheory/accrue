# Phase 118: Admin + Portal Change Flows - Research

**Researched:** 2026-05-07  
**Domain:** Active-subscription-change contract promotion and touched admin/portal flow design across `accrue`, `accrue_admin`, `accrue_portal`, and the example host  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01..D-05:** Promote only the active-subscription-change APIs current
  runtime truth can defend; Stripe/Fake get quantity/item semantics, Braintree
  stays bounded to swap-only with explicit unsupported errors elsewhere.
- **D-06..D-09:** Preview-before-commit remains the default posture where
  supported and must not imply Braintree preview parity.
- **D-10..D-14:** Admin is the primary operator surface for quantity/item
  mutations and must show provider/setup gates clearly.
- **D-15..D-19:** Portal work stays bounded to provider-honest self-serve
  plan-change flows and must avoid pause/resume or schedule implication creep.
- **D-20..D-22:** Host seams stay thin, explicit, and adjacent to the existing
  host billing facade.
- **D-23..D-26:** Fake remains the merge-blocking proof lane; touched admin,
  portal, and example-host surfaces need durable proof.

### Deferred Ideas (OUT OF SCOPE)
- pause/resume and schedule promotion
- broad customer self-serve item management
- coupons/promotion-code expansion
- fabricated Braintree preview or item parity

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `SCM-03` | Stripe and Fake adopters can manage quantity and subscription-item changes through the official billing facade, while unsupported Braintree quantity/item semantics fail clearly and never imply parity. | Runtime APIs already exist (`update_quantity/3`, `add_item/3`, `remove_item/2`, `update_item_quantity/3`), deterministic tests already exist, and Braintree already rejects quantity mutation semantics explicitly; the missing work is official support promotion plus touched UX and docs alignment. |
| `SCM-04` | Admin/operator surfaces expose the supported subscription-change actions, preview states, and setup gates that match the official provider contract. | The current admin subscription detail page already stages actions and exposes swap-plan forms, but it lacks preview and quantity/item flows; it already has the right provider-guidance seam to extend. |
| `SCM-05` | Customer self-serve portal surfaces expose supported plan-change and preview flows with wording that stays provider-honest and avoids unsupported lifecycle implications. | The current portal only exposes cancellation wording. The copy and LiveView seams are clean enough to add a bounded plan-change flow, but the flow must stay limited to supported plan changes and preview semantics. |

</phase_requirements>

## Summary

The runtime already contains almost the entire active-subscription-change
mechanism this phase needs. `Accrue.Billing` publicly exposes `swap_plan/3`,
`preview_upcoming_invoice/2`, `update_quantity/3`, `add_item/3`,
`remove_item/2`, and `update_item_quantity/3`. The gap is that only the
swap/preview pair is currently promoted as the official active-subscription-
change contract, while quantity/item APIs remain effectively "real but not yet
official" from the support-matrix and touched-UI perspective. [VERIFIED:
`accrue/lib/accrue/billing.ex`, `.planning/processor-support-matrix.md`,
`accrue/README.md`]

The Braintree runtime boundary is already honest and useful. `swap_plan/3`
succeeds only when the host configures `:plan_resolver`, while
`update_quantity/3` and Braintree-side quantity mutation paths already fail with
typed unsupported semantics. That means Phase 118 does **not** need to invent a
new unsupported story for Braintree; it needs to promote that story into the
official contract and reflect it in admin/portal flows. [VERIFIED:
`accrue/lib/accrue/billing/subscription_actions.ex`,
`accrue/test/accrue/billing/subscription_actions_test.exs`,
`accrue/test/accrue/processor/braintree_test.exs`]

The support contract is currently inconsistent with the milestone requirements.
The processor support matrix explicitly says advanced subscription mutation
parity such as quantity updates remains out of slice, even though the facade and
tests already exist. `SCM-03` makes that posture obsolete for Stripe/Fake. The
first plan should therefore promote quantity/item APIs into the official
active-subscription-change contract while preserving explicit unsupported
Braintree semantics. [VERIFIED: `.planning/processor-support-matrix.md`,
`.planning/REQUIREMENTS.md`, `accrue/test/accrue/billing/subscription_items_test.exs`]

The admin surface is halfway there already. It has a staged-action pattern,
provider-aware guidance, and a swap-plan form, but no preview flow and no
quantity/item mutation affordances. That makes admin the lowest-risk place to
introduce the richer change-flow UI needed by `SCM-04`, especially because the
current `prepare_action` / `confirm_action` contract can likely absorb a
preview-and-commit variant without restructuring the entire page. [VERIFIED:
`accrue_admin/lib/accrue_admin/live/subscription_live.ex`,
`accrue_admin/lib/accrue_admin/copy/subscription.ex`,
`accrue_admin/test/accrue_admin/live/subscription_live_test.exs`]

The portal surface is much further behind. `accrue_portal` currently teaches
only cancellation semantics and Braintree hard-stop guidance; there is no plan
change or preview flow at all. The good news is that the portal already has a
clean copy seam and a bounded subscription detail/list surface, so the phase can
add one focused self-serve plan-change flow without reopening broader lifecycle
or account-management scope. [VERIFIED:
`accrue_portal/lib/accrue_portal/live/subscription_live.ex`,
`accrue_portal/lib/accrue_portal/live/subscriptions_live.ex`,
`accrue_portal/lib/accrue_portal/copy.ex`]

**Primary recommendation:** split Phase 118 into three plans:

1. promote the official support truth and deterministic core proof for
   quantity/item mutations on Stripe/Fake, keeping Braintree explicit and
   bounded
2. deepen `accrue_admin` with preview-backed change flows and provider/setup
   gates
3. add a bounded mounted-portal self-serve plan-change flow plus thin host
   seams and proof

That sequencing settles the contract first, then layers operator UX, then
customer UX and host ergonomics on top of one stable truth.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Official active-subscription-change support truth | `accrue` runtime + planning mirror | package docs | The contract must start in runtime labels/public facade docs and the support matrix before admin/portal can teach it honestly. |
| Quantity/item mutation semantics | `accrue/lib/accrue/billing/*` | processor adapters | The facade already owns these semantics; adapters are truth providers, not the place to define public support scope. |
| Operator preview and mutation flow | `accrue_admin` | `accrue` facade | Admin already has the staging and provider-guidance pattern needed for these flows. |
| Customer self-serve plan-change flow | `accrue_portal` | host billing facade | Portal should consume thin host/facade seams and shared copy, not reimplement plan resolution or processor-specific semantics. |
| Host-specific plan catalog and policy | example host / generated host facade | `Accrue.Billing` | Host apps own authorization, plan presentation, and bounded Braintree policy above the processor contract. |

## Current-State Findings

### The active-subscription-change runtime is broader than the official support contract

- `Accrue.Billing` already exports:
  - `swap_plan/3`
  - `preview_upcoming_invoice/2`
  - `update_quantity/3`
  - `add_item/3`
  - `remove_item/2`
  - `update_item_quantity/3`
  [VERIFIED: `accrue/lib/accrue/billing.ex`]
- The processor support matrix officially promotes only `swap_plan/3` and
  `preview_upcoming_invoice/2`, while describing quantity updates and broader
  advanced mutation parity as out of slice. [VERIFIED:
  `.planning/processor-support-matrix.md`]
- `accrue/README.md` likewise teaches only the swap/preview pair as the official
  active-subscription-change contract. [VERIFIED: `accrue/README.md`]

### Stripe/Fake quantity and item semantics are already executable

- `SubscriptionItems` already supports `add_item/3`, `remove_item/2`, and
  `update_item_quantity/3` with deterministic tests.
  [VERIFIED: `accrue/lib/accrue/billing/subscription_items.ex`,
  `accrue/test/accrue/billing/subscription_items_test.exs`]
- `SubscriptionActions.update_quantity/3` already performs the single-item
  quantity mutation path on supported processors. [VERIFIED:
  `accrue/lib/accrue/billing/subscription_actions.ex`,
  `accrue/test/accrue/billing/subscription_cancel_test.exs`]
- Fake and preview proof already exists for active-change semantics:
  `upcoming_invoice_test.exs`, `proration_roundtrip_test.exs`, and
  `swap_plan_test.exs`. [VERIFIED:
  `accrue/test/accrue/billing/upcoming_invoice_test.exs`,
  `accrue/test/accrue/billing/proration_roundtrip_test.exs`,
  `accrue/test/accrue/billing/swap_plan_test.exs`]

### Braintree already exposes the exact bounded boundary the milestone wants

- `swap_plan/3` on Braintree works only when a host `:plan_resolver` is
  configured and rejects currency/billing-cycle mismatches explicitly.
  [VERIFIED: `accrue/lib/accrue/billing/subscription_actions.ex`,
  `accrue/test/accrue/billing/subscription_actions_test.exs`]
- `update_quantity/3` explicitly fails for Braintree with a typed unsupported
  error. [VERIFIED:
  `accrue/lib/accrue/billing/subscription_actions.ex`,
  `accrue/test/accrue/billing/subscription_actions_test.exs`]
- Braintree adapter tests also pin unsupported quantity mutation semantics at
  the processor layer. [VERIFIED:
  `accrue/test/accrue/processor/braintree_test.exs`]

### Admin has the right orchestration pattern but not the right mutation depth

- `AccrueAdmin.Live.SubscriptionLive` already supports:
  - staged `prepare_action` -> `confirm_action`
  - provider-aware guidance copy
  - swap-plan form
  - Braintree `:plan_resolver` setup guidance
  [VERIFIED: `accrue_admin/lib/accrue_admin/live/subscription_live.ex`,
  `accrue_admin/lib/accrue_admin/copy/subscription.ex`]
- It does **not** currently expose:
  - preview state before swap commit
  - quantity updates
  - item add/remove/update flows
  [VERIFIED: `accrue_admin/lib/accrue_admin/live/subscription_live.ex`]

### Portal has clean seams but no plan-change flow

- `accrue_portal` currently focuses on lifecycle display and cancellation only.
  [VERIFIED: `accrue_portal/lib/accrue_portal/live/subscription_live.ex`,
  `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex`]
- Copy is already centralized and provider-honest for cancellation, which is the
  right seam to extend into bounded plan-change preview/commit wording.
  [VERIFIED: `accrue_portal/lib/accrue_portal/copy.ex`]
- The portal list/detail tests already prove customer-scoped behavior and
  provider-specific cancellation wording, making them strong anchors for a
  bounded change-flow addition. [VERIFIED:
  `accrue_portal/test/accrue_portal/live/subscription_live_test.exs`,
  `accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs`]

### Host seams are thin but currently too shallow for customer-facing change flows

- `AccrueHost.Billing` exposes `swap_plan/3` but not a preview helper or a
  bounded self-serve plan-change seam. [VERIFIED:
  `examples/accrue_host/lib/accrue_host/billing.ex`,
  `accrue/priv/accrue/templates/install/billing.ex.eex`]
- The example-host billing LiveView currently models start-subscription and
  immediate-cancel behavior only. [VERIFIED:
  `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`]
- The host proof already checks thin facade exports and explicit cancellation
  wording, so extending it with one bounded plan-change helper is consistent
  with existing patterns. [VERIFIED:
  `examples/accrue_host/test/accrue_host/billing_facade_test.exs`,
  `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs`]

## Risks

### Risk 1: keeping quantity/item APIs unofficial would leave the milestone half-done

If Phase 118 only adds UI without promoting quantity/item support truth, the
repo will keep shipping real mutation APIs that the support matrix still treats
as out of slice. That would directly conflict with `SCM-03`.

### Risk 2: pushing item-management self-serve too far would reopen product scope

The portal requirement only needs supported plan-change and preview flows.
Trying to give end users broad subscription-item editing in the same phase could
turn this into a product-modeling exercise rather than a bounded contract pass.

### Risk 3: preview wording can easily imply Stripe parity where Braintree has none

Any preview-centric UI or docs must explicitly gate Braintree rather than
presenting preview as "temporarily unavailable" or "requires setup." The
runtime truth is unsupported, not incomplete.

## Recommended Plan Shape

### Plan 01: Contract promotion + core proof

Scope:
- promote quantity/item APIs into the official active-subscription-change story
- update support labels / support matrix / package-facing contract wording
- extend deterministic core proof
- preserve explicit unsupported Braintree semantics

Why first:
- admin and portal flows need one stable support contract
- this is the only plan that directly closes the `SCM-03` support-promotion gap

### Plan 02: Admin/operator change-flow depth

Scope:
- add preview-backed operator flows on subscription detail
- expose supported quantity/item actions
- preserve Braintree swap-only and setup-gated guidance
- add targeted admin proof

Why second:
- admin already has the scaffolding for rich change actions
- it is the lowest-risk touched UI for the broader mutation bundle

### Plan 03: Portal self-serve plan-change flow + host seams

Scope:
- add bounded mounted-portal plan-change preview/commit flow
- keep wording provider-honest and lifecycle-safe
- add thin host helper/template seams if needed
- extend portal and example-host proof

Why third:
- customer-facing flows should land only after the official contract and admin
  operator model are settled

## Verification Guidance

- `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_items_test.exs test/accrue/billing/upcoming_invoice_test.exs test/accrue/billing/proration_roundtrip_test.exs`
- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs`
- `cd accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/live/subscriptions_live_test.exs`
- `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs test/accrue_host_web/live/subscription_live_test.exs`

## RESEARCH COMPLETE
