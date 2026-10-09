---
phase: "235"
slug: "customer-plan-selection-checkout"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-08"
---

# Phase 235 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser to Hosted Fields and checkout transport | Browser input and SDK callbacks are untrusted; only the one-time provider nonce and signed context pin cross the transport. | Card details stay in provider-hosted fields; nonce, selected offer, and context pin cross the form boundary. |
| Host session to checkout | Sign-in return and checkout session use persisted host-selected Customer, billable, processor, offer, and trusted billing terms. | Authenticated actor, selected offer, processor, and exact billing terms. |
| POST/LiveView to billing provider | Both server transports reload and authorize the persisted checkout before a single claimed provider attempt. | Revalidated Customer/offer, one operation identity, and provider token. |
| Hosted provider return to local billing projection | Return URLs navigate only; fetched, matching, paid processor evidence is required before local completion. | Provider session identifier, authoritative paid status, and local subscription projection. |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-235-01 | Tampering | Hosted Fields submit | high | mitigate | Browser fixture proves only the official Hosted Fields nonce crosses the existing form; denied context has no payment form (`examples/accrue_host/e2e/phase233-braintree-checkout.spec.js`). | closed |
| T-235-02 | Repudiation | Repeated browser submit | high | mitigate | Browser duplicate/interrupted-transport tests prevent nonce replay; `LocalSession` atomically claims a server operation (`phase233-braintree-checkout.spec.js`, `accrue/test/accrue/checkout/local_session_test.exs`). | closed |
| T-235-03 | Spoofing | Sign-in/return | high | mitigate | Selected offer and host actor/billable context persist server-side, with fresh authorization when checkout resumes (`examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs`). | closed |
| T-235-04 | Tampering | Checkout terms | high | mitigate | Portal rejects incomplete or mismatched trusted amount, currency, interval, and line items before enabling payment (`accrue_portal/test/accrue_portal/live/checkout_live_test.exs`). | closed |
| T-235-05 | Tampering | POST/LiveView target | high | mitigate | Both transports reload and reauthorize the exact Customer, processor, offer, and amount before submission (`accrue_portal/test/accrue_portal/checkout_context_test.exs`, `checkout_live_test.exs`). | closed |
| T-235-06 | Repudiation | Concurrent payment | high | mitigate | Database-safe session claim permits one provider attempt; boundary and parallel-claim tests assert the rule (`accrue/test/accrue/checkout/local_session_test.exs`). | closed |
| T-235-07 | Repudiation | Provider/local persistence split | high | mitigate | Accepted-but-unconfirmed operations stay uncertain and non-replayable across POST and LiveView tests (`checkout_context_test.exs`, `checkout_live_test.exs`). | closed |
| T-235-08 | Spoofing | Hosted return | high | mitigate | Return handling fetches and matches the processor session and requires complete paid evidence; URL parameters alone cannot mark paid (`accrue/test/accrue/checkout_test.exs`, `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs`). | closed |
| T-235-09 | Repudiation | Concurrent hosted return | medium | mitigate | Same-session reconciliation is serialized and tested for idempotent singular local projection (`accrue/test/accrue/checkout_test.exs`). | closed |
| T-235-10 | Information disclosure | Provider error/status copy | medium | mitigate | LiveView tests assert card fields never leave Hosted Fields; the browser test asserts the tokenized nonce is not rendered in the page (`accrue_portal/test/accrue_portal/live/checkout_live_test.exs`, `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js`). | closed |
| T-235-11 | Tampering | Trusted zero-priced POST eligibility | high | mitigate | Actual controller POST completes a persisted explicitly zero-priced session once; missing, negative, mismatched, forged, and replayed terms do not cause another provider operation (`accrue_portal/test/accrue_portal/checkout_context_test.exs`). | closed |
| T-235-12 | Spoofing | Expired recovery destination | medium | mitigate | Expired checkout renders only the validated recovery URL; hostile cancel URL falls back to `/billing`, with LiveView and served-browser no-payment assertions (`accrue_portal/test/accrue_portal/live/checkout_live_test.exs`, `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js`). | closed |
| T-235-13 | Spoofing | Braintree host return | high | mitigate | Host return reloads the currently authorized organization and exact processor Customer before scoped LocalSession lookup; completed, foreign, and permission-loss cases are covered (`examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs`). | closed |
| T-235-14 | Tampering | Braintree return locator and state | high | mitigate | Plan/selection URL values are locators only; forged and pending values cannot show completion, while Stripe still requires fetched paid-session evidence (`examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs`, `subscription_live_test.exs`). | closed |
| T-235-15 | Repudiation | Repeated Braintree return | medium | mitigate | Completed return can be revisited without changing the LocalSession count or initiating another payment operation (`examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs`, `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js`). | closed |
| T-235-SC | Tampering | Package changes (235-01) | high | mitigate | No package install occurred; no dependency manifest or lockfile is present in the Phase 235 commit file set. | closed |
| T-235-SC | Tampering | Package changes (235-02) | high | mitigate | No package install occurred; no dependency manifest or lockfile is present in the Phase 235 commit file set. | closed |
| T-235-SC | Tampering | Package changes (235-03) | high | mitigate | No package install occurred; no dependency manifest or lockfile is present in the Phase 235 commit file set. | closed |
| T-235-SC | Tampering | Package changes (235-04) | high | mitigate | No package install occurred; no dependency manifest or lockfile is present in the Phase 235 commit file set. | closed |
| T-235-SC | Tampering | Package changes (235-05) | high | mitigate | No package install occurred; no dependency manifest or lockfile changed for this plan. | closed |
| T-235-SC | Tampering | Package changes (235-06) | high | mitigate | No package install occurred; no dependency manifest or lockfile changed for this plan. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-08 | 21 | 21 | 0 | GSD execute-phase orchestrator, ASVS L1 source/test check |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-08

## Security Audit 2026-10-08

| Metric | Count |
|---|---|
| Threats found | 21 |
| Closed | 21 |
| Open | 0 |
