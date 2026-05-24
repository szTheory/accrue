# Phase 125: Provider Honesty + Lifecycle Truth - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 16 (5 new, 11 modified)
**Analogs found:** 16 / 16 (every file has an in-repo analog — this is mirroring work, not greenfield)

> **Read-before-edit note for the planner:** This phase is overwhelmingly *additive mirroring*. Each file below has an exact in-tree analog whose surrounding style must be copied verbatim (the same `@doc`/`@spec` shape, the same fail-closed head ordering, the same `from(s in query, where: ...)` fragment shape). The danger is *divergence*, not novelty (RESEARCH "Key insight"). Two cross-cutting disciplines bind every slice: the **predicate ↔ Query-fragment twin invariant** and the **SSOT-mirror same-PR co-update**.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/processor/capabilities.ex` | config (support contract) | transform | (self — existing `subscription`/`invoice` groups in same file) | exact (in-file sibling) |
| `accrue/lib/accrue/processor/fake.ex` `capabilities/0` | adapter | transform | (self — existing groups in same `capabilities/0`) | exact (in-file sibling) |
| `accrue/lib/accrue/processor/stripe.ex` `capabilities/0` | adapter | transform | (self — same) | exact (in-file sibling) |
| `accrue/lib/accrue/processor/braintree.ex` `capabilities/0` | adapter | transform | (self — same) | exact (in-file sibling) |
| `scripts/ci/verify_processor_support_matrix.sh` | config (CI gate) | batch/static | (self — `require_substring` + stale-row guards in same script) | exact (in-file sibling) |
| `.planning/processor-support-matrix.md` | config (doc SSOT) | transform | (self — existing capability-contract table) | exact (in-file sibling) |
| `accrue/lib/accrue/billing/subscription.ex` `entitling?/1` | model (predicate) | transform | `active?/1`@147, `paused?/1`@201, `canceled?/1`@163 (same file) | exact (composes siblings) |
| `accrue/lib/accrue/billing/query.ex` `entitling/1` + grace-widen | model (query fragment) | CRUD (read) | `active/1`@30, `canceled/1`@57, `dunning_sweep_candidates/2`@80 (same file) | exact (sibling fragments) |
| `accrue/lib/accrue/entitlements/resolver/local_map.ex` `fold_active/1` | service (resolver) | CRUD (read) | (self — current `fold_active/1`@66) | exact (retarget in place) |
| `accrue/lib/accrue/entitlements/resolver.ex` `resolved` type | model (behaviour type) | transform | (self — current `@type resolved`@38) | exact (extend in place) |
| `accrue/lib/accrue/entitlements.ex` reason computation | service (gate API) | request-response | (self — `entitled?/3` reason `cond`@62-77) | exact (extend in place) |
| `accrue/lib/accrue/config.ex` `past_due_grace` key + accessor | config | transform | `:dunning` schema@228 + `dunning/0`@746; `{:or,..}` unions@281/398 | exact (sibling schema entry) |
| `accrue/lib/accrue/entitlements/past_due_grace.ex` (NEW) | utility (pure helper) | transform | `dunning_sweep_candidates/2`@80 cutoff math (inverted); `canceling?/1`@175 clock-compare | role+flow match |
| `accrue/guides/lifecycle_semantics.md` `entitling` entry + table | config (doc SSOT) | transform | existing `active`/`canceling`/`paused`/`past_due`/`ended` glossary entries@133-160 | exact (in-doc sibling) |
| `accrue/test/accrue/entitlements/provider_honesty_test.exs` (NEW) | test | event-driven (proof) | `local_map_test.exs` env-mutation harness + `capabilities_test.exs` label asserts | role+flow match |
| lifecycle truth-table pin test (extend `subscription_predicates_test.exs` OR new `entitling_test.exs`) | test | transform | `subscription_predicates_test.exs`@24-78 struct-literal pattern | exact (sibling test) |

---

## Pattern Assignments

### `accrue/lib/accrue/processor/capabilities.ex` (config, transform)

**Analog:** the existing `subscription:` / `subscription_item:` / `invoice:` groups *in the same module* — copy their nesting verbatim, add an `entitlements:` group to BOTH `@support_labels` and `@provider_support_labels`.

**`@support_labels` shape** (capabilities.ex:11-60 — note "all first-party" is the canonical convergence label already in use):
```elixir
@support_labels %{
  # ... existing customer / payment_method / subscription / subscription_item /
  #     invoice / checkout / billing_portal / webhook groups (verbatim) ...
  webhook: %{verify: "all first-party", parse: "all first-party"}
}
```
Add (D-02 — ONE `local_mapping` row; the optional `unmapped_plan_fail_closed` row is the planner's reversible call per Open Question #1, lean minimal):
```elixir
entitlements: %{
  local_mapping: "all first-party"
}
```

**`@provider_support_labels` shape** (capabilities.ex:62-99 — every existing provider lane encodes *divergence*: `native` / `bounded first-party` / `unsupported` / `testing/local-only`; this row is the FIRST to encode *convergence*, hence the new `"local-identical"` term, D-02/D-03):
```elixir
@provider_support_labels %{
  subscription: %{
    swap_plan: %{fake: "testing/local-only", stripe: "native", braintree: "bounded first-party"},
    # ...
  },
  # ... subscription_item / invoice groups (verbatim) ...
}
```
Add:
```elixir
entitlements: %{
  local_mapping: %{
    fake: "local-identical",
    stripe: "local-identical",
    braintree: "local-identical"
  }
}
```

**Accessors are reused VERBATIM — do NOT touch** `support_label/1`@123-131, `provider_support_label/2`@133-143, `for/1`@101-113, `supports?/2`@115-121. They read `@support_labels` / `@provider_support_labels` via `get_in/2`, so adding the group is the only change required for them to resolve the new path.

---

### `accrue/lib/accrue/processor/{fake,stripe,braintree}.ex` `capabilities/0` (adapter, transform)

**Analog:** each adapter's existing `capabilities/0` map (Fake@220-240, Stripe@79-99, Braintree@17-44). Add ONE key to the returned map — identical literal in all three (the honest claim is sameness, D-03):
```elixir
@impl Accrue.Processor
def capabilities do
  %{
    customer: %{create: true, retrieve: true, update: true},
    # ... existing groups ...
    webhook: %{verify: true, parse: true},
    entitlements: %{local_mapping: true}   # <-- ADD, byte-identical across all three
  }
