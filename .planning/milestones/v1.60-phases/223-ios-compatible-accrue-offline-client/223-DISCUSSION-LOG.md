# Phase 223: iOS-compatible Accrue offline client - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-05
**Phase:** 223-iOS-compatible Accrue offline client
**Areas discussed:** Host-facing API, package boundary, storage contract, verification proof

---

## Host-Facing API

| Option | Description | Selected |
|--------|-------------|----------|
| Focused primitives | Expose verifier and cache building blocks only. | |
| Higher-level workflow facade | Own purchase, restore, and lifecycle workflow. | |
| Narrow hybrid facade | One safe offline-client integration path over internal verified cache primitives; host owns StoreKit, auth, and UI. | ✓ |

**User's choice:** Locked the research-backed narrow hybrid facade.
**Notes:** It returns immutable domain state and accepts only verified server proofs for cache replacement. It must not become a generic mobile commerce SDK.

---

## Package Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Ship the tracer unchanged | Reuse the existing tracer as the public package. | |
| Extract reusable package | Create a portable client package and retain the tracer as a path-dependent consumer. | ✓ |
| Multiple published packages | Split verifier, cache, Apple helpers, and bridge into independently versioned packages. | |

**User's choice:** Locked the extracted reusable package direction.
**Notes:** Keep canonical vectors, test keys, repository paths, process harnesses, and feasibility reporting out of the installed runtime API.

---

## Storage Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Library owns all secure storage | Package chooses the container, Keychain, device key, and lifecycle behavior. | |
| Host owns all persistence | Package exposes only raw verification primitives. | |
| Verified library core with host resources | Package enforces verified atomic replacement; host supplies secure boundary and runtime resources. | ✓ |

**User's choice:** Locked the verified library core with host-owned resources.
**Notes:** The default authenticated file cache remains; the host owns container URL, cache key, Keychain/Secure Enclave integration, lifecycle, authentication, and content policy.

---

## Verification Proof

| Option | Description | Selected |
|--------|-------------|----------|
| Swift vectors/tests only | Deterministic parity and process tests without an iOS build lane. | |
| Vectors/tests plus iOS compile | Merge-block vectors, cache tests, and generic iOS SDK compilation; retain runtime gate separately. | ✓ |
| Full device/StoreKit integration | Require simulator/device runtime proof in this phase. | |

**User's choice:** Locked vectors/tests plus a generic iOS compilation lane.
**Notes:** SwiftPM/vector success cannot promote Crosswake/device feasibility; physical-device proof remains separately authorized.

---

## the agent's Discretion

- Exact Swift module/type names, package layout, compatible crypto dependency implementation, Keychain helper shape, CI job names, and documentation organization within the locked boundary.

## Deferred Ideas

- Crosswake bridge, StoreKit, learner UI, simulator/StoreKit evidence, and physical-device runtime evidence remain outside Phase 223.
