# Phase 96: chosen-second-provider-thin-slice - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 22
**Analogs found:** 20 / 22

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/mix.exs` | config | batch | `accrue/mix.exs` | exact |
| `accrue/lib/accrue/processor/braintree.ex` | service | request-response | `accrue/lib/accrue/processor/stripe.ex` | exact |
| `accrue/lib/accrue/processor.ex` | service | request-response | `accrue/lib/accrue/processor.ex` | exact |
| `accrue/lib/accrue/processor/capabilities.ex` | utility | transform | `accrue/lib/accrue/processor/capabilities.ex` | exact |
| `accrue/lib/accrue/billing/subscription_actions.ex` | service | CRUD | `accrue/lib/accrue/billing/subscription_actions.ex` | exact |
| `accrue/lib/accrue/billing/subscription_projection.ex` | utility | transform | `accrue/lib/accrue/billing/subscription_projection.ex` | exact |
| `accrue/lib/accrue/billing/invoice_projection.ex` | utility | transform | `accrue/lib/accrue/billing/invoice_projection.ex` | exact |
| `accrue/lib/accrue/webhook/signature.ex` | middleware | request-response | `accrue/lib/accrue/webhook/signature.ex` | exact |
| `accrue/lib/accrue/webhook/plug.ex` | middleware | request-response | `accrue/lib/accrue/webhook/plug.ex` | exact |
| `accrue/lib/accrue/webhook/default_handler.ex` | service | event-driven | `accrue/lib/accrue/webhook/default_handler.ex` | exact |
| `examples/accrue_host/lib/accrue_host/billing.ex` | service | request-response | `examples/accrue_host/lib/accrue_host/billing.ex` | exact |
| `accrue/priv/accrue/templates/install/billing.ex.eex` | template | request-response | `examples/accrue_host/lib/accrue_host/billing.ex` | role-match |
| `examples/accrue_host/test/accrue_host/billing_facade_test.exs` | test | request-response | `examples/accrue_host/test/accrue_host/billing_facade_test.exs` | exact |
| `.planning/processor-support-matrix.md` | config | transform | `.planning/processor-support-matrix.md` | exact |
| `examples/accrue_host/README.md` | config | transform | `examples/accrue_host/README.md` | exact |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | config | transform | `examples/accrue_host/docs/adoption-proof-matrix.md` | exact |
| `accrue/README.md` | config | transform | `accrue/README.md` | exact |
| `accrue/guides/custom_processors.md` | config | transform | `accrue/guides/custom_processors.md` | exact |
| `scripts/ci/verify_processor_support_matrix.sh` | test | batch | `scripts/ci/verify_processor_support_matrix.sh` | exact |
| `scripts/ci/verify_adoption_proof_matrix.sh` | test | batch | `scripts/ci/verify_adoption_proof_matrix.sh` | exact |
| `examples/accrue_host/lib/accrue_host/braintree.ex` | service | request-response | — | no analog |
| `examples/accrue_host/assets/js/braintree_vault_acquisition.js` | utility | request-response | — | no analog |

## Pattern Assignments

### `accrue/lib/accrue/processor/braintree.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/processor/stripe.ex`

**Imports + behaviour pattern** from `accrue/lib/accrue/processor/stripe.ex:60-64`:
```elixir
@behaviour Accrue.Processor

alias Accrue.Processor.Stripe.ErrorMapper
alias Accrue.Telemetry
```

**Capabilities declaration** from `accrue/lib/accrue/processor/stripe.ex:75-99` and `accrue/lib/accrue/processor/fake.ex:219-240`:
```elixir
@impl Accrue.Processor
def capabilities do
  %{
    customer: %{create: true, retrieve: true, update: true},
    payment_method: %{vault_acquisition: true},
    subscription: %{
      direct_create: true,
      fetch: true,
      cancel: true,
      lifecycle_webhook_projection: true
    },
    invoice: %{lifecycle_webhook_projection: true},
    webhook: %{verify: true, parse: true}
  }