end
```
**Note:** Braintree's map is keyed differently in places (`payment_method` has `create/update/delete/set_default: true`, `subscription` carries `cancel_at_period_end: false`) — leave all of that untouched; only append the `entitlements:` key. The point of D-03 is that this ONE row is identical even though the gateway rows differ.

---

### `scripts/ci/verify_processor_support_matrix.sh` (config / CI gate, static)

**Analog:** the script's own `require_substring` helper (lines 13-20) + the positive row assertions (22-59) + the NEGATIVE stale-row guards (60-98) + the final `echo OK` (100).

**`require_substring` helper** (verbatim — already exists, reuse it):
```bash
require_substring() {
  local needle="$1"
  local label="$2"
  if ! grep -Fq "${needle}" "${matrix}"; then
    echo "verify_processor_support_matrix: matrix missing ${label} (expected substring: ${needle})" >&2
    exit 1
  fi
}
```

**Positive assertions to ADD** (mirror the existing swap_plan row assertion style at line 26, `| subscription.swap_plan | testing/local-only | native | bounded first-party | official active-subscription-change |`). D-08 requires: the entitlements row literal + the identity prose + the ENT-10 deferral honesty:
```bash
require_substring "| entitlements.local_mapping | local-identical | local-identical | local-identical | all first-party |" "entitlements local-mapping row"
require_substring "behaves identically across Stripe, Braintree, and Fake" "entitlements identity prose"
require_substring "zero processor calls" "entitlements zero-call prose"
require_substring "local mapping remains the canonical default" "ENT-10 deferral honesty"
```

**NEGATIVE divergence guard to ADD** (D-08 — mirror the existing stale-row guards at lines 60-98 which use `if grep -Fq ... then echo >&2; exit 1; fi`; this one uses `grep -Eq` to catch ANY divergence label on an entitlements row, the drift-back-toward-Phase-127 trap):
```bash
if grep -Eq '\| entitlements\.[a-z_]+ \|[^|]*\b(native|unsupported|bounded)\b' "${matrix}"; then
  echo "verify_processor_support_matrix: entitlements row sprouted a per-provider divergence label (drift toward Phase 127 ahead of schedule)" >&2
  exit 1
