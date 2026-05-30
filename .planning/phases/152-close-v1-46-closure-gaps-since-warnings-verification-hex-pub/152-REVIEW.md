---
phase: 152-close-v1-46-closure-gaps-since-warnings-verification-hex-pub
reviewed: 2026-05-30T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - accrue/lib/accrue/analytics/dunning.ex
  - accrue_admin/lib/accrue_admin/components/funnel_chart.ex
  - accrue_admin/lib/accrue_admin/components/campaign_timeline.ex
  - accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex
  - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
  - accrue_portal/lib/accrue_portal/live/checkout_live.ex
  - accrue_portal/test/accrue_portal/live/checkout_live_test.exs
  - accrue/guides/release-notes.md
findings:
  critical: 3
  warning: 4
  info: 3
  total: 10
status: issues_found
---

# Phase 152: Code Review Report

**Reviewed:** 2026-05-30T00:00:00Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

This batch delivers the dunning analytics context (`Accrue.Analytics.Dunning`), two admin LiveViews (`RecoveryLive`, `CampaignLive`), two admin components (`FunnelChart`, `CampaignTimeline`), the portal checkout LiveView (`CheckoutLive`), a checkout test suite, and updated release notes.

Three blockers were found: an atom-exhaustion vulnerability from `String.to_atom/1` on operator-controlled currency strings, a crash-on-nil in the `CampaignTimeline` component when a `step_sent` event has no matching entry in the indexed list, and a mount clause that silently crashes (no fallback pattern) when the portal session key is absent. Four warnings cover a negative-amount formatting bug, an unguarded `parse_amount_minor/1` that crashes on non-binary input, a data-key inconsistency between `invoices_for_campaign/2` and the component that reads it, and redundant boilerplate that diverges from the router-wired auth path. Three info items note code quality issues.

---

## Critical Issues

### CR-01: `String.to_atom/1` on operator-controlled currency string — atom table exhaustion

**File:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:48`

**Issue:** `String.to_atom(currency)` is called on a string pulled from the `recovered_vs_lost_mrr/1` return value, which derives from the JSONB `currency` field in `accrue_events`. An attacker who can write arbitrary events (or a misconfigured processor that sends unexpected currency codes) can exhaust the BEAM atom table and crash the node. The BEAM atom table is not GC'd; every unique currency value permanently allocates an atom. `String.to_existing_atom/1` is the correct call here, but even better is to keep the value as a string throughout — `Accrue.Invoices.Render.format_money/3` should accept a string currency argument.

**Fix:**
```elixir
# Replace line 48:
currency_arg = if is_binary(currency), do: String.to_atom(currency), else: currency

# With: keep it as a string and pass directly (requires format_money/3 to accept strings,
# which it should since Stripe currency codes are a finite, compile-time-known set).
# If format_money/3 strictly requires an atom, use the safe conversion:
currency_arg = String.to_existing_atom(currency)
```
If `format_money/3` requires atoms and an unknown currency arrives, `String.to_existing_atom/1` will raise `ArgumentError` (correct fail-safe behaviour, not a crash loop) rather than silently leaking atoms.

---

### CR-02: `elem/2` on `nil` crashes when a `step_sent` event has no match in the indexed list

**File:** `accrue_admin/lib/accrue_admin/components/campaign_timeline.ex:39`

**Issue:** The render loop in `arc_rows/1` iterates every event and for `dunning.step_sent` events calls:
```elixir
elem(Enum.find(@step_events_indexed, fn {e, _idx} -> e.id == event.id end), 1)
```
`Enum.find/2` returns `nil` when no tuple matches. `elem(nil, 1)` raises `ArgumentError` at render time, crashing the LiveView process. This can happen if `event.id` is `nil` (pre-v1.44 events are not guaranteed to have an `id`) or if there is any inconsistency between the events list and the indexed list computed from it (e.g., concurrent list mutation is not possible here, but a bug in the upstream data model could produce the same effect). The component has no rescue/fallback for this crash.

**Fix:**
```elixir
# Replace the attempt= binding in the template:
attempt={
  case Enum.find(@step_events_indexed, fn {e, _idx} -> e.id == event.id end) do
    {_e, idx} -> idx
    nil -> "?"
  end
}
```

---

### CR-03: `mount/3` has no fallback clause — crashes with `FunctionClauseError` when `accrue_portal` session key is absent

**File:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex:19`

