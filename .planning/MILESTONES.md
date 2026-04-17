# Milestones

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
