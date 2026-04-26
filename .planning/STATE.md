---
gsd_state_version: 1.0
milestone: v1.30
milestone_name: INV-07 maintainer pass
status: Roadmap drafted — awaiting `/gsd-plan-phase 91`
last_updated: "2026-04-26T21:51:07.220Z"
last_activity: 2026-04-26 — v1.30 ROADMAP.md written, REQUIREMENTS.md traceability populated (12/12 mapped)
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-24)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** **v1.30 planning open (2026-04-26)** — `1.0.0` Declaration (Spine A): linked Hex publish, post-publish contract sweep, planning mirror, stability-posture flip, dated post-1.0 friction-inventory pass. Phases **91–93** drafted in [`ROADMAP.md`](ROADMAP.md). **PROC-08 / FIN-03 reaffirmed out of scope** at 1.0.0 (DOC-04).

## Current Position

Phase: 91 Pre-publish 1.0.0 prep — context gathered (REL-06, REL-07, DOC-03, DOC-04)
Plan: —
Status: `091-CONTEXT.md` committed — awaiting `/gsd-plan-phase 91`
Resume file: `milestones/v1.30-phases/091-pre-publish-prep/091-CONTEXT.md`
Last activity: 2026-04-26 — Phase 91 context gathered via advisor-style cohesive synthesis (4 parallel research agents, no high-impact forks); auto-applied: A1 sequencing (separate pre-bump PR), hybrid CHANGELOG preamble in `## Unreleased`, replace-in-place `RELEASING.md` post-1.0 cadence, two-pass scoped doc flip (READMEs + maturity-and-maintenance + upgrade), dated DOC-04 sub-section

## Milestone Progress

**v1.30** (planning **2026-04-26**): Phases **91–93** **planned** — **REL-05..08**, **PPX-09..12**, **HYG-02**, **DOC-03..04**, **INV-07** mapped 12/12 in [`REQUIREMENTS.md`](REQUIREMENTS.md). Phase tree: `milestones/v1.30-phases/` (created on `/gsd-plan-phase 91`). Spine A — `1.0.0` declaration. **No** **PROC-08** / **FIN-03**.

**v1.29** (shipped **2026-04-26**): Phases **88–90** — **MG-01..MG-07**; **`milestones/v1.29-phases/`**; archives **`v1.29-ROADMAP.md`**, **`v1.29-REQUIREMENTS.md`**; tag **`v1.29`**.

**v1.28** (planning closed **2026-04-24**): Phases **86–87** **Complete** (**`086-VERIFICATION.md`**, **`087-VERIFICATION.md`**); **PPX-05..08**, **INV-06** validated. Not separately tagged — superseded by v1.29 forcing function.

**v1.27** (shipped **2026-04-24**): Phases **84–85** — **CLS-01..03**, **INV-05**; **`milestones/v1.27-phases/`**; archives **`v1.27-ROADMAP.md`**, **`v1.27-REQUIREMENTS.md`**; tag **`v1.27`**.

**Friction inventory (FRG-01):** `.planning/research/v1.17-FRICTION-INVENTORY.md`  
**North star + stop rules (FRG-02):** `.planning/research/v1.17-north-star.md`

