# Phase 157: Metered Usage Adopter Proof - Research

**Researched:** 2026-05-31
**Status:** Ready for planning
**Phase:** 157 - Metered Usage Adopter Proof

## Research Question

What does the executor need to know to plan Phase 157 well?

## Findings

### Existing adopter proof is the right target

`examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` already contains the metered usage host proof. It starts the Fake processor, resets processor state, removes prior fake billing rows, creates an organization, opens `/app/billing`, clicks `"Simulate API Call"`, asserts the success flash, and inspects `Accrue.Billing.MeterEvent`.

The current gap is narrow:

- The test subscribes the organization to `"price_basic"`, not the configured metered price.
- It asserts exactly one `MeterEvent` row and `event.event_name == "api_calls"`.
- It does not assert `event.value == 1`.

The plan should update this test in place rather than create a second proof surface.

### Metered plan identifier already exists

`examples/accrue_host/lib/accrue_host/billing/plans.ex` exposes `AccrueHost.Billing.Plans.ids().metered` as `"price_metered"`. The source also includes the metered plan in `Plans.all/0`.

Using `Plans.ids().metered` in the test is preferable to repeating the literal `"price_metered"` because it ties the proof to the same host-facing plan registry the billing LiveView renders.

### Hybrid setup is the least brittle proof

The existing host test pattern sets up billing preconditions through `AccrueHost.Billing.subscribe/3` and then exercises the LiveView route for the user-visible behavior. That fits the Phase 157 context decisions:

- Use host facade setup for the subscription precondition.
- Keep the visible LiveView click path for `"Simulate API Call"`.
- Avoid forcing tax-location and plan-selection UI choreography into this phase.
- Avoid direct DB inserts for customer, subscription, or subscription item setup.

`examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs` already proves full start/cancel UI choreography for `price_basic`; Phase 157 should not duplicate that coverage.

### `value:` is the public metering option

`accrue/lib/accrue/billing/meter_event_actions.ex` defines the usage schema as:

- `value: [type: :non_neg_integer, default: 1]`
- no `quantity:` option

`examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` currently calls:

`Billing.report_usage_for_scope(socket.assigns.current_scope, "api_calls", value: 1)`

That is the adopter-copyable callsite. The required inline comment belongs immediately adjacent to this call, not in a broad tutorial section. The comment should plainly distinguish metered event `value:` from subscription/invoice line-item `quantity:`.

### Row assertion should stay shallow but real

`accrue/lib/accrue/billing/meter_event.ex` persists `event_name` and `value` on the durable `accrue_meter_events` row. Phase 157 only needs to prove the example host path records one row with the expected event name and value.

Do not duplicate deeper core metering coverage from `accrue/test/accrue/billing/meter_event_actions_test.exs`, which already covers reporting status, idempotency, backdating, telemetry failure behavior, ledger recording, and value forwarding.

## Validation Architecture

Phase 157 is test-centered and should use existing ExUnit infrastructure.

| Validation Target | Command | Expected Proof |
|---|---|---|
| Focused host LiveView proof | `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs --seed 0` | The metered usage test subscribes to the metered plan, clicks the button, sees the flash, and asserts one row with `event_name == "api_calls"` and `value == 1`. |
| Source footgun comment | `rg "value:.*quantity|quantity:.*value" examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | The adopter-copyable callsite contains an inline comment explaining `value:` vs `quantity:`. |

## Security Notes

This phase does not introduce new authorization, routes, schemas, or processor behavior. The relevant security property is preserving the existing `Billing.report_usage_for_scope/3` authorization path: the LiveView event must continue to use `socket.assigns.current_scope` and the host billing facade so organization admin/owner checks remain in force.

## Pitfalls

- Do not switch the test to direct `Repo.insert` setup for customer/subscription rows.
- Do not replace the LiveView click with a core-only `Billing.report_usage/3` call.
- Do not broaden the test into idempotency, telemetry, ledger, or reconciliation coverage.
- Do not place the `value:` explanation only in docs; the success criterion requires an inline comment at the example callsite.

## RESEARCH COMPLETE
