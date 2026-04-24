---
phase: 76
slug: customer-pm-tab-inventory-copy-burn-down
status: approved
created: 2026-04-24
---

# Phase 76 — UI design contract: Customer payment methods tab

## Surface

- **Route:** `GET /customers/:id?tab=payment_methods` (mount path prefix from host; default demo **`/billing/customers/:id`**).
- **LiveView:** `AccrueAdmin.Live.CustomerLive` — `case @tab` branch **`"payment_methods"`** only for Phase 76 code edits.
- **Chrome:** Card uses `section.ax-card` with `h3.ax-heading`, list rows `div.ax-list-row` with `span.ax-body` (existing pattern; do not change layout tokens in 76 except where copy text is replaced by `AccrueAdmin.Copy` calls).

## Roles and tasks

| Role | Task |
|------|------|
| Billing operator | Scan saved payment methods (brand/type, last4 mask, expiry) for a customer. |
| Billing operator | Recognize empty state when customer has no payment methods. |

## Copy and tone

- **Tier A English** via `AccrueAdmin.Copy` / new submodule — same contract as invoice/subscription surfaces (no host Gettext in 76).
- **Card title** and **empty state** must read as neutral operator chrome (no marketing voice).
- **Row fallback** when brand/type missing: single concise label (today literal `"Payment method"` — migrates to Copy-backed equivalent).

## Accessibility

- **Headings:** One `h3` per tab panel (`Payment methods` → Copy-backed string must remain a sensible accessible name when surfaced in heading APIs).
- **Lists:** Rows are visual list rows; no new interactive controls in 76. Preserve existing `ax-list-row` / `ax-body` structure for screen-reader order.
- **axe / Playwright:** Explicitly **out of scope for Phase 76** (Phase 77 ADM-15). No new `@axe-core` scenarios in this phase.

## States

| State | Visual |
|-------|--------|
| Has methods | One row per method; brand/type · masked last4; expiry column. |
| Empty | Single `p.ax-body` empty line. |

## Navigation

- Tab label for `payment_methods` comes from `Tabs` config (`humanize/1` today); Phase 76 **does not** rename tab IDs or query param values.

## Out of scope (visual)

- Subscriptions KPI delta string referencing payment methods (`customer_live.ex` KPI grid) — inventory only; no layout/copy change in 76 per CONTEXT **D-09**.
- Charges empty state, tax strings, other tabs — unchanged in 76.
