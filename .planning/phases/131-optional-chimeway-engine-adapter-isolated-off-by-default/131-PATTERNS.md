# Phase 131: Optional Chimeway Engine Adapter — Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 13 (new/modified)
**Analogs found:** 13 / 13

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/dunning/engine.ex` | behaviour | request-response | `accrue/lib/accrue/auth.ex` | exact (behaviour + facade pattern) |
| `accrue/lib/accrue/dunning/engine/oban.ex` | service | event-driven | `accrue/lib/accrue/webhook/default_handler.ex` lines 929-948 | exact (wraps extracted logic verbatim) |
| `accrue/lib/accrue/integrations/chimeway.ex` | adapter | event-driven | `accrue/lib/accrue/integrations/sigra.ex` | exact (4-pattern conditional compile clone) |
| `accrue/lib/accrue/integrations/chimeway/dunning_notifier.ex` (nested inside chimeway.ex) | adapter | event-driven | `accrue/lib/accrue/integrations/sigra.ex` callback bodies | role-match |
| `accrue/lib/accrue/webhook/default_handler.ex` (MODIFY) | controller | event-driven | self | self-modification, seam at lines 1195–1232 and 911–948 |
| `accrue/lib/accrue/config.ex` (MODIFY) | config | CRUD | self | self-modification, seam at lines 258–298 (dunning: keys block) |
| `scripts/ci/verify_dunning_chimeway_isolation.sh` | utility | batch | `scripts/ci/verify_core_liveview_runtime_free.sh` | exact (shell script clone) |
| `accrue/guides/dunning.md` (MODIFY) | doc | — | `accrue/guides/entitlements.md` stripe_native_sync section | role-match |
| `.planning/processor-support-matrix.md` (MODIFY) | doc | — | existing rows in same file | self-modification |
| `scripts/ci/verify_package_docs.sh` (MODIFY) | utility | batch | existing needles in same file (lines 126–135 for Phase 127 block) | exact (same needle pattern) |
| `accrue/test/accrue/dunning/engine_test.exs` | test | — | `accrue/test/accrue/integrations/sigra_test.exs` | role-match |
| `accrue/test/accrue/dunning/engine/oban_test.exs` | test | — | `accrue/test/accrue/integrations/sigra_test.exs` | role-match |
| `accrue/test/accrue/integrations/chimeway_test.exs` | test | — | `accrue/test/accrue/integrations/sigra_test.exs` | exact (clone) |

---

## Pattern Assignments

### `accrue/lib/accrue/dunning/engine.ex` (behaviour, request-response)

**Analog:** `accrue/lib/accrue/auth.ex`

**Imports / module header pattern** (auth.ex lines 1–10):
```elixir
defmodule Accrue.Auth do
  @moduledoc """
  Behaviour + facade for host-app auth integration.
  ...
  """

  @type conn :: Plug.Conn.t() | map()
  @type user :: map() | struct()
```

**Callback declaration pattern** (auth.ex lines 41–49):
```elixir
  @callback current_user(conn()) :: user() | nil
  @callback require_admin_plug() :: (conn(), keyword() -> conn())
  # ...
  @optional_callbacks step_up_challenge: 2, verify_step_up: 3
```

**Core pattern for Engine behaviour** — follow auth.ex shape exactly; Engine has NO facade delegation (unlike Auth, the engine is called directly via `Config.dunning_engine().start_campaign(...)`, not through a module-level facade function):
```elixir
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

---

### `accrue/lib/accrue/dunning/engine/oban.ex` (service, event-driven)

**Analog:** `accrue/lib/accrue/webhook/default_handler.ex` lines 1219–1232 (`enqueue_day_zero_step`) and lines 929–948 (`cancel_dunning_steps`)

**Behaviour implementation header pattern** (mirrors sigra.ex lines 51-52):
```elixir
  @behaviour Accrue.Dunning.Engine
```

**start_campaign core pattern** — verbatim extraction from default_handler.ex lines 1219–1232:
```elixir
  # default_handler.ex lines 1219-1232 (exact source to extract from):
  defp enqueue_day_zero_step(%Subscription{} = sub, %DateTime{} = anchor, canonical) do
    case day_zero_step_key() do
      nil ->
        :ok

      step_key ->
        emit_campaign_started(sub)   # <-- STAYS in default_handler.ex, NOT here

        Accrue.Workers.DunningStep.enqueue_step(sub.id, step_key, anchor, %{
          customer_id: sub.customer_id,
          invoice_id: get(canonical, :id)
        })
    end
  end
```

