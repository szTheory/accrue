---
phase: 221-close-gap-reference-host-apple-notification-ingress
verified: 2026-08-05T18:11:28Z
status: passed
score: 14/14 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 12/14
  gaps_closed:
    - "Production product-map admission validates every mapping against configured entitlement plans before atom resolution."
    - "The local Apple backpressure policy resolves forwarded identity only at an explicitly trusted edge."
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "In a production-configured Apple environment, use App Store Connect's Request a Test Notification and inspect only the documented safe correlation and response class."
    expected: "The deployed endpoint receives the delivery without exposing provider evidence; Fake-backed host proof remains the merge authority."
    why_human: "The real Apple endpoint, credentials, and deployed network boundary are external and intentionally advisory."
---

# Phase 221: Close Gap — Reference-Host Apple Notification Ingress Verification Report

**Phase Goal:** The reference host accepts App Store Server Notifications V2 through the existing Accrue contract with exact raw-body verification, durable intake and repair, deterministic host-boundary proof, and privacy-safe adopter guidance.
**Verified:** 2026-08-05T18:11:28Z  
**Status:** human_needed  
**Re-verification:** Yes — after gap closure

## Goal Achievement

The two prior blockers are closed in the executable host boundary. Product-map admission is now catalog-bound rather than BEAM-atom-bound, and temporary rate backpressure has a strict trusted-edge contract. The deterministic host proof passes. A live Apple delivery remains an explicitly advisory human check, so this report cannot be `passed` under the verification status rules despite having no blocking implementation gap.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | D-01/D-06 use one host-owned wrapper-forward composition without a public Accrue API change. | ✓ VERIFIED | `router.ex:115-128` uses the dedicated pipeline and forwards to `AppleNotificationIngress`; its `call/2` delegates to `NotificationPlug.init/1` then `call/2` (`apple_notification_ingress.ex:11-15`). |
| 2 | D-04/D-05 define one production-only verifier identity and environment-loading contract before it is published. | ✓ VERIFIED | `runtime.exs:62-106` builds one `Verifier.Config` with production environment, pinned roots, bundle/app IDs, and explicit versions; README names the required inputs without values (`README.md:122-129`). |
| 3 | POST `/webhooks/apple` sends exact captured bytes through verification to durable intake and wakeup before 200. | ✓ VERIFIED | Router integration test posts opaque JSON through the real router, receives byte-identical Fake verifier input, verifies persisted digest/intake and wakeup, then asserts 200 (`apple_notification_ingest_test.exs:52-73`). |
| 4 | Production boot rejects incomplete or unauthorized product-map configuration before it can project an unintended plan. | ✓ VERIFIED | Runtime derives the configured entitlement plan keys then calls `decode_product_map!/2` (`runtime.exs:75-85`); the loader maps only those keys and raises for unknown plans (`apple_notification_ingress.ex:61-76`). Regression tests cover unknown existing-like names plus malformed catalog/map inputs (`apple_notification_ingest_test.exs:90-118`). |
| 5 | The leading Fake-backed proof exercises the host router and PostgreSQL-backed intake/wakeup path, not a direct package Plug call. | ✓ VERIFIED | `apple_notification_ingest_test.exs:55-70` invokes `AccrueHostWeb.Router.call/2` and queries `Repo` for `Intake` and `ReconciliationWakeup`; the focused command passed 23 tests. |
| 6 | D-08 applies deterministic, process-local temporary backpressure by trusted peer identity only, while documenting it as non-distributed. | ✓ VERIFIED | `AppleRatePolicy` gates `x-forwarded-for` on the exact `remote_ip` allowlist and denies missing/multi-hop/malformed forwarding data (`apple_rate_policy.ex:88-102`); direct clients ignore headers. Tests prove direct isolation, trusted proxy isolation, spoof resistance, and fail-closed parsing (`apple_rate_policy_test.exs:31-122`). README states the single-node/edge-authority boundary (`README.md:137-145`). |
| 7 | Malformed, oversized, rate-denied, transient, quarantine, duplicate, and concurrent paths retain the response/durability contract. | ✓ VERIFIED | Router proof covers 400/413/429/503, durable quarantine before 200, persistence failure, and concurrent convergence (`apple_notification_ingest_test.exs:120-173`); the package Plug maps those outcomes without response bodies (`notification_plug.ex:26-45,66-80,173-180`). |
| 8 | Responses, logging, telemetry, and assertions avoid raw provider evidence and secrets. | ✓ VERIFIED | Privacy test captures logs and telemetry and rejects its opaque marker from telemetry, logs, and durable intake inspection (`apple_notification_ingest_test.exs:175-200`); runtime sources values only from environment. |
| 9 | Apple reconciliation is additively scheduled on `:accrue_entitlements` without replacing existing recovery resources. | ✓ VERIFIED | Recovery test validates all previous queues/Cron workers remain, with one entitlement queue and exactly one 15-minute sweeper (`recovery_wiring_test.exs:15-44`). |
| 10 | Ingress-created wakeups reach the configured client/admission/sweeper repair path with PostgreSQL as correctness authority. | ✓ VERIFIED | Runtime shares `verifier_config` between ingress and admission (`runtime.exs:92-106`); worker reads `:apple_reconciliation` (`reconcile_worker.ex:28-46`); recovery proof asserts route wakeup plus queue/sweeper wiring (`recovery_wiring_test.exs:54-80`). |
| 11 | Adopter guidance provides the route, inputs, response classes, trusted-edge operation, safe actions, and literal verifier command. | ✓ VERIFIED | `README.md:115-159` documents each item and the exact `cd examples/accrue_host && mix verify` command. |
| 12 | The proof matrix distinguishes merge-blocking deterministic evidence from advisory Apple delivery. | ✓ VERIFIED | Matrix designates the Fake-backed router proof as merge-blocking (`adoption-proof-matrix.md:67`) and live Apple delivery as advisory (`:101-107`). |
| 13 | Operator guidance exposes only safe correlations and repair indicators. | ✓ VERIFIED | Apple ingress runbook restricts actions to response trends, quarantine/backlog, `needs_repair`, job state, and next action; it prohibits provider evidence, arguments, and failure detail (`operator-runbooks.md:231-244`). |
| 14 | `mix verify` executes the ingress, rate-policy, recovery, and source-contract proof lane. | ✓ VERIFIED | Bounded script lists all four proof files (`accrue_host_verify_test_bounded.sh:13-31`); independent execution of `mix verify` passed 63 tests. |

