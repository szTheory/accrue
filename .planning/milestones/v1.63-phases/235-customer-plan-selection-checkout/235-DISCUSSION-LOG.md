# Phase 235: Customer Plan Selection & Checkout - Discussion Log

> **Audit trail only.** Decisions are captured in `235-CONTEXT.md`; this log preserves the alternatives considered.

**Date:** 2026-10-07
**Phase:** 235-customer-plan-selection-checkout
**Areas discussed:** Trusted offer terms, Provider handoff and successful return, Retry and recovery

---

## Trusted offer terms

| Option | Description | Selected |
|--------|-------------|----------|
| Trusted host offer and session metadata | Render only supported terms; block payment and offer recovery if essential terms are unavailable. | ✓ |
| Inferred price terms | Guess from identifiers, defaults, or return parameters. | |

**Selection:** `--auto` selected the recommended default. No manual response was requested or inferred; CKO-04 already specifies the evidence boundary.
**Notes:** Keep offer discovery host-owned and avoid a new generic catalog capability.

---

## Provider handoff and successful return

| Option | Description | Selected |
|--------|-------------|----------|
| Distinct provider paths and safe returns | Preserve hosted vs mounted flows, the exact pinned context, and server/provider-backed completion evidence. | ✓ |
| Unified URL-based completion | Treat transports as interchangeable and infer payment from the browser return URL. | |

**Selection:** `--auto` selected the recommended default. No manual response was requested or inferred; the Phase 233 contract and CKO-02/04 already settle these boundaries.
**Notes:** Use validated host/local destinations and existing safe fallback behavior.

---

## Retry and recovery

| Option | Description | Selected |
|--------|-------------|----------|
| Evidence-specific recovery | Revalidate session and authorization, clear one-time secure-field state, and require a fresh customer action after uncertainty. | ✓ |
| Automatic or generic retry | Resubmit after failure or tell the customer to retry without distinguishing known from unknown outcomes. | |

**Selection:** `--auto` selected the recommended default. No manual response was requested or inferred; CKO-01/03/04 and Phase 233 D-13–D-17 lock this safety model.
**Notes:** Preserve actionable recovery without replaying an uncertain payment.

---

## the agent's Discretion

- Choose the smallest session/form mechanism that retains the selected offer and context across the current host sign-in flow.
- Choose exact concise copy, component boundaries, executable test layers, and merge-blocking CI wiring based on recurring value.

## Deferred Ideas

- No new idea was raised. Generic plan discovery, new payment capabilities, new processors, and dynamic processor routing remain out of scope.
