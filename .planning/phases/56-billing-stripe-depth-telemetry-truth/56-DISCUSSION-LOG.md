# Phase 56: Billing / Stripe depth + telemetry truth - Discussion log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`56-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 56 — Billing / Stripe depth + telemetry truth  
**Areas discussed:** BIL-01 capability choice; Fake + webhook test depth; BIL-02 telemetry/docs; public API + semver DX  
**Mode:** `[--all]` gray-area selection + maintainer-requested **parallel subagent research** + single-pass synthesis (no interactive conversational prompting in host UI)

---

## 1 — Which single BIL-01 capability

| Option | Description | Selected |
|--------|-------------|----------|
| A — List payment methods | `Accrue.Billing` wraps existing `Processor.list_payment_methods/2` | ✓ |
| B — Confirm PI/SI | Public confirm for SCA-complete flows | |
| C — Get/sync subscription schedule | Read + optional projection sync | |
| D — Retrieve coupon/promo | Read-only retrieve | |
| E — Update payment method | Wrap processor update | |

**User's choice:** Delegated to research synthesis — **Option A** locked in **`56-CONTEXT.md` D-01** (processor already complete; smallest bounded read surface; aligns Fake + span + docs).

**Notes:** Subagent compared operator value, test cost, webhook coupling, and **`lattice_stripe`** readiness; noted **`list_charges`**-style work is **not** thin today (501 / missing intents).

---

## 2 — Fake + test depth

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal | `BillingCase` + Fake + fixtures; no new ingest unless needed | ✓ |
| Medium | `Ingest.run` / `DispatchWorker` + DB assertions | (conditional per D-06) |
| Full trees | Large Stripe JSON fixtures | ✗ |

**User's choice:** **Minimal default** with **conditional** ingest/handler tests only if list work ties to projection/webhook invalidation (**56-CONTEXT D-05–D-07**).

**Notes:** Subagent cited **`webhook_ingest_test.exs`**, **`Accrue.Test.Webhooks.trigger/2`**, **`HostFlowProofCase`**, **`guides/testing.md`**; Pay/Cashier lesson = fixture drift + flaky live Stripe → Accrue’s **Fake-first + tagged `live_stripe`** split preserved.

---

## 3 — BIL-02 telemetry + guides

| Option | Description | Selected |
|--------|-------------|----------|
| Firehose only | Extend billing span docs + span coverage test | ✓ |
| New ops row | Add `[:accrue, :ops, :*]` for list | ✗ (default) |
| Runbook mini-playbook | Revenue-adjacent triage | ✗ unless ops row appears |

**User's choice:** **Firehose-only** documentation for this slice; **single ops table** preserved; **contract tests > grep** for inventory (**56-CONTEXT D-10–D-12**).

**Notes:** Subagent reinforced Phase **40** / **45** — semantics blocks only when **multi-origin / alert semantics** matter; footguns = duplicate tables, retry noise, stale OTel examples.

---

## 4 — Public API + semver

| Option | Description | Selected |
|--------|-------------|----------|
| New functions + `!` | Additive `list_payment_methods` / `!` on façade | ✓ |
| New opts only | Extend unrelated arity | ✗ |
| Breaking rename | N/A | ✗ |

**User's choice:** **New paired functions**, **CHANGELOG**, optional **`@doc since:`**, **no default behavior change** (**56-CONTEXT D-14–D-17**).

**Notes:** Subagent referenced **`guides/upgrade.md`**, **`CHANGELOG.md`** style, Cashier/Stripe-PHP exposure issue class, keyword keys as soft ABI.

---

## Claude's discretion

- **`56-CONTEXT.md`** “Claude's discretion” subsection lists implementation flex that does not require replanning.

## Deferred ideas

- See **`56-CONTEXT.md` `<deferred>`** — confirm PI/SI, schedule read/sync, coupon retrieve, update PM.
