# Multi-Rail and Offline Entitlements — Architecture Signal

**Recorded:** 2026-07-31  
**Status:** accepted direction for queued milestone v1.59  
**Driving scenario:** B2C Alpha, an anonymized consumer subscription adopter using a Phoenix + LiveView monolith across web and mobile, with offline-first core usage.  
**Privacy rule:** this document intentionally contains no adopter identity, application name, user data, or proprietary product detail.

## Executive Decision

Accrue will treat **account entitlement** and **payment lifecycle control** as separate concerns.

- The host asks rail-neutral questions such as `entitled?/2`, `features_for/1`, and `entitlement_quantity/2`.
- Accrue projects verified evidence from multiple rail-specific lifecycle observers into one account-scoped entitlement view.
- Management operations remain explicitly rail-aware because control is genuinely asymmetric: Stripe is controllable through Accrue; Apple is externally managed and observed.
- Offline access uses an Accrue-issued, compact, signed, device-bound, time-bounded entitlement lease. Accrue owns the protocol and server-side issuance; the host/Crosswake integration owns secure device storage and client verification.

This is a deliberate leaky abstraction. It keeps the access question simple without pretending that cancel, retry, offers, refunds, proration, Family Sharing, and account management mean the same thing on every rail.

## Current-State Assessment

Accrue is **multi-provider by deployment, not multi-rail per account in one runtime**. Provider columns and composite keys are useful groundwork, but global dispatch and unscoped reads still select one rail.

| Assumption | Where it lives | Consequence |
|---|---|---|
| One process-global processor module | `Accrue.Processor` resolves `config :accrue, :processor` and forwards the whole facade to it | Stripe and Apple cannot safely coexist or dispatch by resource rail. |
| One arbitrary customer per owner | `Accrue.Billing.customer/1` filters owner type/id with `limit: 1`; `Accrue.Billable` injects `has_one :accrue_customer` | An account with Stripe and Apple customer rows is nondeterministic. |
| One customer drives entitlement resolution | `Accrue.Entitlements.Resolver.LocalMap` repeats the unscoped owner lookup and folds subscriptions for only that customer | Cross-rail access is incomplete and depends on whichever row wins. |
| Bare product/price identifiers are global | `Accrue.Config` plan `price_ids` and reverse lookup | Identical identifiers on different rails can collide; Apple products cannot be qualified honestly. |
| Subscription state is Stripe-shaped | `Accrue.Billing.Subscription` and `SubscriptionProjection` | Apple retry, grace, revocation, ownership, offers, and original-transaction lineage are lossy if forced into this schema. |
| Lifecycle mutation uses the global adapter | `SubscriptionActions`, cancellation/resume/swap/quantity paths, `DunningSweeper` | An Apple record could be sent to a Stripe-like mutation path; Apple must never enter Accrue-owned dunning. |
| Webhook verification/reduction is provider-closed | `Webhook.Plug`, `Signature`, `Ingest`, `Event`, `DispatchWorker`, `DefaultHandler` | Verification is hard-coded, ingestion is Stripe-typed, dispatch is endpoint-based, and several reducer lookups omit processor scope. |
| Stripe advisory entitlements are generic access truth | They are not: `Accrue.Billing.EntitlementSummary` is deliberately Stripe-only and observational | Repurposing this cache would violate the shipped never-a-gate isolation contract. |

Positive foundations to retain:

- customer uniqueness already includes `(owner_type, owner_id, processor)`;
- subscription external identity and webhook idempotency are processor-scoped;
- the public entitlement gate and resolver behavior are already rail-neutral seams;
- current plan/feature union and max-quantity behavior are suitable aggregation defaults;
- `lattice_stripe` remains the Stripe transport and must not be reimplemented.

## Proposed Seam

### 1. Canonical account and evidence projection

Introduce a stable Accrue-owned account identity and rail-qualified evidence, separate from Stripe-shaped billing tables.

**`EntitlementAccount`**

