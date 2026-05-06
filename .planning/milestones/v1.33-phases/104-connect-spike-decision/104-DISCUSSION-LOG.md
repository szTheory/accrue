# Phase 104: Connect Spike / Decision - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-02
**Phase:** 104-Connect Spike / Decision
**Areas discussed:** Decision target, Parity bar, Product boundary, Rejection posture

---

## Decision Target

| Option | Description | Selected |
|--------|-------------|----------|
| Go/no-go only | Fastest way to decide whether the phase should exist at all, but leaves follow-on work underspecified. | |
| Go/no-go plus a narrow if-go slice contract | Best fit for a decision spike: keeps the outcome reusable without committing to a large platform design. | ✓ |
| Full architecture target for a later implementation track | Most complete map, but over-targeted for a spike and risks designing around false commonality. | |

**User's choice:** Go/no-go plus a narrow if-go slice contract
**Notes:** Strong defaults should be shifted left, but only if the choice is materially strategic.

## Parity Bar

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal seller onboarding + payouts only | Honest narrow slice, but not real Connect parity. | |
| Core `Accrue.Connect` semantic parity with clear exclusions | Best balance: one marketplace facade with explicit capability labels and exclusions. | ✓ |
| Near-Stripe feature parity | High risk of false parity and support debt. | |

**User's choice:** Core `Accrue.Connect` semantic parity with clear exclusions
**Notes:** Keep the slice coherent and least-surprise, but do not pretend Braintree+Hyperwallet equals Stripe Connect.

## Product Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Keep Braintree pay-ins and Hyperwallet payouts explicitly separate | Most honest and supportable, but slightly less cohesive as a story. | |
| Wrap under one `Accrue.Connect` story, but capability-labeled | Best balance of narrative and truth; this was selected. | ✓ |
| Hide the split behind a unified abstraction | Lowest initial mental overhead, highest abstraction leakage. | |

**User's choice:** Wrap under one `Accrue.Connect` story, but capability-labeled
**Notes:** Keep provider ownership visible in modules, docs, and failure paths.

## Rejection Posture

| Option | Description | Selected |
|--------|-------------|----------|
| Reject for v1.x only | Too soft; invites zombie scope. | |
| Reject until real adopter demand appears | Better, but still leaves the topic too open. | |
| Reject as strategically out of bounds unless the project boundary changes | Strongest guardrail and best fit for the current boundary. | ✓ |

**User's choice:** Reject as strategically out of bounds unless the project boundary changes
**Notes:** If the spike says no, the decision should be hard and explicit, not a soft maybe-later.

## Deferred Ideas

- Full Braintree marketplace parity.
- Any future payout-platform abstraction that would generalize marketplace support beyond the current direct-gateway boundary.
- A unified abstraction that hides provider ownership behind a single money-movement API.

