---
phase: "243"
slug: "integrated-evidence-and-feedback-preview"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-10"
---

# Phase 243 — Validation Strategy

> All seven tasks have executed automated owners. Canonical summaries retain exact revisions, failed attempts, and successful runtime evidence.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Node built-in test runner, Playwright Test 1.59.1, ExUnit on Elixir 1.19.5/OTP 28 |
| Config files | `accrue_admin/playwright.config.js`, `examples/accrue_host/playwright.config.js`, existing package/host Mix configuration |
| Quick run command | `cd accrue_admin && node --test test/js/visual_baseline_set_test.mjs` |
| Linux comparison | `node accrue_admin/e2e/visual-baseline-set.cjs accrue_admin/e2e/__screenshots__/visual-desktop` then `cd accrue_admin && npm run e2e:visual-regression` on the existing Ubuntu owner |
| Mounted asset owner | `CI=1 npm --prefix examples/accrue_host run e2e -- e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop --workers=1`, only after its complete setup path is proven separate from preview custody |
| Runtime | Node controls finish in seconds; Linux full browser suites took about 14 minutes plus runner setup. Host full verification and focused runs are recorded in the canonical summaries. |

## Sampling Rate

- After each changed guard, mask, fixture or recovery owner, run the cheapest precise automated control for that owner, including known-positive and negative controls.
- Run owner browser checks after fixture/asset changes with database, connection, instance, volume, port and process targets verified first.
- Keep Linux snapshot generation separate from comparison. Preserve `threshold: 0.2` and `maxDiffPixelRatio: 0.01`; a macOS pass cannot close EVR-03.
- Schedule the complete build/check and batched desktop/narrow/effective-theme inspection once for the agreed closure batch. Permit one corrective batch and at most one confirming inspection. Do not multiply full-suite or capture runs merely to populate this document.
- Before completion, required current automated evidence must be green. After canonical summaries and independent verification exist, generate automated UAT, then run the project-wide executable-UAT contract.

## Per-Task Verification Map

| Task/concern | Executed owner | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|---------------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 243-01-01 exact twelve-set and rendered mask controls | Visual spec, guard, Node controls | EVR-03 | T-243-01 | Positive timestamp targets and protected exclusions; absent/empty/every omitted image fail | Node, browser | `cd accrue_admin && node --test test/js/visual_baseline_set_test.mjs` | Yes | Pass: 17/17; Linux masked compositions passed |
| 243-01-02 Ubuntu goldens and normal comparison | Existing workflow mint and blocking visual job | EVR-03 | T-243-02 | Reviewed twelve-image Linux mint separate from comparison | Ubuntu browser/pixel | `node accrue_admin/e2e/visual-baseline-set.cjs accrue_admin/e2e/__screenshots__/visual-desktop`; existing Ubuntu `e2e:visual-regression` | Twelve PNGs | Pass: run 38083267168 at 0197f4ba |
| 243-02-01 wrapper and direct Playwright custody | Shared guard, wrappers, config/setup, dedicated routing runner | EVR-04 | T-243-03 | Collision and generic preview routing fail before mutation; exact owned proof PID passes | Node contract | `node scripts/ci/test_accrue_host_preview_custody.mjs` | Yes | Pass: 12/12 |
| 243-02-02 fresh and warm preview | Compose entrypoint and preservation spec | EVR-04 | T-243-03, T-243-04, T-243-05 | Real operator auth, Fake config, exact sentinel/audit/webhook/dispatch equality; exclusive runner skips generic setup | Host browser/DB | `npm --prefix examples/accrue_host run e2e:preview -- e2e/phase243-preview-preservation.spec.js --project chromium-desktop --workers 1` with documented explicit preview environment | Yes | Pass: 1/1, including post-restart remediation |
| 243-02-03 complete wrapper separation | `mix verify.full` and guarded wrappers | EVR-04 | T-243-03 | Native test/proof-dev DBs separate from dedicated preview; post-command equality | Host full verifier | `cd examples/accrue_host && mix verify.full` after custody preflight/sentinel capture | Yes | Pass: exit 0, exact preservation; see 243-02-SUMMARY |
| 243-03-01 corrected CSS served identity | Phase238 mounted owner | EVR-03, EVR-04 | T-243-03, T-243-06 | Package/compiled/HTTP/browser bytes agree; altered response rejected; corrected 4px gap | Build, mounted browser | `cd accrue_admin && mix accrue_admin.assets.build`; focused Phase238 desktop command in 243-03-SUMMARY | Yes | Pass: 2/2, also after routing repair |
| 243-03-02 current coverage and limits | Phase240 inventory/verifier and Phase243 handoff | EVR-03, EVR-04 | T-243-07 | Exact revision/owner/result; omitted route rejected | Evidence contract | `node scripts/ci/verify_phase240_evidence.mjs <ledger>`; `node scripts/ci/verify_phase240_evidence.mjs --self-test <ledger>` | Yes | Pass: 21 routes, 30/42/8 registry; negative control |

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
- [x] Positive controls establish that absence checks can detect a violation.
- [x] Complete command custody is checked before mutable proof/startup.
- [x] No watch flags, fixed sleeps, blanket retries, hidden exclusions, relaxed thresholds or new CI matrix are planned.
- [x] All planned requirements and D-01 through D-16 are covered.

**Validation:** Executed automated owners cover EVR-03 and EVR-04. Root rechecked 17 visual-set controls, 12 custody controls, the twelve-file guard, and ledger negative control on 2026-10-10. An initial root visual-control invocation from the repository root failed to locate its package-relative CLI; the documented package-directory command passed. Independent goal verification and ordered UAT remain pending.

## Validation Audit 2026-10-10

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 7 |
| Escalated | 0 |
