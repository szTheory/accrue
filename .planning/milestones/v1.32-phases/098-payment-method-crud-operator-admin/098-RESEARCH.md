# Phase 98: Payment Method CRUD & Operator Admin - Research

**Researched:** 2026-04-30
**Domain:** Braintree payment-method CRUD, local projection convergence, and Phoenix LiveView operator administration
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `098-CONTEXT.md`. [VERIFIED: codebase grep]

### Locked Decisions

### Public facade contract

- **D-01:** Phase 98 should move the payment-method public surface toward **honest CRUD verbs** instead of leaning on Stripe-shaped `attach` semantics for Braintree.
- **D-02:** The preferred public shape is: `add_payment_method/3`, `update_payment_method/3`, `delete_payment_method/2`, `set_default_payment_method/3`, and `list_payment_methods/2`.
- **D-03:** `list_payment_methods/2` should become a **local-row-first** read model for app/admin ergonomics rather than a provider-live-only inventory call.
- **D-04:** Braintree add/update flows should accept **one narrow `vault_acquisition` handoff payload** rather than leaking raw provider vocabulary throughout the facade.
- **D-05:** Braintree “update payment method” should be documented and implemented as **replacement-oriented semantics**, not as a fake universal in-place card edit.
- **D-06:** Existing Stripe-shaped `attach` / `detach` seams may remain temporarily for compatibility, but Phase 98 planning should treat the new CRUD verbs as the long-term canonical contract.

### Projection and source-of-truth posture

- **D-07:** Accrue should stay **projection-first** for payment-method inventory: local `PaymentMethod` rows remain the primary read model for `AccrueAdmin` and host-facing reads.
- **D-08:** Braintree remains the **write authority**. After add, delete, set-default, or replacement flows, Accrue should immediately **refetch canonical provider state and re-project locally**.
- **D-09:** Phase 98 should include an explicit **reconcile/resync path** for payment-method drift because Braintree's payment-method webhook surface is not rich enough to guarantee full convergence from webhooks alone.
- **D-10:** The payment-method read model should stay fast and local for Phoenix/LiveView ergonomics; provider-live reads should be reserved for write-through refreshes, reconciliation, or explicitly scoped operator recovery actions.
- **D-11:** Phase 98 must not collapse customer default truth and subscription-funding truth into one naive flag. Braintree customer default changes do **not** automatically migrate existing subscriptions to the new token.

### Operator surface in `AccrueAdmin`

- **D-12:** `AccrueAdmin` should remain a **narrow operator control plane**, not a provider-specific browser tokenization app.
- **D-13:** The customer payment-method tab should support **inventory + explicit set-default** as a first-class operator action.
- **D-14:** Delete should be treated as a **high-risk operator action** with strong guardrails and explicit impact messaging, not as a casual row action.
- **D-15:** Adding or replacing a Braintree payment method should stay **host-assisted / host-owned** at the browser seam rather than embedding Braintree JS / Drop-in directly into `accrue_admin`.
- **D-16:** If operators need to help repair a customer payment method, the preferred experience is a **tightly scoped handoff** from admin to a host-managed flow, not raw payment entry inside the admin package.
- **D-17:** `AccrueAdmin` copy and UI should explain the operator/customer boundary clearly so users understand why some actions happen in admin and others require a host-side billing flow.

### Delete and default semantics

- **D-18:** Phase 98 should use **explicit replacement + guarded delete**, not best-effort fallback magic and not raw provider passthrough semantics.
- **D-19:** `set_default_payment_method/3` should remain an explicit command. Default changes should never be inferred implicitly from row order or “last remaining method” heuristics.
- **D-20:** Deleting a **non-default** payment method is allowed only when Phase 98 can prove the token is not still funding an active Braintree subscription, or when the system can safely repoint that dependency first.
- **D-21:** Deleting the **default** payment method should require an explicit replacement when another usable payment method exists; the system should not silently pick a fallback default.
- **D-22:** Clearing a customer to “no default payment method” is acceptable only when it is the **last** method and no active dependency blocks removal.
- **D-23:** Phase 98 should not mirror raw Braintree deletion semantics through the public facade because raw delete can cancel associated subscriptions immediately. Accrue must guard this behavior deliberately.
- **D-24:** Error policy should distinguish:
  - unsupported capability (`processor_operation_unsupported`)
  - replacement required
  - payment method still in use
  - stale/conflict state
  - provider/API failure