end
```

**Core adapter callback pattern** from `accrue/lib/accrue/processor/stripe.ex:165-174`:
```elixir
@impl Accrue.Processor
def create_subscription(params, opts) when is_map(params) and is_list(opts) do
  client = build_client!(opts)
  params = ensure_expand(params, ["latest_invoice.payment_intent"])
  stripe_opts = stripe_opts(:create_subscription, subject_of(params, "sub"), opts)

  client
  |> LatticeStripe.Subscription.create(stringify_keys(params), stripe_opts)
  |> translate_resource()
end
```

**Naming pattern** from `accrue/lib/accrue/processor/stripe.ex:75-76` and `accrue/lib/accrue/processor/fake.ex:217-217`:
```elixir
@impl Accrue.Processor
def processor_name, do: "stripe"
```

Use the same structure for `processor_name/0`, `capabilities/0`, `create_subscription/2`, `retrieve_subscription/2`, `fetch/2`, and translation helpers. Keep provider SDK calls isolated to this module.

---

### `accrue/lib/accrue/billing/subscription_actions.ex` (service, CRUD)

**Analog:** `accrue/lib/accrue/billing/subscription_actions.ex`

**Facade-to-customer-to-core flow** from `accrue/lib/accrue/billing/subscription_actions.ex:85-112`:
```elixir
def subscribe(%Customer{} = customer, price_spec, opts) do
  do_subscribe(customer, price_spec, opts)
end

def subscribe(billable, price_spec, opts) do
  with {:ok, customer} <- Accrue.Billing.customer(billable) do
    do_subscribe(customer, price_spec, opts)
  end
end

defp do_subscribe(%Customer{} = customer, price_spec, opts) do
  with :ok <- ensure_subscribe_support() do
    do_subscribe_supported(customer, price_spec, opts)
  end
end
```

**Capability gate pattern** from `accrue/lib/accrue/billing/subscription_actions.ex:144-154`:
```elixir
defp ensure_subscribe_support do
  if Processor.first_party_supported?([:subscription, :direct_create]) do
    :ok
  else
    {:error,
     %Accrue.APIError{
       code: "processor_operation_unsupported",
       message: "#{Processor.name()} does not support subscription creation"
     }}
  end
end
```

**Transactional write + projection pattern** from `accrue/lib/accrue/billing/subscription_actions.ex:114-141`:
```elixir
{price_id, quantity} = normalize_price_spec(price_spec)
op_id = resolve_operation_id(opts)
idem_key = Idempotency.key(:create_subscription, customer.id, op_id)

{item_params, trial_end} = build_subscribe_params({price_id, quantity}, opts)
processor_params = build_subscription_request(customer, item_params, trial_end, opts)

result =
  Repo.transact(fn ->
    with :ok <- ensure_customer_tax_location(customer, opts),
         {:ok, stripe_sub} <-
           Processor.__impl__().create_subscription(
             processor_params,
             [idempotency_key: idem_key] ++ sanitize_opts(opts)
           ),
         {:ok, attrs} <- SubscriptionProjection.decompose(stripe_sub),
         {:ok, sub} <- insert_subscription(customer.id, attrs),
         {:ok, _items} <- upsert_items(sub, stripe_sub),
         {:ok, _} <- record_event("subscription.created", sub, %{price_id: price_id}) do
      sub = Repo.preload(sub, :subscription_items, force: true)
      {:ok, sub}
    end
  end)

IntentResult.wrap(result)
```

**Request assembly seam** from `accrue/lib/accrue/billing/subscription_actions.ex:156-170`:
```elixir
defp build_subscription_request(%Customer{} = customer, item_params, trial_end, opts) do
  %{
    customer: customer.processor_id,
    items: [item_params],
    payment_behavior: "default_incomplete",
    expand: ["latest_invoice.payment_intent"]
  }
  |> put_if(:trial_end, trial_end)
  |> maybe_put_automatic_tax(opts)
  |> maybe_put_default_pm(opts)
  |> maybe_put_coupon(opts)
  |> maybe_put_collection_method(opts)
