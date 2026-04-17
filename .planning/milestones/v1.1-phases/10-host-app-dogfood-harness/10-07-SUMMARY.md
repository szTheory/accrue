---
phase: 10-host-app-dogfood-harness
plan: 07
subsystem: auth
tags: [phoenix, liveview, postgres, oban, accrue, accrue_admin, host-app]
requires:
  - phase: 10-04
    provides: installer-generated host billing facade, webhook/admin router wiring, and host app migrations
  - phase: 10-05
    provides: signed-in host billing state and Fake-backed subscription flow
  - phase: 10-06
    provides: signed webhook ingest proof and persisted webhook/event state shape
provides:
  - Host-owned `AccrueHost.Auth` adapter backed by Phoenix session `:user_token`
  - `/billing` admin mount protection for anonymous, non-admin, and admin host sessions
  - Mounted admin replay proof with persisted `admin.webhook.replay.completed` audit evidence
  - Clean-checkout README plus verified setup and local boot path for the host example
affects: [phase-10, host-app, auth, admin-ui, webhooks, docs]
tech-stack:
  added: []
  patterns: [host-session-backed-auth-adapter, mounted-admin-replay-proof, verified-clean-checkout-path]
key-files:
  created:
    - examples/accrue_host/lib/accrue_host/auth.ex
    - examples/accrue_host/priv/repo/migrations/20260416000100_add_billing_admin_to_users.exs
  modified:
    - examples/accrue_host/lib/accrue_host/accounts/user.ex
    - examples/accrue_host/lib/accrue_host_web/router.ex
    - examples/accrue_host/test/accrue_host_web/admin_mount_test.exs
    - examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
    - examples/accrue_host/README.md
    - examples/accrue_host/config/config.exs
    - examples/accrue_host/config/test.exs
    - examples/accrue_host/lib/accrue_host/application.ex
key-decisions:
  - "Use the host app's existing Phoenix session token as the only admin-session bridge into `accrue_admin`, rather than inventing a separate operator token path."
  - "Keep the replay proof on the real mounted webhook detail screen and wire the host app to run Oban locally so the DLQ replay path executes exactly as the admin UI expects."
patterns-established:
  - "Host auth adapters can resolve admin state directly from forwarded session keys and expose host-owned authorization fields like `billing_admin`."
  - "Clean-checkout verification is part of the implementation contract: README commands, migrations, boot config, and installer-boundary assertions must all survive a fresh database rebuild."
requirements-completed: [HOST-05, HOST-07, HOST-08]
duration: 7min
completed: 2026-04-16
---

# Phase 10 Plan 07: Host App Dogfood Harness Summary

**Host-session-backed `/billing` admin auth, mounted webhook replay audit proof, and a verified clean-checkout boot path for the example host app**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-16T13:00:15-04:00
- **Completed:** 2026-04-16T13:07:25-04:00
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments
- Added a real host auth adapter plus `billing_admin` authorization field so anonymous and non-admin sessions cannot mount `/billing`.
- Replaced the admin replay scaffold with a mounted LiveView proof that inspects subscription, webhook, and event history before replaying a row and asserting `admin.webhook.replay.completed`.
- Rewrote the host README with the exact rebuild commands, then verified both the clean-checkout setup flow and the local Phoenix boot path.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add a host auth adapter and admin authorization field for /billing** - `0e294d1` (feat)
2. **Task 2: Replace the admin replay placeholder with an audited replay proof** - `3d63774` (feat)
3. **Task 3: Document the clean-checkout setup and local boot path** - `9deaffd` (docs)

## Files Created/Modified
- `examples/accrue_host/lib/accrue_host/auth.ex` - host `Accrue.Auth` adapter that resolves users from the forwarded Phoenix session token and checks `billing_admin`
- `examples/accrue_host/lib/accrue_host/accounts/user.ex` - host user schema now carries the `billing_admin` flag
- `examples/accrue_host/lib/accrue_host_web/router.ex` - mounted admin route now forwards `:user_token` into `accrue_admin`
- `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` - executable anonymous/non-admin/admin `/billing` auth proof
- `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` - mounted admin replay proof with subscription/webhook/history assertions and audit linkage
- `examples/accrue_host/config/config.exs` - host-owned Accrue repo, branding, and Oban defaults for test/dev boot
- `examples/accrue_host/config/test.exs` - test-mode Oban config for mounted replay coverage
- `examples/accrue_host/lib/accrue_host/application.ex` - host supervision tree now starts Oban
- `examples/accrue_host/priv/repo/migrations/20260416000100_add_billing_admin_to_users.exs` - upgrade-safe `billing_admin` migration
- `examples/accrue_host/priv/repo/migrations/20260416163132_create_users_auth_tables.exs` - fresh-checkout users table now includes `billing_admin`
- `examples/accrue_host/test/install_boundary_test.exs` - installer boundary proof updated for the forwarded `:user_token` admin mount
- `examples/accrue_host/README.md` - exact clean-checkout and local boot commands with explicit PostgreSQL and Fake defaults

