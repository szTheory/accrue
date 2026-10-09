---
phase: 235-customer-plan-selection-checkout
plan: 04
subsystem: payments
tags: [stripe, braintree, phoenix-liveview, playwright, checkout]
requires:
  - phase: 235-customer-plan-selection-checkout
    provides: selected-plan checkout session and processor routing from plan 235-03
provides:
  - Stripe hosted return reconciles authoritative provider state before mirroring payment
  - Concurrent reconciliation serializes per provider session and remains idempotent
  - Served checkout assets and narrow viewport browser assertions in the required CI lane
affects: [checkout, billing, customer-plan-selection]
actuals:
  tokens: 7670
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns: [authoritative hosted-session reconciliation, per-session transaction advisory lock, served-asset Playwright verification]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/checkout.ex
    - accrue/test/accrue/checkout_test.exs
    - examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex
    - examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs
    - accrue_portal/priv/static/accrue_portal.css
    - examples/accrue_host/e2e/phase233-braintree-checkout.spec.js
    - examples/accrue_host/lib/accrue_host_web/components/layouts/root.html.heex
key-decisions:
  - "A return URL is navigation only; completion requires a fetched, matching, complete and paid processor session."
  - "Serialize same-session projection inside the existing host database transaction to keep concurrent reconciliation singular."
  - "Use a 320 CSS-pixel viewport as the 400% zoom-equivalent layout width in Playwright; CSS document zoom did not model browser zoom or responsive media queries correctly."
patterns-established:
  - "Hosted checkout Fake tests prove deterministic contracts only; they do not claim live-provider transaction behavior."
  - "Assert served hashed Portal assets and page geometry in the existing merge-blocking Braintree Playwright command."
requirements-completed: [CKO-01, CKO-02, CKO-03, CKO-04]
coverage:
  - id: D1
    description: "Stripe hosted handoff and safe return reconcile against processor evidence while preserving Braintree mounted checkout."
    requirement: CKO-02
    verification:
      - kind: unit
        ref: "cd accrue && mix test test/accrue/checkout_test.exs test/accrue/billing/checkout_session_facade_test.exs"
        status: pass
      - kind: integration
        ref: "cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Served checkout styles and browser behavior preserve accessible feedback, secure field surroundings, readable terms, and responsive page geometry."
    requirement: CKO-03
    verification:
      - kind: e2e
        ref: "cd examples/accrue_host && npm run e2e:braintree-checkout (12 passed)"
        status: pass
    human_judgment: false
plan_head_before: 8d204acb8857dea6e9ac8ab5fbdf2822a4c647d2
plan_head_after: 5c79eb0e981c862ad4484bf67791e96eaa0ad75b
duration: 17min
completed: 2026-10-08
status: complete
commits: 2
---

# Phase 235 Plan 04: Customer plan selection checkout summary

**Stripe checkout returns now reconcile against fetched paid sessions, and the served checkout journey passes deterministic responsive browser coverage while Braintree remains mounted.**

## Performance

- **Duration:** 17 minutes
- **Started:** 2026-10-08T12:15:00Z
- **Completed:** 2026-10-08T12:32:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added authoritative Stripe session reconciliation with metadata matching, paid/complete checks, safe handling of cancellation and unavailable states, and serialized idempotent subscription projection.
- Preserved separate provider journeys: Stripe redirects to hosted checkout; Braintree stays on the mounted Portal Hosted Fields flow.
- Improved served Portal checkout summary, feedback and narrow-screen layout. Added Playwright assertions for served assets, focus/status, long Unicode content and checkout/host-return geometry at 320 CSS pixels.
- Confirmed the existing merge-blocking `playwright-e2e` CI job already invokes `npm run e2e:braintree-checkout`; no CI file change was necessary.

## Task Commits

1. **Task 1: Prove distinct provider handoff and authoritative safe return** - `cb583311` (feat)
2. **Task 2: Prove accessible checkout states in the served Portal bundle and CI** - `5c79eb0e` (test)

## Files Created/Modified

