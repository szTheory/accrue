# Phase 27: Microcopy and operator strings - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `27-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-20  
**Phase:** 27 — Microcopy and operator strings  
**Areas discussed:** Stable literals (COPY-03), Empty-state voice (COPY-01), Errors/flashes/destructive confirms (COPY-02), Surface scope (INV-03 normative vs broad)  
**Mode:** User selected **all** areas and requested **parallel `generalPurpose` subagent research**; primary agent synthesized one coherent decision set (no per-turn conversational prompting transcript).

---

## Stable literals (COPY-03)

| Option | Description | Selected |
|--------|-------------|----------|
| A — `AccrueAdmin.Copy` module(s) | Elixir functions/constants as SSOT; jump-to-definition; tests import same API | ✓ (core) |
| B — Markdown manifest + CI grep | Doc-first allowlist; high drift + grep fragility | |
| C — Hybrid | Copy module authoritative + optional generated doc or duplicate-literal CI | ✓ (full approach) |

**User's choice:** **Hybrid (C)** centered on **`AccrueAdmin.Copy`** with optional CI / generated docs; Playwright prefers roles/`data-role` + selective exact text.  
**Notes:** Subagent compared Pay/Filament centralization vs ActiveAdmin sprawl; warned against hand-maintained manifest as sole SSOT and gettext coupling for v1.6.

---

## Empty-state voice (COPY-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Keep “Adjust filters / wait” rhythm | Predictable but interface-first; banner blindness | |
| Full Phase 20 paragraph on every table | Spec-aligned but mobile-unfriendly | |
| Two-tier (state-first lists + locked blocks where spec applies) | Short titles + one-sentence billing cause + verify hint; Tier B uses Phase 20 locks | ✓ |

**User's choice:** **Two-tier** system per synthesized research; jargon out of primary chrome; avoid false timing promises.  
**Notes:** Stripe-class pattern: business object in title, mechanics secondary.

---

## Errors, flashes, destructive confirms (COPY-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Big-bang repo sweep | Single voice; merge/review risk | |
| Scattered one-line PRs | Low conflict; copy drift | |
| Risk waves + per-flow coordination + copy tiers A/B/C | Money → webhooks → step-up/dashboard; locked strings centralized; kitchen/dev exempt with docs | ✓ |

**User's choice:** **Waves + per-flow** with **Tier A/B/C** contract and **CHANGELOG** subsection for host-visible copy.  
**Notes:** Pay issue trajectory cited by subagent—integrators treat flash text as integration surface.

---

## Surface scope

| Option | Description | Selected |
|--------|-------------|----------|
| INV-03 normative only | Closed list; INV evidence updates; matches Phase 25 D-03 | ✓ |
| Broad sweep incl. coupons/connect/events/promo | Consistency; breaks INV-03 traceability unless expanded first | |

**User's choice:** **Normative v1.6 surfaces only**; secondary admin deferred with explicit INV-03 promotion path.  
**Notes:** Subagent tied to `25-INV-03` rollup rows (dashboard, money indexes, detail, webhooks, step-up).

---

## Claude's Discretion

- Submodule split and CI mechanism (script vs Credo) left to planner/implementer within bounds of D-01 and D-05.

## Deferred Ideas

- gettext / full-admin i18n — future phase.  
- INV-03 expansion for secondary admin before copy work — policy gate.
