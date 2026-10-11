---
phase: "247"
slug: "evidence-true-details-and-analytics"
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| Behavior | Requirement | Planned tasks / executable owner | Threat refs | Status |
|---|---|---|---|
| Local/UTC, persisted preference, UTC SSR fallback, exact precision, missing timestamp | TIME-01 | 247-01-01/02, 247-02-01, 247-03-01/02/03, 247-08-01/02; timestamp_test.exs, time_display_test.mjs, affected LiveView tests, mounted tracer | T-247-01, T-247-02, T-247-03, T-247-08 | pass |
| Clipboard resolved/rejected/unavailable and manual fallback | TIME-01, DETAIL-02 | 247-02-02; clipboard_test.mjs and 247-07 mounted proof | T-247-02, T-247-07 | pass |
| Matching names/breadcrumbs/scoped destinations | LANG-02 | 247-04-01, 247-05-01/02/03, 247-06-02; scoped_path_test.exs, copy_test.exs and affected LiveView owners | T-247-04, T-247-05, T-247-06, T-247-07 | pass |
| Evidence-backed unavailable/zero/history/status | STATE-02 | 247-04-01/02, 247-05-01/02/03, 247-06-01; copy, webhook, detail and recovery tests | T-247-04, T-247-05, T-247-06, T-247-07 | pass |
| Replay, disclosure, JSON tabs, auth/confirmation/step-up | DETAIL-01, DETAIL-02 | 247-04-01/02, 247-07-01/02; webhook_live_test.exs, webhook_replay_test.exs, mounted proof | T-247-04, T-247-07 | pass |
| Currency comparisons, zero/absent/unsupported, definitions/coverage/window | METRIC-01 | 247-06-01/02, 247-07-01/02; recovery_live_test.exs and mounted proof | T-247-06, T-247-07 | pass |

## Wave 0 Requirements
- Add pure time display and clipboard failure tests in the implementing plans.
- Add one Phase 247 mounted proof spec/manifest owner after product implementation.
- Existing infrastructure provides all runners. No empty stub test acceptance.

## Rendered Review
Inspect representative populated webhook detail, existing detail/action review and analytics at 1280x900/320x820 light/dark. Separate ordinary and held-out fixtures. Held-out uses port4102. Source SHA, served JS/CSS digests, image digests and actual viewport are required. Full-page height may exceed viewport. Original phase243 protected. Secret stays in unprinted temporary memory solely authorized Fake login. Browser first launch needs escalation for Mac MachPort.

## Manual-Only Verifications
No owner-blocking UAT: delegated visual judgment is performed by image inspection using Impeccable; all objective behaviors require tests. Preserve human judgment limits in evidence.

## Plan 247-07 Execution Evidence

- Focused owner suite: `mix test --warnings-as-errors --seed 0` in `accrue_admin` — **727 tests, 0 failures**. One pre-existing unused-variable warning in `subscription_live.ex` is unrelated to this plan.
- Asset build: `NPM_CONFIG_CACHE=/private/tmp/accrue-npm-cache mix accrue_admin.assets.build` — passed after the final product source change.
- Ordinary mounted proof: `playwright.phase247-ordinary.config.js`, `@phase247-current-ordinary` — **1 test passed**, against `http://accrue-host-phase245-ordinary.localhost/` with `ACCRUE_HOST_SKIP_SEEDS=1`; guarded seed setup verified Phase 243 custody.
- Held-out mounted proof: `playwright.phase247.config.js`, `@phase247-current-heldout`, port 4102 — **1 test passed** against the isolated fixture.
- Render owner syntax and listing: `node --check examples/accrue_host/e2e/phase247-current-proof.spec.js`, `node --check scripts/ci/verify_phase247_render_proof.mjs`, and `./node_modules/.bin/playwright test --config=playwright.phase247-ordinary.config.js e2e/phase247-current-proof.spec.js --project=chromium --list` — passed with one listed test. The held-out configuration also listed one test.
- Capture validator: `node scripts/ci/verify_phase247_render_proof.mjs --manifest .planning/phases/247-evidence-true-details-and-analytics/captures/phase247-current-proof/manifest.json` — **16 inspected images accepted**, source `60cbf06331c2`, CSS/JS digests match served assets, ordinary and held-out lanes both present.
- Browser scenarios cover invoice action review, payment recovery, populated held-out webhook detail and replay review; each uses 1280×900 and 320×820 viewports in light and dark themes. Full-page PNG dimensions are independently recorded.
- Fixture limitation: the held-out database has only two dead webhook deliveries. It does not contain a separate eligible blocked-state detail; activity and raw payload evidence are empty for the selected detail. This unavailable visual state is recorded in the capture review, without fabricating a scenario.
- Initial ordinary lifecycle omitted `ACCRUE_HOST_SKIP_SEEDS=1` and seeded only the Phase245 ordinary host. The guarded seed wrapper then ran with the skip flag, verified custody, and confirmed the protected Phase243 snapshot remained unchanged. The Phase243 host was never mutated.
- The plan prescribed Phase246 config paths, whose `testMatch` excludes Phase247. Execution used dedicated Phase247 ordinary and held-out configs created by task 01. Port 4101 remained untouched.

## Validation Sign-Off
- [x] All tasks have automated verification and unique security refs
- [x] No missing test owners without implementation task
- [x] Sampling continuity and no watch flags
- [x] Exact committed-source mounted evidence inspected
- [x] Final suite green
- [x] nyquist_compliant true after execution audit

**Approval:** execution evidence recorded; phase-level integrated verification remains with Phase 248 and the phase verifier.

## Nyquist Coverage Cross-Check
All eight plan summaries and the six requirement rows were checked against their owning tests. The final Admin suite covers the ExUnit/LiveView owners (727 passing); a current audit run of `node --test test/js/time_display_test.mjs test/js/clipboard_test.mjs` passed 10/10. Mounted exact-copy tracer and final rendered proof are recorded separately in Plans 01 and 07. No missing automated owner or implementation gap was found. Visual judgment remains scoped to the inspected matrix, not every possible fixture.

## Validation Audit 2026-10-11

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
