---
phase: "234"
slug: "admin-customers-subscriptions"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-07"
---

# Phase 234 — Validation Strategy

> Execution-time validation contract. No application tests, builds, browser runs, or new render captures have run during planning. Task IDs, waves, checks and threat references below are planning assignments; results remain pending execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing ExUnit/LiveView tests and Playwright adopter-host lane |
| Config files | `accrue_admin/mix.exs`, `examples/accrue_host/playwright.config.js`, `examples/accrue_host/package.json` |
| Quick action run | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/step_up_test.exs` |
| Quick investigation run | `cd accrue_admin && mix test test/accrue_admin/components/global_search_test.exs test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/scoped_path_test.exs` |
| Package suite | `cd accrue_admin && mix test` |
| Served asset build | `cd accrue_admin && mix accrue_admin.assets.build` |
| Planned browser run | `cd examples/accrue_host && npm run e2e -- e2e/phase234-admin-customers-subscriptions.spec.js e2e/verify01-admin-denial.spec.js --workers=1` |
| Pre-layout served capture | Before LiveView layout edits, build assets, then run once: `cd examples/accrue_host && PHASE234_CAPTURE_BASELINE=1 npm run e2e -- e2e/phase234-pre-layout.spec.js --workers=1`. The spec fails if the destination exists. Subsequent `cd examples/accrue_host && npm run e2e -- e2e/phase234-pre-layout.spec.js --workers=1` reads and hash-checks preserved manifest/images without writing. Reads use the archive-aware phase evidence resolver. |
| Runtime | Not measured in planning; establish during execution. Prefer focused feedback under 30 seconds where practical; browser startup is separately accounted for. |

## Sampling Rate

- After each behavior task, run its focused automated check with positive controls and observable failure signals.
- At each wave, run the relevant combined suites; run the Admin package suite and the finite browser lane before phase verification.
- Rebuild the actual served Admin assets before browser evidence. The pre-layout manifest records pre-edit source SHA, source/image byte hashes and provenance; later checks preserve those original bytes and do not compare that historical SHA to current source. Post-layout captures use a distinct destination with current source/asset provenance.
- An unavailable environment, skipped assertion, zero matching tests, or unrun command is not passing evidence. Fix the owned fixture/application failure before restoring the existing skipped mounted denial test.
- Keep browser assertions for DOM, navigation, focus, interaction, reflow and served appearance; exercise pure lifecycle/money and most forged-action cases at the cheaper ExUnit layer.

## Behavior Verification Map

The final per-task/wave/threat map is below. Planning ran no application tests, builds, browser sessions, or new render captures; all results remain pending execution.

| Task / wave | Requirements | Check and threat refs | Status |
|---|---|---|---|
| 234-01 T1 / 1 | ADM-03 SAFE-01 | One-time pre-layout capture before edits, followed by read-only manifest/image hash verification and bounded ScopedPath return validation; T-234-01/02; default-mode baseline spec plus `cd accrue_admin && mix test test/accrue_admin/scoped_path_test.exs` | Pending |
| 234-01 T2 / 1 | ADM-03 SAFE-01 | Scoped subscription list/detail/return, labels and invalid cursor; T-234-01/02; `cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/scoped_path_test.exs` | Pending |
| 234-02 T1 / 1 | ADM-01 ADM-03 SAFE-01 | Same-scope Home facts/links; T-234-03; `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs` | Pending |
| 234-02 T2 / 1 | ADM-03 SAFE-01 | Three bounded search groups, partial failure, stale invalidation; T-234-04/05; `cd accrue_admin && mix test test/accrue_admin/components/global_search_test.exs` | Pending |
| 234-07 T1 / 2 | ADM-03 SAFE-01 | Customer tabs/list context/alternate mount/forged return; T-234-16/17; `cd accrue_admin && mix test test/accrue_admin/live/customers_live_test.exs test/accrue_admin/live/customer_live_test.exs` | Pending |
| 234-07 T2 / 2 | ADM-03 SAFE-01 | Subscription-origin invoice/payment contextual return and denial; T-234-16/17; `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs` | Pending |
| 234-03 T1 / 3 | ADM-01 | Lifecycle separate from ancillary absence, exact money; T-234-06; `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs` | Pending |
| 234-03 T2 / 3 | ADM-01 ADM-03 | Read immutable Plan 234-01 pre-layout evidence via archive-aware resolver; detail hierarchy and technical disclosure; T-234-07; `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/subscription_live_test.exs` | Pending |
| 234-04 T1 / 4 | ADM-04 SAFE-01 | Provider/core/lifecycle/item matrix and forged event; T-234-08/09; `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` | Pending |
| 234-04 T2 / 4 | ADM-04 SAFE-01 | Fresh scope/target/review after step-up; T-234-08/09; `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/step_up_test.exs` | Pending |
| 234-05 T1 / 5 | ADM-04 SAFE-01 | Stable operation ID, duplicate guard, reconnect; T-234-10; `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/live/step_up_test.exs` | Pending |
| 234-05 T2 / 5 | ADM-04 SAFE-01 | Ambiguity, scoped original/replacement refresh; T-234-11/12; `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` | Pending |
| 234-06 T1 / 6 | ADM-01 ADM-03 ADM-04 SAFE-01 | Served focus/reflow/themes/source provenance and distinct post-layout captures; T-234-14/15; `cd examples/accrue_host && npm run e2e -- e2e/phase234-admin-customers-subscriptions.spec.js --workers=1` | Pending |
| 234-06 T2 / 6 | SAFE-01 | Restored mounted denial and CI; T-234-13/14; `cd examples/accrue_host && npm run e2e -- e2e/phase234-admin-customers-subscriptions.spec.js e2e/verify01-admin-denial.spec.js --workers=1` | Pending |

| Behavior group | Requirement | Secure behavior | Layer | Command / file | Current state |
|---|---|---|---|---|---|
| Known lifecycle and truthful amount/date observations | ADM-01 | Ancillary gaps do not rewrite known lifecycle or invent amount/currency/due date | Unit and LiveView | Existing subscription list/detail tests; focused presentation tests as needed | Assertions pending |
| Search, scope and investigation navigation | ADM-03, SAFE-01 | Three bounded query groups; partial failure distinct from no match; stale results invalidated; labels match target; validated mount-local return state preserves filters/tab/current scope | Query, component, LiveView, representative browser | Quick investigation run plus planned host browser file | Assertions pending |
| Eligible action and fresh review | ADM-04, SAFE-01 | Current actor/scope/target/items/provider/lifecycle and step-up rechecked at dispatch, including after challenge delay | Unit and LiveView | Quick action run | Assertions pending |
| Intent, uncertainty and scoped replacement result | ADM-04, SAFE-01 | Logical staged operation identity is reused; duplicate dispatch suppressed; reconnect does not replay; ambiguity is unconfirmed; result refresh and replacement link are scoped | LiveView with deterministic processor fixtures | Quick action run | Assertions pending |
| Mounted positive and denial controls | SAFE-01 | Two-owner and customer-manager denial paths reveal no foreign identity or payment-token data; authorized counterpart succeeds | LiveView and host browser | `examples/accrue_host/e2e/verify01-admin-denial.spec.js` plus action tests | Diagnose existing skip |
| Real keyboard, responsive and theme behavior | ADM-03, ADM-04, SAFE-01 | Focus/close/restore/nested modal stack, visible focus, noncolor state cues, 320px and coarse targets, light/dark/system, long and empty/error states | Host browser and current served captures | Planned phase234 host browser file | New assertions/file pending |

## Wave 0 Requirements

- [x] Bind every implementation task to an executable check, existing or created in the same/dependency task; finalize per-task map and unique threat references in the plans.
- [ ] Inspect existing deterministic auth, two-owner, step-up, and processor fixtures; repair only seams required by these flows.
- [ ] Create `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js` in the host lane, with positive controls and finite representative journeys.
- [ ] Diagnose the existing mounted denial skip before restoring it; retain its meaningful failure direction.
- [ ] Reuse existing package/host tools. No new test framework, provider credentials, dependency install, or exhaustive screenshot matrix is part of the plan.

## Manual-Only Verifications

None required for phase behavior. Project policy requires automated acceptance and `human_judgment: false`; current served visual inspection supplements executable checks without introducing recurring human UAT or claiming accessibility certification.

## Spec-less Edge Classification and Source Audit

The spec-less edge report contains four `unclassified/unresolved` rows, one each for ADM-01, ADM-03, ADM-04 and SAFE-01. They remain flagged classification assumptions, neither resolved nor backstop evidence. Concrete acceptance is independently set by CONTEXT D-01–D-28, REQUIREMENTS and the task map. Execution/verification must review any surviving bespoke item, retaining an unresolved flag when its classification still lacks source support. Routine engineering and canonical security duplicates are filtered under the precision/canon referral rule.

| Source | Coverage |
|---|---|
| ROADMAP goal | 234-01/02 establish discovery; 234-07 completes customer/related return; 234-03 lifecycle truth; 234-04/05 supported action; 234-06 served proof. |
| Requirements | ADM-01: 02/03/06; ADM-03: 01/02/07/03/06; ADM-04: 04/05/06; SAFE-01: 01/02/07/04/05/06. |
| CONTEXT | D-01–D-09: 01/02/07/03; D-10–D-12: 02/03; D-13–D-18: 04/05; D-19–D-23: 03/06; D-24–D-26: 01/02/07/03/04/05; D-27–D-28: 01/03/06. Deferred items excluded. |
| RESEARCH | Scoped queries/navigation in 01/07, three search groups in 02, core/provider action matrix in 04, step-up/operation identity and uncertainty/replacement link in 04/05, finite host browser evidence in 01/06. No new integration, dependency, schema push or public API. |

Before browser evidence, run `cd accrue_admin && mix accrue_admin.assets.build` and retain source SHA, built and served asset hash, route, fixture/owner, viewport, theme and state. The existing `playwright-e2e` host CI lane must execute both new and restored specs; if unrestricted discovery does not include them, add explicit inclusion. A skipped or zero-test run fails acceptance. Run the package suite with `cd accrue_admin && mix test` before phase verification; record runtimes during execution only.

## Validation Sign-Off

### Planning review — 2026-10-07

- Independent plan checker: passed after two targeted revision rounds; no remaining blockers or warnings.
- Seven plans in six waves; all four phase requirements and all 28 tracked context decisions covered.
- Deterministic command-path and failure-direction probes: 14 commands, zero blockers, zero warnings, no read errors.
- Baseline preservation and navigation plan size findings resolved; baseline creation is distinct from read-only verification.
- These are planning checks. Implementation, application tests, served captures, and phase acceptance remain pending execution.

- [x] All planned tasks have automated verification and a stated observable failure signal.
- [x] No three consecutive planned tasks lack automated feedback.
- [x] Newly named test files are assigned to their task or an earlier dependency.
- [x] Planned commands use the actual package/host working directory and no watch mode.
- [ ] Runtime and result evidence are recorded during execution.
- [ ] Phase completion includes automated UAT, committed summaries, passed verification, and `behavior_unverified: 0`.
- [ ] `nyquist_compliant: true` is set only when warranted by finalized coverage.

**Approval:** Per-task map planned; execution supplies results.
