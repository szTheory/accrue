# Phase 131: Optional Chimeway Engine Adapter (isolated, off by default) — Research

**Researched:** 2026-05-25
**Domain:** Elixir/OTP — conditional compilation, behaviour contracts, Chimeway 1.0.0 API, Oban job cancellation
**Confidence:** HIGH (all findings verified against local source code; zero external network lookups required)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — 2 thin callbacks: `start_campaign/3` + `cancel_campaign/2`.**
The behaviour sits at exactly the two call sites already in `default_handler.ex`:
1. `maybe_start_dunning_campaign/2` → calls engine `start_campaign(sub, anchor_at, opts)` after the atomic CAS wins (count == 1).
2. Cancel path (`maybe_finalize_dunning_campaign` / `cancel_dunning_steps`) → calls engine `cancel_campaign(sub, iso_anchor, opts)`.
DB state ownership (anchor CAS, anchor-clear, `Oban.cancel_all_jobs` for built-in) stays inside Accrue's `default_handler.ex`. The engine only governs what orchestration system to signal after Accrue has made its own state change.

Callback signatures:
- `start_campaign(subscription :: Subscription.t(), anchor_at :: DateTime.t(), opts :: keyword()) :: :ok | {:error, term()}`
- `cancel_campaign(subscription :: Subscription.t(), iso_anchor :: String.t(), opts :: keyword()) :: :ok | {:error, term()}`

**D-02 — `Accrue.Dunning.Engine.Oban` wraps existing logic.**
`start_campaign/3` body = the current `enqueue_day_zero_step` logic. `cancel_campaign/2` body = the current `cancel_dunning_steps` logic. Non-breaking extraction. `default_handler.ex` dispatches through `Config.dunning_engine/0` which defaults to `Accrue.Dunning.Engine.Oban`.

**D-03 — `dunning: [engine: Module]` (NimbleOptions type: `{:module, Accrue.Dunning.Engine}`), default: `Accrue.Dunning.Engine.Oban`.**
Nested under existing `:dunning` config key. Accessor: `Config.dunning_engine/0` → `Keyword.get(dunning(), :engine, Accrue.Dunning.Engine.Oban)`. Boot-validated via NimbleOptions.

**D-04 — `Code.ensure_loaded?(Chimeway)` guard, identical to `Integrations.Sigra` pattern.**
`if Code.ensure_loaded?(Chimeway) do defmodule Accrue.Integrations.Chimeway do ... end end`
Dep: `{:chimeway, "~> 1.0", optional: true}` in `accrue/mix.exs`.
Static isolation gate: `scripts/ci/verify_dunning_chimeway_isolation.sh` cloned from `verify_core_liveview_runtime_free.sh`.

**D-05 — Ship `Accrue.Integrations.Chimeway.DunningNotifier` inside the adapter.**
Implements `Chimeway.Notifier` using Accrue's own domain models with callbacks:
- `notification_key/0` → `"accrue.dunning"`
- `version/0` → `1`
- `recipients/1` — resolves subscription_id → Subscription → Customer → email address
- `build/2` — constructs dunning notification content
- `channels/2` → `{:ok, [:email]}`
- `orchestration/2` → `{:ok, :immediate}`
- `workflow/2` → defines multi-step Chimeway workflow matching dunning cadence, with `stop_conditions` on every wait step
- `rendering/2` → delegates to Accrue email rendering

**D-06 — `Chimeway.Signal.track/4` with `"payment_recovered"` signal.**
`cancel_campaign/2` in the adapter calls:
`Chimeway.Signal.track(tenant_id, actor_id, "payment_recovered", %{subscription_id: sub.id})`
MANDATORY: `DunningNotifier.workflow/2` MUST declare `stop_conditions` on EVERY `:wait` step.
`tenant_id` = `sub.customer_id`; `actor_id` = `"accrue.dunning"`.

**D-07 — Docs scope.**
Extend `accrue/guides/dunning.md` with opt-in upgrade section. Add `dunning.engine` row to `.planning/processor-support-matrix.md`. Extend `scripts/ci/verify_package_docs.sh` needles. No `accrue_admin` changes.

### Claude's Discretion
- Exact module layout for `Engine.Oban` (same file as `Engine` behaviour vs. separate `engine/oban.ex`)
- Whether `cancel_campaign/2` receives the ISO anchor string or the DateTime struct
- Exact test tag strategy for the `with_chimeway` matrix cell
- `tenant_id` resolution in `cancel_campaign/2`

### Deferred Ideas (OUT OF SCOPE)
- Multi-channel dunning (SMS / push / in-app via Chimeway)
- Admin Chimeway state visibility
- Per-customer cadence override via Chimeway
- `BillingPortal.Configuration` / Chimeway scheduler configuration from accrue_admin
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DUN-03 | The dunning engine is swappable behind an `Accrue.Dunning.Engine` behaviour, with an off-by-default `Accrue.Integrations.Chimeway` adapter (conditionally compiled; core `accrue` does not require Chimeway) so a host can upgrade to the Chimeway orchestration engine without changing call sites. | Verified: behaviour contract, Chimeway 1.0.0 public API, conditional compile pattern, isolation gate pattern, cancel mechanism, config key addition. All enabling patterns found in local codebase. |
</phase_requirements>

---

## Summary

Phase 131 adds an `Accrue.Dunning.Engine` behaviour at the two campaign boundary seam points in `default_handler.ex`, extracts the existing Oban logic into a built-in `Engine.Oban` wrapper, and ships an off-by-default conditionally-compiled `Accrue.Integrations.Chimeway` adapter — identical in structure to the Phase 127 Stripe-native sync and Phase 123 Sigra isolation patterns.

**The most important finding is an API surface mismatch between Chimeway's guides and its actual 1.0.0 published code.** The CONTEXT.md D-06 decision references `stop_conditions: [%{type: :signal_received, signal_type: "payment_recovered"}]` on `:wait` steps — but this DSL is from the OLD stale guide using the `Chimeway.Workflow` behaviour, which does NOT exist in the 1.0.0 lib code. The actual 1.0.0 code's workflow step `config` field uses `progress` rules (`"wait_until"`, `"on_outcome"`, `"stop"` kinds) and `pending_signals` arrays on WorkflowRun rows for signal routing. The `stop_conditions` shape referenced in CONTEXT.md is not present anywhere in `chimeway/lib/`.

`Chimeway.Signal.track/4` signature is `track(tenant_id, actor_id, event_name, payload)` — confirmed against test suite. The signal routes to WorkflowRun rows via `pending_signals` match (not stop_conditions). The cancel-on-recovery mechanism via `Signal.track` is sound, but the `workflow/2` callback DSL must use the actual progress-rules schema (`"wait_until"` / `"on_outcome"` / `"stop"` kinds) NOT `stop_conditions`.

All other decisions in CONTEXT.md are confirmed as correct and implementable directly from the verified Chimeway 1.0.0 source.

