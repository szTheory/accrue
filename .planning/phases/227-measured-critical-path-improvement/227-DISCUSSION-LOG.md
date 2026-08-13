# Phase 227: Measured Critical-Path Improvement - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-12
**Phase:** 227-Measured Critical-Path Improvement
**Areas discussed:** Optimization Target, Proof Bar, Rollback Safety

---

## Optimization Target

### First optimization target

| Option | Description | Selected |
|--------|-------------|----------|
| Dependency ordering | Start host proof earlier while release/admin proof remains required. | ✓ |
| Repeated release-matrix work | Move duplicated static/setup work while retaining unique cell proof. | |
| Host/browser setup duplication | Consolidate Node/npm/Playwright provisioning without browser caching. | |
| Let downstream research decide | Rank all candidates and implement the strongest safe option. | |

### Prerequisite boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Host after docs only | Start host integration after `docs-contracts-shift-left`. | ✓ |
| Host after release gate | Remove only indirect admin-drift wait. | |
| Evidence-led minimum | Remove the narrowest edge supported by later research. | |

### Failure behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Let independent proof finish | Preserve host/browser results and artifacts when another lane fails. | ✓ |
| Cancel host/browser work | Conserve compute but lose independent evidence. | |
| Conditional policy | Finish deterministic failures and cancel selected infrastructure states. | |

### Change breadth

| Option | Description | Selected |
|--------|-------------|----------|
| One-edge optimization | Detach host integration only; preserve host → Playwright. | ✓ |
| Re-evaluate whole path | Allow removal of any unnecessary staged edge. | |
| Parallelize Playwright too | Investigate starting browser proof independently of host proof. | |

**User's choices:** Dependency ordering; host after docs only; independent proof finishes; one-edge optimization.
**Notes:** The intended saving is removal of measured DAG wait, not removal, skipping, or weakening of any required proof.

---

## Proof Bar

### Post-change sample

| Option | Description | Selected |
|--------|-------------|----------|
| Three successful first attempts | Same event class; retain individual observations and variance. | ✓ |
| One successful run | Quick but weak against runner variance. | |
| Five successful first attempts | Stronger but costlier and slower. | |
| Adaptive sample | Start with three and add two if results overlap prior variance. | |

### Primary metric

| Option | Description | Selected |
|--------|-------------|----------|
| Staged critical-path duration | Release start through latest Playwright completion; DAG wait is causal evidence. | ✓ |
| Host start time | Earlier start is enough even without reliable end-to-end improvement. | |
| Whole-workflow wall time | Require the final workflow completion to improve. | |
| Combined gate | Require both earlier host start and faster staged completion. | |

### Keep threshold

| Option | Description | Selected |
|--------|-------------|----------|
| At least 20% median reduction | Also investigate any post observation above prior p95. | ✓ |
| At least five minutes | Use a simple absolute reduction. | |
| Variance-aware only | Require lower median and causal wait removal without a percentage. | |
| Any repeatable reduction | Keep any consistent improvement. | |

### Evidence location

| Option | Description | Selected |
|--------|-------------|----------|
| Separate Phase 227 evidence pack | Preserve Phase 226 and add Markdown plus machine-readable comparison. | ✓ |
| Extend Phase 226 baseline | Append after-state observations to the existing baseline. | |
| Context and verification only | Store links/calculations only in planning artifacts. | |
| CI summary only | Keep comparison in GitHub's run summary. | |

**User's choices:** Three first-attempt runs; staged critical-path metric; 20% median reduction; separate Phase 227 evidence pack.
**Notes:** Phase 226 remains the immutable before snapshot. Whole-workflow duration is context, not the deciding metric.

---

## Rollback Safety

### Negative control

| Option | Description | Selected |
|--------|-------------|----------|
| Static plus executable failure proof | Verify graph/contracts and record controlled failure propagation with artifacts. | ✓ |
| Static verifier only | Validate workflow structure without a failing run. | |
| Recorded failure run only | Keep immutable run evidence without a repository verifier. | |
| Planner decides | Require outcomes but leave the mechanism open. | |

### Stable contract

| Option | Description | Selected |
|--------|-------------|----------|
| Exact contract manifest | Guard check IDs/names, matrix/provider labels, artifacts, conditions, and retention. | ✓ |
| Required names only | Lock check identities but allow artifact contract changes. | |
| Semantic assertions | Check evidence categories without exact names. | |
| Live ruleset comparison | Validate against externally configured repository rules. | |

### Rollback trigger

| Option | Description | Selected |
|--------|-------------|----------|
| Any safety failure or missed speed bar | Revert on proof regression, failed control, deterministic failure, or <20% gain. | ✓ |
| Safety failures only | Keep a safe cleanup even if performance misses the threshold. | |
| Repeated failures only | Require two failures before reverting. | |
| Maintainer judgment | Review evidence case by case. | |

### Rollback procedure

| Option | Description | Selected |
|--------|-------------|----------|
| Exact inverse patch plus fresh proof | Restore edge, run verifier, and record fresh first-attempt recovery CI. | ✓ |
| Git revert only | Revert and rely on ordinary required CI. | |
| Feature switch | Keep a configurable serialization mode. | |
| Documented YAML edit | Supply manual instructions without a dedicated rollback test. | |

**User's choices:** Static plus executable negative control; exact manifest; rollback on any safety/performance failure; inverse patch plus fresh proof.
**Notes:** Stable evidence means externally visible identity and recoverability, not merely a green workflow conclusion.

---

## the agent's Discretion

- Exact Phase 227 filenames and machine-readable schema.
- Verifier implementation and controlled-failure seam.
- Narrow criteria for substantiating an external timing anomaly, with every exclusion visible.

## Deferred Ideas

- Release-matrix duplicate-work extraction.
- Host/browser setup consolidation.
- Further graph changes, including independent Playwright start.
- Playwright browser caching absent contrary measurements.
