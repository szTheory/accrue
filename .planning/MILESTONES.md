# Milestones

## v1.13 Integrator path + secondary admin parity (Shipped: 2026-04-23)

**Planning opened:** 2026-04-22

**Phases completed:** 3 phases (51–53), **8** plans

**Key accomplishments:**

- **Phase 51 (INT-01..INT-03):** Single **First Hour** ↔ **`accrue_host` README** integrator spine with H/M/R capsules; repo-root **VERIFY-01** discoverability; **troubleshooting** / webhooks anchors with stable slugs and bounded first-run failure callouts.
- **Phase 52 (INT-04, INT-05, AUX-01, AUX-02):** Honest **adoption proof matrix** + **Hex** / **`verify_package_docs`** alignment; **`AccrueAdmin.Copy.Coupon`** + **`Copy.PromotionCode`** with LiveView + ExUnit literal discipline on coupon/promo paths.
- **Phase 53 (AUX-03..AUX-06):** **`AccrueAdmin.Copy.Connect`** + **`Copy.BillingEvent`** for Connect/events surfaces; **theme-exceptions** note; **VERIFY-01** Playwright + **axe** on auxiliary mounted routes; **`export_copy_strings`** allowlist + **`copy_strings.json`** regeneration.

**Theme:** **Integrator golden path** docs + **auxiliary admin** parity with **`AccrueAdmin.Copy`**, **`ax-*`**, and **VERIFY-01** — **no** **PROC-08** / **FIN-03** / new UI kits.

**Milestone audit:** No standalone `v1.13-MILESTONE-AUDIT.md`; closure used per-phase verification, **`ROADMAP.md`** shipped table, and requirements archive (**11/11 Complete**).

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (see `.planning/STATE.md` § Deferred Items).

**Phase directories:** **`phases.clear` not run** — preserves **1–50** trees under **`.planning/phases/`** for traceability.

**Archives:**

- Roadmap: [`milestones/v1.13-ROADMAP.md`](milestones/v1.13-ROADMAP.md)
- Requirements: [`milestones/v1.13-REQUIREMENTS.md`](milestones/v1.13-REQUIREMENTS.md)

**Git tag:** `v1.13`

**Next after ship:** `/gsd-new-milestone` when priorities for **v1.14+** are set.

---

## v1.12 Admin & operator UX (Shipped: 2026-04-22)

**Planning opened:** 2026-04-22

**Phases completed:** 3 phases (48–50), **6** plans

**Key accomplishments:**

- **Phase 48 (ADM-01):** Dashboard **MeterEvent** terminal-failed KPI with honest **`/events`** deep link and **`AccrueAdmin.Copy`**-backed operator strings.
- **Phase 49 (ADM-02, ADM-03):** **SubscriptionLive** drill parity (**`ScopedPath`**, related billing card); automated drill href proofs at admin + mounted host; README **router vs sidebar** note.
- **Phase 50 (ADM-04..ADM-06):** **`AccrueAdmin.Copy.Subscription`** + LiveView migration; **`theme-exceptions.md`** register + contributor checklist; **`mix accrue_admin.export_copy_strings`** with CI **`copy_strings.json`**; VERIFY-01 **subscriptions** axe/spec fed from exported copy.

**Theme:** Post-metering **admin signals**, **drill/nav** polish, **Copy + token** discipline, **VERIFY-01** gates on touched mounted paths — **no** **PROC-08** / **FIN-03**.

**Milestone audit:** No standalone `v1.12-MILESTONE-AUDIT.md`; closure used per-phase **`*-VERIFICATION.md`** / **`50-VERIFICATION.md`** and requirements traceability (6/6 Complete).

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (see `.planning/STATE.md` § Deferred Items).

**Phase directories:** **`phases.clear` not run** — preserves **40–50** trees under **`.planning/phases/`** for traceability.

**Archives:**

- Roadmap: [`milestones/v1.12-ROADMAP.md`](milestones/v1.12-ROADMAP.md)
- Requirements: [`milestones/v1.12-REQUIREMENTS.md`](milestones/v1.12-REQUIREMENTS.md)

**Git tag:** `v1.12`

**Next after ship:** `/gsd-new-milestone` when priorities for **v1.13+** are set.

---

## v1.11 Public Hex release + post-release continuity (Shipped: 2026-04-22)

**Planning opened:** 2026-04-22

**Phases:** **46–47** (see root `.planning/ROADMAP.md`) — **6** plans total, **Complete 2026-04-22**.

