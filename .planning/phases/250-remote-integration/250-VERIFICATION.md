---
phase: 250-remote-integration
verified: 2026-10-26T01:30:00Z
status: passed
score: "3/3 success criteria verified"
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/250-remote-integration/250-01-PLAN.md"
  - ".planning/phases/250-remote-integration/250-01-SUMMARY.md"
  - ".planning/phases/250-remote-integration/250-02-PLAN.md"
  - ".planning/phases/250-remote-integration/250-02-SUMMARY.md"
  - ".planning/phases/250-remote-integration/250-03-PLAN.md"
  - ".planning/phases/250-remote-integration/250-03-SUMMARY.md"
  - ".planning/phases/250-remote-integration/250-04-PLAN.md"
  - ".planning/phases/250-remote-integration/250-04-SUMMARY.md"
  - ".planning/phases/250-remote-integration/250-05-PLAN.md"
  - ".planning/phases/250-remote-integration/250-05-SUMMARY.md"
  - ".planning/phases/250-remote-integration/250-06-PLAN.md"
  - ".planning/phases/250-remote-integration/250-06-SUMMARY.md"
  - ".planning/phases/250-remote-integration/250-07-PLAN.md"
  - ".planning/phases/250-remote-integration/250-07-SUMMARY.md"
  - ".planning/phases/250-remote-integration/250-CONTEXT.md"
  - ".planning/phases/250-remote-integration/250-RESEARCH.md"
  - ".planning/phases/250-remote-integration/250-UAT.md"
  - ".planning/phases/250-remote-integration/250-VISUAL-CLASSIFICATION.md"
  - ".planning/phases/250-remote-integration/250-ci-head-status.mjs"
  - ".planning/phases/250-remote-integration/250-mint-close-artifacts.mjs"
  - ".planning/phases/250-remote-integration/250-prepush-guard.sh"
  - ".planning/phases/250-remote-integration/250-visual-ledger-check.mjs"
  - "accrue_admin/assets/css/app.css"
  - "accrue_admin/config/test.exs"
  - "accrue_admin/e2e/__screenshots__/visual-desktop/dashboard-dark.png"
  - "accrue_admin/e2e/__screenshots__/visual-desktop/dashboard.png"
  - "accrue_admin/e2e/__screenshots__/visual-desktop/invoice-detail-dark.png"
  - "accrue_admin/e2e/__screenshots__/visual-desktop/invoice-detail.png"
  - "accrue_admin/e2e/__screenshots__/visual-desktop/invoices-dark.png"
  - "accrue_admin/e2e/__screenshots__/visual-desktop/invoices.png"
  - "accrue_admin/e2e/__screenshots__/visual-desktop/subscription-detail-dark.png"
  - "accrue_admin/e2e/__screenshots__/visual-desktop/subscription-detail.png"
  - "accrue_admin/e2e/__screenshots__/visual-desktop/subscriptions-dark.png"
  - "accrue_admin/e2e/__screenshots__/visual-desktop/subscriptions.png"
  - "accrue_admin/e2e/admin-visual-regression-phase211.spec.js"
  - "accrue_admin/priv/static/accrue_admin.css"
  - "accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs"
  - "accrue_admin/test/js/time_display_test.mjs"
  - "accrue_portal/test/support/braintree_mox.ex"
  - "examples/accrue_host/e2e/phase13-canonical-demo.spec.js"
  - "examples/accrue_host/e2e/phase233-semantic.spec.js"
  - "examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js"
  - "examples/accrue_host/e2e/phase234-post-layout.spec.js"
  - "examples/accrue_host/e2e/phase237-admin-billing.spec.js"
  - "examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js"
  - "examples/accrue_host/e2e/phase239-integrated-quality.spec.js"
  - "examples/accrue_host/e2e/phase244-operator-evidence.spec.js"
  - "examples/accrue_host/e2e/phase245-admin-baseline.spec.js"
  - "examples/accrue_host/e2e/phase246-collection-filters.spec.js"
  - "examples/accrue_host/e2e/phase246-current-proof.spec.js"
  - "examples/accrue_host/e2e/phase246-invoice-filters.spec.js"
  - "examples/accrue_host/e2e/phase247-current-proof.spec.js"
  - "examples/accrue_host/e2e/phase247-time-tracer.spec.js"
  - "examples/accrue_host/e2e/verify01-admin-a11y.spec.js"
  - "examples/accrue_host/e2e/verify01-admin-mobile.spec.js"
  - "examples/accrue_host/e2e/verify01-admin-mounted.spec.js"
  - "examples/accrue_host/lib/accrue_host/ordinary_seed_boundary.ex"
  - "examples/accrue_host/lib/accrue_host_web/live/phase246_states_live.ex"
  - "examples/accrue_host/priv/repo/seeds/ordinary.exs"
  - "examples/accrue_host/test/ordinary_preview_seed_test.exs"
  - "scripts/ci/verify_release_contract.sh"
covered_digest: "v1:sha256:a404b492d0389b98eca2df8abfd189e6bc43fcf99a1c935d4b6a18d1b609855c"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 250: Remote Integration Verification Report

**Scope:** `status: passed` and `behavior_unverified: 0` cover all seven plans (250-01..07) and success criteria SC1, SC2 and SC3. LAND-01 was marked Complete at the pre-merge close E; LAND-02 and LAND-03 are marked Complete by 250-07, after the merge evidence (250-06) exists.

## Observable Truths