**cancel_campaign core pattern** — verbatim extraction from default_handler.ex lines 929–948:
```elixir
  # default_handler.ex lines 929-948 (exact source to extract from):
  defp cancel_dunning_steps(sub_id, iso_anchor) do
    import Ecto.Query, only: [from: 2]

    from(j in Oban.Job,
      where: j.worker == "Accrue.Workers.DunningStep",
      where: fragment("? ->> 'subscription_id' = ?", j.args, ^sub_id),
      where: fragment("? ->> 'campaign_started_at' = ?", j.args, ^iso_anchor)
    )
    |> Oban.cancel_all_jobs()

    :ok
  rescue
    e ->
      Logger.warning("dunning cancel-on-recovery bulk cancel failed: #{inspect(e)}")
      :ok
  end
```

**Key extraction rules for Engine.Oban:**
- `start_campaign/3` receives `%Subscription{} = sub`, `%DateTime{} = anchor`, `opts` — use `Keyword.get(opts, :invoice_id)` to extract invoice_id (replacing `get(canonical, :id)`)
- `cancel_campaign/3` receives `%Subscription{} = sub`, `iso_anchor :: String.t()`, `opts` — use `sub.id` (not sub_id binary); adapt the query accordingly
- `emit_campaign_started/1` STAYS in `default_handler.ex`, called BEFORE engine dispatch — do NOT move it into `Engine.Oban`
- `day_zero_step_key/0` helper can live in `Engine.Oban` (it only calls `Accrue.Config.dunning_campaign_steps()`, always-on)

**Imports pattern** (follows default_handler.ex style):
```elixir
  import Ecto.Query, only: [from: 2]
  require Logger

  alias Accrue.Billing.Subscription
  alias Accrue.Workers.DunningStep
```

---

### `accrue/lib/accrue/integrations/chimeway.ex` (adapter, event-driven)

**Analog:** `accrue/lib/accrue/integrations/sigra.ex` (EXACT clone target — 4-pattern)

**Full 4-pattern structure** (sigra.ex lines 1–75):
```elixir
# sigra.ex lines 1-30 — file header comment documenting the 4-pattern.
# Clone this comment block, replacing Sigra → Chimeway, auth_adapter → dunning engine.

# sigra.ex line 31 — outer Code.ensure_loaded? guard:
if Code.ensure_loaded?(Sigra) do
  defmodule Accrue.Integrations.Sigra do

# sigra.ex line 51-52 — behaviour + no_warn_undefined inside defmodule:
    @behaviour Accrue.Auth
    @compile {:no_warn_undefined, [Sigra.Auth, Sigra.Audit]}
```

**Clone mapping:**
- `if Code.ensure_loaded?(Sigra)` → `if Code.ensure_loaded?(Chimeway)`
- `defmodule Accrue.Integrations.Sigra` → `defmodule Accrue.Integrations.Chimeway`
- `@behaviour Accrue.Auth` → `@behaviour Accrue.Dunning.Engine`
- `@compile {:no_warn_undefined, [Sigra.Auth, Sigra.Audit]}` → `@compile {:no_warn_undefined, [Chimeway, Chimeway.Signal]}`

**start_campaign/3 core pattern** (Chimeway adapter; verified against chimeway/lib/chimeway/trigger.ex):
```elixir
    @impl Accrue.Dunning.Engine
    def start_campaign(%Subscription{} = sub, %DateTime{} = anchor, _opts) do
      iso_anchor = DateTime.to_iso8601(anchor)
      idempotency_key = "accrue.dunning:" <> sub.id <> ":" <> iso_anchor

      case Chimeway.trigger(
             __MODULE__.DunningNotifier,
             %{subscription_id: sub.id, customer_id: sub.customer_id, anchor: iso_anchor},
             idempotency_key: idempotency_key,
             tenant_id: sub.customer_id
           ) do
        {:ok, _result} -> :ok
        {:duplicate, _event} -> :ok   # idempotency contract: duplicate = no-op
        {:error, reason} -> {:error, reason}
      end
    end
```