- UUID primary identity, plus host `owner_type` / `owner_id`
- monotonic `revision` changed whenever effective account access changes
- the UUID is safe to use as Apple's `appAccountToken`

**`EntitlementGrant`**

- `account_id`, `rail`, `environment`
- external subscription/original-transaction lineage
- rail-qualified product identifier and logical Accrue plan
- normalized access state and effective/expiry/revocation bounds
- observed time, provider order cursor, provenance, ownership/offer metadata
- bounded raw evidence only; never unbounded receipts or notification bodies

**`EntitlementDevice`**

- account-scoped installation identifier
- device P-256 public key, registration/revocation state, last lease revision

The account snapshot is the union of live grants across all rails. Revoking one source retracts only that source. Duplicate sources mapped to the same logical plan do not double-count; feature membership is set-union and quantities use the maximum effective quantity unless a future requirement proves another rule is needed.

### 2. Rail-specific lifecycle observers

Keep `Accrue.Processor` as the controllable gateway seam. Add a smaller rail lifecycle behavior for verified observation and projection; do not require Apple to fake invoices, payment methods, checkout, cancellation, swaps, or dunning.

The honest public boundary is:

- rail-neutral: access checks and snapshots;
- resource/rail-aware: management capabilities and actions;
- explicit result for externally managed operations, with guidance/URL metadata rather than a fake cancel mutation.

Concepts remain provenance, not universal operations:

| Concept | Projection policy |
|---|---|
| Apple billing grace / billing retry | Normalize to bounded access state while retaining provider state and dates. Do not stack Accrue offline grace on top of provider grace. |
| Refund/revocation/clawback | Retract the affected source, increment account revision, issue deny tombstone on reconnect where warranted. |
| Introductory/promotional offers | Preserve as metadata in v1; authoring/eligibility APIs are later. |
| Family Sharing | Explicitly disabled/deferred for v1; ownership type remains representable. |
| Proration/cross-rail migration | No generic v1 operation; rail-specific product policy is later. |

### 3. Additive public compatibility path

Preserve existing APIs and configuration:

- `config :accrue, processor: ...` remains the default gateway rail;
- bare `price_ids` remain aliases for the default/Stripe rail;
- `customer/1` remains deterministic for the default rail;
- `Subscription` remains the gateway billing projection;
- `EntitlementSummary` remains Stripe-only observational diagnostics;
- existing entitlement gate return types do not change.

Add:

- `rails` and `default_rail` configuration;
- `customer/2`, `customers/1`, and a new multi-row association;
- rail-qualified product mapping;
- resource-aware dispatch and `capabilities/management_action` queries;
- a canonical `snapshot/1` entitlement read.

Changing `processor` from module to map, changing `customer/1` to a list, replacing the existing association, or widening the Stripe subscription enum in place would be breaking and is rejected.

## Apple v1 Observation Path

1. The authenticated host account UUID is supplied as `appAccountToken` at purchase.
2. Restore accepts a signed StoreKit transaction, verifies it server-side, and binds by the authenticated account token—not email.
3. App Store Server Notifications V2 are verified and reduced through a rail-specific handler.
4. Get All Subscription Statuses / transaction history repairs missed or out-of-order notification state.
5. Unmatched evidence enters a quarantine/retry path; it never grants access through heuristic email matching.
6. Notification and transaction identifiers are rail/environment scoped, idempotent, and monotonic.

Apple controls cancellation and subscription management. Accrue exposes that truth to the host instead of implementing a lowest-common-denominator mutation API.

## Offline Entitlement Lease

### Token contract

Use a compact **ES256 JWS** with an explicit protocol version, key id, issuer, audience, token id, account id, device key thumbprint, account revision, issued/not-before/fresh-until/hard-expiry timestamps, effective plans/features/quantities, and denial/revocation metadata when applicable.

Accrue owns canonical serialization, signing, verification fixtures, key selection, issuance, and reconnect reconciliation. The host mobile layer owns Keychain/Keystore storage, the client verifier, and UI mode selection. The server never trusts an offline token presented back as fresher billing evidence.

### Locked v1 policy

