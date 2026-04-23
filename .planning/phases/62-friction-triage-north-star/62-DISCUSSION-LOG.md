# Phase 62: Friction triage + north star - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **62-CONTEXT.md** — this log preserves alternatives considered.

**Date:** 2026-04-23  
**Phase:** 62 — Friction triage + north star  
**Areas discussed:** Artifact layout + SSOT; P0/P1/P2 bar; North star + stop rules; FRG-03 traceability  
**Method:** User selected **all** areas and requested **parallel subagent research** + one-shot synthesis.

---

## Artifact layout + SSOT

| Option | Description | Selected |
|--------|-------------|----------|
| A — Single markdown | One file for FRG-01..03 | |
| B — Evidence + policy split | Inventory vs north star | ✓ (adapted) |
| C — Phase dir only | WIP under `phases/` | ✗ (risk with `phases.clear`) |
| D — Directory hub | `triage/v1.17/*` | ✗ (overkill for one milestone) |

**User's choice:** Synthesize subagents → **B** with durable **`research/`** paths; optional thin ROADMAP pointers later.  
**Notes:** Pay/Oban/Stripe patterns favor **separate** integrator docs vs maintainer SSOT; Accrue uses **`research/`** + **`REQUIREMENTS`** split.

---

## P0 / P1 / P2 bar + sources

| Option | Description | Selected |
|--------|-------------|----------|
| Strict P0 = CI only | Objective but misses doc pain | ✗ |
| Broad P0 = any pain | Captures reality; scope creep | ✗ |
| Two-axis + FRG-03 firewall | `ci_contract` × `integrator_impact` + routing rules | ✓ |

**User's choice:** Locked in **CONTEXT D-02** and inventory template.  
**Notes:** MoSCoW / SRE / K8s-style multi-axis avoids overloaded labels.

---

## North star + stop rules

| Option | Description | Selected |
|--------|-------------|----------|
| All in PROJECT.md | Best discoverability; high drift | ✗ |
| Sibling canonical + PROJECT bullets | Low duplication | ✓ |
| Stops only inside inventory | Blurs evidence vs policy | ✗ |

**User's choice:** **`v1.17-north-star.md`** + short pointers in **PROJECT.md**.  
**Notes:** PR-FAQ / Shape Up hybrid — principles + **exit test** table.

---

## FRG-03 traceability

| Option | Description | Selected |
|--------|-------------|----------|
| A — Backlog only in inventory | Single edit surface | ✓ |
| B — Duplicate in ROADMAP | High drift | ✗ |
| C — ROADMAP index + inventory | Optional pointers | ✓ (optional) |

**User's choice:** **A** required; **C** optional one-liner links when helpful. IDs **`v1.17-P0-NNN`**.

---

## Claude's Discretion

- Optional ROADMAP anchor lines when phase **63** planning starts.

## Deferred Ideas

- Automated anchor / ROADMAP drift linter — deferred.