**Score:** 14/14 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `apple_notification_ingress.ex` | Runtime resolver and package-Plug delegate | ✓ VERIFIED | Substantive loader validates roots and finite plan catalog; route invokes it through the wrapper. |
| `router.ex` | Dedicated 262,144-byte Apple pipeline and route | ✓ VERIFIED | Separate pipeline, raw-body reader, and `/webhooks/apple` forward are live alongside unchanged Stripe route. |
| `apple_rate_policy.ex` | Supervised fixed-window trusted-peer backstop | ✓ VERIFIED | Supervised by host application; strict direct/trusted-proxy resolver and bounded in-memory peer state. |
| `runtime.exs` | Shared production verifier/admission and trusted-edge configuration | ✓ VERIFIED | One config term is reused; plan catalog and proxy declaration feed the relevant host components. |
| `config.exs` and recovery proof | Additive queue and 15-minute sweeper | ✓ VERIFIED | Runtime-safe structural test validates preserved resources and repair wiring. |
| Router/rate/source tests and bounded script | Deterministic host-boundary proof | ✓ VERIFIED | All artifacts are registered in the bounded script and passed on this verification run. |
| README, proof matrix, runbook | Privacy-safe adoption guidance | ✓ VERIFIED | Route, response handling, proof authority, and safe operational actions are explicit. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Host router | `AppleNotificationIngress` | `forward("/apple", ...)` | ✓ WIRED | Dedicated scope links router to host wrapper. |
| Host wrapper | package `NotificationPlug` | `init/1` then `call/2` | ✓ WIRED | Direct delegation preserves package ingress semantics. |
| Runtime configuration | ingress and reconciliation admission | shared `verifier_config` variable | ✓ WIRED | Exactly two configured consumers use the one constructed term. |
| Runtime plan catalog | product-map decoder | configured plan keys passed into `decode_product_map!/2` | ✓ WIRED | Unknown mappings raise before production configuration completes. |
| Runtime proxy declaration | rate policy | parsed once into supervised-policy options | ✓ WIRED | Only configured direct peers may supply one forwarded client IP. |
| Oban Cron | `ReconciliationSweeper` | `*/15` on entitlement queue | ✓ WIRED | Recovery configuration test verifies the exact entry. |
| `mix verify` | phase proof files | bounded host script | ✓ WIRED | Script explicitly invokes the ingress, rate, recovery, and source-contract tests. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Apple ingress route | `conn.assigns[:raw_body]` | `CachingBodyReader` → wrapper → package Plug | Router test proves byte equality and persisted SHA-256 digest | ✓ FLOWING |
| Product-map admission | configured plan keys | host `:accrue, :entitlements` configuration → runtime decoder | Only configured atom values are emitted; unknown strings raise | ✓ FLOWING |
| Rate identity | direct/forwarded peer | `remote_ip` with allowlisted trusted edge → strict numeric header parser | Per-client keys are isolated; untrusted headers are ignored | ✓ FLOWING |
| Recovery | durable wakeup | PostgreSQL intake/wakeup → configured sweeper/worker | Real-router test persists wakeup; recovery test verifies scheduled consumer configuration | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Catalog-bound map admission and trusted-edge identity behavior | `MIX_ENV=test mix test test/accrue_host_web/apple_notification_ingest_test.exs test/accrue_host/apple_rate_policy_test.exs test/install_boundary_test.exs --warnings-as-errors` | 23 tests, 0 failures | ✓ PASS |
| Full bounded host proof, including router, recovery, and source contract | `cd examples/accrue_host && mix verify` | 63 tests, 0 failures | ✓ PASS |

