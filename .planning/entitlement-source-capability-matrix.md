# Entitlement-Source Capability Matrix

**Status:** v1.59 design contract; no runtime support is claimed until the owning phase verifies it.  
**Separate SSOT:** `.planning/processor-support-matrix.md` remains authoritative for the shipped Fake/Stripe/Braintree gateway-control facade. This matrix describes how entitlement evidence is observed, reconciled, managed, and leased across rails.

## v1.59 Target Matrix

| Capability | Stripe | Apple | Host/Fake proof |
|---|---|---|---|
| Canonical account grant source | Target via existing subscription/webhook projection | Target via verified StoreKit/App Store evidence | Merge-blocking deterministic rail fixtures |
| Create subscription | Accrue-controlled through `lattice_stripe` | Apple-controlled StoreKit purchase | Fake controllable gateway only |
| Cancel/resume/swap/prorate | Accrue-controlled where existing processor capability says supported | Externally managed; return management guidance, never fake mutation | Capability/unsupported-result conformance |
| Webhook/server notification verification | Existing Stripe path, made resource/rail scoped | App Store Server Notifications V2 signed verification | Signed/invalid/duplicate/out-of-order fixtures |
| Restore/link account | Existing authenticated host customer linkage | Authenticated `appAccountToken` plus verified signed transaction repair | No-email-linking negative fixtures |
| Status/history repair | Stripe fetch/reconciliation through `lattice_stripe` | Get All Subscription Statuses / transaction history | Deterministic missed-notification repair |
| Grace/billing retry | Project provider bounds into account grant | Project Apple grace/retry bounds; retain provenance | No double-grace conformance |
| Refund/revocation/clawback | Retract Stripe source only | Retract Apple transaction lineage only | Cross-rail survivor test |
| Dunning/retry ownership | Accrue-controlled only where processor supports it | Never; Apple owns billing retry | Merge-blocking exclusion test |
| Family Sharing | Not applicable | Deferred/disabled in v1; ownership metadata preserved | Explicit unsupported policy |
| Intro/promotional offers | Existing gateway/provider truth retained | Metadata only in v1; authoring/eligibility deferred | Round-trip provenance fixture |
| Offline lease input | Canonical effective account snapshot | Canonical effective account snapshot | Same account revision and claim shape |
| Offline verifier/storage | Accrue owns protocol/fixtures, not client storage | Same | Host/Crosswake owns secure storage + verifier |
| Merge-blocking proof | Fake/fixture backed | Fake signed provider fixtures; no live App Store dependency | Required |
| Provider-backed fidelity | Stripe advisory/protected lane per existing policy | Sandbox/protected advisory lane later | Never the primary CI proof |

## Aggregation Rules

- A live grant from any verified rail grants the logical plan.
- Revocation affects only the identified rail/environment/lineage source.
- Multiple sources for one logical plan are deduplicated; feature membership is set-union and quantities use the maximum effective quantity.
- External identifiers are never globally unique; every lookup/upsert includes rail and environment.
- Account-link failure is fail-closed and quarantined. Email matching is prohibited.
- The Stripe-only advisory `EntitlementSummary` remains outside this matrix's canonical grant path.

## Compatibility Rule

Existing `config :accrue, processor: ...` and bare plan `price_ids` mean the configured default gateway rail. New multi-rail hosts opt into `rails`, `default_rail`, and rail-qualified products. Existing entitlement-gate APIs keep their current return shapes.

## Deferred Rails and Policies

Google Play is SEED-007. Family Sharing policy, offer authoring, cross-rail migration/proration, arbitrary TTL/device-risk matrices, and advanced attestation are not v1.59 capabilities.

