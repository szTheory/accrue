---
phase: "244"
slug: "operator-language-and-evidence"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-10"
audited: "2026-10-10"
---

# Phase 244 — Validation Strategy

## Test Infrastructure

Existing ExUnit/Phoenix.LiveViewTest owners in `accrue_admin` and the incumbent host Playwright suite in `examples/accrue_host`. No dependency or test framework was added.

Focused Admin command:

```sh
cd accrue_admin && mix test test/accrue_admin/copy/billing_event_test.exs test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhook_replay_test.exs
```

Focused browser command (desktop and touch tests are separately tagged; touch uses the incumbent `chromium-desktop` project with a 320×800 viewport):

```sh
npm --prefix examples/accrue_host run e2e -- e2e/phase244-operator-evidence.spec.js --project chromium-desktop --grep @phase244-desktop --workers 1
npm --prefix examples/accrue_host run e2e -- e2e/phase244-operator-evidence.spec.js --project chromium-desktop --grep @phase244-mobile --workers 1
```

## Requirement Coverage

| Requirement | Behavioral evidence | Result |
|---|---|---|
| LANG-01 | Copy tests verify source-backed meanings and neutral unknown/missing-key handling; Home, Events, and webhook owner tests assert shared rendered labels. | green |
| EVID-01 | EventLive test checks seconds, fractional precision, and UTC offset. Desktop and 320px browser checks confirm the exact scoped key/record/time; webhook owner/browser tests check selectable exact evidence. | green |
| CONS-01 | Home, Events, event detail, webhook, and replay tests assert actual scoped destinations/effects. Desktop and touch browser tests navigate the scoped Home/event/webhook routes and inspect served assets. | green |
| STATE-01 | Replay owner tests bind requested/queued, blocked, denied, failed, unknown, accepted-with-unavailable-reread, and read-only recovery claims to state, dispatch jobs, and audit events. | green |

## Per-Task Verification Map

