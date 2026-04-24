# Phase 81: Telemetry truth + integrator contracts - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`081-CONTEXT.md`**.

**Date:** 2026-04-24  
**Phase:** 81 — Telemetry truth + integrator contracts  
**Areas discussed:** INT-12 same-PR vs deferral; `telemetry.md` catalog shape; `operator-runbooks.md` depth; CHANGELOG strategy; GSD shift-left defaults  
**Mode:** User requested **all** areas + parallel **research subagents** + one-shot cohesive recommendations (no per-turn interactive Q&A).

---

## INT-12 — Golden-path + verifier co-update

| Option | Description | Selected |
|--------|-------------|----------|
| A — Same PR | Any golden-path / merge-blocking mention of `create_checkout_session` → update coupled verifiers + harnesses in one PR per `scripts/ci/README.md`. | ✓ |
| B — Signed deferral | Only if surfaces unchanged; `81-VERIFICATION.md` with dated milestone hook; no silent drift. | (narrow exception) |

**User's choice:** Delegated to research synthesis — **default A**; **B** only under **REQUIREMENTS**’s explicit conditions.  
**Notes:** Subagent cited Pay/Cashier/SDK lag patterns; Accrue’s needle investment makes **A** lower total cost than evaluator confusion.

---

## `guides/telemetry.md` — Checkout row density

| Option | Description | Selected |
|--------|-------------|----------|
| Parity row | Match `billing_portal.create` row; OTel name, tuple, emitter, phase ref, allowlisted metadata keys + PII reminder. | ✓ |
| Minimal line | Tuple/name only; detail in `@doc` only. | |

**User's choice:** **Parity row** (operator SSOT + grep-first DX; ecosystem norm for Phoenix/Ecto/Oban-style telemetry guides).

---

## `operator-runbooks.md` — Checkout support surface

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated mini-playbook | Full Fake vs Stripe / common errors matrix. | |
| Light pointer | Same family as billing portal paragraph + link to `telemetry.md`. | ✓ |
| Telemetry only | No runbook mention. | |

**User's choice:** **Light pointer** — revenue/support-adjacent but Stripe-owned failure detail; escalate only when Accrue-specific **ops** semantics warrant RUN-01 depth.

---

## CHANGELOG — BIL-07 + INT-12 slice

| Option | Description | Selected |
|--------|-------------|----------|
| Atomic KAC bullets | Separate bullets per concern under standard headings. | ✓ |
| Single narrative block | Milestone story only. | |
| Minimal one-liner | References BIL-07/INT-12 only. | |

**User's choice:** **Atomic bullets** + optional one-sentence milestone framing (Keep a Changelog + Hex scanner personas).

---

## Claude's Discretion

- Wording of runbook pointer and changelog bullets.  
- Layout of signed deferral table if **INT-12** path **B** is invoked.

## Deferred ideas

- Full checkout runbook depth — deferred until **ops**-level checkout signals exist (**081-CONTEXT** D-09).
