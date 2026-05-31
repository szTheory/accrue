---
phase: 157
slug: metered-usage-adopter-proof
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-31
---

# Phase 157 - Security

Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser to `/app/billing` LiveView | The visible host billing surface receives the `Simulate API Call` event from an authenticated user session. | LiveView event and active organization scope |
| Example host facade to Accrue core billing | `AccrueHost.Billing.report_usage_for_scope/3` resolves the active organization and checks billing mutation authorization before delegating to core metering. | Customer identity, meter event name, and usage value |
| Test fixture setup to billing persistence | The adopter proof creates the subscription precondition through the host facade, then verifies durable `MeterEvent` persistence. | Subscription rows, subscription item rows, and meter event rows |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-157-01 | Elevation of privilege | `SubscriptionLive.handle_event("simulate_api_call", ...)` | mitigate | Usage reporting still calls `Billing.report_usage_for_scope(socket.assigns.current_scope, "api_calls", value: 1)`, which resolves the scoped customer and enforces `authorize_billing_mutation/1` before delegating to core billing. | closed |
| T-157-02 | Tampering | Copyable host usage callsite | mitigate | The usage call has an adjacent comment: meter events use `value:`, while `quantity:` belongs to subscription/invoice line items. The focused test also asserts the persisted meter-event `value == 1`. | closed |
| T-157-03 | Tampering | `SubscriptionLiveTest` metered usage proof setup | mitigate | The proof subscribes through `AccrueHost.Billing.subscribe/3` with `Plans.ids().metered`, clicks the visible LiveView button, and asserts exactly one persisted `MeterEvent` with `event_name == "api_calls"` and `value == 1`. | closed |

## Evidence

| Threat ID | Evidence |
|-----------|----------|
| T-157-01 | `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` keeps usage reporting on `Billing.report_usage_for_scope/3`; `examples/accrue_host/lib/accrue_host/billing.ex` checks `customer_for_scope/1` and `authorize_billing_mutation/1`. |
| T-157-02 | `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` contains the adjacent `value:` versus `quantity:` comment; `rg "value:.*quantity|quantity:.*value" examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` matched it. |
| T-157-03 | `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` uses `Billing.subscribe(organization, Plans.ids().metered)`, `element("button", "Simulate API Call") |> render_click()`, `Repo.aggregate(MeterEvent, :count, :id) == 1`, `event.event_name == "api_calls"`, and `event.value == 1`. |

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-31 | 3 | 3 | 0 | Codex |

## Verification

| Command | Result |
|---------|--------|
| `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs --seed 0` | Passed: 7 tests, 0 failures |
| `rg "value:.*quantity|quantity:.*value" examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | Passed: found adjacent callsite comment |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-31
