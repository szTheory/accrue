# Phase 42: Operator runbooks - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `42-CONTEXT.md` — this log preserves research synthesis and rationale.

**Date:** 2026-04-22  
**Phase:** 42 — Operator runbooks  
**Mode:** User selected **all** gray areas + requested **parallel subagent research** and a **one-shot coherent recommendation set** (no interactive Q&A menu).

**Areas covered:** (1) Doc topology, (2) Oban queue specificity, (3) Action granularity, (4) Stripe/Dashboard boundary.

---

## Synthesis (subagent research → locked architecture)

Four `generalPurpose` subagents produced independent memos; the maintainer-facing convergence below is what was written to `42-CONTEXT.md`.

### 1 — Doc topology

| Approach | Summary | Verdict |
|----------|---------|---------|
| Monolith (`telemetry.md` only) | Single URL, no cross-link drift; risks two-audience page (reference vs incident), heavy PRs | Secondary |
| Split linked guide | SSOT catalog stays in `telemetry.md`; procedures get stable URL + clearer intent; requires disciplined “no second table” rule | **Selected** |

**Footguns avoided:** duplicate ops inventory tables; mixed SSOT.

### 2 — Oban queue specificity

| Approach | Summary | Verdict |
|----------|---------|---------|
| Heavy inline only | Fast until stale; duplicates queue facts across rows | Rejected |
| Appendix only | Accurate; extra hop under stress | Partial |
| **Hybrid** | Canonical matrix + one-line `queue + §anchor` per scan surface | **Selected** |

**Ecosystem alignment:** Oban separates configured queues vs per-worker `queue:` options — a central atlas matches real Elixir ops practice.

### 3 — Action granularity

| Approach | Summary | Verdict |
|----------|---------|---------|
| One-liners everywhere | Best default for a library; RUN-01 satisfied at minimum | **Default** |
| Mini-playbooks (subset) | Ordered steps where wrong action hurts idempotency / money / migrations | **For 4 signals only** |
| Full playbooks everywhere | High maintenance, host mismatch, skim risk | Rejected |

**Signals chosen for expansion:** `webhook_dlq/dead_lettered`, `events_upcast_failed`, `meter_reporting_failed`, `revenue_loss`.

### 4 — Stripe boundary

| Approach | Summary | Verdict |
|----------|---------|---------|
| Ultra-minimal only | Low maintenance; weak discriminating verification | Insufficient alone |
| Dashboard deep links everywhere | Fast until Stripe UI churn | Avoid as normative |
| **Two-layer** | Accrue-local triage + Stripe **resource type + id** + **stripe.com/docs** anchors; functional Dashboard words sparingly | **Selected** |

**Ecosystem alignment:** Pay defers processor truth; Cashier names concrete operational URLs where useful; Stripe docs remain durable compared to Dashboard paths.

---

## Claude's Discretion (from discussion)

- Exact markdown structure inside `operator-runbooks.md`, anchor naming, optional ExDoc group tweaks, optional CI for queue-name drift.

---

## Deferred Ideas

- See `42-CONTEXT.md` `<deferred>` for optional CI and sidebar follow-ups.
