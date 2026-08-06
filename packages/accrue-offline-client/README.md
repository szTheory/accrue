# Accrue Offline Client

`AccrueOfflineClientCore` is a SwiftPM package for the verified offline-proof
boundary in an Accrue host. It verifies compact ES256 server proofs bound to one
issuer, audience, account subject, and device thumbprint, then stores only an
authenticated, verified replacement.

## Safe host path

Import `AccrueOfflineClientCore` and configure `OfflineEntitlementClient` with the
issuer, audience, account subject, device thumbprint, public JWKS, cache URL, and an
in-memory cache-authentication key supplied by the host. Then:

1. Call `loadCachedState(now:)` when the host starts or resumes.
2. Pass compact server-proof bytes to `applyServerProof(_:now:)`.
3. Call `reconnect(using:now:)` with a host-authenticated
   `OfflineProofReconnectTransport` when the result requests reconnection.

The transport returns compact proof bytes only. Endpoint selection, request shape,
credentials, and retry policy remain host-owned; every response passes through the
same verifier and atomic cache-admission path.

## Result states and host rendering

`OfflineEntitlementState` has exactly four states:

- `fresh` with `ok` and no next action.
- `stale_offline` with `revalidation_due` and `reconnect_required`.
- `denied` with `signed_denial` and `reconnect_required`.
- `invalid` with a bounded verification, cache, or reconnect reason and
  `reconnect_required`.

Stale continuity permits downloaded study and local progress only. It never grants
new value or expands an entitlement. The package renders no UI, but hosts should use
literal text-backed state and action guidance rather than color-only status. Example
host copy: action `Reconnect`; empty cache `No offline proof is cached.`; verification
failure `This offline proof could not be verified. Reconnect to continue.`

## Host ownership

The host owns authentication, endpoint and request construction, cache-key custody,
Keychain service/access group and Secure Enclave policy, lifecycle orchestration,
StoreKit purchase/restore, content policy, localization, accessibility, and UI. The
package does not persist the cache-authentication key, make network requests, manage
commerce, or interpret StoreKit output as entitlement authority.

## Evidence boundary

SwiftPM tests and generic iOS compilation establish deterministic client conformance
and API compatibility only. They do not prove Crosswake bridge behavior, simulator
behavior, StoreKit behavior, or physical-device runtime capability. Those claims stay
`feasibility_blocked` until separately authorized physical-device evidence is present.