**Theme:** Publish **`accrue`** / **`accrue_admin`** to Hex via Release Please **linked versions**, then align **`RELEASING.md`**, **`first_hour`**, **`verify_package_docs`**, and planning Hex version callouts. **PROC-08** / **FIN-03** remain non-goals.

**Current public Hex (lockstep):** **`accrue` 0.3.0** and **`accrue_admin` 0.3.0** — mirror **`accrue/mix.exs`** / **`accrue_admin/mix.exs`** **`@version`** (not a second SSOT).

**Requirements:** archived in [`milestones/v1.11-REQUIREMENTS.md`](milestones/v1.11-REQUIREMENTS.md) (**REL-**, **DOC-**, **HYG-**); all **7/7** complete.

**Next after ship:** `/gsd-discuss-phase 48` or `/gsd-new-milestone` for the next implementation slice.

**Archives:**

- Roadmap: [`milestones/v1.11-ROADMAP.md`](milestones/v1.11-ROADMAP.md)
- Requirements: [`milestones/v1.11-REQUIREMENTS.md`](milestones/v1.11-REQUIREMENTS.md)

**Git tag:** `v1.11`

---

## v1.10 Metered usage + Fake parity (Shipped: 2026-04-22)

**Phases completed:** 3 phases (43–45), **10** plans

**Key accomplishments:**

- **Phase 43 (MTR-01..MTR-03):** Public `Accrue.Billing.report_usage` NimbleOptions + ExDoc SSOT; `accrue_meter_events` lifecycle semantics; Fake happy-path determinism without private-module assertions for ordinary cases.
- **Phase 44 (MTR-04..MTR-06):** Guarded `MeterEvents` failure + `meter_reporting_failed` telemetry (`:sync`, `:reconciler`, `:webhook`); idempotent retries on terminal rows; reconciler + webhook meter error coverage aligned to `DefaultHandler`.
- **Phase 45 (MTR-07..MTR-08):** `guides/metering.md` for public vs internal vs processor boundaries; `guides/telemetry.md` + `guides/operator-runbooks.md` alignment for metering failure sources.

**Theme:** Usage metering provable on **Fake** in CI with stable ops telemetry keys; **PROC-08** / **FIN-03** remain non-goals.

**Milestone audit:** No standalone `v1.10-MILESTONE-AUDIT.md`; closure used **research/v1.10-METERING-SPIKE.md**, per-phase verification, and requirements traceability (8/8 Complete).

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (see `.planning/STATE.md` § Deferred Items).

**Archives:**

- Roadmap: [`milestones/v1.10-ROADMAP.md`](milestones/v1.10-ROADMAP.md)
- Requirements: [`milestones/v1.10-REQUIREMENTS.md`](milestones/v1.10-REQUIREMENTS.md)

**Git tag:** `v1.10`

---

## v1.9 Observability & operator runbooks (Shipped: 2026-04-22)

**Phases completed:** 3 phases (40–42), **8** plans

**Key accomplishments:**

- **Phase 40 (OBS-01, OBS-03, OBS-04):** Authoritative `guides/telemetry.md` ops catalog with measurements/metadata; firehose vs ops split; `OpsEventContractTest` anti-drift; `[:accrue, :ops, :webhook_dlq, :dead_lettered]` on exhausted dispatch; gap audit §1 reconciled in guide + research doc.
- **Phase 41 (OBS-02, TEL-01):** `MetricsOpsParityTest` (or documented omissions) vs ops signals; cross-domain host `Telemetry` example in docs + `examples/accrue_host`.
- **Phase 42 (RUN-01):** `accrue/guides/operator-runbooks.md` (Oban topology, Stripe verification, D-09 mini-playbooks); `telemetry.md` preface and row-level links to runbooks.

**Theme:** Telemetry discoverability, metrics wiring parity, operator first-response runbooks — **no** new billing primitives. **PROC-08** / **FIN-03** remain non-goals.

**Research:**

- [`.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md`](research/v1.9-TELEMETRY-GAP-AUDIT.md)
- [`.planning/research/v1.10-METERING-SPIKE.md`](research/v1.10-METERING-SPIKE.md) (input to **v1.10+**)

**Milestone audit:** No standalone `v1.9-MILESTONE-AUDIT.md`; closure used gap-audit research, per-phase verification, and requirements traceability (6/6 Complete).

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (see `.planning/STATE.md` § Deferred Items).

**Archives:**

