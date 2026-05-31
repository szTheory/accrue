# Phase 155: StripeFixtures Polish + Telemetry Counters - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 155-StripeFixtures Polish + Telemetry Counters
**Areas discussed:** Folded todo, fixture option semantics, StripeFixtures moduledoc positioning, telemetry metrics defaults, verification placement

---

## Folded Todo

| Option | Description | Selected |
|--------|-------------|----------|
| Fold it | Carries the original ENT-10 follow-up source into CONTEXT.md as canonical history. | ✓ |
| Review only | Records that it was seen but does not treat it as scope-driving context. | |

**User's choice:** `1.1` — fold it.
**Notes:** The todo was originally marked `resolves_phase: 154`, but Phase 154 context explicitly deferred IN-03 and IN-04 to Phase 155.

---

## Fixture Option Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| `omit_livemode: true` | Boolean fixture option deletes `"livemode"` from the summary object; keeps `livemode:` boolean semantics intact. | ✓ |
| `livemode: :omit` | Sentinel value on the existing `livemode` option. | |
| Manual `Map.delete` in tests | Keep fixture unchanged and mutate nested payloads per test. | |

**User's choice:** User requested subagent-backed one-shot recommendations across all areas, not another choice menu.
**Notes:** Advisor research recommended `omit_livemode: true` as the most idiomatic Elixir fixture DX and least surprising for maintainers. It avoids sentinel type surprise and avoids duplicating fixture internals in tests.

---

## StripeFixtures Moduledoc

| Option | Description | Selected |
|--------|-------------|----------|
| Test-support boundary wording | Say the module lives under `test/support`, is not part of the published Hex API, and adopters should copy needed fixtures into their own tests. | ✓ |
| Keep current general fixture wording | Leave package/public boundary implicit. | |
| Promote stable fixture API language | Treat fixtures as reusable public test API. | |

**User's choice:** User requested cohesive recommendation.
**Notes:** The selected wording matches project posture: Accrue is a library with strong adopter DX, but test-support modules should not be accidentally treated as runtime/public Hex APIs.

---

## Telemetry Metrics Defaults

| Option | Description | Selected |
|--------|-------------|----------|
| Exact webhook counters | Add `accrue.webhooks.malformed_entitlement_summary.count` with `:reason` tag and `accrue.webhooks.orphan_entitlement_summary.count`. | ✓ |
| Ops namespace bridge/migration | Emit or bridge these through `Accrue.Telemetry.Ops` and default metrics there. | |
| Document omission only | Leave hosts to define metrics manually. | |

**User's choice:** User requested cohesive recommendation.
**Notes:** Advisor research recommended exact webhook counters. This satisfies POL-04 directly, preserves current namespace semantics, and avoids a compatibility-managed telemetry migration. `:reason` remains bounded and acceptable; high-cardinality tags remain forbidden.

---

## Verification Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Update existing focused tests | Use `omit_livemode: true` in the existing entitlement-summary reducer test and add named/event tuple assertions in `metrics_test.exs`. | ✓ |
| Add dedicated new tests | Create isolated test modules/blocks only for the fixture option and metric definitions. | |
| Docs/context only | No new tests. | |

**User's choice:** User requested cohesive recommendation.
**Notes:** Advisor research recommended updating the existing focused tests for best signal-per-line. Do not update `TelemetryOpsInventory`; it is explicitly ops-only.

---

## the agent's Discretion

- Planner may choose the smallest clear implementation shape for deleting the `"livemode"` key inside `entitlement_summary_event/2`, provided `omit_livemode: true` wins over `livemode: ...`.
- Planner may choose whether the metrics test checks metric names, `event_name`, or both, but it must avoid list-order and total-count brittleness.

## Deferred Ideas

- Separate non-ops telemetry parity inventory for all emitted Accrue events.
- Broader compatibility-managed migration of malformed/orphan entitlement-summary events into the ops namespace.
