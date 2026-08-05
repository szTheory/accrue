# Phase 221: Close gap: reference-host Apple notification ingress - Research

**Researched:** 2026-08-05
**Domain:** Phoenix/Plug App Store Server Notifications V2 ingress, host configuration, and durable reconciliation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
- Distributed shared rate limiting, a CDN/gateway implementation, and multi-node enforcement — deployment hardening outside the single-host reference seam.
- A separately configured sandbox Apple endpoint — only if a future adopter or proof contract requires it.
- A public Apple status page, raw notification explorer, Apple lifecycle management controls, or automatic ownership/finance mutation — outside this ingress gap and contrary to existing provider-honesty/privacy decisions.
</user_constraints>

## Summary

The codebase already provides the complete package-side notification contract: `Accrue.Router.accrue_apple_notifications/2`, exact raw-body capture, bounded `NotificationPlug` response handling, verified durable intake/quarantine, and reconciliation wakeups. The reference host currently mounts only Stripe and configures neither the Apple verifier/admission/client nor the `:accrue_entitlements` Oban resources. Phase 221 is therefore host integration and proof work, not a package API or entitlement-reducer change. [VERIFIED: codebase `accrue/lib/accrue/router.ex`, `notification_plug.ex`, `examples/accrue_host/lib/accrue_host_web/router.ex`]

Plan one narrow host-owned wrapper Plug that calls `Application.fetch_env!` for a prevalidated immutable Apple options structure and delegates unchanged to `NotificationPlug`. Add a separate `/webhooks/apple` parser pipeline with an exactly matching 262,144-byte read limit. Supply the same verifier config to admission/reconciliation, start the dedicated Oban queue plus `ReconciliationSweeper`, and prove the real router boundary using a deterministic fake verifier that receives the original raw bytes. [VERIFIED: codebase `accrue/guides/webhooks.md`, `accrue/guides/entitlements.md`, `accrue/lib/accrue/entitlements/apple/reconcile_worker.ex`]

