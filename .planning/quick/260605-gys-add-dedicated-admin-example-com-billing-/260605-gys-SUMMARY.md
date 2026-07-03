---
phase: quick-260605-gys
plan: 01
status: complete
subsystem: testing
tags: [seeds, admin, billing_admin, example_host, elixir, ecto]

requires: []
provides:
  - "ensure_demo_admin/1 helper in AccrueHost.Seeds.Helpers"
  - "admin@example.com seeded with billing_admin: true — /admin console reachable"
  - "OPERATOR/CUSTOMERS split documented in both banners and README"
  - "hero_accounts_test.exs locks persona split with billing_admin assertions"
affects: [accrue_host, seeds, dev_banner, hero_accounts_test]

tech-stack:
  added: []
  patterns:
    - "ensure_demo_admin/1 pattern: ensure_demo_user/1 + Ecto.Changeset.change/2 for privilege escalation outside changeset casts"

key-files:
  created: []
  modified:
    - "examples/accrue_host/priv/repo/seeds.exs"
    - "examples/accrue_host/priv/repo/seeds/hero_accounts.exs"
    - "examples/accrue_host/lib/accrue_host_web/dev_banner.ex"
    - "examples/accrue_host/bin/dev-banner.sh"
    - "examples/accrue_host/README.md"
    - "examples/accrue_host/test/accrue_host/hero_accounts_test.exs"

key-decisions:
  - "admin@example.com gets no org, no subscription, no dunning events — platform admins see all tenants via OwnerScope global mode; zero impact on seeds_idempotency_test 'exactly 7' assertion"
  - "billing_admin set via Ecto.Changeset.change/2 directly because User changeset does not cast this field — documented in code comment"
  - "DevBanner.maybe_print/0 bug fixed inline (nil and ... → BadBooleanError): use == true guard so nil env value in test env does not crash application startup"

requirements-completed: [quick-260605-gys]

duration: 8min
completed: 2026-06-05
---

# Quick Task 260605-gys: admin@example.com Billing-Admin Operator Seed

**`admin@example.com` seeded with `billing_admin: true` via `ensure_demo_admin/1`, making `/admin` structurally reachable; banners and README updated with OPERATOR/CUSTOMERS split; persona assertions locked in test**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-06-05T12:15:00Z
- **Completed:** 2026-06-05T12:23:00Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `ensure_demo_admin/1` to `AccrueHost.Seeds.Helpers`: get-or-creates user via `ensure_demo_user/1`, then unconditionally sets `billing_admin: true` via `Ecto.Changeset.change/2` (the field is not cast by any User changeset)
- Inserted `ensure_demo_admin("admin@example.com")` at the top of `hero_accounts.exs` with an OPERATOR comment; adds zero dunning events, so `seeds_idempotency_test.exs` "exactly 7" assertion is unaffected
- Updated both banners (bash + Elixir) and README with OPERATOR/CUSTOMERS split — `admin@example.com` clearly labeled as billing-admin for `/admin`, 5 customer personas labeled as tenant-facing only
- Locked persona split in `hero_accounts_test.exs`: `admin@example.com` must have `billing_admin: true`, `healthy@example.com` must have `billing_admin: false`
- Docker live verify: reseeded `accrue-host-web-1`, confirmed DB query returns exactly one row `admin@example.com | t`

## Task Commits

1. **Task 1: ensure_demo_admin/1 + admin@example.com seed** - `7b86751f` (feat)
2. **Task 2: banners + README updates** - `8c38ed3c` (docs)
3. **Task 3: hero_accounts_test persona assertions + Docker verify** - `730d9dd9` (test)

## Files Created/Modified

- `examples/accrue_host/priv/repo/seeds.exs` - Added `ensure_demo_admin/1` helper after `ensure_demo_user/1`; also fixed `DevBanner.maybe_print/0` `BadBooleanError`
- `examples/accrue_host/priv/repo/seeds/hero_accounts.exs` - Added `ensure_demo_admin("admin@example.com")` call at top with OPERATOR persona comment
- `examples/accrue_host/lib/accrue_host_web/dev_banner.ex` - OPERATOR/CUSTOMERS split in login block; `== true` guard for `dev_routes` check
- `examples/accrue_host/bin/dev-banner.sh` - OPERATOR/CUSTOMERS split in login block
- `examples/accrue_host/README.md` - Admin requirement sentence after `/admin` URL; `admin@example.com` leading the seeded-logins list
- `examples/accrue_host/test/accrue_host/hero_accounts_test.exs` - Two new assertions: `billing_admin: true` for admin, `billing_admin: false` for healthy

## Decisions Made

- `admin@example.com` has no org, no subscription, no dunning events — platform admins use `OwnerScope` global mode; this preserves the "exactly 7 dunning events" invariant in `seeds_idempotency_test.exs`
- `billing_admin` is set via `Ecto.Changeset.change/2` (not a cast changeset) because the `User` schema does not expose this field through any public changeset — documented in code comment

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed DevBanner.maybe_print/0 BadBooleanError crashing test application startup**
- **Found during:** Task 1 (running seeds_idempotency_test.exs)
- **Issue:** `Application.get_env(:accrue_host, :dev_routes)` returns `nil` in test env; `nil and ...` raises `BadBooleanError` in Elixir, crashing the application supervisor before any test code ran
- **Fix:** Changed `if Application.get_env(:accrue_host, :dev_routes) and ...` to `if Application.get_env(:accrue_host, :dev_routes) == true and ...` — strict boolean equality, nil-safe
- **Files modified:** `examples/accrue_host/lib/accrue_host_web/dev_banner.ex`
- **Verification:** `seeds_idempotency_test.exs` passed immediately after fix
- **Committed in:** `7b86751f` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Fix was blocking — without it no test could run. No scope creep.

## Issues Encountered

- Docker reseed required `mix deps.get` first due to lock mismatch (deps updated since the image was built). Normal container lifecycle behavior; ran `mix deps.get && mix run priv/repo/seeds.exs` and both succeeded cleanly.

## Docker Verify Results

Stack was running (`accrue-host-web-1`, `accrue-host-db-1`). Reseeded successfully. DB query confirmed:

```
       email        | billing_admin
---------------------+---------------
 admin@example.com   | t
 healthy@example.com | f
```

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced. The `billing_admin` flag is an existing DB column set via seeds only.

## Self-Check: PASSED

- `ensure_demo_admin` in `examples/accrue_host/priv/repo/seeds.exs`: FOUND
- `admin@example.com` in `examples/accrue_host/priv/repo/seeds/hero_accounts.exs`: FOUND
- `admin@example.com` in `examples/accrue_host/bin/dev-banner.sh`: FOUND
- `admin@example.com` in `examples/accrue_host/lib/accrue_host_web/dev_banner.ex`: FOUND
- `admin@example.com` in `examples/accrue_host/README.md`: FOUND
- `billing_admin` in `examples/accrue_host/test/accrue_host/hero_accounts_test.exs`: FOUND
- Task 1 commit `7b86751f`: FOUND
- Task 2 commit `8c38ed3c`: FOUND
- Task 3 commit `730d9dd9`: FOUND

## Next Phase Readiness

- `/admin` is now structurally reachable — log in as `admin@example.com` with `accrue-demo-password`
- All 3 tests pass: `hero_accounts_test.exs` (2 tests), `seeds_idempotency_test.exs` (1 test, exactly 7 dunning events)
- Docker live DB confirmed

---
*Quick task: quick-260605-gys*
*Completed: 2026-06-05*
