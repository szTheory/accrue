---
phase: 250-remote-integration
verified: 2026-10-25T17:00:00Z
status: passed
score: "completed-plan claims verified: 250-01, 250-02; phase success criteria claimed: 0/3 (phase in progress)"
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/250-remote-integration/250-01-PLAN.md"
  - ".planning/phases/250-remote-integration/250-01-SUMMARY.md"
  - ".planning/phases/250-remote-integration/250-02-PLAN.md"
  - ".planning/phases/250-remote-integration/250-02-SUMMARY.md"
  - ".planning/phases/250-remote-integration/250-03-PLAN.md"
  - ".planning/phases/250-remote-integration/250-03-SUMMARY.md"
  - ".planning/phases/250-remote-integration/250-04-PLAN.md"
  - ".planning/phases/250-remote-integration/250-05-PLAN.md"
  - ".planning/phases/250-remote-integration/250-06-PLAN.md"
  - ".planning/phases/250-remote-integration/250-07-PLAN.md"
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
covered_digest: "v1:sha256:e823154b65bd5a57a1633780e6848b9eb9cbe5d3bebdd0b27033342a0450df6d"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 250: Remote Integration Verification Report (in progress)

**Scope:** `status: passed` and `behavior_unverified: 0` apply to the completed-plan claims below only. Phase success criteria SC1-SC3 are not yet claimed. No requirement is marked Complete.

## Observable Truths

| # | Claim | Evidence | Status |
|---|-------|----------|--------|
| B1 | Phase 250 owns SL-G, SL-E and executable-UAT from its first commit | `250-01-SUMMARY.md` coverage B1; SL-G, SL-E, exec-UAT `--all-since 229` and `--phase 250` exit 0 | VERIFIED |
| F1 | RecoveryLiveTest ceil+2 clock and admin UTC pin (pin-only control: 8 failures; fixed: 33/0, full suite 746/0) | `250-02-SUMMARY.md` coverage F1 | VERIFIED |
| F2 | docs job `npm ci` before D-32 (clean-clone control FAIL then PASS) | `250-02-SUMMARY.md` coverage F2 | VERIFIED |
| F3 | time_display TZ pin (unpinned UTC control: 1 failure; pinned: 3 zones pass) | `250-02-SUMMARY.md` coverage F3 | VERIFIED |
| D1 | LAND-02/03 wording, D2 deferral, PR 49 body file | `250-02-SUMMARY.md` coverage D1 | VERIFIED |
| SC1 | Roadmap success criterion 1 | not yet claimed (in progress) | NOT CLAIMED |
| SC2 | Roadmap success criterion 2 | not yet claimed (in progress) | NOT CLAIMED |
| SC3 | Roadmap success criterion 3 | not yet claimed (in progress) | NOT CLAIMED |

## Excluded from covered_files

`.planning/STATE.md`, `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` are live trackers. This file is excluded from its own list. `250-INTEGRATION-PR.md` and `250-CI-LEDGER.md` record the CI result of heads they cannot be part of; covering them would form a digest cycle.

## Gaps

SC1-SC3 remain open until later Phase 250 plans claim them.
