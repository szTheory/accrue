# Phase 178: E — Seed Expressiveness & State Coverage — Research

**Researched:** 2026-06-04
**Domain:** Elixir/Phoenix fixture engineering + Ecto seed data + Playwright E2E state coverage
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**State taxonomy:** empty / populated / overflow(pagination) / error / loading, plus the edge set: dunning-at-risk / multi-currency / long-strings / dark-only-contrast-traps. Captured in a **screen×state STATE-MATRIX.md** in the phase dir; audit which cells are currently unreached and seed those.

**Fixture location:** extend `accrue_admin/test/support/e2e_fixtures.ex` (served via `/__e2e__/seed/<name>`) for the automated QA-loop reachability, AND the host `seeds.exs` for the dev-time click-through. Keep the existing "operator-flows" fixture working.

**Granularity:** a small set of **named scenario fixtures** (keep operator-flows; add e.g. edge-states / overflow / dunning-at-risk / multi-currency) where each makes a cluster of related states reachable — NOT one-per-state (too many) and NOT one mega-fixture (states would collide/mask each other).

**Single-click-through:** every state must be reachable from a seeded entity via normal navigation (no hand-picked IDs); the STATE-MATRIX documents the click-path per state cell.

**Dunning/at-risk:** seed past_due + canceling subscriptions + a dead-letter webhook so the Recovery/Developer attention badges (Phase 175) light up and the work-queue defaults (invoices open+uncollectible, subs past_due+canceling, payments failed) are non-empty.

**Multi-currency:** seed at least one zero-decimal currency (JPY) + a standard currency (USD/EUR) so the money-formatting path (the `format_money/3` path corrected in Phase 176) is genuinely exercised.

**Long strings / overflow:** seed an entity with very long names/emails/metadata + enough rows to trigger pagination/overflow on list screens (and the data_table card view at mobile width).

**Loading & error:** loading = the existing skeleton (data_table poll/loading — reachable via a paused/slow fixture or a documented test-only toggle); error = an error-empty fixture (e.g. a dead-lettered webhook / deliberately broken record). These two may require a test-only toggle since genuine async loading / runtime errors are hard to seed statically — document the mechanism in the matrix.

**Idempotency:** reuse the existing `cleanup_fixture_footprint!` processor_id-contract pattern; extend the `@fixture_*` id allowlists for any new fixtures so reseeding is idempotent (no duplicate rows).

**Dark-only contrast traps:** seed instances that specifically exercise tinted status backgrounds / `-readable` variants so Phase 179's dark-theme axe pass has concrete targets; record which screen+state in the matrix.

**QA-handoff artifact:** the **STATE-MATRIX.md** (screen × state → fixture + click-path per cell) committed in the phase dir is the contract Phase 179's screenshot sweep iterates over.

**Known dunning bug:** fix the known host-seed dunning bug (flagged in the v1.50 handoff) so the dunning/at-risk state seeds correctly.

### Claude's Discretion
- Exact fixture names and how states are clustered into them; the exact set of seeded entities per fixture.
- The precise mechanism for the loading/error states (paused fixture vs query param toggle) — provided each is reachable on a single click-through and documented in the matrix.
- Pagination threshold row counts; the exact long-string lengths.
- Whether the multi-currency/JPY data goes in a dedicated fixture or rides an existing one.

### Deferred Ideas (OUT OF SCOPE)
- Screenshot-driven visual QA sweep + LLM scoring + sign-off across every state → Phase 179 (F).
- Any new screens / UI redesign — out of scope (the screens are fixed; only their seeded data changes).
- Motion states beyond what the skeleton/badge transitions (Phase 177) already provide.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEED-01 | Every admin screen's empty, populated, overflow/pagination, error, and loading states are reachable from seeded data on a single click-through. | §Fixture Mechanism + §Screen Inventory × State Audit + §Pagination + §Loading & Error States |
| SEED-02 | Edge states (dunning/at-risk, multi-currency, long strings, dark-only contrast traps) each have a seeded instance; no screen looks good only with hand-picked IDs. | §Edge-State Seeding + §Dunning Bug Fix + §Multi-currency Schema |

</phase_requirements>

---

## Summary

Phase 178 is pure data/fixture engineering. The codebase already has a working two-layer seed system: `e2e_fixtures.ex` / `e2e_plug.ex` (the E2E test-time named fixture registry, served at `POST /__e2e__/seed/<name>`) and the host `seeds.exs` / `accrue_host_seed_e2e.exs` (the dev/CI host seed runner). The current fixture coverage is thin: `operator-flows` covers a charge+refund+two webhooks, `dashboard` covers a customer+subscription+invoice+dead webhook. Neither reaches overflow/pagination, multi-currency, at-risk dunning, or long-string edge cases. JPY already exists in `showcase.exs` (host dev seed) but is absent from the E2E named fixtures. The dunning/at-risk states require a `past_due` subscription with `dunning_campaign_started_at` set — the hero_accounts seed does this but the sidebar badge (`AttentionCounts.compute`) counts `status in [:past_due, :unpaid]` rows, and the "canceling" work queue requires `cancel_at_period_end = true`. Both are absent from `e2e_fixtures.ex`.

The **known dunning bug** is in `hero_accounts.exs`: the past-due subscription is seeded with `past_due_since: now` and `dunning_campaign_started_at: now` only when `dunning_campaign_started_at` is nil (line 33), but the guard `is_nil(past_due_subscription.dunning_campaign_started_at)` checks the subscription returned by `billing_state_for`, not the raw DB row — on a reseed, if the subscription status is already `past_due`, `billing_state_for` returns it and the guard is satisfied, but the anchor dates are `now` on every run, which means `at_risk_subscriptions` only returns the subscription within the time window (which is fine) but `recovery_live` window defaults are `since: 7/30/90 days ago` — the campaign events in `hero_accounts.exs` are orphaned UUIDs not tied to a real subscription ID, so the Recovery/at-risk table renders empty even though data exists. [VERIFIED: source code]

