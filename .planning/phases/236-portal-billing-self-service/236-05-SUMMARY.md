---
phase: 236-portal-billing-self-service
plan: 05
subsystem: ui
tags: [portal, liveview, playwright, accessibility, ci]

# Dependency graph
requires:
  - phase: 236-02
    provides: Portal self-service routes and customer-scoped billing actions
  - phase: 236-03
    provides: Subscription and invoice route behavior
  - phase: 236-04
    provides: Hosted Fields and payment method flows
provides:
  - Host-branded Portal shell with explicit dashboard read failure state
  - Served-browser contract for seven Portal routes and deterministic billing states
  - Blocking CI execution of the Phase 236 Playwright contract
affects: [portal, ci, phase-236-verification]

# Actuals (#2632)
actuals:
  tokens: 15196
  tasks: 2
  commits: 2
plan_head_before: f620097b
plan_head_after: 94288d64305da0b0d56fa4e0bb565a103dee64e9

# Tech tracking
tech-stack:
  added: []
  patterns: ["Served Playwright assertions for packaged Portal CSS and JavaScript", "Deterministic Braintree Hosted Fields fixture in the blocking browser lane"]

key-files:
  created: [examples/accrue_host/e2e/phase236-portal-self-service.spec.js]
  modified: [.github/workflows/ci.yml, accrue_portal/lib/accrue_portal/billing_read_model.ex, accrue_portal/lib/accrue_portal/copy.ex, accrue_portal/lib/accrue_portal/layouts.ex, accrue_portal/lib/accrue_portal/live/home_live.ex, accrue_portal/lib/accrue_portal/live/subscription_live.ex, accrue_portal/lib/accrue_portal/live/subscriptions_live.ex, accrue_portal/priv/static/accrue_portal.css, accrue_portal/priv/static/accrue_portal.js, accrue_portal/test/accrue_portal/live/home_live_test.exs, examples/accrue_host/lib/accrue_host/billing.ex, scripts/ci/accrue_host_seed_e2e.exs]

key-decisions:
  - "Run the served Portal browser contract in the existing blocking Playwright CI lane with deterministic provider behavior."
  - "Authorize workspace invoice reads against the exact selected billable after its billing Customer is attached."

patterns-established:
  - "Portal regressions are asserted against the host-served package assets, including route identity, keyboard behavior, theme, and reflow."
  - "Hosted Fields lifecycle cleanup is verified on navigation and page exit."

requirements-completed: [POR-01, POR-04, POR-05, POR-06, POR-07]

coverage:
  - id: D1
    description: "Dashboard distinguishes successful empty data from unavailable reads while keeping the selected customer and next action visible."
    verification:
      - kind: unit
        ref: "accrue_portal/test/accrue_portal/live/home_live_test.exs#home renders only the current customer's dashboard data"
        status: pass
      - kind: unit
        ref: "accrue_portal/test/accrue_portal/live/home_live_test.exs#home presents successful empty collections as zero and keeps the empty state actionable"
        status: pass
      - kind: unit
        ref: "accrue_portal/test/accrue_portal/live/home_live_test.exs#home shows unavailable dashboard reads instead of zero counts"
        status: pass
    human_judgment: false
  - id: D2
    description: "Seven served Portal routes show the billed identity, relevant facts, and route actions."
    verification:
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase236-portal-self-service.spec.js#seven served Portal routes keep their billed identity, facts, and actions in view"
        status: pass
    human_judgment: false
  - id: D3
    description: "Personal and workspace invoice views remain scoped to their own hosted invoices and render empty collections."
    verification:
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase236-portal-self-service.spec.js#personal and workspace views show empty collections and only their own hosted invoices"
        status: pass
    human_judgment: false
  - id: D4
    description: "Themes, bright host accents, keyboard focus, reduced motion, long text, and narrow viewport reflow remain usable."
    verification:
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase236-portal-self-service.spec.js#themes, bright host accents, keyboard focus, reduced motion, and long text stay readable"
        status: pass
    human_judgment: false
  - id: D5
    description: "Hosted Fields expose pending and validation states, clear failed nonce data, and tear down on exit."
    verification:
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase236-portal-self-service.spec.js#Hosted Fields show pending and validation states, clear failed nonce data, and teardown on exit"
        status: pass
    human_judgment: false
  - id: D6
    description: "Subscription confirmation supports Escape, restores focus, and avoids an unintended provider mutation."
    verification:
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase236-portal-self-service.spec.js#Escape closes subscription confirmation and restores focus without sending a provider mutation"
        status: pass
    human_judgment: false
  - id: D7
    description: "The served-browser contract is included in the blocking CI lane with valid workflow syntax."
    verification:
      - kind: other
        ref: "actionlint .github/workflows/ci.yml"
        status: pass
      - kind: e2e
        ref: "npm run e2e -- --config=playwright.braintree.config.js e2e/phase236-portal-self-service.spec.js (5 passed)"
        status: pass
    human_judgment: false

