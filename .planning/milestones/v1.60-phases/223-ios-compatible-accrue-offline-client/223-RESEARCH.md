# Phase 223: iOS-compatible Accrue offline client - Research

**Researched:** 2026-08-05  
**Domain:** SwiftPM offline-proof client for iOS 16  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01–D-04:** Publish one narrow named Swift facade with immutable `Sendable` values and the locked `fresh`, `stale_offline`, `denied`, and `invalid` result contract. It accepts only compact server-proof bytes for cache mutation. StoreKit, account authentication, authenticated transport implementation, lifecycle, purchase policy, and UI stay host-owned.
- **D-05–D-09:** Extract a standalone SwiftPM package with portable `AccrueOfflineClient` core and an optional Apple-specific Keychain helper product. Keep verifier, verified admission, high-water/deny ordering, authenticated envelope, atomic replacement, and recovery together. The host supplies cache URL, cache-authentication key, Keychain policy, Secure Enclave integration, transport auth, lifecycle, and content policy. The library never persists the cache-authentication key. Default storage must candidate-write, sync, atomically replace on one volume, sync the parent directory where supported, and preserve the prior complete cache on failure. `ThisDeviceOnly` must be explicit; `AfterFirstUnlockThisDeviceOnly` is only for a host that needs post-unlock background recovery.
- **D-10–D-12:** The language-neutral canonical corpus is the only cross-language behavioral oracle. Public-package tests must block merges for ES256/profile/account/device checks, all four states, high-water/deny ordering, rotation, malformed inputs, and crash/recovery. Keep repository-relative fixtures and test keys in test support. Retain macOS/Linux process/fault tests and add generic iOS-SDK compilation at iOS 16. Compilation/vector success must never promote the separate Crosswake/device feasibility report.
- **D-13–D-14:** Follow Accrue's small Phoenix-style public-context convention: facade/domain values public; crypto internals, file format, provider payloads, and host plumbing private. No UI; output values must support literal accessible guidance without color-only state or backend mechanics.

### the agent's Discretion

Exact module/type names, function arities, package directory layout, core deployment floors consistent with validated dependencies, `swift-crypto` versus platform-compatible crypto implementation details, Keychain helper API shape, test target names, CI job names, and documentation organization may be chosen, but must preserve the locked narrow facade, verified-only replacement, host-owned resources, portable core, iOS 16 compilation evidence, canonical-vector authority, and physical-device truth boundary.

### Deferred Ideas (OUT OF SCOPE)

None — Crosswake bridge APIs, StoreKit 2 integration, purchase/restore/update behavior, host UI, simulator/StoreKit proof, and physical-device runtime evidence belong to later phases or separately authorized work.
</user_constraints>

## Project Constraints (from AGENTS.md)