**Primary recommendation:** Add three new named E2E fixtures — `edge-states` (dunning+at-risk+multi-currency+long-strings), `overflow` (>50 rows across entity types for pagination), and extend the host `seeds.exs` `showcase.exs` / `hero_accounts.exs` to mirror those states. Fix the dunning bug (tie dunning campaign events to a real subscription ID). Produce STATE-MATRIX.md covering all 21 screens × 8 state dimensions.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| E2E fixture seeding (automated QA loop) | Test support layer (`e2e_fixtures.ex`) | E2E plug (`e2e_plug.ex`) | Fixtures are Elixir functions calling Ecto directly; the plug is only the HTTP dispatch layer |
| Dev-time seed data (host click-through) | Host seed files (`seeds/showcase.exs`, `hero_accounts.exs`) | CI seed runner (`accrue_host_seed_e2e.exs`) | Host seeds run via `mix ecto.reset`; CI runner extends with fixture cleanup contract |
| STATE-MATRIX.md artifact | Planning artifact (phase dir) | Consumed by Phase 179 Playwright sweep | Matrix is the contract; Phase 178 writes it, Phase 179 reads it |
| Idempotency enforcement | `cleanup_fixture_footprint!` in `accrue_host_seed_e2e.exs` | `on_conflict: :nothing` in `showcase.exs` / `background_data.exs` | Two-layer approach: hard delete by processor_id allowlists + insert-ignore by idempotency_key |
| Badge counts (sidebar attention) | `AttentionCounts.compute/1` → DB query | `NavBadgeHook` on_mount | Badges light up only if DB has `past_due/unpaid` subs or `failed/dead` webhooks |
| Work-queue defaults | `SubscriptionsLive` / `InvoicesLive` handle_params | `build_default_params` push_patch | Subscriptions default to `status=past_due,canceling`; Invoices default to `status=open,uncollectible` |
| Pagination threshold | `Behaviour.normalize_limit/1` (default 50) | `DataTable` `@default_limit = 25` | DataTable default limit is 25 rows per page; query layer default is 50; overflow = >25 visible rows |

---

## Standard Stack

No external package additions in this phase. This is a pure data/fixtures phase using existing dependencies.

### Tools In Use (all already in mix.exs)

| Tool | Version | Purpose |
|------|---------|---------|
| Ecto + TestRepo | `~> 3.13` | Direct DB inserts in `e2e_fixtures.ex` |
| Faker | transitive in host | `background_data.exs` random strings (already present) |
| Jason | `~> 1.4` | JSON payload for webhook raw_body fields |
| Oban.Job | `~> 2.21` | Discarded job seeding for dead-letter state |
| `accrue_host_seed_e2e.exs` | existing | CI fixture runner with idempotency contract |

### No New Packages

This phase installs zero new dependencies. All seeding uses existing Ecto changesets, the `Accrue.Billing.*` schemas already in use, and the established insert patterns.

---

## Package Legitimacy Audit

Not applicable — no new packages installed in this phase.

---

## Architecture Patterns

### Fixture Mechanism Internals

**How a fixture is defined:**

`e2e_fixtures.ex` defines one public function per fixture: `seed_dashboard!/0` and `seed_operator_flows!/0`. Each function inserts records directly via `TestRepo` (Ecto sandbox), returns a plain Elixir map of the IDs the spec needs (e.g., `%{charge_id: ..., single_webhook_id: ...}`).

**How `e2e_plug.ex` dispatches:**

The plug uses `Plug.Router` with explicit `post "/seed/<name>"` routes. Each route calls the corresponding `Fixtures.seed_<name>!/0` function and returns `Jason.encode!(result)` as JSON with status 200. There is no dynamic dispatch — every fixture name needs its own `post` route clause.

**How `admin-visuals.spec.js` consumes fixtures:**

```javascript
const data = await seed(request, "operator-flows");
// data = the JSON map returned by the fixture function
// e.g., data.single_webhook_id, data.charge_id
```

After `seed()`, the spec navigates to URLs using fixture IDs for detail pages.

**Recipe to add a new named fixture:**

1. Add a function `seed_<fixture_name>!/0` in `accrue_admin/test/support/e2e_fixtures.ex`.
2. Add a `post "/seed/<fixture-name>"` route in `e2e_plug.ex`.
3. The function returns a map; include every ID that a Playwright spec will need for detail-page navigation.
4. The function must be idempotent within a single test run — `reset!/0` truncates all fixture tables before each test, so within-run uniqueness is guaranteed by `System.unique_integer([:positive])` on processor_ids.

**Important:** `reset!/0` does a `TRUNCATE ... RESTART IDENTITY CASCADE` on all tables. This means within each Playwright test run, state is always clean. Idempotency only matters for the **host** seed runner (`accrue_host_seed_e2e.exs`) which runs against a persistent DB.

### Existing "operator-flows" Fixture — What It Seeds

| Entity | Details | State covered |
|--------|---------|---------------|
| 1 Customer | `name: "E2E Charge Customer"`, `email: "charge-e2e@example.com"` | Populated customer |
| 1 Subscription | `status: :active`, `processor_id: "sub_e2e_refund"` | Active sub |
| 1 Charge | `status: "succeeded"`, `amount_cents: 10_000`, with fee fields | Succeeded charge with fee data |
| 1 Refund | on the charge, `amount_minor: 1_000` | Refunded charge |
| 1 Ledger event | `type: "charge.succeeded"`, `actor_type: "system"` | Event log entry |
| 1 Webhook (dead) | `processor_event_id: "evt_e2e_single"`, `status: :dead` | Dead-letter webhook (DLQ) |
| 1 Webhook (failed) | `processor_event_id: "evt_e2e_bulk"`, `status: :failed` | Failed webhook |

