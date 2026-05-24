# Phase 127: Optional Stripe-Native Sync (isolated, off by default) - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 13 new/modified artifacts
**Analogs found:** 13 / 13 (every artifact has a named in-codebase analog; this phase is ~90% pattern reuse)

> All paths below are repo-relative to `/Users/jon/projects/accrue`. Line numbers are
> verified against current source read this session. The planner should reference these
> analogs directly in PLAN.md action steps — every excerpt is copy-from material.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/billing/entitlement_summary.ex` (NEW) | model (Ecto schema) | event-driven (webhook projection) | `accrue/lib/accrue/billing/subscription_schedule.ex` | exact |
| `accrue/priv/repo/migrations/*_create_accrue_entitlement_summaries.exs` (NEW) | migration | n/a (DDL) | `accrue/priv/repo/migrations/20260414130100_create_accrue_subscription_schedules.exs` | exact |
| `accrue/lib/accrue/config.ex` (MODIFY) | config | transform (schema validation) | in-file `unmapped_action` (:390), `past_due_grace` (:421 + accessor :770-771) | exact (in-file precedent) |
| `accrue/lib/accrue/webhook/default_handler.ex` (MODIFY) | handler/reducer | event-driven (webhook → cache) | in-file `reduce_row/5` (:1058), `check_stale/2` (:1078), `stamp_watermark/3` (:1102), `reduce_charge`/orphan (:840), `reduce_checkout_session` dispatch (:250) | exact (in-file precedent) |
| `accrue/lib/accrue/entitlements/stripe_sync.ex` (NEW, OR sibling fn in `admin.ex`) | service (read-only seam) | request-response (read) | `accrue/lib/accrue/entitlements/admin.ex:47` `resolve_for_customer/1` | exact |
| Ledger call (in default_handler reducer) | service (audit append) | event-driven | `accrue/lib/accrue/events.ex:109-154` `record/1` + `insert_opts/1`; in-handler `record_event/5` (:1106-1115) | exact |
| `[:accrue, :ops, :entitlement_summary_truncated]` (in reducer) | telemetry (ops event) | event-driven | `accrue/lib/accrue/telemetry/ops.ex:57-75` `emit/3` (`connect_account_deauthorized` model) | exact |
| `[:accrue, :entitlements, :sync]` span (in reducer/seam) | telemetry (span) | event-driven | `accrue/lib/accrue/entitlements.ex:290` `[:accrue, :entitlements, :check]` span | exact (sibling mirror) |
| OTel allowlist (MODIFY — DO NOT widen) | config/telemetry | transform | `accrue/lib/accrue/telemetry/otel.ex:12-45` `@allowed_attributes` | constraint-only |
| `scripts/ci/verify_entitlement_sync_isolation.sh` (NEW) | test (static gate) | transform (grep) | `scripts/ci/verify_core_liveview_runtime_free.sh` | exact |
| `scripts/ci/verify_processor_support_matrix.sh` (MODIFY) + `.planning/processor-support-matrix.md` + `accrue/lib/accrue/processor/capabilities.ex` | config/test (capability row) | transform | in-file `@provider_support_labels` (:65-113), `@core_capability_labels` (:60-62) | exact (in-file precedent) |
| `accrue/test/support/stripe_fixtures.ex` (MODIFY — add `entitlement_summary_event/2`) | test (fixture) | transform | `accrue/test/support/stripe_fixtures.ex:383-395` `webhook_event/3` | exact |
| New test files (3) | test | event-driven / property / isolation | `default_handler_out_of_order_test.exs`, `entitlements_fail_closed_property_test.exs` | exact |

---

## Pattern Assignments

### `accrue/lib/accrue/billing/entitlement_summary.ex` (NEW — model, event-driven projection) — D-05

**Analog:** `accrue/lib/accrue/billing/subscription_schedule.ex` (thin Stripe projection: `data :map` JSONB + typed columns + watermark + `lock_version` + force changeset). Read the whole file (1-98) — it is the structural template.

**Schema block to clone** (`subscription_schedule.ex:29-54`):
```elixir
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id

@type t :: %__MODULE__{}

schema "accrue_subscription_schedules" do
  field(:processor, :string, default: "stripe")
  field(:processor_id, :string)
  belongs_to(:customer, Accrue.Billing.Customer)
  # ...typed columns admin reads...
  field(:data, :map, default: %{})
  field(:metadata, :map, default: %{})
  field(:lock_version, :integer, default: 1)
  field(:last_stripe_event_ts, :utc_datetime_usec)
  field(:last_stripe_event_id, :string)
  timestamps(type: :utc_datetime_usec)
end
```

**Force-changeset to clone** (`subscription_schedule.ex:88-97`) — the webhook-path changeset that skips status allowlists because Stripe is canonical, with the three constraints:
```elixir
def force_status_changeset(schedule_or_changeset, attrs \\ %{}) do
  schedule_or_changeset
  |> cast(attrs, @cast_fields)
  |> Metadata.validate_metadata(:metadata)
  |> optimistic_lock(:lock_version)
  |> unique_constraint(:processor_id)        # → for 127: unique_constraint(:customer_id)
  |> foreign_key_constraint(:customer_id)
end
```

**127-specific deltas from the analog** (per D-05):
- `schema "accrue_entitlement_summaries"` — **one row per customer** (NOT per `processor_id`).
- **NO `processor_id` field** — the summary object has no top-level `id` (D-06, RESEARCH Pattern 4 / A4). Identity is `customer`. The unique key is `customer_id`, not `processor_id`.
- Add columns absent from the analog: `stripe_customer_id` (denormalized `cus_` for orphan/debug); `livemode :boolean`; `entitlement_count :integer` (admin sort); `truncated :boolean` (← `entitlements.has_more`, D-07); `synced_at :utc_datetime_usec` (event `created`, human-friendly).
- Keep `processor` (default `"stripe"`), `data :map`, `lock_version`, `last_stripe_event_ts`, `last_stripe_event_id`, `timestamps`.
- Changeset: `unique_constraint(:customer_id)` + `optimistic_lock(:lock_version)` + `foreign_key_constraint(:customer_id)`. No status allowlist (Stripe canonical, force-style — clone `force_status_changeset/2`, drop the user-path `changeset/2` with `validate_inclusion` since there is no user write path).

---

### `accrue/priv/repo/migrations/*_create_accrue_entitlement_summaries.exs` (NEW — migration) — D-05

**Analog:** `accrue/priv/repo/migrations/20260414130100_create_accrue_subscription_schedules.exs` (whole file, 1-55).

**Table + watermark columns to clone** (`:23-49`):
```elixir
create table(:accrue_subscription_schedules, primary_key: false) do
  add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
  add :processor, :string, null: false, default: "stripe"
  add :customer_id,
      references(:accrue_customers, type: :binary_id, on_delete: :nilify_all),
      null: true
  add :data, :map, null: false, default: %{}
  add :lock_version, :integer, null: false, default: 1
  add :last_stripe_event_ts, :utc_datetime_usec, null: true
  add :last_stripe_event_id, :string, null: true
  timestamps(type: :utc_datetime_usec)
end
create unique_index(:accrue_subscription_schedules, [:processor_id])
create index(:accrue_subscription_schedules, [:customer_id])
```

**127-specific deltas** (per D-05):
- `on_delete: :delete_all` (NOT `:nilify_all`) for the `customer_id` FK — the summary is meaningless without its customer.
- `unique_index(:accrue_entitlement_summaries, [:customer_id])` — this is the upsert target / one-per-customer idempotency key (replaces the analog's `unique_index([:processor_id])`).
- `index([:stripe_customer_id])`.
- Partial `create index(:accrue_entitlement_summaries, [:truncated], where: "truncated = true")` — operators find partial caches fast (D-05).
- Add the new typed columns: `stripe_customer_id :string`, `livemode :boolean`, `entitlement_count :integer`, `truncated :boolean default: false`, `synced_at :utc_datetime_usec`.
- Forward-only migration (no `down`; `change` is fine for a pure `create table`).
- New timestamp prefix (planner picks; format `2026MMDDHHMMSS_`, must sort after `20260415130100`).

---

### `accrue/lib/accrue/config.ex` (MODIFY — config) — D-03

**Analog:** in-file `unmapped_action` enum (`:390-395`) and `past_due_grace` enum (`:421-430`) + its raw-read accessor (`:770-771`).

**Schema entry to clone** — add under `:entitlements` `keys:` (after `past_due_grace`, `:430`). Mirror the `past_due_grace` enum shape:
```elixir
# existing precedent, config.ex:421-430:
past_due_grace: [
  type: {:or, [{:in, [:dunning, :none]}, :pos_integer]},
  default: :none,
  doc: "Entitlement access for :past_due subscriptions. :none (default) fails closed ..."
]
```
127 version (D-03 — enum, NOT boolean, for additive future modes `:reconcile`/`:influence`):
```elixir
stripe_native_sync: [
  type: {:in, [:disabled, :advisory]},
  default: :disabled,
  doc: "..."  # MUST state plainly: ":advisory records summaries to an advisory cache for
              # audit/telemetry/the admin read-seam; it does NOT change entitled?/has_active_plan?
              # decisions in v1.x (local mapping stays canonical)." (D-03)
]
```

**Accessor to clone** — `past_due_grace/0` (`:770-771`), because `entitlements/0` is a **raw read** that does NOT merge nested schema defaults (see the `entitlements/0` moduledoc at `:882-910`), so the accessor MUST supply its own default via `Keyword.get/3`:
```elixir
# precedent, config.ex:770-771:
@spec past_due_grace() :: :none | :dunning | pos_integer()
def past_due_grace, do: entitlements() |> Keyword.get(:past_due_grace, :none)
```
127 version (D-03 — add both the raw accessor and the ergonomic predicate):
```elixir
@spec stripe_native_sync() :: :disabled | :advisory
def stripe_native_sync, do: entitlements() |> Keyword.get(:stripe_native_sync, :disabled)

@spec stripe_native_sync?() :: boolean()
def stripe_native_sync?, do: stripe_native_sync() != :disabled
```

> **Planner note:** RESEARCH §Pattern 2 shows a `type: :boolean` draft — that is superseded by D-03's enum decision. Use the enum.

---

### `accrue/lib/accrue/webhook/default_handler.ex` (MODIFY — handler/reducer) — D-04, D-06, D-07, D-08, D-09

**Analog:** in-file. Four distinct in-file patterns to compose.

**(a) Config-gated dispatch clause** — placement mirrors `checkout.session.*` (`:250-253`), runtime gate checked FIRST so the OFF lane early-returns before any `Repo` call (D-04 layer 1):
```elixir
# placement precedent, default_handler.ex:250-253:
defp dispatch("checkout.session." <> action, evt_id, evt_ts, obj)
     when action in ~w(completed expired async_payment_succeeded async_payment_failed) do
  reduce_checkout_session(action, evt_id, evt_ts, obj)
end
```
127 clause (add before the catch-all at `:268`):
```elixir
defp dispatch("entitlements.active_entitlement_summary.updated", evt_id, evt_ts, obj) do
  if Accrue.Config.stripe_native_sync?() do
    reduce_entitlement_summary(evt_id, evt_ts, obj)
  else
    {:ok, :ignored}   # OFF lane: zero Repo call, byte-for-byte Phase-126 behavior (D-04)
  end
end
```

**(b) Monotonic skip-stale guard — REUSE VERBATIM** (`check_stale/2` `:1078-1087`, `stamp_watermark/3` `:1102-1104`). Do NOT reinvent. The 127 reducer keys on `customer` (not `processor_id`) but uses the same helpers:
```elixir
# default_handler.ex:1078-1104 — clone the call shape, reuse the helpers as-is:
defp check_stale(nil, _evt_ts), do: :ok
defp check_stale(%{last_stripe_event_ts: nil}, _evt_ts), do: :ok
defp check_stale(_row, nil), do: :ok
defp check_stale(%{last_stripe_event_ts: last}, evt_ts) do
  case DateTime.compare(evt_ts, last) do
    :lt -> :stale
    _ -> :ok   # :eq and :gt proceed
  end
end
defp stamp_watermark(attrs, evt_ts, evt_id),
  do: Map.merge(attrs, %{last_stripe_event_ts: evt_ts, last_stripe_event_id: evt_id})
```
The stale-skip telemetry to REUSE (D-09 — do NOT invent a variant; just pass `object_type: :entitlement_summary`) — from `reduce_row/5` (`:1062-1070`):
```elixir
:telemetry.execute([:accrue, :webhooks, :stale_event], %{},
  %{object_type: :entitlement_summary, stripe_id: cus_id, event_id: evt_id})
{:ok, :stale}
```

**(c) Orphan-customer tolerance — clone `orphan_charge`** (`reduce_charge` `:840-848`): never raise, never create a customer, emit telemetry + `{:ok, :deferred}` (D-06):
```elixir
# default_handler.ex:840-848:
case customer_stripe_id && Repo.get_by(Customer, processor_id: customer_stripe_id) do
  %Customer{} = customer -> # ...write...
  _ ->
    :telemetry.execute([:accrue, :webhooks, :orphan_charge], %{},
      %{customer_stripe_id: customer_stripe_id})
    {:ok, :deferred}
end
```
127: emit `[:accrue, :webhooks, :orphan_entitlement_summary]` instead (D-06).

**(d) Dual atom/string `get/2`** (`:1136-1140`) — REUSE for reading the untyped raw `obj`. Read `customer` (binary) and `entitlements`→`data` (list) defensively; malformed (missing `customer`, non-list entitlements) → telemetry + `{:ok, :ignored}`, never write garbage (D-06, RESEARCH Pitfall 6):
```elixir
# default_handler.ex:1136-1140:
defp get(%{} = map, key) when is_atom(key) do
  Map.get(map, key) || Map.get(map, Atom.to_string(key))
end
defp get(_, _), do: nil
```

**(e) Ledger call inside the same `Repo.transact`** — clone `record_event/5` (`:1106-1115`) but D-08 is **on-change-only** (material change = sorted `{feature_id, lookup_key}` pairs OR `truncated` differs; first-ever write = material). No ledger row on stale-skip/orphan/byte-identical redelivery (those are telemetry-only). Event `type`: `"entitlements.summary.synced"`; `idempotency_key: "entitlements.summary.synced:" <> evt_id`:
```elixir
# default_handler.ex:1106-1115:
defp record_event(type, subject_type, subject_id, stripe_event_id, opts \\ []) do
  Events.record(%{
    type: type, subject_type: subject_type, subject_id: subject_id,
    data: %{source: "webhook", stripe_event_id: stripe_event_id},
    idempotency_key: Keyword.get(opts, :idempotency_key)
  })
end
```
> D-08: ledger `data` = IDs/counts only, NEVER the raw payload (V7).

**Overall reducer skeleton** is composed in RESEARCH §"Monotonic upsert" (lines 342-369) — that is the assembled clone; verify each helper against the line refs above.

**Discretion (D-Discretion):** the reducer may live as a private clause in `default_handler.ex` OR a small delegated helper module — planner decides. The `ConnectHandler` moduledoc (`connect_handler.ex:1-60`) is the model for documenting WHY this path uses the monotonic-snapshot guard instead of Connect's refetch-canonical (no `lattice_stripe` 1.1 Entitlements API). Note: `ConnectHandler` is selected by `row.endpoint`; the summary event arrives on the default endpoint, so it stays in `DefaultHandler` (RESEARCH §"Alternatives Considered").

---

### `accrue/lib/accrue/entitlements/stripe_sync.ex` (NEW read-only seam, OR sibling fn) — D-11

**Analog:** `accrue/lib/accrue/entitlements/admin.ex` (whole file, 1-50) — the read-only `@doc false`-ish diagnostic seam with a one-way `admin → billing` dependency that NEVER touches the gate.

**Seam pattern to clone** (`admin.ex:34-49`):
```elixir
alias Accrue.Entitlements.Resolver.LocalMap

@spec resolve_for_customer(Accrue.Billing.Customer.t()) ::
        {resolved :: map(), unmapped_price_ids :: [String.t()]}
def resolve_for_customer(%Accrue.Billing.Customer{} = customer) do
  {LocalMap.fold_for_customer(customer), LocalMap.unmapped_entitling_price_ids(customer)}
end
```
**Moduledoc "one-way dependency" stance to clone** (`admin.ex:11-17`): *"`admin → billing/entitlements core`, never the reverse. Nothing under `Accrue.Billing` or the resolver references this module."*

**127 version:** a read-only fn (e.g. `summary_for_customer/1`) that `Repo.get_by(EntitlementSummary, customer_id: customer.id)` and returns the cached row (or `nil`). It is **observational-only** (D-01): the gate path (`entitled?/2`, `has_active_plan?/2`, `Resolver`, `LocalMap`) MUST NOT reference it. Keep it one-way (seam → billing read), never gate → seam.

> **Discretion (D-Discretion):** new `Accrue.Entitlements.StripeSync` module vs. sibling fn in `Accrue.Entitlements.Admin` — planner decides. Either way: one-way, gate path stays cache-free.

---

### `[:accrue, :entitlements, :sync]` span + `[:accrue, :ops, :entitlement_summary_truncated]` (telemetry) — D-09

**Span analog:** `accrue/lib/accrue/entitlements.ex:290` — the `:check` span the `:sync` span deliberately mirrors (the ENT-05 split):
```elixir
# entitlements.ex:290:
Accrue.Telemetry.span([:accrue, :entitlements, :check], metadata, fun)
```
127: wrap the sync write in `Accrue.Telemetry.span([:accrue, :entitlements, :sync], metadata, fun)` (start/stop/exception). `:check` = per-decision telemetry-only; `:sync` = state-change ledger+telemetry.

**Cache-write event (D-09):** `[:accrue, :entitlements, :summary_synced]`, measurements `%{count: 1, entitlement_count: n}`, metadata `%{customer_id, has_more, result: :written | :unchanged}` (`:unchanged` makes a no-op redelivery observable WITHOUT a ledger row). Emit via plain `:telemetry.execute/3` (it is not an ops-namespace event).

**Ops event analog:** `accrue/lib/accrue/telemetry/ops.ex:57-75` `emit/3` — the `connect_account_deauthorized` model (see the canonical-events list at ops.ex:28). Fire **only when `has_more: true`** (a curated "this cache is known-incomplete" signal — NOT a per-sync heartbeat):
```elixir
# ops.ex:60-75 — the hardcoded [:accrue, :ops] prefix + operation_id auto-merge:
def emit(suffix, measurements, metadata) when is_list(suffix) ... do
  event = [:accrue, :ops] ++ suffix
  merged_metadata = Map.put_new_lazy(metadata, :operation_id, fn ->
    Accrue.Actor.current_operation_id() end)
  :telemetry.execute(event, measurements, merged_metadata)
  :ok
end
```
127: `Accrue.Telemetry.Ops.emit(:entitlement_summary_truncated, %{count: 1}, %{customer_id: ...})`.

---

### `accrue/lib/accrue/telemetry/otel.ex` (CONSTRAINT — do NOT widen) — D-09

**Analog/constraint:** `accrue/lib/accrue/telemetry/otel.ex:12-45` `@allowed_attributes` (already includes `:customer_id`, `:result`, `:feature`, `:reason`). **D-09 forbids adding `entitlement_count`/`has_more` to this allowlist** — keep them telemetry-only (bounded/no-PII but keep the OTel surface lean). `:prohibited_keys` at `:47-69` already blocks `payload`/`metadata`/`raw_body` — never log the raw summary (V7). This file is a guardrail to RESPECT, not edit.

---

### `scripts/ci/verify_entitlement_sync_isolation.sh` (NEW — static gate) — D-04 layer 2

**Analog:** `scripts/ci/verify_core_liveview_runtime_free.sh` (whole file, 1-48) — comment-anchored grep, allowlist-by-construction, `exit 1` on hit.

**Grep + allowlist pattern to clone** (`:34-45`):
```bash
hits=$(grep -rnE \
  '^[^#]*(<FORBIDDEN_REFERENCE_ALTERNATIVES>)' \
  "${lib}" \
  --include='*.ex' \
  | grep -v '<ALLOWLISTED_PATH>' \
  || true)

if [[ -n "${hits}" ]]; then
  echo "verify_...: FAIL — ..." >&2
  echo "${hits}" >&2
  exit 1
fi
echo "verify_...: OK"
```
**127 version (D-04):** assert no `EntitlementSummary` / cache-module / `stripe_sync` reference is reachable from the always-on gate path. The `^[^#]*` anchor (so doc-comments/strings don't trip it) and the trailing `|| true` (so a clean grep doesn't fail `set -e`) are load-bearing — copy both verbatim. Scope the grep to the gate-path files specifically: `accrue/lib/accrue/entitlements.ex` and `accrue/lib/accrue/entitlements/resolver/local_map.ex` (and `resolver.ex`). Wire merge-blocking in `docs-contracts-shift-left` (same place `verify_core_liveview_runtime_free.sh` is wired).

---

### `scripts/ci/verify_processor_support_matrix.sh` + `.planning/processor-support-matrix.md` + `accrue/lib/accrue/processor/capabilities.ex` (MODIFY) — D-10

**Analogs (in-file):**
- `capabilities.ex:106-112` — the `entitlements.local_mapping` CONVERGENCE row (all three `"local-identical"`). **NEVER mutate this** (D-10).
- `capabilities.ex:65-94` — the `@provider_support_labels` divergence rows (`swap_plan`, `subscription_item.*`) showing the `%{fake:, stripe:, braintree:}` shape to clone for a NEW row.
- `capabilities.ex:34-62` — the `@core_capability_labels` block with the existing `entitlements: %{local_mapping: ...}` core row.

**127: add a NEW `entitlements.stripe_native_sync` divergence row** (D-10, D-Specifics): `stripe: "native (advisory)"` / `"native (observational)"`; `fake`/`braintree`: `"unsupported"` or `"out of slice"`. Clone the `subscription.swap_plan` row shape (`:67-71`):
```elixir
# capabilities.ex:67-71 — the divergence-row template:
swap_plan: %{
  fake: "testing/local-only",
  stripe: "native",
  braintree: "bounded first-party"
}
```

> **⚠️ PLANNER-CRITICAL CONFLICT to resolve:** `verify_processor_support_matrix.sh:109-112` has a NEGATIVE guard that `exit 1`s if **ANY** `entitlements.*` matrix-markdown row contains `native|unsupported|bounded`:
> ```bash
> if grep -Eq '^\| entitlements\.[a-z_]+ \|.*\b(native|unsupported|bounded)\b' "${matrix}"; then
>   echo "...entitlements row sprouted a per-provider divergence label..." >&2
>   exit 1
> fi
> ```
> D-10 says "add a NEW row, never mutate convergence." But the new row's labels (`native (advisory)`, `unsupported`) WILL match this guard's word-boundary `\b(native|unsupported|bounded)\b` and fail the build. **The planner MUST update this guard in the same PR** to exempt the new `entitlements.stripe_native_sync` row while still protecting `entitlements.local_mapping` (e.g. tighten the negative guard to match only the convergence row, OR add a positive `require_substring` for the exact new row line and exclude it from the negative pattern). This is a same-PR SSOT co-update (code labels + `processor-support-matrix.md` markdown + the drift gate). Use the existing `require_substring`/negative-`grep -Fq` paired idiom (script lines 60-63 positive, 64-102 negative) as the model.

---

### `accrue/test/support/stripe_fixtures.ex` (MODIFY — add `entitlement_summary_event/2`) — D-12

**Analog:** `accrue/test/support/stripe_fixtures.ex:383-395` `webhook_event/3`:
```elixir
@spec webhook_event(String.t(), map(), map()) :: map()
def webhook_event(type, object_payload, overrides \\ %{})
    when is_binary(type) and is_map(object_payload) do
  base = %{
    "id" => "evt_test_" <> rand(),
    "object" => "event",
    "type" => type,
    "created" => DateTime.to_unix(DateTime.utc_now()),
    "data" => %{"object" => object_payload}
  }
  deep_merge(base, overrides)
end
```
**127:** add `entitlement_summary_event/2` that builds the `entitlements.active_entitlement_summary.updated` payload (the exact JSON is in RESEARCH §"Webhook payload shape", lines 296-326): `data.object` = `%{"object" => "entitlements.active_entitlement_summary", "customer" => cus, "livemode" => bool, "entitlements" => %{"object" => "list", "data" => [...≤10 of {id, feature, lookup_key}...], "has_more" => bool, "url" => "..."}}`. NOTE: NO top-level `id` on `data.object` (A4). Delegate to/compose with `webhook_event/3` for the event envelope (`id`/`created`/`type`).

---

### New test files (3) — RESEARCH §Wave 0 Gaps / Validation Architecture

| New test file | Analog | Covers |
|---------------|--------|--------|
| `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` | `accrue/test/accrue/webhook/default_handler_out_of_order_test.exs` | enabled→cache write, stale-skip (`:lt`), tie (`:eq`) proceeds, orphan→`:deferred`, truncated (`has_more: true`), malformed→`:ignored` |
| `accrue/test/property/entitlement_summary_monotonic_property_test.exs` | `accrue/test/property/entitlements_fail_closed_property_test.exs` (+ `stream_data`) | shuffle event order → final cache == highest-ts snapshot (monotonic invariant) |
| `accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs` | (new shape; assert via Ecto `[:accrue, :repo, :query]` telemetry) | sync `:disabled` → ZERO `accrue_entitlement_summaries` reads on an `entitled?/2` call + surface parity with a Phase-126 fixture (D-04 layer 3) |

**Must stay green (existing, do NOT modify):** `accrue/test/property/entitlements_fail_closed_property_test.exs` — proves the fail-closed contract holds with the overlay present (trivially true since the gate never reads the cache, D-01).

---

## Shared Patterns

### Fail-closed gate contract — UNCHANGED (D-01)
**Source:** `accrue/lib/accrue/entitlements.ex:177-187` `resolve/1`.
**Apply to:** the WHOLE phase as an invariant. The sole path to `entitled? == true` is `{:ok, resolved}` from `Resolver.__impl__().resolve/2`; anything else collapses to `:error` (fail-closed). The cache is observational-only and NEVER on this path.
```elixir
defp resolve(billable) do
  case Resolver.__impl__().resolve(billable, []) do
    {:ok, resolved} -> {:ok, resolved}
    _ -> :error
  end
rescue _ -> :error
catch _ -> :error; _, _ -> :error
end
```

### Monotonic watermark (skip-stale) — REUSE VERBATIM
**Source:** `accrue/lib/accrue/webhook/default_handler.ex:1078-1104` (`check_stale/2`, `stamp_watermark/3`).
**Apply to:** the cache write in `reduce_entitlement_summary`. Do not reinvent; reuse the existing private helpers (strict `:lt` → skip + stale telemetry; `:eq`/`:gt` proceed).

### Idempotent ledger append (on-conflict-nothing via partial unique index)
**Source:** `accrue/lib/accrue/events.ex:146-154` `insert_opts/1` + migration `accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs:32-34` (`UNIQUE (idempotency_key) WHERE idempotency_key IS NOT NULL`).
**Apply to:** the D-08 on-change ledger row — set `idempotency_key: "entitlements.summary.synced:" <> evt_id` so Oban retries collapse.
```elixir
defp insert_opts(%{idempotency_key: key}) when is_binary(key) do
  [on_conflict: :nothing,
   conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"},
   returning: true]
end
```

### Zero-cost off-lane (runtime gate checked FIRST)
**Source:** `accrue/lib/accrue/config.ex:770-771` (`past_due_grace/0` raw-read accessor) + the `none_lane_items/1` precedent in `resolver/local_map.ex`.
**Apply to:** both the dispatch clause (early-return `{:ok, :ignored}` before any `Repo` call when disabled) and the read seam (no cache load when disabled). The OFF lane must be provably DB-free (D-04, SC#3).

### Telemetry/log PII exclusion (V7)
**Source:** `accrue/lib/accrue/telemetry/otel.ex:47-69` `@prohibited_keys` (blocks `payload`/`metadata`/`raw_body`).
**Apply to:** all 127 telemetry/ledger — IDs + counts only, never the raw `data` summary blob, never `feature`/`lookup_key` values en masse.

---

## No Analog Found

None. Every artifact maps to a named, source-verified in-codebase analog. (This phase is deliberately ~90% pattern reuse — RESEARCH §"Key insight".)

---

## Metadata

**Analog search scope:** `accrue/lib/accrue/{billing,webhook,entitlements,config,processor,telemetry,events}/`, `accrue/priv/repo/migrations/`, `accrue/test/{support,accrue/webhook,property}/`, `scripts/ci/`.
**Files scanned (read this session):** `subscription_schedule.ex`, `config.ex` (3 ranges), `entitlements/admin.ex`, `default_handler.ex` (3 ranges), `events.ex`, `telemetry/ops.ex`, `telemetry/otel.ex`, `processor/capabilities.ex`, `connect_handler.ex`, `entitlements.ex` (2 ranges), `stripe_fixtures.ex` (2 ranges), `20260414130100_create_accrue_subscription_schedules.exs`, `verify_core_liveview_runtime_free.sh`, `verify_processor_support_matrix.sh`, plus grep-confirmed: `events/event.ex`, `20260411000001_create_accrue_events.exs`, test analog existence.
**Pattern extraction date:** 2026-05-24
