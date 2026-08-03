# Accrue

## What This Is

Accrue is an open-source Elixir/Phoenix payments and billing library, inspired by Pay (Rails) and Laravel Cashier but built idiomatically for the Elixir/Ecto/Plug/Phoenix ecosystem. It gives Phoenix SaaS developers a batteries-included "jumpstart" for everything a real SaaS business needs on day one — subscriptions, checkout, invoices, coupons, emails, PDFs, webhooks, admin UI, telemetry — without the migration pain and design regrets earlier libraries accumulated.

Tagline: *"Billing state, modeled clearly."*

## Core Value

**A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one** — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain for at least the first major version. Everything else is in service of that.

## Development Posture

**stable-core / demand-driven expansion.** As of **2026-05-31**, Accrue is considered **done enough for its declared scope**: the canonical SaaS billing loop is complete, the dual-provider gateway subscription core is bounded and documented, and the remaining work is release readiness, maintenance, support-contract hardening, or explicitly justified strategic expansion.

**Verification posture:** Testable behavior must use executable unit, integration, contract, browser, screenshot, or accessibility evidence; do not use human verification when that evidence exists. Genuine product decisions, credentials, and irreversible external actions remain authorization gates rather than UAT.

Default future milestone posture:
- Prefer **release-readiness, maintenance, documentation truth, verifier hardening, and adopter-proof closure** over new product surface.
- Do **not** start broad feature milestones because a deferred idea exists. Require a concrete adopter failure mode, correctness/security risk, repeated support issue, or explicit strategy change.
- Treat polish as backlog unless it removes a real onboarding, operational, verifier, or support-contract failure mode.
- Keep Stripe / Braintree / Fake support **capability-explicit**. Any processor-surface change must update behavior, support matrix, docs, examples/verifiers, and release notes together.
- Preserve the architectural boundary: `accrue` owns billing domain and public facades; `accrue_admin` owns operator UI; `accrue_portal` owns customer self-serve UI; host apps own Repo, migrations, Oban supervision, auth, session, runtime secrets, and app-domain membership policy.

### Post-v1.48 pause rule

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

A historical anchor, dormant seed, or deferred idea never opens milestone scope by itself; any reopen decision must be recorded in `.planning/PROJECT.md` or a future strategy artifact before `.planning/ROADMAP.md` or `.planning/STATE.md` changes.

v1.49 **Realistic Demo App & Adoption Evidence** shipped on **2026-06-02**. The checked-in host now has rich PingPal-style demo data, Docker-first local evaluation, deterministic Playwright E2E coverage, CI Docker smoke, mandatory periodic live-Stripe parity, and a Start Here documentation path for adopters.

## Current State

**Latest shipped milestone: v1.58 — lattice_stripe 2.x Bump & Stripe-Native Entitlements Sync (SEED-005), shipped 2026-07-31.** All resolving packages now use `lattice_stripe ~> 2.0` (resolving 2.1.0). The client-backed Stripe entitlement refresh is opt-in and advisory-only, converges with webhook observations through the shared reconciler, never participates in grants, and is visible through the existing core diagnostic and admin customer detail.

**Closeout:** Phases 212, 213, 214, 214.1, and 214.2 completed across 17 plans and 33 tasks. The audit passed 11/11 requirements and 5/5 flows with 10/11 integrations fully wired; the host-owned worker's lack of a production enqueuer and four other warning-level items remain documented technical debt. Phase 214.2 passed 19/19 verification with executable desktop/mobile UAT; its post-execution Nyquist metadata remains `ready` rather than authoritative `validated`.

