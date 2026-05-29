---
phase: 145-time-window-url-plumbing-window-selector
reviewed: 2026-05-27T21:09:47Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - accrue_admin/lib/accrue_admin/components/window_selector.ex
  - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
  - accrue_admin/test/accrue_admin/components/navigation_components_test.exs
  - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
findings:
  critical: 2
  warning: 3
  info: 0
  total: 5
status: issues_found
---

# Phase 145: Code Review Report

**Reviewed:** 2026-05-27T21:09:47Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

The WindowSelector component itself is correct and compact. The failures live in
`RecoveryLive` and its test suite. Two blockers: `assign_shell/2` silently wipes the
`active_organization_name` that `AuthHook` placed on the socket, and `window_bounds/1`
calls `DateTime.utc_now/0` twice per clause, producing a subtly inconsistent time range.
Three warnings cover the fragile `base_path` string concatenation in the component, and
two weaknesses in the recovery live test where window-active assertions do not verify
*which* button carries `aria-current="page"`.

---

## Critical Issues

### CR-01: `assign_shell/2` overwrites `AuthHook`'s `active_organization_name` with `nil`

**File:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:120`

**Issue:** `AuthHook.on_mount/4` runs *before* `mount/3` in the LiveView lifecycle and
assigns `:active_organization_name` via `OwnerScope.active_organization_banner_name/1`.
`assign_shell/2`, called from `mount/3`, then overwrites that value with
`admin["active_organization_name"]`, where `admin` is the `"accrue_admin"` session
sub-map.

That sub-map (built by `AccrueAdmin.Router.__session__/3`, lines 133–143 of
`router.ex`) does **not** include an `"active_organization_name"` key — it stores
`"brand"`, `"theme"`, `"csp_nonce"`, `"mount_path"`, and the three asset paths. As a
result, `admin["active_organization_name"]` is always `nil`, and the organisation banner
in the AppShell shell chrome is permanently blank for RecoveryLive in org-scoped mode.

Every other admin LiveView (e.g. `SubscriptionsLive`, `CustomerLive`) does **not**
re-assign `:active_organization_name` in `assign_shell`, leaving the AuthHook value
intact. `RecoveryLive` is the only divergent implementation.

**Fix:** Remove the stale assign from `assign_shell/2`:

```elixir
# Before (recovery_live.ex assign_shell/2)
defp assign_shell(socket, admin) do
  socket
  |> assign(:page_title, "Recovery Dashboard")
  |> assign(:brand, admin["brand"] || default_brand())
  |> assign(:theme, admin["theme"] || "system")
  |> assign(:csp_nonce, admin["csp_nonce"])
  |> assign(:brand_css_path, admin["brand_css_path"])
  |> assign(:assets_css_path, admin["assets_css_path"])
  |> assign(:assets_js_path, admin["assets_js_path"])
  |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
  |> assign(:current_path, (admin["mount_path"] || "/billing") <> "/analytics/recovery")
  |> assign(:active_organization_name, admin["active_organization_name"])  # <-- DELETE THIS LINE
end

# After
defp assign_shell(socket, admin) do
  socket
  |> assign(:page_title, "Recovery Dashboard")
  |> assign(:brand, admin["brand"] || default_brand())
  |> assign(:theme, admin["theme"] || "system")
  |> assign(:csp_nonce, admin["csp_nonce"])
  |> assign(:brand_css_path, admin["brand_css_path"])
  |> assign(:assets_css_path, admin["assets_css_path"])
  |> assign(:assets_js_path, admin["assets_js_path"])
  |> assign(:admin_mount_path, admin["mount_path"] || "/billing")
  |> assign(:current_path, (admin["mount_path"] || "/billing") <> "/analytics/recovery")
end
```

---

### CR-02: `window_bounds/1` calls `DateTime.utc_now/0` twice, producing an inconsistent time range

**File:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:94-107`

**Issue:** Each `window_bounds` clause calls `DateTime.utc_now/0` independently for
`since` and for `until`:

```elixir
defp window_bounds("7d") do
  since = DateTime.add(DateTime.utc_now(), -7 * 86_400, :second)  # call 1
  {since, DateTime.utc_now()}                                       # call 2
end
```

The two calls are separated by at least the cost of `DateTime.add/3`. Under normal load
this is microseconds. Under a loaded scheduler or a preempted BEAM process it can be
milliseconds. This means:

1. `until` is always slightly later than `since + 7 days`, so the window is
   microseconds-to-milliseconds *wider* than declared. Events inserted between the two
   `utc_now()` calls are included in the `since` computation but not the `until`
   bound — a narrow but real inconsistency.
2. More critically: `Dunning.recovered_vs_lost_mrr/1` and `Dunning.funnel/1` are called
   with the *same* `{since, until}` tuple. Because the tuple is produced by a single
   `window_bounds/1` call, both queries share the same bounds — but if `handle_params`
   is ever refactored to call `window_bounds` twice (once per query), the two DB queries
   would operate over *different* windows, breaking the funnel-vs-MRR alignment.
   Capturing `utc_now()` once eliminates this class of future bug entirely.

