---
phase: 03-core-subscription-lifecycle
plan: 05
subsystem: core-subscription-lifecycle
tags: [billing, invoice, workflow, intent-result, state-machine, projection, lines]
dependency_graph:
  requires:
    - "03-01: Accrue.Actor.current_operation_id!, BillingCase, StripeFixtures"
    - "03-02: Invoice Ecto.Enum status + dual changeset (changeset/force_status_changeset), InvoiceItem schema, D3-14 rollup columns"
    - "03-03: Accrue.Processor behaviour Phase 3 invoice callbacks, Fake invoice lifecycle, Accrue.Processor.Idempotency.key"
    - "03-04: IntentResult.wrap/1, SubscriptionProjection.get/2 dual-key helper, Repo.preload/insert!/update! delegations"
  provides:
    - "Accrue.Billing.InvoiceProjection.decompose/1 deterministic decomposer (dual-key, all D3-14 rollups + child items)"
    - "Accrue.Billing.finalize_invoice/2 + finalize_invoice!/2 (draft -> open)"
    - "Accrue.Billing.void_invoice/2 + void_invoice!/2 (any -> void)"
    - "Accrue.Billing.pay_invoice/2 + pay_invoice!/2 (open -> paid, intent_result wrapped)"
    - "Accrue.Billing.mark_uncollectible/2 + mark_uncollectible!/2 (open -> uncollectible)"
    - "Accrue.Billing.send_invoice/2 + send_invoice!/2 (routes via Processor.send_invoice)"
    - "D3-18 one-shape run_action/4 workflow shape reusable by Plans 06/07"
  affects:
    - "Plan 07 webhook DefaultHandler can reuse InvoiceProjection.decompose/1 for reconcile path"
    - "Plan 06 charge/refund actions can reuse the same run_action shape"
tech_stack:
  added: []
  patterns:
    - "D3-18 one-shape workflow: telemetry.span -> Repo.transact -> Processor.<op> -> Projection.decompose -> user-path changeset -> upsert children by stripe_id -> Events.record (same transaction)"
    - "Dual-key projection via SubscriptionProjection.get/2: same decomposer handles string-keyed Stripe wire shape and atom-keyed Fake state"
    - "Intent-result wrapping only on ops that can trigger SCA (pay_invoice); other 4 return plain {:ok, Invoice}"
    - "Bang variants with pay_invoice! raising Accrue.ActionRequiredError on :requires_action"
    - "Source-audit test (refute file contents) locks down the webhook bypass against regressions"
    - "Upsert-by-stripe-id pattern for child items proven idempotent under repeat workflow calls"
key_files:
  created:
    - accrue/lib/accrue/billing/invoice_projection.ex
    - accrue/test/accrue/billing/invoice_projection_test.exs
    - accrue/test/accrue/billing/invoice_workflow_test.exs
    - accrue/test/accrue/billing/invoice_items_test.exs
  modified:
    - accrue/lib/accrue/billing/invoice_actions.ex
decisions:
  - "InvoiceProjection emits :processor_id (not :stripe_id) for the parent invoice row — the Invoice schema uses :processor_id for consistency with Phase 2 subscriptions/customers. Only InvoiceItem uses :stripe_id (the new Phase 3 D3-15 column)."
  - "Dual-key handling in InvoiceProjection is delegated to Accrue.Billing.SubscriptionProjection.get/2 — no duplication. The projection is the shared canonical bridge between atom-keyed (Fake) and string-keyed (StripeFixtures / real Stripe) shapes."
  - "run_action/4 is a private shape helper taking (invoice, processor_fn_atom, event_type_string, opts). Five public actions share one body; only pay_invoice wraps the result through IntentResult.wrap."
  - "Event :type is a string (not atom) matching existing Accrue.Events.record shape — `invoice.finalized`, `invoice.voided`, `invoice.paid`, `invoice.marked_uncollectible`, `invoice.sent`. Data payload carries `%{source: \"api\"}`."
  - "Illegal user-path transitions (e.g. calling pay_invoice/2 on a :draft invoice) produce `{:error, %Ecto.Changeset{}}` with an error on :status — proven by test. The Fake still returns :paid, but the local `Invoice.changeset/2` rejects the transition before the row is updated."
  - "Source-audit test (`refute src =~ \"Invoice.force_status_changeset\"`) locks down the webhook bypass against accidental reuse in the user-path module. The docstring uses a plain-English reference instead of the literal function name to avoid tripping the audit."
  - "Idempotency key derivation follows Plan 04 pattern: `Idempotency.key(processor_fn_atom, inv.id, op_id)` where op_id comes from `Keyword.get(opts, :operation_id) || Actor.current_operation_id!()`. The Phase 3 Actor strict-mode raises if neither is set."
