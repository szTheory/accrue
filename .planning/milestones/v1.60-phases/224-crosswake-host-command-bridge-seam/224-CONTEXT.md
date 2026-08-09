# Phase 224: Crosswake host-command bridge seam - Context

**Gathered:** 2026-08-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the smallest host-command delegate extension at Crosswake's existing validated bridge boundary. A first-adopter host may declare one of four approved commands only for an approved manifest and active route. The work must preserve mandatory protocol, version, route, origin, pack, and manifest validation; deny every non-admitted request safely; and make no device-runtime claim. It does not add an Accrue dependency to Crosswake, a generic commerce bridge, StoreKit behavior, host authentication/UI, entitlement authority, or physical-device evidence.

</domain>

<decisions>
## Implementation Decisions

### Delivery and Ownership
- **D-01:** Deliver the seam in Crosswake's own safe-bridge implementation, at the existing validated dispatch point. Prefer an accepted upstream patch consumed at an immutable release or commit. If upstream timing prevents the adopter delivery, use the same narrowly reviewed patch in a short-lived, Alpha-owned fork pinned to an exact revision, retaining the base/diff and an upstream-convergence record. — **Reversibility:** costly — the pinned source revision, CI evidence, host integration, and security review all depend on one authoritative bridge implementation.
- **D-02:** Do not create an Accrue-local substitute bridge, custom `WKScriptMessageHandler`, or host wrapper that reimplements validation. Accrue remains a contract/fixture consumer; Crosswake owns validated transport and reply mechanics; the host owns StoreKit, session/authentication, lifecycle, UI, telemetry sink, and all Accrue binding.
- **D-03:** Bridge compile/unit evidence must run against the exact pinned Crosswake revision and establishes deterministic bridge conformance only. The capability report remains `feasibility_blocked` until separately authorized, redacted physical-iPhone evidence exists. — **Reversibility:** one-way — public runtime-readiness claims and the downstream first-adopter proof depend on preserving this evidence boundary.

### Declarative Route Capability and Host DX
- **D-04:** Use a manifest-owned, route-scoped `HostCommandCapability` (exact name at planner discretion) that declares a closed map of command identifiers, capability version, and command-specific request/response descriptors. The host registers a delegate/handler for the same command and version. Dispatch is permitted only when both the active manifest capability and host registry agree; neither declaration nor registration alone grants authority. — **Reversibility:** costly — route manifests and host integrations will depend on this explicit, reviewable configuration model.
- **D-05:** Keep the initial command set literal and closed: `host.accrue.purchase`, `host.accrue.restore`, `host.accrue.entitlements.refresh`, and `host.accrue.offline.reconnect`. Do not allow wildcards, dynamic command discovery, open-ended namespaces, or capability merging that could turn the seam into a generic commerce API.
- **D-06:** Validate malformed/duplicate configuration at bridge setup or manifest-install time, with actionable developer diagnostics. At runtime, expose only stable, privacy-safe denial codes such as `command_not_declared`, `command_not_registered`, `capability_version_mismatch`, `route_inactive`, `origin_not_allowed`, `request_malformed`, `handler_failed`, and `reply_expired`; do not expose allowlists, stack traces, payloads, or backend mechanics.

### Single Admission Path and Reply Ownership
- **D-07:** Require one ordered admission path: bounded envelope parsing; protocol/version validation; main-frame/content-world and exact-origin validation; installed-pack, manifest, active-route, and route-epoch validation; manifest capability plus exact-command lookup; then command-specific schema/bounds validation. Host dispatch happens only after every existing Crosswake validation has passed.
- **D-08:** Give the host delegate a normalized immutable typed request and cancellation context, never a `WKWebView`, raw `WKScriptMessage`, raw envelope/payload bytes, JavaScript evaluator, callback, or reply channel. The delegate returns a closed typed success/denial outcome; Crosswake alone encodes and delivers at most one terminal protocol reply. Host code cannot fabricate a reply, choose a target frame, or execute JavaScript.
- **D-09:** Command descriptors own fixed, bounded request/response schemas. The bridge must reject arbitrary `Any`/JSON maps and must never carry raw JWS, receipts, proof bytes, tokens, account IDs, device IDs, or other sensitive identifiers in command payloads, telemetry, guides, or support artifacts.