Returns: `%{charge_id, source_event_id, single_webhook_id, bulk_webhook_id}`

**Currently NOT covered:** no invoice, no past_due subscription, no JPY/multi-currency, no overflow rows, no long strings, no canceling sub, no connect account.

### Recommended Project Structure (fixture additions)

```
accrue_admin/test/support/
├── e2e_fixtures.ex          # add seed_edge_states!/0, seed_overflow!/0
├── e2e_plug.ex              # add POST /seed/edge-states, /seed/overflow

examples/accrue_host/priv/repo/seeds/
├── hero_accounts.exs        # FIX dunning bug (tie events to real sub ID)
├── showcase.exs             # Already has JPY invoice + multi-status subs (GREEN)
├── background_data.exs      # Already creates 100 accounts (GREEN — pagination covered)
└── edge_states.exs          # NEW: long strings + canceling + explicit at-risk anchor

scripts/ci/accrue_host_seed_e2e.exs
  # Extend @fixture_* allowlists for new processor_ids in edge_states.exs
```

---

## Screen Inventory × State Audit

**21 admin screens** (from Phase 176 SCORECARD):

List screens (9): CustomersLive, SubscriptionsLive, InvoicesLive, ChargesLive, CouponsLive, PromotionCodesLive, ConnectAccountsLive, EventsLive, WebhooksLive

Detail screens (10): CustomerLive, SubscriptionLive, InvoiceLive, ChargeLive, CouponLive, PromotionCodeLive, ConnectAccountLive, EventLive, WebhookLive + CampaignLive

Specialist screens (2): RecoveryLive, DashboardLive

### State Coverage Per Screen — Current vs Needed

| Screen | Empty | Populated | Overflow | Error | Loading (poll-banner) | Dunning/at-risk | Multi-currency | Long strings | Dark-contrast |
|--------|-------|-----------|----------|-------|----------------------|----------------|---------------|-------------|--------------|
| DashboardLive | N/A (always renders) | ✅ dashboard | ✗ N/A | ✅ (redirect-on-nil) | N/A | ✗ NEEDED | ✗ NEEDED | ✗ NEEDED | ✗ NEEDED |
| CustomersLive | ✗ NEEDED | ✅ operator-flows | ✗ NEEDED | ✅ (filtered-empty) | ✗ NEEDED | ✗ NEEDED | ✗ N/A | ✗ NEEDED | ✗ NEEDED |
| CustomerLive | ✅ (redirect-nil) | ✅ operator-flows (customer detail) | N/A | ✅ redirect | N/A | ✗ NEEDED | ✗ NEEDED | ✗ NEEDED | ✗ NEEDED |
| SubscriptionsLive | ✅ (work-queue empty) | ✅ operator-flows | ✗ NEEDED | ✅ (filtered-empty) | ✗ NEEDED | ✗ NEEDED | N/A | ✗ NEEDED | ✗ NEEDED |
| SubscriptionLive | ✅ (redirect-nil) | ✅ operator-flows | N/A | ✅ redirect | N/A | ✗ NEEDED | ✗ N/A | ✗ NEEDED | ✗ NEEDED |
| InvoicesLive | ✅ (work-queue empty) | ✅ dashboard fixture | ✗ NEEDED | ✅ (filtered-empty) | ✗ NEEDED | N/A | ✗ NEEDED | ✗ NEEDED | ✗ NEEDED |
| InvoiceLive | ✅ (redirect-nil) | ✅ dashboard fixture | N/A | ✅ redirect | N/A | N/A | ✗ NEEDED (JPY) | ✗ NEEDED | ✗ NEEDED |
| ChargesLive | ✅ (empty) | ✅ operator-flows | ✗ NEEDED | ✅ (filtered-empty) | ✗ NEEDED | N/A | ✗ NEEDED | ✗ NEEDED | ✗ NEEDED |
| ChargeLive | ✅ (redirect-nil) | ✅ operator-flows | N/A | ✅ redirect | N/A | N/A | ✗ NEEDED | ✗ NEEDED | ✗ NEEDED |
| CouponsLive | ✅ (empty) | ✅ showcase.exs (host only) | ✗ NEEDED | ✅ (filtered-empty) | ✗ NEEDED | N/A | N/A | ✗ NEEDED | ✗ NEEDED |
| CouponLive | ✅ (redirect-nil) | ✅ showcase.exs (host only) | N/A | ✅ redirect | N/A | N/A | N/A | ✗ NEEDED | ✗ NEEDED |
| PromotionCodesLive | ✅ (empty) | ✅ showcase.exs (host only) | ✗ NEEDED | ✅ (filtered-empty) | ✗ NEEDED | N/A | N/A | ✗ NEEDED | ✗ NEEDED |
| PromotionCodeLive | ✅ (redirect-nil) | ✅ showcase.exs (host only) | N/A | ✅ redirect | N/A | N/A | N/A | ✗ NEEDED | ✗ NEEDED |
| ConnectAccountsLive | ✅ (empty) | ✅ host E2E seed | ✗ NEEDED | ✅ (filtered-empty) | ✗ NEEDED | N/A | N/A | ✗ NEEDED | ✗ NEEDED |
| ConnectAccountLive | ✅ (redirect-nil) | ✅ host E2E seed | N/A | ✅ redirect | N/A | N/A | N/A | ✗ NEEDED | ✗ NEEDED |
| EventsLive | ✅ (empty) | ✅ operator-flows | ✗ NEEDED | ✅ (filtered-empty) | ✗ NEEDED | N/A | N/A | ✗ NEEDED | ✗ NEEDED |
| EventLive | ✅ (redirect-nil) | ✅ operator-flows | N/A | ✅ redirect | N/A | N/A | N/A | ✗ NEEDED | ✗ NEEDED |
| WebhooksLive | ✅ (empty) | ✅ operator-flows | ✗ NEEDED | ✅ (filtered-empty) | ✗ NEEDED | N/A | N/A | ✗ NEEDED | ✗ NEEDED |
| WebhookLive | ✅ (redirect-nil) | ✅ operator-flows | N/A | ✅ redirect | N/A | N/A | N/A | ✗ NEEDED | ✗ NEEDED |
| RecoveryLive | N/A (always renders) | ✗ NEEDED (at-risk empty) | N/A | N/A | N/A | ✗ NEEDED | ✗ NEEDED (JPY exhausted) | N/A | ✗ NEEDED |
| CampaignLive | ✅ (no events) | ✗ NEEDED | N/A | N/A | N/A | ✗ NEEDED | ✗ NEEDED | N/A | ✗ NEEDED |

