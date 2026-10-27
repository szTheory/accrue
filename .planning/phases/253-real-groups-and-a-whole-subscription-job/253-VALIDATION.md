---
phase: "253"
slug: "real-groups-and-a-whole-subscription-job"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-27"
---

# Phase 253 — Validation Strategy

Execution record for the 14-task Phase 253 plan. Plans 01–05 and all three Plan 06 tasks have passing task summaries and automated evidence. The post-summary UAT generation and project contract remain pending until 253-06-SUMMARY.md is written; independent phase verification remains separate.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing ExUnit / Phoenix.LiveViewTest, Node test runner and Playwright |
| Config | accrue_admin/mix.exs; accrue_admin/playwright.phase252.config.js; existing disposable lab runner |
| Quick run | `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/subscription_live_test.exs test/accrue_admin/components/data_table_test.exs` |
| Full existing gate | `npm --prefix accrue_admin run phase252:check` passed all 21 commands on 2026-10-27; Phase 253 focused aggregate passed all 10 serial lanes |
| Runtime | Phase 252 cold compile 70,244 ms, cold DB 2,243 ms, warm DB 3,440 ms, browser 12,431 ms; Phase 253 browser lane 46,800 ms with 151 current-run cells |

## Sampling Rate

- After each task: its focused automated command and explicit failure condition in PLAN.md.
- After each wave: relevant mounted/component/browser checks; the full existing gate after shared-owner changes.
- Before phase verification: Phase 253 aggregate, generated executable acceptance, required existing regression owners and project-wide executable-UAT contract.
- Never run concurrent reset-bearing mounted suites against a shared lab. Use the existing disposable lab lane and known process identity.

## Per-Task Verification Map

All 14 actual task IDs are mapped below. Commands assume repository root; each PLAN task contains the immediately following fails_when sibling. Task rows reflect completed task summaries and executed checks; the post-summary UAT contract remains outstanding until this plan's summary is written.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Failure Signal | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|----------------|--------|
| 253-01-01 | 01 | 1 | SBK-04, UXQ-03 | T-253-01/02/03 | Real production scoped query and connected stateful story | mounted | `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_collection_transport_test.exs test/accrue_admin/live/subscriptions_live_test.exs` | transport test created in this task; list test tracked | Nonzero/zero executed transport tests or absent connected child | pass |
| 253-01-02 | 01 | 1 | SBK-04, UXQ-03 | T-253-02/03 | Compiled direct render, not metadata | manifest/browser | `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_compositions_manifest_test.exs && cd .. && node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-compositions-phase253.spec.js` | manifest test/spec created in this task; transport from 01-01 | Nonzero, zero tests, stale/missing/metadata-only render | pass |
| 253-02-01 | 02 | 2 | SBK-04, UXQ-03 | T-253-04/05/06 | State/retry/append/copy and precision | component/mounted | `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_collection_transport_test.exs test/accrue_admin/components/data_table_test.exs` | transport created 01-01; DataTable test tracked | Nonzero, skipped state, wrong target/lost/duplicate rows | pass |
| 253-02-02 | 02 | 2 | SBK-04, UXQ-03 | T-253-04/05/06 | Actual query scope, stable cursor and escaped exact values | mounted | `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/components/data_table_test.exs` | both test paths tracked | Nonzero, missing axis, foreign/duplicate row, invalid cursor replay | pass |
| 253-03-01 | 03 | 2 | SBK-05, UXQ-03 | T-253-07/08/09 | Shared whole page, routed handlers and lazy boundaries | render/mounted | `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_page_slice_test.exs && cd .. && node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/live/subscription_live_test.exs` | page slice created in this task; detail suite tracked | Nonzero, missing parity, DB-free Repo start, event regression | pass |
| 253-03-02 | 03 | 2 | SBK-05, UXQ-03 | T-253-07/08/09 | Honest incomplete/review/result and compiled page | render/manifest | `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_page_slice_test.exs && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_compositions_manifest_test.exs && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_story_slice_test.exs` | first two produced 03-01/01-02; old area test tracked | Nonzero, missing canonical/snapshot, fabricated evidence, old parity loss | pass |
| 253-04-01 | 04 | 3 | SBK-06, UXQ-03 | T-253-10/11/12/13 | Exact target, zero-dismissal effects and valid return | mounted | `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/live/subscription_journey_test.exs` | journey test created in this task | Nonzero, missing ordered leg, dismissal effect or wrong dispatch/return | pass |
| 253-04-02 | 04 | 3 | SBK-06, UXQ-03 | T-253-10/11/12/13 | Fresh authority/step-up and hostile-return controls | mounted | `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/live/subscription_journey_test.exs test/accrue_admin/live/subscription_live_test.exs` | journey produced 04-01; detail suite tracked | Nonzero, omitted axis/valid control, unauthorized effect or unsafe return | pass |
| 253-05-01 | 05 | 4 | SBK-04, UXQ-01, UXQ-03 | T-253-14/16 | Per-cell essential collection content/geometry | browser | `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_compositions_manifest_test.exs && cd .. && node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-compositions-phase253.spec.js` | spec/manifest from 01-02; helper created in this task | Nonzero, omitted/pooled cell, stale asset, hidden content or overflow | pass |
| 253-05-02 | 05 | 4 | SBK-05, SBK-06, UXQ-01, UXQ-03 | T-253-14/15/16 | Detail/review/result/return responsive truth | browser | `node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-compositions-phase253.spec.js && node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-stories-phase252.spec.js` | new spec from 01-02; Phase252 spec tracked | Nonzero, missing cell/control, clipping, misleading result or old assertion loss | pass |
| 253-05-03 | 05 | 4 | SBK-04, SBK-05, SBK-06, UXQ-01, UXQ-03 | T-253-15/16 | Actual/clean pass; independent contradictory claims fail | Node/control | `node --test --test-reporter=tap scripts/ci/verify_phase253_presentation.test.mjs scripts/ci/verify_phase252_lab_presentation.test.mjs scripts/ci/verify_phase252_heldout_attribution.test.mjs && node scripts/ci/verify_phase252_transparency.mjs --self-test --only compositions` | target/3 fixtures created in this task; original owner/tests tracked | Nonzero, zero tests, clean red, violation green or old controls changed | pass |
| 253-06-01 | 06 | 5 | SBK-04, SBK-05, SBK-06, UXQ-01, UXQ-03 | T-253-18/19 | Executed identity/source/run records and serial ownership | Node/contract | `node --test --test-reporter=tap scripts/ci/verify_phase253_compositions.test.mjs` | runner/contract target created in this task | Nonzero, zero tests, forged/skipped/stale record accepted | pass |
| 253-06-02 | 06 | 5 | SBK-04, SBK-05, SBK-06, UXQ-01, UXQ-03 | T-253-17/18 | Actual workflow/root admission and named invocation | CI contract | `node --test --test-reporter=tap scripts/ci/verify_phase252_ci_contract.test.mjs scripts/ci/verify_phase253_compositions.test.mjs && bash scripts/ci/verify_phase200_guardrail_contract.sh` | contract created in 06-02; other owners tracked | Nonzero, omitted path, accepted removal/filter mutation or old gate loss | pass |
| 253-06-03 | 06 | 5 | SBK-04, SBK-05, SBK-06, UXQ-01, UXQ-03 | T-253-18/19/20 | Complete fresh acceptance, native controls before descriptors | aggregate/acceptance | `node --test --test-reporter=tap scripts/ci/generate_phase253_acceptance.test.mjs scripts/ci/verify_phase253_compositions.test.mjs scripts/ci/verify_phase252_ci_contract.test.mjs && npm --prefix accrue_admin run phase252:check && PHASE253_RESULT_ID=<unique> node scripts/ci/verify_phase253_compositions.mjs && node scripts/ci/generate_phase253_acceptance.mjs --latest` | generator/acceptance target created in this task; runner from 06-01 | Nonzero, missing assertion/count/native proof, stale source or premature UAT | pass |

