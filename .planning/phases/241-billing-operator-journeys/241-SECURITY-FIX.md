# Phase 241 Security Acceptance Follow-up

Completed 2026-10-10. This follow-up closes the three assigned acceptance gaps with existing owners and disposable Fake-backed fixtures.

## T-241-14 — Authoritative action dispatch and uncertain outcomes

- ChargeLive tests now assert `Accrue.Processor.Fake.call_count(:create_refund)` directly. The timeout control proves one provider dispatch, an uncertain outcome message, no confirmation affordance, and no repeated dispatch when a stale confirm event is sent. Persisted refund rows are not used as provider-call evidence.
- CustomerLive tests assert provider callback counts for `:detach_payment_method` and `:set_default_payment_method`. A scripted detach timeout is counted once, displays a safe outcome-not-confirmed message, and stays at one after a repeated event and LiveView reconnection.
- The CustomerLive error fallback treats unrecognized action failures as uncertain and directs operators to reload current payment methods before deciding whether to act again. The app performs no automatic retry.
- Evidence: `MIX_ENV=test mix test test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/subscription_live_test.exs` — 80 tests, 0 failures. Admin warnings-as-errors compilation passed.
- Commit: `9001df28` (`test(241-security): prove refund and payment method dispatch safety`).

## T-241-15 — Mounted host invoice review dispatch count

- Added a read-only Fake callback-count endpoint under the existing `sql_sandbox`-guarded authenticated test route; a runtime `sql_sandbox` guard returns 404 if the route is invoked with the test seam disabled. Production router configuration does not mount the endpoint.
- The mounted Playwright case records `invoice_action` before review and after Escape dismissal, asserts equality, and records the measured count and delta in the capture manifest. The disposable host fixture observed `0` before and `0` after (`delta: 0`). No provider was called and no persisted-row inference is used.
- Evidence: `CI=1 npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop --workers=1` — 1 passed. Host warnings-as-errors compilation passed. The first sandboxed browser launch was denied by macOS bootstrap permissions; the same command passed after the environment allowed Chromium startup.
- Durable screenshots and manifest: `.planning/phases/241-billing-operator-journeys/evidence/phase237-exemplar/` (manifest records source, asset and capture hashes, with provider count 0→0).
- Commit: `a009148b` (`test(241-security): measure mounted review dispatches`).
- Evidence commit: `f85e07cd` (`docs(241-security): preserve mounted host evidence`).

## T-241-07 — Subscription staged-action navigation

- Added a LiveView regression that stages an immediate cancellation, navigates to the list and back to detail, reopens and dismisses the review, sends the stale view's confirm event, and reopens detail again. The authoritative `:cancel_subscription` count remains zero throughout; no staged confirmation survives the fresh detail mount.
- Evidence: included in the focused three-owner run above (80 tests, 0 failures).
- Commit: `3ee303c6` (`test(241-security): cover staged subscription navigation`).

## Evidence limits

- The host proof covers the exercised staged invoice review and Escape dismissal; it makes no claim about live-provider behavior.
- The E2E runner refreshed five tracked Phase 240 capture files in place. The parent confirmed they were clean before the run; fresh artifacts were preserved under the Phase 241 evidence directory, then only those five Phase 240 generated files were restored from HEAD.
- Phase 241 Plan 07's duration remains reported as 66 minutes in its Performance section and 228 minutes in its metrics. Available timestamps do not substantiate a correction, so the existing discrepancy is preserved.
- Detailed touched-file coverage is recorded in `241-06-SUMMARY.md` and `241-07-SUMMARY.md`.
