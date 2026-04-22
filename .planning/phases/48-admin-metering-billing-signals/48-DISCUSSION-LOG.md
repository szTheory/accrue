# Phase 48: Admin metering & billing signals - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`48-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 48 — Admin metering & billing signals  
**Areas discussed:** Primary aggregate; Deep link & href honesty; Webhook KPI coexistence; Verification posture  
**Mode:** User requested **all** gray areas + parallel **subagent research** + one-shot synthesis (no interactive menu).

---

## Primary aggregate

| Option | Description | Selected |
|--------|-------------|----------|
| A | Count terminal **`failed`** rows on **`accrue_meter_events`** | ✓ |
| B | Reconciler-eligible **`pending`** (e.g. age > grace window) |  |
| C | All **`pending`** rows |  |
| D | Time-windowed failure **rate** only | (optional delta — **D-03**) |
| E | Latency / oldest-pending (non-scalar) |  |

**User's choice:** Delegated to synthesis after research.  
**Notes:** Chosen for alignment with **`meter_reporting_failed`** “durable transition” semantics and `MeterEvent` lifecycle; avoids alert fatigue from raw `pending`. Subagent cited Pay/Stripe/Cashier footguns (retry-shaped metrics, vague “usage” labels).

---

## Deep link destination

| Option | Description | Selected |
|--------|-------------|----------|
| 1 | **`/events`** unfiltered (`ScopedPath`) — meta explains KPI vs list | ✓ |
| 2 | **`/webhooks`** + query filters |  |
| 3 | Filtered **`/events?type=`** | Deferred without SQL ↔ `Queries.Events` parity |

**User's choice:** Synthesized — **`/events`** without query params for Phase 48.  
**Notes:** Subagent warned KPI ↔ **`Webhooks.list` + `scope_rows`** parity risk; ledger filter parity for `failed` meter rows is also non-obvious (ledger types ≠ row cardinality). Honest copy beats a misleading pre-filter.

---

## Webhook KPI vs new meter KPI

| Theme | Selected approach |
|-------|-------------------|
| Cognitive model | Webhook card = ingestion queue; new card = **`MeterEvent` terminal health** |
| Copy | Distinct `Copy.*` keys; scoped labels; one meta line naming **`accrue_meter_events`** |
| Tone | Independent **`delta_tone`** per card |

**User's choice:** Adopted research “do not” list (no shared vague meter language, no duplicate crisis signaling without distinct meaning).

---

## Verification posture

| Option | Description | Selected |
|--------|-------------|----------|
| A | **ExUnit** (`LiveViewTest` + `Copy` tests + sandbox) | ✓ |
| B | Expand **Playwright/axe** in Phase 48 |  |

**User's choice:** **ExUnit-first in 48**; Playwright/axe concentration in **Phase 50 (ADM-06)**; minimal VERIFY-01 touch only if a merge-blocking spec would otherwise break.

---

## Claude's Discretion

- Optional 24h failed **delta** after schema/timestamp review (**D-03**).
- Final `Copy.*` function names.

## Deferred Ideas

See **`48-CONTEXT.md`** `<deferred>` section.
