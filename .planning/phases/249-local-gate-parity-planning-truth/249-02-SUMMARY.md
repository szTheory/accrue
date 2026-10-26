---
phase: 249-local-gate-parity-planning-truth
plan: "02"
subsystem: ci-gates
status: complete
completed: 2026-10-24
requirements-completed: [GREEN-05]
tags: [credo, accrue_admin, accrue_portal, flaky-test]
key-files:
  modified:
    - accrue_admin/lib/accrue_admin/live/charges_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
    - accrue_admin/lib/accrue_admin/live/coupons_live.ex
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/lib/accrue_admin/live/event_live.ex
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
    - accrue_admin/lib/accrue_admin/scoped_path.ex
    - accrue_admin/test/support/e2e_fixtures.ex
    - accrue_admin/test/accrue_admin/live/webhook_replay_test.exs
    - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
    - accrue_portal/test/accrue_portal/context_contract_test.exs
key-decisions:
  - "Credo findings fixed at source; .credo.exs untouched, no disables"
  - "Portal CustomEndpoint started with start_supervised!, already_started tolerance removed"
commits: 3
plan_head_before: 27c8168a0903c8b38c00fba70d13e3392048d517
plan_head_after: 854e9989cb4c573455a7ad4b7fef73f9144ab5e2
actuals:
  tokens: 15000
  tasks: 3
  commits: 3
coverage:
  - id: C1
    description: accrue_admin credo --strict has zero findings with unchanged config (19 fixed at source)
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "cd accrue_admin && mix credo --strict"
        status: pass
      - kind: command
        ref: "cd accrue_admin && mix test --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: C2
    description: Portal ContextContractTest no longer races a test-linked endpoint; passes across 20 random seeds
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "cd accrue_portal && mix test --warnings-as-errors --seed 262447"
        status: pass
      - kind: command
        ref: "for i in $(seq 1 20); do (cd accrue_portal && mix test --warnings-as-errors) || exit 1; done"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 02: Admin credo and portal flake Summary

accrue_admin `mix credo --strict` goes from 19 findings (exit non-zero) to 0 with config unchanged, and the portal ContextContractTest endpoint is now supervised per test, removing an ETS race.

## Results

- Positive control: credo reported 19 findings (11 alias-order readability, 1 negated-condition refactor at scoped_path.ex:233, 7 length/1 warnings), matching research.
- Task 1 (9be2c27f): alphabetized alias groups in 8 live modules and 3 test/support files (including StatusBadge before StepUpAuthModal in subscription_live, found on re-run); swapped if/else branches in ScopedPath.
- Task 2 (c7a5e990): the 6 invoices_live_test `length(x) == 0` became `x == []`; webhook_live_test `length(x) >= 1` became `assert [_ | _] = x`. Exact-count `== 1` assertions untouched (credo does not flag them), so no cardinality was loosened. Admin suite: 746 tests, 0 failures with --warnings-as-errors.
- Task 3 (854e9989): `start_supervised!(CustomEndpoint)` replaces linked `start_link` with `already_started` tolerance. Cause: the endpoint was linked to the test process and died asynchronously at test end, so the next test saw a missing ETS table.

## Deviations from Plan

**1. [Rule 1 - plan assumption] Seed 262447 does not reproduce RED.** On this tree seed 262447 passed before the fix (111 tests, 0 failures, run twice). The race is timing-dependent: `--seed 1` failed with the ETS error (`a different processor Customer with matching owner does not supply HomeLive data`) before the fix. After the fix: seeds 1 and 262447 pass, the file alone passes (5 tests), and 20/20 random-seed full-suite runs pass (111 tests each). No seed pinned, no retries, no skips.

**2. Plan-head ledger.** The pre-commit ledger file was not created; plan_head_before is the HEAD at start (27c8168a), and the commit count (3) was measured from it.

## Known Stubs

None.

## Self-Check: PASSED

Commits 9be2c27f, c7a5e990, 854e9989 present; credo exit 0; suites green.
