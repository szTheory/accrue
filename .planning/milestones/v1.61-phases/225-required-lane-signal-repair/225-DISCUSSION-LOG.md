# Phase 225: Required-Lane Signal Repair - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-08
**Phase:** 225-Required-Lane Signal Repair
**Areas discussed:** Incident record format, release-matrix repair policy, Admin Playwright investigation, completion bar

---

## Incident Record Format

| Option | Description | Selected |
|---|---|---|
| Checked-in incident record | Concise, reviewable causal index with links to raw CI evidence. | ✓ |
| Ad-hoc PR prose | Low initial friction, but decisions and repro details are not durable. | |
| Raw-artifacts only | High-fidelity forensic data, but artifacts expire and are difficult to review. | |

**User's choice:** Approved the recommendation-led decision set after requesting broad parallel research and a cohesive one-shot recommendation.
**Notes:** Record one incident per normalized failure signature; raw reports, traces, screenshots, and server logs remain GitHub artifacts.

---

## Release-Matrix Repair Policy

| Option | Description | Selected |
|---|---|---|
| Identity-scoped assertions | Test only rows belonging to the event under test; preserve real idempotency/atomicity behavior. | ✓ |
| Global serialization | Reduce apparent contention but conceal over-broad test observation and slow the suite. | |
| Retry/matrix workaround | May make runs appear green without repairing the causal failure. | |

**User's choice:** Approved the recommendation-led decision set.
**Notes:** Treat all four identical release failures as one test-isolation incident. Preserve required cells, advisory Sigra labeling, matrix topology, and stable release-gate identity.

---

## Admin Playwright Investigation

| Option | Description | Selected |
|---|---|---|
| Partition bounded journey tests | Preserve all viewport/theme/flow coverage while giving each unit an intelligible budget and result. | ✓ |
| Raise global timeout | Delays failure without separating the 210 serial journey checks. | |
| Add retries or remove coverage | Masks the signal or weakens the proof. | |

**User's choice:** Approved the recommendation-led decision set.
**Notes:** Trace evidence indicates a capacity/topology mismatch under a 60-second whole-test budget, not an evidenced external/lifecycle interruption. Keep single-worker execution and diagnostic artifacts.

---

## Completion Bar

| Option | Description | Selected |
|---|---|---|
| Fresh-run, evidence-preserving proof | Require classified incidents, narrow repro/negative controls, full local proof, and a fresh green repair run. | ✓ |
| Rerun-only confirmation | Does not prove that the repair commit caused the result. | |
| Green-status-only confirmation | Cannot show that assertions, artifacts, or check semantics were retained. | |

**User's choice:** Approved the recommendation-led decision set.
**Notes:** Required and advisory evidence remain distinct. The Phase 192 generated-evidence artifact path must be repaired or explicitly replaced before it is presented as available evidence.

---

## the agent's Discretion

- Exact Markdown layout and IDs for `225-CI-INCIDENTS.md`.
- Artifact retention duration, consistent with repository policy.
- Deterministic page-flow partition boundary and the truthful treatment of the misleading rollback-test name.

## Deferred Ideas

- CI baseline/proof-semantics work (Phase 226).
- Matrix, cache, branch-protection, and measured critical-path changes (Phase 227).
- Admin ratchet/rework, StoreKit/iPhone/Crosswake, and end-user UI changes.
