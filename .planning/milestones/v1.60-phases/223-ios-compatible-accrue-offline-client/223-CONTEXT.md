# Phase 223: iOS-compatible Accrue offline client - Context

**Gathered:** 2026-08-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Extract the verified Swift tracer into a reusable iOS-compatible SwiftPM offline client. The client must preserve canonical ES256 proof verification, device binding, high-water ordering, signed-deny precedence, and verified atomic cache replacement, while proving iOS compilation and cache semantics. It does not implement the Crosswake bridge, StoreKit, purchase/restore, host authentication, UI, or physical-device runtime proof.

</domain>

<decisions>
## Implementation Decisions

### Host-Facing Offline Client API
- **D-01:** Publish one narrow, named Swift facade (for example, `OfflineEntitlementClient`) over internal verifier and cache primitives. It supplies a clear integration path to load a cached proof, verify/apply a compact server proof, and initiate an authenticated reconnect; it returns immutable `Sendable` domain values. — **Reversibility:** costly — first-adopter integration code and the public SwiftPM API will depend on the facade's nouns and outcome model.
- **D-02:** The public result uses the locked four-state contract: `fresh`, `stale_offline`, `denied`, and `invalid`, with the bounded reason/next-action vocabulary. Stale is study-continuity only; it is never a local entitlement grant or a fifth state such as `reconnect_required`. — **Reversibility:** one-way — this is a cross-language protocol and host-consumer contract already used by canonical vectors and future UI guidance.
- **D-03:** A cache mutation accepts only compact server proof bytes and derives revision, issuance, freshness, and disposition after local ES256/profile/account/device verification. Do not expose caller-constructed verified-replacement metadata, raw cache payload authority, fixture readers, or test keys as runtime API.
- **D-04:** Keep StoreKit purchase/restore/update observation, `appAccountToken`, account authentication, authenticated transport implementation, lifecycle orchestration, product-to-content policy, and learner UI host-owned. The client may define a narrow host-supplied reconnect transport protocol, but it must not grow into a generic mobile commerce SDK.

### Package and Storage Boundary
- **D-05:** Extract a standalone SwiftPM package with a portable `AccrueOfflineClient` core product and an optional Apple-specific product for small Keychain-oriented helpers. Retain `examples/crosswake_tracer` as a path-dependent conformance consumer and feasibility artifact, not as the distributable public package. — **Reversibility:** costly — package products, import paths, and first-adopter dependency configuration become externally consumed SwiftPM contract.
- **D-06:** Keep verifier, opaque verified-proof admission, high-water/deny ordering, authenticated envelope format, atomic replacement, and recovery together in the core package. Do not split them into separately versioned packages before a committed second host/platform establishes that need; ordering and persistence must remain one auditable invariant.
- **D-07:** The host supplies the application/container URL, cache-authentication key from its secure boundary, Keychain service/access-group policy, Secure Enclave device-key integration, transport authentication, lifecycle triggers, and downloaded-content policy. The cache-authentication key is never persisted by the library.
- **D-08:** The library provides a file-backed default store that writes a candidate alongside the destination, synchronizes it, atomically replaces on the same volume, synchronizes the parent directory where supported, and recovers only the canonical authenticated envelope. A write/recovery failure preserves the previous complete cache and returns a bounded reconnect/retry failure; it must never silently weaken integrity.
- **D-09:** Apple helpers make `ThisDeviceOnly` Keychain accessibility an explicit host configuration. `AfterFirstUnlockThisDeviceOnly` is appropriate only when the host requires post-unlock background recovery; failure before first unlock is an actionable bounded outcome, not grounds to weaken device-bound protection.

### Verification and Runtime-Honesty Evidence
- **D-10:** Keep the canonical language-neutral corpus as the sole cross-language behavioral oracle. Make public-package Swift mutation/unit tests merge-blocking for ES256-only verification, exact issuer/audience/device binding, all four states, high-water order, deny precedence, rotation, malformed input, and crash/recovery cases. Repository-relative fixture lookup and test-only private keys stay in test support only.
- **D-11:** Preserve process/fault-injection cache tests on macOS/Linux and add a merge-blocking generic-iOS SDK compilation lane for the declared iOS 16 floor. The iOS lane proves API/deployment compatibility, not simulator or device runtime behavior.
- **D-12:** Keep the Crosswake capability report, bridge evidence, simulator observations, and physical-device evidence outside this client package's pass/fail result. SwiftPM compilation and vectors never change `feasibility_blocked` to `proven`; an authorized physical-device artifact remains a separate external gate. — **Reversibility:** one-way — public readiness claims and downstream bridge/host phases rely on this evidence boundary.

### Developer and Consumer Experience
- **D-13:** Optimize the API for the host developer's job: one obvious safe path, domain nouns, immutable typed results, configuration errors at construction/integration boundaries, and documentation that names ownership. Follow Accrue's Phoenix-style public-context convention: expose the facade, not crypto internals, file format, provider payloads, or host runtime plumbing.
- **D-14:** The package does not render UI in this phase. Its state/reason/next-action values must nevertheless let hosts present literal, accessible, text-backed guidance with no color-only status or backend mechanics. Use the current brandbook's measured, exact, native, and durable voice; stale-study copy remains job-focused.

