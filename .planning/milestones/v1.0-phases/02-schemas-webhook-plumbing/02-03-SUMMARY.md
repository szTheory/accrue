---
phase: 02-schemas-webhook-plumbing
plan: 03
subsystem: webhooks
tags: [plug, webhooks, signature-verification, raw-body, router-macro, security]

# Dependency graph
requires:
  - phase: 01-foundations
    provides: Error hierarchy (Accrue.SignatureError), Config module
  - plan: 02-01
    provides: WebhookEvent schema, migrations
provides:
  - Scoped raw-body capture via CachingBodyReader
  - Webhook signature verification wrapper (Accrue.Webhook.Signature)
  - Lean webhook Event struct with LatticeStripe projection
  - Router macro for mounting webhook endpoints
  - Webhook Plug with telemetry-instrumented signature verification
affects: [02-04, 02-05, phase-03, phase-07]

# Tech tracking
tech-stack:
  added: ["plug ~> 1.16 (explicit hard dep)", "phoenix ~> 1.8 (optional dep)"]
  patterns: [CachingBodyReader body_reader hook, Plug behaviour for webhook ingestion, telemetry.span wrapping, multi-secret rotation via lattice_stripe delegation]

key-files:
  created:
    - accrue/lib/accrue/webhook/caching_body_reader.ex
    - accrue/lib/accrue/webhook/signature.ex
    - accrue/lib/accrue/webhook/event.ex
    - accrue/lib/accrue/webhook/plug.ex
    - accrue/lib/accrue/router.ex
    - accrue/test/accrue/webhook/plug_test.exs
  modified:
    - accrue/mix.exs
    - accrue/lib/accrue/config.ex

key-decisions:
  - "Event.type kept as String.t() in struct; atom conversion deferred to handler dispatch in Plan 04"
  - "Plug stores verified LatticeStripe.Event in conn.private[:accrue_verified_event] for Plan 04 Ingest"
  - "webhook_signing_secrets config key added to Accrue.Config with per-processor map lookup"
  - "Plug sends temporary 200 response; Plan 04 replaces with transactional persist+enqueue"

patterns-established:
  - "CachingBodyReader: prepend chunks (O(1)), reverse+flatten at verification time"
  - "Signature module: zero crypto code, pure delegation to lattice_stripe with error re-raise"
  - "Router macro: accrue_webhook/2 expands to forward, host owns pipeline"

requirements-completed: [WH-01, WH-02, WH-14]

# Metrics
duration: 4min
completed: 2026-04-12
---

# Phase 02 Plan 03: Webhook Plug Pipeline Summary

**Scoped raw-body capture, timing-safe signature verification via lattice_stripe delegation, lean event projection, and router macro -- the security boundary between Stripe and Accrue with 6 passing integration tests**

## What Was Built

### CachingBodyReader (accrue/lib/accrue/webhook/caching_body_reader.ex)

Custom `Plug.Parsers` `body_reader:` hook per D2-19. Tees raw request body chunks into `conn.assigns[:raw_body]` as a prepended iolist for O(1) streaming performance. Only used inside the `:accrue_webhook_raw_body` pipeline -- never globally (WH-01). The host's global `Plug.Parsers` in `MyAppWeb.Endpoint` remains untouched.

### Signature (accrue/lib/accrue/webhook/signature.ex)

Pure delegation wrapper around `LatticeStripe.Webhook.construct_event!/4`. Accrue writes zero HMAC code -- lattice_stripe handles timing-safe compare via `Plug.Crypto.secure_compare/2`, 300s replay tolerance, and multi-secret rotation. On failure, `LatticeStripe.Webhook.SignatureVerificationError` is re-raised as `Accrue.SignatureError` per Phase 1 D-08.

### Event (accrue/lib/accrue/webhook/event.ex)

Lean struct per D2-29: `type` (String.t), `object_id`, `livemode`, `created_at`, `processor_event_id`, `processor`. Deliberately excludes the raw Stripe payload to force WH-10 compliance (handlers must re-fetch canonical state). `from_stripe/2` projects from `%LatticeStripe.Event{}` using string-key access on the `data` map.

### Webhook Plug (accrue/lib/accrue/webhook/plug.ex)

