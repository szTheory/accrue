# Phase 224: Crosswake host-command bridge seam - Research

**Researched:** 2026-08-06  
**Domain:** Swift/WebKit validated native-command bridge  
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Deliver the seam in Crosswake's own safe-bridge implementation, at the existing validated dispatch point. Prefer an accepted upstream patch consumed at an immutable release or commit. If upstream timing prevents the adopter delivery, use the same narrowly reviewed patch in a short-lived, Alpha-owned fork pinned to an exact revision, retaining the base/diff and an upstream-convergence record. — **Reversibility:** costly — the pinned source revision, CI evidence, host integration, and security review all depend on one authoritative bridge implementation.
- **D-02:** Do not create an Accrue-local substitute bridge, custom `WKScriptMessageHandler`, or host wrapper that reimplements validation. Accrue remains a contract/fixture consumer; Crosswake owns validated transport and reply mechanics; the host owns StoreKit, session/authentication, lifecycle, UI, telemetry sink, and all Accrue binding.
- **D-03:** Bridge compile/unit evidence must run against the exact pinned Crosswake revision and establishes deterministic bridge conformance only. The capability report remains `feasibility_blocked` until separately authorized, redacted physical-iPhone evidence exists. — **Reversibility:** one-way — public runtime-readiness claims and the downstream first-adopter proof depend on preserving this evidence boundary.
- **D-04:** Use a manifest-owned, route-scoped `HostCommandCapability` (exact name at planner discretion) that declares a closed map of command identifiers, capability version, and command-specific request/response descriptors. The host registers a delegate/handler for the same command and version. Dispatch is permitted only when both the active manifest capability and host registry agree; neither declaration nor registration alone grants authority. — **Reversibility:** costly — route manifests and host integrations will depend on this explicit, reviewable configuration model.
- **D-05:** Keep the initial command set literal and closed: `host.accrue.purchase`, `host.accrue.restore`, `host.accrue.entitlements.refresh`, and `host.accrue.offline.reconnect`. Do not allow wildcards, dynamic command discovery, open-ended namespaces, or capability merging that could turn the seam into a generic commerce API.
- **D-06:** Validate malformed/duplicate configuration at bridge setup or manifest-install time, with actionable developer diagnostics. At runtime, expose only stable, privacy-safe denial codes such as `command_not_declared`, `command_not_registered`, `capability_version_mismatch`, `route_inactive`, `origin_not_allowed`, `request_malformed`, `handler_failed`, and `reply_expired`; do not expose allowlists, stack traces, payloads, or backend mechanics.
- **D-07:** Require one ordered admission path: bounded envelope parsing; protocol/version validation; main-frame/content-world and exact-origin validation; installed-pack, manifest, active-route, and route-epoch validation; manifest capability plus exact-command lookup; then command-specific schema/bounds validation. Host dispatch happens only after every existing Crosswake validation has passed.
- **D-08:** Give the host delegate a normalized immutable typed request and cancellation context, never a `WKWebView`, raw `WKScriptMessage`, raw envelope/payload bytes, JavaScript evaluator, callback, or reply channel. The delegate returns a closed typed success/denial outcome; Crosswake alone encodes and delivers at most one terminal protocol reply. Host code cannot fabricate a reply, choose a target frame, or execute JavaScript.
- **D-09:** Command descriptors own fixed, bounded request/response schemas. The bridge must reject arbitrary `Any`/JSON maps and must never carry raw JWS, receipts, proof bytes, tokens, account IDs, device IDs, or other sensitive identifiers in command payloads, telemetry, guides, or support artifacts.
- **D-10:** Bind every admitted invocation to the validated route generation/epoch. On main-frame navigation start, invalidate the previous epoch and cooperatively cancel pending delegate work. Before any terminal reply, recheck origin, manifest, route, and epoch; suppress the result if they changed. A non-cancellable native action may complete internally, but it can never reply to a new route. — **Reversibility:** costly — this is the bridge's cross-route authority and user-visible completion contract.
- **D-11:** Normalize unregistered, malformed, inactive-route, cross-origin, cancelled, and failing commands through the bridge-owned safe-denial path. A handler exception or cancellation produces one bounded denial; it must not inject a reply or change entitlement authority. Crosswake command success and StoreKit outcomes are never entitlement grants.
- **D-12:** Emit privacy-bounded telemetry for attempt, validation denial, handler start/result/failure, and reply suppression: command ID, capability version, manifest/route ID or coarse classification, route epoch, terminal reason, duration, and host correlation ID. Never log payload bodies, receipts, JWS/proof bytes, credentials, account/device identifiers, or adopter identity. Treat increased route-inactive/version-mismatch/handler-failure rates as integration signals, not entitlement states.
- **D-13:** Make deterministic tests prove that each validation failure never reaches the delegate; malformed/oversized input, unregistered commands, cross-origin/subframe requests, inactive routes, capability-version drift, throwing/cancelled handlers, double completion, and navigation races all deny safely with no stale reply. Also prove the host delegate cannot access reply transport and success responses conform only to the declared descriptor schema.
- **D-14:** Phase 224 adds no end-user visual system. Any later host UI uses ordinary native controls with visible loading/disabled/error states, accessible names and status announcements, system light/dark behavior, and measured action-first copy. Keep bridge internals hidden unless a bounded next action helps the user (for example: “The page changed before this action completed. Return to the billing screen and try again.”).

