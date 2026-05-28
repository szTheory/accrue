---
phase: 145-time-window-url-plumbing-window-selector
fixed_at: 2026-05-27T21:24:45Z
review_path: .planning/phases/145-time-window-url-plumbing-window-selector/145-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 145: Code Review Fix Report

**Fixed at:** 2026-05-27T21:24:45Z
**Source review:** .planning/phases/145-time-window-url-plumbing-window-selector/145-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: `assign_shell/2` overwrites `AuthHook`'s `active_organization_name` with `nil`

**Files modified:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`
**Commit:** 3698f84a
**Applied fix:** Removed the stale `|> assign(:active_organization_name, admin["active_organization_name"])` line from `assign_shell/2`. The `"accrue_admin"` session sub-map never contains this key, so the assign always wrote `nil`, silently blanking the org banner that `AuthHook.on_mount/4` had correctly set. Removing the line preserves the AuthHook value intact, consistent with all other admin LiveViews.

---

### CR-02: `window_bounds/1` calls `DateTime.utc_now/0` twice, producing an inconsistent time range

**Files modified:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`
**Commit:** 29ae5067
**Applied fix:** In all three `window_bounds` clauses (`"7d"`, `"30d"`, `"90d"`), captured `DateTime.utc_now()` into a `now` variable once, then derived both `since` (via `DateTime.add(now, ...)`) and the returned `until` from that single snapshot. This eliminates the microsecond-to-millisecond drift between the two bounds and prevents future refactors from accidentally calling `window_bounds` twice with diverging windows.

---

### WR-01: `window_selector` concatenates `base_path` unsafely — no guard against existing query params

**Files modified:** `accrue_admin/lib/accrue_admin/components/window_selector.ex`
**Commit:** 6ca402fb
**Applied fix:** Replaced the raw `@base_path <> "?window=" <> value` string concatenation in the template with a call to a new private `window_href/2` helper. The helper uses `URI.parse/1` + `Map.put(:query, URI.encode_query(...))` + `URI.to_string/1` to safely replace any existing `?window=` param (or append a fresh one) without producing a double-`?` URL. Updated the `@moduledoc` to reflect that `base_path` may now carry existing query params safely.

---

### WR-02: Window-active test assertions in `recovery_live_test` are too coarse

**Files modified:** `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs`
**Commit:** e4fd4101
**Applied fix:** Added a private `active_window_label/1` helper that uses a regex to extract the trimmed text content of the `<a>` element carrying `aria-current="page"`. Replaced all five coarse `assert html =~ ~s(aria-current="page")` assertions in the `"window parameter (DAN-10)"` describe block with targeted `assert active_window_label(html) =~ "N days"` assertions that verify the *correct* button is active, not merely that *some* button is active.

---

### WR-03: `Events.record/1` return values are unchecked in test setup blocks

**Files modified:** `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs`
**Commit:** b4306477
**Applied fix:** Pattern-matched all six `Events.record/1` calls across three locations — the module-level `setup` block (2 calls), the `"renders funnel chart"` test body (3 calls), and the `"JPY rendering"` nested `setup` block (1 call) — with `{:ok, _} = Events.record(...)`. A data-setup failure now surfaces immediately as a `MatchError` pointing at the exact failing call rather than causing confusing downstream assertion failures.

---

## Skipped Issues

None — all findings were fixed.

---

_Fixed: 2026-05-27T21:24:45Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
