# Phase 123: Config + Core Gate API Foundation - Pattern Map

**Mapped:** 2026-05-22
**Files analyzed:** 14 (5 created source + 3 modified source + 6 test files)
**Analogs found:** 14 / 14 (100% — every file has a line-anchored in-repo analog; greenfield package tree, zero new external deps)

> All analogs below were re-read at the named line ranges and confirm the RESEARCH.md
> Locked-Decision Verification table. House idioms are stable across the codebase: runtime
> `Application.get_env` dispatch (`__impl__/0`), inline `Accrue.Telemetry.span/3`, catch-all
> `false`/`nil`-clause boolean predicates, NimbleOptions `@schema` keys, and `setup`/`on_exit`
> app-env restore in tests. Build to `123-CONTEXT.md`; the stale `ARCHITECTURE.md` code samples
> (price_id-keyed config, `Billing.customer/1`, `span_entitlement/4`) are superseded by D-02/D-09/D-17.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/entitlements.ex` (NEW) | context (public facade) | request-response (read-only, fail-closed) | `accrue/lib/accrue/storage.ex` | exact (inline-span facade) |
| `accrue/lib/accrue/entitlements/resolver.ex` (NEW) | behaviour + dispatch seam | request-response | `accrue/lib/accrue/processor.ex` (`__impl__/0`) + `accrue/lib/accrue/auth.ex` | exact (behaviour + runtime dispatch) |
| `accrue/lib/accrue/entitlements/resolver/local_map.ex` (NEW) | service (default impl) | CRUD-read (Ecto read-only) | `accrue/lib/accrue/billing/query.ex` `active/1` + `billing.ex` `fetch_customer/2` | role + flow match |
| `accrue/lib/accrue/entitlements/plan.ex` (NEW) | model (pure value struct, NO Ecto) | transform (fold result) | `accrue/lib/accrue/plan_resolver.ex` `resolved_plan` typespec | partial (pure data shape; no struct precedent that is non-Ecto + MapSet) |
| `accrue/lib/accrue/config.ex` (MODIFY) | config | boot-validate + accessor | self — `:branding` `@schema` block, `branding/0`, `validate_descending/1`, `maybe_validate_boot_setup!/1` | exact (clone in-file patterns) |
| `accrue/lib/accrue.ex` (MODIFY) | route (top-level delegation) | request-response | `accrue/lib/accrue/auth.ex` delegate style (`defdelegate` net-new here) | role match (moduledoc-only today) |
| `accrue/lib/accrue/telemetry/otel.ex` (MODIFY) | config (allowlist) | transform (attribute filter) | self — `@allowed_attributes` map | exact (extend existing map) |
| `accrue/test/property/entitlements_fail_closed_property_test.exs` (NEW) | test (property) | — | `accrue/test/property/connect_platform_fee_property_test.exs` | exact |
| `accrue/test/accrue/entitlements_test.exs` (NEW) | test (example + telemetry) | — | `accrue/test/accrue/storage/null_test.exs` | exact (telemetry + app-env restore) |
| `accrue/test/accrue/entitlements/local_map_test.exs` (NEW) | test (resolver read-path) | — | `accrue/test/accrue/storage/null_test.exs` + `BillingCase` + factory | role match |
| `accrue/test/accrue/config_entitlements_test.exs` (NEW) | test (boot validation) | — | `accrue/test/accrue/storage/null_test.exs` (`async: false` env restore) | role match |
| `accrue/test/accrue/telemetry/otel_test.exs` (EXTEND) | test (allowlist) | — | self — `sanitize_attributes` assertions | exact |

## Pattern Assignments

### `accrue/lib/accrue/entitlements.ex` (context, request-response, fail-closed)

**Analog:** `accrue/lib/accrue/storage.ex` (the cleanest 3-level-domain inline-span facade)

**Inline span pattern** (`storage.ex` L42-48 — the verified template to mirror for all 4 fns):
```elixir
adapter = impl()
metadata = %{adapter: adapter, key: key, bytes: byte_size(binary)}