metrics:
  duration: "~12 minutes"
  completed: "2026-04-14"
  tasks_completed: 2
  files_created: 4
  files_modified: 1
  test_count: "314 tests, 20 properties, 0 failures (up from 296 baseline, +18 new)"
requirements: [BILL-17, BILL-18, BILL-19]
---

# Phase 3 Plan 05: Invoice write surface Summary

Ship the full invoice workflow on `Accrue.Billing`: `finalize_invoice/2`,
`void_invoice/2`, `pay_invoice/2`, `mark_uncollectible/2`,
`send_invoice/2` and all five bang variants. Every mutation runs the
D3-18 one-shape pipeline — `telemetry.span` around a `Repo.transact/2`
that threads `Processor.<op>` → `InvoiceProjection.decompose/1` →
`Invoice.changeset/2` (user-path, enforces the legal
draft→open→paid/void/uncollectible state machine) → upsert child
`InvoiceItem` rows by `stripe_id` → `Events.record/1` — all in one
transaction, preserving the EVT-04 invariant that every state mutation
and its audit event land atomically. `pay_invoice/2` is the only action
that wraps its result through `IntentResult.wrap/1`, because it's the
only one where Stripe can surface a `requires_action` PaymentIntent.

`Accrue.Billing.InvoiceProjection` ships as the deterministic
decomposer — a mirror of `SubscriptionProjection`, reusing its
`get/2` dual-key helper so the same decomposer handles both
string-keyed Stripe wire shapes (from `StripeFixtures.invoice/1` and
the real `Accrue.Processor.Stripe` adapter) and atom-keyed Fake shapes
(from `Accrue.Processor.Fake.create_invoice/2`). Every D3-14 rollup
column is extracted (subtotal_minor, tax_minor, discount_minor,
total_minor, amount_due_minor, amount_paid_minor,
amount_remaining_minor, currency, number, hosted_url, pdf_url,
period_start, period_end, due_date, collection_method, billing_reason,
finalized_at, paid_at, voided_at) plus child items from
`lines.data` with `stripe_id`, `description`, `amount_minor`,
`currency`, `quantity`, `period_start/end`, `proration`, `price_ref`,
`subscription_item_ref`, and full `data` preservation. Plan 07's
webhook reducer will reuse the same module unchanged.

## Work Completed

### Task 1 — `Accrue.Billing.InvoiceProjection` (TDD)

**Commits:** `1645ee8` (RED), `49430ba` (Task 1 GREEN), `c69726f` (fix)

- `decompose/1` returns `{:ok, %{invoice_attrs: map, item_attrs: [map]}}`
  — invoice attrs ready for `Invoice.changeset/2`, items list ready
  for `InvoiceItem.changeset/2` (caller adds `:invoice_id`).
- Dual-key support: delegates every field lookup through
  `Accrue.Billing.SubscriptionProjection.get/2`, which tries both atom
  and string keys. Same decomposer handles Fake (atom-keyed) and
  StripeFixtures (string-keyed) without duplication.
- Status atom parsing over `~w(draft open paid uncollectible void)a`
  — handles nil (→ `:draft`), atoms, and strings; unknown strings
  fall through to `:draft` via `String.to_existing_atom/1` rescue.
- Timestamp conversion via private `unix_dt/1`: handles nil, 0
  (Stripe sentinel), `%DateTime{}` passthrough, and integer →
  `DateTime.from_unix!/1`.
- `finalized_at`, `paid_at`, `voided_at` fall back to
  `status_transitions.<field>` if the top-level column is nil — Stripe
  puts these under both keys depending on the event source.
- Preserves the full upstream map in `data` so the jsonb column
  round-trips without loss.
- Discount extraction: `stripe_inv["discount"]["amount_off"]` (or
  nil if `discount` is null).
- **Fix-up commit `c69726f`**: The initial Task 1 implementation
  emitted `:stripe_id` for the parent invoice row, but
  `Accrue.Billing.Invoice` uses `:processor_id` (consistent with
  Phase 2 customers/subscriptions). `InvoiceItem` keeps `:stripe_id`
  because that's the new Phase 3 D3-15 column. Updated the projection
  and the matching test assertion.

**7 tests:**

- Status/rollups/period dates (string-keyed wire)
- `lines.data` → item attrs list
- Status paid → `:paid`
- Status void → `:void`
- Full stripe map preserved in `data`
- Nil status defaults to `:draft`
- Atom-keyed Fake shape round-trips through the same decomposer