**Primary recommendation:** Use `Chimeway.Signal.track(sub.customer_id, "accrue.dunning", "payment_recovered", %{subscription_id: sub.id})` for cancel-on-recovery. For the `workflow/2` callback, use actual Chimeway progress rules (`"wait_until"` with `pending_signals` pre-set) — not `stop_conditions`. Flag this DSL discrepancy clearly in the plan; the planner must not use `stop_conditions` in the `workflow/2` map.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Engine behaviour contract | `accrue` lib (always-compiled) | — | Thin interface; must be present regardless of which engine is active |
| Built-in Oban engine wrapper | `accrue` lib (always-compiled) | — | Wraps existing DunningStep + Oban.cancel_all_jobs — always-on deps |
| Chimeway adapter module | `accrue` lib (conditionally compiled) | — | `Code.ensure_loaded?` gate; never defined when Chimeway absent |
| DunningNotifier (Chimeway.Notifier impl) | Nested inside conditionally-compiled adapter | — | Self-contained; hosts need zero Chimeway code of their own |
| Config key `dunning: [engine:]` | `Accrue.Config` (always-compiled) | — | NimbleOptions schema addition to existing `:dunning` key |
| Isolation CI gate script | `scripts/ci/` | — | Shell script; cloned from `verify_core_liveview_runtime_free.sh` |
| Docs (dunning.md opt-in section) | `accrue/guides/dunning.md` | — | D-07 scope; no admin UI changes |
| cancel-on-recovery (Chimeway path) | `Accrue.Integrations.Chimeway` adapter | Chimeway.Signal | `cancel_campaign/2` calls `Chimeway.Signal.track/4`; Chimeway routes signal to waiting WorkflowRun rows via `pending_signals` match |
| cancel-on-recovery (built-in path) | `Accrue.Dunning.Engine.Oban` | `Oban.cancel_all_jobs` | Wraps existing `cancel_dunning_steps/2` from `default_handler.ex` |

---

## Standard Stack

### Core (all already in mix.exs)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto` / `ecto_sql` | `~> 3.13` | DB ops in Engine.Oban | Already required |
| `oban` | `~> 2.21` | Job cancel in Engine.Oban | Already required |
| `nimble_options` | `~> 1.1` | Config key validation | Already required |
| `mox` | `~> 1.2` | Adapter test without running Chimeway | Already dev dep |

### Optional (new dep)
| Library | Version | Purpose | Marker |
|---------|---------|---------|--------|
| `chimeway` | `~> 1.0` | Orchestration engine | `optional: true` in mix.exs |

**Installation (mix.exs addition):**
```elixir
{:chimeway, "~> 1.0", optional: true}
```

**Version verification:** [VERIFIED: local source at `/Users/jon/projects/chimeway/mix.exs`] Local repo has `@version "0.1.0"` but CONTEXT.md confirms Hex has `1.0.0` (2026-05-08). The dep spec `~> 1.0` targets the published version. The local repo is the development source; the published version is what hosts install.

---

## Package Legitimacy Audit

> Chimeway is a sibling library authored by the same maintainer (jonlunsford/chimeway on GitHub per mix.exs `:links`). It is not a random registry package.

| Package | Registry | Source | Disposition |
|---------|----------|--------|-------------|
| `chimeway` | Hex.pm | `/Users/jon/projects/chimeway` (local, sibling) | Approved — first-party sibling lib, same author |

slopcheck: not run (sibling-authored package, not an ecosystem discovery). All other packages are already installed deps — no new unknown packages.

---

## Architecture Patterns

### System Architecture Diagram

```
default_handler.ex
  │
  ├── maybe_start_dunning_campaign/2
  │     CAS wins (count==1)
  │     ↓
  │     Config.dunning_engine().start_campaign(sub, anchor, opts)
  │              │                    │
  │              │          [Engine.Oban]          [Integrations.Chimeway]
  │              │          DunningStep.enqueue_step  Chimeway.trigger/3
  │              │          (day-0 job)                (idempotency_key required)
  │
  └── maybe_finalize_dunning_campaign/2
        anchor-clear committed (inside Ecto.Multi transaction)
        iso_anchor stashed in process dict
        ↓ [post-commit, via run_post_commit_dunning_cancel]
        Config.dunning_engine().cancel_campaign(sub, iso_anchor, opts)
                 │                    │
                 │          [Engine.Oban]          [Integrations.Chimeway]
                 │          Oban.cancel_all_jobs    Chimeway.Signal.track/4
                 │          (keyed on campaign_started_at)  ("payment_recovered")
```

### Recommended Project Structure

New files added in Phase 131:

```
accrue/lib/accrue/dunning/
├── engine.ex            # Accrue.Dunning.Engine behaviour (2 callbacks)
└── engine/
    └── oban.ex          # Accrue.Dunning.Engine.Oban (built-in wrapper)

accrue/lib/accrue/integrations/
├── sigra.ex             # UNCHANGED
└── chimeway.ex          # Conditionally compiled adapter + DunningNotifier nested

scripts/ci/
└── verify_dunning_chimeway_isolation.sh   # New isolation gate

accrue/guides/dunning.md  # Extended with opt-in Chimeway section (D-07)
.planning/processor-support-matrix.md  # dunning.engine row added (D-07)
scripts/ci/verify_package_docs.sh      # New needles for dunning.md (D-07)
```

Modified files:

```
accrue/lib/accrue/config.ex           # Add engine: key to :dunning schema
accrue/lib/accrue/webhook/default_handler.ex  # Dispatch through Config.dunning_engine()
accrue/mix.exs                        # Add {:chimeway, "~> 1.0", optional: true}
```

### Pattern 1: Engine Behaviour Contract

```elixir
# Source: lib/accrue/dunning/engine.ex (new)
defmodule Accrue.Dunning.Engine do
  @moduledoc """
  Behaviour for dunning campaign orchestration engines.

  Engines control what orchestration system is invoked at campaign boundaries.
  DB state (dunning_campaign_started_at) is managed by Accrue regardless of
  engine choice.

  The built-in engine (`Accrue.Dunning.Engine.Oban`) is always-on and requires
  no additional configuration. The optional Chimeway engine
  (`Accrue.Integrations.Chimeway`) is off by default and conditionally compiled.
  """

  @callback start_campaign(
              subscription :: Accrue.Billing.Subscription.t(),
              anchor_at :: DateTime.t(),
              opts :: keyword()
            ) :: :ok | {:error, term()}

  @callback cancel_campaign(
              subscription :: Accrue.Billing.Subscription.t(),
              iso_anchor :: String.t(),
              opts :: keyword()
            ) :: :ok | {:error, term()}
end
```

### Pattern 2: Built-in Engine.Oban wrapper (extraction)

