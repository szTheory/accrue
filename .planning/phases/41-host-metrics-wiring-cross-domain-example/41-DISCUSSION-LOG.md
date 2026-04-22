# Phase 41: Host metrics wiring + cross-domain example - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `41-CONTEXT.md`.

**Date:** 2026-04-21  
**Phase:** 41 — Host metrics wiring + cross-domain example  
**Areas discussed:** TEL-01 closure strategy; OBS-02 doc/example placement; cross-domain proof depth (ops vs billing); example host `defaults/0` wiring

---

## Selection

User invoked `/gsd-discuss-phase 41` with **`all`** gray areas, then requested parallel subagent research (pros/cons, ecosystem idioms, footguns) and **accepted** the synthesized one-shot recommendation bundle in a follow-up message.

---

## 1 — TEL-01 closure strategy

| Option | Description | Selected |
|--------|-------------|----------|
| ExUnit parity + shared ops allowlist | New test: every `@expected_ops_events` entry covered by `defaults/0` metric `event_name`, with explicit omission list if needed | ✓ |
| `mix` task only | Separate CLI check | |
| Codegen metrics module | Generate from declarative source | |
| Doc + release checklist | Human-only verification | |

**User's choice:** ExUnit contract aligned with `OpsEventContractTest`, optional explicit omissions, no codegen for current scale; defer standalone Mix task unless needed.

**Notes:** Assert on metric structs; respect optional `:telemetry_metrics` compile path.

---

## 2 — OBS-02 example placement

| Option | Description | Selected |
|--------|-------------|----------|
| Guide + example host (thin hybrid) | New subsection in `guides/telemetry.md` + minimal wiring in `examples/accrue_host` + README link | ✓ |
| Guide only | No compile proof in host | |
| New top-level guide | Split observability docs | |

**User's choice:** Single guide remains SSOT for catalog; cross-domain narrative lives in `telemetry.md`; example proves wiring.

---

## 3 — Cross-domain proof depth

| Option | Description | Selected |
|--------|-------------|----------|
| Ops-first | One `:telemetry.attach` for one `[:accrue, :ops, …]` at app/supervision boundary | ✓ (primary) |
| Billing firehose first | Broad `[:accrue, :billing, …]` subscription | ✗ as default |
| Optional bounded billing | One resource, `:stop`/`:exception` only + cardinality warnings | ✓ (optional snippet) |

**User's choice:** Primary = ops; optional second snippet with strict cardinality prose; attach not inside hot context paths.

---

## 4 — Example host telemetry_metrics / defaults

| Option | Description | Selected |
|--------|-------------|----------|
| Append `++ Accrue.Telemetry.Metrics.defaults()` | Matches moduledoc + guide; CI proves glue | ✓ |
| Attach-only while keeping deps | Current partial state | ✗ |
| Remove metrics deps for “minimal” demo | Contradicts headline recipe unless rebranded | ✗ (not default) |

**User's choice:** Wire `defaults/0` in host `metrics/0`, align `telemetry_metrics` version, commented reporter pointer.

---

## Claude's Discretion

- Which single ops event anchors the primary narrative (DLQ vs charge failed).
- Whether optional billing snippet ships if scope tightens.

## Deferred Ideas

- Mix-only parity task; second long guide; Phase 42 runbooks; v1.10 metering API docs.
