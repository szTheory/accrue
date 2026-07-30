# Phase 209: Reign Subscriptions (list + detail CSS coordination) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-19
**Phase:** 209-reign-subscriptions-list-detail-css-coordination
**Areas discussed:** Per-row action treatment, WorkQueueCallout extract-or-inline, Health verdict composition, Detail-page shared-CSS safety

---

## Per-row action treatment (REIGN-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Drop it — row navigates | No per-row action column; identity cell is `ax-link`, whole row navigates to `/subscriptions/:id`; queue action lives only in the single PageHeader CTA. Matches reference pages; best density. | ✓ |
| Dedicated actions column | Right-aligned actions column with per-row invoice-queue affordance. Costs density; diverges from reference. | |
| DropdownMenu per row | Per-row `⋯` menu (detail-page idiom). Heaviest; introduces a control the good list pages don't use. | |

**User's choice:** Drop it — row navigates.
**Notes:** Grounded in scouting: `invoices_live.ex` / `customers_live.ex` have no per-row action column; `DropdownMenu`/`action_menu` appear only on detail pages. Removes the current in-cell "Work open invoices" button (the REIGN-02 anti-pattern). Content preserved by relocating open-invoice data into the StatStrip verdict.

---

## WorkQueueCallout — extract-or-inline (COMP-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Inline now, decide in 210 | Compose from `.ax-card` directly in 209; make the extract call in 210 when Home's rail proves the repeat. Avoids speculative abstraction; COMP-01 resolves as "inline" in 209. | ✓ |
| Extract now for Home | Build `WorkQueueCallout` speculatively in 209 for Home to consume in 210. Bets on Home's shape before seeing it. | |

**User's choice:** Inline now, decide in 210.
**Notes:** Honors the "only if demonstrably repeats" gate literally — the second consumer (Home) isn't reigned until Phase 210.

---

## Health verdict composition (IA-01 / content-preservation)

| Option | Description | Selected |
|--------|-------------|----------|
| Exposure-first (recommended) | StatusBadge + StatStrip: Open invoices · Exposure ($) · At-risk · Last webhook. Leads with money-at-risk. | ✓ |
| Count-first | Same signals, lead with subscription counts (active/at-risk). Census-first framing. | |
| Let planner derive from bands | Don't lock the set/order; instruct planner to relocate exactly the removed-band data, answer-first. | |

**User's choice:** Exposure-first (recommended).
**Notes:** Money-at-risk is the operator's first question. Set is still gated by the content-preservation proof (all five-band data must land in the strip).

---

## Detail-page shared-CSS safety (REIGN-02 → Phase 211 handoff)

| Option | Description | Selected |
|--------|-------------|----------|
| PNG-verify detail + grep-gate (recommended) | grep to confirm remaining refs are only `subscription_live.ex`; zero edits to shared CSS in 209; PNG detail before/after → identical; deletion stays in 211. | ✓ |
| Just don't touch shared CSS | Template-only changes, no CSS edits, no explicit detail-page PNG check. | |

**User's choice:** PNG-verify detail + grep-gate (recommended).
**Notes:** This is the phase's namesake risk; the out-of-scope detail page must be provably unbroken.

---

## Claude's Discretion

- Exact PageHeader slot wiring, StatStrip stat structs, DataTable column render-fn refactor — left to planner/executor within the UI-SPEC contract.
- Removal of the now-dead `open_invoice_queue/1` query and `invoice_queue_record_href` helpers as part of band removal.

## Deferred Ideas

- `WorkQueueCallout` extraction → Phase 210.
- CSS class deletion (grep-gated) → Phase 211 (REIGN-04).
- Home page reign + cross-page IA/COPY certification → Phase 210.
- Answer-first reign of remaining detail surfaces → out of milestone.
