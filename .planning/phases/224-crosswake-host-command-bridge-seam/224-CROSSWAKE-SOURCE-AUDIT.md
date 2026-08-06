# Crosswake Source Audit — Phase 224 Plan 01

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
| Bounded envelope decode / protocol-runtime validation | `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift`, `BridgeChannel.userContentController(_:didReceive:)` and `evaluate(_:completion:)` | `BridgeRequestEnvelope` is decoded before evaluation; `evaluate` checks `crosswake.bridge`, bridge/runtime SemVer compatibility. |
| Route, exact origin, command, installed-pack and manifest capability gates | same file, `BridgeChannel.evaluate(_:completion:)` / `capabilityAvailable(for:request:)` | Existing order is protocol/runtime → active route → exact `allowedOrigin` → bounded command/capability → required packs → route capability/version → configured delegate. |
| Route/manifest state owner | `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift`, `ShellManifest.Route`, `LiveViewSession` | Route manifest carries capabilities/packs/origins; activation resolves the active session. |
| Reply terminalization owner | `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShell.swift`, `BridgeReplyDelivery.sink(evaluate:)` | Crosswake serializes an immutable reply envelope and the host supplies only script execution. |
| Navigation invalidation hook | `examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift`, `webView(_:decidePolicyFor:decisionHandler:)` | The host gate enforces same-origin navigation. No route epoch exists at the locked base; the tracer will introduce an explicit monotonic epoch on the `BridgeChannel` session update seam. |
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
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` | `BridgeCommand.accrueEntitlementsRefresh`, bounded envelope limits, `HostCommandDescriptor`, immutable `HostCommandRequest`, `HostCommandCancellationContext`, `HostCommandOutcome`, manifest/registry intersection, and guarded dispatch. |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeDelegates.swift` | `HostCommandDelegate` only; it receives no WebKit/reply transport object. |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift` | host-command registration and delegate configuration. |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandAdmissionTests.swift` | declared-and-registered tracer and declaration-only/registration-only/version-denial coverage. |

No Accrue bridge, WebKit handler, host transport wrapper, account/device identifier, proof,
receipt, JWS, token, or arbitrary payload map is part of this delivery.

## Review record

The immutable base is the sole pre-edit identity. `crosswake-source-lock.json` is in
`base_locked` state and its audit digest covers this file. The reviewed patch fields are
intentionally absent until the Crosswake diff is tested and committed.