end
```

Phase 96 should keep this seam narrow. Put Braintree branching here or just above it, not across the public `subscribe/3` surface.

---

### `accrue/lib/accrue/billing/subscription_projection.ex` (utility, transform)

**Analog:** `accrue/lib/accrue/billing/subscription_projection.ex`

**Processor branch pattern** from `accrue/lib/accrue/billing/subscription_projection.ex:18-28`:
```elixir
@spec decompose(map(), keyword()) :: {:ok, map()}
def decompose(subscription, opts \\ [])

def decompose(subscription, opts) when is_map(subscription) and is_list(opts) do
  processor = Keyword.get(opts, :processor, processor_atom())

  case processor do
    :paddle -> {:ok, paddle_attrs(subscription)}
    _ -> {:ok, stripe_attrs(subscription)}
  end
end
```

**Normalized attrs pattern** from `accrue/lib/accrue/billing/subscription_projection.ex:30-52`:
```elixir
%{
  processor_id: get(stripe_sub, :id),
  status: parse_status(get(stripe_sub, :status)),
  cancel_at_period_end: get(stripe_sub, :cancel_at_period_end) || false,
  current_period_start: unix_to_dt(get(stripe_sub, :current_period_start)),
  current_period_end: unix_to_dt(get(stripe_sub, :current_period_end)),
  data: normalize_data(stripe_sub),
  metadata: get(stripe_sub, :metadata) || %{}
}
```

**Shared map access + JSON-safe persistence** from `accrue/lib/accrue/billing/subscription_projection.ex:92-99` and `145-200`:
```elixir
def get(map, key) when is_atom(key) do
  Map.get(map, key) || Map.get(map, Atom.to_string(key))
end

defp normalize_data(map) when is_map(map) do
  map
  |> to_string_keys()
end
```

Add a `:braintree` branch here instead of leaking provider-specific field parsing into reducers.

---

### `accrue/lib/accrue/billing/invoice_projection.ex` (utility, transform)

**Analog:** `accrue/lib/accrue/billing/invoice_projection.ex`

**Cross-projection reuse pattern** from `accrue/lib/accrue/billing/invoice_projection.ex:19-19` and `27-35`:
```elixir
alias Accrue.Billing.SubscriptionProjection

currency = SubscriptionProjection.get(stripe_inv, :currency)
status_transitions = SubscriptionProjection.get(stripe_inv, :status_transitions) || %{}
```

**Invoice decompose pattern** from `accrue/lib/accrue/billing/invoice_projection.ex:58-105`:
```elixir
invoice_attrs = %{
  processor_id: SubscriptionProjection.get(stripe_inv, :id),
  status: parse_status(SubscriptionProjection.get(stripe_inv, :status)),
  total_minor: SubscriptionProjection.get(stripe_inv, :total),
  amount_due_minor: SubscriptionProjection.get(stripe_inv, :amount_due),
  hosted_url:
    SubscriptionProjection.get(stripe_inv, :hosted_invoice_url) ||
      SubscriptionProjection.get(stripe_inv, :hosted_url),
  data: SubscriptionProjection.to_string_keys(stripe_inv),
  metadata: SubscriptionProjection.get(stripe_inv, :metadata) || %{}
}
```

**Item extraction pattern** from `accrue/lib/accrue/billing/invoice_projection.ex:108-135`:
```elixir
item_attrs =
  stripe_inv
  |> SubscriptionProjection.get(:lines)
  |> case do
    nil -> []
    %{} = m -> SubscriptionProjection.get(m, :data) || []
    list when is_list(list) -> list
  end
  |> Enum.map(fn line ->
    %{
      stripe_id: SubscriptionProjection.get(line, :id),
      amount_minor: SubscriptionProjection.get(line, :amount),
      data: line
    }
  end)
```

Use the same normalize-then-return-plain-maps shape for Braintree invoice webhook payloads if the thin slice needs invoice projection.

---

### `accrue/lib/accrue/webhook/signature.ex` (middleware, request-response)

**Analog:** `accrue/lib/accrue/webhook/signature.ex`

**Thin SDK wrapper pattern** from `accrue/lib/accrue/webhook/signature.ex:24-33`:
```elixir
@spec verify!(binary(), String.t() | nil, String.t() | [String.t()], keyword()) ::
        LatticeStripe.Event.t()