- **D-25:** Local truth should continue to anchor on `Customer.default_payment_method_id`; any `PaymentMethod.is_default` field should be treated as derived or updated in the same transaction to avoid drift.

### Elixir / Phoenix / Ecto posture

- **D-26:** The public billing surface should stay **context-style and explicit**: validated attrs, narrow handoff structs/maps, tuple returns, and persistence-backed read models.
- **D-27:** Phase 98 should prefer **`Ecto.Multi` / transactional local commits + provider write-through + explicit resync** over hidden side effects or UI-only state assumptions.
- **D-28:** LiveView actions should stay **server-driven and auditable** for default/delete operator flows. Browser tokenization remains a separate host concern.
- **D-29:** Accrue should learn from successful ecosystems by keeping the shared surface **bounded and honest**:
  - from **Laravel Cashier**: clear billable verbs, explicit destructive-payment-method warnings
  - from **Pay (Rails)**: bounded multi-processor support with visible divergence
  - avoid the **ActiveMerchant** footgun: over-broad gateway sameness that hides real processor differences

### Shift-left preference for future GSD passes

- **D-30:** For future processor-track GSD discuss/planning workflows, low-impact implementation choices should be **researched and auto-synthesized into recommendations by default** rather than escalated interactively.
- **D-31:** Reopen choices interactively only when they materially change:
  - public API shape
  - first-party support promise
  - destructive-state semantics
  - operator/security boundary
  - long-term proof-lane philosophy
- **D-32:** Future recommendation bundles should continue to optimize for:
  - least surprise
  - honest support boundaries
  - host-owned browser seams
  - projection-first Phoenix ergonomics
  - explicit state transitions
  - strong DX and clear user/operator copy

### Claude's Discretion

- Exact compatibility/deprecation path for old Stripe-shaped payment-method facade helpers once honest CRUD verbs land.
- Exact shape of the `vault_acquisition` payload as long as it remains narrow, provider-honest, and host-owned at the browser seam.
- Whether `update_payment_method/3` is exposed as a first-class helper or implemented as orchestrated add + set-default + optional cleanup behind a clearer higher-level command.
- Exact reconciliation trigger shape (explicit admin “sync now”, job, write-through helper, or a combination) as long as projection-first truth remains intact.
- Exact admin copy, warning hierarchy, and confirmation UX for destructive flows.

### Deferred Ideas (OUT OF SCOPE)

- Embedding Braintree Drop-in or raw card-entry UX directly into `accrue_admin`
- Generic provider-live payment-method inventory as the default read path
- Automatic fallback-default magic after deletion
- Pretending payment-method updates are universal in-place mutations across processors
- Full checkout parity or billing-portal parity
- Broad payment-method UX beyond the bounded first-party Braintree/Stripe story
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROC-16 | Extend the `Accrue.Billing` facade to provide full CRUD parity for Braintree `payment_methods` (adding new vaulted methods, deleting, setting default). | New honest CRUD verbs, Braintree adapter operations, local projection-first listing, explicit replacement semantics, guarded delete, and forced resync cover this requirement. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/guides/payment-methods/ruby/] [CITED: https://developer.paypal.com/braintree/docs/reference/request/customer/update/node] [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node] |
| PROC-17 | Extend the `AccrueAdmin` UI customer payment methods tab to handle Braintree operator surfaces for payment method updates. | Existing `CustomerLive` payment-method tab can be expanded into server-driven inventory, set-default, guarded delete, sync, and host-assisted replace handoff without embedding browser tokenization in admin. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view] |
</phase_requirements>

## Summary

Phase 98 is not a generic “turn on Braintree CRUD” pass. The current repo already has the right conceptual seams: `Accrue.Billing` wraps payment-method operations, `PaymentMethod` rows are the admin read model, `Customer.default_payment_method_id` anchors local default truth, the host example already passes a narrow `vault_acquisition.reference`, and `AccrueAdmin.Live.CustomerLive` already renders the payment-method tab. What is missing is Braintree-safe orchestration: the public facade still exposes Stripe-shaped `attach` / `detach`, `list_payment_methods/2` intentionally hard-fails, and `Accrue.Processor.Braintree` still returns unsupported for all payment-method callbacks. [VERIFIED: codebase grep]

