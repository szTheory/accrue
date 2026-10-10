---
phase: "241"
slug: "billing-operator-journeys"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-09"
---

# Phase 241 — Validation Strategy

> Draft execution contract derived from focused research. Planning checks command paths and coverage; execution supplies behavioral evidence and measured timings.

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
| Estimated latency | Not measured during planning. Use a targeted owner per task; execution records cheap feedback latency and separates full/browser gates |

## Sampling Rate

- With each owning implementation task: add focused behavioral assertions and known-positive/negative controls; run that owner's targeted test command before committing accepted work.
- At each dependency boundary: run the affected focused integration owner; batch browser owners in 241-07.
- After the combined phase batch: build package assets before the first fresh-server browser acceptance, then run the combined Admin/host check against those bytes; use one batched desktop/narrow/effective-theme inspection, one corrective batch and at most one confirming inspection (D-19/D-20).
- Before phase verification: current automated acceptance and source/built/compiled/served provenance must be green. Phase 240 history is continuity, not fresh Phase 241 evidence.
- Never accept zero selected tests, retries that hide defects, unknown provider outcomes as completion, or URL equality as destination membership proof.

## Per-Task Verification Map

All commands assume repository-root cwd and select existing tracked owners. The new assertions are written by their owning tasks; planning did not run them. Each PLAN task pairs its exact command with a `fails_when` signal. Wave dependencies serialize overlapping source owners.

| Task | Wave | Requirement / threat | Owner and acceptance | Automated command |
|------|------|----------------------|----------------------|-------------------|
| 241-01 T1 | 1 | JRN-01 / T-241-01 | Subscription links plus exact invoice query membership | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/queries/query_modules_test.exs` |
| 241-01 T2 | 1 | JRN-01 / T-241-02 | Subscription fact and related-billing states | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/subscription_live_test.exs` |
| 241-02 T1 | 1 | JRN-02 / T-241-03, T-241-04, T-241-05 | ScopedPath decoder parity, safe fallback and current-owner rebuilding | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs` |
| 241-02 T2 | 1 | JRN-02 / T-241-03 | Invoice contextual return label and exact destination rows | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/scoped_path_test.exs` |
| 241-03 T1 | 2 | JRN-02 / T-241-06 | Payment/customer returns and same-customer tabs | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/customer_live_test.exs` |
| 241-03 T2 | 2 | JRN-02 / T-241-06, T-241-07 | Subscription return, tab and repeated-navigation controls | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/subscription_live_test.exs` |
| 241-04 T1 | 2 | JRN-03 / T-241-08 | Direct/invalid campaign returns and distinct timeline | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/analytics/campaign_live_test.exs` |
| 241-04 T2 | 2 | JRN-03 / T-241-09 | 7d/30d/90d Recovery round trips | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/analytics/recovery_live_test.exs test/accrue_admin/live/analytics/campaign_live_test.exs` |
| 241-05 T1 | 3 | JRN-04 / T-241-10 | All rendered subscription review variants and exact intent | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/subscription_live_test.exs` |
| 241-05 T2 | 3 | JRN-04 / T-241-10, T-241-11 | Subscription stale/repeated/unknown action controls | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/subscription_live_test.exs` |
| 241-06 T1 | 3 | JRN-04 / T-241-12, T-241-14 | Refund exact money, safety and result controls | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/charge_live_test.exs` |
| 241-06 T2 | 3 | JRN-04 / T-241-13, T-241-14 | Set-default/delete method review and revalidation | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/customer_live_test.exs` |
| 241-07 T1 | 4 | JRN-01..04 / T-241-15 | Build tracked package CSS/JS, then exercise keyboard, narrow, theme and reconnect owners against a fresh Playwright server | `cd accrue_admin && mix accrue_admin.assets.build && cd .. && CI=1 npm --prefix accrue_admin run e2e:phase191 && CI=1 npm --prefix accrue_admin run e2e:phase199` |
| 241-07 T2 | 4 | JRN-01..04 / T-241-15, T-241-16 | Compile Admin and host, run full Admin check and prove host-served journeys/assets from T1's build | `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test && cd ../examples/accrue_host && MIX_ENV=test mix compile --warnings-as-errors && CI=1 npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop --workers=1` |

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

No required human UAT. All phase acceptance is assigned executable assertions or bounded agent inspection with committed evidence. Subjective owner feedback is optional. Actual browser zoom, physical-device behavior, screen-reader speech and live-provider fidelity are honest evidence limits, not recurring handoff gates.

## CI and Evidence Ownership

Use existing `release-gate`, Admin guardrails, component and `host-integration` lanes where they already execute the changed owners. Preserve Linux baseline guards, approved masks and pixel thresholds; final reviewed Linux goldens belong to Phase 243. Do not claim remote CI ran during planning.

## Validation Sign-Off

- [x] Final task map has exact IDs/waves and unique `T-241-NN` references.
- [x] Every task has a runnable automated command and immediately paired observable failure signal.
- [ ] No three consecutive tasks lack automated feedback; no watch mode or zero-test acceptance.
- [ ] New scenarios and fixture prerequisites are covered with owning implementation.
- [x] Command directories/scripts and tracked owner paths were checked at planning; selected test counts remain execution evidence.
- [ ] Execution timings, current evidence and automated UAT are recorded.
- [ ] Validation audit sets `nyquist_compliant: true` only after its evidence gate.

**Approval:** Pending execution evidence; no tests ran during planning.
