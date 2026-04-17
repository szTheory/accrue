---
phase: 17
slug: milestone-closure-cleanup
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-17
updated: 2026-04-17
---

# Phase 17 - Security

Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| planning artifacts -> milestone close decision | Stale planning status can falsely imply incomplete or complete milestone work. | Phase completion and requirement traceability metadata. |
| seed script -> shared test database | Destructive cleanup crosses from fixture reset into shared host test history. | Webhook rows, Oban jobs, subscriptions, customers, and audit events in the host test DB. |
| docs -> maintainer/operator actions | Stale release or contributor wording can misroute trust checks or encourage unsafe handling of secrets/PII. | Release instructions, provider-parity guidance, contributor setup, and copied operational evidence. |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-17-01 | Tampering | `scripts/ci/accrue_host_seed_e2e.exs` | mitigate | Cleanup now scopes Oban jobs by fixture `webhook_event_id` and events by fixture `actor_id`, `caused_by_webhook_event_id`, or subscription IDs. `examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs` proves unrelated event and job rows survive rerun cleanup. | closed |
| T-17-02 | Repudiation | `.planning/PROJECT.md` | mitigate | The canonical-demo checklist line is checked in `PROJECT.md`, Phase 13 remains complete in `ROADMAP.md`, and Phase 17 verification confirms traceability metadata is cleanup-only. | closed |
| T-17-03 | Information Disclosure | `RELEASING.md`, `guides/testing-live-stripe.md`, `CONTRIBUTING.md` | mitigate | Release, provider-parity, and contributor docs preserve no-secrets/no-PII guidance; ExUnit docs tests and `scripts/ci/verify_package_docs.sh` lock required and forbidden wording. | closed |
| T-17-04 | Elevation of Privilege | docs and workflow guidance | mitigate | Docs reference only current lanes: `release-gate`, `host-integration`, and `live-stripe`; tests and shell verifier reject stale lane wording. | closed |
| T-17-05 | Denial of Service | docs verification coverage | accept | Focused docs contracts plus `verify_package_docs.sh` are accepted as sufficient for this cleanup because Phase 14 and Phase 15 own surrounding coverage. | closed |

Status: open or closed. Disposition: mitigate, accept, or transfer.

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-17-01 | T-17-05 | No broader docs-verification framework was added for this cleanup. Phase 17 changed a focused set of release/provider/contributor docs, and the existing ExUnit plus shell contracts cover the modified trust-lane and stale-wording invariants. | GSD security audit | 2026-04-17 |

Accepted risks do not resurface in future audit runs.

## Evidence

| Threat ID | Evidence |
|-----------|----------|
| T-17-01 | `scripts/ci/accrue_host_seed_e2e.exs` scopes Oban cleanup by `webhook_event_id` and event cleanup by fixture-owned identifiers. `examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs` asserts unrelated webhook, event, and Oban job rows survive rerun cleanup. |
| T-17-02 | `.planning/PROJECT.md` contains the checked canonical-demo milestone line; `.planning/ROADMAP.md` records Phase 13 complete; `.planning/REQUIREMENTS.md` and `17-VERIFICATION.md` keep Phase 17 cleanup-only. |
| T-17-03 | `RELEASING.md`, `guides/testing-live-stripe.md`, and `CONTRIBUTING.md` include no-secrets/no-PII guidance; docs tests and `verify_package_docs.sh` enforce the release guidance and stale-wording contracts. |
| T-17-04 | `RELEASING.md`, `guides/testing-live-stripe.md`, and `CONTRIBUTING.md` point to `release-gate`, `host-integration`, and `live-stripe`; tests and shell checks reject stale `Phase 9 release gate`, `primary test job`, and wrong browser-UAT path wording. |
| T-17-05 | `17-01-PLAN.md` documents the accepted coverage scope; `17-VERIFICATION.md` records focused docs tests, shell verifier, and host UAT passing after the review fix. |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-17 | 5 | 5 | 0 | gsd-security-auditor |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

Approval: verified 2026-04-17