fi
```
**Placement:** positive `require_substring` lines go in the block ending at line 59; the negative `grep -Eq` guard goes with the other `if grep` guards (60-98), BEFORE the final `echo "verify_processor_support_matrix: OK"` at line 100.

---

### `.planning/processor-support-matrix.md` (config / doc SSOT, transform)

**Analog:** the existing `| Capability | Fake | Stripe | Braintree | Public label |` table (lines 31-58) — its header literal is asserted by the gate (line 22), and the swap_plan/preview rows (45-54) are the divergence-label template the entitlements row deliberately contrasts against (D-04 "makes the contrast legible").

**Row to ADD** (must EXACTLY match the bash `require_substring` literal above — same-PR co-update, D-09):
```markdown
| entitlements.local_mapping | local-identical | local-identical | local-identical | all first-party |
```
**Prose to ADD** (a short Entitlements section near the table, carrying the three gate-pinned strings — `"behaves identically across Stripe, Braintree, and Fake"`, `"zero processor calls"`, `"local mapping remains the canonical default"`). Model the wording on the existing checkout/portal honesty paragraph at line 60 ("The checkout and billing-portal rows stay visible because the public API shape is shared while the provider implementation stays honest..."). The entitlements paragraph inverts that framing: the public API shape AND the implementation are identical by construction.

---

### `accrue/lib/accrue/billing/subscription.ex` `entitling?/1` (model / predicate, transform)

**Analog:** the three composed predicates in the SAME file — `active?/1`@147-149, `paused?/1`@201-205, `canceled?/1`@163-167. Compose them; do NOT re-derive from raw `.status` (the `Accrue.Credo.NoRawStatusAccess` rule exempts this module — see Shared Patterns — but composition is still the convention and avoids the 5 edge-case traps).

**Existing predicate shape to mirror** (the `%__MODULE__{}` head + `%{}` map head + catch-all `false`):
```elixir
@spec active?(%__MODULE__{} | map()) :: boolean()
def active?(%__MODULE__{status: s}) when s in [:active, :trialing], do: true
def active?(%{status: s}) when s in [:active, :trialing], do: true
def active?(_), do: false
```

**New predicate to ADD** (composition — single-clause, RESEARCH Pattern 2):
```elixir
@doc """
True iff the subscription's pure lifecycle grants entitlement:
active (incl. trialing and paid-through cancel_at_period_end) AND not paused AND not terminated.
This is the single source of truth for which lifecycle states grant entitlement.
See guides/lifecycle_semantics.md for the truth table.
"""
@spec entitling?(%__MODULE__{} | map()) :: boolean()
def entitling?(sub), do: active?(sub) and not paused?(sub) and not canceled?(sub)
```
**Why this is complete** (D-10): `canceling?/1`@175 (paid-through `cancel_at_period_end`) is auto-covered because such rows are `status: :active` → `active?` true, `paused?`/`canceled?` false. The moduledoc's predicate list (subscription.ex:18-26) should gain an `entitling?/1` bullet for consistency.

---

### `accrue/lib/accrue/billing/query.ex` `entitling/1` + grace-widen fragment (model / query, CRUD-read)

**Analog:** `active/1`@30-32 (status-only filter), `canceled/1`@57-61 (the `not is_nil(s.ended_at)` shape), `dunning_sweep_candidates/2`@80-92 (the `:past_due` status + cutoff template for the grace-widen fragment).

**Base fragment shape to mirror** (`active/1`):
```elixir
@doc "Subscriptions counted as active (includes `:trialing`)."
@spec active(Ecto.Queryable.t()) :: Ecto.Query.t()
def active(query \\ Subscription) do
  from(s in query, where: s.status in [:active, :trialing])
end
```

**New `entitling/1` to ADD** (the twin of `entitling?/1`; CRITICAL gotcha from RESEARCH Pattern 2 — add ONLY `is_nil(s.pause_collection)`, NOT the full `paused/1` OR-clause, because `active/1`'s status set already excludes legacy `:paused`):
```elixir
@doc "Subscriptions whose lifecycle grants entitlement: active/trialing, not paused, not ended."
@spec entitling(Ecto.Queryable.t()) :: Ecto.Query.t()
def entitling(query \\ Subscription) do
  from(s in query,
    where:
      s.status in [:active, :trialing] and
        is_nil(s.pause_collection) and
        is_nil(s.ended_at)
  )
end
```

**Grace-widen fragment to ADD** (D-18 — model on `dunning_sweep_candidates/2`@80-92 which already uses strict `:past_due`; ADD `:past_due` to the status set, KEEP both nil guards; the clock check stays in Elixir per D-18, so this fragment does NOT do the cutoff math):
```elixir
@doc "Entitlement candidates incl. :past_due rows (grace overlay); per-row window check stays in Elixir."
@spec entitling_with_grace_candidates(Ecto.Queryable.t()) :: Ecto.Query.t()
def entitling_with_grace_candidates(query \\ Subscription) do
  from(s in query,
    where:
      s.status in [:active, :trialing, :past_due] and
        is_nil(s.pause_collection) and
        is_nil(s.ended_at)
  )
