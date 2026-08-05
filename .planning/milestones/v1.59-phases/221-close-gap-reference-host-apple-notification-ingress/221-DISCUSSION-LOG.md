# Phase 221: close-gap-reference-host-apple-notification-ingress - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-05
**Phase:** 221-close-gap-reference-host-apple-notification-ingress
**Areas discussed:** Webhook route contract, Host configuration boundary, Ingress proof, Adopter guidance

---

## Webhook route contract

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated Apple route and parser pipeline | Route-specific exact raw-body capture and 256 KiB limit, separate from Stripe. | ✓ |
| Reuse Stripe webhook pipeline | Less router code, but retains Stripe's 1 MiB contract and obscures Apple-specific limits. | |
| Generic controller/handler | Moves provider ingress behind application plumbing not intended for Apple verification. | |

**User's choice:** Requested a deeply researched, one-shot cohesive recommendation across all areas; approved the dedicated route decision set.
**Notes:** The existing package macro and guide already define this host boundary. Apple ingress remains notification/reconciliation input, not entitlement truth.

---

## Host configuration boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Host-owned runtime verifier/options wrapper | Fail-fast deployment config, one verifier policy shared by ingress and admission, no package API expansion. | ✓ |
| Router-embedded deployment values | Couples compile-time router code to runtime deployment configuration. | |
| Package-owned host configuration | Violates the project boundary that hosts own routes, secrets, supervision, and runtime setup. | |

**User's choice:** Approved the cohesive decision set.
**Notes:** Production-only reference configuration avoids claiming mixed sandbox/production verification from one environment-specific verifier.

---

## Ingress proof and operations

| Option | Description | Selected |
|--------|-------------|----------|
| Deterministic router proof plus advisory live check | Merge-blocking host proof for durable outcomes and response classes; real App Store test remains operational evidence. | ✓ |
| Direct Plug/core tests only | Does not prove the reference host parser, route, config, or wiring. | |
| Live-provider CI proof | Credential-dependent and unsuitable as merge authority. | |

**User's choice:** Approved the cohesive decision set.
**Notes:** Preserve durable-before-acknowledgement response behavior. Apple retries both 4xx and 5xx, so `429` is backpressure rather than a terminal discard.

---

## Adopter guidance and operator experience

| Option | Description | Selected |
|--------|-------------|----------|
| Compact recipe, proof, and safe runbooks | Literal setup and verification while existing authenticated diagnostics show job-and-next-action state. | ✓ |
| New Apple status UI/raw evidence viewer | Adds a public/backend surface and risks exposing sensitive provider evidence. | |
| Omit host guidance | Leaves the correct package API unproven and difficult to adopt. | |

**User's choice:** Approved the cohesive decision set.
**Notes:** Current brandbook voice governs: measured, exact, Phoenix-native, and mechanism-led.

---

## the agent's Discretion

- Exact module/config names, bounded single-node limiter algorithm, fixture/helper placement, and documentation organization, subject to the locked safety and evidence contracts.

## Deferred Ideas

- Distributed rate-limit infrastructure, sandbox endpoint, raw-event UI, and Apple lifecycle controls remain outside Phase 221.
