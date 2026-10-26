---
phase: 243-integrated-evidence-and-feedback-preview
reviewed: 2026-10-10
depth: standard
files_reviewed: 35
files_reviewed_list:
  - accrue_admin/e2e/__screenshots__/visual-desktop/component-kitchen-dark.png
  - accrue_admin/e2e/__screenshots__/visual-desktop/component-kitchen.png
  - accrue_admin/e2e/__screenshots__/visual-desktop/dashboard-dark.png
  - accrue_admin/e2e/__screenshots__/visual-desktop/dashboard.png
  - accrue_admin/e2e/__screenshots__/visual-desktop/invoice-detail-dark.png
  - accrue_admin/e2e/__screenshots__/visual-desktop/invoice-detail.png
  - accrue_admin/e2e/__screenshots__/visual-desktop/invoices-dark.png
  - accrue_admin/e2e/__screenshots__/visual-desktop/invoices.png
  - accrue_admin/e2e/__screenshots__/visual-desktop/subscription-detail-dark.png
  - accrue_admin/e2e/__screenshots__/visual-desktop/subscription-detail.png
  - accrue_admin/e2e/__screenshots__/visual-desktop/subscriptions-dark.png
  - accrue_admin/e2e/__screenshots__/visual-desktop/subscriptions.png
  - accrue_admin/e2e/admin-group-contracts.spec.js
  - accrue_admin/e2e/admin-interactions.spec.js
  - accrue_admin/e2e/admin-spec-overview-phase194.spec.js
  - accrue_admin/e2e/admin-visual-regression-phase211.spec.js
  - accrue_admin/e2e/phase7-uat.spec.js
  - accrue_admin/e2e/visual-baseline-set.cjs
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/test/js/visual_baseline_set_test.mjs
  - examples/accrue_host/README.md
  - examples/accrue_host/config/dev.exs
  - examples/accrue_host/e2e/global-setup.js
  - examples/accrue_host/e2e/phase234-admin-customers-subscriptions.spec.js
  - examples/accrue_host/e2e/phase237-admin-billing.spec.js
  - examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js
  - examples/accrue_host/e2e/phase243-preview-preservation.spec.js
  - examples/accrue_host/e2e/preview-routing.js
  - examples/accrue_host/e2e/preview-runner.js
  - examples/accrue_host/package.json
  - examples/accrue_host/playwright.config.js
  - scripts/ci/accrue_host_preview_custody.sh
  - scripts/ci/accrue_host_verify_browser.sh
  - scripts/ci/accrue_host_verify_dev_boot.sh
  - scripts/ci/test_accrue_host_preview_custody.mjs
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: has_findings
---

# Phase 243: Code Review Report

**Reviewed:** 2026-10-10  
**Depth:** standard  
**Files Reviewed:** 35  
**Status:** has_findings

## Summary

Reviewed all 35 scoped files, including the twelve visual baselines. Two blocker-level issues affect filesystem safety and the preview custody guard. The recorded Linux visual comparison remains tied to its documented historical revision.

## Narrative Findings (AI reviewer)

### CR-01: Unvalidated proof run ID permits output path traversal and deletion

**File:** `examples/accrue_host/playwright.config.js:13-19`
**Severity:** BLOCKER
**Issue:** `ACCRUE_HOST_PROOF_RUN_ID` is accepted verbatim and interpolated into the Mix build, Playwright output/report, and PID-marker paths. A value containing enough `../` segments resolves these paths outside their intended temporary directories. The output path is passed to Playwright as `outputDir` at line 94, and Playwright recursively clears configured output directories when a run starts. A caller-controlled run ID can therefore make a normal E2E invocation delete an arbitrary writable directory.
**Fix:** Restrict the run ID to a safe identifier alphabet such as `[A-Za-z0-9_-]+`, or resolve every derived path and reject it unless it remains inside its intended parent directory. Apply the same containment check to all derived paths before using them.

### CR-02: Caller-controlled test fixtures bypass live preview custody checks

**File:** `scripts/ci/accrue_host_preview_custody.sh:23-31,186-193`
**Severity:** BLOCKER
**Issue:** Setting `ACCRUE_HOST_CUSTODY_TEST_MODE=1` and `ACCRUE_HOST_CUSTODY_TEST_FIXTURE` replaces the live preview and target identity reads with arbitrary JSON. The normal wrappers and Playwright configuration inherit these environment variables, so a regular verifier or direct npm invocation can make the preflight accept fabricated distinct identities while its actual target aliases the preview. This bypasses the fail-closed isolation proof; direct Playwright can also proceed with an occupied reused server after this synthetic preflight succeeds.
**Fix:** Keep fixture injection in a test-only entry point or module that production wrappers/configuration never call. Make normal preflight always derive identities from the live database, Compose instance, and listener, regardless of caller environment.

---

_Reviewed: 2026-10-10_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