- Roadmap: [`milestones/v1.9-ROADMAP.md`](milestones/v1.9-ROADMAP.md)
- Requirements: [`milestones/v1.9-REQUIREMENTS.md`](milestones/v1.9-REQUIREMENTS.md)

**Git tag:** `v1.9`

---

## v1.8 Org billing recipes & host integration depth (Shipped: 2026-04-22)

**Phases completed:** 3 phases (37–39), **8** plans

**Key accomplishments:**

- **Phase 37 (ORG-05, ORG-06):** Single `organization_billing.md` spine for session → billable + ORG-03; phx.gen.auth checklist; installer/README/quickstart/finance-handoff discoverability and guide tests.
- **Phase 38 (ORG-07, ORG-08):** Pow-oriented recipe with maintenance honesty; custom org obligations, admin scoping, webhook replay alignment, and ORG-03 anti-pattern table.
- **Phase 39 (ORG-09):** Adoption proof matrix non-Sigra org archetype; merge-blocking `verify_adoption_proof_matrix.sh`; contributor map in `scripts/ci/README.md`; guide + ExUnit gates from `accrue` package.

**Theme:** Deferred **ORG-04** — non-Sigra org billing recipes + VERIFY/adoption-proof alignment. **PROC-08** and **FIN-03** remain out of scope.

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (see `.planning/STATE.md` § Deferred Items).

**Archives:**

- Roadmap: [`milestones/v1.8-ROADMAP.md`](milestones/v1.8-ROADMAP.md)
- Requirements: [`milestones/v1.8-REQUIREMENTS.md`](milestones/v1.8-REQUIREMENTS.md)

**Git tag:** `v1.8`

---

## v1.7 Adoption DX + operator admin depth (Shipped: 2026-04-21)

**Phases completed:** 5 phases (32–36), **14** plans

**Key accomplishments:**

- **Phase 32–33 (ADOPT):** VERIFY-01 reachable within two hops from the repo root; host README single authoritative Fake-first subsection; guides cross-linked; installer rerun semantics + doc anchors enforced by verifiers; CI/docs keep merge-blocking vs advisory Stripe lanes without renaming job ids.
- **Phase 34 (OPS-01..03):** Operator home KPIs with deep links; customer→invoice drill and invoice breadcrumbs; `AccrueAdmin.Nav` labels/order aligned with README **Admin routes** inventory.
- **Phase 35 (OPS-04..05):** Dashboard surfaces stay on `ax-*` / tokens; operator-visible strings centralized in `AccrueAdmin.Copy` with Playwright + ExUnit alignment (`copy_dashboard.js` where needed).
- **Phase 36:** Three-source traceability for Phase 32–33 plans; `scripts/ci/README.md` maps ADOPT-01..06 to owning verifiers + `[verify_package_docs]` stderr prefix; dual-contract notes in `accrue/guides/testing.md`; forward-coupling doc for OPS-03..05.

**Verification:** `32-VERIFICATION.md` through `36-VERIFICATION.md` (all **passed**).

**Milestone audit:** [`milestones/v1.7-MILESTONE-AUDIT.md`](milestones/v1.7-MILESTONE-AUDIT.md) — **passed** (refreshed 2026-04-21).

**Known deferred items at close:** same **audit-open** carry-forward as prior closes (2 missing quick-task stubs + Phase 21 UAT metadata); see `.planning/STATE.md` § Deferred Items.

**Archives:**

- Roadmap: [`milestones/v1.7-ROADMAP.md`](milestones/v1.7-ROADMAP.md)
- Requirements: [`milestones/v1.7-REQUIREMENTS.md`](milestones/v1.7-REQUIREMENTS.md)
- Audit: [`milestones/v1.7-MILESTONE-AUDIT.md`](milestones/v1.7-MILESTONE-AUDIT.md)

**Git tag:** `v1.7`

---

## v1.6 Admin UI / UX polish (Shipped: 2026-04-20)

**Phases completed:** 5 phases (25–29), 16 plans

**Key accomplishments:**

- Maintainer route matrix, component coverage vs `ComponentKitchenLive`, and Phase 20/21 UI-SPEC alignment tables checked into `.planning/phases/25-admin-ux-inventory/` (INV-01..03).
- Money indexes, detail pages, and webhook surfaces aligned to `ax-*` hierarchy and typography; theme tokens default with documented exceptions (UX-01..04).
- Plain-language empty/error/confirm copy plus `AccrueAdmin.Copy` module for stable Playwright and LiveView literals (COPY-01..03).
- Step-up focus, table captions on customers/webhooks, VERIFY-01 axe (serious/critical) on mounted admin, and verification notes for contrast (A11Y-01..04).
- Mobile overflow/nav assertions, `verify01-admin-mobile.spec.js`, and README **Mounted admin — mobile shell** documentation for VERIFY-01 (MOB-01..03).

