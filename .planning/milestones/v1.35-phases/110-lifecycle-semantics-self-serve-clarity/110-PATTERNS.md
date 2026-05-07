# Phase 110: Lifecycle Semantics & Self-Serve Clarity - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/billing/subscription.ex` | model | transform | same file | exact |
| `accrue/lib/accrue/billing/query.ex` | query | CRUD | same file | exact |
| `accrue/lib/accrue/billing/subscription_actions.ex` | service | request-response | same file | exact |
| `accrue/guides/<new lifecycle SSOT guide>.md` | docs | canonical contract | `accrue/guides/portal_configuration_checklist.md`, `accrue/guides/braintree-local-portal.md` | role-match |
| `accrue/guides/braintree-local-portal.md` | docs | canonical contract | same file | exact |
| `accrue/guides/portal_configuration_checklist.md` | docs | canonical contract | same file | exact |
| `accrue/guides/webhooks.md` | docs | operator guidance | same file | exact |
| `accrue/guides/webhook_gotchas.md` | docs | operator guidance | same file | exact |
| `accrue_portal/lib/accrue_portal/copy.ex` | utility | transform | same file | exact |
| `accrue_portal/lib/accrue_portal/live/subscription_live.ex` | component | request-response | same file | exact |
| `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` | component | request-response | same file | exact |
| `accrue_admin/lib/accrue_admin/copy/subscription.ex` | utility | transform | same file | exact |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | component | request-response | same file | exact |
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | component | request-response | same file | exact |
| `accrue/test`, `accrue_portal/test`, `accrue_admin/test` lifecycle tests | test | verifier | same files listed below | exact |

## Pattern Assignments

### `accrue/lib/accrue/billing/subscription.ex` (model, transform)

**Analog:** same file

**Lifecycle glossary anchor** ([accrue/lib/accrue/billing/subscription.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription.ex:10))
```elixir
## Use the predicates, not raw `.status`

Do not gate business logic on direct comparisons to `.status`.
```

**Canonical predicate pattern** ([accrue/lib/accrue/billing/subscription.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription.ex:169))
```elixir
@doc """
True if the subscription is `:active` with `cancel_at_period_end` set and
the current period end is still in the future
"""
def canceling?(%__MODULE__{
      status: :active,
      cancel_at_period_end: true,
      current_period_end: %DateTime{} = cpe
    }) do
  DateTime.compare(cpe, Accrue.Clock.utc_now()) == :gt
end
```

**Planner implication:** any new lifecycle glossary, UI label helper, or admin summary should derive meanings from these predicates, not from raw `status`.

### `accrue/lib/accrue/billing/query.ex` (query, CRUD)

**Analog:** same file

**Query mirrors predicate semantics** ([accrue/lib/accrue/billing/query.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/query.ex:40))
```elixir
@doc """
Subscriptions that are `:active` with `cancel_at_period_end` set and a
period end still in the future
"""
def canceling(query \\ Subscription) do
  now = Accrue.Clock.utc_now()

  from(s in query,
    where:
      s.status == :active and s.cancel_at_period_end == true and
        s.current_period_end > ^now
  )
end
```

**Planner implication:** if Phase 110 adds shared lifecycle summary helpers for list/detail pages, list filtering and rendered labels should stay aligned with `Query` for multi-row surfaces and `Subscription` for single-row surfaces.

### `accrue/lib/accrue/billing/subscription_actions.ex` (service, request-response)

**Analog:** same file

**Cancel-at-period-end is the local semantic seam** ([accrue/lib/accrue/billing/subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:528))
```elixir
def cancel_at_period_end(%Subscription{} = sub, opts) do
  at_dt = Keyword.get(opts, :at)
  op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()

  {stripe_params, local_attrs_patch, mode_payload} =
    case at_dt do
      nil ->
        {%{cancel_at_period_end: true}, %{cancel_at_period_end: true}, %{mode: "at_period_end"}}
```

