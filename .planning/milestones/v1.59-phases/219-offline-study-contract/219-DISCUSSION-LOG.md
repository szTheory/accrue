# Phase 219: Offline study contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-03
**Phase:** 219-offline-study-contract
**Areas discussed:** Study continuity, Published proof API, Reconnect orchestration

---

## Study Continuity

| Option | Description | Selected |
|--------|-------------|----------|
| Add `reconnect_required` as a fifth state | Mirrors an older architecture table and makes the UI action explicit, but contradicts OFF-04 and widens every client, fixture, support, and UI matrix. | |
| Keep four states with bounded reasons | Preserve `fresh`, `stale_offline`, `denied`, and `invalid`; derive reconnect guidance from state, reason, and attempted operation. | ✓ |
| Collapse unusable proof into `denied` | Minimizes vocabulary but falsely equates signed server denial with failed or unavailable verification. | |

**User's choice:** Accepted the complete recommendation bundle after requesting deep subagent research and a one-shot cohesive recommendation.
**Notes:** `stale_offline` preserves downloaded study and local progress only while the allow proof remains within explicit signed validity. A hard-expired or otherwise invalid proof preserves local data but fails closed for entitlement-gated actions. There is no independent 72-hour cutoff. `reconnect_required` is a next action, not proof state.

---

## Published Proof API

| Option | Description | Selected |
|--------|-------------|----------|
| ES256 JWS, public JWKS, and typed facade | Independent cross-language verification, normal `kid` rotation, public fixtures, and a small Phoenix-native host API. | ✓ |
| Fixed embedded public key | Simple first client but every rotation requires client deployment and compromise recovery is weak. | |
| Opaque server-only token | Smallest crypto surface but cannot satisfy independent extended-offline verification. | |

**User's choice:** Accepted the complete recommendation bundle.
**Notes:** Publish a fixed purpose-specific ES256 profile, cacheable public JWKS, closed four-state decision/reason contract, and language-neutral fixtures behind `Accrue.Entitlements.Offline`. Existing boolean/scalar gates remain unchanged. Hide JOSE, Ecto, provider, reducer, and worker internals.

---

## Reconnect Orchestration

| Option | Description | Selected |
|--------|-------------|----------|
| Synchronous all-rail refresh | Immediate answer but couples request capacity and reconnect availability to provider latency and outages. | |
| Queue-only reconciliation and polling | Isolates provider work but delays renewal and creates a second client status protocol. | |
| Hybrid coordinator plus durable repair | Returns a proof when every due source converges; otherwise returns bounded pending and reuses durable repair. | ✓ |
| Hybrid with partial-result allow | Maximizes apparent availability but can sign access while a due source hides revocation or repair debt. | |

**User's choice:** Accepted the complete recommendation bundle.
**Notes:** Account authentication, server nonce, device proof-of-possession, and idempotency precede refresh. No positive proof is issued from unresolved due sources. Final snapshot/device/revision reread and issuance metadata are transactional; client replacement occurs only after verification through durable compare-and-replace. Deny wins at equal revision.

---

## the agent's Discretion

- Exact internal module/file names and final function arities.
- Struct field layout and bounded reason atom spelling where not explicitly locked.
- JWKS Plug name, issuance/audit record name, reconnect-attempt persistence shape, and telemetry event names.
- Source due intervals, bounded inline timeout, retry/page budgets, and key-retirement buffer within the locked semantics.

## Deferred Ideas

No new ideas were deferred. Existing out-of-scope items remain unchanged: arbitrary TTL/risk matrices, hardware attestation/DRM, Google Play, Family Sharing, offer authoring, migration/proration, Phase-220 UI/runbooks, and later physical-device release evidence.
