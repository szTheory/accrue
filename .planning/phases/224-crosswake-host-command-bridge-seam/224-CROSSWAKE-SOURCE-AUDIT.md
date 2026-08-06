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

### Security boundary finding

The discovered `WKScriptMessageHandler` base seam exposes the decoded message and frame
metadata but has no content-world identity in its current public contract. This patch does
not claim a content-world check that is not present. It preserves the existing protocol,
runtime, route, origin, pack, manifest, and capability checks, adds a strict manifest/host
registration intersection for the tracer, and leaves broader message-context hardening for
the later lifecycle/admission plans and security review. The bridge remains feasibility
evidence only; it is not entitlement authority or physical-device proof.