**Provider-honest unsupported copy pattern** ([accrue/lib/accrue/billing/subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:586))
```elixir
{:error,
 %Accrue.APIError{
   code: "processor_operation_unsupported",
   http_status: 422,
   message:
     "Braintree subscriptions cannot be resumed through resume/2 because provider-side cancellations cannot be reactivated."
 }}
```

**Pause/unpause unsupported pattern** ([accrue/lib/accrue/billing/subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:672))
```elixir
message: "Braintree does not expose Accrue's pause/2 collection semantic."
```

**State guard pattern** ([accrue/lib/accrue/billing/subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:575))
```elixir
unless Subscription.canceling?(sub) do
  raise Accrue.Error.InvalidState,
    message:
      "Accrue.Billing.resume/1 requires a canceling subscription ... For paused subs use unpause/1."
end
```

**Planner implication:** Phase 110 should not invent softer parity wording than the runtime already uses. UI/helper text should either mirror these distinctions or translate them more plainly without changing meaning.

### `accrue/guides/<new lifecycle SSOT guide>.md` (docs, canonical contract)

**Closest analogs:** [accrue/guides/portal_configuration_checklist.md](/Users/jon/projects/accrue/accrue/guides/portal_configuration_checklist.md:1), [accrue/guides/braintree-local-portal.md](/Users/jon/projects/accrue/accrue/guides/braintree-local-portal.md:1)

**Single-issue conceptual guide shape** ([accrue/guides/portal_configuration_checklist.md](/Users/jon/projects/accrue/accrue/guides/portal_configuration_checklist.md:28))
```markdown
## The three required toggles
...
### 3. Cancellation timing — `at_period_end` (NOT immediate)
...
Why: with "Immediately" selected ... loses access on the spot. With `at_period_end` the
customer keeps access through the period they already paid for
```

**Provider-honest capability framing** ([accrue/guides/braintree-local-portal.md](/Users/jon/projects/accrue/accrue/guides/braintree-local-portal.md:16))
```markdown
Braintree does not fall back to an upstream hosted billing portal.
The failure is local and typed ...
```

**Planner implication:** the new guide should use one conceptual glossary first, then attach provider labels and next steps. Do not lead with API reference or processor-by-processor storytelling.

### `accrue/guides/braintree-local-portal.md` (docs, canonical contract)

**Analog:** same file

**Current stale seam Phase 110 should correct** ([accrue/guides/braintree-local-portal.md](/Users/jon/projects/accrue/accrue/guides/braintree-local-portal.md:187))
```markdown
### 3. Canceling Subscriptions

Offer immediate cancellations using Accrue's cancel functions:
...
# Braintree supports immediate cancellation
case Billing.cancel(subscription) do
```

**Planner implication:** this is a prime Phase 110 touchpoint. It currently teaches immediate cancel as the self-serve example, which conflicts with the new default posture.

### `accrue/guides/portal_configuration_checklist.md` (docs, canonical contract)

**Analog:** same file

**Explicit access-through-date wording** ([accrue/guides/portal_configuration_checklist.md](/Users/jon/projects/accrue/accrue/guides/portal_configuration_checklist.md:58))
```markdown
### 3. Cancellation timing — `at_period_end` (NOT immediate)
...
customer keeps access through the period they already paid for
```

**Planner implication:** reuse this guide’s structure and wording posture for the Stripe section of the lifecycle SSOT and for portal/admin copy that should say "cancel renewal" rather than hard-stop cancel.

### `accrue/guides/webhooks.md` and `accrue/guides/webhook_gotchas.md` (docs, operator guidance)

**Analogs:** same files

**Convergence framing** ([accrue/guides/webhook_gotchas.md](/Users/jon/projects/accrue/accrue/guides/webhook_gotchas.md:52))
```markdown
Treat webhook payloads as signals, not as your source of truth.
...
That avoids stale-snapshot bugs and keeps out-of-order deliveries from forcing
the local model backward.
```