- **Fresh lease:** rolling 30 days from a successful online reconciliation.
- **Scheduled end:** shorten `fresh_until` to a known earlier cancellation/revocation/period boundary.
- **Offline degraded grace:** 72 hours after `fresh_until`, encoded in the signed hard expiry.
- **No grace stacking:** a provider billing-grace period is already part of the canonical grant bound; the 72-hour window does not add another grace window after it.
- **Hard expiry while offline:** premium mutations/actions fail closed, while the app shell and existing local user data remain accessible. The host should show a specific reconnect-required state, not erase or hide local data.
- **Reconnect:** authenticate account and device, refresh every due rail, compare account revision and device status, then atomically replace the cached lease. Revocation/refund can return a signed deny tombstone so stale positive tokens cannot be reselected.
- **Clock defense:** device verifier stores a secure high-water mark and rejects material rollback; `iat`/`nbf` skew is bounded.
- **Key rotation:** verification keys remain available for at least 33 days plus clock skew; issuance uses the active key, and emergency compromise can force online renewal/deny.

This policy accepts an honest maximum stale-access exposure of roughly one billing cycle. Shorter TTLs defeat the stated extended-offline requirement; materially longer TTLs make cancellation/refund leakage unacceptable for a ~$100/month consumer product. v1 does not expose a matrix of risk knobs—the policy is a sharp default with only key/issuer wiring owned by the host.

## Threats and Operational Footguns

- Never link Apple purchases by email, device account, product alone, or an unverified client claim.
- Namespace every external identifier by rail and environment; sandbox/production collisions are expected.
- Treat notifications as hints and signed provider state/history as repair authority; delivery is duplicate and out of order.
- Do not let Apple grants enter Stripe dunning, retry, cancel, proration, or price-mutation code.
- Do not put PII, receipt bodies, or sensitive provider payloads in the offline token or telemetry.
- Make account revision changes transactional with grant projection; otherwise a lease can be minted from split-brain state.
- Device binding limits token copying but is not DRM. A compromised device can use its own valid lease until expiry.
- Preserve the last known good lease until a newer signed lease or deny tombstone is atomically stored.
- Diagnostics must show source rail, provider state, observed time, account revision, lease horizon, and reconciliation failure without exposing raw transaction data.

## v1 Versus Later

**v1.59:** Stripe + Apple; account-scoped union; automatic authenticated linking/restore; provider-honest management capabilities; refund/revocation/grace/retry projection; compact offline lease; reconnect/tombstone/key-rotation protocol; minimal operator diagnostics; B2C Alpha proof.

**Later:** Google Play rail; Family Sharing policy; offer authoring/eligibility; cross-rail migration/proration; arbitrary TTL or device-risk policy matrices; transfer/merge tooling beyond the safe automatic path; hardware-backed attestation; richer fraud controls.

## Sources

- Apple, [Transaction.currentEntitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements)
- Apple, [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi)
- Apple, [Get All Subscription Statuses](https://developer.apple.com/documentation/AppStoreServerAPI/Get-All-Subscription-Statuses)
- Apple, [appAccountToken](https://developer.apple.com/documentation/appstoreserverapi/appaccounttoken) and [Set App Account Token](https://developer.apple.com/documentation/appstoreserverapi/set-app-account-token)
- Apple, [Responding to App Store Server Notifications](https://developer.apple.com/documentation/AppStoreServerNotifications/responding-to-app-store-server-notifications)
- Apple, [Billing Grace Period](https://developer.apple.com/help/app-store-connect/manage-subscriptions/enable-billing-grace-period-for-auto-renewable-subscriptions/)
- Apple, [Subscriptions and Family Sharing](https://developer.apple.com/app-store/subscriptions/)
- Google, [Subscription lifecycle](https://developer.android.com/google/play/billing/lifecycle) and [backend integration](https://developer.android.com/google/play/billing/backend)
- IETF, [RFC 8725: JSON Web Token Best Current Practices](https://www.rfc-editor.org/info/rfc8725/)