Accrue.Telemetry.span([:accrue, :storage, :put], metadata, fn ->
  adapter.put(key, binary, meta)
end)
```
For entitlements the event tuple is `[:accrue, :entitlements, :check]` (PLURAL, D-16) and the
metadata is the D-18 map. **CRITICAL — `span/3` does NOT enrich `:stop` from the fun return.**
`Accrue.Telemetry.span/3` (`telemetry.ex` L74-83) builds `base_metadata` once up front and reuses
the *same* map for `:start` AND `:stop`:
```elixir
# accrue/lib/accrue/telemetry.ex L74-83 (verified)
def span(event, metadata \\ %{}, fun) when is_list(event) and is_map(metadata) and is_function(fun, 0) do
  base_metadata = maybe_put_actor(metadata)
  otel_event = event_without_span_suffix(event)
  :telemetry.span(event, base_metadata, fn ->
    result = Accrue.Telemetry.OTel.span(otel_event, base_metadata, fn -> fun.() end)
    {result, base_metadata}
  end)
end
```
Consequence (resolves A2): **compute the decision (`result`, `reason`) BEFORE opening the span**,
pass the full D-18 metadata map into `span/3`, and have the fun simply return the boolean. The
span fun body does the bool/`[]`/`0` projection from the already-resolved `{:ok, …}` tuple.

**Fail-closed wrapper pattern** (D-08; idiom mirrors the catch-all `false` clause everywhere in
`subscription.ex` predicates, e.g. L147-149 `active?/1`):
```elixir
# active?/1 catch-all idiom — replicate the "sole affirmative + catch-all false" shape:
def active?(%__MODULE__{status: s}) when s in [:active, :trialing], do: true
def active?(%{status: s}) when s in [:active, :trialing], do: true
def active?(_), do: false
```
Apply: a single private resolver returns `{:ok, true} | {:ok, false} | {:error, reason}`; the
public fn matches `{:ok, true} -> true` as the SOLE true-path, everything else (`{:ok, false}`,
`{:error, _}`) -> `false`, all wrapped in `try/rescue/catch` so exceptions/throws/exits collapse
to `false`/`[]`/`0`. `nil`/wrong-type billable -> `{:ok, false}` (not `{:error, _}`).

**Resolver dispatch in the context** (D-13; see `resolver.ex` below): call `Resolver.__impl__().resolve(billable, opts)`.

**`features_for/1` boundary rule** (D-06): internal `MapSet`, return `MapSet.to_list |> Enum.sort` — never leak a `MapSet`.

**Ledger boundary** (D-21): NEVER call `Accrue.Events.record/1` (`events.ex` L109) or `record_multi/3` (L135) in this file. Per-check = telemetry only.

---

### `accrue/lib/accrue/entitlements/resolver.ex` (behaviour + runtime dispatch)

**Analog:** `accrue/lib/accrue/processor.ex` `__impl__/0` (L347-348) + `accrue/lib/accrue/auth.ex` (behaviour + `@callback` shape)

**`__impl__/0` runtime-dispatch idiom** (`processor.ex` L347-348, verified):
```elixir
@doc false
@spec __impl__() :: module()
def __impl__, do: Application.get_env(:accrue, :processor, Accrue.Processor.Fake)
```
Adapt to D-13 (read the resolver out of the `:entitlements` keyword list, default `LocalMap`):
```elixir
@doc false
def __impl__ do
  :accrue
  |> Application.get_env(:entitlements, [])
  |> Keyword.get(:resolver, Accrue.Entitlements.Resolver.LocalMap)
end
```
(Same shape as `Storage.impl/0` `storage.ex` L79, `Auth.impl/0` `auth.ex` L105, `Config.plan_resolver/0` `config.ex` L570-576.)

**`@callback` declaration pattern** (`auth.ex` L41-47 / `plan_resolver.ex` L36-39 — single result-tuple callback):
```elixir
# plan_resolver.ex L36-39 (verified — closest single-callback shape)
@callback resolve_price(String.t()) ::
            {:ok, resolved_plan()}
            | {:error, term()}
