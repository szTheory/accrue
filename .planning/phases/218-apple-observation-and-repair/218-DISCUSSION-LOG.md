# Phase 218: Apple observation and repair - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-03
**Phase:** 218-apple-observation-and-repair
**Areas discussed:** Lineage linking and repair, Verification quarantine, Reconciliation convergence

---

## Lineage Linking and Repair

| Option | Description | Selected |
|--------|-------------|----------|
| Token-match-only | Accept evidence only when the verified token equals the authenticated account; leave historical unbound purchases unresolved. | |
| Verified-unbound, bind once | Keep valid unbound evidence non-granting, allow one atomic host-authorized claim, and quarantine conflicts. | ✓ |
| Automatic transfer/reassignment | Restore to the current session or match by email, device, product, or other heuristics. | |

**User's choice:** The user asked the agent and research subagents to consider all approaches and lock the best cohesive recommendation without requiring the user to choose.
**Notes:** Selected bind-once repair because it satisfies AAPL-01 while preserving recoverability. Conflict repair never becomes transfer, and the owning account is not disclosed.

---

## Verification Quarantine

| Option | Description | Selected |
|--------|-------------|----------|
| Strict verifier behaviour | Keep a narrow Accrue boundary, strict default adapter, deterministic Fake, and closed failure taxonomy. | ✓ |
| Direct community dependency | Expose or rely directly on a community Apple server library without an insulating admission boundary. | |
| Separate verification service | Delegate crypto to an official-language service with a new transport and availability boundary. | |

**User's choice:** Delegated to the agent after parallel specialist research.
**Notes:** The community dependency may be used privately only if it passes the locked corpus, independent-verifier, supervision, privacy, and dependency gates. Security-invalid evidence is terminal quarantine; infrastructure/provider failures are retryable; duplicates/stale inputs are successful no-ops.

---

## Reconciliation Convergence

| Option | Description | Selected |
|--------|-------------|----------|
| Notification-first reducer | Treat verified notification delivery as the primary entitlement update. | |
| Status on every notification | Fetch current subscription status for every delivery without a durable history checkpoint. | |
| Hybrid status + history | Use notifications as wakeups, status as present authority, and ascending history as durable repair evidence. | ✓ |
| Notification History ledger | Treat Apple's bounded delivery history as current subscription truth. | |

**User's choice:** Delegated to the agent after parallel specialist research.
**Notes:** The hybrid model matches Apple authority and existing Accrue architecture. The final history cursor commits only after the last page; Notification History is diagnostic/backfill input only; all normalized changes pass through the existing projector.

---

## the agent's Discretion

- Exact internal modules, structs, table/constraint names, worker names, public function names, telemetry events, and closed reason atoms.
- Exact bounded cadence, concurrency, page budget, backoff, and evidence expiry within the locked authority, privacy, and rate-limit semantics.
- Whether the community Apple library passes admission as the private default adapter; its types never escape the Accrue boundary.

## Deferred Ideas

- Automatic ownership transfer or reassignment.
- Family Sharing ownership policy.
- Offer authoring and offer-eligibility policy.
- Phase-220 admin/portal UI and complete operator runbooks.
- Phase-219 offline proof and Crosswake runtime work.
