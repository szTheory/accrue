# Phase 118: Patterns

## Reusable Repo Patterns

### Pattern 1: Contract promotion before touched UX

Use recent contract-closure phases as the primary planning analog:

- Phase 112: runtime contract -> support truth -> thin host proof
- Phase 113: support truth -> touched docs/UI -> proof

For Phase 118, the analogous sequence is:

1. promote quantity/item support truth
2. extend admin/operator flow
3. extend portal/host flow

### Pattern 2: Provider-honest guidance through shared copy seams

- `accrue_admin/lib/accrue_admin/copy/subscription.ex`
- `accrue_portal/lib/accrue_portal/copy.ex`

Both packages already centralize provider-aware wording. New change-flow copy
should land there first, then be rendered from LiveViews.

### Pattern 3: Staged operator actions in `SubscriptionLive`

`AccrueAdmin.Live.SubscriptionLive` already implements:

- `prepare_action`
- `confirm_action`
- provider/setup guidance
- deterministic follow-up refresh

Any new operator change flow should reuse this staged-action pattern rather than
introducing an unrelated admin mutation surface.

### Pattern 4: Thin host facade helpers

`examples/accrue_host/lib/accrue_host/billing.ex` and
`accrue/priv/accrue/templates/install/billing.ex.eex` are the canonical place
for host-owned wrappers that:

- resolve billable/customer ownership
- keep authorization and product policy local to the host
- delegate processor-normalized semantics back to `Accrue.Billing`

### Pattern 5: Fake-first merge-blocking proof

Core active-change proof should center on:

- `swap_plan_test.exs`
- `subscription_actions_test.exs`
- `subscription_items_test.exs`
- `upcoming_invoice_test.exs`
- `proration_roundtrip_test.exs`

Provider-backed Braintree/Stripe assertions should stay targeted and explicit,
not replace the Fake lane.

## Phase-Specific Guidance

- Do not introduce broad new runtime abstractions if the current facade already
  exposes the needed mutation.
- Do not hide Braintree unsupported branches behind generic "unavailable" copy.
- Prefer one bounded portal plan-change flow over a broad customer item editor.
- Prefer explicit setup guidance for `:plan_resolver` rather than optimistic
  commit attempts that fail late.
