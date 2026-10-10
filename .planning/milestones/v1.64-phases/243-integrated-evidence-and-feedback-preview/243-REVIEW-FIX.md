---
phase: 243-integrated-evidence-and-feedback-preview
fixed_at: 2026-10-10T21:57:27Z
review_path: .planning/phases/243-integrated-evidence-and-feedback-preview/243-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 243: Code Review Fix Report

**Fixed at:** 2026-10-10T21:57:27Z  
**Source review:** `.planning/phases/243-integrated-evidence-and-feedback-preview/243-REVIEW.md`  
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: Unvalidated proof run ID permits output path traversal and deletion

**Files modified:** `examples/accrue_host/playwright.config.js`, `scripts/ci/accrue_host_verify_browser.sh`, `scripts/ci/accrue_host_verify_dev_boot.sh`, `scripts/ci/test_accrue_host_proof_paths.mjs`  
**Commit:** `388483ce`  
**Applied fix:** Restrict proof run IDs to 1–80 ASCII letters, digits, underscores, or hyphens in the wrappers and Playwright config. Resolve build, Playwright output/report, admin build, and PID marker paths and require them to remain within the per-run directories; reject existing symlink components.  
**Verification:** `node scripts/ci/test_accrue_host_proof_paths.mjs` passed (1 test, 0 failures; exercises three unsafe IDs and four escaped destination paths). `node -c examples/accrue_host/playwright.config.js`, `bash -n scripts/ci/accrue_host_verify_browser.sh scripts/ci/accrue_host_verify_dev_boot.sh`, and `git diff --check` passed. Checks ran in the main checkout.

### CR-02: Caller-controlled test fixtures bypass live preview custody checks

**Files modified:** `scripts/ci/accrue_host_preview_custody.sh`, `scripts/ci/accrue_host_preview_custody_test_entry.mjs`, `scripts/ci/test_accrue_host_preview_custody.mjs`  
**Commit:** `12649d27`  
**Applied fix:** Production custody preflight now rejects either fixture environment variable and always derives identities from live sources. Fixture identity injection is available only through a separate test entry point. Added controls proving direct Playwright setup and both verifier wrappers reject spoofed fixture environments before fixture or Mix mutation, while the test entry retains positive identity coverage.  
**Verification:** `node scripts/ci/test_accrue_host_preview_custody.mjs` passed (13 tests, 0 failures). `node --check --input-type=commonjs < scripts/ci/accrue_host_preview_custody.sh`, `node --check scripts/ci/accrue_host_preview_custody_test_entry.mjs`, `node --check scripts/ci/test_accrue_host_preview_custody.mjs`, and `git diff --check` passed. Checks ran in the main checkout.

## Skipped Issues

None.

---

_Fixed: 2026-10-10T21:57:27Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