The main planning constraint is Braintree behavior, not Elixir plumbing. Braintree supports creating, finding, updating, and deleting vaulted payment methods, and it supports changing a customer's default payment method. But Braintree also documents that deleting a payment method immediately cancels associated subscriptions, that simply adding or defaulting a new customer payment method does not move existing subscriptions to the new funding source, and that payment-method webhook coverage is narrow and mostly unrelated to normal card CRUD. That means Phase 98 must be built around explicit replacement, guarded delete, and mandatory write-through refetch/reprojection rather than “best effort” parity with Stripe semantics. [CITED: https://developer.paypal.com/braintree/docs/guides/payment-methods/ruby/] [CITED: https://developer.paypal.com/braintree/docs/reference/request/customer/update/node] [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/payment-method/dotnet/]

**Primary recommendation:** Plan Phase 98 as one coupled slice: new honest facade verbs + Braintree adapter payment-method operations + local projection resync + guarded admin mutations + host-assisted replace flow, with delete safety treated as the hardest requirement rather than a follow-up. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Vault acquisition for new or replacement Braintree methods | Browser / Client | API / Backend | The host already owns Braintree browser acquisition and forwards only `payment_method: %{vault_acquisition: %{reference: token}}` into the facade; Phase 98 should preserve that seam. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/guides/payment-methods/ruby/] |
| Public payment-method CRUD commands | API / Backend | Database / Storage | `Accrue.Billing` and `PaymentMethodActions` are the existing context boundary, and all durable payment-method truth is persisted into local rows. [VERIFIED: codebase grep] |
| Payment-method inventory for admin and host reads | Database / Storage | Frontend Server (SSR/LiveView) | Locked decisions require local-row-first listing, and the current admin tab already renders from local `PaymentMethod` rows. [VERIFIED: codebase grep] |
| Operator default/delete/sync UI | Frontend Server (SSR/LiveView) | API / Backend | `CustomerLive` is a server-driven LiveView, and the phase explicitly prefers auditable server-side mutations over client-side provider calls. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view] |
| Drift reconciliation after payment-method writes | API / Backend | Database / Storage | Braintree payment-method webhooks are insufficient for convergence, so the server layer must refetch canonical provider state and re-project rows. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/payment-method/dotnet/] |
| Subscription dependency guard before delete | API / Backend | Database / Storage | Provider delete is destructive, and the safety check needs server-side comparison between active subscription state and the candidate payment-method token. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node] [CITED: https://developer.paypal.com/braintree/docs/reference/response/subscription/] |

## Project Constraints (from CLAUDE.md)

- Keep to the locked stack floor: Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, PostgreSQL 14+. [VERIFIED: CLAUDE.md]
- Webhook signature verification is mandatory and non-bypassable; sensitive processor fields must not be logged verbatim. [VERIFIED: CLAUDE.md]
- Payment-method details must stay token/reference based; no raw card data or PCI-expanding storage belongs in this phase. [VERIFIED: CLAUDE.md]
- `accrue/` and `accrue_admin/` remain sibling Mix projects in one monorepo; Phase 98 should not assume a single-app Phoenix structure. [VERIFIED: CLAUDE.md]
- `accrue_admin` may depend on LiveView, but core `accrue` must keep browser/provider JS concerns out of the library boundary. [VERIFIED: CLAUDE.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:braintree` | `0.16.0` | Elixir SDK for `Customer` and `PaymentMethod` gateway calls | Already locked in `accrue/mix.lock`, and the installed SDK exposes `Customer.find/update/search` plus `PaymentMethod.create/find/update/delete`, which is enough for Phase 98 adapter work without adding another gateway client. [VERIFIED: mix.lock] [VERIFIED: mix hex.info] |
| `:phoenix_live_view` | `1.1.28` | Server-driven operator UI in `accrue_admin` | The customer payment-method surface already lives in `AccrueAdmin.Live.CustomerLive`, and the repo’s admin/browser verification posture is built around LiveView. [VERIFIED: mix.lock] [VERIFIED: mix hex.info] [VERIFIED: codebase grep] |
| `Ecto` / `Ecto.Multi` | `~> 3.13` | Transactional local writes and projection updates | Existing billing actions already use `Repo.transact/1` and changesets for customer/payment-method state, which matches the locked transactional write-through posture for this phase. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:oban` | `2.21.1` | Reconcile/resync jobs if Phase 98 chooses async recovery paths in addition to synchronous write-through refresh | Use for explicit sync jobs or deferred repair, not as a substitute for immediate post-write refetch. [VERIFIED: mix.lock] [VERIFIED: mix hex.info] [VERIFIED: codebase grep] |
| `:nimble_options` | `1.1.1` | Public facade option validation | Use when introducing new CRUD attrs so old and new payment-method APIs fail with typed validation instead of ad hoc pattern matching. [VERIFIED: mix.lock] [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Honest CRUD verbs | Keep `attach_payment_method/3` and `detach_payment_method/2` as the public story | That would preserve backward compatibility but would keep leaking Stripe-shaped semantics into a Braintree-safe slice. The old names can remain as compatibility wrappers, but they should not drive new planning. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/guides/payment-methods/ruby/] |
| Local-row-first listing | Provider-live inventory on every admin page load | Braintree `customer.find` can return payment methods, but the locked posture is projection-first for Phoenix ergonomics, auditability, and consistent copy/state handling. [CITED: https://developer.paypal.com/braintree/docs/reference/response/payment-method/node/] [VERIFIED: codebase grep] |
| Replacement semantics for `update_payment_method/3` | Fake universal in-place edit | Braintree supports limited in-place updates, but changing which token funds subscriptions is a separate concern, so “replace + optional repoint + optional cleanup” is safer and more honest. [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/update/node/] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/] |

**Installation:**
```bash
# None. Phase 98 reuses dependencies already declared in accrue/mix.exs and accrue_admin/mix.exs.
```

**Version verification:** `accrue/mix.lock` confirms `:braintree 0.16.0`, `:oban 2.21.1`, and `:phoenix_live_view 1.1.28`; `mix hex.info` confirmed the installed `:braintree` and `:phoenix_live_view` releases and showed `Oban` has a newer `2.22.x` line, so this phase should assume the repo’s currently locked versions unless a separate upgrade phase is opened. [VERIFIED: mix.lock] [VERIFIED: mix hex.info]

## Architecture Patterns

### System Architecture Diagram

```text
Host browser
  -> Braintree client flow (host-owned)
  -> vault_acquisition.reference
  -> Accrue.Billing.add/update_payment_method
  -> Accrue.Processor.Braintree.{Customer,PaymentMethod}
  -> Braintree Vault
  -> canonical customer/payment-method state
  -> refetch customer + payment methods
  -> local projection update (Customer + PaymentMethod rows)
  -> AccrueAdmin / host reads local rows

AccrueAdmin operator
  -> LiveView event (set default / delete / sync)
  -> Accrue.Billing command
  -> guard checks (ownership, default semantics, active subscription dependency)
  -> provider write if allowed
  -> refetch + reproject
  -> flash + refreshed local inventory
```

### Recommended Project Structure

```text
accrue/lib/accrue/
├── billing.ex                           # Public CRUD facade and telemetry wrappers
├── billing/payment_method_actions.ex    # CRUD orchestration, delete guards, resync helpers
├── processor/braintree.ex               # Braintree Customer/PaymentMethod adapter calls
└── webhook/default_handler.ex           # Reuse only where webhook normalization actually exists

accrue_admin/lib/accrue_admin/
├── live/customer_live.ex                # LiveView events, sync/default/delete UI flow
└── copy/customer_payment_methods.ex     # Operator copy and warning strings

examples/accrue_host/lib/accrue_host_web/
└── ...                                  # Host-owned add/replace handoff route or guidance target
```

### Pattern 1: Host-Owned Vault Acquisition Handoff
**What:** Keep browser tokenization outside `accrue` and pass only a narrow vaulted reference into the billing facade. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/guides/payment-methods/ruby/]

**When to use:** Adding a new Braintree method or replacing an existing one. [CITED: https://developer.paypal.com/braintree/docs/guides/payment-methods/ruby/]

**Example:**
```elixir
# Source: examples/accrue_host/lib/accrue_host/billing.ex
opts = Keyword.put(opts, :payment_method, %{vault_acquisition: %{reference: vault_reference}})
Billing.subscribe(organization, price_id, opts)
```

### Pattern 2: Write-Through Refetch and Reprojection
**What:** Treat Braintree as write authority, then immediately refetch canonical state and persist local `Customer` / `PaymentMethod` rows from that canonical response. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/payment-method/dotnet/]

**When to use:** After add, default change, replacement, delete, or manual sync. [VERIFIED: codebase grep]

**Example:**
```elixir
# Source: repo pattern from webhook/default_handler.ex and payment_method_actions.ex
Repo.transact(fn ->
  with {:ok, _provider_result} <- provider_write(...),
       {:ok, canonical_customer} <- braintree_customer_find(...),
       :ok <- reproject_customer_and_payment_methods(canonical_customer) do
    :ok
  end
end)
```

### Pattern 3: Guarded Delete with Explicit Replacement Path
**What:** Model delete as an orchestrated command that first proves the token is not funding an active subscription, blocks default deletion when replacement is required, and only then issues provider delete. [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/] [VERIFIED: codebase grep]

**When to use:** Any operator- or host-triggered delete of a Braintree method. [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node]

**Example:**
```elixir
# Source: recommended orchestration from locked phase decisions + current local schema
with :ok <- ensure_not_subscription_funding(pm),
     :ok <- ensure_default_delete_is_safe(customer, pm, replacement_pm),
     {:ok, _} <- provider_delete(pm.processor_id),
     :ok <- sync_payment_methods(customer) do
  {:ok, :deleted}
end
```

### Anti-Patterns to Avoid

- **Raw `detach` passthrough for Braintree:** Braintree delete cancels associated subscriptions immediately, so the public delete path cannot be a thin provider passthrough. [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node]
- **Using customer default as a proxy for subscription funding:** Braintree says default changes do not automatically move existing subscriptions to the new token. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/] [CITED: https://developer.paypal.com/braintree/articles/guides/recurring-billing/subscriptions]
- **Provider-live listing as the normal admin read path:** The locked phase posture is local projection first, and the current admin tab already renders from local rows. [VERIFIED: codebase grep]
- **Relying on Braintree payment-method webhooks for convergence:** The documented webhook kinds are too narrow for ordinary vaulted-card CRUD. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/payment-method/dotnet/] [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser-side Braintree capture inside admin | Embedded admin tokenization UI or Drop-in inside `accrue_admin` | Reuse the existing host-owned `vault_acquisition.reference` seam | This preserves the project’s PCI boundary, matches Phase 96, and keeps `accrue_admin` provider-agnostic at the browser edge. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/guides/payment-methods/ruby/] |
| Payment-method truth after mutation | Hand-maintained local flags or optimistic UI-only updates | Provider write followed by explicit refetch and reprojection | Braintree webhook coverage is not sufficient to heal CRUD drift by itself. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/payment-method/dotnet/] [VERIFIED: codebase grep] |
| “Edit card” abstraction | Universal in-place update API | Replacement-oriented orchestration | Braintree supports narrow update fields, but subscription funding token changes are separate, so replacement is the safer shared semantic. [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/update/node/] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/] |
| Silent fallback default selection | Heuristic “pick another method” delete logic | Explicit `set_default_payment_method/3` plus guarded delete | The locked phase contract forbids implicit fallback default magic. [VERIFIED: codebase grep] |

