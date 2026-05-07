# Phase 112: Customer Update Contract Closure - Pattern Map

**Mapped:** 2026-05-06  
**Files analyzed:** 13  
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/billing.ex` | facade | request-response | same file | exact |
| `accrue/lib/accrue/processor/capabilities.ex` | support-ssot | canonical contract | same file | exact |
| `.planning/processor-support-matrix.md` | planning mirror | canonical contract | same file | exact |
| `accrue/lib/accrue/processor/fake.ex` | adapter | request-response | same file | exact |
| `accrue/lib/accrue/processor/stripe.ex` | adapter | request-response | same file | exact |
| `accrue/lib/accrue/processor/braintree.ex` | adapter | request-response | same file | exact |
| `accrue/test/accrue/processor/capabilities_test.exs` | contract gate | verifier | same file | exact |
| `accrue/test/accrue/billing/events_transaction_test.exs` | runtime proof | transaction + projection | same file | exact |
| `accrue/test/accrue/processor/fake_test.exs` | runtime proof | deterministic adapter semantics | same file | exact |
| `accrue/test/accrue/processor/braintree_test.exs` | adapter proof | gateway stub truth | same file | exact |
| `examples/accrue_host/lib/accrue_host/billing.ex` | host facade | request-response | same file | exact |
| `examples/accrue_host/test/accrue_host/billing_facade_test.exs` | host proof | facade delegation | same file | exact |
| `accrue/priv/accrue/templates/install/billing.ex.eex` | template | generator output | same file | exact |

## Pattern Assignments

### `accrue/lib/accrue/billing.ex` (facade, request-response)

**Analog:** `accrue/lib/accrue/billing.ex`

**Remote write-through precedent** (lines 877-905):
```elixir
def update_customer_tax_location(%Customer{} = customer, attrs) when is_map(attrs) do
  span_billing(:customer, :tax_location_update, customer, [], fn ->
    Repo.transact(fn ->
      with {:ok, processor_result} <-
             Processor.update_customer(
               customer.processor_id,
               processor_tax_location_attrs(attrs),
               []
             ),
           customer_attrs = customer_projection_attrs(processor_result),
           {:ok, updated} <-
             customer |> Customer.changeset(customer_attrs) |> Repo.update(),
           {:ok, _event} <-
             Events.record(%{
               type: "customer.tax_location_updated",
               subject_type: "Customer",
               subject_id: updated.id,
               data: %{
                 processor: updated.processor,
                 processor_id: updated.processor_id,
                 validate_location: "immediately",
                 changed_fields: tax_location_field_names(attrs)
               }
             }) do
        {:ok, updated}
      end
    end)
  end)
end
```

**Current local-only seam to replace or split** (lines 925-956):
```elixir
@doc """
Updates a `Customer` with the given attributes.
...
"""
@spec update_customer(%Customer{}, map()) :: {:ok, Customer.t()} | {:error, term()}
def update_customer(%Customer{} = customer, attrs) when is_map(attrs) do
  span_billing(:customer, :update, customer, [], fn ->
    Repo.transact(fn ->
      with {:ok, updated} <- customer |> Customer.changeset(attrs) |> Repo.update(),
           {:ok, _event} <-
             Events.record(%{
               type: "customer.updated",
               subject_type: "Customer",
               subject_id: updated.id,
               data: %{
                 changes:
                   Map.take(attrs, [:metadata, :name, :email, "metadata", "name", "email"])
               }
             }) do
        {:ok, updated}
      end
    end)
  end)
end
```

**Projection sanitization pattern** (lines 1000-1020):
```elixir
defp customer_projection_attrs(processor_result) when is_map(processor_result) do
  %{
    name: Map.get(processor_result, :name),
    email: Map.get(processor_result, :email),
    metadata: Map.get(processor_result, :metadata, %{}),
    data: sanitize_customer_data(processor_result)
  }
end

defp sanitize_customer_data(processor_result) when is_map(processor_result) do
  Map.drop(processor_result, [
    :address,
    :shipping,
    :phone,
    :tax,
    "address",
    "shipping",
    "phone",
    "tax"
  ])