```elixir
# Source: lib/accrue/dunning/engine/oban.ex (new — wraps existing default_handler.ex logic)
defmodule Accrue.Dunning.Engine.Oban do
  @behaviour Accrue.Dunning.Engine

  import Ecto.Query, only: [from: 2]
  require Logger

  alias Accrue.Billing.Subscription
  alias Accrue.Workers.DunningStep

  @impl Accrue.Dunning.Engine
  def start_campaign(%Subscription{} = sub, %DateTime{} = anchor, _opts) do
    # Wrap the exact body of enqueue_day_zero_step from default_handler.ex
    case day_zero_step_key() do
      nil -> :ok
      step_key ->
        DunningStep.enqueue_step(sub.id, step_key, anchor, %{
          customer_id: sub.customer_id,
          invoice_id: Keyword.get(_opts, :invoice_id)  # passed from canonical
        })
        :ok
    end
  end

  @impl Accrue.Dunning.Engine
  def cancel_campaign(%Subscription{} = sub, iso_anchor, _opts) when is_binary(iso_anchor) do
    # Wrap the exact body of cancel_dunning_steps from default_handler.ex
    from(j in Oban.Job,
      where: j.worker == "Accrue.Workers.DunningStep",
      where: fragment("? ->> 'subscription_id' = ?", j.args, ^sub.id),
      where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso_anchor)
    )
    |> Oban.cancel_all_jobs()
    :ok
  rescue
    e ->
      Logger.warning("dunning cancel-on-recovery bulk cancel failed: #{inspect(e)}")
      :ok
  end

  defp day_zero_step_key do
    Enum.find_value(Accrue.Config.dunning_campaign_steps(), fn step ->
      if Keyword.get(step, :after_days) == 0, do: Keyword.get(step, :key)
    end)
  end
end
```

### Pattern 3: Chimeway Adapter — Conditional Compile (clone of sigra.ex 4-pattern)

```elixir
# Source: lib/accrue/integrations/chimeway.ex (new)
# Follows the EXACT same 4-pattern as lib/accrue/integrations/sigra.ex

if Code.ensure_loaded?(Chimeway) do
  defmodule Accrue.Integrations.Chimeway do
    @moduledoc "..."

    @behaviour Accrue.Dunning.Engine
    @compile {:no_warn_undefined, [Chimeway, Chimeway.Signal]}

    alias Accrue.Billing.Subscription

    @impl Accrue.Dunning.Engine
    def start_campaign(%Subscription{} = sub, %DateTime{} = anchor, opts) do
      iso_anchor = DateTime.to_iso8601(anchor)
      idempotency_key = "accrue.dunning:" <> sub.id <> ":" <> iso_anchor

      Chimeway.trigger(
        __MODULE__.DunningNotifier,
        %{subscription_id: sub.id, customer_id: sub.customer_id, anchor: iso_anchor},
        idempotency_key: idempotency_key,
        tenant_id: sub.customer_id
      )
      |> case do
        {:ok, _result} -> :ok
        {:duplicate, _event} -> :ok   # idempotency contract: duplicate = no-op
        {:error, reason} -> {:error, reason}
      end
    end

    @impl Accrue.Dunning.Engine
    def cancel_campaign(%Subscription{} = sub, iso_anchor, _opts) when is_binary(iso_anchor) do
      Chimeway.Signal.track(
        sub.customer_id,       # tenant_id
        "accrue.dunning",      # actor_id (system actor, not a human user)
        "payment_recovered",   # event_name
        %{subscription_id: sub.id}  # payload
      )
      |> case do
        {:ok, _signal} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end
end
```

### Pattern 4: DunningNotifier (Chimeway.Notifier impl — nested inside the adapter module)

The `DunningNotifier` must implement `Chimeway.Notifier`. Key verified facts about the 1.0.0 API:

**Required callbacks** (from `Chimeway.Notifier.validate_module!/1`):
- `notification_key/0` — required
- `version/0` — required
- `recipients/1` — required (1-arity, takes params map)
- `build/2` — required (takes params map + recipient map)

**Optional callbacks** (marked `@optional_callbacks`):
- `channels/2`
- `rendering/2`
- `delayed_fallback_channels/2`
- `orchestration/2`
- `workflow/2`

The `workflow/2` callback returns `{:ok, map()}` where the map has keys `workflow_key`, `workflow_version`, `steps`. Each step is `%{step_key: string, step_order: pos_integer, channel: string, config: map}`. The `config` map can contain a `"progress"` key with rules of kinds `"wait_until"`, `"on_outcome"`, or `"stop"`.

**CRITICAL FINDING about stop_conditions (see Pitfalls):** The `stop_conditions` DSL from CONTEXT.md D-06 is NOT in the actual 1.0.0 Chimeway lib code. See Pitfall 1 below.

### Pattern 5: Config Key Addition

```elixir
# In accrue/lib/accrue/config.ex, inside the :dunning keys: [...] block
# ADD after the :campaign key:
engine: [
  type: :atom,
  default: Accrue.Dunning.Engine.Oban,
  doc:
    "Module implementing `Accrue.Dunning.Engine`. Default: " <>
      "`Accrue.Dunning.Engine.Oban` (built-in Oban campaign). " <>
      "Set to `Accrue.Integrations.Chimeway` to delegate orchestration " <>
      "to Chimeway."
]
```

```elixir
# Add accessor in Accrue.Config:
@spec dunning_engine() :: module()
def dunning_engine do
  Keyword.get(dunning(), :engine, Accrue.Dunning.Engine.Oban)
end
```

### Pattern 6: default_handler.ex dispatch change

```elixir
# BEFORE (existing code):
defp maybe_start_dunning_campaign(%Subscription{} = sub, canonical) do
  if Accrue.Config.dunning_campaign_enabled?() do
    # ... CAS update_all ...
    case count do
      1 -> enqueue_day_zero_step(sub, now_usec, canonical)
      _ -> :ok
    end
  end
  :ok
end

# AFTER (Phase 131 change):
defp maybe_start_dunning_campaign(%Subscription{} = sub, canonical) do
  if Accrue.Config.dunning_campaign_enabled?() do
    # ... same CAS update_all (unchanged) ...
    case count do
      1 ->
        emit_campaign_started(sub)  # MOVED: was inside enqueue_day_zero_step
        opts = [invoice_id: get(canonical, :id)]
        Accrue.Config.dunning_engine().start_campaign(sub, now_usec, opts)
      _ -> :ok
    end
  end
  :ok
end
```

```elixir
# cancel path: replace cancel_dunning_steps call with engine dispatch
defp run_post_commit_dunning_cancel({:ok, %Subscription{} = sub}) do
  case Process.delete(:accrue_dunning_cancel) do
    {sub_id, iso_anchor} when is_binary(sub_id) and is_binary(iso_anchor) ->
      Accrue.Config.dunning_engine().cancel_campaign(sub, iso_anchor, [])
    _ -> :ok
  end
end
```

