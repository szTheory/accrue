---
phase: "252"
slug: "production-backed-subscription-stories"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-26"
---

# Phase 252 — Validation Strategy

> Planning contract only. No implementation tests have run. Planner must replace provisional task rows with final plan/task IDs and commands.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | ExUnit, installed Playwright Test 1.59.1, Node node:test |
| Config files | accrue_admin/mix.exs; accrue_admin/config/test.exs; accrue_admin/playwright.config.js |
| Quick existing command | `cd accrue_admin && mix test test/accrue_admin/dev/storybook_coverage_test.exs` |
| Full existing owner command | `cd accrue_admin && npm run phase200:guardrails` |
| Full phase command | Planner defines a focused phase252 command using existing frameworks and isolated disposable infrastructure |
| Runtime | Measure cold bootstrap separately from warm checks; budgets remain provisional until measured |

## Sampling Rate

- After every task: smallest relevant pure ExUnit or Node contract; every task has automated verification with stated failure signal.
- After each plan wave: relevant Repo/browser/production-boundary integration commands after DB, port and process preflight.
- Before phase verification: focused phase252 suite and existing required owner checks, generated automated UAT, no manual confirmation substitute.
- Fast feedback target: under 60 seconds where feasible; browser integration target under 3 minutes warm, CI incremental target under 5 minutes. Measure rather than assert.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|---|---|---|---|---|---|---|---|---|
| Pending final plan IDs | Pending | Pending | SBK-01, SBK-02 | Pending | Attribution and routes agree with real rendered variations | manifest + browser | Planner assigns concrete generation/reconciliation/direct URL commands | New coverage required | pending |
| Pending final plan IDs | Pending | Pending | SBK-03 | Pending | Production scope/eligibility retained | component + browser | Planner assigns 320px/desktop x light/dark commands for active/cancel/incomplete | New area proof required | pending |
| Pending final plan IDs | Pending | Pending | SCEN-01, SCEN-02 | Pending | Invalid enum/orphan/provider/amount/time rejected | pure ExUnit | Planner assigns domain-valid facts and five invalid-control tests | New tests required | pending |
| Pending final plan IDs | Pending | Pending | SCEN-03 | Pending | Only disposable Repo writes; actual constraints/relationships proved | Repo integration | Planner assigns uniquely namespaced database command and real constraint controls | New adapter proof required | pending |
| Pending final plan IDs | Pending | Pending | SCEN-04, LAB-01 | Pending | Cleanup refuses unrelated child; test reset cannot alter review DB | launcher + DB integration | Planner assigns negative reset/cleanup/server-reuse controls | New isolation proof required | pending |
| Pending final plan IDs | Pending | Pending | LAB-02 | Pending | Fixture/tooling absent from prod packages/routes/compile | package + compile + route | Planner assigns isolated production build/package inspection and mount tests | Existing analogs; new assertions required | pending |
| Pending final plan IDs | Pending | Pending | CIQ-01 | Pending | Every consumed root invokes named required owner | Node + workflow contract | Planner assigns positive path/admission and unrelated selection negative controls | New phase252 contract required | pending |

## Wave 0 Requirements

- Add pure facts/validator tests and explicit invalid controls with implementation task; do not add vacuous stubs as acceptance evidence.
- Add focused Repo adapter, exact-child cleanup preservation, two-namespace reset, occupied-port/server refusal tests.
- Add backend-generated actual variation manifest, direct browser route and viewport/theme proof.
- Add prod compile/package/route boundary and CI admission/classifier contracts, including known-negative fixtures.
- Existing frameworks suffice; no dependency installation campaign.

## Manual-Only Verifications

All phase acceptance behaviors have automated verification. Design quality claims are bounded; static rendering does not prove persistence, mounted authorization, provider effects or aesthetic excellence.

## Validation Sign-Off

- [ ] Final task map matches PLAN files and names concrete executable commands
- [ ] All tasks have automated verification and fails_when signals
- [ ] New test references are created by their owning tasks before invocation
- [ ] No watch-mode flags or owner manual-UAT gates
- [ ] Every absence assertion has a positive control
- [ ] Sampling continuity maintained
- [ ] nyquist_compliant set only when final contract is checked

Approval: pending final plans and independent checker.
