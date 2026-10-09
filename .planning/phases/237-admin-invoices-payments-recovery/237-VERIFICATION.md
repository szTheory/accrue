---
phase: 237-admin-invoices-payments-recovery
verified: 2026-10-09T02:10:00Z
status: passed
score: 5/5 must-haves verified
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
covered_digest: "v3:sha256:5551da41c6f79f855e4612549a040d4769d045560236158715800cae1e6f6348"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 237: Admin Invoices, Payments & Recovery — Verification Report

**Phase Goal:** Operators can complete invoice, payment, refund, and recovery work with exact amounts, correct scope, and truthful result evidence.
**Verified:** 2026-10-09T02:10:00Z
**Status:** passed
**Re-verification:** No — initial verification; no prior verification report existed.

## Goal Achievement

The ROADMAP contract has five success criteria. ADM-02, ADM-05, and ADM-06 all map to this phase in REQUIREMENTS.md; each is satisfied by production paths and focused mounted LiveView tests. Source paths traced from scoped database reads through formatting/rendering or action dispatch to result refresh; the tests exercise boundary and state-transition behavior. No claims of remote processor settlement are made from local audit evidence.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Operators distinguish stored invoice lifecycle from overdue, missing due dates, and unsupported/missing money; supported amounts preserve currency precision. | ✓ VERIFIED | `invoices_live.ex` and `invoice_live.ex` use scoped invoice data and `MoneyFormatter`; overdue is limited to open invoices with a known past due date. `invoices_live_test.exs` covers before/equal/after/missing due dates, and supported zero-, two-, and three-decimal plus unavailable-money cases. |
| 2 | Payment/finalization and refund reviews show exact target, amount, currency, and consequence, and dispatch only after fresh scoped authorization/revalidation. | ✓ VERIFIED | `invoice_live.ex` reauthorizes/reloads reviewed invoices before dispatch and after step-up; `charge_live.ex` does the same for refunds using `Charges.detail`. `invoice_live_test.exs` and `charge_live_test.exs` cover changed scope/facts, amount limits, step-up, and dispatch suppression. |
| 3 | Accepted, requires-action, definitive failure, local completion evidence, and ambiguous outcomes remain distinguishable and evidence-based. | ✓ VERIFIED | Invoice tests cover refreshed scoped result state, requires-action, card decline, ambiguous no-retry, and duplicate confirm. Refund code treats a returned local Refund row as creation evidence and labels ambiguity unconfirmed; charge tests cover refund evidence and stale review. The Admin package regression run passed. |
| 4 | Recovery retains selected UTC window, current authorized owner, currency observations, and return context, while historical failure remains separate from current billing state. | ✓ VERIFIED | `RecoveryLive`, scoped `Queries.Dunning`, and `AtRiskTable` carry the URL window and current owner through scoped reads and `ScopedPath` links. `recovery_live_test.exs` covers loading/error, currency/unavailable values, owner exclusion, historical/current distinction, rapid window selection, and validated return. |
| 5 | Changed flows provide keyboard/focus, narrow-screen, theme, denied/error, and served-asset evidence. | ✓ VERIFIED | `phase237-admin-billing.spec.js` is discovered by the existing blocking Playwright lane. Supplied run: 1/1 passed at source `b24092fa`; it tests read-only staged review/cancel, focus restoration, 320px layout, themes, denial, and recovery return. Screenshots and manifest bind the served evidence to source/assets. |