```
Adapt to D-12: `@callback resolve(billable, opts) :: {:ok, %{plan: term, features: MapSet.t, quantities: map}} | {:error, term}`. **No `capabilities/0` callback yet** (that is ENT-08/Phase 125).

---

### `accrue/lib/accrue/entitlements/resolver/local_map.ex` (service, read-only Ecto fold)

**Analogs:** `accrue/lib/accrue/billing/query.ex` `active/1` (L30-32) + `accrue/lib/accrue/billing.ex` `fetch_customer/2` (L788-796, **private** — D-09 forces a local read-only clone) + `accrue/lib/accrue/billable.ex` `__accrue__/1` (L66) + `accrue/lib/accrue/billing/customer.ex` (`owner_type`/`owner_id` L48-49, `has_many :subscriptions` L65)

**Read-only customer lookup** — D-09 forbids the effectful `Accrue.Billing.customer/1` (`billing.ex` L754-786, fetch-or-create / hits processor on miss). There is **no public read-only equivalent** — `fetch_customer/2` is private. Clone its query body inside the resolver:
```elixir
# accrue/lib/accrue/billing.ex L788-796 (private — clone inside the Resolver)
defp fetch_customer(billable_type, owner_id) do
  query =
    from(c in Customer,
      where: c.owner_type == ^billable_type and c.owner_id == ^owner_id,
      limit: 1
    )
  Repo.one(query)
end
```
billable -> `owner_type` via `billable.__struct__.__accrue__(:billable_type)` (`billable.ex` L66: `def __accrue__(:billable_type), do: @__accrue_billable_type__`); `owner_id = to_string(billable.id)` (matches `billing.ex` L757-758). Guard the lookup with a `%{__struct__: mod, id: id}` head and a catch-all `_ -> nil` so `nil`/wrong-shape billable fails closed.

**Active-subs read fragment** (D-09 — reuse the lifecycle truth, never raw `.status`):
```elixir
# accrue/lib/accrue/billing/query.ex L30-32 (verified — the active/:trialing truth)
def active(query \\ Subscription) do
  from(s in query, where: s.status in [:active, :trialing])
end
```
Compose: `Query.active(Subscription) |> where([s], s.customer_id == ^id) |> join(:inner, [s], i in SubscriptionItem, on: i.subscription_id == s.id) |> select([_s, i], {i.price_id, i.quantity}) |> Accrue.Repo.all()`. `SubscriptionItem.price_id` (`subscription_item.ex` L26) is the join key; `.quantity` (L29, default `1`) is the seat source for `entitlement_quantity/2` (`min(cap, quantity)` per D-06).

**Reverse-index fold:** build `price_id -> plan` from `Accrue.Config.entitlements/0`; unmapped active price_id -> `reason: :unmapped_plan`, drop (`:deny`) or raise (`:raise`). Fold into `%Accrue.Entitlements.Plan{features: MapSet (union), quantities: %{quota_key => min(cap, qty)}}`.

**NEVER in this file:** `Accrue.Processor.*`, `Accrue.Billing.customer/1`, `Accrue.Events.record/1`, raw `.status`.

---

### `accrue/lib/accrue/entitlements/plan.ex` (model — pure value struct, NO Ecto)

**Analog:** `accrue/lib/accrue/plan_resolver.ex` `@type resolved_plan` (L27-34) — the closest pure-data shape; no existing struct is both non-Ecto AND carries a `MapSet`, so this is partial.

```elixir
# plan_resolver.ex L27-34 — pure map typespec shape to mirror as a struct
@type resolved_plan :: %{
        required(:price_id) => String.t(),
        required(:processor) => String.t(),
        ...
      }
```
Build: `defstruct [:plan_id, features: MapSet.new(), quantities: %{}]` + `@type t :: %__MODULE__{plan_id: term, features: MapSet.t(), quantities: map}`. **No `use Ecto.Schema`** (cache schema is a Phase 127 concern, D-12).

---

### `accrue/lib/accrue/config.ex` (MODIFY — schema + accessor + boot collision guard)

**Analog:** self — three in-file patterns to clone.

**1. `@schema` nested-keys block** — clone the `:branding` shape (`config.ex` L272-305) for the locked `:entitlements` fragment (D-02/D-03). The exact fragment is in `123-CONTEXT.md` L67-87; `:branding` is the verified nested-`keys:` precedent (note: no existing `keys: [*: ...]` wildcard precedent in the schema, but NimbleOptions `~> 1.1` supports it — A1):
```elixir
# config.ex L272-300 (verified nested-keys precedent)
branding: [
  type: :keyword_list,
  required: false,
  default: [],
  keys: [
    business_name: [type: :string, default: "Accrue"],
    ...
  ],
  doc: "..."
]
```

**2. Defaults-merge accessor** — clone `branding/0` (`config.ex` L685-731). Per RESEARCH L346-350 a thin `entitlements/0` = `get!(:entitlements)` may suffice (schema nested defaults normalize plan entries on validation); clone the full merge only if call sites need `Keyword.fetch!` safety on partial plan entries:
```elixir
# config.ex L685-715 (verified merge-with-defaults accessor to clone)
def branding do
  raw = get!(:branding)
  cond do
    is_list(raw) and raw == [] -> branding_defaults()
    is_list(raw) -> merge_with_defaults(raw)
    true -> raise Accrue.ConfigError, key: :branding, message: "..."
  end
