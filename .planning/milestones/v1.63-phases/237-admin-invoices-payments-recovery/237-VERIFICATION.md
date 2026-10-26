---
phase: 237-admin-invoices-payments-recovery
verified: 2026-10-09T13:12:54Z
status: passed
score: 66/66 must-haves verified
covered_files:
  - .planning/phases/237-admin-invoices-payments-recovery/237-01-PLAN.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-01-SUMMARY.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-02-PLAN.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-02-SUMMARY.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-03-PLAN.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-03-SUMMARY.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-04-PLAN.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-04-SUMMARY.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-05-PLAN.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-05-SUMMARY.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-06-PLAN.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-06-SUMMARY.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-07-PLAN.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-07-SUMMARY.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-08-PLAN.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-08-SUMMARY.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-SECURITY.md
  - .planning/phases/237-admin-invoices-payments-recovery/237-VALIDATION.md
  - .planning/phases/237-admin-invoices-payments-recovery/COVERAGE.md
  - .planning/phases/237-admin-invoices-payments-recovery/captures/237-08/invoice-collection.png
  - .planning/phases/237-admin-invoices-payments-recovery/captures/237-08/invoice-review.png
  - .planning/phases/237-admin-invoices-payments-recovery/captures/237-08/manifest.json
  - .planning/phases/237-admin-invoices-payments-recovery/captures/237-08/recovery.png
  - accrue/lib/accrue/analytics/dunning.ex
  - accrue_admin/assets/css/app.css
  - accrue_admin/lib/accrue_admin/components/at_risk_table.ex
  - accrue_admin/lib/accrue_admin/components/money_formatter.ex
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/dunning.ex
  - accrue_admin/lib/accrue_admin/copy/invoice.ex
  - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
  - accrue_admin/lib/accrue_admin/live/charge_live.ex
  - accrue_admin/lib/accrue_admin/live/charges_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/invoices_live.ex
  - accrue_admin/lib/accrue_admin/queries/dunning.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/test/accrue_admin/components/at_risk_table_test.exs
  - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
  - accrue_admin/test/accrue_admin/live/charge_live_test.exs
  - accrue_admin/test/accrue_admin/live/charges_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
  - examples/accrue_host/e2e/phase237-admin-billing.spec.js
  - scripts/ci/accrue_host_seed_e2e.exs
covered_digest: "v3:sha256:de896baa8f00d568a652cd1d5bde6473226c6c1422a52be69c36d85bb6d70c6f"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 65/66
  gaps_closed:
    - "Current-source screenshots accompany visual claims and the focused served-browser evidence is bound to the verified source."
  gaps_remaining: []
  regressions: []
---

# Phase 237: Admin Invoices, Payments & Recovery — Verification Report

**Phase Goal:** Operators can complete invoice, payment, refund, and recovery work with exact amounts, correct scope, and truthful result evidence.
**Verified:** 2026-10-09T13:12:54Z
**Status:** passed
**Re-verification:** Yes — after capture freshness gap closure.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Operators distinguish invoice lifecycle, overdue boundaries, missing due dates, and supported currency precision. | ✓ VERIFIED | Current invoice list/detail paths use scoped reads and `MoneyFormatter`; the focused Admin suites exercise lifecycle, due-date boundaries, unavailable money, zero- and three-decimal currencies, and ownership. |
| 2 | Payment/finalization and refund review show exact target, amount, currency, and consequence, then revalidate scope and reviewed facts before dispatch. | ✓ VERIFIED | Current LiveViews reload and reauthorize before action dispatch, including step-up continuation. Tests cover changed scope/facts, bounds, duplicate confirmation, step-up, and dispatch suppression. |
| 3 | Accepted, requires-action, definitive failure, locally evidenced completion, and ambiguous outcomes remain distinguishable. | ✓ VERIFIED | Focused invoice and charge tests exercise typed results, scoped refresh/evidence, ambiguity, and no automatic replay. No remote settlement is inferred from a local row. |
| 4 | Recovery retains owner, UTC window, currency observations, and validated return context while keeping historical events separate from current billing state. | ✓ VERIFIED | Current Dunning queries and RecoveryLive feed currency-separated values and scoped links; the recovery tests exercise boundaries, owner exclusion, navigation, errors, and history/current distinctions. |
| 5 | Changed money/recovery flows retain keyboard, responsive, theme, and pending/denied/error evidence. | ✓ VERIFIED | The current served Playwright test passed and asserts focus/cancel, 320px layout, theme, scoped denial, recovery return, and current served assets. Its three captures and manifest now match the verified source. |

**Score:** 66/66 merged roadmap and plan truths verified. The plan truths restating roadmap criteria are deduplicated.

### Advisory (New Scope, Unevidenced)

None. No new-scope anti-pattern blocker was raised in this re-verification.

### Required Artifacts