**Planner implication:** if Phase 110 adds "refresh" or "may take a moment to converge" language, anchor it to this existing operator truth instead of inventing generic eventual-consistency copy.

### `accrue_portal/lib/accrue_portal/copy.ex` (utility, transform)

**Analog:** same file

**Centralized customer copy seam** ([accrue_portal/lib/accrue_portal/copy.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/copy.ex:65))
```elixir
def subscriptions_cancel_success,
  do: "Subscription will cancel at the end of the current billing period."

def subscription_cancel_body,
  do: "Cancel at period end to keep access through the current billing period."
```

**Planner implication:** Phase 110 portal copy should add new lifecycle summary/status/helper functions here first, then consume them from both portal LiveViews.

### `accrue_portal/lib/accrue_portal/live/subscription_live.ex` (component, request-response)

**Analog:** same file

**Thin mount + scoped mutation pattern** ([accrue_portal/lib/accrue_portal/live/subscription_live.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/live/subscription_live.ex:11))
```elixir
case Authorize.subscription(socket, id) do
  {:ok, %Subscription{} = subscription} ->
    socket
    |> assign(:page_title, Copy.subscription_page_title())
    |> assign(:subscription, subscription)
```

**Mutation pattern** ([accrue_portal/lib/accrue_portal/live/subscription_live.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/live/subscription_live.ex:43))
```elixir
case Authorize.subscription(socket, subscription.id) do
  {:ok, %Subscription{} = scoped_subscription} ->
    case Billing.cancel_at_period_end(scoped_subscription) do
      {:ok, updated} ->
        socket
        |> assign(:subscription, updated)
        |> put_flash(:info, Copy.subscription_cancel_success())
```

**Current render seam** ([accrue_portal/lib/accrue_portal/live/subscription_live.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/live/subscription_live.ex:77))
```elixir
<strong>{Copy.subscription_status_label()}</strong>
<span>{@subscription.status}</span>
...
<strong>{Copy.subscription_period_end_label()}</strong>
<span>{format_datetime(@subscription.current_period_end)}</span>
```

**Planner implication:** add lifecycle summary/predicate-driven labels here without widening into component framework changes.

### `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` (component, request-response)

**Analog:** same file

**List surface currently renders raw status** ([accrue_portal/lib/accrue_portal/live/subscriptions_live.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/live/subscriptions_live.ex:54))
```elixir
<p>{Copy.subscriptions_status_label()}: {subscription.status}</p>
...
{Copy.subscription_cancel_cta()}
```

**Planner implication:** this is the exact list/detail drift seam. If a shared lifecycle summary helper is introduced, use it here and in detail together.

### `accrue_admin/lib/accrue_admin/copy/subscription.ex` (utility, transform)

**Analog:** same file

**Admin strings are delegated, not embedded** ([accrue_admin/lib/accrue_admin/copy/subscription.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/copy/subscription.ex:16))
```elixir
def subscription_kpi_status_label, do: "Status"
def subscription_kpi_canonical_predicates_label, do: "Canonical predicates"
def subscription_action_cancel_now, do: "Cancel now"
def subscription_action_cancel_at_period_end, do: "Cancel at period end"
```

**Planner implication:** if Phase 110 changes operator wording, add it here and keep `AccrueAdmin.Copy` delegation intact rather than inlining strings in LiveView.

### `accrue_admin/lib/accrue_admin/live/subscription_live.ex` (component, request-response)

**Analog:** same file

**Admin summary already uses predicate aggregation** ([accrue_admin/lib/accrue_admin/live/subscription_live.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex:150))
```elixir
<KpiCard.kpi_card label={Copy.subscription_kpi_canonical_predicates_label()} value={predicate_summary(@subscription)}>
  <:meta>Use `Accrue.Billing.Subscription` predicates, not raw status branching.</:meta>
</KpiCard.kpi_card>
```

