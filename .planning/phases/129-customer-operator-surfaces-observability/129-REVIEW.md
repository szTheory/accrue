---
phase: 129-customer-operator-surfaces-observability
reviewed: 2026-05-25T00:00:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - accrue/lib/accrue/billing/dunning.ex
  - accrue/lib/accrue/telemetry/metrics.ex
  - accrue/lib/accrue/webhook/default_handler.ex
  - accrue/lib/accrue/workers/dunning_step.ex
  - accrue/test/support/telemetry_ops_inventory.ex
  - accrue/test/accrue/billing/dunning_test.exs
  - accrue/test/accrue/webhook/dunning_campaign_keying_test.exs
  - accrue/test/accrue/webhook/dunning_campaign_start_test.exs
  - accrue/test/accrue/webhook/dunning_exhaustion_test.exs
  - accrue/test/accrue/workers/dunning_step_test.exs
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/dunning.ex
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
  - accrue_portal/lib/accrue_portal/copy.ex
  - accrue_portal/lib/accrue_portal/live/subscription_live.ex
  - accrue_portal/lib/accrue_portal/path.ex
  - accrue_portal/test/accrue_portal/live/subscription_live_test.exs
findings:
  critical: 0
  warning: 6
  info: 4
  total: 10
status: issues_found
---

# Phase 129: Code Review Report

**Reviewed:** 2026-05-25
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

Reviewed the Phase-129 customer/operator surfaces + observability work: the
dunning lifecycle ledger + telemetry emission (`dunning.campaign_started`,
`dunning.step_sent`, `dunning.recovered`, `dunning.exhausted`), the
`recovered_vs_lost/1` ledger-fold query, the portal recovery banner, and the
admin read-only dunning-state panel.

The core observability logic is well-guarded: the `recovered_vs_lost` query is
fully parameterized (no SQL injection), the ledger writes correctly exclude the
sweeper's request-time `dunning.terminal_action_requested` so "lost" cannot
double-count, and the recovered/exhausted ledger writes are state-guarded
(anchor-cleared / status-flipped) so a webhook redelivery cannot double-write.
No Critical security or data-loss defects were found.

The findings below are correctness/robustness/quality concerns. The most
significant is a **newly-introduced nested `Repo.transaction(multi)` inside the
reducer's outer `Repo.transact`** (WR-01) whose error path is untested and whose
savepoint semantics differ from the Phase-128 plain-update it replaced. The rest
are UX-correctness (terminal-state banner display, duplicated/misleading admin
empty-state fields), a stale moduledoc, a broad bare `rescue`, and a partial
`email_type/1` that can crash on a host-configured custom step key.

## Warnings

### WR-01: Nested `Repo.transaction(multi)` inside the reducer's outer `Repo.transact` (no savepoint, untested error path)

**File:** `accrue/lib/accrue/webhook/default_handler.ex:851-890`
**Issue:** `maybe_finalize_dunning_campaign/2` is invoked at line 742 inside the
`reduce_row` closure, which already runs inside `Repo.transact(fn -> ... end)`.
Phase 129 changed the anchor-clear from a plain `Repo.update()` (Phase 128, which
cleanly joined the outer transaction) to an `Ecto.Multi` executed via
`Repo.transaction(multi)` (line 872). A nested `Repo.transaction` inside an open
transaction does **not** open a savepoint by default, so the new
`record_multi` insert is not isolated: a failure there marks the *outer* DBConnection
as rollback-only, and the `{:error, _failed_op, reason, _changes}` →
`{:error, reason}` mapping (lines 888-889) propagates an error from a connection
that may already be in an aborted state. The happy path works (and is what all
the keying tests exercise — they only assert successful recovery/terminal
finalization), but the failure path is untested and the nested wrapper adds risk
with no benefit over folding both ops into the outer transaction directly.
**Fix:** Drop the inner `Repo.transaction`. Build the same operations against the
outer transaction (the anchor-clear `Repo.update` + an `Events.record/1` call, or
thread an `Ecto.Multi` back to the reducer so `record_multi` runs in the single
enclosing transaction). For example, keep the anchor-clear as a direct update and
record the ledger row in the same outer transaction:

```elixir
with true <- Subscription.dunning_campaign_active?(row),
     true <- finalizing_transition?(updated),
     %DateTime{} = anchor <- row.dunning_campaign_started_at,
     {:ok, _cleared} <-
       updated
       |> Subscription.force_status_changeset(%{dunning_campaign_started_at: nil})
       |> Repo.update() do
  iso_anchor = DateTime.to_iso8601(anchor)
  recovery? = Subscription.active?(updated)

  if recovery? do
    {:ok, _} =
      Events.record(%{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: updated.id,
        data: %{source: dunning_source(row.dunning_sweep_attempted_at)}
      })
  end

  Process.put(:accrue_dunning_cancel, {updated.id, iso_anchor})
  if recovery?, do: Accrue.Telemetry.Ops.emit(:dunning_recovered, ...)
  :ok
else
  {:error, _} = err -> err
  _ -> :ok
end
```

