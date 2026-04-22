# Phase 41 — Technical research

**Phase:** 41 — Host metrics wiring + cross-domain example  
**Question:** What do we need to know to plan TEL-01 + OBS-02 well?

## Findings

### 1. `Telemetry.Metrics` event_name derivation (parity anchor)

- `Telemetry.Metrics.counter/2` (and siblings) split the **last** dot segment as the **measurement** key and the prefix as **`event_name`** (`telemetry_metrics` `common_fields/2`).
- Example: `counter("accrue.ops.webhook_dlq.dead_lettered.count")` → `event_name: [:accrue, :ops, :webhook_dlq, :dead_lettered]`, measurement `:count`.
- That matches `Accrue.Telemetry.Ops.emit([:webhook_dlq, :dead_lettered], ...)` → `[:accrue, :ops, :webhook_dlq, :dead_lettered]`.
- **Parity test strategy:** For each tuple in the shared ops allowlist, assert `Enum.any?(Accrue.Telemetry.Metrics.defaults(), &(&1.event_name == tuple))` (and optionally assert struct is a counter-type metric for ops rows). Do **not** compare raw metric name strings alone — use **`event_name`** on structs (see `accrue/test/accrue/telemetry/metrics_test.exs` for struct field access pattern).

### 2. Single source for ops tuples (D-02)

- Today `@expected_ops_events` and `@not_wired_first_party_emits` live only in `ops_event_contract_test.exs`.
- **Refactor:** Move both to `test/support/telemetry_ops_inventory.ex` (compiled in `:test` via `elixirc_paths`) as `Accrue.TestSupport.TelemetryOpsInventory` with `expected_ops_events/0` and `not_wired_first_party_emits/0`. `OpsEventContractTest` and the new parity module **both** call this — no third list in the guide.

### 3. Example host gap (D-14)

- `examples/accrue_host/lib/accrue_host_web/telemetry.ex` `metrics/0` lists Phoenix/Repo/VM metrics but **does not** append `Accrue.Telemetry.Metrics.defaults()` — contradicts `Accrue.Telemetry.Metrics` moduledoc host recipe.
- `AccrueHost.Application` starts `AccrueHostWeb.Telemetry` before Endpoint — correct place to add a **small** child or inline attach for cross-domain demo; prefer **dedicated module** under `lib/accrue_host/` started once (D-13) over attaching inside Accrue contexts.

### 4. Guide placement (D-07–D-09)

- **One** new titled subsection under `accrue/guides/telemetry.md` (after catalog / near host wiring): cross-domain attach + optional bounded billing span note — **link** to ops catalog rows, **no** second table.
- OTel-only escape hatch: short paragraph, not the default path (D-17).

### 5. Primary narrative choice (D-10)

- **DLQ dead-lettered** is the strongest ops story for hosts (Oban + replay path already documented in catalog) vs **charge_failed** (payment health). Planner default: **webhook_dlq dead_lettered** as primary `:telemetry.attach/4` example unless executor finds a clearer anchor in host code.

## Pitfalls

- **Do not** teach subscribing to all `[:accrue, :billing, …]` as default onboarding (D-11).
- **Do not** put customer/subscription IDs in metric tags in examples (D-12).
- **Do not** add a second long guide file (D-09).

## Validation Architecture

Phase 41 validation is **ExUnit + doc grep + example host compile**:

| Dimension | Strategy |
|-----------|----------|
| Correctness | `cd accrue && mix test test/accrue/telemetry/` (inventory refactor + new parity test + existing `metrics_test.exs` + `ops_event_contract_test.exs`) |
| Example host | `cd examples/accrue_host && mix compile` and optionally `mix test` if host tests exist |
| Docs | `rg` anchors for new subsection title + anchor fragment in README |

**Quick command:** `cd accrue && mix test test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs`  
**Full suite (pre-merge):** `cd accrue && mix test`

Sampling: run telemetry test path after each plan wave; full `accrue` test suite before phase verify-work.

---

## RESEARCH COMPLETE
