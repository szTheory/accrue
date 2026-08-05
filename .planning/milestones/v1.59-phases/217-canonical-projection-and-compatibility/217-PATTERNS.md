# Phase 217: Canonical projection and compatibility - Pattern Map

**Mapped:** 2026-08-02  
**Files analyzed:** 18 planned new/modified files  
**Analogs found:** 18 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/entitlements/snapshot.ex` | model/value | transform | `entitlements/resolver/local_map.ex` | exact flow |
| `accrue/lib/accrue/entitlements/projector.ex` | service | event-driven / CRUD | `entitlements/observation.ex`, `events.ex` | role-match |
| `accrue/lib/accrue/entitlements/purchase_decision.ex` | service/value | request-response | `entitlements/source/registry.ex` | role-match |
| `accrue/lib/accrue/entitlements/compatibility.ex` | service | batch / transform | `entitlements/resolver.ex` | role-match |
| `accrue/lib/accrue/entitlements/resolver/canonical.ex` | service | request-response | `entitlements/resolver/local_map.ex` | exact role |
| `accrue/lib/accrue/rails/gateway_registry.ex` | service | request-response | `entitlements/source/registry.ex` | role-match |
| `accrue/lib/accrue/entitlements.ex` | controller/context | request-response | itself / `billing.ex` | modification |
| `accrue/lib/accrue/entitlements/resolver.ex` | config/behaviour | request-response | itself | modification |
| `accrue/lib/accrue/config.ex` | config | transform | itself (`plan_resolver/0`) | modification |
| `accrue/lib/accrue/billing.ex` | controller/context | request-response | itself | modification |
| `accrue/lib/accrue/billing/subscription_actions.ex` | service | request-response / CRUD | itself | modification |
| `accrue/test/accrue/entitlements/snapshot_test.exs` | test | transform | `entitlements/local_map_test.exs` | flow-match |
| `accrue/test/accrue/entitlements/projector_test.exs` | test | event-driven / CRUD | `entitlements/persistence_test.exs` | role-match |
| `accrue/test/property/entitlement_projection_property_test.exs` | test | transform | `test/accrue/money_property_test.exs` | role-match |
| `accrue/test/accrue/entitlements/compatibility_test.exs` | test | request-response | `entitlements/resolver_test.exs` | exact seam |
| `accrue/test/accrue/entitlements/purchase_decision_test.exs` | test | request-response | `entitlements/source_test.exs` | role-match |
| `accrue/test/accrue/billing/resource_dispatch_test.exs` | test | request-response | `billing/subscription_actions_test.exs` | exact surface |
| `accrue/test/accrue/entitlements/decision_cases_test.exs` | test | transform | itself | modification |

`compatibility.ex` owns deterministic, idempotent backfill plus shadow/parity/cutover selection; no separate migration is implied. Phase 216 already provides accounts, grants, observations, indexes, and durable audit storage.

## Pattern Assignments

### `entitlements/snapshot.ex` (value/transform)

**Analog:** `accrue/lib/accrue/entitlements/resolver/local_map.ex`

Copy the seed-and-fold approach, but return a typed snapshot with sorted public lists rather than the resolver's internal `MapSet`s. The quota merge is directly applicable.

**Core fold** ([local_map.ex](../../../../accrue/lib/accrue/entitlements/resolver/local_map.ex:239), lines 239-274):

```elixir
quantities =
  Enum.reduce(limits, acc.quantities, fn {quota_key, cap}, q ->
    capped = min(cap, quantity)
    Map.update(q, quota_key, capped, &max(&1, capped))
  end)

%{acc |
  active_plans: MapSet.put(acc.active_plans, plan_atom),
  features: MapSet.union(acc.features, feature_set),
  quantities: quantities
}
```

Preserve the pure/read-only posture in [local_map.ex](../../../../accrue/lib/accrue/entitlements/resolver/local_map.ex:68): lookup returns `{:ok, empty}` for absence and never calls the processor. Snapshot signature must be derived from authorization fields only, not diagnostic source correlation.

### `entitlements/projector.ex` (event-driven service)

**Analogs:** `entitlements/observation.ex`, `repo.ex`, `events.ex`, `entitlements/account.ex`

Use `Accrue.Repo.transact/1` as the outer serialized boundary ([repo.ex](../../../../accrue/lib/accrue/repo.ex:20), lines 20-27). Within it, query the account with `lock: "FOR UPDATE"`, fetch current grants, calculate before/after snapshots, and return tagged no-op/error results—not exceptions for expected ordering outcomes.

**Idempotent observation insert** ([observation.ex](../../../../accrue/lib/accrue/entitlements/observation.ex:128), lines 128-153):

```elixir
case repo.insert(changeset,
       on_conflict: :nothing,
       conflict_target: conflict_target(changeset)
     ) do
  {:ok, _observation} -> resolve_identity_owner(repo, changeset)
  {:error, error_changeset} -> {:error, error_changeset}
