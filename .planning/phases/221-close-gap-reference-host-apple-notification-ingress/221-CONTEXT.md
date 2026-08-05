# Phase 221: close-gap-reference-host-apple-notification-ingress - Context

**Gathered:** 2026-08-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the reference host's missing App Store Server Notifications V2 ingress so it demonstrates the existing Accrue Apple notification contract end to end: a host-owned public route, exact raw-body capture, pinned runtime verification configuration, bounded backpressure, durable notification intake, reconciliation wakeup, and deterministic host-boundary proof.

This phase does not create a new entitlement reducer, modify the package's generic notification plug, add an Apple management UI or raw-event explorer, accept raw provider evidence in diagnostics, claim a live App Store delivery as merge authority, or add a distributed rate-limit dependency or cross-rail lifecycle behavior.

</domain>

<decisions>
## Implementation Decisions

### Dedicated Apple route and raw-body contract
- **D-01:** Mount the reference host's Apple V2 endpoint at `/webhooks/apple`, beside—not inside—the Stripe scope. It uses a distinct `:accrue_apple_notifications_raw_body` pipeline with only JSON parsing, `Accrue.Webhook.CachingBodyReader`, and an explicit `262_144` byte limit, then invokes the existing `accrue_apple_notifications` macro. It must not pass through browser, CSRF, session, authentication, controller, or generic Stripe-webhook handling. — **Reversibility:** costly — the route, parser limit, installation recipe, router proof, and Apple App Store Connect endpoint will form one public host contract.
- **D-02:** Do not share Stripe's 1 MiB parser pipeline. Exact byte preservation and the Apple plug's 256 KiB limit are intentional, route-visible safety constraints; parsed parameters, reconstructed JSON, or a different raw byte sequence are never verifier input.
- **D-03:** The endpoint is an authenticated notification/reconciliation boundary, not entitlement truth. It returns success only after a durable verified intake or durable terminal quarantine; it never projects grants directly from request order and never turns a notification receipt into a reducer.

### Runtime trust and host ownership
- **D-04:** The reference host owns its Apple verifier and reconciliation configuration in runtime configuration, failing fast in production for pinned trust roots, bundle ID, production app ID, expected environment, and explicit verifier/config versions. No secrets, private credentials, raw provider payloads, or cert material belong in source fixtures, logs, telemetry, or diagnostics. — **Reversibility:** one-way — configuration and verifier identity become the host's published trust boundary and must agree across ingress and admission/reconciliation paths.
- **D-05:** Reuse one immutable host verifier configuration for notification ingress and Apple purchase/restore admission. Do not present one mixed sandbox/production endpoint while the configured verifier is environment-specific; the reference recipe is production-only. A future sandbox route must be independently configured and proven.
- **D-06:** Use a small host-owned wrapper Plug to resolve the already-validated runtime options and delegate to `Accrue.Entitlements.Apple.NotificationPlug`. This keeps runtime ownership in the app without expanding Accrue's public API or embedding deployment values in compile-time router options.
- **D-07:** Wire the existing Apple reconciliation resources in the host—client/admission configuration, `:accrue_entitlements` Oban queue, and reconciliation sweeper. Queue uniqueness may coalesce wakeups, but PostgreSQL constraints and locks remain the authority for durable correctness and ownership.

### Backpressure, response semantics, and operations
- **D-08:** Pass a host-owned Apple rate-policy callback. The reference host may use a small deterministic, single-node backstop keyed from a trusted peer identity, but its README/runbook must state that deployment edge/shared infrastructure is authoritative for multi-node or internet-scale limits. Do not add Redis or a rate-limit package in this phase. — **Reversibility:** costly — the callback is the public extension seam for host rate policy and must preserve predictable ingress behavior.
- **D-09:** Preserve the plug's response classes: malformed input `400`, oversized input `413`, temporary rate denial `429`, and missing raw body, configuration, verification-transient, or persistence failure `503`. A verified-invalid notification is acknowledged `200` only after successful bounded quarantine. Apple retries both `4xx` and `5xx`, so `429` is temporary backpressure—not a terminal discard—and early `2xx` is forbidden.
- **D-10:** Keep the existing authenticated diagnostic and runbook surfaces as the operator experience. Use job-and-next-action language and safe correlations only; do not add a public Apple status page, raw JWS/certificate viewer, Apple lifecycle control, or automatic ownership/finance mutation. Monitor response-class trends, quarantine growth, reconciliation age/backlog, and `needs_repair` without emitting raw bodies, signatures, provider payloads, tokens, PII, worker arguments, or exception text.

