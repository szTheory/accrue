# Phase 156: Entitlements Gating Adopter Proof - Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue/lib/accrue/entitlements/guard.ex` | service | request-response | `accrue/lib/accrue/entitlements/guard.ex` | exact |
| `examples/accrue_host/config/config.exs` | config | transform | `examples/accrue_host/config/config.exs` | exact |
| `examples/accrue_host/lib/accrue_host_web/router.ex` | route | request-response | `examples/accrue_host/lib/accrue_host_web/router.ex` | exact |
| `examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` | test | request-response | `examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` | exact |
| `accrue/test/accrue/entitlements/guard_test.exs` (optional support test) | test | request-response | `accrue/test/accrue/entitlements/guard_test.exs` | exact |
| `accrue/guides/entitlements.md` (optional canonical recipe update) | config | transform | `accrue/guides/entitlements.md` | exact |
| `examples/accrue_host/docs/adoption-proof-matrix.md` (optional proof-matrix note) | config | transform | `examples/accrue_host/docs/adoption-proof-matrix.md` | exact |

## Pattern Assignments

### `accrue/lib/accrue/entitlements/guard.ex` (service, request-response)

**Analog:** `accrue/lib/accrue/entitlements/guard.ex`

**Imports/alias pattern** (lines 104-106):
```elixir
:feature -> Accrue.Entitlements.entitled?(billable, required, surface: surface)
:plan -> Accrue.Entitlements.has_active_plan?(billable, required, surface: surface)
```

**Core guard decision pattern** (lines 98-120):
```elixir
{kind, required} = guard_target!(opts)
{billable, container} = resolve_once(surface, container, opts)

allowed? =
  case kind do
    :feature -> Accrue.Entitlements.entitled?(billable, required, surface: surface)
    :plan -> Accrue.Entitlements.has_active_plan?(billable, required, surface: surface)
  end

if allowed? do
  {:allow, container}
else
  ctx = %{guard: kind, required: required, reason: deny_reason(billable), billable: billable, surface: surface}
  {:deny, resolve_on_deny(opts), ctx}
end
```

**Fail-closed error handling pattern** (lines 276-285):
```elixir
defp safe_apply(fun, container) do
  fun.(container)
rescue
  _ -> nil
catch
  _ -> nil
  _, _ -> nil
end
```

**Billable probe pattern** (lines 289-293):
```elixir
case Map.get(assigns, :current_scope) do
  %{user: user} when not is_nil(user) -> user
  _ -> Map.get(assigns, :current_user)
end
```

**Implementation note for Phase 156:** there is no existing `%Ecto.Association.NotLoaded{}` branch in this file today; add normalization in this same fail-closed resolution seam (not in LiveView surface).

---

### `examples/accrue_host/config/config.exs` (config, transform)

**Analog:** `examples/accrue_host/config/config.exs`

**Entitlements resolver pattern** (lines 107-116):
```elixir
config :accrue, :entitlements,
  billable: fn container ->
    scope = Map.get(container.assigns, :current_scope)

    if scope do
      Map.get(scope, :active_organization) || Map.get(scope, :user)
    else
      Map.get(container.assigns, :current_user)
    end
  end
```

**Pattern to preserve:** resolver remains a single `billable` function over container assigns; add explicit unloaded-association handling in this function while keeping fallback order intact.

---

### `examples/accrue_host/lib/accrue_host_web/router.ex` (route, request-response)

**Analog:** `examples/accrue_host/lib/accrue_host_web/router.ex`

**`live_session` ordering pattern** (lines 50-56):
```elixir
live_session :entitled_reports,
  on_mount: [
    {AccrueHostWeb.UserAuth, :require_authenticated},
    {Accrue.Live.Entitlements, {:require_feature, :advanced_reports}}
  ] do
  live("/app/reports/advanced", AdvancedReportsLive, :index)
end
```

**Comment placement pattern:** add concise contract comment directly above this block (same local style as nearby router comments at lines 29-34 and 97-99).

---

### `examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` (test, request-response)

**Analog:** `examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs`

