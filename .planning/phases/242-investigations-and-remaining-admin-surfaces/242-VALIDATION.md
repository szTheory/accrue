---
phase: "242"
slug: "investigations-and-remaining-admin-surfaces"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-10"
---

# Phase 242 — Validation Strategy

> Execution audit: all sixteen automated tasks have accepted nonzero test evidence in the seven canonical SUMMARYs and 242-EXECUTION-GATES.md. This validation coverage result does not replace independent phase-goal verification.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | Existing ExUnit / Phoenix LiveViewTest, Node tests, package and mounted-host Playwright |
| Config | `accrue_admin/playwright.config.js`, `examples/accrue_host/playwright.config.js`, existing Mix/test setup |
| Quick return command | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs` |
| Quick search command | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/components/global_search_test.exs && node --test test/js/command_palette_test.mjs` |
| Full Admin command | `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test && node --test test/js/*.mjs` |
| Full host command | `cd examples/accrue_host && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test` |
| Assets | `cd accrue_admin && mix accrue_admin.assets.build`; build before current fresh-server browser proof and confirm package/compiled/HTTP-served bytes |
| Runtime | Task execution durations and suite timing evidence are recorded in the canonical SUMMARYs and 242-EXECUTION-GATES.md |

## Sampling Rate

- With each implementation task: add precise assertions in the existing behavioral owner and run that owner's focused command before committing accepted work.
- At dependency boundaries: run affected focused integration tests; batch mounted browser acceptance after combined changes and current package build.
- Before verification: run the combined Admin/host gate and changed package/host browser owners with nonzero selected tests. Zero matches, hidden retries or skips, and relaxed tolerances cannot establish acceptance.
- Visual budget: one batched desktop/narrow/effective-theme inspection, one corrective batch, at most one confirming inspection per agreed delivery batch. Count captures/scans/edits/rebuilds together. Cosmetic candidates require mounted confirmation; do not reset the budget by renaming a batch.

## Per-Task Verification Map

Every row names the exact plan/task owner and wave. Every command owner ran with nonzero selected cases. Actual counts, adjustments and evidence limits are recorded in the corresponding canonical SUMMARY; Plan07 records combined suites and mounted owners. Existing tests contain the new behavior assertions.

| Plan/task | Wave | Requirement | Threat ref | Automated command | Fails when | Status |
|---|---:|---|---|---|---|---|
| 242-01/T1 | 1 | JRN-05, JRN-06 | T-242-01; T-242-SC | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs test/accrue_admin/live/events_live_test.exs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-01/T2 | 1 | JRN-05, JRN-06 | T-242-01; T-242-SC | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/queries/events_test.exs test/accrue_admin/live/event_live_test.exs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-02/T1 | 2 | JRN-05, UXC-01 | T-242-02; T-242-SC | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/webhook_replay_test.exs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-02/T2 | 2 | JRN-05, UXC-01 | T-242-02; T-242-SC | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/webhook_live_test.exs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-03/T1 | 2 | JRN-06, UXC-01 | T-242-03; T-242-SC | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-03/T2 | 2 | JRN-06, UXC-01 | T-242-03; T-242-SC | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-03/T3 | 2 | JRN-06, UXC-01 | T-242-03; T-242-SC | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-04/T1 | 2 | JRN-06 | T-242-04; T-242-SC | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/connect_account_live_test.exs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-04/T2 | 2 | JRN-06 | T-242-04; T-242-SC | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/copy/connect_test.exs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-05/T1 | 1 | JRN-07 | T-242-05; T-242-SC | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/components/global_search_test.exs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-05/T2 | 1 | JRN-07 | T-242-05; T-242-SC | `cd accrue_admin && node --test test/js/command_palette_test.mjs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-06/T1 | 3 | JRN-07, UXC-01 | T-242-06; T-242-SC | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/components/app_shell_test.exs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-06/T2 | 3 | JRN-07, UXC-01 | T-242-06; T-242-SC | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/copy test/accrue_admin/copy_test.exs` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-07/T1 | 4 | JRN-05, JRN-06, JRN-07, UXC-01 | T-242-07; T-242-SC | `cd accrue_admin && mix accrue_admin.assets.build && cd .. && CI=1 npm --prefix accrue_admin run e2e:phase191 && CI=1 npm --prefix accrue_admin run e2e:phase199` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-07/T2 | 4 | JRN-05, JRN-06, JRN-07, UXC-01 | T-242-07; T-242-SC | `cd examples/accrue_host && CI=1 npx playwright test e2e/phase238-admin-events-webhooks.spec.js e2e/phase234-search-completion.spec.js --project=chromium-desktop --workers=1` | Nonzero exit, failed assertion or zero selected cases | Green |
| 242-07/T3 | 4 | JRN-05, JRN-06, JRN-07, UXC-01 | T-242-07; T-242-SC | `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test && node --test test/js/*.mjs && cd ../examples/accrue_host && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test` | Nonzero exit, failed assertion or zero selected cases | Green |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. New behavior assertions belong in incumbent owners with their implementation. Fixture prerequisites were ordered before dependent browser assertions; Plan07 records the host replay fixture counter adjustment. Do not add a dependency or parallel coverage registry.

