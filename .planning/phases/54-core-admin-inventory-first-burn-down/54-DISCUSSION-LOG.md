# Phase 54: Core admin inventory + first burn-down - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`54-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 54 — Core admin inventory + first burn-down  
**Areas discussed:** ADM-07 inventory artifact; ADM-08 anchor flow; P0 definition and VERIFY boundary; Core surface checklist  

**Method:** User selected **all** gray areas; four **parallel `generalPurpose` subagents** produced research memos; maintainer agent synthesized into **`54-CONTEXT.md`** (no interactive conversational prompting — single-shot merge).

---

## 1 — ADM-07 inventory artifact

| Option | Description | Selected |
|--------|-------------|----------|
| A | **`accrue_admin/guides/*.md`** wide matrix, Hex-visible SSOT | ✓ |
| B | **`.planning/phases/54-*` only** | |
| C | Hybrid pointer + planning (drift risk) | |
| D | Narrative + appendix split | (subsumed: primary = new guide; **`admin_ui.md`** links) |

**User's choice:** **A** (with **D-01** elaboration: new **`core-admin-parity.md`**, no duplicate matrix in `.planning`).  
**Notes:** Subagent compared Oban/Req/Phoenix-ecosystem **guides on Hexdocs** vs Rails engine README bloat; rejected hybrid as drift-prone unless planning copy is explicitly non-authoritative.

---

## 2 — ADM-08 money-primary anchor flow

| Option | Description | Selected |
|--------|-------------|----------|
| Invoices | `/invoices` + `/invoices/:id` | ✓ |
| Subscriptions | `/subscriptions` + `/subscriptions/:id` | (fallback per **D-09** only) |
| Customers / charges / webhooks / dashboard | Other candidates | |

**User's choice:** **Invoices** (**D-06**).  
**Notes:** Subagent tradeoff table cited operator value, literal density, Phase 55 axe ROI, and risk of **subscriptions** yielding thinner net-new P0 after Phase 49.

---

## 3 — P0 definition and VERIFY / export_copy_strings boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Strict whole-repo literals | Maximum aesthetic completeness | |
| Anchor closure + touched + asserting tests | Bounded ADM-08 | ✓ |
| New merge-blocking Playwright in Phase 54 | Early a11y | (rejected — **ADM-09**) |

**User's choice:** **P0/P1/P2** definitions **D-10–D-12**; literal discipline **D-13**; **D-14** no new merge-blocking e2e; **D-15** minimal `export_copy_strings` touch only if existing JSON pipeline would break.  
**Notes:** Aligned to roadmap phase split (54 vs 55) and **Phase 53** lesson on **`copy_strings.json`** merge churn.

---

## 4 — Core surface checklist boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Router-only rows | Mount contract = inventory | ✓ |
| Router + `live/` scan for orphans | Hygiene / noise | (optional **D-19** only) |

**User's choice:** **Eleven rows** per **D-17**; exclusions **D-18**; **`/dev/*`** omitted from core table with prose note.  
**Notes:** Subagent provided explicit route ↔ module mapping from **`AccrueAdmin.Router`**.

---

## Claude's discretion

- **`54-VERIFICATION.md`** shape vs **`core-admin-parity.md`** cross-links (**D-22** discretion block in CONTEXT).

## Deferred ideas

- Subscriptions-first or joint invoice+subscription VERIFY group — captured in **`<deferred>`** in **`54-CONTEXT.md`**.
