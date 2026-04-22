# Phase 49: Drill flows & navigation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`049-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 49 — Drill flows & navigation  
**Mode:** `[--all]` — all gray areas auto-selected; user requested one-shot **subagent research** + cohesive recommendations (no interactive Q&A).

**Areas covered:** (1) Primary drill slice, (2) Smoother definition, (3) Nav vs drill-only, (4) Verification posture.

---

## Gray area 1 — Primary drill slice (ADM-02)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Customer → subscription → invoice | Single vertical slice; aligns Pay/Cashier + fixes subscription asymmetry vs invoice breadcrumbs | ✓ |
| B — Invoice-first | Fast for finance; weaker human context | |
| C — Subscription-first without customer | Matches weak current chrome; rejected | |
| D — Webhooks/events | Wrong primary ADM-02 story for this phase | |

**User's choice:** Delegated to research synthesis — **Option A** locked in **049-CONTEXT.md** as **D-01..D-03**.

**Notes:** Four parallel `generalPurpose` subagents researched ecosystem + idioms; orchestrator reconciled toward **customer-anchored** chain with **`SubscriptionLive`** as the **primary code surface** (breadcrumb gap vs **`InvoiceLive`**).

---

## Gray area 2 — “Smoother” definition

| Pattern | Role in Phase 49 | Selected |
|---------|------------------|----------|
| Breadcrumb parity with Invoice | Add **Customer** segment on **Subscription** detail | ✓ |
| Curated Related `ax-card` | ≤5 honest links | ✓ |
| URL-driven list state | `handle_params`; no session-only filters | ✓ |
| Honest filter deep links | Only if query parity proven | ✓ (conditional) |

**Notes:** Merged subagent-2 “subscription hub” framing into **customer-anchored slice** — hub means **detail page polish**, not subscription-first **navigation**.

---

## Gray area 3 — Navigation (ADM-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Drill-only (no sidebar IA) | Keeps blast radius low | ✓ |
| Restructure `AccrueAdmin.Nav` in 49 | README + tests + muscle memory | |

**Notes:** Doc-only README clarification allowed per **D-09** if it reduces router-vs-sidebar confusion.

---

## Gray area 4 — Verification

| Option | Description | Selected |
|--------|-------------|----------|
| LiveViewTest + host integration | Primary ADM-02 proof | ✓ |
| New Playwright/axe in 49 | Deferred to Phase 50 (ADM-06) | |
| Minimal Playwright fix | Only if existing VERIFY-01 blocking spec breaks (D-13) | ✓ (exception) |

---

## Claude's Discretion

- Related card **exact** link set inside **≤5** cap and optional filtered invoice list — bounded by honesty rules (**049-CONTEXT.md**).

## Deferred Ideas

See `<deferred>` in **`049-CONTEXT.md`**.
