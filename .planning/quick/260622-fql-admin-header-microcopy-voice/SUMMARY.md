---
quick_id: 260622-fql
slug: admin-header-microcopy-voice
date: 2026-06-22
status: complete
validate: true
verify: Verified
---

# Summary: Admin page headers — one consistent JTBD-oriented voice

Rewrote every admin section page's header (`h1.ax-display` + `p.ax-body.ax-page-copy` subtitle) to
the `/admin/customers` philosophy, fixing inconsistent voice + implementation-jargon leakage, and
**added the missing Recovery subtitle** (the user's headline complaint). Copy + tiny markup only —
**no CSS/JS, no asset-bundle rebuild** (`--validate`: plan-check PASS w/ corrections folded in —
incl. a missed events test assertion; verify PASS 7/7). 3 atomic code commits on `main`.

## What changed

**The consistency rules applied:** h1 = plain section noun (matches nav label); subtitle = two-part
"[what this is, in domain terms]. [how you navigate/act — search/filter/open]"; brand voice
(Measured/Exact/Native/Durable); domain-native but **implementation-hidden** (stripped "facade /
query layer / projections / audit seams / server-side / admin surface / raw status checks /
Lifecycle-safe / dedicated admin surface"); not boilerplate.

- **Strings rewritten in place** (existing fn names kept, no rename): `copy/billing_event.ex`
  (events headings → "Event log" both org+global + new append-only subtitles), `copy/invoice.ex`
  → "Invoices", `copy/coupon.ex` → "Coupons", `copy/promotion_code.ex` → "Promotion codes",
  `copy/connect.ex` → "Connected accounts" + new subtitles.
- **4 new helpers added directly in `copy.ex`** (beside the `*_index_empty_*` family):
  `subscriptions_index_heading/subtitle`, `charges_index_heading/subtitle`,
  `webhooks_index_heading/subtitle`, `recovery_index_heading/subtitle`.
- **LiveViews wired:** subscriptions/charges/webhooks_live.ex dropped their inline `<h1>`/`<p>`
  literals for `Copy.<page>_index_*()`; `analytics/recovery_live.ex` moved the h1 to a Copy helper
  AND **added** `<p class="ax-body ax-page-copy">` (after `.ax-heading-row`, before `WindowSelector`).
- Dashboard + Customers headers **unchanged** (the reference voice).

## Result

`mix compile --warnings-as-errors` clean; full `mix test` → **350 tests, 0 failures**. `assets_test`
green **without** a rebuild (no CSS/JS touched); `copy_test.exs` CPY-03 token-check green. Grep
confirms no implementation jargon remains in any page header/subtitle; Recovery renders a subtitle
(test-covered).

## Commits
- `68fb8bc5` — feat(copy): rewrite section-header strings + 4 new copy.ex heading/subtitle helpers
- `b3709f8f` — refactor: wire subscriptions/charges/webhooks inline headers to Copy + Recovery subtitle markup
- `beef8722` — test: update header assertions (incl. events) + add Recovery subtitle test

## Notes / decisions
- **Plan-check caught a blocker the first grep missed:** `events_live_test.exs:172` asserted the OLD
  literal "Billing activity for the active organization" (events asserts the literal, not
  `Copy.<fn>()`) — folded into the must-update set and fixed.
- **Accepted out-of-scope leftovers (not headers):** "billing facade" survives in a refund flash +
  invoice-actions body; `webhooks_index_table_caption` keeps the old phrase (it's a table
  `<caption>`, not the page header). All explicitly out of scope.
- "Revenue Recovery" kept as the one title-case h1 (nav label is "Recovery") — user-approved exact
  string.
- Guardrails honored: no Tailwind/CSS/JS, bundles untouched, no StatusBadge/CSP/host
  mix.lock/ROADMAP changes, no host tests.

## Supersedes
Closes todo `.planning/todos/260622-admin-page-header-microcopy-audit.md` (deleted in the docs
commit) — this task IS that audit, executed.

## Browser-only follow-up (user visual confirm)
Walk every section (`/admin/customers`, `…/subscriptions`, `…/invoices`, `…/payments`,
`…/webhooks`, `…/events`, `…/coupons`, `…/promotion-codes`, `…/analytics/recovery`, `…/connect`):
each shows a plain-noun h1 + a one/two-sentence subtitle in the same voice; **Recovery now has a
subtitle**; copy reads as job-orientation, not jargon or boilerplate.
