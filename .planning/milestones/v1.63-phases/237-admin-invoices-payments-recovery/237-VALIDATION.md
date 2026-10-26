---
phase: "237"
slug: "admin-invoices-payments-recovery"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-08"
---

# Phase 237 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit and Phoenix LiveView tests in accrue_admin; Playwright Test in examples/accrue_host |
| Config file | Existing Mix configuration; examples/accrue_host/playwright.config.js |
| Quick run command | cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/analytics/recovery_live_test.exs |
| Full suite command | cd accrue_admin && mix test --warnings-as-errors |
| Served browser seam | Existing host integration Playwright lane via scripts/ci/accrue_host_uat.sh and .github/workflows/ci.yml |
| Estimated runtime | Focused ExUnit suites: about 4 seconds; served Playwright journey: 8.6 seconds |

## Sampling Rate

- After every behavior task: run the focused ExUnit/LiveView or Playwright check assigned to that task.
- After every plan wave: run cd accrue_admin && mix test --warnings-as-errors; run the affected served browser contract after browser-facing changes.
- Before phase verification: full Admin package suite and the representative phase-owned served browser journey must pass.
- Max feedback latency: target under 5 minutes for focused checks; record actual suite times during execution.

## Per-Task Verification Map

The plan/task/wave IDs and threat references below identify ownership; execution status belongs in each plan summary.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 237-01-T1/T2; 237-04-T1/T2 | 237-01, 237-04 | 0, 1 | ADM-02 | T-237-01, T-237-08, T-237-09 | Wave 0 characterizes existing scoped invoice path and raw fixtures to green; plan 04 adds and greens overdue, money, and collection assertions | ExUnit + LiveView | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs`; `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs` | Existing invoice suites; baseline/fixtures by 237-01 and behavior checks by 237-04 | green |
| 237-02-T1/T2; 237-05-T1/T2; 237-06-T1/T2 | 237-02, 237-05, 237-06 | 0, 1, 2 | ADM-05 | T-237-03, T-237-04, T-237-05, T-237-10..15 | Wave 0 prepares green action/result fixtures; plans 05/06 add and green stale-dispatch and outcome assertions | LiveView + action contract | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs`; `cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs` | Existing action suites; fixtures by 237-02 and stale-dispatch/result checks by 237-05/06 | green |
| 237-03-T1/T2; 237-07-T1/T2 | 237-03, 237-07 | 0, 1 | ADM-06 | T-237-06, T-237-07, T-237-16..18 | Wave 0 prepares green raw event/window/owner fixtures; plan 07 adds and greens currency/history/return assertions | Query/LiveView | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | Existing recovery suite; fixtures by 237-03 and currency/history/navigation checks by 237-07 | green |
| 237-08-T1/T2 | 237-08 | 3 | ADM-02, ADM-05, ADM-06 | T-237-19, T-237-20 | Read-only served navigation and staged-review inspection, focus/cancel, 320px reflow, due-date/unavailable state and visible row action, theme, assets, denial of a real Beta-owned invoice under Alpha scope, and read-error; no confirm or dispatch | Playwright | `cd examples/accrue_host && npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop`; `cd examples/accrue_host && npx playwright test --list e2e/phase237-admin-billing.spec.js` | Phase-owned browser spec; existing blocking playwright-e2e discovery. Fake-backed LiveView plans 05/06 own pending, duplicate-submit, and result assertions. | green |

## Criterion Evidence Index

Every surfaced UI consideration and spec-less edge resolution has an owning implementation task, threat reference, and deterministic command. Wave 0 provides passing current-source characterization and reusable fixtures; each implementation task adds its new behavior assertions and turns them green before completion.

