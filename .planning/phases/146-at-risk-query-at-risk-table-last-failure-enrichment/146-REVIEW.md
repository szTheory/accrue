---
phase: 146-at-risk-query-at-risk-table-last-failure-enrichment
reviewed: 2026-05-27T23:05:54Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - accrue/lib/accrue/webhook/default_handler.ex
  - accrue/lib/accrue/billing/query.ex
  - accrue/test/accrue/webhook/dunning_campaign_start_test.exs
  - accrue/test/accrue/billing/query_test.exs
  - accrue/test/accrue/analytics/at_risk_subscriptions_test.exs
  - accrue/lib/accrue/analytics/dunning.ex
  - accrue_admin/lib/accrue_admin/components/at_risk_table.ex
  - accrue_admin/assets/css/app.css
  - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
  - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
findings:
  critical: 2
  warning: 3
  info: 3
  total: 8
status: issues_found
---

# Phase 146: Code Review Report

**Reviewed:** 2026-05-27T23:05:54Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Phase 146 adds three things: (1) `Accrue.Analytics.Dunning.at_risk_subscriptions/1` — a live-query enriching active dunning subscriptions with ETA and last-failure data; (2) `AccrueAdmin.Components.AtRiskTable` — the table component rendering that data; (3) `Accrue.Billing.Query.in_active_dunning_campaign/1` — a composable query fragment.

The core `Query` module addition is clean and correctly tested. The `DefaultHandler` changes are pre-existing and not part of this phase's surface area (only the new `calculate_mrr_cents` function at the bottom is net-new).

Two blockers exist. First, `pf.data` (a JSONB column) is placed in the `GROUP BY` list in `at_risk_subscriptions/1`; because every `invoice.payment_failed` event produces a distinct `data` payload (different `stripe_event_id`), a subscription with multiple payment failures in its campaign window is returned as **multiple rows**, one per distinct failure event. Second, `format_failure/1` in `AtRiskTable` displays the Stripe internal event ID from `pf.data.stripe_event_id` as "Last Failure Reason" — the Accrue ledger stores only `%{source: "webhook", stripe_event_id: ...}` in event data, not the decline message. The column is meaningless to a merchant operator.

Three warnings cover: a test helper that crashes instead of failing cleanly, duplicate rows in `at_risk_subscriptions` when multiple `dunning.campaign_started` events exist per subscription, and the `current_step` off-by-one (Step 0 displayed for a newly-started campaign).

---

## Critical Issues

### CR-01: `pf.data` in GROUP BY causes one row per payment failure, not one per subscription

**File:** `accrue/lib/accrue/analytics/dunning.ex:212-219`

**Issue:** `pf.data` is included in `group_by`. `pf` is a left-joined `accrue_events` row of type `invoice.payment_failed`. Every payment failure event for the same invoice carries a different `stripe_event_id` in its `data` JSONB payload (written by `record_event/5` as `%{source: "webhook", stripe_event_id: evt_id}`). PostgreSQL treats each distinct JSONB value as a separate group key, so a subscription that has failed payment three times in its campaign window will appear three times in the `Repo.all` result. The `AtRiskTable` then renders three identical rows for the same customer. This also inflates the count string "N active dunning campaigns in this window" in the table header.

The intent is to select at most one failure reason per subscription. The group key should be `s.id` (and its dependent columns) only; `pf.data` must not be a group key.

**Fix:** Remove `pf.data` from the `group_by` list. To return a single failure event per subscription, use a correlated scalar subquery in the `select` clause (fetching `data` from the most-recent `invoice.payment_failed` event for the invoice), or add a `DISTINCT ON` / window function to the `pf` join to keep only the latest failure. A scalar subquery approach matches the pattern already used for `current_step`:

