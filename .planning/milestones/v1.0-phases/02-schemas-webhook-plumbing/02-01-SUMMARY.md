---
phase: 02-schemas-webhook-plumbing
plan: 01
subsystem: database
tags: [ecto, schemas, migrations, postgres, webhooks, metadata]

# Dependency graph
requires:
  - phase: 01-foundations
    provides: Event schema pattern, Config module, Repo facade, Error hierarchy
provides:
  - Polymorphic Customer schema with owner_type/owner_id
  - PaymentMethod, Subscription, SubscriptionItem, Charge, Invoice, Coupon stub schemas
  - Metadata validation helper with Stripe-compatible constraints
  - WebhookEvent schema with status enum and bytea raw_body
  - 3 migrations creating 8 tables with indexes
affects: [02-02, 02-03, 02-04, 02-05, phase-03, phase-07]

# Tech tracking
tech-stack:
  added: []
  patterns: [Ecto.Enum for webhook status, optimistic_lock on all billing schemas, Stripe-compatible metadata validation, custom Inspect protocol for PII redaction]

key-files:
  created:
    - accrue/lib/accrue/billing/metadata.ex
    - accrue/lib/accrue/billing/customer.ex
    - accrue/lib/accrue/billing/payment_method.ex
    - accrue/lib/accrue/billing/subscription.ex
    - accrue/lib/accrue/billing/subscription_item.ex
    - accrue/lib/accrue/billing/charge.ex
    - accrue/lib/accrue/billing/invoice.ex
    - accrue/lib/accrue/billing/coupon.ex
    - accrue/lib/accrue/webhook/webhook_event.ex
    - accrue/priv/repo/migrations/20260412100001_create_accrue_customers.exs
    - accrue/priv/repo/migrations/20260412100002_create_accrue_billing_schemas.exs
    - accrue/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs
  modified: []

key-decisions:
  - "Used %__MODULE__{} in typespecs instead of t() since Ecto.Schema does not auto-generate t/0 type"
  - "WebhookEvent raw_body uses redact: true field option plus custom Inspect protocol for defense-in-depth PII protection"
  - "Billing stub schemas include has_many/belongs_to associations wired up for Phase 3 preload support"

patterns-established:
  - "Billing schema pattern: binary_id PK, processor/processor_id, metadata/data maps, lock_version, utc_datetime_usec timestamps"
  - "Metadata validation: shared Accrue.Billing.Metadata.validate_metadata/2 imported by all billing schemas"
  - "Optimistic locking: all billing schemas use Ecto.Changeset.optimistic_lock(:lock_version)"

requirements-completed: [BILL-01, WH-11, WH-12, WH-14]

# Metrics
duration: 4min
completed: 2026-04-12
---

# Phase 02 Plan 01: Billing Schemas + WebhookEvent Summary

**9 Ecto schemas and 3 migrations establishing the billing domain foundation with polymorphic Customer, Stripe-compatible metadata validation, and webhook event ledger with status enum and bytea raw_body**

## What Was Built

### Billing Schemas (8 modules)

- **Accrue.Billing.Customer** -- Fully-realized polymorphic schema with `owner_type`/`owner_id` as explicit strings (D2-01, D2-02), `metadata` with Stripe-compatible validation (D2-07), `data` jsonb cache (D2-08), and `optimistic_lock` on `lock_version` (D2-09). Composite unique index on `(owner_type, owner_id, processor)`.

- **Accrue.Billing.Metadata** -- Shared validation helper enforcing Stripe's exact metadata contract: max 50 keys, keys max 40 chars, values max 500 chars, flat string/string only, no nested maps. Includes `shallow_merge/2` for update paths where `""`/`nil` deletes a key (D2-10 rejects deep merge).

- **Accrue.Billing.{PaymentMethod, Subscription, SubscriptionItem, Charge, Invoice, Coupon}** -- Stub schemas with the common billing shape (binary_id PK, processor/processor_id, metadata/data maps, lock_version, timestamps). All include metadata validation and optimistic locking. Associations wired (belongs_to/has_many) for Phase 3 preload support.

### WebhookEvent Schema

- **Accrue.Webhook.WebhookEvent** -- Single-table webhook event ledger with:
  - `status` as `Ecto.Enum` with values `[:received, :processing, :succeeded, :failed, :dead, :replayed]` (D2-33)
  - `raw_body` as `:binary` (PostgreSQL bytea) for byte-exact forensic replay
  - `ingest_changeset/1` for hot-path webhook insert (casts required fields only)
  - `status_changeset/2` for status transitions with automatic `processed_at` timestamping
  - Custom `Inspect` protocol implementation excluding `raw_body` from output (T-2-04a PII mitigation)
  - `redact: true` on `raw_body` field for defense-in-depth

### Migrations (3 files)

1. **20260412100001** -- `accrue_customers` with composite unique index and processor indexes
2. **20260412100002** -- All remaining billing tables (payment_methods, subscriptions, subscription_items, charges, invoices, coupons) with foreign keys, customer/subscription indexes
3. **20260412100003** -- `accrue_webhook_events` with `UNIQUE(processor, processor_event_id)`, partial index on `status IN ('failed', 'dead')` (D2-36), type and livemode indexes

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed undefined `t()` type in @spec annotations**
- **Found during:** Task 1 compilation
- **Issue:** `use Ecto.Schema` does not generate a `t/0` type. All schema modules used `t()` in `@spec changeset(t() | ...)` which caused `Kernel.TypespecError` on Elixir 1.19.5.
- **Fix:** Replaced `t()` with `%__MODULE__{}` in all 8 `@spec` annotations (7 billing schemas + 1 webhook event).
- **Files modified:** All 8 schema modules
- **Commit:** 08fa109

## Verification

- `mix compile --warnings-as-errors` exits 0
- `MIX_ENV=test mix ecto.migrate` exits 0 (all 3 migrations applied)
- All 9 schema modules exist with correct field definitions
- Customer has `owner_type :string`, `owner_id :string`, `optimistic_lock(:lock_version)`, metadata validation
- WebhookEvent has `Ecto.Enum` status with all 6 values, `raw_body :binary`, unique constraint on processor+processor_event_id

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 08fa109 | Billing schemas, metadata validation, webhook event schema |
| 2 | 27ce11e | Migrations for all billing schemas and webhook events |

## Self-Check: PASSED

- All 9 schema files: FOUND
- All 3 migration files: FOUND
- Commit 08fa109: FOUND
- Commit 27ce11e: FOUND