## Decisions Made
- Used the host app's normal `phx.gen.auth` session token as the admin identity input to `AccrueHost.Auth`, which keeps the mounted admin boundary realistic and host-owned.
- Fixed clean-checkout and boot regressions in-place instead of documenting workarounds, because the plan's README/boot contract is only satisfied when a fresh rebuild really works.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added host-owned Oban wiring for mounted replay jobs**
- **Found during:** Task 2 (Replace the admin replay placeholder with an audited replay proof)
- **Issue:** The mounted `replay-single` action called the real DLQ replay path, but the host app had Oban migrations only and no running/configured `Oban` instance.
- **Fix:** Added host Oban config, test overrides, and an Oban child in the host supervision tree.
- **Files modified:** `examples/accrue_host/config/config.exs`, `examples/accrue_host/config/test.exs`, `examples/accrue_host/lib/accrue_host/application.ex`
- **Verification:** `cd examples/accrue_host && mix test test/accrue_host_web/admin_webhook_replay_test.exs`
- **Committed in:** `3d63774` (part of task commit)

**2. [Rule 1 - Bug] Fixed fresh-checkout migration ordering for `billing_admin`**
- **Found during:** Task 3 (Document the clean-checkout setup and local boot path)
- **Issue:** The new `20260416000100_add_billing_admin_to_users` migration ran before the generated users-table migration on a clean database and failed because `users` did not exist yet.
- **Fix:** Made the upgrade migration conditional when `users` is absent and added `billing_admin` directly to the later users-table creation migration for fresh databases.
- **Files modified:** `examples/accrue_host/priv/repo/migrations/20260416000100_add_billing_admin_to_users.exs`, `examples/accrue_host/priv/repo/migrations/20260416163132_create_users_auth_tables.exs`
- **Verification:** `cd examples/accrue_host && mix ecto.create && mix ecto.migrate && mix test`
- **Committed in:** `9deaffd` (part of task commit)

**3. [Rule 2 - Missing Critical] Added non-test Accrue boot defaults required by `mix phx.server`**
- **Found during:** Task 3 (Document the clean-checkout setup and local boot path)
- **Issue:** The host example only configured `:accrue` repo and branding in `test`, so the documented `mix phx.server` boot path failed validation in `dev`.
- **Fix:** Added host-owned `:accrue` repo and branding defaults to app config and updated the installer-boundary assertion to match the forwarded-session admin mount.
- **Files modified:** `examples/accrue_host/config/config.exs`, `examples/accrue_host/test/install_boundary_test.exs`
- **Verification:** `cd examples/accrue_host && mix ecto.create && mix ecto.migrate && mix test && LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/accrue-host-boot.XXXXXX.log")" && ( export MIX_ENV=dev; mix phx.server >"$LOG_FILE" 2>&1 & SERVER_PID=$!; cleanup() { kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true; rm -f "$LOG_FILE"; }; trap cleanup EXIT; READY=0; for _ in $(seq 1 30); do if ! kill -0 "$SERVER_PID" 2>/dev/null; then cat "$LOG_FILE"; exit 1; fi; if rg -q 'Running AccrueHostWeb\\.Endpoint|http://localhost:4000' "$LOG_FILE"; then READY=1; break; fi; sleep 1; done; if [ "$READY" -ne 1 ]; then cat "$LOG_FILE"; exit 1; fi; if rg -q 'secret_key_base|STRIPE_WEBHOOK_SECRET|could not start.*Repo|failed to start child: .*Repo|database .* does not exist|pending migrations|tcp connect .* refused' "$LOG_FILE"; then cat "$LOG_FILE"; exit 1; fi )`
- **Committed in:** `9deaffd` (part of task commit)

---

**Total deviations:** 3 auto-fixed (1 bug, 2 missing critical)
**Impact on plan:** All three fixes were required to make the mounted replay path and clean-checkout boot contract actually executable. No scope creep beyond the host app boundaries named by the plan.

## Issues Encountered
- The mounted replay test initially failed because the host example had no Oban instance, which exposed a real gap between the admin UI's expected runtime and the host app's supervision/config state.
- The clean-checkout verification caught both a migration ordering bug and a missing dev boot config path that earlier task-local tests would not have surfaced on their own.

## User Setup Required

None - PostgreSQL 14+ on `localhost:5432` (or via `PGHOST` / `PGUSER` / `PGPASSWORD`) is now explicitly documented in the example README, and no live Stripe access is required for the local Fake-backed path.

## Next Phase Readiness
- Phase 10's host example now has the required auth/session boundary, audited admin replay proof, and reproducible local boot path for later stabilization and adoption work.
- The host app's Oban and Accrue boot config are now aligned with the mounted admin and webhook behavior already proven in the tests.

## Self-Check: PASSED
- Found `.planning/phases/10-host-app-dogfood-harness/10-07-SUMMARY.md`
- Found commit `0e294d1` in git history
- Found commit `3d63774` in git history
- Found commit `9deaffd` in git history

---
*Phase: 10-host-app-dogfood-harness*
*Completed: 2026-04-16*