```elixir
group_by: [
  s.id,
  s.customer_id,
  c.email,
  c.name,
  s.dunning_campaign_started_at
  # pf.data removed
],
select: %{
  # ... other fields unchanged ...
  failure_reason:
    fragment(
      """
      (SELECT e.data FROM accrue_events e
         JOIN accrue_invoices i ON i.id::text = e.subject_id
         JOIN accrue_events cs ON cs.type = 'dunning.campaign_started'
                               AND cs.subject_id = ?::text
                               AND cs.data->>'invoice_id' = i.processor_id
       WHERE e.type = 'invoice.payment_failed'
         AND e.inserted_at >= ?
       ORDER BY e.inserted_at DESC
       LIMIT 1)
      """,
      s.id,
      s.dunning_campaign_started_at
    )
}
```

Alternatively, the simpler approach: keep the join but use `max(pf.inserted_at)` to identify the latest failure, and join back for the `data`. If the failure reason display is low-priority, remove `pf` and the `inv` joins entirely and return `nil` for `failure_reason` until the enrichment is reworked.

---

### CR-02: `format_failure/1` displays an opaque Stripe event ID as "Last Failure Reason"

**File:** `accrue_admin/lib/accrue_admin/components/at_risk_table.ex:85-87`

**Issue:** `format_failure/1` calls `Map.get(data, "stripe_event_id", "—")`. The `data` map for an `invoice.payment_failed` ledger event is written by `record_event/5` in `DefaultHandler` as:

```elixir
%{source: "webhook", stripe_event_id: stripe_event_id}
```

This contains only internal plumbing metadata, not the actual payment failure reason (e.g., "Your card was declined", "Insufficient funds", `card_declined`, etc.). A merchant operator looking at the "Last Failure Reason" column will see something like `evt_1OgVGXLkdIwHu7ixypbT3KDs` — an opaque Stripe event ID that provides no actionable information.

The `@moduledoc` for `AtRiskTable` describes `:failure_reason` as "raw `pf.data` jsonb" which accurately describes what the data is, but the column header "Last Failure Reason" implies human-readable failure context. The mismatch propagates from `dunning.ex` where the docstring for `at_risk_subscriptions/1` says `:failure_reason` is "raw `invoice.payment_failed` event data map" without noting that this only contains webhook metadata.

**Fix:** Either:

(a) Pull the actual Stripe decline reason into the ledger. When recording the `invoice.payment_failed` event in `DefaultHandler.reduce_invoice/4`, add failure context extracted from the canonical invoice payload into `data`:

```elixir
# In record_event call for invoice.payment_failed:
Events.record(%{
  type: "invoice.payment_failed",
  subject_type: "Invoice",
  subject_id: updated.id,
  data: %{
    source: "webhook",
    stripe_event_id: evt_id,
    failure_code: get(canonical, :last_finalization_error) |> get(:code),
    failure_message: get(canonical, :last_finalization_error) |> get(:message)
  }
})
```

(b) Change `format_failure/1` to display a different key that IS meaningful, or update the column header to "Last Event" and document the limitation.

(c) If the failure reason cannot be reliably populated, remove the column and the `inv`/`pf` join entirely for v1.44; re-add in a follow-on phase with proper enrichment.

---

## Warnings

### WR-01: `active_window_label/1` test helper crashes instead of failing cleanly when regex finds no match

**File:** `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:212-217`

**Issue:** `active_window_label/1` pipes `Regex.run/3` output through `List.first/1` then `String.trim/1`. When `Regex.run` returns `nil` (no `aria-current="page"` element in the HTML), `List.first(nil)` raises `FunctionClauseError` because `List.first/1` requires a list argument. The comment says "Fails with nil if no active button is found" — this is incorrect; it crashes the test with a confusing error rather than a clear assertion failure. All five window-selector tests (`lines 181, 187, 193, 199, 206`) share this helper and would produce opaque FunctionClauseErrors if the `WindowSelector` component changes its `aria-current` placement.

**Fix:**