end
```

**Account ownership/idempotent provision** ([account.ex](../../../../accrue/lib/accrue/entitlements/account.ex:39), lines 39-55):

```elixir
case repo.insert(changeset,
       on_conflict: :nothing,
       conflict_target: [:owner_type, :owner_id]
     ) do
  {:ok, _account} ->
    {:ok, repo.get_by!(__MODULE__, owner_type: owner_type, owner_id: owner_id)}
  {:error, changeset} -> {:error, changeset}
end
```

Append the audit event inside the same transaction via `Accrue.Events.record_multi/3` ([events.ex](../../../../accrue/lib/accrue/events.ex:119), lines 119-150). Keep schema validations/unique constraints authoritative; do not move raw provider data into `Observation.metadata` (its bounded validation is in lines 70-125).

### `entitlements/purchase_decision.ex` (typed decision service)

**Analog:** `accrue/lib/accrue/entitlements/source/registry.ex`

Define an enforced struct and closed atoms, then return `{:ok, struct}` / `{:error, typed_error}`. Model external management and invalid input as distinct outcomes, as the registry does.

**Closed outcome/error construction** ([registry.ex](../../../../accrue/lib/accrue/entitlements/source/registry.ex:37), lines 37-67):

```elixir
case declaration(source, capability) do
  {:ok, state, guidance} ->
    {:ok, %Outcome{source: source, capability: capability, state: state, guidance: guidance}}
  {:error, code, next_action} ->
    {:error, %CapabilityError{source: source, capability: capability,
                              code: code, next_action: next_action}}
end
```

The decision struct must carry `status: :eligible | :block | :warn`, stable reason, target rail/logical plan, redacted sources, and snapshot revision. Override rechecks revision and equivalence within the projector/transaction boundary; use `Accrue.Events` for its idempotent audit record.

### `entitlements/compatibility.ex` and `resolver/canonical.ex` (compatibility service / resolver)

**Analogs:** `entitlements/resolver.ex`, `entitlements/resolver/local_map.ex`, `entitlements/resolver_test.exs`

Implement Canonical as the existing behaviour, keeping output compatible with the current gate facade. Let `Compatibility` choose exactly one authority (`:disabled`, `:shadow`, `:enabled`) before resolution; shadow may compare and emit/store a blocker but must return LocalMap’s value.

**Resolver type and runtime seam** ([resolver.ex](../../../../accrue/lib/accrue/entitlements/resolver.ex:52), lines 52-78):

```elixir
@type resolved :: %{
  required(:plan) => term(),
  required(:active_plans) => MapSet.t(),
  required(:features) => MapSet.t(),
  required(:quantities) => map()
}

@callback resolve(billable :: term(), opts :: keyword()) ::
            {:ok, resolved()} | {:error, term()}
```

**Pure absence/error style** ([local_map.ex](../../../../accrue/lib/accrue/entitlements/resolver/local_map.ex:68), lines 68-94):

```elixir
case lookup_customer(billable) do
  %Customer{} = customer -> {:ok, fold_active(customer)}
  nil -> {:ok, @empty}
end
```

For backfill, start from authenticated/known billable identity and `Account.fetch_or_create/3`; iterate deterministically in chunks, make each account/current-grant operation idempotent, and never call a provider or mutate subscription/customer rows.

### `rails/gateway_registry.ex`, `billing.ex`, and `billing/subscription_actions.ex` (resource-aware lifecycle dispatch)

**Analogs:** `entitlements/source/registry.ex`, `billing.ex`, `billing/subscription_actions.ex`

Registry lookup must receive the persisted resource processor only after resource scoping/authorization. It returns a typed unavailable/error or adapter; never call `Processor.__impl__/0` for existing subscriptions. New-resource creation and `customer/1` retain their existing default-processor path.

**Keep facade signatures and telemetry wrapping** ([billing.ex](../../../../accrue/lib/accrue/billing.ex:102), lines 102-142):

```elixir
def cancel(sub, opts \\ []),
  do: span_subscription(:cancel, sub, opts, &SubscriptionActions.cancel/2)

def resume(sub, opts \\ []),
  do: span_subscription(:resume, sub, opts, &SubscriptionActions.resume/2)