def verify!(raw_body, sig_header, secrets, opts \\ []) do
  tolerance = Keyword.get(opts, :tolerance, 300)

  LatticeStripe.Webhook.construct_event!(raw_body, sig_header, secrets, tolerance: tolerance)
rescue
  e in LatticeStripe.Webhook.SignatureVerificationError ->
    reraise Accrue.SignatureError, [reason: Exception.message(e)], __STACKTRACE__
end
```

Keep Phase 96 verification/parsing logic inside the signature seam. Add Braintree parse/verify functions here rather than branching inside callers.

---

### `accrue/lib/accrue/webhook/plug.ex` (middleware, request-response)

**Analog:** `accrue/lib/accrue/webhook/plug.ex`

**Telemetry-wrapped ingress pattern** from `accrue/lib/accrue/webhook/plug.ex:35-46`:
```elixir
processor = Keyword.fetch!(opts, :processor)
endpoint = Keyword.get(opts, :endpoint)

:telemetry.span(
  [:accrue, :webhook, :receive],
  %{processor: processor, endpoint: endpoint},
  fn ->
    result = do_call(conn, processor, endpoint)
    {result, %{processor: processor, endpoint: endpoint}}
  end
)
```

**Fail-closed error handling** from `accrue/lib/accrue/webhook/plug.ex:47-60`:
```elixir
rescue
  e in Accrue.SignatureError ->
    Logger.warning("Webhook signature verification failed: #{e.reason}")

    conn
    |> send_resp(400, Jason.encode!(%{error: "signature_verification_failed"}))
    |> halt()
```

**Signature resolution + ingest handoff** from `accrue/lib/accrue/webhook/plug.ex:63-78`:
```elixir
raw_body = flatten_raw_body(conn)
sig_header = get_req_header(conn, "stripe-signature") |> List.first()

unless sig_header do
  raise Accrue.SignatureError, reason: "missing stripe-signature header"
end

secrets = resolve_secrets!(endpoint, processor)
stripe_event = Signature.verify!(raw_body, sig_header, secrets)
Accrue.Webhook.Ingest.run(conn, processor, stripe_event, raw_body, endpoint)
```

Phase 96 should keep the same plug contract but branch by `processor` before signature parsing. Do not bypass `flatten_raw_body/1` or the telemetry wrapper.

---

### `accrue/lib/accrue/webhook/default_handler.ex` (service, event-driven)

**Analog:** `accrue/lib/accrue/webhook/default_handler.ex`

**Subscription reducer pattern** from `accrue/lib/accrue/webhook/default_handler.ex:342-368`:
```elixir
reduce_row(:subscription, stripe_id, evt_ts, evt_id, fn row ->
  with {:ok, canonical} <- Processor.__impl__().fetch(:subscription, stripe_id),
       {:ok, attrs} <- SubscriptionProjection.decompose(canonical),
       attrs <- stamp_watermark(attrs, evt_ts, evt_id),
       {:ok, upsert_result} <- upsert_subscription(row, canonical, attrs) do
    case upsert_result do
      :deferred -> {:ok, :deferred}
      %Subscription{} = updated ->
        with {:ok, _} <- upsert_subscription_items(updated, canonical),
             {:ok, _} <- record_event(subscription_event_type(action), "Subscription", updated.id, evt_id) do
          {:ok, updated}
        end
    end
  end
end)
```

**Invoice reducer pattern** from `accrue/lib/accrue/webhook/default_handler.ex:556-575`:
```elixir
reduce_row(:invoice, stripe_id, evt_ts, evt_id, fn row ->
  with {:ok, canonical} <- Processor.__impl__().fetch(:invoice, stripe_id),
       {:ok, %{invoice_attrs: attrs, item_attrs: item_attrs}} <- InvoiceProjection.decompose(canonical),
       attrs <- stamp_watermark(attrs, evt_ts, evt_id),
       {:ok, upsert_result} <- upsert_invoice(row, canonical, attrs) do
    case upsert_result do
      :deferred -> {:ok, :deferred}
      %Invoice{} = updated ->
        with {:ok, _} <- upsert_invoice_items(updated, item_attrs),
             {:ok, _} <- record_event("invoice." <> action, "Invoice", updated.id, evt_id) do
          {:ok, updated}
        end
    end
  end
end)
```

**Event recording + processor naming** from `accrue/lib/accrue/webhook/default_handler.ex:983-999`:
```elixir
Events.record(%{
  type: type,
  subject_type: subject_type,
  subject_id: subject_id,
  data: %{source: "webhook", stripe_event_id: stripe_event_id}
})

