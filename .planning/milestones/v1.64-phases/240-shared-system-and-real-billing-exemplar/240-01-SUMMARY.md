---
phase: 240-shared-system-and-real-billing-exemplar
plan: "01"
subsystem: ui
tags: [phoenix-liveview, billing, admin, css, playwright]

# Dependency graph
requires: []
provides:
  - Mounted invoice collection, detail, and action-review exemplar with explicit target and exact money facts.
  - Shared detail action geometry with 44px frequent-action targets, 2px dense grouping, and 1px structural separation.
  - Subscription cross-check evidence for empty, one-row, multi-row, unknown facts, long content, and touch-pointer widths.
affects: [phase-240, admin-ui, billing, design-system]

# Actuals (#2632); chars/4 over realized diff, measured commits from plan ledger.
actuals:
  tokens: 70722
  tasks: 3
  commits: 5
plan_head_before: fef1c8cb6f1e84578d128f1cca157c72b8e74a76
plan_head_after: de0c4e19c76edbb926757c0d3c29006d12e049c9

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Mounted Playwright acceptance assertions compare served package CSS bytes with the rebuilt artifact.
    - Shared detail action bands use the system 44px target while data and structural spacing stay at 2px and 1px.

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/copy/invoice.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/lib/accrue_admin/live/invoices_live.ex
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/e2e/admin-spec-detail-phase198.spec.js
    - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - examples/accrue_host/e2e/phase237-admin-billing.spec.js

key-decisions:
  - "Invoice review exposes invoice, customer, and owner identity with exact currency while preserving existing authorization, step-up, eligibility, and duplicate protections."
  - "Set the owning shared detail action selector to 44px and use the existing 2px dense spacing token; retain the 1px structural rule."
  - "Keep subscription presentation unchanged because mounted desktop, narrow, intermediate, and coarse-pointer evidence showed no composition defect."

patterns-established:
  - "Action reviews should identify the canonical record, customer, owner target, amount/currency, consequence, and audit effect before dispatch."
  - "Cross-check long identity values in a disposable mounted fixture, verify wrapping and accessible actions, then restore the DOM before capture."

requirements-completed: [DSN-01, UXC-02, EVR-02]
coverage:
  - id: D1
    description: "Mounted invoice list-to-detail-to-review path states scoped record identity, customer/owner target, exact amount/currency, and action consequence."
    requirement: UXC-02
    verification:
      - kind: unit
        ref: "mix test test/accrue_admin/live/invoice_live_test.exs — 22 tests"
        status: pass
      - kind: e2e
        ref: "CI=1 npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop — disposable host fixture"
        status: pass
    human_judgment: false
  - id: D2
    description: "Shared detail action hit area and dense/structural spacing match mounted geometry and served package assets."
    requirement: DSN-01
    verification:
      - kind: e2e
        ref: "npm run e2e:phase198 — 24 passed; 4 existing desktop-only drawer cases skipped on mobile"
        status: pass
      - kind: integration
        ref: "mix accrue_admin.assets.build; mounted CSS bytes matched accrue_admin/priv/static/accrue_admin.css (SHA-256 7766ba983f02101445e756a75ced61117bcb338048f7b23fa5df4eaf22fbbfcf)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Dense subscription collection and detail remain truthful and reachable across record counts, unknown facts, long identity text, and coarse-pointer widths."
    requirement: EVR-02
    verification:
      - kind: unit
        ref: "mix test test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/subscription_live_test.exs — 44 tests"
        status: pass
      - kind: e2e
        ref: "CI=1 npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop — desktop and touch-enabled Pixel 5, 320/768/1280px"
        status: pass
    human_judgment: false

metrics:
  duration: 18min
  completed: 2026-10-09
  commits: 5
status: complete
---

# Phase 240 Plan 01: Shared System and Real Billing Exemplar Summary

**An exact mounted invoice review path and measured shared detail controls, with dense subscription behavior verified at desktop, narrow, and touch widths.**

## Performance