```

**Existing mutation transaction / audit / bang convention** ([subscription_actions.ex](../../../../accrue/lib/accrue/billing/subscription_actions.ex:587), lines 587-622):

```elixir
Repo.transact(fn ->
  with {:ok, provider_sub} <- adapter.cancel_subscription(sub.processor_id, params,
         idempotency_key: idem_key),
       {:ok, attrs} <- SubscriptionProjection.decompose(provider_sub),
       {:ok, updated} <- update_subscription_row(sub, attrs),
       {:ok, _} <- record_event("subscription.canceled", updated, %{mode: "immediate"}) do
    {:ok, Repo.preload(updated, :subscription_items, force: true)}
  end
end)
```

Copy the bang conversion immediately below it ([subscription_actions.ex](../../../../accrue/lib/accrue/billing/subscription_actions.ex:615), lines 615-622). Replace all existing-resource global-dispatch sites—cancel, period-end, resume, pause/unpause, swap, quantity/item update, preview—with the registry adapter. Apple has no `%Billing.Subscription{}` mutation path: use the established `:externally_managed` literal guidance ([registry.ex](../../../../accrue/lib/accrue/entitlements/source/registry.ex:69), lines 69-76) through an additive non-bang management query.

### `entitlements.ex`, `resolver.ex`, and `config.ex` (public compatibility configuration)

**Analogs:** `entitlements.ex`, `resolver.ex`, `config.ex`

Keep legacy gate return shapes. `Entitlements` already converts resolver faults to fail-closed values and performs per-check telemetry; add snapshot/provision/preflight APIs without changing `entitled?/2`, `has_active_plan?/2`, `features_for/1`, or `entitlement_quantity/2`.

Configuration should follow the runtime, inert-default access pattern ([config.ex](../../../../accrue/lib/accrue/config.ex:818), lines 818-824): a missing multi-rail entry means disabled LocalMap authority. Tests must restore mutated app env in `on_exit`, following [resolver_test.exs](../../../../accrue/test/accrue/entitlements/resolver_test.exs:11).

### Test files (unit, integration, property, isolation)

**Analogs:** `entitlements/resolver_test.exs`, `entitlements/provider_honesty_test.exs`, `entitlements/persistence_test.exs`, `billing/subscription_actions_test.exs`, `entitlements/decision_cases_test.exs`

Use `Accrue.BillingCase, async: false` for database/app-env tests and restore every changed config in `on_exit`; use ordinary `ExUnit.Case, async: true` for pure value/fixture tests.

**Runtime-config restoration** ([resolver_test.exs](../../../../accrue/test/accrue/entitlements/resolver_test.exs:11), lines 11-25):

```elixir
prev = Application.get_env(:accrue, :entitlements)
on_exit(fn ->
  if prev, do: Application.put_env(:accrue, :entitlements, prev),
           else: Application.delete_env(:accrue, :entitlements)
end)
```

**Provider-isolation proof shape** ([provider_honesty_test.exs](../../../../accrue/test/accrue/entitlements/provider_honesty_test.exs:74), lines 74-132): attach processor telemetry, resolve/evaluate, compare deterministic values, and `refute_received` provider calls. Reuse that negative-proof idiom for every Apple management path: assert no cancel, retry, swap, proration, refund, invoice, payment-method, or dunning adapter is reachable.

**Closed-fixture test shape** ([decision_cases_test.exs](../../../../accrue/test/accrue/entitlements/decision_cases_test.exs:9), lines 9-64): assert sorted/unique stable case IDs, valid closed values, and explicit failure on mutated invalid values. Extend the corpus assertions for projection ordering, survivor access, revision/no-op, eligibility, and cutover reason IDs.

## Shared Patterns

### Transactions, ordering, and durable truth

**Sources:** `repo.ex`, `account.ex`, `observation.ex`, `events.ex`  
**Apply to:** projector, backfill, override, cutover/blocker recording.

- Host-owned Repo only through `Accrue.Repo`; use `transact/1` and lock the account row in the callback.
- Preserve database identity/partial unique constraints and use `on_conflict: :nothing` plus canonical-row readback.
- Mutate only qualified current grants for a rail/environment/lineage, then derive effective state from all current grants.
- Record material projection/override/cutover events in the same transaction; no revision/event on a no-op signature.

### Public boundary and errors

**Sources:** `entitlements/resolver.ex`, `source/registry.ex`, `billing/subscription_actions.ex`  
**Apply to:** snapshot, purchase decision, management query, resolver/cutover.

- Use typed structs with closed status/code/action atoms; preserve tagged results.
- Retain bang functions only for the established gateway facades. Apple externally-managed guidance is a successful non-bang outcome, not an exception.
- Keep values privacy-bounded: opaque/internal IDs and redacted correlation only; never raw evidence, payload, email, or adopter identity.

### Telemetry and audit

**Sources:** `billing.ex`, `events.ex`, `entitlements.ex`  
**Apply to:** every public Phase-217 facade.

- Preserve context-level telemetry wrappers and bounded metadata.
- Use `Events.record/1`/`record_multi/3` for immutable audit history; do not create an ad-hoc event table.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | — | — | Every planned responsibility has a strong existing seam; canonical projection itself is new, but its fold, transaction, idempotency, compatibility, and typed-result pieces are all established. |

## Metadata

**Analog search scope:** `accrue/lib/accrue/{entitlements,billing,rails,repo,events,config}.ex`, `accrue/test/accrue/{entitlements,billing}`, `accrue/test/property`  
**Files scanned:** 25  
**Pattern extraction date:** 2026-08-02
