---
quick_id: 260622-fql
slug: admin-header-microcopy-voice
date: 2026-06-22
validate: true
approved_plan: /Users/jon/.claude/plans/i-just-got-an-ethereal-harbor.md
supersedes_todo: .planning/todos/260622-admin-page-header-microcopy-audit.md
---

# Admin page headers: one consistent JTBD-oriented voice across every section

Rewrite every admin section page's header (`h1.ax-display` + `p.ax-body.ax-page-copy` subtitle) to
the `/admin/customers` philosophy: plain-noun h1 (matches nav label) + a two-part subtitle
"[what this is, domain terms]. [how you navigate/act — search/filter/open]". User-facing, JTBD-
oriented, domain-native but implementation-hidden, brand voice (Measured/Exact/Native/Durable), not
boilerplate. Fixes: jargon-leaking subtitles (facade/query layer/projections/audit seams/server-
side/admin surface) and **Recovery has no subtitle**. COPY + tiny markup only — **NO CSS/JS, NO
asset-bundle rebuild**. Full approved-copy table in the approved plan.

## Approved copy (h1 / subtitle) — user-approved exact strings
- Dashboard / Customers: **KEEP unchanged** (the reference voice).
- Subscriptions → "Subscriptions" / "Every subscription for this organization and where it sits in
  its lifecycle. Filter by status or search by customer to find the ones that need attention."
- Invoices → "Invoices" / "Open and uncollectible invoices first — your collections queue. Switch
  status or search by customer to widen the view."
- Payments → "Payments" / "Every charge and refund for this organization. Filter by status, or open
  a charge to see its fees, payment method, and any failure."
- Webhooks → "Webhooks" / "Inbound webhook deliveries, the failed ones first. Open a delivery for
  its full payload, or select deliveries to replay."
- Events (org) → "Event log" / "An append-only record of every billing and admin action in this
  organization. Filter by actor or subject to trace who did what, and when."
- Events (global) → "Event log" / "An append-only record of every billing and admin action across
  all organizations. Filter by actor or subject to trace who did what, and when."
- Coupons → "Coupons" / "Discounts you can apply to subscriptions and invoices. Filter by validity
  or search to find a coupon and see how often it's been redeemed."
- Promotion codes → "Promotion codes" / "Customer-facing codes that apply a coupon at checkout.
  Search by code, or open one to see its coupon and redemptions."
- Recovery → "Revenue Recovery" (move to Copy helper) / ADD "Track the dunning funnel and customers
  at risk of churn — how many recover after a failed payment, and which are nearing cancellation."
- Connect → "Connected accounts" / "Stripe Connect accounts on this platform. Check onboarding and
  payout readiness, or open an account to configure its platform fees."

## Implementation
- Rewrite returned STRINGS in place for Copy-backed pages (KEEP existing fn names — no rename):
  **`copy/billing_event.ex:59-69`** (events `billing_events_heading_organization|global` +
  `billing_events_copy_organization|global` — these live in the submodule; `copy.ex` only
  `defdelegate`s, so edit the SUBMODULE not copy.ex); `copy/invoice.ex` (24,26), `copy/coupon.ex`
  (8,10), `copy/promotion_code.ex` (8,10), `copy/connect.ex` (12,14) — headings → plain noun, bodies
  → new subtitle. Customers (`copy.ex:497-505`) UNCHANGED.
- Extract 4 inline-literal pages to NEW Copy helpers — **add them directly in `copy.ex`** beside the
  existing `*_index_empty_*` family (plan-check confirmed index copy lives in copy.ex, not
  submodules), named `<page>_index_heading/0` + `<page>_index_subtitle/0`:
  `subscriptions_live.ex` (~102-105), `charges_live.ex` (~78-81), `webhooks_live.ex` (~139-142).
  `analytics/recovery_live.ex` (~100-116): h1 → `Copy.recovery_index_heading()`; ADD
  `<p class="ax-body ax-page-copy"><%= Copy.recovery_index_subtitle() %></p>` after the
  `.ax-heading-row` and before the `WindowSelector`.
- OUT OF SCOPE: renaming existing inconsistent Copy fn names. Also leave `copy.ex:727`
  `webhooks_index_table_caption` ("Replay, inspect, and trace webhook delivery") AS-IS — it's a
  table `<caption>`, not the page header; not jargon; no test pins it. (Noted by plan-check.)

## Tests (plan-check-confirmed exact set)
- **MUST UPDATE (literal assertions of OLD header strings that will break):**
  `subscriptions_live_test.exs:50` ("Lifecycle-safe subscription search"),
  `charges_live_test.exs:60` ("Payment and refund review"),
  `webhooks_live_test.exs:66` ("Replay, inspect, and trace webhook delivery"),
  `connect_accounts_live_test.exs:64` ("Connected accounts and payout readiness"),
  **`events_live_test.exs:172` ("Billing activity for the active organization")** ← the blocker the
  first plan grep missed; events asserts the literal, not `Copy.<fn>()`. Update each to the new
  literal or `Copy.<fn>()`.
- **STAY GREEN automatically** (assert via `Copy.<fn>()`): `invoices_live_test.exs:62`,
  `coupons_live_test.exs:64`, `promotion_codes_live_test.exs:62`.
- **`copy_test.exs:140-170` (CPY-03)** — plan-check verified SAFE: it token-checks (invoice/
  subscription/charge/coupon/promotion code/connect/event/webhook/organization), all still present
  in the new strings + unchanged `*_empty_copy`. No change needed, but re-run to confirm.
- **ADD** a Recovery-subtitle render assertion in
  `test/accrue_admin/live/analytics/recovery_live_test.exs` (exists, render test ~line 57+).

## Guardrails
Don't touch StatusBadge, CSP, examples/accrue_host/mix.lock, .planning/research/.cache/, ROADMAP.md.
NO CSS/JS edits → no `assets.build`, priv/static bundles unchanged (assets_test md5 stays). No host
tests. STATE.md "Quick Tasks Completed". Delete the superseded todo. Orchestrator commits docs;
executor commits code. On `main`, non-worktree.

## Commits (atomic)
1. `feat(copy)`: rewrite section-header strings + normalize h1s (copy.ex + copy/ submodules).
2. `refactor`: extract subscriptions/charges/webhooks/recovery inline headers to Copy + Recovery subtitle markup.
3. `test`: update per-page header assertions + Recovery subtitle test.

## Verification
`cd accrue_admin`: `mix compile --warnings-as-errors` clean; full `mix test` green (report N/M).
priv/static bundles UNCHANGED. Grep confirms no jargon fragments remain in headers; Recovery renders
a subtitle.
