---
phase: 176-c-systematic-per-screen-rubric-uplift
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - accrue_admin/lib/accrue_admin/live/webhook_live.ex
  - accrue_admin/lib/accrue_admin/live/charge_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
  - accrue_admin/lib/accrue_admin/live/coupon_live.ex
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/coupon.ex
findings:
  critical: 0
  warning: 0
  info: 1
  total: 1
status: clean
---

# Phase 176-C: Code Review Report (Iteration 2)

**Reviewed:** 2026-06-04
**Depth:** standard
**Files Reviewed:** 7
**Status:** clean

## Summary

Re-review after iteration 1 applied four fixes: CR-01 (safe_utf8 binary guard), WR-01 (charge not-found redirect to `/payments`), WR-02 (put_flash + Copy keys for not-found on invoice/charge/connect), WR-03 (coupon format_minor replaced with `Accrue.Invoices.Render.format_money/3` + `normalize_currency`).

All four fixes are correctly implemented and no new Critical or Warning issues were introduced. Specific verification:

- **CR-01 (safe_utf8):** `text when is_binary(text) -> {:ok, text}` guard correctly distinguishes the success tuple from `:unicode.characters_to_binary/1`'s error/incomplete returns. The catch-all `_error_or_incomplete -> :error` return meshes cleanly with the `with` else arm in `decode_raw_body/1`. Fix is sound.
- **WR-01 (charge not-found → /payments):** `redirect(to: admin_path(admin, "/payments"))` at line 38 of `charge_live.ex`. Correct path; `put_flash(:error, Copy.charge_not_found())` present. `charge_not_found/0` exists in `copy.ex` line 449.
- **WR-02 (not-found Copy keys):** `Copy.invoice_not_found()` delegates to `Invoice.invoice_not_found/0` (copy/invoice.ex line 212). `Copy.connect_account_not_found()` delegates to `Connect.connect_account_not_found/0` (copy/connect.ex line 214). `Copy.coupon_not_found()` delegates to `Coupon.coupon_not_found/0` (copy/coupon.ex line 111). All three delegate chains in `copy.ex` are present (lines 158, 357, 211). Fix is complete.
- **WR-03 (coupon format_minor → format_money):** `format_minor/2` at coupon_live.ex lines 200-206 calls `Accrue.Invoices.Render.format_money(amount_minor, normalize_currency(currency), Accrue.Config.default_locale())`. Signature matches `@spec format_money(integer(), atom(), String.t())`. `normalize_currency/1` correctly handles atom passthrough, binary downcasing with `String.to_existing_atom/1` rescue to `:usd`, and nil/other fallback to `:usd`. Zero-decimal currencies such as `:jpy` are registered atoms (confirmed in `accrue/lib/accrue/test/generators.ex`) and resolve correctly through this path. Fix is sound.

One pre-existing Info item is recorded below. The two intentionally deferred Info items from iteration 1 (IN-01 label-for, IN-02 maybe_decimal over-broad rescue) are not re-flagged.

## Structural Findings (fallow)

No structural pre-pass was provided for this iteration.

## Narrative Findings (AI reviewer)

### IN-01: Unhandled `with` else branch in `confirm_replay` (pre-existing)

**File:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex:79`
**Issue:** The `with {:ok, ^webhook} <- Webhooks.detail(...)` pin match will fall through to the `else` block when the re-fetched row's fields differ from the in-memory `webhook` assign (e.g., if the row was updated between page-load and the operator clicking Confirm). The `else` block handles `:not_found`, `{:ambiguous, _}`, and `{:error, reason}` but has no clause for `{:ok, _stale_webhook}`. An unmatched `else` value raises `WithClauseError`, crashing the LiveView process for that operator session.

This is pre-existing and was not introduced by any iteration-1 fix. The window of divergence is narrow (webhook rows are rarely mutated in flight), so this is Info severity rather than Warning.

**Fix:** Add a catch-all else arm:
```elixir
{:ok, _stale} ->
  {:noreply,
   socket
   |> assign(:pending_replay, false)
   |> push_flash(:warning, Copy.Locked.replay_blocked())}
```

---

_Reviewed: 2026-06-04_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
