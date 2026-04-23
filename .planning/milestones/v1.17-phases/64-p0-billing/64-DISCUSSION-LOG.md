# Phase 64: P0 billing - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`64-CONTEXT.md`** — this log preserves alternatives considered.

**Date:** 2026-04-23  
**Phase:** 64 — P0 billing  
**Areas discussed:** Closure artifacts, Empty-queue audit bar, CHANGELOG/telemetry when nothing ships, Late P0 routing  
**Method:** User selected **`all`**; four parallel **`generalPurpose`** research subagents; parent synthesized one coherent decision set (**D-01–D-04**).

---

## Closure artifacts (inventory vs `64-VERIFICATION.md` vs friction script)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Signed prose only | Certification under **`### Backlog — BIL-03`** only | Partial ✓ (required floor, not sufficient alone for auditable closure) |
| B — Lean `64-VERIFICATION.md` | Mirror **63**: scope + traceability + proof commands | ✓ |
| C — Extend friction script with BIL-03 semantics | Encode row counts / meaning in bash | ✗ (duplicate SSOT; brittle) |
| C′ — Optional structural-only needles later | e.g. file exists, symmetric 63–65 | Deferred (see **64-CONTEXT** deferred) |

**User's choice:** Synthesized — **A + B** primary; **no semantic C**; optional structural **C′** only as a deliberate trilogy-wide follow-up.

**Notes:** Subagent consensus: Hex/OSS process truth usually lives in **issues/milestones + verification appendices**, not regex on essays; **B** matches **Phase 63** mental model and prevents “trust me” closure.

---

## Empty-queue audit bar

| Option | Description | Selected |
|--------|-------------|----------|
| A — Inventory certification | Meets **BIL-03** `or` branch | ✓ |
| B — Bounded checklist in verification | FRG-03 reconcile + ship/no-ship lines | ✓ |
| C — Merge-blocking prose guards | Regex on inventory | ✗ |

**User's choice:** **A + thin B**; no merge-blocking **C**.

**Notes:** Aligns with Stripe/Cashier/Pay pattern: **automate structure + tests**; keep **narrative closure** human-auditable. Avoid **audit theater** and **CI on prose**.

---

## `CHANGELOG` + `telemetry.md` when nothing ships

| Option | Description | Selected |
|--------|-------------|----------|
| A — No package edits | Silence when no artifact delta | ✓ |
| B — Proactive doc polish | Only for concrete defects | Optional |
| C — CHANGELOG “no P0” line | Process metadata in consumer log | ✗ |

**User's choice:** **A** default; **B** only for evidence-based doc fixes; reject **C**.

**Notes:** **BIL-03** grammar read as: telemetry/changelog obligations attach to the **ship** path; **certify empty** path is satisfied by **inventory + verification**, not Hex diary entries.

---

## Late P0 billing evidence

| Option | Description | Selected |
|--------|-------------|----------|
| A — Always fold into 64 | Execute full ship bar | ✓ **after** triage |
| B — Inventory disposition first | Downgrade / `not_v1.17` / row hygiene | ✓ (mandatory gate) |
| C — Split true P0 vs borderline | Re-triage two-axis bar | ✓ (routing rule) |

**User's choice:** **C implemented via mandatory B**; **A** for rows that **remain** P0 **`BIL-03`** after triage — **no silent absorption**.

**Notes:** Rust RFC / K8s-style traceability + Shape Up appetite — new work enters **FRG-01**, passes axes, then **FRG-03** execution.

---

## Claude's Discretion

- **`64-VERIFICATION.md`** formatting leeway while staying parallel to **63**.
- Optional symmetric friction-script structural checks — explicitly deferred.

## Deferred Ideas

- Symmetric structural CI for **`64-VERIFICATION.md`** / **`65-VERIFICATION.md`** existence alongside **63** — only via intentional milestone-wide PR.
