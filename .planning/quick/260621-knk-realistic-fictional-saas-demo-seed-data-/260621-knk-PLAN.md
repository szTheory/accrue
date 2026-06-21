---
phase: 260621-knk
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs
  - examples/accrue_host/test/seeds_idempotency_test.exs
  - examples/accrue_host/test/accrue_host/phase191_seed_reachability_test.exs
autonomous: true
requirements: [SEED-C]
must_haves:
  truths:
    - "/admin/customers shows realistic company/person names + emails for the page customers, not 'Phase 191 Page Customer NN'"
    - "Most page customers show 'On file' under the Payment method column (a non-null default_payment_method_id)"
    - "The 'With payment method' KPI on /admin/customers reads a meaningful non-zero count"
    - "At least a representative subset of realistic customers have a coherent linked subscription + invoice + charge so their detail pages and billing signals populate"
    - "Re-running mix run priv/repo/seeds.exs twice does not crash and does not change row counts (idempotent)"
    - "Every preserved processor_id, idempotency key, unicode string (株式会社/Café/Crème/ÉTÉ191), and the 26 page-customer boundary count remain intact"
  artifacts:
    - path: "examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs"
      provides: "Realistic Faker-backed page customers + payment methods + coherent linked billing graph, fully idempotent"
      contains: "Faker.Company.name"
    - path: "examples/accrue_host/test/seeds_idempotency_test.exs"
      provides: "Updated phase191 fixture count assertions reflecting new idempotent linked rows"
      contains: "phase191_fixture_counts"
    - path: "examples/accrue_host/test/accrue_host/phase191_seed_reachability_test.exs"
      provides: "Preserved unicode/boundary assertions, plus realistic-data + payment-method coverage assertions"
      contains: "paginated_count"
  key_links:
    - from: "examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs"
      to: "accrue/lib/accrue/billing/payment_method.ex"
      via: "PaymentMethod.changeset/2 inserts pm_phase191_host_page_NN rows linked by customer_id; customer.default_payment_method_id points back"
      pattern: "default_payment_method_id"
    - from: "examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs"
      to: "examples/accrue_host/test/seeds_idempotency_test.exs"
      via: "like(processor_id, 'sub_phase191_host%') prefix-counts new linked rows — counts MUST be updated in lockstep"
      pattern: "phase191_fixture_counts"
---

<objective>
Make the `accrue_host` demo seed data look like a believable fictional SaaS's book of business: realistic company/person names + emails for the 26 page customers, a payment method on file for most of them, and a coherent linked subscriptions/invoices/charges graph for a representative subset — so `/admin/customers`, customer detail pages, KPIs, and billing signals populate with lifelike data. Do this WITHOUT breaking the seed-idempotency or reachability tests that assert on the demo's stable identifiers, counts, and unicode strings.

Purpose: Part C of the approved three-part plan (`~/.claude/plans/i-just-got-an-ethereal-harbor.md`). Parts A (events cursor crash) and B (DataTable + customers redesign) already shipped; this makes B's redesign demo-able against real data.

Output: A rewritten `examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs` (data only) plus updated count/structure assertions in the two host seed tests.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

# Source of truth — Part C is the spec
@/Users/jon/.claude/plans/i-just-got-an-ethereal-harbor.md

# The file being rewritten (study the upsert/upsert_processor helpers ~38-60 and the page-customer loop ~316-334)
@examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs

# The Faker pattern to follow (Faker.Company.name/0, Faker.Internet.email/0, on_conflict: :nothing)
@examples/accrue_host/priv/repo/seeds/background_data.exs

# Exact attrs shapes for the linked graph — copy these field sets verbatim where building sub/invoice/charge/payment-method rows
@examples/accrue_host/priv/repo/seeds/hero_accounts.exs
@examples/accrue_host/priv/repo/seeds/showcase.exs

