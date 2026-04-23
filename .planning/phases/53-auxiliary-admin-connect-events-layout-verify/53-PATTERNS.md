# Phase 53 — Pattern map

**Sources:** `53-CONTEXT.md`, `53-RESEARCH.md`, `53-UI-SPEC.md`

## Copy facade + delegate

**Analog:** `accrue_admin/lib/accrue_admin/copy.ex` (lines delegating to `Coupon`, `PromotionCode`, `Subscription`).

**Pattern:** `alias AccrueAdmin.Copy.Connect` + `defdelegate connect_accounts_page_title_index(), to: Connect` (example shape — exact function names follow CONTEXT D-10).

## Copy implementation module

**Analog:** `accrue_admin/lib/accrue_admin/copy/coupon.ex` — `@moduledoc false`, pure functions returning operator strings.

## LiveView consuming Copy

**Analog:** `accrue_admin/lib/accrue_admin/live/coupons_live.ex` — `AccrueAdmin.Copy.coupon_*` in HEEx attributes and text nodes.

## Playwright + axe + copyStrings

**Analog:** `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` — `readFixture`, `login`, `waitForLiveView`, `copyStrings.*`, `scanAxe`, mobile skip comment.

## Export allowlist

**Analog:** `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` — `@allowlist ~w(...)a` must list every exported 0-arity `AccrueAdmin.Copy` function used in JSON.

## Path inventory doc

**Analog:** `examples/accrue_host/docs/verify01-v112-admin-paths.md` — numbered list of mounted paths; extend with v1.13 auxiliary rows + AUX requirement mapping.

## Theme exceptions

**Analog:** `accrue_admin/guides/theme-exceptions.md` — table: slug, location, deviation, rationale, future_token, status, phase_ref.

## PATTERN MAPPING COMPLETE