### Route Lifecycle, Failure, and Operations
- **D-10:** Bind every admitted invocation to the validated route generation/epoch. On main-frame navigation start, invalidate the previous epoch and cooperatively cancel pending delegate work. Before any terminal reply, recheck origin, manifest, route, and epoch; suppress the result if they changed. A non-cancellable native action may complete internally, but it can never reply to a new route. — **Reversibility:** costly — this is the bridge's cross-route authority and user-visible completion contract.
- **D-11:** Normalize unregistered, malformed, inactive-route, cross-origin, cancelled, and failing commands through the bridge-owned safe-denial path. A handler exception or cancellation produces one bounded denial; it must not inject a reply or change entitlement authority. Crosswake command success and StoreKit outcomes are never entitlement grants.
- **D-12:** Emit privacy-bounded telemetry for attempt, validation denial, handler start/result/failure, and reply suppression: command ID, capability version, manifest/route ID or coarse classification, route epoch, terminal reason, duration, and host correlation ID. Never log payload bodies, receipts, JWS/proof bytes, credentials, account/device identifiers, or adopter identity. Treat increased route-inactive/version-mismatch/handler-failure rates as integration signals, not entitlement states.

### Verification and Consumer Experience
- **D-13:** Make deterministic tests prove that each validation failure never reaches the delegate; malformed/oversized input, unregistered commands, cross-origin/subframe requests, inactive routes, capability-version drift, throwing/cancelled handlers, double completion, and navigation races all deny safely with no stale reply. Also prove the host delegate cannot access reply transport and success responses conform only to the declared descriptor schema.
- **D-14:** Phase 224 adds no end-user visual system. Any later host UI uses ordinary native controls with visible loading/disabled/error states, accessible names and status announcements, system light/dark behavior, and measured action-first copy. Keep bridge internals hidden unless a bounded next action helps the user (for example: “The page changed before this action completed. Return to the billing screen and try again.”).

### the agent's Discretion
The planner may choose exact Swift/module/type names, descriptor encoding format, task/cancellation primitives, telemetry event names, test target layout, and the precise upstream/fork contribution mechanics. These choices must preserve the source-access gate, explicit manifest-and-registry intersection, fixed command allowlist, one validated admission/reply path, route-epoch suppression, data minimization, deterministic negative proof, and device-runtime honesty.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current Scope and Ownership
- `.planning/PROJECT.md` — v1.60 adopter goal, Crosswake/host/Accrue ownership, runtime-honesty, and deferral guardrails.
- `.planning/ROADMAP.md` — Phase 224 goal, success criteria, dependency shape, and strict phase boundary.
- `.planning/REQUIREMENTS.md` — BRDG-01 and BRDG-02 acceptance contract and explicit exclusions.
- `accrue/guides/first_adopter_ios_bridge.md` — approved command names, required validation order, payload prohibition, ownership, and evidence boundary.

### Locked Offline and Feasibility Contracts
- `.planning/phases/223-ios-compatible-accrue-offline-client/223-CONTEXT.md` — public-client boundary, host ownership, deterministic proof culture, and physical-device honesty.
- `.planning/milestones/v1.59-phases/215-research-contracts-and-crosswake-feasibility/215-CONTEXT.md` — Crosswake tracer and feasibility decisions D-09 through D-13.
- `.planning/research/v1.59-SUMMARY.md` — active authority for mobile/Crosswake ownership and accepted tradeoffs.
- `.planning/research/v1.59-ARCHITECTURE.md` — host/core boundary, user/support responsibilities, and privacy-safe diagnostic model.
- `.planning/research/v1.59-PITFALLS.md` — validation, privacy, evidence, ordering, and operational failure modes.
- `.planning/research/MULTI-RAIL-OFFLINE-ENTITLEMENTS.md` — accepted multi-rail/offline architecture and deliberate ownership boundary.