None — `AGENTS.md` and `.codex/AGENTS.md` are absent. [VERIFIED: codebase filesystem]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| IOS-01 | Host imports an iOS-compatible SwiftPM client whose proof, high-water, and allow/deny replacement match canonical vectors. | Split core package from tracer; move corpus and keys into test-only support; run the corpus and iOS SDK library-build lanes. [VERIFIED: codebase Swift tracer/tests] |
| IOS-02 | Client verifies only server ES256 proof, binds registered device, and preserves stale-study-only continuity. | Make proof parsing/verification private and expose only the four-state facade result; preserve strict header, claims, device binding, and stale semantics. [VERIFIED: codebase Swift verifier; CITED: https://developer.apple.com/documentation/cryptokit/] |
| IOS-03 | Client performs authenticated reconnect and replaces cache only with verified newer allow or signed deny. | Define a narrow host transport protocol returning compact proof bytes; route every response through the same private verifier and atomic cache admission path. [VERIFIED: 223-CONTEXT.md; VERIFIED: codebase Swift verifier/cache] |
</phase_requirements>

## Summary

The existing `examples/crosswake_tracer` is a strong extraction seed, not yet a distributable client. Its `OfflineGoldenVectorVerifier` is both runtime verification and a repository-relative fixture reader; its public protocol includes StoreKit-shaped methods and caller-constructed replacement metadata. Those surfaces conflict with the Phase 223 boundary. Extract the verifier/cache foundation into a new standalone SwiftPM package, put corpus/key readers and crash harnesses in test support, and replace the current public protocol with one safe facade. [VERIFIED: examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift]

The core must remain the authority boundary: it receives compact proof bytes, strictly verifies ES256/profile/issuer/audience/account/device/temporal claims, derives the opaque verified replacement internally, then performs high-water and signed-deny ordering before an authenticated atomic file write. Cache reads verify the envelope MAC before returning a result. The host owns cache-key custody, Keychain/Secure Enclave setup, auth and reconnect transport, lifecycle, StoreKit, and presentation. [VERIFIED: 223-CONTEXT.md; VERIFIED: codebase Swift verifier/cache]

**Primary recommendation:** Create an `AccrueOfflineClient` SwiftPM package with `AccrueOfflineClientCore` and a small Apple Keychain product; retain `examples/crosswake_tracer` as a local-path conformance consumer, and make its report entirely independent of package tests and iOS compilation. [VERIFIED: 223-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Compact-proof verification and four-state derivation | Client core | API/backend | The core is the offline verifier; the server remains proof issuer. [VERIFIED: 223-CONTEXT.md] |
| High-water and signed-deny admission | Client core | Storage | Ordering must be coupled to durable verified replacement. [VERIFIED: 223-CONTEXT.md] |
| Authenticated atomic cache | Client core | Device filesystem | The core owns envelope integrity/recovery; host gives it a container URL and secret key. [VERIFIED: 223-CONTEXT.md] |
| Cache-key custody and Keychain policy | Host app | Apple helper | Secure-boundary policy/access group are host-specific. [VERIFIED: 223-CONTEXT.md] |
| Reconnect request authentication | Host app | Client core | The host supplies authenticated transport; the core validates only the returned compact proof. [VERIFIED: 223-CONTEXT.md] |
| StoreKit, content access, lifecycle, and UI | Host app | — | Explicitly out of client ownership and this phase scope. [VERIFIED: 223-CONTEXT.md] |
| Crosswake/device feasibility status | Tracer/report | External physical evidence | Package success cannot assert runtime feasibility. [VERIFIED: 223-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---|---|---|
| SwiftPM | tools version 6.0 | Standalone package/products/test targets | The existing package declares Swift tools 6.0 and iOS 16; preserve a current package manifest rather than embedding runtime code in the tracer. [VERIFIED: examples/crosswake_tracer/Package.swift] |
| Foundation | Apple platform SDK | URLs, files, JSON, dates | Existing verifier/cache uses Foundation and it is available for the declared Apple target. [VERIFIED: codebase Swift source] |
| CryptoKit | Apple platform SDK | P-256 ES256 signature verification and HMAC-SHA256 cache envelope authentication | Apple documents CryptoKit P256, HMAC, and `SymmetricKey`; P-256 raw signatures are `Data`. [CITED: https://developer.apple.com/documentation/cryptokit/] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| Security | Apple platform SDK | Keychain query/accessibility helpers | Only in an optional Apple-specific product; the core must not know service/access-group policy. [CITED: https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility] |
| Swift Testing | Swift 6 toolchain | Unit and mutation tests | Keep the existing deterministic Swift test style for core behavior. [VERIFIED: examples/crosswake_tracer/Tests/AccrueOfflineClientTests] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Platform CryptoKit | `swift-crypto` | A cross-platform package could expand future portability, but Phase 223 requires iOS and the existing dependency-free source already imports CryptoKit; do not add a third-party package unless a validated second platform requires it. [ASSUMED] |
| File-backed default store | Host-defined storage only | Host-only storage would make the required atomic/recovery invariant nonstandard and harder to prove; retain the safe default plus an internal seam only where tests need it. [VERIFIED: 223-CONTEXT.md] |

**Installation:** No third-party package installation is recommended. Add the standalone package as a pinned SwiftPM source dependency or local path consumer. [VERIFIED: 223-CONTEXT.md]

## Package Legitimacy Audit

No external package installation is recommended; the package uses Apple system frameworks (`Foundation`, `CryptoKit`, `Security`). Therefore the package-legitimacy gate is not applicable. [VERIFIED: Standard Stack]

## Architecture Patterns

### System Architecture Diagram

```text
host lifecycle/auth event
          |
          v
host-supplied ReconnectTransport ---- authenticated request ----> Accrue backend
          |                                                        |
          |                                               compact ES256 proof bytes
          v                                                        |
OfflineEntitlementClient.reconnect <------------------------------+
          |
          v
private strict verifier (ES256 + typ/kid + issuer/audience/account/device/time)
          | invalid --------------------------------> immutable .invalid result
          v
opaque VerifiedProof -> high-water + signed-deny order -> authenticated atomic file store
          |                                                  |
          v                                                  v
immutable fresh/stale_offline/denied result           prior complete cache survives failure
```

### Recommended Project Structure

```text
packages/accrue-offline-client/
├── Package.swift                         # Core + Apple-helper public products
├── Sources/
│   ├── AccrueOfflineClientCore/           # Facade, verifier, ordering, store/recovery
│   └── AccrueOfflineClientApple/          # Optional Keychain helpers only
└── Tests/
    ├── AccrueOfflineClientCoreTests/      # corpus copied/injected by test support
    └── AccrueOfflineClientProcessTests/   # macOS/Linux crash harness tests
examples/crosswake_tracer/
└── Package.swift                          # local path dependency and feasibility consumer
```

### Pattern 1: Opaque verified-admission token

**What:** Parse and verify compact proof bytes once; construct an internal `VerifiedProof` only on success; only that value reaches ordering and persistence. [VERIFIED: existing `VerifiedOfflineProof` pattern]

**When to use:** Every public mutation, including reconnect responses and direct host proof application. [VERIFIED: 223-CONTEXT.md]

**Example:**

```swift
// Recommended public boundary; names are planner discretion. [ASSUMED]
public func applyServerProof(_ compactProof: Data, now: Date = .now) -> OfflineEntitlementState {
    do {
        let verified = try verifier.verify(compactProof, now: now) // private
        try store.replace(verified) // accepts only opaque private type
        return state(for: verified, now: now)
    } catch {
        return .invalid(reason: .proofRejected, nextAction: .reconnect)
    }
}
```

### Pattern 2: Host-owned reconnect transport

**What:** Define one focused `Sendable` protocol that requests a proof and returns compact bytes; it exposes no bearer token, StoreKit, or generic commerce operations. [VERIFIED: 223-CONTEXT.md]

**Example:**

```swift
// Host supplies authentication and lifecycle; client supplies verification. [ASSUMED]
public protocol OfflineProofReconnectTransport: Sendable {
    func fetchOfflineProof() async throws -> Data
}
```

### Pattern 3: Core plus optional Apple helper

**What:** Put cryptographic verification/cache semantics in one core product and compile Keychain helpers only in an Apple product. Apple recommends conditional compilation or availability checks for platform-specific APIs. [CITED: https://developer.apple.com/documentation/xcode/running-code-on-a-specific-version/]

### Anti-Patterns to Avoid

- **Public fixture reader or test key:** Installed runtime code must not derive repository paths or load private test keys. [VERIFIED: 223-CONTEXT.md]
- **Caller-created replacement metadata:** Do not accept disposition/revision/time separately from a verified compact proof. [VERIFIED: 223-CONTEXT.md]
- **Generic client protocol with `purchase`/`restore`:** It recreates a mobile-commerce SDK and leaks later-phase StoreKit scope. [VERIFIED: 223-CONTEXT.md]
- **Separate persistence/order package:** It lets ordering and crash recovery drift apart. [VERIFIED: 223-CONTEXT.md]
- **Reaching a `proven` capability result from tests/build:** That violates the locked physical-device evidence boundary. [VERIFIED: 223-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| P-256 signature and HMAC primitives | Custom EC math or MAC implementation | CryptoKit `P256`, `HMAC<SHA256>`, `SymmetricKey` | CryptoKit provides the platform cryptographic primitives; custom implementation is unnecessary cryptographic risk. [CITED: https://developer.apple.com/documentation/cryptokit/] |
| Device key/keychain security policy | A faux encrypted preferences store | Host-configured Keychain; optional small Security helper | `ThisDeviceOnly`/accessibility is an OS policy; the host must select it intentionally. [CITED: https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility] |
| Offline authority | Reachability, StoreKit state, or cache presence | Server-issued ES256 proof validated by core | Only verified proof can authorize cache replacement under the phase contract. [VERIFIED: 223-CONTEXT.md] |
| Cross-language behavioral definition | Newly invented Swift fixtures | Canonical language-neutral corpus | One behavioral oracle prevents server/client drift. [VERIFIED: 223-CONTEXT.md] |

**Key insight:** The hard problem is not serializing a cache; it is ensuring no unverified or stale positive state can pass the verification/order/durability boundary. [VERIFIED: existing cache/verifier code]

## Common Pitfalls

### Pitfall 1: Extraction leaves test-only authority in runtime

**What goes wrong:** A published package still uses `#filePath` to find repository fixtures or exports fixture-based mutation methods. [VERIFIED: existing `OfflineGoldenVectorVerifier.fixtureData()`]

**How to avoid:** Move corpus loaders, test keys, corpus mutation helpers, and crash-harness invocation into test targets/support; public source accepts runtime configuration and compact proof bytes only. [VERIFIED: 223-CONTEXT.md]

### Pitfall 2: A “newer revision” overwrites stronger denial state

**What goes wrong:** The implementation compares only revision and lets an allow replace a same-revision signed denial, or ignores `iat`/freshness high-water on process restart. [VERIFIED: existing `ProofHighWater` and process tests]

**How to avoid:** Preserve the existing conjunction of monotonic issuance, revision, freshness, and deny precedence; reload/authenticate persisted high-water before every replacement. [VERIFIED: codebase Swift cache/verifier]

### Pitfall 3: Cache durability errors weaken integrity

**What goes wrong:** Candidate/rename/directory-sync errors are swallowed or a partial candidate becomes accepted state. [VERIFIED: existing `AtomicOfflineCache` fault tests]

**How to avoid:** Write a same-directory candidate, synchronize it, atomically replace, synchronize parent directory where supported, and return bounded retry/reconnect failure while retaining the prior complete authenticated envelope. [VERIFIED: 223-CONTEXT.md]

### Pitfall 4: iOS compile lane accidentally builds macOS-only process harnesses

**What goes wrong:** CI calls unconstrained `swift build`, which includes the executable crash harness and obscures whether the public library is iOS-compatible. [VERIFIED: existing package exports `AccrueOfflineCacheCrashHarness`]

**How to avoid:** Add a separate generic-iOS SDK job that selects the public core product/target only and passes the iPhoneOS SDK path; keep process/fault tests in macOS/Linux lanes. The local probe passed with `swift build --triple arm64-apple-ios16.0 -Xswiftc -sdk -Xswiftc "$(xcrun --sdk iphoneos --show-sdk-path)"`, although that unconstrained command also built the existing harness. [VERIFIED: local environment probe]

### Pitfall 5: Keychain accessibility becomes implicit

**What goes wrong:** The package silently chooses a migratable accessibility value or treats pre-first-unlock failure as permission to retry with weaker storage. [VERIFIED: 223-CONTEXT.md]

**How to avoid:** Require the host to select accessibility; document `AfterFirstUnlockThisDeviceOnly` only for background recovery and return a bounded action when unavailable. Apple documents that `ThisDeviceOnly` items do not migrate to another device and that After First Unlock is available only after the device has been unlocked after restart. [CITED: https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility]

## Code Examples

### iOS compilation lane

```sh
# Compile the public core product against the declared iOS 16 floor. [ASSUMED: exact product flag]
SDKROOT="$(xcrun --sdk iphoneos --show-sdk-path)"
swift build --package-path packages/accrue-offline-client \
  --triple arm64-apple-ios16.0 --product AccrueOfflineClientCore \
  -Xswiftc -sdk -Xswiftc "$SDKROOT"
```

Apple’s build documentation uses a generic iOS destination rather than hand-selected architectures/SDKs for Xcode archive work; this phase’s command is a compile-only SwiftPM analogue, not a device-runtime claim. [CITED: https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle]

### Four-state host result model

```swift
// Public values are immutable and Sendable; exact enum nesting is discretionary. [ASSUMED]
public enum OfflineEntitlementState: Sendable, Equatable {
    case fresh(OfflineEntitlement)
    case staleOffline(reason: OfflineReason, nextAction: OfflineNextAction)
    case denied(reason: OfflineReason, nextAction: OfflineNextAction)
    case invalid(reason: OfflineReason, nextAction: OfflineNextAction)
}
```

The lock permits no fifth `reconnect_required` state; stale is continuity only, never a grant. [VERIFIED: 223-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Tracer-local Swift package with public fixture/cache primitives | Standalone core facade plus optional Apple helper, tracer as consumer | Phase 223 | Extraction must remove repository/test authority from distributed runtime. [VERIFIED: 223-CONTEXT.md] |
| “Latest allow” cache thinking | Verified high-water plus signed-deny precedence | v1.59 contract | Prevents replay and equal-revision allow-over-denial rollback. [VERIFIED: codebase Swift cache/verifier] |

**Deprecated/outdated:** The current public `AccrueOfflineClient` protocol and `VerifiedEntitlementReplacement` are tracer-bound APIs; do not carry them into the distributed public package because their StoreKit-shaped methods and caller-selected metadata contradict the locked facade boundary. [VERIFIED: codebase Swift source; VERIFIED: 223-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Platform CryptoKit is sufficient for all intended core targets, so `swift-crypto` is unnecessary now. | Standard Stack | A later non-Apple platform requirement would need a validated dependency/abstraction decision. |
| A2 | `AccrueOfflineClientCore`, `OfflineEntitlementClient`, and `OfflineProofReconnectTransport` are suitable exact public names. | Architecture Patterns / Code Examples | Public SwiftPM names are costly to change after first adoption. |
| A3 | The shown `swift build --product` command is the final CI invocation after package extraction. | Code Examples | The actual package product graph may require a small CI command adjustment. |

## Resolved Questions

1. **RESOLVED — What platform support does the extracted core declare?**
   - Phase 223 publishes one `AccrueOfflineClientCore` product with an iOS 16 deployment floor and the explicit macOS floor needed by the package's macOS test lane. It does not add a Linux-specific product or make a Linux public-support promise. Core source and process/fault tests remain Linux-compatible per D-05/D-06/D-11, but that portability evidence does not expand the phase beyond iOS compatibility or establish another supported host platform. [VERIFIED: 223-CONTEXT.md D-05/D-06/D-11; VERIFIED: REQUIREMENTS.md]
2. **RESOLVED — What bounded reason/next-action enums does the public API use?**
   - `OfflineEntitlementReason` uses the canonical raw-value cases `ok`, `signed_denial`, `revalidation_due`, `clock_rollback`, `device_mismatch`, `hard_expired`, `malformed`, `superseded`, `unknown_key`, `wrong_algorithm`, `wrong_audience`, `wrong_issuer`, and `wrong_type`, plus the bounded operational failures `reconnect_failed`, `cache_write_failed`, and `cache_recovery_failed`. `OfflineNextAction` uses only `none` and `reconnect_required`. These cases are derived from the canonical corpus and locked host actions; Plan 223-02 must assert exact state/reason/action mappings, while Plan 223-03 may only exercise the three named operational failures and may not introduce another state or action. [VERIFIED: 223-CONTEXT.md D-02/D-10/D-14; VERIFIED: canonical vector contract; VERIFIED: 223-01-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Swift | Core build/tests | ✓ | Apple Swift 6.3.3 | — [VERIFIED: local environment probe] |
| Xcode/iPhoneOS SDK | generic iOS 16 compile lane | ✓ | Xcode 26.6; iPhoneOS 26.5 SDK | — [VERIFIED: local environment probe] |
| `xcrun` | resolve iPhoneOS SDK path | ✓ | 72 | — [VERIFIED: local environment probe] |
| macOS process execution | crash/restart cache tests | ✓ | local Darwin host | Linux CI is also acceptable if process tests retain POSIX compatibility. [VERIFIED: local `swift test`; ASSUMED] |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment probe]

**Missing dependencies with fallback:** None. [VERIFIED: local environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | Swift Testing (Swift 6 toolchain) [VERIFIED: tracer test imports] |
| Config file | `examples/crosswake_tracer/Package.swift`; new standalone `Package.swift` is Wave 0. [VERIFIED: codebase] |
| Quick run command | `swift test --package-path packages/accrue-offline-client` [ASSUMED: final extracted path] |
| Full suite command | `swift test --package-path packages/accrue-offline-client` plus iOS compile and existing repository contract gates. [ASSUMED] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| IOS-01 | Product imports; vectors preserve verification/order/replacement behavior | Swift unit/mutation + iOS compile | `swift test --package-path packages/accrue-offline-client`; iOS core build | ❌ Wave 0 |
| IOS-02 | ES256-only, exact bindings, all four states, stale continuity | Swift unit/mutation | `swift test --package-path packages/accrue-offline-client --filter OfflineEntitlementClientTests` | ❌ Wave 0 |
| IOS-03 | Reconnect bytes pass verifier only; verified newer allow/signed deny atomically replace cache | Swift unit + macOS/Linux process fault test | `swift test --package-path packages/accrue-offline-client --filter AtomicOfflineCacheProcessTests` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** extracted package Swift tests plus the narrow affected contract script. [ASSUMED]
- **Per wave merge:** full package tests, iOS compile lane, and existing reference-scenario contract. [VERIFIED: scripts/ci/verify_reference_scenario_contract.sh]
- **Phase gate:** Full suite green and capability report still `feasibility_blocked` absent authorized device evidence. [VERIFIED: 223-CONTEXT.md]

### Wave 0 Gaps

- [ ] New standalone package manifest and core/apple targets.
- [ ] Test-support fixture/key loader with injected/checked-in corpus path, not runtime `#filePath`.
- [ ] iOS 16 public-core compilation CI job/script.
- [ ] Tracer local-path dependency and contract proving it remains feasibility-only.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | yes | Host authenticates reconnect; core never accepts local auth as entitlement authority. [VERIFIED: 223-CONTEXT.md] |
| V3 Session Management | yes | Keep account/device transport auth host-owned and avoid token persistence in core. [VERIFIED: 223-CONTEXT.md] |
| V4 Access Control | yes | Server-issued verified proof is the only cache replacement authority; stale is non-expanding continuity. [VERIFIED: 223-CONTEXT.md] |
| V5 Input Validation | yes | Strict compact-JWS/header/claim/JWKS parsing and malformed-input rejection. [VERIFIED: codebase Swift verifier] |
| V6 Cryptography | yes | Fixed ES256 validation plus CryptoKit P-256/HMAC; no custom primitives. [CITED: https://developer.apple.com/documentation/cryptokit/] |

### Known Threat Patterns for Swift offline proof/cache

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Algorithm/header confusion or forged proof | Tampering | Require exact `alg=ES256`, `typ`, known `kid`, P-256 verification, and strict claims. [VERIFIED: codebase Swift verifier] |
| Cross-account/device proof replay | Spoofing | Bind issuer, audience, account, and device thumbprint before admission. [VERIFIED: codebase Swift verifier] |
| Stale allow overrides signed denial | Tampering | Persist and compare issuance/revision/freshness high-water; signed denial wins at same revision. [VERIFIED: codebase Swift cache/verifier] |
| Torn/modified cache | Tampering / DoS | HMAC envelope bound to cache path plus candidate/sync/atomic replacement/recovery. [VERIFIED: codebase Swift cache] |
| Cache-key migration/exposure | Information disclosure | Host owns key material; explicit `ThisDeviceOnly` Keychain policy for Apple helper. [VERIFIED: 223-CONTEXT.md; CITED: https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility] |

## Sources

### Primary (HIGH confidence)

- `223-CONTEXT.md` — locked scope, ownership, storage, evidence, and public API constraints. [VERIFIED: project planning artifact]
- `examples/crosswake_tracer/Package.swift`, source, and tests — extraction seam, current verifier/cache implementation, and 28 passing local Swift tests. [VERIFIED: codebase; VERIFIED: local `swift test`]
- `scripts/ci/verify_reference_scenario_contract.sh` — existing merge-blocking reference/tracer integration. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- [Apple CryptoKit](https://developer.apple.com/documentation/cryptokit/) and [P-256 raw representation](https://developer.apple.com/documentation/cryptokit/p256/signing/ecdsasignature/rawrepresentation) — P-256, HMAC, and raw signature APIs. [CITED: official Apple documentation]
- [Apple Keychain accessibility](https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility) — `ThisDeviceOnly` and After First Unlock behavior. [CITED: official Apple documentation]
- [Apple platform conditional compilation](https://developer.apple.com/documentation/xcode/running-code-on-a-specific-version/) — isolate platform-only APIs. [CITED: official Apple documentation]

### Tertiary (LOW confidence)

- [Apple generic iOS build destination guidance](https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle) — supports the compile-lane design by analogy; exact final SwiftPM command remains an implementation validation item. [CITED: official Apple documentation]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — system frameworks and current package/toolchain are directly inspected. [VERIFIED: codebase; VERIFIED: local environment probe]
- Architecture: HIGH — locked Phase 223 decisions directly prescribe the ownership and invariant boundary. [VERIFIED: 223-CONTEXT.md]
- Pitfalls: HIGH — each is demonstrated by the current source/test behavior or locked phase rule. [VERIFIED: codebase; VERIFIED: 223-CONTEXT.md]

**Research date:** 2026-08-05  
**Valid until:** 2026-09-04 for project architecture; recheck Apple/Xcode APIs before CI implementation. [ASSUMED]
