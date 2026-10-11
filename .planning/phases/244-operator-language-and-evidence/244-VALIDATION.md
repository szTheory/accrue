---
phase: "244"
slug: "operator-language-and-evidence"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-10"
---

# Phase 244 — Validation Strategy

## Test Infrastructure

Existing ExUnit/Phoenix.LiveViewTest in `accrue_admin/mix.exs`, with incumbent Playwright owners in `accrue_admin/playwright.config.js`.

Quick command: `cd accrue_admin && mix test test/accrue_admin/copy/billing_event_test.exs test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhook_replay_test.exs`.

Full regression: `cd accrue_admin && mix test`. Browser/build/parity commands must be grounded in existing owners during planning. Runtime is unmeasured in this planning session; do not invent a latency estimate or claim a pass.

## Sampling Rate

After each task run the affected owner subset of the quick command. After each coherent wave run the combined focused owners. Before final verification run the Admin regression and affected existing build/parity/browser owners. Commands fail on nonzero exit or no executed tests; preserve initial failures. Do not rerun unrelated broad matrices without evidence.

## Per-Task Verification Map

| Task | Requirement | Owning proof | Command (repository root unless `cd` shown) | Fails when | Status |
|---|---|---|---|---|---|
| 244-01 T1 | LANG-01, EVID-01, CONS-01 | Rendered EventLive exact time and isolated mounted Home-to-event auto slice, revision/asset identity and preview custody | `cd accrue_admin && mix test test/accrue_admin/live/event_live_test.exs`; `npm --prefix examples/accrue_host run e2e -- e2e/phase244-operator-evidence.spec.js --project chromium-desktop --grep @phase244-desktop --workers 1` | Either nonzero exit, zero EventLive tests, fewer than one selected browser test, missing sub-minute/timezone journey or asset/custody proof | planned |
| 244-01 T2 | LANG-01, EVID-01 | BillingEvent Copy and Home rendered known/unknown/missing parity | `cd accrue_admin && mix test test/accrue_admin/copy/billing_event_test.exs test/accrue_admin/live/dashboard_live_test.exs` | Nonzero exit, zero tests, changed raw key/filter identity | planned |
| 244-02 T1 | LANG-01, EVID-01, CONS-01 | Events list/detail semantic parity, exact key and scoped destination, preserving Wave 1 timestamp evidence | `cd accrue_admin && mix test test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs` | Nonzero exit, zero tests, regression of exact evidence or wrong scope | planned |
| 244-02 T2 | LANG-01, EVID-01, CONS-01 | Related activity owner and named desktop/mobile disclosure/navigation tests | `cd accrue_admin && mix test test/accrue_admin/live/webhook_live_test.exs`; `npm --prefix examples/accrue_host run e2e -- e2e/phase244-operator-evidence.spec.js --project chromium-desktop --grep @phase244-desktop --workers 1`; `npm --prefix examples/accrue_host run e2e -- e2e/phase244-operator-evidence.spec.js --project chromium-desktop --grep @phase244-mobile --workers 1` | Any nonzero result, zero owner tests, fewer than one selected test in either browser subset, inaccessible evidence, delivery/event conflation or asset/custody drift | planned |
| 244-03 T1 | STATE-01, CONS-01 | Rendered outcome plus state/job/dispatch/audit and zero mutation from read retry | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/event_live_test.exs` | Nonzero exit, zero tests, unsupported effect/cause or duplicate dispatch | planned |
| 244-03 T2 | STATE-01, CONS-01, LANG-01, EVID-01 | Final mounted effects/destinations and Admin regression at tested revision | `npm --prefix examples/accrue_host run e2e -- e2e/phase244-operator-evidence.spec.js --project chromium-desktop --grep @phase244-desktop --workers 1`; `npm --prefix examples/accrue_host run e2e -- e2e/phase244-operator-evidence.spec.js --project chromium-desktop --grep @phase244-mobile --workers 1`; `cd accrue_admin && mix test` | Any nonzero result, fewer than one selected test per browser subset, zero Admin tests, mismatched effects, assets or custody | planned |

The host browser spec is a planned new file in the incumbent Playwright suite; commands are grounded by `examples/accrue_host/package.json` and `playwright.config.js`. The existing `chromium-mobile` project selects only `verify01-admin-mobile.spec.js`, so Phase 244's named mobile tests run under `chromium-desktop` with explicit 320×800 viewport, `isMobile: true`, and `hasTouch: true` settings, matching the incumbent Phase 234 test pattern. Each tagged browser subset is run separately and must execute at least one test. No plan command is reported as already run. The spec-less edge fallback has eight defensible predicates in `must_haves.truths` (four explicit, four flat-scalar backstops), plus one visibly flagged unclassified STATE-01 assumption. Three descriptor-less prohibition candidates remain flagged/unverified; no mechanical check is invented.

## Wave 0 Requirements

Existing infrastructure covers the phase. Extend existing tests for mapping/fallback, precision and affected mounted boundaries; no new framework or CI lane. Mounted candidates remain unobserved: confirm current output before edits, preserving the feedback preview and recording change/adequate/unobserved disposition.

## Rendered Review

One batched review, one corrective batch and one confirming round per coherent slice. Record tested revision, route/state/fixture, viewport/theme and served assets. Source-only inspection does not prove rendering. Comprehension judgment accompanies objective checks without inventing a routine owner-approval loop.

## Validation Sign-Off

- [ ] Exact task verification map populated by planner
- [ ] Every task has automated verification or explicit preceding dependency
- [ ] No three consecutive tasks without automated verification
- [ ] Missing tests created in existing owners
- [ ] No watch-mode flags
- [ ] Latency measured during execution if claimed
- [ ] Revision-bound focused/full/build/browser evidence recorded
- [ ] nyquist_compliant set true only after evidence supports it

Approval: pending execution; no suites run during planning.
