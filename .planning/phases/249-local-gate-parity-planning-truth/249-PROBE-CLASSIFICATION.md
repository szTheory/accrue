# Phase 249 Probe Classification Ledger (GREEN-04, R10)

Positive control: `cd accrue_admin && MIX_ENV=test ACCRUE_ADMIN_E2E_PORT=4017 npm run e2e:group-contracts`
failed 6 of 16 tests before any edit (3 probes x chromium-desktop and chromium-mobile). Failures were
stale-literal assertions, each traced to an intentional source commit; no UI behavior broke. No probe was
skipped, deleted, or loosened to a non-specific matcher. No baselines were touched.

Receipt note for the window label and invoices heading: `.planning/notes/2026-10-18-admin-owner-feedback.md`
(line 18: "Invoices and Payments use stable destination headings"; line 20: "The compact date selector states UTC once").
Receipt for the webhook detail: same note line 10/22 (webhook detail reviewed and refined, replay behavior preserved)
plus commit e6f39cef (247-04) and its updated `webhook_live_test.exs`.

| Probe (spec line, title, project) | Failing assertion | Current source | Causing commit | Receipt | Classification | Fix |
|---|---|---|---|---|---|---|
| spec:616 active filter/selection/sort/subview cues; chromium-desktop | `currentWindow` toContainText `30 days UTC` (was line 269) | `window_selector.ex:~44` renders `<%= label %>` only; nav `aria-label="Time window (UTC)"` at line 32 | b4a7eeac (removed trailing ` UTC` from visible label) | owner-feedback note l.20 | stale-contract | Visible text asserted as `30 days`; added assertion that `nav[aria-label*="UTC"]` is visible so UTC disclosure is still enforced |
| spec:616 same; chromium-mobile | same | same | b4a7eeac | same | stale-contract | same |
| spec:626 operator-stress group scan; chromium-desktop | GROUP_FINDABILITY `tabs-subviews` `/30 days UTC/i` (was line 89, asserted at 204) | same as above | b4a7eeac | owner-feedback note l.20 | stale-contract | Matcher changed to `/30 days/i` |
| spec:626 same; chromium-mobile | same | same | b4a7eeac | same | stale-contract | same |
| spec:643 representative live probes, list-table route `/billing/invoices`; chromium-desktop | heading `/Clear open receivables/i` (was line 470) | `copy/invoice.ex:34` `invoices_list_heading` = `"Invoices"`, rendered as `h1` by PageHeader via `invoices_live.ex:111` | b4a7eeac (`"Clear open receivables"` -> `"Invoices"`) | owner-feedback note l.18 | stale-contract | `getByRole('heading', { name: 'Invoices', exact: true })` |
| spec:643 same; chromium-mobile | same | same | b4a7eeac | same | stale-contract | same |
| spec:643 overlay-path route `/billing/webhooks/:webhook_id` (revealed after first fix); chromium-desktop | `[data-component-group="detail-header-metadata-actions"]` not found | `webhook_live.ex` uses `PageHeader.page_header component_group="webhook-detail-header"`, status in `data-role="webhook-observed-status"` | e6f39cef (247-04: Detail.summary_card -> PageHeader) | note l.10/22; commit message and updated `webhook_live_test.exs` | stale-contract | Asserts `webhook-detail-header` group and observed-status role visible; replay assertions kept |
| spec:643 same; chromium-mobile | same | same | e6f39cef | same | stale-contract | same |
| spec:643 overlay-path replay copy (revealed after second fix); chromium-desktop | text `/Single replay calls the existing DLQ primitive\|Replay is unavailable/i` | `webhook_live.ex:501` `"Queues another delivery attempt. Queue acceptance does not confirm processing."` | e6f39cef | same | stale-contract | Literal updated to the new sentence; `Replay is unavailable` alternative retained |
| spec:643 same; chromium-mobile | same | same | e6f39cef | same | stale-contract | same |

No row is classified `regression`: for each, the changed behavior is documented as intentional in a commit and
its updated unit test, and the user-visible capability (UTC disclosure, invoices destination heading, webhook
replay action and guidance) is still present and asserted.