end
```
**Pitfall 3 guard:** the widen status set adds `:past_due` ONLY — never `:unpaid` (D-17; `:unpaid` is dunning-terminal). Do NOT reuse `Query.past_due/1`@64-67 (it includes `:unpaid`).

**Query module IS Credo-exempt** for `s.status in [...]` (see Shared Patterns) — these `in` clauses are sanctioned here.

---

### `accrue/lib/accrue/entitlements/resolver/local_map.ex` `fold_active/1` (service / resolver, CRUD-read)

**Analog:** the current `fold_active/1`@66-95 — retarget its base fetch in place (D-13/D-18).

**Current base fetch** (local_map.ex:67-81 — the WR-04 local `where(is_nil(ended_at))`@77 folds INTO `Query.entitling/1`, becoming redundant and removable):
```elixir
active_items =
  Subscription
  |> Query.active()
  |> where([s], is_nil(s.ended_at))            # WR-04 — moves into Query.entitling/1
  |> where([s], s.customer_id == ^customer_id)
  |> join(:inner, [s], i in SubscriptionItem, on: i.subscription_id == s.id)
  |> select([_s, i], {i.price_id, i.quantity})
  |> Accrue.Repo.all()
```

**Conditional cost-aware retarget** (D-18, RESEARCH Pattern 3 — common case = zero query change; grace lane widens AND needs a richer select because `within_grace?/2` runs per-row in Elixir, RESEARCH Pattern 3 Note + Pitfall 3a):
```elixir
defp base_query(customer_id) do
  case Accrue.Config.past_due_grace() do
    :none -> Query.entitling()
    _grace -> Query.entitling_with_grace_candidates()
  end
  |> where([s], s.customer_id == ^customer_id)
end
```
- **`:none` lane:** keep the lean `select([_s, i], {i.price_id, i.quantity})` and fold exactly as today.
- **grace lane:** the select MUST also carry the subscription row (or `s.status` + `s.past_due_since`) so `PastDueGrace.within_grace?/2` can be evaluated per row; DROP `:past_due` rows that fail the window BEFORE folding their `price_id` into `active_plans`/`features`/`quantities`; tag kept-via-grace plans into the resolved map's new field (see below).
- Use `Subscription.dunning_sweepable?/1`@217-220 (strict `:past_due`, Credo-clean) as the per-row "is this a grace candidate?" check — NOT a raw `sub.status == :past_due` (which would trip the Credo rule in this module — see Shared Patterns).

The `merge_plan/4`@97-121, `handle_unmapped/3`@123-128, and `catalog/0`@132-145 helpers are reused unchanged. `@empty`@36 gains the new field (see resolver.ex below).

---

### `accrue/lib/accrue/entitlements/resolver.ex` `resolved` type (model / behaviour type, transform)

**Analog:** the current `@type resolved`@38-43 — extend additively (D-19; do NOT add a `capabilities/0` callback, D-01).

**Current type:**
```elixir
@type resolved :: %{
        plan: term(),
        active_plans: MapSet.t(),
        features: MapSet.t(),
        quantities: map()
      }
```
**Add ONE field** (Open Question #2 recommends a `:grace_plans` MapSet, consistent with the existing `:active_plans` MapSet shape, default `MapSet.new()` when grace disabled — zero-cost):
```elixir
@type resolved :: %{
        plan: term(),
        active_plans: MapSet.t(),
        features: MapSet.t(),
        quantities: map(),
        grace_plans: MapSet.t()
      }
```
Update the typedoc bullet list@28-37 to document `:grace_plans` (the plans admitted via the past-due grace window, used by `Accrue.Entitlements` to select the `:past_due_grace` reason). `@empty` in `local_map.ex`@36 must add `grace_plans: MapSet.new()`.

---

### `accrue/lib/accrue/entitlements.ex` reason computation (service / gate API, request-response)

**Analog:** the `entitled?/3` reason `cond`@62-77 (and the parallel `cond`s in `has_active_plan?/3`@91-112, `features_for/1`@119-131, `entitlement_quantity/2`@138-152). The reason atom flows into `span/6`@232-244 as `:reason` metadata.

**Current reason selection** (entitled?/3@63-77):
```elixir
{result, reason} =
  case resolve(billable) do
    {:ok, %{features: features} = resolved} ->
      cond do
        MapSet.member?(features, feature) -> {true, :entitled}
        empty?(resolved) -> {false, :no_active_subscription}
        true -> {false, :not_entitled}
      end

    :error ->
      {false, :error}
  end