| Artifact group | Expected | Status | Details |
|---|---|---|---|
| Invoice list/detail and tests | Scoped lifecycle, due-date and money evidence | ✓ VERIFIED | Plan-declared files exist and are substantive; current tests pass. Rendered values trace to scoped invoice queries and shared money formatting. |
| Invoice action/revalidation and tests | Exact staged review and result semantics | ✓ VERIFIED | Dispatch paths re-read and authorize scoped targets; Fake-backed tests exercise stale, pending, duplicate, and outcome paths. |
| Charge/refund views and tests | Exact balances, eligibility, refund result evidence | ✓ VERIFIED | Scoped charge reads and returned records drive the views; 0-/3-decimal precision and post-step-up revalidation are exercised. |
| Recovery query/views/tests | Scoped window, currency grouping, historical/current distinction | ✓ VERIFIED | Recovery values flow from Dunning and current scoped billing reads into the dashboard and links; focused tests pass. |
| Served spec and refreshed captures | Browser acceptance, CI discovery, source-bound visual evidence | ✓ VERIFIED | Spec exists, is discovered by the existing Playwright config, and passes locally. All 24 artifacts named across plan frontmatter exist. Manifest matches current source and all screenshot hashes/byte counts. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Owner-scoped invoice query | Invoice list/detail and `MoneyFormatter` | LiveView assigns/render | ✓ WIRED | Query results supply rendered lifecycle, due date, identity, and minor-unit values; focused mounted tests assert values and foreign-owner exclusion. |
| Invoice/refund review | Billing action | Fresh owner-scoped reload, authorization, reviewed-facts comparison | ✓ WIRED | Stale scope/state and changed reviewed facts cancel before dispatch; tests assert no write/dispatch on those paths. |
| Billing response | Result UI | Typed result handling and scoped refresh | ✓ WIRED | Refreshed records and typed errors produce distinct accepted/requires-action/failed/ambiguous copy. |
| Owner/window URL state | Recovery query, rows, and return links | Scoped Dunning reads and validated `ScopedPath` | ✓ WIRED | Query results reach dashboard/table; tests cover current owner, window changes, and safe return context. |
| Phase 237 browser spec | Existing blocking Playwright lane | Playwright discovery and unrestricted CI invocation | ✓ WIRED | `--list` discovers the spec; `.github/workflows/ci.yml` runs the Playwright suite without a Phase 237 exclusion. Remote CI execution was not available in this verification. |

### Data-Flow Trace (Level 4)

| Artifact | Rendered data | Source | Produces real data | Status |
|---|---|---|---|---|
| Invoice list/detail | Invoice rows and minor-unit money | Owner-scoped repository query | Yes | ✓ FLOWING |
| Payment/refund review | Invoice/charge facts and result rows | Scoped billing reads and action return values | Yes | ✓ FLOWING |
| Recovery dashboard/table | Currency buckets, events, current at-risk state | Scoped Dunning queries plus current subscription/invoice reads | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Invoice/refund/recovery mounted behavior | `cd accrue_admin && mix test --warnings-as-errors test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/analytics/recovery_live_test.exs` | 87 tests, 0 failures | ✓ PASS |
| Served browser journey | `cd examples/accrue_host && npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` | 1 passed. First sandbox attempt failed before test startup due to macOS Mach service permissions; authorized host-access retry passed. | ✓ PASS |
| Playwright discovery | `cd examples/accrue_host && npx playwright test --list e2e/phase237-admin-billing.spec.js --project=chromium-desktop` | One test discovered in the configured project. | ✓ PASS |
| Current-source capture persistence | Validate manifest against `git rev-parse HEAD`, source list, and all three PNGs | `source_head` matches `b113b182`; 9/9 source files and 3/3 screenshots match SHA-256 and byte counts; aggregate `source_sha` matches. `read_only: true`; `confirmed_or_dispatched: false`. | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| Phase-declared probes | None declared; this is an Admin UI feature phase. | Not applicable | — |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| ADM-02 | Plans 01, 04, 08 | Accurate invoice lifecycle, due-date, and currency/minor-unit precision | ✓ SATISFIED | Current invoice queries/rendering, focused invoice suites, and passing served test. |
| ADM-05 | Plans 02, 05, 06, 08 | Exact payment/finalization/refund review and truthful outcomes | ✓ SATISFIED | Focused invoice/charge LiveView suites pass; local audit evidence is explicitly not described as provider settlement. |
| ADM-06 | Plans 03, 07, 08 | Recovery owner/window/currency context and historical/current distinction | ✓ SATISFIED | Recovery suite passes; current Dunning and RecoveryLive path traced to scoped reads and validated links. |

No orphaned Phase 237 requirement IDs were found. The API coverage gate declares no new external API integration; this phase reuses existing Billing action contracts. No live-provider result was requested or inferred. Actual remote CI status was not available; CI wiring and local automated results were verified.

### Decision Coverage

The decision-coverage gate reports **7/7 decisions honored**, with no unhonored decisions.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | No debt markers or implementation stubs found in the phase production/spec files. | — | — |

The UI review’s remaining polish findings are non-blocking and do not contradict the verified behavior. No failed tests or security threats were found. The Phase 237 security report records 21/21 threats closed and `threats_open: 0`; its local evidence does not claim live settlement.

### Human Verification Required

None for routine acceptance: deterministic package/browser evidence covers the phase behaviors. External live-provider settlement was not performed and is not represented as verified. Remote CI execution was unavailable; local test success and CI discovery are recorded separately.

### Gaps Summary

The core roadmap behaviors, all three requirements, scoped data paths, current served browser journey, and source-bound screenshot evidence pass. The prior freshness gap is closed: the current run passed and the retained manifest binds all 9 sources and 3 screenshots to `b113b182`. No live-provider settlement was attempted or inferred; remote CI status was not available.

---

_Verified: 2026-10-09T13:12:54Z_
_Verifier: the agent (gsd-verifier)_
