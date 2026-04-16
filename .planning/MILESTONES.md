# Milestones

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