span(billable, feature, result, reason, opts, fn -> result end)
```
**Extend** (D-19 — add `:past_due_grace` when the affirmative match came via a grace plan, `:past_due_expired` when denied specifically because a past-due window lapsed; read these off the resolved map's new `:grace_plans` field — no re-query). The existing `:reason` is already OTel-allowlisted (Phase 123 D-19), so only the atom *values* change; NO new event, NO `Telemetry.Ops.emit` (D-19/D-21). Keep the fail-closed `:error` sentinel head unchanged.

**Telemetry house style (unchanged):** the `span/6` helper@232-243 builds metadata BEFORE opening the span (decision must be known first); `subject_id`@222-226 is internal id only (PII-safe).

---

### `accrue/lib/accrue/config.ex` `past_due_grace` key + accessor (config, transform)

**Analog:** the `:dunning` schema entry@228-242 (for the keyword-list/`type:`/`default:`/`doc:` shape), the in-file `{:or, [...]}` union precedents (`reply_to_email`@281, `billable`@398), and the `dunning/0`@746-747 accessor (the accessor shape to mirror exactly).

**Schema entry to ADD** — goes in the nested `:entitlements` schema's `keys:` list (config.ex:359-419, alongside `plans`/`resolver`/`unmapped_action`/`billable`/`on_deny`/`deny_path`). Verbatim from D-16:
```elixir
past_due_grace: [
  type: {:or, [{:in, [:dunning, :none]}, :pos_integer]},
  default: :none,
  doc: "Entitlement access for :past_due subscriptions. :none (default) fails closed " <>
       "immediately. :dunning honors the dunning grace window (reuses " <>
       "Accrue.Config.dunning()[:grace_days]). A positive integer N honors an " <>
       "entitlement-specific N-day window. Grace grants are affirmative, resolved, " <>
       "configured decisions — never a fail-open."
]
```
**No custom validator** — NimbleOptions 1.x validates `{:or, [{:in, [...]}, :pos_integer]}` natively (D-16; same schema already uses `{:or,..}` + `{:in,..}` — see `unmapped_action`@391 `type: {:in, [:deny, :raise]}`). Boot-validation is automatic via the existing `validate_at_boot!/0`@499-511 (it runs `NimbleOptions.validate!/2` over the whole `@schema` — no edit needed there).

**Accessor to ADD** (mirror `dunning/0`@746-747; D-16 says read from the `entitlements()` keyword with `:none` default):
```elixir
@doc """
Returns the past-due entitlement grace policy: `:none` (default, fail-closed),
`:dunning` (reuse the dunning grace window), or a positive integer of days.
"""
@spec past_due_grace() :: :none | :dunning | pos_integer()
def past_due_grace, do: entitlements() |> Keyword.get(:past_due_grace, :none)
```
**Note:** `entitlements/0`@874-886 does a RAW read (no nested defaults) + `Keyword.put_new/3` for the three guard keys; `past_due_grace/0` adds its own `:none` default via `Keyword.get/3` for the same reason (the raw read does not normalize nested `:entitlements` keys). The `:dunning`→`grace_days` resolution (config.ex `dunning()`@747 returns `[..., grace_days: 14, ...]`) is done by the RESOLVER when widening, not by this accessor (D-17/RESEARCH Pattern 4 "Grace-days resolution").

---

### `accrue/lib/accrue/entitlements/past_due_grace.ex` (NEW — utility / pure helper, transform)

**Analog:** `dunning_sweep_candidates/2`@80-92 cutoff math (inverted — sweeper keeps rows OLDER than grace, entitlement keeps rows YOUNGER), and `canceling?/1`@175-191 for the `DateTime.compare/2` + `Accrue.Clock.utc_now/0` clock pattern.

**Clock pattern to mirror** (`canceling?/1` — clock via `Accrue.Clock`, NEVER `DateTime.utc_now/0`):
```elixir
def canceling?(%__MODULE__{status: :active, cancel_at_period_end: true, current_period_end: %DateTime{} = cpe}) do
  DateTime.compare(cpe, Accrue.Clock.utc_now()) == :gt