**Summary of gaps:**
- Overflow/pagination: 9 list screens — none currently have >25 E2E-fixture rows
- Poll/load-newer banner: 9 list screens — state requires rows inserted AFTER initial render; achievable via a second `seed` call in Playwright or a `newer_count` fixture inject
- At-risk/dunning: RecoveryLive, CampaignLive, SubscriptionLive (dunning section), DashboardLive badge
- Multi-currency (JPY): InvoiceLive, ChargeLive, RecoveryLive exhausted metric
- Long strings: CustomerLive, Customer-360 tabs, InvoiceLive, ChargesLive, EventsLive
- Dark-only contrast: all screens with tinted status chips/badges (focus for Phase 179 axe)

---

## Edge-State Seeding Specifics

### 1. Dunning / At-Risk States

**What lights up the Recovery badge (sidebar):**
`AttentionCounts.compute/1` counts subscriptions where `status in [:past_due, :unpaid]`. Recipe:
```elixir
# Insert a past_due subscription with dunning_campaign_started_at set
%Subscription{}
|> Subscription.force_status_changeset(%{
  customer_id: customer.id,
  processor: "fake",
  processor_id: "sub_e2e_dunning_at_risk",
  status: :past_due,
  past_due_since: DateTime.add(now, -5 * 86_400, :second),
  dunning_campaign_started_at: DateTime.add(now, -5 * 86_400, :second)
})
|> TestRepo.insert!()
```

**What lights up the Developer badge (sidebar):**
`WebhookEvent` with `status in [:failed, :dead]` — already seeded in `operator-flows`. The `seed_operator_flows!` fixture already seeds two such webhooks, so this badge already fires.

**What populates the at-risk table (RecoveryLive):**
`Dunning.at_risk_subscriptions/1` looks for subscriptions with `dunning_campaign_started_at NOT NULL` where no `dunning.recovered` / `dunning.exhausted` event exists since the anchor. The Events table must contain a `dunning.campaign_started` event with `subject_id = subscription.id` and `inserted_at >= dunning_campaign_started_at` — OR the subscription has `dunning_campaign_started_at` set with no terminal events. [VERIFIED: source code, `accrue/lib/accrue/analytics/dunning.ex` line 242-248]

**What populates the "canceling" work queue (SubscriptionsLive):**
`@default_queue_status "past_due,canceling"`. The "canceling" filter maps to `status == :active AND cancel_at_period_end == true AND current_period_end > now`. Recipe:
```elixir
%Subscription{}
|> Subscription.changeset(%{
  status: :active,
  cancel_at_period_end: true,
  current_period_end: DateTime.add(now, 7 * 86_400, :second)
})
```

### 2. Multi-Currency (JPY)

**Schema:** The `Invoice` schema has `currency: :string` (stored as lowercase string, e.g. `"jpy"`). The `Charge` schema similarly has `currency: :string`. `MoneyFormatter.normalize_currency/1` calls `String.to_existing_atom("jpy")` — the `:jpy` atom must already exist (it does, because `Accrue.Money` / `Accrue.Invoices.Render.format_money` is loaded at boot). [VERIFIED: source code, `accrue_admin/lib/accrue_admin/components/money_formatter.ex`]

**JPY is zero-decimal:** `format_money/3` must receive `amount_minor` that represents full yen (no division by 100). Example: `55_000` minor units = ¥55,000. The `showcase.exs` already seeds `"in_showcase_paid_jpy"` with `currency: "jpy", total_minor: 55_000` — this is the correct representation. [VERIFIED: source code]

**For the E2E fixture:** add one JPY invoice + one JPY charge to the `edge-states` fixture so the `InvoiceLive` and `ChargeLive` detail pages render JPY formatting.

### 3. Long Strings / Overflow

**Pagination threshold:** The `DataTable` `@default_limit` is 25 (line 12 of `data_table.ex`). The "Load more" button appears when `next_cursor` is non-nil, which happens when the query returns `limit + 1` rows. **Overflow = 26+ rows in a single fixture.** [VERIFIED: source code]

The `background_data.exs` already inserts 100 random customers/subscriptions, so in the host dev environment, overflow is already reached. For the E2E fixture (which starts from a clean `reset!`), the `overflow` fixture must seed at least 26 rows per targeted entity.

**Long string lengths:** No schema max-length constraints exist on `name` / `email` / `processor_id` beyond PG's text limit. For visual overflow testing:
- Customer name: 120 characters (exceeds card header)
- Customer email: 80 characters
- Coupon name: 80 characters
- Promotion code `code`: 40 characters
- Invoice `number`: 40 characters

### 4. Loading & Error States

**Loading (poll-banner):** The `DataTable` shows a "N new rows - click to load" banner when `newer_count > 0`, which is set by `poll_newer/1` called every `poll_interval_ms` (default 5000ms). To reach this state in a screenshot:

