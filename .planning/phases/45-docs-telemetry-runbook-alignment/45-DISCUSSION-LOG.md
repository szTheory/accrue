# Phase 45: Docs + telemetry/runbook alignment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `45-CONTEXT.md`.

**Date:** 2026-04-22  
**Phase:** 45 — Docs + telemetry/runbook alignment  
**Areas discussed:** Doc spine (MTR-07); telemetry catalog depth (MTR-08); runbook vs catalog split; README/testing cross-links  
**Method:** User requested “all” gray areas; four parallel `generalPurpose` research subagents; orchestrator synthesized into non-contradictory decisions.

---

## 1 — Doc spine for MTR-07

| Option | Description | Selected |
|--------|-------------|----------|
| A | Thin `guides/metering.md` (concept map + links, no option duplication) | ✓ |
| B | Layered only (ExDoc + testing + telemetry, no new guide) | Fallback if timeboxed |
| C | Fold deep metering into quickstart / first hour | ✗ (wrong abstraction layer) |
| D | External wiki / off-Hex long-form | ✗ (version skew) |

**User's choice:** Research-recommended **Option A** with **Option B** as explicit fallback in CONTEXT (**D-04**).  
**Notes:** Coheres with Phase 43 **D-09** (no ops duplication in metering narrative); ExDoc remains options SSOT.

---

## 2 — Telemetry.md depth for MTR-08

| Option | Description | Selected |
|--------|-------------|----------|
| A | Single catalog row only | ✗ (insufficient for three sources) |
| B | Semantics block: paragraph (durable transition) + three `:source` bullets | ✓ |
| C | Full metadata matrix in prose | Deferred (semver / D-13 stability) |

**User's choice:** **Option B** under existing row; matrix deferred per Phase 44 **D-13**.  
**Notes:** Matches “one telemetry event, metadata dimensions” idiom (Phoenix/Oban patterns); avoids catalog fork.

---

## 3 — Runbook vs telemetry.md split

| Option | Description | Selected |
|--------|-------------|----------|
| A | Runbook-heavy (duplicate signal definitions) | ✗ |
| B | Catalog-heavy (all triage in one file) | ✗ |
| C | v1.9 layered: fat catalog + thin runbook procedures | ✓ |

**User's choice:** **Extend** `meter_reporting_failed` mini-playbook with **source branches** + **links** to telemetry semantics; **no second ops table**.

---

## 4 — README / testing.md cross-links

| Option | Description | Selected |
|--------|-------------|----------|
| A | Mandatory comprehensive cross-link graph | ✗ |
| B | Optional stretch; minimal high-signal links only | ✓ |

**User's choice:** ROADMAP optional stretch preserved; **D-12** minimal pattern documented if stretch is executed.

---

## Claude's Discretion

- Anchors, exact prose, `@moduledoc` cross-links.
- Trigger **D-04** fallback (skip `metering.md`) only on schedule pressure.

## Deferred Ideas

- Full metadata matrix across sync/reconciler/webhook — deferred to stable **D-13** surface.
- README link graph beyond minimal pattern — evidence-driven only.
