# Phase 26: Hierarchy and pattern alignment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `26-CONTEXT.md`.

**Date:** 2026-04-20  
**Phase:** 26 — Hierarchy and pattern alignment  
**Areas discussed:** INV-driven scope and sequencing; refactor depth (minimal vs wave vs big-bang); verification strategy (ExUnit / Floki / Playwright); UX-04 token exceptions  

**Method:** User selected **all** gray areas and requested **parallel subagent research** + one-shot synthesis. Four `generalPurpose` research passes; parent agent merged into coherent **D-01..D-04** in CONTEXT.

---

## 1. INV-driven scope and sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| A — INV-03 tags only | Work only rows tagged Phase 26 | |
| B — Requirements-only | UX-01..04 order; INV optional | |
| C — INV-01 route order | Walk route matrix top to bottom | |
| D — Hybrid | Requirements = done bar; INV-03 rows + evidence per slice; INV-01 for ownership | ✓ |

**User's choice:** **Hybrid (D)** — research consensus: avoids under-shipping UX-01..04 and avoids coverage-theatre route ordering; preserves Phase 25 traceability.  
**Notes:** Work order locked as **UX-01 → UX-02 → UX-03 → UX-04** waves.

---

## 2. Refactor depth (touched surfaces)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Surgical only | Fix only spec contradictions | Partial |
| B — Bounded wave | Money + webhooks consistency | ✓ |
| C — Big bang | New layout API everywhere | Rejected |

**User's choice:** **Wave B with A’s discipline** — normative domain wave; surgical within file; reject library-wide rewrite.  
**Notes:** Stable `ax-*` + `data-role` as semver-relevant surface for v1.x.

---

## 3. Verification strategy

| Layer | Description | Selected |
|-------|-------------|----------|
| LiveViewTest + Floki | Structure / nesting in `accrue_admin` | ✓ Primary |
| Raw `html =~` | Cheap needles | ✓ Supplement |
| Playwright in package | Second browser matrix | Rejected |
| Host Playwright | Mounted realism, VERIFY-01 | ✓ Extend only when LV cannot prove risk |

**User's choice:** **Elixir-first** structure gate; **Floki** for hierarchy; **host Playwright** only for gaps LiveViewTest cannot express; align Phase 21 test pyramid.

---

## 4. UX-04 token exceptions

| Option | Description | Selected |
|--------|-------------|----------|
| Narrative phase notes only | Weak grep | Rejected |
| ADR per tint | Heavy for small literals | Optional for structural breaks only |
| Single registry + theme.css contract | Auditable, grepable | ✓ |
| CHANGELOG per hex | Noise | Rejected |

**User's choice:** **`theme.css` semantic contract** + **`26-theme-exceptions.md`** registry (+ optional CI grep later).  
**Notes:** Prefer named CSS variables for “exceptional” values at call sites.

---

## Claude's Discretion

- CI script shape for hex allowlist; direct vs transitive **Floki** test dependency (see CONTEXT).

## Deferred Ideas

- Library-wide `<.ax_*>` component migration as default public API — deferred past Phase 26 scope.