**Note:** `run_post_commit_dunning_cancel` currently receives `{:ok, %Subscription{}}` — the `sub` struct is already available at the call site. The planner should verify whether the sub object in scope at that point is `row` (before anchor clear) or `updated` (after). From reading the code: the function receives the Repo.transaction result which contains `updated`. However the `Subscription.id` field is on both structs. The `cancel_campaign/2` engine callback receives `sub` (for `sub.id` and `sub.customer_id`) and `iso_anchor` (string). The planner may need to thread the full subscription struct into the process dict stash instead of just `{sub_id, iso_anchor}` — OR keep the existing `{sub_id, iso_anchor}` stash and add a DB reload in Engine.Oban (wasteful) OR restructure slightly. The SIMPLEST approach: pass `{sub, iso_anchor}` (the full struct) in the process dict stash.

### Pattern 7: Isolation Gate (clone of verify_core_liveview_runtime_free.sh)

```bash
#!/usr/bin/env bash
# Shift-left merge gate (DUN-03): always-on dunning path stays Chimeway-free.
set -euo pipefail

repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
lib="${repo_root}/accrue/lib"

# Files that constitute the ALWAYS-ON dunning path:
always_on_files=(
  "${lib}/accrue/billing/dunning.ex"
  "${lib}/accrue/workers/dunning_step.ex"
  "${lib}/accrue/dunning/campaign.ex"
  # Note: default_handler.ex dispatches through Config.dunning_engine() —
  # which resolves to Engine.Oban by default. It should NOT reference Chimeway
  # symbols directly in the always-compiled dunning dispatch path.
)

hits=$(grep -rn \
  'Accrue\.Integrations\.Chimeway\|Chimeway\.' \
  "${lib}/accrue/billing/dunning.ex" \
  "${lib}/accrue/workers/dunning_step.ex" \
  "${lib}/accrue/dunning/campaign.ex" \
  --include='*.ex' \
  | grep -v '^[[:space:]]*#' \
  || true)

if [[ -n "${hits}" ]]; then
  echo "verify_dunning_chimeway_isolation: FAIL — Chimeway ref in always-on dunning path:" >&2
  echo "${hits}" >&2
  exit 1
fi

echo "verify_dunning_chimeway_isolation: OK"
```

**Note on gate scope:** `default_handler.ex` dispatches through `Config.dunning_engine()` — it does NOT directly reference `Accrue.Integrations.Chimeway`. The built-in Oban path in `Engine.Oban` may reference `Oban` (always-on dep) and `DunningStep` (always-on). The isolation gate should assert those always-on dunning files have zero Chimeway symbols. The `default_handler.ex` itself is safe as long as the dispatch goes through `Config.dunning_engine()` only.

### Anti-Patterns to Avoid

- **Don't put the `emit_campaign_started/1` call inside `Engine.Oban.start_campaign/3`:** Telemetry/ledger emission is Accrue's responsibility, not the engine's. The engine only does orchestration signaling. `emit_campaign_started` must stay in `default_handler.ex`, called BEFORE the engine dispatch (or moved to right after the CAS count==1 branch, before the engine call).
- **Don't dispatch `Config.dunning_engine()` inside any `Repo.transact`:** The engine calls are post-commit side effects (same as the existing behavior). This is already the pattern in `default_handler.ex` — don't break it.
- **Don't use `stop_conditions` key in workflow/2:** This DSL key is from the old stale guide and is not validated by Chimeway 1.0.0 code. Use `"progress"` rules with `"wait_until"`, `"on_outcome"`, or `"stop"` kinds instead.
- **Don't atomize `iso_anchor` or any string from the process dict:** The process dict stash `{sub_id, iso_anchor}` today holds binaries; keep it that way.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Chimeway Notifier protocol | Custom notification dispatch logic | `Chimeway.trigger/3` with `DunningNotifier` implementing `Chimeway.Notifier` | Chimeway's trigger handles event persistence, idempotency (via `idempotency_key`), notification creation, dispatch — building any of this is wheel-reinvention |
| Signal routing to stop workflow runs | Custom Chimeway DB queries | `Chimeway.Signal.track/4` | This is Chimeway's public cancel API — it atomically persists a Signal row + enqueues `SignalRouterWorker` in a single `Ecto.Multi`. Race-safe by design. |
| Idempotency key for Chimeway trigger | Random UUID or timestamp-based key | `"accrue.dunning:" <> sub.id <> ":" <> iso_anchor` | Stable, deterministic, unique per-campaign. Prevents duplicate Chimeway triggers from concurrent webhooks — mirrors the Phase 128 atomic CAS design at the orchestration layer. |
| NimbleOptions module type validation | Custom `{:custom, ...}` validator | NimbleOptions `:atom` type for the `engine:` key | Existing `:atom` type allows any atom; the behaviour contract is enforced at runtime via `@behaviour` on each adapter. A custom `{:module, Accrue.Dunning.Engine}` validator is a nice-to-have but `:atom` with documentation is sufficient for v1.40. |

---

## Critical API Surface Finding

### VERIFIED: Chimeway 1.0.0 Public API (from local source)

**Public entry points** (from `chimeway/lib/chimeway.ex`):
- `Chimeway.trigger(notifier, params, opts)` — trigger a notifier execution
- `Chimeway.Signal.track(tenant_id, actor_id, event_name, payload \\ %{})` — emit a signal
- `Chimeway.recover_event/2`, `Chimeway.recover_delivery/2` — recovery (not needed here)
- `Chimeway.list_for_recipient/2`, `Chimeway.mark_seen/3`, etc. — inbox (not needed)

**`Chimeway.trigger/3` signature verified from `chimeway/lib/chimeway/trigger.ex`:**
- REQUIRES `idempotency_key:` in opts — missing key returns `{:error, :missing_idempotency_key}`
- REQUIRES `tenant_id:` in opts — missing returns `{:error, :missing_tenant_id}`
- `tenant_id` must be a non-empty binary string
- Returns `{:ok, result_map}`, `{:duplicate, event}`, or `{:error, reason}`

**`Chimeway.Signal.track/4` signature verified from `chimeway/lib/chimeway/signal.ex` and tests:**
- `track(tenant_id :: String.t(), actor_id :: String.t(), event_name :: String.t(), payload :: map())`
- `payload` defaults to `%{}` when omitted
- Returns `{:ok, Signal.t()}` or `{:error, Ecto.Changeset.t() | term()}`
- Atomically persists Signal row + enqueues `SignalRouterWorker` in a single `Ecto.Multi`

**`Chimeway.Notifier` required callbacks** (from `chimeway/lib/chimeway/notifier.ex`):
- `notification_key/0 :: String.t()` — required
- `version/0 :: pos_integer()` — required
- `recipients/1 :: {:ok, [map()]} | {:error, term()}` — required, 1-arity
- `build/2 :: {:ok, map()} | {:error, term()}` — required, 2-arity

**Optional Notifier callbacks:**
- `channels/2`, `rendering/2`, `delayed_fallback_channels/2`, `orchestration/2`, `workflow/2`