end
```
**Cutoff math to mirror (inverted)** (`dunning_sweep_candidates/2`@83): `cutoff = DateTime.add(Accrue.Clock.utc_now(), -grace_days * 86_400, :second)`; the sweeper sweeps `past_due_since < cutoff`, entitlement grants `past_due_since >= cutoff`.

**New module** (D-17 — pure, fail-closed on nil `past_due_since`, multi-head with catch-all `false`, mirroring the predicate house style):
```elixir
defmodule Accrue.Entitlements.PastDueGrace do
  @moduledoc "Pure, clock-driven past-due grace-window check. Fail-closed on missing past_due_since."

  @spec within_grace?(map(), pos_integer()) :: boolean()
  def within_grace?(%{past_due_since: nil}, _grace_days), do: false

  def within_grace?(%{past_due_since: %DateTime{} = since}, grace_days)
      when is_integer(grace_days) and grace_days > 0 do
    cutoff = DateTime.add(Accrue.Clock.utc_now(), -grace_days * 86_400, :second)
    DateTime.compare(since, cutoff) != :lt   # since >= cutoff -> still in window
  end

  def within_grace?(_sub, _grace_days), do: false
end
```
**Layer placement (D-14):** this lives under `entitlements/` (config-coupled grace, reads `:entitlements`/`:dunning`) — NEVER on `Subscription` (which must not read config). The one-way dependency entitlements→billing stays clean.

---

### `accrue/guides/lifecycle_semantics.md` `entitling` entry + truth table (config / doc SSOT, transform)

**Analog:** the existing State glossary entries@133-160 (`active`/`canceling`/`paused`/`past_due`/`ended`) — each is a `### name` heading + a short prose paragraph that points at the predicate. Add an `### entitling` entry in the same shape, plus the D-12 truth table with the D-20 past-due footnote.

**Existing entry shape to mirror** (`active`@133-136):
```markdown
### `active`

The subscription currently counts for entitlement purposes. In Accrue this
includes trialing subscriptions as well as normal active rows.
```
**Truth table to render** (D-12/D-20 — the spec; `:past_due` is the only knob-controlled row, footnote it):

| Status / modifier | Entitled? | Basis |
|---|:---:|---|
| `:trialing` | ✅ | `active?` includes trialing |
| `:active` | ✅ | normal paid-active |
| `:active` + `cancel_at_period_end`, period future (`canceling?`) | ✅ | paid-through |
| `:active` + `pause_collection` non-nil | ✗ | `paused?` overrides status (D-11 gap closed) |
| `:active` + `ended_at` non-nil | ✗ | `canceled?` terminal override (WR-04) |
| `:paused` (legacy status) | ✗ | `paused?` |
| `:past_due` | ✗ default / ✅ in-grace | knob (`past_due_grace`) |
| `:unpaid` | ✗ | dunning-terminal; grace does NOT extend |
| `:canceled` / `:incomplete_expired` / any `ended_at` | ✗ | `canceled?` |
| `:incomplete` | ✗ | initial payment not yet succeeded |

The footnote should state grace is an affirmative configured grant (fail-closed contract preserved), measured from `past_due_since` via `Accrue.Clock`, surfaced as `reason: :past_due_grace` / `:past_due_expired`. **Do NOT touch the PUBLIC `accrue/guides/entitlements.md` (Phase 126, D-07).**

---

### `accrue/test/accrue/entitlements/provider_honesty_test.exs` (NEW — test, proof)

**Analog:** `local_map_test.exs`@1-49 (the `:entitlements` env-mutation harness + `async: false` + `on_exit` restore + `Accrue.Test.Factory.active_subscription/1` seeding) AND `capabilities_test.exs`@57-148 (the `support_label`/`provider_support_label` literal-assertion style).