case Processor.__impl__() do
  Accrue.Processor.Fake -> "fake"
  Accrue.Processor.Stripe -> "stripe"
  other -> other |> Module.split() |> List.last() |> String.downcase()
end
```

Keep webhook reducers canonical-refetch-first. Do not project directly from untrusted webhook payloads.

---

### `examples/accrue_host/lib/accrue_host/billing.ex` (service, request-response)

**Analog:** `examples/accrue_host/lib/accrue_host/billing.ex`

**Thin facade pattern** from `examples/accrue_host/lib/accrue_host/billing.ex:20-37`:
```elixir
def subscribe(billable, price_id, opts \\ []) do
  Billing.subscribe(billable, price_id, opts)
end

def customer_for(billable) do
  Billing.customer(billable)
end
```

**Host policy + scope gating pattern** from `examples/accrue_host/lib/accrue_host/billing.ex:82-99`:
```elixir
def subscribe_active_organization(%Scope{} = scope, price_id, opts \\ []) do
  with {:ok, organization} <- organization_from_scope(scope),
       :ok <- authorize_billing_mutation(scope) do
    subscribe(organization, price_id, opts)
  end
end
```

**Local ownership lookup pattern** from `examples/accrue_host/lib/accrue_host/billing.ex:122-143`:
```elixir
defp find_customer(%{__struct__: mod, id: id}) do
  billable_type = mod.__accrue__(:billable_type)
  owner_id = to_string(id)

  from(customer in Customer,
    where: customer.owner_type == ^billable_type and customer.owner_id == ^owner_id,
    limit: 1
  )
  |> Repo.one()
end
```

If Phase 96 adds a host-owned Braintree preparatory helper, keep it beside this facade as a host seam, not inside `Accrue.Billing`.

---

### `accrue/priv/accrue/templates/install/billing.ex.eex` (template, request-response)

**Analog:** `examples/accrue_host/lib/accrue_host/billing.ex`

**Template module skeleton** from `accrue/priv/accrue/templates/install/billing.ex.eex:1-28`:
```elixir
defmodule <%= @billing_context %> do
  @moduledoc """
  Host-owned billing facade generated by `mix accrue.install`.

  Keep host policy hooks here and leave processor normalization to Accrue.
  """

  alias Accrue.Billing

  def subscribe(billable, price_id, opts \\ []) do
    Billing.subscribe(billable, price_id, opts)
  end
end
```

Use the checked-in host module as the richer analog; keep the installer template thinner and generic.

---

### `examples/accrue_host/test/accrue_host/billing_facade_test.exs` (test, request-response)

**Analog:** `examples/accrue_host/test/accrue_host/billing_facade_test.exs`

**Public API export proof** from `examples/accrue_host/test/accrue_host/billing_facade_test.exs:41-52`:
```elixir
exports = Billing.__info__(:functions)

assert {:subscribe, 2} in exports
assert {:subscribe, 3} in exports
assert {:customer_for, 1} in exports
assert {:billing_state_for, 1} in exports
```

**Facade round-trip proof** from `examples/accrue_host/test/accrue_host/billing_facade_test.exs:64-80`:
```elixir
assert {:ok, %Subscription{} = subscription} =
         Billing.subscribe(user, "price_basic", trial_end: {:days, 14})

