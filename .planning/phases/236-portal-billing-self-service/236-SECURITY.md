---
phase: "236"
slug: "portal-billing-self-service"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-08"
---

# Phase 236 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Host identity to Portal context | The authenticated actor and freshly resolved billable determine access; display fields are presentation-only. | Actor, selected billable, owner identity, Customer ID |
| Portal reads and actions to billing data | Untrusted route IDs, POST bodies, and LiveView events are re-scoped and authorized against the current Customer and exact target. | Invoice, payment method, subscription identifiers; action; payment nonce |
| Hosted Fields to Portal | Provider-hosted fields retain card number and security code; application code receives only a single-use nonce. | Nonce and pending/result state |
| Checkout return to host | Return paths, pins, and query parameters are untrusted; only validated destinations and server-observed outcomes are used. | Signed context pin, return URL, query status |
| Host presentation data to browser | Host names and theme tokens affect presentation and do not grant authorization. | Display name, theme values, route feedback |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-236-01 | Elevation of privilege | Invoice read | high | mitigate | Invoice queries scope by resolved Customer; two-owner isolation is covered by LiveView and served-browser tests. | closed |
| T-236-02 | Information disclosure | Invoice URL | high | mitigate | Hosted invoice links are rendered from Customer-scoped authorized rows; served tests assert owner isolation. | closed |
| T-236-03 | Elevation of privilege | Card POST | high | mitigate | The controller resolves the current context and authorizes the exact payment-method action; denial cases run in the package suite. | closed |
| T-236-04 | Information disclosure | Hosted Fields | high | mitigate | Card fields remain provider-hosted; the application submits only the nonce. Served tests cover initialization, validation, failure cleanup, and teardown. | closed |
| T-236-05 | Tampering | Duplicate card submit | medium | mitigate | Pending state disables repeat submission and consumed nonce state is cleared; package and served-browser tests pass. | closed |
| T-236-06 | Elevation of privilege | Subscription event | high | mitigate | Subscription actions re-resolve owner context and authorize the named target/action at event time; action and denial tests pass. | closed |
| T-236-07 | Repudiation | Mutation feedback | medium | mitigate | Provider mutations execute with actor attribution and feedback reflects observed outcomes; package outcome tests pass. | closed |
| T-236-08 | Spoofing | Return URL | high | mitigate | Checkout accepts validated local or approved HTTPS destinations and uses a safe local fallback; destination matrix tests pass. | closed |
| T-236-09 | Tampering | Checkout query and pin | high | mitigate | Query status does not establish success; the signed context and checkout operation are freshly validated and authorized by the server. | closed |
| T-236-10 | Repudiation | Uncertain result | medium | mitigate | Uncertain provider outcomes remain distinct and are not automatically replayed; package assertions pass. | closed |
| T-236-11 | Information disclosure | Shared shell | high | mitigate | Two-owner served-browser assertions verify billed identity and scoped content across the Portal routes. | closed |
| T-236-12 | Spoofing | Visual result state | medium | mitigate | Served-browser and LiveView assertions verify announced feedback against actual result branches. | closed |
| T-236-SC | Tampering | Package installs | high | mitigate | Phase task commits changed no package manifests or lockfiles and added no install task; the existing legitimacy gate remains in force for future install scope. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-08 | 13 | 13 | 0 | GSD phase closeout |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-08