# The two tests that gate this work (do not break the preserved assertions; update counts in lockstep)
@examples/accrue_host/test/seeds_idempotency_test.exs
@examples/accrue_host/test/accrue_host/phase191_seed_reachability_test.exs

# Core schema field shapes
@accrue/lib/accrue/billing/customer.ex
@accrue/lib/accrue/billing/payment_method.ex
</context>

<key_facts>
Load-bearing facts the executor MUST internalize before editing (derived from reading the schemas, queries, and tests):

1. ACTIVE-ORG SCOPING / VISIBILITY: `/admin/customers` for a platform admin (`admin@example.com`) defaults to `:global` mode (no `?org=` param) and shows ALL customers regardless of `owner_type`/`owner_id` (see `AccrueAdmin.Queries.Customers.scope_query/2` + `AccrueAdmin.OwnerScope.resolve/2`). So the 26 page customers already appear in the default `/admin/customers`. You do NOT need to re-home them under a specific org id to make them visible. Keep each page customer's existing distinct `owner_id` (the pagination/boundary fixture relies on row count, not owner). Vary `owner_type` across the realistic set (e.g. mostly "Organization", a few "User", "Team") so the owner-type dropdown filter (`distinct_owner_types/1`) shows real variety — `owner_type` is a host-defined free string.

2. KPI WIRING: the customers KPIs are "Customers" (count) and "With payment method" (count of customers with non-null `default_payment_method_id`). The list "Payment method" column renders "On file" when `default_payment_method_id` is set, else "Missing" (`customers_live.ex` `default_payment_method_label/1`). To make these meaningful, give MOST page customers a `default_payment_method_id` pointing at a linked PaymentMethod row.

3. DETAIL-PAGE / SIGNALS WIRING: the customer detail page tabs (subscriptions / invoices / charges / payment_methods) key off `customer_id`. A row appears on the detail page simply by having `customer_id` = that customer. Build a coherent linked graph (subscription + invoice + charge + payment method) for a representative SUBSET of the page customers (not all 26 — keep insert volume bounded) so several detail pages are richly populated.

4. PAYMENT METHOD SCHEMA: `PaymentMethod.changeset/2` requires `customer_id` + `processor`. Use the same field shape hero_accounts.exs uses for `pm_seed_healthy_portal_default` (type: "card", is_default: true, fingerprint, card_brand, card_last4, card_exp_month/year, exp_month/exp_year). Insert the PM first, then set `customer.default_payment_method_id` to it via `Customer.changeset/2` (mirror hero_accounts.exs lines ~110-116). `fingerprint` participates in a `(customer_id, fingerprint)` unique index — make it unique per customer (e.g. derive from the page index).

5. IDEMPOTENCY MODEL (CRITICAL): the existing `upsert`/`upsert_processor` helpers in this file are get-or-insert keyed on `(processor: "fake", processor_id: <id>)`. Re-running is a no-op for existing processor_ids, so a name/email set on first insert STAYS STABLE across re-seeds even though Faker is non-deterministic — because the idempotency test asserts COUNTS, not names. Reuse these helpers for EVERY new row (payment methods, linked subs/invoices/charges). Give every new row a deterministic `processor_id` derived from the page index so re-runs collapse to no-ops.

6. TEST COUNT COUPLING (CRITICAL): `seeds_idempotency_test.exs` `phase191_fixture_counts/0` prefix-counts via `like(processor_id, "<prefix>_phase191_host%")`:
   - customers: `cus_phase191_host%` == 28 (1 primary + 1 one-row + 26 page). DO NOT add or remove customers → keep 28.
   - subscriptions: `sub_phase191_host%` == 2 today. Any new `sub_phase191_host_page_NN` you add is prefix-counted → you MUST update this assertion to the new total in the SAME commit.
   - invoices: `in_phase191_host%` == 1; charges: `ch_phase191_host%` == 1 — same rule: new `in_phase191_host_page_NN` / `ch_phase191_host_page_NN` rows are counted; update in lockstep.
   - PaymentMethods are NOT counted by any test (no `pm_phase191_host%` assertion) → `pm_phase191_host_page_NN` rows are free; you may still add a payment-method count assertion if you want coverage (optional, see Task 3).
   - coupons/promotion_codes/connect_accounts/webhooks/events counts are unchanged → do not touch those rows.
   Decide the exact subset size (how many page customers get a linked sub/invoice/charge), compute the resulting `sub_phase191_host%`/`in_phase191_host%`/`ch_phase191_host%` totals, and write those exact numbers into the test. The arithmetic must be exact — a fixture-count mismatch fails the idempotency test on the first eval.

