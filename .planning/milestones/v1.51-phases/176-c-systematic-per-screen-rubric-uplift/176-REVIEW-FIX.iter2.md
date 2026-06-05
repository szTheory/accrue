---
phase: 176-c-systematic-per-screen-rubric-uplift
fixed_at: 2026-06-04T13:00:00Z
review_path: .planning/phases/176-c-systematic-per-screen-rubric-uplift/176-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 176: Code Review Fix Report

**Fixed at:** 2026-06-04T13:00:00Z
**Source review:** .planning/phases/176-c-systematic-per-screen-rubric-uplift/176-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (1 Critical + 3 Warning)
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: `safe_utf8/1` passes error tuple to `Jason.decode/1` for invalid UTF-8

**Files modified:** `accrue_admin/lib/accrue_admin/live/webhook_live.ex`, `accrue_admin/test/accrue_admin/live/webhook_live_test.exs`
**Commit:** 58a9c2a2
**Applied fix:** Replaced the unconditional `{:ok, :unicode.characters_to_binary(raw_body)}` wrap with a `case` that pattern-matches `is_binary(text)` to return `{:ok, text}` and falls through to `:error` for the `{:error, ..., ...}` and incomplete-sequence return values from `:unicode.characters_to_binary/1`. The `rescue ArgumentError` branch is retained. Added a test that inserts a webhook with `<<0xFF, 0xFE, 0x41, 0x42>>` as `raw_body` (valid Erlang binary, illegal UTF-8) and asserts the page renders without crashing by falling back to the `:data` field.

---

### WR-01: `ChargeLive` not-found redirect targets legacy `/charges` path

**Files modified:** `accrue_admin/lib/accrue_admin/live/charge_live.ex`
**Commit:** 0321503f
**Applied fix:** Changed `admin_path(admin, "/charges")` to `admin_path(admin, "/payments")` on the nil-charge not-found branch in `mount/3`. This eliminates the double redirect hop through `RedirectController` and makes the path consistent with `assign_shell`'s `:current_path` of `/payments`.

---

### WR-02: Inconsistent `put_flash` coverage on not-found redirects

**Files modified:** `accrue_admin/lib/accrue_admin/copy.ex`, `accrue_admin/lib/accrue_admin/copy/invoice.ex`, `accrue_admin/lib/accrue_admin/copy/connect.ex`, `accrue_admin/lib/accrue_admin/live/invoice_live.ex`, `accrue_admin/lib/accrue_admin/live/charge_live.ex`, `accrue_admin/lib/accrue_admin/live/connect_account_live.ex`
**Commit:** 6e3ac82f
**Applied fix:**
- Added `invoice_not_found/0` to `AccrueAdmin.Copy.Invoice` and a `defdelegate` in `AccrueAdmin.Copy`.
- Added `charge_not_found/0` inline in `AccrueAdmin.Copy` (near the other inline charge copy strings).
- Added `connect_account_not_found/0` to `AccrueAdmin.Copy.Connect` and a `defdelegate` in `AccrueAdmin.Copy`.
- Added `alias AccrueAdmin.Copy` to `ConnectAccountLive` (it was missing; the other two already had it).
- Wrapped all three nil-not-found `redirect` returns in a pipe: `socket |> put_flash(:error, Copy.<not_found_fn>()) |> redirect(to: ...)`.

---

### WR-03: `format_minor/2` uses floating-point division for money display

**Files modified:** `accrue_admin/lib/accrue_admin/live/coupon_live.ex`
**Commit:** 615efc0b
**Applied fix:** Replaced the `amount_minor / 100` float division + `:erlang.float_to_binary/2` implementation with a call to `Accrue.Invoices.Render.format_money/3` (same helper used by `ChargeLive.money_text/2` and `InvoiceLive`). Added the `normalize_currency/1` helper (identical to the one in `charge_live.ex`) so the atom/binary/fallback currency normalization is available locally. This correctly handles zero-decimal currencies (JPY/KRW: 500 minor units → "500 JPY" not "5.00 JPY") and eliminates IEEE 754 float imprecision.

---

## Skipped Issues

None — all in-scope findings were fixed.

---

_Fixed: 2026-06-04T13:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