**cancel_campaign/3 core pattern** (verified against chimeway/test/chimeway/signal_test.exs):
```elixir
    @impl Accrue.Dunning.Engine
    def cancel_campaign(%Subscription{} = sub, iso_anchor, _opts) when is_binary(iso_anchor) do
      # Signal.track signature: track(tenant_id, actor_id, event_name, payload)
      # Verified from signal_test.exs: track("acme", "user_42", "email_opened", %{})
      case Chimeway.Signal.track(
             sub.customer_id,            # tenant_id — NOT actor_id
             "accrue.dunning",           # actor_id (system actor constant)
             "payment_recovered",
             %{subscription_id: sub.id}
           ) do
        {:ok, _signal} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
```

---

### `DunningNotifier` (nested inside chimeway.ex as `Accrue.Integrations.Chimeway.DunningNotifier`)

**Analog:** `chimeway/lib/chimeway/notifier.ex` (behaviour definition); pattern from RESEARCH.md verified against `notifier.ex` `validate_module!/1`

**Required callbacks** (verified from chimeway/lib/chimeway/notifier.ex):
```elixir
    # notification_key/0 and version/0 — simple returns
    @impl Chimeway.Notifier
    def notification_key, do: "accrue.dunning"

    @impl Chimeway.Notifier
    def version, do: 1

    # recipients/1 — 1-arity, takes params map; resolves Subscription → Customer
    @impl Chimeway.Notifier
    def recipients(%{subscription_id: subscription_id}) do
      case Accrue.Repo.repo().get(Accrue.Billing.Subscription, subscription_id) do
        nil -> {:error, :subscription_not_found}
        sub ->
          customer = Accrue.Repo.repo().get!(Accrue.Billing.Customer, sub.customer_id)
          {:ok, [%{recipient_identity: customer.email, recipient_type: "email"}]}
      end
    end

    # build/2 — 2-arity, takes (params_map, recipient_map)
    @impl Chimeway.Notifier
    def build(params, _recipient) do
      {:ok, %{subscription_id: params[:subscription_id] || params["subscription_id"]}}
    end
```

**Optional callbacks for v1.40 scope:**
```elixir
    # channels/2 — email-only for v1.40 (multi-channel is deferred)
    @impl Chimeway.Notifier
    def channels(_params, _recipient), do: {:ok, [:email]}

    # orchestration/2 — :immediate (no WorkflowRun needed for v1.40 email-only path)
    @impl Chimeway.Notifier
    def orchestration(_params, _recipient), do: {:ok, :immediate}

    # rendering/2 — delegate to Accrue email rendering
    @impl Chimeway.Notifier
    def rendering(params, recipient) do
      # ... delegate to Accrue.Mailer / existing dunning email templates
    end
```

