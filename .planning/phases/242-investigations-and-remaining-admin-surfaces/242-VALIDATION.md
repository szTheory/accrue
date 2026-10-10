---
phase: "242"
slug: "investigations-and-remaining-admin-surfaces"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-10"
---

# Phase 242 — Validation Strategy

> Planning contract. No Phase 242 product test or browser proof has run. The planner must reconcile the task map below to final plan/task IDs and unique threat IDs before plan checking. Execution and the validation audit own green statuses and compliance promotion.

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
| Runtime | Unmeasured for Phase 242; record actual task and suite timings during execution |

## Sampling Rate

- With each implementation task: add precise assertions in the existing behavioral owner and run that owner's focused command before committing accepted work.
- At dependency boundaries: run affected focused integration tests; batch mounted browser acceptance after combined changes and current package build.
- Before verification: run the combined Admin/host gate and changed package/host browser owners with nonzero selected tests. Zero matches, hidden retries or skips, and relaxed tolerances cannot establish acceptance.
- Visual budget: one batched desktop/narrow/effective-theme inspection, one corrective batch, at most one confirming inspection per agreed delivery batch. Count captures/scans/edits/rebuilds together. Cosmetic candidates require mounted confirmation; do not reset the budget by renaming a batch.

## Per-Task Verification Map

Final task IDs, waves, requirements and unique threat references are filled by the planner from the executable PLAN files. Existing files below are proof owners; new scenario assertions are authored with their corresponding implementation task, not claimed to exist today.

| Slice | Requirement | Test type | Automated command | File exists | Status |
|---|---|---|---|---|---|
| Validated returns and matching family labels | JRN-05, JRN-06 | Unit and LiveView | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs` | Yes | Pending |
| Event filter membership, related evidence and return | JRN-05 | Query and LiveView | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/queries/events_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs` | Yes | Pending |
| Delivery review freshness, no dispatch on dismiss, truthful outcomes | JRN-05 | LiveView integration | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/webhook_live_test.exs` | Yes | Pending |
| Coupon/code identity, restrictions, parent and filtered return | JRN-06 | LiveView and query | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs` | Yes | Pending |
| Connect observations, local fee review and policy freshness | JRN-06 | LiveView and Copy | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/connect_account_live_test.exs test/accrue_admin/copy/connect_test.exs` | Yes | Pending |
| Search input selection, generations and owner scope | JRN-07 | LiveComponent and Node | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/components/global_search_test.exs && node --test test/js/command_palette_test.mjs` | Yes | Pending |
| Coherent routine copy and verbatim locked wording | UXC-01 | Copy and changed LiveViews | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/copy` | Yes | Pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. New behavior assertions belong in incumbent owners with their implementation. The planner must name any new fixture prerequisites and order them before dependent browser assertions. Do not add a dependency or parallel coverage registry.

## Failure Controls and Safety Evidence

- Validated returns: foreign origin/mount/owner, malformed escapes, duplicate/unsupported keys, decoder/encoder parity, actual result membership, and label/destination agreement.
- Relationships: missing or foreign subject/source/parent renders a truthful unavailable state without a usable unrelated link.
- Replay: selection/owner/eligibility changes after review, duplicate confirmation, step-up denial/dismissal, pre-dispatch read failure and post-acceptance reread failure. Observe exact jobs/dispatch/audit/state; HTTP method counts prove only their narrower transport claim.
- Connect: exact reviewed target/current policy/proposal, invalid fee precision/input, fresh actor/owner/policy, step-up and duplicates, authoritative persisted fee state on dismissal/failure/success. Preserve the absence of a Stripe-report timestamp.
- Search: pointer → Arrow → Enter selects the visibly and accessibly active real destination; delayed previous query/owner and LiveView replacement cannot reinstate stale results. Successful groups survive partial failure.
- Every runnable task command has an immediately paired `<fails_when>` signal. Commands must fail on failed assertions/nonzero exit and must not accept zero selected cases.

## Mounted Consumer Proof

Reuse Phase 191 page-flow, Phase 199 overlays, host Phase 238 events/webhooks and Phase 234 search completion owners. Final plans must select concrete new cases and grounded commands, not assume an old green suite exercises the change. Include changed catalog/Connect consumers, focus/disclosure/validation/correction/dismissal, busy/reconnect, supported narrow/theme/coarse-pointer and measured text stress. Apply and measure text stress atomically around LiveView replacement. Record source, fixture, built, compiled and served asset identity separately from behavior.

Update incumbent route/state coverage and use existing CI lanes for recurring assertions. Canonical SUMMARY coverage uses `human_judgment: false`; generate automated UAT through the GSD owner and run the existing executable-UAT contract. No remote CI result is inferred from local proof. Phase 243 owns reviewed Linux goldens and the stable feedback preview.

## Manual-Only Verifications

All accepted phase behaviors have planned automated verification. Required human UAT: zero. Actual browser zoom, physical devices, screen-reader speech, live-provider behavior and remote CI are distinct unobserved claims unless separately exercised; they do not become confirmation-only checkpoints.

## Validation Sign-Off

- [ ] Final task map matches all PLAN task IDs/waves and unique `T-242-NN` references.
- [ ] Every task has a runnable automated owner and observable failure signal.
- [ ] No three consecutive tasks lack automated feedback; no watch mode or zero-test acceptance.
- [ ] New scenario/fixture prerequisites are ordered before consumers.
- [ ] Current combined acceptance and asset provenance are recorded.
- [ ] Actual timings and evidence limits are recorded.
- [ ] Validation audit promotes `nyquist_compliant` only after execution proof.

**Approval:** Planning draft; execution pending.
