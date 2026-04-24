# Phase 80: Checkout session on `Accrue.Billing` - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`080-CONTEXT.md`**.

**Date:** 2026-04-24  
**Phase:** 80-checkout session on `Accrue.Billing`  
**Areas discussed:** Telemetry metadata, Test file layout, `@doc` depth, ExUnit failure classes  
**Method:** User requested **all** areas + parallel **generalPurpose** research subagents; maintainer one-shot synthesis.

---

## 1. Span metadata (minimal vs allowlisted dimensions)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Match portal — only existing `billing_metadata` fields | |
| B | Add `checkout_mode`, `checkout_ui_mode`, `line_items_count` (namespaced, validated only, no secrets/URLs) | ✓ |

**User's choice:** Maintainer synthesis adopted **B** with strict allowlist and tests on telemetry payload.  
**Notes:** Subagent compared Honeycomb/Datadog usefulness vs symmetry; Stripe/logging footguns favor allowlist + policy over minimal black box.

---

## 2. Test file layout

| Option | Description | Selected |
|--------|-------------|----------|
| A | Dedicated `checkout_session_facade_test.exs` adjacent to portal facade test | ✓ |
| B | Fold into larger billing test module | |

**User's choice:** **A** — matches repo grain and **BIL-04** precedent.

---

## 3. `@doc` depth on `Accrue.Billing`

| Option | Description | Selected |
|--------|-------------|----------|
| A | Full duplicate of all Checkout options in Billing | |
| B | Minimal one-liner only | |
| Hybrid | Portal-shaped sections + `m:Accrue.Checkout.Session` SSOT for options | ✓ |

**User's choice:** **Hybrid** per subagent + cohesion with **`create_billing_portal_session/2`**.

---

## 4. ExUnit failure classes

| Option | Description | Selected |
|--------|-------------|----------|
| A | NimbleOptions only | |
| B | Processor `{:error, _}` via Fake script only | Partial |
| C | B + one structural invalid-key test | ✓ |

**User's choice:** **Processor scripted (required)** + **one invalid attr** test (required) — satisfies BIL-06 “at least one” with stronger facade-boundary proof than portal file alone.

---

## Claude's Discretion

- Optional extra Fake scenarios: only if trivially small (**080-CONTEXT** D-08).

## Deferred ideas

- **INT-12** surfaces — Phase **81** by default.