**Verification:** Phase `25-VERIFICATION.md`, `26-VERIFICATION.md`, `28-VERIFICATION.md`, `29-VERIFICATION.md`; host Playwright mobile + desktop gates per existing CI.

**Known deferred items at close:** 3 (see `.planning/STATE.md` § Deferred Items — `audit-open` at milestone close, acknowledged under yolo workflow).

**Archives:**

- Roadmap: [`milestones/v1.6-ROADMAP.md`](milestones/v1.6-ROADMAP.md)
- Requirements: [`milestones/v1.6-REQUIREMENTS.md`](milestones/v1.6-REQUIREMENTS.md)

---

## v1.6 audit gap closure — post-ship (Closed: 2026-04-21)

**Phases completed:** 2 phases (30–31), 5 plans (2 + 3)

**Key accomplishments:**

- **Phase 30 — Audit corpus:** COPY-01..03 requirement coverage table added to `27-VERIFICATION.md`; `requirements-completed` YAML backfilled on all Phase **26** and **29** plan summaries for strict 3-source traceability.
- **Phase 31 — Advisory integration:** VERIFY-01 README/CI contract enforces mobile spec anchors and `npm run e2e:mobile`; step-up modal operator chrome uses `AccrueAdmin.Copy`; fixture Playwright + `accrue_admin` browser workflow + README align on host VERIFY-01 as the merge-blocking mounted-admin path.

**Verification:** Phase summaries `30-01`, `30-02`, `31-01`..`31-03`; milestone audit refreshed to **passed** in [`milestones/v1.6-MILESTONE-AUDIT.md`](milestones/v1.6-MILESTONE-AUDIT.md).

**Known deferred items at planning line close:** 3 (`audit-open` 2026-04-21 — same carry-forward class as v1.6 ship: Phase 21 UAT metadata + two missing quick-task stubs; acknowledged per `/gsd-complete-milestone`, see `.planning/STATE.md` § Deferred Items).

**Git tag:** Existing **`v1.6`** tag unchanged (no duplicate tag); this slice is planning/audit closure only.

---

## v1.5 Adoption proof hardening (Shipped: 2026-04-18)

**Phases completed:** 1 phase (24), documentation-only execution

**Key accomplishments:**

- Host adoption proof matrix (`examples/accrue_host/docs/adoption-proof-matrix.md`) tying Fake VERIFY-01, bounded/full ExUnit, Playwright, and advisory Stripe test-mode parity.
- Evaluator screen-recording checklist (`evaluator-walkthrough-script.md`) linked from the host README.
- README VERIFY-01 contract extended; CI job display name clarifies Stripe test mode; `accrue/guides/testing.md` and `guides/testing-live-stripe.md` cross-linked for contributor clarity.

**Verification:** `verify_verify01_readme_contract.sh` + existing `mix test` for `accrue` docs guide tests.

**Known deferred items at close:** 3 (see `.planning/STATE.md` § Deferred Items — `audit-open` carry-forward).

**Archives:**

- Roadmap: [`milestones/v1.5-ROADMAP.md`](milestones/v1.5-ROADMAP.md)
- Requirements: [`milestones/v1.5-REQUIREMENTS.md`](milestones/v1.5-REQUIREMENTS.md)

---

## v1.4 Ecosystem stability + demo visuals (Shipped: 2026-04-17)

**Phases completed:** 1 phase (23), 2 plans

**Key accomplishments:**

- `lattice_stripe` lockfile refresh across monorepo packages on latest 1.1.x.
- Visual walkthrough (`e2e:visuals`), CI screenshot artifact documentation, committed real `accrue_admin` esbuild static bundle for mounted LiveView.

**Archives:** v1.4 requirements captured historically in git; see `PROJECT.md` Shipped v1.4 section.

---

## v1.3 Tax + Organization Billing (Shipped: 2026-04-17)

**Phases completed:** 5 phases (18–22), 23 plans

**Key accomplishments:**