**Predicate-summary helper** ([accrue_admin/lib/accrue_admin/live/subscription_live.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex:407))
```elixir
[
  Accrue.Billing.Subscription.active?(subscription) && "active",
  Accrue.Billing.Subscription.canceling?(subscription) && "canceling",
  Accrue.Billing.Subscription.paused?(subscription) && "paused",
  Accrue.Billing.Subscription.past_due?(subscription) && "past due",
  Accrue.Billing.Subscription.canceled?(subscription) && "canceled"
]
```

**Action dispatch seam** ([accrue_admin/lib/accrue_admin/live/subscription_live.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex:501))
```elixir
defp execute_action(subscription, _customer, %{type: "cancel_at_period_end"}, operation_id) do
  Billing.cancel_at_period_end(subscription, operation_id: operation_id)
end
```

**Planner implication:** this file is the best analog for a shared lifecycle summary helper. Portal can likely borrow the summary logic shape from here, but with customer-facing copy.

### `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` (component, request-response)

**Analog:** same file

**Host example still carries local string constants** ([examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:18))
```elixir
@error_copy "We couldn't complete that billing action..."
@cancel_copy "Cancel organization subscription: Confirm cancellation before ending organization access."
```

**Current immediate-cancel flow** ([examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:155))
```elixir
case Billing.cancel_active_organization(
       socket.assigns.current_scope,
       subscription,
       operation_id: operation_id(params, "cancel")
     ) do
  {:ok, _updated_subscription} ->
    put_flash(socket, :info, "Subscription canceled.")
```

**Planner implication:** Phase 110 should keep this example aligned with the clarified semantics, or explicitly mark it as support/admin-only hard-stop behavior if it remains immediate.

### Tests and verifier patterns

**Core predicate truth** ([accrue/test/accrue/billing/subscription_predicates_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/subscription_predicates_test.exs:44))
```elixir
test "canceling? requires status=:active + cancel_at_period_end + future period end" do
  ...
  refute Subscription.canceling?(%Subscription{status: :canceled, ...})
end
```

**Core action truth** ([accrue/test/accrue/billing/subscription_cancel_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/subscription_cancel_test.exs:58))
```elixir
test "sets cancel_at_period_end=true; status stays :active; canceling? returns true" do
  assert {:ok, updated} = Billing.cancel_at_period_end(sub)
  assert updated.cancel_at_period_end == true
  assert updated.status == :active
  assert Subscription.canceling?(updated)
end
```

**Query/list truth** ([accrue/test/accrue/billing/query_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing/query_test.exs:66))
```elixir
rows = Query.canceling() |> Repo.all()
assert length(rows) == 1
assert hd(rows).cancel_at_period_end == true
```

**Portal rendered-copy verification** ([accrue_portal/test/accrue_portal/live/subscription_live_test.exs](/Users/jon/projects/accrue/accrue_portal/test/accrue_portal/live/subscription_live_test.exs:20), [accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs](/Users/jon/projects/accrue/accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs:20))
```elixir
assert {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")
...
html =
  view
  |> element("button[phx-click='cancel']")
  |> render_click()

assert TestRepo.get!(Subscription, subscription.id).cancel_at_period_end
```

**Admin rendered summary + action verification** ([accrue_admin/test/accrue_admin/live/subscription_live_test.exs](/Users/jon/projects/accrue/accrue_admin/test/accrue_admin/live/subscription_live_test.exs:80))
```elixir
assert html =~ "Canonical predicates"
assert html =~ "active"
...
assert html =~ Copy.subscription_action_recorded_info()
```

**Docs contract test analog** ([accrue/test/accrue/docs/organization_billing_guide_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/organization_billing_guide_test.exs:10), [accrue/test/accrue/billing_portal_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/billing_portal_test.exs:88))
```elixir
guide = File.read!(@guide)

for needle <- ["...", "..."] do
  assert guide =~ needle
end
```

