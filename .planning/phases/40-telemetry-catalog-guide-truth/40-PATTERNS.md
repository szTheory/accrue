# Phase 40 — Pattern map

Analogs for doc + telemetry contract work in this repo.

| Intent | Target / analog | Notes |
|--------|-----------------|-------|
| Guide as SSOT + contract test | `accrue/test/accrue/docs/troubleshooting_guide_test.exs` (v1.1 phase 12) | Pattern: ExUnit asserts required strings exist in Markdown; Phase 40 uses smaller surface (ops table + allowlist). |
| Ops emit helper | `accrue/lib/accrue/telemetry/ops.ex` | `emit/3` appends `[:accrue, :ops]`; moduledoc lists canonical tuples — keep list aligned with guide, not duplicated schema. |
| Span + OTel bridge | `accrue/lib/accrue/telemetry.ex` + `accrue/lib/accrue/telemetry/otel.ex` | `span/3` → `OTel.span/3`; `span_name/1` is dot-join of atoms. |
| Billing span coverage | `accrue/test/accrue/telemetry/billing_span_coverage_test.exs` | Enumerates “every public `Accrue.Billing` function wrapped” — OTel section should **point here** for non-exhaustive billing span inventory. |
| Ops emits in lib | `accrue/lib/accrue/webhook/default_handler.ex`, `.../connect_handler.ex`, `.../workers/mailer.ex`, `.../events.ex`, `.../webhooks/dlq.ex`, `.../webhook/pruner.ex`, `.../billing/meter_event_actions.ex`, `.../jobs/meter_events_reconciler.ex` | All `[:accrue, :ops` call sites for contract grep. |

---

## PATTERN MAPPING COMPLETE
