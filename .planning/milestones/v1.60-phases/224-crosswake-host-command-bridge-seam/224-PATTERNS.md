# Phase 224: Crosswake host-command bridge seam - Pattern Map

**Mapped:** 2026-08-06
**Files analyzed:** 6 anticipated files/records (all implementation files are in the not-yet-pinned Crosswake source)
**Analogs found:** 2 / 6 locally; the Crosswake source analogs are intentionally unavailable until the source-access gate resolves.

## Scope Gate

There is no Crosswake implementation in this checkout. `examples/crosswake_tracer/capability-report.json` lines 4-19 records `feasibility_blocked` because the pinned shell/core source and documented bridge are unavailable. Therefore the first plan task must acquire and record an immutable upstream release/commit or short-lived reviewed Alpha fork, its base/diff, test command, and upstream-convergence status. It must then replace every `TBD after pin` path below with the exact discovered Crosswake location. Do not create an Accrue-local bridge, `WKScriptMessageHandler`, or host wrapper.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `<pinned Crosswake>/Sources/.../Manifest/<HostCommandCapability>.swift` | model/config | transform | none — source unavailable | no local analog |
| `<pinned Crosswake>/Sources/.../HostCommands/<HostCommandDescriptorRegistry>.swift` | service/model | request-response | `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/CanonicalJSONAdmission.swift` | partial data-boundary match |
| `<pinned Crosswake>/Sources/.../HostCommands/<HostCommandDelegate>.swift` | provider | request-response | `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineReconnect.swift` | role-match |
| `<pinned Crosswake>/Sources/.../Bridge/<existing validated dispatcher>.swift` | controller/middleware | event-driven | none — exact dispatch/reply owner unavailable | no local analog |
| `<pinned Crosswake>/Tests/.../HostCommandAdmissionTests.swift` | test | request-response | `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift` | role-match |
| `<pinned Crosswake>/Tests/.../HostCommandDenialAndEpochTests.swift` | test | event-driven | `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift` | partial negative-proof match |

`examples/crosswake_tracer/capability-report.json` and its tests remain consumer/evidence controls, not bridge implementation targets. Preserve their blocked status; modify them only if a separately authorized evidence-contract change explicitly requires it.

## Pattern Assignments

### `<pinned Crosswake>/Sources/.../Manifest/<HostCommandCapability>.swift` (model/config, transform)

**Analog:** No implementation analog is available in this repository. Discover the actual manifest model only after pinning Crosswake.

**Required pattern from the locked contract:** add one manifest-owned, route-scoped capability with a closed literal descriptor map. Configuration/install must reject malformed or duplicate descriptors with actionable developer diagnostics. The allowed command IDs are only:

```swift
// Locked Phase 224 contract — not an Accrue-local implementation.
[
  "host.accrue.purchase",
  "host.accrue.restore",
  "host.accrue.entitlements.refresh",
  "host.accrue.offline.reconnect"
]
```

Do not merge capabilities, accept wildcards, or support dynamic discovery. The active manifest declaration alone never authorizes dispatch.

---

### `<pinned Crosswake>/Sources/.../HostCommands/<HostCommandDescriptorRegistry>.swift` (service/model, request-response)

**Analog:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/CanonicalJSONAdmission.swift`.

**Bounded-input pattern** (lines 3-14):

```swift
/// A deliberately small JSON scanner used before Foundation turns objects into maps.
/// It only admits well-formed JSON with unique object member names at every depth.
enum CanonicalJSONAdmission {
    static let maximumNestingDepth = 32

    static func validate(_ data: Data) throws {
        var scanner = Scanner(bytes: Array(data))
        try scanner.value(depth: 0)
        scanner.space()
        guard scanner.index == scanner.bytes.count else { throw Error.malformed }
    }
}
```

**Apply:** keep descriptor decoding before any host invocation: bounded envelope, no duplicate fields, fixed schema/field and byte limits, and closed response validation. Never pass `Any`, arbitrary JSON maps, raw receipts/JWS/proofs/tokens, or account/device identifiers across the delegate boundary.

**Authorization core:** after Crosswake's existing protocol/version/main-frame/content-world/exact-origin/pack/manifest/route/epoch checks, require both an exact active-manifest descriptor and exact registered handler with equal capability versions. Map each failure to a stable bridge-owned denial code; never expose configuration details at runtime.

---

### `<pinned Crosswake>/Sources/.../HostCommands/<HostCommandDelegate>.swift` (provider, request-response)

**Analog:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineReconnect.swift`.

**Narrow host-owned protocol pattern** (lines 3-6):

```swift
/// A host-owned authenticated request that returns only a compact entitlement proof.
/// Implementations retain responsibility for endpoints, credentials, request shape, and retries.
public protocol OfflineProofReconnectTransport: Sendable {
    func reconnectProof() async throws -> Data
}
```

**Error-boundary pattern** (lines 9-17):

```swift
func reconnect(using transport: some OfflineProofReconnectTransport, now: Date) async -> OfflineEntitlementState {
    do {
        return applyServerProof(try await transport.reconnectProof(), now: now)
    } catch {
        return .invalid(reason: .reconnectFailed, nextAction: .reconnectRequired)
    }
}
```