**workflow/2 note (CRITICAL — from RESEARCH.md):** Do NOT define `workflow/2` in v1.40 unless the `pending_signals` population mechanism is verified first (RESEARCH.md Open Question #1, Pitfall 2, Assumption A3). With `orchestration: :immediate` and no `workflow/2`, `Chimeway.trigger/3` delivers email immediately with no WorkflowRun created. `Signal.track("payment_recovered")` is then a no-op — correct because anchor-clear in Accrue prevents future `start_campaign` calls. Do NOT use `stop_conditions` key anywhere — it does not exist in Chimeway 1.0.0 lib code (RESEARCH.md Pitfall 1).

---

### `accrue/lib/accrue/webhook/default_handler.ex` (MODIFY)

**Analog:** self — seam modification at two locations

**Seam 1 — start_campaign dispatch** (current code at lines 1195–1232, after modification):
```elixir
  # BEFORE (lines 1205-1206):
  case count do
    1 -> enqueue_day_zero_step(sub, now_usec, canonical)

  # AFTER (Phase 131 change):
  case count do
    1 ->
      emit_campaign_started(sub)               # moved OUT of enqueue_day_zero_step
      opts = [invoice_id: get(canonical, :id)]
      Accrue.Config.dunning_engine().start_campaign(sub, now_usec, opts)
```

**Seam 2 — cancel_campaign dispatch** (current code at lines 911–919, after modification):
```elixir
  # BEFORE (lines 911-914):
  defp run_post_commit_dunning_cancel({:ok, %Subscription{}}) do
    case Process.delete(:accrue_dunning_cancel) do
      {sub_id, iso_anchor} when is_binary(sub_id) and is_binary(iso_anchor) ->
        cancel_dunning_steps(sub_id, iso_anchor)

  # AFTER (Phase 131 change):
  defp run_post_commit_dunning_cancel({:ok, %Subscription{}}) do
    case Process.delete(:accrue_dunning_cancel) do
      {%Subscription{} = sub, iso_anchor} when is_binary(iso_anchor) ->
        Accrue.Config.dunning_engine().cancel_campaign(sub, iso_anchor, [])
```

**Process dict stash change** — at line 877 (inside `maybe_finalize_dunning_campaign/2`):
```elixir
  # BEFORE (line 877):
  Process.put(:accrue_dunning_cancel, {updated.id, iso_anchor})

  # AFTER (Phase 131 change — stores full struct so Chimeway adapter can access customer_id):
  Process.put(:accrue_dunning_cancel, {updated, iso_anchor})
```

**Cleanup** — `cancel_dunning_steps/2` private function (lines 929–948) moves verbatim into `Engine.Oban.cancel_campaign/3`. The `enqueue_day_zero_step/3` private function (lines 1219–1232) is replaced by the engine dispatch above; remove both from `default_handler.ex` after extraction.

---

### `accrue/lib/accrue/config.ex` (MODIFY)

**Analog:** self — NimbleOptions schema addition inside the `:dunning` keys block

**Existing dunning schema location** (config.ex lines 258–298, keys block lines 269–290):
```elixir
    dunning: [
      type: :keyword_list,
      default: [...],
      keys: [
        mode: [...],
        grace_days: [...],
        terminal_action: [...],
        telemetry_prefix: [...],
        campaign: [...]   # <-- ADD engine: key AFTER this
      ],
```

**Pattern to follow for new key** (follows `mode:` atom key with `{:in, [...]}` pattern for bounded atoms; uses `:atom` for open module type per RESEARCH.md "Don't Hand-Roll" recommendation):
```elixir
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

**New accessor function** — follow the `dunning_campaign_enabled?/0` pattern (config.ex lines 854–855) for accessor shape:
```elixir
  # Add after dunning_campaign_steps/0 (after line 870):
  @doc """
  Returns the configured dunning engine module (D-03).

  Defaults to `Accrue.Dunning.Engine.Oban` (built-in Oban campaign).
  Set `dunning: [engine: Accrue.Integrations.Chimeway]` to opt into
  Chimeway orchestration.
  """
  @spec dunning_engine() :: module()
  def dunning_engine do
    Keyword.get(dunning(), :engine, Accrue.Dunning.Engine.Oban)
  end
```

**Default value** must also be added to the `default:` keyword list for the `:dunning` key (config.ex line 261–266) to maintain the NimbleOptions defaults as the single source of truth:
```elixir
      default: [
        mode: :stripe_smart_retries,
        grace_days: @default_grace_days,
        terminal_action: :unpaid,
        telemetry_prefix: [:accrue, :ops],
        campaign: @default_dunning_campaign,
        engine: Accrue.Dunning.Engine.Oban   # <-- add this
      ],
```

---

### `scripts/ci/verify_dunning_chimeway_isolation.sh` (utility, batch)

**Analog:** `scripts/ci/verify_core_liveview_runtime_free.sh` (EXACT clone target)

**Full shell script structure** (verify_core_liveview_runtime_free.sh lines 1–47 — clone verbatim, adapt as shown):
```bash
#!/usr/bin/env bash
# Shift-left merge gate (DUN-03): always-on dunning path stays Chimeway-free.
#
# Fails the build if any ALWAYS-COMPILED dunning module references Chimeway
# symbols. This makes "core stays Chimeway-free" a verifiable, non-regressing
# invariant: an accidental Chimeway coupling in the always-on dunning path is
# blocked at merge, not caught post-merge.
#
# Allowlists (by construction):
#   - Doc comments / comment lines — grep -v '^[[:space:]]*#' strips these.
#   - lib/accrue/integrations/chimeway.ex — the legitimately cond-compiled
#     adapter (lives outside the always-on dunning path files listed below).
set -euo pipefail

repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
lib="${repo_root}/accrue/lib"

if [[ ! -d "${lib}" ]]; then
  echo "verify_dunning_chimeway_isolation: missing ${lib}" >&2
  exit 1
fi

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

**Note on scope:** `default_handler.ex` dispatches through `Config.dunning_engine()` — it is NOT included in the grep target files. `Engine.Oban` only references `Oban` and `DunningStep` (always-on deps) — it is also not a target. Only the three files above (`dunning.ex`, `dunning_step.ex`, `campaign.ex`) are checked.

**Shell variable pattern** (clone lines 26–32 of verify_core_liveview_runtime_free.sh verbatim):
```bash
repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
lib="${repo_root}/accrue/lib"
```

---

### `scripts/ci/verify_package_docs.sh` (MODIFY)

**Analog:** self — existing Phase 127 needle block (lines 126–135) as pattern for adding Phase 131 needles

**Pattern to follow** (lines 126–135):
```bash
# Optional Stripe-native advisory sync (Phase 127, ENT-10 / D-12)
# Pins the entitlements.md Stripe-native section + the telemetry.md sync catalog
# so the observational-disclaimer, enable steps, 10-cap, deferred 1.2 read, and
# the new telemetry events cannot silently regress. grep -F is literal.
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'stripe_native_sync'
require_fixed "$ROOT_DIR/accrue/guides/entitlements.md" 'entitlements.active_entitlement_summary.updated'
```

**New needles to add** (after the Phase 127 block, before the `require_fixed "$ROOT_DIR/accrue_admin/mix.exs"` block):
```bash
# Optional Chimeway dunning engine adapter (Phase 131, DUN-03)
# Pins the dunning.md opt-in upgrade section so the install steps, config key,
# and engine behaviour reference cannot silently regress.
require_fixed "$ROOT_DIR/accrue/guides/dunning.md" 'Accrue.Dunning.Engine'
require_fixed "$ROOT_DIR/accrue/guides/dunning.md" 'Accrue.Integrations.Chimeway'
require_fixed "$ROOT_DIR/accrue/guides/dunning.md" 'dunning: [engine:'
```

---

### `accrue/guides/dunning.md` (MODIFY, doc)

**Analog:** `accrue/guides/entitlements.md` Stripe-native sync section (the Phase 127 opt-in upgrade pattern)

**Section structure to follow:**
- H2 heading: `## Upgrading to Chimeway orchestration`
- Subsections: `### Prerequisites`, `### Installation`, `### Configuration`, `### What changes`, `### What stays the same`
- Code block for mix.exs dep addition: `{:chimeway, "~> 1.0"}`
- Code block for config key: `dunning: [engine: Accrue.Integrations.Chimeway]`
- Must contain the three needles added to `verify_package_docs.sh`: `Accrue.Dunning.Engine`, `Accrue.Integrations.Chimeway`, `dunning: [engine:`

---

### Test Files (Wave 0)

#### `accrue/test/accrue/integrations/chimeway_test.exs` (test)

**Analog:** `accrue/test/accrue/integrations/sigra_test.exs` (EXACT clone — same structure)

**Full test structure** (sigra_test.exs lines 1–63 — clone verbatim, adapt as shown):
```elixir
defmodule Accrue.Integrations.ChimewayTest do
  @moduledoc """
  Verify the Chimeway conditional-compile scaffold (DUN-03, D-04).

  Contract:
    * When :chimeway is NOT loaded, Accrue.Integrations.Chimeway is NEVER
      defined — Code.ensure_loaded/1 returns {:error, :nofile}.
    * When :chimeway IS loaded, the module is defined and implements
      Accrue.Dunning.Engine with both callbacks exported.
    * In BOTH matrices, mix compile --warnings-as-errors passes.
  """

  use ExUnit.Case, async: true

  describe "conditional compile" do
    test "Accrue.Integrations.Chimeway is either loaded OR :nofile — never a crash" do
      case Code.ensure_loaded(Accrue.Integrations.Chimeway) do
        {:module, Accrue.Integrations.Chimeway} ->
          assert function_exported?(Accrue.Integrations.Chimeway, :start_campaign, 3)
          assert function_exported?(Accrue.Integrations.Chimeway, :cancel_campaign, 3)

          behaviours =
            Accrue.Integrations.Chimeway.module_info(:attributes)
            |> Keyword.get_values(:behaviour)
            |> List.flatten()

          assert Accrue.Dunning.Engine in behaviours

        {:error, :nofile} ->
          refute Code.ensure_loaded?(Chimeway)
      end
    end

    test "source file exists and uses the 4-pattern conditional compile" do
      source = File.read!("lib/accrue/integrations/chimeway.ex")
      assert source =~ "Code.ensure_loaded?(Chimeway)"
      assert source =~ "@compile {:no_warn_undefined"
      assert source =~ "@behaviour Accrue.Dunning.Engine"
    end
  end
end
```

#### `accrue/test/accrue/dunning/engine_test.exs` (test)

**Analog:** `accrue/test/accrue/integrations/sigra_test.exs` (structure) + behaviour verification pattern

**Pattern:**
```elixir
defmodule Accrue.Dunning.EngineTest do
  use ExUnit.Case, async: true

  describe "behaviour contract" do
    test "defines start_campaign/3 callback" do
      callbacks = Accrue.Dunning.Engine.behaviour_info(:callbacks)
      assert {:start_campaign, 3} in callbacks
    end

    test "defines cancel_campaign/3 callback" do
      callbacks = Accrue.Dunning.Engine.behaviour_info(:callbacks)
      assert {:cancel_campaign, 3} in callbacks
    end

    test "Engine.Oban implements the behaviour" do
      behaviours =
        Accrue.Dunning.Engine.Oban.module_info(:attributes)
        |> Keyword.get_values(:behaviour)
        |> List.flatten()
      assert Accrue.Dunning.Engine in behaviours
    end

    test "Engine.Oban exports start_campaign/3" do
      assert function_exported?(Accrue.Dunning.Engine.Oban, :start_campaign, 3)
    end

    test "Engine.Oban exports cancel_campaign/3" do
      assert function_exported?(Accrue.Dunning.Engine.Oban, :cancel_campaign, 3)
    end
  end
end
```

#### `accrue/test/accrue/dunning/engine/oban_test.exs` (test)

**Analog:** `accrue/test/accrue/integrations/sigra_test.exs` (structure) + Mox stub pattern from existing dunning tests

**Test strategy:** Use `@tag :with_dunning_campaign` (existing tag) or a Mox-based approach that stubs `DunningStep.enqueue_step/4` and `Oban.cancel_all_jobs/1` without requiring a running Oban instance. The `with_chimeway` test matrix cell is NOT needed — `Engine.Oban` is always-compiled and tested in the standard `mix test` suite.

**Pattern:**
```elixir
defmodule Accrue.Dunning.Engine.ObanTest do
  use ExUnit.Case, async: true
  # Use existing test support for Repo/Oban as needed

  describe "start_campaign/3" do
    test "delegates to DunningStep.enqueue_step for day-zero step" do
      # Verify the correct step_key is enqueued via Mox stub or integration
    end

    test "returns :ok when no day-zero step configured" do
      # Verify :ok when dunning_campaign_steps() has no after_days: 0 entry
    end
  end

  describe "cancel_campaign/3" do
    test "cancels Oban jobs matching the campaign anchor" do
      # Verify Oban.cancel_all_jobs is called with matching query
    end

    test "returns :ok even when cancel raises (rescue pattern)" do
      # Verify the rescue block returns :ok on failure
    end
  end
end
```

---

## Shared Patterns

### Conditional Compile Guard
**Source:** `accrue/lib/accrue/integrations/sigra.ex` lines 31–75
**Apply to:** `accrue/lib/accrue/integrations/chimeway.ex`

The entire `defmodule Accrue.Integrations.Chimeway` block MUST be wrapped in:
```elixir
if Code.ensure_loaded?(Chimeway) do
  defmodule Accrue.Integrations.Chimeway do
    @compile {:no_warn_undefined, [Chimeway, Chimeway.Signal]}
    @behaviour Accrue.Dunning.Engine
    # ...
  end
end
```

### NimbleOptions `:atom` Key Pattern
**Source:** `accrue/lib/accrue/config.ex` lines 269–270 (`:mode` key pattern)
**Apply to:** new `engine:` key in `config.ex` dunning schema

```elixir
mode: [type: {:in, [:stripe_smart_retries, :disabled]}, default: :stripe_smart_retries]
# engine: uses :atom (open set — any implementing module):
engine: [type: :atom, default: Accrue.Dunning.Engine.Oban, doc: "..."]
```

### Config Accessor Pattern
**Source:** `accrue/lib/accrue/config.ex` lines 854–855 (`dunning_campaign_enabled?/0`)
**Apply to:** new `dunning_engine/0` accessor

```elixir
# Pattern: def accessor, do: Keyword.get(dunning(), :key, default)
def dunning_campaign_enabled?, do: Keyword.get(dunning_campaign(), :enabled, false)
# New accessor follows identical shape:
def dunning_engine, do: Keyword.get(dunning(), :engine, Accrue.Dunning.Engine.Oban)
```

### Shell Script Isolation Gate Pattern
**Source:** `scripts/ci/verify_core_liveview_runtime_free.sh` lines 24–47
**Apply to:** `scripts/ci/verify_dunning_chimeway_isolation.sh`

Key elements to preserve verbatim:
- `set -euo pipefail`
- `repo_root="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"`
- `grep ... || true` (prevents `set -e` from triggering on zero matches)
- `if [[ -n "${hits}" ]]; then ... exit 1; fi` (fail-on-hit structure)
- Missing directory check with `exit 1`

### Telemetry / Ledger Separation
**Source:** `accrue/lib/accrue/webhook/default_handler.ex` lines 1219–1258 (the `enqueue_day_zero_step` + `emit_campaign_started` split)
**Apply to:** Phase 131 extraction of `Engine.Oban.start_campaign/3`

`emit_campaign_started/1` (lines 1242–1258) stays in `default_handler.ex`, called in the `count == 1` branch BEFORE the engine dispatch. It must NEVER be moved inside any engine module. Engine modules are pure orchestration delegates; Accrue ledger/telemetry emission is Accrue's responsibility.

### Process Dict Stash Shape Change
**Source:** `accrue/lib/accrue/webhook/default_handler.ex` line 877 and lines 911–919
**Apply to:** both modification sites

The process dict stash changes from `{sub_id :: binary(), iso_anchor :: binary()}` to `{sub :: %Subscription{}, iso_anchor :: binary()}` so the Chimeway adapter's `cancel_campaign/3` can access `sub.customer_id` as tenant_id. Update BOTH the stash write (line 877) and the stash read pattern match (lines 911–913).

---

## No Analog Found

All files have analogs. No entries needed.

---

## Metadata

**Analog search scope:** `accrue/lib/accrue/`, `accrue/test/accrue/`, `scripts/ci/`
**Files scanned:** 9 analog files read in full
**Pattern extraction date:** 2026-05-25

### Critical Implementation Notes (From RESEARCH.md)

1. **stop_conditions DSL is stale** — Do NOT use `stop_conditions` key in `workflow/2`. It appears only in old Chimeway guides and does not exist in the 1.0.0 lib code. If `workflow/2` is implemented at all, use `"progress"` rules with `"wait_until"` / `"on_outcome"` / `"stop"` kinds in step `config` maps.

2. **workflow/2 is optional for v1.40** — With `orchestration: :immediate`, Chimeway delivers email immediately and creates no `WorkflowRun`. `Signal.track("payment_recovered")` is then a no-op — which is correct because Accrue's anchor-clear already prevents future `start_campaign` calls. This is the safe v1.40 default.

3. **Signal.track argument order** — `track(tenant_id, actor_id, event_name, payload)`. `sub.customer_id` = tenant_id; `"accrue.dunning"` = actor_id. Confirmed from chimeway/test/chimeway/signal_test.exs.

4. **Chimeway.trigger/3 requires both opts** — `idempotency_key:` and `tenant_id:` are both required. Missing either returns `{:error, :missing_idempotency_key}` or `{:error, :missing_tenant_id}`. Idempotency key must be `"accrue.dunning:" <> sub.id <> ":" <> iso_anchor`.