**Planner implication:** if Phase 110 adds a new canonical lifecycle guide, add a docs contract test in this style instead of relying only on manual review.

## Shared Patterns

### Lifecycle meaning comes from predicates, not raw status
**Sources:** [accrue/lib/accrue/billing/subscription.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription.ex:10), [accrue_admin/lib/accrue_admin/live/subscription_live.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex:407)

Apply to all doc/copy/UI work in Phase 110:
- `active` can coexist with a pending end-of-period cancel.
- `canceling` is a distinct user-facing state.
- `paused`, `past_due`, and `ended/canceled` must not be collapsed.

### Provider-honest unsupported messaging
**Source:** [accrue/lib/accrue/billing/subscription_actions.ex](/Users/jon/projects/accrue/accrue/lib/accrue/billing/subscription_actions.ex:586)

Apply to lifecycle helper text and docs:
- say what Braintree cannot do
- say what Accrue owns locally
- give the next step

### Portal copy should stay centralized
**Source:** [accrue_portal/lib/accrue_portal/copy.ex](/Users/jon/projects/accrue/accrue_portal/lib/accrue_portal/copy.ex:53)

Apply to both portal LiveViews:
- add shared lifecycle labels/body/helper text in `Copy`
- keep LiveViews thin and copy-driven

### Admin summary should stay predicate-driven
**Source:** [accrue_admin/lib/accrue_admin/live/subscription_live.ex](/Users/jon/projects/accrue/accrue_admin/lib/accrue_admin/live/subscription_live.ex:407)

Apply to any shared lifecycle summary extraction:
- the existing `predicate_summary/1` is the strongest UI analog for Phase 110
- if extracted/shared, preserve ordering `active -> canceling -> paused -> past due -> canceled`

### Rendered HTML assertions over helper-unit tests
**Sources:** [accrue_portal/test/accrue_portal/live/subscription_live_test.exs](/Users/jon/projects/accrue/accrue_portal/test/accrue_portal/live/subscription_live_test.exs:24), [accrue_admin/test/accrue_admin/live/subscription_live_test.exs](/Users/jon/projects/accrue/accrue_admin/test/accrue_admin/live/subscription_live_test.exs:86)

Apply to UI verification:
- assert user-visible copy in rendered HTML
- then assert the row mutation (`cancel_at_period_end`, canceled predicate, etc.)

## Slice Boundaries The Patterns Suggest

1. **Core lifecycle SSOT + guide slice**
   Use `Subscription`, `Query`, and `SubscriptionActions` as truth anchors; create the canonical lifecycle guide and a docs contract test.

2. **Portal copy + shared customer lifecycle summary slice**
   Start in `AccruePortal.Copy`, then update `subscription_live.ex` and `subscriptions_live.ex` together so list/detail cannot drift.

3. **Admin/operator lifecycle clarity slice**
   Extend `AccrueAdmin.Copy.Subscription` and `AccrueAdmin.Live.SubscriptionLive` using the existing predicate-summary pattern and provider-honest action helper text.

4. **Example-host alignment slice**
   Reconcile `examples/accrue_host/.../subscription_live.ex` with the new semantics, especially if it remains an immediate-cancel example.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `accrue/guides/<new lifecycle SSOT guide>.md` | docs | canonical contract | No existing guide is already the cross-provider lifecycle glossary SSOT; closest matches are Stripe cancellation-timing guidance and Braintree local-portal contract guidance. |

## Metadata

**Analog search scope:** `accrue/lib/accrue/billing`, `accrue/guides`, `accrue_portal/lib`, `accrue_admin/lib`, `examples/accrue_host/lib`, `accrue/test`, `accrue_portal/test`, `accrue_admin/test`, `.planning/milestones/v1.35-phases/109-support-contract-truth`

**Phase-109 carry-forward:** docs truth should move as one recommendation package first, then copy/UI mirrors, then verifier tests.

**Pattern extraction date:** 2026-05-06