**Reopen decision (recorded per the post-v1.48 pause rule, before ROADMAP/STATE change):** justification class **maintenance / dependency currency** (a major-version bump of a required core dependency, `lattice_stripe`, cf. v1.46) **plus closing a prior explicitly-deferred capability** (Phase 127's optional Stripe-native entitlements sync, unblocked only now that 2.0.0 ships the entitlements primitives). This is *not* broad new product surface: it stays inside the already-shipped entitlements feature, keeps local plan→feature mapping canonical as the gate, and keeps `scripts/ci/verify_entitlement_sync_isolation.sh` (`gate → seam` must never happen) green. Library pin target is `~> 2.0` (permissive within major 2 for adopters).

**v1.57 — Admin Operator Control Plane (SEED-004, M1)** shipped & archived **2026-07-30** (Phases 209–211, 11/11 requirements, milestone audit passed). The next SEED-004 candidate is **M2** (signature "Why blocked?" diagnosis surfaces + causality graph + the first core `accrue` diagnosis functions), deferred — reopen class *explicit strategy change*, to be recorded here before any ROADMAP/STATE change.

**v1.56 (Admin UI Ratchet) remains PARKED** — phases 205–207 shipped, 208 was 3/5, non-converging because the ratchet kept surfacing information-architecture findings (23 confirmed in round 99); that was exactly the work v1.57 took on and shipped. The ratchet ledger/baseline in `accrue_admin/e2e/ratchet/` are preserved and become the tool that re-freezes the v1.57 redesign after M3.

The Phase 204 hardening roadmap's top slice (**Public Truth And Proof-State Baseline**) remains the highest-ranked *release-readiness* follow-up, deferred — a candidate for a later milestone.

**Current milestone: v1.59 — Account-Scoped Multi-Rail & Offline Entitlements (SEED-006).** A concrete adopter, anonymized as **B2C Alpha**, requires one account to remain entitled across Stripe web billing, Apple in-app purchase, and extended offline study in a Phoenix/Crosswake application. This satisfies the post-v1.48 reopen bar as both a sourced adopter requirement and an explicit strategy expansion with reusable value for Phoenix apps going mobile. The approved direction is a common account entitlement projection fed by rail-specific lifecycle observers, plus signed device-bound offline proof whose freshness state is interpreted by host policy; lifecycle management remains honestly rail-aware. Google Play is SEED-007 and stays backlogged until Android is scheduled or a second adopter requires it. Source: `.planning/research/MULTI-RAIL-OFFLINE-ENTITLEMENTS.md`.

**Phase 215 complete (2026-08-01):** the versioned v1.59 authority bundle, canonical decision-case corpus, source-capability boundary, and checked-in Crosswake prove-or-block tracer are validated (19/19 must-haves; RSCH-01..03 and RAIL-04..05 satisfied). The canonical report remains honestly `feasibility_blocked` until genuine bridge and physical-device evidence exists, and caller-selected report roots cannot manufacture proof.

**Phase 216 complete (2026-08-02):** concurrent Stripe/Apple rail registration, legacy default-processor aliasing, rail/environment-qualified product mapping, and durable account/observation/grant/device persistence are validated (21/21 must-haves; RAIL-01..03 satisfied). PostgreSQL-backed automation now proves identity races, opaque cross-account ownership failures, named raw-write constraints, and whole-transaction rollback with no human UAT. The recurring persistence proofs already run in the existing PostgreSQL-backed `mix test --warnings-as-errors` CI job, so no duplicate workflow was added. Next: Phase 217, canonical projection and compatibility.

**Phase 217 complete (2026-08-02):** rail-qualified observations now converge through one revisioned account projection, preserve cross-rail grants, expose provider-honest management, and keep legacy single-processor hosts compatible (ACCT-01..05 satisfied).

**Phase 218 complete (2026-08-03):** strict Apple Notifications V2 and nested evidence verification, bind-once lineage ownership, bounded raw-body admission, durable quarantine, scheduled status/history reconciliation, lifecycle projection, and Stripe-isolated Apple management are validated (5/5 truths; AAPL-01..05 satisfied). All 16 plan summaries produce 30 deterministic automated UAT checks, `behavior_unverified` is zero, and CI rejects incomplete, forged, pending, or human-dependent acceptance evidence. Next: Phase 219, offline study contract.

## Current Milestone: v1.59 Account-Scoped Multi-Rail & Offline Entitlements

**Goal:** Preserve one account's access across Stripe web billing, Apple in-app purchase, and extended offline study through a common entitlement projection and signed device-bound proof, while keeping lifecycle operations rail-aware and avoiding connectivity-driven learner lockout.

**Target features:**
- Durable, versioned research memory spanning stakeholder lenses, primary sources, decision tables, threats, and a monitored watchlist.
- Concurrent Stripe and Apple rail registration plus rail-qualified product mapping and source capabilities.
- A canonical account projection that unions effective grants without allowing one rail's revocation to erase another rail's access.
- Verified Apple evidence and automatic `appAccountToken` linking with idempotent reconciliation.
- Cross-rail purchase eligibility that warns or blocks an accidental second subscription without automatic cancellation or migration.
- A compact ES256 offline lease with a 30-day revalidation target; stale-offline study keeps downloaded lessons and progress usable while new premium downloads and other value-expanding actions wait for reconnect.
- An anonymized B2C Alpha reference-host proof, operator diagnostics, automatic repair paths, runbooks, and public contract alignment.

**Guardrails:** Existing single-processor hosts remain compatible; lifecycle management stays provider-honest; the adopter identity and PII never enter planning, fixtures, tokens, telemetry, or diagnostics; Google Play, Family Sharing, offer authoring, automatic ownership transfer, migration/proration, and advanced risk/fraud controls remain deferred unless separately justified.

## Most recently shipped milestone: v1.57 — Admin Operator Control Plane (SEED-004, M1) (**shipped & archived 2026-07-30**)

**Goal (ACHIEVED):** Begin the SEED-004 redesign of `accrue_admin` from a CRUD surface into an "operator control plane over billing state," via the **M1 information-architecture / grammar pivot** — one health verdict + one primary action per zone, trim the redundant bands, and reign the two outlier pages (Home + Subscriptions) onto the same shared component vocabulary as the rest of the admin — so the whole admin reads as one cohesive, operator-first system.

**Delivered (Phases 209–211, 10/10 plans, 11/11 requirements):** the Subscriptions list reigned onto the canonical PageHeader/StatStrip/DataTable spine with one StatusBadge verdict, one primary CTA, a 4-stat StatStrip, compact cell idiom, and zero bespoke worklist bands or in-cell action buttons — COMP-01 resolved inline, no new component (209); Home recomposed onto `PageHeader` with a single verdict (StatusBadge + exposure-first StatStrip), one discoverable customer-search control, a primitive-built attention rail + EmptyState, and a launcher grid, with plain-language `AccrueAdmin.Copy`-sourced strings, real-parent breadcrumbs, and the answer-first IA certified across both pages (axe-clean, no density regression) (210); and the grep-gated retirement of 97 dead bespoke `.ax-home-*`/`.ax-launcher*`/`.ax-attention*`/`.ax-subscriptions-*` selectors with detail-page-shared classes preserved, both generated artifacts (`accrue_admin.css`, `copy_strings.json`) rebuilt, storybook recomposed, and the parked ratchet's dangling selector fixed — full unit (514/0) + e2e (200/0) + storybook suites green with zero regressions (211).

**Reopen decision (honored):** justification class **explicit strategy change** — flagship adopter-facing admin surface elevated to a strategic redesign (same class accepted for v1.50–v1.54). Scope stayed **admin-only** (`accrue_admin` LiveView templates + `assets/css`): no core `accrue` change (M2 owns the diagnosis fns like `blocking_reason_for_owner/1`), no new nav rooms (M3), no `accrue_portal` work, no new deps, no Tailwind migration; `ax-*` stayed the styling SSOT; the Cobalt/quiet-confidence brand + prior de-garish/card-grammar polish were kept.

**Closeout proof:** Phases 209–211; planning tag `v1.57`; milestone audit `passed` with 3/3 phase verifications, 11/11 requirements clean, 5/5 integration checks, 5/5 flows, zero blockers. UAT auto-closed with **zero human checkpoints** — the two former visual checkpoints replaced by a new deterministic Playwright `toHaveScreenshot` pixel-diff gate (4 admin surfaces × light/dark, blocking in browser-uat; quick-260729-rjo, PRs #35/#36/#37). See `.planning/MILESTONES.md`, `.planning/milestones/v1.57-ROADMAP.md`, `.planning/milestones/v1.57-REQUIREMENTS.md`, `.planning/milestones/v1.57-MILESTONE-AUDIT.md`, and `.planning/milestones/v1.57-phases/`.

**Key context:** driven by the 23 round-99 ratchet-confirmed IA findings (`research/admin-ratchet-round99-confirmed-findings.json`); the 12 on `dashboard` + `subscriptions` were the M1 acceptance checklist. **M2** (signature "Why blocked?" diagnosis surfaces + causality graph + core `accrue` diagnosis fns) and **M3** (new Usage/checkout/fee-reconciliation rooms + ratchet re-freeze) remain later milestones. North-star: `prompts/accrue_admin_operator_ui_journey_blueprint.md`; synthesis: `.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md`; seed: `.planning/seeds/SEED-004-admin-ui-blueprint-redesign.md`. GOTCHA logged: Phase 211 execution was 11 unpushed local-main commits (origin had plans, not the CSS retirement); reconciled + CI-validated via PR #36.

## Parked milestone: v1.56 — Admin UI Ratchet (PARKED 2026-07-19)
Machinery milestone (automated adversarial UI-eval ratchet). Phases 205–207 shipped; 208 parked at 3/5 (208-04/05 maintainer-gated, non-converging on IA findings — the work v1.57 now does). Ledger + baseline in `accrue_admin/e2e/ratchet/` preserved; the harness re-locks the v1.57 redesign later. Archived: `.planning/milestones/v1.56-{ROADMAP,REQUIREMENTS}.md`, `.planning/milestones/v1.56-phases/` (205–208). Resume via restore + `/gsd-execute-phase 208`.

## Prior shipped milestone: v1.55 — OSS Quality Evaluation & Hardening Roadmap (**shipped & archived 2026-07-03**)

**Goal (ACHIEVED):** Evaluate Accrue as a real OSS billing project end to end, identify the weakest quality dimensions with repo evidence, and produce a ranked hardening roadmap without changing product behavior.

**Delivered (Phases 201-204, 4/4 plans, 18/18 requirements):** an evidence-backed software-quality audit across adoption, production, maintenance, support, UI, release, upgrade, architecture, data, security, OSS trust, and Accrue-specific dimensions (201); a static-first CI/CD performance and determinism audit with workflow topology, critical path, measurement needs, flaky/determinism risks, cache risks, provider-state ambiguity, and target recommendations (202); an accepted database schema contract ADR keeping `billing` as the default dedicated Postgres schema while preserving explicit `public` and deferring rename/data-movement work (203); and a ranked top-10 hardening roadmap sliced into future milestones with impact, effort, risk reduction, done criteria, metrics needed, and explicit non-goals (204).

**Reopen decision (honored):** maintenance / release-readiness / support-contract hardening under the stable-core posture, not a broad feature milestone. The trigger was an explicit maintainer request to find the weakest quality dimensions before public-adoption/release confidence work. Scope stayed audit-only: no product behavior changes, public API changes, DB default changes, CI required-check topology changes, release automation changes, or runtime UI changes.

**Closeout proof:** Phases 201-204; planning tag `v1.55`; milestone audit `passed` with 4/4 phase verifications, 18/18 requirements clean by 3-source audit, 8/8 integration checks, 6/6 audit-only flows, zero blockers, and Nyquist-compliant validation metadata. See `.planning/MILESTONES.md`, `.planning/milestones/v1.55-ROADMAP.md`, `.planning/milestones/v1.55-REQUIREMENTS.md`, `.planning/milestones/v1.55-MILESTONE-AUDIT.md`, and `.planning/milestones/v1.55-phases/`.

**Key context:** Phase 204 ranks Public Truth And Proof-State Baseline first, followed by evaluator/release safety, measured CI cleanup, schema-prefix contract hardening, and portal parity readiness. These are follow-up implementation candidates; v1.55 itself only produced the audits, ADR, and roadmap.

## Prior shipped milestone: v1.54 — Admin UI Page-Level Streamlining & Storybook (**shipped & archived 2026-07-01**)

**Goal (ACHIEVED):** Take the already-component-hardened `accrue_admin` operator UI (v1.53) from *interaction-correct building blocks* to *page-level excellence* — every page driven from operator JTBD, the info-dump density reduced, firsthand-observed usability defects fixed, and the surface proven in light/dark/system with a rendered Storybook + page-flow gate.

**Delivered (Phases 193–200, 59/59 plans, 23/23 requirements):** locked SPEC-OVERVIEW/LIST/DETAIL guides plus a page-flow baseline and PhoenixStorybook dev/test-only scaffold (193); Dashboard and Recovery overview exemplar (194); Subscription detail summary-then-drill exemplar with canonical overlay/drawer action hosting (195); Subscriptions list exemplar plus shared `PageHeader` (196); LIST propagation across customers, invoices, payments, coupons, promotion codes, webhooks, events, and connect (197); DETAIL/analytics propagation across customer/invoice/charge/coupon/promotion-code/connect/webhook/event plus Recovery/Campaign (198); cross-cutting overlay/focus/scroll/floating correctness, deterministic fixture stress, and brand-voice microcopy (199); and final Storybook/theming/axe/no-FOUC/reduced-motion/CI guardrail sign-off with a 30,348-cell union baseline and zero regressions (200).

**Reopen decision (honored):** explicit strategy change for the flagship adopter-facing admin surface plus concrete firsthand usability defects. Scope stayed within `accrue_admin`: no new billing primitives, no breaking API/route changes, no Tailwind migration, no `accrue_portal` work, and core `accrue` stayed LiveView-runtime-free. PhoenixStorybook is dev/test-only.

**Closeout proof:** Phases 193–200; planning tag `v1.54`; milestone audit `passed` with 23/23 requirements clean, 8/8 phase verifications, 8/8 E2E flows, zero blockers, and one accepted out-of-scope deferral (TOOL-02 pixel-diff visual regression). See `.planning/MILESTONES.md`, `.planning/milestones/v1.54-ROADMAP.md`, `.planning/milestones/v1.54-REQUIREMENTS.md`, `.planning/milestones/v1.54-MILESTONE-AUDIT.md`, and `.planning/milestones/v1.54-phases/`.

**Key context:** PhoenixStorybook reverses v1.53's TOOL-01 deferral and is now adopted as a dev/test-only design lab. The in-app `/dev/components` kitchen remains a second renderer backing drift tests. TOOL-02 remains deferred; the scored-cell forward-only page-flow gate is the regression mechanism.

## Prior shipped milestone: v1.53 — Admin UI Design-System Hardening (**shipped & archived 2026-06-20**)

**Goal (ACHIEVED):** Take the already-shipped `accrue_admin` operator UI from *considered* (v1.51) to *interaction-correct and component-systematic* — audit the design system fractally (foundations → primitives → component groups → pages → flows), catch and fix the behavioral defects screenshot scoring can't see (modal-behind-scrim, scroll traps, focus loss, overlay z-index, hover-on-empty-state, disabled-looks-enabled), formalize every component in isolation across its full state matrix, and lock it all behind an idempotent only-forward verification loop.

**Delivered (Phases 187–192, 39/39 plans, 33/33 requirements):** a refreshed 12-dimension rubric with a 21,276-cell scored baseline + 800-row AX187 defect ledger (187); one package-local styling SSOT, composed `ax-*` typography bundles, a tokenized z-index/layer scale, motion-token closure, and contrast-correct dark-mode roles (188); a registry-driven `/dev/components` state-matrix gallery (14 families) + 8 new primitives + component-root token fixes (189); group/meta-component cohesion from a canonical group-contract registry with responsive table→card degradation (190); a package-local FocusTrap + regression coverage for the Phase-187 behavioral defects, LiveView disconnected-state handling, an on-brand microcopy pass, and idempotent one-click seed reachability (191); and a final scorecard ≥ baseline across all 21,276 cells with **zero regressions**, merge-blocking CI regression guardrails, and maintainer sign-off ACCEPT — discharging v1.51's open photographic-sign-off tech-debt (192).

**Reopen decision (recorded per the post-v1.48 pause rule):** Justification class **explicit strategy change** (design quality of the flagship adopter-facing surface elevated to a strategic priority — same class accepted for v1.50/v1.51/v1.52) **plus firsthand-observed interaction defects** in the running demo (concrete failure evidence). A hardening pass on the existing admin UI surface — no new billing primitives, no breaking API/route changes, no Tailwind migration; demo/host chrome and `accrue_portal` out of scope (all honored).

**Closeout proof:** Phases 187–192; planning tag `v1.53`; milestone audit `gaps_found` → all documentation/traceability gaps closed inline at milestone close; see `.planning/MILESTONES.md` v1.53 entry, `.planning/milestones/v1.53-ROADMAP.md`, `.planning/milestones/v1.53-REQUIREMENTS.md`, and `.planning/milestones/v1.53-MILESTONE-AUDIT.md`. CI runs the deterministic guardrail boundary; scorecard/sign-off regeneration accepted as locally-reproducible closeout evidence.

**Key context:** Component lab extends the in-app `/dev/components` kitchen (no new dependency; TOOL-01 PhoenixStorybook deferred). Standing constraints honored: custom `ax-*` CSS + tokens stayed SSOT; backward-compatible APIs/routes. Design source `.planning/research/v1.51-admin-ui-depth-design.md`. With v1.53 shipped, the project returns to **stable core / demand-driven** posture.

## Prior shipped milestone: v1.52 Brand System (**shipped & archived 2026-06-14**)

**Goal (ACHIEVED):** Pressure-test the brand book seed (`prompts/accrue-brand-book.md`) through a 14-section critical audit, run a user-judged SVG logo tournament to a locked winner, and ship a committed, self-contained `brandbook/` — standalone HTML brand book, full SVG logo system, design tokens, and voice/microcopy/marketing copy.

**Delivered (Phases 180–186, 29/29 plans, 14/14 requirements):** ratified `BRAND-DNA.md` + binding logo brief from a 14-section audit; an opentype.js Geist-outline SVG harness with 6 pre-gate lints; a user-judged tournament to locked winner **R2-7** (two-tone stepped mark); the full production logo system at `brandbook/logo/` (21 outlined-path, svgo-optimized files); `brandbook/tokens/` with admin `ax-*` parity check (zero admin changes) + specimens; a committed voice system + ready-to-paste copy for every adopter-facing surface; and a self-contained, file://-openable `brandbook/index.html` passing the quality gate within the ≤2 MB budget (~656K git-tracked).

**Closeout proof:** Phases 180–186; planning tag `v1.52`; see `.planning/MILESTONES.md` v1.52 entry, `.planning/milestones/v1.52-ROADMAP.md`, and `.planning/milestones/v1.52-REQUIREMENTS.md`. No formal milestone audit was produced — maintainer accepted the de-facto-complete state (14/14 requirements, all human checkpoints passed) and skipped the audit gate.

**Posture justification:** Brand/DX investment in adopter-facing presentation surfaces (README, Hex.pm, HexDocs, social previews, admin UI identity) — no new billing primitives; same justification class as v1.50/v1.51 and explicitly requested by the maintainer. This paragraph is the recorded reopen decision required by the post-v1.48 pause rule.

**Target features (Phases 180–186, deps 180→181→182→183→186, with 180→{184,185}→186 side-rails):**
- **180** Brand audit & DNA lock — 14-section pressure test with KEEP/TIGHTEN/REWORK/ADD/REMOVE verdicts; locked BRAND-DNA + binding logo design brief (✋ user ratifies)
- **181** SVG pipeline + tournament round 1 — opentype.js Geist-outline harness, pre-gate lints, Playwright QA; 12–16 candidates across 4 directions incl. fully-integrated typemarks; context-matrix gallery (✋ user picks winners)
- **182** Convergent refinement — variation rounds on winners via monotonic `TOURNAMENT.md` ledger until user settles (✋ looping checkpoint); locked winner
- **183** Logo system production — full derived suite in `brandbook/logo/` (primary lockup, typemark, icon-only, monochrome, dark/light, favicon, social card, subtitle variant, clearspace spec); outlined paths only, svgo-optimized
- **184** Design tokens & specimens — `brandbook/tokens/` with documented mapping + automated consistency check against admin `ax-*` tokens (admin `theme.css` stays SSOT, untouched)
- **185** Voice, microcopy & marketing copy — ready-to-paste blocks for GitHub/Hex.pm/HexDocs/README/landing/release notes (✋ batch copy review)
- **186** Standalone HTML brand book at `brandbook/index.html` (self-contained, no build step, no JS frameworks) + quality gate (≤2 MB `brandbook/` budget, ✋ final UAT)

**Hard logo constraints (binding on every candidate):** no rectangular background/container shape behind the mark; logotype optically close to the mark; main lockup carries no subtitle (a separate with-subtitle variant ships); fully-integrated custom typemark options required. **Seed latitude is evidence-gated:** Geist + the existing palette are defaults; changes only with a cited failure (contrast, distinctiveness, 16px rendering) and user ratification at the audit checkpoint.

Authoritative design source: `.planning/research/v1.52-brand-system-design.md` (user-approved 2026-06-11).

## Last shipped milestone

### v1.51 — Admin UI: Depth Pass (**shipped & archived 2026-06-04**)

**Goal:** Take the already-shipped `accrue_admin` UI from *consistent* (v1.50) to *considered* — persona-shaped IA, design-token gap closure, per-screen rubric uplift, restrained motion, seed expressiveness, screenshot-driven visual QA.

**Delivered (Phases 174–179, 33/33 plans, 22/22 requirements):** design-system gap closure (DSY), cordoned-hybrid persona-driven nav + threading (IA), systematic per-screen rubric uplift (SCR), token-based motion (MOT), single-click-through seed state coverage (SEED), and the screenshot/axe visual-QA loop (QA). Audit: `tech_debt` (photographic sign-off run is a standing human/CI gate; code-level compliance 100%) — see `.planning/v1.51-MILESTONE-AUDIT.md`.

Authoritative design source: `.planning/research/v1.51-admin-ui-depth-design.md`.

## Prior shipped milestone

### v1.50 — Admin UI Foundation (**shipped 2026-06-02 via PR #32; archived 2026-06-03**)

**Goal:** Systematically raise the design-system, information-architecture, and usability baseline of the already-shipped `accrue_admin` UI to a coherent, distinctly-branded standard.

**Delivered (Phases 167-173, merged via PR #32):**
- Tightened `ax-*` design tokens (radii, shadows, spacing, info/money color) + token-based motion.
- Distinct brand typography (self-hosted Geist display + body, tabular numerals) + heroicons + favicon.
- uk.gov-style task-launcher home, job-aligned nav regroup, always-on `Cmd-K` search.
- Cross-screen threading, path-aware breadcrumbs, plain-language microcopy.
- Shared `<.detail_section>` components across the 6 large detail screens; skeleton/empty states.
- Seed enrichment (+ host seed dunning-event bug fix); rebuilt component kitchen.
- 10-dimension rubric audit; screenshot coverage (desktop + mobile + dark) + automated axe a11y.

**v1.51 builds directly on this** — it is the second, depth-oriented pass on the same surface.

## Last shipped milestone

### v1.49 — Realistic Demo App & Adoption Evidence (**archived 2026-06-02**)

**Goal:** Turn `examples/accrue_host` into a realistic adoption-evidence demo app with rich seeds, deterministic E2E automation, frictionless Docker DX, and clear evaluator documentation.

**Delivered:**
- PingPal-style seeded host data with deterministic hero accounts, realistic background accounts, subscriptions, events, and time-series history.
- Docker-first local development path with dependency/build volume isolation and Docker-aware Phoenix endpoint binding.
- Native sharded Playwright CI, checked-in Docker boot smoke, and mandatory periodic live-Stripe parity.
- Host README Start Here flow and proof ladder that guide adopters from Docker boot to Fake-backed billing inspection.

**Closeout proof:** Phases 163–166; planning tag `v1.49`; see `.planning/MILESTONES.md` v1.49 entry, `.planning/milestones/v1.49-ROADMAP.md`, `.planning/milestones/v1.49-REQUIREMENTS.md`, `.planning/milestones/v1.49-MILESTONE-AUDIT.md`, and `.planning/milestones/v1.49-phases/`.

## Prior shipped milestone

### v1.47 — ENT-10 Polish + Adopter-Proof Completeness (**archived 2026-05-31**)

**Goal:** Close the ENT-10 advisory-cache follow-up set and prove entitlements gating, metered usage, and Oban cron wiring in the checked-in example host.

**Delivered:**
- Advisory entitlement cache writes now use a DB-level monotonic upsert guard with stale handling, accurate processor attribution, and livemode carry-forward.
- Stripe entitlement-summary fixtures can model absent `livemode` directly, and default metrics expose malformed/orphan entitlement-summary webhook signals.
- Fail-closed LiveView entitlement gating for unloaded organization billables is proven through the example host route.
- Example host metered usage proof subscribes to the metered plan, clicks the visible LiveView action, and asserts the durable meter event value.
- Base host Oban config wiring is validated directly for required cron workers and queues, with append-merge guidance anchored at the host crontab callsite.

**Closeout proof:** Phases 154–158; planning tag `v1.47`; see `.planning/MILESTONES.md` v1.47 entry, `.planning/milestones/v1.47-ROADMAP.md`, `.planning/milestones/v1.47-REQUIREMENTS.md`, and `.planning/milestones/v1.47-MILESTONE-AUDIT.md`.

## Prior shipped milestone

### v1.46 — Maintenance & Closure (**archived 2026-05-30**)

**Goal:** Routine maintenance, dependency updates, ENT-10 scoping fix, @since annotation cleanup, and shipping the linked 1.3.0 Hex publish across all three packages.

**Delivered:**
- ENT-10 webhook scoping fix: `customer` lookups now strictly scope by `processor_id + processor` to prevent cross-processor ID collisions.
- Dependency updates across accrue / accrue_admin / accrue_portal.
- All 8 malformed `@since` annotations fixed to canonical `@doc since: "1.3.0"` (dunning.ex ×7, funnel_chart.ex ×1).
- Three Zeros gate: all 13 `verify_*.sh` scripts + mix test/dialyzer/credo/coveralls green across all packages.
- `accrue_portal` credo baseline established (`.credo.exs` mirroring accrue_admin).
- `accrue / accrue_admin / accrue_portal` **1.3.0** published to Hex.pm via Release Please; git tags pushed.

**Closeout proof:** Phases 151–153; planning tag `v1.46`; see `.planning/MILESTONES.md` v1.46 entry.

## Prior shipped milestone

### v1.45 — Multi-channel Dunning (In-App Banners) (**archived 2026-05-29**)

**Goal:** Ship `Accrue.Dunning.requires_attention?/1` API and headless `<AccrueAdmin.Components.DunningBanner />` component for Phoenix LiveView host apps. Document integration in guides/dunning.md and prove adoption in examples/accrue_host.

**Delivered:**
- `Accrue.Dunning.requires_attention?/1` — billing-state-aware API for banner visibility.
- `AccrueAdmin.Components.DunningBanner` — headless LiveView component (core-only DIY path documented).
- In-app dunning banner documented in `guides/dunning.md` with explicit package dependency boundary.
- Adopter proof in `examples/accrue_host` (resolver uses `billing_state_for_scope/1`).

**Closeout proof:** Phases 149–150; planning tag `v1.45`; see `.planning/MILESTONES.md` v1.45 entry.

## Prior shipped milestone (v1.44)

### v1.44 — Recovered-Revenue Dashboard Completion (**archived 2026-05-28**)

**Goal:** Delivered the Recovered-Revenue dashboard in AccrueAdmin, visualizing the funnel query and at-risk table. Built on the Phase 143 MRR snapshotting foundation. Included cross-currency widening, recovery-rate API, time-window URL plumbing, and drill-down route.

**Delivered:**
- Funnel query + viz + campaign-anchor retrofit + money formatter polish.
- Time-window URL plumbing + window selector.
- At-risk query + at-risk table + last-failure enrichment.
- Per-subscription drill-down route + CampaignLive.
- Cross-currency widening + recovery-rate API + public docs + adopter-proof.

**Closeout proof:** Phases 144–148; planning git tag `v1.44`; see `.planning/MILESTONES.md` v1.44 entry.

## Prior shipped milestone

### v1.43 — Linked Release 1.2.0 Truth (**archived 2026-05-27**)

**Goal:** Close the linked release-truth gap by locking the three-package contract, shipping the public `1.2.0` trio with canonical proof, and finishing the post-publish planning-mirror plus inventory closeout.

**Delivered:**
- Ad-hoc invoice line items on Draft invoices.
- Example host adopter proofs (metered usage, checkout, recovery).
- Entitlement cache robustness fixes.

**Closeout proof:** `.planning/v1.42-v1.42-MILESTONE-AUDIT.md`.

## Prior shipped milestone

### v1.41 — Admin global search (native Postgres) (**archived 2026-05-26**)

**Goal:** Ecto-native global search for Customers, Invoices, and Subscriptions in the admin UI using Postgres native text search (`pg_trgm`), approaching the Stripe Dashboard UX without adding a separate sidecar dependency.

**Delivered:**
- Postgres native global search using `pg_trgm` indices and similarity queries.
- CMD+K global search component in `accrue_admin`.
- Verified across Customers, Invoices, and Subscriptions.

**Closeout proof:** `.planning/v1.41-v1.41-MILESTONE-AUDIT.md`.

## Prior shipped milestone

### v1.40 — Dunning depth / notification journeys (**archived 2026-05-25**)

**Goal:** Promote failed-payment recovery from today's single un-deduped email + grace/terminal sweeper into a first-party, configurable **multi-step dunning journey** (reminder → wait → escalate → final notice) with a customer recovery surface, admin visibility, and provider-honest + Fake-proven behavior — with Chimeway as an **optional** engine, not a hard dep. Also closes the v1.39 adopter-proof gap by demonstrating entitlements gating in `examples/accrue_host`.

**Delivered:**
- Built-in Oban `Accrue.Dunning.Campaign` — config-driven cadence + per-step Mailglass templates (default journey).
- `Accrue.Dunning.Engine` behaviour + off-by-default `Accrue.Integrations.Chimeway` adapter (SEED-002 #1).
- `:invoice_payment_failed` email idempotency (must-fix double-send) + cancel-on-recovery.
- Customer recovery surface (portal "update card" banner) + admin dunning-state visibility.
- Dunning ledger events + telemetry (incl. a recovered-revenue counter).
- Fake-lane deterministic clock-advance proof + default campaign wired into `examples/accrue_host`.
- Entitlements adopter-proof: an entitlement-gated route/page demonstrated in `examples/accrue_host`.

**Closeout proof:** `.planning/v1.40-v1.40-MILESTONE-AUDIT.md`.

## Prior shipped milestone

### v1.39 — Entitlements / Plan-Gating (**archived 2026-05-24**)

**Previously:** `v1.39 — Entitlements / Plan-Gating` **shipped & archived 2026-05-24** (Phases 123–127, ENT-01..12, planning tag `v1.39`). The canonical six-step SaaS loop (*bill → change/cancel → recover failed
payments → self-serve → **gate access** → operate with an audit trail*) is now
**complete** — entitlements was the last open step. The current public linked
release line is `accrue` / `accrue_admin` / `accrue_portal` `1.1.1`
(published 2026-05-08; tags have since moved to `1.1.2`).

**v1.39 delivered:** first-party, local-first, **fail-closed** plan/feature
gating with **no new tables and no Stripe dependency** on the core gate path
(`Accrue.has_active_plan?` / `entitled?` / `features_for` / `entitlement_quantity`),
a Plug guard + cond-compiled LiveView `on_mount` guard (core stays
runtime-LiveView-free), a provider-honest Resolver + capability matrix, a
lifecycle→entitlement truth-table SSOT, a read-only admin entitlements tab, the
`guides/entitlements.md` spine + JTBD ⛔→✅ flip, and an **isolated, off-by-default**
Stripe-native advisory-sync overlay. Milestone audit: `tech_debt` (DoD achieved,
zero blockers; non-critical follow-ups + partial Nyquist 123–125 deferred).

**Carried posture (unchanged):**

- The active strategy remains **PROC-08**: a bounded dual-provider **gateway subscription core** centered on **Stripe-first** defaults plus one Stripe-like gateway, with **`Accrue.Billing.subscribe/3`** as the primary public-facade entry and **Fake** as the deterministic merge-blocking proof lane. Entitlements shipped **provider-honest**: local plan→feature mapping canonical across all providers, with the optional off-by-default Stripe-native advisory overlay.
- Entitlement guards are **adapter-thin** over host identity (Sigra/Lockspire optional, never required). Accrue never owns the auth user schema.
- Braintree marketplace parity via Hyperwallet remains out of scope unless a future strategy change explicitly reopens it.
- **FIN-03** (app-owned finance exports) and dunning notification journeys remain out of scope (dunning is the leading next-milestone candidate).

## Last shipped milestone

### v1.37 — Subscription Change Management (**archived 2026-05-07**)

**Goal:** Make Accrue feel complete for the most common post-checkout SaaS billing work by promoting active subscription-change management into an explicit first-party contract across the public billing facade, admin/operator surfaces, and customer self-serve portal.

**Delivered:**

- [x] **SCM-01..SCM-02** (Phase 117) — `Accrue.Billing.swap_plan/3` and `preview_upcoming_invoice/2` are now explicit first-party APIs with provider-honest support labels, canonical docs, and merge-blocking drift gates.
- [x] **SCM-03..SCM-05** (Phase 118) — Stripe/Fake quantity and subscription-item changes are official, admin surfaces expose supported preview/change actions, and portal/host flows now support bounded plan-change preview and commit semantics.
- [x] **SCM-06** (Phase 119) — Braintree plan swaps are finalized around the `:plan_resolver` contract, with public docs, host mirrors, and verifier scripts all pinned to the same swap-only boundary.

**Closeout proof:** [milestones/v1.37-ROADMAP.md](milestones/v1.37-ROADMAP.md), [milestones/v1.37-REQUIREMENTS.md](milestones/v1.37-REQUIREMENTS.md), [117-VERIFICATION.md](/Users/jon/projects/accrue/.planning/milestones/v1.37-phases/117-contract-promotion-preview-truth/117-VERIFICATION.md), [118-VERIFICATION.md](/Users/jon/projects/accrue/.planning/milestones/v1.37-phases/118-admin-portal-change-flows/118-VERIFICATION.md), and [119-03-SUMMARY.md](/Users/jon/projects/accrue/.planning/milestones/v1.37-phases/119-braintree-bounded-plan-swap-closeout/119-03-SUMMARY.md). Milestone closeout accepted one known process gap: no dedicated `v1.37` milestone audit artifact was produced before archival.

## Prior shipped milestone

### v1.36 — Dual-Provider Core Completion (**archived 2026-05-07**)

**Goal:** Close the remaining staged rows in the official Stripe + Braintree gateway-subscription-core contract so the shipped support surface is fully consistent, merge-blocking, and no longer half-staged.

**Delivered:**

- [x] **PROC-21** (Phase 112) — `Accrue.Billing.update_customer/2` is now an explicit bounded first-party contract across Fake, Stripe, and Braintree, with matching host/helper proof.
- [x] **PROC-22..PROC-23** (Phase 113, verification backfilled by Phase 115) — immediate cancellation is first-party across the shipped slice, while Braintree scheduled-end semantics stay explicit, typed, and provider-honest across runtime labels, docs, and UI copy.
- [x] **PROC-24** (Phase 114, verification backfilled by Phase 116) — the processor support matrix, package docs, example-host proof docs, and support-contract verifier bundle now repeat one finalized contract and re-fail drift before merge.

**Closeout proof:** [v1.36-v1.36-MILESTONE-AUDIT.md](v1.36-v1.36-MILESTONE-AUDIT.md), [milestones/v1.36-ROADMAP.md](milestones/v1.36-ROADMAP.md), [milestones/v1.36-REQUIREMENTS.md](milestones/v1.36-REQUIREMENTS.md), [113-VERIFICATION.md](/Users/jon/projects/accrue/.planning/milestones/v1.36-phases/113-cancellation-semantics-closure/113-VERIFICATION.md), and [114-VERIFICATION.md](/Users/jon/projects/accrue/.planning/milestones/v1.36-phases/114-contract-drift-gate-closeout/114-VERIFICATION.md).

## Prior shipped milestone

### v1.35 — Dual-Provider Supportability Closure (**archived 2026-05-07**)

**Goal:** Make the shipped Stripe + Braintree surface easier to adopt, easier to operate, and harder to misunderstand by closing contract drift across docs, lifecycle semantics, portal behavior, and webhook/operator truth.

**Delivered:**

- [x] **SUP-01..SUP-02** (Phase 109) — provider-honest support contract across the support matrix, package docs, planning mirrors, First Hour, `accrue_portal`, and example-host proof docs; mounted Braintree onboarding contract and matching drift gates.
- [x] **LIF-01..LIF-02** (Phase 110) — one lifecycle semantics SSOT plus least-surprise portal/admin/example-host wording for cancel renewal, access timing, pause, past-due, ended, and provider-aware lifecycle copy.
- [x] **OPS-01..OPS-02** (Phase 111) — processor-aware webhook, telemetry, and operator runbooks; deterministic replay/DLQ/local portal-completion proof; bounded host verifier and milestone audit rerun green.

**Closeout proof:** [v1.35-v1.35-MILESTONE-AUDIT.md](v1.35-v1.35-MILESTONE-AUDIT.md), [milestones/v1.35-ROADMAP.md](milestones/v1.35-ROADMAP.md), [milestones/v1.35-REQUIREMENTS.md](milestones/v1.35-REQUIREMENTS.md), and [milestones/v1.35-phases/](milestones/v1.35-phases/).

## Prior shipped milestone

### v1.34 — Rendro Native Invoice PDF Default (**archived 2026-05-06**)

**Goal:** Make Rendro the default invoice PDF path in Accrue so the primary install story no longer requires Chrome, while preserving invoice-facing APIs, lazy render semantics, an explicit ChromicPDF compatibility path, and a published Rendro Hex release handoff.

**Delivered:**

- [x] **PDF-01..PDF-05** (Phase 106) — invoice-specific renderer seam, stable `render/store/fetch_invoice_pdf` facade semantics, Rendro default-path proof, and billing/mailer/admin parity.
- [x] **PDF-06..PDF-07** (Phase 107) — typed explicit-Chromic compatibility errors, migration-aware boot warnings, invoice-path telemetry, Hex-backed Rendro dependency resolution, and a clean-checkout release proof script.
- [x] **PDF-08..PDF-09** (Phase 108) — Rendro-first install and migration docs, advanced guide cleanup, package-doc verification, clean HexDocs build, and final billing/mailer/admin closeout proof.

**Closeout proof:** [v1.34-v1.34-MILESTONE-AUDIT.md](v1.34-v1.34-MILESTONE-AUDIT.md), [milestones/v1.34-ROADMAP.md](milestones/v1.34-ROADMAP.md), [milestones/v1.34-REQUIREMENTS.md](milestones/v1.34-REQUIREMENTS.md), and [milestones/v1.34-phases/](milestones/v1.34-phases/).

## Prior shipped milestone

### v1.33 — Braintree Full Maturity (**archived 2026-05-06**)

**Goal:** Close the remaining Braintree maturity gaps by shipping first-party hosted checkout and self-serve portal surfaces, local promotion-code discount mapping, local metered billing with renewal settlement, and a durable written no-go boundary for Hyperwallet marketplace parity.

**Delivered:**

- [x] **BT-01..BT-03** (Phase 101) — mounted `Accrue.Portal` shell, Braintree Hosted Fields checkout, customer dashboard/payment-method/invoice self-serve surfaces, telemetry, and public boundary docs.
- [x] **BT-04..BT-05** (Phase 102) — local discount-mapping table, `subscribe/3` revalidation and drift failure semantics, plus checkout preview/revalidation UX.
- [x] **BT-06..BT-07** (Phase 103) — local metering ledger, renewal invoice authoring, off-session settlement charges, stale-window repair, telemetry catalog, and Braintree metering/operator docs.
- [x] **BT-08..BT-09** (Phase 104) — Hyperwallet spike, explicit no-go verdict, strategy/support-matrix/verifier mirrors, and a narrow reopen rule.

**Closeout proof:** [v1.33-v1.33-MILESTONE-AUDIT.md](v1.33-v1.33-MILESTONE-AUDIT.md), [milestones/v1.33-ROADMAP.md](milestones/v1.33-ROADMAP.md), [milestones/v1.33-REQUIREMENTS.md](milestones/v1.33-REQUIREMENTS.md), and [milestones/v1.33-phases/](milestones/v1.33-phases/).

### v1.30 — `1.0.0` Declaration (Spine A) (**archived 2026-04-28**)

**Goal:** Cut `accrue` / `accrue_admin` `1.0.0` on a single linked Hex publish, with the final post-publish contract sweep verifying everything is consistent at `1.0.0`, the planning mirror aligned, the stability posture flipped to "1.0.0 stable, post-1.0 cadence," and a dated post-publish friction-inventory maintainer pass to certify the post-1.0 surface. **`PROC-08` (second processor) and `FIN-03` (app-owned finance exports) remain explicitly out of scope at 1.0.0** — calling stable does not lift those non-goals.

**Target features:**

- **REL-05..08** — Linked `1.0.0` Hex publish (single coordinated cut for `accrue` and `accrue_admin`), `CHANGELOG` "1.0.0 — Stable" entry per package, `RELEASING.md` post-1.0 cadence section (semver discipline + deprecation policy), planning git tag `v1.30`.
- **PPX-09..12** — Final post-publish contract sweep at `1.0.0`: `verify_package_docs` + `verify_adoption_proof_matrix` + the six-script `docs-contracts-shift-left` bundle re-run clean at `1.0.0`; First Hour + host README + adoption matrix needles refreshed across the surface for the `0.3.1 → 1.0.0` jump.
- **HYG-02** — `.planning/` mirror pass (`PROJECT.md`, `MILESTONES.md`, `STATE.md`) aligned to the published `1.0.0` pair after the linked publish lands.
- **DOC-03..04** — `accrue/README.md` Stability + root README maintenance posture flipped from "pre-1.0 closure" to "1.0.0 stable, post-1.0 cadence"; PROJECT.md non-goals section retained (PROC-08 / FIN-03 reaffirmed as explicitly out of scope at `1.0.0`, with written boundaries — not lifted).
- **INV-07** — Post-1.0 dated maintainer pass `(b)` in `v1.17-FRICTION-INVENTORY.md` certifying the inventory remains accurate at `1.0.0`.

**Key context:**

- Forcing function for the `1.0.0` declaration (Spine A) has been deferred since v1.28; v1.27/28/29 each closed cleanly with no half-finished migrations overhanging the surface, so calling `1.0.0` now does not stack risk.
- Same spine pattern as v1.11 (REL-01..04 / DOC-01..02 / HYG-01) and v1.23/v1.28 (PPX-01..08), but bumped to `1.0.0` rather than another `0.3.x` patch.
- "Ship complete, not MVP" — calling `1.0.0` is the obligation embedded in the project's Core Value (zero breaking-change pain through v1.x), not a stretch.
- **No new feature surface** in this milestone — explicitly out of scope (no second processor, no app-owned finance exports, no new billing primitives).

**Phase numbering:** continues from v1.29 → starts at **Phase 91** (default; no `--reset-phase-numbers`).

**Closeout proof:** `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md`, `.planning/research/v1.17-FRICTION-INVENTORY.md` (`### v1.30 INV-07 maintainer pass (2026-04-28)`), and planning git tag `v1.30`.

**Archives:** [`milestones/v1.30-ROADMAP.md`](milestones/v1.30-ROADMAP.md), [`milestones/v1.30-REQUIREMENTS.md`](milestones/v1.30-REQUIREMENTS.md). **Phase trees:** [`milestones/v1.30-phases/`](milestones/v1.30-phases/).

### v1.29 — Mailglass Integration (**archived 2026-04-26**)

**Goal (shipped):** Replaced `mjml_eex` and `phoenix_swoosh` with the [Mailglass](https://github.com/szTheory/mailglass) framework as a path dependency. Mailglass provides HEEx-native components (no Node MJML compile), an append-only event ledger, native database-level idempotency via `idempotency_key`, and a LiveView dev-preview dashboard mounted at `/dev/mail` in `accrue_admin`. **No** **PROC-08** / **FIN-03**.

**Shipped:**

- [x] **MG-01..MG-03** (Phase 88 — Foundation): path-dep `mailglass` in `accrue` and `mailglass_admin` (dev+test) in `accrue_admin`; `/dev/mail` LiveView mounted via sibling scope; install + email guides updated for the three Mailglass migrations. Validated 2026-04-25 — `088-VERIFICATION.md` (5/5).
- [x] **MG-04..MG-06** (Phase 89 — Proof of Concept): `Accrue.Workers.Mailer` dispatches via `Mailglass.deliver/1` with explicit `idempotency_key` (Oban `unique: [period: 60]` removed); `Accrue.Emails.Receipt` + `Accrue.Emails.PaymentFailed` ported to `Mailglass.Mailable` with PDF attachment intact. Validated 2026-04-26 — `089-01-SUMMARY.md`, `089-02-SUMMARY.md`.
- [x] **MG-07** (Phase 90 — Cleanup): all 13 transactional templates Mailglass-backed; `mjml_eex` + `phoenix_swoosh` removed from `accrue/mix.exs`; 26 legacy `.mjml.eex`/`.text.eex` deleted; `mix accrue.mail.preview` + `Accrue.Emails.HtmlBridge` + `Accrue.Workers.Mailer.template_for/1` retired; `mailglass_cleanup_test` guards regressions. Validated 2026-04-26 — `090-VERIFICATION.md` (6/6) + `090-UAT.md` (7/7 automated).

**Archives:** [`milestones/v1.29-ROADMAP.md`](milestones/v1.29-ROADMAP.md), [`milestones/v1.29-REQUIREMENTS.md`](milestones/v1.29-REQUIREMENTS.md). **Phase trees:** [`milestones/v1.29-phases/`](milestones/v1.29-phases/). **Git tag:** `v1.29`. **Next forcing function:** linked Hex publish for Mailglass itself (gating Mailglass on Hex via `~> x.y` instead of path dep) — outside this milestone's scope.

### v1.28 — Next linked publish continuity (**archived 2026-04-25 — planning complete 2026-04-24**)

**Goal (planning closed):** Post-publish contract work (**PPX-05..08**, same semantics family as **v1.23** **PPX-01..04**) and the dated friction-inventory maintainer pass (**INV-06**). Strategic spine **B** (maintenance / wrap-up plan). **No** **PROC-08** / **FIN-03**.

**Shipped artifacts:**

- [x] **PPX-05..08** — Package docs, adoption matrix + script, `docs-contracts-shift-left`, `.planning/` Hex mirrors aligned to the new `@version` / registry reality. Validated 2026-04-24 — `.planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md` (re-verification at **0.3.1**).
- [x] **INV-06** — Post-publish `v1.17-FRICTION-INVENTORY.md` maintainer pass (b) with `087-VERIFICATION.md` verifier evidence. Validated 2026-04-24 — `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-VERIFICATION.md`.

**Archived requirements:** `.planning/milestones/v1.28-REQUIREMENTS.md`. **Phases:** **86–87** in `.planning/milestones/v1.28-ROADMAP.md`. **Next forcing function:** linked Hex publish per `RELEASING.md` (outside this in-repo planning milestone).

### v1.27 — Pre-1.0 closure narrative (**archived 2026-04-24**)

**Goal (shipped):** Make the **“parked / intake-gated”** maintainer posture and **pre-1.0 vs 1.0.0** intent legible on integrator front doors and release docs—without new billing primitives. Close with a dated **friction inventory** maintainer pass after the doc touch (**INV-05**). **No** **PROC-08** / **FIN-03**.

**Shipped:**

- [x] **CLS-01** — Root + **`accrue`** README surfaces link **maturity-and-maintenance** + **production-readiness** and state **intake-gated** work (no speculative roadmap implied).
- [x] **CLS-02** — **`RELEASING.md`** documents **pre-1.0 closure** maintainer intent; **`upgrade.md`** adds **wrap-up semantics** pointer to maturity doc.
- [x] **CLS-03** — **`accrue/README.md` Stability** clarifies **`0.x`** ≠ open-ended feature expansion; **PROC-08** / **FIN-03** remain **`PROJECT.md`** non-goals (cross-linked from root **Maintenance posture**).
- [x] **INV-05** — Post-CLS doc touch: maintainer pass **(b)** on **`v1.17-FRICTION-INVENTORY.md`** with **`085-VERIFICATION.md`** verifier transcripts (same bundle family as **INV-03** / **INV-04**).

**Evidence:** **`.planning/milestones/v1.27-ROADMAP.md`**, **`v1.27-REQUIREMENTS.md`**, **`milestones/v1.27-phases/84-pre-1-0-closure-narrative/084-VERIFICATION.md`**, **`milestones/v1.27-phases/85-friction-inventory-post-closure/085-VERIFICATION.md`**; inventory **`### v1.27 INV-05 maintainer pass (2026-04-24)`**; planning git tag **`v1.27`**.

### v1.26 — First-hour billing facade spine (**archived 2026-04-24**)

**Goal (shipped):** Put **`Accrue.Billing.create_billing_portal_session/2`** on the same **First Hour + host README + adoption proof matrix + verifier** plane as **`create_checkout_session`**, then run a **dated friction-inventory maintainer pass** after that doc touch. **No** **PROC-08** / **FIN-03**.

**Shipped:**

- [x] **INT-13** — Guide capsule, host README parity (**D-02** / **INT-11**), matrix row + **`verify_adoption_proof_matrix`** (and coupled doc verifiers in the **same PR** when required). **Validated in Phase 82** (`milestones/v1.26-phases/082-first-hour-portal-spine/082-VERIFICATION.md`).
- [x] **INV-04** — Path **(b)** dated maintainer certification + **`083-VERIFICATION.md`** (`milestones/v1.26-phases/083-friction-inventory-post-touch/083-VERIFICATION.md`).

**Evidence:** **`.planning/milestones/v1.26-ROADMAP.md`**, **`v1.26-REQUIREMENTS.md`**, execution trees **`milestones/v1.26-phases/`**; planning git tag **`v1.26`**.

### v1.25 — Evidence-bound triad (friction + integrator + billing depth) (**archived 2026-04-24**)

**Goal (shipped):** **INV-03** maintainer pass; **`Accrue.Billing.create_checkout_session/2`** (**BIL-06**) with **Fake** + **`:telemetry` / span**; **BIL-07** / **INT-12** telemetry + integrator needles — **no** **PROC-08** / **FIN-03**.

**Evidence:** **`.planning/milestones/v1.25-ROADMAP.md`**, **`v1.25-REQUIREMENTS.md`**, execution trees **`milestones/v1.25-phases/`**; planning git tag **`v1.25`**.

### v1.24 — Billing portal facade + customer PM operator surfaces (**archived 2026-04-24**)

**Goal:** Ship bounded **billing depth** (customer **Billing Portal** session creation on **`Accrue.Billing`** with **Fake**-provable tests and **telemetry** aligned to **`guides/telemetry.md`** / runbooks) plus **admin/operator** quality on the **customer `payment_methods`** tab (**`AccrueAdmin.Copy`**, **`ax-*`**, **VERIFY-01** where routes change materially). **No** **PROC-08** / **FIN-03**; no integrator-milestone or Hex-release theme.

**Shipped (planning):**

- **`Accrue.Billing.create_billing_portal_session/2`** (+ **`!`**) delegating to **`Accrue.BillingPortal.Session`**, with **`:telemetry`** / span parity and catalog/runbook updates (**BIL-04**, **BIL-05**) — **`78-VERIFICATION.md`** under **`milestones/v1.24-phases/78-billing-portal-on-accrue-billing-telemetry-truth/`**.
- **Customer LiveView** payment-methods tab: Copy SSOT burn-down, token discipline, theme exceptions (**ADM-13**, **ADM-14**) — **`76-VERIFICATION.md`**.
- **VERIFY-01** + **axe** on materially touched customer paths; **`export_copy_strings`** / **`copy_strings.json`** hygiene (**ADM-15**, **ADM-16**) — **`77-VERIFICATION.md`**.

**Last closed:** **v1.27** (Phases **84–85**); prior **v1.26** (Phases **82–83**); prior **v1.25** (Phases **79–81**); prior **v1.24** (Phases **76–78**); prior **v1.23** (**2026-04-24**).

### v1.23 — Post-publish contract alignment (Branch A — **archived 2026-04-24**)

**Goal:** After each **linked Hex publish** for **`accrue` / `accrue_admin`**, keep merge-blocking **package docs**, **adoption proof matrix**, and **docs-contracts-shift-left** (including **production-readiness discoverability**) honest, and align **`.planning/`** public-Hex callouts — so integrators on **`main`** and on **Hex** see one coherent pin and doc story.

**Shipped:** **PPX-01..PPX-04**; evidence **`milestones/v1.23-phases/75-post-publish-contract-alignment/75-VERIFICATION.md`**; **`v1.17-P1-002`** **closed** in the friction inventory. Archives: **`.planning/milestones/v1.23-ROADMAP.md`**, **`v1.23-REQUIREMENTS.md`**. Planning git tag **`v1.23`**.

**v1.22 — Production path discoverability** is **archived** (**2026-04-24**). Phase **74**; **PRS-01..PRS-03** validated. Phase tree: **`.planning/milestones/v1.22-phases/74-production-path-discoverability/`**. Archives: **`.planning/milestones/v1.22-ROADMAP.md`**, **`v1.22-REQUIREMENTS.md`**. Planning git tag **`v1.22`**.

**v1.21 — Maturity posture and diminishing returns** is **archived** (**2026-04-23**). Phases **72–73**; **MAT-01..MAT-02**, **INT-11** validated. Phase trees: **`.planning/milestones/v1.21-phases/`**. Archives: **`.planning/milestones/v1.21-ROADMAP.md`**, **`v1.21-REQUIREMENTS.md`**. Planning git tag **`v1.21`**.

**v1.20 — Professional adoption confidence** is **archived** (**2026-04-24**). Phases **70–71**; **INV-01..INV-02**, **PRD-01..PRD-02** validated. Phase trees: **`.planning/milestones/v1.20-phases/`**. Archives: **`.planning/milestones/v1.20-ROADMAP.md`**, **`v1.20-REQUIREMENTS.md`**. Planning git tag **`v1.20`**.

**v1.19 — Release continuity + proof resilience** is **archived** (**2026-04-24**). Phases **67–69**; **PRF-01..PRF-02**, **REL-01..REL-03**, **DOC-01..DOC-02**, **HYG-01** validated. Phase trees: **`.planning/milestones/v1.19-phases/67-proof-contracts/`**, **`68-release-train/`**, **`69-doc-planning-mirrors/`**. Archives: **`.planning/milestones/v1.19-ROADMAP.md`**, **`v1.19-REQUIREMENTS.md`**. Planning git tag **`v1.19`**.

### Library maintenance posture (v1.21)

- **Maintenance mode** — merge-blocking **VERIFY-01**, **`verify_package_docs`**, and **host-integration** stay honest on **`main`**; default work is **intake-gated** (security, correctness, Hex publish, sourced integrator stall) rather than speculative multi-file doc sweeps. See stop rules **S1** / **S5** in [North star](research/v1.17-north-star.md).
- **New friction** — add rows only in [Friction inventory](research/v1.17-FRICTION-INVENTORY.md) using the table **priority bar** and **`sources`**; do not hide scope in **ROADMAP** prose alone.
- **Revisit triggers** — maintainer pass on the inventory after **linked Hex publish** for **`accrue` / `accrue_admin`**, or intentional **adoption-proof-matrix** / **`verify_adoption_proof_matrix.sh`** taxonomy edits (same-PR co-update discipline from **v1.19** **PRF**).
- **Spine for humans** — ship checklist **[`accrue/guides/production-readiness.md`](../accrue/guides/production-readiness.md)**; maintainer-facing summary **[`accrue/guides/maturity-and-maintenance.md`](../accrue/guides/maturity-and-maintenance.md)**.

**Triage doctrine (read-only context, v1.17–v1.18):** [North star + stop rules](research/v1.17-north-star.md) · [Friction inventory](research/v1.17-FRICTION-INVENTORY.md)

**v1.18 — Onboarding confidence** is **archived** (**2026-04-23**). Phase **66**; **UAT-01..UAT-05**, **PROOF-01** validated. Phase tree: **`.planning/milestones/v1.18-phases/66-onboarding-confidence/`**. Archives: **`.planning/milestones/v1.18-ROADMAP.md`**, **`v1.18-REQUIREMENTS.md`**. Planning git tag **`v1.18`**.

**v1.17 — Friction-led developer readiness** is **archived** (**2026-04-23**). Phases **62–65**; **FRG-01..FRG-03**, **INT-10**, **BIL-03**, **ADM-12** validated. Archives: **`.planning/milestones/v1.17-ROADMAP.md`**, **`v1.17-REQUIREMENTS.md`**; planning git tag **`v1.17`**. Phase working trees: **`.planning/milestones/v1.17-phases/`**.

**v1.16 — Integrator + proof continuity** is **archived** (2026-04-23). Phases **59–61**; **INT-06..INT-09** validated. Archives: `.planning/milestones/v1.16-ROADMAP.md`, `v1.16-REQUIREMENTS.md`. Planning git tag **`v1.16`**.

**v1.15 — Release / trust semantics** is **archived** (2026-04-23). Phases **57–58**; **TRT-01..TRT-04** validated. Archives: `.planning/milestones/v1.15-ROADMAP.md`, `v1.15-REQUIREMENTS.md`. Planning git tag **`v1.15`**.

**v1.14 — Companion admin + billing depth** is **archived** (2026-04-23). Phases **54–56**; **ADM-07..ADM-11**, **BIL-01..BIL-02** validated. Archives: `.planning/milestones/v1.14-ROADMAP.md`, `v1.14-REQUIREMENTS.md`. Planning git tag **`v1.14`**.

**v1.13 — Integrator path + secondary admin parity** is **archived** (2026-04-23). Phases **51–53**; **INT-01..INT-05**, **AUX-01..AUX-06** validated. Archives: `.planning/milestones/v1.13-ROADMAP.md`, `v1.13-REQUIREMENTS.md`. Planning git tag **`v1.13`**.

**v1.12 — Admin & operator UX** is **archived** (2026-04-22). Phases **48–50**; **ADM-01..ADM-06** validated. Archives: `.planning/milestones/v1.12-ROADMAP.md`, `v1.12-REQUIREMENTS.md`. Planning git tag **`v1.12`**.

**v1.11 — Public Hex release + post-release continuity** is **archived** (2026-04-22). Phases **46–47**; **REL-01..REL-04**, **DOC-01..DOC-02**, **HYG-01** validated. Archives: `.planning/milestones/v1.11-ROADMAP.md`, `v1.11-REQUIREMENTS.md`. Git tag **`v1.11`**.

**v1.10 — Metered usage + Fake parity** is **archived** (2026-04-22). Phases **43–45**; **MTR-01..MTR-08** validated. Archives: `.planning/milestones/v1.10-ROADMAP.md`, `v1.10-REQUIREMENTS.md`. Spike retained: `.planning/research/v1.10-METERING-SPIKE.md`. Git tag **`v1.10`**.

**v1.9 — Observability & operator runbooks** is **archived** (2026-04-22). Archives: `.planning/milestones/v1.9-ROADMAP.md`, `v1.9-REQUIREMENTS.md`. Gap audit (research): `.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md`. Git tag **`v1.9`**.

**v1.7 Adoption DX + operator admin depth** is **archived** (2026-04-21). Archives: `.planning/milestones/v1.7-ROADMAP.md`, `v1.7-REQUIREMENTS.md`, `v1.7-MILESTONE-AUDIT.md` (**passed**). Git tag **`v1.7`**.

### Non-goals (until reprioritized in a future milestone)

**FIN-03** (app-owned finance exports) remains **explicitly out of scope** until a later milestone prioritizes it with written boundaries. **Stripe Dashboard** meter setup UX stays host/Stripe documentation unless a future requirement explicitly pulls UI scope in.

**PROC-08** is no longer a parked non-goal in the abstract: it has been **reopened in v1.31** as a bounded strategic track toward an official dual-provider core. The track remains constrained to **Stripe-like gateway** work and does **not** imply a merchant-of-record or accounting-surface expansion.

### Reaffirmed at 1.0.0 (2026-04-26)

- **PROC-08 (second processor):** explicit non-goal at 1.0.0; reopened on **2026-04-28** via **v1.31** with written boundaries and a persistent strategy tracker.
- **FIN-03 (app-owned finance exports):** explicit non-goal at 1.0.0; Accrue is a billing/subscription library, not an accounting system; revisit only via later-milestone reprioritization with written boundaries.

## Most Recent Milestone (shipped & archived)

### v1.43 — Linked Release 1.2.0 Truth (shipped & archived 2026-05-27)

**Goal (ACHIEVED):** Close the linked release-truth gap by locking the three-package contract, shipping the public `1.2.0` trio (`accrue` / `accrue_admin` / `accrue_portal`) with canonical proof, and finishing the post-publish planning-mirror plus inventory closeout.

**Delivered:**
- Three-package release contract locked in release automation and runbooks (Phase 140).
- Linked `1.2.0` trio published to Hex with canonical post-publish contract sweep (Phase 141).
- Planning-mirror alignment and friction-inventory maintainer pass (Phase 142).

**Phases:** 140–142. **Planning tag:** `v1.43`.

## Standalone post-v1.43 phase

### Phase 143 — Recovered-Revenue Analytics Foundation (verified 2026-05-27)

**Status:** `passed` (4/4 must-haves verified). Standalone phase — not part of v1.43 milestone scope, but informs v1.44.

**Delivered:**
- `Accrue.Analytics.Dunning` Ecto context with `recovered_vs_lost_mrr/1` (aggregates the existing `accrue_events` ledger via JSONB `sum(fragment("(?->>'mrr_value_cents')::integer", e.data))` — no new tables).
- MRR snapshotted into `dunning.recovered` and `dunning.exhausted` event payloads in `Accrue.Webhook.DefaultHandler` (atomic with the existing anchor-clear `Ecto.Multi`).
- `AccrueAdmin.Live.Analytics.RecoveryLive` at `/billing/analytics/recovery` with two `KpiCard` components ("Recovered MRR" / "Lost MRR"), nested in the admin `live_session` for auth inheritance.
- Tests: `accrue/test/accrue/analytics/dunning_test.exs` + `accrue_admin/test/.../recovery_live_test.exs`.

**v1.44 builds on this foundation** with funnel visualization, at-risk drill-down, time-window filters, public docs, and adopter-proof.

## Prior Shipped Milestone

### v1.41 — Admin global search (native Postgres) (shipped & archived 2026-05-26)

**Delivered:** Postgres-native global search (`pg_trgm`) + CMD+K LiveComponent across Customers, Invoices, and Subscriptions. **Phases:** 133–134. **Audit:** `passed`. See `.planning/v1.41-v1.41-MILESTONE-AUDIT.md`.

### v1.40 — Dunning depth / notification journeys (shipped & archived 2026-05-25)

**Goal (ACHIEVED):** Promote failed-payment recovery from today's single un-deduped email + grace/terminal sweeper into a first-party, configurable **multi-step dunning journey** (reminder → wait → escalate → final notice) with a customer recovery surface, admin visibility, and provider-honest + Fake-proven behavior — with Chimeway as an **optional** engine, not a hard dep. Also closes the v1.39 adopter-proof gap by demonstrating entitlements gating in `examples/accrue_host`.

**Delivered:**
- Built-in Oban `Accrue.Dunning.Campaign` — config-driven cadence + per-step Mailglass templates (default journey).
- `Accrue.Dunning.Engine` behaviour + off-by-default `Accrue.Integrations.Chimeway` adapter (SEED-002 #1).
- `:invoice_payment_failed` email idempotency (must-fix double-send) + cancel-on-recovery.
- Customer recovery surface (portal "update card" banner) + admin dunning-state visibility.
- Dunning ledger events + telemetry (incl. a recovered-revenue counter).
- Fake-lane deterministic clock-advance proof + default campaign wired into `examples/accrue_host`.
- Entitlements adopter-proof: an entitlement-gated route/page demonstrated in `examples/accrue_host`.

**Closeout proof:** `.planning/v1.40-v1.40-MILESTONE-AUDIT.md`.

## Recently Completed Milestone

### v1.49 — Realistic Demo App & Adoption Evidence

**Goal:** Transform the example host into a highly realistic, "click-around" adoption evidence demo with rich seeds, E2E automation, and frictionless Docker DX.

**Target features:**
- **Realistic Domain & Rich Seeds:** Define a concrete cohort persona/JTBD and populate the demo app with realistic fixtures (users, plans, subscriptions).
- **Docker DX:** Seamless Docker setup with optimized caching (e.g. Tailwind) for rapid local iteration.
- **E2E Automation:** Comprehensive, non-flakey Playwright tests covering the happy-path journey (install, onboarding, checkout).
- **Adoption DX Docs:** Clear guides with a simple "Start Here" DX summary at the top.

## Current State

**v1.57 — Admin Operator Control Plane (SEED-004 M1) is in flight (opened 2026-07-19, Phases 209–211).** Phase 209 (Reign Subscriptions list + detail CSS coordination) complete 2026-07-19 — `subscriptions_live.ex` recomposed onto the canonical spine (single StatusBadge verdict, one invoice-queue CTA, 4-stat money-at-risk StatStrip, five bespoke bands removed, compact `ax-stack-xs` / `ax-chip.ax-label` cells with no in-cell actions), the shared-CSS coordination with the out-of-scope subscription **detail** page resolved via a D-04 grep-gate + PNG parity check, tests migrated to the post-reign shape (12/12 green), and both generated artifacts (`accrue_admin.css`, `copy_strings.json`) rebuilt. Verified 12/12 must-haves, validating REIGN-01, REIGN-02, COMP-01. Next: Phase 210 (Reign Home + certify answer-first IA).

**v1.55 — OSS Quality Evaluation & Hardening Roadmap shipped & archived 2026-07-03.** Phase 201 produced the evidence-backed software-quality audit at `.planning/milestones/v1.55-phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md`, verified 8/8 must-haves, and validated QLT-01 through QLT-05. Phase 202 produced the focused CI/CD performance and determinism audit at `.planning/milestones/v1.55-phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md`, verified 11/11 must-haves, and validated CI-01 through CI-05 with static topology evidence, explicit metrics-needed boundaries, provider proof classification, and Phase 204-ready handoff rows. Phase 203 produced the accepted database schema contract ADR at `.planning/milestones/v1.55-phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`, verified 5/5 must-haves, validated DB-01 through DB-04, kept `billing` as the default Accrue-owned Postgres schema, preserved explicit `public`, rejected a default `accrue` rename for v1.55, and handed schema-prefix hardening checks to Phase 204. Phase 204 produced the ranked hardening roadmap at `.planning/milestones/v1.55-phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md`, verified 12/12 must-haves, validated RD-01 through RD-04, and grouped future hardening work around public truth, evaluator proof, provider semantics, release safety, CI baseline data, schema guards, package listing trust, host browser setup, release-gate cleanup, and portal readiness. The milestone stayed audit/ADR/roadmap-only: no product behavior, public API, DB default, CI topology, release automation, runtime UI, CSS, route, source, workflow, script, docs mirror, example host, or package metadata changes.

**v1.54 — Admin UI Page-Level Streamlining & Storybook shipped & archived 2026-07-01 (Phases 193–200, 59/59 plans, 23/23 requirements).** The milestone locked SPEC-OVERVIEW/LIST/DETAIL, extended the page-flow baseline, adopted PhoenixStorybook dev/test-only, delivered the Dashboard/Subscription-detail/Subscriptions-list archetype exemplars, extracted `PageHeader`, propagated LIST and DETAIL/analytics patterns across the admin surface, fixed overlay/focus/scroll/floating correctness, completed fixture stress and microcopy sweeps, and closed with Storybook/theming/axe/no-FOUC/reduced-motion/CI guardrail sign-off. The audit passed with 23/23 implementation-verified requirements, 8/8 phase verifications, 8/8 E2E flows, zero blockers, and TOOL-02 pixel-diff visual regression recorded as an accepted out-of-scope deferral.

**v1.53 — Admin UI Design-System Hardening shipped & archived 2026-06-20 (Phases 187–192, 39/39 plans, 33/33 requirements).** The fourth pass on the `accrue_admin` surface completed the interaction-correct and component-systematic baseline that v1.54 then lifted to page-level excellence.

The v1.50→v1.54 arc (Admin UI Foundation → Depth Pass → Brand System → Design-System Hardening → Page-Level Streamlining) closed out the adopter-facing presentation/DX investment: a coherent, distinctly-branded, interaction-correct, page-level-consistent operator UI plus a committed standalone brand book (`brandbook/`), logo system, design tokens, and voice/copy.

**Last shipped planning milestone:** **v1.55** — Phases **201–204** — **2026-07-03** (OSS Quality Evaluation & Hardening Roadmap)
**Hex.pm:** accrue 1.4.0 · accrue_admin 1.4.0 · accrue_portal 1.4.0 (unchanged — v1.55 shipped no package/runtime code; v1.50–v1.54 shipped no new core package code)

## Prior shipped milestone

### v1.48 — Release Readiness + Stable Core Posture (**archived 2026-06-01**)

**Goal:** Publish the post-1.3.0 / v1.47 correctness and adopter-proof work, make the stable-core posture explicit across public and planning surfaces, archive stale backlog anchors, and then pause broad feature work.

**Delivered:**
- Linked release readiness: verified package versions, changelogs, release automation, docs, and deterministic gates.
- Stable-core positioning: updated public docs, package docs, planning mirrors.
- Backlog anchor closure: retired stale planning seeds and friction anchors.
- Pause rule: recorded the maintainer decision that broad feature work should stop unless reopened by concrete evidence.

**Closeout proof:** Phases 159–162; planning tag `v1.48`; see `.planning/MILESTONES.md` v1.48 entry.

## Requirements

### Active

- [ ] Project verified rail evidence into one account snapshot with resource-aware management and duplicate-purchase prevention.
- [ ] Verify, link, reconcile, quarantine, and repair Apple subscription evidence without heuristic ownership transfer.
- [ ] Issue device-bound offline proof that distinguishes fresh, stale-offline, denied, and invalid states while allowing host-owned study-continuity policy.
- [ ] Prove the anonymized Phoenix/Crosswake adopter journey with diagnostics, automatic repair, runbooks, and release gates.

### Validated v1.59 (Phase 215 complete 2026-08-01)

Research, contracts, and Crosswake feasibility — 5/5 requirements satisfied in Phase 215.

- ✓ **RSCH-01** — One versioned v1.59 research authority records source provenance, accepted and rejected choices, and confidence.
- ✓ **RSCH-02** — One canonical decision-case corpus drives deterministic Markdown, JSON, and offline-vector consumers.
- ✓ **RSCH-03** — A dated owner/response watchlist and amendment workflow preserve current research memory.
- ✓ **RAIL-04** — A typed, processor-independent source-capability contract exposes rail-specific observation, control, restore, reconciliation, management, and offline capabilities.
- ✓ **RAIL-05** — The checked-in Crosswake tracer provides one provenance-bound prove-or-block boundary and remains fail-closed while required bridge and physical-device evidence is unavailable.

### Validated v1.59 (Phase 216 complete 2026-08-02)

Additive rail and persistence foundation — 3/3 requirements satisfied in Phase 216.

- ✓ **RAIL-01** — Hosts can register Stripe and Apple concurrently while legacy `processor` configuration remains the supported default-rail alias.
- ✓ **RAIL-02** — Rail/environment/product-qualified catalog keys map to logical plans without cross-rail or sandbox/production collisions.
- ✓ **RAIL-03** — Durable account, observation, grant, and device records enforce stable identity, bounded provenance, quarantine/order metadata, database-decided races, and transactional rollback safety.

### Validated v1.55 (Phases 201-204 complete 2026-07-03)

Software Quality Evaluation — 5/5 satisfied in Phase 201.

- ✓ **QLT-01** — Evidence-backed audit ranks Accrue's weakest adoption, production, maintenance, support, architecture, data, UI, security, release, upgrade, and OSS trust dimensions without equal weighting — Phase 201.
- ✓ **QLT-02** — Top-five weakness deep dives include repo evidence, practical consequences, highest-leverage fixes, and explicit restraint — Phase 201.
- ✓ **QLT-03** — Separate adopter journey, production/SRE journey, maintainer journey, GSD sanity, and missing project-specific dimension coverage — Phase 201.
- ✓ **QLT-04** — Strong and not-applicable dimensions are marked honestly without manufactured concerns — Phase 201.
- ✓ **QLT-05** — Direct repo facts, assumptions, metrics-needed items, and local evidence paths are separated for low scores and recommendations — Phase 201.

CI/CD Performance and Determinism Audit — 5/5 satisfied in Phase 202.

- ✓ **CI-01** — Current CI topology, trigger model, matrix shape, service usage, cache posture, and likely critical path are documented from checked-in workflow evidence — Phase 202.
- ✓ **CI-02** — Duplicated setup, bottlenecks, flaky/determinism risks, cache risks, release risks, and provider-parity risks are identified with concrete repo evidence — Phase 202.
- ✓ **CI-03** — Target pipeline recommendations preserve high-value gates and require measurement before deleting, demoting, reshaping, or making checks optional — Phase 202.
- ✓ **CI-04** — Follow-up work is classified by priority, expected impact, tradeoff, implementation approach, verification, rollback, metric-needed status, and Phase 204 slice fit — Phase 202.
- ✓ **CI-05** — Baseline metrics still needing live GitHub run data are explicit, with dynamic claims labeled as collected evidence, metrics-needed, static inspection, or assumption — Phase 202.

Database Schema Contract ADR — 4/4 satisfied in Phase 203.

- ✓ **DB-01** — ADR explains the current Accrue-owned Postgres schema contract: default `billing`, explicit `public`, Ecto compile-time schema prefix, migration prefix helpers, and host-owned data-migration responsibility — Phase 203.
- ✓ **DB-02** — ADR explains why v1.55 keeps `billing` instead of switching to `accrue`, including pros/cons and upgrade risk — Phase 203.
- ✓ **DB-03** — ADR lists concrete future hardening checks for prefix agreement, raw SQL qualification, installer/docs/test coverage, and explicit old-default compatibility — Phase 203.
- ✓ **DB-04** — ADR identifies which schema-related work belongs in a future implementation milestone and which work is not worth doing now — Phase 203.

Ranked Hardening Roadmap — 4/4 satisfied in Phase 204.

- ✓ **RD-01** — Ranked top-10 hardening list includes area/quality dimension, impact, effort, risk reduction, timing/slice, and done criteria — Phase 204.
- ✓ **RD-02** — Follow-up work is grouped into milestone-sized slices rather than one broad cleanup list — Phase 204.
- ✓ **RD-03** — Ranked rows, implementation cards, and follow-up slices trace back to concrete Phase 201, Phase 202, or Phase 203 evidence — Phase 204.
- ✓ **RD-04** — Polish-only or overbuilt work is explicitly deferred unless it reduces adoption, production, support, release, data, or maintenance risk — Phase 204.

### Validated v1.54 (archived in `.planning/milestones/v1.54-REQUIREMENTS.md`; milestone shipped & archived 2026-07-01)

Admin UI Page-Level Streamlining & Storybook — 23/23 satisfied across Phases 193–200.

- ✓ **RES-01..RES-04, STY-01** — Research, page-flow baseline, spike decisions, CSS source guards, and PhoenixStorybook dev/test-only foundation — Phase 193.
- ✓ **EXE-01** — Dashboard overview exemplar and Recovery analytics overview grammar — Phase 194.
- ✓ **EXE-02** — Subscription detail summary-then-drill object-detail exemplar with drawer-hosted actions and overlay handoff — Phase 195.
- ✓ **EXE-03, PGH-01** — Subscriptions list exemplar plus shared `PageHeader` contract — Phase 196.
- ✓ **PRP-01** — All eight remaining list pages conform to SPEC-LIST, adopt `PageHeader`, carry per-page JTBD microcopy, and have four-state coverage — Phase 197.
- ✓ **PRP-02** — Remaining detail and analytics pages conform to SPEC-DETAIL / overview grammar — Phase 198.
- ✓ **IXN-01..IXN-04, FIX-01..FIX-02, CPY-01** — Canonical overlay primitive, scroll/focus/floating/theme correctness, deterministic fixture stress, and brand-voice microcopy sweep — Phase 199.
- ✓ **VER-01..VER-03, STY-02..STY-03** — Zero-regression union scorecard, Storybook coverage/theming, axe/no-FOUC/reduced-motion/CI guardrails, adversarial judge, and maintainer ACCEPT sign-off — Phase 200.

### Validated v1.53 (archived in `.planning/milestones/v1.53-REQUIREMENTS.md`; milestone shipped & archived 2026-06-20)

Admin UI Design-System Hardening — 33/33 satisfied across Phases 187–192.

- ✓ **VER-01** — refreshed 12-dimension rubric + 21,276-cell scored baseline + 800-row AX187 severity-ranked defect ledger as the only-forward reference point — v1.53
- ✓ **FND-01..FND-06** — composed `ax-*` typography bundles + reading-measure; tokenized z-index/layer scale (no ad-hoc literals); motion-token closure with `prefers-reduced-motion`; inert-Tailwind resolved to one styling SSOT; contrast-correct dark-mode roles (focus rings, scrollbars, disabled) — v1.53
- ✓ **CMP-01..CMP-05** — registry-driven `/dev/components` state-matrix gallery (14 families) + 8 new primitives; full state matrix × theme × viewport; a11y (role/keyboard/focus/name); component-root token fixes propagating to all consumers — v1.53
- ✓ **GRP-01..GRP-04** — recurring component *groups* audited as units from a canonical group-contract registry; responsive table→card degradation; consistent KPI cards; de-emphasized empty pagination — v1.53
- ✓ **IXN-01..IXN-05** — package-local FocusTrap + regression coverage for Phase-187 behavioral defects (modal-behind-scrim, scroll traps, post-patch focus loss, overlay z-index); keyboard-complete flows — v1.53
- ✓ **PAGE-01..PAGE-04** — every page walked against persona/JTBD across happy/empty/loading/error/permission/boundary/disconnected paths; verified at 320/375/768/1024/1440 in light+dark — v1.53
- ✓ **CPY-01..CPY-03** — recoverable error microcopy, object-named destructive confirmations, consistent domain vocabulary — v1.53
- ✓ **SEED-01..SEED-02** — idempotent `examples/accrue_host` seeds reaching every matrix cell in one click — v1.53
- ✓ **VER-02..VER-04** — final scorecard ≥ baseline across all 21,276 cells (zero regressions); merge-blocking CI regression guardrails; maintainer sign-off ACCEPT (closes v1.51 photographic-sign-off tech-debt) — v1.53

### Validated v1.52 (archived in `.planning/milestones/v1.52-REQUIREMENTS.md`; milestone shipped & archived 2026-06-14)

Brand System — 14/14 satisfied (AUD-01..03, LOGO-01..04, TOK-01..03, COPY-01..02, BOOK-01..02) across Phases 180–186.

- ✓ **AUD-01..AUD-03** — 14-section ratified `BRAND-AUDIT.md`, locked `BRAND-DNA.md` + binding `logo-brief.md` + quality-gate checklist, committed WCAG contrast evidence; user ratified all verdicts at the audit checkpoint — v1.52
- ✓ **LOGO-01..LOGO-03** — opentype.js Geist-outline harness with 6 pre-gate lints; file://-openable round-1 gallery (16 candidates × 4 directions); monotonic `TOURNAMENT.md` tournament to locked winner **R2-7** (two-tone stepped mark) — v1.52
- ✓ **LOGO-04** — complete production logo system at `brandbook/logo/` (21 committed files): lockups, wordmark, mark, mono/inverse, clearspace, social card (SVG+PNG), favicon (SVG+.ico+PNG), with-subtitle variant, PWA/apple-touch icons; all outlined paths, svgo-optimized, `<title>`/`<desc>` metadata, OFL/Geist provenance — v1.52
- ✓ **TOK-01..TOK-03** — `brandbook/tokens/` (palette, semantic roles, type/spacing/radius/focus/state) + automated `ax-*` parity check (zero admin changes) + palette/typography/spacing specimens — v1.52
- ✓ **COPY-01..COPY-02** — committed voice system + ready-to-paste copy for GitHub/Hex.pm/HexDocs/README/landing/release-notes/microcopy, reviewed in one batch — v1.52
- ✓ **BOOK-01..BOOK-02** — self-contained, file://-openable `brandbook/index.html` (inline CSS/SVG, no build step); passes the Phase-180 quality gate within the ≤2 MB budget — v1.52

### Validated v1.51 (archived in `.planning/milestones/v1.51-REQUIREMENTS.md`; milestone shipped & archived 2026-06-04)

Admin UI Depth Pass — 22/22 satisfied (DSY-01..03, IA-01..07, SCR-01..04, MOT-01..03, SEED-01..02, QA-01..03) across Phases 174–179.

### Validated v1.50 (archived in `.planning/milestones/v1.50-REQUIREMENTS.md`; milestone shipped 2026-06-02 via PR #32, archived 2026-06-03)

Admin UI Foundation — 7/7 satisfied.

- ✓ **AUI-01..AUI-02** — Tightened `ax-*` design tokens + token-based motion (zero bypasses); distinct brand typography (Geist), heroicons, favicon — v1.50
- ✓ **AUI-03..AUI-04** — uk.gov-style task-launcher home, job-aligned nav regroup, always-on `Cmd-K` search; cross-screen threading (no dead ends), breadcrumbs, plain-language microcopy — v1.50
- ✓ **AUI-05..AUI-06** — Shared `<.detail_section>` components + skeleton/empty states; seed enrichment + rebuilt component kitchen (host seed dunning bug fixed) — v1.50
- ✓ **AUI-07** — 10-dimension rubric audit; desktop/mobile/dark screenshot coverage + automated axe a11y — v1.50

### Validated v1.49 (archived in `.planning/milestones/v1.49-REQUIREMENTS.md`; milestone shipped & archived 2026-06-02)

Realistic Demo App & Adoption Evidence — 11/11 satisfied.

- ✓ **EVD-01..EVD-02** — Realistic SaaS cohort persona and rich database seeds — v1.49
- ✓ **EVD-03..EVD-04** — Docker DX & optimized caching — v1.49
- ✓ **E2E-01..E2E-04** — Deterministic Playwright E2E coverage and CI integration — v1.49
- ✓ **DOC-01..DOC-03** — Docker-first, persona-framed Start Here documentation — v1.49

### Validated v1.48 (archived in `.planning/milestones/v1.48-REQUIREMENTS.md`; milestone completed 2026-06-01)

Release Readiness + Stable Core Posture — 9/9 satisfied.

- ✓ **REL-01..REL-03** — Linked release readiness, deterministic gate evidence, and canonical post-publish proof of the 1.4.0 line — v1.48
- ✓ **POS-01..POS-03** — Stable-core public positioning, package/doc mirrors, and CI posture contract — v1.48
- ✓ **BAK-01..BAK-02** — Historical backlog anchors and dormant/deferred planning surfaces no longer imply active broad-feature scope — v1.48
- ✓ **PAU-01** — Post-v1.48 broad-feature pause rule with concrete reopen criteria — v1.48

### Validated v1.47 (archived in `.planning/milestones/v1.47-REQUIREMENTS.md`; milestone shipped & archived 2026-05-31)

ENT-10 Polish + Adopter-Proof Completeness — 11/11 satisfied.

- ✓ **ADV-01..ADV-04** — Advisory cache concurrency, NULL watermark, stale telemetry, and concurrent delivery proof — v1.47
- ✓ **POL-01..POL-04** — Advisory cache processor/livemode fidelity, fixture polish, and telemetry metrics polish — v1.47
- ✓ **PRF-01** — Entitlements gating adopter proof in `examples/accrue_host` — v1.47
- ✓ **PRF-02** — Metered usage adopter proof in `examples/accrue_host` — v1.47
- ✓ **PRF-03** — Oban cron and queue wiring adopter proof in `examples/accrue_host` — v1.47

### Validated v1.46 (archived in `.planning/milestones/v1.46-REQUIREMENTS.md`; milestone shipped & archived 2026-05-30)

Maintenance & Closure — 1/1 satisfied.

- ✓ **MNT-01** — Routine issue triage and repository maintenance — v1.46

### Validated v1.41 (archived in `.planning/milestones/v1.41-REQUIREMENTS.md`; milestone shipped & archived 2026-05-26)

Admin global search — 4/4 satisfied.

- ✓ **SRCH-01** — Global search backend using Postgres `pg_trgm` similarity.
- ✓ **SRCH-02** — CMD+K Keyboard navigation in admin UI.
- ✓ **SRCH-03** — Unified search results for Customers, Invoices, Subscriptions.
- ✓ **SRCH-04** — Zero-sidecar search implementation.

... (rest of requirements unchanged) ...

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-08-02 after completing Phase 216 additive rail and persistence foundation.*
