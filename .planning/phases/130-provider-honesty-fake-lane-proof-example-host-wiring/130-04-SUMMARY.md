---
phase: 130-provider-honesty-fake-lane-proof-example-host-wiring
plan: "04"
subsystem: example-host-dunning-wiring
tags: [dunning, host-wiring, fake-lane, oban, dun-10, adoption-proof]
dependency_graph:
  requires: ["130-01"]
  provides: [host-dunning-queue-wired, dunning-wiring-proof, adoption-proof-matrix-dunning-row]
  affects:
    - examples/accrue_host/config/config.exs
    - examples/accrue_host/config/test.exs
    - examples/accrue_host/test/accrue_host/dunning_wiring_test.exs
    - examples/accrue_host/priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs
    - examples/accrue_host/docs/adoption-proof-matrix.md
    - scripts/ci/verify_adoption_proof_matrix.sh
tech_stack:
  added: []
  patterns: [oban-cron-plugin, oban-testing-manual, fake-backed-host-proof, require_substring-drift-pin]
key_files:
  created:
    - examples/accrue_host/test/accrue_host/dunning_wiring_test.exs
    - examples/accrue_host/priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs
  modified:
    - examples/accrue_host/config/config.exs
    - examples/accrue_host/config/test.exs
    - examples/accrue_host/docs/adoption-proof-matrix.md
    - scripts/ci/verify_adoption_proof_matrix.sh
decisions:
  - "Scoped to DunningSweeper only (D-14 discretion) — DetectExpiringCards NOT wired; no accrue_scheduled queue added"
  - "Cron schedule is */15 * * * * (every 15 minutes) — matches DunningSweeper docstring recommendation"
  - "StripeFixtures not available in host test context (accrue test/support not compiled as host dep) — inlined webhook event map construction via make_webhook_event/2 helper"
  - "dunning_campaign_started_at migration added to host migrations (Rule 3 auto-fix — column missing blocked test)"
  - "Clock.advance/2 returns {:ok, _} not :ok (confirmed from Plan 03 learnings — applied correctly)"
  - "Recovery path is customer.subscription.updated (not invoice.paid) — confirmed from Plan 03"
metrics:
  duration: 18min
  completed_date: "2026-05-25"
  tasks: 3
  files: 6
---

# Phase 130 Plan 04: Example-Host Dunning Wiring + Adoption-Proof Matrix Summary

Closes the dormant-cron gap (DUN-10 SC#4): `examples/accrue_host` now has `accrue_dunning: 2` queue + `Oban.Plugins.Cron` DunningSweeper entry, a 5-test Fake-backed host wiring smoke proof, and a drift-gated adoption-proof-matrix row — demonstrating failed-payment → campaign-step → recovery end-to-end on the host path.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Wire host Oban queue + cron + manual testing | 166caa6c | config/config.exs, config/test.exs |
| 2 | Host-level Fake-backed dunning wiring smoke proof | 07b9a73d | dunning_wiring_test.exs, 20260525120000 migration |
| 3 | Add dunning row to adoption-proof matrix + verifier | c9143f6e | adoption-proof-matrix.md, verify_adoption_proof_matrix.sh |

## Key Decisions

**1. D-14 discretion: DunningSweeper only, no DetectExpiringCards**

Scoped tightly to the failed-payment dunning loop as recommended. `DetectExpiringCards` was NOT wired; no `accrue_scheduled: 5` queue added. The plan explicitly warns: if DetectExpiringCards is added, `accrue_scheduled: 5` must also be added (Pitfall 6). We avoided this complexity.

**2. Cron schedule: `*/15 * * * *`**

Matches the example in `DunningSweeper`'s `@moduledoc` host-wiring section verbatim.

**3. Inlined webhook event construction in host test**

`StripeFixtures` lives in `accrue/test/support` and is not compiled as a dep of the host app. Rather than creating a host-side test support module, the test inlines `make_webhook_event/2` — a private helper that constructs the same plain map that `StripeFixtures.webhook_event/2` produces (the format `DefaultHandler.handle/1` accepts).

**4. Four adoption-proof-matrix tokens (locked for verifier)**

- `dunning_wiring_test.exs` — host wiring smoke test
- `accrue_dunning` — queue name
- `Oban.Plugins.Cron` — crontab plugin
- `dunning_full_journey_test.exs` — accrue package full journey (Plan 03)

## Deviations from Plan

**1. [Rule 3 - Blocking] Missing `dunning_campaign_started_at` migration in host**

- **Found during:** Task 2 (test run)
- **Issue:** `accrue` package migration `20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs` existed in accrue's migration directory but had NOT been copied to `examples/accrue_host/priv/repo/migrations/`. The test DB raised `ERROR 42703 (undefined_column) column a0.dunning_campaign_started_at does not exist`.
- **Fix:** Copied the migration to the host migrations directory and ran `MIX_ENV=test mix ecto.migrate`.
- **Files modified:** examples/accrue_host/priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs (created)
- **Commit:** 07b9a73d

**2. [Rule 1 - Bug] `Clock.advance/2` returns `{:ok, _}` not `:ok`**

- **Found during:** Task 2 (test run — same behavior as Plan 03 deviation #1)
- **Issue:** Code initially used `:ok = Clock.advance([days: 5], [])` but the function returns `{:ok, %{clock: ..., advanced_by: ...}}`.
- **Fix:** Changed to `{:ok, _} = Clock.advance([days: 5], [])`.
- **Files modified:** examples/accrue_host/test/accrue_host/dunning_wiring_test.exs
- **Commit:** 07b9a73d

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. Config changes are host-local. T-130-04 (silent queue failure) mitigated: `accrue_dunning: 2` queue is now present and the wiring test asserts enqueue+drain fire. T-130-05 (false proof claim) mitigated: the four verifier needles pin the matrix row to real artifact names.

## Known Stubs

None. The test drives the real production path end-to-end using the Fake processor.

## Self-Check: PASSED

- `examples/accrue_host/config/config.exs` — contains `accrue_dunning`, `Oban.Plugins.Cron`, `Accrue.Jobs.DunningSweeper`
- `examples/accrue_host/config/test.exs` — contains `testing: :manual`
- `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs` — exists (276 lines > min_lines: 50)
- `examples/accrue_host/docs/adoption-proof-matrix.md` — contains all four tokens
- `scripts/ci/verify_adoption_proof_matrix.sh` — exits 0 ("verify_adoption_proof_matrix: OK")
- `mix test test/accrue_host/dunning_wiring_test.exs --seed 0` → 5 tests, 0 failures
- Task 1 commit 166caa6c — verified in git log
- Task 2 commit 07b9a73d — verified in git log
- Task 3 commit c9143f6e — verified in git log