| Criterion | Exact acceptance claim | Task | Plan | Wave | Threat Ref | Automated command |
|---|---|---|---|---|---|---|
| UI-01 invoice-collection / empty | Distinguish first-run, genuinely empty, and filtered-empty states; a failed read renders an error, never the empty state. | 237-04-T1 | 237-04 | 1 | T-237-08 | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs` |
| UI-02 invoice-collection / loading | Keep read/filter progress with its initiating collection; do not imply payment success or suppress the last confirmed scope while pending. | 237-04-T1 | 237-04 | 1 | T-237-08 | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs` |
| UI-03 invoice-collection / error | Show actionable read error and retry; do not render an empty list or disclose records outside authorized scope. | 237-04-T1 | 237-04 | 1 | T-237-08 | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs` |
| UI-04 invoice-collection / populated | Show stored lifecycle separately from overdue, plus exact supported amount/currency, due-date fact, identity, and available action. | 237-04-T1 | 237-04 | 1 | T-237-08 | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs` |
| UI-05 invoice-collection / partial | Missing due date, money, currency, or processor evidence renders unavailable; never infer overdue, USD, zero, or completion. | 237-04-T1 | 237-04 | 1 | T-237-08 | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs` |
| UI-06 invoice-collection / overflow | At 320 CSS px, preserve identity, lifecycle/result, exact amount/currency, due date, and action without page-level horizontal scroll or hover-only facts. | 237-08-T1 | 237-08 | 3 | T-237-19 | `cd examples/accrue_host && npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` |
| UI-07 invoice-collection / zero-one-many | Automated fixtures cover zero, one, and multiple invoice rows with appropriate singular/plural copy and item actions; do not synthesize totals. | 237-04-T1 | 237-04 | 1 | T-237-08 | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs` |
| UI-08 invoice-collection / long-text | Long customer names, invoice IDs, and error reasons wrap or use deliberate disclosure without clipping amount, status, or action labels. | 237-08-T1 | 237-08 | 3 | T-237-19 | `cd examples/accrue_host && npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` |
| UI-09 invoice-charge-detail-actions / loading | After submit, keep the initiating action pending/disabled to prevent duplicates; pending does not claim acceptance, completion, or processor settlement. | 237-05-T1 / 237-06-T2 | 237-05 / 237-06 | 2 / 1 | T-237-10 / T-237-14 | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs; cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs` |
| UI-10 invoice-charge-detail-actions / error | If authorization, eligibility, or reviewed amount/currency changes before dispatch, cancel, refresh the scoped view, and announce the changed record; keep ambiguous outcomes unconfirmed. | 237-05-T1 / 237-06-T2 | 237-05 / 237-06 | 2 / 1 | T-237-10 / T-237-14 | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs; cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs` |
| UI-11 invoice-charge-detail-actions / overflow | At 320 CSS px, the reviewed record, exact amount/currency when known, action, consequence, and confirm/cancel controls remain visible and operable. | 237-08-T1 | 237-08 | 3 | T-237-19 | `cd examples/accrue_host && npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` |
| UI-12 invoice-charge-detail-actions / long-text | Long record IDs and processor/error reasons wrap or use deliberate disclosure while exact target and action consequence remain legible. | 237-08-T1 | 237-08 | 3 | T-237-19 | `cd examples/accrue_host && npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` |
| UI-13 recovery-dashboard / empty | With no observations, show route-specific empty copy and no synthetic currency buckets/totals; distinguish no data from failed read. | 237-07-T1 | 237-07 | 1 | T-237-16 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| UI-14 recovery-dashboard / loading | During recovery queries, preserve selected owner and URL-backed 7/30/90-day UTC window; do not imply fresh results before the scoped read completes. | 237-07-T1 | 237-07 | 1 | T-237-16 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| UI-15 recovery-dashboard / error | Show a recoverable read error distinct from no activity and preserve only validated owner/window/return context. | 237-07-T1 | 237-07 | 1 | T-237-16 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| UI-16 recovery-dashboard / populated | Keep owner and UTC window, group observed amounts by currency, and label historical failures separately from current invoice/subscription state. | 237-07-T1 | 237-07 | 1 | T-237-16 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| UI-17 recovery-dashboard / partial | Missing/unsupported currency, date, or owner data renders unavailable; preserve known currency groups without inventing zero totals or current state. | 237-07-T1 | 237-07 | 1 | T-237-16 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| UI-18 recovery-dashboard / overflow | At 320 CSS px, preserve identity, owner, selected window, currency grouping, and essential links without page-level horizontal scroll. | 237-08-T1 | 237-08 | 3 | T-237-19 | `cd examples/accrue_host && npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` |
| UI-19 recovery-dashboard / zero-one-many | Automated fixtures cover zero, one, and multiple recovery rows while preserving window/owner scope, currency separation, and appropriate copy. | 237-07-T1 | 237-07 | 1 | T-237-16 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| UI-20 recovery-dashboard / long-text | Long customer IDs and failure reasons wrap or use deliberate disclosure without obscuring currency, history labels, or related-record links. | 237-08-T1 | 237-08 | 3 | T-237-19 | `cd examples/accrue_host && npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` |
| EDGE-01 ADM-02/boundary | Derive overdue only from stored open status and an applicable due date that is strictly before the established current-date boundary; test due date before, equal to, and after the boundary, plus missing date. | 237-04-T1 | 237-04 | 1 | T-237-08 | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs` |
| EDGE-02 ADM-02/adjacency | Invoices with equal due dates, amounts, or statuses remain distinct records; equality in displayed values never merges, overwrites, or hides a row. | 237-04-T1 | 237-04 | 1 | T-237-08 | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs` |
| EDGE-03 ADM-02/empty | Empty collections, one invoice, and missing/null due-date or money observations render distinct truthful states; no synthetic zero or currency is introduced. | 237-04-T1 | 237-04 | 1 | T-237-08 | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs` |
| EDGE-04 ADM-02/encoding | The displayed currency identifier and amount remain a faithful representation of supported input; customer-facing text does not split or corrupt Unicode identifiers. | 237-04-T2 | 237-04 | 1 | T-237-09 | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs` |
| EDGE-05 ADM-02/ordering | Keep separate invoices in the existing canonical collection order; equal sort keys retain a deterministic stable record order across identical reads. | 237-04-T1 | 237-04 | 1 | T-237-08 | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs` |
| EDGE-06 ADM-02/precision | Format integer minor units only with the supported currency precision, including true zero and zero-/three-decimal currencies; do not round, overflow, or substitute currency. | 237-04-T2 | 237-04 | 1 | T-237-09 | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs` |
| EDGE-07 ADM-05/boundary | Dispatch only the exact reviewed amount/currency for a currently eligible target; an amount or currency change, zero/missing unsupported amount, or target becoming ineligible blocks dispatch. | 237-05-T1 / 237-06-T2 | 237-05 / 237-06 | 2 / 1 | T-237-10 / T-237-14 | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs; cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs` |
| EDGE-08 ADM-05/empty | With no eligible invoice/charge action or a missing target/amount/currency, expose no unsupported confirm action and do not submit a fabricated value. | 237-05-T1 / 237-06-T2 | 237-05 / 237-06 | 2 / 1 | T-237-10 / T-237-14 | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs; cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs` |
| EDGE-09 ADM-05/encoding | Confirmation and result copy preserve the exact supported amount and currency identifier and name the actual action/consequence; long or unusual evidence text remains legible. | 237-05-T1 / 237-06-T2 | 237-05 / 237-06 | 2 / 1 | T-237-10 / T-237-14 | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs; cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs` |
| EDGE-10 ADM-05/precision | Payment/finalization/refund review uses exact integer minor units and currency-specific 0-/3-decimal formatting, preserving real zero and never converting through a lossy float. | 237-05-T1 / 237-06-T2 | 237-05 / 237-06 | 2 / 1 | T-237-10 / T-237-14 | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs; cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs` |
| EDGE-11 ADM-05/idempotency | Repeated confirm input cannot duplicate a dispatch; ambiguous outcomes remain unconfirmed and are not automatically retried, while existing per-operation idempotency remains intact. | 237-05-T1 / 237-06-T2 | 237-05 / 237-06 | 2 / 1 | T-237-10 / T-237-14 | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs; cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs` |
| EDGE-12 ADM-05/concurrency | Immediately before dispatch, including after step-up, reload and reauthorize the same owner-scoped target and recheck eligibility and reviewed facts; stale scope/state cancels without a write. | 237-05-T1 / 237-06-T2 | 237-05 / 237-06 | 2 / 1 | T-237-10 / T-237-14 | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs; cd accrue_admin && mix test test/accrue_admin/live/charge_live_test.exs` |
| EDGE-13 ADM-06/boundary | For selected 7/30/90-day windows, use the established UTC bounds and inclusive query edges; deterministic fixtures cover exactly-at and one-step-before/after bounds. | 237-07-T1 / 237-07-T2 | 237-07 | 1 | T-237-16 / T-237-17 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| EDGE-14 ADM-06/adjacency | Recovery observations that share timestamps or campaign anchors remain distinct by their canonical record/event identity; boundary events are neither merged nor counted twice within a selected window. | 237-07-T1 / 237-07-T2 | 237-07 | 1 | T-237-16 / T-237-17 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| EDGE-15 ADM-06/empty | No observations renders the recovery empty state with no fabricated currency bucket/zero total; one observation and absent observation remain distinguishable. | 237-07-T1 / 237-07-T2 | 237-07 | 1 | T-237-16 / T-237-17 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| EDGE-16 ADM-06/encoding | Preserve each observed currency as its own labeled bucket and format supported amounts by its currency exponent; unknown/missing currency stays unavailable and is never relabeled USD. | 237-07-T1 / 237-07-T2 | 237-07 | 1 | T-237-16 / T-237-17 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| EDGE-17 ADM-06/ordering | Keep the existing deterministic grouping and row order for equal event times/campaign anchors; repeated reads of the same scoped window return the same distinct rows. | 237-07-T1 / 237-07-T2 | 237-07 | 1 | T-237-16 / T-237-17 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| EDGE-18 ADM-06/precision | Recovered/lost measures retain exact integer minor units within each currency bucket, including zero-/three-decimal currencies; never sum across currencies or synthesize missing values. | 237-07-T1 / 237-07-T2 | 237-07 | 1 | T-237-16 / T-237-17 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| EDGE-19 ADM-06/idempotency | Selecting the same owner and window repeatedly is read-only and does not mutate invoices/subscriptions or duplicate recovery evidence. | 237-07-T1 / 237-07-T2 | 237-07 | 1 | T-237-16 / T-237-17 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |
| EDGE-20 ADM-06/concurrency | A window/owner navigation change renders only the latest URL-selected, server-authorized scope; a prior or stale read cannot overwrite newer selection or current billing state. | 237-07-T1 / 237-07-T2 | 237-07 | 1 | T-237-16 / T-237-17 | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs` |

## Source Coverage Audit

| Source | Item | Plan | Status |
|---|---|---|---|
| GOAL | Exact scoped evidence-based invoice, payment, refund, recovery work; all five ROADMAP success criteria | 237-01..08 | COVERED |
| REQ | ADM-02 | 237-01, 237-04, 237-08 | COVERED |
| REQ | ADM-05 | 237-02, 237-05, 237-06, 237-08 | COVERED |
| REQ | ADM-06 | 237-03, 237-07, 237-08 | COVERED |
| RESEARCH | Stored lifecycle/overdue, exact money, no currency fallback | 237-01, 237-04, 237-06, 237-07 | COVERED |
| RESEARCH | Fresh scoped review/step-up and result mapping | 237-02, 237-05, 237-06 | COVERED |
| RESEARCH | Recovery owner/window/currency/history/return context | 237-03, 237-07 | COVERED |
| RESEARCH | Served browser proof in existing CI | 237-08 | COVERED |
| CONTEXT | D-01, D-02 | 237-01, 237-04, 237-06, 237-07 | COVERED |
| CONTEXT | D-03, D-04 | 237-02, 237-05, 237-06 | COVERED |
| CONTEXT | D-05 | 237-03, 237-07 | COVERED |
| CONTEXT | D-06, D-07 | 237-01..08 | COVERED |

## Spec-less Prohibition Precision Pass

Recall considered status shaming, invented currency/amounts, unsupported provider capability, false settlement claims, historical failure framed as current debt, foreign-owner leaks, duplicate writes, and routine rendering/ordering faults. Precision kept product-specific transparency and harm claims in plan `must_haves.prohibitions`, descriptor-less and flagged-unverified. Money/date/ordering/race correctness belongs to the 20 edge checks; generic cross-owner access control belongs to the ASVS L1 threat model. No canon OWASP/GDPR prohibition was minted.

## Wave 0 Requirements

- [x] 237-01-T1/T2: Keep the current scoped invoice route green and provide passing raw date, lifecycle, zero/0-/3-decimal money, row-count, and owner fixtures. Plan 04 owns the new presentation assertions.
- [x] 237-02-T1/T2: Keep current invoice/refund action suites green and provide passing target, step-up, eligibility, amount/currency, and result-contract fixtures. Plans 05/06 own new stale-dispatch and outcome assertions.
- [x] 237-03-T1/T2: Keep current recovery suite green and provide passing raw currency/event, UTC boundary, owner, window, target, and return-context fixtures. Plan 07 owns new currency, history/current, and navigation assertions.
- [x] 237-08-T1/T2: Add one representative read-only served Admin browser journey for navigation, staged-review inspection/cancel, focus, 320px reflow, theme, assets, and denied/read-error UI in the existing blocking host CI lane. Do not confirm or dispatch; plans 05/06 prove pending, duplicate-submit, and results.
- [x] No new test framework or provider credential setup is required.

## Manual-Only Verifications

All stable in-scope acceptance behavior should have automated ExUnit/LiveView or served-browser evidence; human UAT is not required for phase acceptance. Deterministic Fake/provider fixtures do not prove live-provider parity. Do not make a live-provider appearance or remote outcome claim without its existing independent evidence.

## Validation Sign-Off

- [x] Every plan task has an automated verify command or an explicit Wave 0 dependency.
- [x] No three consecutive tasks lack automated feedback.
- [x] Wave 0 provides green fixtures for each research-identified coverage gap; plans 04–07 close the behavioral gaps with passing assertions.
- [x] No watch-mode flags.
- [x] Focused feedback latency and test results are recorded during execution.
- [x] nyquist_compliant is set true only after finalized coverage and passing evidence.

Approval: automated validation passed 2026-10-09. Initial focused ExUnit suites: 87 tests, 0 failures; post-UI-fix focused suites: 62 tests, 0 failures; served Playwright journey: 1 passed and 1 discovered; full package suite: 581 tests, 0 failures. No human UAT remains for deterministic acceptance.

## Final Regression Gate (2026-10-09 UTC)

| Scope | Automated verification | Result |
|---|---|---|
| Core | `cd accrue && mix test --warnings-as-errors` | 70 properties, 2,077 tests, 0 failures (11 excluded) |
| Admin | `cd accrue_admin && mix test --warnings-as-errors` | 581 tests, 0 failures |
| Portal | `cd accrue_portal && mix test.ci` | 110 tests, 0 failures |
| Host | `cd examples/accrue_host && mix test --warnings-as-errors` | 222 tests, 0 failures |
| Package documentation verifier | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | 46 tests, 0 failures |
| Phase 237 served browser | `cd examples/accrue_host && npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` | 1 passed after source commit `b24092fa` |
| Phase 234 subscription-detail browser | `cd examples/accrue_host && npx playwright test e2e/phase234-admin-customers-subscriptions.spec.js --project=chromium-desktop -g "Phase 234 served Admin journeys"` | 1 passed after the semantic typography change |
| Broader browser regression lanes | Existing Fake, real-query, and Braintree lanes | 14 + 1 + 12 + 14 passed, respectively |

The first full Core run exposed two stale contracts: raw type declarations in the admin stylesheet, and tests expecting missing currency to default to USD. The heading now composes the semantic `.ax-type-label` role and the built CSS was regenerated; the recovery tests now expect `nil` for absent currency. The focused documentation verifier and the complete Core/Admin suites pass after these corrections. `mix accrue_admin.assets.build` and `git diff --check` also pass.

The refreshed Phase 237 capture manifest binds 9 source files and 3 screenshots to source `b24092fa`; every source, capture, and served stylesheet hash and byte count was checked. Code review covered six files with no findings. Stable deterministic acceptance remains fully automated; no human UAT is required.

## Validation Audit 2026-10-09

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Security Audit Follow-up 2026-10-09

- Added a real Beta-owned invoice to the deterministic host seed and asserted that its detail request under Alpha scope is denied without leaking the ID or invoice number.
- The post-fix served Playwright rerun passed 1/1 after commit `3de23b59`; seed cleanup ownership is covered by `mix test test/accrue_host/seed_e2e_cleanup_test.exs`.
- The security auditor retest closed all 21 declared threats; `threats_open: 0` is recorded in `237-SECURITY.md`.
- UI audit findings are fixed: mobile cards expose date state and action, false boolean no longer leaks, pay confirmation names the action, recovery error copy matches the contract, and drawer content stays grouped. Full suite 581/581 passed; post-fix Playwright 1/1 passed and refreshed all three captures with 9 source hashes.
- Acceptance remains automated and requires no human UAT.
