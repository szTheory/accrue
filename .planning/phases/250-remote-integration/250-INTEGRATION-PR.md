<!-- pr: https://github.com/szTheory/accrue/pull/49 -->

## What a reviewer would reject this for

- Before this phase's fixes, CI runs 40204835226 and 40204835309 at `23bee494` were red for three root causes, each now fixed in its own commit:
  - `RecoveryLiveTest` failed 8 of 33 tests on a UTC database server. Fix: `fix(250-02): ceil RecoveryLiveTest clock and pin admin test PG timezone to UTC`.
  - `docs-contracts-shift-left` failed the D-32 cohort because `@playwright/test` was not installed. Fix: `ci(250-02): install host Playwright deps before the D-32 cohort`.
  - `time_display_test.mjs` failed under `TZ=UTC` because it read the host zone. Fix: `test(250-02): pin time_display test timezone`.
- The first run that reached `Host integration` (CI run 40213687124 at `bde9ae6c`) exposed a fourth cause: the ordinary seed boundary refused the CI Postgres service container (13 host tests). Fix: `fix(250-03): accept the GitHub Actions Docker-bridge Postgres in the ordinary seed boundary`.
- The second run (CI run 40216216053 at `11ede7ff`) got the host Playwright lane running for the first time since the 2026-10-12..19 admin owner-feedback series and found 24 specs asserting superseded UI, a missing keyboard focus ring on quiet admin links, and preview-only specs that threw in the default lane. Each is fixed in its own `fix(250-03)` commit; the lane was reproduced locally (`50 passed, 31 skipped, 0 failed`).
- The third run (CI run 40221570264 at `ead4f497`) left one host Playwright failure, `phase247-time-tracer`, which assumed a non-UTC browser zone on a UTC runner. Fix: `fix(250-03): pin the phase247 time tracer browser timezone`.
- The fourth run (CI run 40226070833 at `533d2ded`) was the first with `Host integration` green; it then reached the `Playwright E2E` shards for the first time and they timed out starting their server (cold compile in a proof build path). Fix: `fix(250-03): share one proof build path across the Playwright shard job`.
- Still open: the `Browser UAT` pixel-diff gate (`Phase 211 visual regression gate`), whose baselines predate the v1.63-v1.66 admin changes. It is re-minted from a workflow artifact only after each changed surface is classified.
- One product risk is found and deliberately not fixed here: `accrue_events.inserted_at` follows the Postgres session timezone. It is recorded as a HIGH-priority v1.68 item in `.planning/REQUIREMENTS.md` (Future Requirements).
- The parked `Admin UI ratchet guardrails [parked]` lane stays `continue-on-error` by design (`.planning/WINDOWS.md` row 11). It is outside the PR bar.

## Provenance

- **Head branch:** `integration/v1.63-v1.66`.
- **Evidence SHA:** pending. It is recorded here by plan 250-05 once the exact-SHA CI verdict is measured.
- The PR head may differ from the evidence SHA by exactly one commit that changes only this file.

## What changed, and how to check it

- RecoveryLiveTest aligns the fake clock by ceiling plus a 2-second margin, and the admin test repo pins the Postgres session timezone to UTC.
  Falsify: with only the pin applied on a server in America/New_York, `mix test test/accrue_admin/live/analytics/recovery_live_test.exs` in `accrue_admin` reports `33 tests, 8 failures`. With the fix it reports `33 tests, 0 failures`.
- The docs job runs `npm ci` in `examples/accrue_host` before the D-32 step.
  Falsify: in a clean clone without `examples/accrue_host/node_modules`, `node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor` prints a FAIL line naming the two host cohort files. After `npm ci` it prints PASS.
- The time_display test pins `process.env.TZ`.
  Falsify: with the pin removed, `TZ=UTC node --test accrue_admin/test/js/time_display_test.mjs` reports `# fail 1`. With the pin it passes under UTC, America/New_York and Asia/Tokyo.

## Rollback

One command, run immediately after this PR lands, against the merge commit GitHub creates: `git fetch origin && git revert -m 1 --no-edit $(git rev-parse origin/main)`.

## Scope

- Requirements LAND-01, LAND-02 and LAND-03 only.
- The PR is merged with a merge commit. There is no squash and no rebase.
- No milestone tag is pushed. This PR does not publish to Hex.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
