# Phase 226: CI Baseline & Proof Semantics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-11
**Phase:** 226-ci-baseline-proof-semantics
**Areas discussed:** Comparable-run baseline, Provider proof states, Setup ownership

---

## Comparable-Run Baseline

| Option | Description | Selected |
|--------|-------------|----------|
| Checked-in versioned evidence pack | Durable Markdown plus sanitized machine-readable rows, generated from Actions metadata and verified in-repo. | ✓ |
| Per-run GitHub summaries only | Native and immediate, but retention-bound and unsuitable as a durable multi-run baseline. | |
| External CI observability service | Rich dashboards and long retention, but adds credentials, cost, governance, and an unnecessary source of truth. | |

**User's choice:** Delegated the choice after parallel expert research, then accepted the recommendation.
**Notes:** The accepted cohort uses event/config/job/matrix/provider fingerprints, the latest 20 successful first attempts within 90 days, an explicit insufficient-sample state, separate reliability accounting, DAG-aware wait measurement, and privacy-safe checked-in evidence.

---

## Provider Proof States

| Option | Description | Selected |
|--------|-------------|----------|
| GitHub conclusion as provider status | Simple, but skipped checks can appear successful and advisory failures can be obscured. | |
| Independent lane policy and proof-state record | Separates required/advisory enforcement from proved/failed/misconfigured/blocked/skipped/non-run evidence. | ✓ |
| External proof aggregation service | Cross-repository aggregation at the cost of new credentials and operational ownership. | |

**User's choice:** Delegated the choice after parallel expert research, then accepted the recommendation.
**Notes:** `stale` is derived freshness. Scheduled/manual provider misconfiguration fails closed. Only an actually executed, nonzero, passing provider suite can produce `proved`.

---

## Setup Ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Host self-provisions all tooling | One-command bootstrap, but duplicates CI setup and conflates environment failure with proof failure. | |
| Host declares/preflights; CI provisions explicitly | Keeps proof semantics host-owned while making runner provisioning, diagnostics, timing, and artifacts CI-owned. | ✓ |
| Containerize all browser proof | Strong Linux parity, but adds image/supply-chain ownership and changes topology before measurement. | |

**User's choice:** Delegated the choice after parallel expert research, then accepted the recommendation.
**Notes:** Both environments invoke the same host-owned proof contract. Phase 226 measures and classifies current duplication; Phase 227 decides whether to remove it. Playwright browser caching is not introduced without measured net benefit.

## the agent's Discretion

- Exact filenames, JSON versus NDJSON, schema field names, signature normalization mechanics, Markdown layout, and provider freshness grace window.
- Exact deterministic fixtures and narrow verifier commands, provided the accepted evidence and scope constraints hold.

## Deferred Ideas

- Remove one measured duplicate setup cost in Phase 227.
- Add Playwright browser caching only after measured proof.
- Consider an external observability service only for a separately authorized multi-repository need.