### Deterministic reference-host proof and adopter guidance
- **D-11:** Add host-router integration proof rather than relying on direct core Plug tests or the current direct `observe_apple_evidence/2` scenario. Deterministic signed fixtures/Fake verifier evidence must cover valid delivery, duplicate/concurrent idempotency, durable quarantine, raw-body regression, all response classes, privacy, and reconciliation wiring. — **Reversibility:** costly — this closes the reference-host evidence gap and becomes the merge-blocking proof of the documented setup.
- **D-12:** Real App Store `Request a Test Notification`/status evidence is an advisory deployment check only. Keep deterministic host proof merge-blocking and label live delivery honestly; it must not promote unsupported Crosswake/runtime or provider-capability claims.
- **D-13:** Update the reference-host README, adoption proof matrix, and narrow operator runbooks with the route, runtime inputs, response classes, safe troubleshooting sequence, and a literal verification command. Copy follows the current brandbook: measured, exact, Phoenix-native, and mechanism-led.

### the agent's Discretion
The planner may choose exact host module names, runtime-config key shapes, trusted-peer normalization details, single-node limiter algorithm, fixture source, test helper placement, Oban schedule wiring, and documentation organization. These choices must preserve the dedicated 256 KiB raw-body boundary, host-owned runtime configuration, durable-before-acknowledgement rule, environment isolation, privacy limits, database correctness authority, deterministic Fake-first proof, and existing Apple-external-management policy.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, authority, and previously locked behavior
- `.planning/PROJECT.md` — v1.59 host/package ownership, privacy limits, and stable-core posture.
- `.planning/ROADMAP.md` — authoritative Phase 221 boundary and dependency on Phase 220.
- `.planning/REQUIREMENTS.md` — AAPL-02 through AAPL-04 and PROOF-01 through PROOF-05 acceptance context.
- `.planning/phases/218-apple-observation-and-repair/218-CONTEXT.md` — Apple verification, exact raw-body capture, quarantine, reconciliation, lock, provider-isolation, and redaction decisions.
- `.planning/phases/220-first-adopter-proof-and-release-gates/220-CONTEXT.md` — reference-host proof lanes, operator-safe diagnosis/repair, deterministic Fake-first merge authority, and public-contract honesty.
- `.planning/research/v1.59-DECISION-TABLE.md` — canonical decision-case authority; notification ingress must not become a competing reducer.
- `.planning/research/v1.59-PITFALLS.md` — Apple/provider, privacy, ordering, and operational risks.

### Existing Accrue ingress and reconciliation contract
- `accrue/lib/accrue/router.ex` — public `accrue_apple_notifications/2` route macro and its raw-body/limit contract.
- `accrue/lib/accrue/entitlements/apple/notification_plug.ex` — response classes, durable quarantine, rate-policy callback, and telemetry boundary.
- `accrue/lib/accrue/entitlements/apple/verifier.ex` — verifier configuration contract.
- `accrue/lib/accrue/entitlements/apple/verifier/production.ex` — pinned-root verification and environment/application validation.
- `accrue/lib/accrue/entitlements/apple/reconciliation.ex` — reconciliation and durable wakeup behavior.
- `accrue/lib/accrue/entitlements/apple/reconciliation_wakeup.ex` — wakeup uniqueness and bounded persistence contract.
- `accrue/guides/webhooks.md` — package-supported Apple route, parser, raw-body, and host-policy setup.
- `accrue/guides/entitlements.md` — host-owned Apple admission, queue, scheduler, and authority boundaries.
- `accrue/guides/operator-runbooks.md` — privacy-safe, bounded operator response patterns.
- `accrue/guides/telemetry.md` — prohibited raw evidence, signature, and PII telemetry fields.

