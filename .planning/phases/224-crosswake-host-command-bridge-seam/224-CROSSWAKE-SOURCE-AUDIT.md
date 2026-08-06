# Crosswake Source Audit — Phase 224 Plans 01–02

**Audit status:** base locked; source inspected before any Crosswake edit.

## Authorized delivery source

| Field | Value |
| --- | --- |
| Checkout | `/Users/jon/projects/crosswake-accrue-bridge` |
| Sanitized remote | `https://github.com/szTheory/crosswake.git` |
| Delivery lane | Alpha-owned short-lived branch `chore/accrue-host-command-bridge` |
| Upstream base revision | `932b4f32bf087b8e4c0c36c3e54b1031839e867d` |
| Initial checkout state | clean |
| Fork owner/lifetime | szTheory Alpha delivery fork; delete or merge after the Phase 224 review path closes |
| Upstream convergence | pending review; no upstream PR is asserted by this audit |
| License | MIT (`LICENSE`) |
| Build prerequisites | SwiftPM, Swift 5.9+ package tools; macOS or a Swift-capable host |

This audit deliberately retains the plan's two specless assumptions as unresolved:
`SPEC-FALLBACK-BRDG-01` and `SPEC-FALLBACK-BRDG-02`. Deterministic denial coverage
is the executable backstop; it is not a claim of exhaustive SPEC coverage.

## Existing safe bridge boundary

| Role | Owner | Evidence |
| --- | --- | --- |
| Envelope decode / protocol-runtime validation | `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift`, `BridgeChannel.userContentController(_:didReceive:)` and `evaluate(_:completion:)` | `BridgeRequestEnvelope` is decoded before evaluation; `evaluate` checks `crosswake.bridge`, bridge/runtime SemVer compatibility. The tracer itself has a zero-field schema: any payload is denied before the delegate. |
| Route, exact origin, command, installed-pack and manifest capability gates | same file, `BridgeChannel.evaluate(_:completion:)` / `capabilityAvailable(for:request:)` | Existing order is protocol/runtime → active route → exact `allowedOrigin` → bounded command/capability → required packs → route capability/version → configured delegate. |
| Route/manifest state owner | `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift`, `ShellManifest.Route`, `LiveViewSession` | Route manifest carries capabilities/packs/origins; activation resolves the active session. |
| Reply terminalization owner | `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShell.swift`, `BridgeReplyDelivery.sink(evaluate:)` | Crosswake serializes an immutable reply envelope and the host supplies only script execution. |
| Navigation invalidation hook | `examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift`, `webView(_:decidePolicyFor:decisionHandler:)`; `BridgeChannel.update(session:transferCoordinator:)` | The host gate enforces same-origin navigation. The tracer increments a monotonic `routeEpoch` whenever its session changes and suppresses a delegate outcome whose captured epoch is stale. |
| Telemetry seam | none in the bridge dispatch path | The tracer adds no telemetry to avoid payload/identity leakage. |

## Test targets and commands

| Purpose | Command |
| --- | --- |
| Baseline native suite | `swift test --package-path packages/crosswake-shell-core-ios` |
| Tracer filter (created by this plan) | `swift test --package-path packages/crosswake-shell-core-ios --filter HostCommandAdmissionTests` |

## Planned tracer files and symbols

The following table is complete for the pre-edit review; it is finalized with patch
revision and line-level symbols after the Crosswake commit.

| File | Planned symbols / scope |
| --- | --- |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` | Added `BridgeCommand.accrueEntitlementsRefresh`, `routeEpoch`, and the guarded `accrueEntitlementsRefresh` switch case. It admits only a no-field request whose exact capability/version is present in both session manifest state and host registration, invokes the typed delegate, and retains reply ownership. |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeDelegates.swift` | Added immutable `HostCommandRequest`, transport-free `HostCommandCancellationContext`, closed `HostCommandOutcome`, and `HostCommandDelegate`. |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift` | Added `HostCommandDescriptor`, its public alias, weak `hostCommandDelegate`, and immutable descriptor registration. |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift` | Added the production tracer: admitted path plus declaration-only, registration-only, exact-version mismatch, and no-field-schema denial coverage. |

No Accrue bridge, WebKit handler, host transport wrapper, account/device identifier, proof,
receipt, JWS, token, or arbitrary payload map is part of this delivery.

## Reviewed patch record

| Field | Value |
| --- | --- |
| Patch revision | `e04928e36381fbbf076ec72eed09737f39c94986` |
| Diff range | `932b4f32bf087b8e4c0c36c3e54b1031839e867d..e04928e36381fbbf076ec72eed09737f39c94986` |
| Review status | local diff reviewed; full SwiftPM suite and tracer filter passed |
| Upstream convergence | still `alpha_fork_pending_upstream_review`; no upstream acceptance is claimed |

## Plan 03 final proof inventory