- Stripe Tax core with automatic-tax projections, checkout parity, and Fake-backed regression coverage.
- Customer tax-location capture/validation, invalid-location recovery, finalization-failure surfacing, and rollout-safety documentation (including non-retroactive Stripe Tax enablement).
- Sigra-first organization billing in `examples/accrue_host` with active-organization scope, row-scoped admin queries, webhook replay proof, and cross-org denial UX.
- Admin/host UX proof: BillingPresentation, money-index signals, tenant chrome, Tax & ownership card, README VERIFY-01 + CI `host-integration` contract.
- Finance handoff guide (`accrue/guides/finance-handoff.md`) for Stripe Revenue Recognition, Sigma, Data Pipeline, audit-ledger positioning, and explicit non-accounting boundaries; doc contract test.

**Verification:**

- Milestone audit: [`milestones/v1.3-MILESTONE-AUDIT.md`](milestones/v1.3-MILESTONE-AUDIT.md) (passed; see STATE.md for acknowledged `audit-open` carry-forward).
- VERIFY-01: CI-backed host integration + `mix verify.full`; Phase 22 doc test for finance guide.

**Known deferred items at close:** see `.planning/STATE.md` § Deferred Items (quick-task stubs; GSD audit tooling flag on Phase 21 UAT).

**Archives:**

- Roadmap: [`milestones/v1.3-ROADMAP.md`](milestones/v1.3-ROADMAP.md)
- Requirements: [`milestones/v1.3-REQUIREMENTS.md`](milestones/v1.3-REQUIREMENTS.md)
- Audit: [`milestones/v1.3-MILESTONE-AUDIT.md`](milestones/v1.3-MILESTONE-AUDIT.md)

---

## v1.2 Adoption + Trust (Shipped: 2026-04-17)

**Phases completed:** 5 phases, 13 plans, 26 tasks

**Key accomplishments:**

- Manifest-backed demo modes with host-local `mix verify` and `mix verify.full`, plus a repo-root wrapper that now delegates to the same full gate
- Manifest-backed tutorial parity tests plus a narrow shell verifier for command labels, links, anchors, and package versions
- A Fake-first host tutorial, mirrored First Hour guide, and compact package README that now teach one coherent subscription, webhook, admin-inspection, and proof flow
- Root repository front door with a proof-backed package map, stable public setup boundaries, and downstream admin positioning
- Structured GitHub issue intake with no-secrets warnings, private security routing, and public-boundary support taxonomy
- Release guidance that locks Fake as the required deterministic lane while Stripe test mode and live Stripe stay separate provider-parity and advisory checks
- Checked-in trust review plus executable leakage and release-language contracts for trust evidence, secret-safe docs, and failure-only retained artifacts
- Seeded webhook latency smoke in `mix verify` plus desktop/mobile admin trust coverage with blocking Axe and responsiveness checks
- CI now encodes the support floor, primary target, advisory cells, and Phase 15 host trust artifact policy inside the existing workflow
- Ranked Phase 16 expansion decisions with a checked-in recommendation artifact, ExUnit docs contract, and artifact-first validation map
- Phase 16 verification evidence plus durable roadmap, requirements, and project guidance for the ranked Stripe Tax, org billing, revenue/export, and second-processor recommendations
- Exact ranked candidate-to-outcome docs contract for the Phase 16 expansion recommendation
- Canonical-demo bookkeeping is closed, host browser seed cleanup is fixture-scoped, and release/contributor docs now track the current trust lanes only

**Verification:**

- Milestone audit: 23/23 requirements, 4/4 pre-cleanup phases, 23/23 integrations, 6/6 flows; non-critical tech debt closed by Phase 17.
- Phase 17 verification: 5/5 must-haves passed after traceability cleanup.
- Security audit: 5/5 Phase 17 threats closed; `threats_open: 0`.

**Deferred / carry-forward:**

- Recommended next implementation candidate: Stripe Tax support.
- Backlog candidates: Organization / multi-tenant billing and Revenue recognition / exports.
- Planted seed: Official second processor adapter.

**Archives:**