**Issue:** The only `mount/3` clause pattern-matches `%{"accrue_portal" => portal}` in the session map. If the session does not contain the `"accrue_portal"` key (misconfigured router, expired session after a deploy, or a direct navigation to the URL outside the portal live_session), Elixir raises `FunctionClauseError` — a 500 in production rather than a graceful redirect. The `%{"token" => token}` params pattern is similarly unguarded but that failure mode is less likely because the router controls the URL structure.

**Fix:**
```elixir
# Add a fallback mount clause:
def mount(_params, _session, socket) do
  {:ok, redirect(socket, to: "/")}
end
```
Place this after the primary clause. The primary clause handles the happy path; this clause catches all session-missing cases with a safe redirect.

---

## Warnings

### WR-01: `format_minor_amount/1` produces wrong output for negative amounts

**File:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex:348-352`

**Issue:** The formatter uses `rem/2` to compute the cents component and then calls `abs/1` on it. However, the `dollars` component computed by `div(amount_minor, 100)` is also negative for negative `amount_minor`. A credit of -150 cents formats as `"$-1.50"` (correct), but -105 cents formats as `"$-1.05"` (accidentally correct here), while -100 cents formats as `"$-1.00"` — the `abs` call masks the fact that for values like `-50` cents, `div(-50, 100)` is `0` and `rem(-50, 100)` is `-50`, so `abs` gives `50` and the result is `"$0.50"` instead of `"-$0.50"`. The sign is silently dropped on sub-dollar negative amounts. This affects the discount preview path where `amount_off_minor` could theoretically be negative.

**Fix:**
```elixir
defp format_minor_amount(amount_minor) when is_integer(amount_minor) do
  sign = if amount_minor < 0, do: "-", else: ""
  abs_minor = abs(amount_minor)
  dollars = div(abs_minor, 100)
  cents = abs_minor |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")
  "#{sign}$#{dollars}.#{cents}"
end
```

---

### WR-02: `parse_amount_minor/1` is called without a guard and crashes on non-binary `"amount"` values

**File:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex:338-346`

**Issue:** `parse_amount_minor/1` has a `when is_binary(amount)` guard, but `checkout_amount_minor/1` calls it via `Map.get("amount", "0.00")` which could return a non-binary value if the `line_items` map has an integer or nil `"amount"` key (e.g., set programmatically by an operator calling `LocalSession.create_or_reuse/2` with `amount: 4900` as an integer). The `Decimal.new/1` call on a non-string will raise `Decimal.Error` or `FunctionClauseError`, crashing `mount/3` and producing a 500 instead of falling back to `checkout_amount_minor(_session)` returning 0.

**Fix:**
```elixir
defp parse_amount_minor(amount) when is_binary(amount) do
  # existing implementation
end

defp parse_amount_minor(amount) when is_integer(amount), do: amount

defp parse_amount_minor(_), do: 0
```

---

### WR-03: `invoices_for_campaign/2` returns atom-keyed maps but `CampaignTimeline` reads string keys

**File:** `accrue/lib/accrue/analytics/dunning.ex:384-393` and `accrue_admin/lib/accrue_admin/components/campaign_timeline.ex:56-58, 81-88`

**Issue:** `invoices_for_campaign/2` builds the value maps via a `select:` fragment and `Map.delete/2` — the resulting maps have **atom keys** (`:status`, `:amount_due_cents`, `:card_last4`, `:card_brand`). In `campaign_row/1`, the component reads `Map.get(invoice_ctx, "failure_code")` and `Map.get(invoice_ctx, "failure_message")` — **string keys** that will never match atom keys, so this block always falls through to the `"—"` fallback. In `step_row/1`, `invoice_ctx.status` and `invoice_ctx.amount_due_cents` use atom-key dot syntax (correct), but then the `failure_code`/`failure_message` string-key reads silently fail and always display `"—"` even when the failure data is present. This means the failure reason column is permanently blank for the `campaign_started` row regardless of what data is stored.

Note: `failure_code`/`failure_message` are not fields returned by `invoices_for_campaign/2` at all — they are only available via `at_risk_subscriptions/1`'s `failure_reason` subquery. The `campaign_row/1` component appears to be reading the wrong source map entirely. This is a data-wiring bug.