| File | Created / modified symbols and bounded responsibility |
| --- | --- |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeDelegates.swift` | `HostCommandDelegate.handle` is throwing; the delegate remains limited to `HostCommandRequest` and `HostCommandCancellationContext`, with no WebKit, raw envelope, callback, reply, or frame control. |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` | The sole ordered dispatcher catches a host delegate failure and sends the existing bounded `handler_failed` denial through the route-epoch-bound terminalizer. |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift` | Proves a synthetic throwing delegate produces exactly one opaque bounded denial, keeps normalized delegate fields transport-free, and retains the four-command/intersection/no-field/epoch negative coverage. |

The deterministic runner's `full` mode runs the pinned source gate followed by the entire native SwiftPM suite. It is deterministic; this synchronous source has no scheduler/seed facility, so cancellation and route invalidation remain represented by the captured immutable cancellation context and epoch terminalization tested in the same target.

## Plan 03 reviewed patch record

| Field | Value |
| --- | --- |
| Patch revision | `57e03b61082b1f865bc31c5e8b6dcee444f56dad` |
| Diff range | `932b4f32bf087b8e4c0c36c3e54b1031839e867d..57e03b61082b1f865bc31c5e8b6dcee444f56dad` |
| Review status | local diff reviewed; full SwiftPM suite plus admission, lifecycle, and full runner modes passed |
| Upstream convergence | still `alpha_fork_pending_upstream_review`; no upstream acceptance is claimed |

### Security boundary finding

The discovered `WKScriptMessageHandler` base seam exposes the decoded message and frame
metadata but has no content-world identity in its current public contract. This patch does
not claim a content-world check that is not present. It preserves the existing protocol,
runtime, route, origin, pack, manifest, and capability checks, adds a strict manifest/host
registration intersection for the tracer, and leaves broader message-context hardening for
the later lifecycle/admission plans and security review. The bridge remains feasibility
evidence only; it is not entitlement authority or physical-device proof.

## Plan 04 final exact-revision inventory

The final reviewed delivery is limited to the four files below. This is the exhaustive
production/test inventory for the reviewed diff
`932b4f32bf087b8e4c0c36c3e54b1031839e867d..57e03b61082b1f865bc31c5e8b6dcee444f56dad`:

| File | Final bounded symbols / responsibility |
| --- | --- |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` | The four literal `BridgeCommand` cases share the existing ordered validation path; `routeEpoch`, `terminalizeHostCommand`, and `emitHostCommandTelemetry` retain one Crosswake-owned, stale-safe terminal reply. |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeDelegates.swift` | `HostCommandRequest`, `HostCommandCancellationContext`, `HostCommandOutcome`, and throwing `HostCommandDelegate.handle` expose only normalized command intent and cancellation. |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift` | `HostCommandDescriptor`, `HostCommandConfigurationError`, and validating descriptor registration restrict setup to the literal four-command capability intersection. |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift` | Deterministic admission, schema, descriptor, throwing-delegate, API-surface, route-epoch, and one-shot denial coverage. |

No StoreKit, Accrue binding, host UI/authentication, simulator promotion, physical-device
run, generic plugin API, or additional command appears in that diff. The checked-in
conformance record is revision-bound to this inventory; it is compile/unit evidence only.

## Plan 02 expansion inventory

| File | Created / modified symbols and bounded responsibility |
| --- | --- |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` | Added `BridgeCommand.accruePurchase`, `.accrueRestore`, `.accrueOfflineReconnect`, `hostAccrueCommands`, `HostCommandTelemetryEvent`, `terminalizeHostCommand`, and `emitHostCommandTelemetry`. Four literal no-field commands share the one ordered admission path; reply delivery is rechecked against the captured `LiveViewSession` and `routeEpoch`, and duplicate/stale terminalization is suppressed. |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift` | Added `HostCommandConfigurationError` and `CrosswakeShellConfig.validating(hostCommandDescriptors:hostCommandDelegate:)`, which rejects unsupported, malformed, and duplicate closed descriptors before bridge installation. |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift` | Added literal-four-command admission, configuration diagnostic, bounded request-field, and navigation/epoch reply-suppression coverage. |

The available lifecycle hook in this pinned source is `BridgeChannel.update(session:transferCoordinator:)`, called by the audited container as its session changes. Its monotonic epoch invalidates an admitted binding before the new session is installed. This synchronous source contract exposes cooperative cancellation to the delegate; non-cooperative results are suppressed before delivery. No host receives a reply closure, WebKit target, raw route binding, or terminalizer.

## Plan 02 reviewed patch record

| Field | Value |
| --- | --- |
| Patch revision | `8611c09d4c9e6a32233425b3d876321632b89aef` |
| Diff range | `932b4f32bf087b8e4c0c36c3e54b1031839e867d..8611c09d4c9e6a32233425b3d876321632b89aef` |
| Review status | local diff reviewed; full SwiftPM suite plus admission and lifecycle filters passed |
| Upstream convergence | still `alpha_fork_pending_upstream_review`; no upstream acceptance is claimed |
