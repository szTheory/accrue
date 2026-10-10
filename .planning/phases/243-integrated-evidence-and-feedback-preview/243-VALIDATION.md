---
phase: "243"
slug: "integrated-evidence-and-feedback-preview"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-10"
---

# Phase 243 — Validation Strategy

> Mapped to three executable plans and seven tasks. No product acceptance result is claimed during planning.

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
| 243-01-01 exact twelve-set and rendered mask controls | Existing visual spec, guard, Node controls; existing Phase191 invoice seed ID needs no fixture edit | EVR-03 | T-243-01 | Positive volatile match and protected fact exclusions; absent/empty/every omitted image fail | Node, browser | `cd accrue_admin && node --test test/js/visual_baseline_set_test.mjs` | Guard exists; expanded browser assertions pending | Pending |
| 243-01-02 Ubuntu goldens and normal comparison | Existing workflow mint and blocking visual job | EVR-03 | T-243-02 | Deliberate twelve-image Linux mint separate from normal comparison | Ubuntu browser/pixel | `node accrue_admin/e2e/visual-baseline-set.cjs accrue_admin/e2e/__screenshots__/visual-desktop`; `cd accrue_admin && npm run e2e:visual-regression` on existing Ubuntu job | Existing eight; four new PNGs pending | Pending |
| 243-02-01 wrapper and direct Playwright custody | Existing browser/dev-boot wrappers plus host Playwright config/global setup, new shared preflight and controls | EVR-04 | T-243-03 | Known collision fails before wrapper mutation, direct webServer startup and global setup create/migrate/seed; distinct proof DB/port passes | Node contract | `node scripts/ci/test_accrue_host_preview_custody.mjs` | New control pending | Pending |
| 243-02-02 fresh and warm preview | Existing Compose/entrypoint, new host preservation spec; direct Playwright preflight from 243-02-01 | EVR-04 | T-243-03, T-243-04, T-243-05 | Preflight precedes global setup mutation; operator auth/Fake/readiness plus authoritative sentinel/audit persistence | Host browser/DB | `CI=1 npm --prefix examples/accrue_host run e2e -- e2e/phase243-preview-preservation.spec.js --project=chromium-desktop --workers=1` | New spec pending | Pending |
| 243-02-03 complete wrapper separation | Existing `mix verify.full`, guarded browser/dev-boot scripts | EVR-04 | T-243-03 | Positive overlap refusal and post-wrapper preview-state equality | Host full verifier | `cd examples/accrue_host && mix verify.full` only after custody preflight and sentinel capture | Existing wrapper; guard pending | Pending |
| 243-03-01 corrected CSS served identity | Existing Phase238 mounted asset owner; direct Playwright preflight from 243-02-01 | EVR-03, EVR-04 | T-243-03, T-243-06 | Preflight precedes global setup mutation; package-built, host-compiled, HTTP-served and browser-requested bytes agree | Build, mounted browser | `cd accrue_admin && mix accrue_admin.assets.build`; `CI=1 npm --prefix examples/accrue_host run e2e -- e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop --workers=1` after custody preflight | Existing owner | Pending |
| 243-03-02 current coverage and limits | Existing Phase240 inventory and verifier; new Phase243 handoff | EVR-03, EVR-04 | T-243-07 | Each claim links actual revision/owner/result; omitted route fails | Evidence contract | `node scripts/ci/verify_phase240_evidence.mjs .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md`; `node scripts/ci/verify_phase240_evidence.mjs --self-test` | Existing verifier | Pending |

## Wave 0 Requirements

- Extend current mask owners with rendered positive-match and protected-exclusion assertions for touched compositions.
- Add the smallest authoritative warm-recovery/preview-preservation control if current owners do not already decide the claim. Specify exact targets and complete command paths before any mutable setup.
- Add light/dark `invoices` and `invoice-detail` compositions from the already seeded Phase191 invoice ID, chosen to protect invoice list density, exact money and review hierarchy absent from the existing eight, and update every expected-set declaration/control atomically. No shared fixture edit is planned; Plan 243-01 declares all twelve actual PNG outputs and three code owners (15 paths).
- Preflight both full-verifier wrappers and direct host Playwright config/global setup, so focused npm commands cannot start a colliding webServer or create/migrate/seed a preview database before custody is decided.
- Existing test frameworks require no installation. A genuine Linux runtime result is an execution dependency, not a missing local-test fallback.

## Manual-Only Verifications

None required for machine-verifiable acceptance. Optional external subjective feedback is not a UAT gate. Intended golden/diff inspection belongs to the bounded closure review; objective assertions and genuine Linux comparison decide EVR-03. Missing Linux results remain unresolved rather than turning into a human-confirmation checkpoint.

## Validation Sign-Off

- [x] Exact plan/task IDs and focused commands are assigned by the planner.
- [x] Every task has an automated verify and an observable failing direction, or an explicit dependency creating its owner.
- [ ] Positive controls establish that absence checks can detect a violation.
- [ ] Complete command custody is checked before mutable proof/startup.
- [x] No watch flags, fixed sleeps, blanket retries, hidden exclusions, relaxed thresholds or new CI matrix are planned.
- [x] All planned requirements and D-01 through D-16 are covered.

**Approval:** Independent plan checking passed on 2026-10-10 after one revision. Runtime controls and acceptance remain pending; this document remains a draft execution-validation contract.