**Key insight:** The dangerous complexity in this phase is not SDK calls; it is the mismatch between customer-default semantics, subscription-funding semantics, and destructive delete behavior. The plan should spend effort on orchestration and convergence, not on inventing a broader abstraction layer. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/] [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node]

## Common Pitfalls

### Pitfall 1: Treating `set_default` as “move all subscriptions”
**What goes wrong:** Operators believe a new customer default immediately funds existing subscriptions. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/]
**Why it happens:** Stripe-shaped intuition leaks into Braintree planning. [ASSUMED]
**How to avoid:** Keep customer default and subscription-funding checks separate in facade docs, admin copy, and delete guards. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/]
**Warning signs:** A proposed delete flow checks only `Customer.default_payment_method_id` and not active subscription linkage. [VERIFIED: codebase grep]

### Pitfall 2: Deleting a token before proving dependency safety
**What goes wrong:** A provider delete cancels live subscriptions immediately. [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node]
**Why it happens:** `detach_payment_method/2` sounds harmless when read through Stripe vocabulary. [VERIFIED: codebase grep]
**How to avoid:** Build Braintree delete as a dedicated guarded command, not as an alias of existing detach semantics. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node]
**Warning signs:** Any plan item that deletes a Braintree token before checking active subscriptions is wrong. [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node]

