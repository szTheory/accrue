---
phase: 249-local-gate-parity-planning-truth
plan: "08"
subsystem: admin-browser-gates
status: complete
completed: 2026-10-24
requirements-completed: [GREEN-02, GREEN-04, GREEN-05]
tags: [phase192, phase199, phase200, guardrails, stale-contract, regression]
key-files:
  modified:
    - accrue_admin/e2e/admin-page-flow-phase191.spec.js
    - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - .planning/phases/249-local-gate-parity-planning-truth/249-PROBE-CLASSIFICATION.md
key-decisions:
  - "One real regression found and fixed at source: webhook detail header description overflowed at 320px with 200% text spacing (e6f39cef); fixed with ax-body wrapping, no CSS bundle rebuild"
  - "All other findings stale-contract with commit receipts; assertions updated, none deleted, skipped or loosened"
  - "Command palette floating-panel failure did not reproduce in isolation or in two later full replays; recorded as an observed flake with no edit"
commits: 4
plan_head_before: 1dd9b58bfe0df721d560450c2ff91983853cf467
plan_head_after: 7509d2e3a8cf88f1a5069b11cef80f65571e15e3
actuals:
  tokens: 60000
  tasks: 2
  commits: 4
coverage:
  - id: C1
    description: admin-hardening-guardrails job (Phase 192 contracts, phase191 page-flow, group-contracts, a11y, reduced-motion) replays green
    requirement: GREEN-02
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job admin-hardening-guardrails --out $(mktemp -d) --run --skip 'Install Chromium' --skip 'Install Hex' --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA="
        status: pass
    human_judgment: false
  - id: C2
    description: admin-phase200-guardrails job (storybook, group contracts, phase199, scorecard, sign-off) replays green with Phase 200 output moved to scratch
    requirement: GREEN-02
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job admin-phase200-guardrails --out $(mktemp -d) --run --skip 'Install Chromium' --skip 'Install Hex' --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA="
        status: pass
      - kind: command
        ref: "test ! -e .planning/phases/200-idempotent-verification-sign-off"
        status: pass
    human_judgment: false
  - id: C3
    description: Every failing probe classified with commit receipt or source fix
    requirement: GREEN-04
    verification:
      - kind: command
        ref: "cd accrue_admin && MIX_ENV=test ACCRUE_ADMIN_E2E_PORT=4017 npm run e2e:phase199"
        status: pass
      - kind: command
        ref: "cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/webhook_live_test.exs"
        status: pass
    human_judgment: false
  - id: C4
    description: Admin slice of the green-baseline requirement closed with no skips or baseline edits
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "git status --porcelain (only the pre-existing untracked .planning/milestone.lock)"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 08: Phase 192 and 200 admin guardrail jobs Summary

Both admin guardrail jobs now replay green; the 11 failing probe runs were ten stale contracts and one real 320px reflow regression, each classified in `249-PROBE-CLASSIFICATION.md`.

## Outcomes

1. **admin-hardening-guardrails (52f50df2).** One test (desktop and mobile) asserted the removed "Subscription has ended" headline (b4a7eeac); it now asserts `Subscription action recorded.` plus a visible `Canceled` label, keeping every dispatch, audit, and event assertion.
2. **admin-phase200-guardrails.** `e2e:phase199` failed 9 runs. Findings and classification:
   - Webhook and Connect drill links: stale (separated identity, ec8a0d13).
   - Invoice link count 2 to 3: stale (39759079/ec8a0d13).
   - Home shortcut hit-target block and ratchet selector `.ax-home [data-command-palette-trigger]`: stale (3d7d949d moved the trigger to the topbar); the checks were retargeted, not removed.
   - Webhook replay object context: stale (e6f39cef); the button now asserts its action text and the page h1 asserts the event id.
   - **Regression (50e814b4):** webhook detail header description `invoice.payment_failed` was unbreakable and produced a 361px scroll width at 320px with 200% text and WCAG text spacing. Fixed in `webhook_live.ex` with `<p class="ax-body">`, the dashboard's existing pattern; no CSS rebuild needed.
   - Command palette floating panel failure was not reproducible (isolated run and two later full replays pass); no edit.
3. **Steps after phase199** (reduced-motion, scorecard, sign-off) passed in their in-job order once phase199 was green.
4. **Phase 200 output** was moved to scratch after every run and its absence asserted; no generated evidence entered the tree.

## Deviations from Plan

- [Rule 1 - Bug] The webhook header reflow regression was fixed in admin source (one file) as the plan allows for proven regressions.
- Replays pass `GITHUB_EVENT_NAME=workflow_dispatch`, `BASE_SHA=`, `BEFORE_SHA=` (as in 249-07) because `github.event.*` is unresolvable locally.

## Known Stubs

None.

## Self-Check: PASSED