- Roadmap archive: [`milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md)
- Requirements archive: [`milestones/v1.2-REQUIREMENTS.md`](milestones/v1.2-REQUIREMENTS.md)
- Audit archive: [`milestones/v1.2-MILESTONE-AUDIT.md`](milestones/v1.2-MILESTONE-AUDIT.md)

---

## v1.1 Stabilization + Adoption (Shipped: 2026-04-17)

**Delivered:** Real host-app proof, CI integration gate, hermetic host-flow tests, and first-user DX/docs stabilization for the published Accrue packages.

**Phases completed:** 10-12 plus 11.1 (4 phases, 22 plans, 42 tasks)

**Key accomplishments:**

- Built `examples/accrue_host` as a realistic Phoenix dogfood app using the public installer, generated billing facade, scoped webhook route, Fake processor, and mounted `accrue_admin`.
- Proved signed-in billing, signed webhook ingest, admin inspect/replay, audit events, clean-checkout rebuild, and local boot paths with executable host tests.
- Promoted the host-app proof into CI with a Playwright browser gate, retained failure artifacts, ordered release jobs, Hex-mode smoke validation, and warning/error annotation sweeps.
- Closed the audit-discovered host-flow hermeticity gap by making focused subscription/webhook/admin proof files self-isolating outside the canonical UAT wrapper.
- Hardened first-user DX with installer no-clobber reruns, conflict sidecars, setup diagnostics, host-first First Hour/troubleshooting docs, strict package-doc verification, and correct `:webhook_signing_secrets` guidance.

**Verification:**

- Milestone audit: 21/21 scoped requirements, 4/4 phases, 21/21 integrations, 6/6 flows.
- Status: tech debt only; no requirement, integration, or flow blockers.
- Audit archive: [`milestones/v1.1-MILESTONE-AUDIT.md`](milestones/v1.1-MILESTONE-AUDIT.md)

**Deferred / carry-forward:**

- Adoption assets, quality hardening, and expansion discovery remain candidate next-milestone themes.
- Known debt at close: requirements traceability drift in the archived source, Phase 11.1 validation metadata cleanup, and legacy raw browser smoke retirement.

**Archives:**

- Roadmap archive: [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md)
- Requirements archive: [`milestones/v1.1-REQUIREMENTS.md`](milestones/v1.1-REQUIREMENTS.md)
- Audit archive: [`milestones/v1.1-MILESTONE-AUDIT.md`](milestones/v1.1-MILESTONE-AUDIT.md)

---

## v1.0 Initial Release (Shipped: 2026-04-16)

**Status:** shipped  
**Public package versions:** `accrue` 0.1.2 and `accrue_admin` 0.1.2  
**Phases completed:** 9 phases, 69 plans, 117 tasks  
**Git range:** `3feb44f` through `e93efd0`

### Key Accomplishments

- Built the core Accrue billing domain: money safety, processor abstraction, Fake processor, polymorphic customers, subscriptions, invoices, charges, refunds, coupons, payment methods, checkout, portal, and Stripe Connect support.
- Shipped hardened webhook infrastructure with scoped raw-body capture, signature verification, transactional ingest, Oban dispatch, DLQ/replay tooling, out-of-order reconciliation, and event-ledger history.
- Added customer communication surfaces: transactional email catalogue, shared HEEx rendering, PDF adapters, branded invoice layouts, storage abstraction, and test assertion helpers.
- Delivered `accrue_admin` as a companion Phoenix LiveView package with dashboard, list/detail pages, destructive-action step-up, webhook inspector, replay controls, Connect administration, and dev-only Fake tools.
- Built installer and host-app DX: `mix accrue.install`, route/auth/test snippets, public `Accrue.Test` helpers, OpenTelemetry spans, and Fake-first testing documentation.
- Set up public OSS release infrastructure: CI matrix with warnings-as-errors, Credo, Dialyzer, docs, Hex audit, Release Please, Hex publishing, changelogs, ExDoc/HexDocs, MIT license, contributing, conduct, and security policies.

### Verification

- Phase 09 verification passed 12/12 must-have checks.
- Release Please PR #3 published `accrue` 0.1.2.
- Release Please PR #4 published `accrue_admin` 0.1.2.
- Main CI, Browser UAT, and Release Please completed successfully after both release merges.
- GitHub annotation sweeps found no warnings or errors, only the expected Browser UAT notice.
- HexDocs pages were checked after the docs hotfix and show `~> 0.1.2` snippets with internal guide links.

### Archives

- Roadmap archive: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md)
- Requirements archive: [`milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md)
- Phase execution history: [`milestones/v1.0-phases/`](milestones/v1.0-phases/)

### Deferred Items

- No open GSD artifacts were reported by the pre-close audit.
- No standalone `.planning/v1.0-MILESTONE-AUDIT.md` existed at close. Phase-level verification, validation, release CI, Hex publishing, and post-release HexDocs checks were used as closure evidence.

---
