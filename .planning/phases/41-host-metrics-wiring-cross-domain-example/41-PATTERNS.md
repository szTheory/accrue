# Phase 41 — Pattern map

Analogs for telemetry parity + host wiring in this repo.

| Intent | Target / analog | Notes |
|--------|-----------------|-------|
| Ops allowlist + guide literals | `accrue/test/accrue/telemetry/ops_event_contract_test.exs` | Phase 41 extracts tuple list to `test/support/telemetry_ops_inventory.ex` for reuse (D-02). |
| Metrics struct shape | `accrue/test/accrue/telemetry/metrics_test.exs` | Uses `:name` and `:event_name` on `Telemetry.Metrics.*` structs — parity test follows same access. |
| `defaults/0` recipe | `accrue/lib/accrue/telemetry/metrics.ex` | Conditional compile on `Code.ensure_loaded?(Telemetry.Metrics)` — tests assume dep present like existing `MetricsTest`. |
| Host Telemetry supervisor | `examples/accrue_host/lib/accrue_host_web/telemetry.ex` | Append `++ Accrue.Telemetry.Metrics.defaults()` to `metrics/0` (D-14). |
| Application children | `examples/accrue_host/lib/accrue_host/application.ex` | Add dedicated attach module as child after `AccrueHostWeb.Telemetry` (D-13). |
| Phase 40 guide spine | `accrue/guides/telemetry.md` | Subsection + anchors only; catalog remains SSOT from Phase 40. |

---

## PATTERN MAPPING COMPLETE
