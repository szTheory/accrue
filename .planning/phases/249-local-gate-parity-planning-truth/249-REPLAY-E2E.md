# Phase 249 Playwright E2E Replay Ledger (249-15)

- Inventory taken at HEAD: `b21850ecda4d0f9f40d1fd5f620610d2ac38cc14` (scratch clone via `git clone --no-local`, real `npm ci`, no symlinks)
- Date: 2026-10-25
- Command per shard: `env -u ACCRUE_HOST_CUSTODY_CI_ABSENT npx playwright test --list --shard=N/3` in `examples/accrue_host`

## Non-vacuity inventory (listing only; nothing executed, no webServer, preview untouched)

| Shard | Result |
|-------|--------|
| 1/3 | Total: 30 tests in 11 files |
| 2/3 | Total: 25 tests in 11 files |
| 3/3 | Total: 26 tests in 8 files |

This proves the lane is non-vacuous. It does not prove the tests pass. The config-load custody preflight did not refuse during `--list` (preview-preservation guard is read-only there). The clone was removed afterwards.

## Routing

- playwright-e2e shards 1-3 (incl. shard-1 conditional lanes and Braintree steps): Routed to Phase 250 (custody: no local preview DB; maintainer decision 2026-10-25)

Phase 250 SC2 requires the `playwright-e2e` job to be `success` on the exact integration head SHA, using the absent-mode added in 249-18.

## Custody positive control

Deviation: the live flag-on run was denied by the execution permission classifier, so the recorded 249-18 real run is substituted. The fixture test is the repeatable control.

- Recorded real run (249-18-SUMMARY.md, maintainer machine with a preview), exit 2:
  `[preview-custody] REFUSED: CI absent-mode found a accrue-host preview instance (10 volumes, 0 containers)`
- `scripts/ci/accrue_host_preview_custody.sh` is unchanged since commit 84f78f40 (`git log 84f78f40..HEAD -- <script>` is empty), so the recorded run applies to these exact bytes.
- Repeatable control: `node --test scripts/ci/test_accrue_host_preview_custody.mjs` passes 28/28, including "absent-mode refuses when a labelled preview volume exists" (flag set + preview present -> REFUSE).