Post-summary acceptance (after 253-06-SUMMARY.md exists): `node scripts/ci/generate_phase253_acceptance.mjs --latest --write-uat && node scripts/ci/verify_executable_uat_contract.mjs --phase 253`. Fails on nonzero exit, absent/incomplete summaries, missing automated UAT or unproved items. This is pending until execution; no passing VERIFICATION.md is authored by planning.

## Creation and Dependency Map

| Producer | New checks/artifacts produced before invocation | Consumers |
|----------|-----------------------------------------------|-----------|
| 253-01-01 | collection transport test; actual transport.json | 01-02,02-01,06 |
| 253-01-02 | compiled compositions manifest/test; browser spec; generated manifest.json | 02-03 story expansion,05 browser,06 |
| 253-03-01 | whole-page slice test and source renderer/adapter/story | 03-02,04 mounted parity,05 browser |
| 253-04-01 | complete mounted journey test | 04-02,06 |
| 253-05-01 | browser content/geometry helper and current-run per-cell records | 05-02,06 |
| 253-05-03 | bounded transparency target and clean/two independent violation fixtures | 06 native descriptor/acceptance proof |
| 253-06-01 | bounded runner and Node contract test | 06-02/03 |
| 253-06-03 | acceptance generator/test; UAT only after completed summaries | final project executable-UAT contract |

Wave ownership: 01 in wave 1; 02 and 03 in wave 2 have disjoint writes; 04 in wave 3; 05 in wave 4; 06 in wave 5. Mutable lab commands remain serial even where source planning permits independent execution. Native prohibition metadata initially stays descriptorless/flagged-unverified in 253-05; promotion is an execution task conditioned on actual controls and required admission. Two current edge assumptions (SBK-05 and UXQ-01 unclassified) and four historical Phase252 unclassified assumptions stay explicit unresolved metadata.

The four-source audit is in 253-06-PLAN.md. It covers all five roadmap success criteria, all five requirement IDs, D-01 through D-08, research constraints, 10 resolved edge criteria, 26 UI criteria and both current unresolved assumptions. Coverage is planned; implementation and acceptance remain pending.

## Wave 0 Requirements

Existing frameworks, lab transport, Repo/Fake adapters and browser infrastructure suffice; install no framework or dependency. Each plan that names a new test/spec/script must create it before invoking it, and wire its real CI owner before claiming recurring coverage. The planner must enumerate these test-file creation dependencies explicitly.

## Manual-Only Verifications

None required for machine-verifiable phase acceptance. Source-bound design review is advisory and must not claim aesthetic certainty or become confirmation-only UAT. Static stories do not establish dispatch, persistence or provider completion.

## Validation Sign-Off

- [x] Every task mapped to an automated command and failure condition; all task statuses are pass.
- [x] No three consecutive tasks without automated verification.
- [x] New test files created before invocation.
- [x] No watch flags or unknown server reuse.
- [x] Requirement and security negative controls represented.
- [x] Execution evidence recorded before setting compliant/complete flags.

Approval: task execution is recorded; status remains draft, `nyquist_compliant` remains false and `wave_0_complete` remains false until the post-summary UAT generation and project contract pass. Independent phase verification then decides completion.