**Imports/setup pattern** (lines 2-7):
```elixir
use AccrueHost.HostFlowProofCase, async: false
import Phoenix.LiveViewTest
alias AccrueHost.Billing
```

**Route-level allow proof pattern** (lines 8-23):
```elixir
{:ok, _view, html} = live(conn, "/app/reports/advanced")
assert html =~ "Advanced Reports"
```

**Route-level deny proof pattern** (lines 37-43):
```elixir
result = live(conn, "/app/reports/advanced")
assert {:error, {:redirect, %{to: "/", flash: %{"error" => "You don't have access to this page."}}}} = result
```

**Phase 156 regression shape:** add one more test in this module using same `live(conn, "/app/reports/advanced")` assertion style, but with unloaded billable state to prove redirect/halt instead of raise.

---

### `accrue/test/accrue/entitlements/guard_test.exs` (optional support test, request-response)

**Analog:** `accrue/test/accrue/entitlements/guard_test.exs`

**Fail-closed assertion pattern** (lines 165-183):
```elixir
assert {:deny, _form, ctx} =
         Guard.check(:plug, conn, feature: :reports, billable: fn _ -> nil end)

assert ctx.surface == :plug
```

**Pattern use:** only add a small unit test here if guard helper extraction needs direct coverage; keep host regression as primary proof.

---

### `accrue/guides/entitlements.md` (optional canonical doc update, transform)

**Analog:** `accrue/guides/entitlements.md`

**Canonical ordering recipe pattern** (lines 153-162):
```elixir
live_session :paid,
  on_mount: [
    MyAppWeb.UserAuth,
    {Accrue.Live.Entitlements, {:require_feature, :reports}}
  ] do
  live "/reports", ReportsLive
end
```

**Pattern use:** if Phase 156 updates docs, keep long-form ordering guidance here, not in router comment.

---

### `examples/accrue_host/docs/adoption-proof-matrix.md` (optional proof note, transform)

**Analog:** `examples/accrue_host/docs/adoption-proof-matrix.md`

**Matrix-row pattern** (line 29):
```markdown
| Entitlement gating (`Accrue.Live.Entitlements`) | Gated `/app/reports/advanced` with `{:require_feature, :advanced_reports}` ; `entitlements_guard_test.exs` | `examples/accrue_host` router + `Accrue.Config.entitlements()` configuration |
```

**Pattern use:** if touched, keep proof claims concise and tied to concrete test/module names.

## Shared Patterns

### Authentication-before-authorization ordering
**Source:** `examples/accrue_host/lib/accrue_host_web/router.ex` lines 50-54 and `examples/accrue_host/lib/accrue_host_web/user_auth.ex` lines 243-247.
**Apply to:** `live_session` entitlement-gated routes.
```elixir
on_mount: [
  {AccrueHostWeb.UserAuth, :require_authenticated},
  {Accrue.Live.Entitlements, {:require_feature, :advanced_reports}}
]
```

### Fail-closed billable resolution
**Source:** `accrue/lib/accrue/entitlements/guard.ex` lines 276-285 and 289-293.
**Apply to:** guard billable normalization and host resolver fallback behavior.
```elixir
defp safe_apply(fun, container) do
  fun.(container)
rescue
  _ -> nil
catch
  _ -> nil
  _, _ -> nil
end
```

### Deny response semantics (generic/opaque)
**Source:** `accrue/lib/accrue/live/entitlements.ex` lines 140-143 and host regression assertions in `examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` lines 37-43.
**Apply to:** host-facing deny behavior in regression tests.
```elixir
socket
|> put_flash(:error, @deny_flash)
|> redirect(to: Accrue.Entitlements.Guard.deny_path())
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `%Ecto.Association.NotLoaded{}` normalization branch (new code inside guard/config resolver) | service/config | transform | No existing NotLoaded handling in entitlement path (`rg "Association.NotLoaded"` has no guard/resolver matches). |

## Metadata

**Analog search scope:** `accrue/lib`, `accrue/test`, `accrue/guides`, `examples/accrue_host/lib`, `examples/accrue_host/test`, `examples/accrue_host/config`, `examples/accrue_host/docs`  
**Files scanned:** 10  
**Pattern extraction date:** 2026-05-31