## Failure Controls and Safety Evidence

- Validated returns: foreign origin/mount/owner, malformed escapes, duplicate/unsupported keys, decoder/encoder parity, actual result membership, and label/destination agreement.
- Relationships: missing or foreign subject/source/parent renders a truthful unavailable state without a usable unrelated link.
- Replay: selection/owner/eligibility changes after review, duplicate confirmation, step-up denial/dismissal, pre-dispatch read failure and post-acceptance reread failure. Observe exact jobs/dispatch/audit/state; HTTP method counts prove only their narrower transport claim.
- Connect: exact reviewed target/current policy/proposal, invalid fee precision/input, fresh actor/owner/policy, step-up and duplicates, authoritative persisted fee state on dismissal/failure/success. Preserve the absence of a Stripe-report timestamp.
- Search: pointer → Arrow → Enter selects the visibly and accessibly active real destination; delayed previous query/owner and LiveView replacement cannot reinstate stale results. Successful groups survive partial failure.
- Every runnable task command has an immediately paired `<fails_when>` signal. Commands must fail on failed assertions/nonzero exit and must not accept zero selected cases.

## Mounted Consumer Proof

Reuse Phase 191 page-flow, Phase 199 overlays, host Phase 238 events/webhooks and Phase 234 search completion owners. Final plans must select concrete new cases and grounded commands, not assume an old green suite exercises the change. Include changed catalog/Connect consumers, focus/disclosure/validation/correction/dismissal, busy/reconnect, supported narrow/theme/coarse-pointer and measured text stress. Apply and measure text stress atomically around LiveView replacement. Record source, fixture, built, compiled and served asset identity separately from behavior.

Update incumbent route/state coverage and use existing CI lanes for recurring assertions. After all seven canonical SUMMARYs and passing phase verification exist, the GSD phase execute/verify owner follows `242-EXECUTION-HANDOFF.md`: generate automated UAT through the existing owner and run `node scripts/ci/verify_executable_uat_contract.mjs --all-since 229`. This is a downstream phase-completion gate, not the 242-07/T3 pre-completion verify. No remote CI result is inferred from local proof. Phase 243 owns reviewed Linux goldens and the stable feedback preview.

## Manual-Only Verifications

All four requirement IDs have executed automated verification through the sixteen tasks. Independent phase-goal verification remains the completion owner. Required human UAT: zero. Actual browser zoom, physical devices, screen-reader speech, live-provider behavior and remote CI are distinct unobserved claims unless separately exercised; they do not become confirmation-only checkpoints.

## Validation Sign-Off

- [x] Final task map matches all PLAN task IDs/waves and unique `T-242-NN` references.
- [x] Every task has a runnable automated owner and observable failure signal.
- [x] No three consecutive tasks lack automated feedback; no watch mode or zero-test acceptance.
- [x] New scenario/fixture prerequisites are ordered before consumers.
- [x] Current combined acceptance and asset provenance are recorded.
- [x] Actual timings and evidence limits are recorded.
- [x] Validation audit promotes `nyquist_compliant` only after execution proof.

**Approval:** Automated validation audit passed. Sixteen task owners, four requirements, no missing validation owner and no manual-only gate. Combined proof: Admin 679/0, Node 44/0, host 223/0; package191 29 passed/1 incumbent skip, package199 27 passed/15 incumbent skips, host browsers 2 passed. Incumbent browser skips are explicitly bounded in 242-EXECUTION-GATES.md and do not establish changed-behavior acceptance. Source/build/compiled/served identity and observed visual limits remain in that record. Independent phase verification and generated executable UAT remain downstream.

## Validation Audit 2026-10-10

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
