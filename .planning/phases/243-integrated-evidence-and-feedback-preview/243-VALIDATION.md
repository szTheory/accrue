---
phase: "243"
slug: "integrated-evidence-and-feedback-preview"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-10"
---

# Phase 243 — Validation Strategy

> Drafted from focused research. The planner must replace concern rows with exact plan/task IDs and commands; no product acceptance result is claimed here.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Node built-in test runner, Playwright Test 1.59.1, ExUnit on Elixir 1.19.5/OTP 28 |
| Config files | `accrue_admin/playwright.config.js`, `examples/accrue_host/playwright.config.js`, existing package/host Mix configuration |
| Quick run command | `cd accrue_admin && node --test test/js/visual_baseline_set_test.mjs` |
| Linux comparison | `node accrue_admin/e2e/visual-baseline-set.cjs accrue_admin/e2e/__screenshots__/visual-desktop` then `cd accrue_admin && npm run e2e:visual-regression` on the existing Ubuntu owner |
| Mounted asset owner | `CI=1 npm --prefix examples/accrue_host run e2e -- e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop --workers=1`, only after its complete setup path is proven separate from preview custody |
| Runtime | Unmeasured in planning; record actual timing at execution. Fast Node controls are the immediate feedback lane; browser and full regression lanes retain existing scope. |

## Sampling Rate

- After each changed guard, mask, fixture or recovery owner, run the cheapest precise automated control for that owner, including known-positive and negative controls.
- Run owner browser checks after fixture/asset changes with database, connection, instance, volume, port and process targets verified first.
- Keep Linux snapshot generation separate from comparison. Preserve `threshold: 0.2` and `maxDiffPixelRatio: 0.01`; a macOS pass cannot close EVR-03.
- Schedule the complete build/check and batched desktop/narrow/effective-theme inspection once for the agreed closure batch. Permit one corrective batch and at most one confirming inspection. Do not multiply full-suite or capture runs merely to populate this document.
- Before completion, required current automated evidence must be green. After canonical summaries and independent verification exist, generate automated UAT, then run the project-wide executable-UAT contract.

## Per-Task Verification Map

| Task/concern | Planned owner | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|---------------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Complete selected set | Existing expected-set guard/controls | EVR-03 | Assigned by planner | Missing-all and every individually omitted golden fail | Node | `cd accrue_admin && node --test test/js/visual_baseline_set_test.mjs` | Yes | Pending |
| Faithful masks and intended pixels | Existing visual spec and Ubuntu lane | EVR-03 | Assigned by planner | Volatile timestamp values alone are masked; protected facts remain exposed | Browser/pixel | `cd accrue_admin && npm run e2e:visual-regression` on Linux, preceded by complete-set guard | Existing owner; focused assertions pending | Pending |
| Bootstrap, recovery and custody | Existing host startup/verifier seams | EVR-04 | Assigned by planner | No reset/reseed/mutation proof touches preview; preservation uses authoritative state evidence | Focused contract/runtime | Planner must specify exact existing or new owner commands with positive controls before execution | Existing startup seams; preservation controls pending | Pending |
| Corrected CSS served identity | Existing Phase 238 mounted owner | EVR-03, EVR-04 | Assigned by planner | Package-built, host-compiled, HTTP-served and browser-requested bytes agree | Browser | `CI=1 npm --prefix examples/accrue_host run e2e -- e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop --workers=1` after custody preflight | Yes | Pending |
| Current coverage and closure | Phase 240 inventory, normal verifier and UAT generator | EVR-03, EVR-04 | Assigned by planner | Claims retain actual revision, owner and evidence limits | Evidence contract | `node scripts/ci/verify_executable_uat_contract.mjs --phase 243 --write` then `node scripts/ci/verify_executable_uat_contract.mjs --all-since 229`, after summaries and verification | Yes | Pending |

## Wave 0 Requirements

- Extend current mask owners with rendered positive-match and protected-exclusion assertions for touched compositions.
- Add the smallest authoritative warm-recovery/preview-preservation control if current owners do not already decide the claim. Specify exact targets and complete command paths before any mutable setup.
- Update complete-set declarations and every missing-file control atomically if the planner justifies selected invoice exemplar additions.
- Existing test frameworks require no installation. A genuine Linux runtime result is an execution dependency, not a missing local-test fallback.

## Manual-Only Verifications

None required for machine-verifiable acceptance. Optional external subjective feedback is not a UAT gate. Intended golden/diff inspection belongs to the bounded closure review; objective assertions and genuine Linux comparison decide EVR-03. Missing Linux results remain unresolved rather than turning into a human-confirmation checkpoint.

## Validation Sign-Off

- [ ] Exact plan/task IDs and focused commands are assigned by the planner.
- [ ] Every task has an automated verify and an observable failing direction, or an explicit dependency creating its owner.
- [ ] Positive controls establish that absence checks can detect a violation.
- [ ] Complete command custody is checked before mutable proof/startup.
- [ ] No watch flags, fixed sleeps, blanket retries, hidden exclusions, relaxed thresholds or new CI matrix.
- [ ] All planned requirements and D-01 through D-16 are covered.

**Approval:** Pending independent plan checking; this is planning guidance, not execution acceptance.