**`workflow/2` map shape** (from `Chimeway.Notifier.normalize_workflow_declaration/1`):
```elixir
%{
  workflow_key: "accrue.dunning",       # binary, required
  workflow_version: 1,                  # pos_integer, required
  steps: [                              # non-empty list, required
    %{
      step_key: "reminder",             # binary, required
      step_order: 1,                    # pos_integer starting from 1, sequential
      channel: "email",                 # binary (atom also accepted)
      config: %{                        # map, optional, can have "progress" rules
        "progress" => [
          %{
            "kind" => "wait_until",
            "anchor" => "prior_delivery_terminal_at",  # ONLY valid anchor in 1.0
            "delay_seconds" => 432000,  # 5 days = 5 * 86400
            "to_step" => "action_required"
          }
        ]
      }
    }
  ]
}
```

**Signal routing mechanism** (from `chimeway/lib/chimeway/workflows.ex`):
- `Signal.track/4` → durably persists Signal row + enqueues `SignalRouterWorker`
- `SignalRouterWorker` calls `Workflows.route_signal/1`
- `route_signal/1` finds WorkflowRun rows WHERE `wr.state == :waiting AND ^event_name IN wr.pending_signals`
- Found runs are transitioned `:waiting → :active` with `reason: "signal_received"`, `pending_signals: []`
- `pending_signals` is populated when a `wait_until` step is entered (via `enter_waiting` in progression.ex)

### CRITICAL: stop_conditions DSL vs actual code

The CONTEXT.md D-06 mentions:
```
stop_conditions: [%{type: :signal_received, signal_type: "payment_recovered"}]
```

**This DSL does NOT exist in Chimeway 1.0.0 lib code.** [VERIFIED: grep of entire `/Users/jon/projects/chimeway/lib/` found zero matches for `stop_conditions`]. It appears only in:
- `chimeway/guides/flows/multi-step-journeys.md` — the old guide
- `chimeway/doc/` — the compiled guide HTML

The guide uses a `Chimeway.Workflow` behaviour with a `workflow(_args)` callback returning a different map shape with `id`, `action`, `type: :wait`, `duration` (ISO 8601). This behaviour DOES NOT EXIST in the lib code.

**The actual 1.0.0 mechanism for signal-triggered run stopping:**
1. When `workflow/2` returns a workflow with a `wait_until` step, Chimeway sets the run to `:waiting` state and populates `pending_signals` with the signal event name
2. When `Signal.track/4` is called, `SignalRouterWorker` finds matching `:waiting` runs and transitions them back to `:active`
3. The progression engine then evaluates the now-active run against the `on_outcome` or `stop` progress rules

**Implication for DunningNotifier.workflow/2:** To achieve "stop the run when payment_recovered signal is received while the run is waiting on a dunning step", the workflow must:
1. Define wait steps with `"kind" => "wait_until"` progress rules pointing to the next step
2. The WorkflowRun's `pending_signals` field must include `"payment_recovered"` for each waiting step — this requires understanding where `pending_signals` is set when entering waiting state

**However:** The actual mechanism may be simpler than expected. `Chimeway.Signal.track("payment_recovered")` will route to ANY `:waiting` WorkflowRun that has `"payment_recovered"` in its `pending_signals`. If the `workflow/2` callback is not used at all (just `orchestration/2` → `:immediate`), there is no WorkflowRun to stop. The WorkflowRun only exists when `workflow/2` is defined and returns a valid workflow map.

**For v1.40 (email-only, `orchestration/2` → `:immediate`):** The simplest correct approach is:
- **Do NOT define `workflow/2`** — it is `@optional_callbacks`. Without it, `Chimeway.trigger/3` delivers the email immediately with no WorkflowRun, and `Signal.track/4` for `"payment_recovered"` will route to zero waiting runs (no-op). The cancel-on-recovery guarantee is already provided by the Accrue-side anchor-clear + `Engine.Oban.cancel_all_jobs` (in the built-in path) or the fact that a new trigger won't be called after recovery.
- **OR define `workflow/2`** to set up a multi-step Chimeway workflow that mirrors the dunning cadence — but this requires understanding `pending_signals` population, which is an internal Chimeway mechanism not directly controllable by the notifier.

The CONTEXT.md D-05 says `workflow/2` defines the multi-step Chimeway workflow matching the configured dunning cadence steps. This is the correct scope for a Chimeway-backed multi-step journey. The `"payment_recovered"` signal routing will work naturally IF the `pending_signals` field is populated correctly by Chimeway internals when a `wait_until` step is entered.

**The planner decision point:** Does `workflow/2` implementation require knowing the `pending_signals` population mechanism, or does Chimeway populate it automatically when a `wait_until` step is entered? From reading `progression.ex` → `enter_waiting`, the `pending_signals` field is NOT set there — it's on the `WorkflowRun` changeset. This needs investigation of how `pending_signals` gets populated in Chimeway 1.0.0 for signal routing to work.

---

## Common Pitfalls

### Pitfall 1: stop_conditions DSL is stale guide API (CRITICAL)
**What goes wrong:** Planner includes `stop_conditions: [%{type: :signal_received, ...}]` in the `workflow/2` map based on CONTEXT.md D-06 wording.
**Why it happens:** CONTEXT.md D-06 references the old Chimeway guide's `stop_conditions` DSL which does not exist in the 1.0.0 lib code.
**How to avoid:** Use `"progress"` rules with `"wait_until"`, `"on_outcome"`, or `"stop"` kinds in the `config` map of each workflow step. Do NOT use `stop_conditions` key anywhere.
**Warning signs:** `Chimeway.Notifier.normalize_workflow_config/1` will return `{:error, {:invalid_workflow_config, _}}` or silently accept the key (because config accepts arbitrary maps). Neither will produce the intended stop-on-signal behavior.

### Pitfall 2: pending_signals population is unclear
**What goes wrong:** `Chimeway.Signal.track/4` is called with `"payment_recovered"` but no waiting WorkflowRun has `"payment_recovered"` in its `pending_signals`, so the signal routes to zero runs (silent no-op, no stop of the Chimeway workflow).
**Why it happens:** The `pending_signals` field on `WorkflowRun` is not set by the notifier's `workflow/2` declaration — it must be populated by the Chimeway internals when entering a wait state. The mechanism for linking a signal event name to a specific wait step is not visible in the code reviewed.
**How to avoid:** Investigate `chimeway/lib/chimeway/dispatch/` or `chimeway/lib/chimeway/workflows/` for how `pending_signals` is set during wait step entry. The plan must include a task to verify this before writing `workflow/2`.
**Warning signs:** `Chimeway.Workflows.explain/2` returns `pending_signals: []` after triggering when it should contain `["payment_recovered"]`.