**Apply:** define a `Sendable` host delegate that receives only an immutable normalized typed request plus cooperative cancellation context and returns a closed typed success/denial outcome. Adapt throwing/cancelled work to `handler_failed`/bounded denial inside Crosswake. The delegate must not receive WebKit objects, raw message/payload data, JavaScript evaluation, callback, or reply channel.

---

### `<pinned Crosswake>/Sources/.../Bridge/<existing validated dispatcher>.swift` (controller/middleware, event-driven)

**Analog:** No local analog. This must be the exact existing Crosswake safe-dispatch/reply owner identified during source audit—not a new handler in Accrue or the host.

**Admission/reply assignment:** insert dispatch only after the established Crosswake validation path completes, in this fixed order:

```text
bounded envelope → protocol/version → main-frame/content-world + exact origin
→ installed pack/manifest/active route + epoch → manifest descriptor ∩ registry/version
→ command schema/bounds → typed delegate
```

Keep the request-associated WebKit reply handler private. Capture the validated route binding; cancel pending tasks on main-frame navigation start; before every terminal reply recheck origin, manifest, route, and epoch. Crosswake claims an at-most-once terminal reply; stale/cancelled outcomes are suppressed or become the locked bounded denial. A delegate cannot select a frame or fabricate a reply.

---

### `<pinned Crosswake>/Tests/.../HostCommandAdmissionTests.swift` (test, request-response)

**Analog:** `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift`.

**Fail-closed assertion pattern** (lines 83-104):

```swift
@Test("missing bridge or device evidence fails feasibility closed")
func missingEvidenceBlocksFeasibility() {
    // Build otherwise-complete evidence, remove one required state,
    // then assert feasibility remains blocked.
    #expect(CapabilityReport(schemaVersion: "1.0", capabilities: evidence).overallStatus == .feasibilityBlocked)
}
```

**Apply:** use deterministic fake delegate/bridge state and assert every failed precondition invokes the delegate zero times and yields exactly one safe bridge outcome. Cover malformed/oversized envelope, undeclared command, unregistered command, version drift, subframe/cross-origin, inactive route, and descriptor request/response validation.

---

### `<pinned Crosswake>/Tests/.../HostCommandDenialAndEpochTests.swift` (test, event-driven)

**Analog:** `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift`.

**Checked-in truth assertion pattern** (lines 131-140):

```swift
@Test("checked-in capability report remains feasibility blocked without bridge and device evidence")
func checkedInCapabilityReportRemainsBlocked() throws {
    let report = try JSONDecoder().decode(CheckedInReport.self, from: Data(contentsOf: reportURL))
    #expect(report.overallStatus == "feasibility_blocked")
    #expect(report.capabilities.allSatisfy { $0.status == "feasibility_blocked" })
}
```

**Apply:** write race/negative tests around observable outcomes: throwing delegate, cancellation, double completion, navigation/epoch change after admission, and changed origin/manifest/route before completion. Assert one terminal bridge action at most, no reply after binding invalidation, and no successful command result is interpreted as an entitlement grant. Add a static/API test proving the delegate-facing types have no WebKit or reply transport member.

## Shared Patterns

### Fail-closed canonical admission

**Source:** `accrue/lib/accrue/plug/require_entitlement.ex` lines 52-82; `accrue/lib/accrue/entitlements/guard.ex` lines 89-120.

```elixir
def call(conn, opts) do
  case Guard.check(:plug, conn, opts) do
    {:allow, conn} -> conn
    {:deny, deny_form, ctx} -> Guard.deny_plug(conn, deny_form, ctx, opts)
  end
end
```

**Apply to:** the Crosswake dispatcher. Keep exactly one authoritative validation/decision path; thin host-facing registration must delegate to it rather than independently admitting or replying.

### Bounded privacy-safe outcomes

**Source:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift` lines 55-72.

```swift
guard !proof.isEmpty else { return invalid(.malformed) }
do {
    let verified = try verify(proof, now: now)
    // admit only verified, bounded input
} catch let error as VerificationError { return invalid(error.reason) }
catch { return invalid(.cacheWriteFailed) }
```

**Apply to:** descriptors, bridge denial, and telemetry. Use only the locked stable reason vocabulary and bounded metadata (command ID, capability version, manifest/route classification, epoch, terminal reason, duration, host correlation ID). Never emit payloads, receipts/JWS/proofs, credentials, identifiers, stacks, or allowlists.

### Evidence honesty

**Source:** `examples/crosswake_tracer/capability-report.json` lines 4-19 and `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift` lines 131-140.

**Apply to:** every phase test/report. Pinned-source compile/unit tests establish deterministic bridge conformance only; retain `feasibility_blocked` until separately authorized redacted physical-iPhone evidence exists.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Exact Crosswake manifest capability model | model/config | transform | Crosswake source is unavailable locally. |
| Exact Crosswake validated dispatcher/reply gate | controller/middleware | event-driven | The sole valid owner is outside this checkout; source pin is a hard prerequisite. |

## Metadata

**Analog search scope:** `packages/accrue-offline-client`, `examples/crosswake_tracer`, `accrue/lib`, `accrue/guides`, and phase/project contracts.
**Files scanned:** 13 primary source, test, contract, and evidence files.
**Pattern extraction date:** 2026-08-06