subscription = Repo.preload(subscription, :subscription_items)
assert subscription.processor == "fake"
assert subscription.status == :trialing
```

**Source-stays-thin proof** from `examples/accrue_host/test/accrue_host/billing_facade_test.exs:200-220`:
```elixir
billing_source = File.read!(Path.join(@host_root, "lib/accrue_host/billing.ex"))

assert billing_source =~ "alias Accrue.Billing"
assert billing_source =~ "Billing.subscribe(billable, price_id, opts)"
assert billing_source =~ "Billing.customer(billable)"
```

Use this pattern for any Braintree host-proof: assert through the facade, not via direct provider SDK fixtures.

---

### `.planning/processor-support-matrix.md` (config, transform)

**Analog:** `.planning/processor-support-matrix.md`

**Framing and lane language** from `.planning/processor-support-matrix.md:3-14`:
```markdown
This matrix answers: **what does Accrue mean by official multi-processor support, and where does that promise stop?**

Accrue intentionally splits processor truth into a **deterministic Fake-first lane** and **provider-backed fidelity lanes**.
```

**Capability table pattern** from `.planning/processor-support-matrix.md:29-44`:
```markdown
| Capability | Fake | Stripe | Braintree | Public label |
| subscription.direct_create | Required | Required | Required target | all first-party |
| checkout.hosted_handoff | Local proof helper | Supported | No | Stripe-only |
```

**Public facade mapping pattern** from `.planning/processor-support-matrix.md:49-60`:
```markdown
| `Accrue.Billing.subscribe/3` | all first-party | Primary gateway-subscription-core facade for the second-provider slice. |
| `Accrue.Billing.create_checkout_session/2` | Stripe-only | Valuable public API, but not part of the first official second-provider promise. |
```

Keep all public-positioning edits matrix-led, then mirror them into READMEs/docs.

---

### `examples/accrue_host/README.md` and `examples/accrue_host/docs/adoption-proof-matrix.md` (config, transform)

**Analogs:** `examples/accrue_host/README.md`, `examples/accrue_host/docs/adoption-proof-matrix.md`

**README observability bullets** from `examples/accrue_host/README.md:89-104`:
```markdown
- **Billing checkout facade:** `Accrue.Billing.create_checkout_session/2` emits **`[:accrue, :billing, :checkout_session, :create]`**
- **Billing portal facade:** `Accrue.Billing.create_billing_portal_session/2` emits **`[:accrue, :billing, :billing_portal, :create]`**
```

**README proof-lane wording** from `examples/accrue_host/README.md:99-118`:
```markdown
Pull requests are merge-blocked on GitHub Actions jobs `docs-contracts-shift-left` and `host-integration`...
Use `mix verify` for a faster bounded Fake slice that is not CI-complete.
```

**Adoption matrix layering pattern** from `examples/accrue_host/docs/adoption-proof-matrix.md:8-28`:
```markdown
**Layer B (local Fake-backed proof):** running `mix verify` or `mix verify.full`...
**Layer C (merge-blocking `docs-contracts-shift-left` + `host-integration`):**
```

**Adoption matrix concern/proof rows** from `examples/accrue_host/docs/adoption-proof-matrix.md:16-25`:
```markdown
| User-as-billable **API** (B2C-shaped host facade) | `billing_facade_test.exs` (`Billing.subscribe(user, …)`, `owner_type == "User"`) | Bounded `mix verify` slice |
```

When adding Braintree wording, keep it explicit about slice, lane, and advisory-vs-blocking status.

---

### `accrue/README.md`, `accrue/guides/custom_processors.md`, and verifier scripts (config/test)

**Analogs:** `accrue/README.md`, `accrue/guides/custom_processors.md`, `scripts/ci/verify_processor_support_matrix.sh`, `scripts/ci/verify_adoption_proof_matrix.sh`

**Package README support-surface pattern** from `accrue/README.md:54-67`:
```markdown
- Billing domain: customers, subscriptions, invoices, charges, refunds, coupons, promotion codes, metered usage.
- Money paths: Checkout, billing portal, Connect helpers behind one processor contract (Stripe in production, Fake in test).
```

**Custom processor boundary wording** from `accrue/guides/custom_processors.md:12-15`:
```markdown
Custom adapters are also **outside first-party support** unless Accrue names
them in the official processor-support matrix.
```

**Matrix verifier pattern** from `scripts/ci/verify_processor_support_matrix.sh:22-42`:
```bash
require_substring "| Capability | Fake | Stripe | Braintree | Public label |" "matrix header"
require_substring "gateway subscription core" "official capability slice"
require_substring "Stripe-only" "stripe-only support label"
```

**Adoption-proof verifier pattern** from `scripts/ci/verify_adoption_proof_matrix.sh:22-47`:
```bash
require_substring "**Layer B (local Fake-backed proof):**" "Layer B label"
require_substring "Accrue.Billing.create_checkout_session/2" "checkout facade API in matrix"
require_substring 'linked `1.0.0` pair' "linked 1.0.0 pair proof needle"
```

Any doc wording changes should update the matching verifier in the same slice.

## Shared Patterns

### Processor capability gates
**Sources:** `accrue/lib/accrue/processor.ex:372-412`, `accrue/lib/accrue/processor/capabilities.ex:10-88`

Apply to all first-party processor-dependent paths:
```elixir
def capabilities do
  Accrue.Processor.Capabilities.for(__impl__())
