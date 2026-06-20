---
quick_id: 260620-lie
slug: fix-stale-active-org-login
date: 2026-06-20
status: complete
---

# Summary: Fix login 500 from stale active_organization_id

## What changed
- `examples/accrue_host/lib/accrue_host_web/user_auth.ex`: session creation now
  validates the cookie's `active_organization_id` against the user's live
  memberships via a new `validated_active_organization_id/2` helper, passing
  `nil` when the org is stale/foreign/soft-deleted instead of FK-crashing the
  `user_sessions` insert.
- `examples/accrue_host/test/accrue_host_web/user_auth_test.exs`: +2 regression
  tests (stale id dropped → row nil; valid membership → row preserved).

## Result
`mix test test/accrue_host_web/user_auth_test.exs` → **29 tests, 0 failures**
(was 27). The login 500 is fixed and locked in by tests.

## Immediate operator note
To unblock an already-stuck browser session: clear cookies for
`accrue.localhost` (or use incognito) once — the fix prevents recurrence.