```elixir
defp active_window_label(html) do
  case Regex.run(~r/aria-current="page"[^>]*>\s*([^<]+)\s*<\/a>/, html,
         capture: :all_but_first
       ) do
    [label | _] -> String.trim(label)
    nil -> nil
  end
end
```

Tests that call this should then use `assert active_window_label(html) =~ "30 days"` — if the result is `nil`, the `=~` will raise a clear mismatch rather than a FunctionClauseError.

---

### WR-02: Multiple `dunning.campaign_started` events per subscription produce phantom rows via Cartesian product in `at_risk_subscriptions/1`

**File:** `accrue/lib/accrue/analytics/dunning.ex:184-188`

**Issue:** The `cs` left join (campaign_started events) is:

```elixir
left_join: cs in Event,
on:
  cs.type == "dunning.campaign_started" and
    fragment("? = ?::text", cs.subject_id, s.id) and
    cs.inserted_at >= s.dunning_campaign_started_at,
```

There is no guard limiting this to a single row. In normal operation there is one `dunning.campaign_started` event per campaign, but Oban retry semantics or a crashed DispatchWorker that replayed the webhook could produce duplicates. If `cs` matches two events, the subsequent `inv` and `pf` joins produce a Cartesian product: a subscription that had one payment failure would appear twice. Combined with CR-01, the duplication compounds.

**Fix:** Add a `LIMIT 1` subquery or use `DISTINCT ON` to select only the earliest (or latest) `dunning.campaign_started` event per subscription:

```elixir
left_join: cs in subquery(
  from(e in Event,
    where: e.type == "dunning.campaign_started",
    distinct: e.subject_id,
    order_by: [asc: e.inserted_at]
  )
),
on: fragment("? = ?::text", cs.subject_id, s.id) and
    cs.inserted_at >= s.dunning_campaign_started_at,
```

The `idempotency_key` on `accrue_events` may already prevent exact duplicates (the `emit_campaign_started` path does not pass an `idempotency_key`), but the defensive guard is needed since there is no database-level unique constraint scoped to campaign-started events.

---

### WR-03: `current_step` off-by-one — newly-started campaign renders "Step 0"

**File:** `accrue_admin/lib/accrue_admin/components/at_risk_table.ex:62` and `accrue/lib/accrue/analytics/dunning.ex:231-235`

**Issue:** `current_step` is computed as:

```sql
(SELECT COUNT(*) FROM accrue_events WHERE type = 'dunning.step_sent' AND subject_id = ?::text AND inserted_at >= ?)
```

When a dunning campaign has just started (day 0, before the first step fires), this count is 0. The template renders `Step {row.current_step}` which produces `"Step 0"`. To an operator, "Step 0" is confusing — the campaign is in progress at step 1 (pending). At step 1 sent it shows "Step 1", which is correct. The issue is the zero case.

The docstring for `at_risk_subscriptions/1` describes `:current_step` as "count of `dunning.step_sent` events", which is accurate but the "Step N" UI presentation implies a 1-indexed step position. Displaying "Step 0" or "Pending" for the not-yet-fired case would be clearer.

**Fix (component):** Render the step as 1-indexed or with a "Pending" fallback:

```elixir
<td class="ax-body">
  <%= if row.current_step == 0, do: "Pending", else: "Step #{row.current_step}" %>
</td>
```

Or add `+ 1` to the count in the query to make it 1-indexed (step 1 = waiting, step 2 = first step sent, etc.) — but this changes the documented semantics. The simplest fix is the Pending label.

---

## Info

### IN-01: `Query.in_active_dunning_campaign/1` is defined but not used in production code

**File:** `accrue/lib/accrue/billing/query.ex:148-151`

**Issue:** `in_active_dunning_campaign/1` is a new query fragment added in this phase, but `Accrue.Analytics.Dunning.at_risk_subscriptions/1` does not use it — it replicates the same predicate inline with `where: not is_nil(s.dunning_campaign_started_at)`. No other call site exists in non-test code. The fragment is well-written and tested; it will presumably be used by a future context or admin query, but it is currently dead code.