Option A (recommended — documented test-only toggle): Seed the fixture, capture the screenshot, then POST `/__e2e__/seed/operator-flows` a second time (which inserts more rows since `reset!` was not called between them). Wait for the poll interval to fire (5s default). The banner will appear. Document in STATE-MATRIX: "requires 5s wait after second seed post."

Option B: Pass `poll_interval_ms={1000}` via a query param — but `DataTable` does not currently accept poll_interval_ms as a URL param. Not easily achievable without code change.

**Recommendation:** document the poll-banner as "reachable by double-seeding + 5s wait" in STATE-MATRIX; Phase 179 handles the actual screenshot timing. No code change needed.

**Error state (error-empty):** The DataTable already renders the empty state when rows are empty after a filter. The "filtered-empty" path (filter with no matches) is the practical error-empty state. Recipe in Playwright:
```
GET /billing/invoices?status=nonexistent_status
```
This renders `data-role="empty-state"` with the "Clear filters" button. This is already reachable without a new fixture. Document as "navigate to list with impossible filter value" in STATE-MATRIX. [VERIFIED: source code, `data_table.ex` line 155-167]

---

## The Known Dunning Bug

**Location:** `examples/accrue_host/priv/repo/seeds/hero_accounts.exs`, lines 100–188.

**The bug:** The dunning analytics events (`dunning.campaign_started`, `dunning.step_sent`, `dunning.recovered`, `dunning.exhausted`) are inserted with randomly-generated `sub_7d = Ecto.UUID.generate()`, `sub_30d = Ecto.UUID.generate()`, and `sub_90d = Ecto.UUID.generate()` as their `subject_id`. These are phantom UUIDs — they are never inserted as actual `accrue_subscriptions` rows.

**Why it matters for seeding:**
- `RecoveryLive` calls `Dunning.at_risk_subscriptions/1`, which JOINs `accrue_events` to `accrue_subscriptions` on `subject_id`. Since the phantom sub UUIDs have no subscription row, the at-risk table is always empty.
- `CampaignLive` navigates to `/billing/analytics/recovery/campaigns/:subscription_id` — without real subscription IDs, these links cannot be constructed.
- The Recovery badge sidebar count comes from `AttentionCounts.compute` which counts `past_due`/`unpaid` subscriptions — the `past_due_user`/`past_due_org` subscription IS a real row, but its `dunning_campaign_started_at` is set correctly. The badge DOES fire for the past-due org correctly. The bug only affects the Recovery analytics charts and at-risk table.

**The fix:** Replace the phantom `sub_7d/sub_30d/sub_90d` UUIDs with the IDs of existing hero subscriptions:
```elixir
# After inserting hero subscriptions, read back their IDs:
{:ok, %{subscription: past_due_subscription}} = AccrueHost.Billing.billing_state_for(past_due_org)
{:ok, %{subscription: canceled_subscription}} = AccrueHost.Billing.billing_state_for(canceled_org)

# Use real IDs for the dunning events
sub_7d = past_due_subscription.id    # was: Ecto.UUID.generate()
sub_30d = canceled_subscription.id   # was: Ecto.UUID.generate()
# ...
```

This makes `at_risk_subscriptions/1` return the `past_due_subscription` row (which has `dunning_campaign_started_at` set and no terminal event), populating the Recovery/at-risk table.

**Idempotency note:** The `record_at/3` helper already uses `on_conflict: :nothing` keyed on `idempotency_key`. On reseed, these events are skipped cleanly. The fix does not break idempotency. [VERIFIED: source code]

---

## Idempotency Contract

### How `cleanup_fixture_footprint!` Works

The CI seed runner (`accrue_host_seed_e2e.exs`) cleans up by allowlist before inserting:

1. **@seeded_emails** — users whose customer rows are cleaned (all downstream rows cascade).
2. **@fixture_customer_processor_ids** — explicit customer rows by processor_id.
3. **@fixture_subscription_processor_ids** — explicit subscription rows by processor_id.
4. **@fixture_subscription_item_processor_ids** — explicit subscription items.
5. **@fixture_processor_event_ids** — webhook events by processor_event_id.
6. **@fixture_org_customer_emails** — org-scoped customers by email.
7. **@fixture_discount_codes** — discount mappings.
8. **@fixture_checkout_operation_ids** — local sessions by operation_id.

Delete order matters: child rows first (events disabled via trigger → events deleted → trigger re-enabled), then oban jobs, then webhooks, then subscription items, then subscriptions, then customers, then users.

### How to Extend for New Fixtures (Host Side)

To add new processor_ids to new fixtures in `accrue_host_seed_e2e.exs`:
1. Add deterministic processor_id strings to the relevant `@fixture_*` module attribute lists.
2. Add any new entity types (e.g., coupons) with their own cleanup clause.
3. The `seed_e2e_cleanup_test.exs` asserts that unrelated rows are preserved — this test PASSES as long as unrelated processor_ids are NOT in the allowlists. Adding new allowlist entries does not break the test.

### E2E Fixtures Idempotency (Admin Side)

`e2e_fixtures.ex` relies on `reset!/0` being called before each test run (via `test.beforeEach` in `admin-visuals.spec.js`). `reset!` does `TRUNCATE ... RESTART IDENTITY CASCADE`, so there is no within-run collision. New fixtures do NOT need their own cleanup — the truncate handles it. New processor_ids in `e2e_fixtures.ex` functions can use `System.unique_integer([:positive])` for within-run uniqueness.

---

## Recommended New Fixtures

### Fixture 1: `seed_edge_states!/0`