### Pitfall 3: Assuming payment-method webhooks can keep rows converged
**What goes wrong:** Local projections drift after add/default/delete flows initiated outside the current code path. [VERIFIED: codebase grep]
**Why it happens:** The current Braintree webhook normalization only maps subscription events, and official payment-method webhooks do not cover normal card CRUD parity. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/payment-method/dotnet/]
**How to avoid:** Add explicit sync/reconcile commands and mandatory post-write refetch. [VERIFIED: codebase grep]
**Warning signs:** A design that says “webhooks will update payment methods later” without a sync path is incomplete. [VERIFIED: codebase grep]

### Pitfall 4: Letting `PaymentMethod.is_default` drift from `Customer.default_payment_method_id`
**What goes wrong:** Admin UI shows contradictory default markers. [VERIFIED: codebase grep]
**Why it happens:** The schema has both a customer foreign key anchor and a boolean field, but the current code treats the customer FK as the stronger source of truth. [VERIFIED: codebase grep]
**How to avoid:** Derive row default presentation from `Customer.default_payment_method_id`, or update any boolean shadow in the same transaction. [VERIFIED: codebase grep]
**Warning signs:** Queries or templates reading only `payment_method.is_default` for Braintree state. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources and the current codebase:

### Narrow host handoff for vaulted acquisition
```elixir
# Source: examples/accrue_host/lib/accrue_host/billing.ex
opts = Keyword.put(opts, :payment_method, %{vault_acquisition: %{reference: vault_reference}})
```
[VERIFIED: codebase grep]

