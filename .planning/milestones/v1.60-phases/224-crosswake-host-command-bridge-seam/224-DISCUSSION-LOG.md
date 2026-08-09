# Phase 224: Crosswake host-command bridge seam - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-06
**Phase:** 224-Crosswake host-command bridge seam
**Areas discussed:** Crosswake delivery target, delegate declaration shape, dispatch and reply boundary, route lifecycle behavior

---

## Crosswake Delivery Target

| Option | Description | Selected |
|---|---|---|
| Upstream Crosswake patch | One authoritative safe-bridge implementation consumed at an immutable release or commit. | ✓ Preferred |
| Short-lived pinned Alpha-owned fork | Fallback carrying the same reviewed patch when upstream timing blocks delivery. | ✓ Conditional fallback |
| Accrue-local wrapper/custom WebKit handler | Local substitute that would bypass Crosswake's validator and create false evidence. | Rejected |

**User's choice:** Approved the cohesive recommendation.
**Notes:** Implement only at Crosswake's existing validated dispatch point; keep a fork temporary, exact-revision pinned, source/diff audited, and converging upstream. Compile evidence does not replace device evidence.

---

## Delegate Declaration Shape

| Option | Description | Selected |
|---|---|---|
| Manifest-owned capability map plus explicit host registry | Exact commands/version are visible and dispatch requires their intersection. | ✓ |
| Generic `handle(command, payload)` delegate | Small initial surface but turns allowlisting and schema validation into convention. | Rejected |
| Global command registry with route predicates | Separates authority from the manifest and introduces lifecycle/race hazards. | Rejected |

**User's choice:** Approved the cohesive recommendation.
**Notes:** The four literal commands are closed; no wildcards, dynamic discovery, or generic commerce namespace.

---

## Dispatch and Reply Boundary

| Option | Description | Selected |
|---|---|---|
| One bridge-owned admission and reply path | Validate first; delegate receives typed input and returns typed outcome; bridge serializes one reply. | ✓ |
| Host-owned raw WebKit/reply channel | Lets host code inject arbitrary responses or bypass validator context. | Rejected |
| Arbitrary JSON/generic native-call API | Broad ambient authority and weak schema/privacy controls. | Rejected |

**User's choice:** Approved the cohesive recommendation.
**Notes:** Existing protocol/version/route/origin/pack/manifest checks remain mandatory before lookup and dispatch. Replies and failures are closed, bounded, and privacy-safe.

---

## Route Lifecycle Behavior

| Option | Description | Selected |
|---|---|---|
| Active-route-only completion | Route epoch invalidates on navigation and suppresses any stale reply. | ✓ |
| Allow old request to complete into current page | Risks cross-route reply injection and ghost success. | Rejected |
| Rely on host cancellation alone | Cannot safely handle non-cancellable native work or guarantee reply suppression. | Rejected |

**User's choice:** Approved the cohesive recommendation.
**Notes:** A native operation may complete host-side after navigation, but its result cannot reply to a new route or become entitlement authority.

---

## the agent's Discretion

- Exact Crosswake types, module names, descriptor encoding, task/cancellation implementation, telemetry event names, test layout, and upstream/fork mechanics within the locked boundary.

## Deferred Ideas

- Generic Crosswake commerce/plugin API, additional command namespaces, receipt/proof forwarding, StoreKit and host UI orchestration, and physical-device promotion are outside Phase 224.