**Fix:** Capture `DateTime.utc_now/0` once and derive both bounds from it:

```elixir
defp window_bounds("7d") do
  now = DateTime.utc_now()
  since = DateTime.add(now, -7 * 86_400, :second)
  {since, now}
end

defp window_bounds("30d") do
  now = DateTime.utc_now()
  since = DateTime.add(now, -30 * 86_400, :second)
  {since, now}
end

defp window_bounds("90d") do
  now = DateTime.utc_now()
  since = DateTime.add(now, -90 * 86_400, :second)
  {since, now}
end
```

---

## Warnings

### WR-01: `window_selector` concatenates `base_path` unsafely — no guard against existing query params

**File:** `accrue_admin/lib/accrue_admin/components/window_selector.ex:31`

**Issue:** The component builds patch URLs via raw string concatenation:

```elixir
patch={@base_path <> "?window=" <> value}
```

The `@moduledoc` warns that `base_path` must have no existing query params, but the
component enforces nothing at runtime. If a caller passes
`"/billing/analytics/recovery?foo=bar"` the generated URL becomes
`"/billing/analytics/recovery?foo=bar?window=7d"` — an invalid URL with two `?`
characters. Phoenix router will silently discard everything after the second `?`,
causing `handle_params` to see an empty `"window"` param and fall back to the `"30d"`
default regardless of which button the user clicked.

This is not triggered by `RecoveryLive` today (which passes a clean static path), but
any future caller that passes a path with an existing query string will silently
misbehave.

**Fix:** Use `URI` to assemble the URL safely:

```elixir
patch={URI.to_string(%URI{URI.parse(@base_path) | query: "window=#{value}"})}
```

Or equivalently, in a function component helper:

```elixir
defp window_href(base_path, value) do
  base_path
  |> URI.parse()
  |> Map.put(:query, URI.encode_query(%{"window" => value}))
  |> URI.to_string()
end
```

Then use `patch={window_href(@base_path, value)}` in the template. This also correctly
*replaces* any existing `?window=` param rather than appending a second one.

---

### WR-02: Window-active test assertions in `recovery_live_test` are too coarse

**File:** `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:179-207`

**Issue:** Four tests in the `"window parameter (DAN-10)"` describe block assert that
`aria-current="page"` *exists* in the rendered HTML, but none verify that it appears on
the *correct* button. For example:

```elixir
test "?window=7d renders 7d button as active", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery?window=7d")
  assert html =~ "7 days UTC"              # true — all 3 buttons render text with "days UTC"
  assert html =~ ~s(aria-current="page")   # true — one button always has it
end
```

A bug that applied `aria-current="page"` to the 30-day button when `?window=7d` is
requested would pass both assertions. The same weakness affects the 90d and invalid
fallback tests.

**Fix:** Assert that the specific button text and the `aria-current` marker appear
together. One approach is to extract a small helper that parses the active button:

```elixir
defp active_window_label(html) do
  # Matches the link element that has aria-current="page" and extracts its text content.
  # Works as long as the label text is on the same element as aria-current.
  ~r/aria-current="page"[^>]*>([^<]+)</
  |> Regex.run(html, capture: :all_but_first)
  |> List.first()
  |> String.trim()
end

test "?window=7d renders 7d button as active", %{conn: conn} do
  conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
  {:ok, _view, html} = live(conn, "/billing/analytics/recovery?window=7d")
  assert active_window_label(html) =~ "7 days"
end
```

Alternatively, add a targeted count check similar to the unit-test approach already
used in `navigation_components_test.exs:206`.

---

### WR-03: `Events.record/1` return values are unchecked in test setup blocks

**File:** `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:32-51, 79-98, 140-149`

**Issue:** All `Events.record/1` calls in the module-level `setup` block and in the two
nested `setup` blocks are fire-and-forget:

```elixir
Events.record(%{type: "dunning.recovered", ...})
Events.record(%{type: "dunning.exhausted", ...})
```

`Events.record/1` returns `{:ok, event}` or `{:error, changeset}`. If an insertion
fails (schema validation failure, DB constraint violation, missing required field), the
`setup` block returns `:ok` and the tests continue with no seeded data. The subsequent
assertions then fail with confusing messages like `"expected to find '$50.00' in ..."`
rather than `"Events.record failed: ..."`.

**Fix:** Pattern-match the return value in setup:

```elixir
{:ok, _} = Events.record(%{
  type: "dunning.recovered",
  subject_type: "Subscription",
  subject_id: "sub_123",
  data: %{mrr_value_cents: 5000, currency: "usd"}
})
```

This converts a silent data-setup failure into a clear `MatchError` pointing at the
exact failing call.

---

_Reviewed: 2026-05-27T21:09:47Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
