---
phase: "238"
slug: "admin-events-webhooks-remaining-billing-surfaces"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-09"
---

# Phase 238 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser selection → LiveView action | Untrusted selected IDs and repeated events request queue mutation. | Webhook event IDs and replay intent |
| Admin session → owner-scoped delivery | Step-up and current ownership/status must be authoritative when replay executes. | Actor, owner scope, webhook state |
| Route/filter → scoped evidence reads | Untrusted IDs and filters select event, delivery, Connect, and billing evidence. | Local records and exact related links |
| Provider observation → Admin view | Provider facts may be missing or stale and must retain their provenance. | Stored Stripe snapshot values |
| Browser override submit → local account | Untrusted target and value request a local policy mutation. | Connect account ID and platform fee |
| Browser-rendered Admin → operator | Copy and affordances can misstate state or imply unsupported capability. | Queue outcomes, unavailable evidence, inspection actions |
| CI configuration → acceptance claim | Local discovery alone does not establish inclusion in the required shard. | Playwright spec selection |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-238-01 | Elevation of privilege | Bulk replay handler | high | mitigate | Consume confirmation intent and require fresh StepUp; revalidate current owner and status inside the locked DLQ claim transaction. | closed |
| T-238-02 | Tampering | Selected IDs and repeated confirmation | high | mitigate | Canonicalize/deduplicate IDs, consume intent once, and atomically recheck status and owner before queueing. | closed |
| T-238-03 | Repudiation | Replay audit | medium | mitigate | Persist exact selected, eligible, attempted, queued, skipped, failed, scoped ID, and per-row outcome evidence. | closed |
| T-238-04 | Information disclosure | Event and delivery links | high | mitigate | Resolve detail and related links under the current owner scope; deny foreign records. | closed |
| T-238-05 | Elevation of privilege | Single replay callback | high | mitigate | Require fresh StepUp, reload current owner/status, and pass an owner proof into the locked DLQ claim. | closed |
| T-238-06 | Information disclosure | Coupon/code detail links | high | mitigate | Preserve exact global record IDs and coupon/code parent-child relationships while keeping route context. | closed |
| T-238-07 | Spoofing | Billing capability copy | medium | mitigate | Keep coupon and promotion-code surfaces inspection-only with no create/edit affordances. | closed |
| T-238-08 | Tampering | Fee override submit | high | mitigate | Validate value, bind fresh StepUp to the exact account, reauthorize the current owner, and save only local policy. | closed |
| T-238-09 | Information disclosure | Connect account detail | high | mitigate | Load by exact account ID under the active owner scope and deny foreign accounts. | closed |
| T-238-10 | Repudiation | Provider/local status labels | medium | mitigate | Label provider facts as the last stored Stripe snapshot and keep local override state separate. | closed |
| T-238-11 | Repudiation | Replay result UI | high | mitigate | Report queued, skipped, and failed counts and distinguish queue acceptance from processing. | closed |
| T-238-12 | Information disclosure | Scoped evidence links | high | mitigate | Carry exact IDs and active scope through related event, webhook, and Connect links; cover foreign-route denial. | closed |
| T-238-13 | Denial of service | Duplicate submission | medium | mitigate | Canonical dedupe, one-use confirmation intent, atomic replay claim, and unique active dispatch jobs prevent duplicate queueing. | closed |
| T-238-SC | Tampering | Package installs | high | mitigate | No dependency install was introduced; package manifests and lockfiles are unchanged in the Phase 238 diff. | closed |

*Threat status values: open or closed. Any open finding below the configured blocking severity is non-blocking.*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open.*  
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*  

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-09 | 14 | 14 | 0 | gsd-security-auditor (ASVS L1) |

## Audit Notes

- No `## Threat Flags` sections or unregistered flags were found in the five plan summaries.
- The shared package-install threat `T-238-SC` is recorded once across the phase plans.
- All threat dispositions are `mitigate`; no accepted-risk entry was used.

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-09

## Security Audit 2026-10-09

| Metric | Count |
|---|---|
| Threats found | 14 |
| Closed | 14 |
| Open | 0 |
