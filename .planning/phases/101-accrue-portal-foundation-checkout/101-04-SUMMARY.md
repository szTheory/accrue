---
phase: 101-accrue-portal-foundation-checkout
plan: 04
subsystem: checkout
tags: [braintree, hosted-fields, liveview, portal]
requires:
  - phase: 101-03
    provides: local portal billing facade and Braintree adapter semantics
  - phase: 101-07
    provides: package-local portal test harness and Braintree client-token stub
provides:
  - Hosted Fields checkout UI on the mounted portal route
  - nonce-only browser-to-LiveView tokenization contract
  - focused checkout LiveView regression coverage
affects: [101-08, accrue_portal]
tech-stack:
  added: [none]
  patterns: [Hosted Fields LiveView hook, pinned CDN SRI tags, package-local LiveView checkout proof]
key-files:
  created: [accrue_portal/lib/accrue_portal/copy.ex, accrue_portal/test/accrue_portal/live/checkout_live_test.exs]
  modified: [accrue_portal/lib/accrue_portal/assets.ex, accrue_portal/lib/accrue_portal/layouts.ex, accrue_portal/lib/accrue_portal/live/checkout_live.ex, accrue_portal/lib/accrue_portal/router.ex, accrue_portal/priv/static/accrue_portal.css, accrue_portal/priv/static/accrue_portal.js]
key-decisions:
  - "Boot the portal's own Phoenix and LiveView assets from package-owned hashed routes so the checkout page can run independently from any host asset pipeline."
  - "Keep the Braintree trust boundary explicit by posting only the payment-method nonce back to LiveView and never persisting a hidden PAN/CVV input."
  - "Centralize customer-facing checkout strings in AccruePortal.Copy so later portal screens reuse the same voice and CTA contract."
patterns-established:
  - "Portal checkout hooks push a single LiveView event with `%{nonce: ...}` and keep tokenize failures inside the LiveView surface."
  - "Pinned Braintree CDN tags with SRI live directly in the checkout LiveView render contract and are regression-tested package-locally."
requirements-completed: [BT-02]
completed: 2026-05-02
---

# Phase 101 Plan 04: Hosted checkout flow Summary

**The portal now ships a real Braintree Hosted Fields checkout flow with pinned CDN assets, nonce-only LiveView submission, and focused package-local regression coverage.**

## Performance

- **Completed:** 2026-05-02T14:43:02Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Replaced the prototype checkout form with a Hosted Fields LiveView surface that renders the locked CTA/copy contract, inline failure states, expired-session behavior, and SRI-pinned Braintree CDN scripts.
- Added package-owned `phoenix` and `phoenix_live_view` static asset serving so the mounted portal can boot its LiveView hook without leaning on host app bundles.
- Added `AccruePortal.Copy` and a focused `checkout_live_test.exs` suite that proves Hosted Fields placeholders, nonce-only submission, expiry/not-found handling, and inline tokenization errors.

## Files Created/Modified

- `accrue_portal/lib/accrue_portal/copy.ex` - centralized checkout page copy and error strings.
- `accrue_portal/lib/accrue_portal/live/checkout_live.ex` - Hosted Fields LiveView flow, nonce-only subscription handoff, expired-session handling, and pinned Braintree script tags.
- `accrue_portal/priv/static/accrue_portal.js` - LiveView Hosted Fields hook, tokenize-to-nonce push event, and submit-button state handling.
- `accrue_portal/priv/static/accrue_portal.css` - checkout-specific layout, field, and inline error styling.
- `accrue_portal/test/accrue_portal/live/checkout_live_test.exs` - focused LiveView regression coverage for the checkout contract.
- `accrue_portal/lib/accrue_portal/assets.ex` - hashed package-local `phoenix` and `phoenix_live_view` asset routes.
- `accrue_portal/lib/accrue_portal/layouts.ex` - package-local Phoenix/LiveView script includes.
- `accrue_portal/lib/accrue_portal/router.ex` - hashed asset route exposure and session wiring for the added scripts.

## Decisions Made

- The checkout page now owns its own Phoenix and LiveView runtime assets via hashed package-local routes; relying on a host app bundle would make the mounted package contract too implicit.
- The browser hook tokenizes card data entirely inside Braintree-controlled iframes and sends only the nonce back to LiveView, even if extra fields are present in the client event payload.
- Missing checkout tokens redirect straight back to the portal root rather than attempting a flash write from a pipeline that has not fetched flash.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed missing checkout script assigns in the LiveView render**
- **Found during:** Task 2 verification
- **Issue:** The checkout page rendered `@client_script_src` / `@hosted_fields_script_src` in HEEx without assigning them, causing a 500 during LiveView mount.
- **Fix:** Assigned the pinned Braintree script URLs and SRI hashes during mount and removed the stale hidden nonce input from the form.
- **Files modified:** `accrue_portal/lib/accrue_portal/live/checkout_live.ex`
- **Verification:** `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs`

**2. [Rule 1 - Bug] Corrected the checkout JS contract proof to assert the actual push payload**
- **Found during:** Task 2 verification
- **Issue:** The initial JS regression test wrongly rejected Hosted Fields config keys (`number`, `expirationDate`, `cvv`) instead of checking the `pushEvent/3` payload shape.
- **Fix:** Tightened the test to assert the hook pushes only `%{nonce: payload.nonce}` and never includes server-posted card fields or the old hidden `payment_method_nonce` input.
- **Files modified:** `accrue_portal/test/accrue_portal/live/checkout_live_test.exs`
- **Verification:** `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs`

**3. [Rule 3 - Blocking] Adjusted plan verification to match the installed Mix/ExUnit CLI**
- **Found during:** Task 2 verification
- **Issue:** The plan's `mix test ... -x` command is unsupported in the current repo toolchain.
- **Fix:** Ran the same focused test file with plain `mix test`, which exercises the full checkout contract without the invalid flag.
- **Files modified:** none
- **Verification:** `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs`

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 blocking toolchain drift)
**Impact on plan:** No scope expansion beyond the locked checkout slice; the deviations were required to make the Hosted Fields contract real and executable in this repo.

## User Setup Required

None.

## Next Phase Readiness

- Plan 08 can now layer synthetic completion-event and telemetry plumbing onto a stable checkout LiveView/nonce contract.
- Later portal slices can reuse `AccruePortal.Copy` and the package-local checkout test harness rather than re-deriving checkout copy or auth setup.

## Self-Check: PASSED

- Confirmed `.planning/phases/101-accrue-portal-foundation-checkout/101-04-SUMMARY.md` exists.
- Verified `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs` passes.
- Verified `cd accrue_portal && rg -n 'integrity="sha384-(rNv6rxT4CpVv9Kb8luV4l/GpBwbhHTmZxWbI74/LX\+ShrJzh/b9AL7nynSmHDpRC|QAzc9uX3XQPGzTESbnMNOUn9hY9jVL/L10Eq3Gxt4NKXIZZWzGlhnEscA3iGj8Jp)"|crossorigin="anonymous"' lib/accrue_portal/live/checkout_live.ex priv/static/accrue_portal.js` returns the pinned checkout script tags.