**Score:** 5/5 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact group | Expected | Status | Details |
|---|---|---|---|
| Invoice list/detail | Scoped collection, overdue and money presentation | ✓ VERIFIED | Production rendering is wired to invoice query results and MoneyFormatter; list/detail tests cover owner scope, lifecycle, due-date boundaries, and money precision. |
| Invoice payment/finalization | Review, fresh target validation, dispatch and result evidence | ✓ VERIFIED | LiveView handlers connect staged review to scoped reload, Billing operation and scoped refresh; focused Fake-backed tests exercise stale and result paths. |
| Charge/refund | Exact charge/refund facts and scoped revalidated refund action | ✓ VERIFIED | Charge and refund views use the scoped charge/read path; review and confirmation tests assert target and balance, stale step-up cancellation, money precision, and result semantics. |
| Recovery | Scoped queries, currency-aware measures, async states and validated navigation | ✓ VERIFIED | `Dunning` query outputs flow to RecoveryLive KPIs and AtRiskTable; related links preserve owner/window and current status comes from current subscription data. |
| Served browser evidence | Playwright spec, screenshots, manifest | ✓ VERIFIED | Spec and three captures exist; manifest is recorded as revalidated against source `b24092fa`, with read-only/no-dispatch assertions. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Owner-scoped invoice query | Invoice list/detail and MoneyFormatter | LiveView assigns/render callbacks | ✓ WIRED | Invoice query results feed row fields and shared formatter; mounted tests assert rendered values and foreign-owner exclusion. |
| Invoice/refund review | Billing action | Fresh scoped reload + host authorization + reviewed-facts comparison | ✓ WIRED | Stale data, changed owner, and post-step-up changes cancel before the Fake/provider action; tests assert no dispatch/write. |
| Billing response | Result UI | Scoped refresh and typed outcome handling | ✓ WIRED | Refreshed invoice state, requires-action, definitive decline, and ambiguous response take distinct branches; no automatic replay. |
| URL owner/window | Dunning queries and recovery rows | Async query captures current owner and UTC bounds; ScopedPath return links | ✓ WIRED | Tests cover current selection after rapid changes, foreign-owner exclusion, and validated return context. |
| Phase browser test | Existing CI browser lane | Playwright config discovery and unrestricted CI spec selection | ✓ WIRED | Listed by Playwright; CI lane runs without excluding the phase spec. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Invoice list/detail | Invoice rows and integer minor-unit fields | Scoped repository query | Yes | ✓ FLOWING |
| Payment/refund views | Invoice/Charge/Refund records | Scoped billing reads and returned action results | Yes | ✓ FLOWING |
| Recovery KPIs and table | Currency buckets, funnel and at-risk rows | Scoped Dunning database queries and current subscription reads | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

The following current regression evidence is recorded in `237-VALIDATION.md` / `237-08-SUMMARY.md` and was supplied for this verification. This report did not rerun suites.

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Cross-core regressions | Core 2,077 tests, 0 failures; Admin 581/0; Portal 110/0; Host 222/0 | Passed | ✓ PASS |
| Package documentation contract | Docs verifier 46 tests, 0 failures | Passed | ✓ PASS |
| Served Phase 237 invoice/recovery flow | Chromium Playwright at source `b24092fa` | 1/1 passed | ✓ PASS |
| Related Phase 234 subscription detail regression | Chromium Playwright | 1/1 passed | ✓ PASS |
| Prior browser lanes | Standard Fake 14, Phase 234 query search 1, Phase 233 Braintree 12, Phase 236 Braintree 14 | All passed | ✓ PASS |

### Probe Execution

| Probe | Result | Status |
|---|---|---|
| No phase-declared probe scripts; this is an Admin feature/UI phase | Not applicable | — |

### Requirements Coverage

| Requirement | Source | Description | Status | Evidence |
|---|---|---|---|---|
| ADM-02 | 237 plans 01/04/08 | Accurate invoice lifecycle, due-date, and currency/minor-unit precision | ✓ SATISFIED | `invoices_live_test.exs`, `invoice_live_test.exs`, source traces, served browser evidence. |
| ADM-05 | 237 plans 02/05/06/08 | Exact payment/finalization/refund review and truthful outcomes | ✓ SATISFIED | `invoice_live_test.exs`, `charges_live_test.exs`, `charge_live_test.exs`; Admin regression suite. |
| ADM-06 | 237 plans 03/07/08 | Recovery owner/window/currency context and historical/current distinction | ✓ SATISFIED | `recovery_live_test.exs`, Dunning query path, served recovery round-trip. |

No additional requirement IDs are mapped to Phase 237 in REQUIREMENTS.md.

### Decision Coverage

The non-blocking CONTEXT decision gate found **7/7 decisions honored**, with no unhonored decisions.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | No debt markers, placeholder implementations, or relevant stub matches in phase implementation/test files. | — | — |

The UI review documents remaining non-blocking polish findings (currency-code casing, repeated clear labels, color/contrast coverage, typography/spacing). They do not contradict the five roadmap outcomes or block deterministic acceptance.

### Human Verification Required

None. The changed acceptance criteria have deterministic source-bound LiveView and served-browser evidence; no unresolved behavior requires a human decision.

### Gaps Summary

No must-have truth failed, no artifact is missing or stubbed, and the checked data paths are wired to real scoped queries/actions. All three phase requirements are satisfied. The security report records zero open threats. No deferred items or verification overrides apply.

---

_Verified: 2026-10-09T02:10:00Z_  
_Verifier: the agent (gsd-verifier)_
