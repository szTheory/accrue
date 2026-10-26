---
phase: "237"
slug: "admin-invoices-payments-recovery"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-09"
---

# Phase 237 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Admin browser to LiveView routes | Browser-provided organization, invoice, charge, window, and return-path values are untrusted until server-side actor authorization and scope resolution succeed. | Organization identifiers, record IDs, filters, action intent, return URLs |
| LiveView and query layer to persisted billing data | Invoice, charge, customer, subscription, and recovery rows must be selected and refreshed within the authorized owner scope. | Owner identity, lifecycle status, integer amounts, currency, event history |
| Admin action flow to processor adapter | Reviewed payment/refund facts cross a dispatch boundary and outcomes return with provider-specific certainty. | Target ID, amount, currency, idempotency key, processor result |
| Seeded host browser lane to test evidence | CI fixtures and screenshots prove deterministic application behavior only; they are not evidence of live-provider settlement. | Seeded organization records, routes, rendered UI, screenshot manifest |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-237-01 | Information Disclosure | invoice list query | high | mitigate | Join Customer and apply owner scope before selecting invoice rows; foreign-owner query tests pass. | closed |
| T-237-02 | Tampering | invoice state display | medium | mitigate | Derive overdue from stored status/date without mutating persisted state. | closed |
| T-237-03 | Elevation of Privilege | invoice action authorization | high | mitigate | Capture and recheck the actor and owner scope before final dispatch and after step-up. | closed |
| T-237-04 | Tampering | refund amount and operation | high | mitigate | Recompute refundable balance/currency, compare exact reviewed integer facts, and preserve operation idempotency. | closed |
| T-237-05 | Repudiation | action result copy | high | mitigate | Distinguish scoped success, required action, definitive decline, and unconfirmed outcomes; never automatically replay ambiguous outcomes. | closed |
| T-237-06 | Information Disclosure | recovery scoped query and links | high | mitigate | Scope recovery aggregates/current records and validate return context before link generation. | closed |
| T-237-07 | Tampering | recovery currency aggregate | medium | mitigate | Keep unsupported currency unavailable and retain exact per-currency integer measures. | closed |
| T-237-08 | Information Disclosure | invoice list/detail | high | mitigate | Keep owner-scoped list/detail queries and generic denial/error copy; do not expose foreign rows in fallback states. | closed |
| T-237-09 | Tampering | invoice amount presentation | medium | mitigate | Use supported currency and integer minor-unit formatting, including zero and 0-/3-decimal currencies. | closed |
| T-237-10 | Elevation of Privilege | invoice action confirm | high | mitigate | Reauthorize actor/owner and reload target eligibility at dispatch and step-up continuation. | closed |
| T-237-11 | Tampering | invoice reviewed facts | high | mitigate | Compare target, action, amount, and currency immediately before Billing calls; pass the operation ID. | closed |
| T-237-12 | Repudiation | invoice result rendering | high | mitigate | Require scoped resulting-row evidence for success; leave ambiguous results unconfirmed without replay. | closed |
| T-237-13 | Elevation of Privilege | refund confirm | high | mitigate | Reauthorize actor/scope and reload the owner-scoped charge after step-up and before dispatch. | closed |
| T-237-14 | Tampering | refund amount and operation | high | mitigate | Recompute balance and reviewed facts and pass an operation ID for idempotency. | closed |
| T-237-15 | Repudiation | refund result copy | high | mitigate | Require a returned Refund and scoped charge refresh for success; preserve uncertainty otherwise. | closed |
| T-237-16 | Information Disclosure | recovery aggregate and links | high | mitigate | Apply owner scope to aggregates/current rows and validate return links. | closed |
| T-237-17 | Tampering | recovery currency buckets | medium | mitigate | Keep unknown currency unavailable and aggregate exact amounts by currency. | closed |
| T-237-18 | Repudiation | historical failure display | medium | mitigate | Label event history separately from fresh invoice/subscription status. | closed |
| T-237-19 | Information Disclosure | served Admin navigation | high | mitigate | Seed a real Beta-owned invoice; under Alpha scope the browser journey confirms list omission and generic detail denial without ID/number leakage. Seed cleanup verifies ownership and recreation. | closed |
| T-237-20 | Spoofing | browser evidence claim | medium | mitigate | Identify deterministic seeded evidence and make no live-provider settlement claim. | closed |
| T-237-SC | Tampering | package installs | high | mitigate | No dependency manifest or lockfile changed during Phase 237. | closed |

*Status: open · closed · open — below the configured high threshold (non-blocking)*
*Only open threats at or above `workflow.security_block_on` count toward `threats_open`.*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-09 | 21 | 21 | 0 | gsd-security-auditor (ASVS L1) |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-09
