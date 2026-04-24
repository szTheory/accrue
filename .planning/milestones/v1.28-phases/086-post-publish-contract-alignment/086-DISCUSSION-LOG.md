# Phase 86: Post-publish contract alignment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`086-CONTEXT.md`**.

**Date:** 2026-04-24  
**Phase:** 86 — Post-publish contract alignment  
**Areas discussed:** PR coupling, Verification artifact depth, PPX-08 vs INV-06 split, docs-contracts-shift-left breadth  
**Research mode:** Deep synthesis in orchestrator (repo SSOT + public ecosystem patterns). Workspace policy prefers not spawning non-`gsd-*` subagents; substantive multi-source reasoning inlined below.

---

## Research notes (shared)

**Elixir / Hex / Mix idioms:** [Elixir library guidelines](https://hexdocs.pm/elixir/library-guidelines.html) emphasize semver, tests, and publishable docs — Accrue’s **bash-enforced literals** are a *stronger* variant of “docs match the artifact” than HexDocs alone. **Mix** libraries conventionally keep **`mix.lock`** for apps, not for published libs — our **determinism** shows up in **CI matrices + Fake**, not in consumer lockfiles.

**This repo’s SSOT:** **`RELEASING.md`** (Release Please combined PR, `accrue` before `accrue_admin`), **`scripts/ci/README.md`** (**INT-06** script family, same-PR co-update rules for matrix + script), **Phase 75** verification (first **PPX** tranche).

**Cross-ecosystem (billing libs):** **Laravel Cashier** documents **Stripe API version** coupling per release and steers upgrades through first-party docs — pattern we mirror with **`@version`** + **`upgrade.md`** + **verifiers**. **Rails Pay** historically suffered README/example drift when release cadence outran docs — Accrue’s **merge-blocking** gates are the structural prevention. **Stripe-first** products universally punish “install line says X, server expects Y” — **least surprise** = **one SHA truth**.

**GSD shift-left:** Persisted defaults in **`.planning/config.json`** (`workflow.discuss_default_post_publish_*`, `workflow.discuss_publish_contracts_research_depth`) alongside existing **`discuss_auto_all_gray_areas`**, **`discuss_high_impact_confirm`**, **`research_before_questions`**.

---

## Area 1 — PR coupling (evidence vs `@version` bump)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Same PR | All PPX-touching edits + verifier greens + `086-VERIFICATION.md` in the **combined release / version PR** before `main` merge | ✓ |
| B — Staged | Version merges first; honesty PR later | |
| C — Docs-only hotfix week | Fix verifiers after release when convenient | |

**User's choice:** **A**, with **narrow same-day exception** only for automation misfits — documented in Preconditions (**`086-CONTEXT.md` D-01..D-02**).

**Notes:** **Pros of A:** `main` never lies; matches **Release Please** design; minimizes contributor confusion. **Cons of A:** larger PR surface — mitigated by checklist + existing triage docs. **B/C footguns:** false-green integrator experience; violates project **INT-12** culture.

---

## Area 2 — `086-VERIFICATION.md` depth

| Option | Description | Selected |
|--------|-------------|----------|
| A — Lean (Phase 75) | Preconditions + checklist + sign-off | ✓ (baseline) |
| B — Rich (Phase 82-style) | Full transcripts everywhere | |
| C — Hybrid | Lean spine + transcript annex when gates/requirements change | ✓ (full package) |

**User's choice:** **A+C** — hybrid as **`086-CONTEXT.md` D-03..D-04**.

**Notes:** **B** maximizes audit prose but **taxes maintainer DX** on routine bumps. **Hybrid** preserves **speed by default** and **depth when risk moves**.

---

## Area 3 — PPX-08 vs friction inventory / INV-06

| Option | Description | Selected |
|--------|-------------|----------|
| A — All in 86 | Full inventory maintainer narrative in Phase 86 | |
| B — Split | PPX-08 minimal row + mirror updates in 86; INV-06 substance in 87 | ✓ |
| C — Defer PPX-08 | Push inventory + mirrors to 87 | |

**User's choice:** **B** — **`086-CONTEXT.md` D-05**.

**Notes:** **A** duplicates Phase **87** and creates **dual maintainer passes**. **C** risks leaving **PPX-08** unclosed.

---

## Area 4 — `docs-contracts-shift-left` breadth

| Option | Description | Selected |
|--------|-------------|----------|
| A — Full CI bundle | Evidence matches **entire** `docs-contracts-shift-left` job set | ✓ |
| B — Delta-only | Only scripts touched by PR | |

**User's choice:** **A** — **`086-CONTEXT.md` D-06..D-07**.

**Notes:** **B** is a known OSS footgun (local green / CI red). **INT-06** already names the family — use **`ci.yml`** as authoritative list at execution time.

---

## Claude's Discretion

- Annex formatting and minor checklist ordering — bounded by **D-03..D-04**.

## Deferred Ideas

- None beyond Phase **87** scope already in roadmap.