### the agent's Discretion
The planner may choose exact module/type names, function arities, package directory layout, core deployment floors consistent with validated dependencies, `swift-crypto` versus platform-compatible crypto implementation details, Keychain helper API shape, test target names, CI job names, and documentation organization. These choices must preserve the narrow public facade, verified-only replacement, host-owned runtime resources, portable core, iOS 16 compilation evidence, canonical-vector authority, and physical-device truth boundary.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current Scope and Acceptance Contract
- `.planning/PROJECT.md` — v1.60 goal, host/core ownership, runtime-honesty, adopter and deferral guardrails.
- `.planning/ROADMAP.md` — Phase 223 scope, dependency shape, and milestone doctrine.
- `.planning/REQUIREMENTS.md` — IOS-01 through IOS-03 acceptance contract and v1.60 exclusions.

### Locked Offline and Feasibility Contracts
- `.planning/milestones/v1.59-phases/215-research-contracts-and-crosswake-feasibility/215-CONTEXT.md` — Crosswake tracer, secure storage, high-water, atomic replacement, and feasibility-boundary decisions D-09 through D-13.
- `.planning/milestones/v1.59-phases/219-offline-study-contract/219-CONTEXT.md` — four-state vocabulary, ES256/JWKS/device binding, reconnect, cache-ordering, privacy, host-ownership, and learner-guidance contracts.
- `.planning/research/v1.59-AUTHORITY.md` — current authority precedence for the offline contract.
- `.planning/research/v1.59-STACK.md` — ES256, key, fixture, and deterministic test constraints.
- `.planning/research/v1.59-ARCHITECTURE.md` — client/host ownership and reconnect boundaries.
- `.planning/research/v1.59-PITFALLS.md` — protocol, replay, rotation, privacy, and operational hazards.
- `.planning/research/MULTI-RAIL-OFFLINE-ENTITLEMENTS.md` — accepted offline strategy and explicit v1 limits.

### Existing Executable Inputs
- `examples/crosswake_tracer/Package.swift` — current SwiftPM targets and iOS 16 declaration.
- `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` — existing verifier, high-water, authenticated cache, and tracer boundary to extract without weakening.
- `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift` — current vector-consumer and mutation-test precedent.
- `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/AtomicOfflineCacheProcessTests.swift` — current crash/restart cache-semantics proof.
- `examples/crosswake_tracer/README.md` — current public boundary and evidence-lane wording.
- `examples/crosswake_tracer/capability-report.json` — feasibility report that must remain independent of package compilation/vector success.
- `accrue/priv/entitlements/v1.59-offline-golden-vectors.json` — canonical language-neutral proof/vector corpus.
- `accrue/priv/entitlements/v1.59-decision-cases.json` — canonical decision-case corpus.

### Developer Experience and Voice
- `prompts/accrue-best-practices-deep-research-independent.md` — developer, operator, SRE, security, reconciliation, and safe-action JTBD input.
- `prompts/accrue-library-summary-for-admin-ux-deep-research.md` — consumer/host mental-model and exception-first outcome guidance; historical when superseded by current authority.
- `brandbook/voice.md` — current voice authority, superseding older prompt wording when they differ.
- `brandbook/copy.md` — literal mechanism-plus-next-action copy patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `OfflineGoldenVectorVerifier` and the canonical vector corpus — strict ES256/profile/device binding and parity test seed; fixture access must move behind test support.
- `AtomicOfflineCache` and `ProofHighWater` — authenticated file envelope, monotonic replacement, per-path/process locking, candidate cleanup, synchronization, and recovery foundation.
- `examples/crosswake_tracer/Package.swift` — existing iOS 16 library/test/harness layout to split into a reusable package and separate consumer.
- `capability-report.json` and its validator — retained feasibility-report pattern, explicitly not runtime client API.

### Established Patterns
- Accrue public interfaces are small Phoenix-style facades with tagged/typed values; schemas, reducers, cryptographic details, and host runtime resources stay private.
- Host applications own routes, authentication, secrets, secure storage, supervision, transport, lifecycle, and UI; Accrue owns bounded domain and verification invariants.
- Deterministic, credential-free vectors and negative/mutation tests are merge-blocking; simulator/device evidence is separately classified and must not be overstated.
- Existing offline contract allows only verified newer server allow or signed denial to replace cache; reachability and lifecycle events may request, not authorize, reconciliation.

### Integration Points
- Extract the existing library target into a distributable package; retain the Crosswake tracer as a consumer wired to the package through a local/path dependency.
- Move corpus loading, test keys, and child-process crash harness into package test support or the tracer without carrying repository paths into installed runtime code.
- Wire an iOS SDK compilation check beside the existing Swift and repository contract gates while retaining the separate Crosswake/device evidence report.

</code_context>

<specifics>
## Specific Ideas

- Favor a small Swift facade with explicit configuration and ownership over both a bag of crypto primitives and an all-in-one mobile entitlement SDK.
- Learn the convenience of cached-entitlement SDKs without inheriting their authority: Accrue verifies only server-issued proof and never uses cache, StoreKit, or reachability as grant authority.
- Preserve the library user's mental model: load verified state, apply verified proof, reconnect through the host, render an action-focused result.
- UI is out of scope, but output values must support conventional accessible host rendering in light, dark, and system themes without color-only meaning or implementation leakage.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 223. Crosswake bridge APIs, StoreKit 2 integration, purchase/restore/update behavior, host UI, simulator/StoreKit proof, and physical-device runtime evidence belong to later phases or separately authorized work.

</deferred>

---

*Phase: 223-iOS-compatible Accrue offline client*
*Context gathered: 2026-08-05*