end

def supports?(path) when is_list(path),
  do: Accrue.Processor.Capabilities.supports?(capabilities(), path)

def first_party_supported?(path) when is_list(path),
  do: Accrue.Processor.Capabilities.first_party_supported?(capabilities(), path)
```

### Transactional write + event recording
**Sources:** `accrue/lib/accrue/billing/subscription_actions.ex:123-141`, `accrue/lib/accrue/webhook/default_handler.ex:983-990`

Apply to all subscription/webhook persistence changes:
```elixir
Repo.transact(fn ->
  ...
  {:ok, _} <- record_event("subscription.created", sub, %{price_id: price_id})
end)
```

### Projection-first normalization
**Sources:** `accrue/lib/accrue/billing/subscription_projection.ex:21-27`, `accrue/lib/accrue/billing/invoice_projection.ex:58-135`

Apply to provider payload handling:
```elixir
{:ok, attrs} <- SubscriptionProjection.decompose(canonical)
{:ok, %{invoice_attrs: attrs, item_attrs: item_attrs}} <- InvoiceProjection.decompose(canonical)
```

### Host-owned seam, Accrue-owned normalization
**Sources:** `examples/accrue_host/lib/accrue_host/billing.ex:20-22`, `accrue/priv/accrue/templates/install/billing.ex.eex:10-28`

Apply to any Braintree preparatory helper:
```elixir
def subscribe(billable, price_id, opts \\ []) do
  Billing.subscribe(billable, price_id, opts)
end
```

Keep browser tokenization/client-token exchange in the host app. Keep processor request shaping in `Accrue.Processor.Braintree`.

### Docs + verifier co-update discipline
**Sources:** `scripts/ci/verify_processor_support_matrix.sh:22-42`, `scripts/ci/verify_adoption_proof_matrix.sh:22-47`, `scripts/ci/verify_package_docs.sh:159-185`

Apply to all matrix/README copy edits:
```bash
require_substring "Braintree" "locked target provider"
require_substring "Accrue.Billing.create_checkout_session/2" "checkout facade API in matrix"
require_fixed "$ROOT_DIR/accrue/guides/custom_processors.md" "outside first-party support"
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `examples/accrue_host/lib/accrue_host/braintree.ex` | service | request-response | No existing provider-specific host helper module; current host seams are provider-neutral facade wrappers only. |
| `examples/accrue_host/assets/js/braintree_vault_acquisition.js` | utility | request-response | No existing processor-owned browser tokenization/client-token asset path in the repo; Phase 96 will need a fresh host-owned pattern. |

## Metadata

**Analog search scope:** `accrue/lib/accrue`, `accrue/test/accrue`, `examples/accrue_host`, `scripts/ci`, `.planning`

**Files scanned:** 30+

**Pattern extraction date:** 2026-04-29
