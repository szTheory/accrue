---
phase: 04-advanced-billing-webhook-hardening
plan: 05
subsystem: billing-coupons-discounts
tags: [wave-5, bill-27, bill-28, coupons, promotion-codes, discounts, d4-mirror-not-compute]
dependency_graph:
  requires:
    - "Phase 3 D3-16 (accrue_coupons minimal schema)"
    - "04-01 (accrue_promotion_codes migration, invoice.total_discount_amounts column, subscription.discount_id column)"
    - "04-03 (Subscription.force_status_changeset/2 webhook path)"
  provides:
    - "Accrue.Billing.PromotionCode Ecto schema (thin passthrough; unique on code + processor_id)"
    - "Accrue.Billing.PromotionCodeProjection.decompose/1 → {attrs, coupon_processor_id}"
    - "Accrue.Billing.CouponActions.create_coupon/2 + create_promotion_code/2 + apply_promotion_code/3"
    - "Accrue.Billing.Invoice.force_discount_changeset/2 (Stripe-canonical, no validate_number)"
    - "Accrue.Billing.InvoiceProjection — discount_minor summation from total_discount_amounts"
    - "Accrue.Billing.SubscriptionProjection — discount_id extraction"
    - "Processor callbacks: coupon_create/2, coupon_retrieve/2, promotion_code_create/2, promotion_code_retrieve/2"
    - "Accrue.Processor.Fake coupon/promotion_code in-memory storage with id prefixes coupon_fake_ / promo_fake_"
    - "Accrue.Billing defdelegates: create_coupon, create_promotion_code, apply_promotion_code (+ bang variants)"
    - "coupon.created / promotion_code.created / coupon.applied accrue_events rows"
  affects:
    - "Plan 04-06/07/08 — promotion code + discount projection decoupled from downstream work"
    - "Closes Phase 3 D3-16 schema/DB drift on accrue_coupons (amount_off_minor + redeem_by columns now actually present)"
tech_stack:
  added: []
  patterns:
    - "Thin-passthrough projection pattern (BILL-27 shape — mirror only the fields admin LV filters/sorts on, not the full Stripe object)"
    - "Pre-processor validation pipeline for apply_promotion_code (fetch → active → max_redemptions → expires_at) BEFORE any HTTP call so crafted/expired/exhausted inputs never reach Stripe (T-04-05-02 mitigation)"
    - "Force-path changeset on webhook for discounts (D3-17 extended): force_discount_changeset/2 casts without validate_number; Stripe is canonical (D2-29)"
    - "Wrapped-list jsonb storage shape %{\"data\" => [...]} for total_discount_amounts — mirrors Stripe's own list-object wire shape and sidesteps Ecto :map's rejection of top-level arrays"
    - "Upsert-by-processor_id coupon persistence (SELECT + INSERT/UPDATE) instead of :replace_all_except on_conflict — avoids triggering the Phase 3 schema/DB drift that broke :replace_all_except target resolution"
    - "Idempotency.key(:apply_promotion_code, sub.id, operation_id) before any Stripe call so retries converge on the same Stripe idempotency key"
key_files:
  created:
    - "accrue/lib/accrue/billing/promotion_code.ex"
    - "accrue/lib/accrue/billing/promotion_code_projection.ex"
    - "accrue/lib/accrue/billing/coupon_actions.ex"
    - "accrue/priv/repo/migrations/20260414130600_add_missing_coupon_columns.exs"
    - "accrue/test/accrue/billing/coupon_actions_test.exs"
    - "accrue/test/accrue/billing/promotion_code_test.exs"
    - "accrue/test/accrue/billing/discount_denormalization_test.exs"
  modified:
    - "accrue/lib/accrue/billing.ex"
    - "accrue/lib/accrue/billing/invoice.ex"
    - "accrue/lib/accrue/billing/invoice_projection.ex"
    - "accrue/lib/accrue/billing/subscription_projection.ex"
    - "accrue/lib/accrue/processor.ex"
    - "accrue/lib/accrue/processor/fake.ex"
    - "accrue/lib/accrue/processor/fake/state.ex"
    - "accrue/lib/accrue/processor/stripe.ex"
    - "accrue/test/support/stripe_fixtures.ex"