end
defp merge_with_defaults(user_kw) do
  Enum.reduce(branding_defaults(), user_kw, fn {k, default}, acc ->
    case Keyword.fetch(acc, k) do
      :error -> Keyword.put(acc, k, default)
      {:ok, _} -> acc
    end
  end)
end
```
`get!/1` (`config.ex` L394-405) already falls back to the schema default `[]` via `default_for/1` (L892-897).

**3. Boot collision guard** — wire into `maybe_validate_boot_setup!/1` (`config.ex` L786-798), NOT a `{:custom, ...}` field validator (the collision is cross-plan; `:custom` validators see one value). `validate_descending/1` (L846-863) is the *shape* to clone (a named module fn returning on success / raising-or-erroring on failure); the wiring precedent is how `webhook_signing_secrets(:stripe)` is conditionally called from `maybe_validate_boot_setup!/1`:
```elixir
# config.ex L786-798 (verified — the boot-setup hook to extend)
defp maybe_validate_boot_setup!(opts) do
  _ = Keyword.fetch!(opts, :repo)
  if safe_mix_env() != :test do
    _ = ensure_migrations_current!()
  end
  if Keyword.get(opts, :processor, Accrue.Processor.Fake) == Accrue.Processor.Stripe do
    _ = webhook_signing_secrets(:stripe)
  end
  :ok
end
```
Add a `validate_entitlements_price_ids!(opts)` call here that reduces all plans' `price_ids`, raising `Accrue.ConfigError` (`errors.ex` L112-127, fields `[:message, :key, :diagnostic]`) when a price_id maps to two plans. The RESEARCH L270-282 sketch is the exact reduce shape. Raise idiom (verified across `config.ex`, e.g. L607-611):
```elixir
raise Accrue.ConfigError, key: :entitlements,
  message: "price_id #{inspect(pid)} mapped to both #{inspect(other)} and #{inspect(plan)}"