# Metrics
duration: 28min
completed: 2026-10-08
status: complete
---

# Phase 236 Plan 05: Branded Portal and served browser proof

**Host-branded Portal routes and billing interactions now have deterministic served-browser coverage in the blocking CI lane.**

## Performance

- **Duration:** 28 min
- **Started:** 2026-10-08T17:27:48Z
- **Completed:** 2026-10-08T17:55:27Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Refined the shared shell and Home dashboard to identify the selected billed entity, bound visible counts, and show unavailable reads distinctly from successful empty data.
- Added a served-host Playwright contract covering seven routes, personal/workspace invoice scope, Hosted Fields lifecycle, feedback, keyboard behavior, themes, reduced motion, contrast, and narrow layouts.
- Added the browser contract to the merge-blocking CI lane and verified the package gate and all five browser tests.

## Task Commits

Each task was committed atomically:

1. **Task 1: Apply host-branded hierarchy across the Portal shell** - `b8c04a52` (feat)
2. **Task 2: Prove all seven served routes in blocking Playwright CI** - `94288d64` (test)

## Files Created/Modified

- `examples/accrue_host/e2e/phase236-portal-self-service.spec.js` - Served-browser contract for Portal routes and interactions.
- `.github/workflows/ci.yml` - Runs the contract in the blocking Braintree Playwright lane.
- `accrue_portal/lib/accrue_portal/` and `accrue_portal/priv/static/` - Shared shell, billing read model, LiveViews, and served assets.
- `accrue_portal/test/accrue_portal/live/home_live_test.exs` - Dashboard identity, empty, and unavailable-read cases.
- `examples/accrue_host/lib/accrue_host/billing.ex` - Exact selected-billable authorization for workspace invoice reads.
- `scripts/ci/accrue_host_seed_e2e.exs` - Deterministic two-owner browser fixture.

## Decisions Made

- Use the existing Braintree-configured Playwright lane and a deterministic Hosted Fields fixture so browser proof recurs in CI without live provider calls.
- Reauthorize workspace invoice reads against the exact selected billable after attaching the billing Customer.

## Deviations from Plan

### Auto-fixed Issues

**1. Rule 1 - Correctness: workspace invoice reads were denied after Customer attachment.**
- **Found during:** Task 2 served-browser verification.
- **Issue:** The host action guard rejected a workspace billable after its billing Customer had been attached.
- **Fix:** Allowed the exact selected billable target and carried the signed workspace context across the tested routes.
- **Files modified:** `examples/accrue_host/lib/accrue_host/billing.ex`, `examples/accrue_host/e2e/phase236-portal-self-service.spec.js`
- **Verification:** The personal/workspace invoice isolation browser case passed.
- **Committed in:** `94288d64`

**2. Rule 1 - Correctness: the browser fixture attempted an invalid invoice state transition.**
- **Found during:** Task 2 served-browser verification.
- **Issue:** The invoice changeset does not allow a draft invoice to transition directly to paid.
- **Fix:** Seeded a legal open invoice with a remaining balance for the hosted-invoice assertions.
- **Files modified:** `scripts/ci/accrue_host_seed_e2e.exs`
- **Verification:** The two-owner fixture seeded successfully and the browser suite passed.
- **Committed in:** `94288d64`

---

**Total deviations:** 2 auto-fixed (correctness: 2)
**Impact on plan:** Both fixes were required for deterministic, source-valid browser coverage; no scope expansion.

## Issues Encountered

- Chromium required the approved local browser execution permission; with it, the served suite completed 5/5.
- `git diff --check`, `actionlint .github/workflows/ci.yml`, `cd accrue_portal && mix test.ci` (110 tests, 0 failures), and the served Playwright suite passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 05 is ready for phase-level goal verification. Automated evidence covers every shipped deliverable; proceed with phase security, review, regression, and verifier gates.

---
*Phase: 236-portal-billing-self-service*
*Completed: 2026-10-08*
