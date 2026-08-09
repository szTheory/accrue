# Crosswake Source Audit — Phase 224 Plans 01–07

**Audit status:** exact reviewed patch re-pinned after the Plan 07 safety closures.

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

## Plan 07 replay and configuration closure

| Field | Value |
| --- | --- |
| Patch revision | `789175f219de03047456e098fedf4a97891feff2` |
| Immutable base-to-patch range | `932b4f32bf087b8e4c0c36c3e54b1031839e867d..789175f219de03047456e098fedf4a97891feff2` |
| Binary diff identity (SHA-256) | `d4380733c61521060cbb7c7c50b522a6c7b08234ddfd83757cb2cb993a8479d4` |
| Review status | Local base-to-patch diff reviewed; focused 17-test and full 31-test native suites passed before re-pin; command-safe source-gate, trusted-frame, and full gates rerun at this exact revision. |
| Upstream convergence | still `alpha_fork_pending_upstream_review`; no upstream acceptance is claimed |

This closure addresses both verifier findings without changing the validated admission
order, literal four-command allowlist, narrow delegate surface, reply ownership,
telemetry privacy boundary, delivery lane, sanitized remote, or runtime classification.

| File | Exhaustive Plan 07 changed symbols / test coverage |
| --- | --- |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` | `HostCommandInvocationKey`, `HostCommandInvocationLifecycle`, `hostCommandInvocationLock`, `hostCommandInvocations`, `claimHostCommandInvocation`, and `isRouteEpochActive`; the epoch/correlation claim is atomic after all admission guards and before attempt telemetry or `HostCommandDelegate.handle`; `update(session:transferCoordinator:)` advances the epoch and retires lifecycle state under the same lock; terminalization transitions only an admitted claim. |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift` | Ordinary public initializer has no descriptor/delegate inputs and produces a non-host config; private descriptor-bearing initializer, `validating(hostCommandDescriptors:hostCommandDelegate:)`, and `isStrictSemanticVersion` make validated construction the sole public host path; duplicate command IDs and malformed versions produce bounded actionable diagnostics. |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift` | Real trusted-sender duplicate-correlation, post-navigation reuse, and 32-way contention regressions prove one host call/terminal reply; real factory/channel/navigation coverage proves valid construction; malformed, identical-duplicate, and conflicting-version descriptors assert bounded diagnostics. |

Actual native commands and results: `swift test --package-path packages/crosswake-shell-core-ios --filter HostCommandAdmissionTests` passed 17 tests; `swift test --package-path packages/crosswake-shell-core-ios` passed 31 tests. The deterministic runner then passed `source-gate`, `trusted-frame`, and `full` at this pinned revision; the full mode also passed the Accrue tracer, evidence digest, and blocked-status/evidence-location assertions. This remains deterministic compile/unit evidence only: no simulator, StoreKit, host integration, physical device, UI, entitlement authority, or runtime-readiness proof is claimed.

## Plan 05 trusted sender-frame closure

| Field | Value |
| --- | --- |
| Patch revision | `fc5e399fcb46d78b610c81e13c644277f3fcf1c5` |
| Immutable base-to-patch range | `932b4f32bf087b8e4c0c36c3e54b1031839e867d..fc5e399fcb46d78b610c81e13c644277f3fcf1c5` |
| Binary diff identity (SHA-256) | `af1dd2259a6d18645169375298e0adb8accdaf9945f98496b2a593bbdbf01176` |
| Review status | clean checkout; local diff reviewed; focused 14-test and full 28-test SwiftPM suites passed |
| Upstream convergence | still `alpha_fork_pending_upstream_review`; no upstream acceptance is claimed |
| iOS availability | `CrosswakeShellCore` targets iOS 15; installed iPhoneOS SDK exposes `WKScriptMessage.world` from iOS 14 |

The prior WebKit boundary finding is closed. At the real `BridgeChannel.userContentController(_:didReceive:)` entry point, production derives an internal immutable value-only sender context solely from `message.frameInfo.isMainFrame`, `message.frameInfo.securityOrigin` (protocol, case-normalized host, effective port), and `message.world == WKContentWorld.page`.

It compares those components to `session.allowedOrigin` before JSON body decode, evaluation, delegate invocation, or reply-sink delivery. Missing, opaque, malformed, subframe, cross-origin, and non-page-world contexts fail closed; the existing envelope `request.origin == session.allowedOrigin.absoluteString` remains defense in depth after trusted-frame admission.

The exhaustive two-file Plan 05 gap-closure inventory is:

| File | Final bounded symbols / responsibility |
| --- | --- |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` | `BridgeMessageSenderContext`, `userContentController(_:didReceive:)`, `receive(_:from:completion:)`, and internal `evaluate(_:completion:)`; the seam is not public authority and no host delegate receives WebKit objects, origin metadata, a reply closure, or evaluator access. |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift` | Trusted main-frame/page-world/exact-origin tracer and forged-envelope subframe, cross-origin-main-frame, and non-page-world negatives; each proves zero delegate calls and zero reply deliveries while retained protocol/version, route, pack, manifest, descriptor/version, schema, failure, epoch, and one-terminal-reply coverage stays green. |

The full reviewed range contains the earlier four-file Phase 224 foundation; only the two files above implement this sender-frame repair. No Accrue-local handler/wrapper, StoreKit, host UI/authentication, generic commerce API, additional command, simulator/physical-device claim, or capability-report status change was introduced.

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