### Existing Executable Inputs and Evidence
- `examples/crosswake_tracer/README.md` — tracer is a conformance consumer, not a Crosswake runtime proof.
- `examples/crosswake_tracer/capability-report.json` — current `feasibility_blocked` status and required bridge/device evidence.
- `examples/crosswake_tracer/Tests/AccrueOfflineClientTracerTests/PackageConformanceTests.swift` — existing package-consumer conformance precedent.
- `packages/accrue-offline-client/README.md` — host/offline-client ownership and adoption boundary.

### Developer Experience and Voice
- `prompts/accrue-best-practices-deep-research-independent.md` — developer, support, SRE, security, and safe-action JTBD input.
- `prompts/accrue-library-summary-for-admin-ux-deep-research.md` — host-consumer mental model and exception-first outcome guidance; historical when superseded.
- `prompts/original-billing-ecosystem-deep-research.md` — cross-ecosystem library lessons; historical context only.
- `brandbook/voice.md` — current voice authority, superseding prompt wording where they differ.
- `brandbook/copy.md` — current action-oriented literal copy patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/crosswake_tracer/capability-report.json` — capability/evidence schema that must retain its blocked status until genuine bridge and device evidence exist.
- `examples/crosswake_tracer` — local-path conformance-consumer pattern for exercising the pinned offline-client package without creating a second verifier or runtime authority.
- `accrue/lib/accrue/plug/require_entitlement.ex` and `accrue/lib/accrue/entitlements/guard.ex` — narrow ordered-admission/fail-closed boundary precedent: validate intent early and delegate decisions through one canonical path.
- `accrue/lib/accrue/entitlements/offline/proof.ex` — closed state/reason/next-action vocabulary and action-focused user guidance precedent.

### Established Patterns
- Accrue uses narrow public facades, explicit host ownership of runtime resources, typed/tagged outcomes, bounded diagnostics, and deterministic negative tests rather than ambient hooks or loose runtime maps.
- A validated fact must take one canonical path; a convenience reply or custom WebKit handler that bypasses bridge admission would violate this pattern.
- Privacy-safe observability records coarse reason/outcome/correlation data and omits raw billing evidence, proofs, tokens, and identifiers.
- Crosswake/mobile runtime evidence is classified separately from compile, fixture, simulator, and package conformance proof.

### Integration Points
- The real implementation belongs in the unavailable Crosswake source, directly after its existing protocol/version/route/origin/pack/manifest checks, not in `accrue` or the local tracer.
- The first-adopter host later consumes that pinned Crosswake bridge alongside `AccrueOfflineClient`; Phase 225 owns StoreKit and host orchestration.
- This repository can retain contract fixtures, pinned-revision metadata, source/diff audit, and deterministic verification without representing it as runtime proof.

</code_context>

<specifics>
## Specific Ideas

- Use WebKit's request-associated reply facility only inside Crosswake; never deliver late results with evaluated JavaScript.
- Learn from Electron's narrow context bridge, Tauri's window/webview-scoped capabilities, and Capacitor/React Native's explicit Promise methods and single terminal completion, without importing their generic plugin surface.
- Optimize for a host developer who can see one safe route capability, register one explicit handler, write deterministic denial tests, and understand an actionable configuration failure without learning Crosswake internals.
- Users interact with native purchase/restore/refresh/reconnect actions, not bridge mechanics. Support and SRE need bounded reason codes and correlation IDs, not sensitive payload access.

</specifics>

<deferred>
## Deferred Ideas

- A generic Crosswake commerce or plugin API — outside Phase 224 and prohibited by BRDG scope.
- StoreKit purchase/restore/update implementation, host UI flows, authenticated host transport, and Accrue integration — Phase 225.
- Simulator or physical-device runtime promotion — physical evidence is a separately authorized external gate.
- Additional commands, Android/Google Play policy, product catalogs, receipt forwarding, or entitlement interpretation — out of scope.

</deferred>

---

*Phase: 224-Crosswake host-command bridge seam*
*Context gathered: 2026-08-06*
