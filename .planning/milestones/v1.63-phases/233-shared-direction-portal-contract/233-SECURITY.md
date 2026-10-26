---
phase: "233"
slug: "shared-direction-portal-contract"
status: verified
threats_open: 0
threats_total: 16
asvs_level: 1
created: "2026-10-07"
---

# Phase 233 — Security

The configured L1 audit verifies the 16 unique threats authored in the seven plans. All have matching implemented mitigations and executable evidence; no accepted-risk waiver is used. The shared package-install threat is counted once. The secure-phase L1 short-circuit applies after all threats classify closed.

## Trust Boundaries

| Boundary | Data and control |
|---|---|
| Host authentication / selection to Portal | Authenticated person, host billable locator and current membership |
| Browser flow to server mutation | Signed short-lived locator, server-loaded target, fresh named permission |
| Server to payment processor | Authorized token issuance and operation with human audit attribution |
| Host branding / assets to UI evidence | Semantic roles, current served bytes, synthetic screenshot data |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / evidence | Status |
|---|---|---|---|---|---|---|
| T-233-01 | Spoofing | CustomerSession | high | mitigate | CustomerSession.resolve/2 and Context.resolve/4 authorize before exact owner/processor lookup and provisioning; context_contract_test covers missing/invalid selection and zero provisioning. | closed |
| T-233-02 | Information disclosure | blocked page | medium | mitigate | BlockedLive generic copy and local recovery link; AuthHook.ensure_user and router blocked session do not require/create a Customer; revoked browser case reaches blocked state. | closed |
| T-233-SC | Tampering | package installs | high | mitigate | No new dependency or lockfile change. Existing pinned Tailwind3.4.17/esbuild0.25.3 tooling approved by user; temporary npm cache fixed filesystem permissions. | closed |
| T-233-03 | Tampering | signed flow pin | high | mitigate | Context.verify_pin/2 verifies Phoenix.Token signature and 20-minute age; CustomerSession.resolve_pin/3 re-resolves policy and matches owner type/id, processor and Customer; context_post_test exercises forgery/expiry/switching. | closed |
| T-233-04 | Elevation of privilege | payment mount and controller | high | mitigate | PaymentMethodController named-action authorization and server-scoped target lookup; AddPaymentMethodLive create grant precedes Braintree token; context_post_test verifies zero token/write with eligible controls. | closed |
| T-233-06 | Elevation of privilege | protected LiveView events | high | mitigate | Authorize reloads pin and Customer-scoped subscription before named action; context_live_test covers revoked/foreign events and authorized human actor. | closed |
| T-233-07 | Information disclosure | protected navigation | high | mitigate | CustomerSession/AuthHook and invoice/subscription reads scope data and reauthorize; context_live_test reconnect/foreign controls plus host revoked-pin browser proof. | closed |
| T-233-09 | Information disclosure | screenshots | medium | mitigate | All five refreshed capture PNGs visually inspected by root after final rerun; deterministic synthetic fixture content, no credential or nonce text. 233-BASELINE records provenance. | closed |
| T-233-10 | Tampering | asset evidence | low | mitigate | Baseline browser asserts served hashed asset bytes equal current source; initial and final source SHAs/digests recorded separately in 233-BASELINE. | closed |
| T-233-11 | Elevation of privilege | host adapter | high | mitigate | Host PortalContextAdapter and Billing.authorize_portal_action reload membership and target; real membership-only revocation and non-Admin billing-manager browser scenarios pass. | closed |
| T-233-12 | Repudiation | actor attribution | medium | mitigate | Custom account mutation through mounted Portal is visible as a created card and persisted Admin event with User actor; package integration tests assert human actor ID. | closed |
| T-233-13 | Information disclosure | state styling | low | mitigate | Semantic browser assertions check light/dark contrast, focus and textual status cues on real existing consumers. | closed |
| T-233-14 | Tampering | asset recompilation | low | mitigate | Semantic/baseline browser tests compare served hashes and exact CSS source bytes after asset build. | closed |
| T-233-05 | Repudiation | checkout result | medium | mitigate | Checkout controller/LiveView preserve LocalSession operation_id and use Accrue.Actor.with_actor; checkout_context_test asserts provider-accepted result and human actor. | closed |
| T-233-08 | Tampering | Hosted Fields lifecycle | medium | mitigate | Hosted Fields hook clears nonce and tears down fields on invalidation/destruction; both checkout transports re-resolve pin; checkout_context_test verifies revoked/replayed requests make no additional provider call. | closed |
| T-233-15 | Elevation of privilege | checkout client token | high | mitigate | CheckoutLive checks checkout_complete on pinned LocalSession before client_token_for; checkout_context_test asserts zero token on denial with eligible positive control. | closed |

## Accepted Risks Log

No accepted risks.

## Audit Trail

| Date | Threats total | Closed | Open | Depth |
|---|---|---|---|---|
| 2026-10-07 | 16 | 16 | 0 | L1 source/control mapping plus committed deterministic execution evidence |

## Sign-Off

- [x] Every planned threat has a disposition and verified mitigation.
- [x] No blocking or below-threshold threat remains open.
- [x] No provider-live fidelity claim; deterministic processor controls are the required evidence.
- [x] `status: verified`; `threats_open: 0`.