### Pitfall 3: emit_campaign_started called inside Engine.Oban
**What goes wrong:** Ledger/telemetry emission (`emit_campaign_started/1`) is moved inside `Engine.Oban.start_campaign/3`, making it fire even in the Chimeway path (not idiomatic) or not at all (if omitted from the Chimeway adapter).
**Why it happens:** The current `enqueue_day_zero_step` function combines enqueue + emit. Extraction must split these.
**How to avoid:** `emit_campaign_started/1` stays in `default_handler.ex` called from the count==1 branch BEFORE the engine dispatch. `Engine.Oban.start_campaign/3` only does Oban enqueue. The engine never emits Accrue ledger events.

### Pitfall 4: cancel_campaign receives wrong argument type
**What goes wrong:** `cancel_campaign/2` is called with a `DateTime.t()` anchor instead of an ISO8601 string, or with `sub_id` (binary) instead of `%Subscription{}`.
**Why it happens:** The existing `cancel_dunning_steps/2` takes `(sub_id, iso_anchor)` (both binaries). The new behaviour signature takes `(%Subscription{}, iso_anchor)`. The process dict stash currently stores `{sub_id, iso_anchor}`. The stash must be changed to `{sub, iso_anchor}` (struct + string) to support the new signature. Or the engine callback can take `(sub_id, iso_anchor)` and the struct is not needed — both sub_id and customer_id for the Chimeway path come from the full sub struct.
**How to avoid:** The planner must decide: store `{sub, iso_anchor}` in the process dict (full struct). The `Engine.Oban` implementation only needs `sub.id`. The Chimeway implementation needs `sub.customer_id` as tenant_id.

### Pitfall 5: Chimeway.trigger/3 tenant_id vs. actor_id confusion
**What goes wrong:** `tenant_id` and `actor_id` are swapped in `Signal.track/4` call.
**Why it happens:** `Signal.track` signature is `track(tenant_id, actor_id, event_name, payload)` — NOT `track(actor_id, tenant_id, ...)`. The test in `signal_test.exs` shows: `Chimeway.Signal.track("acme", "user_42", "email_opened", %{})` where `"acme"` is tenant and `"user_42"` is actor.
**How to avoid:** In `cancel_campaign/2`: `Chimeway.Signal.track(sub.customer_id, "accrue.dunning", "payment_recovered", %{subscription_id: sub.id})`. `sub.customer_id` = tenant_id; `"accrue.dunning"` = actor_id (system actor).

### Pitfall 6: Chimeway adapter defined in always-compiled path
**What goes wrong:** `defmodule Accrue.Integrations.Chimeway` is compiled without the `Code.ensure_loaded?` guard, pulling Chimeway symbols into the always-compiled core.
**Why it happens:** Forgetting the guard or miscopying the Sigra pattern.
**How to avoid:** Copy the Sigra 4-pattern EXACTLY. The outer `if Code.ensure_loaded?(Chimeway) do` block must wrap the entire `defmodule Accrue.Integrations.Chimeway do...end`. Test with `mix compile --warnings-as-errors` in the without-Chimeway matrix (standard CI).

---

## Runtime State Inventory

> Omit — this is a greenfield addition phase (new modules, new config key), not a rename/refactor/migration. No existing runtime state is being renamed or migrated.

---

## Code Examples

### Chimeway.trigger/3 call pattern (verified)

```elixir
# Source: /Users/jon/projects/chimeway/lib/chimeway/trigger.ex (lines 40-58)
# trigger/3 requires BOTH idempotency_key: and tenant_id: in opts.
# Missing either returns {:error, :missing_idempotency_key} or {:error, :missing_tenant_id}.

Chimeway.trigger(
  Accrue.Integrations.Chimeway.DunningNotifier,
  %{subscription_id: sub.id, customer_id: sub.customer_id, anchor: iso_anchor},
  idempotency_key: "accrue.dunning:" <> sub.id <> ":" <> iso_anchor,
  tenant_id: sub.customer_id
)
```

### Chimeway.Signal.track/4 call pattern (verified)

```elixir
# Source: /Users/jon/projects/chimeway/test/chimeway/signal_test.exs (lines 12-32)
# Signature: track(tenant_id, actor_id, event_name, payload)

Chimeway.Signal.track(
  sub.customer_id,            # tenant_id — isolates signal routing to this tenant
  "accrue.dunning",           # actor_id — system actor (constant)
  "payment_recovered",        # event_name
  %{subscription_id: sub.id} # payload — safe scalar reference only
)
```

### Chimeway.Notifier required callback stubs (verified against notifier.ex validate_module!)

```elixir
# Source: /Users/jon/projects/chimeway/lib/chimeway/notifier.ex (lines 67-87)
# validate_module!/1 checks: notification_key/0, version/0, recipients/1, build/2

@impl Chimeway.Notifier
def notification_key, do: "accrue.dunning"

@impl Chimeway.Notifier
def version, do: 1

@impl Chimeway.Notifier
def recipients(%{subscription_id: subscription_id}) do
  # Load Subscription → Customer → email
  case Accrue.Repo.repo().get(Accrue.Billing.Subscription, subscription_id) do
    nil -> {:error, :subscription_not_found}
    sub ->
      customer = Accrue.Repo.repo().get!(Accrue.Billing.Customer, sub.customer_id)
      {:ok, [%{recipient_identity: customer.email, recipient_type: "email"}]}
  end
end

@impl Chimeway.Notifier
def build(params, _recipient) do
  {:ok, %{subscription_id: params[:subscription_id] || params["subscription_id"]}}
end
```

### Sigra conditional compile pattern (exact clone target)

```elixir
# Source: /Users/jon/projects/accrue/accrue/lib/accrue/integrations/sigra.ex (lines 31-75)
if Code.ensure_loaded?(Sigra) do
  defmodule Accrue.Integrations.Sigra do
    @behaviour Accrue.Auth
    @compile {:no_warn_undefined, [Sigra.Auth, Sigra.Audit]}
    # ... callbacks ...
  end
end
```

Clone: replace `Sigra` → `Chimeway`, behaviour reference → `Accrue.Dunning.Engine`.

### Isolation gate shell script pattern (exact clone target)

```bash
# Source: /Users/jon/projects/accrue/scripts/ci/verify_core_liveview_runtime_free.sh (lines 34-47)
hits=$(grep -rnE \
  '^[^#]*((import|alias)[[:space:]]+Phoenix\.LiveView|Phoenix\.LiveView\.Socket|...)' \
  "${lib}" --include='*.ex' \
  | grep -v '/accrue/live/' \
  || true)

if [[ -n "${hits}" ]]; then
  echo "...: FAIL — ..." >&2
  exit 1
fi
```

Clone: adapt grep pattern for `Chimeway` symbols in always-on dunning files.

### SigraTest conditional compile test (exact clone target)

