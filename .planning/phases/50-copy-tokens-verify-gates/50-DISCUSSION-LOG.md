# Phase 50: Copy, tokens & VERIFY gates - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`50-CONTEXT.md`**.

**Date:** 2026-04-22  
**Phase:** 50 — Copy, tokens & VERIFY gates  
**Mode:** User selected **all** gray areas + requested **parallel subagent research** with ecosystem / idiomatic / DX synthesis.

**Areas covered (research + consolidation):**

1. ADM-04 — scope of “v1.12 churn” for `AccrueAdmin.Copy` enforcement  
2. Copy module shape — monolith vs `defdelegate` + `copy/*.ex` + `Locked` boundary  
3. ADM-05 — where token/layout exceptions are documented (register + phase gate)  
4. ADM-06 — definition of “materially touched mounted paths” (explicit inventory)  
5. Playwright + axe — VERIFY-01 extension, LiveView timing, selector + anti-drift strategy  

---

## Synthesis method

| Source | Role |
|--------|------|
| Five **`generalPurpose`** subagents (2026-04-22) | Parallel pros/cons, ecosystem notes (Pay, Cashier, Stripe, design-system practice), Elixir/Hex library norms, VERIFY-01 / Playwright / axe tradeoffs |
| Maintainer (`composer-2-fast` parent) | Merged into **non-contradictory** decisions **D-01–D-25** in **`50-CONTEXT.md`**; resolved path **`accrue_admin/guides/theme-exceptions.md`** to align with existing **`accrue_admin/guides/admin_ui.md`** |

---

## 1 — ADM-04 scope

| Approach | Description | Verdict |
|----------|-------------|---------|
| Git-diff-only gate | Block on diff vs `main` | **Rejected** as primary gate (noise, unrelated edits) |
| Whole `accrue_admin/lib` | Any touched file | **Rejected** (over-broad contributor tax) |
| Manifest-only | Static file list | **Partial** — rots without tying to UI globs |
| **Hybrid (chosen)** | **Glob allowlist** + Phase 48/49 named surfaces + **documented escapes**; diff as **secondary** | **Selected** — see **D-01**, **D-02** in CONTEXT |

**User's direction:** “One-shot coherent recommendations” — encoded as **D-01–D-04** + **D-23** (anti-drift with Playwright).

---

## 2 — Copy module shape

| Approach | Verdict |
|----------|---------|
| Monolith forever | **Rejected** at Phase 50 scale |
| Public `Copy.*` + private domain modules + **`defdelegate`** | **Selected** — **D-05–D-09** |
| Behaviour/protocol now | **Deferred** — **D-09** |

---

## 3 — ADM-05 documentation

| Approach | Verdict |
|----------|---------|
| Phase notes only | **Insufficient** for OSS discoverability |
| **Register + phase link + PR checkbox + inline pointer** | **Selected** — **D-10–D-14** |
| ADR per exception | **Rejected** for normal rows |

---

## 4 — ADM-06 path coverage

| Definition | Verdict |
|------------|---------|
| Narrow (only last diff) | **Rejected** as milestone sign-off |
| Broad (full README matrix) | **Rejected** for Phase 50 cost |
| **Medium — explicit v1.12 inventory** | **Selected** — **D-15–D-17** |

---

## 5 — Playwright + axe

| Topic | Verdict |
|-------|---------|
| New CI lane | **Rejected** (**D-17**) |
| Extend `verify01-admin-a11y.spec.js` first | **Selected** (**D-18**) |
| `networkidle` for LiveView | **Rejected** (**D-20**) |
| Role/label first; `data-test-id` scalpel | **Selected** (**D-22**) |
| **Copy ↔ JS literal anti-drift mechanism** | **Required** (**D-23**) |

---

## Claude's Discretion

Inventory file location and exact **D-23** mechanism left to planner within bounds stated in **`50-CONTEXT.md`**.

## Deferred Ideas

Captured in **`<deferred>`** in **`50-CONTEXT.md`** (Gettext milestone, nightly matrix, per-row ADRs).
