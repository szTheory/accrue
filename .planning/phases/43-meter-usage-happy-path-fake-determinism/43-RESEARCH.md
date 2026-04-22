# Phase 43 — Technical research

**Question:** What do we need to know to plan **Meter usage happy path + Fake determinism** well?

**Sources:** `43-CONTEXT.md`, `.planning/REQUIREMENTS.md` (MTR-01..MTR-03), `.planning/research/v1.10-METERING-SPIKE.md`, current `accrue/lib` + `accrue/test` meter code.

## RESEARCH COMPLETE

### 1. Current implementation map

- **Public API:** `Accrue.Billing.report_usage/3` and `report_usage!/3` delegate to `MeterEventActions` inside `span_billing(:meter_event, :report_usage, ...)`, so **ExDoc must live on the `Billing` defs** (CONTEXT D-07); duplicating full option tables in guides violates D-08/D-09.
- **Options schema:** `@report_usage_schema` in `MeterEventActions` — keys `:value`, `:timestamp`, `:identifier`, `:operation_id`, `:payload` with NimbleOptions types; `validate!` raises on bad opts.
- **Lifecycle:** `pending` insert + `accrue_events` inside `Repo.transact/2`; processor `report_meter_event/1` **outside** transaction; success → `reported` + `reported_at`; failure → `failed` + ops telemetry (Phase 44 deepens failure catalog).
- **Fake:** `Accrue.Processor.Fake.report_meter_event/1` and `meter_events_for/1` already exist; tests today alias `Fake` from `Accrue.BillingCase`.

### 2. Gap vs MTR-01..MTR-03

| REQ | Gap |
|-----|-----|
| **MTR-01** | `Billing.report_usage/3` has **no** `@doc` describing opts; hosts must read source or `MeterEventActions` moduledoc. |
| **MTR-02** | Row semantics exist in `MeterEvent` moduledoc and tests; **published** testing narrative for Fake metering is thin in `guides/testing.md`. |
| **MTR-03** | Tests use **`Fake.meter_events_for/1` directly**; CONTEXT D-02/D-03 require **`Accrue.Test`** facade with non-Fake guardrail. Determinism: idempotency test uses `DateTime.utc_now()` — CONTEXT D-04 wants **fixed `timestamp:`** for golden vectors; async tests should avoid module-attribute “unique” ids (D-05). |

### 3. Determinism levers (execution order)

1. **`operation_id:`** — passed through `Actor` override or opt; drives `identifier` derivation when not overridden.
2. **`timestamp:`** — `DateTime` or unix int; stabilizes `derive_identifier/4` phash input.
3. **`identifier:`** — bypasses derivation; use only when the test explicitly targets override behavior.

### 4. Telemetry (Phase 43 ceiling)

- Billing span: `[:accrue, :billing, :meter_event, :report_usage, :start | :stop | :exception]` per `Accrue.Telemetry` moduledoc.
- **D-12:** At most one narrow test: attach handler, call happy-path `report_usage`, assert exactly one `:stop` (or start+stop pair), assert **no** `:exception` for the same invocation path.

### 5. Out of scope (defer)

- `meter_reporting_failed` matrices, reconciler/webhook sources — Phases **44–45** (CONTEXT D-13).
- `guides/metering.md` — Phase **45** (D-09).

---

## Validation Architecture

**Nyquist Dimension 8 —** Phase 43 is **ExUnit + Mix** only. Validation is **automated** via `mix test` scoped to meter paths; no manual Stripe Dashboard steps.

| Dimension | Strategy |
|-----------|----------|
| **1–2 Requirements trace** | Each plan frontmatter lists `MTR-0x`; executor grep-checks after merge. |
| **3 Contract** | Assertions on `MeterEvent.stripe_status`, `identifier`, Fake payload shape via `Accrue.Test.meter_events_for/1`. |
| **4 Regression** | `mix test test/accrue/billing/meter_event_actions_test.exs` (and new/updated modules) green after each wave. |
| **5 Security** | Docs/tests must not log or print live **`:payload`** secrets; examples use synthetic keys only. |
| **6 Performance** | N/A for doc-only tasks; tests remain sub-second Fake paths. |
| **7 Observability** | Optional single telemetry smoke — event name + count only. |
| **8 Sampling** | After each task: `mix test` on touched test files; wave end: full `meter_*` + `billing/meter` grep suite. |

**Sign-off command (executor):** `mix test test/accrue/billing/meter_event_actions_test.exs test/accrue/processor/fake_meter_event_test.exs` (extend paths if new test modules added in Plan 03).
