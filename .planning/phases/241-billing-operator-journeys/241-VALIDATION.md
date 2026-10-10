---
phase: "241"
slug: "billing-operator-journeys"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-09"
---

# Phase 241 — Validation Strategy

> Execution audit: every planned task is backed by a focused behavioral owner and the combined phase gates passed. The evidence and limits below distinguish browser viewport simulations from physical zoom/device/provider observations.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing ExUnit/Phoenix LiveViewTest, Node tests, package Playwright and mounted host Playwright |
| Config | `accrue_admin/playwright.config.js`, `examples/accrue_host/playwright.config.js`, existing Mix/test setup |
| Quick navigation command | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs` |
| Quick action command | Run the changed action owner's existing LiveView test file, as concretely bound in its PLAN |
| Full Admin server command | `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test` |
| Package browser owner | Existing Phase 191 page-flow and Phase 199 overlay owners; exact focused title/selection must include new cases and report a nonzero executed count |
| Host browser owner | `cd examples/accrue_host && npm run e2e -- e2e/phase237-admin-billing.spec.js --project=chromium-desktop --workers=1` |
| Assets | `cd accrue_admin && mix accrue_admin.assets.build` runs once in 241-07 T1 before package browsers; tracked CSS/JS are retained for T2 Admin/host compile and HTTP-served byte proof |
| Recorded task durations | 241-01 4 min; 241-02 5 min; 241-03 5 min; 241-04 5 min; 241-05 8 min; 241-06 9 min; 241-07 summary records 66 min in Performance and 228 min in metrics (source discrepancy retained) |

## Sampling Rate

- With each owning implementation task: add focused behavioral assertions and known-positive/negative controls; run that owner's targeted test command before committing accepted work.
- At each dependency boundary: run the affected focused integration owner; batch browser owners in 241-07.
- After the combined phase batch: build package assets before the first fresh-server browser acceptance, then run the combined Admin/host check against those bytes; use one batched desktop/narrow/effective-theme inspection, one corrective batch and at most one confirming inspection (D-19/D-20).
- Before phase verification: current automated acceptance and source/built/compiled/served provenance must be green. Phase 240 history is continuity, not fresh Phase 241 evidence.
- Never accept zero selected tests, retries that hide defects, unknown provider outcomes as completion, or URL equality as destination membership proof.

## Per-Task Verification Map

All commands assume repository-root cwd and select existing tracked owners. Every command below ran during execution; task-level behavioral evidence is cross-referenced in its SUMMARY. Each PLAN task pairs its command with a `fails_when` signal. Wave dependencies serialize overlapping source owners.

| Task | Wave | Requirement / threat | Owner and acceptance | Automated command |
|------|------|----------------------|----------------------|-------------------|
| 241-01 T1 | 1 | JRN-01 / T-241-01 | PASS — exact customer and authorized-scope invoice IDs, distinct filters | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/queries/query_modules_test.exs` |
| 241-01 T2 | 1 | JRN-01 / T-241-02 | PASS — lifecycle, missing observations, empty sets and supported actions | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/subscription_live_test.exs` |
| 241-02 T1 | 1 | JRN-02 / T-241-03, T-241-04, T-241-05 | PASS — validated local origins, hostile/cross-mount controls, owner rebuilding | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs` |
| 241-02 T2 | 1 | JRN-02 / T-241-03 | PASS — label/href agreement and exact authorized invoice results | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/scoped_path_test.exs` |
| 241-03 T1 | 2 | JRN-02 / T-241-06 | PASS — customer/payment return context and foreign-customer rejection | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/customer_live_test.exs` |
| 241-03 T2 | 2 | JRN-02 / T-241-06, T-241-07 | PASS — subscription list/tab restore with matching customer | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/subscription_live_test.exs` |
| 241-04 T1 | 2 | JRN-03 / T-241-08 | PASS — direct/untrusted Recovery returns and complete historical timeline | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/analytics/campaign_live_test.exs` |
| 241-04 T2 | 2 | JRN-03 / T-241-09 | PASS — 7d/30d/90d round trips, current owner and invalid default | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/analytics/recovery_live_test.exs test/accrue_admin/live/analytics/campaign_live_test.exs` |
| 241-05 T1 | 3 | JRN-04 / T-241-10 | PASS — every eligible subscription review variant names exact target/evidence | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/subscription_live_test.exs` |
| 241-05 T2 | 3 | JRN-04 / T-241-10, T-241-11 | PASS — dismissal, stale/repeated confirmation, unknown outcome controls | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/subscription_live_test.exs` |
| 241-06 T1 | 3 | JRN-04 / T-241-12, T-241-14 | PASS — exact refund amount/currency, boundary and safe-result behavior | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/charge_live_test.exs` |
| 241-06 T2 | 3 | JRN-04 / T-241-13, T-241-14 | PASS — selected method review and stale-default rejection | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/customer_live_test.exs` |
| 241-07 T1 | 4 | JRN-01..04 / T-241-15 | PASS — Phase191 28/28; Phase199 24 pass, 15 incumbent skips; new text/reflow and review cases pass | `cd accrue_admin && mix accrue_admin.assets.build && cd .. && CI=1 npm --prefix accrue_admin run e2e:phase191 && CI=1 npm --prefix accrue_admin run e2e:phase199` |
| 241-07 T2 | 4 | JRN-01..04 / T-241-15, T-241-16 | PASS — Admin compile/full suite 642/0; host compile and mounted host 1/1 pass | `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test && cd ../examples/accrue_host && MIX_ENV=test mix compile --warnings-as-errors && CI=1 npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop --workers=1` |

## Source and Probe Coverage Audit

| Source | IDs / obligation | Plans | Status |
|--------|------------------|-------|--------|
| GOAL | Truthful customer/subscription/invoice/payment/Recovery destinations, bounded returns and reviews | 01–07 | COVERED |
| REQ | JRN-01 | 01, 07 | COVERED |
| REQ | JRN-02 | 02, 03, 07 | COVERED |
| REQ | JRN-03 | 04, 07 | COVERED |
| REQ | JRN-04 | 05, 06, 07 | COVERED |
| CONTEXT | D-01..D-04 | 01 | COVERED |
| CONTEXT | D-05..D-07 | 02, 03 | COVERED |
| CONTEXT | D-08..D-09 | 04 | COVERED |
| CONTEXT | D-10..D-15 | 05, 06 | COVERED |
| CONTEXT | D-16..D-20 | 01, 02, 07 | COVERED |
| RESEARCH | Decoder parity, no added dependency, exact-money/fresh safety, current mounted and served provenance | 01–07 | COVERED |
| UI | 40 explicit E1–E7 criteria from 241-UI-SPEC.md | 01, 02, 03, 04, 05, 07 | COVERED |
| EDGE | 20 explicit JRN-01..04 criteria from 241-PROBE-COVERAGE.md | 01–07 | COVERED |

The spec-less prohibition recall/precision pass was applied separately to each requirement. The adversarial question was what each journey could silently become that the operator would reject despite a literal green implementation.

| Requirement | Recall candidates | Precision disposition |
|-------------|-------------------|-----------------------|
| JRN-01 | Misnamed customer/owner queue, hidden excluded-owner rows, inferred zero, order-dependent identity | Existing JRN-01 and E2 positive/negative acceptance owns membership, absence and identity; scope disclosure refers to T-241-01/02. |
| JRN-02 | Arbitrary redirect, cross-customer tab, stale supplied owner, ignored filter sold as retained, nested origin stack | Decoder fidelity is JRN-02 acceptance; OWASP redirect/access-control concern refers to T-241-03/04/06; nested stack is already excluded by D-07. |
| JRN-03 | Campaign opening subscriptions instead of Recovery, fabricated selected window, historical timeline described as filtered, unrelated origin accepted | Existing JRN-03/E6 acceptance owns truthful window/history; route and scope security refer to T-241-08/09. |
| JRN-04 | Inferred refund amount or settlement, generic confirmation hiding target, dismissal dispatch, blind retry, stale actor/method action | Existing JRN-04/E4/E5 acceptance owns truth and correction; fresh authorization/duplicate security refer to T-241-10..14. |

Routine correctness candidates are kept in owning tests, and security canon is referred to the threat register. No distinct project-value prohibition survives precision, so the single projectProhibitions projection is empty; no descriptor or green enforcement claim is fabricated. The schema gate found no Payload/Prisma/Drizzle/Supabase/TypeORM paths. The API detector returned `detected:false` for these plans and Phase 241 roadmap scope. Assumption-delta returned `detected:false`.

## Assertion Creation

There is no separate Wave 0. Each owning task creates its new assertion before implementation and runs its focused command. 241-01 covers result membership, 241-02/03 decoder and caller parity, 241-04 Recovery, 241-05/06 action variants and safety, and 241-07 mounted interactions/assets. Disposable mutation/reset fixtures remain separate from feedback previews.

## Manual-Only Verifications

**Required manual-only verifications: 0.** All phase acceptance has executable behavioral evidence; no human UAT gate remains. Actual browser zoom controls, physical-device behavior, screen-reader speech, live-provider outcomes, and Phase 243 Linux visual goldens were not observed and are not claimed. The reflow result is a 320 CSS-pixel viewport simulation; text enlargement doubles measured computed font sizes with WCAG text-spacing overrides.

## Execution Evidence and Limits

- Plans 241-01 through 241-06 report durations of 4, 5, 5, 5, 8, and 9 minutes. Plan 241-07 reports 66 minutes in its Performance section but 228 minutes in frontmatter metrics; this source discrepancy is preserved rather than reconciled by inference.
- The current Admin package completed `MIX_ENV=test mix compile --warnings-as-errors` and the full suite: 642 tests, 0 failures. The captured run is `/private/tmp/accrue241-wave4-test.log`.
- Browser evidence: Phase191 28 passed; Phase199 24 passed and 15 incumbent project-specific skips. One incumbent Phase199 drawer test timed out during Chromium launch at 180 seconds and passed 1/1 on isolated rerun. Both newly added Phase241 cases ran and passed. The focused responsive stress case passed across seven consumers; the review matrix passed with ten subscription and two payment-method reviews.
- Component and host evidence: AtRiskTable 6 passed; Admin and mounted-host warnings-as-errors compiles passed; the Phase237 mounted-host spec passed 1/1 after CSS rebuild and host recompile. The host run checked Recovery window/owner return and package, compiled-host, HTTP-served, and browser-request asset bytes.
- JRN-01..04 are covered by task owners 241-01..07 as mapped above. The 40 applicable UI criteria and 20 edge probes in the UI-SPEC and PROBE-COVERAGE have explicit owning evidence; they are criteria inventories, not standalone claims that physical zoom or provider behavior was observed.
- The phase SUMMARY records that automated-UAT artifact generation requires a genuine `241-VERIFICATION.md`; none was fabricated. This does not replace or weaken the executed test evidence above.

## CI and Evidence Ownership

Use existing `release-gate`, Admin guardrails, component and `host-integration` lanes where they already execute the changed owners. Preserve Linux baseline guards, approved masks and pixel thresholds; final reviewed Linux goldens belong to Phase 243. Do not claim remote CI ran during planning.

## Validation Sign-Off

- [x] Final task map has exact IDs/waves and unique `T-241-NN` references.
- [x] Every task has a runnable automated command and immediately paired observable failure signal.
- [x] No three consecutive tasks lack automated feedback; no watch mode or zero-test acceptance.
- [x] New scenarios and fixture prerequisites are covered with owning implementation and executed owners.
- [x] Command directories/scripts and tracked owner paths were checked; all task owners have behavioral evidence.
- [x] Execution timings, current evidence, caveats, and unobserved limits are recorded.
- [x] Validation audit sets `nyquist_compliant: true` after the evidence gate.

**Audit:** Validated 2026-10-10. Gaps found: 0. Resolved: all 14 planned tasks across JRN-01..04. Escalated: 0. Manual-only: 0. Phase199's incumbent launch timeout passed on isolated rerun; incumbent skips and physical/provider evidence limits are recorded above.

## Validation Audit 2026-10-10

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 14 |
| Escalated | 0 |