### the agent's Discretion
The planner may choose exact Swift/module/type names, descriptor encoding format, task/cancellation primitives, telemetry event names, test target layout, and the precise upstream/fork contribution mechanics. These choices must preserve the source-access gate, explicit manifest-and-registry intersection, fixed command allowlist, one validated admission/reply path, route-epoch suppression, data minimization, deterministic negative proof, and device-runtime honesty.

### Deferred Ideas (OUT OF SCOPE)
- A generic Crosswake commerce or plugin API — outside Phase 224 and prohibited by BRDG scope.
- StoreKit purchase/restore/update implementation, host UI flows, authenticated host transport, and Accrue integration — Phase 225.
- Simulator or physical-device runtime promotion — physical evidence is a separately authorized external gate.
- Additional commands, Android/Google Play policy, product catalogs, receipt forwarding, or entitlement interpretation — out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| BRDG-01 | A Crosswake host may declare a route-scoped command delegate without bypassing protocol, version, route, origin, pack, or manifest validation. | Ordered admission, manifest/registry intersection, immutable source pin, and direct-after-validation insertion point. |
| BRDG-02 | Unregistered, malformed, inactive-route, cross-origin, or failing host commands deny safely and cannot inject replies. | Bridge-owned closed outcomes, one-shot reply gate, route epoch recheck, and negative/race test matrix. |
</phase_requirements>

## Summary

The implementation target is an unavailable external Crosswake source tree, not this Accrue checkout. [VERIFIED: codebase grep] The checked-in capability report explicitly says the pinned Crosswake shell/core source and documented bridge are unavailable, and keeps every listed Crosswake-dependent capability `feasibility_blocked`. [VERIFIED: examples/crosswake_tracer/capability-report.json] Therefore the first plan wave must acquire either the accepted upstream implementation or the narrowly scoped Alpha fork at an exact immutable revision, record its base/diff/convergence status, and run every bridge test against that revision.

The smallest safe shape is a manifest-owned route capability plus a separately registered host delegate, intersected after Crosswake's existing validation path. [VERIFIED: 224-CONTEXT.md] The delegate must receive a normalized immutable request and cooperative cancellation context only; Crosswake retains raw WebKit input and the sole terminal reply closure. Apple defines `WKScriptMessageHandlerWithReply` as the reply-capable message-handler protocol, whose callback receives a message plus reply handler; its reply values are Foundation property-list-compatible. [CITED: https://developer.apple.com/documentation/webkit/wkscriptmessagehandlerwithreply] [CITED: https://developer.apple.com/documentation/webkit/wkscriptmessagehandlerwithreply/usercontentcontroller%28_%3Adidreceive%3Areplyhandler%3A)

