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

Planner must replace the provisional requirement rows below with exact task IDs and grounded commands once decomposition is known.

| Requirement | Owner | Secure behavior | Verification | Status |
|---|---|---|---|---|
| LANG-01 | BillingEvent Copy and Home/event LiveViews | Persisted/filter keys retain identity | Known producer-backed labels, unknown/nil fallback, consumer parity | pending |
| STATE-01 | Webhook/replay LiveViews | Read retry never dispatches mutation; uncertain enqueue never invites duplicate replay | Completed/requested/failed/blocked/unconfirmed branches plus state/job/dispatch/audit evidence | pending |
| EVID-01 | Event/Home LiveViews and incumbent browser owner | Authorized projection and scoped relationships preserved | Exact key/IDs, seconds/fraction/timezone, missing time, keyboard/touch and long IDs | pending |
| CONS-01 | Targeted owning LiveViews/browser owner | Destinations remain scoped | Actual href/effect and disclosure activation assertions | pending |

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
