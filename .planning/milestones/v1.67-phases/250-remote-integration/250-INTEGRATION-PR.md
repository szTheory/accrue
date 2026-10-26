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
- The `Browser UAT` pixel-diff gate (`Phase 211 visual regression gate`, run 40229480489 at `b9c98b20`) failed before any pixel comparison: 247-03 moved timeline instants into the shared `Timestamp` control, so the spec's dashboard timestamp anchor no longer rendered. Fix: `test(250-04): retarget the Phase 211 dashboard timestamp anchor to the 247-03 Timestamp control` (no mask, threshold or surface added).
- Its baselines (`0197f4ba`, 2026-10-10) predated the v1.63-v1.66 admin changes. Every one of the 12 surfaces is classified in `.planning/phases/250-remote-integration/250-VISUAL-CLASSIFICATION.md`: 10 intentional with owner-feedback receipts, 2 unchanged, 0 regressions. Only the intentional PNGs are copied from the Linux `phase211-visual-baselines` artifact of `workflow_dispatch` run 40232864961. `250-visual-ledger-check.mjs` enforces the receipts and that the changed PNG set equals the intentional rows.
- The run with the re-minted baselines (CI run 40234321143 at `74cdd43a`) had `Browser UAT` green and one timing-dependent portal failure: `AccruePortal.BraintreeMox` linked its shared Agent to the first test that reset it, and ExUnit does not wait for a finished test process to exit. Fix: `fix(250-04): start the portal Braintree client-token stub unlinked`.
- The first close commit (CI run 40241001658 at `7b1b5862`) had one Release gate cell red: `verify_release_contract.sh` piped a 7551-byte section into `grep -q` under `pipefail`, so `grep` exiting on its first match could EPIPE the `printf` and turn a present needle into "missing". Fix: `fix(250-05): feed the v1.59 runbook greps from here-strings, not a pipe`. The same pattern remains in 6 other `scripts/ci` scripts; that sweep is recorded as a follow-up, not done here.
- One product risk is found and deliberately not fixed here: `accrue_events.inserted_at` follows the Postgres session timezone. It is recorded as a HIGH-priority v1.68 item in `.planning/REQUIREMENTS.md` (Future Requirements).
- Outside the PR bar (D1): the parked `Admin UI ratchet guardrails [parked]` lane stays `continue-on-error` by design (`.planning/WINDOWS.md` row 11) and fails at every head; the dispatch-only `Mint visual baselines` job and the push/schedule-only `Stripe provider-proof trigger classifier`, `Stripe provider-proof incident reconciliation` and `Stripe test-mode parity (mandatory periodic)` jobs are `skipped` on `pull_request` runs. They are not claimed here.

## Provenance

- **Head branch:** `integration/v1.63-v1.66`.
- **Evidence head:** `ece41e51eb0e6ab4f030d33501cd811188542686`, the Phase 250 pre-merge close. `250-ci-head-status.mjs --repo szTheory/accrue --sha ece41e51eb0e6ab4f030d33501cd811188542686 --event pull_request` (no `--visual-pending-ok`) prints GREEN, 20 jobs `success` (ci.yml run 40243045805, accrue_admin_browser.yml run 40243045812). Publication hygiene passes over every pushed commit: `bash .planning/phases/250-remote-integration/250-prepush-guard.sh --hygiene-only --range 23bee4949045b7ac9361d954b24497bb749e771b..ece41e51eb0e6ab4f030d33501cd811188542686`.
- The PR head is the evidence head plus one commit that changes only this file, because a commit cannot contain its own SHA. Falsify: `git diff --name-only ece41e51eb0e6ab4f030d33501cd811188542686 origin/integration/v1.63-v1.66` prints exactly `.planning/phases/250-remote-integration/250-INTEGRATION-PR.md`.
- The last green head before the close is `5ad01dee2c70087aa89fafdfb154f6e9d8068277`: `250-ci-head-status.mjs --event pull_request` GREEN, 20 jobs `success` (ci.yml run 40236926623, accrue_admin_browser.yml run 40236926603). The first close commit `7b1b5862` was red and is superseded.

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