Core `@behaviour Plug` module (D2-26). Pipeline: extract raw body -> verify signature -> project event -> store in `conn.private` -> respond. Wrapped in `:telemetry.span([:accrue, :webhook, :receive], ...)`. Signature failures rescue to HTTP 400 with `{"error": "signature_verification_failed"}`. Currently sends a temporary 200 response -- Plan 04 replaces the final section with `Accrue.Webhook.Ingest.run/4` for transactional persist + Oban enqueue.

### Router (accrue/lib/accrue/router.ex)

`accrue_webhook/2` macro per D2-16. Expands to `forward path, Accrue.Webhook.Plug, processor: processor`. Multi-endpoint ready for Phase 4 Connect (D2-18). Host imports `Accrue.Router` and owns the pipeline with `Plug.Parsers` + `body_reader:` configuration.

### Config Updates (accrue/lib/accrue/config.ex)

Added `webhook_signing_secrets` config key (map of processor atom to string or list of strings) and `webhook_signing_secrets/1` convenience function with per-processor lookup and clear error on missing config.

### mix.exs Updates

Added `{:plug, "~> 1.16"}` as hard dep (webhook modules use `Plug.Conn`, `Plug.Builder`). Added `{:phoenix, "~> 1.8", optional: true}` for Router macro's `forward/3` when Phoenix is loaded.

### Integration Tests (6 tests, all passing)

| Test | Description | Threat/Requirement |
|------|-------------|-------------------|
| 1 | Valid signature returns 200 | T-2-01 |
| 2 | Tampered body returns 400 | T-2-01 |
| 3 | Rotation: signed with secret_b, secrets=[a,b] returns 200 | T-2-05 |
| 4 | Raw body populated in assigns + verified event in private | T-2-02 |
| 5 | Non-webhook route has no raw_body (scoping) | WH-01 |
| 6 | Missing stripe-signature header returns 400 | D2-26 |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing] Added webhook_signing_secrets to Accrue.Config**
- **Found during:** Task 1
- **Issue:** The Plug calls `Accrue.Config.webhook_signing_secrets(processor)` but no such config key or function existed in the Config module.
- **Fix:** Added `webhook_signing_secrets` key to the NimbleOptions schema and a `webhook_signing_secrets/1` convenience function with per-processor map lookup and clear error messaging.
- **Files modified:** accrue/lib/accrue/config.ex
- **Commit:** 7e99fd3

**2. [Rule 1 - Bug] Event struct uses string-key access for LatticeStripe.Event.data**
- **Found during:** Task 1 implementation
- **Issue:** Plan's `from_stripe/2` example used atom-key access (`get_in(stripe_event, [:data, :object, :id])`) but `LatticeStripe.Event.from_map/1` stores `data` as a raw map with string keys from `Jason.decode!/1`.
- **Fix:** Used pattern match `%{"object" => %{"id" => id}}` on `stripe_event.data` instead.
- **Files modified:** accrue/lib/accrue/webhook/event.ex
- **Commit:** 7e99fd3

**3. [Rule 1 - Bug] Plug version pinned to ~> 1.16 instead of ~> 1.19**
- **Found during:** Task 1
- **Issue:** Plan specified `{:plug, "~> 1.19"}` but the `body_reader` feature has been stable since Plug 1.16+. Using `~> 1.16` is more compatible and matches the RESEARCH.md note that the pattern is "stable across Plug 1.16+".
- **Fix:** Used `~> 1.16` for broader compatibility.
- **Files modified:** accrue/mix.exs
- **Commit:** 7e99fd3

## Verification

- `mix compile --warnings-as-errors` exits 0
- `mix test test/accrue/webhook/plug_test.exs` exits 0 (6 tests, 0 failures)
- Tampered body returns 400 (T-2-01)
- Rotation secrets accepted (T-2-05)
- Raw-body capture scoped to webhook pipeline only (WH-01)
- Missing signature header returns 400

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 7e99fd3 | Webhook plug pipeline modules (CachingBodyReader, Signature, Event, Router) + deps |
| 2 (RED) | 0133d7d | Failing webhook plug integration tests |
| 2 (GREEN) | 4d7ec4b | Implement Accrue.Webhook.Plug, all 6 tests pass |

## Self-Check: PASSED

- All 6 created files: FOUND
- Commit 7e99fd3: FOUND
- Commit 0133d7d: FOUND
- Commit 4d7ec4b: FOUND