7. PRESERVE EXACTLY (renaming breaks the suite):
   - The PRIMARY customer (`cus_phase191_host_customer`): name MUST still contain `株式会社` AND `Café`; email stays `phase191-host-customer@example.com`; and `phase191_seed_reachability_test.exs:66` asserts `is_nil(customer.default_payment_method_id)` → the primary customer MUST NOT receive a payment method. Leave the primary customer, its subscription (`sub_phase191_host_active`), invoice (`in_phase191_host_boundary`), charge (`ch_phase191_host_boundary`), at-risk sub (`sub_phase191_host_at_risk`), coupon (`coupon_phase191_host_unicode` name contains "Crème"), promo (`promo_phase191_host_unicode` code "ÉTÉ191"), connect account (`acct_phase191_host_boundary`), webhook (`evt_phase191_host_dead`), source event (`seed-phase191-fixture-seeded`), and the one-row customer (`cus_phase191_host_one`) STRUCTURALLY UNCHANGED except you MAY humanize the one-row and page customer NAMES/EMAILS.
   - The 26 page customers: keep processor_ids `cus_phase191_host_page_01`..`cus_phase191_host_page_26` and keep their stable `id`/`owner_id` UUID derivation (the `suffix` scheme). The boundary test asserts `paginated_count() == 26` via `like(... "cus_phase191_host_page_%")` — do NOT change the count or the processor_id prefix. Only the `name`/`email`/`metadata`/`data`/`owner_type` and the NEW linked rows are free to change.
</key_facts>

<tasks>

<task type="auto">
  <name>Task 1: Realistic page-customer identities + payment methods on file</name>
  <files>examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs</files>
  <action>
Rewrite the `Enum.each(1..26, ...)` page-customer loop (and optionally the one-row customer) so each page customer reads like a real account, while preserving every stable identifier.

For each `index` 1..26:
- Keep the existing deterministic `id` (the `"19100000-0000-4000-8000-#{suffix}"` scheme), the existing `owner_id` (`"19100000-0000-4001-8000-#{suffix}"`), and the processor_id `"cus_phase191_host_page_#{padded}"` EXACTLY — these are asserted/counted.
- Replace `name: "Phase 191 Page Customer #{padded}"` with a realistic name. Use `Faker.Company.name()` for Organization-owned customers and `Faker.Person.name()` (or `Faker.Person.first_name() <> " " <> Faker.Person.last_name()`) for User-owned ones. Replace the email with `Faker.Internet.email()`.
- Vary `owner_type` deterministically across the 26 so the owner-type filter has real options: mostly "Organization", a handful "User", a couple "Team". Drive the split off `index` (e.g. `rem(index, ...)`) so it is stable per re-run — but remember names/emails are Faker (fine, idempotency keys on processor_id).
- Keep the `metadata`/`data` boundary markers (`"phase191_boundary" => "more-than-one-page"`, `"phase191_index" => index`) so nothing else that reads them breaks; you may add benign extra keys but do not remove the existing ones.

