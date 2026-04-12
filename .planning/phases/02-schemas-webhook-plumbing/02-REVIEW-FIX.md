---
phase: 02-schemas-webhook-plumbing
fixed_at: 2026-04-12T19:55:00Z
review_path: .planning/phases/02-schemas-webhook-plumbing/02-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 02: Code Review Fix Report

**Fixed at:** 2026-04-12T19:55:00Z
**Source review:** .planning/phases/02-schemas-webhook-plumbing/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7
- Fixed: 7
- Skipped: 0

## Fixed Issues

### CR-01: Atom Exhaustion via `String.to_existing_atom` on Untrusted Processor String

**Files modified:** `accrue/lib/accrue/webhook/event.ex`
**Commit:** 3fbf380
**Applied fix:** Replaced `String.to_existing_atom(row.processor)` with a bounded `@processor_atoms` allow-list map and a `processor_to_atom/1` private function. The map explicitly maps `"stripe"`, `"stripe_connect"`, and `"fake"` to their atom equivalents. Unknown processor strings raise `ArgumentError` with a clear message rather than relying on BEAM atom table state.

### WR-01: Metadata `validate_value_lengths` Filter Logic Bug

**Files modified:** `accrue/lib/accrue/billing/metadata.ex`
**Commit:** b8b21a6
**Applied fix:** Replaced the misleading `String.length(value) > @max_value_length && key` predicate (which returned a truthy string, working by accident) with a clean boolean predicate: `is_binary(value) and String.length(value) > @max_value_length`. The `Enum.map` step that extracts keys remains unchanged.

### WR-02: DispatchWorker Updates Status Without Re-fetching Row After Handler Execution

**Files modified:** `accrue/lib/accrue/webhook/dispatch_worker.ex`
**Commit:** 69332a6
**Applied fix:** Captured the return value of `repo.update!()` into the `row` variable after transitioning to `:processing`. Previously the updated struct was discarded (pipe used for side-effect only), leaving `row` holding the stale `:received` version for subsequent `mark_succeeded`/`mark_failed_or_dead` calls.

### WR-03: Missing `processor_id` Unique Indexes on Billing Tables

**Files modified:** `accrue/priv/repo/migrations/20260412100002_create_accrue_billing_schemas.exs`
**Commit:** 6f8a9ce
**Applied fix:** Added `unique_index(table, [:processor, :processor_id], where: "processor_id IS NOT NULL")` partial unique indexes to all 6 billing tables: payment_methods, subscriptions, subscription_items, charges, invoices, and coupons. This prevents duplicate processor-synced records while allowing local-only rows without a `processor_id`.

### WR-04: `Billing.customer/1` Has a TOCTOU Race Between SELECT and `create_customer`

**Files modified:** `accrue/lib/accrue/billing.ex`
**Commit:** b62d2e9 (fixed: requires human verification)
**Applied fix:** Extracted `fetch_customer/2` private function and added retry logic in `customer/1`. When `create_customer/1` returns an `Ecto.Changeset` error with `:owner_id` errors (indicating unique constraint violation from a concurrent insert), the function retries the fetch. Non-constraint errors are returned as-is. Avoids infinite recursion by using a single retry fetch rather than recursive `customer/1` call.

### WR-05: `Billing.create_customer/1` Stores Entire Processor Response in `data` Column

**Files modified:** `accrue/lib/accrue/billing.ex`
**Commit:** 5873d12
**Applied fix:** Added `Map.drop(processor_result, [:address, :phone, :shipping, "address", "phone", "shipping"])` to filter PII-sensitive fields from the processor response before storing in the `data` column. Handles both atom and string keys since processor adapters may return either. Aligns with CLAUDE.md constraint: "Payment method details stored as Stripe references, never as PII."

### WR-06: Ingest Uses `Accrue.Repo.transaction` Directly Instead of Host Repo

**Files modified:** `accrue/lib/accrue/webhook/ingest.ex`
**Commit:** 49c7ed5
**Applied fix:** Changed `Oban.insert(job_changeset)` to `repo.insert(job_changeset)` inside the `Multi.run(:maybe_enqueue, ...)` callback. Since `DispatchWorker.new/1` returns a standard Ecto changeset for the `oban_jobs` table, inserting via the `repo` argument (which is the transaction's connection) ensures the Oban job is created within the same transaction as the webhook event row, preserving atomicity even in multi-database setups.

---

_Fixed: 2026-04-12T19:55:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