- `accrue/lib/accrue/checkout.ex` - Provider session reconciliation and singular projection.
- `accrue/test/accrue/checkout_test.exs` - Authoritative state and concurrent/idempotent Fake contract coverage.
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` - Hosted success/cancel return routing and metadata context.
- `examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs` - Host return and provider-path behavior coverage.
- `accrue_portal/priv/static/accrue_portal.css` - Narrow layout, wrapping, and secure-field surroundings.
- `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js` - Served bundle, keyboard/status, error, long-text and viewport assertions.
- `examples/accrue_host/lib/accrue_host_web/components/layouts/root.html.heex` - Collapse Pricing and theme controls at narrow widths after browser evidence showed host navigation caused page overflow.

## Decisions Made

- Provider return query parameters cannot establish payment completion; the host fetches and validates the Stripe session before mirroring it.
- Same-session reconciliation takes a transaction advisory lock before projection to guarantee a single local subscription under concurrent returns.
- Playwright uses a 320 CSS-pixel viewport to exercise the effective layout width of a 1280px display at 400% browser zoom. Applying CSS `zoom` to the document did not model browser zoom because media queries continued to use the original viewport.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Critical correctness] Serialize concurrent reconciliation for the same provider session**
- **Found during:** Task 1
- **Issue:** Concurrent retries could race when projecting one provider session.
- **Fix:** Acquire a PostgreSQL transaction advisory lock keyed by the provider session before projection; add deterministic parallel Fake-backed coverage.
- **Files modified:** `accrue/lib/accrue/checkout.ex`, `accrue/test/accrue/checkout_test.exs`
- **Verification:** Focused ExUnit commands passed; the parallel test verifies one local subscription projection.
- **Committed in:** `cb583311`

**2. [Rule 1 - Layout bug] Prevent host navigation from overflowing hosted return at 320 CSS pixels**
- **Found during:** Task 2
- **Issue:** Browser evidence showed the host navigation's Pricing, theme controls and account/logout controls exceeded the viewport on the hosted cancellation return.
- **Fix:** Hide Pricing and the three-button theme control below the small breakpoint, retaining accessible controls at wider widths; add a served-browser regression assertion. Also set CTA box sizing and wrap checkout content in the Portal stylesheet.
- **Files modified:** `examples/accrue_host/lib/accrue_host_web/components/layouts/root.html.heex`, `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js`, `accrue_portal/priv/static/accrue_portal.css`
- **Verification:** Focused regression passed; the full required browser lane passed 12/12.
- **Committed in:** `5c79eb0e`

**Total deviations:** 2 auto-fixed (Rule 2: 1; Rule 1: 1). The host layout edit was an explicitly bounded out-of-frontmatter addition requested by the parent executor after the 320px browser assertion isolated overflow to the shared navigation.

## Issues Encountered

- Initial unprivileged Chromium startup was blocked by the local macOS sandbox. The browser lane was rerun with the required local Chromium access and passed.
- The initial CSS `zoom` simulation did not change media-query viewport width and produced false overflow in unrelated wide-breakpoint navigation controls. The assertion was corrected to exercise the actual 320 CSS-pixel effective layout width; no live-provider behavior is claimed.
- Existing Admin compiler clause-grouping and exchange-rate deprecation warnings appeared during browser startup; they are unrelated to this plan and unchanged.
- `roadmap.update-plan-progress 235` found no writable phase-235 entry in ROADMAP.md and left it unchanged; the plan and summary counts both report 4.

## User Setup Required

None - deterministic Fake-backed verification; no external provider configuration required.

## Next Phase Readiness

Plan 235-04 is complete. Hosted returns are server-reconciled, mounted Braintree remains separate, and the existing merge-blocking browser job covers the delivered bundle and narrow layout.

---
*Phase: 235-customer-plan-selection-checkout*
*Completed: 2026-10-08*

## Self-Check: PASSED

- SUMMARY exists at the required phase path.
- Task commits `cb583311` and `5c79eb0e` are ancestors of HEAD.