Payment methods on file (the "On file" / "With payment method" KPI):
- For MOST page customers (decide a deterministic majority, e.g. ~22 of 26 — leave a few intentionally "Missing" so the column shows both states), insert a PaymentMethod via the existing `upsert_processor.(Accrue.Billing.PaymentMethod, &Accrue.Billing.PaymentMethod.changeset/2, <deterministic pm uuid>, "pm_phase191_host_page_#{padded}", attrs)` and then set the customer's `default_payment_method_id` to that PM's id (mirror the hero_accounts.exs pattern: re-run `Customer.changeset/2` with `%{default_payment_method_id: pm.id}` only when it differs, so re-seeds stay no-op).
- PaymentMethod attrs: copy the field shape from hero_accounts.exs `pm_seed_healthy_portal_default` — `type: "card"`, `is_default: true`, a per-customer-unique `fingerprint` (e.g. `"fp_phase191_host_page_#{padded}"`), realistic `card_brand` (vary across Visa/Mastercard/Amex deterministically), `card_last4` (deterministic 4 digits from index), `card_exp_month`/`card_exp_year` AND the `exp_month`/`exp_year` aliases, `metadata`/`data`.
- Derive a deterministic PM `id` UUID in a distinct sub-namespace so it never collides with the customer ids (e.g. base it on the suffix with a different group nibble, like `"19100000-0000-4002-8000-#{suffix}"`).
- The PRIMARY customer (`cus_phase191_host_customer`) and the one-row customer get NO payment method change (primary is asserted `is_nil`). Only page customers get PMs.

Do NOT touch the `:faker` dep, mix.lock, or any other seed sub-file. Faker is available in dev/test (the envs seeds run in).
  </action>
  <verify>
    <automated>cd examples/accrue_host && grep -q "Faker.Company.name" priv/repo/seeds/phase191_flow_states.exs && grep -q "pm_phase191_host_page" priv/repo/seeds/phase191_flow_states.exs && grep -q "default_payment_method_id" priv/repo/seeds/phase191_flow_states.exs && grep -c "cus_phase191_host_page" priv/repo/seeds/phase191_flow_states.exs</automated>
  </verify>
  <done>
The page-customer loop emits Faker-backed names/emails, varied owner_types, and a deterministic majority of page customers get an idempotent `pm_phase191_host_page_NN` PaymentMethod plus a back-set `default_payment_method_id`. The primary and one-row customers' payment-method state is unchanged. All `cus_phase191_host_page_NN` processor_ids, ids, owner_ids, and the count of 26 are preserved.
  </done>
</task>

<task type="auto">
  <name>Task 2: Coherent linked subscriptions/invoices/charges for a realistic subset</name>
  <files>examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs</files>
  <action>
For a bounded, deterministic SUBSET of the page customers (pick a fixed number — e.g. the first N where N is small enough to keep insert volume low but large enough to make several detail pages rich; recommend N = 8–12, you choose and record N in a comment), build a coherent linked billing graph so their customer detail pages, KPIs, and signals populate.

For each chosen page customer (index `i`), insert via the existing `upsert_processor` helper, with deterministic ids and processor_ids in the page namespace:
- A subscription `sub_phase191_host_page_#{padded}` (use `&Subscription.changeset/2` for active rows, `&Subscription.force_status_changeset/2` if you seed a non-active status like `:past_due`/`:trialing`). Set `customer_id`, `status`, `current_period_start`/`current_period_end` (use the existing `days_ago`/`days_from_now` helpers), `lock_version: 1`, and benign `metadata`/`data`. Vary status across the subset (mostly `:active`, a couple `:trialing`, one `:past_due` with a `dunning_campaign_started_at` so the Recovery/at-risk signal lights up) so the demo shows a realistic status mix.
- An invoice `in_phase191_host_page_#{padded}` (use `&Invoice.force_status_changeset/2`) linked to that customer + subscription. Copy the full money-field shape from showcase.exs invoice_specs (subtotal_minor/tax_minor/total_minor/total_cents/amount_due_minor/amount_paid_minor/amount_remaining_minor, currency, number, billing_reason, collection_method, the relevant timestamps). Vary status/currency a little (mostly `:paid` usd, a couple `:open`, maybe one jpy zero-decimal) but keep amounts internally consistent.
- A charge `ch_phase191_host_page_#{padded}` (use `&Charge.changeset/2`) linked to customer + subscription: `status: "succeeded"` (one `"failed"` in the past-due case), `amount_cents`, `currency`, optional fee fields. Keep amounts coherent with the invoice.