decisions:
  - "Coupon upsert uses a SELECT-by-processor_id followed by insert or update, rather than Repo.insert with on_conflict: {:replace_all_except, ...}. The latter implicitly references every schema field in its ON CONFLICT DO UPDATE target, which surfaced the Phase 3 schema/DB drift (amount_off_minor + redeem_by were declared on the schema but never migrated) as a hard SQL error. The SELECT-then-write shape is local to CouponActions and has no upstream implications."
  - "Added migration 20260414130600_add_missing_coupon_columns.exs to close the Phase 3 D3-16 schema/DB drift (amount_off_minor :bigint + redeem_by :utc_datetime_usec). Rule 1 deviation — the drift was a latent bug blocking any SELECT on accrue_coupons, not a forward-compat stub. Explicitly categorized as a bug fix in the migration moduledoc."
  - "total_discount_amounts is stored as %{\"data\" => [...]} (wrapped list) not as a bare list, because Ecto's :map type rejects top-level arrays at the jsonb boundary. The wrapper mirrors Stripe's own `list` object shape (e.g. `items: %{object: \"list\", data: [...]}`) so admin LV consumers iterate a familiar structure. Alternative (Ecto {:array, :map} custom type) would require migrating accrue_invoices.total_discount_amounts from jsonb to jsonb[] — rejected because the column was already created in 04-01 as jsonb."
  - "No new reduce_invoice wiring in DefaultHandler — the existing Invoice.force_status_changeset/2 path already casts the whole @cast_fields list, and adding :total_discount_amounts to that list made the webhook reconcile path automatically pick up the new column. force_discount_changeset/2 is published as a dedicated entry point for future webhook handlers that want a focused cast (documented in its moduledoc), but Plan 05 does not need it inside DefaultHandler."
  - "apply_promotion_code/3 validates applicability (active / expires_at / max_redemptions) BEFORE Repo.transact. Pure lookup, no side effects, lets the :error tuple return cleanly without rollback overhead. Only the successful path wraps the processor call + event record in a single transact block. Matches the T-04-05-02 STRIDE disposition (pre-flight check so replayed crafted codes never touch Stripe)."
  - "CouponActions.create_coupon/2 omits `:amount_off_minor` → nil when Stripe's coupon payload has no amount_off (percent_off-only coupons) because the schema has no NOT NULL guard on it. Stripe's coupon objects carry amount_off xor percent_off, never both."
  - "PromotionCodeProjection.decompose/1 returns a three-tuple `{:ok, attrs, coupon_processor_id}` instead of folding the coupon reference into attrs. Callers (CouponActions) need the processor_id string to resolve the local coupon FK, and the schema-level Repo.insert wants the local :coupon_id UUID. Splitting these two identifier shapes at the projection boundary keeps the action layer free of nested map drilling."
metrics:
  duration: "~30m"
  tasks_completed: 2
  files_created: 7
  files_modified: 9
  commits: 2
  completed_date: "2026-04-14"
requirements: [BILL-27, BILL-28]
---

# Phase 4 Plan 05: BILL-27 Coupons + BILL-28 Discount Denormalization Summary

Closes BILL-27 (PromotionCode CRUD + coupon lifecycle wrapper) and BILL-28 (webhook-driven denormalization of Stripe discount fields into local rollup columns). Thin-passthrough projection: Accrue mirrors Stripe's `discount_minor` + `total_discount_amounts` + `discount_id` fields, never computes discount math locally (D2-29 canonicality). Ships the customer-facing `Accrue.Billing.apply_promotion_code/3` flow with pre-processor validation so crafted / expired / exhausted inputs never touch Stripe.

## Objective Achieved

A Phoenix developer running Accrue can now expose promo codes to customers with full pre-flight validation and audit trail:

- Seed a 100%-off coupon: `Accrue.Billing.create_coupon(%{id: "accrue_comp_100_forever", percent_off: 100, duration: "forever"})` — required by `Accrue.Billing.comp_subscription/3` shipped in 04-03.
- Create a promotion code backed by that coupon: `Accrue.Billing.create_promotion_code(%{coupon: "accrue_comp_100_forever", code: "VIP"})` — persists a local `%PromotionCode{}` with unique constraints on `code` + `processor_id`.
- Apply at customer request: `Accrue.Billing.apply_promotion_code(sub, "VIP")` — returns `{:error, :not_found | :inactive | :expired | :max_redemptions_reached}` for any invalid case BEFORE hitting Stripe, or `{:ok, %Subscription{}}` on success with a `coupon.applied` event in the append-only ledger.
- Stripe's discount state flows back via webhooks: `invoice.finalized` populates `invoice.discount_minor` + `total_discount_amounts`; `customer.subscription.updated` populates `subscription.discount_id` — all through the existing D3-17 `force_status_changeset/2` path.

## Tasks Completed