**Env-mutation harness to mirror** (local_map_test.exs:36-49):
```elixir
use Accrue.BillingCase, async: false   # async:false because it mutates app env

setup do
  prev = Application.get_env(:accrue, :entitlements)
  Application.put_env(:accrue, :entitlements, @entitlements)
  on_exit(fn ->
    if prev, do: Application.put_env(:accrue, :entitlements, prev),
             else: Application.delete_env(:accrue, :entitlements)
  end)
  :ok
end
```
**Provider-loop proof to add** (D-05 — loop the three processors as `:processor`, seed identical local state ONCE, assert the three `resolved` maps `==`, AND zero processor calls):
```elixir
for processor <- [Accrue.Processor.Fake, Accrue.Processor.Stripe, Accrue.Processor.Braintree] do
  Application.put_env(:accrue, :processor, processor)
  {:ok, resolved} = LocalMap.resolve(billable, [])
  # collect; after loop assert all three resolved maps == each other
end
```
**Zero-call proof mechanism** (RESEARCH "Don't Hand-Roll" + Assumption A2 — pick one):
1. **Structural** (strongest, simplest): `LocalMap.resolve/2` takes NO `:processor` argument and reads only `Accrue.Repo` — a code comment + the `==` equality across providers IS the proof. Swapping `:processor` is safe precisely because the resolver ignores it (no Stripe/Braintree network occurs).
2. **Regression guard:** `Accrue.Processor.Fake.reset/0`@99-100 zeros all counters; snapshot Fake state before/after `resolve/2` and assert counters unchanged. (Fake state is read via `:sys.get_state/1` — no public arbitrary-counter accessor was confirmed, A2.)
3. **Telemetry guard:** attach a `:telemetry` handler to `[:accrue, :processor, :_, :_]` and assert it never fires.

**Capability-label mirror asserts to add** (the code-side twin of the bash gate, D-05):
```elixir
assert Capabilities.support_label([:entitlements, :local_mapping]) == "all first-party"
for p <- [:fake, :stripe, :braintree] do
  assert Capabilities.provider_support_label(p, [:entitlements, :local_mapping]) == "local-identical"
end
```

---

### lifecycle truth-table pin test (extend `subscription_predicates_test.exs` OR new `entitling_test.exs`) (test, transform)

**Analog:** `subscription_predicates_test.exs`@1-85 — pure struct-literal predicate tests; `async: true`; `setup` starts the Fake clock (`Accrue.Processor.Fake.start_link/1` + `reset/0`) so `canceling?/1`'s `Clock.utc_now/0` resolves.

**Setup to mirror** (subscription_predicates_test.exs:12-22):
```elixir
setup do
  Application.put_env(:accrue, :env, :test)
  case Accrue.Processor.Fake.start_link([]) do
    {:ok, _} -> :ok
    {:error, {:already_started, _}} -> :ok
  end
  :ok = Accrue.Processor.Fake.reset()
  :ok
end
```
**8-status pin to add** (D-14/D-12 — exhaustive struct-literal enumeration; MUST include the two gap rows the table flags):
```elixir
test "entitling?/1 truth table over all statuses and modifiers" do
  now = Accrue.Clock.utc_now()
  future = DateTime.add(now, 7, :day)
  past = DateTime.add(now, -1, :day)

  assert Subscription.entitling?(%Subscription{status: :trialing})
  assert Subscription.entitling?(%Subscription{status: :active})
  assert Subscription.entitling?(%Subscription{status: :active, cancel_at_period_end: true, current_period_end: future})
  refute Subscription.entitling?(%Subscription{status: :active, pause_collection: %{"behavior" => "void"}})  # D-11 gap
  refute Subscription.entitling?(%Subscription{status: :active, ended_at: past})                              # WR-04
  refute Subscription.entitling?(%Subscription{status: :paused})
  refute Subscription.entitling?(%Subscription{status: :past_due})    # pure-lifecycle, pre-grace
  refute Subscription.entitling?(%Subscription{status: :unpaid})
  refute Subscription.entitling?(%Subscription{status: :canceled})
  refute Subscription.entitling?(%Subscription{status: :incomplete})
  refute Subscription.entitling?(%Subscription{status: :incomplete_expired})
end
```
**Twin-invariant DB cross-check** (Pitfall 2 — the strongest drift guard; needs a DB-backed case, so a `Repo`-backed test, e.g. extending `query_test.exs` or `local_map_test.exs`): seed each status (incl. the `status: :active` + `pause_collection` row) and assert `Subscription.entitling?(row) == (row.id in (Query.entitling() |> Repo.all() |> Enum.map(& &1.id)))`.

---

## Shared Patterns

### SSOT-mirror same-PR co-update (Slices A + B)
**Sources:** `accrue/lib/accrue/processor/capabilities.ex` (code labels) ↔ `.planning/processor-support-matrix.md` (doc) ↔ `scripts/ci/verify_processor_support_matrix.sh` (gate).
**Apply to:** the `entitlements:` capability row + the matrix doc row + the bash assertions.
**Rule:** all three change in ONE PR (`processor_support_matrix_public_ssot_capabilities_code_mirror_same_pr_co_update`, Phase 124 D-06 / Pitfall 5). The bash literal at the gate MUST byte-match the matrix-doc table row (`grep -Fq`). Land Slice A (capabilities + 3 adapters) and Slice B (doc + gate) together. The gate rides the existing `docs-contracts-shift-left` CI job — no new CI step (D-09).