Derive deterministic UUIDs for these rows in distinct sub-namespaces so they never collide with customer/PM ids (e.g. subs `"19100000-0000-4003-8000-#{suffix}"`, invoices `"19100000-0000-4004-8000-#{suffix}"`, charges `"19100000-0000-4005-8000-#{suffix}"`). Every row uses `upsert_processor` so re-seeds are no-ops.

IMPORTANT: keep the PRIMARY customer's existing `sub_phase191_host_active`/`in_phase191_host_boundary`/`ch_phase191_host_boundary` rows untouched — your new rows are ADDITIONAL `*_page_NN` rows. After implementing, COUNT exactly how many `sub_phase191_host%`, `in_phase191_host%`, `ch_phase191_host%` rows the seed now produces (existing + new) — you need these exact totals for Task 3. Record the totals in a comment at the bottom of the loop.
  </action>
  <verify>
    <automated>cd examples/accrue_host && grep -q "sub_phase191_host_page" priv/repo/seeds/phase191_flow_states.exs && grep -q "in_phase191_host_page" priv/repo/seeds/phase191_flow_states.exs && grep -q "ch_phase191_host_page" priv/repo/seeds/phase191_flow_states.exs && mix compile --warnings-as-errors 2>&1 | tail -5</automated>
  </verify>
  <done>
A bounded, deterministic subset of page customers each have a linked subscription + invoice + charge (varied status/currency, including one at-risk/past-due to light the recovery signal). The primary customer's existing `*_active`/`*_boundary` rows are untouched. The exact `sub_/in_/ch_phase191_host%` totals are recorded in a comment for Task 3. The file compiles with `--warnings-as-errors`.
  </done>
</task>

<task type="auto">
  <name>Task 3: Update test count/structure assertions + prove idempotency and preservation</name>
  <files>examples/accrue_host/test/seeds_idempotency_test.exs, examples/accrue_host/test/accrue_host/phase191_seed_reachability_test.exs</files>
  <action>
Update the two host seed tests to reflect the new idempotent linked rows while preserving every existing preserved-string assertion.

In `seeds_idempotency_test.exs`:
- Update the `phase191_fixture_counts/0` expectation map (the `assert first_counts == %{...}` block, ~lines 108-118) so `subscriptions`, `invoices`, and `charges` equal the EXACT totals the seed now produces (existing primary/at-risk rows + the new `*_page_NN` rows from Task 2). `customers` STAYS 28. `coupons`/`promotion_codes`/`connect_accounts`/`webhooks`/`events` stay unchanged. Use the totals you recorded in the seed comment — the arithmetic must match exactly or the first eval fails.
- Do NOT change `phase191_route_ids/0` or any of the `first_route_ids.*` assertions — those preserved processor_ids and ids are untouched.

In `phase191_seed_reachability_test.exs`:
- Leave EVERY existing assertion intact — especially `customer.name =~ "株式会社"`, `customer.name =~ "Café"`, `is_nil(customer.default_payment_method_id)` (primary), `coupon.name =~ "Crème"`, `promo_code.code == "ÉTÉ191"`, `boundary_count(...)`, and `paginated_count() == 26`. The page-customer rename does NOT touch the primary customer's unicode name, so these stay green as-is.
- ADD coverage proving the realism work landed: assert that the page customers now carry non-"Phase 191 Page Customer" names (e.g. fetch `cus_phase191_host_page_01` and assert its name does NOT match `~r/Phase 191 Page Customer/`), and assert that at least one page customer has a non-nil `default_payment_method_id` (e.g. `Repo.aggregate(from(c in Customer, where: like(c.processor_id, "cus_phase191_host_page_%") and not is_nil(c.default_payment_method_id)), :count) > 0`). Optionally assert a `pm_phase191_host_page_%` PaymentMethod count and a `sub_phase191_host_page_%` subscription count > 0. Keep these new assertions structural (counts / negative-match), never asserting specific Faker output (which is non-deterministic).