end
```

**Planner implication:** Phase 112 should copy the `update_customer_tax_location/2` execution shape for the promoted facade row, not the old local-only `update_customer/2` body. If a separate local-only API lands, it should preserve the current changeset-plus-event pattern under a new explicit name rather than mixing both meanings into one function.

---

### `accrue/lib/accrue/processor/capabilities.ex` and `.planning/processor-support-matrix.md` (support SSOT, canonical contract)

**Analogs:** same files

**Runtime label SSOT** (`accrue/lib/accrue/processor/capabilities.ex`, lines 11-16):
```elixir
@support_labels %{
  customer: %{
    create: "all first-party",
    retrieve: "all first-party",
    update: "staged first-party target"
  },
```

**First-party gate rule** (`accrue/lib/accrue/processor/capabilities.ex`, lines 86-93):
```elixir
def first_party_supported?(capabilities, path)
    when is_map(capabilities) and is_list(path) do
  support_label(path) == "all first-party" and supports?(capabilities, path)
end
```

**Planning/public mirror row** (`.planning/processor-support-matrix.md`, current row):
```markdown
| customer.update | Supported | Supported | Staged target | staged first-party target |
...
| `Accrue.Billing.update_customer/2` | staged first-party target | Existing behavior remains, but this row is not yet part of the merge-blocking thin slice. |
```

**Planner implication:** keep the runtime label change and any matrix-row wording change in the same plan if Phase 112 promotes the row publicly now. Do not widen this to cancellation rows; Phase 113 owns those labels.

---

### `accrue/lib/accrue/processor/fake.ex`, `stripe.ex`, and `braintree.ex` (adapters, request-response)

**Analogs:** same files

**Fake capability and callback seam** (`fake.ex`, lines 220-250):
```elixir
%{
  customer: %{create: true, retrieve: true, update: true},
  ...
}

def update_customer(id, params, opts \\ [])
    when is_binary(id) and is_map(params) and is_list(opts) do
  call({:update_customer, id, params, opts})
end
```

**Stripe truth pattern** (`stripe.ex`, lines 139-157):
```elixir
def update_customer(id, params, opts)
    when is_binary(id) and is_map(params) and is_list(opts) do
  Telemetry.span(
    [:accrue, :processor, :customer, :update],
    %{adapter: :stripe, operation: :update_customer},
    fn ->
      client = build_client!(opts)
      idem_key = compute_idempotency_key(:update_customer, id, opts)

      stripe_opts =
        opts
        |> Keyword.put(:idempotency_key, idem_key)
        |> Keyword.put(:stripe_version, resolve_api_version(opts))

      client
      |> LatticeStripe.Customer.update(id, stringify_keys(params), stripe_opts)
      |> translate_customer()
    end
  )
end
```

**Braintree truth pattern** (`braintree.ex`, lines 114-120 and 625-669):
```elixir
def update_customer(id, params, opts)
    when is_binary(id) and is_map(params) and is_list(opts) do
  case customer_gateway().update(id, translate_customer_params(params), opts) do
    {:ok, customer} -> {:ok, translate_customer(customer)}
    {:error, raw} -> {:error, to_accrue_error(raw)}
  end
end
```

```elixir
defp translate_customer(customer) do
  %{
    id: Map.get(customer, :id),
    name: customer_name(customer),
    email: Map.get(customer, :email),
    metadata: Map.get(customer, :custom_fields, %{})
  }
end

defp translate_customer_params(params) do
  params
  |> stringify_keys()
  |> maybe_move_name_to_company()
end
```

**Planner implication:** the adapters already prove the narrow shared fields are feasible. Phase 112 should keep the shared facade contract bounded to what the translated return maps already round-trip cleanly: `name`, `email`, and flat `metadata`. Do not reopen nested payment-method or tax-location semantics through this generic row.

---

### `accrue/test/accrue/processor/capabilities_test.exs` (contract gate, verifier)

**Analog:** same file

**Current staged-row assertion pattern** (lines 57-76):
```elixir
test "known adapters report the staged contract rows explicitly" do
  stripe_caps = Capabilities.for(Accrue.Processor.Stripe)
  braintree_caps = Capabilities.for(Accrue.Processor.Braintree)
  ...
  assert Capabilities.support_label([:subscription, :update]) == "staged first-party target"

  assert Capabilities.support_label([:subscription, :cancel_immediately]) ==
           "staged first-party target"
end
```

**Planner implication:** add the promoted `customer.update` assertion here instead of inventing a new contract-test module. Keep the staged cancellation assertions intact so Phase 112 does not steal Phase 113’s work.

---

### `accrue/test/accrue/billing/events_transaction_test.exs` (runtime proof, transaction + projection)

**Analog:** same file

**Current update-customer validation seam** (lines 113-138):
```elixir
describe "update_customer/2 metadata validation" do
  test "nested map in metadata raises validation error" do
    user = test_user()
    {:ok, customer} = Billing.create_customer(user)

    result = Billing.update_customer(customer, %{metadata: %{"key" => %{"nested" => "bad"}}})

    assert {:error, changeset} = result
    assert %Ecto.Changeset{} = changeset
    assert changeset.errors[:metadata]
  end
```

**Transactional rollback proof pattern** (lines 90-105):
```elixir
result =
  Accrue.Repo.transaction(fn ->
    {:ok, customer} = Billing.create_customer(user)
    ...
    Accrue.Repo.repo().rollback(:test_rollback)
  end)

assert {:error, :test_rollback} = result
```

**Planner implication:** extend this file for Phase 112 semantic proofs: accepted attr subset, unsupported attr rejection, projection sanitization, and `customer.updated` event meaning. Keep it as the transactional/event SSOT rather than moving that proof into adapter tests.

---

### `accrue/test/accrue/processor/fake_test.exs` and `braintree_test.exs` (adapter proofs)

**Analogs:** same files

**Deterministic Fake update proof** (`fake_test.exs`, lines 58-89):
```elixir
describe "update_customer/3" do
  test "merges new params into the stored customer" do
    {:ok, %{id: id}} = Processor.create_customer(%{email: "a@b", name: "Old"}, [])

    assert {:ok, %{id: ^id, name: "New", email: "a@b"}} =
             Processor.update_customer(id, %{name: "New"}, [])
```

**Immediate-validation error precedent** (`fake_test.exs`, lines 73-89):
```elixir
assert {:error, %Accrue.APIError{} = error} =
         Processor.update_customer(
           id,
           %{
             address: %{line1: "27 Fredrick Ave", country: "US"},
             tax: %{validate_location: "immediately", ip_address: "203.0.113.10"}
           },
           []
         )
```

**Braintree stubbed update shape** (`braintree_test.exs`, lines 48-56):
```elixir
def update(id, params, _opts) do
  {:ok,
   %{
     id: id,
     company: params["company"] || "ACME Billing",
     email: params["email"] || "billing@example.com",
     custom_fields: %{"source" => "stubbed"}
   }}
end
```

**Planner implication:** Fake remains the merge-blocking semantic lane; Braintree stays the translator-truth lane with gateway stubs. Stripe does not need a new proof model if existing processor-backed tests already cover the callback; keep the main deterministic assertions in Fake.

---

### `examples/accrue_host/lib/accrue_host/billing.ex`, `billing_facade_test.exs`, and `accrue/priv/accrue/templates/install/billing.ex.eex` (host facade proof)

**Analogs:** same files

**Thin helper pattern in host facade** (`examples/accrue_host/lib/accrue_host/billing.ex`, lines 49-60):
```elixir
def update_customer_tax_location(billable, attrs) when is_map(attrs) do
  with {:ok, customer} <- customer_for(billable) do
    if function_exported?(Billing, :update_customer_tax_location, 2) do
      apply(Billing, :update_customer_tax_location, [customer, attrs])
    else
      {:error, :tax_location_update_requires_newer_accrue}
    end
  end
end
```

**Host proof style** (`billing_facade_test.exs`, lines 41-52 and 177-220):
```elixir
test "generated facade exports the expected public functions" do
  exports = Billing.__info__(:functions)
  ...
  assert {:update_customer_tax_location, 2} in exports
end
```

```elixir
test "update_customer_tax_location/2 delegates to Accrue.Billing when available", %{user: user} do
  assert {:ok, customer} = Billing.customer_for(user)
  ...
  assert {:ok, updated} = Billing.update_customer_tax_location(user, attrs)
  assert updated.id == customer.id
  refute Map.has_key?(updated.data || %{}, "address")
end

test "generated facade source stays thin and explicit" do
  ...
  assert billing_source =~ "apply(Billing, :update_customer_tax_location, [customer, attrs])"
end
```

**Installer template baseline** (`billing.ex.eex`, lines 8-39):
```elixir
alias Accrue.Billing

def subscribe(billable, price_id, opts \\ []) do
  Billing.subscribe(billable, price_id, opts)
end
...
def customer_for(billable) do
  Billing.customer(billable)
end
```

**Planner implication:** if Phase 112 adds a host helper for the promoted shared customer-update row, follow the exact tax-location pattern: resolve the billable boundary in the host, delegate through `apply/3` only if forward-compatibility matters, and keep the helper generic with no processor jargon. Update the installer template in the same plan if the checked-in host facade changes.

## Shared Patterns

### Projection sanitization
**Source:** `accrue/lib/accrue/billing.ex` lines 1000-1020  
**Apply to:** `Accrue.Billing.update_customer/2` and any new local-only variant

```elixir
defp customer_projection_attrs(processor_result) when is_map(processor_result) do
  %{
    name: Map.get(processor_result, :name),
    email: Map.get(processor_result, :email),
    metadata: Map.get(processor_result, :metadata, %{}),
    data: sanitize_customer_data(processor_result)
  }
end
```

### Metadata validation and optimistic locking
**Source:** `accrue/lib/accrue/billing/customer.ex` lines 66-88  
**Apply to:** all local customer projection writes

```elixir
@cast_fields ~w[
  owner_type owner_id processor processor_id
  name email default_payment_method_id
  last_stripe_event_ts last_stripe_event_id
  preferred_locale preferred_timezone
  metadata data lock_version
]a

def changeset(customer_or_changeset, attrs \\ %{}) do
  customer_or_changeset
  |> cast(attrs, @cast_fields)
  |> validate_required(@required_fields)
  |> Metadata.validate_metadata(:metadata)
  |> optimistic_lock(:lock_version)
```

### Remote-first then local transaction
**Source:** `accrue/lib/accrue/billing.ex` lines 877-905  
**Apply to:** promoted `update_customer/2`

```elixir
with {:ok, processor_result} <- Processor.update_customer(...),
     customer_attrs = customer_projection_attrs(processor_result),
     {:ok, updated} <- customer |> Customer.changeset(customer_attrs) |> Repo.update(),
     {:ok, _event} <- Events.record(%{...}) do
  {:ok, updated}
end
```

### Fake-first semantic proof
**Source:** `accrue/test/accrue/processor/fake_test.exs` lines 58-89  
**Apply to:** accepted attr subset, rejection semantics, deterministic projection assertions

```elixir
assert {:ok, %{id: ^id, name: "New", email: "a@b"}} =
         Processor.update_customer(id, %{name: "New"}, [])
```

## Planner Notes

- Sequence the phase around the semantic seam, not around files:
  1. Settle `accrue/lib/accrue/billing.ex` first: promoted remote write-through path, separate local-only API name if needed, bounded attr validation, event meaning.
  2. Co-update `accrue/lib/accrue/processor/capabilities.ex` with any `.planning/processor-support-matrix.md` row promotion only after the facade semantics are settled.
  3. Update adapter tests and deterministic billing/event tests next so Fake remains the merge-blocking proof lane and Braintree remains translator-truth proof.
  4. Finish with the host helper, facade proof, and installer template in one pass so adoption-facing ergonomics match the new public contract.
- Keep Phase 112 scoped to `customer.update` only. Do not touch `subscription.cancel`, `cancel_immediately`, or `cancel_at_period_end` labels beyond preserving existing assertions.
- Prefer extending existing proof files over adding new test modules. The repo already has the right seams for capability labels, transactional events, Fake semantics, Braintree translation, and host-facade delegation.
- If remote-success/local-write-failure telemetry is added, place the behavior in the promoted billing facade path and prove it from the billing/event test lane rather than in provider-specific tests.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| none | n/a | n/a | Phase 112 is a contract-closure pass on existing seams; every likely touchpoint already has a strong in-repo analog. |

## Metadata

**Analog search scope:** `accrue/lib/accrue`, `accrue/test/accrue`, `examples/accrue_host`, `.planning`  
**Files scanned:** required Phase 112 sources plus recent Phase 109-111 pattern maps and adjacent host/template files  
**Pattern extraction date:** 2026-05-06