### WR-02: Portal recovery banner shows for terminal `:unpaid` subscriptions

**File:** `accrue_portal/lib/accrue_portal/live/subscription_live.ex:283-285`
**Issue:** `recovery_prompt?/1` returns `true` when `Subscription.past_due?/1`
OR `dunning_campaign_active?/1`. `past_due?/1` matches **both** `:past_due` and
`:unpaid` (see `accrue/lib/accrue/billing/subscription.ex:156-158`). `:unpaid` is
the dunning-**terminal** state — the campaign has been finalized and the anchor
cleared. A customer in that terminal state will still see the banner "Your
payment didn't go through … Update your payment method to keep your subscription
active," implying recovery is still routine. The test suite only covers
`:past_due` and `:active` (`subscription_live_test.exs:161-231`); the `:unpaid`
case is unverified, so the displayed behavior is whatever `past_due?` happens to
do rather than an asserted contract.
**Fix:** Decide and assert the intended contract. If the banner should be
limited to the still-recoverable window, gate on the narrow predicate
(`Subscription.dunning_sweepable?/1`, i.e. strictly `:past_due`) plus
`dunning_campaign_active?/1`, and add a test asserting an `:unpaid` row does
*not* render `[data-role='subscription-recovery-banner']`. If showing it for
`:unpaid` is intended (Stripe `:unpaid` invoices can still be paid), add an
explicit test documenting that decision.

### WR-03: Admin dunning panel renders misleading "Started: Unknown" and duplicates the empty-state body when no campaign exists

