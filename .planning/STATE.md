---
gsd_state_version: 1.0
milestone: v1.33
milestone_name: Braintree Full Maturity
status: verifying
last_updated: "2026-05-02T18:31:14.962Z"
last_activity: 2026-05-02
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 14
  completed_plans: 14
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-29)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** Phase 102 (coupon-discount-mapping)

## Current Position

Milestone: v1.33 — Braintree Full Maturity (planning open 2026-05-01)
Phase: 102 (coupon-discount-mapping) — EXECUTING
Plan: 3 of 3
Status: Phase complete — ready for verification
Resume file: None
Last activity: 2026-05-02

## Milestone Progress

**v1.32** (shipped **2026-05-01**): Phases **97–100** — **PROC-14..20**; **`milestones/v1.32-phases/`**; archives **`v1.32-ROADMAP.md`**, **`v1.32-REQUIREMENTS.md`**. Strategic parent: **`.planning/STRATEGY.md`**.

**v1.31** (shipped **2026-04-29**): Phases **94–96** — **PROC-09..13**; **`milestones/v1.31-phases/`**; archives **`v1.31-ROADMAP.md`**, **`v1.31-REQUIREMENTS.md`**; tag **`v1.31`**. Strategic parent: **`.planning/STRATEGY.md`**.

**v1.30** (opened **2026-04-26**, closed **2026-04-28**): **Phases 91-93 complete** — package-doc pins, host/adoption `1.0.0` needles, `release-manifest-ssot`, the six-script docs bundle, the host wrapper, the planning mirrors, the dated INV-07 maintainer pass, and the durable closeout ledger all have execution evidence (`091-VERIFICATION.md`, `092-01-SUMMARY.md`, `092-02-SUMMARY.md`, `092-VERIFICATION.md`, `092-03-SUMMARY.md`, `093-VERIFICATION.md`). Planning tag `v1.30` resolves to the final milestone-closing `HEAD` proven in `093-VERIFICATION.md`. Spine A — `1.0.0` declaration. **No** **PROC-08** / **FIN-03**.

**v1.29** (shipped **2026-04-26**): Phases **88–90** — **MG-01..MG-07**; **`milestones/v1.29-phases/`**; archives **`v1.29-ROADMAP.md`**, **`v1.29-REQUIREMENTS.md`**; tag **`v1.29`**.

**v1.28** (planning closed **2026-04-24**): Phases **86–87** **Complete** (**`086-VERIFICATION.md`**, **`087-VERIFICATION.md`**); **PPX-05..08**, **INV-06** validated. Not separately tagged — superseded by v1.29 forcing function.

**v1.27** (shipped **2026-04-24**): Phases **84–85** — **CLS-01..03**, **INV-05**; **`milestones/v1.27-phases/`**; archives **`v1.27-ROADMAP.md`**, **`v1.27-REQUIREMENTS.md`**; tag **`v1.27`**.

**Friction inventory (FRG-01):** `.planning/research/v1.17-FRICTION-INVENTORY.md`  
**North star + stop rules (FRG-02):** `.planning/research/v1.17-north-star.md`

**Last shipped (public packages on Hex):** **`accrue` / `accrue_admin` 1.0.0** — linked release landed on 2026-04-28 and Phase 92's post-publish proof sweep is complete.

## Current Planning Artifacts

