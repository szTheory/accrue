---
phase: 260718-t4g-portal-nav-breadcrumbs-dunning-cta
plan: quick
subsystem: ui
tags: [phoenix, liveview, heex, accrue_portal, accrue_host, breadcrumbs, navigation, dunning]

requires:
  - phase: v1.45-multi-channel-dunning
    provides: dunning banner styling and past-due detection (accrue_admin DunningBanner component, dunning_customer/1 gate)
provides:
  - location-aware breadcrumb trail (Account / ... / current) on 5 accrue_portal sub-pages
  - clickable topbar brand (logo/wordmark) linking to portal home on every portal page
  - "Update payment method" CTA link inside the /app/billing dunning banner (examples/accrue_host demo)
affects: [accrue_portal, examples/accrue_host]

tech-stack:
  added: []
  patterns:
    - "AccruePortal.Layouts.breadcrumb/1 function component consuming a %{label, href} trail list, rendered fully-qualified from LiveViews with no shared web module"
    - "base_path assigned once at AuthHook.mount_customer/2 so root layout + any LiveView can rely on @base_path without per-LiveView duplication"

key-files:
  created: []
  modified:
    - accrue_portal/lib/accrue_portal/layouts.ex
    - accrue_portal/lib/accrue_portal/auth_hook.ex
    - accrue_portal/lib/accrue_portal/copy.ex
    - accrue_portal/lib/accrue_portal/live/subscriptions_live.ex
    - accrue_portal/lib/accrue_portal/live/subscription_live.ex
    - accrue_portal/lib/accrue_portal/live/payment_methods_live.ex
    - accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex
    - accrue_portal/lib/accrue_portal/live/invoices_live.ex
    - accrue_portal/priv/static/accrue_portal.css
    - accrue_portal/test/accrue_portal/live/payment_methods_live_test.exs
    - accrue_portal/test/accrue_portal/live/subscription_live_test.exs
    - examples/accrue_host/lib/accrue_host_web/components/layouts.ex

key-decisions:
  - "Two atomic commits scoped per concern: PART A (accrue_portal library) and PART B (examples/accrue_host demo), matching the plan's guardrail."
  - "No new --accrue-* tokens; breadcrumb + brand-link CSS consumes only existing tokens so it recolors automatically per theme and per host brand."

patterns-established:
  - "Breadcrumb separators are CSS-generated (li + li::before content: '/') rather than markup, keeping the HEEx template free of literal separator strings."

requirements-completed: []

coverage:
  - id: D1
    description: "Breadcrumb trail renders as the first element inside .portal-shell on SubscriptionsLive, SubscriptionLive (normal render), PaymentMethodsLive, AddPaymentMethodLive, and InvoicesLive"
    verification:
      - kind: unit
        ref: "accrue_portal/test/accrue_portal/live/payment_methods_live_test.exs#payment methods page renders only the current customer's cards and actions"
        status: pass
      - kind: unit
        ref: "accrue_portal/test/accrue_portal/live/subscription_live_test.exs#subscription detail stays customer-scoped through cancel confirmation"
        status: pass
    human_judgment: false
  - id: D2
    description: "Topbar brand (logo/wordmark) is a working home link on every portal page (visual/manual click-through)"
    verification: []
    human_judgment: true
    rationale: "No automated render test asserts the anchor's href/click-through visually; plan explicitly defers live verification to a human docker-restart pass per its Verification step 4."
  - id: D3
    description: "/app/billing dunning banner shows an Update payment method CTA navigating to /billing/payment-methods for a past-due workspace"
    verification:
      - kind: other
        ref: "cd examples/accrue_host && mix compile --warnings-as-errors (exit 0)"
        status: pass
    human_judgment: true
    rationale: "Plan explicitly states no docker restart is run as part of this task — the human performs the live check afterward per plan Verification step 4."

duration: 12min
completed: 2026-07-19
status: complete
---

# Quick Task 260718-t4g: Portal return-navigation + dunning CTA Summary

