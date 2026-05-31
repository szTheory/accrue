# Phase 157: Metered Usage Adopter Proof - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the checked-in `examples/accrue_host` metered usage proof match the adopter story promised by PRF-02: a developer can read and run a host-level test that subscribes an organization to the metered plan, triggers the visible "Simulate API Call" action, sees the success flash, and verifies exactly one durable `MeterEvent` row was recorded.

- **In scope:** update the existing `examples/accrue_host` metered usage LiveView proof to use the metered price, keep the user-visible LiveView click path, assert the resulting meter event row, and add the inline `value:` vs `quantity:` callsite comment.
- **Out of scope:** new metering APIs, new billing primitives, schema changes, new processor behavior, a broad metering guide rewrite, telemetry/ledger assertions beyond the adopter proof, and full browser choreography for every subscription setup prerequisite.

</domain>

<decisions>
## Implementation Decisions

### E2E proof shape
- **D-01:** Use the existing `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` metered usage proof as the target. Do not create a parallel test surface unless the planner finds the current file structurally unsuitable.
- **D-02:** Keep the proof hybrid: establish the subscription precondition through the host billing facade/context, then exercise the adopter-visible LiveView button for `"Simulate API Call"`.
- **D-03:** Do not force the subscription precondition through the LiveView UI in this phase. The full UI path is more brittle because tax-location and selector behavior can mask the metering proof; `subscription_flow_test.exs` already covers start/cancel UI choreography for the billing screen.
- **D-04:** Do not reduce this to a core-only metering test. PRF-02 is explicitly about `examples/accrue_host` adopter proof and must exercise the host route/flash path.

### Metered setup
- **D-05:** Subscribe the example organization to `price_metered` (preferably via `AccrueHost.Billing.subscribe/3` or the smallest existing host facade path) before opening `/app/billing`.
- **D-06:** Keep setup deterministic under the existing Fake processor reset and `async: false` test posture. Avoid direct schema inserts for customer/subscription/subscription-item setup because those bypass public facade behavior and are easier to drift from real adopter usage.
- **D-07:** Preserve the current route and UI affordance: `/app/billing`, the `"Metered Usage Demo"` section, and the `"Simulate API Call"` button. The phase should sharpen the existing proof, not redesign the billing page.

### MeterEvent assertion
- **D-08:** Assert the success flash/copy after clicking `"Simulate API Call"`: `"Usage reported: 1 API call recorded."`
- **D-09:** Assert exactly one `Accrue.Billing.MeterEvent` row after the isolated setup and click. The existing `cleanup_fake_billing_rows!/0` plus `async: false` makes the global one-row assertion acceptable and directly matches the success criterion.
- **D-10:** Add minimal row-shape assertions so the count is not shallow: at least `event.event_name == "api_calls"` and `event.value == 1`. Do not add telemetry, ledger, processor-wire, or idempotency deep assertions to this host proof; those belong in core billing tests such as `meter_event_actions_test.exs`.

### `value:` vs `quantity:` explanation
- **D-11:** Add the required inline comment at the adopter-copyable callsite in `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`, immediately adjacent to `Billing.report_usage_for_scope(..., value: 1)`.
- **D-12:** The comment should state the footgun plainly: metered usage submission uses `value:`; `quantity:` is for subscription/invoice line items and is not the meter-event option.
- **D-13:** Do not make this a long tutorial in the LiveView. If the planner sees a nearby ExDoc/API doc note that is stale or missing, a tiny canonical backup note is acceptable, but Phase 157 is satisfied by the inline host example comment plus executable proof.

### the agent's Discretion
- The planner may decide whether to keep the existing test name `"demonstrates metered usage reporting (PROOF-04)"` or rename it to reflect PRF-02/Phase 157, as long as the test remains discoverable as the metered usage adopter proof.
- The planner may choose a scoped query instead of `Repo.one(MeterEvent)` if that makes the test clearer, but it should not expand into a broad idempotency or telemetry contract test.