### Predicate ↔ Query-fragment twin invariant (Slice C)
**Sources:** every `Accrue.Billing.Subscription` predicate has a matching `Accrue.Billing.Query` fragment (the moduledocs in both files@subscription.ex:27-28 and query.ex:1-12 declare this contract).
**Apply to:** `entitling?/1` (predicate) MUST get `entitling/1` (fragment) with identical semantics. Author them together; cross-check with a DB test (Pitfall 2). The fragment's `is_nil(s.pause_collection)` is the SQL twin of `paused?/1`'s `is_map(pause_collection)` head.

### Fail-closed predicate / gate style
**Sources:** every `?` predicate ends in `def x?(_), do: false` (subscription.ex:139/149/167/205); the gate API collapses every error to the fail-closed value (`entitlements.ex`@72-74 `:error -> {false, :error}`; `resolve/2`@161-171 `rescue`/`catch` → `:error`).
**Apply to:** `entitling?/1` (catch-all `false`), `within_grace?/2` (catch-all `false`, fail-closed on nil `past_due_since`). A grace grant is still an affirmative resolved+configured decision — never fail-open (D-15).

### Clock mandate (testable time)
**Source:** `accrue/lib/accrue/clock.ex` `utc_now/0`@25-31 — delegates to the Fake test clock in `:test`.
**Apply to:** `PastDueGrace.within_grace?/2` and any test computing `future`/`past` offsets. NEVER `DateTime.utc_now/0` directly (untestable; the existing `canceling?/1`@180 and `dunning_sweep_candidates/2`@83 both route through `Accrue.Clock`).

### Credo `NoRawStatusAccess` exemption map (binds where raw `.status` is legal)
**Source:** `accrue/credo_checks/accrue/credo/no_raw_status_access.ex`@40-42, @64-71.
**Resolves Open Question #3 / Assumption A1 (definitively):**
- The rule flags `expr.status == :<status>` and `expr.status in [..., :<status>, ...]` (lines 107-164).
- **Exempt modules** (`@exempt_module_prefixes`@42): `Accrue.Billing.Subscription` and `Accrue.Billing.Query` ONLY → the `s.status in [:active, :trialing, :past_due]` clauses in `Query.entitling/1` and the grace-widen fragment are SANCTIONED.
- **Exempt files** (`exempt_file?/1`@64-71): anything under `test/` → all the new tests can use raw struct `status:` freely.
- **NOT exempt:** `Accrue.Entitlements.*` (incl. `PastDueGrace` and the `LocalMap` resolver). So a bare `sub.status == :past_due` in the grace clause WOULD trip the rule. **Route through `Subscription.dunning_sweepable?/1`**@217-220 (exactly strict `:past_due`, Credo-clean, already exists) for the per-row grace-eligibility check (Pitfall 4 / Open Question #3 recommendation confirmed).

### Config schema: NimbleOptions union, no custom validator
**Source:** `accrue/lib/accrue/config.ex` `{:or, [...]}` precedents (`reply_to_email`@281, `billable`@398) and `{:in, [...]}` (`unmapped_action`@391); boot via `validate_at_boot!/0`@499-511.
**Apply to:** the `past_due_grace` `{:or, [{:in, [:dunning, :none]}, :pos_integer]}` type — native NimbleOptions, no `{:custom, ...}` validator (D-16, RESEARCH Don't-Hand-Roll). It validates automatically at boot via the existing whole-`@schema` `NimbleOptions.validate!/2`.

---

## No Analog Found

None. Every file in scope has an exact or close in-repo analog (this phase is mirroring/additive work by design — RESEARCH "codebase-mirroring work, not greenfield"). The two NEW modules (`PastDueGrace`, `provider_honesty_test`) and two NEW-or-extended tests reuse existing math/harness patterns rather than introducing novel structure.

## Metadata

**Analog search scope:** `accrue/lib/accrue/{processor,billing,entitlements,jobs}/`, `accrue/lib/accrue/{config,clock}.ex`, `accrue/credo_checks/`, `accrue/test/accrue/{entitlements,billing,processor}/`, `accrue/guides/`, `scripts/ci/`, `.planning/`.
**Files scanned:** 21 (all read this session; line numbers verified against live source).
**Pattern extraction date:** 2026-05-23