```

---

### `accrue/lib/accrue.ex` (MODIFY — 4 `defdelegate`s)

**Analog:** `accrue/lib/accrue/auth.ex` delegate style (`accrue.ex` is moduledoc-only today, L1-16, so delegates are net-new). Add the four D-06 delegates to `Accrue.Entitlements`:
```elixir
defdelegate has_active_plan?(billable, plan), to: Accrue.Entitlements
defdelegate entitled?(billable, feature), to: Accrue.Entitlements
defdelegate features_for(billable), to: Accrue.Entitlements
defdelegate entitlement_quantity(billable, quota_key), to: Accrue.Entitlements
```
(`@doc`/`@spec` each per house style; specs: `boolean()`, `boolean()`, `[atom()]`, `non_neg_integer()`.)

---

### `accrue/lib/accrue/telemetry/otel.ex` (MODIFY — extend `@allowed_attributes`)

**Analog:** self — the `@allowed_attributes` map (L12-27). It is a STRICT allowlist: `sanitize_attributes/1` (L99-111) drops any key not present, so the six D-19 keys MUST be added in **both atom and string form** or every entitlement OTel attribute is silently discarded (raw `:telemetry` metadata is unaffected — only the OTel bridge filters):
```elixir
# accrue/lib/accrue/telemetry/otel.ex L12-27 (verified — extend this map)
@allowed_attributes %{
  :processor => "accrue.processor",
  ...
  :status => "accrue.status",
  "accrue.processor" => "accrue.processor",
  ...
  "accrue.status" => "accrue.status"
}
```
Add (atom + `"accrue.<key>"` string forms for each): `:feature`, `:result`, `:resolver`, `:reason`, `:subject_type`, `:subject_id`. **Do NOT reuse `:status`** (L18→`accrue.status`) for `:result` — D-19/RESEARCH L160 mandate a distinct `:result` key. `@prohibited_keys` (L29-51) already blocks `:email`/`:address`/etc., satisfying the PII rule (D-18).

---

## Shared Patterns

### Inline telemetry span (all 4 public functions)
**Source:** `accrue/lib/accrue/storage.ex` L42-48 (template); `accrue/lib/accrue/telemetry.ex` L74-83 (`span/3` contract)
**Apply to:** `entitlements.ex` (every public fn)
```elixir
Accrue.Telemetry.span([:accrue, :entitlements, :check], metadata, fn -> ... end)
```
Event PLURAL `:entitlements` (D-16). Metadata = D-18 map, fully resolved BEFORE the span opens (the helper does not enrich `:stop` from the fun result — it reuses `base_metadata` for both `:start` and `:stop`).

### Runtime adapter dispatch
**Source:** `accrue/lib/accrue/processor.ex` L347-348 (`__impl__/0`); also `auth.ex` L105, `storage.ex` L79, `config.ex` L570-576
**Apply to:** `resolver.ex` `__impl__/0` (reads `:entitlements`→`:resolver`, default `LocalMap`)
```elixir
def __impl__, do: :accrue |> Application.get_env(:entitlements, []) |> Keyword.get(:resolver, Accrue.Entitlements.Resolver.LocalMap)
```
Also makes the D-10 raising-stub resolver swap trivial in the property test.

### Fail-closed boolean predicate
**Source:** `accrue/lib/accrue/billing/subscription.ex` L146-149 (`active?/1` — sole-affirmative + catch-all `false`)
**Apply to:** all `entitlements.ex` public fns + the read-only customer guard in `local_map.ex`
Sole affirmative head returns `true`; every other shape (incl. `nil`, wrong type, `{:error,_}`) -> `false`/`[]`/`0`; wrap in `try/rescue/catch` (D-08).

### Lifecycle truth reuse (never raw `.status`)
**Source:** `accrue/lib/accrue/billing/query.ex` L30-32 (`active/1`); `accrue/lib/accrue/billing/subscription.ex` L146-149 (`active?/1`)
**Apply to:** `local_map.ex` read path
Use `Query.active/1` / `Subscription.active?/1` — they encode `:trialing` inclusion + cancel/incomplete edges (Pitfall 2). 123 inherits whatever `active?/1` decides (`:active` + `:trialing` only); the `past_due` grace knob is Phase 125.

### Config schema + boot validation
**Source:** `accrue/lib/accrue/config.ex` — `:branding` `@schema` block (L272-305), `branding/0`+`merge_with_defaults/1` (L685-731), `get!/1` (L394-405), `validate_descending/1` (L846-863), `maybe_validate_boot_setup!/1` (L786-798)
**Apply to:** `config.ex` (the only MODIFY for ENT-01)
Extend `@schema`; clone the accessor; place the cross-plan price_id-collision guard in `maybe_validate_boot_setup!/1` raising `Accrue.ConfigError`.

### One-way dependency (LOCKED, D-14)
**Source:** clean baseline — `grep -rn "Accrue.Entitlements" lib/accrue/billing/ lib/accrue/billing.ex` returns zero matches today.
**Apply to:** verify-step gate. `Accrue.Entitlements.*` reads `Billing.Query`/`Subscription`/`SubscriptionItem`/`Customer`; **nothing under `lib/accrue/billing/` may reference `Accrue.Entitlements.*`.** Verify gate: `! grep -rq "Accrue.Entitlements" accrue/lib/accrue/billing/ accrue/lib/accrue/billing.ex`.

### Test: telemetry handler + app-env restore
**Source:** `accrue/test/accrue/storage/null_test.exs` L6-19 (env restore via `setup`/`on_exit`) + L46-73 (`:telemetry.attach_many` → `send(test_pid, ...)`)
**Apply to:** `entitlements_test.exs`, `config_entitlements_test.exs`, `local_map_test.exs`
```elixir
# null_test.exs L6-19 — app-env restore (mutate :entitlements with on_exit restore)
setup do
  prev = Application.get_env(:accrue, :storage_adapter)
  Application.delete_env(:accrue, :storage_adapter)
  on_exit(fn ->
    if prev, do: Application.put_env(:accrue, :storage_adapter, prev),
    else: Application.delete_env(:accrue, :storage_adapter)
  end)
  :ok