### Reviewed Todos
- **ENT-10 advisory-cache code-review follow-ups (WR-05 + INFO)** - Reviewed and not folded. It matched Phase 157 only through generic `code`/`phase`/`accrue` keywords and belongs to advisory-cache/webhook work already closed by Phases 154 and 155. Do not reopen it here.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/ROADMAP.md` §"Phase 157: Metered Usage Adopter Proof" - phase goal and success criteria.
- `.planning/REQUIREMENTS.md` §"Adopter-Proof: Metered Usage" - PRF-02 locked requirement.
- `.planning/STATE.md` §"Current Position" and §"Key Planning Decisions for v1.47" - confirms Phase 157 is independent adopter-proof closure with no new billing primitive.
- `.planning/PROJECT.md` §"Core Value" - Accrue's day-one Phoenix SaaS billing DX and adopter-proof posture.

### Prior phase context
- `.planning/phases/156-entitlements-gating-adopter-proof/156-CONTEXT.md` - closest prior adopter-proof pattern: keep proof host-level, narrow, copyable, and avoid adding new product behavior.
- `.planning/phases/155-stripefixtures-polish-telemetry-counters/155-CONTEXT.md` - reinforces least-surprise fixture/test ergonomics and avoiding broad telemetry scope creep.
- `.planning/phases/154-advisory-cache-core-correctness/154-CONTEXT.md` - confirms advisory-cache todo scope is already handled and should not leak into Phase 157.

### Prompt corpus and research posture
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - recurring maintainer preference for repo-local truth, adopter-facing proof, idiomatic Elixir/Phoenix, subagent-backed tradeoff research, DX/least-surprise, and cohesive recommendations.

### Source files
- `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` - existing metered usage proof; update here if feasible.
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` - LiveView event handler and inline `value:` comment target.
- `examples/accrue_host/lib/accrue_host/billing.ex` - host-owned billing facade, including `report_usage_for_scope/3` and subscription helper boundaries.
- `examples/accrue_host/lib/accrue_host/billing/plans.ex` - deterministic Fake-backed `price_metered` plan definition.
- `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs` - existing full billing UI start/cancel proof; use as evidence that Phase 157 need not re-prove every subscription UI prerequisite.
- `examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` - prior host adopter-proof pattern using real route behavior with facade setup.
- `accrue/lib/accrue/billing/meter_event_actions.ex` - public metered usage implementation and `value:` option schema.
- `accrue/lib/accrue/billing/meter_event.ex` - persisted row schema and fields to assert minimally.
- `accrue/test/accrue/billing/meter_event_actions_test.exs` - deeper core metering/idempotency/telemetry tests; do not duplicate that depth in the host proof.

### Reviewed todo origin
- `.planning/todos/pending/2026-05-24-ent10-advisory-cache-followups.md` - reviewed but not folded into Phase 157.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` already starts the Fake processor, resets it, cleans fake billing rows, creates a user + organization, opens `/app/billing`, clicks `"Simulate API Call"`, asserts the flash, and inspects `MeterEvent`.
- `AccrueHost.Billing.report_usage_for_scope/3` already resolves the active organization to a customer, checks admin/owner authorization, and delegates to `Accrue.Billing.report_usage/3`.
- `AccrueHost.Billing.Plans.ids().metered` is already defined as `"price_metered"`, with plan metadata present in `Plans.all/0`.
- `Accrue.Billing.MeterEventActions` already validates `value:` and defaults it to `1`; it does not define a `quantity:` option for usage submission.

### Established Patterns
- Host proof tests use facade/context setup for deterministic preconditions, then LiveView route interactions for the user-visible behavior.
- Example-host billing tests are `async: false` where Fake processor state and cleanup helpers are involved.
- Deeper billing semantics live in core `accrue/test` modules; example-host tests should prove the adopter path without becoming a second full contract suite.
- Phoenix/Phoenix LiveView tests commonly set up state through context functions and assert UI behavior via `live/2`, `element/2`, and `render_click/1`.

### Integration Points
- Update the current metered proof from `Billing.subscribe(organization, "price_basic")` to a metered price (`"price_metered"` or `Plans.ids().metered`) so the test matches the roadmap.
- Add `assert event.value == 1` beside the existing `event.event_name == "api_calls"` assertion.
- Add the inline comment beside `Billing.report_usage_for_scope(socket.assigns.current_scope, "api_calls", value: 1)` in `SubscriptionLive.handle_event/3`.

</code_context>

<specifics>
## Specific Ideas

- Four advisor subagents compared the serious alternatives and converged on the same direction: use the hybrid host proof, subscribe to `price_metered`, keep the visible LiveView click, assert a single persisted row with `event_name` and `value`, and put the `value:` warning where adopters copy the example.
- Ecosystem lesson to carry forward: Stripe-style metered usage is value/payload driven, while subscription quantity is a different concept. Successful billing examples keep subscription setup and usage reporting conceptually separate so developers do not confuse seat quantity with usage value.
- Footgun to avoid: direct DB seeding can create impossible billing states and teach adopters the wrong integration boundary. Full UI setup can make unrelated tax-location or selector issues look like metering failures. The hybrid proof avoids both.

</specifics>

<deferred>
## Deferred Ideas

- A broader metering guide or ExDoc refresh could be useful later if the public docs prove incomplete, but it is not required for PRF-02.
- Full UI subscription-to-metered-plan choreography is not needed here because the host already has subscription flow proof and Phase 157 is about the metered usage adopter slice.

</deferred>

---

*Phase: 157-Metered-Usage-Adopter-Proof*
*Context gathered: 2026-05-31*