| # | Claim | Evidence | Status |
|---|-------|----------|--------|
| B1 | Phase 250 owns SL-G, SL-E and executable-UAT from its first commit | `250-01-SUMMARY.md` coverage B1 | VERIFIED |
| F1 | RecoveryLiveTest ceil+2 clock and admin UTC pin (pin-only control: 8 failures; fixed: 33/0, full suite 746/0) | `250-02-SUMMARY.md` coverage F1 | VERIFIED |
| F2 | docs job `npm ci` before D-32 (clean-clone control FAIL then PASS) | `250-02-SUMMARY.md` coverage F2 | VERIFIED |
| F3 | time_display TZ pin (unpinned UTC control: 1 failure; pinned: 3 zones pass) | `250-02-SUMMARY.md` coverage F3 | VERIFIED |
| D1 | LAND-02/03 wording, D2 deferral, PR 49 body file | `250-02-SUMMARY.md` coverage D1 | VERIFIED |
| H1/G1 | Exact-SHA verdict helper (34 fixture checks, live rc 1 control at `23bee494`) and pre-push guard with runtime-built positive controls | `250-03-SUMMARY.md` coverage H1, G1 | VERIFIED |
| F4 | Host-integration and Playwright shard fixes, each with a negative control or an exact local reproduction | `250-03-SUMMARY.md` coverage F4; `250-CI-LEDGER.md` iterations 1-5 | VERIFIED |
| V1-V4 | D4 checker, Phase 211 anchor retarget, per-surface classification (10 intentional, 2 unchanged, 0 regressions), portal stub race | `250-04-SUMMARY.md` coverage V1-V4; `250-VISUAL-CLASSIFICATION.md`; `250-CI-LEDGER.md` iterations 6-8 | VERIFIED |
| SC1 | LAND-01: the integration head is on `integration/v1.63-v1.66` with publication hygiene passing across the full pushed history; milestone tags stay local | Re-runnable: `bash .planning/phases/250-remote-integration/250-prepush-guard.sh --hygiene-only --range 23bee4949045b7ac9361d954b24497bb749e771b..<E>`, where `<E>` is the evidence head named in `250-INTEGRATION-PR.md` Provenance. Before E it passed over `23bee494..6fe35302` (48 commits; `250-05-SUMMARY.md` coverage SC1). History before `23bee494`: the 850-commit full-history scan and the 91-commit `b4a7eeac..23bee494` scan in `250-CONTEXT.md` (Already done). The guard passed before every push (250-03 G1, ledger iterations 1-8) | VERIFIED |
| SC2 | LAND-02: every `ci.yml` and `accrue_admin_browser.yml` job with a `pull_request` run path concludes `success` on the exact head, with the D1 exclusions only | `node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 5ad01dee2c70087aa89fafdfb154f6e9d8068277 --event pull_request` (no `--visual-pending-ok`): GREEN, rc 0, 20 jobs `success`; ci.yml run 40236926623, accrue_admin_browser.yml run 40236926603; `250-CI-LEDGER.md` iteration 8. The first close commit `7b1b5862` was red on one Release gate cell (ledger iteration 9, a SIGPIPE race in `verify_release_contract.sh`), fixed at source in `5561a9a9` with controls (`250-05-SUMMARY.md` F5). The same helper at the evidence head E `ece41e51eb0e6ab4f030d33501cd811188542686`: GREEN, rc 0, 20 jobs `success` (ci.yml run 40243045805, accrue_admin_browser.yml run 40243045812); at the body-only PR head H `17a608ccdbc1512a31475e0804d46811d2059c4b`: GREEN, rc 0, 20 jobs `success` (ci.yml run 40245573325, accrue_admin_browser.yml run 40245573321); `git diff --name-only E H` lists only `250-INTEGRATION-PR.md` (`250-CI-LEDGER.md` iterations 10 and 11). SL-F keeps the committed body byte-identical to the live body | VERIFIED |
| SC3 | LAND-03: merge commit, pre-merge SHAs reachable from `main`, first post-merge `main` push run meets run 35374333981 job by job | `gh pr merge 49 --merge --match-head-commit 17a608ccdbc1512a31475e0804d46811d2059c4b` gave M `3dd5f8746b34497d345cd4d03c44f3756a159bab`. Parent count: `git rev-list --parents -n 1 3dd5f874` prints 3 SHAs (M, `7971753a` old origin/main, `17a608cc` H). Reachability: `git rev-list 3dd5f874 \| grep -c -x -F -f .planning/250-premerge.local` = 993 = the list length, 0 missing. Baseline: `node .planning/phases/250-remote-integration/250-ci-head-status.mjs --repo szTheory/accrue --sha 3dd5f8746b34497d345cd4d03c44f3756a159bab --event push --baseline-run 35374333981`: GREEN, rc 0, 21 jobs `success` (ci.yml run 40247684345, accrue_admin_browser.yml run 40247684340). Recorded, not claimed: `Stripe provider-proof incident reconciliation` and `Stripe test-mode parity (mandatory periodic)` (baseline skipped), `Admin UI ratchet guardrails [parked]` (baseline failure, D1). `250-06-SUMMARY.md` coverage SC3; `250-CI-LEDGER.md` post-merge row | VERIFIED |

## Excluded from covered_files

`.planning/STATE.md`, `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` are live trackers. This file is excluded from its own list. `250-INTEGRATION-PR.md` and `250-CI-LEDGER.md` record the CI result of heads they cannot be part of; covering them would form a digest cycle. Control (d) in `250-05-SUMMARY.md` shows that a byte appended to either leaves SL-G passing, and control (b) shows that a byte appended to a covered file does not.

## Gaps

None.