| Task | Requirement | Owning proof and actual result | Command / revision | Status |
|---|---|---|---|---|
| 244-01 T1 | LANG-01, EVID-01, CONS-01 | EventLive 15 tests, 0 failures; mounted Home-to-event browser proof 1/1 passed with matching served/package/compiled assets. | `cd accrue_admin && mix test test/accrue_admin/live/event_live_test.exs`; `npm --prefix examples/accrue_host run e2e -- e2e/phase244-operator-evidence.spec.js --project chromium-desktop --grep @phase244-desktop --workers 1` at `5a0876f9`. | green |
| 244-01 T2 | LANG-01, EVID-01 | Copy and Home owners: 8 tests, 0 failures; unknown/malformed key and raw-value behavior are asserted. | `cd accrue_admin && mix test test/accrue_admin/copy/billing_event_test.exs test/accrue_admin/live/dashboard_live_test.exs` at `5a0876f9`. | green |
| 244-02 T1 | LANG-01, EVID-01, CONS-01 | Events and event detail owners: 29 tests, 0 failures; list/detail label, raw key/filter, and scoped-link assertions include exact timestamp regression. | `cd accrue_admin && mix test test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs` at `613f2309`. | green |
| 244-02 T2 | LANG-01, EVID-01, CONS-01 | Webhook related-activity owner and tagged desktop/touch browser checks passed; the summaries record 52/52 focused tests across changed event/webhook/asset owners and browser revision `613f2309`. | `cd accrue_admin && mix test test/accrue_admin/live/webhook_live_test.exs`; desktop and mobile tagged browser commands above at `613f2309`. | green |
| 244-03 T1 | STATE-01, CONS-01, LANG-01, EVID-01 | Replay/read/event owners: 49 tests, 0 failures, including accepted enqueue + failed reread and no second dispatch on read retry. | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/event_live_test.exs` at `36f69a5a`. | green |
| 244-03 T2 | STATE-01, CONS-01, LANG-01, EVID-01 | Full Admin regression: 688 tests, 0 failures. Desktop browser subset: 2/2; touch subset: 1/1; browser evidence binds revision `33242617`, fixture state, served CSS/JS hashes, and no replay mutation before step-up. | `cd accrue_admin && mix test`; tagged desktop/mobile browser commands above at `33242617`. | green |
| Validation additions | LANG-01, EVID-01, CONS-01 | Added Home scoped empty/many assertions, webhook activity empty/many assertions, and a 320px EventLive timestamp/overflow browser assertion. Focused Home+webhook owners: 25 tests, 0 failures. Tagged mobile lane: 2/2 passed at `80086cc2044f9429f8f9830b58ea232678a436c3`; exact timestamp was visible and document/field widths were 320/280px. | `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/live/webhook_live_test.exs`; `ACCRUE_HOST_PROOF_RUN_ID=26284-1791685212995 npm --prefix examples/accrue_host run e2e -- e2e/phase244-operator-evidence.spec.js --project chromium-desktop --grep @phase244-mobile --workers 1`. | green |

The full Admin regression was last run at `33242617`; it was not repeated after the validation-only tests were added. The affected owners were rerun at `80086cc2`. The mobile browser first could not launch Chromium in the sandbox and did not enter either test body; the same command passed after browser-launch access was granted. Custody preflight showed the feedback preview stopped, the proof database separate, and port 4101 unused before the run.

## UI Probe Audit

The UI-SPEC probe contains 35 state considerations: 6 explicit and 29 backstop. All 6 explicit states have owner assertions. Each of the 29 backstops was checked against the changed behavior and owning source; the UI-SPEC consideration table records covered cases and source-grounded not-applicable cases. In particular, Home has no partial/loading/error branch, and webhook Activity has an intentional pre-load instruction followed by synchronous rendering rather than an in-flight state. The four scope-specific one/many cases now have rendered owner assertions; Events already covers empty, populated, and paginated collections. Narrow-width browser evidence covers EventLive timestamp, webhook evidence, and replay step-up controls.

## Requirement and Decision Trace

The three completed plans map the four requirements across six auto tasks. D-01–D-03 are exercised by producer-backed Copy and cross-surface label assertions; D-04–D-06 by exact evidence, timestamp, and native disclosure assertions; D-07–D-10 by scoped-link, read-only recovery, and replay step-up/effect assertions; D-11–D-14 by mounted route, fixture, viewport, asset, and preview-custody evidence; D-15 by using existing owners without a dependency or new runtime seam. These results come from executed owner tests and browser assertions, not from taxonomy classification or human UAT.

## Review Flags (not requirement gaps)

- The plan's STATE-01 edge probe remains unclassified. No behavior was invented for it; retain it for independent verifier review.
- Three descriptor-less prohibitions remain unresolved for review: no completion claim from queue acceptance alone; no generic mutation retry after uncertain observation; no raw/sensitive payload on Home. They are not marked as machine-proved here and are not converted into manual-only requirements.
- The mounted browser did not induce an event read outage or render the accepted-replay/failed-reread state. Those states are covered by focused LiveView assertions; browser rendering remains explicitly unobserved.

## Validation Sign-Off

- [x] All three plans and summaries read; six task rows mapped to owning proofs.
- [x] All four phase requirements have executed automated behavioral evidence.
- [x] No implementation files were changed during validation.
- [x] Focused owner suites and the changed browser lane ran; no zero-test run is counted as passing.
- [x] UI probe states were checked against owner assertions or dismissed with a sourced reason.
- [x] Revision-bound browser evidence records served asset identity and preview custody.
- [x] `nyquist_compliant` set true based on requirement proofs; verifier review flags above remain visible and unclaimed.

## Validation Audit 2026-10-11

| Metric | Count |
|---|---|
| Gaps found | 3 |
| Resolved | 3 |
| Escalated | 0 |

## 244-04 Executable Gap Closure

| Former verifier backstop | Owning assertion | Executed result |
|---|---|---|
| Truth 6: unusual raw event-key bytes remain selectable and exact | Mounted webhook Activity evidence disclosure checks exact stored Unicode key in rendered evidence and selected text. | Passed in the 320×800 touch case. |
| Truth 7: long/Unicode identifiers remain exact and usable | Long Unicode actor ID, external subject ID, processor event ID, and raw event key are asserted in rendered/selectable evidence with valid event numeric IDs and webhook UUID. | Passed in the 320×800 touch case; `document.scrollWidth=320`, evidence width 221px. |
| Truth 8: adjacent actions and repeated matching rows preserve association/order | Desktop duplicate rows share the same label/value but retain numeric IDs 3133 then 3134, each has its own exact scoped `Open event` href; touch flow activates the event's scoped Related billing webhook action. | Passed; desktop duplicate case and touch navigation case both executed. |
| Truth 9: long/Unicode link labels keep scoped destinations and remain operable | Touch Related billing `Actor <long Unicode ID>` link is checked for exact label, expected webhook UUID path, org query, nonzero target bounds, and successful tap navigation. | Passed at 320×800. |

Task 1 owner coverage: `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs` — 16 tests, 0 failures at `e608c2f4`.

The final batched browser command was `ACCRUE_HOST_PROOF_RUN_ID=26284-1791685212995 npm --prefix examples/accrue_host run e2e -- e2e/phase244-operator-evidence.spec.js --project chromium-desktop --grep '@phase244-(desktop|mobile)' --workers 1`; 6 tests passed, 0 failed at `1b62ad78a754fcd8c8bbae6aa3b1847ed9e97fa4`. The spec SHA-256 was `33dade95e36208063b6d539646660d297ff3b8be637c3b01409b15351f0698ba`. Served, packaged, and compiled assets matched: CSS `b40ac1dc7bb6a09ac7bccedb10ac1856ea9cbad212d69ce11db054a22807b952` (129,964 bytes), JS `e228bac9b978a658b37e96b9aa833fe6e8a87358447d00d93e616f55f5667c26` (161,648 bytes). Custody preflight confirmed preview stopped, isolated `accrue_host_test`, and port 4101 unoccupied before each start; feedback preview and Docker Up were untouched.

Recorded fixture-only failures during development: invalid test actor type (`external`, rejected by the persisted enum), then selector assumptions that did not match the rendered generic billing label and action regions. They were corrected in the browser spec; no product CSS change was needed. The final six-case confirmation passed on one committed revision.

These rows replace the four former human backstops with executable browser evidence. `human_judgment: false` is recorded in `244-04-SUMMARY.md`; the phase verification report remains owned by the post-execution verifier.

## Incremental Review Closure — WR-02

The refreshed review found that a pre-dispatch detail read failure was labeled “Dispatch result could not be confirmed,” despite `attempted: false`. `19449fb4` passes the actual attempt flag into copy selection and renders “Delivery could not be read; replay was not requested.” The adjacent read-failed owner test now checks this exact text along with no link, no dispatch job, no replay-request event, and `attempted: 0`. The accepted-enqueue/reread-failed test remains unchanged and verifies the accepted queue plus unknown processing status. Verification: focused `webhook_replay_test.exs` suite, 16 passed / 0 failed; three-file `mix format --check-formatted` and `git diff --check` passed. No browser rerun was needed because no rendered geometry, route, or browser asset changed.