### Task 2 — `Accrue.Billing.InvoiceActions` workflow (TDD)

**Commit:** `6f83608`

`Accrue.Billing.InvoiceActions` went from a raise-on-call stub to the
full Plan 05 implementation. The public surface is 5 action + 5 bang
variants, all delegated from `Accrue.Billing` (Plan 01 facade):

| Action               | Returns                                   | State transition            |
| -------------------- | ----------------------------------------- | --------------------------- |
| `finalize_invoice/2` | `{:ok, Invoice}`                          | `draft → open`              |
| `void_invoice/2`     | `{:ok, Invoice}`                          | `any → void`                |
| `pay_invoice/2`      | `intent_result(Invoice)` (wrapped)        | `open → paid`               |
| `mark_uncollectible/2` | `{:ok, Invoice}`                        | `open → uncollectible`      |
| `send_invoice/2`     | `{:ok, Invoice}`                          | no state change (notify)    |

**Workflow shape (`run_action/4`):**

```elixir
:telemetry.span([:accrue, :billing, :invoice, processor_fn], meta, fn ->
  result =
    Repo.transact(fn ->
      with {:ok, stripe_inv} <- apply(Processor.__impl__(), processor_fn, [inv.processor_id, stripe_opts]),
           {:ok, %{invoice_attrs: attrs, item_attrs: items}} <- InvoiceProjection.decompose(stripe_inv),
           {:ok, updated}  <- inv |> Invoice.changeset(attrs) |> Repo.update(),
           {:ok, _upsert}  <- upsert_items(updated, items),
           {:ok, _event}   <- Events.record(%{type: event_type, subject_type: "Invoice", subject_id: updated.id, data: %{source: "api"}}) do
        {:ok, Repo.preload(updated, :items, force: true)}
      end
    end)
  {result, %{result: tag(result)}}
end)
```

One shape, five actions. `pay_invoice/2` is the only caller that pipes
its return through `IntentResult.wrap/1`.

**Upsert semantics:** `upsert_item/1` dispatches on the child's
`:stripe_id`. If nil → plain insert. If a binary → query
`InvoiceItem` by `stripe_id` (respecting the Phase 3 partial unique
index `accrue_invoice_items_stripe_id_index`), update if found, insert
otherwise. This is proven idempotent by the `invoice_items_test`
upsert case: two consecutive workflow calls with the same upstream
line set produce the same row count.

**Idempotency key:** `Idempotency.key(processor_fn, inv.id, op_id)`
where `op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()`.
The Phase 3 Actor raises in `:strict` mode if neither is set; the
`BillingCase` seeds a per-test operation id via
`Actor.put_operation_id/1`.

**Bang variants:** `finalize_invoice!/2`, `void_invoice!/2`,
`mark_uncollectible!/2`, `send_invoice!/2` unwrap `{:ok, _}` or raise.
`pay_invoice!/2` additionally raises `Accrue.ActionRequiredError` on
`{:ok, :requires_action, pi}`, surfacing SCA to the caller.

**11 new tests:**

- `invoice_workflow_test.exs` (9 tests):
  1. `finalize_invoice` draft→open with items preloaded
  2. `finalize_invoice` records `accrue_events` row in same transaction
  3. `void_invoice` transitions to :void
  4. `pay_invoice` :open→:paid (requires finalize first)
  5. `mark_uncollectible` :open→:uncollectible
  6. `send_invoice` returns `{:ok, Invoice}`
  7. `finalize_invoice!` bang variant returns raw struct
  8. Illegal user-path transition `draft → paid` returns
     `{:error, %Ecto.Changeset{}}` with error on `:status`
  9. Source-audit: `InvoiceActions` does NOT call
     `Invoice.force_status_changeset` (lockdown against webhook-bypass
     regressions)
- `invoice_items_test.exs` (2 tests):
  1. `decompose + insert` creates InvoiceItem rows linked to invoice
     with correct amount_minor, price_ref
  2. Upsert via workflow is idempotent — two consecutive workflow
     calls yield the same `count(InvoiceItem)`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Plan specified `:stripe_id` for the parent invoice row**

- **Found during:** Task 2 first compile + test
- **Issue:** The plan's Task 1 literal emits
  `stripe_id: stripe_inv["id"]` in the invoice_attrs. But
  `Accrue.Billing.Invoice` schema uses `:processor_id` (consistent
  with Phase 2 customer/subscription). Only `InvoiceItem` uses
  `:stripe_id` (the new Phase 3 D3-15 column). Shipping the plan as
  literal would produce `KeyError` on
  `Invoice.changeset/2 → cast/3` silently dropping the key.