Makes reachable:
- At-risk/dunning subscription (past_due + dunning_campaign_started_at set)
- Canceling subscription (active + cancel_at_period_end)
- JPY invoice (currency: "jpy")
- JPY charge
- Long-name customer (120-char name)
- Long-email customer
- Connect account (for ConnectAccountLive detail)
- Coupon + PromotionCode (for their detail screens)

Returns: `%{at_risk_sub_id, canceling_sub_id, jpy_invoice_id, jpy_charge_id, long_name_customer_id, coupon_id, promo_code_id, connect_account_id}`

### Fixture 2: `seed_overflow!/0`

Makes reachable:
- 26 customers (triggers "Load more" on CustomersLive)
- 26 invoices across customers (triggers "Load more" on InvoicesLive)
- 26 charges (triggers "Load more" on ChargesLive)
- 26 subscriptions (triggers "Load more" on SubscriptionsLive)
- 26 webhooks (triggers "Load more" on WebhooksLive)
- 26 events (triggers "Load more" on EventsLive)

Returns: `%{first_customer_id, first_invoice_id, first_charge_id}` (for detail navigation)

**Implementation note:** Use `Enum.map(1..26, fn i -> ... end)` and `TestRepo.insert_all` for bulk inserts. Each row needs a unique `processor_id` via `"e2e_overflow_#{i}"`.

### E2E Plug Routes to Add

```elixir
post "/seed/edge-states" do
  json(conn, 200, Fixtures.seed_edge_states!())
end

post "/seed/overflow" do
  json(conn, 200, Fixtures.seed_overflow!())
end
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-entity bulk inserts | Loop with `TestRepo.insert!` | `TestRepo.insert_all` with maps | 10x faster; avoids N+1 insert round trips for overflow fixture |
| JPY amount formatting | Custom divide-by-factor logic | `Accrue.Invoices.Render.format_money(55_000, :jpy, "en")` | Already handles zero-decimal currencies; `amount_minor` for JPY IS the full yen amount |
| Idempotent event inserts | Delete + reinsert | `on_conflict: :nothing` with `idempotency_key` conflict target | Already established pattern in `hero_accounts.exs` and `showcase.exs` |
| Webhook raw_body JSON | String interpolation | `Jason.encode!(%{...})` | Type-safe; already the established pattern in `accrue_host_seed_e2e.exs` |
| force_status_changeset | Direct Ecto.Changeset.change on status field | `Subscription.force_status_changeset/2` | Bypasses transition guards safely; established in `showcase.exs` and `hero_accounts.exs` |

---

## Common Pitfalls

### Pitfall 1: Phantom Subscription IDs in Dunning Events
**What goes wrong:** Seeding dunning events with `subject_id = Ecto.UUID.generate()` creates events that JOIN to no real subscription. `at_risk_subscriptions/1` and `CampaignLive` find nothing.
**Why it happens:** The current `hero_accounts.exs` does this (the known bug).
**How to avoid:** Always seed dunning events with `subject_id` pointing to a real `accrue_subscriptions.id`.
**Warning signs:** RecoveryLive at-risk table shows 0 rows even though past_due subscription exists.

### Pitfall 2: `String.to_existing_atom` for JPY Currency
**What goes wrong:** `MoneyFormatter.normalize_currency("jpy")` calls `String.to_existing_atom("jpy")`. If `:jpy` atom has never been created before this call, it raises `ArgumentError`.
**Why it happens:** Elixir atom table only has atoms that have been created at compile time or via prior runtime call.
**How to avoid:** In the E2E fixture, set `currency: "jpy"` (string) and trust that the LiveView module loading at app start ensures `:jpy` is already in the atom table. In practice this is safe because `Accrue.Money` and `LatticeStripe` define JPY as a known currency atom. Do NOT pre-create atoms in fixtures — it's not needed and indicates a misunderstanding.
**Warning signs:** MoneyFormatter renders "--" for JPY amounts.

### Pitfall 3: Overflow Fixture Processor_id Collisions
**What goes wrong:** If two overflow rows share a `processor_id`, the unique index on `(processor, processor_id)` will raise on insert.
**Why it happens:** Using static strings like `"sub_e2e_overflow"` across 26 rows.
**How to avoid:** Suffix with index: `"sub_e2e_overflow_#{i}"` for `i` in `1..26`.
**Warning signs:** `Ecto.ConstraintError` on `accrue_subscriptions_processor_id_index` during fixture seed.

### Pitfall 4: Canceling Subscription Misses Work Queue
**What goes wrong:** A subscription seeded with `status: :canceling` appears in the DB but not in the work queue because the filter is `status == :active AND cancel_at_period_end == true AND current_period_end > now`.
**Why it happens:** `:canceling` is not a DB status value — it is a derived query concept in `Billing.Query.canceling/1`.
**How to avoid:** Seed with `status: :active, cancel_at_period_end: true, current_period_end: DateTime.add(now, 7 * 86_400, :second)`.
**Warning signs:** Subscriptions work queue shows only past_due, no canceling entries.

### Pitfall 5: `seed_e2e_cleanup_test.exs` Failures After Extending `accrue_host_seed_e2e.exs`
**What goes wrong:** Adding new processor_ids to `@fixture_*` allowlists in the CI runner, but the `insert_unrelated_rows!/0` helper in the cleanup test happens to use the same processor_id string.
**Why it happens:** The cleanup test inserts rows with `processor_id: "cus_unrelated_replay"`, `"sub_unrelated_replay"` etc. If a new fixture allowlist entry accidentally matches these, the unrelated rows get deleted and the test fails on the `assert Repo.get!/2` assertions.
**How to avoid:** Use the `e2e_` prefix namespace for all new fixture processor_ids (e.g., `"cus_e2e_edge_1"`, `"sub_e2e_dunning_at_risk"`). The cleanup test uses `"unrelated_"` prefix.
**Warning signs:** `seed_e2e_cleanup_test.exs` fails on `assert Repo.get!(WebhookEvent, unrelated.webhook.id)`.

### Pitfall 6: at_risk_subscriptions Returns Subscription Even After Dunning Terminal Event
**What goes wrong:** After seeding a `past_due` subscription with `dunning_campaign_started_at` set, the at-risk query STILL excludes it because `showcase.exs` seeds a `dunning.recovered` or `dunning.exhausted` event with a phantom subscription ID that happens to match.
**Why it happens:** Phantom UUID collision (astronomically unlikely but worth noting).
**How to avoid:** After fixing the dunning bug, verify by direct `Dunning.at_risk_subscriptions/1` call in tests.

---

## Code Examples

### Adding a New E2E Fixture Function

```elixir
# Source: accrue_admin/test/support/e2e_fixtures.ex (existing pattern)
def seed_edge_states! do
  now = DateTime.utc_now()
  
  # At-risk / dunning customer
  dunning_customer = insert_customer(%{
    name: "E2E Dunning At-Risk Co",
    email: "dunning-e2e@example.com"
  })
  
  # past_due + dunning_campaign_started_at set → lights up Recovery badge
  at_risk_sub = insert_subscription(dunning_customer, %{
    processor_id: "sub_e2e_dunning_at_risk",
    status: :past_due,
    past_due_since: DateTime.add(now, -5 * 86_400, :second),
    dunning_campaign_started_at: DateTime.add(now, -5 * 86_400, :second)
  })
  
  # canceling → appears in Subscriptions work-queue default filter
  canceling_sub = insert_subscription(dunning_customer, %{
    processor_id: "sub_e2e_canceling",
    status: :active,
    cancel_at_period_end: true,
    current_period_end: DateTime.add(now, 7 * 86_400, :second)
  })
  
  # JPY invoice → exercises format_money zero-decimal path
  jpy_invoice = insert_invoice(dunning_customer, at_risk_sub, %{
    processor_id: "in_e2e_jpy",
    currency: "jpy",
    total_minor: 55_000,
    amount_due_minor: 55_000,
    amount_remaining_minor: 55_000,
    status: :open
  })
  
  # Long-name customer → exercises overflow in card views
  long_name_customer = insert_customer(%{
    name: String.duplicate("A", 100) <> " LongName Corp",
    email: "long-name-e2e@example.com"
  })
  
  %{
    at_risk_sub_id: at_risk_sub.id,
    canceling_sub_id: canceling_sub.id,
    jpy_invoice_id: jpy_invoice.id,
    dunning_customer_id: dunning_customer.id,
    long_name_customer_id: long_name_customer.id
  }