**Last shipped (public packages on Hex):** **`accrue` / `accrue_admin` 0.3.1`** — v1.30 will cut **`1.0.0`** as a coordinated linked publish (REL-05).

## Current Planning Artifacts

- **`.planning/REQUIREMENTS.md`** — v1.30 (12 reqs across REL / PPX / HYG / DOC / INV families). Traceability populated 2026-04-26 (12/12 mapped to Phases 91–93).
- **`.planning/ROADMAP.md`** — v1.30 details block at top (Phases 91–93, success criteria, definition-of-done artifact paths). v1.29 collapsed in `<details>` block; all prior milestones preserved.
- **`milestones/v1.29-ROADMAP.md`** / **`v1.29-REQUIREMENTS.md`** — final v1.29 archives (preserved, untouched).
- **Phase summaries (v1.29):** `088-01..03-SUMMARY.md`, `089-01..02-SUMMARY.md`, `090-01..03-SUMMARY.md` under `milestones/v1.29-phases/`.
- **Research (v1.30):** Skipped — brownfield maintenance/release milestone with no new feature surface (same pattern as v1.23 / v1.28).

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| uat_gap | Phase **62** **`62-UAT.md`** | **closed** — **v1.18** |

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260425-gr1 | Drop deprecated flat-branding-keys infrastructure | 2026-04-25 | 50f80db | [260425-gr1-drop-deprecated-flat-branding-keys-infra](./quick/260425-gr1-drop-deprecated-flat-branding-keys-infra/) |
| 260425-imj | Strip GSD requirement-ID artifacts from public hexdocs | 2026-04-25 | c855743 | [260425-imj-strip-gsd-requirement-ids-from-public-he](./quick/260425-imj-strip-gsd-requirement-ids-from-public-he/) |
| 260426-fb8 | Mix format auto-fix for v1.29 Mailglass commits (Phase 1 main-CI recovery, PR #16) | 2026-04-26 | 9869c85 | [260426-fb8-mix-format-v1.29](./quick/260426-fb8-mix-format-v1.29/) |

## Recent Decisions

- **2026-04-26:** **v1.30 opened** — Spine A (`1.0.0` declaration). 3 phases (91–93) following v1.11 / v1.28 / v1.27 precedent: pre-publish prep (DOC + REL narrative) → linked publish + post-publish contract sweep → HYG mirror + INV-07 + tag. Granularity standard; same 3-phase ceiling as recent maintenance milestones.
- **2026-04-26:** **v1.30 traceability** — 12/12 requirements mapped: Phase 91 (4 — REL-06, REL-07, DOC-03, DOC-04), Phase 92 (5 — REL-05, PPX-09..12), Phase 93 (3 — HYG-02, INV-07, REL-08). No orphans, no duplicates.
- **2026-04-26:** **v1.30 research skipped** — same brownfield rationale as v1.23 / v1.28: maintenance/release milestone, no new feature surface, prior `.planning/research/SUMMARY.md` context still applies.
- **2026-04-26:** **Phase 90 / v1.29 close** — Mailglass is the only mail render path. `mjml_eex` + `phoenix_swoosh` removed from `accrue/mix.exs`. `mailglass_cleanup_test` enforces in CI that the deps, the legacy CLI, `Accrue.Emails.HtmlBridge`, `Accrue.Workers.Mailer.template_for/1`, and the 26 legacy `*.mjml.eex` / `*.text.eex` assets stay gone.
- **2026-04-26:** **Phase 90** — `mix accrue.mail.preview` deleted outright; no compatibility shim. `AccrueAdmin.Dev.EmailPreviewLive` (`/dev/email-preview`) is the only supported preview surface.
- **2026-04-26:** **Phase 90** — `Accrue.Emails.PaymentSucceeded` ported to Mailglass and added to `Fixtures.all/0` so the broad sweep stays honest after the dependency purge.
- **2026-04-26:** **Phase 90 UAT** — Shift-left taken to its conclusion: 7/7 UAT truths automated, 0 human steps, with `mailglass_cleanup_test` and `email_preview_live_test` fixture-sweep both gating on `release-gate` CI.
- **2026-04-25:** **Phase 88 Plan 02** — Sibling scope pattern: `mailglass_admin_routes` mounted OUTSIDE the `:accrue_admin` live_session to avoid nested live_session conflict; Phoenix forbids nested `live_session` blocks.
- **2026-04-25:** **Phase 88 Plan 02** — Shift-left: human browser-verify checkpoint replaced with ExUnit `__routes__/0` assertions — route existence verified at compile time.
- **2026-04-25:** **Phase 88 Plan 01** — Path is `../../mailglass` (not `../mailglass`) — accrue packages are two levels below `~/projects/`.
- **2026-04-25:** **Phase 88 Plan 01** — `only: [:dev, :test]` for mailglass_admin (not `:dev` only) — test env compiles `accrue_admin/2` macro expansion which imports `MailglassAdmin.Router` at compile time.
- **2026-04-25:** **Phase 88 Plan 01** — Fixed mailglass credo checks compilation: moved 13 custom credo check files from `lib/mailglass/credo/` to `credo_checks/` in the mailglass sibling repo, matching the accrue pattern.
- **2026-04-26:** **Phase 89 Plans 01–02** — Mailglass worker seam now dispatches through `Mailglass.deliver/1` with explicit idempotency; Receipt and PaymentFailed are Mailglass HEEx mailables.
- **2026-04-24:** **v1.28** opened — **spine B** (**next linked publish** + **INV-06**); **not** **1.0.0** (**spine A**) unless reprioritized.
- **2026-04-24:** **Phase 86** — **PPX-05..08** contract re-verification at **0.3.1** documented in **`086-VERIFICATION.md`** (no new SemVer bump in this pass).
- **2026-04-24:** **Phase 87** — **INV-06** dated maintainer pass **(b)** + **`087-VERIFICATION.md`** closed per **`.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/`**.

**Next:** `/gsd-plan-phase 91` — start v1.30 execution at Phase 91 (Pre-publish 1.0.0 prep).

**Completed (v1.29):** Phases **88–90** — **`milestones/v1.29-phases/`**; archives **`v1.29-ROADMAP.md`** + **`v1.29-REQUIREMENTS.md`**; tag **`v1.29`**.

**Completed (v1.28):** Phases **86–87** — **`milestones/v1.28-phases/086-post-publish-contract-alignment/`**, **`087-friction-inventory-post-publish/`**.

**Completed (v1.27):** Phases **84–85** — **`milestones/v1.27-phases/`**.
