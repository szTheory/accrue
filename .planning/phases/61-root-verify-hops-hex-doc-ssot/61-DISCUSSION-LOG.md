# Phase 61: Root VERIFY hops + Hex doc SSOT - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`61-CONTEXT.md`**.

**Date:** 2026-04-23  
**Phase:** 61 — Root VERIFY hops + Hex doc SSOT  
**Areas discussed:** All four gray areas (user: “all”), with parallel research subagents per area.

---

## Selection

**User's choice:** Discuss **all** areas in one pass with **research-backed** defaults (no per-area interactive Q&A in chat).

---

## Area 1 — Root README vs ADOPT-01 hop budget (INT-08)

| Approach | Description | Selected |
|----------|-------------|----------|
| A | Thin root + deep host README | ✓ (part of hybrid) |
| B | Fully self-contained root proof block |  |
| C | Explicit hop map in root | ✓ (conditional) |
| D | Machine-verified hop semantics | ✓ (narrow invariants only) |

**Research notes:** Elixir OSS (Phoenix, Ecto, Oban, Broadway) typically uses **README as front door** + **guides/example app** for depth. Other ecosystems (Rails gem dummy apps, Laravel packages, Stripe/Twilio READMEs) reward **one obvious command** and punish **dual SSOT** between root and example README.

**Locked in CONTEXT:** **D-01–D-03** (hybrid IA, conditional micro hop map, narrow machine checks).

---

## Area 2 — Where the root README contract lives (INT-08)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Fold everything into `verify_package_docs` only |  |
| B | Extend `verify_verify01` for root README |  |
| C | New dedicated root README script |  |

**Research notes:** **`verify_package_docs`** already pins root README proof strings and runs via **`accrue` `mix test`** in **`release-gate`**. **`verify_verify01`** is **`host-integration`** shift-left with **dynamic/semantic** checks — different blast radius. Third script hurts the **bash trio** mental model unless internal modularization.

**Locked in CONTEXT:** **D-04–D-07** (keep split, no third script, dedupe rule).

---

## Area 3 — `.planning` mirrors for Hex vs `main` (INT-09)

| Approach | Description | Selected |
|----------|-------------|----------|
| Single number everywhere | Collapse Hex + `main` |  |
| Two-line / dual-authority | Branch `@version` vs registry “last published” | ✓ |
| Hex API in every PR | Automated planning line |  |

**Research notes:** Release Please / Cargo / npm patterns separate **workspace version** from **registry artifact**. Accrue already leans on **`verify_package_docs`** for branch truth.

**Locked in CONTEXT:** **D-08–D-10**.

---

## Area 4 — Package docs + First Hour when `@version` leads Hex (INT-09)

| Approach | Description | Selected |
|----------|-------------|----------|
| A | Pins track `@version` (verifier SSOT) | ✓ |
| B | Pins track last Hex only |  |
| C | Dual pins everywhere |  |
| D | No literal pins |  |

**Research notes:** Phoenix/Oban/LiveView favor **explicit “main may be ahead”** + **HexDocs for stable**. Footgun: claiming **Hex release** for an unpublished bump.

**Locked in CONTEXT:** **D-11–D-12**.

---

## Claude's discretion

- Hop map trigger and wording (**D-02**).
- Dedupe ordering (**D-07**).
- Optional ExUnit wrapper for **`verify_verify01`** — deferred.

## Deferred ideas

- Hex API / release-only planning check — see **CONTEXT** `<deferred>`.