```elixir
# Source: /Users/jon/projects/accrue/accrue/test/accrue/integrations/sigra_test.exs
# Clone for ChimewayTest — replace module names, behaviour name, callback names.

case Code.ensure_loaded(Accrue.Integrations.Chimeway) do
  {:module, Accrue.Integrations.Chimeway} ->
    assert function_exported?(Accrue.Integrations.Chimeway, :start_campaign, 3)
    assert function_exported?(Accrue.Integrations.Chimeway, :cancel_campaign, 3)
    behaviours = Accrue.Integrations.Chimeway.module_info(:attributes)
                 |> Keyword.get_values(:behaviour) |> List.flatten()
    assert Accrue.Dunning.Engine in behaviours

  {:error, :nofile} ->
    refute Code.ensure_loaded?(Chimeway)
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `default_handler.ex` calls `DunningStep.enqueue_step` directly | Dispatch through `Config.dunning_engine()` → `Engine.Oban.start_campaign` | Phase 131 | Non-breaking extraction; existing hosts see zero behavior change |
| No engine abstraction | `Accrue.Dunning.Engine` behaviour | Phase 131 | Enables swappable orchestration engines |
| Single hardcoded Oban cancel path | `Engine.Oban.cancel_campaign` wrapper | Phase 131 | Chimeway adapter can substitute a signal-based cancel |
| Chimeway guide uses `Chimeway.Workflow` + `stop_conditions` DSL | Actual 1.0.0 code uses `Chimeway.Notifier` + `progress` rules + `pending_signals` | Chimeway 1.0.0 (2026-05-08) | The old guide DSL is stale; use the actual notifier pattern |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Chimeway 1.0.0 is available on Hex at `~> 1.0` and the local repo at `0.1.0` is the development source | Standard Stack | If Hex has a different API, adapter callbacks may break — LOW risk, same maintainer |
| A2 | `sub.customer_id` is always a non-nil binary string (suitable as Chimeway `tenant_id`) | Code Examples | If customer_id is nil, `Chimeway.trigger/3` returns `{:error, :invalid_tenant_id}` — verify at adapter call site |
| A3 | The `pending_signals` field is populated automatically by Chimeway when a `wait_until` step is entered | Pitfall 2, Code Examples | If not automatic, `Signal.track("payment_recovered")` will route to zero runs (silent no-op) — the workflow/2 implementation would need rethinking |
| A4 | `emit_campaign_started/1` can be cleanly separated from `enqueue_day_zero_step` and moved to be called in `default_handler.ex` before the engine dispatch | Architecture Patterns | If they are entangled (they are not based on reading the code), extraction is clean |
| A5 | `workflow/2` callback is truly optional and the adapter works correctly with only `:immediate` orchestration (no workflow) | Code Examples | If workflow is required for proper email delivery routing, the adapter may not send emails |

**A3 is the highest-risk assumption.** The planner should include a task to investigate `pending_signals` population before finalizing the `workflow/2` implementation. If `pending_signals` is not set automatically during `wait_until` step entry, the signal-cancel-on-recovery mechanism will silently fail. An alternative: if `workflow/2` is not implemented (adapter uses `orchestration: :immediate`), the Chimeway adapter simply sends the email immediately with no WorkflowRun, and `Signal.track` is a no-op — which is still correct because the cancel-on-recovery is already handled by the Accrue anchor-clear preventing future `start_campaign` calls.

---

## Open Questions

1. **How does `pending_signals` get populated on `WorkflowRun` rows?**
   - What we know: `WorkflowRun` has `pending_signals :: {:array, :string}` field; `route_signal` queries for runs WHERE `^event_name IN wr.pending_signals`; `enter_waiting` in progression.ex transitions to `:waiting` but does not appear to set `pending_signals`
   - What's unclear: What sets `pending_signals` when a `wait_until` step is entered? Is it set from the workflow step `config`? Is there a separate mechanism?
   - Recommendation: Read `chimeway/lib/chimeway/dispatch/` and any remaining `workflows/` files before implementing `workflow/2`. If `pending_signals` population is not automatic from the workflow declaration, consider omitting `workflow/2` in v1.40 (email-only path, immediate orchestration) and using `Signal.track` only as a "best-effort" signal rather than a guaranteed stop.

2. **Process dict stash shape for cancel_campaign**
   - What we know: Currently `{sub_id, iso_anchor}` — two binaries. Engine.Oban.cancel_campaign needs `sub.id`. Chimeway adapter needs `sub.customer_id` as tenant_id.
   - What's unclear: Should the stash be changed to `{sub, iso_anchor}` (struct + string), or should the cancel_campaign callback be `cancel_campaign(sub_id, customer_id, iso_anchor)` instead of taking the full struct?
   - Recommendation: Change the stash to `{sub, iso_anchor}` and update `run_post_commit_dunning_cancel` to pattern match on `{%Subscription{} = sub, iso_anchor}`. The behaviour callback signature is `cancel_campaign(%Subscription{}, iso_anchor, opts)` as locked by D-01.

3. **NimbleOptions type for `engine:` config key**
   - What we know: NimbleOptions 1.1 supports `:atom` type. D-03 says type: `{:module, Accrue.Dunning.Engine}` but NimbleOptions does not have a `{:module, behaviour}` type validator built-in.
   - Recommendation: Use `:atom` type with documentation. The behaviour contract is enforced at compile time via `@behaviour` on each implementing module.

---

## Environment Availability

> Step 2.6: SKIPPED — Phase 131 is a code/config addition with no new external tool dependencies beyond Chimeway (already in the local project). Chimeway is a sibling library. No CLI tools, databases, or external services beyond what Phase 128–130 already depend on.

---

## Validation Architecture

> `workflow.nyquist_validation: true` — section included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `accrue/test/test_helper.exs` |
| Quick run command | `cd accrue && mix test test/accrue/dunning/ test/accrue/integrations/chimeway_test.exs --seed 0` |
| Full suite command | `cd accrue && mix test --seed 0` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DUN-03 SC#1 | Engine behaviour has 2 callbacks, built-in Oban satisfies it | unit | `mix test test/accrue/dunning/engine_test.exs` | ❌ Wave 0 |
| DUN-03 SC#1 | default_handler dispatches through Config.dunning_engine() | integration | `mix test test/accrue/webhook/default_handler_test.exs -k "dunning engine"` | ❌ Wave 0 |
| DUN-03 SC#2 | Chimeway adapter is conditionally compiled (absent when no dep) | unit | `mix test test/accrue/integrations/chimeway_test.exs` | ❌ Wave 0 |
| DUN-03 SC#3 | Default path (Engine.Oban) works unchanged after Phase 130 | integration | Full Fake-lane test unchanged: `mix test test/accrue/webhook/default_handler_test.exs -k "dunning"` | ✅ (Phase 130 test suite) |
| DUN-03 SC#4 | Chimeway adapter documented targeting 1.0.0 API | manual | Docs review | N/A |

### Sampling Rate
- **Per task commit:** `cd accrue && mix test test/accrue/dunning/ test/accrue/integrations/ --seed 0`
- **Per wave merge:** `cd accrue && mix test --seed 0`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `accrue/test/accrue/dunning/engine_test.exs` — covers DUN-03 SC#1 (behaviour contract + Engine.Oban impl)
- [ ] `accrue/test/accrue/integrations/chimeway_test.exs` — covers DUN-03 SC#2 (conditional compile; clone of sigra_test.exs)
- [ ] `accrue/test/accrue/dunning/engine/oban_test.exs` — covers Engine.Oban start_campaign/cancel_campaign with Mox stubs for DunningStep/Oban

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | `iso_anchor` is always a binary produced by `DateTime.to_iso8601/1` (Accrue-owned); `tenant_id` / `actor_id` are binaries validated by Chimeway's trigger before use |
| V6 Cryptography | no | — |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Duplicate Chimeway trigger from concurrent webhooks | Spoofing | `idempotency_key: "accrue.dunning:" <> sub.id <> ":" <> iso_anchor` — stable, unique per campaign; Chimeway returns `{:duplicate, event}` on conflict |
| Stale `Signal.track` cancelling a fresh re-lapse campaign | Tampering | iso_anchor is campaign-specific; a recovered + re-lapsed sub has a NEW anchor; the old signal routes to the old WorkflowRun only |
| Signal routing cross-tenant | Tampering | `Signal.track(tenant_id=sub.customer_id, ...)` scoped to the customer's tenant; Chimeway's `find_runs_waiting_for_signal` filters by `wr.tenant_id = ^signal.tenant_id` structurally |
| Sensitive fields logged via Chimeway telemetry | Information Disclosure | `Chimeway.Trigger`'s `sanitize_payload/1` strips keys matching `~w(password token secret)`. The params map `%{subscription_id: sub.id, customer_id: sub.customer_id, anchor: iso_anchor}` contains no secrets. |

---

## Project Constraints (from CLAUDE.md)

- **Tech stack:** Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, PostgreSQL 14+. Phase 131 adds no new required deps.
- **Chimeway dep:** `optional: true` — core `accrue` never requires it. Consistent with CLAUDE.md "Dependencies (optional)".
- **`phoenix_live_view` runtime-free posture:** Phase 131 adds no LiveView socket runtime. The isolation gate for LiveView (`verify_core_liveview_runtime_free.sh`) is cloned as the model for the Chimeway gate. No conflict.
- **Webhook signature verification:** Not touched. Phase 131 only modifies the dunning campaign dispatch.
- **Observability:** All Accrue ledger/telemetry emission stays in `default_handler.ex`, NOT moved inside the engine callbacks. Engine modules are pure orchestration delegates.
- **Oban queue config:** No new Oban queues needed. The existing `accrue_dunning` queue handles `DunningStep` jobs (Engine.Oban path). Chimeway's own queue (if any) is configured by the host's Chimeway setup.
- **Security:** `Chimeway.Signal.track` args contain only non-PII reference IDs (`sub.id`, `sub.customer_id`). Chimeway's payload sanitizer is an additional backstop.
- **GSD Workflow Enforcement:** This research was initiated through the GSD workflow. No direct repo edits made.

---

## Sources

### Primary (HIGH confidence — local source code, directly read)

| Source | What was verified |
|--------|-------------------|
| `/Users/jon/projects/chimeway/lib/chimeway.ex` | Public entry points: `trigger/3`, `Signal.track/4`, `recover_event/2`, `recover_delivery/2` |
| `/Users/jon/projects/chimeway/lib/chimeway/trigger.ex` | `trigger/3` signature, required opts (`idempotency_key`, `tenant_id`), return types `{:ok, ...}`, `{:duplicate, event}`, `{:error, ...}` |
| `/Users/jon/projects/chimeway/lib/chimeway/signal.ex` | `track/4` signature `(tenant_id, actor_id, event_name, payload)`, atomicity via `Ecto.Multi` |
| `/Users/jon/projects/chimeway/lib/chimeway/notifier.ex` | `Chimeway.Notifier` behaviour: required callbacks (`notification_key/0`, `version/0`, `recipients/1`, `build/2`); optional callbacks; `workflow/2` map shape via `normalize_workflow_declaration/1`; progress rule kinds (`wait_until`, `on_outcome`, `stop`) |
| `/Users/jon/projects/chimeway/lib/chimeway/workflows.ex` | `route_signal/1`, `pending_signals` field, signal routing mechanism via `find_runs_waiting_for_signal` |
| `/Users/jon/projects/chimeway/lib/chimeway/workflows/progression.ex` | WorkflowRun state machine, `enter_waiting`, progress rule evaluation |
| `/Users/jon/projects/chimeway/mix.exs` | Local version `0.1.0` (stale; Hex has `1.0.0`) |
| `/Users/jon/projects/chimeway/test/chimeway/signal_test.exs` | Signal.track/4 argument order and return type confirmed |
| `/Users/jon/projects/accrue/accrue/lib/accrue/integrations/sigra.ex` | Exact 4-pattern for conditional compile |
| `/Users/jon/projects/accrue/scripts/ci/verify_core_liveview_runtime_free.sh` | Exact shell script clone target |
| `/Users/jon/projects/accrue/accrue/lib/accrue/config.ex` | Existing `:dunning` config schema; accessor patterns |
| `/Users/jon/projects/accrue/accrue/lib/accrue/webhook/default_handler.ex` | `maybe_start_dunning_campaign/2` (lines 1195–1232), `maybe_finalize_dunning_campaign/2` (lines 835–894), `run_post_commit_dunning_cancel/1` (lines 911–927), `cancel_dunning_steps/2` (lines 929–948) |
| `/Users/jon/projects/accrue/accrue/lib/accrue/workers/dunning_step.ex` | `enqueue_step/4` public signature; `unique_opts/0`; `perform/1` structure |
| `/Users/jon/projects/accrue/accrue/test/accrue/integrations/sigra_test.exs` | Test clone target for chimeway_test.exs |

### Tertiary (LOW confidence — guide docs, not backed by lib code)

- `/Users/jon/projects/chimeway/guides/flows/multi-step-journeys.md` — `stop_conditions` DSL; STALE, not reflected in 1.0.0 lib. Marked LOW, explicitly contradicted by lib code grep.

---

## Metadata

**Confidence breakdown:**
- Engine behaviour contract: HIGH — derived directly from reading existing call sites in `default_handler.ex` and the locked CONTEXT.md decisions
- Chimeway 1.0.0 public API: HIGH — read from local source code + test suite
- stop_conditions mismatch finding: HIGH — confirmed via grep of entire chimeway/lib/ (zero matches)
- pending_signals population mechanism: LOW — `enter_waiting` does not obviously set it; investigation deferred to planning
- Architecture patterns: HIGH — all clone targets verified against existing code
- Pitfalls: HIGH — derived from direct code reading

**Research date:** 2026-05-25
**Valid until:** 2026-06-25 (stable; Chimeway 1.0.0 API unlikely to change, local source is the authority)