- **Duration:** 18 minutes from the first persisted task commit; startup/read time was not captured.
- **Started (first persisted task commit):** 2026-10-09T19:24:54Z
- **Completed:** 2026-10-09T19:42:19Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Invoice collection copy now renders known collection methods as human-readable labels. Review exposes the invoice ID, customer label and ID, owner type and ID, owner scope, exact amount/currency, action effect, and audit consequence.
- The shared detail action-band button rule now preserves a 44px target. Dense detail groups use the existing 2px spacing token; structural separators remain 1px. The Phase 198 owner verifies computed geometry and byte-for-byte served CSS identity.
- Subscription owner tests now prove zero, one, and multiple rows and reject zero-filled unknown amounts. A disposable mounted past-due subscription retained its scoped customer identity, honest missing price/period copy, overflow action, and long identity wrapping at 320px without document overflow across 320/768/1280px desktop and touch-enabled Pixel 5 contexts.
- The fresh host invoice route loaded in 221.79ms to LiveView readiness and 271.51ms to task readiness in this run (diagnostic only, no timing threshold). Five resources totaled 406,454 encoded/decoded body bytes and 407,954 transfer bytes. Served CSS was 130,123 bytes and matched the rebuilt package artifact by SHA-256.

## Task Commits

Each task was committed atomically:

1. **Task 1: Prove the real invoice collection to review path** — `6c5b0604` (RED), `54023dbb` (implementation).
2. **Task 2: Align the shared detail and action geometry at its owner** — `f6ad91a9` (RED), `ba3bf484` (implementation).
3. **Task 3: Cross-check the dense subscription composition** — `de0c4e19` (owner and mounted acceptance evidence; existing composition was already adequate).

**Plan metadata:** included in the final docs commit; its hash is recorded in the execution completion message.

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/copy/invoice.ex` — labels and copy for explicit invoice review facts.
- `accrue_admin/lib/accrue_admin/live/invoice_live.ex` — customer and owner target facts in action review.
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex` — human-readable collection method in invoice list/card.
- `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` — review identity, exact money, stale-state, and action safety assertions.
- `accrue_admin/assets/css/app.css` — shared action-band and dense detail spacing geometry.
- `accrue_admin/priv/static/accrue_admin.css` — rebuilt package stylesheet.
- `accrue_admin/e2e/admin-spec-detail-phase198.spec.js` — mounted hit rectangle, spacing, and served CSS identity checks.
- `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs` — zero/one/many and scope checks.
- `accrue_admin/test/accrue_admin/live/subscription_live_test.exs` — no-zero-fill assertion for unknown amount/period.
- `examples/accrue_host/e2e/phase237-admin-billing.spec.js` — invoice tracer diagnostics plus long-content and coarse-pointer subscription evidence.

## Decisions Made

- Keep review identity and money facts in the existing Invoice LiveView and Copy owner; leave provider policy, audit language, and dispatch checks unchanged.
- Correct the action geometry at the shared selector, not with route-specific overrides. Preserve the existing 2px dense and 1px structural spacing roles.
- Make no subscription renderer edit: the mounted cross-check found the existing identity hierarchy, unknown-state copy, and actions remained legible and accessible under the requested density stress.

## Deviations from Plan

None — the plan allowed evidence-backed no-change for adequate subscription composition, and no unrelated product behavior was added.

## Issues Encountered

- The first asset build could not write to the configured root-owned npm cache. The same repository-pinned Tailwind 3.4.17 and esbuild 0.25.3 build succeeded with `npm_config_cache=/private/tmp/accrue240-npm-cache`; no dependency files changed.
- The first mounted subscription assertions assumed a processor ID heading and a primary action. Browser evidence showed the customer label is the heading and the seeded past-due record exposes its action through the overflow menu. The acceptance assertions were corrected to those live semantics; no action was dispatched.
- Phase 198 reports four skipped mobile drawer-flow cases because the existing owner intentionally runs those representative flows only on desktop. Its desktop and mobile render/geometry cases passed.
- STATE.md had no parseable plan counter (`Plan: —`), so the first SDK advance could not resolve position. After using the on-disk summary count to restore the counter through the SDK, the state now points to plan 2 of 6 and remains in progress.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

The invoice tracer, shared detail hit-area rule, and subscription density evidence are ready for subsequent Phase 240 plans. Phase 240 remains in progress; phase-level verification and completion are owned by the orchestrator.

---
*Phase: 240-shared-system-and-real-billing-exemplar*
*Completed: 2026-10-09*

## Self-Check: PASSED

- Summary file exists at the required phase path.
- All five task commits are ancestors of the current plan head.
