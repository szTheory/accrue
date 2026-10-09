---
phase: "234"
slug: "admin-customers-subscriptions"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-07"
---

# Phase 234 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Admin authentication and owner scope | Host identity and active owner scope gate Admin reads and actions. | Actor ID, owner IDs, customer and subscription records |
| Browser to mounted Admin | LiveView events and route parameters are untrusted and revalidated against the current scope. | Record IDs, return context, action payloads |
| Admin to billing/provider operations | Reviewed actions use current scoped targets and explicit operation identity before dispatch. | Subscription IDs, operation IDs, processor result state |
| Built assets to served browser | Browser evidence is tied to current source and served asset bytes. | Static assets and capture provenance |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-234-01 | Spoofing | Return URL and owner | high | mitigate | Allowlisted mount-local return paths are rebuilt through the current `OwnerScope`; forged and absolute paths are covered by scoped-path tests. | closed |
| T-234-02 | Information disclosure | Subscription detail | high | mitigate | Detail reads and denial behavior remain owner-scoped; focused mounted tests cover positive and foreign-scope cases. | closed |
| T-234-03 | Information disclosure | Home activity | high | mitigate | Home observations and destinations use the current owner scope; dashboard tests include scope controls. | closed |
| T-234-04 | Tampering | Async search replies | medium | mitigate | Search replies are accepted only for the current query, scope, and generation; focused component tests cover stale replies. | closed |
| T-234-05 | Denial of service | Search queries | medium | mitigate | Search keeps three bounded groups, query length validation, and five-result limits without full-population counts. | closed |
| T-234-06 | Tampering | Lifecycle presentation | medium | mitigate | Core lifecycle state is separated from nullable ancillary fields and covered by list/detail cases. | closed |
| T-234-07 | Information disclosure | Detail and raw payload | high | mitigate | Detail views avoid exposing raw processor data and payment tokens; focused tests assert sensitive-value absence. | closed |
| T-234-08 | Elevation of privilege | Action event and step-up | high | mitigate | Current actor, scope, and owner-scoped target are rechecked immediately before the facade call; forged and expired challenge paths are tested. | closed |
| T-234-09 | Tampering | Action item and reviewed payload | high | mitigate | Persisted item membership and the material review fingerprint are re-resolved before dispatch. | closed |
| T-234-10 | Tampering | Duplicate confirmation | high | mitigate | A stable operation ID and server-side dispatch guard prevent duplicate operation submission. | closed |
| T-234-11 | Repudiation | Ambiguous action outcome | high | mitigate | Uncertain outcomes retain scoped evidence and do not trigger invented failures or automatic retries. | closed |
| T-234-12 | Information disclosure | Refresh and replacement | high | mitigate | Original and replacement records are loaded under the current owner scope; foreign replacement identifiers are suppressed. | closed |
| T-234-13 | Elevation of privilege | Mounted Admin denial | high | mitigate | Host browser coverage verifies denied deep links, an authorized counterpart, and billing-manager denial. | closed |
| T-234-14 | Information disclosure | Hidden or duplicate DOM | high | mitigate | Browser checks cover duplicate IDs, hidden focus, and foreign payment-data absence. | closed |
| T-234-15 | Repudiation | Stale visual evidence | medium | mitigate | Capture manifests record source hashes, served asset hashes, routes, fixtures, viewport, and theme. | closed |
| T-234-16 | Spoofing | Customer and related-record return URL | high | mitigate | Return context validates the target record and current owner scope before rebuilding a customer path. | closed |
| T-234-17 | Information disclosure | Invoice and payment detail | high | mitigate | Related-record reads preserve scoped access and generic denial; tests cover foreign identifiers and payment-token absence. | closed |
| T-234-SC | Tampering | Package supply chain | high | mitigate | No dependency changes were introduced; existing Mix/npm lockfiles and host tooling remain in use. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-07 | 18 | 18 | 0 | GSD Phase 234 execution |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-07
