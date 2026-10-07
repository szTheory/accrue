---
phase: "233"
slug: "shared-direction-portal-contract"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-07"
---

# Phase 233 — Validation Strategy

> Execution validation contract. Phase execution and audit evidence are recorded below. Wave 1 current served baseline (233-04) precedes router/auth edits (233-01, wave 2); 233-02 follows in wave 3; 233-03 and 233-07 run independently in wave 4; host proof 233-05 runs in wave 5. Semantic CSS 233-06 is wave 2 after baseline.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing ExUnit, Phoenix.LiveViewTest, and canonical host Playwright |
| Config file | `accrue_portal/mix.exs`; canonical host Playwright configuration |
| Quick run command | `cd accrue_portal && mix test test/accrue_portal/auth_hook_test.exs test/accrue_portal/router_test.exs` |
| Full suite command | `cd accrue_portal && mix test --warnings-as-errors` |
| Estimated runtime | Portal full suite: 2.0 seconds in independent wave-5 rerun (68 tests); final review regression passed 72 tests. Context browser: 6/6; prior 4/5 audit run measured 18.5 seconds. |

## Sampling Rate

- After each behavior change, run its focused test files before committing.
- After each wave, run the Portal suite and the browser scenarios applicable to that wave.
- Before phase verification, require the full Portal suite, canonical example integration checks, docs contracts, and current served visual evidence.
- Target focused feedback under 60 seconds; measure rather than claim this target has passed.

## Per-Task Verification Map

| Task | Requirement | Threat ref | Automated command / evidence | Fails when | Status |
|------|-------------|------------|------------------------------|------------|--------|
| 233-01-T1 | POR-08, SAFE-02 | T-233-01 | `cd accrue_portal && mix test test/accrue_portal/context_contract_test.exs` | Nonzero, zero tests or missing rendered custom path and exact identity | passed |
| 233-01-T2 | SAFE-02 | T-233-01, T-233-02 | `cd accrue_portal && mix test test/accrue_portal/auth_hook_test.exs test/accrue_portal/context_contract_test.exs` | Nonzero, zero tests or absent denied/no-provision assertions | passed |
| 233-02-T1 | SAFE-02, SAFE-03 | T-233-03, T-233-04 | `cd accrue_portal && mix test test/accrue_portal/context_post_test.exs` | Nonzero, zero tests, or missing rendered default/delete producer-to-POST positive controls, switched-tab pin, denied zero-write or wrong-target assertions for either action | passed |
| 233-02-T2 | SAFE-03 | T-233-04 | `cd accrue_portal && mix test test/accrue_portal/context_post_test.exs` | Nonzero, zero tests, read-allowed/write-denied add-card mount calls client_token_for, or missing rendered producer-to-POST positive and denied controls across default/delete/create | passed |
| 233-03-T1 | POR-08, SAFE-02 | T-233-06, T-233-07 | `cd accrue_portal && mix test test/accrue_portal/context_live_test.exs` | Nonzero, zero tests or missing subscription event/reconnect cases | passed |
| 233-03-T2 | SAFE-03 | T-233-07 | `cd accrue_portal && mix test test/accrue_portal/context_live_test.exs` | Nonzero, zero tests or missing invoice direct-navigation/reconnect denial | passed |
| 233-07-T1 | SAFE-02, SAFE-03 | T-233-08, T-233-15 | `cd accrue_portal && mix test test/accrue_portal/checkout_context_test.exs` | Nonzero, zero tests, read-allowed/complete-denied mount calls client_token_for, or eligible event cannot mutate | passed |
| 233-07-T2 | SAFE-03 | T-233-05, T-233-08 | `cd accrue_portal && mix test test/accrue_portal/checkout_context_test.exs` | Nonzero, zero tests, rendered checkout form lacks context_pin, or denied/replayed POST calls provider | passed |
| 233-04-T1 | BASE-01 | T-233-10 | `node -e "const f=require('fs').readFileSync('.planning/phases/233-shared-direction-portal-contract/233-INVENTORY.md','utf8');for(const x of ['/subscriptions/:id','/payment-methods/new','/checkout/:token','/checkout/:token/complete','Admin','source SHA','historical'])if(!f.includes(x))process.exit(1)"` | Missing file or route/provenance markers | passed |
| 233-04-T2 | BASE-01 | T-233-09, T-233-10 | `cd accrue_admin && mix accrue_admin.assets.build` then `cd examples/accrue_host && npm run e2e -- e2e/phase233-baseline.spec.js --workers=1` | Build nonzero/missing asset; browser nonzero/zero tests or missing both served audiences and provenance | passed |
| 233-04-T3 | SYS-01, SYS-02 | T-233-10 | `node -e "const f=require('fs').readFileSync('.planning/phases/233-shared-direction-portal-contract/DESIGN.md','utf8');for(const x of ['--ax-','--accrue-','focus','reflow','host','motion','status'])if(!f.includes(x))process.exit(1)"` | Missing DESIGN.md or role/ownership markers | passed |
| 233-05-T1 | POR-08, SHIP-04 | T-233-11, T-233-12 | Default context spec plus dedicated Braintree config via `scripts/ci/accrue_host_verify_browser.sh` | Nonzero, zero tests or absent personal/custom/mixed, revoked/no-write, tab pin and actor cases | passed: 6 context cases plus 4 dedicated Braintree cases; SDK initialization, organization checkout denial, membership revocation, stale-pin POST denial and persisted human actor verified |
| 233-05-T2 | SHIP-04 | T-233-11 | `cd accrue_portal && mix test test/accrue_portal/readme_contract_test.exs --warnings-as-errors` | Nonzero, zero tests or docs differ from public option/callback/action symbols | passed: 2 tests |
| 233-06-T1 | SYS-01, SYS-02 | T-233-13 | `cd accrue_admin && mix accrue_admin.assets.build` | Nonzero, missing generated asset or public-token rename | passed |
| 233-06-T2 | SYS-01, SYS-02 | T-233-14 | `cd examples/accrue_host && npm run e2e -- e2e/phase233-semantic.spec.js --workers=1` | Nonzero, zero tests or stale served Portal asset | passed |