**Primary recommendation:** Plan a source-access/pin checkpoint followed by a Crosswake-only extension that invokes the host strictly after the pre-existing validator, and make a bridge-owned one-shot reply gate revalidate epoch/origin/route/manifest immediately before delivery.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Envelope and protocol admission | Frontend Server (native Crosswake shell) | Browser / Client | Crosswake owns raw WebKit message transport and protocol validation. [VERIFIED: 224-CONTEXT.md] |
| Route-origin-pack-manifest authorization | Frontend Server (native Crosswake shell) | CDN / Static (pack assets) | Authority is determined from installed pack, current manifest, active route, frame/content world, and exact origin before dispatch. [VERIFIED: 224-CONTEXT.md] |
| Command capability declaration | Frontend Server (manifest model) | Browser / Client | Capability is route-scoped manifest configuration, not a JavaScript-discovered plugin surface. [VERIFIED: 224-CONTEXT.md] |
| Host command work | API / Backend (host-native delegate) | Frontend Server | The host owns StoreKit/session/lifecycle; it returns a typed result but never transport control. [VERIFIED: 224-CONTEXT.md] |
| Terminal response | Frontend Server (native Crosswake shell) | Browser / Client | Crosswake alone serializes and targets the at-most-once WebKit protocol reply. [VERIFIED: 224-CONTEXT.md] |
| Entitlement authority | API / Backend (Accrue/host backend) | — | Command success and StoreKit outcomes cannot grant entitlement. [VERIFIED: 224-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---|---|---|
| Crosswake safe bridge | Exact upstream release or commit, unavailable at research time | Existing validated message admission and reply transport | Locked owner of protocol, route, origin, pack, manifest checks, and replies. [VERIFIED: 224-CONTEXT.md] |
| WebKit `WKScriptMessageHandlerWithReply` | Apple platform SDK supplied by pinned Crosswake target | Request-associated JS reply facility internal to Crosswake | Apple-provided reply-capable bridge protocol; do not substitute evaluated JavaScript. [CITED: https://developer.apple.com/documentation/webkit/wkscriptmessagehandlerwithreply] |
| Swift structured concurrency | Swift 6.3.3 installed locally | Track/cancel route-bound delegate work | Native cancellation signalling supports the required cooperative cancellation plus recheck design. [CITED: https://developer.apple.com/documentation/swift/task/cancel%28%29] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| Swift Testing | Swift 6 toolchain | Deterministic unit and race tests | Match the Phase 223 package/tracer precedent. [VERIFIED: examples/crosswake_tracer/Tests] |
| `jq` | local CLI | Assert evidence report stays blocked | Retain the existing machine-checkable evidence boundary. [VERIFIED: examples/crosswake_tracer/capability-report.json] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Crosswake validated dispatch | Accrue-local or host-local `WKScriptMessageHandler` | Prohibited: it duplicates/bypasses Crosswake validation and creates a second reply authority. [VERIFIED: 224-CONTEXT.md] |
| Request-associated reply handler | `evaluateJavaScript` late response | Prohibited: it loses the request-associated reply boundary and enables stale/new-route targeting mistakes. [VERIFIED: 224-CONTEXT.md] |
| Literal descriptor registry | Dynamic plugin/namespace discovery | Prohibited: it widens a first-adopter seam into generic commerce API. [VERIFIED: 224-CONTEXT.md] |

**Installation:** None. This phase must not install a package; it consumes the externally pinned Crosswake source and Apple platform SDK. [VERIFIED: 224-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Web content / postMessage
          |
          v
Crosswake raw receiver (main frame + content world)
          |
          v
bounded envelope -> protocol/version -> exact origin
          |                                      |
          | denial ------------------------------+--> bridge-owned one-shot reply
          v
pack -> installed manifest -> active route + epoch
          |
          v
manifest capability ∩ registered command/version -> fixed schema/bounds
          |                                      |
          | denial ------------------------------+--> bridge-owned one-shot reply
          v
immutable typed request + cancellation context
          |
          v
host delegate (StoreKit/session work remains host-owned)
          |
          v
closed success/denial outcome -> recheck origin/manifest/route/epoch
          |                                      |
          | stale/cancelled ---------------------+--> suppress or bounded denial
          v
Crosswake serializes exactly one terminal protocol reply
```

### Recommended Project Structure

```text
Crosswake source at immutable revision/
├── Sources/.../Bridge/                 # existing safe admission/reply owner
├── Sources/.../Manifest/               # route-scoped HostCommandCapability
├── Sources/.../HostCommands/           # closed descriptors, registry, delegate boundary
└── Tests/.../HostCommands/             # unit, denial, schema, epoch-race tests

accrue/
└── examples/crosswake_tracer/          # consumer/evidence check only; no bridge replacement
```

### Pattern 1: Capability plus registry intersection

**What:** Bind a fixed command descriptor to both the active manifest capability and host registry; require exact command ID and capability version agreement. [VERIFIED: 224-CONTEXT.md]

**When to use:** For every host-command invocation, after existing bridge route/origin/pack/manifest validation and before passing data to host code. [VERIFIED: 224-CONTEXT.md]

**Example:**

```swift
// Source: Phase 224 locked contract; implementation names are illustrative.
guard let descriptor = activeManifest.hostCommandCapability?.descriptor(for: envelope.command),
      let handler = registry.handler(for: descriptor.id),
      descriptor.version == handler.version else {
  return replyOnce(.denial(.commandNotRegistered))
}
try descriptor.decodeBoundedRequest(envelope.payload)
```

### Pattern 2: Bridge-owned terminalization with epoch check

**What:** Store invocation work by validated route epoch, cancel it when navigation begins, then revalidate the route binding before Crosswake sends the only reply. [VERIFIED: 224-CONTEXT.md]

**When to use:** Every async delegate outcome, including success, exception, cancellation, and duplicate completion. [VERIFIED: 224-CONTEXT.md]

**Example:**

```swift
// Source: Apple Task cancellation docs + Phase 224 locked contract.
let outcome = await invoke(delegate, request: request, cancellation: context)
guard !Task.isCancelled, routeState.matches(validatedBinding) else {
  return replyOnce(.denial(.replyExpired))
}
replyOnce(encode(outcome)) // private Crosswake method; not passed to host.
```

Apple states task cancellation is cooperative and does not automatically stop arbitrary work, so cancellation alone is insufficient for route safety. [CITED: https://developer.apple.com/documentation/swift/task/cancel%28%29]

### Anti-Patterns to Avoid

- **Delegate before validation:** Never let command-specific schema validation or host dispatch precede protocol/version/origin/route/pack/manifest admission. [VERIFIED: 224-CONTEXT.md]
- **Raw transport capability:** Do not pass `WKWebView`, `WKScriptMessage`, bytes, callback, JavaScript evaluator, or reply channel to the host delegate. [VERIFIED: 224-CONTEXT.md]
- **Open response maps:** Do not accept or emit `Any`/arbitrary JSON; descriptors own fixed bounded request and response schemas. [VERIFIED: 224-CONTEXT.md]
- **Cancellation-as-security-check:** Do not assume `Task.cancel()` stops non-cooperative work; always use the pre-reply binding recheck. [CITED: https://developer.apple.com/documentation/swift/task/cancel%28%29]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| JavaScript/native transport | A second `WKScriptMessageHandler` or JavaScript-evaluation callback path | Crosswake's existing safe bridge and request-associated reply path | A separate path cannot inherit its validation/reply invariants. [VERIFIED: 224-CONTEXT.md] |
| Command authorization | String-prefix/wildcard matcher | Literal closed descriptor map plus manifest-and-registry intersection | Prevents ambient/dynamic command expansion. [VERIFIED: 224-CONTEXT.md] |
| Response delivery | Delegate callback or WebView access | Crosswake private one-shot terminalization gate | Prevents host reply injection, duplicate terminal replies, and cross-route targeting. [VERIFIED: 224-CONTEXT.md] |
| Route invalidation | Best-effort delegate cancellation only | Epoch-bound task cancellation plus pre-reply revalidation | Cancellation is cooperative. [CITED: https://developer.apple.com/documentation/swift/task/cancel%28%29] |

**Key insight:** the security property comes from preserving one authoritative admission-and-reply path, not from making the host delegate more capable. [VERIFIED: 224-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Planning against undocumented Crosswake APIs

**What goes wrong:** A plan invents file names or handler contracts that do not match the only authoritative bridge implementation. [VERIFIED: examples/crosswake_tracer/capability-report.json]

**How to avoid:** Make source access, immutable revision pin, base/diff record, and upstream/fork convergence record the first executable task and do not claim bridge compilation until that source is present. [VERIFIED: 224-CONTEXT.md]

### Pitfall 2: A stale command replies after navigation

**What goes wrong:** A previous route's async native action replies into a newer route. [VERIFIED: 224-CONTEXT.md]

**How to avoid:** Capture route epoch at admission; invalidate/cancel on main-frame navigation; recheck exact origin, manifest, route, and epoch at terminalization; suppress result if changed. [VERIFIED: 224-CONTEXT.md]

### Pitfall 3: A convenience error leaks policy or data

**What goes wrong:** Runtime errors expose allowlists, payloads, stack traces, receipts, or account/device data. [VERIFIED: 224-CONTEXT.md]

**How to avoid:** Map all failures to the locked stable reason vocabulary, with actionable setup diagnostics only at install time and data-minimized telemetry. [VERIFIED: 224-CONTEXT.md]

### Pitfall 4: Deterministic evidence is labelled runtime proof

**What goes wrong:** Bridge tests or iOS compilation change public capability posture. [VERIFIED: examples/crosswake_tracer/capability-report.json]

**How to avoid:** Assert the report remains `feasibility_blocked`; treat physical iPhone evidence as a separate, authorized gate. [VERIFIED: 224-CONTEXT.md]

## Code Examples

### Delegate boundary

```swift
// Source: Phase 224 locked contract. Illustrative API shape only.
protocol HostCommandDelegate: Sendable {
  func handle(_ request: HostCommandRequest,
              cancellation: HostCommandCancellation) async -> HostCommandOutcome
}

// HostCommandRequest has no WebKit or reply-transport member.
// HostCommandOutcome is a closed success/denial enum validated by its descriptor.
```

### One-shot reply ownership

```swift
// Source: Apple WKScriptMessageHandlerWithReply docs + Phase 224 locked contract.
private func terminalize(_ outcome: BridgeOutcome, binding: RouteBinding) {
  guard routeState.matches(binding), terminalReply.claim() else { return }
  webKitReply(encodeProtocolOutcome(outcome), nil)
}
```

The WebKit API is explicitly designed to receive a JavaScript message and provide a reply; this implementation must keep that reply handler private to Crosswake. [CITED: https://developer.apple.com/documentation/webkit/wkscriptmessagehandlerwithreply]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Generic raw JS/native callback with optional late response | Request-associated WebKit reply plus a bridge-owned, typed terminal gate | Apple SDK API currently documented | Preserve request correlation while restricting replies to the validated shell. [CITED: https://developer.apple.com/documentation/webkit/wkscriptmessagehandlerwithreply] |
| Fire-and-forget delegate completion | Cooperative cancellation plus explicit state revalidation | Swift concurrency current docs | Correctness must not depend on cancellation terminating work. [CITED: https://developer.apple.com/documentation/swift/task/cancel%28%29] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Suggested Crosswake folder/type names and the illustrative Swift snippets match a plausible structure, but cannot be verified without the pinned source. | Architecture Patterns / Code Examples | Planner could misname files; resolve immediately after source-access gate. |

## Open Questions

1. **Which immutable Crosswake revision and source location will own the patch?**
   - What we know: The local capability report records the source as unavailable. [VERIFIED: examples/crosswake_tracer/capability-report.json]
   - What's unclear: Upstream acceptance timing, exact module names, test target, and current validator seam.
   - Recommendation: Gate all implementation tasks on recording the revision, base/diff, source audit, and convergence record; use the exact discovered safe dispatch point.

2. **Which precise fixed schemas fit the four literal commands without sensitive payloads?**
   - What we know: Arbitrary maps and raw proofs/receipts/tokens/identifiers are prohibited. [VERIFIED: 224-CONTEXT.md]
   - What's unclear: The first-adopter's minimal non-sensitive request/response fields.
   - Recommendation: Define descriptors as fixed zero/small-field contracts in Crosswake after host review; reject oversize/unknown/duplicate fields and defer StoreKit/Accrue semantics to Phase 225.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Swift toolchain | Bridge/test work once source is supplied | ✓ | Swift 6.3.3 | — |
| Xcode SDK/toolchain | WebKit/iOS compile lane once source is supplied | ✓ | Xcode 26.6 | — |
| Pinned Crosswake source | Actual patch and bridge tests | ✗ | — | Accepted upstream patch or short-lived Alpha-owned exact-revision fork, both requiring source access. [VERIFIED: 224-CONTEXT.md] |

**Missing dependencies with no fallback:** None; the locked upstream-or-reviewed-fork path is the permitted fallback, but it remains a blocking acquisition task. [VERIFIED: 224-CONTEXT.md]

**Missing dependencies with fallback:** Crosswake source is unavailable in this checkout; do not substitute Accrue code or a custom WebKit handler. [VERIFIED: 224-CONTEXT.md]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | Swift Testing / Swift 6.3.3 [VERIFIED: local `swift --version`] |
| Config file | Crosswake package/project configuration — unavailable; discover after source pin. |
| Quick run command | Exact pinned Crosswake test filter for host-command admission (Wave 0). |
| Full suite command | Exact pinned Crosswake bridge suite plus `swift test --package-path examples/crosswake_tracer` and evidence-report assertion. |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| BRDG-01 | Existing validation completes before delegate dispatch; only capability ∩ registry permits invocation. | Crosswake unit/integration | `<pinned-crosswake-test-command> HostCommandAdmissionTests` | ❌ Wave 0 |
| BRDG-02 | Unregistered, malformed, inactive, cross-origin, handler-failing, duplicate-complete, and epoch-race requests never inject/stale-reply. | Crosswake negative/concurrency | `<pinned-crosswake-test-command> HostCommandDenialAndEpochTests` | ❌ Wave 0 |
| BRDG-01, BRDG-02 | Evidence remains deterministic and blocked. | Consumer/contract | `swift test --package-path examples/crosswake_tracer && jq -e '.overall_status == "feasibility_blocked" and all(.capabilities[]; .status == "feasibility_blocked")' examples/crosswake_tracer/capability-report.json` | ✅ |

### Sampling Rate

- **Per task commit:** affected pinned-Crosswake host-command tests.
- **Per wave merge:** full pinned-Crosswake bridge suite and tracer/evidence command.
- **Phase gate:** all deterministic suites green; report remains blocked; no physical-runtime claim.

### Wave 0 Gaps

- [ ] Exact Crosswake source revision, contribution/fork record, and test/build command.
- [ ] Pinned-source `HostCommandAdmissionTests` covering all mandatory pre-dispatch checks.
- [ ] Pinned-source `HostCommandDenialAndEpochTests` covering exception/cancellation/double-completion/navigation races.
- [ ] Static/API test proving delegate exposure excludes WebKit and reply transport types.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | Yes | Exact-origin, main-frame/content-world and installed manifest admission; host auth stays outside this seam. [VERIFIED: 224-CONTEXT.md] |
| V3 Session Management | Yes | Route epoch binds authority to current navigation and suppresses stale replies. [VERIFIED: 224-CONTEXT.md] |
| V4 Access Control | Yes | Manifest capability ∩ exact registered command/version; closed allowlist. [VERIFIED: 224-CONTEXT.md] |
| V5 Input Validation | Yes | Bounded envelope then fixed descriptor schemas; reject arbitrary maps and sensitive payloads. [VERIFIED: 224-CONTEXT.md] |
| V6 Cryptography | No | This bridge transports no proofs, tokens, receipts, or cryptographic authority. [VERIFIED: 224-CONTEXT.md] |

### Known Threat Patterns for Swift/WebKit bridge

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Cross-origin/subframe command | Spoofing | Main-frame/content-world and exact-origin checks before dispatch. [VERIFIED: 224-CONTEXT.md] |
| Unregistered/undeclared command | Elevation of privilege | Closed descriptor allowlist plus manifest/registry/version intersection. [VERIFIED: 224-CONTEXT.md] |
| Stale route reply | Tampering | Epoch invalidate/cancel plus recheck immediately before bridge-owned reply. [VERIFIED: 224-CONTEXT.md] |
| Host reply injection/double completion | Tampering | No transport capability crosses delegate boundary; one-shot Crosswake terminalization. [VERIFIED: 224-CONTEXT.md] |
| Payload/log disclosure | Information disclosure | Fixed bounded schemas and telemetry fields that exclude bodies and sensitive identifiers. [VERIFIED: 224-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- Repository contract: `224-CONTEXT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and `accrue/guides/first_adopter_ios_bridge.md` — scope, ownership, admission, reply, and evidence constraints. [VERIFIED: codebase grep]
- `examples/crosswake_tracer/capability-report.json` — source-unavailable and blocked-evidence fact. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- [Apple `WKScriptMessageHandlerWithReply`](https://developer.apple.com/documentation/webkit/wkscriptmessagehandlerwithreply) — request-associated reply protocol/API.
- [Apple reply-handler method](https://developer.apple.com/documentation/webkit/wkscriptmessagehandlerwithreply/usercontentcontroller%28_%3Adidreceive%3Areplyhandler%3A) — reply closure values and error channel.
- [Apple `Task.cancel()`](https://developer.apple.com/documentation/swift/task/cancel%28%29) — cooperative, idempotent cancellation semantics.

### Tertiary (LOW confidence)
- None beyond the explicitly labelled illustrative source-layout/API assumption.

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM — Apple APIs are documented, but exact Crosswake revision/source remains unavailable.
- Architecture: HIGH — locked phase contract precisely defines the mandatory ownership and ordered admission invariants.
- Pitfalls: HIGH — route epoch, reply ownership, sensitive-data, and evidence-boundary failures are explicitly locked and testable.

**Research date:** 2026-08-06  
**Valid until:** Source-access gate is resolved, or 7 days; exact Crosswake APIs cannot be planned beyond the locked seam without its pinned source.
