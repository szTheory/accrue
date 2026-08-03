# Phase 218 Apple API Coverage

Scope: Apple App Store Server API and App Store Server Notifications V2 capabilities that can verify, link, quarantine, reconcile, or honestly present Apple subscription evidence for AAPL-01 through AAPL-05.

| capability | decision | reason |
|---|---|---|
| Stable entitlement-account UUID supplied as StoreKit `appAccountToken` | INTEGRATE | It is the only Apple ownership corroboration accepted for a new lineage per D-02/D-03. |
| Authenticated purchase-completion observation | INTEGRATE | Purchase completion must verify and bind eligible lineage before projection. |
| Authenticated restore observation | INTEGRATE | Restore uses the same verified bind-once rule and cannot infer ownership from the restoring session. |
| Set App Account Token | INTEGRATE | Available only after local authorization and local bind of a currently unbound lineage; it is follow-up provider repair, never ownership authority. |
| App Store Server Notifications V2 `signedPayload` | INTEGRATE | A verified notification is durably recorded as an idempotent reconciliation wakeup. |
| Nested `signedTransactionInfo` verification | INTEGRATE | Every nested transaction JWS must independently satisfy the ES256, x5c, certificate, app, and environment policy. |
| Nested `signedRenewalInfo` verification | INTEGRATE | Renewal/grace/retry facts cannot enter normalization without independent verification. |
| Notification acknowledgement and Apple retry semantics | INTEGRATE | Success is returned only after a bounded verified/no-op/quarantine result is durable; transient failure remains unsuccessful. |
| Notification request-size and rate admission | INTEGRATE | Internet input must not create unbounded quarantine storage or verification work. |
| Notification delivery deduplication | INTEGRATE | Provider event identity plus evidence digest makes repeated delivery a successful no-op. |
| Get All Subscription Statuses | INTEGRATE | This is the present-state authority for auto-renewable subscriptions per D-10. |
| Get Transaction History V2 in ascending order | INTEGRATE | History repairs missed evidence and supplies renewal, transition, refund, and revocation facts. |
| Transaction History V2 revision pagination | INTEGRATE | Filters are fingerprinted and the completed cursor advances only after `hasMore: false`. |
| Repeated/updated transactions during history scans | INTEGRATE | Each verified transaction is upserted idempotently and ordered independently of delivery. |
| Get Notification History | INTEGRATE | It diagnoses delivery gaps and seeds bounded status/history recovery, but cannot grant or retract directly. |
| Refund and revocation evidence carried by verified transaction history | INTEGRATE | Source-local retraction must converge without a separate Apple-shaped subscription reducer. |
| Production App Store Server API JWT authentication | INTEGRATE | The private client adapter needs host-owned issuer/key configuration isolated from offline-proof keys. |
| Sandbox/production environment separation | INTEGRATE | Every lineage, intake, checkpoint, verifier claim, and provider identity is environment-qualified. |
| Bundle ID and production `appAppleId` validation | INTEGRATE | Wrong-app evidence must remain non-granting; sandbox does not invent a production app identity. |
| Apple x5c trust-root and certificate policy | INTEGRATE | Outer and nested JWS require ordered-chain, time, purpose, signature, and critical-header validation. |
| Provider 429 `Retry-After` and 5xx handling | INTEGRATE | Durable retry state and bounded backoff must survive Oban exhaustion and process restarts. |
| Apple subscription management URL/guidance | INTEGRATE | Hosts must present the exact externally-managed guidance already defined by Source.Registry. |
| App Store Server API v1 transaction history | OPT-OUT | Deprecated surface; Phase 218 uses Transaction History V2 only. |
| App Store Server Notifications V1 | OPT-OUT | Legacy unsigned/older delivery semantics are outside the locked V2-only contract. |
| Notification History as entitlement truth | OPT-OUT | It is delivery diagnostics only; status/history reconciliation owns current truth. |
| Client-decoded or unverified StoreKit claims | OPT-OUT | Decoding does not establish provenance, app identity, or account ownership. |
| Automatic ownership transfer, merge, or reassignment | OPT-OUT | Locked deferred policy; bound conflicts remain privacy-safe quarantine. |
| Family Sharing ownership semantics | OPT-OUT | Explicitly deferred to POL-01 by locked context. |
| Introductory, promotional, win-back, and offer-eligibility authoring | OPT-OUT | Explicitly deferred to POL-02 by locked context. |
| Promotional-offer signature authoring | OPT-OUT | Offer authoring is deferred and does not affect verified entitlement observation. |
| Extend a subscription renewal date (single or mass) | OPT-OUT | Provider lifecycle control is outside observational repair and Apple remains externally managed. |
| Send Consumption Information | OPT-OUT | App Store refund adjudication input is not entitlement authority and needs separate product/privacy policy. |
| Look Up Order ID | OPT-OUT | Order lookup does not prove account ownership or improve the locked lineage/status/history contract. |
| Get Refund History as a second reducer | OPT-OUT | Verified transaction history already supplies source-local refund/revocation facts; a second reducer would create competing authority. |
| Request a Test Notification / notification test status | OPT-OUT | Provider-fidelity operations are Phase 220/runbook material; deterministic fixtures remain the merge gate here. |
| Crosswake/StoreKit runtime implementation | OPT-OUT | The host owns mobile runtime; Phase 219 owns offline runtime coupling and Phase 220 owns adopter proof. |

## Prohibition-probe breadcrumb

Generic injection, certificate-validation, secret-handling, and denial-of-service concerns are canonical security items and are handled by each plan's ASVS-L1 threat model plus later `$gsd-secure-phase`; they are not duplicated as bespoke prohibitions. The bespoke ownership-disclosure, raw-evidence-retention, and provider-control-misrepresentation prohibitions are carried descriptor-less and flagged under `must_haves.prohibitions` in Plans 218-01, 218-03, 218-04, and 218-06.
