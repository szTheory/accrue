# Phase 157: Metered Usage Adopter Proof - Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` | test | request-response | same file | exact |
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | LiveView | request-response | same file | exact |

## Pattern Assignments

### `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs`

**Current setup pattern:**

- `use AccrueHostWeb.ConnCase, async: false`
- Start or reuse `Accrue.Processor.Fake`
- `Accrue.Processor.Fake.reset()`
- `cleanup_fake_billing_rows!()`
- Create user and organization fixtures

**Current metered proof pattern:**

- `Billing.subscribe(organization, "price_basic")`
- `live(~p"/app/billing")`
- Assert `"Metered Usage Demo"` and `"Simulate API Call"`
- `element("button", "Simulate API Call") |> render_click()`
- Assert `"Usage reported: 1 API call recorded."`
- Assert one `MeterEvent` row
- Assert `event.event_name == "api_calls"`

**Phase 157 target pattern:**

- Add `alias AccrueHost.Billing.Plans`
- Replace `"price_basic"` with `Plans.ids().metered`
- Keep the LiveView click path unchanged
- Add `assert event.value == 1`

### `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`

**Current usage callsite:**

`Billing.report_usage_for_scope(socket.assigns.current_scope, "api_calls", value: 1)`

**Phase 157 target pattern:**

- Keep the call through `Billing.report_usage_for_scope/3`
- Keep `socket.assigns.current_scope`
- Keep `event_name` as `"api_calls"`
- Keep `value: 1`
- Add one short inline comment immediately above the call explaining that metered usage uses `value:`, while subscription/invoice line-item quantities use `quantity:`

## Related Source Truth

### `examples/accrue_host/lib/accrue_host/billing/plans.ex`

`Plans.ids().metered` returns `"price_metered"` and `Plans.all/0` includes the metered plan rendered by the billing LiveView.

### `examples/accrue_host/lib/accrue_host/billing.ex`

`report_usage_for_scope/3` resolves the active organization to a customer, enforces billing mutation authorization, then delegates to `Accrue.Billing.report_usage/3`.

### `accrue/lib/accrue/billing/meter_event_actions.ex`

`@report_usage_schema` accepts `value:` and does not define `quantity:`.

### `accrue/lib/accrue/billing/meter_event.ex`

`MeterEvent` persists `event_name` and `value`, which are the right shallow row-shape assertions for this adopter proof.
