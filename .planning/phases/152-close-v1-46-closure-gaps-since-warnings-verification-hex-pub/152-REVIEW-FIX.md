---
phase: 152-close-v1-46-closure-gaps-since-warnings-verification-hex-pub
fixed_at: 2026-05-30T00:00:00Z
review_path: .planning/phases/152-close-v1-46-closure-gaps-since-warnings-verification-hex-pub/152-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 152: Code Review Fix Report

**Fixed at:** 2026-05-30T00:00:00Z
**Source review:** .planning/phases/152-close-v1-46-closure-gaps-since-warnings-verification-hex-pub/152-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7
- Fixed: 7
- Skipped: 0

## Fixed Issues

### CR-01: `String.to_atom/1` on operator-controlled currency string

**Files modified:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`
**Commit:** 2fd26836
**Applied fix:** Replaced `String.to_atom(currency)` with `String.to_existing_atom(currency)` on line 48. This raises `ArgumentError` on unknown currency codes (correct fail-safe) rather than permanently allocating a new atom and eventually exhausting the BEAM atom table.

---

### CR-02: `elem/2` on `nil` crashes when step_sent event has no indexed match

**Files modified:** `accrue_admin/lib/accrue_admin/components/campaign_timeline.ex`
**Commit:** 512b6db6
**Applied fix:** Replaced the bare `elem(Enum.find(...), 1)` call in the `arc_rows/1` template with a `case` expression that pattern-matches `{_e, idx} -> idx` on success and falls back to `"?"` when `Enum.find/2` returns `nil`. This prevents `ArgumentError` from crashing the LiveView process when an event has no matching entry in the indexed list.

---

### CR-03: `mount/3` no fallback clause — FunctionClauseError when session key absent

**Files modified:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex`
**Commit:** 117c4ce4
**Applied fix:** Added a catch-all `def mount(_params, _session, socket)` clause after the primary `%{"accrue_portal" => portal}` clause. When the session key is absent (misconfigured router, expired session after deploy, or direct URL navigation outside the live_session), the fallback clause redirects to `"/"` instead of raising `FunctionClauseError` and producing a 500.

---

### WR-01: `format_minor_amount/1` drops sign for sub-dollar negative amounts

**Files modified:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex`
**Commit:** 285a03f9
**Applied fix:** Rewrote `format_minor_amount/1` to extract the sign separately, take `abs(amount_minor)` first, then divide to get dollars and cents. The old code used `div(amount_minor, 100)` directly, producing `0` for sub-dollar negatives and losing the sign. The new code formats as `"#{sign}$#{dollars}.#{cents}"` which is correct for all values including `-50` cents (`"-$0.50"`).

---

### WR-02: `parse_amount_minor/1` crashes on non-binary input

**Files modified:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex`
**Commit:** a91c2cdf
**Applied fix:** Added two additional clauses after the existing `when is_binary(amount)` clause: `defp parse_amount_minor(amount) when is_integer(amount), do: amount` (passes integer amounts through unchanged) and `defp parse_amount_minor(_), do: 0` (returns 0 for any other unexpected type such as `nil`). This prevents `Decimal.new/1` from raising when an operator passes an integer `amount` in `line_items`.

---

### WR-03: `campaign_row/1` reads wrong source for failure info

**Files modified:** `accrue_admin/lib/accrue_admin/components/campaign_timeline.ex`
**Commit:** 43b21791
**Applied fix:** Removed the `invoice_map` lookup for `failure_code`/`failure_message` in the `dunning.campaign_started` row. Those fields are not present in `invoices_for_campaign/2` return values (which use atom keys and a different field set). Replaced with `@event.data["failure_reason"] || @event.data["failure_code"]` — reading directly from the event's own JSONB data, which is where failure context is actually recorded for the campaign_started event.

---

### WR-04: `group_into_arcs/1` is O(n²) in list appends

**Files modified:** `accrue/lib/accrue/analytics/dunning.ex`
**Commit:** e14a2a08
**Applied fix:** Rewrote `group_into_arcs/1` using a two-accumulator `Enum.reduce/3` pattern. The completed-arcs list and the current-arc event list both use prepend (`[item | list]`) during the reduce, then `Enum.reverse/1` is applied to both at the end. This eliminates the four O(n) traversals per element (`acc ++ [...]`, `arc_events ++ [event]`, `List.last/1`, `List.replace_at/3`) and reduces the overall complexity from O(n²) to O(n).

---

_Fixed: 2026-05-30T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