**Fix:** The `campaign_row/1` for `dunning.campaign_started` should read failure info from the event's own `data` field (which is available as `@event.data`), not from `invoice_map`. The invoice_map lookup at that row is incorrect. For example:
```elixir
# In campaign_row for dunning.campaign_started — read failure_reason from event data directly:
<% failure = @event.data["failure_reason"] || @event.data["failure_code"] %>
<p>{failure || "—"}</p>
```

---

### WR-04: `group_into_arcs/1` is O(n²) in list appends — correctness risk for large histories

**File:** `accrue/lib/accrue/analytics/dunning.ex:353-368`

**Issue:** `group_into_arcs/1` uses `acc ++ [...]` to append new arcs and `arc_events ++ [event]` to append events within an arc. Both operators traverse the full left-hand list on every call, making the function O(n²) in the total number of events. For subscriptions with long dunning histories (many cycles, many step_sent events), the function will produce progressively slower results. More importantly, the `List.last(acc)` + `List.replace_at(acc, -1, ...)` pattern also traverses the full accumulator twice per non-start event. While not a crash, O(n²) in a list that grows unboundedly is a correctness-adjacent quality issue because it can stall a LiveView process for long histories.

**Fix:** Accumulate arcs in reverse (prepend, then `Enum.reverse` at the end) and keep the current arc as a separate accumulator:
```elixir
defp group_into_arcs(events) do
  {arcs, current} =
    Enum.reduce(events, {[], nil}, fn event, {arcs, current} ->
      if event.type == "dunning.campaign_started" do
        arcs = if current, do: [current | arcs], else: arcs
        {arcs, {event.data["campaign_anchor"], [event]}}
      else
        case current do
          nil -> {arcs, {nil, [event]}}
          {anchor, evts} -> {arcs, {anchor, [event | evts]}}
        end
      end
    end)

  arcs = if current, do: [current | arcs], else: arcs

  arcs
  |> Enum.reverse()
  |> Enum.map(fn {anchor, evts} -> {anchor, Enum.reverse(evts)} end)
end
```

---

## Info

### IN-01: Hardcoded "Showing data since 2024-01-01" label — not driven by actual data

**File:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:85`

**Issue:** The cutoff annotation in the recovery dashboard UI is a hardcoded string `"Showing data since 2024-01-01"` that does not reflect the actual `since` window bound chosen by the operator. When a user selects the 7-day window, the label still says 2024-01-01. This is misleading and will become wrong after January 2024 recedes far into history.

**Fix:** Replace the hardcoded date with the computed `since` value:
```elixir
# Pass since as an assign and render it:
|> assign(:since, since)

# In render:
<a ...>Showing data since {Calendar.strftime(@since, "%Y-%m-%d")}</a>
```

---

### IN-02: `CampaignLive` assigns `assign_shell/2` but never assigns `:active_organization_name` locally — relies entirely on `AuthHook`

**File:** `accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex:51-66`

**Issue:** `assign_shell/2` in `CampaignLive` assigns `:page_title`, `:brand`, `:theme`, `:csp_nonce`, `:brand_css_path`, `:assets_css_path`, `:assets_js_path`, `:admin_mount_path`, and `:current_path` — but not `:active_organization_name`. The template uses `@active_organization_name` (line 32). This is safe in production because `AuthHook.on_mount/4` runs before `mount/3` and assigns it, but the `assign_shell/2` helper is inconsistent with its counterpart in `RecoveryLive` and every other admin LiveView, which all also rely on the hook. The inconsistency is a maintenance trap: if someone tests `CampaignLive` outside the live_session (e.g., in an isolated unit test), `@active_organization_name` will be missing and the render will crash.

**Fix:** Either add `|> assign(:active_organization_name, nil)` to `assign_shell/2` as a safe default, or add a `@doc` comment noting the dependency on `AuthHook`.

---

### IN-03: Duplicate trailing paragraph in `release-notes.md`

**File:** `accrue/guides/release-notes.md:116-119`

**Issue:** The final two paragraphs of the "How we version" section are duplicated verbatim (lines 113-114 and 116-119):

```
adopt incrementally; read the changelog before upgrading production.

When in doubt, read **[Upgrade](upgrade.md)** and run your usual test and staging passes.
```

This appears twice, the second copy starting mid-sentence at line 117. This is a copy-paste artifact.

**Fix:** Delete lines 116-119 (the duplicate block).

---

_Reviewed: 2026-05-30T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