**Location-aware breadcrumbs + clickable topbar brand across 5 `accrue_portal` sub-pages, plus an "Update payment method" CTA wired into the `/app/billing` dunning banner in the `examples/accrue_host` demo.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-07-19T00:54:00Z (approx)
- **Completed:** 2026-07-19T01:06:47Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments
- Added `AccruePortal.Layouts.breadcrumb/1` function component and wrapped the topbar logo/wordmark in a `portal-brand-link` pointing at `@base_path`.
- Assigned `:base_path` once in `Accrue.Portal.AuthHook.mount_customer/2` so the root layout (and `InvoicesLive`, which previously had none) reliably has it without depending on each LiveView's own mount.
- Wired location-aware breadcrumb trails (`Account / ... / current`) into `SubscriptionsLive`, `SubscriptionLive` (normal render clause only), `PaymentMethodsLive`, `AddPaymentMethodLive`, and `InvoicesLive`.
- Added `Copy.breadcrumb_home/0`; reused existing `*_heading` getters for all other trail segments — no hardcoded copy in templates.
- Hand-written, committed `accrue_portal.css` breadcrumb + brand-link styles consuming only existing `--accrue-*` tokens (no new tokens), including `:focus-visible` rings.
- Added an "Update payment method →" CTA link inside the past-due dunning banner on `/app/billing` in `examples/accrue_host`, navigating to `/billing/payment-methods`. `AccrueAdmin.Components.DunningBanner` itself and the `dunning_customer/1` read-only gate are untouched.

## Task Commits

Each task was committed atomically:

1. **Task 1: PART A — breadcrumb component + clickable brand + 5-page wiring (`accrue_portal`)** - `ad1cccde` (feat)
2. **Task 2: PART B — dunning-banner action CTA (`examples/accrue_host`, demo-only)** - `80ee1c5c` (feat)

**Plan metadata:** committed separately by the orchestrator (docs commit not made by this executor per plan constraints).

## Files Created/Modified
- `accrue_portal/lib/accrue_portal/layouts.ex` - added `:base_path` attr to `root/1`, wrapped logo/wordmark in `portal-brand-link`, added `breadcrumb/1` component
- `accrue_portal/lib/accrue_portal/auth_hook.ex` - assign `:base_path` in `mount_customer/2`
- `accrue_portal/lib/accrue_portal/copy.ex` - added `breadcrumb_home/0`
- `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` - breadcrumb trail `[Account, Subscriptions]`
- `accrue_portal/lib/accrue_portal/live/subscription_live.ex` - breadcrumb trail `[Account, Subscriptions, Subscription details]` (normal render clause only)
- `accrue_portal/lib/accrue_portal/live/payment_methods_live.ex` - breadcrumb trail `[Account, Payment methods]`
- `accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex` - breadcrumb trail `[Account, Payment methods, Add payment method]`
- `accrue_portal/lib/accrue_portal/live/invoices_live.ex` - added `alias AccruePortal.Path`, breadcrumb trail `[Account, Invoices]`
- `accrue_portal/priv/static/accrue_portal.css` - `.portal-brand-link` + `.portal-breadcrumb*` rules (hand-written, committed, no build step)
- `accrue_portal/test/accrue_portal/live/payment_methods_live_test.exs` - additive breadcrumb render assertions
- `accrue_portal/test/accrue_portal/live/subscription_live_test.exs` - additive breadcrumb render assertions
- `examples/accrue_host/lib/accrue_host_web/components/layouts.ex` - added dunning-banner "Update payment method" `<.link navigate>` CTA

## Decisions Made
- None beyond the plan's own guardrails — plan executed as written with two atomic, concern-scoped commits (PART A / PART B).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness

- All automated verification passed: `accrue_portal` compiles with `--warnings-as-errors` (exit 0), `mix test` is green (37 tests, 0 failures, including the two new breadcrumb assertions), and `examples/accrue_host` compiles with `--warnings-as-errors` (exit 0).
- Live/human verification remains outstanding per the plan's own scope (no docker restart run here): confirm breadcrumbs + brand link render correctly in light/dark themes and under the Cadence brand at `docker restart accrue-host-web-1`, then click through `/billing/payment-methods`, `/billing/subscriptions`, a subscription detail, `/billing/invoices`, and the `/app/billing` dunning banner CTA as a past-due persona.
- No blockers for future work.

---
*Phase: 260718-t4g-portal-nav-breadcrumbs-dunning-cta*
*Completed: 2026-07-19*

## Self-Check: PASSED

All 13 files (12 modified source/test files + this SUMMARY) confirmed present on disk; both commits (`ad1cccde`, `80ee1c5c`) confirmed in `git log --oneline --all`.