- **Fix:** Projection emits `:processor_id` for invoices,
  `:stripe_id` for items. Updated the Task 1 tests to assert
  `attrs.processor_id == inv["id"]`. Separate fix-up commit
  `c69726f` after Task 1 green.
- **Files modified:** `accrue/lib/accrue/billing/invoice_projection.ex`,
  `accrue/test/accrue/billing/invoice_projection_test.exs`
- **Commit:** `c69726f`

**2. [Rule 2 — Missing critical functionality] Dual-key handling in the projection**

- **Found during:** Task 1 implementation
- **Issue:** The plan literal uses only string-keyed access
  (`stripe_inv["status"]`, `stripe_inv["subtotal"]`, etc.) — which
  works for `StripeFixtures.invoice/1` but crashes on the atom-keyed
  maps returned by `Accrue.Processor.Fake`. The Plan 05 workflow
  tests need to drive real Fake invoices through the projection, so
  the decomposer must accept either shape.
- **Fix:** Delegate every field lookup through
  `Accrue.Billing.SubscriptionProjection.get/2`, which is the
  existing Phase 3 dual-key helper (atom first, fall back to string).
  The atom-keyed test case (`Accrue.Processor.Fake`-shaped invoice)
  now round-trips through the same decomposer. No duplication.
- **Files modified:** `accrue/lib/accrue/billing/invoice_projection.ex`
- **Commit:** `49430ba`

**3. [Rule 1 — Bug] Plan's workflow test seed used `Accrue.Billing.create_customer(%{})` with a plain map**

- **Found during:** Task 2 test writing
- **Issue:** Plan's setup literal calls
  `Accrue.Billing.create_customer(%{owner_type: "User", ...})`. But
  `Accrue.Billing.create_customer/1` takes a **billable struct**,
  not a plain attrs map — it's the host-side entry point that
  resolves via protocol dispatch on `billable.__struct__`. Plain maps
  don't match the `%{__struct__: mod, id: id} = billable` pattern.
- **Fix:** Test setups insert `%Customer{}` directly via
  `Customer.changeset/2 |> Repo.insert/1`, matching the pattern
  Plan 04's `subscription_test.exs` uses for the same reason.
- **Files modified:**
  `accrue/test/accrue/billing/invoice_workflow_test.exs`,
  `accrue/test/accrue/billing/invoice_items_test.exs`
- **Commit:** `6f83608`

**4. [Rule 1 — Bug] Plan's test pattern `Fake.scripted_response(:finalize_invoice, ...)` was unnecessary**

- **Found during:** Task 2 test writing
- **Issue:** The plan's workflow tests program the Fake via
  `Fake.scripted_response(:op, {:ok, StripeFixtures.invoice(...)})`.
  But the Fake already has a full invoice lifecycle — call
  `Fake.create_invoice/2` to get a real stored invoice, then calling
  `Billing.finalize_invoice/2` exercises the same `invoice_action`
  dispatch on the Fake's stored state. Scripted responses are for
  **error injection** (`{:error, %Accrue.CardError{}}`), not the happy
  path. Using them on the happy path would mean the test never
  actually exercises the Fake's state machine.
- **Fix:** Tests drive real Fake state: seed via `Fake.create_invoice`,
  insert a local Invoice row at `:draft`, then call
  `Billing.finalize_invoice` which hits
  `Processor.finalize_invoice(stripe_id, opts)` → Fake's
  `apply_invoice_action(:finalize, clock)` → returns the transitioned
  stored invoice. Same request flow the host app will see.
- **Files modified:**
  `accrue/test/accrue/billing/invoice_workflow_test.exs`
- **Commit:** `6f83608`

**5. [Rule 1 — Bug] Source-audit test tripped on docstring literal**

- **Found during:** Task 2 initial test run
- **Issue:** The initial source-audit test `refute src =~ "force_status_changeset"`
  matched the moduledoc's explanatory reference
  ``The webhook path uses `Accrue.Billing.Invoice.force_status_changeset/2`...``
  — a false positive; the lockdown target is actual calls, not
  documentation mentions.
- **Fix:** Two changes. First, tightened the audit to
  `refute src =~ "Invoice.force_status_changeset"` (the module-qualified
  call form) AND `refute src =~ ~r/\|>\s*force_status_changeset/`
  (the pipe form). Second, rewrote the moduledoc reference in
  plain English ("the force-status bypass on the Invoice schema")
  so future edits can't accidentally trip either regex.
