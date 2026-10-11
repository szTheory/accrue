---
phase: "247"
slug: "evidence-true-details-and-analytics"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-11"
---

# Phase 247 — Validation Strategy

## Test Infrastructure
Existing ExUnit/LiveView, Node built-in tests, and host Playwright. No installation needed.
Quick feedback: affected owning ExUnit files or `node --test test/js/time_display_test.mjs test/js/clipboard_test.mjs` from accrue_admin after those new owners exist.
Full phase gate: `cd accrue_admin && mix test --warnings-as-errors --seed 0`.

## Sampling Rate
Every implementation task has a focused automated check; each wave runs affected owners. One final full Admin gate and one bounded mounted capture batch after committed source/assets. No repeated full-suite runs absent a new change/failure. Planner must populate task IDs and unique threat refs once plans exist.

## Per-Task Verification Map
| Behavior | Requirement | Test owner | Status |
|---|---|---|---|
| Local/UTC, persisted preference, UTC SSR fallback, exact precision, missing timestamp | TIME-01 | new time_display Node/component owners and mounted proof | pending |
| Clipboard resolved/rejected/unavailable and manual fallback | TIME-01, DETAIL-02 | new clipboard Node owner and mounted proof | pending |
| Matching names/breadcrumbs/scoped destinations | LANG-02 | copy, scoped_path, affected LiveView owners | pending |
| Evidence-backed unavailable/zero/history/status | STATE-02 | copy, webhook, affected consumer tests | pending |
| Replay, disclosure, JSON tabs, auth/confirmation/step-up | DETAIL-01, DETAIL-02 | webhook_live, webhook_replay, detail/json component tests and mounted proof | pending |
| Currency comparisons, zero/absent/unsupported, definitions/coverage/window | METRIC-01 | analytics/recovery_live_test.exs and mounted proof | pending |

## Wave 0 Requirements
- Add pure time display and clipboard failure tests in the implementing plans.
- Add one Phase 247 mounted proof spec/manifest owner after product implementation.
- Existing infrastructure provides all runners. No empty stub test acceptance.

## Rendered Review
Inspect representative populated webhook detail, existing detail/action review and analytics at 1280x900/320x820 light/dark. Separate ordinary and held-out fixtures. Held-out uses port4102. Source SHA, served JS/CSS digests, image digests and actual viewport are required. Full-page height may exceed viewport. Original phase243 protected. Secret stays in unprinted temporary memory solely authorized Fake login. Browser first launch needs escalation for Mac MachPort.

## Manual-Only Verifications
No owner-blocking UAT: delegated visual judgment is performed by image inspection using Impeccable; all objective behaviors require tests. Preserve human judgment limits in evidence.

## Validation Sign-Off
- [ ] All tasks have automated verification and unique security refs
- [ ] No missing test owners without implementation task
- [ ] Sampling continuity and no watch flags
- [ ] Exact committed-source mounted evidence inspected
- [ ] Final suite green
- [ ] nyquist_compliant true after execution audit

**Approval:** pending execution