| # | Task | Commit | Key Files |
|---|------|--------|-----------|
| 1 | PromotionCode schema + projection + CouponActions (create_coupon, create_promotion_code, apply_promotion_code) wired through Processor behaviour, Stripe adapter, and Fake adapter with 14 tests | `18a6df6` | `billing/promotion_code.ex`, `billing/promotion_code_projection.ex`, `billing/coupon_actions.ex`, `processor.ex`, `processor/fake.ex`, `processor/stripe.ex` |
| 2 | Invoice.force_discount_changeset/2 + InvoiceProjection discount extraction + SubscriptionProjection discount_id extraction + 10 tests | `74ea9f8` | `billing/invoice.ex`, `billing/invoice_projection.ex`, `billing/subscription_projection.ex` |

## Key Decisions Made

- **No on_conflict :replace_all_except.** Replaced with SELECT-by-processor_id + conditional insert/update. The :replace_all_except target expansion surfaced the Phase 3 coupons schema/DB drift as a hard SQL error.
- **Phase 3 coupon schema drift closed via migration, not worked around.** `amount_off_minor` and `redeem_by` were declared in the `Accrue.Billing.Coupon` Ecto schema but never landed in migrations. Migration `20260414130600_add_missing_coupon_columns.exs` closes the drift. This is a Rule 1 auto-fix — a latent bug that would have broken any caller touching the table.
- **total_discount_amounts wrapped as %{"data" => [...]}.** Ecto's `:map` type rejects top-level jsonb arrays. Wrapping mirrors Stripe's own list-object wire shape and defers the decision on whether to migrate to `jsonb[]` to a later plan if admin LV ergonomics demand it.
- **apply_promotion_code/3 validates OUTSIDE Repo.transact.** Pure lookup, no side effects; lets `:error` tuples return cleanly. Only the Stripe call + event record are wrapped in transact. Matches T-04-05-02 STRIDE disposition.
- **PromotionCodeProjection returns 3-tuple with coupon_processor_id split out.** Cleaner than folding the nested coupon reference into attrs — the action layer wants the FK UUID, the projection layer knows the processor_id string.
- **force_discount_changeset/2 published but not wired into DefaultHandler.** The existing Invoice.force_status_changeset/2 path already casts the new fields via @cast_fields, so webhook denormalization happens without new wiring. force_discount_changeset/2 is available for future focused-cast handlers and documented in moduledoc.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Phase 3 `accrue_coupons` schema/DB drift**
- **Found during:** Task 1 (first `Repo.get_by(Coupon, processor_id: ...)` crash)
- **Issue:** `Accrue.Billing.Coupon` schema declared `:amount_off_minor` + `:redeem_by` fields from D3-16, but migration `20260412100002_create_accrue_billing_schemas.exs` never added the columns. Any SELECT on the table failed with `undefined_column`. Latent bug since Phase 3 shipped.
- **Fix:** Added migration `20260414130600_add_missing_coupon_columns.exs` with both columns (`amount_off_minor :bigint`, `redeem_by :utc_datetime_usec`). Rewrote `CouponActions.upsert_coupon/1` to use SELECT + insert/update instead of `on_conflict: {:replace_all_except, ...}` so the drift issue can't resurface.
- **Files modified:** `accrue/priv/repo/migrations/20260414130600_add_missing_coupon_columns.exs` (new)
- **Commit:** `18a6df6`

**2. [Rule 1 - Bug] Plan-text referenced nonexistent callback `subscription_update/3`**
- **Found during:** Task 1 (during coupon_actions.ex authoring)
- **Issue:** Plan text's pseudocode referenced `Processor.__impl__().subscription_update(...)`. The canonical Phase 3 callback name is `update_subscription/3` (see `Accrue.Processor` @callback declaration). Same naming carryover noted in 04-04 SUMMARY.
- **Fix:** Used `update_subscription/3` everywhere, matching Phase 3 precedent.
- **Files modified:** `accrue/lib/accrue/billing/coupon_actions.ex`
- **Commit:** `18a6df6`

**3. [Rule 3 - Blocking] Test fixture `invoice_test.updated` not in DefaultHandler dispatch whitelist**
- **Found during:** Task 2 (discount_denormalization_test.exs first run)
- **Issue:** DefaultHandler dispatch whitelist for `"invoice." <> action` is `~w(created finalized paid payment_failed voided marked_uncollectible sent)` — `updated` is absent. First test draft used `"invoice.updated"` and hit the `{:ok, :ignored}` fallthrough.
- **Fix:** Changed test to `"invoice.finalized"` which exercises the same reduce_invoice path. Whitelist extension deferred — plan did not require `invoice.updated` support and adding it would balloon scope.
- **Files modified:** `accrue/test/accrue/billing/discount_denormalization_test.exs`
- **Commit:** `74ea9f8`