- **Files modified:** `accrue/lib/accrue/billing/invoice_actions.ex`,
  `accrue/test/accrue/billing/invoice_workflow_test.exs`
- **Commit:** `6f83608`

## Verification Results

- `MIX_ENV=test mix compile --warnings-as-errors` — clean (0 warnings,
  77 files)
- `MIX_ENV=test mix test --seed 0` — **314 tests, 20 properties, 0
  failures** (up from 296 baseline in 03-04, +18 new)
- `MIX_ENV=test mix test test/accrue/billing/invoice_projection_test.exs`
  — 7/7 pass
- `MIX_ENV=test mix test test/accrue/billing/invoice_workflow_test.exs`
  — 9/9 pass
- `MIX_ENV=test mix test test/accrue/billing/invoice_items_test.exs`
  — 2/2 pass
- `mix credo --strict` — **0 issues** across 118 source files (828
  mods/funs analyzed)

## Success Criteria

- [x] `Accrue.Billing.finalize_invoice/2` transitions `:draft → :open`
      (proven by test)
- [x] `Accrue.Billing.void_invoice/2` transitions to `:void`
- [x] `Accrue.Billing.pay_invoice/2` transitions `:open → :paid` and
      returns via `IntentResult.wrap`
- [x] `Accrue.Billing.mark_uncollectible/2` transitions
      `:open → :uncollectible`
- [x] `Accrue.Billing.send_invoice/2` delegates to
      `Processor.send_invoice` (not Elixir `send/2`)
- [x] Invoice line items decompose from `lines.data` into
      `accrue_invoice_items` rows
- [x] `InvoiceProjection.decompose/2` extracts all D3-14 rollup columns
- [x] Illegal user-path transitions (`draft → paid`) return
      `{:error, %Ecto.Changeset{}}` with error on `:status`
- [x] `force_status_changeset` bypass is used only by webhook path
      (source-audit test proves it isn't called from InvoiceActions)
- [x] Every mutation records an `accrue_events` row in the same
      `Repo.transact/2` (EVT-04 invariant proven by test)
- [x] `upsert_items/2` is idempotent — repeated workflow calls don't
      duplicate rows (proven by invoice_items_test)

## Acceptance Criteria Checklist

Task 1:

- [x] `grep -q "defmodule Accrue.Billing.InvoiceProjection"` in
      `invoice_projection.ex` — present
- [x] `grep -q "def decompose"` — present
- [x] `grep -q "item_attrs"` — present
- [x] `grep -q "hosted_invoice_url"` — present
- [x] `grep -q "invoice_pdf"` — present
- [x] `grep -q "subtotal_minor"` — present
- [x] 7 projection tests passing (plan specified 5; added nil-status
      default and atom-keyed Fake shape)

Task 2:

- [x] `grep -q "defmodule Accrue.Billing.InvoiceActions"` — present
- [x] `grep -q "def finalize_invoice"` — present
- [x] `grep -q "def void_invoice"` — present
- [x] `grep -q "def pay_invoice"` — present
- [x] `grep -q "def mark_uncollectible"` — present
- [x] `grep -q "def send_invoice"` — present
- [x] `grep -q "IntentResult.wrap"` — present
- [x] `grep -q "Invoice.changeset"` — present
- [x] `! grep -q "Invoice.force_status_changeset"` — absent (proven
      by in-source audit test)
- [x] `mix test test/accrue/billing/invoice_workflow_test.exs` — 9/9
      passing (plan specified ≥6; added EVT-04 invariant + bang +
      illegal transition + audit)
- [x] `mix test test/accrue/billing/invoice_items_test.exs` — 2/2
      passing

## Self-Check: PASSED

All created files exist, all commits are in the log:

- `accrue/lib/accrue/billing/invoice_projection.ex` — FOUND
- `accrue/lib/accrue/billing/invoice_actions.ex` — MODIFIED (full
  Plan 05 implementation replacing stub)
- `accrue/test/accrue/billing/invoice_projection_test.exs` — FOUND (7
  tests)
- `accrue/test/accrue/billing/invoice_workflow_test.exs` — FOUND (9
  tests)
- `accrue/test/accrue/billing/invoice_items_test.exs` — FOUND (2
  tests)
- Commit `1645ee8` (Task 1 RED) — FOUND
- Commit `49430ba` (Task 1 GREEN) — FOUND
- Commit `c69726f` (processor_id fix) — FOUND
- Commit `6f83608` (Task 2) — FOUND