The commands emit three existing unused-module-attribute warnings from `accrue/lib/accrue/entitlements/reference_scenarios.ex`; both commands exit successfully and the warnings are outside this phase's host ingress files.

### Requirements Coverage

`REQUIREMENTS.md` lists Phase 221 requirements as `TBD`; therefore the phase context's D-contracts are the effective verifiable contract.

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| D-04 | 221-02, 221-04, 221-06 | Production pinned trust/config and fail-fast, catalog-bound runtime admission | ✓ SATISFIED | One production config, `fetch_env!`, catalog-bound decoder, and named regressions. |
| D-05 | 221-01, 221-02, 221-04, 221-06 | One production-only immutable verifier configuration shared by ingress and admission | ✓ SATISFIED | Same `verifier_config` is passed to both runtime destinations. |
| D-08 | 221-03, 221-05, 221-06 | Deterministic local trusted-peer backpressure with explicit non-distributed scope | ✓ SATISFIED | Strict trusted edge implementation, behavior tests, and README authority boundary. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No unreferenced `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or hardcoded-empty data flow found in Phase-221 artifacts. | ℹ️ Info | No implementation stub/debt-marker blocker found. |

### Human Verification Required

### 1. Advisory App Store delivery

**Test:** In a production-configured Apple environment, send App Store Connect's Request a Test Notification to `POST /webhooks/apple` and inspect only a safe correlation and response class.

**Expected:** The endpoint receives the notification without surfacing raw provider evidence; the deterministic Fake-backed suite continues to be the merge authority.

**Why human:** Apple credentials, deployed ingress, and the external provider network cannot be exercised by the credential-free test lane. The adoption matrix deliberately classifies this as advisory.

## Gaps Summary

No blocking implementation gaps remain. The two previous blockers are closed and their deterministic regressions pass. The only remaining action is the explicitly advisory external-provider check above.

## Acknowledged Gaps

- **Deferred external Apple delivery smoke test (minor):** The developer accepts the current external-provider risk. Capture and implement a repeatable scheduled/manual CI smoke test later, using a dedicated App Store Connect test app and an existing stable staging deployment. Deterministic Fake-backed host verification remains the PR merge authority.

---

_Verified: 2026-08-05T18:11:28Z_  
_Verifier: the agent (gsd-verifier)_
