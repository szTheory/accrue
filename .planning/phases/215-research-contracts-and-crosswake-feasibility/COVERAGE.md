# Phase 215 External API Coverage

No external API integration: Phase 215 validates checked-in feasibility evidence only; Crosswake source and documented bridge APIs remain unavailable, so runtime coupling stays blocked.

The deferred capability surface is explicit: authenticated host transport; StoreKit 2 purchase with `appAccountToken`; transaction updates; current-entitlement and user-initiated restore handling; Secure Enclave P-256 key creation and nonce proof; `ThisDeviceOnly` Keychain state; durable local state; monotonic `iat`/revision/freshness high-water checks; atomic verified allow/deny replacement; foreground/background lifecycle; network-path coalescing; reconnect recovery; and physical-device evidence. Each row is INTEGRATE by default once authoritative Crosswake source is supplied; until then each unproven row is recorded as `feasibility_blocked`, not silently opted out.
