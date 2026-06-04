# Phase 178 — Screen × State Coverage Matrix

**Phase:** 178-e-seed-expressiveness-state-coverage
**Produced by:** Plan 178-01 executor (2026-06-04)
**Consumed by:** Phase 179 Playwright screenshot sweep

This matrix is the anti-entropy contract for Phase 178 and Phase 179. Every cell names the fixture
or mechanism that makes that state reachable. Phase 179 iterates this table — each non-N/A cell
maps to at least one Playwright assertion.

---

## Matrix

| Screen | Empty | Populated | Overflow | Error (filtered-empty) | Loading (poll-banner) | Dunning/At-risk | Multi-currency | Long-strings | Dark-contrast |
|--------|-------|-----------|----------|------------------------|-----------------------|-----------------|----------------|--------------|---------------|
| **CustomersLive** | no-fixture: navigate `/billing/customers?status=nonexistent_status` → empty-state renders | operator-flows — navigate `/billing/customers` | seed_overflow — navigate `/billing/customers` → "Load more" visible | no-fixture: navigate `/billing/customers?status=nonexistent_status` → empty-state with "Clear filters" | no-fixture: POST `/seed/operator-flows` twice (no reset between) + wait 5s for poll_interval → newer_count banner appears | seed_edge_states — at-risk customer present in list (customer linked to `at_risk_sub_id`) | N/A (customers have no currency display) | seed_edge_states — `long_name_customer_id` customer appears in list (120-char name truncates in card) | seed_edge_states — `at_risk_sub_id` customer row shows attention signals (billing_signals chip) |
| **SubscriptionsLive** | no-fixture: work-queue default shows 0 if no past_due/canceling rows (empty DB pre-seed state) | operator-flows — navigate `/billing/subscriptions` | seed_overflow — navigate `/billing/subscriptions` → "Load more" visible | no-fixture: navigate `/billing/subscriptions?status=nonexistent_status` → empty-state with "Clear filters" | no-fixture: POST `/seed/operator-flows` twice (no reset between) + wait 5s for poll_interval → newer_count banner appears | seed_edge_states — navigate `/billing/subscriptions` (work-queue default shows `at_risk_sub_id` as past_due + `canceling_sub_id` as canceling) | N/A (subscriptions list has no currency column) | seed_edge_states — long name customer linked to at-risk sub appears in subscription card customer field | seed_edge_states — `:past_due` status triggers tinted `ax-badge-danger` chip in subscription card |
| **InvoicesLive** | no-fixture: work-queue default shows 0 if no open/uncollectible invoices (empty DB pre-seed state) | dashboard — navigate `/billing/invoices` | seed_overflow — navigate `/billing/invoices` → "Load more" visible | no-fixture: navigate `/billing/invoices?status=nonexistent_status` → empty-state with "Clear filters" | no-fixture: POST `/seed/dashboard` twice (no reset between) + wait 5s for poll_interval → newer_count banner appears | N/A (invoices are not at-risk themselves) | seed_edge_states — JPY invoice appears in list (¥55,000 renders in amount column) | seed_edge_states — JPY invoice `number` field (long number string in list card) | seed_edge_states — `:open` invoice status chip renders in list |
| **ChargesLive** | no-fixture: navigate `/billing/charges?status=nonexistent_status` → empty-state renders | operator-flows — navigate `/billing/charges` | seed_overflow — navigate `/billing/charges` → "Load more" visible | no-fixture: navigate `/billing/charges?status=nonexistent_status` → empty-state with "Clear filters" | no-fixture: POST `/seed/operator-flows` twice (no reset between) + wait 5s for poll_interval → newer_count banner appears | N/A (charges are not at-risk) | seed_edge_states — JPY charge appears in list (¥ symbol in amount column) | seed_edge_states — long-string customer name appears in charge card customer field | N/A (no tinted status chips — charge status is plain text) |
| **CouponsLive** | no-fixture: navigate `/billing/coupons?status=nonexistent_status` → empty-state renders (empty DB pre-seed) | host:showcase.exs — navigate `/billing/coupons` (dev env only) | seed_overflow — navigate `/billing/coupons` → "Load more" visible | no-fixture: navigate `/billing/coupons?status=nonexistent_status` → empty-state with "Clear filters" | no-fixture: POST `/seed/operator-flows` twice (no reset between) + wait 5s for poll_interval → newer_count banner appears | N/A (coupons are not at-risk) | N/A (coupons have no currency amounts displayed in list) | seed_edge_states — long-name coupon appears in list (80-char coupon name truncates in card) | N/A (no tinted status chips on CouponsLive list) |
| **PromotionCodesLive** | no-fixture: navigate `/billing/promotion-codes?status=nonexistent_status` → empty-state renders | host:showcase.exs — navigate `/billing/promotion-codes` (dev env only) | seed_overflow — navigate `/billing/promotion-codes` → "Load more" visible | no-fixture: navigate `/billing/promotion-codes?status=nonexistent_status` → empty-state with "Clear filters" | no-fixture: POST `/seed/operator-flows` twice (no reset between) + wait 5s for poll_interval → newer_count banner appears | N/A (promo codes are not at-risk) | N/A (promo codes have no currency amounts displayed in list) | seed_edge_states — long-code promotion code (40-char code) appears in list | N/A (no tinted status chips on PromotionCodesLive list) |
| **ConnectAccountsLive** | no-fixture: navigate `/billing/connect-accounts?status=nonexistent_status` → empty-state renders (empty DB pre-seed) | seed_edge_states — navigate `/billing/connect-accounts` | seed_overflow — navigate `/billing/connect-accounts` → "Load more" visible | no-fixture: navigate `/billing/connect-accounts?status=nonexistent_status` → empty-state with "Clear filters" | no-fixture: POST `/seed/edge-states` twice (no reset between) + wait 5s for poll_interval → newer_count banner appears | N/A (connect accounts are not at-risk) | N/A (connect accounts have no currency amounts displayed in list) | seed_edge_states — connect account with long email appears in list | N/A (no tinted status chips on ConnectAccountsLive list) |
| **EventsLive** | no-fixture: navigate `/billing/events?type=nonexistent_type` → empty-state renders (empty DB pre-seed) | operator-flows — navigate `/billing/events` | seed_overflow — navigate `/billing/events` → "Load more" visible | no-fixture: navigate `/billing/events?type=nonexistent_type` → empty-state with "Clear filters" | no-fixture: POST `/seed/operator-flows` twice (no reset between) + wait 5s for poll_interval → newer_count banner appears | N/A (events are not at-risk) | N/A (events have no currency amounts displayed in list) | seed_edge_states — event with long subject_id appears in list | N/A (no tinted status chips on EventsLive list) |
| **WebhooksLive** | no-fixture: navigate `/billing/webhooks?status=nonexistent_status` → empty-state renders (empty DB pre-seed) | operator-flows — navigate `/billing/webhooks` | seed_overflow — navigate `/billing/webhooks` → "Load more" visible | no-fixture: navigate `/billing/webhooks?status=nonexistent_status` → empty-state with "Clear filters" | no-fixture: POST `/seed/operator-flows` twice (no reset between) + wait 5s for poll_interval → newer_count banner appears | N/A (webhooks are not at-risk) | N/A (webhooks have no currency amounts displayed in list) | seed_edge_states — webhook with long endpoint URL appears in list | seed_edge_states — `:dead` webhook status triggers tinted `ax-badge-danger` chip in card |
| **CustomerLive** | no-fixture: navigate `/billing/customers/nonexistent-uuid` → redirect to index (nil redirect) | operator-flows — navigate to any customer detail e.g. `/billing/customers/:customer_id` | N/A (detail screens have no pagination) | no-fixture: navigate `/billing/customers/nonexistent-uuid` → redirect (same as empty — redirect-on-nil counts as error path) | N/A (detail screens have no poll-banner) | seed_edge_states — navigate to `dunning_customer_id` → customer detail shows past_due subscription in related resources | seed_edge_states — navigate to `long_name_customer_id` → JPY invoice appears in invoice tab if any | seed_edge_states — navigate to `long_name_customer_id` → 120-char name truncates in summary_card header | seed_edge_states — navigate to `dunning_customer_id` → past_due subscription badge in related resources section |
| **SubscriptionLive** | no-fixture: navigate `/billing/subscriptions/nonexistent-uuid` → redirect to index (nil redirect) | operator-flows — navigate to subscription detail e.g. `/billing/subscriptions/:sub_id` | N/A (detail screens have no pagination) | no-fixture: navigate `/billing/subscriptions/nonexistent-uuid` → redirect (redirect-on-nil counts as error path) | N/A (detail screens have no poll-banner) | seed_edge_states — navigate to `at_risk_sub_id` → status shows `:past_due`, dunning section shows active campaign | N/A (subscriptions have no currency in this view) | seed_edge_states — navigate to subscription for `long_name_customer_id` → customer name truncates in summary_card facts | seed_edge_states — navigate to `at_risk_sub_id` → `:past_due` status triggers tinted `ax-badge-danger` in summary_card status chip |
| **InvoiceLive** | no-fixture: navigate `/billing/invoices/nonexistent-uuid` → redirect to index (nil redirect) | dashboard — navigate to invoice detail e.g. `/billing/invoices/:invoice_id` | N/A (detail screens have no pagination) | no-fixture: navigate `/billing/invoices/nonexistent-uuid` → redirect (redirect-on-nil counts as error path) | N/A (detail screens have no poll-banner) | N/A (invoices are not at-risk themselves) | seed_edge_states — navigate to `jpy_invoice_id` → amount renders as ¥55,000 (zero-decimal JPY formatting exercised) | seed_edge_states — navigate to `jpy_invoice_id` → long invoice number in summary_card title if seeded with long number | seed_edge_states — navigate to `jpy_invoice_id` → `:open` status chip renders tinted in summary_card |
| **ChargeLive** | no-fixture: navigate `/billing/charges/nonexistent-uuid` → redirect to index (nil redirect) | operator-flows — navigate to charge detail e.g. `/billing/charges/:charge_id` | N/A (detail screens have no pagination) | no-fixture: navigate `/billing/charges/nonexistent-uuid` → redirect (redirect-on-nil counts as error path) | N/A (detail screens have no poll-banner) | N/A (charges are not at-risk) | seed_edge_states — navigate to `jpy_charge_id` → amount renders with ¥ symbol (zero-decimal JPY path) | seed_edge_states — navigate to charge for `long_name_customer_id` → long customer name in summary_card facts | N/A (charge status is plain text in summary_card — no tinted status chips) |
| **CouponLive** | no-fixture: navigate `/billing/coupons/nonexistent-uuid` → redirect to index (nil redirect) | host:showcase.exs — navigate to coupon detail e.g. `/billing/coupons/:coupon_id` (dev env only) | N/A (detail screens have no pagination) | no-fixture: navigate `/billing/coupons/nonexistent-uuid` → redirect (redirect-on-nil counts as error path) | N/A (detail screens have no poll-banner) | N/A (coupons are not at-risk) | N/A (coupon discount amounts are not multi-currency in Accrue's model) | seed_edge_states — navigate to `coupon_id` → long coupon name (80 chars) truncates in summary_card title | N/A (no tinted status chips — coupon status is plain text) |
| **PromotionCodeLive** | no-fixture: navigate `/billing/promotion-codes/nonexistent-uuid` → redirect to index (nil redirect) | host:showcase.exs — navigate to promo code detail e.g. `/billing/promotion-codes/:promo_id` (dev env only) | N/A (detail screens have no pagination) | no-fixture: navigate `/billing/promotion-codes/nonexistent-uuid` → redirect (redirect-on-nil counts as error path) | N/A (detail screens have no poll-banner) | N/A (promo codes are not at-risk) | N/A (promo codes have no currency amounts in Accrue's model) | seed_edge_states — navigate to `promo_code_id` → long code string (40 chars) in summary_card title | N/A (no tinted status chips — promo code status is plain text) |
| **ConnectAccountLive** | no-fixture: navigate `/billing/connect-accounts/nonexistent-uuid` → redirect to index (nil redirect) | seed_edge_states — navigate to `connect_account_id` → connect account detail | N/A (detail screens have no pagination) | no-fixture: navigate `/billing/connect-accounts/nonexistent-uuid` → redirect (redirect-on-nil counts as error path) | N/A (detail screens have no poll-banner) | N/A (connect accounts are not at-risk) | N/A (connect accounts have no currency amounts) | seed_edge_states — navigate to `connect_account_id` → long email in summary_card facts | N/A (no tinted status chips — connect account status is plain text "Enabled"/"Disabled") |
| **EventLive** | no-fixture: navigate `/billing/events/nonexistent-uuid` → redirect to index (nil redirect) | operator-flows — navigate to event detail e.g. `/billing/events/:source_event_id` | N/A (detail screens have no pagination) | no-fixture: navigate `/billing/events/nonexistent-uuid` → redirect (redirect-on-nil counts as error path) | N/A (detail screens have no poll-banner) | N/A (events are not at-risk) | N/A (events have no currency amounts) | seed_edge_states — navigate to event with long subject_id in summary_card | N/A (no tinted status chips — events have no colored status badge) |
| **WebhookLive** | no-fixture: navigate `/billing/webhooks/nonexistent-uuid` → redirect to index (nil redirect) | operator-flows — navigate to webhook detail e.g. `/billing/webhooks/:single_webhook_id` | N/A (detail screens have no pagination) | no-fixture: navigate `/billing/webhooks/nonexistent-uuid` → redirect (redirect-on-nil counts as error path) | N/A (detail screens have no poll-banner) | N/A (webhooks are not at-risk) | N/A (webhooks have no currency amounts) | seed_edge_states — navigate to webhook with long endpoint URL in summary_card facts | seed_edge_states — navigate to dead-letter webhook from `operator-flows` → `:dead` status triggers tinted `ax-badge-danger` in summary_card |
| **RecoveryLive** | N/A (always renders — empty state shows zeroed KPI cards and empty at-risk table) | seed_edge_states — navigate `/billing/analytics/recovery` → at-risk table non-empty, `at_risk_sub_id` appears | N/A (specialist screen — no pagination) | N/A (no filter path that errors; empty state is valid empty data display) | N/A (specialist screen — no poll-banner) | seed_edge_states — navigate `/billing/analytics/recovery` → at-risk table shows `at_risk_sub_id` with dunning_campaign_started_at set | seed_edge_states — JPY at-risk row in 30-day window (host:hero_accounts.exs after dunning bug fix — dev env only) | N/A (specialist screen — no long-string display paths) | seed_edge_states — at-risk row renders tinted row or status badge for `:past_due` subscription in at-risk table |
| **CampaignLive** | no-fixture: navigate `/billing/analytics/recovery/campaigns/nonexistent-uuid` → empty CampaignTimeline with "No dunning history found" | seed_edge_states — navigate `/billing/analytics/recovery/campaigns/:at_risk_sub_id` → campaign timeline non-empty | N/A (specialist screen — no pagination) | no-fixture: navigate `/billing/analytics/recovery/campaigns/nonexistent-uuid` → empty state renders (no redirect — Dunning returns empty map for unknown IDs) | N/A (specialist screen — no poll-banner) | seed_edge_states — navigate to `/billing/analytics/recovery/campaigns/:at_risk_sub_id` → subscription_id shown in summary_card facts, campaign timeline shows dunning history | seed_edge_states — navigate to `at_risk_sub_id` campaign page (sub has JPY invoice as source of past_due) | N/A (specialist screen — no long-string display paths) | seed_edge_states — summary_card shows `:past_due` status context from subscription facts |
| **DashboardLive** | N/A (always renders — empty state is valid: zeroed KPIs and empty attention rail) | dashboard — navigate `/` → KPI cards populated, timeline non-empty | N/A (no pagination on dashboard) | N/A (dashboard has no error/filter path by design) | N/A (dashboard has no poll-banner) | seed_edge_states — navigate `/` → sidebar Recovery badge count > 0, attention rail shows at-risk row | N/A (dashboard KPIs are aggregate counts, not per-currency amounts) | N/A (dashboard header/KPIs have no long-string truncation risk — copy is hardcoded) | seed_edge_states — sidebar Recovery badge uses `ax-badge-danger` tint when count > 0 |

---

## Legend

| Abbreviation | Meaning |
|---|---|
| `operator-flows` | E2E named fixture: `POST /__e2e__/seed/operator-flows` → calls `Fixtures.seed_operator_flows!/0`. Seeds: 1 customer, 1 subscription, 1 charge, 1 refund, 1 event, 2 webhooks (dead + failed). Returns `%{charge_id, source_event_id, single_webhook_id, bulk_webhook_id}`. |
| `dashboard` | E2E named fixture: `POST /__e2e__/seed/dashboard` → calls `Fixtures.seed_dashboard!/0`. Seeds: 1 customer, 1 subscription, 1 invoice, 1 dead webhook, 1 event. Returns `%{customer_id, subscription_id, event_id}`. |
| `seed_edge_states` | E2E named fixture (Wave 2, Plan 178-02): `POST /__e2e__/seed/edge-states` → `Fixtures.seed_edge_states!/0`. Seeds: past_due at-risk subscription, canceling subscription, JPY invoice, JPY charge, long-name customer, coupon, promo code, connect account. Returns `%{at_risk_sub_id, canceling_sub_id, jpy_invoice_id, jpy_charge_id, dunning_customer_id, long_name_customer_id, coupon_id, promo_code_id, connect_account_id}`. |
| `overflow` fixture | E2E named fixture (Wave 2, Plan 178-02): `POST /__e2e__/seed/overflow` → `Fixtures.overflow!/0` (wave 2 name). Seeds: 26+ customers, subscriptions, invoices, charges, events, webhooks, coupons, promo codes, connect accounts. Returns `%{first_customer_id, first_invoice_id, first_charge_id}`. |
| `host:showcase.exs` | Host-only dev seed: `examples/accrue_host/priv/repo/seeds/showcase.exs`. Not available in E2E test fixture context — dev click-through only. Use `seed_edge_states` for equivalent E2E coverage. |
| `host:hero_accounts.exs` | Host-only dev seed: `examples/accrue_host/priv/repo/seeds/hero_accounts.exs`. After the dunning bug fix (Plan 178-03), this correctly seeds JPY exhausted rows and ties dunning events to real subscription IDs. Dev click-through only. |
| `host:edge_states.exs` | Host-only dev seed (NEW, Plan 178-04): `examples/accrue_host/priv/repo/seeds/edge_states.exs`. Seeds long-string + canceling + explicit at-risk anchor for dev/host click-through. |
| `no-fixture: ...` | State is reachable without seeding — achieved via URL parameter, empty DB, or double-seed + wait. The mechanism is documented in the cell text. |
| `N/A` | State is not applicable to this screen by design (e.g., detail screens do not have pagination; dashboard has no filter-error path). |

---

## Loading State Mechanism — Canonical Documentation

**The `poll-banner` / `newer_count` state** is produced by the `DataTable` component's `poll_newer/1`
callback, which fires every `poll_interval_ms` (default: 5000ms). The banner appears when
`newer_count > 0`.

**How to reach this state in a Playwright test:**
1. Call `POST /__e2e__/seed/<fixture>` to seed initial rows (e.g., `operator-flows`).
2. Navigate to the list page — the data_table renders with the initial rows.
3. WITHOUT calling `reset!`, call `POST /__e2e__/seed/<fixture>` a second time — this inserts
   additional rows (processor_ids use `System.unique_integer` so they never collide).
4. Wait 5 seconds for the `poll_interval_ms` to fire.
5. The `newer_count` banner ("N new rows — click to load") appears at the top of the data table.

**Why no code change is needed:** The existing `poll_newer/1` mechanism is triggered by new rows
having `inserted_at > @last_rendered_at`. A double-seed (without reset) produces this condition
naturally. Phase 179 owns the actual screenshot timing and poll-wait logic.

---

## Error State Mechanism — Canonical Documentation

**The `error-empty` / `filtered-empty` state** is produced when a list screen receives a URL
query parameter that matches no rows. This renders `data-role="empty-state"` with the empty
state title/copy and a "Clear filters" button.

**How to reach this state:**
```
GET /billing/invoices?status=nonexistent_status
GET /billing/customers?status=nonexistent_status
GET /billing/charges?status=nonexistent_status
```
(etc. — any impossible filter value works for any list screen)

**For detail screens**, the error state is the nil redirect path:
```
GET /billing/customers/00000000-0000-0000-0000-000000000000
```
A nonexistent UUID triggers `redirect/flash` on mount (since Phase 176 Wave 2b).

---

## Gap Closure Status

| Plan | Closes |
|------|--------|
| Plan 178-01 (this plan) | Produces this matrix (no fixture code yet) |
| Plan 178-02 | Implements `seed_edge_states!/0` and the overflow fixture in `e2e_fixtures.ex`; adds routes to `e2e_plug.ex`. Closes all `seed_edge_states` and overflow fixture cells. |
| Plan 178-03 | Fixes dunning bug in `hero_accounts.exs` (ties phantom sub IDs to real subscription rows). Closes `host:hero_accounts.exs` JPY-exhausted cell in RecoveryLive multi-currency column (dev env). |
| Plan 178-04 | Creates `examples/accrue_host/priv/repo/seeds/edge_states.exs` (host seed). Extends `scripts/ci/accrue_host_seed_e2e.exs` allowlists. Closes `host:edge_states.exs` cells. |
| Phase 179 | Iterates every non-N/A cell in this matrix with Playwright screenshots and axe assertions. |

---

## Overflow Threshold Note

The `DataTable` `@default_limit = 25` (line 12 of `data_table.ex`). The "Load more" button
appears when `next_cursor` is non-nil, which requires `limit + 1` rows from the query.
**Overflow = 26+ rows per entity type in the fixture.** The overflow fixture function seeds
exactly 26+ rows per targeted list screen entity.

List screens with overflow coverage (9): CustomersLive, SubscriptionsLive, InvoicesLive,
ChargesLive, CouponsLive, PromotionCodesLive, ConnectAccountsLive, EventsLive, WebhooksLive.