**Fix:** Either wire `at_risk_subscriptions/1` to use `Query.in_active_dunning_campaign/1` as its base queryable (`from(s in Query.in_active_dunning_campaign(), ...)`) to remove the duplicate inline predicate, or document that the fragment is anticipatory.

---

### IN-02: `@dunning_lifecycle_types` module attribute includes `"dunning.step_sent"` but `funnel/1` does not filter by it in the inner subquery — only `campaign_started`, `recovered`, and `exhausted` contribute to funnel stage counts

**File:** `accrue/lib/accrue/analytics/dunning.ex:20-21`

**Issue:**

```elixir
@dunning_lifecycle_types ~w[dunning.campaign_started dunning.step_sent dunning.recovered dunning.exhausted]
```

This attribute is used in the `funnel/1` inner query at line 121 to filter events. `"dunning.step_sent"` events are loaded into the subquery but produce neither `has_recovered: true` nor `has_exhausted: true`. They contribute rows to the `per_campaign` subquery, which means the outer `count()` (entered) over distinct `(subject_id, campaign_anchor)` tuples counts a campaign that only has a `step_sent` event as "entered" even if no `campaign_started` event exists. This is an edge case, but it means `entered` can count campaigns not initiated by `campaign_started` events (e.g., manual step injection or a missed event). Conversely, `step_sent` is needed only to establish that a campaign "entered" if `campaign_started` is somehow missing.

More likely the intent is that `step_sent` was added to ensure campaigns with only steps (no explicit start event) are counted — but this over-counts if `step_sent` events exist without a `campaign_started` event that crossed the `(subject_id, campaign_anchor)` pair. Not a bug in normal operation, but a latent correctness risk.

**Fix:** Document the intent of including `step_sent` in `@dunning_lifecycle_types`, or remove it if the invariant is that `campaign_started` always precedes `step_sent`.

---

### IN-03: `safe_deliver/2` in `DefaultHandler` rescues all exceptions but re-raises `exit` only via the `catch` arm — an `exit/1` from within `Accrue.Mailer.deliver/2` would be caught by the `rescue` arm and silently swallowed

**File:** `accrue/lib/accrue/webhook/default_handler.ex:1850-1860`

**Issue:** The inline comment at line 1845-1848 states: "the `catch` is narrowed to `:throw` only; an abnormal `exit` (e.g. DBConnection.OwnershipError, `exit(:shutdown)`) is RE-RAISED rather than masked". However, in Elixir/Erlang, `exit/1` signals do NOT pass through the `rescue` arm — they are caught by `catch :exit, _`. The current code only has `catch :throw, reason`, meaning an `exit` from `Accrue.Mailer.deliver/2` is NOT caught by `catch :throw` and would propagate normally — which is the intended behavior. But an exception (including `DBConnection.OwnershipError` which IS an exception, not an exit) IS caught by the `rescue e ->` arm and silently suppressed. The comment says `DBConnection.OwnershipError` exits are re-raised, but `DBConnection.OwnershipError` is raised as an exception (not an exit signal in newer DBConnection), so it would be caught and swallowed. This creates a silent failure path for connection errors.

This is pre-existing behavior (not introduced in phase 146) but is called by the new email dispatch paths in phase 146's test coverage.

**Fix:** Narrow the `rescue` to the mailer-specific exception set, or check for `DBConnection.OwnershipError` explicitly:

```elixir
defp safe_deliver(type, assigns) do
  Accrue.Mailer.deliver(type, assigns)
rescue
  %DBConnection.OwnershipError{} = e ->
    reraise e, __STACKTRACE__
  e ->
    emit_dispatch_failed(type, assigns, inspect(e))
    :ok
catch
  :throw, reason ->
    emit_dispatch_failed(type, assigns, inspect({:throw, reason}))
    :ok
end
```

---

_Reviewed: 2026-05-27T23:05:54Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
