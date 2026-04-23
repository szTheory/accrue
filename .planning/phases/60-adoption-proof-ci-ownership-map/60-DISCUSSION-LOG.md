# Phase 60: Adoption proof + CI ownership map - Discussion log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `60-CONTEXT.md`.

**Date:** 2026-04-23  
**Phase:** 60 — Adoption proof + CI ownership map  
**Areas discussed:** CI README ownership layout; Matrix vs walkthrough parity; Trust copy placement; Contributor map audit scope  

---

## Session shape

- **User instruction:** Discuss **all** gray areas; run **subagent research** for pros/cons, ecosystem patterns, DX, and return **one-shot cohesive recommendations**.
- **Execution:** Four parallel `generalPurpose` research passes; parent agent synthesized into `60-CONTEXT.md` decisions **D-01–D-11**.

---

## 1 — `scripts/ci/README.md` ownership layout

| Option | Description | Selected |
|--------|-------------|----------|
| A — New milestone-style section | Same table schema as ADOPT/ORG; INT/v1.16 rows | ✓ Primary |
| B — Extend ADOPT/ORG only | When REQ is semantically adoption/org | ✓ Conditional |
| C — PR-only / minimal | Changelog or inline only | ✗ Not sole SSOT |

**User's choice:** Delegated to research synthesis — **A primary**, **B** when taxonomy fits, **C** supplement only.  
**Notes:** Elixir OSS median is lighter than Accrue’s registry; Kubernetes-style explicitness matches existing file. Footgun: PR-only discoverability.

---

## 2 — Matrix vs evaluator walkthrough parity

| Option | Description | Selected |
|--------|-------------|----------|
| Strict | Step ↔ row ↔ README anchor | ✗ Deferred without automation |
| Narrative | Same lane honesty; loose commands | Partial (insufficient alone) |
| Hybrid | Matrix = claims; walkthrough = journey + stable refs to matrix | ✓ |

**User's choice:** Research synthesis — **hybrid default** (CONTEXT D-04–D-06).  
**Notes:** K8s conformance pairs machine truth + human reproduction narrative, not line-by-line doc parity to every test.

---

## 3 — v1.15 trust signals in matrix + walkthrough

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit long copy | Repeat full trust narrative | ✗ |
| Thin links only | Risk evaluators never open SSOT | Partial risk |
| Hybrid stubs + links | Bold atomic bullets + deep links to First Hour / host README | ✓ |

**User's choice:** Research synthesis — **Diátaxis** + Stripe/Twilio/MDN-style boundary stubs (CONTEXT D-07–D-08).

---

## 4 — Contributor map update scope

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow | Only checks touched in phases 59–61 | ✓ |
| Broad | Full `ci.yml` + all scripts refresh | ✗ → separate hygiene phase |

**User's choice:** Research synthesis — **narrow + explicit scope note** pointing normative SSOT to `ci.yml` + branch protection (CONTEXT D-09–D-11).

---

## Claude's discretion

- Section titles, optional stable row IDs for matrix rows, exact triage bullet wording.

## Deferred ideas

- Full-map CI audit phase; strict parity automation.