end
```
```elixir
# null_test.exs L47-73 — telemetry handler (attach to the 3 PLURAL entitlement events)
test_pid = self(); ref = make_ref(); handler_id = {__MODULE__, ref}
:telemetry.attach_many(handler_id,
  [[:accrue,:entitlements,:check,:start],
   [:accrue,:entitlements,:check,:stop],
   [:accrue,:entitlements,:check,:exception]],
  fn name, m, meta, _ -> send(test_pid, {:telemetry_event, name, m, meta}) end, nil)
on_exit(fn -> :telemetry.detach(handler_id) end)
```
Use `use ExUnit.Case, async: false` for any test that mutates `:entitlements` app env. Customer/sub/item fixtures come from `Accrue.Test.Factory.{active,trialing,canceled}_subscription/1` (`factory.ex` L92-203, `%{customer:, subscription:, items:}`, `:price_id` override), inside `use Accrue.BillingCase` (SQL Sandbox + Fake processor) for the resolver read-path tests.

### Test: property (`StreamData`)
**Source:** `accrue/test/property/connect_platform_fee_property_test.exs` L19-20, L31, L81-94
**Apply to:** `entitlements_fail_closed_property_test.exs` (D-10, the load-bearing test)
```elixir
# connect_platform_fee_property_test.exs L19-20 + L81-94 (verified idiom)
use ExUnit.Case, async: true
use ExUnitProperties
...
property "..." do
  check all(input <- gen(), max_runs: 200) do
    assert ...
  end
end
```
Generators (RESEARCH L484-489): `StreamData.one_of([constant(nil), term(), integer(), string(:ascii), atom(:alphanumeric)])` for garbage; factory-backed billable for the affirmative-match leg; a raising resolver/Repo stub (swap `:entitlements`→`:resolver` to a module whose `resolve/2` raises). Invariants: `entitled?/2 == false`, `entitlement_quantity/2 == 0`, `features_for/1 == []` on all garbage; `entitled?(billable, feat) == MapSet.member?(F, feat)` on the affirmative leg. Note: `async: false` here (mutates `:entitlements` app env), unlike the pure-math `connect` property test which is `async: true`.

### Test: OTel allowlist (extend)
**Source:** `accrue/test/accrue/telemetry/otel_test.exs` L12-41 (`sanitize_attributes/1` assertions)
**Apply to:** add a test asserting `Accrue.Telemetry.OTel.sanitize_attributes(%{feature: :x, result: true, resolver: :local_map, reason: :entitled, subject_type: "User", subject_id: "<uuid>"})` retains all six keys (mapped to `accrue.<key>`) — proving the D-19 additions landed.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | — | — | Every created/modified file has an in-repo, line-anchored analog. `plan.ex` is the weakest match (no existing non-Ecto + `MapSet` struct), but `plan_resolver.ex`'s `resolved_plan` typespec supplies the data-shape pattern; the planner should use `123-CONTEXT.md` D-12 for the exact `%Plan{}` field set. |

## Metadata

**Analog search scope:** `accrue/lib/accrue/` (config, telemetry, billing, processor, auth, plan_resolver, storage, events, errors, billable), `accrue/lib/accrue/test/factory.ex`, `accrue/test/` (support, property, storage, telemetry).
**Files scanned:** 18 source/test files read at verified line ranges; all confirm RESEARCH.md Locked-Decision Verification (no discrepancies found).
**Key cross-cutting confirmation:** `Accrue.Telemetry.span/3` reuses one `base_metadata` map for `:start` and `:stop` — the decision must be computed before the span opens (resolves Assumption A2). The OTel `@allowed_attributes` allowlist is strict-drop — the 6 keys are mandatory (resolves the 123-specific OTel-drop pitfall). The D-09 read-only customer lookup has no public equivalent — `fetch_customer/2` is private and must be cloned into the resolver.
**Pattern extraction date:** 2026-05-22

## PATTERN MAPPING COMPLETE
