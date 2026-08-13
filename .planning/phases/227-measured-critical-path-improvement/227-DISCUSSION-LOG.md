# Phase 227: Measured Critical-Path Improvement - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-13
**Phase:** 227-measured-critical-path-improvement
**Areas discussed:** Candidate trigger contract, Success admission boundary, Failure and run budget, Rollback posture

---

## Candidate Trigger Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Current `workflow_dispatch` | Repeatable manual launches at one SHA, but every launch also selects unavailable live-Stripe proof. | |
| Pull-request runs | Represent the contributor merge path and naturally exclude live Stripe, but repeated first attempts at one SHA require surprising PR close/reopen activity. | |
| Separate performance workflow | Isolates timing collection, but creates a second topology that can drift from required CI. | |
| Typed dispatch input | Keep the real CI workflow; add a required Boolean `run_live_stripe` input whose default preserves current behavior and whose explicit false value identifies measurement runs. | ✓ |

**User's choice:** Accepted the research-backed recommendation in full.
**Notes:** Measurement runs explicitly record provider proof as `non_run`. Scheduled provider proof is unchanged; normal manual behavior remains the default. Input values become part of the evidence fingerprint.

---

## Success Admission Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Workflow conclusion only | Simple, but a skipped job can report success and a green aggregate cannot prove job, artifact, or provider completeness. | |
| Critical-path jobs only | Directly measures the release/host/browser path, but ignores independent required proof and the final fan-in. | |
| Workflow success plus exact proof vector | Require raw success and repository-bound evidence for the exact revision, trigger/input topology, required matrix and independent lanes, finalizer, artifacts, and explicit provider state. | ✓ |

**User's choice:** Accepted the research-backed recommendation in full.
**Notes:** Required, advisory, provider, artifact, and raw GitHub states remain independent literal facts. Missing or weakened required proof is an exclusion and rollback trigger.

---

## Failure and Run Budget

| Option | Description | Selected |
|--------|-------------|----------|
| Run until three green samples appear | Eventually fills a cohort, but creates unbounded cost, selection bias, and sample-shopping. | |
| Replace externally failed runs | Tolerates infrastructure incidents, but makes exclusion classification subjective and expandable. | |
| Exactly three predeclared first attempts | Retain all existing exclusions, preflight the corrected topology, and permit one final three-run cohort at one SHA/event/input fingerprint with no replacements. | ✓ |

**User's choice:** Accepted the research-backed recommendation in full.
**Notes:** Reruns are reliability/diagnosis evidence only. Failures are classified as `candidate_regression`, `deterministic_required_lane_failure`, `external_or_runner_blocked`, or `inconclusive` from repository-bound facts.

---

## Rollback Posture

| Option | Description | Selected |
|--------|-------------|----------|
| Leave candidate active while replanning | Avoids an immediate inverse patch, but makes an unproved topology the de facto accepted state. | |
| Permanent switch | Makes toggling easy, but adds an unnecessary third graph state and lasting failure surface. | |
| Restore now and reapply only for the bounded experiment | Return to the known graph, verify restoration, then reapply only after trigger/proof preflight; any final-cohort failure restores it again. | ✓ |

**User's choice:** Accepted the research-backed recommendation in full.
**Notes:** Rollback truth is staged as `rollback_applied`, `rollback_verified`, or `rollback_applied_unverified`; only the verified state is complete.

---

## the agent's Discretion

- Machine-readable schema details, exact preflight command composition, verifier implementation, and controlled-failure seam remain planner discretion within the locked decisions.
- An external timing anomaly is excludable only with observation-specific GitHub status/incident or explicit runner/infrastructure evidence.

## Deferred Ideas

- A separate performance-only workflow may be considered in a future observability phase if repeated experiments justify its maintenance and drift cost.

## Research Notes

- Three parallel advisor subagents covered trigger/admission semantics, run-budget/rollback policy, and cross-ecosystem/project/DX coherence.
- Primary external guidance consulted: GitHub Actions trigger inputs, job-condition and status semantics, workflow reruns, and Google SRE canary/rollback guidance.
- End-user UI, Phoenix/LiveView components, Plug/Ecto API design, dark/light themes, and product graphic design were judged inapplicable. The relevant UX is the maintainer evidence interface: fact, literal state, owner, one exact next command, then immutable proof.