**File:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex:242-252`
**Issue:** In the `else` (no-active-campaign) branch the panel renders the
empty-state body once at line 243 **and again** effectively at line 251 via
`next_action_summary/1` (the catch-all clause at `subscription_live.ex:1051`
returns `Copy.dunning_empty_state_body()`), so "This subscription has no active
dunning campaign." appears twice. It also renders `Started:
<%= format_datetime(@subscription.dunning_campaign_started_at) %>` where the
anchor is `nil`, so `format_datetime/1` (line 1019) returns `"Unknown"` — an
operator sees "Started: Unknown" and "Next scheduled action: This subscription
has no active dunning campaign." for a subscription that never entered dunning.
This is confusing operator copy for a read-only diagnostic panel.
**Fix:** In the no-campaign branch, render only the empty-state body and omit the
`Started` / `Next scheduled action` rows (they are only meaningful when
`dunning_campaign_active?/1`). The active branch (lines 233-241) already renders
those rows correctly; the else branch should not repeat them.

### WR-04: `DunningStep.email_type/1` is a partial function that crashes on host-configured custom step keys

**File:** `accrue/lib/accrue/workers/dunning_step.ex:293-295`
**Issue:** `email_type/1` matches only `"reminder"`, `"action_required"`, and
`"final_notice"` with no catch-all. The dunning campaign config schema
(`accrue/lib/accrue/config.ex:8`) accepts an arbitrary `key: atom` per step, so a
host that configures a custom step key produces an Oban job whose
`deliver_step/4` (line 177) calls `Mailer.deliver(email_type(step_key_str), ...)`
and raises `FunctionClauseError`. Because this runs in `perform/1`, the step job
fails and retries (max_attempts: 3) then exhausts — the dunning email is never
sent. The new Phase-129 `emit_step_sent/2` runs *after* delivery, so a crashing
`email_type/1` also means no `dunning.step_sent` ledger/telemetry for that step.
This is partly pre-existing (Phase 128) but the config schema's open `key` makes
it reachable by any host.
**Fix:** Either constrain the step `key` schema to the supported enum, or add a
defensive fallback clause that maps unknown keys to a documented default template
(or returns a tagged error the worker can `{:cancel, :unknown_step_template}`),
rather than raising:

```elixir
defp email_type("reminder"), do: :invoice_payment_failed
defp email_type("action_required"), do: :dunning_action_required
defp email_type("final_notice"), do: :dunning_final_notice
defp email_type(_other), do: :invoice_payment_failed  # or {:error, :unknown_step}
```

### WR-05: Two near-identically-named ops telemetry events fire on the same terminal transition

**File:** `accrue/lib/accrue/webhook/default_handler.ex:770-800`
**Issue:** `maybe_emit_dunning_exhaustion/2` fires **both**
`[:accrue, :ops, :dunning_exhaustion]` (line 770, the Phase-4 signal) **and**
`[:accrue, :ops, :dunning_exhausted]` (line 796, the new DUN-08 lifecycle signal
the counter folds) for the same `:past_due → :unpaid/:canceled` transition, plus
the `dunning.exhausted` ledger write (line 789). The two event names differ only
by tense (`dunning_exhaustion` vs `dunning_exhausted`) and carry overlapping
metadata (`source`, `to_status`). An SRE wiring `Telemetry.Metrics` from
`defaults/0` will get two counters that increment in lockstep but are trivially
easy to confuse, and a future maintainer could "dedupe" them and break the
recovered-vs-lost fold (which depends specifically on the `dunning.exhausted`
ledger type). This is intentional per the plan, but the naming collision is a
maintainability hazard.
**Fix:** Add a code comment at the dual emit site cross-referencing that
`:dunning_exhaustion` is the legacy Phase-4 signal and `:dunning_exhausted` is the
DUN-08 lifecycle signal the `recovered_vs_lost` fold depends on (the ledger
moduledoc already says this; the emit site does not). Consider renaming one of
the two before v1.0 ships, since both are pre-release.

### WR-06: Broad bare `rescue _ ->` in admin `next_action_summary/1` masks all errors

**File:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex:1047-1049`
**Issue:** `next_action_summary/1` wraps the `Campaign.next_step/3` call in
`rescue _ -> Copy.dunning_next_action_unavailable()`. The catch-all rescues
every exception class (including programming errors, `DBConnection` failures,
etc.), silently degrading them to "Next action unavailable" with no telemetry or
log. The cited justification (T-129-14: don't crash the LiveView) is reasonable
for a read-only panel, but a blanket rescue hides genuine bugs in the pure
resolver or config.
**Fix:** Narrow the rescue to the expected failure modes (e.g.
`KeyError`, `ArgumentError`, `FunctionClauseError`) and emit a debug log /
telemetry breadcrumb so a misconfigured cadence is observable rather than
silently swallowed:

```elixir
rescue
  e in [KeyError, ArgumentError, FunctionClauseError] ->
    Logger.debug("dunning next_action_summary fallback: #{inspect(e)}")
    Copy.dunning_next_action_unavailable()
end
```

## Info

### IN-01: `Accrue.Telemetry.Ops` moduledoc "Canonical ops events" list is stale

**File:** `accrue/lib/accrue/telemetry/ops.ex:10-31`
**Issue:** The moduledoc enumerates the canonical ops events but omits the four
new Phase-129 dunning lifecycle events (`dunning_campaign_started`,
`dunning_step_sent`, `dunning_recovered`, `dunning_exhausted`) that are present
in `metrics.ex` and `telemetry_ops_inventory.ex`. The contract test
(`ops_event_contract_test.exs`) strips moduledocs before scanning, so this does
not break the build — but the documented canonical list now disagrees with the
actual inventory and with `guides/telemetry.md`.
**Fix:** Add the four new events to the moduledoc list so the in-module
documentation matches the inventory and the telemetry guide.

### IN-02: `dunning.recovered` / `dunning.exhausted` ledger writes carry no `idempotency_key`

**File:** `accrue/lib/accrue/webhook/default_handler.ex:789-794, 862-867`
**Issue:** Unlike the entitlement-summary and portal-checkout reducers (which
pass `idempotency_key:` to `record_event/5`), the new `dunning.exhausted`
(`Events.record/1`) and `dunning.recovered` (`record_multi`) writes rely solely
on state-guarding (anchor cleared / status no longer `:past_due`) to prevent
double-writes on webhook redelivery. This is correct today because the guards
hold, but it is a more fragile contract than an explicit idempotency key keyed on
the Stripe event id. If a future refactor relaxes the state guard, the counter
would double-count.
**Fix:** Consider adding `idempotency_key: "dunning.exhausted:" <> evt_id` (and
the recovered equivalent) so idempotency is enforced at the ledger layer
independent of the state guard, matching the pattern already used elsewhere in
this file.

### IN-03: Admin panel calls `next_action_summary/1` in both branches; the inactive call is dead-weight

**File:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex:249-251`
**Issue:** Tied to WR-03: the else branch's `Next scheduled action` row always
resolves to the empty-state body via the catch-all clause, so the
`next_action_summary/1` call in that branch never produces a "real" next action
and exists only to duplicate copy already shown at line 243. Removing it (per
WR-03) also removes this redundant code path.
**Fix:** Remove the inactive-branch `Next scheduled action` row (see WR-03).

### IN-04: `recovered_vs_lost/1` `:since`/`:until` accept only `%DateTime{}`; other inputs silently no-op

**File:** `accrue/lib/accrue/billing/dunning.ex:158-166`
**Issue:** `maybe_since/2` and `maybe_until/2` apply the bound only for a
`%DateTime{}` and silently fall through to the unfiltered query for anything
else (`nil`, a `Date`, a string). The docstring promises `%DateTime{}` bounds, so
this is documented behavior, but a caller passing a `Date` or ISO string
(plausible from an admin filter form) would get an unbounded count with no error
— a quietly-wrong result rather than a validation failure.
**Fix:** This is acceptable as a private contract, but consider raising or
returning an error tuple on a non-`DateTime` `:since`/`:until` so a
mis-typed bound is loud rather than silently ignored.

---

_Reviewed: 2026-05-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
