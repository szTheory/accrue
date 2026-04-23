# Phase 63: P0 integrator / VERIFY / docs - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`63-CONTEXT.md`**.

**Date:** 2026-04-23  
**Phase:** 63 — P0 integrator / VERIFY / docs  
**Areas discussed:** P0-001 pins/Hex/First Hour; P0-002 host-integration discoverability; P0 closure vs downgrade governance; Phase 63 verification depth  

**Method:** User selected **all** gray areas and requested parallel **subagent** research plus a **single synthesized** recommendation set (no per-turn interactive Q&A).

---

## P0-001 — Pins / Hex / First Hour / `@version`

| Approach | Description | Selected |
|----------|-------------|----------|
| A — Verifier + `@version` SSOT + prose for Hex vs main | Keep **`verify_package_docs`**, add/keep explicit integrator prose (three facts + pre-1.0 honesty); optional dual Hex/path snippets only if verifier-constrained | ✓ |
| B — Dual blocks without automation | Two snippets without strict enforcement | |
| C — Generator-first | `mix accrue.install` as canonical snippet source | |
| D — Relax verifier | Human-owned pins | |

**User's choice:** Research-synthesized lock — **A** (see **D-01** in **63-CONTEXT.md**).  
**Notes:** Idiomatic **Hex / nimble_*** pattern is **one dep line + explicit edge section**; cross-ecosystem **Cashier/Pay/Stripe** teach **stable vs bleeding edge** headings and **lockfile** honesty.

---

## P0-002 — `host-integration` failure discoverability

| Approach | Description | Selected |
|----------|-------------|----------|
| A — Doc-only triage table | **`scripts/ci/README.md`** only | Partial |
| B — Split CI jobs / many steps | Maximum GitHub UI clarity, higher churn + minutes | |
| C — GitHub annotations only | `::error` wrappers | Optional later |
| D — Ordered sub-gates + stderr prefixes + failure banner | Single job, grep-first DX; mirror **`[verify_package_docs]`** | ✓ |

**User's choice:** **D** primary + **A** as short contributor map row (**D-02** in context).  
**Notes:** **Phoenix/Oban**-style clarity favors **named phases**; **K8s-style runbooks** complement, not replace, **signals in logs**.

---

## P0 closure vs downgrade governance

| Approach | Description | Selected |
|----------|-------------|----------|
| Strict ship-only | Never downgrade | |
| Hybrid default-ship + governed downgrade | Mini-ADR notes + needle law for true demotion | ✓ |
| Silent downgrade | Edit without inventory trace | |

**User's choice:** **Hybrid** — **D-03** in context (RFC-style fields; **`verify_v1_17_friction_research_contract.sh`** table invariants).

---

## Phase 63 verification artifact depth

| Approach | Description | Selected |
|----------|-------------|----------|
| Heavy UAT / long narrative | Restate **`ci.yml`** in markdown | |
| Lean traceability + verifier-as-test | Scope + table + CI vs manual + handoff to 64/65 | ✓ |

**User's choice:** **Lean** — **D-04** in context, aligned with **62-VALIDATION.md** markdown-first planning precedent.

---

## Claude's Discretion

- Exact **`FAILED_GATE`** / prefix strings if not already standardized — implementer chooses consistent naming; prefer **tested** log output where a new contract is introduced.

## Deferred Ideas

- Split **`host-integration`** job — deferred per **63-CONTEXT.md** `<deferred>`.