Final result: `npm run e2e:group-contracts` 16 passed (chromium-desktop and chromium-mobile).

## Lanes

Job `admin-group-contracts` replayed with `249-replay-ci-job.py --run` at HEAD 285c01bd (spec fix commit).

| Step | Result |
|---|---|
| 02 Detect Phase 190 browser-relevant changes | PASS (replayed with `--env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA=`; `github.event.*` is unresolvable locally, a first run without it reported FAIL on those unresolved vars only) |
| 03 Phase 190 automation contract | PASS |
| 08 Install admin deps | PASS |
| 09 Compile admin package | PASS |
| 10 Install browser deps | PASS |
| 12 Run Phase 190 group-contract browser gate | PASS |

Skips: `Install Hex` (global hex already installed on the host), `Install Chromium` (apt-backed; Playwright Chromium already cached).
Also `bash scripts/ci/verify_phase190_automation_contract.sh` -> ok.

## Plan 249-08: admin-hardening-guardrails

Positive control: first replay failed step 13 (`Run Phase 192 admin hardening guardrails`) on 2 of the phase191 page-flow tests, before any edit.

| Probe (spec line, title, project) | Failing assertion | Current source | Causing commit | Receipt | Classification | Fix |
|---|---|---|---|---|---|---|
| admin-page-flow-phase191.spec.js:555 (was 469 test) disposable phase 240 subscription action stays busy through a single held dispatch; chromium-desktop | `getByText('Subscription has ended', {exact:true})` not found after cancel completes | `copy.ex:1001` `subscription_action_recorded_info` = `"Subscription action recorded."`; lifecycle `Canceled` still rendered (screenshot + a11y snapshot) | b4a7eeac (fix(admin): clarify billing views and recorded evidence) removed the `headline: "Subscription has ended"` status-card copy | `.planning/notes/2026-10-18-admin-owner-feedback.md` (clarified billing views); commit b4a7eeac diff | stale-contract | Asserts `Subscription action recorded.` visible and a `Canceled` label visible; all dispatch/audit/event assertions unchanged |
| same; chromium-mobile | same | same | b4a7eeac | same | stale-contract | same |

### Lanes (249-08 Task 1)

Job `admin-hardening-guardrails` replayed with `249-replay-ci-job.py --run --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA=`: all steps PASS (7 PASS, 2 SKIP).
Skips: `Install Hex`, `Install Chromium` (already present on host).

## Plan 249-08: admin-phase200-guardrails

Positive control: first replay failed step 12 (`Run Phase 200 deterministic guardrails`, which runs `verify_phase200_admin_guardrails.sh`) in the `e2e:phase199` sub-step: 9 failing tests (desktop plus mobile) before any edit. Steps after phase199 (reduced-motion, scorecard, sign-off) were unreached until phase199 was green, then passed in the in-job order.

