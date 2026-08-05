# First-adopter iOS bridge contract

This guide connects the Accrue offline contract to a Crosswake-based iOS host.
It is a host integration recipe, not a claim that any Crosswake runtime has
passed physical-device proof.

## Package and ownership

The host imports the `AccrueOfflineClient` SwiftPM product from the pinned
Accrue revision. It owns networking, authenticated sessions, StoreKit 2,
keychain configuration, route policy, and user-facing states. Accrue owns
server verification, account projection, device registration, signed proof,
and reconnect authority.

Crosswake owns only the validated shell transport. It has no Accrue dependency
and does not interpret StoreKit results as entitlement authority.

## Declared host commands

Declare only the following commands for the approved study or billing routes,
with the same capability version in the route manifest and request envelope:

- `host.accrue.purchase`
- `host.accrue.restore`
- `host.accrue.entitlements.refresh`
- `host.accrue.offline.reconnect`

The host command delegate runs only after Crosswake validates protocol version,
runtime version, active route, allowlisted origin, installed packs, and the
manifest capability. A command not declared by both the host and route must
deny; it must never be forwarded through a custom WebKit handler.

## StoreKit and Accrue flow

1. The host obtains a server-issued purchase context including the account-bound
   `appAccountToken`, then starts StoreKit 2 purchase with that token.
2. Purchase results, transaction updates, current entitlements, and explicit
   restore become evidence sent to the host backend. They never grant local
   access by themselves.
3. The backend verifies Apple evidence through Accrue and projects the
   resulting rail-qualified account state. Apple lifecycle operations remain
   externally managed.
4. The host registers its device and verifies only Accrue-issued ES256 proof
   through `AccrueOfflineClient`. A stale proof may keep downloaded study and
   local progress usable; it must not unlock new value.
5. Reconnect uses Accrue's challenge/proof-of-possession flow. The client only
   replaces cache state with a verified newer allow or a signed deny.

Do not send raw JWS, receipts, proof bytes, tokens, account identifiers, or
device identifiers through Crosswake command payloads, telemetry, guides, or
support evidence.

## Evidence and release boundary

StoreKit Test, Swift vectors, browser tests, and simulator runs prove
deterministic conformance only. They do not promote runtime feasibility.
Crosswake remains `feasibility_blocked` until its separately authorized
physical-iPhone harness produces the approved redacted evidence artifact.

Before any public runtime claim, run Accrue's reference scenarios, the host
integration suite, Crosswake shell tests, and the physical-device harness. A
missing device authorization is a blocking external gate, not a condition to
paper over in docs or fixtures.