Then run the full relevant host suite and prove idempotency by re-eval. The idempotency test already evals the seed twice — confirm it stays green.
  </action>
  <verify>
    <automated>cd examples/accrue_host && mix test test/seeds_idempotency_test.exs test/accrue_host/phase191_seed_reachability_test.exs 2>&1 | tail -20</automated>
  </verify>
  <done>
`seeds_idempotency_test.exs` asserts the new exact `subscriptions`/`invoices`/`charges` totals (customers still 28; coupons/promos/connect/webhooks/events unchanged) and all preserved route ids; the two-eval idempotency assertion passes (no double-count, no crash). `phase191_seed_reachability_test.exs` keeps every unicode/boundary/primary-PM-nil assertion green AND adds passing realism assertions (humanized page names, ≥1 page customer with a default payment method). Both test files pass.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| seed script → DB | Dev/Docker-only seed data; no untrusted external input. Faker generates synthetic names/emails. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-knk-01 | Tampering | Seed re-run double-inserts / mutates append-only rows | mitigate | Every new row uses the existing `upsert_processor` get-or-insert keyed on `(processor, processor_id)`; no append-only `accrue_events` rows are added/updated, so the immutability trigger is never hit. Idempotency test evals the seed twice. |
| T-knk-02 | Information disclosure | Realistic-looking PII in demo seeds | accept | Faker output is synthetic; no real PII. PaymentMethods store only card brand/last4/expiry references (never PAN), matching the core security constraint. |
| T-knk-03 | Denial of service | Unbounded linked-row inserts blow up reset time | mitigate | Linked sub/invoice/charge graph is built for a bounded, fixed subset (N ≈ 8–12 page customers), not all 26; payment methods are one cheap row per customer. |
| T-knk-SC | Tampering | npm/pip/cargo installs | n/a | No package installs in this plan (data-only; `:faker` already a dep, mix.lock OFF-LIMITS). |
</threat_model>

<verification>
- `cd examples/accrue_host && mix compile --warnings-as-errors` succeeds (seed file is valid).
- `cd examples/accrue_host && mix test test/seeds_idempotency_test.exs test/accrue_host/phase191_seed_reachability_test.exs` is green — both the two-eval idempotency assertion and the preserved unicode/boundary assertions pass.
- A fresh seed eval succeeds (the tests `Code.eval_file` the seed; that exercises the same path as `mix run priv/repo/seeds.exs`).
- HARD GUARDRAILS confirmed unviolated: `examples/accrue_host/mix.lock` NOT staged/modified; `.planning/research/.cache/` untouched; `ROADMAP.md` untouched; no `accrue_admin` or core `accrue` lib changes; no CSS/JS bundle rebuild; every preserved processor_id / idempotency key / unicode string (`株式会社`/`Café`/`Crème`/`ÉTÉ191`) intact; the 26-page-customer boundary count preserved; `cus_phase191_host%` total still 28; primary customer still `default_payment_method_id == nil`.
</verification>

<success_criteria>
- `/admin/customers` (run locally via `make reset` / `mix run priv/repo/seeds.exs`) shows realistic company/person names + emails for the page customers and "On file" payment-method status for most of them; the "With payment method" KPI is meaningfully non-zero.
- At least one page customer's detail page shows linked subscriptions/invoices/charges and a populated billing signal (including an at-risk/recovery case).
- The seed is re-runnable (idempotent) with stable counts; both gating tests pass with updated counts and preserved strings.
</success_criteria>

<output>
Create `.planning/quick/260621-knk-realistic-fictional-saas-demo-seed-data-/260621-knk-SUMMARY.md` when done.
</output>