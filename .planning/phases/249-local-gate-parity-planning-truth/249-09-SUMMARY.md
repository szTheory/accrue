---
phase: 249-local-gate-parity-planning-truth
plan: "09"
subsystem: admin-browser-gates
status: complete
completed: 2026-10-24
requirements-completed: [GREEN-05]
tags: [browser-uat, drift-docs, ratchet, stale-contract, regression, reflow]
key-files:
  modified:
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/e2e/admin-spec-list-phase196.spec.js
    - accrue_admin/e2e/admin-spec-list-phase197.spec.js
    - accrue_admin/e2e/admin-spec-overview-phase194.spec.js
    - accrue_admin/e2e/admin-spec-detail-phase198.spec.js
    - accrue_admin/e2e/phase7-uat.spec.js
    - .planning/phases/249-local-gate-parity-planning-truth/249-PROBE-CLASSIFICATION.md
key-decisions:
  - "One real regression found and fixed at source: topbar overflowed 320px at 200% root font (theme picker plus Time display); CSS fixed and committed bundle rebuilt"
  - "All other findings stale-contract with commit receipts; assertions retargeted, none deleted, skipped or loosened"
  - "admin-ui-ratchet-guardrails recorded as ADVISORY exactly as CI treats it (continue-on-error, WINDOWS row 11); not reclassified"
  - "Phase 211 visual regression gate skipped and routed to Phase 250 (Linux baselines); screenshots untouched"
commits: 7
plan_head_before: d4808120
plan_head_after: 4bcf8cdb3cd328f8730c4471b3ecbf61a2e4e5f2
actuals:
  tokens: 70000
  tasks: 2
  commits: 7
coverage:
  - id: C1
    description: admin-drift-docs replays green and the committed admin bundle is fresh (also after the CSS rebuild)
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job admin-drift-docs --out $(mktemp -d) --run --skip 'Install Hex' --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA="
        status: pass
    human_judgment: false
  - id: C2
    description: admin-ui-ratchet-selftests replays green
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job admin-ui-ratchet-selftests --out $(mktemp -d) --run --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA="
        status: pass
    human_judgment: false
  - id: C3
    description: admin-ui-ratchet-guardrails recorded as advisory exactly as CI treats it (continue-on-error steps, exit 0)
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job admin-ui-ratchet-guardrails --out $(mktemp -d) --run --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA="
        status: pass
    human_judgment: false
  - id: C4
    description: Non-visual browser-uat (npm run e2e on desktop and mobile, node hooks tests, baseline-set guard) replays green with the visual gate skipped
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --workflow .github/workflows/accrue_admin_browser.yml --job browser-uat --out $(mktemp -d) --run --skip 'Install Chromium' --skip 'Install Hex' --skip 'Phase 211 visual regression gate' --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA="
        status: pass
      - kind: command
        ref: "git diff --quiet -- accrue_admin/e2e/__screenshots__ && test ! -e .planning/phases/200-idempotent-verification-sign-off"
        status: pass
    human_judgment: false
  - id: C5
    description: Every failing probe classified with commit receipt or source fix; admin ExUnit suite unaffected by the CSS fix
    requirement: GREEN-05
    verification:
      - kind: command
        ref: "cd accrue_admin && MIX_ENV=test mix test"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 09: Admin drift-docs, ratchet, and non-visual browser-uat Summary

Drift-docs, the ratchet self-tests and the non-visual `browser-uat` workflow now replay green; the 17 failing e2e tests were sixteen stale contracts and one real 320px reflow regression, each classified in `249-PROBE-CLASSIFICATION.md`.

## Outcomes

1. **Task 1 (d7af912b).** `admin-drift-docs` (4 PASS) and `admin-ui-ratchet-selftests` (5 PASS) are green. `admin-ui-ratchet-guardrails` exits 0 with two ADVISORY-FAIL steps (`Verify frozen ratchet evidence`, `Verify UI ratchet sign-off`), which are `continue-on-error` in CI and parked per WINDOWS row 11. They are recorded as is.
2. **Task 2.** The first `browser-uat` replay failed `npm run e2e` with 34 failures (17 distinct tests on two projects). After fixes the full replay is 6 PASS, 3 SKIP.
   - **Regression (8b9dc258):** at 320px with 200% root font, the topbar (`Time display` control plus three-segment theme picker in a two-auto-column grid) overflowed the document by 32px. Theme picker now takes its own grid row and Time display wraps. `mix accrue_admin.assets.build` regenerated the committed bundle, and drift-docs was replayed again afterwards.
   - **Stale contracts:** Phase 196 and 197 list specs (view nav, scoped chips, `Reset filters`, renamed columns, event labels; 8b9dc258, 20ee1eaf), Phase 194 overview (topbar trigger, "Recent billing activity"; 08a00625), Phase 198 event detail (no lazy sections, inline payload; a376ef6e), Phase 7 UAT (Home headline, webhook title = event id; d1c5fce6). Assertions were retargeted to the current product, none deleted or skipped.
   - Two single-run failures (webhook bulk retry, refund drawer) did not reproduce; recorded as observed flakes with no edit.
3. **Skip routed.** `Phase 211 visual regression gate` skipped (Linux baselines, WINDOWS row 27), measured remotely in Phase 250. `accrue_admin/e2e/__screenshots__/` is unchanged. Phase 200 generated output was moved to `$GSD_SCRATCH` after each replay and its absence asserted.

## Deviations from Plan

- [Rule 1 - Bug] Topbar reflow regression fixed in admin CSS and the committed bundle rebuilt, as the plan allows for proven regressions.
- Replays pass `GITHUB_EVENT_NAME=workflow_dispatch`, `BASE_SHA=`, `BEFORE_SHA=` (as in 249-07/08).
- The drift-docs replay recreated `.planning/phases/200-*`; it was moved to scratch before the final commit.

## Known Stubs

None.

## Deferred Items

`examples/accrue_host/e2e/support/copy_dashboard.js` still mirrors `DASHBOARD_BREADCRUMB_HOME: "Dashboard"` while `copy.ex` says "Recent activity". Host e2e lanes must reconcile it. The admin spec no longer imports it.

## Self-Check: PASSED