end
```

### Adding the Overflow Fixture

```elixir
# Source: accrue_admin/test/support/e2e_fixtures.ex (established pattern)
def seed_overflow! do
  customers =
    Enum.map(1..26, fn i ->
      insert_customer(%{
        name: "E2E Overflow Customer #{i}",
        email: "overflow-e2e-#{i}@example.com",
        processor_id: "cus_e2e_overflow_#{i}"
      })
    end)
  
  first_customer = List.first(customers)
  
  # 26 subscriptions → overflow on SubscriptionsLive
  Enum.each(customers, fn customer ->
    insert_subscription(customer, %{
      processor_id: "sub_e2e_overflow_#{customer.processor_id}",
      status: :active
    })
  end)
  
  %{first_customer_id: first_customer.id}
end
```

### Fixing the Dunning Bug in hero_accounts.exs

```elixir
# BEFORE (buggy):
sub_7d = Ecto.UUID.generate()  # phantom UUID — no subscription row

# AFTER (fixed):
# Use the real ID of the past_due_subscription created above
sub_7d = past_due_subscription.id

# All record_at calls below then reference a real subscription
```

### Extending cleanup_fixture_footprint! for New IDs

```elixir
# Add to @fixture_* module attributes in accrue_host_seed_e2e.exs:
@fixture_subscription_processor_ids [
  "sub_host_browser_replay",
  "sub_host_premium_replay",
  "sub_e2e_dunning_at_risk",    # NEW
  "sub_e2e_canceling"            # NEW
]

@fixture_customer_processor_ids [
  "cus_host_browser_replay",
  "cus_host_premium_replay",
  "cus_e2e_edge_1"               # NEW (if edge_states added to host seed)
]
```

---

## Runtime State Inventory

Not applicable — this is a greenfield fixture-data phase. No existing stored state is being renamed or migrated. The only mutation is adding rows to existing tables.

---

## Validation Architecture

nyquist_validation is enabled (absent from config → enabled).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `accrue_admin/test/test_helper.exs` |
| Quick run command | `cd accrue_admin && mix test --seed 0 test/accrue_admin/` |
| Full suite command | `cd accrue_admin && mix test --seed 0` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEED-01 | Each new fixture POST returns 200 | integration | `cd accrue_admin && mix test --seed 0 test/accrue_admin/e2e_fixtures_test.exs` | ❌ Wave 0 |
| SEED-01 | `seed_edge_states!` produces at_risk_sub with status :past_due | unit | same file | ❌ Wave 0 |
| SEED-01 | `seed_overflow!` inserts ≥26 customers/subs | unit | same file | ❌ Wave 0 |
| SEED-01 | Filtered-empty path (error state) navigates correctly | smoke | existing `customers_live_test.exs` | ✅ |
| SEED-02 | JPY invoice renders correct amount string | unit | `test/accrue_admin/components/money_formatter_test.exs` | ✅ (existing) |
| SEED-02 | at_risk_sub appears in `Dunning.at_risk_subscriptions/1` | unit | `test/accrue_admin/e2e_fixtures_test.exs` | ❌ Wave 0 |
| SEED-02 | host seed: reseed idempotency (no dupes) | integration | `examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs` | ✅ (existing, must stay green) |

### Sampling Rate

- Per task commit: `cd accrue_admin && mix test --seed 0`
- Per wave merge: `cd accrue_admin && mix test --seed 0` (254 tests must stay green)
- Phase gate: Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs` — covers SEED-01, SEED-02 fixture assertions
  - `test "seed_edge_states!/0 inserts at-risk subscription"` — verifies `status: :past_due` + `dunning_campaign_started_at` is set
  - `test "seed_edge_states!/0 inserts canceling subscription"` — verifies `cancel_at_period_end: true`
  - `test "seed_edge_states!/0 inserts JPY invoice"` — verifies `currency: "jpy"`
  - `test "seed_overflow!/0 inserts 26+ customers"` — verifies count ≥ 26
  - `test "POST /__e2e__/seed/edge-states returns 200"` — verifies plug route

