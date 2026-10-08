---
phase: "234"
slug: "admin-customers-subscriptions"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-07"
---

# Phase 234 — Validation Strategy

> Execution-time validation contract. No application tests, builds, browser runs, or new render captures have run during planning. The planner must bind the behavior groups below to final task IDs, waves, and threat references before planning completes.

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
| Runtime | Not measured in planning; establish during execution. Prefer focused feedback under 30 seconds where practical; browser startup is separately accounted for. |

## Sampling Rate

- After each behavior task, run its focused automated check with positive controls and observable failure signals.
- At each wave, run the relevant combined suites; run the Admin package suite and the finite browser lane before phase verification.
- Rebuild the actual served Admin assets before browser evidence. Preserve source SHA, route, viewport, theme, and fixture/state provenance in captures.
- An unavailable environment, skipped assertion, zero matching tests, or unrun command is not passing evidence. Fix the owned fixture/application failure before restoring the existing skipped mounted denial test.
- Keep browser assertions for DOM, navigation, focus, interaction, reflow and served appearance; exercise pure lifecycle/money and most forged-action cases at the cheaper ExUnit layer.

## Behavior Verification Map

Task IDs, waves, and unique `T-234-NN` threat references will be filled from finalized plans. These groups are acceptance scope, not a proposed separate horizontal test phase.

| Behavior group | Requirement | Secure behavior | Layer | Command / file | Current state |
|---|---|---|---|---|---|
| Known lifecycle and truthful amount/date observations | ADM-01 | Ancillary gaps do not rewrite known lifecycle or invent amount/currency/due date | Unit and LiveView | Existing subscription list/detail tests; focused presentation tests as needed | Assertions pending |
| Search, scope and investigation navigation | ADM-03, SAFE-01 | Three bounded query groups; partial failure distinct from no match; stale results invalidated; labels match target; validated mount-local return state preserves filters/tab/current scope | Query, component, LiveView, representative browser | Quick investigation run plus planned host browser file | Assertions pending |
| Eligible action and fresh review | ADM-04, SAFE-01 | Current actor/scope/target/items/provider/lifecycle and step-up rechecked at dispatch, including after challenge delay | Unit and LiveView | Quick action run | Assertions pending |
| Intent, uncertainty and scoped replacement result | ADM-04, SAFE-01 | Logical staged operation identity is reused; duplicate dispatch suppressed; reconnect does not replay; ambiguity is unconfirmed; result refresh and replacement link are scoped | LiveView with deterministic processor fixtures | Quick action run | Assertions pending |
| Mounted positive and denial controls | SAFE-01 | Two-owner and customer-manager denial paths reveal no foreign identity or payment-token data; authorized counterpart succeeds | LiveView and host browser | `examples/accrue_host/e2e/verify01-admin-denial.spec.js` plus action tests | Diagnose existing skip |
| Real keyboard, responsive and theme behavior | ADM-03, ADM-04, SAFE-01 | Focus/close/restore/nested modal stack, visible focus, noncolor state cues, 320px and coarse targets, light/dark/system, long and empty/error states | Host browser and current served captures | Planned phase234 host browser file | New assertions/file pending |

## Wave 0 Requirements

- [ ] Bind every implementation task to an executable check, existing or created in the same/dependency task; finalize per-task map and unique threat references.
- [ ] Inspect existing deterministic auth, two-owner, step-up, and processor fixtures; repair only seams required by these flows.
- [ ] Create `examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js` in the host lane, with positive controls and finite representative journeys.
- [ ] Diagnose the existing mounted denial skip before restoring it; retain its meaningful failure direction.
- [ ] Reuse existing package/host tools. No new test framework, provider credentials, dependency install, or exhaustive screenshot matrix is part of the plan.

## Manual-Only Verifications

None required for phase behavior. Project policy requires automated acceptance and `human_judgment: false`; current served visual inspection supplements executable checks without introducing recurring human UAT or claiming accessibility certification.

## Validation Sign-Off

- [ ] All tasks have automated verification and a stated observable failure signal.
- [ ] No three consecutive tasks lack automated feedback.
- [ ] Newly named test files are created by their task or an earlier dependency.
- [ ] Commands use the actual package/host working directory and no watch mode.
- [ ] Runtime and result evidence are recorded during execution.
- [ ] Phase completion includes automated UAT, committed summaries, passed verification, and `behavior_unverified: 0`.
- [ ] `nyquist_compliant: true` is set only when warranted by finalized coverage.

**Approval:** Draft; planning binds task coverage, execution supplies results.