| Probe (spec line, title, project) | Failing assertion | Current source | Causing commit | Receipt | Classification | Fix |
|---|---|---|---|---|---|---|
| phase199:965 floating panels (Command palette panel); chromium-desktop | `.ax-command-palette` not visible after trigger click | topbar trigger `topbar.ex:36` intact; same test passed on isolated re-run and on both later full replays | none found | n/a | not reproducible (timing flake; click raced LiveView connect after theme reload) | No edit. Passed in the isolated npm run and in both subsequent full job replays; recorded as an observed flake, not a fix |
| phase199:1037 route flows, Webhook drill link; chromium-desktop | link `/evt_e2e_phase199_dead/i` not found | `webhooks_live.ex` `webhook_link`: link text is `humanize(row.type)` ("Invoice.payment Failed"); event id is a copy badge | ec8a0d13 (246-04 separated identity across admin tables) | commit message | stale-contract | Link matcher `/Invoice\.payment Failed/i` |
| phase199:1037 route flows, Connect drill link (revealed after webhook fix); chromium-desktop | link `/acct_e2e_phase199_attention/i` not found | connect list link text is the account email; account id is a copy badge | ec8a0d13 | commit message | stale-contract | Link matcher `/phase199-connect@example\.com/i` |
| phase199:1057 open-invoice destination; chromium-desktop and chromium-mobile | `main a[href^='/billing/invoices/']` count 2, received 3 | one invoice renders hidden-table number link, card heading link, and `View invoice` action link; `resultIds` still dedupes to the single JPY invoice | 39759079/ec8a0d13 (identity separated, no repeated identity in cards) | commit messages | stale-contract | Count 3 with comment; the single-invoice identity assertion is unchanged |
| phase199:1318 mounted CSS stress, webhook delivery light 320px; chromium-desktop and chromium-mobile | `scrollWidth` 361 > 321 | `webhook_live.ex` page-header description `invoice.payment_failed` in `.ax-page-copy` without wrapping | e6f39cef (247-04 moved type into the header description) | WCAG 1.4.10 reflow, the contract's own intent | regression | Source fix: description wrapped in `<p class="ax-body">` (`overflow-wrap:anywhere`), same pattern as `dashboard_live.ex` (commit 50e814b4) |
| phase199:1318 same test, Home hit-target block (mobile only, revealed after fix) | `.ax-home .ax-page-header-actions > .ax-button` expected 3 | Home header shortcuts removed; shell search trigger remains | 3d7d949d (clarify home activity; removed `data-command-palette-trigger` shortcut from home) | owner-feedback note 2026-10-12 | stale-contract | Hit-target check retargeted to the topbar `[data-command-palette-trigger]` (1 mounted, height >= 44) |
| phase199:1401 repeated action labels, Webhook replay; chromium-desktop | button aria/text lacked `evt_e2e_phase199_dead` | `webhook_live.ex` Replay button under "Replay webhook" section; object id in page h1 `webhook_heading` | e6f39cef (removed per-button aria-label) | note l.10/22 as in the 249-07 receipt | stale-contract | Button context asserts `Replay webhook`; added `pageHeading` assertion that the h1 contains the event id |
| phase199:1495 auto-minted ratchet guards (focus-ring) rows f-68d2bf118467b34a and f-9e6f3e53a835a6d5; desktop and mobile | `.ax-home [data-command-palette-trigger]` must exist | trigger lives in the topbar, not `.ax-home` | 3d7d949d | as above | stale-contract | Selector `[data-command-palette-trigger]`; focus-ring outline assertion unchanged |

Final results: `npm run e2e:phase199` 29 passed (15 skipped by design: desktop-only projects); full job replay green.

### Lanes (249-08)

Both replays used `--run --skip 'Install Chromium' --skip 'Install Hex' --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA=`.

| Job | Result | Notes |
|---|---|---|
| `admin-hardening-guardrails` | PASS (7 PASS, 2 SKIP) | replayed again after the source fix |
| `admin-phase200-guardrails` | PASS (6 PASS, 2 SKIP) | scorecard and sign-off passed in their in-job order |

Phase 200 output: the scripts write to the hard-coded `.planning/phases/200-idempotent-verification-sign-off`; after every run it was moved to `$GSD_SCRATCH/phase200-output-<epoch>/` and its absence asserted, so no generated evidence entered the tree. The path was not changed (out of scope).

## Plan 249-09: admin-drift-docs and ratchet jobs

Replays used `--run --env GITHUB_EVENT_NAME=workflow_dispatch --env BASE_SHA= --env BEFORE_SHA=` (drift-docs also `--skip 'Install Hex'`).

| Job | Result | Notes |
|---|---|---|
| `admin-drift-docs` | PASS (4 PASS, 1 SKIP) | `Install Hex` skipped (already present). Rebuilt assets produced no diff: the committed admin bundle is fresh |
| `admin-ui-ratchet-selftests` | PASS (5 PASS) | ledger self-tests, sign-off self-test, Phase 208 CI contract, parked-lane expiry |
| `admin-ui-ratchet-guardrails` | ADVISORY (2 ADVISORY-PASS, 2 ADVISORY-FAIL), exit 0 | Steps `Verify frozen ratchet evidence` and `Verify UI ratchet sign-off` fail, but both are `continue-on-error` in ci.yml. Recorded exactly as CI treats it: the job is parked per WINDOWS row 11. Not reclassified, not fixed, no edits |