Apple documents that the endpoint must be HTTPS/TLS 1.2+ and that a 2xx response signals success, while 4xx/5xx causes retry; V2 production retries failed deliveries five times and sandbox delivery is one attempt. That supports the locked durable-before-acknowledgement rule and makes `429` temporary admission pressure rather than a discard signal. [CITED: https://developer.apple.com/documentation/AppStoreServerNotifications/responding-to-app-store-server-notifications]

**Primary recommendation:** Extend only `examples/accrue_host` with an Apple-specific parser pipeline, runtime-owned wrapper/options, reconciliation scheduling, deterministic router-level proof, and compact adopter/runbook documentation; leave all generic Accrue notification code untouched.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Receive `/webhooks/apple` and preserve exact bytes | API / Backend | — | Phoenix router/Plug owns the public HTTP boundary and must pass the captured bytes unchanged. [VERIFIED: codebase `accrue/lib/accrue/router.ex`] |
| Verify JWS trust, bundle, app ID, and environment | API / Backend | Host runtime config | The package verifier consumes host-pinned configuration; runtime config owns deployment values. [VERIFIED: codebase `verifier.ex`, `verifier/production.ex`] |
| Rate-policy decision | API / Backend | CDN / Static | The host callback is the in-process backstop; a deployment edge is the future multi-node authority. [VERIFIED: context D-08] |
| Durable intake, quarantine, and wakeup | Database / Storage | API / Backend | Intake must persist before acknowledgement; locks and constraints, not jobs, establish ownership. [VERIFIED: codebase `notification_plug.ex`, `reconciliation.ex`] |
| Reconciliation scheduling/execution | API / Backend | Database / Storage | Host Oban/Cron enqueues work; checkpoint locks claim durable work. [VERIFIED: codebase `reconciliation_sweeper.ex`, `reconciliation.ex`] |
| Diagnostics and operational response | API / Backend | Browser / Client | Existing authenticated diagnostic surfaces render only safe correlations and next actions. [VERIFIED: context D-10] |
| Live Apple test-notification check | External Apple service | API / Backend | It validates deployed endpoint reachability but is advisory, not deterministic merge proof. [CITED: https://developer.apple.com/documentation/AppStoreServerAPI/Request-a-Test-Notification] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---:|---|---|
| Phoenix / Plug | existing host dependency (`phoenix ~> 1.8.5`) | Router pipeline and body parsing | The existing host and supported Accrue macro are Phoenix/Plug-native. [VERIFIED: codebase `examples/accrue_host/mix.exs`] |
| Accrue | local path dependency | Apple ingress macro, verifier, intake, quarantine, reconciliation workers | This phase wires existing supported seams; no new package is needed. [VERIFIED: codebase `examples/accrue_host/mix.exs`, `accrue/lib/accrue/router.ex`] |
| Oban | existing host dependency | Queue and periodic reconciliation sweep | Existing host uses Oban and Accrue workers already target `:accrue_entitlements`. [VERIFIED: codebase `examples/accrue_host/config/config.exs`, `reconciliation_sweeper.ex`] |
| PostgreSQL/Ecto | existing host stack | Intake/checkpoint persistence and lock-backed correctness | Reconciliation explicitly uses transactions and `FOR UPDATE SKIP LOCKED`. [VERIFIED: codebase `reconciliation.ex`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| `Accrue.Webhook.CachingBodyReader` | local package | Captures exact request bytes in `conn.assigns[:raw_body]` | Only on the dedicated Apple JSON parser pipeline. [VERIFIED: codebase `accrue/guides/webhooks.md`] |
| `Accrue.Entitlements.Apple.Verifier.Production` | local package | Pinned-root JWS verification | Production-only runtime configuration; deterministic tests use a test-local fake verifier. [VERIFIED: codebase `verifier/production.ex`, context D-05] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Host wrapper Plug | Router macro with deployment options embedded at compile time | Contradicts locked runtime ownership and makes fail-fast configuration/identity harder to prove. [VERIFIED: context D-06] |
| Deterministic single-node limiter | Redis/distributed limiter | Explicitly deferred; adds a deployment dependency without improving the reference-host contract. [VERIFIED: context D-08] |
| Route-level host proof | Direct `NotificationPlug` test | Direct tests cannot prove router placement, parser length, or exact raw-body capture. [VERIFIED: context D-11] |

**Installation:** No external package installation. Reuse the checked-in dependencies.

## Architecture Patterns

### System Architecture Diagram

```text
Apple V2 POST (HTTPS)
        |
        v
/webhooks/apple -- dedicated Plug.Parsers pipeline
        |  JSON only + CachingBodyReader + length 262_144
        v
AccrueHost Apple ingress wrapper Plug
        |  fetch immutable runtime options + host rate callback
        v
Accrue.Entitlements.Apple.NotificationPlug
        |-- missing/raw-too-large/malformed/transient --> 503/413/400 (no intake)
        |-- temporary rate denial ------------------------> 429 (retryable pressure)
        |-- verified invalid -----------------------------> durable quarantine --> 200
        '-- verified facts -------------------------------> durable Intake --> 200
                                                           |
                                                           v
                                            reconciliation wakeup row + Oban job
                                                           |
                                                           v
                           :accrue_entitlements / ReconciliationSweeper / locked checkpoint
                                                           |
                                                           v
                                    Apple status/history client -> canonical projection path
```

### Recommended Project Structure

```text
examples/accrue_host/
├── config/
│   ├── config.exs                 # queue and Cron entry
│   └── runtime.exs                # production fail-fast Apple options/client
├── lib/accrue_host/
│   └── apple_notification_ingress.ex # wrapper Plug + deterministic rate policy (exact name discretionary)
├── lib/accrue_host_web/router.ex  # dedicated pipeline and /webhooks/apple mount
├── test/accrue_host_web/
│   └── apple_notification_ingest_test.exs # router boundary proof
└── docs/                          # adoption matrix/runbook wording
```

### Pattern 1: Runtime-owned delegating Plug
**What:** Resolve validated host runtime options once, pass them to the existing plug, and expose no new package surface.

**When to use:** Every request to `/webhooks/apple`; production configuration must be present before startup/request handling rather than supplied inline in `router.ex`.

**Example:**

```elixir
# Source: existing Accrue Router / NotificationPlug contract
defmodule AccrueHost.AppleNotificationIngress do
  @behaviour Plug

  @impl Plug
  def init(_opts), do: []

  @impl Plug
  def call(conn, []) do
    opts = Application.fetch_env!(:accrue_host, :apple_notification_ingress)
    Accrue.Entitlements.Apple.NotificationPlug.call(conn, opts)
  end
end
```

The implementation task must make the configured `:verifier_config` object the same immutable value consumed by the host's Apple admission/reconciliation config, and must fail fast for production inputs. [VERIFIED: context D-04 through D-06]

### Pattern 2: Dedicated raw-body route
**What:** Place the Apple parser pipeline outside all browser and Stripe scopes, and keep parser `:length` equal to the plug's `:max_body_bytes`.

**When to use:** Only `/webhooks/apple`.

**Example:**

```elixir
pipeline :accrue_apple_notifications_raw_body do
  plug Plug.Parsers,
    parsers: [:json], pass: ["*/*"], json_decoder: Jason,
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
    length: 262_144
end

scope "/webhooks" do
  pipe_through :accrue_apple_notifications_raw_body
  forward "/apple", AccrueHost.AppleNotificationIngress
end
```

Use the package macro if it can delegate to the wrapper without compile-time deployment options; do not substitute parsed params for `conn.assigns[:raw_body]`. [VERIFIED: codebase `accrue/lib/accrue/router.ex`, context D-01, D-02, D-06]

### Pattern 3: Fake-first router proof
**What:** Build connections with actual JSON bytes, call `AccrueHostWeb.Router`, and assert response, durable records/jobs, and the fake verifier's byte-exact input.

**When to use:** Valid, duplicate/concurrent, malformed, oversized, rate-denied, transient/missing raw body, quarantine, and privacy checks.

**Example:**

```elixir
conn =
  Plug.Test.conn(:post, "/webhooks/apple", payload)
  |> Plug.Conn.put_req_header("content-type", "application/json")
  |> AccrueHostWeb.Router.call(AccrueHostWeb.Router.init([]))

assert conn.status == 200
# Assert durable Apple intake/wakeup state and FakeVerifier.received_raw_body() == payload.
```

This follows the existing Stripe router proof shape but must assert Apple-domain tables/jobs rather than generic `WebhookEvent`. [VERIFIED: codebase `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs`, context D-11]

### Anti-Patterns to Avoid

- **Sharing the Stripe pipeline:** Its 1 MiB limit violates the public 256 KiB Apple boundary. [VERIFIED: codebase `router.ex`, context D-02]
- **Direct entitlement projection after receipt:** Notification order is not entitlement truth; only durable intake/quarantine may precede acknowledgement. [VERIFIED: context D-03]
- **Embedding runtime trust material in router options/fixtures:** This leaks deployment concerns into compiled route code and risks source exposure. [VERIFIED: context D-04, D-06]
- **Treating Oban uniqueness as a lock:** Wakeup coalescing is not durable ownership; retain database transactions and locks. [VERIFIED: codebase `reconciliation.ex`, context D-07]
- **Using a live Apple test as merge proof:** It is a deployment diagnostic, not credential-free deterministic coverage. [VERIFIED: context D-12]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| JWS/certificate validation | A host JWS verifier | `Accrue.Entitlements.Apple.Verifier.Production` | It already enforces algorithm, pinned roots, certificate policy/time, signature, bundle, environment, and app identity. [VERIFIED: codebase `verifier/production.ex`] |
| Durable Apple intake/quarantine | Host event table/reducer | `NotificationPlug` + `Intake` | Preserves established response classes, idempotency, quarantine, and wakeup behavior. [VERIFIED: codebase `notification_plug.ex`] |
| Reconciliation worker | A host-specific polling loop | Existing `ReconciliationSweeper`, `ReconciliationWakeupWorker`, and `ReconcileWorker` | Existing transaction/lock semantics prevent duplicate ownership. [VERIFIED: codebase `reconciliation*.ex`] |
| Distributed throttling | Redis/rate-limit dependency | Small host local callback plus deployment edge policy | Distributed enforcement is explicitly deferred. [VERIFIED: context D-08] |

**Key insight:** Phase 221 is an integration seam. Reimplementing any package behavior would make the reference host a divergent second contract and undermine its value as an adoption recipe.

## Common Pitfalls

### Pitfall 1: Acknowledging before a durable terminal outcome
**What goes wrong:** A 2xx response tells Apple that delivery succeeded even though the host has no durable intake/quarantine record.

**Why it happens:** Confusing transport acknowledgement with entitlement projection or asynchronous job completion.

**How to avoid:** Assert `200` only after `NotificationPlug` returns a verified/duplicate/quarantined durable disposition; return `503` for raw-body, verifier/config, or persistence failures. [VERIFIED: codebase `notification_plug.ex`, context D-03, D-09]

**Warning signs:** Router tests observe 200 with zero intake/quarantine rows or zero reconciliation wakeups.

### Pitfall 2: Losing byte identity in parsing
**What goes wrong:** Verification runs on JSON re-encoding or parsed parameters rather than the incoming byte sequence.

**Why it happens:** Reusing a generic API/browser pipeline or inspecting `conn.params` as verifier input.

**How to avoid:** Use `CachingBodyReader`, test exact fake-verifier input equality, and make parser limit and plug maximum both 262,144. [VERIFIED: codebase `accrue/guides/webhooks.md`, context D-01, D-02]

### Pitfall 3: Environment/trust configuration drifts across paths
**What goes wrong:** Notification ingress verifies one bundle/environment/root set while purchase/restore or reconciliation uses another.

**Why it happens:** Independently constructed per-path keyword lists.

**How to avoid:** Construct one immutable runtime verifier config and inject that same value into ingress and `:apple_reconciliation` admission. A production reference route must remain production-only. [VERIFIED: context D-04, D-05]

### Pitfall 4: Rate limiting becomes a security/correctness authority
**What goes wrong:** A process-local limiter is portrayed as shared enforcement, or a rate denial is treated as a terminal invalid notification.

**Why it happens:** A reference host’s local implementation is mistaken for deployment-scale infrastructure.

**How to avoid:** Key the local deterministic limiter on normalized trusted peer identity, return `{:deny, seconds}` only for temporary pressure, document the edge/shared policy limitation, and never add Redis here. [VERIFIED: context D-08, D-09]

### Pitfall 5: Proof bypasses the missing boundary
**What goes wrong:** Tests directly call `observe_apple_evidence/2` or `NotificationPlug`, so an absent/wrong router pipeline still passes.

**Why it happens:** Existing scenario conformance is semantic but is not an HTTP ingress test.

**How to avoid:** Add router-level tests to the bounded host verification alias and cover route/pipeline/raw-body/response behavior plus durable state. [VERIFIED: codebase `reference_scenario_conformance_test.exs`, `accrue_host_verify_test_bounded.sh`; context D-11]

## Code Examples

### Production fail-fast configuration shape

```elixir
# Source: existing host runtime config pattern + Apple Verifier.Config contract
if config_env() == :prod do
  verifier_config = %Accrue.Entitlements.Apple.Verifier.Config{
    roots: load_pinned_apple_roots!(),
    bundle_id: System.fetch_env!("APPLE_BUNDLE_ID"),
    app_apple_id: System.fetch_env!("APPLE_APP_ID"),
    environment: :production,
    verifier_version: "apple-production-v1",
    config_version: System.fetch_env!("APPLE_VERIFIER_CONFIG_VERSION")
  }

  config :accrue_host, :apple_notification_ingress,
    verifier_config: verifier_config,
    rate_limiter: &AccrueHost.AppleRatePolicy.check/1

  config :accrue, :apple_reconciliation,
    client: Accrue.Entitlements.Apple.Client.Production.new(
      authorization: System.fetch_env!("APPLE_SERVER_API_TOKEN")
    ),
    admission: [
      verifier: Accrue.Entitlements.Apple.Verifier.Production,
      verifier_config: verifier_config,
      product_map: configured_apple_product_map!(),
      verifier_version: "apple-production-v1",
      config_version: System.fetch_env!("APPLE_VERIFIER_CONFIG_VERSION")
    ]
end
```

The exact env-key names, root-loading mechanism, product map, and module names remain discretionary; the plan must ensure the source does not contain roots, credentials, payloads, or private key material. [VERIFIED: codebase `examples/accrue_host/config/runtime.exs`, `verifier.ex`, `reconcile_worker.ex`; context D-04]

### Reconciliation configuration

```elixir
# Source: `accrue/guides/entitlements.md`
config :accrue_host, Oban,
  queues: [
    # preserve existing queues; add, do not replace
    accrue_entitlements: 10
  ],
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       # preserve existing cron entries; append this entry
       {"*/15 * * * *", Accrue.Entitlements.Apple.ReconciliationSweeper}
     ]}
  ]
```

The implementation must append to the existing queue and Cron configuration, then add a configuration test that proves both existing and Apple entries remain. [VERIFIED: codebase `examples/accrue_host/config/config.exs`, `accrue/guides/entitlements.md`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| App Store Server Notifications V1 | V2 HTTPS endpoint with signed payload | Apple labels V1 deprecated in its current docs | Implement and document V2 only; do not add V1 compatibility. [CITED: https://developer.apple.com/documentation/AppStoreServerNotifications] |
| Direct semantic Apple scenario | Router-level deterministic ingress proof | Phase 221 gap | Preserve semantic corpus, add host-boundary proof as the merge authority for this recipe. [VERIFIED: codebase `reference_scenario_conformance_test.exs`, context D-11] |

**Deprecated/outdated:** App Store Server Notifications V1 is deprecated by Apple; do not expand the reference host toward it. [CITED: https://developer.apple.com/documentation/AppStoreServerNotifications]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | A process-local fixed-window or token-bucket limiter is suitable as a deterministic reference-host backstop once trusted peer normalization is specified. | Architecture Patterns | The chosen API/semantics could be unsuitable for test determinism; implementation should select and document the exact algorithm. [ASSUMED] |

## Open Questions

1. **Which deterministic verifier fixture mechanism best proves byte identity without introducing sensitive-like signed samples?**
   - What we know: The host can use a fake verifier and existing tests already mutate app config for host-local fakes. [VERIFIED: codebase `reference_scenario_conformance_test.exs`]
   - What's unclear: Whether an existing safe fixture can be reused or a purpose-built test fake should capture bytes in a supervised process/Agent.
   - Recommendation: Use a purpose-built test fake with opaque synthetic JSON and a minimal captured-byte assertion unless a current fixture exactly meets the privacy rule.

2. **What is the exact trusted peer identity contract behind a proxy?**
   - What we know: D-08 permits a single-node backstop only when keyed from trusted peer identity. [VERIFIED: context D-08]
   - What's unclear: Which proxy/forwarded-header trust configuration the reference deployment guarantees.
   - Recommendation: Define a conservative direct-peer default for the reference host and document that production proxy normalization is host/deployment configuration, not an Apple header claim.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir/Mix | Host compilation and tests | ✓ | Mix 1.19.5 / OTP 28 | — |
| PostgreSQL | Ecto + router integration proof | ✓ | accepting on `/tmp:5432` | — |
| Docker | Optional local infrastructure workflow | ✓ | Client 29.5.2 | Native PostgreSQL is available |
| Redis | No requirement | ✓ | responds `PONG` | Do not use; distributed limiting is out of scope |
| Apple App Store credentials/endpoint | Advisory deployment test only | not probed | — | Deterministic fake-backed test is merge-blocking |

**Missing dependencies with no fallback:** None for merge-blocking implementation/proof.

**Missing dependencies with fallback:** Live App Store access is intentionally advisory; deterministic host proof is the required fallback. [VERIFIED: context D-12]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit (Elixir/Mix host project) |
| Config file | `examples/accrue_host/config/test.exs` |
| Quick run command | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host_web/apple_notification_ingest_test.exs --warnings-as-errors` |
| Full suite command | `cd examples/accrue_host && mix verify` |

### Phase Requirements → Test Map

Phase requirement IDs are TBD; map the following locked behaviors into the plan's acceptance criteria.

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| D-01/D-02 | Dedicated route, no browser/Stripe pipeline, exact raw bytes, 256 KiB boundary | Router integration | focused Apple ingress test | ❌ Wave 0 |
| D-03/D-09 | Correct `200` only after durable intake/quarantine; all response classes | Router + persistence integration | focused Apple ingress test | ❌ Wave 0 |
| D-04/D-05/D-06 | Shared runtime verifier config/wrapper and production fail-fast source contract | Configuration/unit | focused Apple ingress/config test | ❌ Wave 0 |
| D-07 | Queue/Cron/reconciliation configuration and durable wakeup | Config + persistence integration | focused Apple ingress/config test | ❌ Wave 0 |
| D-08 | Deterministic temporary rate denial only | Unit + router integration | focused Apple ingress test | ❌ Wave 0 |
| D-10/D-13 | Privacy-safe documentation and literal verification recipe | Static documentation contract | existing/adapted CI script | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** focused Apple ingress test and formatter.
- **Per wave merge:** `cd examples/accrue_host && mix verify`.
- **Phase gate:** `mix verify` green plus the repository documentation-contract gate(s) updated for README/adoption-matrix wording.

### Wave 0 Gaps

- [ ] `examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs` — router-level coverage for all D-11 cases.
- [ ] Add that file to `scripts/ci/accrue_host_verify_test_bounded.sh` so `mix verify` is the literal local command.
- [ ] A test-safe host Apple configuration/fake verifier helper — prevents use of production roots/credentials or raw signed payload fixtures.
- [ ] A static config wiring test or assertions in the ingress integration test — preserves existing Oban queues/Cron entries while adding Apple resources.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | yes | Cryptographically verify Apple's signed JWS against pinned roots before durable verified intake. [VERIFIED: codebase `verifier/production.ex`] |
| V3 Session Management | no | Route must not enter browser/session/auth pipelines. [VERIFIED: context D-01] |
| V4 Access Control | yes | Keep diagnostics authenticated; webhook itself authenticates the provider evidence, not a browser user. [VERIFIED: context D-03, D-10] |
| V5 Input Validation | yes | Parser size cap, exact captured raw body, bounded IDs, strict verifier claims. [VERIFIED: codebase `notification_plug.ex`, `verifier/production.ex`] |
| V6 Cryptography | yes | Use the existing verifier's ES256/x5c/pinned-root validation; never implement crypto in host code. [VERIFIED: codebase `verifier/production.ex`] |

### Known Threat Patterns for Phoenix/Apple ingress

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Forged/replayed malformed notification | Spoofing/Tampering | Verify signed bytes before verified intake; invalid evidence enters only bounded durable quarantine. [VERIFIED: codebase `notification_plug.ex`] |
| Parser expansion/body exhaustion | Denial of Service | Dedicated 262,144-byte parser and matching plug cap; temporary local backpressure. [VERIFIED: context D-01, D-08] |
| Cross-environment or wrong-app evidence | Tampering | Pinned roots plus bundle, environment, and production-app identity checks from one host config. [VERIFIED: codebase `verifier/production.ex`, context D-04] |
| Raw evidence leakage | Information Disclosure | No raw JWS/payloads/certs/tokens/PII in tests, logs, telemetry, diagnostics, or docs. [VERIFIED: context D-04, D-10] |
| Duplicate concurrent delivery | Tampering/Denial of Service | Let intake constraints and PostgreSQL locks own correctness; Oban only coalesces work. [VERIFIED: context D-07, D-11] |

## Sources

### Primary (HIGH confidence)
- [Accrue router macro and host router](../../../../accrue/lib/accrue/router.ex) - dedicated raw-body contract and current missing host route.
- [Apple notification plug](../../../../accrue/lib/accrue/entitlements/apple/notification_plug.ex) - response classes, durable intake/quarantine, and telemetry boundary.
- [Apple reconciliation](../../../../accrue/lib/accrue/entitlements/apple/reconciliation.ex) - transaction/lock-backed wakeup and scheduling behavior.
- [Reference host configuration](../../../../examples/accrue_host/config/config.exs) - existing queue/Cron append point.
- [Reference host webhook proof](../../../../examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs) - router-level proof precedent.

### Secondary (MEDIUM confidence)
- [Accrue webhook guide](../../../../accrue/guides/webhooks.md) - exact Apple parser and raw-body setup.
- [Accrue entitlements guide](../../../../accrue/guides/entitlements.md) - host-owned reconciliation setup and database authority.
- [Apple: Responding to App Store Server Notifications](https://developer.apple.com/documentation/AppStoreServerNotifications/responding-to-app-store-server-notifications) - HTTPS/response/retry behavior.
- [Apple: Request a Test Notification](https://developer.apple.com/documentation/AppStoreServerAPI/Request-a-Test-Notification) - advisory deployed-endpoint testing.

### Tertiary (LOW confidence)
- None beyond the explicitly logged local-limiter algorithm choice.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all required components are existing checked-in dependencies and public package seams.
- Architecture: HIGH - the CONTEXT locks host/package ownership and the existing source precisely defines each handoff.
- Pitfalls: HIGH - driven by explicit existing response behavior, persistent locks, and Apple’s official retry guidance.

**Research date:** 2026-08-05
**Valid until:** 2026-09-04 for the stable internal contract; reconfirm Apple delivery documentation before production deployment.
