---
gsd_state_version: 1.0
milestone: v1.28
milestone_name: milestone
status: completed
last_updated: "2026-04-25T22:00:00Z"
last_activity: "2026-04-25 — Phase 88 (Mailglass Foundation) execute complete: Plans 01 (path deps), 02 (/dev/mail mount + automated tests), 03 (migration docs + VERIFICATION) all shipped. Awaiting verifier gate."
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 3
  completed_plans: 3
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-24)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** **v1.28** — Phases **86–87** **Complete** **2026-04-24**; next forcing function is **linked Hex publish** per **`RELEASING.md`**.

## Current Position

**Milestone:** **v1.29** — Mailglass Integration (in progress)

**Phase:** **88** — Mailglass Foundation — **Plans 01–02 Complete 2026-04-25**

**Plan:** **`088-02-PLAN.md`** **Complete** — `088-03-PLAN.md` next (Phase 88 final plan)

**Status:** Phase 88 Plans 01–02 complete — path deps wired, `/dev/mail` mounted in router with automated route-existence tests. Phase 88 Plan 03 (migrations) remains.

**Last activity:** 2026-04-25 — Phase **88** Plan **02** (dev-preview-mount): mounted `mailglass_admin_routes("/dev/mail")` as sibling dev-gated scope in `accrue_admin/2` macro; 3 ExUnit route-existence tests added (shift-left automation replaces human browser-verify checkpoint).

## Milestone Progress

**v1.28** (planning **2026-04-24**): Phases **86–87** **Complete** (**`086-VERIFICATION.md`**, **`087-VERIFICATION.md`**); live **`.planning/REQUIREMENTS.md`** (**PPX-05..08**, **INV-06**).

**v1.27** (shipped **2026-04-24**): Phases **84–85** — **CLS-01..03**, **INV-05**; **`milestones/v1.27-phases/`**; archives **`v1.27-ROADMAP.md`**, **`v1.27-REQUIREMENTS.md`**; tag **`v1.27`**.

**Friction inventory (FRG-01):** `.planning/research/v1.17-FRICTION-INVENTORY.md`  
**North star + stop rules (FRG-02):** `.planning/research/v1.17-north-star.md`

**Last shipped (public packages on Hex):** **`accrue` / `accrue_admin` 0.3.1`**

## Current Planning Artifacts

- **`.planning/REQUIREMENTS.md`** — **v1.28** (**PPX-05..08** + **INV-06** complete)
- **`.planning/ROADMAP.md`** — **v1.28** Phases **86–87** + shipped history
- **`086-VERIFICATION.md`** / **`087-VERIFICATION.md`** — **`.planning/milestones/v1.28-phases/`**

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| uat_gap | Phase **62** **`62-UAT.md`** | **closed** — **v1.18** |

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260425-gr1 | Drop deprecated flat-branding-keys infrastructure | 2026-04-25 | 50f80db | [260425-gr1-drop-deprecated-flat-branding-keys-infra](./quick/260425-gr1-drop-deprecated-flat-branding-keys-infra/) |
| 260425-imj | Strip GSD requirement-ID artifacts from public hexdocs | 2026-04-25 | c855743 | [260425-imj-strip-gsd-requirement-ids-from-public-he](./quick/260425-imj-strip-gsd-requirement-ids-from-public-he/) |

## Recent Decisions

- **2026-04-25:** **Phase 88 Plan 02** — Sibling scope pattern: `mailglass_admin_routes` mounted OUTSIDE the `:accrue_admin` live_session to avoid nested live_session conflict; Phoenix forbids nested `live_session` blocks.
- **2026-04-25:** **Phase 88 Plan 02** — Shift-left: human browser-verify checkpoint replaced with ExUnit `__routes__/0` assertions — route existence verified at compile time.
- **2026-04-25:** **Phase 88 Plan 01** — Path is `../../mailglass` (not `../mailglass`) — accrue packages are two levels below `~/projects/`.
- **2026-04-25:** **Phase 88 Plan 01** — `only: [:dev, :test]` for mailglass_admin (not `:dev` only) — test env compiles `accrue_admin/2` macro expansion which imports `MailglassAdmin.Router` at compile time.
- **2026-04-25:** **Phase 88 Plan 01** — Fixed mailglass credo checks compilation: moved 13 custom credo check files from `lib/mailglass/credo/` to `credo_checks/` in the mailglass sibling repo, matching the accrue pattern.
- **2026-04-24:** **v1.28** opened — **spine B** (**next linked publish** + **INV-06**); **not** **1.0.0** (**spine A**) unless reprioritized.
- **2026-04-24:** **Phase 86** — **PPX-05..08** contract re-verification at **0.3.1** documented in **`086-VERIFICATION.md`** (no new SemVer bump in this pass).
- **2026-04-24:** **Phase 87** — **INV-06** dated maintainer pass **(b)** + **`087-VERIFICATION.md`** closed per **`.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/`**.

**Next:** Phase **88** Plan **03** — verify the three Mailglass migrations execute in the host application.

**Completed (v1.29 Phase 88):** Plans 01–02 — **`milestones/v1.29-phases/088-mailglass-foundation/088-01-SUMMARY.md`**, **`088-02-SUMMARY.md`**.

**Completed (v1.28):** Phases **86–87** — **`milestones/v1.28-phases/086-post-publish-contract-alignment/`**, **`087-friction-inventory-post-publish/`**.

**Completed (v1.27):** Phases **84–85** — **`milestones/v1.27-phases/`**.
