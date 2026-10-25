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