### Braintree-safe default change
```elixir
# Source idea: Braintree Customer: Update defaultPaymentMethodToken
customer_update = %{defaultPaymentMethodToken: payment_method_token}
```
[CITED: https://developer.paypal.com/braintree/docs/reference/request/customer/update/node]

### Local inventory query for admin rendering
```elixir
# Source: accrue_admin/lib/accrue_admin/live/customer_live.ex
PaymentMethod
|> where([payment_method], payment_method.customer_id == ^customer.id)
|> order_by([payment_method], desc: payment_method.inserted_at, desc: payment_method.id)
|> Repo.all()
```
[VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Stripe-shaped public attach/detach vocabulary for payment methods | Honest CRUD verbs are now the locked direction for Braintree planning | Locked in Phase 98 context on 2026-04-30 | Planner should treat compatibility wrappers as secondary and design the phase around `add/update/delete/set_default/list`. [VERIFIED: codebase grep] |
| Payment-method listing as out-of-slice unsupported operation | Local-row-first listing is now a locked target for Braintree/admin ergonomics | Phase 95 made `list_payment_methods/2` explicitly unsupported; Phase 98 reopens it as a projected read model | Planning must include read-model promotion, not just adapter calls. [VERIFIED: codebase grep] |
| Thin Braintree slice centered only on `subscribe/3` with host-owned vault acquisition | CRUD phase extends the same host-owned acquisition seam into payment-method management | Phase 96 completed the subscribe path on 2026-04-29; Phase 98 extends that seam | No admin-embedded Braintree JS should appear in the plan. [VERIFIED: codebase grep] |

**Deprecated/outdated:**

- `Accrue.Billing.list_payment_methods/2` as a permanent unsupported seam: this was correct for Phase 95 but is outdated for Phase 98 planning. [VERIFIED: codebase grep]
- Thinking of Braintree “update payment method” as universal in-place card editing: the safer first-party contract is explicit replacement semantics. [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/update/node] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Operators may still infer Stripe-like “set default moves subscriptions” behavior unless copy and guardrails make the distinction explicit. | Common Pitfalls | Medium: UI and docs could under-warn a destructive path even if the backend is correct. |

## Open Questions (RESOLVED)

1. **What is the cheapest durable way to prove a payment method is funding an active Braintree subscription?**
   - Decision: Phase 98 should rely on the existing projected `Subscription.data["payment_method_token"]` field as the delete guard source of truth, queried only for active Braintree subscriptions. This keeps the phase inside the current schema budget and matches the canonical subscription payload Accrue already stores. [CITED: https://developer.paypal.com/braintree/docs/reference/response/subscription/] [VERIFIED: codebase grep]
   - Boundary: do not add a new first-class schema field or index in Phase 98 unless the implementation proves the JSONB path is unavailable or materially too slow under the repo's current proof lane. If that evidence appears, treat it as a follow-up phase rather than reopening this plan mid-execution. [VERIFIED: codebase grep]

2. **Should `update_payment_method/3` be a first-class public command or a documented orchestrator?**
   - Decision: yes. Phase 98 should expose `update_payment_method/3` as a first-class public `Accrue.Billing` command, but its semantics must stay replacement-oriented: add a new vaulted method through the host-owned seam, optionally set it as default, then optionally remove the replaced method when guardrails allow. [VERIFIED: codebase grep]
   - Boundary: this is a convenience wrapper over explicit orchestration, not a promise of provider-agnostic in-place card editing. UI and docs should prefer "Replace payment method" language and avoid implying universal edit semantics. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core `accrue` and `accrue_admin` implementation/tests | ✓ | `1.19.5` | — |
| Erlang/OTP | Core runtime/tests | ✓ | `28` | — |
| Mix | ExUnit, compile, dialyzer, docs | ✓ | `1.19.5` | — |
| PostgreSQL CLI | Local test DB setup and manual verification | ✓ | `14.17` | Repo test helpers can still run with configured DB even if `psql` is unused directly. |
| Node / npm / npx | Host Playwright verification for admin route changes | ✓ | `22.14.0` / `11.1.0` | — |
| `examples/accrue_host/node_modules` | Running host Playwright immediately | ✗ | — | Run `npm install` in `examples/accrue_host` before browser verification. |
| Braintree sandbox credentials/account | Provider-fidelity execution beyond hermetic tests | Not locally verifiable | — | Use hermetic stub/Fake coverage as the merge-blocking lane. |

**Missing dependencies with no fallback:**
- None identified for planning. Live-provider Braintree execution is advisory rather than merge-blocking in the current project posture. [VERIFIED: codebase grep]

**Missing dependencies with fallback:**
- Host/browser dependencies are not installed locally, but the repo already has `package.json` scripts and CI coverage for that path. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`, plus host Playwright for browser verification. [VERIFIED: codebase grep] |
| Config file | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `examples/accrue_host/package.json`. [VERIFIED: codebase grep] |
| Quick run command | `cd accrue && mix test test/accrue/billing/payment_method_actions_test.exs test/accrue/billing/default_payment_method_test.exs test/accrue/processor/braintree_test.exs --warnings-as-errors` [VERIFIED: codebase grep] |
| Full suite command | `cd accrue && mix test --warnings-as-errors && cd ../accrue_admin && mix test --warnings-as-errors` plus host browser verification when UI changes touch the VERIFY route. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROC-16 | Public facade can add/list/set-default/delete Braintree payment methods with replacement/delete guardrails and resync | unit + integration | `cd accrue && mix test test/accrue/billing/payment_method_actions_test.exs test/accrue/billing/default_payment_method_test.exs test/accrue/processor/braintree_test.exs --warnings-as-errors` | ✅ existing targets, but they need substantial expansion. [VERIFIED: codebase grep] |
| PROC-17 | Admin customer payment-method tab supports inventory, set-default, guarded delete, sync, and host-assisted replace messaging | LiveView + browser | `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs --warnings-as-errors` and `cd examples/accrue_host && npm run e2e:a11y` | ✅ existing route/test harnesses, but mutation coverage is missing. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Run the targeted ExUnit command for the file(s) touched. [VERIFIED: codebase grep]
- **Per wave merge:** Run the core `accrue` and `accrue_admin` test suites; add host Playwright if the `payment_methods` tab markup or copy changes materially. [VERIFIED: codebase grep]
- **Phase gate:** Full suites green plus browser verification for the customer payment-method route before `/gsd-verify-work`. [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] `accrue/test/accrue/billing/payment_method_crud_braintree_test.exs` — new facade-level Braintree CRUD and delete-guard coverage for PROC-16. [VERIFIED: codebase grep]
- [ ] Expand `accrue/test/accrue/processor/braintree_test.exs` — adapter coverage for `Customer.find/update` and `PaymentMethod.create/find/update/delete`. [VERIFIED: codebase grep]
- [ ] Expand `accrue_admin/test/accrue_admin/live/customer_live_test.exs` — server-driven mutation events, flash states, blocked delete copy, and sync action coverage for PROC-17. [VERIFIED: codebase grep]
- [ ] `examples/accrue_host/test/accrue_host/braintree_payment_method_flow_test.exs` or equivalent — host-assisted replace proof using the existing vault handoff seam. [VERIFIED: codebase grep]
- [ ] Update `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` if the customer payment-method route gains materially changed interactive chrome. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Admin auth remains host-configured through `Accrue.Auth`; operator mutations must stay behind the existing LiveView/admin auth boundary. [VERIFIED: codebase grep] |
| V3 Session Management | yes | Use Phoenix/LiveView session and CSRF protections already present in the mounted admin surface. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Customer-scoped admin access already exists, and destructive payment-method actions must reuse server-side scope checks. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Validate new CRUD attrs with explicit schemas and current changeset/option validation patterns; do not trust browser payloads. [VERIFIED: codebase grep] |
| V6 Cryptography | no | Phase 98 should not add custom cryptography; it should continue to rely on Braintree vault tokens and existing webhook-signature infrastructure. [VERIFIED: CLAUDE.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Operator deletes a payment method that still funds an active subscription | Tampering / Denial of Service | Server-side dependency guard before provider delete, explicit replacement path, and mandatory confirmation UI. [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node] [VERIFIED: codebase grep] |
| Admin UI implies a default change moved subscription funding when it did not | Spoofing / Integrity | Copy and command semantics must distinguish customer default from subscription funding token. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/] |
| Sensitive processor payloads leak into logs during errors | Information Disclosure | Continue honoring the `APIError.processor_error` warning and avoid logging raw provider payloads. [VERIFIED: codebase grep] [VERIFIED: CLAUDE.md] |
| Stale local projection enables an unsafe destructive action | Tampering | Post-write refetch/reprojection plus explicit sync action and optimistic-lock-aware local writes. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- `098-CONTEXT.md`, `v1.32-REQUIREMENTS.md`, `v1.32-ROADMAP.md`, `098-UI-SPEC.md` — locked scope, semantics, and UI boundaries. [VERIFIED: codebase grep]
- `accrue/lib/accrue/billing.ex`, `billing/payment_method_actions.ex`, `billing/payment_method.ex`, `billing/customer.ex`, `processor/braintree.ex`, `processor/capabilities.ex`, `webhook/default_handler.ex`, `accrue_admin/live/customer_live.ex`, `examples/accrue_host/lib/accrue_host/billing.ex` — current implementation seams. [VERIFIED: codebase grep]
- `accrue/mix.exs`, `accrue/mix.lock`, `accrue_admin/mix.exs`, `accrue_admin/mix.lock`, `mix hex.info` output — dependency and environment verification. [VERIFIED: mix.lock] [VERIFIED: mix hex.info]
- Braintree payment-method guide: https://developer.paypal.com/braintree/docs/guides/payment-methods/ruby/ — create/update/find/delete lifecycle and default semantics. [CITED: https://developer.paypal.com/braintree/docs/guides/payment-methods/ruby/]
- Braintree customer update reference: https://developer.paypal.com/braintree/docs/reference/request/customer/update/node — `defaultPaymentMethodToken` semantics and customer-update add/replace patterns. [CITED: https://developer.paypal.com/braintree/docs/reference/request/customer/update/node]
- Braintree payment-method delete reference: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node — destructive delete consequences. [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node]
- Braintree recurring billing manage guide: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/ — subscription payment-method coupling and update behavior. [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/]
- Braintree payment-method webhooks reference: https://developer.paypal.com/braintree/docs/reference/general/webhooks/payment-method/dotnet/ — limited webhook kinds. [CITED: https://developer.paypal.com/braintree/docs/reference/general/webhooks/payment-method/dotnet/]
- Braintree subscription response reference: https://developer.paypal.com/braintree/docs/reference/response/subscription/ — `paymentMethodToken` in canonical subscription data. [CITED: https://developer.paypal.com/braintree/docs/reference/response/subscription/]

### Secondary (MEDIUM confidence)

- Phoenix LiveView docs: https://hexdocs.pm/phoenix_live_view — server-driven mutation model guidance used for the admin interaction posture. [CITED: https://hexdocs.pm/phoenix_live_view]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - The relevant libraries, versions, and current repo locks were directly verified from `mix.lock`, `mix.exs`, and `mix hex.info`. [VERIFIED: mix.lock] [VERIFIED: mix hex.info]
- Architecture: MEDIUM - The recommended shape is strongly constrained by locked context and current seams, but the exact delete-dependency implementation path still has one open question around JSONB vs first-class projection. [VERIFIED: codebase grep] [CITED: https://developer.paypal.com/braintree/docs/reference/response/subscription/]
- Pitfalls: HIGH - The dangerous behaviors are explicitly documented by Braintree and already visible in the current code gaps. [CITED: https://developer.paypal.com/braintree/docs/reference/request/payment-method/delete/node] [CITED: https://developer.paypal.com/braintree/docs/guides/recurring-billing/manage/node/] [VERIFIED: codebase grep]

**Research date:** 2026-04-30
**Valid until:** 2026-05-30 for repo-structure claims; 2026-05-07 for Braintree and dependency-currentness claims.