---

## Security Domain

`security_enforcement` not explicitly set to false in config. Phase 178 ships no HTTP endpoints, auth changes, or secret handling. The `/__e2e__/seed/*` routes are already gated by the E2E plug which only runs when `Mix.env() == :test` (inferred from its location in `test/support/` and the TestRouter wiring). No new attack surface.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | No | Fixtures use hardcoded strings, no user input |
| V4 Access Control | Minimal | E2E plug only available in test env; existing pattern unchanged |
| V2 Authentication | No | No auth changes |
| V6 Cryptography | No | No crypto |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | All Ecto inserts | ✓ | PG 14+ (project floor) | — |
| Elixir + Mix | test run | ✓ | 1.17+ | — |
| Node.js + Playwright | admin-visuals.spec.js | ✓ | Confirmed (Phase 176 used it) | — |

No missing dependencies.

---

## Open Questions

1. **Poll-banner screenshot timing**
   - What we know: The poll-banner appears when `newer_count > 0`, which is set after a 5s poll interval fires.
   - What's unclear: Whether Phase 179's Playwright sweep will handle the 5s wait, or whether Phase 178 should add a `post "/seed/trigger-poll-banner"` endpoint that directly sets `newer_count` via a LiveView inject.
   - Recommendation: Document in STATE-MATRIX as "requires double-seed + 5s wait" for now; Phase 179 can decide whether to add a toggle.

2. **Dark-only contrast traps — which specific CSS classes need seeded instances**
   - What we know: `ax-badge-warning` / `ax-badge-danger` (sidebar badges), status chips on subscription/invoice/webhook detail.
   - What's unclear: Whether any tinted surfaces have failing contrast in dark mode that require specific data to exercise (vs. being visible on any populated screen).
   - Recommendation: Phase 179's axe pass will surface the specific failures; Phase 178 only needs to ensure every tinted state is seeded (e.g., a `:past_due` subscription ensures the danger-tone badge renders).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `:jpy` atom is always in the atom table at fixture seed time because `Accrue.Money` / `LatticeStripe` creates it at module load | Edge-State Seeding §Multi-Currency | MoneyFormatter renders "--" for JPY amounts; low risk since both modules are loaded at compile |
| A2 | `DataTable` `@default_limit = 25` means 26 rows triggers the "Load more" button | Overflow §Pagination Threshold | If the DataTable passes `limit: 50` (query default), need 51 rows; low risk since DataTable explicitly sets `@default_limit 25` |

---

## Sources

### Primary (HIGH confidence)
- `accrue_admin/test/support/e2e_fixtures.ex` — fixture function signatures, insert patterns, what operator-flows currently seeds
- `accrue_admin/test/support/e2e_plug.ex` — dispatch mechanism (explicit post routes per fixture)
- `accrue_admin/lib/accrue_admin/components/data_table.ex` — `@default_limit 25`, poll mechanism, `newer_count`, `next_cursor` pagination logic
- `accrue_admin/lib/accrue_admin/queries/behaviour.ex` — `@default_limit 50` in query layer, `paginate/3` contract
- `scripts/ci/accrue_host_seed_e2e.exs` — `cleanup_fixture_footprint!` allowlist pattern, full idempotency contract
- `examples/accrue_host/priv/repo/seeds/hero_accounts.exs` — dunning bug location (phantom UUID lines 101, 140, 165)
- `examples/accrue_host/priv/repo/seeds/showcase.exs` — JPY invoice seeding pattern, upsert helpers
- `examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs` — what the cleanup test asserts and what NOT to collide with
- `accrue_admin/lib/accrue_admin/attention_counts.ex` — badge count logic (`status in [:past_due, :unpaid]` for recovery, `status in [:failed, :dead]` for developer)
- `accrue/lib/accrue/analytics/dunning.ex` line 225-280 — `at_risk_subscriptions/1` JOIN and WHERE logic
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` — `@default_queue_status "past_due,canceling"`, work-queue filter
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex` — `@default_queue_status "open,uncollectible"`
- `.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md` — authoritative 21-screen inventory

### Secondary (MEDIUM confidence)
- `.planning/research/v1.51-admin-ui-depth-design.md` §4 Phase E — scope definition
- `.planning/phases/178-e-seed-expressiveness-state-coverage/178-CONTEXT.md` — locked decisions

---

## Metadata

**Confidence breakdown:**
- Fixture mechanism: HIGH — read source directly
- Screen inventory: HIGH — from Phase 176 SCORECARD
- Dunning bug: HIGH — traced through source code
- Idempotency contract: HIGH — full source of `cleanup_fixture_footprint!` read
- Pagination threshold: HIGH — `@default_limit = 25` in `data_table.ex` line 12
- JPY schema: HIGH — `invoice.currency` is a string field, `MoneyFormatter` handles it
- Loading state mechanism: HIGH — poll mechanism fully traced in `data_table.ex`

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (stable codebase; no fast-moving external deps)