### Reference host and proof precedent
- `examples/accrue_host/lib/accrue_host_web/router.ex` — current Stripe-only route and raw-body pipeline to extend without conflation.
- `examples/accrue_host/config/runtime.exs` — established host-owned runtime configuration and production fail-fast pattern.
- `examples/accrue_host/config/config.exs` — host-owned Oban queues/plugins configuration.
- `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` — router-level host proof, durable persistence, and idempotency assertion precedent.
- `examples/accrue_host/test/accrue_host/reference_scenario_conformance_test.exs` — current semantic Apple-to-web proof whose HTTP-boundary gap this phase closes.
- `examples/accrue_host/README.md` — reference-host adoption/proof narrative to update.
- `examples/accrue_host/docs/adoption-proof-matrix.md` — evidence-lane and proof-matrix contract.

### Product, voice, and research inputs
- `brandbook/voice.md` — current copy authority; supersedes older prompt wording.
- `brandbook/copy.md` — approved mechanism-led developer and operational copy patterns.
- `prompts/accrue-best-practices-deep-research-independent.md` — billing-library and webhook operational lessons.
- `prompts/accrue-library-summary-for-admin-ux-deep-research.md` — operator JTBD, bounded diagnosis, and host/package boundary research.
- `prompts/original-billing-ecosystem-deep-research.md` — Pay/Cashier ecosystem lessons; historical context, not scope authority.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Router.accrue_apple_notifications/2` and `Accrue.Entitlements.Apple.NotificationPlug` — the supported public ingress seam; no generic Plug change is needed.
- `Accrue.Webhook.CachingBodyReader` — established exact raw-body capture used by the host's Stripe ingress.
- Apple verifier, intake, quarantine, reconciliation wakeup, and sweeper modules — existing bounded trust and recovery path to wire from the host.
- `AccrueHostWeb.WebhookIngestTest` — direct `Router.call/2`, persistence, Oban, and idempotency proof style.
- Existing diagnostics, runbooks, and telemetry policy — operator-facing next-action and privacy-safe presentation boundary.

### Established Patterns
- Phoenix routes use narrowly scoped pipelines for provider-specific parsing and verification constraints.
- The host owns routes, runtime configuration, secrets, supervision, queues, and rate policy; Accrue owns bounded domain behavior and public macros.
- Runtime production configuration uses `System.fetch_env!` to fail fast instead of committing secrets or deferring configuration failure to an unrelated request.
- Database constraints/locks establish correctness; Oban uniqueness is coalescing only.
- Deterministic Fake-backed proof is merge-blocking; real provider delivery evidence is advisory and labeled as such.

### Integration Points
- Extend `AccrueHostWeb.Router` with the dedicated Apple pipeline and mount.
- Add a host-owned options wrapper/rate-policy module plus runtime Apple/reconciliation configuration and host supervision/Oban wiring.
- Add a focused host-router ingress proof beside Stripe's existing ingress test and retain the scenario corpus as semantic—not HTTP-boundary—coverage.
- Update reference-host adoption materials and narrow operational runbooks without creating a new operator UI surface.

</code_context>

<specifics>
## Specific Ideas

- The user requested an integrated, consumer-first recommendation spanning architecture, operational safety, developer ergonomics, privacy, accessibility where applicable, and established ecosystem lessons.
- The selected direction favors Phoenix/Plug conventions, explicit host/package ownership, compact setup, literal verification, and safe operator outcomes over clever abstraction or a new dependency.
- UI work is intentionally limited to existing authenticated diagnostics and clear runbook/microcopy. The public ingress is machine-to-machine; exposing backend evidence would harm both usability and privacy.

</specifics>

<deferred>
## Deferred Ideas

- Distributed shared rate limiting, a CDN/gateway implementation, and multi-node enforcement — deployment hardening outside the single-host reference seam.
- A separately configured sandbox Apple endpoint — only if a future adopter or proof contract requires it.
- A public Apple status page, raw notification explorer, Apple lifecycle management controls, or automatic ownership/finance mutation — outside this ingress gap and contrary to existing provider-honesty/privacy decisions.

</deferred>

---

*Phase: 221-close-gap-reference-host-apple-notification-ingress*
*Context gathered: 2026-08-05*
