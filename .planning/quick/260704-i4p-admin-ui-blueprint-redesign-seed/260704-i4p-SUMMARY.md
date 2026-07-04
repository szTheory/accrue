---
quick_id: 260704-i4p
slug: admin-ui-blueprint-redesign-seed
date: 2026-07-04
status: complete
type: docs / roadmap-seeding
---

# Summary 260704-i4p: Admin-UI blueprint redesign seeded (SEED-004)

## What was done

Digested the maintainer's ~94KB admin/operator UI journey blueprint into durable planning
artifacts and seeded it as a **post-v1.56** GSD redesign program. Docs-only; no code, no
milestone opened.

**Artifacts created / edited:**
- **NEW** `.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md` — self-contained synthesis
  (verdict, ~16 load-bearing ideas, delta vs current 6-group/21-screen baseline, pros/cons +
  patterns/antipatterns/footguns checklist, posture reconciliation, core-`accrue` §45 dependency,
  recommended M1/M2/M3 decomposition, ratchet relationship, source pointers).
- **NEW** `.planning/seeds/SEED-004-admin-ui-blueprint-redesign.md`.
- **EDIT** `.planning/ROADMAP.md` — one row added to "Deferred Seeds and Ideas" (SEED-004).
- **NEW** memory `project_admin_ui_blueprint_redesign_seed.md` + MEMORY.md pointer (outside repo).

## Key decisions carried

- Blueprint adopted as the **north-star target**; it's a genuine NEW target, distinct from the
  v1.56 ratchet (machinery). Sequence: finish v1.56 → open redesign via `/gsd-new-milestone`.
- Kept v1.56 pure (no mid-flight retarget); recorded the downstream ratchet-refresh as a later step.
- Flagged the **core-`accrue` diagnosis dependency** (first non-admin-only scope in the admin-UI line).
- Recommended a 3-milestone decomposition (M1 IA/grammar pivot → M2 signature surfaces + core
  diagnosis → M3 new rooms + ratchet re-freeze); NOT locked — `/gsd-new-milestone` formalizes.

## Notable

- Authored by the orchestrator (held the full digest from 3 Explore agents) instead of spawning a
  fresh gsd-executor, to avoid re-exploration and preserve synthesis fidelity for a pure docs task.
- Confirmed "Threadline" (and scoria/scrypath/etc.) in `.planning/` are **sibling sztheory libs /
  legit Accrue integration seeds**, NOT cross-contamination — surfaced after a maintainer concern.

## Verification

All artifacts + ROADMAP row + MEMORY.md pointer present and render cleanly. No v1.56
REQUIREMENTS/STATE milestone scope or phase files touched. No code changed. No milestone opened.