- **`.planning/STRATEGY.md`** — persistent strategic tracker for the active **PROC-08** dual-provider core track.
- **`.planning/ROADMAP.md`** — active milestone roadmap for **v1.33** (phases **101–104**) plus archived milestone index.
- **`.planning/milestones/v1.33-REQUIREMENTS.md`** — active **v1.33** requirements (**BT-01..BT-09**).
- **`milestones/v1.31-ROADMAP.md`** / **`v1.31-REQUIREMENTS.md`** — final v1.31 archives (phases 94–96, 5 requirements).
- **`milestones/v1.30-ROADMAP.md`** / **`v1.30-REQUIREMENTS.md`** — final v1.30 archives (phases 91–93, all 12 requirements, final proof links, archived intact).
- **`milestones/v1.29-ROADMAP.md`** / **`v1.29-REQUIREMENTS.md`** — final v1.29 archives (preserved, untouched).
- **Phase 92 proof:** `092-VERIFICATION.md` is the canonical same-day linked `1.0.0` publish ledger; `093-VERIFICATION.md` reuses it and adds the final planning closeout ledger.
- **Strategic context:** `093-RESEARCH.md` closed the v1.30 maintenance posture; `STRATEGY.md` is now the parent context for the next product-expansion sequence.

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
| 260501-lfk | Repair active ROADMAP.md for v1.33 (archive stale ### Phase blocks for 24, 59-66, 88-90; add Phase 101-104 detail blocks) | 2026-05-01 | 445c742 | [260501-lfk-repair-active-roadmap-md-for-v1-33-archi](./quick/260501-lfk-repair-active-roadmap-md-for-v1-33-archi/) |

## Recent Decisions

- **2026-05-02:** **Phase 102 Plan 03 complete** — `AccruePortal.Live.CheckoutLive` now previews Braintree promotion-code savings in LiveView, updates the pay CTA before submit, and announces provisional results through an `aria-live` status region.
- **2026-05-02:** **Phase 102 Plan 03 submit contract** — the portal keeps `promotion_code` on the existing `Accrue.Billing.subscribe/3` seam and translates `%Accrue.Error.DiscountMappingInvalid{}` into safe customer copy instead of allowing an undiscounted subscription.
- **2026-05-02:** **Phase 102 Plan 01 complete** — Braintree discount mappings now live in a dedicated `accrue_discount_mappings` table instead of reusing Stripe promotion-code projections.
- **2026-05-02:** **Phase 102 Plan 01 validation contract** — local discount resolution returns explicit `:not_found` / `:inactive` / `:expired` / `:max_redemptions_reached` atoms and reserves `%Accrue.Error.DiscountMappingInvalid{}` for stored drift.
- **2026-05-02:** **Phase 101 Plan 07 complete** — `accrue_portal` now publishes explicit `:plug` / `:jason` runtime deps, owns package-local config/test bootstrap, and ships router/auth/CSP shell regression tests with a reusable Braintree client-token stub for later portal suites.
- **2026-05-02:** **Phase 101 Plan 03 complete** — Braintree local billing-portal availability is enforced in the adapter via `portal_base_url`, preserving the `:unsupported_by_gateway` fallback when the host has not configured the local portal.
- **2026-05-02:** **Phase 101 Plan 03 docs** — `Accrue.Billing` now states explicitly that Stripe remains hosted upstream while Braintree returns host-mounted local portal URLs without adding a new `ui_mode`.
- **v1.32 opened**: Expanding Braintree integration for production parity (Subscription mutation, Payment Methods CRUD, Refunds, Portal semantics).
- **2026-04-29:** **Phase 96 complete** — the Braintree-backed thin slice is implemented through the public facade with webhook lifecycle support. The canonical matrix, package docs, and example-host docs now mirror the bounded support story, and verifiers pin the new Phase 96 wording.
- **2026-04-28:** **v1.31 opened** — maintenance-only follow-on work was rejected as diminishing-return territory after `1.0.0`; the project is now on a bounded **PROC-08** strategic track aimed at an official dual-provider core.
- **2026-04-28:** **Persistent strategic tracking added** — `.planning/STRATEGY.md` is now the parent artifact for the processor-expansion epic so future milestones inherit the rationale instead of re-deriving it.
- **2026-04-28:** **v1.31 traceability** — 5/5 requirements mapped: Phase 94 (**PROC-09**), Phase 95 (**PROC-10**, **PROC-11**), Phase 96 (**PROC-12**, **PROC-13**). No orphans, no duplicate ownership.
- **2026-04-29:** **Phase 94 complete** — the repo now has a locked `Braintree` target, a canonical processor-support matrix, a dedicated `verify_processor_support_matrix.sh` gate, Phase 94 package-doc drift needles, and ExUnit shell-out coverage for both docs verifiers.
- **2026-04-29:** **Phase 95 complete** — runtime processor truth now comes from explicit adapter capability maps and support labels, `subscribe/3` and `list_payment_methods/2` fail clearly outside the staged slice, and the Fake-first conformance lane is documented and tested as the merge-blocking SSOT.
- **2026-04-28:** **Phase 92 Plan 03 complete** — `092-VERIFICATION.md` now ties merged PR `#15`, release workflow run `25055758784`, GitHub release URLs, Hex `1.0.0` timestamps, `release-manifest-ssot`, the six-script docs bundle, and `host-integration` to the final REL-05 / PPX-09..12 closeout.
- **2026-04-28:** **Phase 91 complete** — Reviewed SHA `3cca930` passed the full docs-contracts-shift-left bundle plus `host-integration`; REL-06, REL-07, DOC-03, and DOC-04 are now closed and the phase is ready to hand off to Phase 92 planning.
- **2026-04-28:** **Phase 92 Plan 02 complete** — Reviewed `1.0.0` branch state passed `release-manifest-ssot`, the full `docs-contracts-shift-left` bundle, and `bash scripts/ci/accrue_host_uat.sh`; merged PR `#15` file list remains the canonical proof for the full release slice.
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

**Next:** **Phase 102 verification / Phase 103 planning** — coupon-discount mapping is implementation-complete; next work should shift to validation handoff or metering-engine planning.

**Completed (v1.32):** Phases **97–100** — **`milestones/v1.32-phases/`**; archives **`v1.32-ROADMAP.md`** + **`v1.32-REQUIREMENTS.md`**; tag **`v1.32`** (local).

**Completed (v1.31):** Phases **94–96** — **`milestones/v1.31-phases/`**; archives **`v1.31-ROADMAP.md`** + **`v1.31-REQUIREMENTS.md`**; tag **`v1.31`**.

**Completed (v1.29):** Phases **88–90** — **`milestones/v1.29-phases/`**; archives **`v1.29-ROADMAP.md`** + **`v1.29-REQUIREMENTS.md`**; tag **`v1.29`**.

**Completed (v1.28):** Phases **86–87** — **`milestones/v1.28-phases/086-post-publish-contract-alignment/`**, **`087-friction-inventory-post-publish/`**.

**Completed (v1.27):** Phases **84–85** — **`milestones/v1.27-phases/`**.

**Planned Phase:** 102 (Coupon/Discount Mapping) — 3 plans — 2026-05-02T15:59:06.760Z
