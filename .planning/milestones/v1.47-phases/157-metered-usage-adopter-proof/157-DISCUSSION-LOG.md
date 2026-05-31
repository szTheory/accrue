# Phase 157: Metered Usage Adopter Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 157-Metered Usage Adopter Proof
**Areas discussed:** E2E adopter-test journey shape, metered subscription/data setup, MeterEvent assertion shape, `value:` vs `quantity:` comment placement

---

## E2E Adopter-Test Journey Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Full LiveView route interaction | Subscribe to `price_metered` through the UI, then click `"Simulate API Call"` and assert the row. Most realistic but brittle because setup can fail for unrelated UI/tax/selector reasons. | |
| Hybrid host facade setup + LiveView usage click | Subscribe through the host billing facade/context, then exercise the visible LiveView `"Simulate API Call"` action, flash, and row assertion. | ✓ |
| Core-only metering test + tiny host smoke | Fast and isolated but misses the adopter-proof intent of PRF-02. | |

**User's choice:** User explicitly delegated routine decisions to the agent and asked to follow recommendations after subagent research.
**Notes:** Advisor research recommended the hybrid shape because it is deterministic, idiomatic for Phoenix tests, and still proves the user-visible host path.

---

## Metered Subscription/Data Setup

| Option | Description | Selected |
|--------|-------------|----------|
| Full UI subscribe to `price_metered` | Maximum browser-level realism but brings unrelated preconditions into the metering proof. | |
| Host billing context/facade subscribe to `price_metered` | Clear deterministic precondition using public host boundary, followed by real LiveView usage action. | ✓ |
| Direct schema inserts | Fast but over-coupled to internals and can create impossible states. | |
| New helper-only setup | Reusable but too much abstraction for one adopter proof. | |

**User's choice:** Delegated to the researched recommendation.
**Notes:** Existing `SubscriptionLiveTest` already uses facade setup; Phase 157 should change the plan from `price_basic` to `price_metered` rather than inventing a new pattern.

---

## MeterEvent Assertion Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Flash only | Too weak; does not prove the row was persisted. | |
| Exactly one global row plus minimal field checks | Matches PRF-02 directly under current isolated setup and remains readable. | ✓ |
| Scoped row plus operation-id/idempotency checks | More robust for idempotency but broader than this adopter proof. | |
| Row + telemetry + ledger assertions | Strongest internal proof but duplicates deeper core metering tests and over-specifies the host proof. | |

**User's choice:** Delegated to the researched recommendation.
**Notes:** Recommended assertions: success flash, exactly one `MeterEvent`, `event_name == "api_calls"`, and `value == 1`. Keep idempotency/telemetry/ledger assertions in core tests.

---

## `value:` vs `quantity:` Comment Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Inline comment at `SubscriptionLive` callsite | Most visible to adopters copying the host example and satisfies the phase's inline-comment requirement. | ✓ |
| Comment in host billing facade helper | Central but less discoverable for UI-focused adopters. | |
| Test-only comment | Executable but not where adopters copy usage code. | |
| Broader guide/API doc update | Useful as canonical backup but not necessary for the phase by itself. | |

**User's choice:** Delegated to the researched recommendation.
**Notes:** Put the comment adjacent to `Billing.report_usage_for_scope(..., value: 1)`. The comment should say usage reporting uses `value:`; `quantity:` belongs to subscription/invoice line items and is not the meter-event option.

---

## the agent's Discretion

- Selected all gray areas because the user asked to discuss/consider all and follow recommendations.
- Used four `gsd-advisor-researcher` subagents for independent tradeoff research.
- Reviewed the pending ENT-10 advisory-cache todo and did not fold it into Phase 157.

## Deferred Ideas

- Broader metering guide or API-doc refresh if future planning finds public docs stale.
- Full UI subscription-to-metered-plan choreography if a future phase wants pure browser-flow proof for plan selection.