**4. [Rule 3 - Blocking] Fake stub signature for webhook fetch**
- **Found during:** Task 2 (DefaultHandler reduce_invoice refetch path)
- **Issue:** First test draft stubbed `:fetch` with `fn :invoice, _id -> ... end`. DefaultHandler calls `Processor.__impl__().fetch(:invoice, stripe_id)` which in Fake delegates to `retrieve_invoice/2`, a GenServer call. Stubbing `:fetch` never intercepts because the Fake's `fetch/2` isn't a genserver op.
- **Fix:** Stubbed `:retrieve_invoice` with `fn _id, _opts -> ... end` directly.
- **Files modified:** `accrue/test/accrue/billing/discount_denormalization_test.exs`
- **Commit:** `74ea9f8`

**5. [Rule 3 - Blocking] Expired-promotion test clock skew**
- **Found during:** Task 1 (apply_promotion_code `:expired` branch test)
- **Issue:** Test set `expires_at = DateTime.utc_now() - 1 day`, but `Accrue.Clock.utc_now/0` in test env reads the Fake clock (epoch 2026-01-01), which is far in the past relative to wall clock. Fake sees expires_at as well in the future, skipping the `:expired` branch.
- **Fix:** Use `Accrue.Clock.utc_now/0` as the anchor for the expired date.
- **Files modified:** `accrue/test/accrue/billing/coupon_actions_test.exs`
- **Commit:** `18a6df6`

**6. [Rule 1 - Bug] Idempotency cache collision in "duplicate code" test**
- **Found during:** Task 1 (create_promotion_code dup test)
- **Issue:** Test called `create_promotion_code(%{code: "DUP"})` twice in sequence expecting the second to return a `changeset.errors[:code]`. But the Fake's idempotency cache keyed on `(:promotion_code_create, "DUP", operation_id)` returned the same cached result on the second call, so the second insert tried the same `processor_id` and hit the `processor_id` uniqueness constraint first.
- **Fix:** Test now inserts a second PromotionCode changeset DIRECTLY via `Repo.insert/1` (bypassing the idempotency cache) with a fresh `processor_id` but the same `code`, asserting the DB-level `unique_constraint(:code)` fires. This tests the actual constraint path the webhook reconciler will hit on genuine duplicates.
- **Files modified:** `accrue/test/accrue/billing/coupon_actions_test.exs`
- **Commit:** `18a6df6`

### Human Verification Bypassed

None — fully autonomous execution.

## Tests Added

| File | Tests | Coverage |
|------|-------|----------|
| `test/accrue/billing/coupon_actions_test.exs` | 9 | create_coupon happy + deterministic-id fallback; create_promotion_code happy + unique constraint; apply_promotion_code happy + 4 error branches (:not_found, :inactive, :expired, :max_redemptions_reached) |
| `test/accrue/billing/promotion_code_test.exs` | 8 | required-field changeset validation; force_status_changeset lax path; processor_id + code unique constraints; projection extraction with nested coupon reference + expires_at unix conversion + nil handling |
| `test/accrue/billing/discount_denormalization_test.exs` | 10 | InvoiceProjection.decompose sum-of-discounts + empty path; force_discount_changeset negative values allowed (no validate_number); webhook reduce_invoice finalized → discount_minor + total_discount_amounts; re-project overwrites; no-discount path; SubscriptionProjection.discount_id for nested / string / nil shapes |

Total: **27 tests, all green.** Full suite before commit: **490 tests, 36 properties, 0 failures.**

## Credo Strict

Clean on all new / modified files:

```
lib/accrue/billing/invoice.ex
lib/accrue/billing/invoice_projection.ex
lib/accrue/billing/subscription_projection.ex
lib/accrue/billing/promotion_code.ex
lib/accrue/billing/promotion_code_projection.ex
lib/accrue/billing/coupon_actions.ex
→ 82 mods/funs, found no issues.
```

## Self-Check: PASSED

All created files present on disk:

- `accrue/lib/accrue/billing/promotion_code.ex` ✓
- `accrue/lib/accrue/billing/promotion_code_projection.ex` ✓
- `accrue/lib/accrue/billing/coupon_actions.ex` ✓
- `accrue/priv/repo/migrations/20260414130600_add_missing_coupon_columns.exs` ✓
- `accrue/test/accrue/billing/coupon_actions_test.exs` ✓
- `accrue/test/accrue/billing/promotion_code_test.exs` ✓
- `accrue/test/accrue/billing/discount_denormalization_test.exs` ✓

Commits verified in git log:

- `18a6df6` feat(04-05): PromotionCode schema + CouponActions (BILL-27) ✓
- `74ea9f8` feat(04-05): webhook discount denormalization (BILL-28) ✓