## Wave 0 Requirements

- Existing frameworks suffice; no new framework or dependency is required.
- Create meaningful adapter/identity/policy fixtures in 233-01-T1 before the expanded scenarios use them.
- Add denied, missing, deleted, explicit-invalid and unavailable selection cases; prove zero provisioning/provider writes.
- Cover all four POST routes by submitting pins extracted from rendered forms, LiveView connected/disconnected mounts, reconnect, protected navigation/events, stale form and checkout identity. Plan 02 owns all payment form producer/consumer paths; plan 07 owns checkout event and POST producer/consumer paths.
- Test read-allowed/write-denied add-card and checkout mounts with exactly zero Braintree client-token calls and zero mutation, plus eligible client-token and mutation positive controls.
- Create bounded canonical-host browser proof for current served assets in 233-04-T2, billed identity, read-only payment mount state and secure-field clearing in 233-05-T1, and CSS semantics in 233-06-T2.
- A source-only assertion or historical screenshot cannot substitute for current served behavior.

## Visual observations (no recurring manual gate)

| Behavior | Requirement | Why Direct Inspection | Instructions |
|----------|-------------|-----------------------|--------------|
| Audience identity and visual hierarchy | BASE-01, SYS-01, SYS-02 | Browser assertions cannot fully judge composition | Executor inspects current representative Admin/Portal renders; records observations and provenance alongside machine assertions. No recurring user UAT checkpoint is needed for automatable behavior. |

## Validation Sign-Off

- [x] Concrete plan task IDs, threat references and commands are synchronized.
- [x] Every task has an automated check or explicit prerequisite that supplies it.
- [x] No three consecutive tasks lack automated verification.
- [x] Every new verification target is created before it is invoked.
- [x] No watch-mode command is used.
- [x] Focused feedback timing is measured.
- [x] Execution results support `nyquist_compliant: true` and `wave_0_complete: true` before those flags change.

## Resolved Implementation Gaps

- **233-05-T1 / POR-08, SAFE-02:** Personal Customer resolution preserves the sole existing Customer for reads. The final code review corrected the earlier checkout exception: both personal and custom checkout require the exact selected Customer and configured processor before tokens or mutation. Mismatched checkout is denied with zero writes; matching Braintree personal and custom POST controls pass. Separate Fake and Braintree browser processes reflect the LocalSession provider contract.
- **233-05-T1 / SAFE-02:** Membership-only revocation initially reached the blocked page over HTTP, then its LiveView socket redirected to login. The blocked live session omitted host-provided `on_mount` hooks, including the E2E SQL Sandbox allowance. It now forwards host hooks before the user-only guard, without invoking the default customer resolver. A Router test proves this hook contract; the browser now confirms generic blocked denial after membership deletion and rejects stale-pin POST without fallback.
- Other browser proof includes personal-only Hosted Fields SDK initialization counters, read-only organization checkout with accessible denial and no Hosted Fields/submit, cross-tab pin retention, an authorized organization mutation persisted under the human `User`, and no Admin privilege bleed.
- Canonical browser commands passed: Phase233 context 6/6, Phase233 baseline and semantic plus Phase102 checkout 4/4. Full Portal suite passed 70 tests; full host suite passed 219 tests.

**Approval:** All planned validation rows and implementation gaps are resolved; the final goal verifier owns phase-level sign-off.

## Validation Audit 2026-10-07

| Metric | Count |
|---|---|
| Gaps found | 3 |
| Resolved | 2 |
| Escalated | 1 |

## Validation Audit 2026-10-07

| Metric | Count |
|---|---|
| Gaps found | 4 |
| Resolved | 3 |
| Escalated | 1 |

## Validation Audit Resolution 2026-10-07

| Metric | Count |
|---|---|
| Gaps found | 4 |
| Resolved | 4 |
| Escalated | 0 |

## Final validation reconciliation

All 15 planned task checks have passing execution evidence in their committed summaries and 233-EXECUTION-CHECKS.md. The gap rerun passed 70 Portal tests and 219 host tests. Final review corrections `d828adc9` and `3dff46b2` supersede that checkpoint with **72 Portal tests**, **219 host tests**, **27 default browser passes / 3 existing intentional skips**, and **4 dedicated Braintree browser passes**. Billing facade 18/18 and README 2/2 are included in the respective full suites. Both browser lanes run in CI and the local full-verification command. The connected blocked-page issue was fixed in `e21cb7f9`; the processor boundary now matches the no-dynamic-routing contract. No behavior is delegated to manual UAT. All four audited coverage gaps and the checkout review finding are resolved.

## Validation Audit 2026-10-07

| Metric | Count |
|---|---|
| Gaps found | 4 |
| Resolved | 4 |
| Escalated | 0 |
